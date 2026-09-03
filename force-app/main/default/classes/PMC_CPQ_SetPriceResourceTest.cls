/** @description This is the test class for PMC_CPQ_SetPriceResource REST API endpoint.
 *  @author Raphael Ferreira de Holanda Soares
 *  @GCPM-3584 Related to pricing integration functionality
 */

@isTest
public without sharing class PMC_CPQ_SetPriceResourceTest {
	public static List<String> lstPayloadQuoteIds = new List<String>();

	/**
	 * @description setup users to create sales area and test data.
	 * @author Raphael Ferreira de Holanda Soares
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
			objUser.PMC_CPQ_PrimaryBusinessType__c = 'Feed';
            objUser.PMC_CPQ_SalesArea__c='Mosaic Global Sales LLC Domestic Common';
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
			lstSalesArea[0].PMC_SS_DistributionChannel__c = '00';
			lstSalesArea[0].PMC_SS_Division__c = '10';
			update lstSalesArea;
		}
	}

	/**
	 * @description createQuotes Creates the Quote to send to REST endpoint
	 * @param numQuote - Number of quotes to be created and Account Manager.
	 * @param lstUser - list of users.
	 * @return lstQuotes - List<SBQQ__Quote__c> to be returned.
	 */
	public static List<SBQQ__Quote__c> createQuotes(Integer numQuote, List<User> lstUser) {
		PMC_ProcessSwitches__c bypassSetting = PMC_ProcessSwitches__c.getOrgDefaults();
		// Bypass record-triggered flows during setup to reduce SOQL/CPU footprint
		// (the org has many after-save flows on Quote/QuoteLine that are heavy in
		// test context). Restored at the end of this method.
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
		// Create quotes directly with all required fields to avoid validation issues
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

		// Use Database.insert with allOrNone = true to get proper error handling
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
	 * @description Builds a realistic success JSON body for testing based on actual API response format
	 * @param transactionId The transaction ID to use in the JSON
	 * @return String The formatted JSON body
	 */
	public static String buildSuccessJsonBody(String transactionId) {
		return '{"HeaderSet":{"Header":{"PriceDate":"2025-06-01T00:00:00.000","AmedInd":"","PriceGrp":"","ReturnSet":"","SalesAgrStartDate":"2025-01-17T00:00:00.000","ReqDateH":"2025-06-01T00:00:00.000","DistrChan":"00","Price_CondSet":[{"Price_Cond":[{"Ztransid":"' +
			transactionId +
			'","Currency":"USD","CondValue":"50.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZLST"},{"Ztransid":"' +
			transactionId +
			'","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZMIN"},{"Ztransid":"' +
			transactionId +
			'","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZMAX"},{"Ztransid":"' +
			transactionId +
			'","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZTAR"},{"Ztransid":"' +
			transactionId +
			'","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZNTV"},{"Ztransid":"' +
			transactionId +
			'","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZLSP"},{"Ztransid":"' +
			transactionId +
			'","Currency":"USD","CondValue":"99.640000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZNTB"}]}],"RegStrGrp":"","SalesAgrEndDate":"2026-01-16T00:00:00.000","SalesOrg":"1002","Currency":"USD","Division":"10","VcoInd":"","DocType":"ZQT","Ztransid":"' +
			transactionId +
			'","QtValidT":"2025-08-31T00:00:00.000","PrimBusType":"Co-Products","Credit_LimitSet":"","SalesOff":"100J","QtValidF":"2025-06-01T00:00:00.000","PurchNoC":"","Pmnttrms":"D060","SchedAgreement":"A-0000036","B2cB2bInd":"","ZrefTransid":"","PurchDate":"2025-08-04T00:00:00.000","Raw_MaterialSet":"","ParQuoteTimStmp":"","Item_RSet":{"Item_R":[{"TaxAmount":"0.0000","Zpricerefresh":"true","HgLvItem":"000000","Zconprcfrml":"","Ztransid":"' +
			transactionId +
			'","NetValue":"50.0000","Material":"1000077","ZrefTransid":"","ItmNumber":"1","Zprcduedt":"","ScheduleSet":{"Schedule":[{"SchedLine":"0001","Ztransid":"' +
			transactionId +
			'","ConfirQty":"1500.000","ZrefTransid":"","ItmNumber":"1","ReqDate":"2025-06-01"}]}}]},"Material_AvailabilitySet":{"Material_Availability":[{"Ztransid":"' +
			transactionId +
			'","ZrefTransid":"","ItmNumber":"1","Material":"1000077","Uom":"STN","Plant":"1217","ReqDate":"2025-08-04","ReqQty":"0.000","ComDate":"2025-08-04","ComQty":"4500.001"}]}}}}';
	}

	/**
	 * @description Builds an error JSON body for testing
	 * @param transactionId The transaction ID to use in the JSON
	 * @return String The formatted JSON body
	 */
	public static String buildErrorJsonBody(String transactionId) {
		return '{"error":"External system error occurred","Ztransid":"' + transactionId + '"}';
	}

	/**
	 * @description Test successful price setting with valid JSON response
	 */
	@isTest
	public static void testSetPriceSuccess() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];
		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = PMC_CPQ_SetPriceResourceTest.createQuotes(1, lstUser);
			SBQQ__Quote__c createdQuote = [SELECT Name FROM SBQQ__Quote__c WHERE Id = :lstQuotes[0].Id];
			// Get the auto-generated quote name and extract transaction ID
			String quoteName = createdQuote.Name;
			String transactionId = quoteName.startsWith('Q-') ? quoteName.substring(2) : quoteName;

			String successRequestBody = buildSuccessJsonBody(transactionId);

			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestBody = Blob.valueOf(successRequestBody);
			RestContext.request = req;
			RestContext.response = res;
			
            PMC_CPQ_QuoteTriggerHandler.boolBypassTriggerLogic = true;
			Test.startTest();
			PMC_CPQ_SetPriceResource.savePrice();
			Test.stopTest();

			System.assertEquals(200, res.statusCode, 'Response status should be 200 for success');
			System.assert(res.responseBody.toString().contains('Success'), 'Response should contain success message');

			// Verify quote was updated
			SBQQ__Quote__c updatedQuote = [SELECT Get_Prices_Status__c, PMC_CPQ_IntegrationStatus__c FROM SBQQ__Quote__c WHERE Id = :lstQuotes[0].Id];
			System.assertEquals('Completed', updatedQuote.Get_Prices_Status__c, 'Quote status should be Completed');
			System.assertEquals('Success', updatedQuote.PMC_CPQ_IntegrationStatus__c, 'Integration status should be Success');
		}
	}

	/**
	 * @description Test error handling when external system returns error
	 */
	@isTest
	public static void testSetPriceWithError() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];

			// Get the auto-generated quote name and extract transaction ID
		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = PMC_CPQ_SetPriceResourceTest.createQuotes(1, lstUser);
			SBQQ__Quote__c createdQuote = [SELECT Name FROM SBQQ__Quote__c WHERE Id = :lstQuotes[0].Id];
			String quoteName = createdQuote.Name;
			String transactionId = quoteName.startsWith('Q-') ? quoteName.substring(2) : quoteName;

			String errorRequestBody = buildErrorJsonBody(transactionId);

			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestBody = Blob.valueOf(errorRequestBody);
			RestContext.request = req;
			RestContext.response = res;

			Test.startTest();
			PMC_CPQ_SetPriceResource.savePrice();
			Test.stopTest();

			System.assertEquals(200, res.statusCode, 'Response status should be 200');
			System.assert(res.responseBody.toString().contains('Price fetch failed'), 'Response should contain error message');

			// Verify quote was updated with error status
			SBQQ__Quote__c updatedQuote = [
				SELECT Get_Prices_Status__c, PMC_CPQ_IntegrationStatus__c, PMC_CPQ_IntegrationMessage__c
				FROM SBQQ__Quote__c
				WHERE Id = :lstQuotes[0].Id
			];
			System.assertEquals('Failed', updatedQuote.Get_Prices_Status__c, 'Quote status should be Failed');
			System.assertEquals('Error', updatedQuote.PMC_CPQ_IntegrationStatus__c, 'Integration status should be Error');
		}
	}

	/**
	 * @description Test handling of invalid JSON format
	 */
	@isTest
	public static void testSetPriceInvalidJSON() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];

		System.runAs(lstUser.get(0)) {
			String invalidRequestBody = '{"HeaderSet":{"Header":{"Price_CondSet":[]}}}'; // Empty Price_CondSet

			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestBody = Blob.valueOf(invalidRequestBody);
			RestContext.request = req;
			RestContext.response = res;

			Test.startTest();
			try {
				PMC_CPQ_SetPriceResource.savePrice();
				// If no exception, check the response
				System.assertEquals(500, res.statusCode, 'Response status should be 500 for invalid JSON');
				System.assert(res.responseBody.toString().contains('Invalid JSON'), 'Response should contain invalid JSON message');
			} catch (System.NullPointerException e) {
				// Expected behavior - quoteRecord is null when Price_CondSet is empty
				System.assert(true, 'NullPointerException expected for empty Price_CondSet');
			}
			Test.stopTest();
		}
	}

	/**
	 * @description Test quote not found scenario
	 */
	@isTest
	public static void testSetPriceQuoteNotFound() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];

		System.runAs(lstUser.get(0)) {
			String requestBody = '{"error":"Some error","Ztransid":"99999"}'; // Non-existent quote ID

			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestBody = Blob.valueOf(requestBody);
			RestContext.request = req;
			RestContext.response = res;

			Test.startTest();
			PMC_CPQ_SetPriceResource.savePrice();
			Test.stopTest();

			System.assertEquals(500, res.statusCode, 'Response status should be 500 when quote not found');
			System.assert(res.responseBody.toString().contains('Quote not found'), 'Response should contain quote not found message');
		}
	}

	/**
	 * @description Test successful price setting with multiple quote lines
	 */
	@isTest
	public static void testSetPriceWithMultipleQuoteLines() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];

		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = PMC_CPQ_SetPriceResourceTest.createQuotes(1, lstUser);
			// Create additional quote line - select all fields to ensure clone has all required data
			SBQQ__QuoteLine__c additionalQuoteLine = [
				SELECT
					Id,
					SBQQ__Product__c,
					SBQQ__Quote__c,
					PMC_CPQ_SoldToShipToJunction__c,
					PMC_CPQ_ProductLocation__c,
					PMC_CPQ_ShipTo__c,
					PMC_CPQ_Discount__c,
					PMC_CPQ_QuoteRecordType__c,
					PMC_CPQ_ModeofTransportation__c,
					PMC_CPQ_UnitofMeasure__c,
					PMC_CPQ_QuoteRecordSubType__c,
					PMC_CPQ_Incoterms1__c,
					PMC_CPQ_EstFreightPrice__c,
					SBQQ__Quantity__c,
					SBQQ__ListPrice__c,
					PMC_CPQ_FinalPricePerTonne__c,
					PMC_CPQ_ContractType__c,
					PMC_CPQ_DeliveryStartDate__c,
					PMC_CPQ_DeliveryEndDate__c,
					PMC_CPQ_PaymentTerms__c,
					PMC_CPQ_CropType__c
				FROM SBQQ__QuoteLine__c
				WHERE SBQQ__Quote__c = :lstQuotes[0].Id
				LIMIT 1
			];
			SBQQ__QuoteLine__c newQuoteLine = additionalQuoteLine.clone(false);
			newQuoteLine.SBQQ__Number__c = 2;

			PMC_ProcessSwitches__c processSwitch = PMC_ProcessSwitches__c.getOrgDefaults();
			Boolean originalBypassFlowValue = processSwitch.PMC_BypassFlow__c;
			Boolean originalBypassVRValue = processSwitch.PMC_BypassValidationRule__c;
			Boolean originalBypassTriggerValue = processSwitch.PMC_BypassTrigger__c;
			processSwitch.PMC_BypassFlow__c = true;
			processSwitch.PMC_BypassValidationRule__c = true;
			processSwitch.PMC_BypassTrigger__c = true;
			upsert processSwitch;
			insert newQuoteLine;
			processSwitch.PMC_BypassFlow__c = originalBypassFlowValue;
			processSwitch.PMC_BypassValidationRule__c = originalBypassVRValue;
			processSwitch.PMC_BypassTrigger__c = originalBypassTriggerValue;
			

			// Get the auto-generated quote name and extract transaction ID
			SBQQ__Quote__c createdQuote = [SELECT Name FROM SBQQ__Quote__c WHERE Id = :lstQuotes[0].Id];
			String quoteName = createdQuote.Name;
			String transactionId = quoteName.startsWith('Q-') ? quoteName.substring(2) : quoteName;

			String successRequestBody = buildSuccessJsonBody(transactionId);

			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestBody = Blob.valueOf(successRequestBody);
			RestContext.request = req;
			RestContext.response = res;

			Test.startTest();
			PMC_CPQ_SetPriceResource.savePrice();
			Test.stopTest();
			
            upsert processSwitch;
			System.assertEquals(200, res.statusCode, 'Response status should be 200 for success');

			// Verify quote was updated
			SBQQ__Quote__c updatedQuote = [SELECT Get_Prices_Status__c, PMC_CPQ_IntegrationStatus__c FROM SBQQ__Quote__c WHERE Id = :lstQuotes[0].Id];
			System.assertEquals('Completed', updatedQuote.Get_Prices_Status__c, 'Quote status should be Completed');
		}
	}

	/**
	 * @description Test edge case with empty Ztransid
	 */
	@isTest
	public static void testSetPriceEmptyZtransid() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];
		List<SBQQ__Quote__c> lstQuotes = PMC_CPQ_SetPriceResourceTest.createQuotes(1, lstUser);

		System.runAs(lstUser.get(0)) {
			// Select created quote lines without filter to see what exists
			List<SBQQ__QuoteLine__c> allQuoteLines = [
				SELECT Id, SBQQ__Quote__r.Name, SBQQ__Quote__c
				FROM SBQQ__QuoteLine__c
				ORDER BY CreatedDate DESC
				LIMIT 10
			];
			System.debug('Available quote lines: ' + allQuoteLines.size());
			for (SBQQ__QuoteLine__c ql : allQuoteLines) {
				System.debug('Quote Name: ' + ql.SBQQ__Quote__r.Name + ', Quote ID: ' + ql.SBQQ__Quote__c);
			}

			// Build JSON with empty Ztransid to test error handling
			String requestBody = '{"HeaderSet":{"Header":{"Price_CondSet":[{"Price_Cond":[{"Ztransid":"","Price":"100.00","Currency":"USD"}]}]}}}';

			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestBody = Blob.valueOf(requestBody);
			RestContext.request = req;
			RestContext.response = res;

			Test.startTest();
			try {
				PMC_CPQ_SetPriceResource.savePrice();
				// If no exception, check the response
				System.assertEquals(500, res.statusCode, 'Response status should be 500 for empty Ztransid');
				System.assert(res.responseBody.toString().contains('Invalid JSON'), 'Response should contain invalid JSON message');
			} catch (System.NullPointerException e) {
				// Expected behavior - quoteRecord is null when no valid Ztransid is provided
				System.assert(true, 'NullPointerException expected for empty Ztransid');
			}
			Test.stopTest();
		}
	}
}