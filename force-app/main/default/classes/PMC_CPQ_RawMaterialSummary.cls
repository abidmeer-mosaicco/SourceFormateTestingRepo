/**
 * @description This class will be used to Update the Rawmaterial Summary Information to the Quote Record..
 * @author Jeyanthi Muthaiah
 * @storynumber : GDASF-7851,GDASF-18765
 */

public with sharing class PMC_CPQ_RawMaterialSummary {
	/**
	 * @description rawMaterialQuantitySum -to store the Sum of Quantity Tons of Same Raw Materilas which have same Product SKU
	 **/

	public static Map<String, Decimal> rawMaterialQuantitySum = new Map<String, Decimal>();

	/**
	 * @description rawMaterialListCFRAvg -to store the Avg ListCFR of Same Raw Materilas which have same Product SKU
	 */

	public static Map<String, Decimal> rawMaterialListCFRAvg = new Map<String, Decimal>();

	/**
	 * @description rawMaterialSoldCFRAvg -to store the Avg SoldCFR of Same Raw Materilas which have same Product SKU
	 */

	public static Map<String, Decimal> rawMaterialSoldCFRAvg = new Map<String, Decimal>();

	/**
	 * @description rawMaterialName -to store the Names of Raw Materilas which have same Product SKU
	 */

	public static Map<String, String> rawMaterialName = new Map<String, String>();

	/**
	 * @description rawMaterialSumsKey -to store the Unique Raw Materials in a List
	 */

	public static Set<String> rawMaterialSumsKey = new Set<String>();

	/**
	 * @description This method will be used get the Rawmaterial information of the Quote.
	 * @param recordid - holds the current quote ID
	 */

	public static void rawMaterialInfo(Id recordid) {
		SBQQ__Quote__c quoteInfo = new SBQQ__Quote__c();
		List<SBQQ__QuoteLine__c> qLines = new List<SBQQ__QuoteLine__c>();
		List<SBQQ__QuoteLine__c> blendedProducts = new List<SBQQ__QuoteLine__c>();

		// Get Quote Info
		quoteInfo = [
			SELECT
				id,
				PMC_CPQ_RawMaterialName1__c,
				PMC_CPQ_RawMaterialName2__c,
				PMC_CPQ_RawMaterialQuantity1__c,
				PMC_CPQ_RawMaterialQuantity2__c,
				PMC_CPQ_RawMaterial2ListCFR__c,
				PMC_CPQ_RawMaterial1SoldCFR__c,
				PMC_CPQ_RawMaterial2SoldCFR__c,
				PMC_CPQ_RawMaterial1ListCFR__c,
				PMC_CPQ_QuoteShortNameDescription__c,
				CurrencyIsoCode,
				PMC_CPQ_ContractEnd__c,
				CreatedDate,
				PMC_CPQ_AccountCountry__c,
				SBQQ__Account__r.Name,
				(SELECT CreatedDate FROM Approvals1__r)
			FROM SBQQ__Quote__c
			WHERE ID = :recordid
		];

		//Get Quote line Info
		qLines = [
			SELECT
				id,
				SBQQ__ProductName__c,
				(
					SELECT
						PMC_CPQ_Product__r.Name,
						PMC_CPQ_ListCFR__c,
						PMC_CPQ_SoldCFR__c,
						PMC_CPQ_Quantity__c,
						PMC_CPQ_QuantityTons__c,
						PMC_CPQ_ProductSKU__c
					FROM Raw_Materials1__r
				)
			FROM SBQQ__QuoteLine__c
			WHERE SBQQ__Quote__c = :recordid
		];
		// Get blended products among quotelines
		for (SBQQ__QuoteLine__c blendedProduct : qLines) {
			if (blendedProduct.Raw_Materials1__r.size() > 0) {
				blendedProducts.add(blendedProduct);
			}
		}

		calculateRawMaterialSummary(blendedProducts, quoteInfo);
	}

	/**
	 * @description This method will be used Calculate RM Summary Information on Quote.
	 * @param blendedProducts - holds the blended product records.
	 * @param quoteInfo - holds the Quote info.
	 */

	public static void calculateRawMaterialSummary(List<SBQQ__QuoteLine__c> blendedProducts, SBQQ__Quote__c quoteInfo) {
		Map<String, Decimal> rawMaterialListCFRSum = new Map<String, Decimal>();
		Map<String, Decimal> rawMaterialSoldCFRSum = new Map<String, Decimal>();

		for (SBQQ__QuoteLine__c blendedProduct : blendedProducts) {
			for (PMC_CPQ_RawMaterial__c blendedProductInfo : blendedProduct.Raw_Materials1__r) {
				String rawMaterialSKU = blendedProductInfo.PMC_CPQ_ProductSKU__c;
				// Fallback: if no explicit Raw Material SKU populated yet, derive from related product name
				if (String.isBlank(rawMaterialSKU) && blendedProductInfo.PMC_CPQ_Product__r != null) {
					rawMaterialSKU = blendedProductInfo.PMC_CPQ_Product__r.Name;
				}
				if (String.isBlank(rawMaterialSKU)) {
					continue; // Still no usable key; skip this raw material
				}
				Decimal quantity = (blendedProductInfo.PMC_CPQ_QuantityTons__c == null) ? 0 : blendedProductInfo.PMC_CPQ_QuantityTons__c;
				Decimal listCFR = (blendedProductInfo.PMC_CPQ_ListCFR__c == null) ? 0 : blendedProductInfo.PMC_CPQ_ListCFR__c;
				Decimal soldCFR = (blendedProductInfo.PMC_CPQ_SoldCFR__c == null) ? 0 : blendedProductInfo.PMC_CPQ_SoldCFR__c;
				Decimal totalListCFR = quantity * listCFR;
				Decimal totalSoldCFR = quantity * soldCFR;
				String nameofRM = (blendedProductInfo.PMC_CPQ_Product__r != null) ? blendedProductInfo.PMC_CPQ_Product__r.Name : null;

				if (rawMaterialQuantitySum.containsKey(rawMaterialSKU)) {
					rawMaterialQuantitySum.put(rawMaterialSKU, rawMaterialQuantitySum.get(rawMaterialSKU) + quantity);
					rawMaterialListCFRSum.put(rawMaterialSKU, rawMaterialListCFRSum.get(rawMaterialSKU) + totalListCFR);
					rawMaterialSoldCFRSum.put(rawMaterialSKU, rawMaterialSoldCFRSum.get(rawMaterialSKU) + totalSoldCFR);
				} else {
					rawMaterialQuantitySum.put(rawMaterialSKU, quantity);
					rawMaterialListCFRSum.put(rawMaterialSKU, totalListCFR);
					rawMaterialSoldCFRSum.put(rawMaterialSKU, totalSoldCFR);
				}
				rawMaterialName.put(rawMaterialSKU, nameofRM);
			}
		}

		rawMaterialSumsKey = rawMaterialQuantitySum.keySet();
		for (String keys : rawMaterialSumsKey) {
			Decimal qtySum = rawMaterialQuantitySum.get(keys);
			if (qtySum == null || qtySum == 0) {
				// Avoid division by zero; set averages to zero when no quantity
				rawMaterialListCFRAvg.put(keys, 0);
				rawMaterialSoldCFRAvg.put(keys, 0);
				continue;
			}
			Decimal listCFRSum = rawMaterialListCFRSum.get(keys) == null ? 0 : rawMaterialListCFRSum.get(keys);
			Decimal soldCFRSum = rawMaterialSoldCFRSum.get(keys) == null ? 0 : rawMaterialSoldCFRSum.get(keys);
			rawMaterialListCFRAvg.put(keys, listCFRSum / qtySum);
			rawMaterialSoldCFRAvg.put(keys, soldCFRSum / qtySum);
		}

		updateRawMaterialSummary(quoteInfo);
	}

	/**
	 * @description This method will be used  Update RM Summary Information on Quote.
	 * @param quoteInfo - holds the Quote info.
	 */

	public static void updateRawMaterialSummary(SBQQ__Quote__c quoteInfo) {
		try {
			SBQQ__Quote__c quotetoUpadte = new SBQQ__Quote__c();

			//Reset Rawmaterial Summary Fields
			decimal j = 1;
			for (j = 1; j <= 10; j++) {
				String rawMaterialNames = 'PMC_CPQ_RawMaterialName' + j + '__c';
				String rawMaterialQuantitys = 'PMC_CPQ_RawMaterialQuantity' + j + '__c';
				String rawMaterialListCFR = 'PMC_CPQ_RawMaterial' + j + 'ListCFR' + '__c';
				String rawMaterialSoldCFR = 'PMC_CPQ_RawMaterial' + j + 'SoldCFR' + '__c';
				quotetoUpadte.put(RawMaterialNames, null);
				quotetoUpadte.put(RawMaterialQuantitys, null);
				quotetoUpadte.put(RawMaterialListCFR, null);
				quotetoUpadte.put(RawMaterialSoldCFR, null);
			}
			// Update the Calculated Vaues to the Raw Material Field
			decimal i = 1;
			for (String keys : rawMaterialSumsKey) {
				if (i <= 10) {
					String rawMaterialNames = 'PMC_CPQ_RawMaterialName' + i + '__c';
					String rawMaterialQuantitys = 'PMC_CPQ_RawMaterialQuantity' + i + '__c';
					String rawMaterialListCFR = 'PMC_CPQ_RawMaterial' + i + 'ListCFR' + '__c';
					String rawMaterialSoldCFR = 'PMC_CPQ_RawMaterial' + i + 'SoldCFR' + '__c';
					quotetoUpadte.id = quoteInfo.id;
					quotetoUpadte.put(RawMaterialNames, rawMaterialName.get(keys));
					quotetoUpadte.put(RawMaterialQuantitys, rawMaterialQuantitySum.get(keys));
					quotetoUpadte.put(RawMaterialListCFR, rawMaterialListCFRAvg.get(keys));
					quotetoUpadte.put(RawMaterialSoldCFR, rawMaterialSoldCFRAvg.get(keys));
					i++;
				}
			}
			if (Schema.sObjectType.SBQQ__Quote__c.isAccessible() && Schema.sObjectType.SBQQ__Quote__c.isUpdateable()) {
				SBQQ.TriggerControl.enable();
				update quotetoUpadte;
				SBQQ.TriggerControl.disable();
			}
		} catch (DmlException objException) {
			PMC_ErrorLogClass.processException(objException);
		}
	}
}