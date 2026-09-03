/**
 * @description       : Used to perform DML for Service Now
 * @author            : Sayali Shinde
 * @last modified on  : 09-26-2023
**/

public with sharing class PMC_SS_CaseServiceNowUpdateCtrl {
    
    /**
     * @description - Method used to fetch the Contracts Details related to Account Id
     * @param strAccountId - Account Id
     * @return Account - Returns Account Record & Related Contract Records
     */
    @AuraEnabled
    public static Account getAccountRelatedDetails(String strAccountId){
        try {
            Account objAccount = [SELECT Id, Name, 
                                    (SELECT Id, ContractNumber,SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__CustomerAmount__c, Name FROM Contracts)
                                     FROM Account WHERE Id =: strAccountId WITH SECURITY_ENFORCED];
            return objAccount;
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * @description - Method used to fetch the users
     * @return list<User> - Returns Account Record & Related Contract Records
     */
    @AuraEnabled
    public static List<User> getUserDetails(){
        
       return [SELECT Id, Name,FederationIdentifier FROM User WHERE IsActive =: true AND IsPortalEnabled =:false AND FederationIdentifier != null WITH SECURITY_ENFORCED];
        
    }

    /**
     * @description - Method used to fetch the Invoice Details related to Account Id
     * @param strAccountId - Account Id
     * @return Account - Returns Account Record & Related Contract Records
     */
    @AuraEnabled
    public static List<PMC_CPQ_Invoice__c> getInvoices(String strAccountId){
        
            return [SELECT Id,Name,PMC_CPQ_SoldToAccount__c  FROM PMC_CPQ_Invoice__c 
                    WHERE PMC_CPQ_SoldToAccount__c =: strAccountId WITH SECURITY_ENFORCED];
        
    }

    
    /**
     * @description - Method used to insert ServiceNow tickect using REST Callout
     * @param strSolutionType - Selected Solution Type
     * @param strRequestJson - request body JSON string 
     * @return tickect Sync ID  - Returns response from serviceNow
     */
    @AuraEnabled
    public static String createSNTicket(String strSolutionType, String strRequestJson){
        try {

            
            HttpResponse response = doCallout(strSolutionType,strRequestJson,PMC_SS_ConstantClass.POST);
            createTransactionLogRecord(strRequestJson,response.getBody(),response.getStatus());
            
            
            if(response.getStatusCode() == 200){
                Map<String, Object> mapResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                return  String.valueOf(mapResponse.values()[0]);
            }
            return 'ERROR';    
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
            
        }
    }
    
    /**
     * @description - Method used to insert comment to ServiceNow
     * @param lstNewCasesComment - List of inserted comments
     */
    @InvocableMethod(label='Add Comments' description='Send Comments to ServiceNow ')
    public static void addComments(List<CaseComment> lstNewCasesComment){
        for(CaseComment objComment : lstNewCasesComment ) {
            PMC_SS_CaseServiceNowUpdateCtrl.sendCommentToSNOW(objComment.Id);
        }
        
    }
    /**
     * @description - Method used to insert comment to ServiceNow
     * @param idCaseComment - Comment ID 
     */
    @future(Callout=True)
    public static void sendCommentToSNOW(Id idCaseComment){

            String strRequestJson = '';
            for(CaseComment objCaseComment : [SELECT Id,ParentId,CommentBody,Parent.PMC_SS_SNOW_ServiceNowTicketSyncId__c FROM CaseComment 
                                             		WHERE ID=: idCaseComment AND Parent.PMC_SS_SNOW_ServiceNowTicketSyncId__c != '' 
                                              		 WITH SECURITY_ENFORCED LIMIT 1]) {
				
                strRequestJson = '{"ticket_sys_id": "'+objCaseComment.Parent.PMC_SS_SNOW_ServiceNowTicketSyncId__c;
                strRequestJson +='",  "comments": "'+UserInfo.getName()+' : '+objCaseComment.CommentBody+'"}';
            }
            
           HttpResponse response = doCallout(PMC_SS_ConstantClass.COMMENTS,strRequestJson,PMC_SS_ConstantClass.PUT);
        	 createTransactionLogRecord(strRequestJson,response.getBody(),response.getStatus());
    }
    
    /**
     * @description - Method used to insert comment to ServiceNow
     * @param strSolutionType -  Solution Type
     * @param strRequestJson - request body
     * @param strCalloutType - callout type
     * @return response - reponse from callout
     */
    
    private static HttpResponse doCallout(String strSolutionType,String strRequestJson,String strCalloutType){
        
        	PMC_SS_SNOW_SolutionWithEndPoint__mdt objSolutionDetails = new PMC_SS_SNOW_SolutionWithEndPoint__mdt();

            for(PMC_SS_SNOW_SolutionWithEndPoint__mdt objSolution : [SELECT MasterLabel,PMC_SS_SNOW_SolutionEndPoint__c,PMC_SS_SNOW_TicketType__c,PMC_SS_SNOW_TableName__c
                                                                            FROM PMC_SS_SNOW_SolutionWithEndPoint__mdt 
                                                                            WHERE PMC_SS_SNOW_TicketType__c =:  strSolutionType
                                                                            WITH SECURITY_ENFORCED]) {
                    objSolutionDetails = objSolution;
            }
        
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:PMC_SS_ServiceNow'+objSolutionDetails.PMC_SS_SNOW_SolutionEndPoint__c);
            request.setMethod(strCalloutType);
            request.setHeader('Accept', 'application/json');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(strRequestJson);
            return http.send(request);
    } 
    /**
     * @description - Method used to fetch the users
     * @return list<PMC_SS_SNOWKeyValuePair__mdt> - Returns Account Record & Related Contract Records
     */
    @AuraEnabled
    public static List<PMC_SS_SNOWKeyValuePair__mdt> getsnowlistDetails(){
        
       return [SELECT MasterLabel,PMC_SS_Value__c FROM PMC_SS_SNOWKeyValuePair__mdt WITH SECURITY_ENFORCED];
        
    }
     /** 
* @description This is to create PMC_CPQ_TransactionLog__c record.
* @param strRequestBody - request body.
* @param strResponseBody - response body
* @param strStatus - status of service response
*/
    private static void createTransactionLogRecord(String strRequestBody,String strResponseBody,String strStatus){
        PMC_CPQ_TransactionLog__c objTransactionLog = new PMC_CPQ_TransactionLog__c();
        objTransactionLog.PMC_CPQ_IntegrationStatus__c = strStatus;
        objTransactionLog.PMC_CPQ_RequestBody__c = strRequestBody;
        objTransactionLog.PMC_CPQ_ResponseBody__c = strResponseBody;
        objTransactionLog.PMC_CPQ_InterfaceURL__c = PMC_SS_ConstantClass.STRING_INTERFACE_NAME;
     	try{
            if(Schema.sObjectType.PMC_CPQ_TransactionLog__c.isCreateable()){
                Database.insert(objTransactionLog, true);
            }
            
        }catch(Exception objException){
            PMC_ErrorLogClass.processException(objException);
        }
            
    }

}