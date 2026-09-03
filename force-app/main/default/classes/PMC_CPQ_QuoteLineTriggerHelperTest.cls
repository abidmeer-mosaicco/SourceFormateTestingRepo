/**
 * @description Test class for PMC_CPQ_QuoteLineTriggerHelper
 * @author Raphael Soares
 * @storynumber GCPM-4221
 */
@isTest
public without sharing class PMC_CPQ_QuoteLineTriggerHelperTest {

	@TestSetup
	static void setup() {
		//PMC_FlowBypassChecker.mapTestOverrides.put('PMC_SS_AccountAfterInsertFlow', true);
		//PMC_FlowBypassChecker.mapTestOverrides.put('PMC_MD_Validate_Account_Changes_From_LE', true);
		//PMC_FlowBypassChecker.mapTestOverrides.put('Send_Email_Notification_for_NA_Master_Data_GTM_Cases', true);

		PMC_ProcessSwitches__c bypassSetting = PMC_ProcessSwitches__c.getOrgDefaults();
		bypassSetting.PMC_BypassFlow__c = true;
		upsert bypassSetting;

		// Create test data using factory class (same pattern as PMC_CPQ_QuoteLineTriggerHandlerTest)
		Account testAccount = PMC_DH_TestDataFactoryClass.createTestAccount();
		Contact testContact = PMC_DH_TestDataFactoryClass.createTestContact(testAccount.Id);
		//testAccount.Primary_Contract_Recipient__c = testContact.Id;
		update testAccount;
		Opportunity testOpp = PMC_DH_TestDataFactoryClass.createOpportunity(testAccount);
		Opportunity testOpp2 = PMC_DH_TestDataFactoryClass.createOpportunity2(testAccount);

		testOpp.CurrencyIsoCode = 'USD';
		testOpp2.CurrencyIsoCode = 'USD';
		update new List<Opportunity>{ testOpp, testOpp2 };

		SBQQ__Quote__c testQuote = PMC_DH_TestDataFactoryClass.createQuote(testAccount, testContact.Id, testOpp);
		testQuote.SBQQ__Status__c = 'Draft';
		update testQuote;

		Product2 testProduct = PMC_DH_TestDataFactoryClass.createProduct();
		insert testProduct;

		SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote, testProduct);

		// Create contract linked to the quote (wrapped with SBQQ trigger control)
		SBQQ.TriggerControl.disable();
		Contract testContract = PMC_DH_TestDataFactoryClass.createContract(testQuote.Id, testAccount.Id);
		SBQQ.TriggerControl.enable();

		// Create subscription linking quote line to contract
		SBQQ__Subscription__c testSubscription = new SBQQ__Subscription__c(
			SBQQ__Account__c = testAccount.Id,
			SBQQ__Product__c = testProduct.Id,
			SBQQ__Quantity__c = 25,
			SBQQ__QuoteLine__c = testQuoteLine.Id,
			SBQQ__Contract__c = testContract.Id
		);
		insert testSubscription;

		// Set up second opportunity for amendment scenario
		testOpp2.SBQQ__AmendedContract__c = testContract.Id;
		update testOpp2;

		// Create amendment quote
		SBQQ.TriggerControl.disable();
		bypassSetting.PMC_BypassValidationRule__c = true;
		upsert bypassSetting;

		SBQQ__Quote__c amendmentQuote = new SBQQ__Quote__c(
			SBQQ__Account__c = testAccount.Id,
			SBQQ__Opportunity2__c = testOpp2.Id,
			SBQQ__Type__c = 'Amendment',
			SBQQ__Status__c = 'Draft',
			PMC_CPQ_ContractStart__c = Date.today().addDays(10),
			PMC_CPQ_ContractEnd__c = Date.today().addDays(40),
			PMC_CPQ_PrimaryContact__c = testContact.Id,
			PMC_CPQ_CustomCreatedDate__c = System.now(),
			PMC_CPQ_AccountManager__c = UserInfo.getUserId(),
			PMC_CPQ_Region__c = 'North America',
			PMC_CPQ_ExpiresOn__c = Datetime.now().addDays(10),
			PMC_CPQ_QuoteRecordSubType__c = 'Feed',
			SBQQ__MasterContract__c = testContract.Id,
			PMC_CPQ_VCOQuotation__c = false
		);
		insert amendmentQuote;

		bypassSetting.PMC_BypassFlow__c = false;
		bypassSetting.PMC_BypassValidationRule__c = false;
		upsert bypassSetting;
		SBQQ.TriggerControl.enable();
	}

	/**
	 * @description Test copyAmendmentQuoteLineDetails - first amendment scenario
	 * Verifies fields are copied from the original quote line via UpgradedSubscription
	 */
	@isTest
	static void testCopyAmendmentQuoteLineDetailsFirstAmendment() {
		SBQQ__Quote__c amendmentQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Amendment' LIMIT 1];
		SBQQ__QuoteLine__c baseQuoteLine = [
			SELECT Id, SBQQ__Product__c, PMC_CPQ_ModeofTransportation__c, PMC_CPQ_UnitofMeasure__c,
				PMC_CPQ_Incoterms1__c, PMC_CPQ_ContractType__c, PMC_CPQ_FinalPricePerTonne__c,
				PMC_CPQ_VCOQuotation__c, PMC_CPQ_PackType__c, PMC_CPQ_PackageType__c, PMC_CPQ_CustomerPrice__c
			FROM SBQQ__QuoteLine__c
			WHERE SBQQ__Quote__r.SBQQ__Type__c != 'Amendment'
			LIMIT 1
		];
		SBQQ__Subscription__c subscription = [SELECT Id FROM SBQQ__Subscription__c LIMIT 1];

		Test.startTest();

		// Create amendment quote line with UpgradedSubscription (first amendment pattern)
		SBQQ.TriggerControl.disable();
		SBQQ__QuoteLine__c amendmentQuoteLine = new SBQQ__QuoteLine__c(
			SBQQ__Quote__c = amendmentQuote.Id,
			SBQQ__Product__c = baseQuoteLine.SBQQ__Product__c,
			SBQQ__UpgradedSubscription__c = subscription.Id,
			SBQQ__Number__c = 1,
			SBQQ__Quantity__c = 1500,
			PMC_CPQ_QuoteRecordType__c = 'Domestic NA',
			PMC_CPQ_QuoteRecordSubType__c = 'Feed',
			PMC_CPQ_ContractType__c = 'Priced',
			PMC_CPQ_EstFreightPrice__c = 100
		);
		insert amendmentQuoteLine;
		SBQQ.TriggerControl.enable();

		Test.stopTest();

		// Verify fields were copied from the base quote line
		SBQQ__QuoteLine__c insertedQL = [
			SELECT Id, PMC_CPQ_ModeofTransportation__c, PMC_CPQ_UnitofMeasure__c,
				PMC_CPQ_Incoterms1__c, PMC_CPQ_ContractType__c, PMC_CPQ_FinalPricePerTonne__c,
				PMC_CPQ_VCOQuotation__c, PMC_CPQ_PackType__c, PMC_CPQ_PackageType__c, PMC_CPQ_CustomerPrice__c
			FROM SBQQ__QuoteLine__c
			WHERE Id = :amendmentQuoteLine.Id
		];

		System.assertEquals(baseQuoteLine.PMC_CPQ_ModeofTransportation__c, insertedQL.PMC_CPQ_ModeofTransportation__c, 'Mode of Transportation should be copied');
		System.assertEquals(baseQuoteLine.PMC_CPQ_UnitofMeasure__c, insertedQL.PMC_CPQ_UnitofMeasure__c, 'Unit of Measure should be copied');
		System.assertEquals(baseQuoteLine.PMC_CPQ_Incoterms1__c, insertedQL.PMC_CPQ_Incoterms1__c, 'Incoterms should be copied');
		System.assertEquals(baseQuoteLine.PMC_CPQ_ContractType__c, insertedQL.PMC_CPQ_ContractType__c, 'Contract Type should be copied');
		System.assertEquals(baseQuoteLine.PMC_CPQ_FinalPricePerTonne__c, insertedQL.PMC_CPQ_FinalPricePerTonne__c, 'Final Price Per Tonne should be copied');
		System.assertEquals(baseQuoteLine.PMC_CPQ_PackType__c, insertedQL.PMC_CPQ_PackType__c, 'Pack Type should be copied');
		System.assertEquals(baseQuoteLine.PMC_CPQ_PackageType__c, insertedQL.PMC_CPQ_PackageType__c, 'Package Type should be copied');
		System.assertEquals(baseQuoteLine.PMC_CPQ_CustomerPrice__c, insertedQL.PMC_CPQ_CustomerPrice__c, 'Customer Price should be copied');
	}

	/**
	 * @description Test copyAmendmentQuoteLineDetails - non-amendment quotes are skipped
	 */
	@isTest
	static void testCopyAmendmentQuoteLineDetailsSkipsNonAmendment() {
		SBQQ__Quote__c baseQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c != 'Amendment' LIMIT 1];
		Product2 product = [SELECT Id FROM Product2 LIMIT 1];

		Test.startTest();

		// Create regular quote line (not amendment - no UpgradedSubscription)
		SBQQ.TriggerControl.disable();
		SBQQ__QuoteLine__c regularQuoteLine = new SBQQ__QuoteLine__c(
			SBQQ__Quote__c = baseQuote.Id,
			SBQQ__Product__c = product.Id,
			SBQQ__Number__c = 2,
			SBQQ__Quantity__c = 1000,
			PMC_CPQ_QuoteRecordType__c = 'Domestic NA',
			PMC_CPQ_QuoteRecordSubType__c = 'Feed',
			PMC_CPQ_ContractType__c = 'Priced'
		);
		insert regularQuoteLine;
		SBQQ.TriggerControl.enable();

		Test.stopTest();

		// Verify no fields were copied (should retain inserted values or be null)
		SBQQ__QuoteLine__c insertedQL = [
			SELECT Id, PMC_CPQ_ModeofTransportation__c, PMC_CPQ_Incoterms1__c
			FROM SBQQ__QuoteLine__c
			WHERE Id = :regularQuoteLine.Id
		];

		System.assertEquals(null, insertedQL.PMC_CPQ_ModeofTransportation__c, 'Non-amendment quote line should not have copied values');
		System.assertEquals(null, insertedQL.PMC_CPQ_Incoterms1__c, 'Non-amendment quote line should not have copied values');
	}

	/**
	 * @description Test copyAmendmentQuoteLineDetails - quote lines with Source (clones) are skipped
	 */
	@isTest
	static void testCopyAmendmentQuoteLineDetailsSkipsClones() {
		SBQQ__Quote__c amendmentQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Amendment' LIMIT 1];
		SBQQ__QuoteLine__c baseQuoteLine = [SELECT Id, SBQQ__Product__c FROM SBQQ__QuoteLine__c LIMIT 1];
		SBQQ__Subscription__c subscription = [SELECT Id FROM SBQQ__Subscription__c LIMIT 1];

		Test.startTest();

		// Create quote line with Source set (clone scenario - should be skipped)
		SBQQ__QuoteLine__c cloneQuoteLine = new SBQQ__QuoteLine__c(
			SBQQ__Quote__c = amendmentQuote.Id,
			SBQQ__Product__c = baseQuoteLine.SBQQ__Product__c,
			SBQQ__UpgradedSubscription__c = subscription.Id,
			SBQQ__Source__c = baseQuoteLine.Id,
			SBQQ__Number__c = 1,
			SBQQ__Quantity__c = 500,
			PMC_CPQ_QuoteRecordType__c = 'Domestic NA',
			PMC_CPQ_QuoteRecordSubType__c = 'Feed',
			PMC_CPQ_ContractType__c = 'Priced'
		);
		insert cloneQuoteLine;

		Test.stopTest();

		// Verify no fields were copied because Source was set (clone)
		SBQQ__QuoteLine__c insertedQL = [
			SELECT Id, PMC_CPQ_ModeofTransportation__c, PMC_CPQ_Incoterms1__c
			FROM SBQQ__QuoteLine__c
			WHERE Id = :cloneQuoteLine.Id
		];

		System.assertEquals(null, insertedQL.PMC_CPQ_ModeofTransportation__c, 'Clone quote line should not have copied values');
		System.assertEquals(null, insertedQL.PMC_CPQ_Incoterms1__c, 'Clone quote line should not have copied values');
	}

	/**
	 * @description Test updateVCOInsertedLineItems - VCO false/null on parent quote
	 */
	@isTest
	static void testUpdateVCOInsertedLineItemsFalse() {
		SBQQ__Quote__c baseQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c != 'Amendment' LIMIT 1];
		Product2 product = [SELECT Id FROM Product2 LIMIT 1];

		// Ensure VCO is false on the parent quote
		baseQuote.PMC_CPQ_VCOQuotation__c = false;
		update baseQuote;

		Test.startTest();

		SBQQ.TriggerControl.disable();
		SBQQ__QuoteLine__c newQuoteLine = new SBQQ__QuoteLine__c(
			SBQQ__Quote__c = baseQuote.Id,
			SBQQ__Product__c = product.Id,
			SBQQ__Number__c = 4,
			SBQQ__Quantity__c = 1000,
			PMC_CPQ_QuoteRecordType__c = 'Domestic NA',
			PMC_CPQ_QuoteRecordSubType__c = 'Feed',
			PMC_CPQ_ContractType__c = 'Priced'
		);
		insert newQuoteLine;
		SBQQ.TriggerControl.enable();

		Test.stopTest();

		SBQQ__QuoteLine__c insertedQL = [
			SELECT Id, PMC_CPQ_VCOQuotation__c
			FROM SBQQ__QuoteLine__c
			WHERE Id = :newQuoteLine.Id
		];

		System.assertEquals(false, insertedQL.PMC_CPQ_VCOQuotation__c, 'VCO Quotation should default to false');
	}

	/**
	 * @description Test setContractUpdateCheckEligibilityStatus - eligible scenario (no price/margin change)
	 */
	@isTest
	static void testSetContractUpdateCheckEligibilityStatusEligible() {
		SBQQ__Quote__c baseQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c != 'Amendment' LIMIT 1];
		SBQQ__QuoteLine__c quoteLine = [
			SELECT Id, Name, SBQQ__Quote__c, PMC_CPQ_FinalPricePerTonne__c, PMC_CPQ_Margin__c
			FROM SBQQ__QuoteLine__c
			WHERE SBQQ__Quote__c = :baseQuote.Id
			LIMIT 1
		];

		MassUpdateExecution__c exec = new MassUpdateExecution__c(
			Feature__c = 'ContractDateUpdate',
			Status__c = 'In Progress'
		);
		insert exec;

		MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
			MassUpdateExecution__c = exec.Id,
			CreatedQuote__c = baseQuote.Id,
			Feature__c = 'ContractDateUpdate',
			Step__c = 'Check Eligibility',
			Status__c = 'In Progress'
		);
		insert line;

		Test.startTest();

		// Build old map with same values (no change to FinalPricePerTonne or Margin)
		Map<Id, SBQQ__QuoteLine__c> oldMap = new Map<Id, SBQQ__QuoteLine__c>{
			quoteLine.Id => quoteLine.clone(true, true, true, true)
		};

		// Simulate a non-price field change
		quoteLine.PMC_CPQ_Incoterms1__c = 'FOB';

		PMC_CPQ_QuoteLineTriggerHelper.setContractUpdateCheckEligibilityStatus(
			new List<SBQQ__QuoteLine__c>{ quoteLine },
			oldMap
		);

		Test.stopTest();

		MassUpdateExecutionLine__c updatedLine = [
			SELECT Id, CheckEligibilityStatus__c, Status__c, Step__c
			FROM MassUpdateExecutionLine__c
			WHERE Id = :line.Id
		];

		System.assertEquals('Eligible', updatedLine.CheckEligibilityStatus__c, 'Should be eligible when FinalPricePerTonne and Margin are unchanged');
		System.assertEquals('Pending', updatedLine.Status__c, 'Status should be Pending');
		System.assertEquals('Submit for Approval', updatedLine.Step__c, 'Step should advance to Submit for Approval');
	}

	/**
	 * @description Test setContractUpdateCheckEligibilityStatus - not eligible when FinalPricePerTonne changes
	 */
	@isTest
	static void testSetContractUpdateCheckEligibilityStatusNotEligiblePrice() {
		SBQQ__Quote__c baseQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c != 'Amendment' LIMIT 1];
		SBQQ__QuoteLine__c quoteLine = [
			SELECT Id, Name, SBQQ__Quote__c, PMC_CPQ_FinalPricePerTonne__c, PMC_CPQ_Margin__c
			FROM SBQQ__QuoteLine__c
			WHERE SBQQ__Quote__c = :baseQuote.Id
			LIMIT 1
		];

		MassUpdateExecution__c exec = new MassUpdateExecution__c(
			Feature__c = 'ContractDateUpdate',
			Status__c = 'In Progress'
		);
		insert exec;

		MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
			MassUpdateExecution__c = exec.Id,
			CreatedQuote__c = baseQuote.Id,
			Feature__c = 'ContractDateUpdate',
			Step__c = 'Check Eligibility',
			Status__c = 'In Progress'
		);
		insert line;

		Test.startTest();

		// Build old map with original values
		Map<Id, SBQQ__QuoteLine__c> oldMap = new Map<Id, SBQQ__QuoteLine__c>{
			quoteLine.Id => quoteLine.clone(true, true, true, true)
		};

		// Change FinalPricePerTonne (should make it not eligible)
		quoteLine.PMC_CPQ_FinalPricePerTonne__c = quoteLine.PMC_CPQ_FinalPricePerTonne__c != null
			? quoteLine.PMC_CPQ_FinalPricePerTonne__c + 100
			: 100;

		PMC_CPQ_QuoteLineTriggerHelper.setContractUpdateCheckEligibilityStatus(
			new List<SBQQ__QuoteLine__c>{ quoteLine },
			oldMap
		);

		Test.stopTest();

		MassUpdateExecutionLine__c updatedLine = [
			SELECT Id, CheckEligibilityStatus__c, Status__c, Step__c, Message__c
			FROM MassUpdateExecutionLine__c
			WHERE Id = :line.Id
		];

		System.assertEquals('Not Eligible', updatedLine.CheckEligibilityStatus__c, 'Should be not eligible when FinalPricePerTonne changes');
		System.assertEquals('Error', updatedLine.Status__c, 'Status should be Error');
		System.assertEquals('Check Eligibility', updatedLine.Step__c, 'Step should remain at Check Eligibility');
	}

	/**
	 * @description Test setContractUpdateCheckEligibilityStatus - not eligible when Margin changes
	 */
	@isTest
	static void testSetContractUpdateCheckEligibilityStatusNotEligibleMargin() {
		SBQQ__Quote__c baseQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Type__c != 'Amendment' LIMIT 1];
		SBQQ__QuoteLine__c quoteLine = [
			SELECT Id, Name, SBQQ__Quote__c, PMC_CPQ_FinalPricePerTonne__c, PMC_CPQ_Margin__c
			FROM SBQQ__QuoteLine__c
			WHERE SBQQ__Quote__c = :baseQuote.Id
			LIMIT 1
		];

		MassUpdateExecution__c exec = new MassUpdateExecution__c(
			Feature__c = 'ContractDateUpdate',
			Status__c = 'In Progress'
		);
		insert exec;

		MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
			MassUpdateExecution__c = exec.Id,
			CreatedQuote__c = baseQuote.Id,
			Feature__c = 'ContractDateUpdate',
			Step__c = 'Check Eligibility',
			Status__c = 'In Progress'
		);
		insert line;

		Test.startTest();

		// Build old map with original values
		Map<Id, SBQQ__QuoteLine__c> oldMap = new Map<Id, SBQQ__QuoteLine__c>{
			quoteLine.Id => quoteLine.clone(true, true, true, true)
		};

		// Change Margin (should make it not eligible)
		quoteLine.PMC_CPQ_Margin__c = quoteLine.PMC_CPQ_Margin__c != null
			? quoteLine.PMC_CPQ_Margin__c + 50
			: 50;

		PMC_CPQ_QuoteLineTriggerHelper.setContractUpdateCheckEligibilityStatus(
			new List<SBQQ__QuoteLine__c>{ quoteLine },
			oldMap
		);

		Test.stopTest();

		MassUpdateExecutionLine__c updatedLine = [
			SELECT Id, CheckEligibilityStatus__c, Status__c, Message__c
			FROM MassUpdateExecutionLine__c
			WHERE Id = :line.Id
		];

		System.assertEquals('Not Eligible', updatedLine.CheckEligibilityStatus__c, 'Should be not eligible when Margin changes');
		System.assertEquals('Error', updatedLine.Status__c, 'Status should be Error');
	}

	/**
	 * @description Test non-approved quote line deletion is allowed
	 */
	@isTest
	static void testAllowNonApprovedQuoteLineDeletion() {
		SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];

		Test.startTest();
		delete quoteLine;
		Test.stopTest();

		List<SBQQ__QuoteLine__c> remaining = [SELECT Id FROM SBQQ__QuoteLine__c WHERE Id = :quoteLine.Id];
		System.assertEquals(0, remaining.size(), 'Non-approved quote line should be deleted');
	}

	@isTest
	static void testQuoteModel() {
		QuoteModel model = new QuoteModel();
		model.record = new SBQQ__Quote__c();
		model.lineItems = new QuoteLineModel[]{};
		model.lineItemGroups = new QuoteLineGroupModel[]{};
		model.nextKey = 1;
		model.applyAdditionalDiscountLast = true;
		model.applyPartnerDiscountFirst = true;
		model.channelDiscountsOffList = true;
		model.customerTotal = 100.0;
		model.netTotal = 80.0;
		model.netNonSegmentTotal = 90.0;

		System.assertNotEquals(null, model, 'QuoteModel should be instantiated');
		System.assertNotEquals(null, model.record, 'record should be set');
		System.assertEquals(1, model.nextKey, 'nextKey should be set');
	}

	@isTest
	static void testQuoteLineModel() {
		QuoteLineModel model = new QuoteLineModel();
		model.record = new SBQQ__QuoteLine__c();
		model.amountDiscountProrated = true;
		model.parentGroupKey = 1;
		model.parentItemKey = 2;
		model.key = 3;
		model.upliftable = true;
		model.configurationType = 'TestType';
		model.configurationEvent = 'TestEvent';
		model.reconfigurationDisabled = true;
		model.descriptionLocked = true;
		model.productQuantityEditable = true;
		model.productQuantityScale = 2.0;
		model.dimensionType = 'TestDim';
		model.productHasDimensions = true;
		model.targetCustomerAmount = 50.0;
		model.targetCustomerTotal = 150.0;

		System.assertNotEquals(null, model, 'QuoteLineModel should be instantiated');
		System.assertNotEquals(null, model.record, 'record should be set');
		System.assertEquals(3, model.key, 'key should be set');
	}

	@isTest
	static void testQuoteLineGroupModel() {
		QuoteLineGroupModel model = new QuoteLineGroupModel();
		model.record = new SBQQ__QuoteLineGroup__c();
		model.netNonSegmentTotal = 200.0;
		model.key = 4;

		System.assertNotEquals(null, model, 'QuoteLineGroupModel should be instantiated');
		System.assertNotEquals(null, model.record, 'record should be set');
		System.assertEquals(4, model.key, 'key should be set');
	}
}