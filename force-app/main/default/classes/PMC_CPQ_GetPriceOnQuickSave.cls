/** @description This class will be called FROM a flow whenever a Quote record is updated and saved.
 *	@author Prakhar, Vignesh
 *	@storynumber GDASF-6819
 */
public without sharing class PMC_CPQ_GetPriceOnQuickSave implements Database.AllowsCallouts {
	static String strExceptionMsg = '';
	public static String strErrorMessage = '<br/>';
	static Map<Integer, String> salesOrg = new Map<Integer, String>{
		1 => 'PMC_CPQ_DomesticNA',
		2 => 'PMC_CPQ_DomesticNA',
		4 => 'PMC_CPQ_DomesticBR'
	};

	static Map<String, PMC_CPQ_IntegrationFieldMap__mdt> quoteFieldsMap = new Map<String, PMC_CPQ_IntegrationFieldMap__mdt>();
	static Map<String, PMC_CPQ_IntegrationFieldMap__mdt> quoteLineFieldsMap = new Map<String, PMC_CPQ_IntegrationFieldMap__mdt>();
	static Set<String> quoteFields = new Set<String>();
	static Set<String> quoteLineFields = new Set<String>();

	/**
	 * @description Method to filter list for integration mapping.
	 * @param strRegion - Region of Quotes
	 */
	public static void filterMapValues(String strRegion) {
		strRegion = salesOrg.get(Integer.valueOf(strRegion.split('')[0]));
		List<PMC_CPQ_IntegrationFieldMap__mdt> lstIntegration = [
			SELECT
				MasterLabel,
				PMC_CPQ_ApexAPIName__c,
				PMC_CPQ_SFObject__c,
				PMC_CPQ_IsMandatory__c,
				PMC_CPQ_ErrorMessage__c,
				PMC_CPQ_AttributeKey__c,
				PMC_CPQ_DataType__c,
				PMC_CPQ_IsLookup__c
			FROM PMC_CPQ_IntegrationFieldMap__mdt
			WHERE
				PMC_CPQ_ApexAPIName__c != NULL
				AND PMC_CPQ_SFObject__c IN ('SBQQ__Quote__c', 'SBQQ__QuoteLine__c')
				AND (PMC_CPQ_DataType__c = NULL
				OR PMC_CPQ_DataType__c = :strRegion)
			ORDER BY MasterLabel ASC
		];

		for (PMC_CPQ_IntegrationFieldMap__mdt mapVal : lstIntegration) {
			if (mapVal.PMC_CPQ_SFObject__c == 'SBQQ__Quote__c') {
				quoteFieldsMap.put(mapVal.PMC_CPQ_AttributeKey__c, mapVal);
				quoteFields.add(mapVal.PMC_CPQ_ApexAPIName__c);
			} else {
				quoteLineFieldsMap.put(mapVal.PMC_CPQ_AttributeKey__c, mapVal);
				quoteLineFields.add(mapVal.PMC_CPQ_ApexAPIName__c);
			}
		}
	}

	/**
	 * @description This class will make a callout to CPI.
	 * @param lstQuotes - List of quotes.
	 * @param strEndpoint - Endpoint that the HttpRequest will hit.
	 * @return response - HttpResponse Object returned FROM Endpoint.
	 */
	public static HttpResponse makeCalloutRequest(List<SBQQ__Quote__c> lstQuotes, String strEndpoint) {
		Integer i = 0;

		filterMapValues(lstQuotes[0].PMC_CPQ_SalesArea__r.PMC_SS_SalesArea__r.PMC_CPQ_SAPSalesOrganization__c);
		try {
			JSONGenerator jsonReq = JSON.createGenerator(false);
			jsonReq.writeStartObject();
			SBQQ__Quote__c qt = getQuote(lstQuotes[0].Id);
			jsonReq = quoteJsonGeneration(qT, jsonReq);

			List<Map<String, String>> lstLineItem = new List<Map<String, String>>();
			for (SObject quoteLine : getQuoteLines(lstQuotes[0].Id)) {
				// i++;
				lstLineItem.add(quoteLineJSONGen(quoteLine));
			}
			jsonReq.writeFieldName('LineItemList');
			jsonReq.writeObject(lstLineItem);
			jsonReq.writeEndObject();
			if (strErrorMessage == '<br/>') {
				String strRequest = jsonReq.getAsString();
				System.debug('strRequest:::' + strRequest);
				HttpResponse response = PMC_CPQ_CPIRemoteCalloutUtilityClass.sendCalloutRequest(
					'GET',
					'callout:PMC_CPQ_NamedCredential' + strEndpoint,
					PMC_CPQ_GetPriceUtilityClass.stringProcess(strRequest)
				);
				return response;
			}
			return null;
		} catch (Exception e) {
			PMC_ErrorLogClass.processException(e);
			strExceptionMsg = e.getMessage();
		} finally {
			PMC_CPQ_GetPriceUtilityClass.errorLogExit(lstQuotes, PMC_CPQ_CPIRemoteCalloutUtilityClass.strExceptionMsg);
		}
		return null;
	}
	/**
	 * @description Returns the map of quote line after adding fields.
	 * @param quoteLineFieldsMap - Map for all the fields that have to be used in the JSON Request.
	 * @param quoteLine - Argument of type Object that may be of type Quote or Aggregate result all similar to Quote.
	 * @param mapQuoteLineDet - Reference of the jsonReq Object that is to have the additional fields that are in the Quote Field Map.
	 * @return mapQuoteLineDet - Returns map after adding values
	 */
	public static Map<String, String> quoteLineJSONGen(SObject quoteLine) {
		Map<String, String> mapQuoteLineDet = new Map<String, String>();
		String strLocError = '';
		for (PMC_CPQ_IntegrationFieldMap__mdt integrationFieldMap : quoteLineFieldsMap.values()) {
			String fieldValue = getFieldValue(quoteLine, integrationFieldMap.PMC_CPQ_ApexAPIName__c);
			mapQuoteLineDet.put(integrationFieldMap.PMC_CPQ_AttributeKey__c, fieldValue);
			strLocError =
				strLocError +
				(String.isBlank(fieldValue) && integrationFieldMap.PMC_CPQ_IsMandatory__c
					? ('-' + integrationFieldMap.PMC_CPQ_ErrorMessage__c + '<br/>')
					: '');
		}

		strErrorMessage = (strLocError != ''
			? (strErrorMessage + '<br/>QuoteLine ' + (((SBQQ__QuoteLine__c) quoteLine).get('SBQQ__Number__c')) + ' :<br/>' + strLocError)
			: strErrorMessage);

		return mapQuoteLineDet;
	}
	/**
	 * @description Returns the JSON Generator Object after adding fields based on if it is a lookup or not.
	 * @param quoteFieldsMap - Map for all the fields that have to be used in the JSON Request.
	 * @param quoteObject - Argument of type Object that may be of type Quote or Aggregate result all similar to Quote.
	 * @param jsonReq - Reference of the jsonReq Object that is to have the additional fields that are in the Quote Field Map.
	 * @return qtLines - Returns list of Quote Lines of the quote in argument
	 */
	public static JSONGenerator quoteJsonGeneration(Object quoteObject, JSONGenerator jsonReq) {
		String strPlaceHolderValue = '';
		SBQQ__Quote__c qT = (SBQQ__Quote__c) quoteObject;
		for (PMC_CPQ_IntegrationFieldMap__mdt value : quoteFieldsMap.values()) {
			jsonReq.writeFieldName(value.PMC_CPQ_AttributeKey__c);
			strPlaceHolderValue = getFieldValue(qT, value.PMC_CPQ_ApexAPIName__c);
			strErrorMessage =
				strErrorMessage + (((strPlaceHolderValue == '') && (value.PMC_CPQ_IsMandatory__c)) ? (value.PMC_CPQ_ErrorMessage__c + '<br/>') : '');
			jsonReq.writeObject(strPlaceHolderValue);
		}
		return jsonReq;
	}

	public static String getFieldValue(SObject record, String fieldPath) {
		if (record == null || String.isBlank(fieldPath)) {
			return '';
		}
		String result;
		if (fieldPath.contains('.')) {
			List<String> parts = fieldPath.split('\\.', 2); // Split into 2 parts: [relationship, remainingPath]
			String relationshipName = parts[0];
			String remainingPath = parts[1];
			SObject parentRecord = record.getSObject(relationshipName);
			if (parentRecord != null) {
				result = getFieldValue(parentRecord, remainingPath);
			}
		} else {
			result = String.valueOf(record.get(fieldPath));
		}
		return String.isBlank(result) ? '' : result;
	}

	/**
	 * @description Returns all the quotelines related to the Quote passed in the method
	 * @param queryQuote - Quote for which quote lines has to be fetched
	 * @param queryParam - Contains part of the query on Quote Line object
	 * @return qtLines - Returns list of Quote Lines of the quote in argument
	 */
	public static Map<String, List<Object>> getQuoteLines(Id queryQuote, String queryParam) {
		Map<String, List<Object>> bulkifiedQL = new Map<String, List<Object>>();
		String quoteLineQuery =
			'SELECT ' +
			String.escapeSingleQuotes(queryParam) +
			' FROM SBQQ__QuoteLine__c where SBQQ__Quote__c	= \'' +
			queryQuote +
			'\' ORDER BY Id ASC';
		List<SBQQ__QuoteLine__c> qtLines = Database.query(quoteLineQuery);
		bulkifiedQL.put(queryQuote, qtLines);
		return bulkifiedQL;
	}

	public static SBQQ__Quote__c getQuote(Id queryQuote) {
		List<String> fields = new List<String>(quoteFields);
		return Database.query(
			'SELECT ' + String.escapeSingleQuotes(String.join(fields, ', ')) + ' FROM SBQQ__Quote__c WHERE Id	= \'' + queryQuote + '\' LIMIT 1'
		);
	}

	public static List<SBQQ__QuoteLine__c> getQuoteLines(Id queryQuote) {
		List<String> fields = new List<String>(quoteLineFields);
		if (!quoteLineFields.contains('SBQQ__Number__c')) {
			fields.add('SBQQ__Number__c');
		}
		return Database.query(
			'SELECT ' +
				String.escapeSingleQuotes(String.join(fields, ', ')) +
				' FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c	= \'' +
				queryQuote +
				'\' ORDER BY Id ASC'
		);
	}
}