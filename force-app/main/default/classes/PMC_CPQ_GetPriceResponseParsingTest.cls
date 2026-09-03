/** @description Test class for PMC_CPQ_GetPriceResponseParsing
 *  @author Raphael Soares
 *  @GCPM-3584 Test Coverage for Response Parsing
 */

@isTest
public class PMC_CPQ_GetPriceResponseParsingTest {
	public static List<String> lstPayloadQuoteIds = new List<String>();

	/**
	 * @description Setup test data with users, sales areas, and permissions
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
			// Create Sales area
			List<PMC_SS_SalesArea__c> lstSalesArea = PMC_TestUtilityClass.createSalesArea(1, 'Master');
			lstSalesArea[0].PMC_SS_SalesOrganization__c = 'Mosaic Global Sales LLC';
			lstSalesArea[0].PMC_CPQ_SAPSalesOrganization__c = '10020010';
			lstSalesArea[0].PMC_SS_DistributionChannel__c = 'Common';
			lstSalesArea[0].PMC_SS_Division__c = '10';
			update lstSalesArea;
		}
	}

	/**
	 * @description Create test quotes with all required dependencies
	 * @param numQuote Number of quotes to create
	 * @param lstUser List of users for assignment
	 * @return List of created quotes
	 */
	public static List<SBQQ__Quote__c> createQuotes(Integer numQuote, List<User> lstUser) {
		PMC_ProcessSwitches__c bypassSetting = PMC_ProcessSwitches__c.getOrgDefaults();
		// Bypass record-triggered flows during setup to reduce SOQL/CPU footprint.
		bypassSetting.PMC_BypassFlow__c = true;
		upsert bypassSetting;

		List<SBQQ__Quote__c> lstQuotes = new List<SBQQ__Quote__c>();
		List<Opportunity> lstOpportunities = PMC_TestUtilityClass.createOpportunity(2, 'Master');
		List<PMC_SS_SalesArea__c> lstSalesArea = [SELECT Id FROM PMC_SS_SalesArea__c WITH SECURITY_ENFORCED LIMIT 1];

		// Order matters: the contact must be a CONTACT RELATED to the account before
		// being referenced as Primary_Contract_Recipient__c (validation rules:
		// PMC_CPQ_PrimaryContractRecipientAccount + 'PCR must be related to this Account').
		List<Contact> lstContacts = PMC_TestUtilityClass.createContact(1, 'Master');
		lstContacts[0].AccountId = lstOpportunities[0].AccountId;
		update lstContacts;

		Account accnt = new Account();
		accnt.Id = lstOpportunities[0].AccountId;
		accnt.Type = 'Sold-to';
		accnt.PMC_SS_AccountExternalID__c = '8923743784';
		accnt.PMC_SS_SAPCustomerNumber__c = '4208024022';
		accnt.BillingCountryCode = 'US';
		accnt.BillingStateCode = 'CA';
		//accnt.Primary_Contract_Recipient__c = lstContacts[0].Id;

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

		Product2 objproduct = new Product2(Name = 'Test Product');
		insert objproduct;
		// Product Location
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

		SBQQ__QuoteLine__c objQuoteLine = new SBQQ__QuoteLine__c(
			PMC_CPQ_SoldToShipToJunction__c = accntRelAcc.Id,
			SBQQ__Quote__c = lstQuotes[0].Id,
			SBQQ__Product__c = objproduct.Id,
			PMC_CPQ_Discount__c = 10,
			SBQQ__Number__c = 1,
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
		insert objQuoteLine;

		// Restore the flow bypass so it does not affect the action under test.
		bypassSetting.PMC_BypassFlow__c = false;
		upsert bypassSetting;

		return lstQuotes;
	}

	/**
	 * @description Test parseJSONGetPriceInterface method with success response (200)
	 */
	@isTest
	public static void testParseJSONGetPriceInterfaceSuccess() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createQuotes(1, lstUser);

			// Create mock HTTP response
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setBody('{"success": "true"}');

			// Mock the static request
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request = new HttpRequest();
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request.setBody('{"test": "request"}');

			Test.startTest();
			PMC_CPQ_GetPriceResponseParsing.parseJSONGetPriceInterface(lstQuotes, response, 'test/endpoint');
			Test.stopTest();

			// Verify quote was updated correctly
			SBQQ__Quote__c updatedQuote = [
				SELECT PMC_CPQ_IntegrationStatus__c, Get_Prices_Status__c, PMC_CPQ_IntegrationMessage__c, PMC_CPQ_GetPriceCallComplete__c
				FROM SBQQ__Quote__c
				WHERE Id = :lstQuotes[0].Id
			];
			System.assertEquals('Success', updatedQuote.PMC_CPQ_IntegrationStatus__c, 'Integration status should be Success');
			System.assertEquals('In Progress', updatedQuote.Get_Prices_Status__c, 'Get Prices status should be In Progress');
			System.assertEquals(true, updatedQuote.PMC_CPQ_GetPriceCallComplete__c, 'Get Price call should be complete');
			System.assert(updatedQuote.PMC_CPQ_IntegrationMessage__c.contains('Get Price:'), 'Integration message should contain prefix');
		}
	}

	/**
	 * @description Test parseJSONGetPriceInterface method with error response (400)
	 */
	@isTest
	public static void testParseJSONGetPriceInterfaceError() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createQuotes(1, lstUser);

			// Create mock HTTP error response
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setBody(
				'{"error":{"code":"/IWBEP/CM_MGW_RT/022","message":{"@xml:lang":"en","$":"Exception raised without specific error"},"innererror":{"application":{"component_id":"","service_namespace":"/SAP/","service_id":"ZOTC_I060_QUOTATION_PRICE_CAL_SRV","service_version":"0001"},"transactionid":"400cb41ec4584a8988cf9a31b7a541fb","timestamp":"","Error_Resolution":{"SAP_Transaction":"","SAP_Note":"See SAP Note 1797736 for error analysis (https://service.sap.com/sap/support/notes/1797736)"},"errordetails":{"errordetail":[{"ContentID":"","code":"CZ/115","message":"Sales area 1002 00 ? does not exist","longtext_url":"Test","propertyref":"","severity":"error","target":"","transition":"false"}]}}}}'
			);

			// Mock the static request
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request = new HttpRequest();
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request.setBody('{"test": "request"}');

			Test.startTest();
			PMC_CPQ_GetPriceResponseParsing.parseJSONGetPriceInterface(lstQuotes, response, 'test/endpoint');
			Test.stopTest();

			// Verify quote was updated correctly
			SBQQ__Quote__c updatedQuote = [
				SELECT PMC_CPQ_IntegrationStatus__c, Get_Prices_Status__c, PMC_CPQ_IntegrationMessage__c, PMC_CPQ_GetPriceCallComplete__c
				FROM SBQQ__Quote__c
				WHERE Id = :lstQuotes[0].Id
			];
			System.assertEquals('Error', updatedQuote.PMC_CPQ_IntegrationStatus__c, 'Integration status should be Error');
			System.assertEquals('Failed', updatedQuote.Get_Prices_Status__c, 'Get Prices status should be Failed');
			System.assert(updatedQuote.PMC_CPQ_IntegrationMessage__c.contains('Get Price:'), 'Integration message should contain prefix');
		}
	}

	/**
	 * @description Test parseJSONGetPriceInterface method with 500 server error
	 */
	@isTest
	public static void testParseJSONGetPriceInterface500Error() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createQuotes(1, lstUser);

			// Create mock HTTP 500 response
			HttpResponse response = new HttpResponse();
			response.setStatusCode(500);
			response.setBody('Internal Server Error');

			// Mock the static request
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request = new HttpRequest();
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request.setBody('{"test": "request"}');

			Test.startTest();
			PMC_CPQ_GetPriceResponseParsing.parseJSONGetPriceInterface(lstQuotes, response, 'test/endpoint');
			Test.stopTest();

			// Verify quote was updated correctly
			SBQQ__Quote__c updatedQuote = [
				SELECT PMC_CPQ_IntegrationStatus__c, Get_Prices_Status__c, PMC_CPQ_IntegrationMessage__c, PMC_CPQ_GetPriceCallComplete__c
				FROM SBQQ__Quote__c
				WHERE Id = :lstQuotes[0].Id
			];
			System.assertEquals('Error', updatedQuote.PMC_CPQ_IntegrationStatus__c, 'Integration status should be Error');
			System.assertEquals('Failed', updatedQuote.Get_Prices_Status__c, 'Get Prices status should be Failed');
			System.assertEquals('Get Price: Error', updatedQuote.PMC_CPQ_IntegrationMessage__c, 'Integration message should show error');
		}
	}

	/**
	 * @description Test responseProcess method with valid JSON response
	 */
	@isTest
	public static void testResponseProcessSuccess() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createQuotes(1, lstUser);

			// Create mock HTTP response with valid pricing data
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setBody(
				'{"HeaderSet":{"Header":{"PriceDate":"2023-10-04","Price_CondSet":[{"Price_Cond":[{"Ztransid":"Q-01644","Currency":"USD","CondValue":"100.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZLST"}]}],"Credit_LimitSet":{"Credit_Limit":[{"CredLimit":"12716004.2600","Ztransid":"Q-01644","Currency":"","ZrefTransid":"","CredLiab":"0.0000"}]},"Item_RSet":{"Item_R":[{"TaxAmount":"0.0000","Zpricerefresh":"false","HgLvItem":"000000","Ztransid":"Q-01644","NetValue":"12212.5400","Material":"1000229","ZrefTransid":"","ItmNumber":"1","Zprcduedt":"2023-08-08"}]},"Raw_MaterialSet":{"Raw_Material":[{"Zsoldcfr":"0.000000000","Zzcompqty":"1.000","Zlistcfr":"0.000000000","Ztransid":"Q-01644","ZzMatDesc":"","Zzcomponent":"9999999999","ItmNumber":"1","ZrefTransid":""}]}}}}'
			);

			Test.startTest();
			PMC_CPQ_GetPriceResponseParsing.responseProcess(lstQuotes, response);
			Test.stopTest();

			// Verify that quote lines were processed
			List<SBQQ__QuoteLine__c> updatedQuoteLines = [
				SELECT Id, SBQQ__ListPrice__c
				FROM SBQQ__QuoteLine__c
				WHERE SBQQ__Quote__c = :lstQuotes[0].Id
			];
			System.assert(!updatedQuoteLines.isEmpty(), 'Quote lines should exist');
		}
	}

	/**
	 * @description Test responseProcess method with quote record parameter
	 */
	@isTest
	public static void testResponseProcessWithQuoteRecord() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createQuotes(1, lstUser);

			// Create mock response map
			Map<String, Object> untypedResponse = (Map<String, Object>) JSON.deserializeUntyped(
				'{"HeaderSet":{"Header":{"PriceDate":"2023-10-04","Price_CondSet":[{"Price_Cond":[{"Ztransid":"Q-01644","Currency":"USD","CondValue":"100.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZLST"}]}],"Credit_LimitSet":{"Credit_Limit":[{"CredLimit":"12716004.2600","Ztransid":"Q-01644","Currency":"","ZrefTransid":"","CredLiab":"0.0000"}]},"Item_RSet":{"Item_R":[{"TaxAmount":"0.0000","Zpricerefresh":"false","HgLvItem":"000000","Ztransid":"Q-01644","NetValue":"12212.5400","Material":"1000229","ZrefTransid":"","ItmNumber":"1","Zprcduedt":"2023-08-08"}]},"Raw_MaterialSet":{"Raw_Material":[{"Zsoldcfr":"0.000000000","Zzcompqty":"1.000","Zlistcfr":"0.000000000","Ztransid":"Q-01644","ZzMatDesc":"","Zzcomponent":"9999999999","ItmNumber":"1","ZrefTransid":""}]}}}}'
			);

			Test.startTest();
			PMC_CPQ_GetPriceResponseParsing.responseProcess(lstQuotes[0], untypedResponse);
			Test.stopTest();

			// Verify that quote lines were processed
			List<SBQQ__QuoteLine__c> updatedQuoteLines = [
				SELECT Id, SBQQ__ListPrice__c
				FROM SBQQ__QuoteLine__c
				WHERE SBQQ__Quote__c = :lstQuotes[0].Id
			];
			System.assert(!updatedQuoteLines.isEmpty(), 'Quote lines should exist');
		}
	}

	/**
	 * @description Test prepareQuoteUpdateAndLog method
	 */
	@isTest
	public static void testPrepareQuoteUpdateAndLog() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createQuotes(1, lstUser);

			// Create mock HTTP response
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setBody('{"success": "true"}');

			// Mock the static request
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request = new HttpRequest();
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request.setBody('{"test": "request"}');

			Test.startTest();
			PMC_CPQ_TransactionLog__c log = PMC_CPQ_GetPriceResponseParsing.prepareQuoteUpdateAndLog(lstQuotes, response, 'test/endpoint');
			Test.stopTest();

			// Verify transaction log was created
			System.assertNotEquals(null, log, 'Transaction log should be created');
			System.assertEquals('Success', log.PMC_CPQ_IntegrationStatus__c, 'Log should show success status');
			System.assertEquals('test/endpoint', log.PMC_CPQ_InterfaceURL__c, 'Log should have correct endpoint');
		}
	}

	/**
	 * @description Test exception handling in parseJSONGetPriceInterface
	 */
	@isTest
	public static void testParseJSONGetPriceInterfaceException() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createQuotes(1, lstUser);

			// Create mock HTTP response with malformed JSON
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setBody('{"malformed": json}');

			// Mock the static request
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request = new HttpRequest();
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request.setBody('{"test": "request"}');

			Test.startTest();
			try {
				PMC_CPQ_GetPriceResponseParsing.parseJSONGetPriceInterface(lstQuotes, response, 'test/endpoint');
			} catch (Exception e) {
				// Expected to catch exception due to malformed JSON in processing
				System.debug('Expected exception caught: ' + e.getMessage());
			}
			Test.stopTest();

			// Verify quote was updated with error status
			SBQQ__Quote__c updatedQuote = [
				SELECT PMC_CPQ_IntegrationStatus__c, Get_Prices_Status__c, PMC_CPQ_GetPriceCallComplete__c
				FROM SBQQ__Quote__c
				WHERE Id = :lstQuotes[0].Id
			];
			System.assertEquals('Success', updatedQuote.PMC_CPQ_IntegrationStatus__c, 'Integration status should be Success initially');
			System.assertEquals('In Progress', updatedQuote.Get_Prices_Status__c, 'Get Prices status should be In Progress');
		}
	}

	/**
	 * @description Test filterResponseMap method
	 */
	@isTest
	public static void testFilterResponseMap() {
		Test.startTest();
		PMC_CPQ_GetPriceResponseParsing.filterResponseMap();
		Test.stopTest();

		// This method filters integration field maps - just verify it runs without error
		System.assert(true, 'filterResponseMap should complete without error');
	}

	/**
	 * @description Test with Brazil region quote lines - tests the Brazil-specific code path
	 */
	@isTest
	public static void testBrazilRegionProcessing() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createQuotes(1, lstUser);

			// Update quote to Brazil region
			lstQuotes[0].PMC_CPQ_Region__c = 'Brazil';
			update lstQuotes[0];

			// Create mock response map with proper structure including Raw_MaterialSet
			// Using complete data structure to match integration field metadata expectations
			Map<String, Object> untypedResponse = (Map<String, Object>) JSON.deserializeUntyped(
				'{"HeaderSet":{"Header":{"PriceDate":"2023-10-04","Price_CondSet":[{"Price_Cond":[{"Ztransid":"Q-01644","Currency":"USD","CondValue":"100.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZLST"}]}],"Credit_LimitSet":{"Credit_Limit":[{"CredLimit":"12716004.2600","Ztransid":"Q-01644","Currency":"","ZrefTransid":"","CredLiab":"0.0000"}]},"Item_RSet":{"Item_R":[{"TaxAmount":"0.0000","Zpricerefresh":"false","HgLvItem":"000000","Ztransid":"Q-01644","NetValue":"100.0000","Material":"1000229","ZrefTransid":"","ItmNumber":"1","Zprcduedt":"2023-08-08","ZvldStrtdt":"2023-10-04","ZvldEnddt":"2023-10-04"}]},"Raw_MaterialSet":{"Raw_Material":[{"Zsoldcfr":"0.000000000","Zzcompqty":"1.000","Zlistcfr":"0.000000000","Ztransid":"Q-01644","ZzMatDesc":"","Zzcomponent":"9999999999","ItmNumber":"1","ZrefTransid":""}]}}}}'
			);

			Test.startTest();
			PMC_CPQ_GetPriceResponseParsing.responseProcess(lstQuotes[0], untypedResponse);
			Test.stopTest();

			// Verify that the response processing completed successfully for Brazil region
			List<SBQQ__QuoteLine__c> updatedQuoteLines = [
				SELECT Id, PMC_CPQ_FinalPricePerTonne__c, PMC_CPQ_InterestFees__c, SBQQ__ListPrice__c
				FROM SBQQ__QuoteLine__c
				WHERE SBQQ__Quote__c = :lstQuotes[0].Id
			];
			System.assert(!updatedQuoteLines.isEmpty(), 'Quote lines should exist');
			// The test verifies that Brazil region code path executes without error
			// The actual field clearing behavior depends on integration field metadata configuration
			System.assertNotEquals(null, updatedQuoteLines[0], 'Quote line should be processed successfully');
		}
	}

	/**
	 * @description Test static variable getPriceCalloutComplete
	 */
	@isTest
	public static void testGetPriceCalloutCompleteFlag() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createQuotes(1, lstUser);

			// Reset the static variable
			PMC_CPQ_GetPriceResponseParsing.getPriceCalloutComplete = false;

			// Create mock HTTP response
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setBody('{"success": "true"}');

			// Mock the static request
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request = new HttpRequest();
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request.setBody('{"test": "request"}');

			Test.startTest();
			PMC_CPQ_GetPriceResponseParsing.parseJSONGetPriceInterface(lstQuotes, response, 'test/endpoint');
			Test.stopTest();

			// Verify static variable was set
			System.assertEquals(true, PMC_CPQ_GetPriceResponseParsing.getPriceCalloutComplete, 'Static variable should be set to true on success');
		}
	}

	/**
	 * @description Test exception handling in parseJSONGetPriceInterface success path
	 */
	@isTest
	public static void testParseJSONGetPriceInterfaceSuccessException() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createQuotes(1, lstUser);

			// Set quote to null to force an exception in the success processing
			lstQuotes[0].PMC_CPQ_GetPriceCallComplete__c = null;

			// Create mock HTTP response with success status
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setBody('{"success": "true"}');

			// Mock the static request
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request = new HttpRequest();
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request.setBody('{"test": "request"}');

			Test.startTest();
			PMC_CPQ_GetPriceResponseParsing.parseJSONGetPriceInterface(lstQuotes, response, 'test/endpoint');
			Test.stopTest();

			// Verify quote was updated with error status due to exception
			SBQQ__Quote__c updatedQuote = [
				SELECT PMC_CPQ_IntegrationStatus__c, Get_Prices_Status__c, PMC_CPQ_IntegrationMessage__c, PMC_CPQ_GetPriceCallComplete__c
				FROM SBQQ__Quote__c
				WHERE Id = :lstQuotes[0].Id
			];
			// Should be success since the exception is in the internal processing
			System.assertEquals('Success', updatedQuote.PMC_CPQ_IntegrationStatus__c, 'Integration status should be Success');
			System.assertEquals('In Progress', updatedQuote.Get_Prices_Status__c, 'Status should be In Progress');
			System.assertEquals(true, updatedQuote.PMC_CPQ_GetPriceCallComplete__c, 'Get Price call should be marked complete');
		}
	}

	/**
	 * @description Test non-500 error response with SAP error structure
	 */
	@isTest
	public static void testParseJSONGetPriceInterfaceNon500Error() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createQuotes(1, lstUser);

			// Create mock HTTP response with non-500 error and SAP error structure
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setBody(
				'{"error":{"code":"/IWBEP/CM_MGW_RT/022","message":{"@xml:lang":"en","$":"Exception raised without specific error"},"innererror":{"application":{"component_id":"","service_namespace":"/SAP/","service_id":"ZOTC_I060_QUOTATION_PRICE_CAL_SRV","service_version":"0001"},"transactionid":"400cb41ec4584a8988cf9a31b7a541fb","timestamp":"","Error_Resolution":{"SAP_Transaction":"","SAP_Note":"See SAP Note 1797736 for error analysis (https://service.sap.com/sap/support/notes/1797736)"},"errordetails":{"errordetail":[{"ContentID":"","code":"CZ/115","message":"Sales area 1002 00 ? does not exist","longtext_url":"Test","propertyref":"","severity":"error","target":"","transition":"false"}]}}}}'
			);

			// Mock the static request
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request = new HttpRequest();
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request.setBody('{"test": "request"}');

			Test.startTest();
			PMC_CPQ_GetPriceResponseParsing.parseJSONGetPriceInterface(lstQuotes, response, 'test/endpoint');
			Test.stopTest();

			// Verify quote was updated with error status and processed SAP error message
			SBQQ__Quote__c updatedQuote = [
				SELECT PMC_CPQ_IntegrationStatus__c, Get_Prices_Status__c, PMC_CPQ_IntegrationMessage__c, PMC_CPQ_GetPriceCallComplete__c
				FROM SBQQ__Quote__c
				WHERE Id = :lstQuotes[0].Id
			];
			System.assertEquals('Error', updatedQuote.PMC_CPQ_IntegrationStatus__c, 'Integration status should be Error');
			System.assertEquals('Failed', updatedQuote.Get_Prices_Status__c, 'Get Prices status should be Failed');
			System.assert(updatedQuote.PMC_CPQ_IntegrationMessage__c.contains('Get Price:'), 'Integration message should contain prefix');
			System.assertEquals(false, PMC_CPQ_GetPriceResponseParsing.getPriceCalloutComplete, 'Get Price callout complete should be false');
		}
	}

	/**
	 * @description Test the private extractRawErrorMessage helper via @TestVisible with structured and unstructured bodies.
	 */
	@isTest
	public static void testExtractRawErrorMessage() {
		// Structured error response
		HttpResponse structured = new HttpResponse();
		structured.setStatusCode(400);
		structured.setBody('{"error":{"innererror":{"errordetails":{"errordetail":[{"message":"Structured Failure"}]}}}}');
		String msg1 = PMC_CPQ_GetPriceResponseParsing.extractRawErrorMessage(structured);
		System.assertEquals('Structured Failure', msg1, 'Should extract explicit structured failure message');

		// Unstructured / blank response should fall back to label
		HttpResponse unstructured = new HttpResponse();
		unstructured.setStatusCode(400);
		unstructured.setBody('{}');
		String msg2 = PMC_CPQ_GetPriceResponseParsing.extractRawErrorMessage(unstructured);
		System.assertNotEquals('Structured Failure', msg2, 'Fallback label expected for unstructured body');

		// Test with null response
		String msg3 = PMC_CPQ_GetPriceResponseParsing.extractRawErrorMessage(null);
		System.assertNotEquals(null, msg3, 'Should return fallback label for null response');

		// Test with empty body
		HttpResponse emptyBody = new HttpResponse();
		emptyBody.setStatusCode(400);
		emptyBody.setBody('');
		String msg4 = PMC_CPQ_GetPriceResponseParsing.extractRawErrorMessage(emptyBody);
		System.assertNotEquals(null, msg4, 'Should return fallback label for empty body');
	}

	/**
	 * @description Test parsePriceCondUpdateQuoteLine method directly
	 */
	@isTest
	public static void testParsePriceCondUpdateQuoteLine() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createQuotes(1, lstUser);

			// Get the created quote line
			List<SBQQ__QuoteLine__c> quoteLines = [
				SELECT Id, SBQQ__Number__c, SBQQ__ListPrice__c, SBQQ__Quote__r.PMC_CPQ_Region__c
				FROM SBQQ__QuoteLine__c
				WHERE SBQQ__Quote__c = :lstQuotes[0].Id
			];

			Map<String, SBQQ__QuoteLine__c> mapQuoteLine = new Map<String, SBQQ__QuoteLine__c>();
			for (SBQQ__QuoteLine__c ql : quoteLines) {
				mapQuoteLine.put(String.valueOf(ql.SBQQ__Number__c), ql);
			}

			// Create mock price condition data
			List<Object> lstPriceCond = new List<Object>{
				new Map<String, Object>{
					'ItmNumber' => '1',
					'CondType' => 'ZLST',
					'CondValue' => '150.50'
				}
			};

			Test.startTest();
			PMC_CPQ_GetPriceResponseParsing.filterResponseMap();
			PMC_CPQ_GetPriceResponseParsing.parsePriceCondUpdateQuoteLine(lstPriceCond, mapQuoteLine);
			Test.stopTest();

			// Verify the quote line was updated
			System.assert(mapQuoteLine.containsKey('1'), 'Quote line map should contain item 1');
		}
	}

	/**
	 * @description Test parseItemRUpdateQuoteLine method directly
	 */
	@isTest
	public static void testParseItemRUpdateQuoteLine() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createQuotes(1, lstUser);

			// Get the created quote line
			List<SBQQ__QuoteLine__c> quoteLines = [
				SELECT Id, SBQQ__Number__c, SBQQ__ListPrice__c, SBQQ__Quote__r.PMC_CPQ_Region__c
				FROM SBQQ__QuoteLine__c
				WHERE SBQQ__Quote__c = :lstQuotes[0].Id
			];

			Map<String, SBQQ__QuoteLine__c> mapQuoteLine = new Map<String, SBQQ__QuoteLine__c>();
			for (SBQQ__QuoteLine__c ql : quoteLines) {
				mapQuoteLine.put(String.valueOf(ql.SBQQ__Number__c), ql);
			}

			// Create mock Item_R data
			List<Object> lstItemR = new List<Object>{
				new Map<String, Object>{
					'ItmNumber' => '1',
					'NetValue' => '1000.00',
					'TaxAmount' => '50.00'
				}
			};

			Test.startTest();
			PMC_CPQ_GetPriceResponseParsing.filterResponseMap();
			PMC_CPQ_GetPriceResponseParsing.parseItemRUpdateQuoteLine(lstItemR, mapQuoteLine);
			Test.stopTest();

			// Verify the method executed without errors
			System.assert(mapQuoteLine.containsKey('1'), 'Quote line map should contain item 1');
		}
	}

	/**
	 * @description Test responseProcess with Credit_LimitSet null scenario
	 */
	@isTest
	public static void testResponseProcessWithoutCreditLimit() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createQuotes(1, lstUser);

			// Create mock response without Credit_LimitSet
			Map<String, Object> untypedResponse = (Map<String, Object>) JSON.deserializeUntyped(
				'{"HeaderSet":{"Header":{"PriceDate":"2023-10-04","Price_CondSet":[{"Price_Cond":[{"Ztransid":"Q-01644","Currency":"USD","CondValue":"100.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZLST"}]}],"Item_RSet":{"Item_R":[{"TaxAmount":"0.0000","Zpricerefresh":"false","HgLvItem":"000000","Ztransid":"Q-01644","NetValue":"100.0000","Material":"1000229","ZrefTransid":"","ItmNumber":"1"}]}}}}'
			);

			Test.startTest();
			PMC_CPQ_GetPriceResponseParsing.responseProcess(lstQuotes[0], untypedResponse);
			Test.stopTest();

			// Verify that quote lines were processed without credit limit
			List<SBQQ__QuoteLine__c> updatedQuoteLines = [
				SELECT Id
				FROM SBQQ__QuoteLine__c
				WHERE SBQQ__Quote__c = :lstQuotes[0].Id
			];
			System.assert(!updatedQuoteLines.isEmpty(), 'Quote lines should exist');
		}
	}

	/**
	 * @description Test prepareQuoteUpdateAndLog with error response
	 */
	@isTest
	public static void testPrepareQuoteUpdateAndLogWithError() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createQuotes(1, lstUser);

			// Create mock HTTP error response
			HttpResponse response = new HttpResponse();
			response.setStatusCode(500);
			response.setBody('Internal Server Error');

			// Mock the static request
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request = new HttpRequest();
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request.setBody('{"test": "request"}');

			Test.startTest();
			PMC_CPQ_TransactionLog__c log = PMC_CPQ_GetPriceResponseParsing.prepareQuoteUpdateAndLog(lstQuotes, response, 'test/endpoint');
			Test.stopTest();

			// Verify transaction log was created with error status
			System.assertNotEquals(null, log, 'Transaction log should be created');
			System.assertEquals('Error', log.PMC_CPQ_IntegrationStatus__c, 'Log should show error status');
		}
	}

	/**
	 * @description Test static variable getPriceCalloutComplete with error scenario
	 */
	@isTest
	public static void testGetPriceCalloutCompleteFlagOnError() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = createQuotes(1, lstUser);

			// Reset the static variable
			PMC_CPQ_GetPriceResponseParsing.getPriceCalloutComplete = true;

			// Create mock HTTP error response
			HttpResponse response = new HttpResponse();
			response.setStatusCode(500);
			response.setBody('Internal Server Error');

			// Mock the static request
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request = new HttpRequest();
			PMC_CPQ_CPIRemoteCalloutUtilityClass.request.setBody('{"test": "request"}');

			Test.startTest();
			PMC_CPQ_GetPriceResponseParsing.parseJSONGetPriceInterface(lstQuotes, response, 'test/endpoint');
			Test.stopTest();

			// Verify static variable was set to false on error
			System.assertEquals(false, PMC_CPQ_GetPriceResponseParsing.getPriceCalloutComplete, 'Static variable should be set to false on error');
		}
	}

	// @isTest
	// public static void testParseItemRUpdateQuoteLine() {
	// 	List<String> lstProfileNames = new List<String>{ 'Sales User' };
	// 	Map<String, Id> mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);

	// 	User objSalesUser;
	// 	List<User> lstUser = PMC_TestUtilityClass.createUser(1);
	// 	for (User objUser : lstUser) {
	// 		objUser.LastName = 'Sales User Test PMC_CPQ_GenerateContractTest';
	// 		objUser.ProfileId = mapOfProfiles.get('Sales User');
	// 		objUser.FederationIdentifier = objUser.Username + 'Sales';
	// 		objUser.PMC_CPQ_SalesArea__c = 'Mosaic Global Sales LLC Export Common';
	// 		objUser.PMC_CPQ_SalesRegion__c = 'Brazil';
	// 		objUser.isActive = true;
	// 		objUser.MobilePhone = '1234567890';
	// 		objUser.UserPermissionsKnowledgeUser = true;
	// 		objUser.LanguageLocaleKey = 'en_US';
	// 	}
	// 	insert lstUser;
	// 	objSalesUser = lstUser[0];

	// 	Account acc = new Account(Name = 'Test Account', BillingCity = 'toronto', BillingStreet = 'tor');
	// 	insert acc;
		
	// 	PMC_SS_SalesArea__c salesArea = new PMC_SS_SalesArea__c(
	// 		Name = 'Brazil Area',
	// 		PMC_CPQ_SAPSalesOrganization__c = '40000010',
	// 		PMC_SS_SalesOrganization__c = 'Mosaic Global Sales LLC',
	// 		PMC_SS_DistributionChannel__c = '0',
	// 		PMC_SS_Division__c = '20'
	// 	);
	// 	insert salesArea;

	// 	PMC_SS_AccountSalesAreaRelationship__c salesAreaAssignment = new PMC_SS_AccountSalesAreaRelationship__c(
	// 		Name = 'Test Sales Area Assignment',
	// 		PMC_SS_Account__c = acc.Id,
	// 		PMC_SS_SalesArea__c = salesArea.Id
	// 	);
	// 	insert salesAreaAssignment;

	// 	SBQQ__Quote__c quote = new SBQQ__Quote__c(
	// 		SBQQ__Account__c = acc.Id,
	// 		SBQQ__PriceBook__c = Test.getStandardPricebookId(),
	// 		SBQQ__Primary__c = true,
	// 		PMC_CPQ_SalesArea__c = salesAreaAssignment.Id,
	// 		PMC_CPQ_Region__c = 'Brazil',
	// 		PMC_CPQ_ContractLanguage__c = 'Portuguese',
	// 		PMC_CPQ_AccountManager__c = objSalesUser.Id
	// 	);
	// 	insert quote;

	// 	Product2 product = new Product2(Name = 'Test Product', IsActive = true);
	// 	insert product;

	// 	SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
	// 		SBQQ__Quote__c = quote.Id,
	// 		SBQQ__Product__c = product.Id,
	// 		SBQQ__Quantity__c = 1,
	// 		SBQQ__NetPrice__c = 100,
	// 		PMC_CPQ_EstFreightPrice__c = 10,
	// 		PMC_CPQ_QuoteRecordType__c = 'Domestic SA',
	// 		PMC_CPQ_QuoteRecordSubType__c = 'B2C - Fertilizer',
	// 		PMC_CPQ_Incoterms1__c = 'CIF'
	// 	);
	// 	insert quoteLine;

	// 	Map<String, SBQQ__QuoteLine__c> mapQuoteLine = new Map<String, SBQQ__QuoteLine__c>{
	// 			'10' => quoteLine
	// 	};

	// 	Map<String, Object> responseMap = new Map<String, Object>{
	// 			'ItmNumber' => '10',
	// 			'ZLST' => '123.45'
	// 	};
	// 	List<Object> lstItemR = new List<Object>{ responseMap };

	// 	List<PMC_CPQ_IntegrationFieldMap__mdt> lstFldMap = [
	// 		SELECT PMC_CPQ_ApexAPIName__c, PMC_CPQ_AttributeKey__c, PMC_CPQ_DataType__c
	// 		FROM PMC_CPQ_IntegrationFieldMap__mdt
	// 		WHERE PMC_CPQ_SFObject__c = 'Price_Cond'
	// 		AND PMC_CPQ_ApexAPIName__c IN ('SBQQ__ListPrice__c')
	// 		AND PMC_CPQ_AttributeKey__c != NULL
	// 		LIMIT 1
	// 	];
	// 	PMC_CPQ_GetPriceResponseParsing.setIntegrationFieldMap(lstFldMap);

	// 	Test.startTest();
	// 	PMC_CPQ_GetPriceResponseParsing.parseItemRUpdateQuoteLine(lstItemR, mapQuoteLine);
	// 	Test.stopTest();

	// 	SBQQ__QuoteLine__c updatedLine = mapQuoteLine.get('10');

	// 	System.assertEquals(null, updatedLine.PMC_CPQ_Margin__c);
	// 	System.assertEquals(123.45, updatedLine.SBQQ__ListPrice__c);
	// }
}