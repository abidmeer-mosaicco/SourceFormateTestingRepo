/** @description This class will be used to make callouts to the Contract Update interface of CPI. 
 *  @author Shefali Dsouza
 *  @storynumber GDASF-2978
 */
public class PMC_CPQ_ContractUpdateActionClass implements Queueable, Database.AllowsCallouts{   
    public List<SBQQ__Quote__c> lstQuotes;
    public List<Id> lstIds;
    static final String STRING_INTEGRATIONSTATUSERROR = 'Error';
    static final String STRING_INTERFACE = 'SAPContractUpdate';
    static final String STRING_NAMEDCREDENTIALS = 'callout:PMC_CPQ_NamedCredential';
    static final String STRING_METHOD = 'POST';
    static List<PMC_CPQ_TransactionLog__c> lstTransactionLogs = new List<PMC_CPQ_TransactionLog__c>();
     /** 
     * @description Constructor of the class. 
     * @param lstQuotes - list of quotes sent from the flow.
     * @param lstIds - lists of ids
     */
    public PMC_CPQ_ContractUpdateActionClass(List<SBQQ__Quote__c> lstQuotes, List<Id> lstIds)
    {
        this.lstQuotes = lstQuotes; 
        this.lstIds = lstIds;
    }	
    /** 
     * @description This is the apex action that will be invoked from the flow.
     * @param lstQuotes - list of quotes sent from the flow.
     */
	@InvocableMethod(label='Contract Update Remote Action' description='Triggers the CPI Interface to update contract records in SAP' category='SBQQ__Quote__c')
  	public static void postInfoToCPI(List<SBQQ__Quote__c> lstQuotes) {
        List<Id> lstIds = new List<Id>();
        
        for(SBQQ__Quote__c objQuote: lstQuotes)
        {
            lstIds.add(objQuote.Id);
        }
       System.enqueueJob(new PMC_CPQ_ContractUpdateActionClass(lstQuotes,lstIds));
    }    
    /** 
     * @description Makes a rerquest to callout class.
     * @param context - Receives the context of the flow. In this case it is the list of quotes.
     */
    public void execute(QueueableContext context)
    {
        PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(STRING_INTERFACE); 
        String strEndpoint = strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c;
        String strCalloutEndpoint = STRING_NAMEDCREDENTIALS+strEndpoint;
        
        String strSerializedBody = PMC_CPQ_CPIRemoteCalloutUtilityClass.createMinimalPayload(lstIds);
        HttpResponse response = PMC_CPQ_CPIRemoteCalloutUtilityClass.sendCalloutRequest(STRING_METHOD, strCalloutEndpoint, strSerializedBody);

        if(response != null)
        {
            PMC_CPQ_CPIQuoteContractIntegrationClass.parseJSONQuoteContractInterface(lstQuotes,response,strEndpoint);
        }
        else
        {
            Boolean boolRetry = PMC_CPQ_CPIRemoteCalloutUtilityClass.autoRetryQueueableApex(AsyncInfo.getCurrentQueueableStackDepth(),PMC_CPQ_CPIRemoteCalloutUtilityClass.strExceptionMsg);
            if(boolRetry)
            {
                System.enqueueJob(new PMC_CPQ_ContractUpdateActionClass(lstQuotes,lstIds), 1);
            }
            PMC_CPQ_CPIQuoteContractIntegrationClass.updateQuoteExceptionStatusMsg(lstQuotes,strEndpoint);
        }
    }
}