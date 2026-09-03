/**
 * @description       : 
 * @author            : nokrause@valgroupco.com.gaugedev
 * @group             : 
 * @last modified on  : 02-09-2025
 * @last modified by  : nokrause@valgroupco.com.gaugedev
**/
public without sharing class IcsInviteService {

    public class Request {
        @InvocableVariable(required=true) public Datetime startTime;
        @InvocableVariable(required=true) public Datetime endTime;
        @InvocableVariable(required=true) public String subject;
        @InvocableVariable public String descriptionText;
        @InvocableVariable public String organizerName;
        @InvocableVariable public String organizerEmail;
        @InvocableVariable public String attendeeEmails; // vírgula ou ;
        @InvocableVariable public Id linkEntityId;       // opcional
    }

    public class Response {
        @InvocableVariable public Id contentVersionId;
        @InvocableVariable public String fileName;
    }

    @InvocableMethod(label='Create ICS Invite'
                     description='Gera um arquivo .ics como ContentVersion e retorna o Id para anexar no e-mail do Flow.')
    public static List<Response> create(List<Request> requests) {
        List<Response> results = new List<Response>();
        List<ContentVersion> versions = new List<ContentVersion>();

        for (Request r : requests) {
            Response res = new Response();
            if (r == null) { results.add(res); continue; }

            String subj = String.isBlank(r.subject) ? 'Appointment' : r.subject;
            String icsDescription = (r.descriptionText == null) ? '' :
                r.descriptionText.replace('\r','').replace('\n','\\n');
            String orgName  = String.isBlank(r.organizerName)  ? 'Organizer' : r.organizerName;
            String orgEmail = String.isBlank(r.organizerEmail) ? UserInfo.getUserEmail() : r.organizerEmail;

            String dtStart = formatIcsDate(r.startTime);
            String dtEnd   = formatIcsDate(r.endTime);
            String dtStamp = formatIcsDate(Datetime.now());

            String uid = (r.linkEntityId != null ? String.valueOf(r.linkEntityId) : 'NA')
                       + '-' + String.valueOf(Datetime.now().getTime());

            String attendeeLines = '';
            if (!String.isBlank(r.attendeeEmails)) {
                for (String addr : r.attendeeEmails.replace(';', ',').split(',', 0)) {
                    if (String.isBlank(addr)) continue;
                    addr = addr.trim();
                    attendeeLines += 'ATTENDEE;CN=' + sanitizeIcs(addr) +
                                     ';RSVP=TRUE:MAILTO:' + addr + '\r\n';
                }
            }

            String ics =
'BEGIN:VCALENDAR\r\n' +
'VERSION:2.0\r\n' +
'PRODID:-//Mosaic//Scheduler//EN\r\n' +
'METHOD:REQUEST\r\n' +
'BEGIN:VEVENT\r\n' +
'UID:' + uid + '\r\n' +
'DTSTAMP:' + dtStamp + '\r\n' +
'DTSTART:' + dtStart + '\r\n' +
'DTEND:' + dtEnd + '\r\n' +
'SUMMARY:' + sanitizeIcs(subj) + '\r\n' +
'DESCRIPTION:' + sanitizeIcs(icsDescription) + '\r\n' +
'ORGANIZER;CN=' + sanitizeIcs(orgName) + ':MAILTO:' + orgEmail + '\r\n' +
attendeeLines +
'END:VEVENT\r\n' +
'END:VCALENDAR\r\n';

            Blob body = Blob.valueOf(ics);

            ContentVersion cv = new ContentVersion();
            cv.Title = subj.left(80);
            cv.PathOnClient = 'invite.ics';
            cv.VersionData = body;
            if (r.linkEntityId != null) {
                cv.FirstPublishLocationId = r.linkEntityId;
            }
            versions.add(cv);
            results.add(res);
        }

        if (!versions.isEmpty()) {
            insert versions;
            for (Integer i = 0; i < versions.size(); i++) {
                results[i].contentVersionId = versions[i].Id;
                results[i].fileName = versions[i].PathOnClient;
            }
        }

        return results;
    }

    private static String sanitizeIcs(String s) {
        if (s == null) return '';
        s = s.replace('\\','\\\\');
        s = s.replace(',','\\,');
        s = s.replace(';','\\;');
        s = s.replace('\n','\\n');
        return s;
    }

    private static String formatIcsDate(Datetime dt) {
        if (dt == null) dt = Datetime.now();
        return dt.formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'');
    }
}