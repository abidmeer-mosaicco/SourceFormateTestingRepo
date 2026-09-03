/** @description This class will be used to publish quote amend event to SAP Event Mesh. 
 *  @author 
 *  @storynumber -SIR-26
 */
public class PMC_CPQ_ContractUpdatePublishClass implements Queueable, Database.AllowsCallouts{
    
    public List<SBQQ__Quote__c> lstQuotes;
    public List<Id> lstIds;
    static final String STRING_INTEGRATIONSTATUSERROR = 'Error';
    static final String STRING_INTEGRATIONSTATUSSUCCESS = 'Success';
	static final String STRING_INTERFACE = 'PublishContractUpdate';    
    static final String STRING_NAMEDCREDENTIALS = 'callout:PMC_CPQ_EDANamedCredential';
    static final String STRING_METHOD = 'POST';
    static final Integer INT_STATUSCODE204 = 204; 
    static final String STRING_PREFIX = 'Contract Update: ';
    static List<PMC_CPQ_TransactionLog__c> lstTransactionLogs = new List<PMC_CPQ_TransactionLog__c>();
     /** 
     * @description Constructor of the class. 
     * @param lstQuotes - list of quotes sent from the flow.
     * @param lstIds - lists of ids
     */
    public PMC_CPQ_ContractUpdatePublishClass(List<SBQQ__Quote__c> lstQuotes, List<Id> lstIds)
    {
        this.lstQuotes = lstQuotes; 
        this.lstIds = lstIds;
    }
    
    /** 
     * @description This is the apex action that will be invoked from the flow.
     * @param lstQuotes - list of quotes sent from the flow.
     */
	@InvocableMethod(label='Contract Update Event Publishing Action' description='Publishes the Amended quotes to Event Mesh to update contract records in SAP' category='SBQQ__Quote__c')
  	public static void postInfoToCPI(List<SBQQ__Quote__c> lstQuotes) {
        List<Id> lstIds = new List<Id>();
        
        for(SBQQ__Quote__c objQuote: lstQuotes)
        {
            lstIds.add(objQuote.Id);
        }
       System.enqueueJob(new PMC_CPQ_ContractUpdatePublishClass(lstQuotes,lstIds));
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
        
        Map<Id, MassUpdateExecutionLine__c> mapExecutionLinesByCreatedQuote = new Map<Id, MassUpdateExecutionLine__c>();
        for(MassUpdateExecutionLine__c line: [
            SELECT Id, CreatedQuote__c, FinishedSteps__c
            FROM MassUpdateExecutionLine__c 
            WHERE CreatedQuote__c IN :lstIds
        ]) {
            mapExecutionLinesByCreatedQuote.put(line.CreatedQuote__c, line);
        }
        String strSerializedBody = PMC_CPQ_CPIRemoteCalloutUtilityClass.createMinimalPayload(lstIds);
        HttpResponse response = PMC_CPQ_CPIRemoteCalloutUtilityClass.sendCalloutRequest(STRING_METHOD, strCalloutEndpoint, strSerializedBody);

        if(response != null){
			
            Map<String, String> mapTransactionLogFields = new Map<String, String>();
			mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c', STRING_INTEGRATIONSTATUSERROR);
			mapTransactionLogFields.put('PMC_CPQ_InterfaceURL__c', strEndpoint);
			mapTransactionLogFields.put('PMC_CPQ_RequestBody__c', strSerializedBody);
			mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c',response.getStatusCode() + ' '+response.getBody());            
            
            for(SBQQ__Quote__c amendedQuote: lstQuotes){
                MassUpdateExecutionLine__c executionLine = mapExecutionLinesByCreatedQuote.get(amendedQuote.Id);
                if(response.getStatusCode() == INT_STATUSCODE204){
                    amendedQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSSUCCESS;
                    // GCPM-5314
                    // amendedQuote.Get_Prices_Status__c = 'In Progress';
                    amendedQuote.PMC_CPQ_IntegrationMessage__c = STRING_PREFIX + 'Published to Event Mesh';
                    if(executionLine != null){
                        mapExecutionLinesByCreatedQuote.put(amendedQuote.Id, new MassUpdateExecutionLine__c(
                            Id = executionLine.Id,
                            Status__c = 'Success',
                            Step__c = 'Generate Contracts',
                            FinishedSteps__c = StringUtils.addPicklistValueToMultiSelect(mapExecutionLinesByCreatedQuote.get(amendedQuote.Id).FinishedSteps__c, 'Generate Contracts')
                        ));
                    }
					mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c', STRING_INTEGRATIONSTATUSSUCCESS);                    
                }
                else{
                    amendedQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
                    // GCPM-5314
                    // amendedQuote.Get_Prices_Status__c = 'Failed';
                    amendedQuote.PMC_CPQ_IntegrationMessage__c = STRING_PREFIX + STRING_INTEGRATIONSTATUSERROR;                    
                    if(executionLine != null){
                        mapExecutionLinesByCreatedQuote.put(amendedQuote.Id, new MassUpdateExecutionLine__c(
                            Id = executionLine.Id,
                            Status__c = 'Error',
                            Step__c = 'Generate Contracts'
                        ));
                    }
                }
                
            }
            update (mapExecutionLinesByCreatedQuote.values());
            update lstQuotes;
            
            lstTransactionLogs = PMC_CPQ_TransactionLogUtilityClass.addTransactionLog(mapTransactionLogFields);
			PMC_CPQ_TransactionLogUtilityClass.insertTransactionLogs(lstTransactionLogs);
            
        } else {
            Boolean boolRetry = PMC_CPQ_CPIRemoteCalloutUtilityClass.autoRetryQueueableApex(AsyncInfo.getCurrentQueueableStackDepth(),PMC_CPQ_CPIRemoteCalloutUtilityClass.strExceptionMsg);
            if(boolRetry) {
                System.enqueueJob(new PMC_CPQ_ContractUpdatePublishClass(lstQuotes,lstIds), 1);
            }
            for(Id quoteId : lstIds) {
                if(mapExecutionLinesByCreatedQuote.size()>0 && mapExecutionLinesByCreatedQuote.get(quoteId)!=null){
                    mapExecutionLinesByCreatedQuote.put(quoteId, new MassUpdateExecutionLine__c(
                        Id = mapExecutionLinesByCreatedQuote.get(quoteId).Id,
                        Status__c = 'Error',
                        Step__c = 'Generate Contracts'
                    ));
                }
            }
            PMC_CPQ_CPIQuoteContractIntegrationClass.updateQuoteExceptionStatusMsg(lstQuotes,strEndpoint);
        }
    }

}