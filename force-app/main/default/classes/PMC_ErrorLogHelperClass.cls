/**
 * @description This class acts as a helper for the Error Log class.
 * @author Sachin Seshabhattar
 */
public without sharing class PMC_ErrorLogHelperClass {
    
    /**
     * @description This method would be used to process the error log records and generate attachments if any.
     * @param objErrorLog error log object
     * @param intLongTextAreaFieldLimit character limit of textarea fields
     * @param boolSkipAttachmentGeneration variable to check if we have to skip attachment generation
     * @return Attachment attachment related to error log if any
     */
    public static Attachment processErrorLogRecord(PMC_ErrorLog__c objErrorLog, Integer intLongTextAreaFieldLimit, Boolean boolSkipAttachmentGeneration){
        Attachment objAttachment;
        String strTrimmedMessage = 'Data Trimmed by Developer: ';

        if(String.IsNotBlank(objErrorLog.PMC_SerializedClass__c) && (objErrorLog.PMC_SerializedClass__c.length() > intLongTextAreaFieldLimit)
            && boolSkipAttachmentGeneration) {
            objErrorLog.PMC_SerializedClass__c = strTrimmedMessage + objErrorLog.PMC_SerializedClass__c;
            objErrorLog.PMC_SerializedClass__c = objErrorLog.PMC_SerializedClass__c.substring(0, intLongTextAreaFieldLimit - 1);
        }else {
            objAttachment = new Attachment();
            objAttachment.Body = objErrorLog.PMC_SerializedClass__c != null?Blob.valueOf(objErrorLog.PMC_SerializedClass__c):Blob.valueOf('');
            objAttachment.Name = 'SerializedClass.txt';
            objAttachment.Description = objErrorLog.PMC_ExternalId__c;
            objErrorLog.PMC_SerializedClass__c = 'Please see ' + objAttachment.Name + ' attached file.';
        }

        if(String.IsNotBlank(objErrorLog.PMC_AdditionalSerializedObject__c) && (objErrorLog.PMC_AdditionalSerializedObject__c.length() > intLongTextAreaFieldLimit) 
            && boolSkipAttachmentGeneration) {
            objErrorLog.PMC_AdditionalSerializedObject__c = strTrimmedMessage + objErrorLog.PMC_AdditionalSerializedObject__c;
            objErrorLog.PMC_AdditionalSerializedObject__c = objErrorLog.PMC_AdditionalSerializedObject__c.substring(0, intLongTextAreaFieldLimit - 1);
        }else {
            objAttachment = new Attachment();
            objAttachment.Body = objErrorLog.PMC_AdditionalSerializedObject__c != null?Blob.valueOf(objErrorLog.PMC_AdditionalSerializedObject__c):Blob.valueOf('');
            objAttachment.Name = 'AdditionalSerializedClass.txt';
            objAttachment.Description = objErrorLog.PMC_ExternalId__c;
            objErrorLog.PMC_AdditionalSerializedObject__c = 'Please see ' + objAttachment.Name + ' attached file.';
        }
        return objAttachment;
    }

    /**
    * @description This method inserts Error log records.
    *
    * @param lstAttachments List of Attchment records
    * @param lstErrorLogRecords    List of Error Log records.
    */
    public static void insertAttachmentRecords(List<Attachment> lstAttachments, List<PMC_ErrorLog__c> lstErrorLogRecords){
        //This map stores the Error Log record ExternalId as key and Id as value
        Map<String, Id> mapErrorLogExternalIdVsId = new Map<String, Id>();
        
        for(PMC_ErrorLog__c objError : lstErrorLogRecords) {
            mapErrorLogExternalIdVsId.put(objError.PMC_ExternalId__c, objError.Id);
        }
        
        for(Attachment objNewAttachment : lstAttachments) {
            if(mapErrorLogExternalIdVsId.get(objNewAttachment.Description) != NULL) {
                objNewAttachment.ParentId = mapErrorLogExternalIdVsId.get(objNewAttachment.Description);
                objNewAttachment.Description = null;
            }            
        }
        
        //Insert the attchment records
        if(lstAttachments.size() > 0 && Schema.sObjectType.Attachment.isCreateable()) {
            insert lstAttachments;
        }
    }
}