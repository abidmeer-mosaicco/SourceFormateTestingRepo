/** @description This is a utility class for external callouts.
 *  @author Gideoni Silva
 *  @storynumber EIDGT-550
 */
public without sharing class PMC_CPIAccountIntegrationClass implements Database.AllowsCallouts {
    static HttpRequest request = new HttpRequest();
    static HttpResponse response;
    static Boolean boolTransLogSuccess = false;
    static Boolean boolTransLogError = false;
    static String strTransactionLogStatus;
    static final String STRING_INTEGRATIONSTATUSERROR = 'Error'; 
    static final String STRING_INTEGRATIONSTATUSSUCCESS = 'Success';
    static final String STRING_INTEGRATIONSTATUSPARTIALSUCCESS = 'Partial Success';
    static final string STRING_SFRECORDID = 'ExpressTrainStationName';
    static final string STRING_MDMSYNCERROR = 'Failure';
    static final string STRING_MDMSYNCSUCCESS = 'Success';    
    static final Integer INT_STATUSCODE200 = 200;
    static final Integer INT_STATUSCODE201 = 201;
    static final Integer INT_STATUSCODE204 = 204;
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
     * @description It returns the prefix for integration message.
     * @param strEndpoint - Integration Endpoint.
     * @return strPrefix - Prefix of Integration Message.
     */
    
    /** 
     * @description Parses through the response body and populates Integration fields on the Account.
     * @param lstAccounts - List of Accounts.
     * @param response - Response received from the endpoint.
     * @param strEndpoint - Endpoint that the HttpRequest will hit.
     */
    public static void parseJSONAccountInterface(Account EffectiveAccount, HttpResponse response, String strEndpoint)
    {    
        List<Object> lstFilteredList = new List<Object>();
        List<Object> lstObjContainer= new List<Object>();
        String strJSONResponseBody = response.getBody();
		Integer intResponseCode;
		String strSAPRefId;
        String strEffectiveAccountId;
		Integer intCountResponseCodes;

        if(LISTINT_SUCCESSCODES.contains(response.getStatusCode()))//status code returned is 200
        {   
            try
            {
				Map<String, Object> mapBusinessPartner = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                EffectiveAccount.PMC_CPI_IntegrationStatus__c = STRING_INTEGRATIONSTATUSSUCCESS;
                EffectiveAccount.PMC_CPI_IntegrationMessage__c = strEndpoint + ': ' + response.toString();
                EffectiveAccount.PMC_SS_MDMSyncStatus__c = STRING_MDMSYNCSUCCESS;
                update EffectiveAccount;
                
                strTransactionLogStatus = getOverallTransactionStatus();
            }
            catch(Exception e)//Exception caused due to inablitiy to parse through response.
            {
                strTransactionLogStatus = STRING_INTEGRATIONSTATUSPARTIALSUCCESS;
				EffectiveAccount.PMC_CPI_IntegrationStatus__c = STRING_INTEGRATIONSTATUSPARTIALSUCCESS;
				EffectiveAccount.PMC_CPI_IntegrationMessage__c = strEndpoint + ': ' + e.getMessage().abbreviate(225);
                EffectiveAccount.PMC_SS_MDMSyncStatus__c = STRING_MDMSYNCSUCCESS;
                update EffectiveAccount;
            }
		}
        else //status code returned is not 200
        {
            strTransactionLogStatus = STRING_INTEGRATIONSTATUSERROR;
			EffectiveAccount.PMC_CPI_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
			EffectiveAccount.PMC_CPI_IntegrationMessage__c = strEndpoint + ': ' + strJSONResponseBody.abbreviate(225);
            EffectiveAccount.PMC_SS_MDMSyncStatus__c = STRING_MDMSYNCERROR;
            update EffectiveAccount;
        }
        
        Map<String, String> mapTransactionLogFields = new Map<String,String>();
        mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',strTransactionLogStatus);
        mapTransactionLogFields.put('PMC_CPQ_InterfaceURL__c',strEndpoint);
        mapTransactionLogFields.put('PMC_CPQ_RequestBody__c',PMC_CPIAccountCalloutUtilityClass.request.getBody());
        mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c',strJSONResponseBody);

        lstTransactionLogs = PMC_CPQ_TransactionLogUtilityClass.addTransactionLog(mapTransactionLogFields);
        PMC_CPQ_TransactionLogUtilityClass.insertTransactionLogs(lstTransactionLogs);
    
    }

    /** 
     * @description Parses through the response body and populates Integration fields on the Account.
     * @param lstAccounts - List of Accounts.
     * @param response - Response received from the endpoint.
     * @param strEndpoint - Endpoint that the HttpRequest will hit.
     */
    public static void parseXMLAccountInterface(Account EffectiveAccount, HttpResponse response, String strEndpoint)
    {    
        List<Object> lstStatusCode = new List<Object>();
		Integer intResponseCode;
		String strSAPRefId;
        String strEffectiveAccountId;
		Integer intCountResponseCodes;

        try         
        {
            if (strEndpoint == '/http/BPCreation') 
            {
        		if (LISTINT_SUCCESSCODES.contains(response.getStatusCode()))//status code returned is 200
                {
                    strTransactionLogStatus = STRING_INTEGRATIONSTATUSSUCCESS;
                	EffectiveAccount.PMC_CPI_IntegrationStatus__c = STRING_INTEGRATIONSTATUSSUCCESS;
                	EffectiveAccount.PMC_CPI_IntegrationMessage__c = strEndpoint + ': ' + response.toString().abbreviate(225);
                	EffectiveAccount.PMC_SS_MDMSyncStatus__c = STRING_MDMSYNCSUCCESS;
                	update EffectiveAccount;
                }  else
                {
                    strTransactionLogStatus = STRING_INTEGRATIONSTATUSERROR;
                    EffectiveAccount.PMC_CPI_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
                    EffectiveAccount.PMC_CPI_IntegrationMessage__c = strEndpoint + ': ' + response.toString().abbreviate(225);
                    EffectiveAccount.PMC_SS_MDMSyncStatus__c = STRING_MDMSYNCERROR;
                    update EffectiveAccount;
                }
                
            } else if (strEndpoint == '/http/BPModification') 
            {
                DOM.Document docXMLResponseBody = response.getBodyDocument();
                for(Dom.XmlNode changeSetNode: docXMLResponseBody.getRootElement().getChildElements()) {
                    for(Dom.XmlNode changeSetPartNode: changeSetNode.getChildElements()) {
                        if(changeSetPartNode.getName() == 'batchChangeSetPartResponse') {
                            lstStatusCode.add(changeSetPartNode.getChildElement('statusCode',null).getText());
                        }
                    }
                }
        
                if(lstStatusCode.contains('201') || lstStatusCode.contains('204'))
                {   
                    EffectiveAccount.PMC_CPI_IntegrationStatus__c = STRING_INTEGRATIONSTATUSSUCCESS;
                    EffectiveAccount.PMC_CPI_IntegrationMessage__c = strEndpoint + ': ' + response.toString().abbreviate(225);
                    EffectiveAccount.PMC_SS_MDMSyncStatus__c = STRING_MDMSYNCSUCCESS;
                    update EffectiveAccount;
                    
                    strTransactionLogStatus = getOverallTransactionStatus();
                }
                else //status code returned is not 200
                {
                    strTransactionLogStatus = STRING_INTEGRATIONSTATUSERROR;
                    EffectiveAccount.PMC_CPI_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
                    EffectiveAccount.PMC_CPI_IntegrationMessage__c = strEndpoint + ':' + response.getStatusCode();
                    EffectiveAccount.PMC_SS_MDMSyncStatus__c = STRING_MDMSYNCERROR;
                    update EffectiveAccount;
                }
            
                Map<String, String> mapTransactionLogFields = new Map<String,String>();
                mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',strTransactionLogStatus);
                mapTransactionLogFields.put('PMC_CPQ_InterfaceURL__c',strEndpoint);
                mapTransactionLogFields.put('PMC_CPQ_RequestBody__c',PMC_CPIAccountCalloutUtilityClass.request.getBody());
                mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c',response.getBody());
        
                lstTransactionLogs = PMC_CPQ_TransactionLogUtilityClass.addTransactionLog(mapTransactionLogFields);
                PMC_CPQ_TransactionLogUtilityClass.insertTransactionLogs(lstTransactionLogs);
            }
        }
        catch(Exception e)//Exception caused due to inablitiy to parse through response.
        {
            strTransactionLogStatus = STRING_INTEGRATIONSTATUSERROR;
            EffectiveAccount.PMC_CPI_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
            EffectiveAccount.PMC_CPI_IntegrationMessage__c = strEndpoint + ': ' + e.getMessage().abbreviate(225);
            EffectiveAccount.PMC_SS_MDMSyncStatus__c = STRING_MDMSYNCERROR;
            update EffectiveAccount;
        }    
    }    
    /** 
     * @description Updates the status and message for accounts 
     * @param EffectiveAccount - Account object.
     * @param strEndpoint - Integration Endpoint.
     */
    public static void updateAccountExceptionStatusMsg(Account EffectiveAccount, String strEndpoint)
    {
        EffectiveAccount.PMC_CPI_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
        EffectiveAccount.PMC_CPI_IntegrationMessage__c = strEndpoint + ': ' + 
            (PMC_CPIAccountCalloutUtilityClass.strExceptionMsg != null 
                ? PMC_CPIAccountCalloutUtilityClass.strExceptionMsg.abbreviate(225) 
                : 'Unknown error');
        EffectiveAccount.PMC_SS_MDMSyncStatus__c = STRING_MDMSYNCERROR;
        update EffectiveAccount;
    }
}