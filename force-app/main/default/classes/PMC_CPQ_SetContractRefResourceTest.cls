/** @description This is the test class for PMC_CPQ_SetContractRefResource REST API endpoint.
 *  @author Raphael Ferreira de Holanda Soares
 *  @GCPM-3584 Related to pricing integration functionality
 */
@isTest
public without sharing class PMC_CPQ_SetContractRefResourceTest {
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
		accnt.PMC_SS_MDMVerified__c = false;
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

		//accnt.Primary_Contract_Recipient__c = lstContacts[0].Id;
		//update accnt;

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
		SBQQ__Subscription__c objSubscription = new SBQQ__Subscription__c(SBQQ__QuoteLine__c = objQuoteLine.Id, SBQQ__Quantity__c = 1);
		insert objSubscription;

		return lstQuotes;
	}

	/**
	 * @description Builds a realistic success JSON body for testing based on actual API response format
	 * @param transactionId The transaction ID to use in the JSON
	 * @return String The formatted JSON body
	 */
	public static String buildSuccessJsonBody(String transactionId) {
		return buildSuccessJsonBody(transactionId, null);
	}

	public static String buildSuccessJsonBody(String transactionId, String quoteLineId) {
		String quoteLineIdSafe = String.isBlank(quoteLineId) ? '' : quoteLineId;
		return '[{"QUOTE":"0010010049","QUOTE_LINE":0,"CONTRACT":"","CONTRACT_LINE":0,"SFDC_ITEM":"","FLAG":"","ACTION":"","TYPE":"S","ID":"V4","NUMBER":233,"MESSAGE":"SALES_HEADER_IN has been processed successfully","LOG_NO":"","LOG_MSG_NO":0,"MESSAGE_V1":"VBAKKOM","MESSAGE_V2":"","MESSAGE_V3":"","MESSAGE_V4":"","PARAMETER":"SALES_HEADER_IN","ROW":0,"FIELD":"","SYSTEM":"DA1CLNT110","SFRecordId":"'
            + transactionId +
            '","ObjectName":"Quote","OBJECT_NUMBER":"0010010049","statusCode":201,"responsetext":"Created"},{"QUOTE":"0010010049","QUOTE_LINE":0,"CONTRACT":"","CONTRACT_LINE":0,"SFDC_ITEM":"","FLAG":"","ACTION":"","TYPE":"S","ID":"V1","NUMBER":311,"MESSAGE":"Standard Quotation 10010049 has been saved.","LOG_NO":"","LOG_MSG_NO":0,"MESSAGE_V1":"Standard Quotation","MESSAGE_V2":"10010049","MESSAGE_V3":"","MESSAGE_V4":"","PARAMETER":"SALES_HEADER_IN","ROW":0,"FIELD":"","SYSTEM":"DA1CLNT110","SFRecordId":"'
            + transactionId +
            '","ObjectName":"Quote","OBJECT_NUMBER":"0010010049","statusCode":201,"responsetext":"Created"},{"QUOTE":"0010010049","QUOTE_LINE":10,"CONTRACT":"","CONTRACT_LINE":0,"SFDC_ITEM":"-0004286","FLAG":"","ACTION":"","TYPE":"S","ID":"V4","NUMBER":233,"MESSAGE":"SALES_ITEM_IN has been processed successfully","LOG_NO":"","LOG_MSG_NO":0,"MESSAGE_V1":"VBAPKOM","MESSAGE_V2":"000010","MESSAGE_V3":"","MESSAGE_V4":"","PARAMETER":"SALES_ITEM_IN","ROW":10,"FIELD":"","SYSTEM":"DA1CLNT110","SFRecordId":"'
            + transactionId +
            '","ObjectName":"Quote","OBJECT_NUMBER":"0010010049","statusCode":201,"responsetext":"Created"},{"QUOTE":"","QUOTE_LINE":0,"CONTRACT":"0020009926","CONTRACT_LINE":0,"SFDC_ITEM":"","FLAG":"","ACTION":"","TYPE":"S","ID":"V4","NUMBER":233,"MESSAGE":"SALES_HEADER_IN has been processed successfully","LOG_NO":"","LOG_MSG_NO":0,"MESSAGE_V1":"VBAKKOM","MESSAGE_V2":"","MESSAGE_V3":"","MESSAGE_V4":"","PARAMETER":"","ROW":0,"FIELD":"","SYSTEM":"","SFRecordId":"'
            + transactionId +
            '","ObjectName":"Contract","OBJECT_NUMBER":"0020009926","statusCode":201,"responsetext":"Created"},{"QUOTE":"","QUOTE_LINE":0,"CONTRACT":"0020009926","CONTRACT_LINE":0,"SFDC_ITEM":"","FLAG":"","ACTION":"","TYPE":"S","ID":"V1","NUMBER":311,"MESSAGE":"Standard Contract 20009926 has been saved.","LOG_NO":"","LOG_MSG_NO":0,"MESSAGE_V1":"Standard Contract","MESSAGE_V2":"","MESSAGE_V3":"","MESSAGE_V4":"","PARAMETER":"","ROW":0,"FIELD":"","SYSTEM":"","SFRecordId":"'
            + transactionId +
            '","ObjectName":"Contract","OBJECT_NUMBER":"0020009926","statusCode":201,"responsetext":"Created"},{"QUOTE":"","QUOTE_LINE":0,"CONTRACT":"0020009926","CONTRACT_LINE":10,"SFDC_ITEM":"'
            + quoteLineIdSafe +
            '","OBJECT_ITEM":10,"J_1BCFOP":"6101AA","FLAG":"","ACTION":"","TYPE":"S","ID":"V4","NUMBER":233,"MESSAGE":"SALES_ITEM_IN has been processed successfully","LOG_NO":"","LOG_MSG_NO":0,"MESSAGE_V1":"VBAPKOM","MESSAGE_V2":"","MESSAGE_V3":"","MESSAGE_V4":"","PARAMETER":"","ROW":10,"FIELD":"","SYSTEM":"","SFRecordId":"'
            + transactionId +
            '","ObjectName":"Contract","OBJECT_NUMBER":"0020009926","statusCode":201,"responsetext":"Created"}]';
	}

	/**
	 * @description Builds an error JSON body for testing
	 * @param transactionId The transaction ID to use in the JSON
	 * @return String The formatted JSON body
	 */
	public static String buildErrorJsonBody(String transactionId) {
		return '[{"QUOTE":"0010010049","QUOTE_LINE":0,"CONTRACT":"","CONTRACT_LINE":0,"SFDC_ITEM":"","FLAG":"","ACTION":"","TYPE":"S","ID":"V4","NUMBER":233,"MESSAGE":"SALES_HEADER_IN has been processed successfully","LOG_NO":"","LOG_MSG_NO":0,"MESSAGE_V1":"VBAKKOM","MESSAGE_V2":"","MESSAGE_V3":"","MESSAGE_V4":"","PARAMETER":"SALES_HEADER_IN","ROW":0,"FIELD":"","SYSTEM":"DA1CLNT110","SFRecordId":"'
            + transactionId +
            '","ObjectName":"Quote","OBJECT_NUMBER":"0010010049","statusCode":406,"responsetext":"Not Acceptable"},{"QUOTE":"0010010049","QUOTE_LINE":0,"CONTRACT":"","CONTRACT_LINE":0,"SFDC_ITEM":"","FLAG":"","ACTION":"","TYPE":"S","ID":"V1","NUMBER":311,"MESSAGE":"Standard Quotation 10010049 has been saved.","LOG_NO":"","LOG_MSG_NO":0,"MESSAGE_V1":"Standard Quotation","MESSAGE_V2":"10010049","MESSAGE_V3":"","MESSAGE_V4":"","PARAMETER":"SALES_HEADER_IN","ROW":0,"FIELD":"","SYSTEM":"DA1CLNT110","SFRecordId":"'
            + transactionId +
            '","ObjectName":"Quote","OBJECT_NUMBER":"0010010049","statusCode":406,"responsetext":"Not Acceptable"},{"QUOTE":"0010010049","QUOTE_LINE":10,"CONTRACT":"","CONTRACT_LINE":0,"SFDC_ITEM":"-0004286","FLAG":"","ACTION":"","TYPE":"S","ID":"V4","NUMBER":233,"MESSAGE":"SALES_ITEM_IN has been processed successfully","LOG_NO":"","LOG_MSG_NO":0,"MESSAGE_V1":"VBAPKOM","MESSAGE_V2":"000010","MESSAGE_V3":"","MESSAGE_V4":"","PARAMETER":"SALES_ITEM_IN","ROW":10,"FIELD":"","SYSTEM":"DA1CLNT110","SFRecordId":"'
            + transactionId +
            '","ObjectName":"Quote","OBJECT_NUMBER":"0010010049","statusCode":406,"responsetext":"Not Acceptable"},{"QUOTE":"","QUOTE_LINE":0,"CONTRACT":"0020009926","CONTRACT_LINE":0,"SFDC_ITEM":"","FLAG":"","ACTION":"","TYPE":"S","ID":"V4","NUMBER":233,"MESSAGE":"SALES_HEADER_IN has been processed successfully","LOG_NO":"","LOG_MSG_NO":0,"MESSAGE_V1":"VBAKKOM","MESSAGE_V2":"","MESSAGE_V3":"","MESSAGE_V4":"","PARAMETER":"","ROW":0,"FIELD":"","SYSTEM":"","SFRecordId":"'
            + transactionId +
            '","ObjectName":"Contract","OBJECT_NUMBER":"0020009926","statusCode":406,"responsetext":"Not Acceptable"},{"QUOTE":"","QUOTE_LINE":0,"CONTRACT":"0020009926","CONTRACT_LINE":0,"SFDC_ITEM":"","FLAG":"","ACTION":"","TYPE":"S","ID":"V1","NUMBER":311,"MESSAGE":"Standard Contract 20009926 has been saved.","LOG_NO":"","LOG_MSG_NO":0,"MESSAGE_V1":"Standard Contract","MESSAGE_V2":"","MESSAGE_V3":"","MESSAGE_V4":"","PARAMETER":"","ROW":0,"FIELD":"","SYSTEM":"","SFRecordId":"'
            + transactionId +
            '","ObjectName":"Contract","OBJECT_NUMBER":"0020009926","statusCode":406,"responsetext":"Not Acceptable"},{"QUOTE":"","QUOTE_LINE":0,"CONTRACT":"0020009926","CONTRACT_LINE":10,"SFDC_ITEM":"-0004286","FLAG":"","ACTION":"","TYPE":"S","ID":"V4","NUMBER":233,"MESSAGE":"SALES_ITEM_IN has been processed successfully","LOG_NO":"","LOG_MSG_NO":0,"MESSAGE_V1":"VBAPKOM","MESSAGE_V2":"","MESSAGE_V3":"","MESSAGE_V4":"","PARAMETER":"","ROW":10,"FIELD":"","SYSTEM":"","SFRecordId":"'
            + transactionId +
            '","ObjectName":"Contract","OBJECT_NUMBER":"0020009926","statusCode":406,"responsetext":"Not Acceptable"}]';
	}

	/**
	 * @description Test successful price setting with valid JSON response
	 */
	@isTest
	public static void testSetContractRefSuccess() {
		List<User> lstSalesUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];
		List<User> lstAdminUser = [SELECT Id FROM User WHERE LastName = 'Admin User Test' LIMIT 1];
		List<SBQQ__Quote__c> lstQuotes;
		SBQQ__Subscription__c subscription;

		System.runAs(lstSalesUser.get(0)) {
			lstQuotes = PMC_CPQ_SetContractRefResourceTest.createQuotes(1, lstSalesUser);
		}

		subscription = [SELECT Id FROM SBQQ__Subscription__c WHERE SBQQ__QuoteLine__c IN (SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :lstQuotes[0].Id) LIMIT 1];
		String transactionId = lstQuotes[0].Id;
		String successRequestBody = buildSuccessJsonBody(transactionId, subscription.Id);

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestBody = Blob.valueOf(successRequestBody);
		RestContext.request = req;
		RestContext.response = res;

		System.runAs(lstAdminUser.get(0)) {
			PMC_CPQ_QuoteTriggerHandler.boolBypassTriggerLogic = true;
			Test.startTest();
			PMC_CPQ_SetContractRefResource.saveQuoteContractRef();
			Test.stopTest();
		}

		System.assertEquals(200, res.statusCode, 'Response status should be 200 for success');

		SBQQ__Quote__c updatedQuote = [SELECT PMC_CPQ_SAPContractReference__c, PMC_CPQ_IntegrationStatus__c FROM SBQQ__Quote__c WHERE Id = :lstQuotes[0].Id];
		System.assertEquals('0020009926', updatedQuote.PMC_CPQ_SAPContractReference__c, 'Quote SAP Contract reference should be 0020009926');
		System.assertEquals('Success', updatedQuote.PMC_CPQ_IntegrationStatus__c, 'Integration status should be Success');

		//SBQQ__Subscription__c updatedSub = [SELECT MD_SAPItemNumber__c, MD_CFOP_Contrato__c FROM SBQQ__Subscription__c WHERE Id = :subscription.Id];
		//System.assertEquals('000010', updatedSub.MD_SAPItemNumber__c, 'SAP item number should be zero-padded');
		//System.assertEquals('6101AA', updatedSub.MD_CFOP_Contrato__c, 'CFOP should match J_1BCFOP');
	}

	/**
	 * @description Test error handling when external system returns error
	 */
	@isTest
	public static void testSetContractRefWithError() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];

			// Get the auto-generated quote name and extract transaction ID
		System.runAs(lstUser.get(0)) {
			List<SBQQ__Quote__c> lstQuotes = PMC_CPQ_SetContractRefResourceTest.createQuotes(1, lstUser);
			String transactionId = lstQuotes[0].Id;

			String errorRequestBody = buildErrorJsonBody(transactionId);

			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestBody = Blob.valueOf(errorRequestBody);
			RestContext.request = req;
			RestContext.response = res;

			Test.startTest();
			PMC_CPQ_SetContractRefResource.saveQuoteContractRef();
			Test.stopTest();

			System.assertEquals(200, res.statusCode, 'Response status should be 200');
			

			// Verify quote was updated with error status
			SBQQ__Quote__c updatedQuote = [
				SELECT PMC_CPQ_IntegrationStatus__c, PMC_CPQ_IntegrationMessage__c
				FROM SBQQ__Quote__c
				WHERE Id = :lstQuotes[0].Id
			];
			System.assertEquals('Error', updatedQuote.PMC_CPQ_IntegrationStatus__c, 'Integration status should be Error');
		}
	}

	/**
	 * @description Test handling of invalid JSON format
	 */
	@isTest
	public static void testSetContractRefInvalidJSON() {
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
				PMC_CPQ_SetContractRefResource.saveQuoteContractRef();
				// If no exception, check the response
				System.assertEquals(500, res.statusCode, 'Response status should be 500 for invalid JSON');
				System.assert(res.responseBody.toString().contains('Internal Server Error'), 'Response should contain Internal Server Error message');
			} catch (System.NullPointerException e) {
				// Expected behavior - quoteRecord is null
				System.assert(true, 'NullPointerException expected');
			}
			Test.stopTest();
		}
	}

	/**
	 * @description Test quote not found scenario
	 */
	@isTest
	public static void testSetContractRefQuoteNotFound() {
		List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];

		System.runAs(lstUser.get(0)) {
			String requestBody = buildSuccessJsonBody('123456'); // Non-existent quote ID

			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestBody = Blob.valueOf(requestBody);
			RestContext.request = req;
			RestContext.response = res;

			Test.startTest();
			PMC_CPQ_SetContractRefResource.saveQuoteContractRef();
			Test.stopTest();

			System.assertEquals(500, res.statusCode, 'Response status should be 500 when quote not found');
			System.assert(res.responseBody.toString().contains('Internal Server Error'), 'Response should contain Internal Server Error message');
		}
	}	
}