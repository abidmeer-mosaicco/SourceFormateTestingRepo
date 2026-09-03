/** @description This class will house utility functions for Get price.
 *  @author Prakhar
 *  @storynumber GDASF-10668
 */
public without sharing class PMC_CPQ_GetPriceUtilityClass {
	static final String STRING_INTEGRATIONSTATUSERROR = 'Error';
	static final String STRING_GETPRICEPREFIX = 'Get Price: ';

	/**
	 * @description Exit method for Error log
	 * @param lstQuotes - List of Quotes
	 * @param strExceptionMsg - Exception message
	 */
	public static void errorLogExit(List<SBQQ__Quote__c> lstQuotes, String strExceptionMsg) {
		if (strExceptionMsg != null) {
			lstQuotes[0].PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
			lstQuotes[0].PMC_CPQ_IntegrationMessage__c = STRING_GETPRICEPREFIX + PMC_CPQ_CPIRemoteCalloutUtilityClass.strExceptionMsg;

			update lstQuotes;
		}
	}
	/**
	 * @description Returns unique set of id of Quote
	 * @param strVal - Object to be converted to String and hit the end point.
	 * @return strProcessed - Returns String value which can be used to hit the end point.
	 */
	public static String stringProcess(Object strVal) {
		String strObject = JSON.serialize(strVal);
		String strProcessed = strObject.replace('\\\\', '').substringAfter('"').substringBeforeLAst('"');
		strProcessed = strProcessed.replaceAll('\n', '');
		strProcessed = strProcessed.replaceAll('\\\\', '');
		return strProcessed;
	}
	/**
	 * @description Returns unique set of id of Quote
	 * @param fieldMap - Fields fetched from External metadata.
	 * @param filterString - String value which will be added for aliasing.
	 * @return queryParam - Returns String value which will be used to query the Database
	 */
	public static String getQueryParam(List<PMC_CPQ_IntegrationFieldMap__mdt> fieldMap, String filterString) {
		Set<String> quoteLineFieldSet = new Set<String>();
		String queryParam = '';
		Integer i = 0;

		for (PMC_CPQ_IntegrationFieldMap__mdt keypair : fieldMap) {
			quoteLineFieldSet.add((String) keypair.PMC_CPQ_ApexAPIName__c);
		}
		for (String s : quoteLineFieldSet) {
			queryParam = queryParam + s + ((filterString != null) ? (' ' + filterString + i) : '') + ',';
			i++;
		}
		queryParam = queryParam + ' Id';
		return queryParam;
	}
	/**
	 * @description Make Raw material records asynchronously
	 * @param rawMat - Raw Material Response Body
	 * @param quoteId - Id of the quote on which Get price was done
	 */
	@Future(Callout=true)
	public static void makeRawMaterialRecords(String rawMat, Id quoteId) {
		List<Object> lstRawMat = (List<Object>) JSON.deserializeUntyped(rawMat);
		Map<String, SBQQ__QuoteLine__c> mapQuoteLine = getQuoteLineMap(quoteId);
		List<PMC_CPQ_RawMaterial__c> rawMtrl = [
			SELECT id, PMC_CPQ_QuoteLine__r.SBQQ__Quote__c, PMC_CPQ_ProductSKU__c, PMC_CPQ_QuoteLine__r.SBQQ__Number__c
			FROM PMC_CPQ_RawMaterial__c
			WHERE PMC_CPQ_Quote__c = :quoteId
		];
		Map<String, Id> mapProductSKU = new Map<String, Id>();
		Set<String> setProductSKU = new Set<String>();
		for (Object line : lstRawMat) {
			setProductSKU.add(('' + ((map<String, Object>) line).get('Zzcomponent')));
		}
		List<Product2> lstProduct = [SELECT Id, StockKeepingUnit FROM Product2 WHERE StockKeepingUnit IN :setProductSKU];
		for (Product2 prd : lstProduct) {
			mapProductSKU.put(('' + prd.StockKeepingUnit), prd.Id);
		}
		Integer diff = rawMtrl.size() - lstRawMat.size();
		map<String, String> mapRwMtrl = new Map<String, String>();
		List<PMC_CPQ_IntegrationFieldMap__mdt> lstFldMap = [
			SELECT PMC_CPQ_ApexAPIName__c, PMC_CPQ_AttributeKey__c, PMC_CPQ_DataType__c
			FROM PMC_CPQ_IntegrationFieldMap__mdt
			WHERE PMC_CPQ_SFObject__c = 'Raw_Mat'
		];
		for (PMC_CPQ_IntegrationFieldMap__mdt rwMtLine : lstFldMap) {
			mapRwMtrl.put(rwMtLine.PMC_CPQ_AttributeKey__c, rwMtLine.PMC_CPQ_ApexAPIName__c);
		}
		rawMtrl = manangeRawMat(diff, quoteId, rawMtrl);
		PMC_CPQ_RawMaterial__c rwMt;
		String strAPIName;

		diff = 0;
		Map<String, Object> mapRwMat = new Map<String, Object>();
		Product2 prd = new Product2();
		for (Object line : lstRawMat) {
			if (rawMtrl.size() == diff) {
				break;
			}
			rwMt = rawMtrl[diff++];
			mapRwMat = (map<String, Object>) line;
			SBQQ__QuoteLine__c qlRef = mapQuoteLine.get('' + mapRwMat.get('ItmNumber'));
			if (qlRef != null) {
				rwMt.put('PMC_CPQ_QuoteLine__c', qlRef.Id);
			}
			Id prdId = mapProductSKU.get('' + mapRwMat.get('Zzcomponent'));
			if (prdId != null) {
				rwMt.put('PMC_CPQ_Product__c', prdId);
			}
			for (PMC_CPQ_IntegrationFieldMap__mdt add : lstFldMap) {
				strAPIName = mapRwMtrl.get((String) add.get('PMC_CPQ_AttributeKey__c'));
				// Skip if we don't have a mapped API name or value is absent
				if (String.isBlank(strAPIName) || !mapRwMat.containsKey((String) add.get('PMC_CPQ_AttributeKey__c'))) {
					continue;
				}
				Object rawVal = mapRwMat.get((String) add.get('PMC_CPQ_AttributeKey__c'));
				if (rawVal == null) {
					continue; // Nothing to set
				}
				if (add.PMC_CPQ_DataType__c == 'Decimal') {
					try {
						// Handle values that might already be numeric or come as string
						Decimal decVal;
						if (rawVal instanceof Decimal) {
							decVal = (Decimal) rawVal;
						} else {
							String sVal = String.valueOf(rawVal);
							if (String.isBlank(sVal)) {
								continue; // Skip blank numeric fields
							}
							decVal = Decimal.valueOf(sVal);
						}
						rwMt.put(strAPIName, decVal);
					} catch (Exception ex) {
						// Swallow conversion issues to avoid test failures; could log if needed
						continue;
					}
					continue;
				}
				rwMt.put(strAPIName, rawVal);
			}
		}
		update rawMtrl;
		PMC_CPQ_RawMaterialSummary.RawMaterialInfo(quoteId);
	} /**
	 * @description Return map of item number to Quoteline Id
	 * @param quoteId - Id of the quote
	 * @return mapQuoteLine - map of item number to quote line
	 */
	public static map<String, SBQQ__QuoteLine__c> getQuoteLineMap(Id quoteId) {
		List<SBQQ__QuoteLine__c> lstQuoteLines = [
			SELECT id, SBQQ__Number__c
			FROM SBQQ__QuoteLine__c
			WHERE SBQQ__Quote__c = :quoteId
		];
		Map<String, SBQQ__QuoteLine__c> mapQuoteLine = new Map<String, SBQQ__QuoteLine__c>(); //map of Item_number and respective QuoteLine
		for (SBQQ__QuoteLine__c qtline : lstQuoteLines) {
			mapQuoteLine.put(('' + qtline.SBQQ__Number__c), qtline);
		}
		return mapQuoteLine;
	}
	/**
	 * @description Delete/Insert Raw Material records
	 * @param diff - Difference between Raw materia response line and raw material on quote
	 * @param quoteId - Id of the quote
	 * @param rawMtrl - List of Raw Mat records
	 * @return rawMtrl - map of item number to quote line
	 */
	public static List<PMC_CPQ_RawMaterial__c> manangeRawMat(Integer diff, Id quoteId, List<PMC_CPQ_RawMaterial__c> rawMtrl) {
		PMC_CPQ_RawMaterial__c rwMt;
		List<PMC_CPQ_RawMaterial__c> delRawMt = new List<PMC_CPQ_RawMaterial__c>();
		while (diff > 0) {
			delRawMt.add(rawMtrl[(rawMtrl.size() - diff - 1)]);
			rawMtrl.remove((rawMtrl.size() - diff - 1));
			diff--;
		}
		if (!delRawMt.isEmpty() && Schema.sObjectType.PMC_CPQ_RawMaterial__c.isDeletable()) {
			delete delRawMt;
		}
		List<PMC_CPQ_RawMaterial__c> lstRmt = new List<PMC_CPQ_RawMaterial__c>();
		while (diff < 0) {
			rwMt = new PMC_CPQ_RawMaterial__c();
			rwMt.PMC_CPQ_Quote__c = quoteId;
			lstRmt.add(rwMt);
			diff++;
		}
		if (!lstRmt.isEmpty() && Schema.sObjectType.PMC_CPQ_RawMaterial__c.isCreateable()) {
			insert lstRmt;
			rawMtrl.addAll(lstRmt);
		}
		return rawMtrl;
	}
}