/**
* @description This class will be used to Send NA Payment Terms  Approval Email to the Service Director Users
* @author Jeyanthi Muthaiah
* @storynumber GDASF-10718 S14
*/
public with sharing  class PMC_CPQ_ApprovalGroupEmailSenderClass {
    /**
* @description This method is invoked from the flow  PMC CPQ Send Email to Service Director User Sub Flow as a sub flow from PMC CPQ After Create/Update Quote .
* and calls this Apex Action.
* @param recordid - id of the approval record.	
*/
    Public static Boolean testRunning=false;
    
    
    @InvocableMethod(label='send Approval Group Email')
    public static void sendApprovalGroupEmail(List<Id> recordid) {
        String approvaltemplateId;
        string id;
        
        // Query to fetch the approval Record
        sbaa__Approval__c approvalRecordInfo = [SELECT id,sbaa__Approver__r.sbaa__GroupId__c,sbaa__Rule__r.sbaa__ApprovalTemplate__r.sbaa__TemplateId__c  from sbaa__Approval__c WHERE id =: recordid[0] WITH SECURITY_ENFORCED];
        approvaltemplateId = ApprovalRecordInfo.sbaa__Rule__r.sbaa__ApprovalTemplate__r.sbaa__TemplateId__c;
        id = approvalRecordInfo.id;
        
        
        // Get Users having Service Director Role
        List<User> userList =[SELECT id,Name From User where UserRole.Name='Service Director' WITH SECURITY_ENFORCED];
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        // Loop through each service director user and send email
        for (User userDetails : userList) { 
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();            
            
            email.setTemplateId(approvaltemplateId);
            if(!testRunning){
                email.setWhatId(id);
                }
            email.setTargetObjectId(userDetails.id);
            email.setSaveAsActivity(false);
            emailMessages.add(email);            
        }      
        Messaging.sendEmail(emailMessages);           
    }
}