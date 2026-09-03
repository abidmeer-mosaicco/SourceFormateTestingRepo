/** @description This is a utility class for external callouts.
 *  @author Gideoni Silva
 */
public without sharing class PMC_CPI_ProductIntegrationClass implements Database.AllowsCallouts {
    static HttpRequest request = new HttpRequest();
    static HttpResponse response;
    static Boolean boolTransLogSuccess = false;
    static Boolean boolTransLogError = false;
    static String strTransactionLogStatus;
    static final String STRING_INTEGRATIONSTATUSERROR = 'Error'; 
    static final String STRING_INTEGRATIONSTATUSSUCCESS = 'Success';
    static final String STRING_INTEGRATIONSTATUSPARTIALSUCCESS = 'Partial Success';
    static final string STRING_MDMSYNCERROR = 'Failure';
    static final string STRING_MDMSYNCSUCCESS = 'Success';    
    static final Integer INT_STATUSCODE200 = 200;
    static final Integer INT_STATUSCODE201 = 201;
    static final Integer INT_STATUSCODE204 = 204;
    static final Boolean BOOL_MDMVERIFIEDTRUE = true;
    static final Boolean BOOL_MDMVERIFIEDFALSE = false;
    static Exception objException;
    static final List<Integer> LISTINT_SUCCESSCODES = new List<Integer>{INT_STATUSCODE200,INT_STATUSCODE201,INT_STATUSCODE204};
    static List<PMC_CPQ_TransactionLog__c> lstTransactionLogs;
    
     /** 
     * @description Returns overall order status
     * @return strIntegrationStatusError - Status = Error
     * @return strIntegrationStatusWarning - Status = Warning
     * @return strIntegrationStatusSuccess - Status = Success 
     */
    public static String getOverallTransactionStatus()
    {
        if(boolTransLogError)
        {
            return (STRING_INTEGRATIONSTATUSERROR);
        }
        return (STRING_INTEGRATIONSTATUSSUCCESS);
    }
    
    /** 
     * @description Parses through the response body and populates Integration fields on the Product.
     * @param EffectiveProduct - Product affected.
     * @param response - Response received from the endpoint.
     * @param strEndpoint - Endpoint that the HttpRequest will hit.
     */

    public static void parseXMLProductInterface(Product2 EffectiveProduct, HttpResponse response, String strEndpoint)
    {    
        try         
        {
        	if (LISTINT_SUCCESSCODES.contains(response.getStatusCode()))//status code returned is 200
            {
                strTransactionLogStatus = STRING_INTEGRATIONSTATUSSUCCESS;
                EffectiveProduct.PMC_CPI_IntegrationStatus__c = STRING_INTEGRATIONSTATUSSUCCESS;
                EffectiveProduct.PMC_CPI_IntegrationMessage__c = strEndpoint + ': ' + response.toString().abbreviate(225);
                EffectiveProduct.PMC_SS_MDMSyncStatus__c = STRING_MDMSYNCSUCCESS;
                EffectiveProduct.PMC_SS_MDMVerified__c = BOOL_MDMVERIFIEDTRUE;
                update EffectiveProduct;
            } else {
                strTransactionLogStatus = STRING_INTEGRATIONSTATUSERROR;
                EffectiveProduct.PMC_CPI_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
                EffectiveProduct.PMC_CPI_IntegrationMessage__c = strEndpoint + ': ' + response.toString().abbreviate(225);
                EffectiveProduct.PMC_SS_MDMSyncStatus__c = STRING_MDMSYNCERROR;
                EffectiveProduct.PMC_SS_MDMVerified__c = BOOL_MDMVERIFIEDFALSE;
                update EffectiveProduct;
            }

            Map<String, String> mapTransactionLogFields = new Map<String,String>();
            mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',strTransactionLogStatus);
            mapTransactionLogFields.put('PMC_CPQ_InterfaceURL__c',strEndpoint);
            mapTransactionLogFields.put('PMC_CPQ_RequestBody__c',PMC_CPI_ProductCalloutUtilityClass.request.getBody());
            mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c',response.getBody());
        
            lstTransactionLogs = PMC_CPQ_TransactionLogUtilityClass.addTransactionLog(mapTransactionLogFields);
            PMC_CPQ_TransactionLogUtilityClass.insertTransactionLogs(lstTransactionLogs);

        }
        catch(Exception e)//Exception caused due to inablitiy to parse through response.
        {
            strTransactionLogStatus = STRING_INTEGRATIONSTATUSERROR;
            EffectiveProduct.PMC_CPI_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
            EffectiveProduct.PMC_CPI_IntegrationMessage__c = strEndpoint + ': ' + e.getMessage().abbreviate(225);
            EffectiveProduct.PMC_SS_MDMSyncStatus__c = STRING_MDMSYNCERROR;
            update EffectiveProduct;
        }    
    }    
    /** 
     * @description Updates the status and message for Product 
     * @param EffectiveProduct - Product object.
     * @param strEndpoint - Integration Endpoint.
     */
    public static void updateProductExceptionStatusMsg(Product2 EffectiveProduct, String strEndpoint)
    {
        EffectiveProduct.PMC_CPI_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
        EffectiveProduct.PMC_CPI_IntegrationMessage__c = strEndpoint + ': ' + 
            (PMC_CPI_ProductCalloutUtilityClass.strExceptionMsg != null 
                ? PMC_CPI_ProductCalloutUtilityClass.strExceptionMsg.abbreviate(225) 
                : 'Unknown error');
        EffectiveProduct.PMC_SS_MDMSyncStatus__c = STRING_MDMSYNCERROR;
        update EffectiveProduct;
    }
}