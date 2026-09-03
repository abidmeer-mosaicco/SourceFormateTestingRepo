/** @description This is a utility class for external callouts.
 *  @author Prakhar, Vignesh
 *  @storynumber GDASF-6987, 9437
 *  @Storynumber GDASF-6229 - Vignesh updated for cloned quote - Get Price banner display
 */
public with sharing class PMC_CPQ_GetPriceResponseParsing implements Database.AllowsCallouts {
	public static Boolean getPriceCalloutComplete = false;
	static final String STRING_INTEGRATIONSTATUSERROR = 'Error';
	static final String STRING_INTEGRATIONSTATUSSUCCESS = 'Success';
	static final String STRING_GETPRICEPREFIX = 'Get Price: ';
	static final Integer INT_STATUSCODE200 = 200;
	static final Integer INT_STATUSCODE201 = 201;
	static Exception objException;
	static final List<Integer> LISTINT_SUCCESSCODES = new List<Integer>{ INT_STATUSCODE200, INT_STATUSCODE201 };
	static HttpRequest request = new HttpRequest();
	static HttpResponse response;
	static List<PMC_CPQ_TransactionLog__c> lstTransactionLogs;
	static List<PMC_CPQ_IntegrationFieldMap__mdt> lstPriceCondMap = new List<PMC_CPQ_IntegrationFieldMap__mdt>();
	static List<PMC_CPQ_IntegrationFieldMap__mdt> lstItemMap = new List<PMC_CPQ_IntegrationFieldMap__mdt>();
	static List<String> ls = new List<String>{ '', null };

	public static void setIntegrationFieldMap(List<PMC_CPQ_IntegrationFieldMap__mdt> newValue) {
			lstItemMap = newValue;
	}

	/**
	 * @description Parses through the response body and populates Integration fields on the quote.
	 * @param lstQuotes - List of quotes.
	 * @param response - response received from the endpoint.
	 * @param strEndpoint - Endpoint that the HttpRequest will hit.
	 */
	public static void parseJSONGetPriceInterface(List<SBQQ__Quote__c> lstQuotes, HttpResponse response, String strEndpoint) {
		String strJSONResponseBody = response.getBody();

		SBQQ__Quote__c objQuote = lstQuotes[0];
		Map<String, String> mapTransactionLogFields = new Map<String, String>();
		mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c', STRING_INTEGRATIONSTATUSERROR);
		mapTransactionLogFields.put('PMC_CPQ_InterfaceURL__c', strEndpoint);
		mapTransactionLogFields.put('PMC_CPQ_RequestBody__c', PMC_CPQ_CPIRemoteCalloutUtilityClass.request.getBody());
		mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c', strJSONResponseBody);

		if (LISTINT_SUCCESSCODES.contains(response.getStatusCode())) {
			//status code returned is 200
			try {
				//responseProcess(lstQuotes, response);
				objQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSSUCCESS;
				objQuote.Get_Prices_Status__c = 'In Progress';
				objQuote.PMC_CPQ_IntegrationMessage__c = STRING_GETPRICEPREFIX + 'Wainting for SAP response...';
				//Adding below assignment as part of GDASF-6229
				objQuote.PMC_CPQ_GetPriceCallComplete__c = true;
				getPriceCalloutComplete = true;

				mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c', STRING_INTEGRATIONSTATUSSUCCESS);
			} catch (Exception e) {
				//Exception caused due to inablitiy to parse through response.
				objQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
				objQuote.Get_Prices_Status__c = 'Failed';
				objQuote.PMC_CPQ_IntegrationMessage__c = STRING_GETPRICEPREFIX + e.getMessage();
				//Adding below If condition and assignment as part of GDASF-6229
				objQuote.PMC_CPQ_GetPriceCallComplete__c = ((objQuote.PMC_CPQ_GetPriceCallComplete__c != true) ? false : true);
				getPriceCalloutComplete = false;
			}
		} else if (response.getStatusCode() != 500) { //status code returned is not 200
			objQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
			objQuote.Get_Prices_Status__c = 'Failed';

			// Extract and convert error message via refactored helper
			String rawError = extractRawErrorMessage(response);
			List<String> lstErrorMsg = new List<String>{ rawError };
			objQuote.PMC_CPQ_IntegrationMessage__c =
				STRING_GETPRICEPREFIX + PMC_CPQ_ConvertErrorMessageClass.convertToUserFriendlyMsg(lstErrorMsg)[0];

			//Adding below If condition and assignment as part of GDASF-6229
			objQuote.PMC_CPQ_GetPriceCallComplete__c = ((objQuote.PMC_CPQ_GetPriceCallComplete__c != true) ? false : true);
			getPriceCalloutComplete = false;
		} else {
			objQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
			objQuote.Get_Prices_Status__c = 'Failed';
			objQuote.PMC_CPQ_IntegrationMessage__c = STRING_GETPRICEPREFIX + STRING_INTEGRATIONSTATUSERROR;

			//Adding below If condition and assignment as part of GDASF-6229
			objQuote.PMC_CPQ_GetPriceCallComplete__c = ((objQuote.PMC_CPQ_GetPriceCallComplete__c != true) ? false : true);
			getPriceCalloutComplete = false;
		}

		try {
			update lstQuotes;

			lstTransactionLogs = PMC_CPQ_TransactionLogUtilityClass.addTransactionLog(mapTransactionLogFields);
			PMC_CPQ_TransactionLogUtilityClass.insertTransactionLogs(lstTransactionLogs);
		} finally {}
	}

	/**
	 * @description Parses through the response body and populates Integration fields on the quote.
	 * @param lstQuotes - List of quotes.
	 * @param response - response received from the endpoint.
	 */
	public static void responseProcess(List<SBQQ__Quote__c> lstQuotes, HttpResponse response) {
		responseProcess(lstQuotes[0], (Map<String, Object>) JSON.deserializeUntyped(response.getBody()));
	}

	public static void responseProcess(SBQQ__Quote__c quoteRecord, Map<String, Object> untypedResponse) {
		System.debug('Parsed JSON Response (responseProcess): ' + JSON.serialize(untypedResponse));

		Map<String, Object> jsonResponse = (Map<String, Object>) ((Map<String, Object>) (untypedResponse).get('HeaderSet')).get('Header');

		List<SBQQ__QuoteLine__c> lstQuoteLines = [
			SELECT
				id,
				SBQQ__ListPrice__c,
				SBQQ__Number__c,
				SBQQ__Quote__c,
				PMC_CPQ_LastPricedDate__c,
				SBQQ__UpgradedSubscription__c,
				SBQQ__Quote__r.SBQQ__Type__c,
				SBQQ__Quote__r.PMC_CPQ_Region__c,
				PMC_CPQ_FinalPricePerTon__c,
				PMC_CPQ_FinalPricePerTonne__c
			FROM SBQQ__QuoteLine__c
			WHERE SBQQ__Quote__c = :(quoteRecord.Id)
		];

		List<Object> lstPriceCond = (List<Object>) ((Map<String, Object>) ((List<Object>) jsonResponse.get('Price_CondSet'))[0]).get('Price_Cond');

		PMC_CPQ_IntegrationFieldMap__mdt credLim = PMC_CPQ_IntegrationFieldMap__mdt.getInstance('CD1');
		PMC_CPQ_IntegrationFieldMap__mdt credExp = PMC_CPQ_IntegrationFieldMap__mdt.getInstance('CD2'); // Credit Records are being fetched manually to caputre credit details

		List<Object> lstItemR = (List<Object>) ((Map<String, Object>) jsonResponse.get('Item_RSet')).get('Item_R');

		// '' + null returns 'null' (string), not ''. The original check did not catch
		// this case and get('Credit_Limit')[0] threw NPE. Treat empty string or 'null'
		// as absent and also verify it is a Map before casting.
		String checkNullCred = '' + jsonResponse.get('Credit_LimitSet');
		Boolean boolHasCreditSet = (checkNullCred != '' && checkNullCred != 'null'
			&& jsonResponse.get('Credit_LimitSet') instanceof Map<String, Object>);
		quoteRecord
			.put(
				credLim.PMC_CPQ_ApexAPIName__c,
				(boolHasCreditSet
					? Decimal.valueOf(
							(String) (((Map<String, Object>) ((List<Object>) ((Map<String, Object>) jsonResponse.get('Credit_LimitSet'))
									.get('Credit_Limit'))[0])
								.get(credLim.PMC_CPQ_AttributeKey__c))
					  )
					: null)
			);
		quoteRecord
			.put(
				credExp.PMC_CPQ_ApexAPIName__c,
				(boolHasCreditSet
					? Decimal.valueOf(
							(String) (((Map<String, Object>) ((List<Object>) ((Map<String, Object>) jsonResponse.get('Credit_LimitSet'))
									.get('Credit_Limit'))[0])
								.get(credExp.PMC_CPQ_AttributeKey__c))
					  )
					: null)
			);

		Map<String, SBQQ__QuoteLine__c> mapQuoteLine = new Map<String, SBQQ__QuoteLine__c>(); //map of Item_number and respective QuoteLine
		for (SBQQ__QuoteLine__c qtline : lstQuoteLines) {
			mapQuoteLine.put(('' + qtline.SBQQ__Number__c), qtline);
		}
		SBQQ__QuoteLine__c qtLine = new SBQQ__QuoteLine__c();
		filterResponseMap();
		parseItemRUpdateQuoteLine(lstItemR, mapQuoteLine);
		parsePriceCondUpdateQuoteLine(lstPriceCond, mapQuoteLine);
		// '' + null returns 'null', not ''. Also verify it is a Map before casting.
		checkNullCred = '' + jsonResponse.get('Raw_MaterialSet');
		if (checkNullCred != '' && checkNullCred != 'null'
			&& jsonResponse.get('Raw_MaterialSet') instanceof Map<String, Object>) {
			PMC_CPQ_GetPriceUtilityClass.makeRawMaterialRecords(
				JSON.serialize(((Map<String, Object>) jsonResponse.get('Raw_MaterialSet')).get('Raw_Material')),
				quoteRecord.Id
			);
		}

		// IMPORTANT: SBQQ.TriggerControl.disable() suppresses the CPQ trigger-calc
		// on this DML. The single calculation is invoked explicitly by SetPriceResource
		// via PMC_CPQ_QuoteCalcService (Calculate Quote API with callbackClass) after
		// the SAP prices have been consolidated. Before this suppression, this update
		// enqueued a stale QueueableCalculatorService job (snapshot Status=Draft)
		// that reverted the status after the flow's auto-approval.
		SBQQ.TriggerControl.disable();
		try {
			Database.update(lstQuoteLines, false);
		} finally {
			SBQQ.TriggerControl.enable();
		}
	}
	/**
	 * @description filter through integration field map
	 */
	public static void filterResponseMap() {
		List<PMC_CPQ_IntegrationFieldMap__mdt> lstCompParseMap = [
			SELECT MasterLabel, PMC_CPQ_ApexAPIName__c, PMC_CPQ_DataType__c, PMC_CPQ_SFObject__c, PMC_CPQ_AttributeKey__c
			FROM PMC_CPQ_IntegrationFieldMap__mdt
			WHERE
				PMC_CPQ_SFObject__c IN ('Item_R', 'Price_Cond')
				AND PMC_CPQ_IsLookup__c = FALSE
				AND PMC_CPQ_AttributeKey__c != NULL
				AND PMC_CPQ_ApexAPIName__c != NULL
			ORDER BY MasterLabel ASC
		];
		for (PMC_CPQ_IntegrationFieldMap__mdt s : lstCompParseMap) {
			if (s.PMC_CPQ_SFObject__c == 'Price_Cond') {
				lstPriceCondMap.add(s);
				continue;
			}
			lstItemMap.add(s);
		}
	}
	/**
	 * @description Parses through the response body and populates Integration fields on the quote.
	 * @param lstPriceCond - Price Condition block from Response
	 * @param mapQuoteLine - QuoteLine record
	 */
	public static void parsePriceCondUpdateQuoteLine(List<Object> lstPriceCond, Map<String, SBQQ__QuoteLine__c> mapQuoteLine) {
		String strAPIName = '';
		SBQQ__QuoteLine__c qtLine = new SBQQ__QuoteLine__c();
		//PMC_CPQ_IntegrationFieldMap__mdt validStrtDt = PMC_CPQ_IntegrationFieldMap__mdt.getInstance('D1');
		//PMC_CPQ_IntegrationFieldMap__mdt validEndDt = PMC_CPQ_IntegrationFieldMap__mdt.getInstance('D2');

		Map<String, String> mapPriceCond = new Map<String, String>(); //map of CondType and Apex API Name
		Map<String, String> mapDataTypePrcCond = new Map<String, String>();
		for (PMC_CPQ_IntegrationFieldMap__mdt priceCondLine : lstPriceCondMap) {
			mapPriceCond.put(priceCondLine.PMC_CPQ_AttributeKey__c, priceCondLine.PMC_CPQ_ApexAPIName__c);
			mapDataTypePrcCond.put(priceCondLine.PMC_CPQ_AttributeKey__c, priceCondLine.PMC_CPQ_DataType__c);
		}

		Map<String, Object> mapResponseLine = new Map<String, Object>();
		for (Object responseKey : lstPriceCond) {
			mapResponseLine = (Map<String, Object>) responseKey;
			strAPIName = mapPriceCond.get((String) mapResponseLine.get('CondType'));
			if (strAPIName == null) {
				continue;
			}
			qtLine = mapQuoteLine.get(('' + mapResponseLine.get('ItmNumber')));
			/*
            	if((qtLine.SBQQ__Quote__r.SBQQ__Type__c != 'Amendment')||(qtLine.SBQQ__UpgradedSubscription__c == null)){	// GDASF-9425 - GDASF-18763
                    qtLine.put('PMC_CPQ_LastPricedDate__c', (((String)mapResponseLine.get('CondType') == 'ZLST')?System.now():qtLine.get('PMC_CPQ_LastPricedDate__c')));
            	}*/

			if (mapDataTypePrcCond.get((String) mapResponseLine.get('CondType')) == 'Decimal') {
				qtLine.put(strAPIName, Decimal.valueOf((String) mapResponseLine.get('CondValue')));
				continue;
			} /*else if((mapDataTypePrcCond.get((String)mapResponseLine.get('CondType')) == 'Date')&&(mapResponseLine.get('CondValue')!=null)){
                        qtLine.put(strAPIName, Date.valueOf((String)mapResponseLine.get('CondValue')));
                    continue;
                }*/
			qtLine.put(strAPIName, mapResponseLine.get('CondValue'));
		}
	}
	/**
	 * @description Parses through the response body and populates Integration fields on the quote.
	 * @param lstItemR - response line from EndPoint
	 * @param mapQuoteLine - QuoteLine record
	 */
	public static void parseItemRUpdateQuoteLine(List<Object> lstItemR, Map<String, SBQQ__QuoteLine__c> mapQuoteLine) {
		String strAPIName = '';
		Map<String, String> mapItemR = new Map<String, String>(); //map of Key and Apex API name
		Map<String, Object> mapResponseLine = new Map<String, Object>();
		for (PMC_CPQ_IntegrationFieldMap__mdt itmLine : lstItemMap) {
			mapItemR.put(itmLine.PMC_CPQ_AttributeKey__c, itmLine.PMC_CPQ_ApexAPIName__c);
		}
		for (Object responseKey : lstItemR) {
			mapResponseLine = (Map<String, Object>) responseKey;
			SBQQ__QuoteLine__c qtLine = mapQuoteLine.get(('' + mapResponseLine.get('ItmNumber')));
			if (qtLine.SBQQ__Quote__r.PMC_CPQ_Region__c == 'Brazil') {
				qtLine.PMC_CPQ_FinalPricePerTonne__c = null;
				qtLine.PMC_CPQ_InterestFees__c = null;
				qtLine.PMC_CPQ_VCOAdjustment__c = null;
				qtLine.PMC_CPQ_EstTax__c = null;
				qtLine.PMC_CPQ_ReplacementCost__c = null;
				qtLine.PMC_CPQ_ExchangeRate__c = null;
				qtLine.SBQQ__ListPrice__c = null;
				qtLine.PMC_CPQ_NetUnitPrice__c = null;
				qtLine.PMC_CPQ_PriceGuidanceFloor__c = null;
				qtLine.PMC_CPQ_PriceGuidanceTarget__c = null;
				qtLine.PMC_CPQ_PriceGuidanceCeiling__c = null;
				qtLine.PMC_CPQ_CommissionCurrency__c = null;
				qtLine.PMC_CPQ_InterestPeriod__c = null;
				qtLine.PMC_CPQ_Interest__c = null;
				qtLine.PMC_CPQ_ReplacementMargin__c = null;
			}
			for (PMC_CPQ_IntegrationFieldMap__mdt add : lstItemMap) {
				strAPIName = mapItemR.get((String) add.get('PMC_CPQ_AttributeKey__c'));
				if (add.PMC_CPQ_DataType__c == 'Date') {
					qtLine.put(
						strAPIName,
						(mapResponseLine.containsKey((String) add.get('PMC_CPQ_AttributeKey__c')) &&
							(!(ls.contains((String) mapResponseLine.get((String) add.get('PMC_CPQ_AttributeKey__c'))))))
							? (Date.valueOf((String) mapResponseLine.get((String) add.get('PMC_CPQ_AttributeKey__c'))))
							: null
					);
					continue;
				} else if (add.PMC_CPQ_DataType__c == 'Decimal') {
					qtLine.put(strAPIName, Decimal.valueOf((String) mapResponseLine.get((String) add.get('PMC_CPQ_AttributeKey__c'))));
					continue;
				} else if (add.PMC_CPQ_DataType__c == 'Boolean') {
					String strBoolValue = (String) mapResponseLine.get((String) add.get('PMC_CPQ_AttributeKey__c'));
					qtLine.put(strAPIName, strBoolValue == null ? null : Boolean.valueOf(strBoolValue));
					continue;
				}
				qtLine.put(strAPIName, mapResponseLine.get((String) add.get('PMC_CPQ_AttributeKey__c')));
			}
		}
	}
	/**
	 * @description Core logic for updating quote and preparing transaction log. Used by both parseJSONGetPriceInterface and prepareQuoteUpdateAndLog.
	 * @param lstQuotes - List of quotes (should contain one quote)
	 * @param response - The HttpResponse from the callout
	 * @param strEndpoint - The endpoint string
	 * @return PMC_CPQ_TransactionLog__c - The transaction log object (not inserted)
	 */
	private static PMC_CPQ_TransactionLog__c handleQuoteResponseUpdateAndLog(
		List<SBQQ__Quote__c> lstQuotes,
		HttpResponse response,
		String strEndpoint
	) {
		SBQQ__Quote__c objQuote = lstQuotes[0];
		String strJSONResponseBody = response.getBody();
		Map<String, String> mapTransactionLogFields = new Map<String, String>();
		mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c', STRING_INTEGRATIONSTATUSERROR);
		mapTransactionLogFields.put('PMC_CPQ_InterfaceURL__c', strEndpoint);
		mapTransactionLogFields.put('PMC_CPQ_RequestBody__c', PMC_CPQ_CPIRemoteCalloutUtilityClass.request.getBody());
		mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c', strJSONResponseBody);

		if (LISTINT_SUCCESSCODES.contains(response.getStatusCode())) {
			try {
				objQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSSUCCESS;
				objQuote.Get_Prices_Status__c = 'In Progress';
				objQuote.PMC_CPQ_IntegrationMessage__c = STRING_GETPRICEPREFIX + 'Wainting for SAP response...';
				objQuote.PMC_CPQ_GetPriceCallComplete__c = true;
				getPriceCalloutComplete = true;
				mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c', STRING_INTEGRATIONSTATUSSUCCESS);
			} catch (Exception e) {
				objQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
				objQuote.Get_Prices_Status__c = 'Failed';
				objQuote.PMC_CPQ_IntegrationMessage__c = STRING_GETPRICEPREFIX + e.getMessage();
				objQuote.PMC_CPQ_GetPriceCallComplete__c = ((objQuote.PMC_CPQ_GetPriceCallComplete__c != true) ? false : true);
				getPriceCalloutComplete = false;
			}
		} else if (response.getStatusCode() != 500) {
			objQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
			objQuote.Get_Prices_Status__c = 'Failed';
			String rawErr = extractRawErrorMessage(response);
			List<String> lstErr = new List<String>{ rawErr };
			objQuote.PMC_CPQ_IntegrationMessage__c = STRING_GETPRICEPREFIX + PMC_CPQ_ConvertErrorMessageClass.convertToUserFriendlyMsg(lstErr)[0];
			objQuote.PMC_CPQ_GetPriceCallComplete__c = ((objQuote.PMC_CPQ_GetPriceCallComplete__c != true) ? false : true);
			getPriceCalloutComplete = false;
		} else {
			objQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
			objQuote.Get_Prices_Status__c = 'Failed';
			objQuote.PMC_CPQ_IntegrationMessage__c = STRING_GETPRICEPREFIX + STRING_INTEGRATIONSTATUSERROR;
			objQuote.PMC_CPQ_GetPriceCallComplete__c = ((objQuote.PMC_CPQ_GetPriceCallComplete__c != true) ? false : true);
			getPriceCalloutComplete = false;
		}
		// Return the log object (do not insert)
		PMC_CPQ_TransactionLog__c log = new PMC_CPQ_TransactionLog__c();
		log.PMC_CPQ_IntegrationStatus__c = mapTransactionLogFields.get('PMC_CPQ_IntegrationStatus__c');
		log.PMC_CPQ_InterfaceURL__c = mapTransactionLogFields.get('PMC_CPQ_InterfaceURL__c');
		log.PMC_CPQ_RequestBody__c = mapTransactionLogFields.get('PMC_CPQ_RequestBody__c');
		log.PMC_CPQ_ResponseBody__c = mapTransactionLogFields.get('PMC_CPQ_ResponseBody__c').abbreviate(131065);
		return log;
	}

	public static PMC_CPQ_TransactionLog__c prepareQuoteUpdateAndLog(List<SBQQ__Quote__c> lstQuote, HttpResponse response, String strEndpoint) {
		return handleQuoteResponseUpdateAndLog(lstQuote, response, strEndpoint);
	}

	/**
	 * @description Extracts the raw SAP error message from a non-500 error HttpResponse. Returns a default label if structure not present.
	 * @param response HttpResponse from SAP
	 * @return Raw error message String (unconverted)
	 */
	@TestVisible
	private static String extractRawErrorMessage(HttpResponse response) {
		if (response == null || String.isBlank(response.getBody())) {
			return System.Label.PMC_CPQ_GetPriceCalloutFailedNoResponse;
		}
		try {
			Map<String, Object> top = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
			if (!top.containsKey('error'))
				return System.Label.PMC_CPQ_GetPriceCalloutFailedNoResponse;
			Map<String, Object> error = (Map<String, Object>) top.get('error');
			if (!error.containsKey('innererror'))
				return System.Label.PMC_CPQ_GetPriceCalloutFailedNoResponse;
			Map<String, Object> innerError = (Map<String, Object>) error.get('innererror');
			Object errDetailsObj = innerError.get('errordetails');
			if (errDetailsObj == null)
				return System.Label.PMC_CPQ_GetPriceCalloutFailedNoResponse;
			Map<String, Object> errDetails = (Map<String, Object>) errDetailsObj;
			List<Object> detailList = (List<Object>) errDetails.get('errordetail');
			if (detailList == null || detailList.isEmpty())
				return System.Label.PMC_CPQ_GetPriceCalloutFailedNoResponse;
			Map<String, Object> first = (Map<String, Object>) detailList[0];
			String msg = (String) first.get('message');
			return String.isNotBlank(msg) ? msg : System.Label.PMC_CPQ_GetPriceCalloutFailedNoResponse;
		} catch (Exception e) {
			return System.Label.PMC_CPQ_GetPriceCalloutFailedNoResponse;
		}
	}
}