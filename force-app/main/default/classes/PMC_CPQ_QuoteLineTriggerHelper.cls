/**
 * @description Helper class for QuoteLineTrigger
 * @author Raphael Soares
 * @storynumber GCPM-4221
 */
public without sharing class PMC_CPQ_QuoteLineTriggerHelper {
	/**
	 * @description Copy amendment quote line details from latest quote line
	 * This method replicates the logic from PMC_CPQ_BeforeCreateQuoteLinesAmendmentDetailsAssignmentFlow
	 * Handles both first amendment (using UpgradedSubscription.QuoteLine) and subsequent amendment scenarios
	 * @param newQuoteLines List of new quote lines being inserted
	 */
	public static void copyAmendmentQuoteLineDetails(List<SBQQ__QuoteLine__c> newQuoteLines) {
		// Filter quote lines for amendment quotes that are not clones
		List<SBQQ__QuoteLine__c> amendmentQuoteLines = new List<SBQQ__QuoteLine__c>();
		Set<Id> quoteIds = new Set<Id>();
		Set<Id> upgradedSubscriptionIds = new Set<Id>();
		Set<Id> originalQuoteLineIds = new Set<Id>();

		for (SBQQ__QuoteLine__c quoteLine : newQuoteLines) {
			// Only process amendment quote lines that are not clones
			if (quoteLine.SBQQ__Source__c == null && quoteLine.SBQQ__UpgradedSubscription__c != null) {
				amendmentQuoteLines.add(quoteLine);
				quoteIds.add(quoteLine.SBQQ__Quote__c);
				upgradedSubscriptionIds.add(quoteLine.SBQQ__UpgradedSubscription__c);
			}
		}

		if (amendmentQuoteLines.isEmpty()) {
			return;
		}

		// Query quotes with related data to check if they are amendment quotes
		Map<Id, SBQQ__Quote__c> quotesMap = new Map<Id, SBQQ__Quote__c>(
			[
				SELECT
					Id,
					SBQQ__Type__c,
					SBQQ__MasterContract__r.PMC_CPQ_LatestQuote__c,
					SBQQ__MasterContract__r.PMC_CPQ_LatestQuote__r.SBQQ__Type__c
				FROM SBQQ__Quote__c
				WHERE Id IN :quoteIds AND SBQQ__Type__c = 'Amendment'
			]
		);

		if (quotesMap.isEmpty()) {
			return;
		}

		// Query upgraded subscriptions to get the original quote line reference
		Map<Id, SBQQ__Subscription__c> subscriptionsMap = new Map<Id, SBQQ__Subscription__c>(
			[
				SELECT Id, SBQQ__QuoteLine__c
				FROM SBQQ__Subscription__c
				WHERE Id IN :upgradedSubscriptionIds AND SBQQ__QuoteLine__c != NULL
			]
		);

		// Collect original quote line IDs for first amendment scenario
		for (SBQQ__Subscription__c sub : subscriptionsMap.values()) {
			originalQuoteLineIds.add(sub.SBQQ__QuoteLine__c);
		}

		// Get latest quote IDs for subsequent amendment scenario
		Set<Id> latestQuoteIds = new Set<Id>();
		for (SBQQ__Quote__c quote : quotesMap.values()) {
			if (quote.SBQQ__MasterContract__r.PMC_CPQ_LatestQuote__c != null) {
				latestQuoteIds.add(quote.SBQQ__MasterContract__r.PMC_CPQ_LatestQuote__c);
			}
		}

		// Query source quote lines - both original and from latest quote
		List<SBQQ__QuoteLine__c> sourceQuoteLines = [
			SELECT
				Id,
				SBQQ__Quote__c,
				SBQQ__Quote__r.PMC_CPQ_AccountManager__c,
				SBQQ__UpgradedSubscription__c,
				PMC_CPQ_UnitofMeasure__c,
				PMC_CPQ_Incoterms1__c,
				PMC_CPQ_ModeofTransportation__c,
				PMC_CPQ_ShippingType__c,
				PMC_CPQ_ContractType__c,
				PMC_CPQ_Discount__c,
				PMC_CPQ_EstFreightPrice__c,
				PMC_CPQ_Interest__c,
				PMC_CPQ_ExspaceIndicator__c,
				PMC_CPQ_Netback__c,
				PMC_CPQ_PriceByDate__c,
				PMC_CPQ_EstTax__c,
				PMC_CPQ_FinalPricePerTonne__c,
				PMC_CPQ_Allocation__c,
				PMC_CPQ_ExistingInventory__c,
				PMC_CPQ_PriceDueDate__c,
				PMC_CPQ_HarvestPeriod__c,
				PMC_CPQ_ProductLocation__c,
				PMC_CPQ_CropType__c,
				PMC_CPQ_PriceGuidanceTarget__c,
				PMC_CPQ_PriceGuidanceCeiling__c,
				PMC_CPQ_PriceGuidanceFloor__c,
				PMC_CPQ_VolumeDiscount__c,
				PMC_CPQ_ShipTo__c,
				PMC_CPQ_PaymentDate__c,
				PMC_CPQ_LinePONumber__c,
				PMC_CPQ_PriceBookValue__c,
				PMC_CPQ_DeliveryStartDate__c,
				PMC_CPQ_DeliveryEndDate__c,
				PMC_CPQ_Nitrogen__c,
				PMC_CPQ_Potassium__c,
				PMC_CPQ_Phosphorous__c,
				PMC_CPQ_InForecast__c,
				PMC_CPQ_InSalesProgram__c,
				PMC_CPQ_Margin__c,
				PMC_CPQ_CostAdjustment__c,
				PMC_CPQ_MarginAdjustment__c,
				PMC_CPQ_VariationofCFR__c,
				PMC_CPQ_Industrialization__c,
				PMC_CPQ_MosaicOptiontoShip__c,
				PMC_CPQ_CustomerOfferedPrice__c,
				PMC_CPQ_NetUnitPrice__c,
				PMC_CPQ_CustomerPrice__c,
				PMC_CPQ_PaymentTerms__c,
				PMC_CPQ_SoldToShipToJunction__c,
				PMC_CPQ_ExchangeRate__c,
				PMC_CPQ_InterestFees__c,
				PMC_CPQ_PackType__c,
				PMC_CPQ_PackageType__c,
				PMC_CPQ_VCOQuotation__c,
				PMC_CPQ_Tolerance__c,
				PMC_CPQ_RoadDistance__c,
				PMC_CPQ_DirtyDistance__c,
				PMC_CPQ_ToleranceComments__c,
				PMC_CPQ_FinalPricePerTon__c,
				PMC_CPQ_PercentageOfQuantity__c,
				PMC_CPQ_OriginalQuantity__c,
				PMC_CPQ_CommissionCurrency__c,
				PMC_CPQ_ExpeditionPoint__c,
				PMC_CPQ_frontendIncoterms2__c,
				PMC_CPQ_VCODeliveryRegion__c,
				PMC_CPQ_InterestPeriod__c,
				PMC_CPQ_VCOIntercompanyPlant__c,
				PMC_CPQ_ValidEndDate__c,
				PMC_CPQ_ValidStartDate__c,
				PMC_CPQ_LastProductCustomerPrice__c,
				PMC_CPQ_LastPricedDate__c,
				PMC_CPQ_AveragePricePerProduct__c,
				PMC_CPQ_ReplacementMargin__c,
				PMC_CPQ_ListCFR__c,
				PMC_CPQ_SoldCFR__c,
				PMC_CPQ_VCOAdjustment__c,
				PMC_CPQ_Commission__c
			FROM SBQQ__QuoteLine__c
			WHERE
				Id IN :originalQuoteLineIds
				OR (SBQQ__Quote__c IN :latestQuoteIds
				AND SBQQ__UpgradedSubscription__c IN :upgradedSubscriptionIds)
		];

		// Create maps for quick lookup
		Map<Id, SBQQ__QuoteLine__c> originalQuoteLinesMap = new Map<Id, SBQQ__QuoteLine__c>();
		Map<String, SBQQ__QuoteLine__c> latestQuoteLinesByUpgradedSub = new Map<String, SBQQ__QuoteLine__c>();

		for (SBQQ__QuoteLine__c sourceQL : sourceQuoteLines) {
			// Map original quote lines (for first amendment)
			if (originalQuoteLineIds.contains(sourceQL.Id)) {
				originalQuoteLinesMap.put(sourceQL.Id, sourceQL);
			}

			// Map latest quote lines by UpgradedSubscription (for subsequent amendments)
			if (latestQuoteIds.contains(sourceQL.SBQQ__Quote__c) && sourceQL.SBQQ__UpgradedSubscription__c != null) {
				String key = sourceQL.SBQQ__Quote__c + '_' + sourceQL.SBQQ__UpgradedSubscription__c;
				latestQuoteLinesByUpgradedSub.put(key, sourceQL);
			}
		}

		// Copy fields from source quote lines to amendment quote lines
		for (SBQQ__QuoteLine__c amendmentQL : amendmentQuoteLines) {
			SBQQ__Quote__c parentQuote = quotesMap.get(amendmentQL.SBQQ__Quote__c);
			if (parentQuote == null) {
				continue;
			}

			SBQQ__QuoteLine__c sourceQL = null;

			// Get the subscription record to determine the source
			SBQQ__Subscription__c subscription = subscriptionsMap.get(amendmentQL.SBQQ__UpgradedSubscription__c);

			// Get the latest quote approach (subsequent amendment)
			if (sourceQL == null && parentQuote.SBQQ__MasterContract__r?.PMC_CPQ_LatestQuote__r?.SBQQ__Type__c == 'Amendment') {
				String lookupKey =
					parentQuote.SBQQ__MasterContract__r.PMC_CPQ_LatestQuote__c +
					'_' +
					amendmentQL.SBQQ__UpgradedSubscription__c;
				sourceQL = latestQuoteLinesByUpgradedSub.get(lookupKey);
			}

			if (sourceQL == null && subscription?.SBQQ__QuoteLine__c != null) {
				// Check if we have the original quote line (first amendment scenario)
				sourceQL = originalQuoteLinesMap.get(subscription.SBQQ__QuoteLine__c);
			}

			if (sourceQL != null) {
				copyQuoteLineFields(amendmentQL, sourceQL);
			}
		}
	}

	/**
	 * @description Copy all the fields from source quote line to amendment quote line
	 * @param amendmentQL Target amendment quote line
	 * @param sourceQL Source quote line (original or from latest quote)
	 */
	private static void copyQuoteLineFields(SBQQ__QuoteLine__c amendmentQL, SBQQ__QuoteLine__c sourceQL) {
		amendmentQL.PMC_CPQ_UnitofMeasure__c = sourceQL.PMC_CPQ_UnitofMeasure__c;
		amendmentQL.PMC_CPQ_Incoterms1__c = sourceQL.PMC_CPQ_Incoterms1__c;
		amendmentQL.PMC_CPQ_ModeofTransportation__c = sourceQL.PMC_CPQ_ModeofTransportation__c;
		amendmentQL.PMC_CPQ_ShippingType__c = sourceQL.PMC_CPQ_ShippingType__c;
		amendmentQL.PMC_CPQ_ContractType__c = sourceQL.PMC_CPQ_ContractType__c;
		amendmentQL.PMC_CPQ_Discount__c = sourceQL.PMC_CPQ_Discount__c;
		amendmentQL.PMC_CPQ_EstFreightPrice__c = sourceQL.PMC_CPQ_EstFreightPrice__c;
		amendmentQL.PMC_CPQ_Interest__c = sourceQL.PMC_CPQ_Interest__c;
		amendmentQL.PMC_CPQ_ExspaceIndicator__c = sourceQL.PMC_CPQ_ExspaceIndicator__c;
		amendmentQL.PMC_CPQ_Netback__c = sourceQL.PMC_CPQ_Netback__c;
		amendmentQL.PMC_CPQ_PriceByDate__c = sourceQL.PMC_CPQ_PriceByDate__c;
		amendmentQL.PMC_CPQ_EstTax__c = sourceQL.PMC_CPQ_EstTax__c;
		amendmentQL.PMC_CPQ_FinalPricePerTonne__c = sourceQL.PMC_CPQ_FinalPricePerTonne__c;
		amendmentQL.PMC_CPQ_Allocation__c = sourceQL.PMC_CPQ_Allocation__c;
		amendmentQL.PMC_CPQ_ExistingInventory__c = sourceQL.PMC_CPQ_ExistingInventory__c;
		amendmentQL.PMC_CPQ_PriceDueDate__c = sourceQL.PMC_CPQ_PriceDueDate__c;
		amendmentQL.PMC_CPQ_HarvestPeriod__c = sourceQL.PMC_CPQ_HarvestPeriod__c;
		amendmentQL.PMC_CPQ_ProductLocation__c = sourceQL.PMC_CPQ_ProductLocation__c;
		amendmentQL.PMC_CPQ_CropType__c = sourceQL.PMC_CPQ_CropType__c;
		amendmentQL.PMC_CPQ_PriceGuidanceTarget__c = sourceQL.PMC_CPQ_PriceGuidanceTarget__c;
		amendmentQL.PMC_CPQ_PriceGuidanceCeiling__c = sourceQL.PMC_CPQ_PriceGuidanceCeiling__c;
		amendmentQL.PMC_CPQ_PriceGuidanceFloor__c = sourceQL.PMC_CPQ_PriceGuidanceFloor__c;
		amendmentQL.PMC_CPQ_VolumeDiscount__c = sourceQL.PMC_CPQ_VolumeDiscount__c;
		amendmentQL.PMC_CPQ_ShipTo__c = sourceQL.PMC_CPQ_ShipTo__c;
		amendmentQL.PMC_CPQ_PaymentDate__c = sourceQL.PMC_CPQ_PaymentDate__c;
		amendmentQL.PMC_CPQ_LinePONumber__c = sourceQL.PMC_CPQ_LinePONumber__c;
		amendmentQL.PMC_CPQ_PriceBookValue__c = sourceQL.PMC_CPQ_PriceBookValue__c;
		amendmentQL.PMC_CPQ_DeliveryStartDate__c = sourceQL.PMC_CPQ_DeliveryStartDate__c;
		amendmentQL.PMC_CPQ_DeliveryEndDate__c = sourceQL.PMC_CPQ_DeliveryEndDate__c;
		amendmentQL.PMC_CPQ_Nitrogen__c = sourceQL.PMC_CPQ_Nitrogen__c;
		amendmentQL.PMC_CPQ_Potassium__c = sourceQL.PMC_CPQ_Potassium__c;
		amendmentQL.PMC_CPQ_Phosphorous__c = sourceQL.PMC_CPQ_Phosphorous__c;
		amendmentQL.PMC_CPQ_InForecast__c = sourceQL.PMC_CPQ_InForecast__c;
		amendmentQL.PMC_CPQ_InSalesProgram__c = sourceQL.PMC_CPQ_InSalesProgram__c;
		amendmentQL.PMC_CPQ_Margin__c = sourceQL.PMC_CPQ_Margin__c;
		amendmentQL.PMC_CPQ_CostAdjustment__c = sourceQL.PMC_CPQ_CostAdjustment__c;
		amendmentQL.PMC_CPQ_MarginAdjustment__c = sourceQL.PMC_CPQ_MarginAdjustment__c;
		amendmentQL.PMC_CPQ_VariationofCFR__c = sourceQL.PMC_CPQ_VariationofCFR__c;
		amendmentQL.PMC_CPQ_Industrialization__c = sourceQL.PMC_CPQ_Industrialization__c;
		amendmentQL.PMC_CPQ_MosaicOptiontoShip__c = sourceQL.PMC_CPQ_MosaicOptiontoShip__c;
		amendmentQL.PMC_CPQ_CustomerOfferedPrice__c = sourceQL.PMC_CPQ_CustomerOfferedPrice__c;
		amendmentQL.PMC_CPQ_NetUnitPrice__c = sourceQL.PMC_CPQ_NetUnitPrice__c;
		amendmentQL.PMC_CPQ_CustomerPrice__c = sourceQL.PMC_CPQ_CustomerPrice__c;
		amendmentQL.PMC_CPQ_PaymentTerms__c = sourceQL.PMC_CPQ_PaymentTerms__c;
		amendmentQL.PMC_CPQ_SoldToShipToJunction__c = sourceQL.PMC_CPQ_SoldToShipToJunction__c;
		amendmentQL.PMC_CPQ_ExchangeRate__c = sourceQL.PMC_CPQ_ExchangeRate__c;
		amendmentQL.PMC_CPQ_InterestFees__c = sourceQL.PMC_CPQ_InterestFees__c;
		amendmentQL.PMC_CPQ_PackType__c = sourceQL.PMC_CPQ_PackType__c;
		amendmentQL.PMC_CPQ_PackageType__c = sourceQL.PMC_CPQ_PackageType__c;
		amendmentQL.PMC_CPQ_VCOQuotation__c = sourceQL.PMC_CPQ_VCOQuotation__c == true;
		amendmentQL.PMC_CPQ_Tolerance__c = sourceQL.PMC_CPQ_Tolerance__c;
		amendmentQL.PMC_CPQ_RoadDistance__c = sourceQL.PMC_CPQ_RoadDistance__c;
		amendmentQL.PMC_CPQ_DirtyDistance__c = sourceQL.PMC_CPQ_DirtyDistance__c;
		amendmentQL.PMC_CPQ_ToleranceComments__c = sourceQL.PMC_CPQ_ToleranceComments__c;
		amendmentQL.PMC_CPQ_FinalPricePerTon__c = sourceQL.PMC_CPQ_FinalPricePerTon__c;
		amendmentQL.PMC_CPQ_PercentageOfQuantity__c = sourceQL.PMC_CPQ_PercentageOfQuantity__c;
		amendmentQL.PMC_CPQ_OriginalQuantity__c = sourceQL.PMC_CPQ_OriginalQuantity__c;
		amendmentQL.PMC_CPQ_CommissionCurrency__c = sourceQL.PMC_CPQ_CommissionCurrency__c;
		amendmentQL.PMC_CPQ_ExpeditionPoint__c = sourceQL.PMC_CPQ_ExpeditionPoint__c;
		amendmentQL.PMC_CPQ_frontendIncoterms2__c = sourceQL.PMC_CPQ_frontendIncoterms2__c;
		amendmentQL.PMC_CPQ_VCODeliveryRegion__c = sourceQL.PMC_CPQ_VCODeliveryRegion__c;
		amendmentQL.PMC_CPQ_InterestPeriod__c = sourceQL.PMC_CPQ_InterestPeriod__c;
		amendmentQL.PMC_CPQ_VCOIntercompanyPlant__c = sourceQL.PMC_CPQ_VCOIntercompanyPlant__c;
		amendmentQL.PMC_CPQ_ValidEndDate__c = sourceQL.PMC_CPQ_ValidEndDate__c;
		amendmentQL.PMC_CPQ_ValidStartDate__c = sourceQL.PMC_CPQ_ValidStartDate__c;
		amendmentQL.PMC_CPQ_LastProductCustomerPrice__c = sourceQL.PMC_CPQ_LastProductCustomerPrice__c;
		amendmentQL.PMC_CPQ_LastPricedDate__c = sourceQL.PMC_CPQ_LastPricedDate__c;
		amendmentQL.PMC_CPQ_AveragePricePerProduct__c = sourceQL.PMC_CPQ_AveragePricePerProduct__c;
		amendmentQL.PMC_CPQ_ReplacementMargin__c = sourceQL.PMC_CPQ_ReplacementMargin__c;
		amendmentQL.PMC_CPQ_ListCFR__c = sourceQL.PMC_CPQ_ListCFR__c;
		amendmentQL.PMC_CPQ_SoldCFR__c = sourceQL.PMC_CPQ_SoldCFR__c;
		amendmentQL.PMC_CPQ_VCOAdjustment__c = sourceQL.PMC_CPQ_VCOAdjustment__c;
		amendmentQL.PMC_CPQ_Commission__c = sourceQL.PMC_CPQ_Commission__c;
	}

	/**
	 * Update Quote Line Items based on Quote PMC_CPQ_VCOQuotation__c value.
	 * @param newLines List of new Quote Line records being inserted.
	 */
	public static void updateVCOInsertedLineItems(List<SBQQ__QuoteLine__c> newLines) {
		Set<Id> quoteIds = new Set<Id>();

		// Collect unique Quote IDs from the new Quote Line records.
		for (SBQQ__QuoteLine__c item : newLines) {
			if (item.SBQQ__Quote__c != null) {
				quoteIds.add(item.SBQQ__Quote__c);
			}
		}

		if (quoteIds.isEmpty()) {
			return;
		}

		// Query the quotes to get their PMC_CPQ_VCOQuotation__c values.
		List<SBQQ__Quote__c> quotes = [
			SELECT Id, PMC_CPQ_VCOQuotation__c
			FROM SBQQ__Quote__c
			WHERE Id IN :quoteIds
		];

		if (quotes.isEmpty()) {
			return;
		}

		// Update the PMC_CPQ_VCOQuotation__c field in the new Quote Line records.
		for (SBQQ__Quote__c quote : quotes) {
			for (SBQQ__QuoteLine__c quoteItem : newLines) {
				if (quoteItem.SBQQ__Quote__c == quote.Id) {
					quoteItem.PMC_CPQ_VCOQuotation__c = quote.PMC_CPQ_VCOQuotation__c == null ? false : quote.PMC_CPQ_VCOQuotation__c;
				}
			}
		}
	}

	public static void setContractUpdateCheckEligibilityStatus(List<SBQQ__QuoteLine__c> newList, Map<Id, SBQQ__QuoteLine__c> oldMap) {
		// Collect quote IDs and filter to only process lines with relevant changes
		Set<Id> quoteIds = new Set<Id>();
		Map<Id, String> quoteEligibilityMap = new Map<Id, String>();
		for (SBQQ__QuoteLine__c item : newList) {
			quoteIds.add(item.SBQQ__Quote__c);
			if ((UserInfo.getName() == 'Integration User' || Test.isRunningTest())) {
				if (RecordValidator.isFieldChanged(item, oldMap, 'PMC_CPQ_FinalPricePerTonne__c', null)) {
					String message = System.Label.MassUpdate_Error_NotEligibleFinalPricePerTonne.replace('{0}', item.Name);
					quoteEligibilityMap.put(item.SBQQ__Quote__c, StringUtils.addPicklistValueToMultiSelect(quoteEligibilityMap.get(item.SBQQ__Quote__c), message));
				}
				if (RecordValidator.isFieldChanged(item, oldMap, 'PMC_CPQ_Margin__c', null)) {
					String message = System.Label.MassUpdate_Error_NotEligibleMargin.replace('{0}', item.Name);
					quoteEligibilityMap.put(item.SBQQ__Quote__c, StringUtils.addPicklistValueToMultiSelect(quoteEligibilityMap.get(item.SBQQ__Quote__c), message));
				}
			}
		}
		// Only run the query once per transaction for each set of quote IDs
		Set<Id> quotesToProcess = ExecutionController.bulkExecuteOnce('setContractUpdateCheckEligibility', quoteIds);
		if (quotesToProcess.isEmpty()) {
			return;
		}
		List<MassUpdateExecutionLine__c> linesToUpdate = [
			SELECT Id, CheckEligibilityStatus__c, CreatedQuote__c, FinishedSteps__c, Message__c, Status__c, Step__c, Feature__c
			FROM MassUpdateExecutionLine__c
			WHERE CreatedQuote__c IN :quotesToProcess
		];
		// for (MassUpdateExecutionLine__c line : linesToUpdate) {
		// 	line.CheckEligibilityStatus__c = null;
		// }
		for (MassUpdateExecutionLine__c line : linesToUpdate) {
			if(line.Feature__c == 'ContractDateUpdate') {
				String message = quoteEligibilityMap.get(line.CreatedQuote__c);
				if(String.isEmpty(message) && line.CheckEligibilityStatus__c != 'Not Eligible') {
					line.CheckEligibilityStatus__c = 'Eligible';
					line.Status__c = 'Pending';
					line.Message__c = null;
					line.Step__c = 'Submit for Approval';
					line.FinishedSteps__c = StringUtils.addPicklistValueToMultiSelect(line.FinishedSteps__c, 'Check Eligibility');
				} else {
					line.CheckEligibilityStatus__c = 'Not Eligible';
					line.Status__c = 'Error';
					line.Message__c = String.isNotBlank(message) ? message : line.Message__c;
					line.Step__c = 'Check Eligibility';
				}
			}
		}
		if (!linesToUpdate.isEmpty()) {
			update linesToUpdate;
		}
	}
}