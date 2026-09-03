/** @description This is a utility class for transaction logs.
 *  @author Shefali Dsouza
 *  @storynumber GDASF-2983
 */
public without sharing class PMC_CPQ_TransactionLogUtilityClass {
    
    public static List<PMC_CPQ_TransactionLog__c> lstTransactionLogs = new List<PMC_CPQ_TransactionLog__c>();
    /** 
     * @description This class is used to add a trasaction log to the list of transaction logs.
     * @param mapTransactionLogFields - Send integration fields. 
     * @return lstTransactionLogs - Add to list of transaction logs.
     */
    public static List<PMC_CPQ_TransactionLog__c> addTransactionLog(Map<String, String> mapTransactionLogFields)
    {
        PMC_CPQ_TransactionLog__c trl = new PMC_CPQ_TransactionLog__c();
        trl.PMC_CPQ_IntegrationStatus__c = mapTransactionLogFields.get('PMC_CPQ_IntegrationStatus__c');
        trl.PMC_CPQ_InterfaceURL__c = mapTransactionLogFields.get('PMC_CPQ_InterfaceURL__c');
        trl.PMC_CPQ_RequestBody__c = mapTransactionLogFields.get('PMC_CPQ_RequestBody__c');
        trl.PMC_CPQ_ResponseBody__c = mapTransactionLogFields.get('PMC_CPQ_ResponseBody__c').abbreviate(131065);
        trl.PMC_CPQ_Quote__c = mapTransactionLogFields.containsKey('PMC_CPQ_Quote__c') ? (Id) mapTransactionLogFields.get('PMC_CPQ_Quote__c'): null;
        trl.PMC_CPQ_Error_Message__c = mapTransactionLogFields.containsKey('PMC_CPQ_Error_Message__c')? mapTransactionLogFields.get('PMC_CPQ_Error_Message__c'): ''; 
         trl.PMC_CPQ_Error_Category__c = mapTransactionLogFields.containsKey('PMC_CPQ_Error_Category__c')? mapTransactionLogFields.get('PMC_CPQ_Error_Category__c'): '';        
        lstTransactionLogs.add(trl); 
        return lstTransactionLogs;
    }
     /** 
     * @description This class is used to insert the transaction log.
     * @param lstTransactionLogs - List of transaction logs
     */
	public static void insertTransactionLogs(List<PMC_CPQ_TransactionLog__c> lstTransactionLogs)
    {
        SObjectAccessDecision securityDecisionTrl = Security.stripInaccessible(AccessType.CREATABLE, lstTransactionLogs);
    	Database.insert(securityDecisionTrl.getRecords(),false);
    }  
    
    /**
     * @description Add transaction log fields with error message and Quote Id if error scenario
     * @param responseBody - Raw response body from CPI
     * @param requestBody - Raw request body sent to CPI
     * @param mapTransactionLogFields - Current transaction log fields map
     * @return Updated mapTransactionLogFields with error details if applicable
     */
    public static Map<String, String> extractQuoteAndErrorMsg(String responseBody,String requestBody, Map<String, String> mapTransactionLogFields) {      
     
        String errorMsg;
        Id quoteId;
        Integer maxLength = PMC_CPQ_TransactionLog__c.PMC_CPQ_Error_Message__c.getDescribe().getLength();

    
        try {
            // Try parsing JSON response
            List<Object> payload = (List<Object>) JSON.deserializeUntyped(responseBody);
            Set<String> messages = new Set<String>();
            Set<Id> errorQuoteIds = new Set<Id>();
    
            for (Object row : payload) {
                Map<String, Object> rec = (Map<String, Object>) row;
                if ('E'.equalsIgnoreCase((String) rec.get('TYPE'))) {
    
                    // collect messages with metadata mapping
                    String rawMsg = (String) rec.get('MESSAGE');
                    messages.add(mapToFriendlyMsg(rawMsg));
    
                    String sfId = (String) rec.get('SFRecordId');
                    if (String.isNotBlank(sfId)) {
                        errorQuoteIds.add((Id) sfId);
                    }
                }
            }
    		
            // Pick first valid quote
            if (!errorQuoteIds.isEmpty()) {
               List<SBQQ__Quote__c> validQuotes = [SELECT Id FROM SBQQ__Quote__c WHERE Id IN :errorQuoteIds LIMIT 1];
                if (!validQuotes.isEmpty()) {
                    quoteId = validQuotes[0].Id;
                }
            }
    
            if (!messages.isEmpty()) {
                mapTransactionLogFields.put('PMC_CPQ_Error_Category__c', 'Functional');
                errorMsg = String.join(new List<String>(messages), '; ');
            }           
        }
        catch (Exception e) {
            // If not json responsebody
            errorMsg = mapToFriendlyMsg(responseBody);
    
            try {
                // take first Id from request body
                Map<String, Object> req = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
                List<Object> ids = (List<Object>) req.get('Id');
                if (!ids.isEmpty()) {
                    Id candidate = (Id) ids[0];
                    SBQQ__Quote__c q = [SELECT Id FROM SBQQ__Quote__c WHERE Id = :candidate LIMIT 1];
                    quoteId = q.Id;
                }
                 mapTransactionLogFields.put('PMC_CPQ_Error_Category__c', 'Technical');
            } catch (Exception ignore) {
                // no valid Id found
            }
        }
    
        // Enrich map
        if (!String.isBlank(errorMsg)) {
            mapTransactionLogFields.put('PMC_CPQ_Error_Message__c', errorMsg.abbreviate(255));
        }
        if (quoteId != null) {

            if (errorMsg.length() > maxLength) {
                errorMsg = errorMsg.substring(0, maxLength);
            }
            mapTransactionLogFields.put('PMC_CPQ_Quote__c', String.valueOf(quoteId));
        }
        return mapTransactionLogFields;
    }
    
    /**
     * @description Map raw message to user-friendly message via metadata
     *  @param rawMsg 
     */
    private static String mapToFriendlyMsg(String rawMsg) {
        if (String.isBlank(rawMsg)) return '';
        for (PMC_CPQ_ErrorMessageSettings__mdt mdt :
             [SELECT PMC_CPQ_RegexExpression__c, PMC_CPQ_ConvertedErrorMessage__c 
              FROM PMC_CPQ_ErrorMessageSettings__mdt]) {
            if (!String.isBlank(mdt.PMC_CPQ_RegexExpression__c) &&
                rawMsg.contains(mdt.PMC_CPQ_RegexExpression__c)) {
                return mdt.PMC_CPQ_ConvertedErrorMessage__c;
            }
        }
        return rawMsg; 
    }

}