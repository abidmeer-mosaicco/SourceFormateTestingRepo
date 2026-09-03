/** @description This is the test class for PMC_CPQ_GetPriceUtilityClass.
 *  @author Assistant
 *  @GDASF-10668 Related to Get Price utility functionality
 */

@isTest
public without sharing class PMC_CPQ_GetPriceUtilityClassTest {
	/**
	 * @description setup users to create sales area and test data.
	 * @author Assistant
	 */
	@TestSetup
	public static void setup() {
		List<String> lstProfileNames = new List<String>{ 'System Administrator', 'Sales User' };
		List<String> lstPermissionSetGroupNames = new List<String>{ 'PMC_Administrator_Permission_Set_Group', 'PMC_SLS_Permission_Set_Group' };
		Map<String, Id> mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
		Map<String, PermissionSetGroup> mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionSetGroupNames);
		Integer intuserCount = 0;
		User objSystemAdminUser;
		User objSalesUser;
		List<User> lstUser = PMC_TestUtilityClass.createUser(2);
		for (User objUser : lstUser) {
			if (intuserCount == 0) {
				objUser.LastName = 'Admin User Test';
				objUser.ProfileId = mapOfProfiles.get('System Administrator');
				objUser.FederationIdentifier = objUser.Username + 'Admin';
			} else if (intuserCount == 1) {
				objUser.LastName = 'Sales User Test';
				objUser.ProfileId = mapOfProfiles.get('Sales User');
				objUser.FederationIdentifier = objUser.Username + 'Sales';
			}
			objUser.isActive = true;
			objUser.MobilePhone = '1234567890';
			objUser.UserPermissionsKnowledgeUser = true;
			objUser.LanguageLocaleKey = 'en_US';
			objUser.PMC_CPQ_SalesRegion__c = 'North America';
			objUser.PMC_CPQ_SalesArea__c = 'Mosaic Global Sales LLC Domestic Common';
			objUser.PMC_CPQ_PrimaryBusinessType__c = 'Feed';
			intuserCount = intuserCount + 1;
		}
		insert lstUser;
		objSystemAdminUser = lstUser[0];
		objSalesUser = lstUser[1];
		PMC_TestUtilityClass.assignPermissionSetGroupToUsers(
			new List<User>{ objSystemAdminUser },
			mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group')
		);
		PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{ objSalesUser }, mapOfPermissionGrp.get('PMC_SLS_Permission_Set_Group'));

		System.runAs(objSystemAdminUser) {
			//Create Sales area
			List<PMC_SS_SalesArea__c> lstSalesArea = PMC_TestUtilityClass.createSalesArea(1, 'Master');
			lstSalesArea[0].PMC_SS_SalesOrganization__c = 'Mosaic Global Sales LLC';
			lstSalesArea[0].PMC_CPQ_SAPSalesOrganization__c = '10020010';
			lstSalesArea[0].PMC_SS_DistributionChannel__c = 'Common';
			lstSalesArea[0].PMC_SS_Division__c = '10';
			update lstSalesArea;
		}
	}

	/**
	 * @description createTestQuotes Creates test quotes with quote lines and raw materials
	 * @param numQuote - Number of quotes to be created
	 * @param lstUser - list of users
	 * @return lstQuotes - List<SBQQ__Quote__c> to be returned
	 */
	public static List<SBQQ__Quote__c> createTestQuotes(Integer numQuote, List<User> lstUser) {
		PMC_ProcessSwitches__c bypassSetting = PMC_ProcessSwitches__c.getOrgDefaults();

		List<SBQQ__Quote__c> lstQuotes = new List<SBQQ__Quote__c>();
		List<Opportunity> lstOpportunities = PMC_TestUtilityClass.createOpportunity(2, 'Master');
		update lstOpportunities;

		// Get existing SalesArea
		List<PMC_SS_SalesArea__c> lstSalesArea = [SELECT Id FROM PMC_SS_SalesArea__c WITH SECURITY_ENFORCED LIMIT 1];

		Account accnt = new Account();
		accnt.Id = lstOpportunities[0].AccountId;
		accnt.Type = 'Sold-to';
		accnt.PMC_SS_AccountExternalID__c = '8923743784';
		accnt.PMC_SS_SAPCustomerNumber__c = '4208024022';
		accnt.BillingCountryCode = 'US';
		accnt.BillingStateCode = 'CA';

		bypassSetting.PMC_BypassValidationRule__c = true;
		upsert bypassSetting;
		update accnt;
		bypassSetting.PMC_BypassValidationRule__c = false;
		upsert bypassSetting;

		List<Account> lstAccount = new List<Account>();
		lstAccount.add(accnt);
		PMC_TestUtilityClass.createAccountSalesAreaRelationship(lstAccount, lstSalesArea);
		PMC_SS_AccountSalesAreaRelationship__c relObj = new PMC_SS_AccountSalesAreaRelationship__c(
			PMC_SS_Account__c = lstAccount[0].Id,
			PMC_SS_SalesArea__c = lstSalesArea[0].Id
		);
		insert relObj;

		List<Contact> lstContacts;
		lstContacts = PMC_TestUtilityClass.createContact(1, 'Master');
		lstContacts[0].AccountId = accnt.Id;
		update lstContacts;

		// Create quotes directly with all required fields
		SBQQ__Quote__c objQuote = new SBQQ__Quote__c();
		objQuote.SBQQ__Opportunity2__c = lstOpportunities[0].id;
		objQuote.PMC_CPQ_ContractStart__c = System.today().addDays(10);
		objQuote.PMC_CPQ_ContractEnd__c = System.today().addDays(40);
		objQuote.PMC_CPQ_PrimaryContact__c = lstContacts[0].id;
		objQuote.PMC_CPQ_CustomCreatedDate__c = System.now();
		objQuote.PMC_CPQ_AccountManager__c = lstUser[0].Id;
		objQuote.PMC_CPQ_Region__c = 'North America';
		objQuote.PMC_CPQ_ExpiresOn__c = Datetime.now().addDays(10);
		objQuote.PMC_CPQ_QuoteRecordSubType__c = 'Feed';
		objQuote.PMC_CPQ_SalesAreaCombination__c = 'Mosaic Global Sales LLC Domestic Common';
		objQuote.PMC_CPQ_SalesArea__c = relObj.Id;

		try {
			Database.insert(objQuote, true);
			lstQuotes.add(objQuote);
		} catch (DmlException e) {
			System.debug('Quote insert failed: ' + e.getMessage());
			throw new System.AssertException('Failed to create quote: ' + e.getMessage());
		}

		// Create test product
		Product2 objproduct = new Product2(Name = 'Test Product', StockKeepingUnit = 'SKU-001');
		insert objproduct;

		// Product Location - follow exact pattern from working test classes
		Schema.Location loc = new Schema.Location(Name = 'TestName');
		loc.PMC_CPQ_Plant__c = 'Test';
		loc.LocationType = 'Site';
		loc.RecordTypeId = [SELECT Name, SobjectType, Id FROM RecordType WHERE Name = 'Origin Location'][0].Id;
		insert loc;
		PMC_CPQ_ProductLocation__c prodLoc = new PMC_CPQ_ProductLocation__c(PMC_CPQ_Location__c = loc.Id, PMC_CPQ_ProductName__c = objproduct.Id);
		insert prodLoc;

		PMC_SS_AccountPartnerRelationships__c accntRelAcc = new PMC_SS_AccountPartnerRelationships__c(PMC_SS_Account__c = accnt.Id);
		accntRelAcc.Name = 'Test';
		accntRelAcc.PMC_SS_Account__c = accnt.Id;
		accntRelAcc.PMC_SS_RelatedAccount__c = accnt.Id;
		accntRelAcc.PMC_SS_Type__c = 'Ship-to';
		accntRelAcc.PMC_SS_RelatedAccountSalesArea__c = relObj.Id;
		insert accntRelAcc;

		// Create multiple quote lines
		List<SBQQ__QuoteLine__c> lstQuoteLines = new List<SBQQ__QuoteLine__c>();
		for (Integer i = 0; i < 2; i++) {
			SBQQ__QuoteLine__c objQuoteLine = new SBQQ__QuoteLine__c(
				PMC_CPQ_SoldToShipToJunction__c = accntRelAcc.Id,
				SBQQ__Quote__c = lstQuotes[0].Id,
				SBQQ__Product__c = objproduct.Id,
				PMC_CPQ_Discount__c = 10,
				SBQQ__Number__c = i + 1,
				PMC_CPQ_QuoteRecordType__c = 'Domestic NA',
				PMC_CPQ_ModeofTransportation__c = 'Rail',
				PMC_CPQ_UnitofMeasure__c = 'STN',
				PMC_CPQ_QuoteRecordSubType__c = 'Feed',
				PMC_CPQ_Incoterms1__c = 'CFR',
				PMC_CPQ_ShipTo__c = accnt.Id,
				PMC_CPQ_ProductLocation__c = prodLoc.Id,
				SBQQ__Quantity__c = 1,
				SBQQ__ListPrice__c = 10,
				PMC_CPQ_EstFreightPrice__c = 100,
				PMC_CPQ_FinalPricePerTonne__c = 20,
				PMC_CPQ_ContractType__c = 'Priced',
				PMC_CPQ_DeliveryStartDate__c = System.today().addDays(20),
				PMC_CPQ_DeliveryEndDate__c = System.today().addDays(23),
				PMC_CPQ_PaymentTerms__c = 'Net 30 Days - From Invoicing Date',
				PMC_CPQ_CropType__c = 'Coffee'
			);
			lstQuoteLines.add(objQuoteLine);
		}
		insert lstQuoteLines;

		// Create test raw materials
		List<PMC_CPQ_RawMaterial__c> lstRawMaterials = new List<PMC_CPQ_RawMaterial__c>();
		for (Integer i = 0; i < 3; i++) {
			Integer quoteLineIndex = Math.mod(i, 2);
			PMC_CPQ_RawMaterial__c rawMat = new PMC_CPQ_RawMaterial__c(
				PMC_CPQ_Quote__c = lstQuotes[0].Id,
				PMC_CPQ_Product__c = objproduct.Id,
				PMC_CPQ_QuoteLine__c = lstQuoteLines[quoteLineIndex].Id
			);
			lstRawMaterials.add(rawMat);
		}
		insert lstRawMaterials;

		return lstQuotes;
	}

	/**
	 * @description Test errorLogExit method with valid exception message
	 */
	@isTest
	public static void testErrorLogExitWithExceptionMessage() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createTestQuotes(1, lstUser);
			String exceptionMessage = 'Test exception occurred';

			Test.startTest();
			PMC_CPQ_GetPriceUtilityClass.errorLogExit(lstQuotes, exceptionMessage);
			Test.stopTest();

			// Verify quote was updated with error status
			SBQQ__Quote__c updatedQuote = [
				SELECT PMC_CPQ_IntegrationStatus__c, PMC_CPQ_IntegrationMessage__c
				FROM SBQQ__Quote__c
				WHERE Id = :lstQuotes[0].Id
			];
			System.assertEquals('Error', updatedQuote.PMC_CPQ_IntegrationStatus__c, 'Integration status should be Error');
			System.assert(updatedQuote.PMC_CPQ_IntegrationMessage__c.contains('Get Price: '), 'Integration message should contain prefix');
		}
	}

	/**
	 * @description Test errorLogExit method with null exception message
	 */
	@isTest
	public static void testErrorLogExitWithNullExceptionMessage() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createTestQuotes(1, lstUser);
			String originalStatus = lstQuotes[0].PMC_CPQ_IntegrationStatus__c;

			Test.startTest();
			PMC_CPQ_GetPriceUtilityClass.errorLogExit(lstQuotes, null);
			Test.stopTest();

			// Verify quote was not updated when exception message is null
			SBQQ__Quote__c updatedQuote = [
				SELECT PMC_CPQ_IntegrationStatus__c
				FROM SBQQ__Quote__c
				WHERE Id = :lstQuotes[0].Id
			];
			// Quote should not be updated when exception message is null
			System.assertNotEquals(
				'Error',
				updatedQuote.PMC_CPQ_IntegrationStatus__c,
				'Integration status should not be changed when exception is null'
			);
		}
	}

	/**
	 * @description Test stringProcess method with various JSON structures
	 */
	@isTest
	public static void testStringProcess() {
		Test.startTest();

		// Test with simple object
		Map<String, String> testMap = new Map<String, String>{ 'key1' => 'value1', 'key2' => 'value2' };
		String result = PMC_CPQ_GetPriceUtilityClass.stringProcess(testMap);
		System.assertNotEquals(null, result, 'Result should not be null');
		System.assert(!result.contains('\\\\'), 'Result should not contain double backslashes');
		System.assert(!result.contains('\n'), 'Result should not contain newlines');

		// Test with complex nested object
		Map<String, Object> complexMap = new Map<String, Object>{
			'header' => new Map<String, String>{ 'price' => '100.00' },
			'items' => new List<String>{ 'item1', 'item2' }
		};
		String complexResult = PMC_CPQ_GetPriceUtilityClass.stringProcess(complexMap);
		System.assertNotEquals(null, complexResult, 'Complex result should not be null');

		Test.stopTest();
	}

	/**
	 * @description Test getQueryParam method with field map and filter string
	 */
	@isTest
	public static void testGetQueryParam() {
		Test.startTest();

		// Create mock field map data (would normally come from custom metadata)
		List<PMC_CPQ_IntegrationFieldMap__mdt> mockFieldMap = new List<PMC_CPQ_IntegrationFieldMap__mdt>();
		// Note: In a real test, you'd query actual metadata or use a different approach
		// For now, we'll test the method behavior with empty list and verify it adds ' Id'

		String result = PMC_CPQ_GetPriceUtilityClass.getQueryParam(mockFieldMap, null);
		System.assertEquals(' Id', result, 'Result should contain Id field when field map is empty');

		String resultWithFilter = PMC_CPQ_GetPriceUtilityClass.getQueryParam(mockFieldMap, 'alias');
		System.assertEquals(' Id', resultWithFilter, 'Result with filter should still contain Id field');

		Test.stopTest();
	}

	/**
	 * @description Test getQuoteLineMap method
	 */
	@isTest
	public static void testGetQuoteLineMap() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createTestQuotes(1, lstUser);

			Test.startTest();
			Map<String, SBQQ__QuoteLine__c> resultMap = PMC_CPQ_GetPriceUtilityClass.getQuoteLineMap(lstQuotes[0].Id);
			Test.stopTest();

			System.assertEquals(2, resultMap.size(), 'Map should contain 2 quote lines');
			System.assert(resultMap.containsKey('1'), 'Map should contain quote line with number 1');
			System.assert(resultMap.containsKey('2'), 'Map should contain quote line with number 2');
		}
	}

	/**
	 * @description Test manangeRawMat method with positive diff (delete scenario)
	 */
	@isTest
	public static void testManangeRawMatWithPositiveDiff() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createTestQuotes(1, lstUser);
			List<PMC_CPQ_RawMaterial__c> rawMaterials = [SELECT Id FROM PMC_CPQ_RawMaterial__c WHERE PMC_CPQ_Quote__c = :lstQuotes[0].Id];
			Integer originalSize = rawMaterials.size();

			Test.startTest();
			// Test with positive diff (should delete records)
			List<PMC_CPQ_RawMaterial__c> result = PMC_CPQ_GetPriceUtilityClass.manangeRawMat(1, lstQuotes[0].Id, rawMaterials);
			Test.stopTest();

			System.assertEquals(originalSize - 1, result.size(), 'Should have one less record after positive diff');
		}
	}

	/**
	 * @description Test manangeRawMat method with negative diff (insert scenario)
	 */
	@isTest
	public static void testManangeRawMatWithNegativeDiff() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createTestQuotes(1, lstUser);
			List<PMC_CPQ_RawMaterial__c> rawMaterials = [SELECT Id FROM PMC_CPQ_RawMaterial__c WHERE PMC_CPQ_Quote__c = :lstQuotes[0].Id];
			Integer originalSize = rawMaterials.size();

			Test.startTest();
			// Test with negative diff (should insert records)
			List<PMC_CPQ_RawMaterial__c> result = PMC_CPQ_GetPriceUtilityClass.manangeRawMat(-2, lstQuotes[0].Id, rawMaterials);
			Test.stopTest();

			System.assertEquals(originalSize + 2, result.size(), 'Should have two more records after negative diff');
		}
	}

	/**
	 * @description Test manangeRawMat method with zero diff (no change scenario)
	 */
	@isTest
	public static void testManangeRawMatWithZeroDiff() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createTestQuotes(1, lstUser);
			List<PMC_CPQ_RawMaterial__c> rawMaterials = [SELECT Id FROM PMC_CPQ_RawMaterial__c WHERE PMC_CPQ_Quote__c = :lstQuotes[0].Id];
			Integer originalSize = rawMaterials.size();

			Test.startTest();
			// Test with zero diff (should not change records)
			List<PMC_CPQ_RawMaterial__c> result = PMC_CPQ_GetPriceUtilityClass.manangeRawMat(0, lstQuotes[0].Id, rawMaterials);
			Test.stopTest();

			System.assertEquals(originalSize, result.size(), 'Should have same number of records with zero diff');
		}
	}

	/**
	 * @description Test makeRawMaterialRecords future method
	 */
	@isTest
	public static void testMakeRawMaterialRecords() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createTestQuotes(1, lstUser);

			// Create test raw material JSON response
			String rawMatJson =
				'[' +
				'{"ItmNumber":"1","Zzcomponent":"SKU-001","TestField":"TestValue1"},' +
				'{"ItmNumber":"2","Zzcomponent":"SKU-001","TestField":"TestValue2"}' +
				']';

			Test.startTest();
			PMC_CPQ_GetPriceUtilityClass.makeRawMaterialRecords(rawMatJson, lstQuotes[0].Id);
			Test.stopTest();

			// Verify raw materials were processed
			List<PMC_CPQ_RawMaterial__c> updatedRawMaterials = [
				SELECT Id, PMC_CPQ_QuoteLine__c, PMC_CPQ_Product__c
				FROM PMC_CPQ_RawMaterial__c
				WHERE PMC_CPQ_Quote__c = :lstQuotes[0].Id
			];
			System.assert(!updatedRawMaterials.isEmpty(), 'Raw materials should exist after processing');
		}
	}

	/**
	 * @description Test edge case scenarios
	 */
	@isTest
	public static void testEdgeCases() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createTestQuotes(1, lstUser);

			Test.startTest();

			// Test getQuoteLineMap with quote that has no quote lines
			SBQQ__Quote__c emptyQuote = new SBQQ__Quote__c(
				SBQQ__Opportunity2__c = lstQuotes[0].SBQQ__Opportunity2__c,
				PMC_CPQ_AccountManager__c = lstUser[0].Id,
				PMC_CPQ_Region__c = 'North America'
			);
			insert emptyQuote;

			Map<String, SBQQ__QuoteLine__c> emptyMap = PMC_CPQ_GetPriceUtilityClass.getQuoteLineMap(emptyQuote.Id);
			System.assertEquals(0, emptyMap.size(), 'Map should be empty for quote with no lines');

			// Test stringProcess with null
			String nullResult = PMC_CPQ_GetPriceUtilityClass.stringProcess(null);
			System.assertNotEquals(null, nullResult, 'Should handle null input gracefully');

			Test.stopTest();
		}
	}
}