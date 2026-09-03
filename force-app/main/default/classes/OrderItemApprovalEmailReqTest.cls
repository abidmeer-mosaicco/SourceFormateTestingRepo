@isTest
public class OrderItemApprovalEmailReqTest {
	@TestSetup
	static void setup() {
		List<String> lstProfileNames = new List<String>{ 'System Administrator', 'Sales User' };
		List<userRole> userRoleName = [SELECT Id FROM userRole WHERE Name = 'Service Director'];
		List<String> lstPermissionNames = new List<String>{ 'PMC_Administrator_Permission_Set_Group', 'PMC_SLS_Permission_Set_Group' };
		Map<String, Id> mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
		Map<String, PermissionSetGroup> mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionNames);
		Integer intuserCount = 0;
		User objSystemAdminUser;
		User objSalesUser;
		List<User> lstUser = PMC_TestUtilityClass.createUser(2);
		for (User objUser : lstUser) {
			if (intuserCount == 0) {
				objUser.LastName = 'Admin User Test';
				objUser.ProfileId = mapOfProfiles.get('System Administrator');
				objUser.FederationIdentifier = objUser.Username + 'Admin';
				objUser.UserRoleId = userRoleName[0].id;
			} else if (intuserCount == 1) {
				objUser.LastName = 'Sales User Test PMC_CPQ_GenerateContractTest';
				objUser.ProfileId = mapOfProfiles.get('Sales User');
				objUser.FederationIdentifier = objUser.Username + 'Sales';
			}
			objUser.PMC_CPQ_SalesArea__c = 'Mosaic Global Sales LLC Export Common';
			objUser.PMC_CPQ_SalesRegion__c = 'Brazil';
			objUser.isActive = true;
			objUser.MobilePhone = '1234567890';
			objUser.UserPermissionsKnowledgeUser = true;
			objUser.LanguageLocaleKey = 'en_US';
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

		//     User adminUser = [SELECT Id FROM User WHERE Name = 'Copado Integration' LIMIT 1];

		//     // Bypass validation rule using custom setting
		System.runAs(objSystemAdminUser) {
			PMC_ProcessSwitches__c bypassSetting = PMC_ProcessSwitches__c.getOrgDefaults();
			bypassSetting.PMC_BypassValidationRule__c = true;
			upsert bypassSetting;

			// Run remaining setup as test user to bypass validation rules

			Account acc = new Account(Name = 'Test Account', BillingCity = 'toronto', BillingStreet = 'tor');
			insert acc;

			PMC_SS_SalesArea__c salesArea = new PMC_SS_SalesArea__c(
				Name = 'Brazil Area',
				PMC_CPQ_SAPSalesOrganization__c = '40000010',
				PMC_SS_SalesOrganization__c = 'Mosaic Global Sales LLC',
				PMC_SS_DistributionChannel__c = '0',
				PMC_SS_Division__c = '20'
			);
			insert salesArea; // PMC_DH_SalesArea__c = Mosaic Global Sales LLC Export

			//Create sales Area Assignment
			PMC_SS_AccountSalesAreaRelationship__c salesAreaAssignment = new PMC_SS_AccountSalesAreaRelationship__c(
				Name = 'Test Sales Area Assignment',
				PMC_SS_Account__c = acc.Id,
				PMC_SS_SalesArea__c = salesArea.Id
			);
			insert salesAreaAssignment;
			system.debug('sales Area Assignment outcome : ' + salesAreaAssignment);

			Product2 product = new Product2(Name = 'Test Product', IsActive = true);
			insert product;

			PricebookEntry pbe = new PricebookEntry(
				Pricebook2Id = Test.getStandardPricebookId(),
				Product2Id = product.Id,
				UnitPrice = 100,
				IsActive = true,
				UseStandardPrice = false
			);
			insert pbe;
			// Create common test data
			SBQQ__Quote__c validQuote = new SBQQ__Quote__c(
				SBQQ__Account__c = acc.Id,
				SBQQ__PriceBook__c = Test.getStandardPricebookId(),
				SBQQ__Primary__c = true,
				PMC_CPQ_SalesArea__c = salesAreaAssignment.Id,
				PMC_CPQ_Region__c = 'Brazil',
				PMC_CPQ_ContractLanguage__c = 'Portuguese',
				// PMC_CPQ_ContractShippingInstructions__c = 'Test Shipping Instructions',
				PMC_CPQ_AccountManager__c = objSalesUser.Id
			);
			insert validQuote;

			SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
				SBQQ__Quote__c = validQuote.Id,
				SBQQ__Product__c = product.Id,
				SBQQ__PricebookEntryId__c = Pbe.Id,
				SBQQ__Quantity__c = 1,
				SBQQ__NetPrice__c = 100,
				PMC_CPQ_EstFreightPrice__c = 10,
				PMC_CPQ_QuoteRecordType__c = 'Domestic SA',
				PMC_CPQ_QuoteRecordSubType__c = 'B2C - Fertilizer',
				PMC_CPQ_Incoterms1__c = 'CIF'
			);
			insert quoteLine;
		}
	}

	@isTest
	static void testGetQLines() {
		// Retrieve the Quote created in the setup
		SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

		// Instantiate the class to be tested
		OrderItemApprovalEmailReq emailReq = new OrderItemApprovalEmailReq();
		emailReq.quoteId = testQuote.Id;

		// Call the qLines property to trigger the query
		List<SBQQ__QuoteLine__c> qLines = emailReq.qLines;

		// Assert that the qLines list is not null and contains the expected QuoteLine
		System.assertNotEquals(null, qLines, 'qLines should not be null');
		System.assertEquals(1, qLines.size(), 'qLines should contain one QuoteLine');
		System.assertEquals(testQuote.Id, qLines[0].SBQQ__Quote__c, 'The QuoteLine should be related to the Quote created in setup');
	}

	@isTest
	static void testGetQLinesWithNullQuoteId() {
		// Instantiate the class to be tested without setting quoteId
		OrderItemApprovalEmailReq emailReq = new OrderItemApprovalEmailReq();

		// Call the qLines property to trigger the query
		List<SBQQ__QuoteLine__c> qLines = emailReq.qLines;

		// Assert that the qLines list is null since quoteId is not set
		System.assertEquals(null, qLines, 'qLines should be null when quoteId is not set');
	}

	@isTest
	static void testGetQuoteInfo() {
		// Retrieve the Quote created in the setup
		SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

		// Instantiate the class to be tested
		OrderItemApprovalEmailReq emailReq = new OrderItemApprovalEmailReq();
		emailReq.quoteId = testQuote.Id;

		// Call the getQuoteInfo method to trigger the query
		SBQQ__Quote__c quoteInfo = emailReq.getQuoteInfo();

		// Assert that the quoteInfo is not null and matches the Quote created in setup
		System.assertNotEquals(null, quoteInfo, 'quoteInfo should not be null');
		System.assertEquals(testQuote.Id, quoteInfo.Id, 'The Quote Id should match the one created in setup');
	}

	@isTest
	static void testGetQuoteInfoWithNullQuoteId() {
		// Instantiate the class to be tested without setting quoteId
		OrderItemApprovalEmailReq emailReq = new OrderItemApprovalEmailReq();

		// Call the getQuoteInfo method to trigger the query
		SBQQ__Quote__c quoteInfo = emailReq.getQuoteInfo();

		// Assert that the quoteInfo is null since quoteId is not set
		System.assertEquals(null, quoteInfo, 'quoteInfo should be null when quoteId is not set');
	}
}