public without sharing class GenericEmailService {
    // ===== Inputs / Outputs for Flow =====
    public class Request {
        @InvocableVariable(required=true)
        public Id targetId;                 

        @InvocableVariable(required=true)
        public Id serviceAppointmentId;     

        @InvocableVariable
        public String orgWideEmailAddressName; 

        @InvocableVariable
        public Id fileId;

    }

    public class Response {
        @InvocableVariable public String status;   // "OK" or "ERROR"
        @InvocableVariable public String message;  // details
    }

    @InvocableMethod(label='Send Appointment Email (Custom HTML)'
                     description='Sends an email composing HTML from a Custom Label (or override), with Service Appointment fields.')
    public static List<Response> send(List<Request> requests) {
        List<Response> out = new List<Response>();
        for (Request r : requests) {
            Response res = new Response();
            try {
                if (r == null || r.targetId == null || r.serviceAppointmentId == null) {
                    res.status = 'ERROR';
                    res.message = 'targetId and serviceAppointmentId are required.';
                    out.add(res); continue;
                }

                // Identify recipient type
                String pref = String.valueOf(r.targetId).left(3);
                Boolean isLead = pref == '00Q';
                Boolean isContact = pref == '003';
                Boolean isUser = pref == '005';

                // Load SA + relateds
                SAData data = fetchSAData(r.serviceAppointmentId);

                String html = '';
                if (isLead || isContact) {
                    html = System.Label.PMC_Appointment_Email_Lead;
                } else {
                    html = System.Label.PMC_Appointment_Email_Resource;
                }
               
                
                String saUrl = buildRecordUrl(data.saId, 'ServiceAppointment');

                html = mergeHtml(html, new Map<String, String>{
                    'workTypeName'               => data.workTypeName,
                    'schedStart'                 => formatDateTime(data.schedStart),
                    'schedEnd'                   => formatDateTime(data.schedEnd),
                    'assignedToName'            => data.assignedToName,
                    'link' => saUrl
                });

                // Prepare message
                Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
                m.setTargetObjectId(r.targetId);

                if (isLead || isContact) {
                    m.setTreatTargetObjectAsRecipient(true);
                }                

                  // We are NOT using TemplateId: we compose HTML ourselves
                m.setHtmlBody(html);
                m.setSaveAsActivity(false); // default; adjust below

                // Optional OWA
                if (!String.isBlank(r.orgWideEmailAddressName)) {
                    Id owaId = getOrgWideEmailAddressId(r.orgWideEmailAddressName);
                    if (owaId == null) throw new AuraHandledException('Org-Wide Email Address not found: ' + r.orgWideEmailAddressName);
                    m.setOrgWideEmailAddressId(owaId);
                }
 
                // Attachment (optional)
                if (r.fileId != null) {
                    m.setFileAttachments(new Messaging.EmailFileAttachment[]{ buildAttachment(r.fileId) });
                }

                // Subject dinamicamente como no template
                m.setSubject(
                    'Appointment for ' + data.workTypeName + ' on ' + data.schedStart.format()
                );                

                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ m });

                res.status = 'OK';
                res.message = 'Email sent.';
            } catch (Exception e) {
                res.status = 'ERROR';
                res.message = e.getMessage();
            }
            out.add(res);
        }
        return out;
    }

    // ===== Data carrier for SA query =====
    private class SAData {
        Id saId;
        Datetime schedStart;
        Datetime schedEnd;
        String workTypeName;
        String assignedToName;
    }

    // Query SA, WorkType, and Assigned Resource (RelatedRecord.Name)
    private static SAData fetchSAData(Id saId) {
        SAData d = new SAData();
        ServiceAppointment sa = [
            SELECT Id, SchedStartTime, SchedEndTime,
                   WorkType.Name,
                   Owner.FirstName, Owner.LastName
            FROM ServiceAppointment
            WHERE Id = :saId
            LIMIT 1
        ];
        d.saId = sa.Id;
        d.schedStart = sa.SchedStartTime;
        d.schedEnd = sa.SchedEndTime;
        d.workTypeName = (sa.WorkType != null) ? sa.WorkType.Name : null;
        d.assignedToName = sa.Owner.LastName + ' ' + sa.Owner.FirstName;
        return d;
    }

    // Merge placeholders {{Key}} in HTML
    private static String mergeHtml(String html, Map<String,String> tokens) {
        if (String.isBlank(html) || tokens == null) return html;
        for (String k : tokens.keySet()) {
            String token = '{{' + k + '}}';
            html = html.replace(token, tokens.get(k) == null ? '' : tokens.get(k));
        }
        return html;
    }

    /*
    // Build Salesforce record URL (works in sandbox/prod)
    private static String buildRecordUrl(Id recordId, String sobjectName) {
        String base = '';//URL.getSalesforceBaseUrl().toExternalForm();
        return base + '/lightning/r/ServiceAppointment/' + sobjectName + '/' + recordId + '/view';
        //https://globaldigitalacceleration--devp1.sandbox.lightning.force.com/lightning/r/ServiceAppointment/08pOt0000030HYbIAM/view
    }*/
     // Link absoluto que abre no navegador (sandbox/prod, Lightning)
// Ex.: https://mydomain--dev.my.salesforce.com/lightning/r/ServiceAppointment/08p.../view
private static String buildRecordUrl(Id recordId, String sobjectApiName) {
    // Base do seu My Domain (compatível com API ≥ 59)
    String base = URL.getOrgDomainUrl().toExternalForm();

    // Fallback simples se não vier o nome do sObject
    if (String.isBlank(sobjectApiName)) {
        return base + '/' + recordId; // universal (redireciona)
    }

    // Caminho Lightning correto: /lightning/r/{SObject}/{Id}/view
    return base + '/lightning/r/' + sobjectApiName + '/' + recordId + '/view';
}


    // Datetime formatting (adjust as needed)
    private static String formatDateTime(Datetime dt) {
        return (dt == null) ? '' : dt.format(); // usa locale/timezone do org/usuário de execução
    }

    // Optional: find OWA by DisplayName
    private static Id getOrgWideEmailAddressId(String displayName) {
        List<OrgWideEmailAddress> ow = [
            SELECT Id
            FROM OrgWideEmailAddress
            WHERE DisplayName = :displayName
            LIMIT 1
        ];
        return ow.isEmpty() ? null : ow[0].Id;
    }

    // Accept ContentVersion (068) or ContentDocument (069)
    private static Messaging.EmailFileAttachment buildAttachment(Id fileId) {
        
        ContentVersion cv = [SELECT Title, FileExtension, VersionData FROM ContentVersion WHERE Id = :fileId LIMIT 1];

        Messaging.EmailFileAttachment a = new Messaging.EmailFileAttachment();
        a.setFileName(cv.Title + '.' + cv.FileExtension);
        a.setBody(cv.VersionData);
        return a;
    }
}