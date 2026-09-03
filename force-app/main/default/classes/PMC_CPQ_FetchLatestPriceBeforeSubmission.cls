/**@description Action Class invoked from the flow whenever Submit For Approval Button is clicked.
 *  @author Sai Shashank Poondla
 *  @storynumber GDASF-8480
 */
public without sharing class PMC_CPQ_FetchLatestPriceBeforeSubmission {
	/**
	 * @description This is the apex action that will be invoked from the flow.
	 * @param lstQuotes - list of quotes sent from the flow.
	 * @return getPriceResult - List of boolean results.
	 */
	@InvocableMethod(
		label='Get Price Callout on Submit for Approval'
		description='Triggers the CPI Interface to create quote, quote line and contract records in SAP'
		category='SBQQ__Quote__c'
	)
	public static List<Boolean> postInfoToCPI(List<SBQQ__Quote__c> lstQuotes) {
		try {
			return executeGetPriceCallout(lstQuotes);
		} catch (Exception e) {
			return new List<Boolean>{ false };
		}
	}

	/**
	 * @description This is the apex action that will be invoked from the LWC.
	 * @param lstQuotes - list of quotes sent from the LWC.
	 * @return getPriceResult - List of boolean results.
	 */
	@AuraEnabled(cacheable=false)
	public static List<Boolean> postInfoToCPIFromLWC(List<SBQQ__Quote__c> lstQuotes) {
		return executeGetPriceCallout(lstQuotes);
	}

	/**
	 * @description Common method that contains the actual logic for both flow and LWC calls.
	 * @param lstQuotes - list of quotes.
	 * @return getPriceResult - List of boolean results.
	 */
	private static List<Boolean> executeGetPriceCallout(List<SBQQ__Quote__c> lstQuotes) {
		Map<String, Schema.SObjectField> fieldMap = SBQQ__Quote__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();

		// Get all of the fields on the object
		Set<String> setFieldNames = fieldMap.keySet();
		list<String> lstFieldNames = new List<String>(setFieldNames);
		//Get price return
		List<Boolean> getPriceResult = new List<Boolean>();

		// Dynamic Query String. - Additional Record Tye details fetched for Region based Request 060
		Id quoteId = lstQuotes[0].Id;
		List<SBQQ__Quote__c> lstQuote = Database.query(
			'SELECT ' +
				String.escapeSingleQuotes(String.join(lstFieldNames, ',')) +
				', PMC_CPQ_SalesArea__r.PMC_SS_SalesArea__r.PMC_CPQ_SAPSalesOrganization__c FROM SBQQ__Quote__c where Id  = \'' +
				String.escapeSingleQuotes(quoteId) +
				'\''
		); // WITH SECURITY_ENFORCED');

		if (lstQuotes != null && !lstQuotes.isempty()) {
			// List<SBQQ__QuoteLine__c> lstQuoteLine = [
			// 	SELECT id, PMC_CPQ_FinalPricePerTonne__c
			// 	FROM SBQQ__QuoteLine__c
			// 	WHERE SBQQ__Quote__c = :lstQuotes[0].id
			// 	WITH SECURITY_ENFORCED
			// ];
			// List<SBQQ__QuoteLine__c> updateOriginalPrice = new List<SBQQ__QuoteLine__c>();

			// for (SBQQ__QuoteLine__c quoteLine : lstQuoteLine) {
			// 	if (quoteLine.PMC_CPQ_FinalPricePerTonne__c != null) {
			// 		quoteLine.PMC_CPQ_FinalPricePerTon__c = quoteLine.PMC_CPQ_FinalPricePerTonne__c;
			// 		updateOriginalPrice.add(quoteLine);
			// 	}
			// }

			String strInterface = 'ProductsExternalPricing';
			PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(strInterface);
			String strEndpoint = strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c;
			HttpResponse response = PMC_CPQ_GetPriceOnQuickSave.makeCalloutRequest(lstQuote, strEndpoint);
			String getPricesStatus;
			SBQQ.TriggerControl.disable();
			if (response.getStatusCode() != 200 && response.getStatusCode() != 201) {
				getPriceResult.add(false);
				if (!Test.isRunningTest()) {
					update new SBQQ__Quote__c(Id = lstQuotes[0].Id, Get_Prices_Status__c = 'Failed');
					throw new CustomException('Error in Get Price Callout: ' + response.getStatus());
				}
			} else {
				update new SBQQ__Quote__c(Id = lstQuotes[0].Id, Get_Prices_Status__c = 'Approval In Progress');
				getPriceResult.add(true);
			}
			SBQQ.TriggerControl.enable();
			// if (response != null && (Schema.sObjectType.SBQQ__QuoteLine__c.isAccessible() || Schema.sObjectType.SBQQ__QuoteLine__c.isUpdateable())) {
			// 	try {
			// 		DataBase.update(updateOriginalPrice);
			// 	} catch (DmlException objException) {
			// 		PMC_ErrorLogClass.processException(objException);
			// 	}

			// 	PMC_CPQ_GetPriceResponseParsing.parseJSONGetPriceInterface(lstQuotes, response, strEndpoint);

			// }
		}

		return getPriceResult;
	}
}