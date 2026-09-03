/** @description This class will be used to create and expose a custom web service end point for CPI to call with response to the 
 * published amend quote/update contract event . 
 *  @author 
 *  @storynumber -SIR-27
 */
@RestResource(urlMapping='/quote/contractupdate')
global without sharing class PMC_CPQ_SetContractRefResource {
    static final String STRING_INTEGRATIONSTATUSERROR = 'Error';
	static final String STRING_INTEGRATIONSTATUSSUCCESS = 'Success';
	static final String STRING_GETPRICEPREFIX = 'Contract Update: ';
    static final string STRING_SFRECORDID = 'SFRecordId';    
    static String strTransactionLogStatus;
    static List<PMC_CPQ_TransactionLog__c> lstTransactionLogs;
    
    /** 
     * @description This is the apex method that will be exposed as HTTP POST action that will be called by CPI.
     * @param 
     */
    
    @HttpPost
	global static void saveQuoteContractRef() {
		RestRequest req = RestContext.request;
		RestResponse res = RestContext.response;
		SBQQ__Quote__c quoteRecord;
		List<SBQQ__Quote__c> lstQuotes;
		Map<String, Object> jsonResponse;
		String reqBody = req.requestBody.toString();
		String resBody = '';
        String strEndpoint = '/http/UpdateContractRecords';
		PMC_CPQ_TransactionLog__c transactionLog = new PMC_CPQ_TransactionLog__c();
		transactionLog.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
		transactionLog.PMC_CPQ_InterfaceURL__c = strEndpoint;
		List<Object> lstObjContainer= new List<Object>();
        List<Object> lstFilteredList = new List<Object>();
        Set<String> quoteSFRecIdSet = new Set<String>();
		list<SBQQ__QuoteLine__c> QuoteItemUpdate=new list<SBQQ__QuoteLine__c>();
        String strSerializedBody;
        
        Map<String, String> mapTransactionLogFields = new Map<String,String>();
        mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',strTransactionLogStatus);
        mapTransactionLogFields.put('PMC_CPQ_InterfaceURL__c',strEndpoint);
        mapTransactionLogFields.put('PMC_CPQ_RequestBody__c',reqBody);
        mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c','');
        try {
			lstObjContainer = (List<Object>) JSON.deserializeUntyped(reqBody);
            lstFilteredList = PMC_CPQ_CPIQuoteContractIntegrationClass.getFilteredList(lstObjContainer);//removes duplicate records and non essential values
            for(Object curObjContainer: lstFilteredList)//parse through filtered list 
            {
                Map<String,Object> mapRecord = (Map<String,Object>)curObjContainer;
                quoteSFRecIdSet.add((Id)mapRecord.get(STRING_SFRECORDID));
            }
            
            lstQuotes = [
					SELECT Id, PMC_CPQ_SAPContractReference__c, PMC_CPQ_IntegrationStatus__c, PMC_CPQ_IntegrationMessage__c 
					FROM SBQQ__Quote__c
					WHERE Id in  :quoteSFRecIdSet					
				];
            // Convert Set to List using the List constructor
			List<String> lstIds = new List<String>(quoteSFRecIdSet);
            strSerializedBody = PMC_CPQ_CPIRemoteCalloutUtilityClass.createMinimalPayload(lstIds);
            
            if (lstQuotes.isEmpty()) {
					throw new CustomException('Quotes not found!');
			}
            
            PMC_CPQ_CPIQuoteContractIntegrationClass.parseQuoteContractFilteredList(lstQuotes, lstFilteredList, strEndpoint, lstObjContainer);
            strTransactionLogStatus = PMC_CPQ_CPIQuoteContractIntegrationClass.getOverallTransactionStatus();
            if(strTransactionLogStatus == STRING_INTEGRATIONSTATUSERROR){
            	PMC_CPQ_CPIQuoteContractIntegrationClass.getFilteredErrorList(lstObjContainer,lstQuotes,QuoteItemUpdate,strEndpoint);
            }

            SObjectAccessDecision securityDecisionQuote = Security.stripInaccessible(AccessType.UPDATABLE, lstQuotes);
            Database.update(securityDecisionQuote.getRecords(),false);

           // PMC_CPQ_CPIQuoteContractIntegrationClass.parseAndUpdateQuoteLineFields(lstObjContainer);
            
            
            res.statusCode = 200;
            
            
        	mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',strTransactionLogStatus);
        	                    
        	if (strTransactionLogStatus == STRING_INTEGRATIONSTATUSERROR) {
        		mapTransactionLogFields = PMC_CPQ_TransactionLogUtilityClass.extractQuoteAndErrorMsg(reqBody,
                                                                                            strSerializedBody,
                                                                                            mapTransactionLogFields );
        	}
        
        	
        	
								
			
		} catch (Exception ex) {
			System.debug(ex.getMessage());
            mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',STRING_INTEGRATIONSTATUSERROR);
            mapTransactionLogFields = PMC_CPQ_TransactionLogUtilityClass.extractQuoteAndErrorMsg(reqBody,
                                                                                            strSerializedBody,
                                                                                            mapTransactionLogFields );
			res.statusCode = 500;
			if (lstQuotes!=null && !lstQuotes.isEmpty()) {				
				resBody = '{"error":"Internal Server Error","details":"' + ex.getMessage() + '","quoteId":"' + lstQuotes[0].Id + '"}';			
				
			} else {
				resBody = '{"error":"Internal Server Error","details":"' + ex.getMessage() + '","quoteId":""}';
			}
		}
		
		res.responseBody = Blob.valueOf(resBody);
        lstTransactionLogs = PMC_CPQ_TransactionLogUtilityClass.addTransactionLog(mapTransactionLogFields);
		PMC_CPQ_TransactionLogUtilityClass.insertTransactionLogs(lstTransactionLogs);
		
	}

}