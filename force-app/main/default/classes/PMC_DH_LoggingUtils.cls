/**
* @description : class for Logging 
* @author      : Siddharth Pradhan
* */
public without sharing class PMC_DH_LoggingUtils {
    
    static final String STRING_INTEGRATIONSTATUSERROR = 'Error'; 
    static final String STRING_INTEGRATIONSTATUSSUCCESS = 'Success';
    static final Integer INT_STATUSCODE200 = 200;
    static final Integer INT_STATUSCODE201 = 201;
    static final List<Integer> LISTINT_SUCCESSCODES = new List<Integer>{INT_STATUSCODE200,INT_STATUSCODE201};
        static HttpRequest request = new HttpRequest();
    static HttpResponse response;
    static List<PMC_CPQ_TransactionLog__c> lstTransactionLogs;
    static final String STRING_DOCENDPOINT='/documents/';
    /**
* @description Parses through the response body and populates Integration fields on the cart.
* @param lstCarts - List of cart.
* @param response - response received from the endpoint. 
* @param strEndpoint - Endpoint that the HttpRequest will hit.
**/
    public static void parseJSONGetPriceInterface(List<WebCart> lstCarts , HttpResponse response, String strEndpoint)
    {    
        String strJSONResponseBody = response.getBody();
        WebCart objCart = lstCarts[0];
        Map<String, String> mapTransactionLogFields = new Map<String,String>();
        mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',STRING_INTEGRATIONSTATUSERROR);
        mapTransactionLogFields.put('PMC_CPQ_InterfaceURL__c',strEndpoint);
        mapTransactionLogFields.put('PMC_CPQ_RequestBody__c',PMC_CPQ_CPIRemoteCalloutUtilityClass.request.getBody());
        mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c',strJSONResponseBody);
        
        
        if(LISTINT_SUCCESSCODES.contains(response.getStatusCode()))//status code returned is 200
        {   
            objCart.PMC_DH_IntegrationStatus__c = STRING_INTEGRATIONSTATUSSUCCESS;
            objCart.PMC_DH_IntegrationMessage__c = STRING_INTEGRATIONSTATUSSUCCESS;
            
            objCart.PMC_DH_GetPriceCallComplete__c = true;
            
            mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',STRING_INTEGRATIONSTATUSSUCCESS);
            
            
        }
        else if(response.getStatusCode() != 500) //status code returned is not 200
        {
            objCart.PMC_DH_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
            
            //Check for null response under Error Details json node.
            
            String checkForNullResponseFromSAP;
            checkForNullResponseFromSAP = ('' + ((Map<String, Object>)((Map<String, Object>)((Map<String, Object>)JSON.deserializeUntyped(response.getBody())).get('error')).get('innererror')).get('errordetails'));
            objCart.PMC_DH_IntegrationMessage__c = ((checkForNullResponseFromSAP != '')?(String)((Map<String, Object>)((List<Object>)((Map<String, Object>)((Map<String, Object>)((Map<String, Object>)((Map<String, Object>)JSON.deserializeUntyped(response.getBody())).get('error')).get('innererror')).get('errordetails')).get('errordetail'))[0]).get('message'):System.Label.PMC_CPQ_GetPriceCalloutFailedNoResponse);              
            
            
        }else{
            objCart.PMC_DH_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
            objCart.PMC_DH_IntegrationMessage__c = STRING_INTEGRATIONSTATUSERROR;
            
            
        }
        
        try {
            SObjectAccessDecision securityDecisionQuote = Security.stripInaccessible(AccessType.UPDATABLE, lstCarts);
            Database.update(securityDecisionQuote.getRecords(),false);
            
            lstTransactionLogs = PMC_CPQ_TransactionLogUtilityClass.addTransactionLog(mapTransactionLogFields);
            PMC_CPQ_TransactionLogUtilityClass.insertTransactionLogs(lstTransactionLogs);
        } 
        catch(Exception ex)
        {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    /**
* @description Parses through the response body and creates transaction logs.
* @param request 
* @param response - response received from the endpoint. 
* @param strEndpoint - Endpoint that the HttpRequest will hit.

**/
    
    public static void createDHTransactionLogs(HttpRequest request,HttpResponse response, String strEndpoint){
        String strJSONResponseBody = response.getBody();
        Map<String, String> mapTransactionLogFields = new Map<String,String>();
        mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',STRING_INTEGRATIONSTATUSERROR);
        mapTransactionLogFields.put('PMC_CPQ_InterfaceURL__c',strEndpoint);
        mapTransactionLogFields.put('PMC_CPQ_RequestBody__c',request.getBody());
        mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c',response.getStatusCode()+' _ '+strJSONResponseBody); 
        
        if(LISTINT_SUCCESSCODES.contains(response.getStatusCode()))//status code returned is 200
        {  
            mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',STRING_INTEGRATIONSTATUSSUCCESS);
            if(strEndpoint.contains(STRING_DOCENDPOINT)){
                mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c',response.getStatusCode()+' _ '+'Success_Response');
            }
        }
        else{
            mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',STRING_INTEGRATIONSTATUSERROR);
        }
        
        try{
            lstTransactionLogs = PMC_CPQ_TransactionLogUtilityClass.addTransactionLog(mapTransactionLogFields);
            //system.debug('@@@3'+lstTransactionLogs);
            PMC_CPQ_TransactionLogUtilityClass.insertTransactionLogs(lstTransactionLogs);
        } 
        catch(Exception ex)
        {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
}