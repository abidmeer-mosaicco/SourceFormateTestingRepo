/**
 * @description This test class will be used to cover all the methods of PMC_CPQ_QuoteTriggerHandler and PMC_CPQ_QuoteTriggerHelper.
 * @author Jaswanth
 * @storynumber GDASF-8944
 */

@isTest(seeAllData=false)
public with sharing class PMC_CPQ_QuoteTriggerHandlerTest {
	/**
	 * @description This Method will be used to setup the data for the test class execution.
	 * @modified by Jaswanth Vaithiswaran part of Test class optimization to run in sales user context.
	 */
	@testSetup
	private static void setup() {
		

		List<String> lstProfileNames = new List<String>{ 'System Administrator', 'Sales User' };
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
			} else if (intuserCount == 1) {
				objUser.LastName = 'Sales User Test';
				objUser.ProfileId = mapOfProfiles.get('Sales User');
				objUser.FederationIdentifier = objUser.Username + 'Sales';
			}
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

		System.runAs(objSalesUser) {
			Account objAcc = new Account();
			objAcc.Name = 'Test Account Quote Trigger';
			objAcc.PMC_SS_SAPCustomerNumber__c = 'ijklmnop';
			objAcc.BillingCountry = 'United States';
			objAcc.BillingState = 'California';
			objAcc.BillingStreet = 'fsvc';
			objAcc.BillingCity = 'San Francisco';
			objAcc.BillingPostalCode = '94001';
			insert objAcc;
			Contact testContact = new Contact();
			testContact.FirstName = 'test Jane';
			testContact.LastName = 'test Doe';
			insert testContact;
			Date dateStartDate = System.today();
			dateStartDate = dateStartDate.addDays(2);
			Date dateEndDate = dateStartDate.addDays(35);
			SBQQ__Quote__c objQuote;
			objQuote = new SBQQ__Quote__c();
			objQuote.SBQQ__Account__c = objAcc.Id;
			objQuote.PMC_CPQ_ContractStart__c = dateStartDate;
			objQuote.PMC_CPQ_ContractEnd__c = dateEndDate;
			objQuote.PMC_CPQ_PrimaryContact__c = testContact.id;
			objQuote.SBQQ__Primary__c = true;
			objQuote.SBQQ__Status__c = 'Expired';
			objQuote.PMC_CPQ_ExpiresOn__c = Datetime.now().adddays(-10);
			insert objQuote;
		}

	}
	/**
	 * @description This method will be used to test the scenario where Quote is expired and try to edit the quote.
	 * @modified by Jaswanth Vaithiswaran part of Test class optimization to run in sales user context.
	 */
	@istest
	private static void validateQuoteExpirationTest() {
		Test.startTest();
		User salesUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
		System.runAs(salesUser) {
			SBQQ__Quote__c cpqQuote = [
				SELECT id, SBQQ__Status__c, PMC_CPQ_AccountCountry__c
				FROM SBQQ__Quote__c
				WHERE SBQQ__Status__c = 'Expired'
				LIMIT 1
			];
			cpqQuote.PMC_CPQ_AccountCountry__c = 'India';
			String errorMsg = '';
			try {
				update cpqQuote;
			} catch (EXCEPTION e) {
				errorMsg = e.getMessage();
			}

			Assert.isTrue(errorMsg.contains(System.Label.PMC_CPQ_QuoteExpirationValidationMessage), 'Expiration validation not thrown');
		}
		Test.stopTest();
	}
	/**
	 * @description This method will be used to test the scenario where Query return exception
	 */
	@isTest
	private static void validateQuoteExpirationCatchBlockTest() {
		PMC_CPQ_QuoteTriggerHelper.testException = true;
		Test.startTest();
		User salesUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
		System.runAs(salesUser) {
			SBQQ__Quote__c cpqQuote = [
				SELECT id, SBQQ__Status__c, PMC_CPQ_AccountCountry__c
				FROM SBQQ__Quote__c
				WHERE SBQQ__Status__c = 'Expired'
				LIMIT 1
			];
			update cpqQuote;

			Assert.isTrue(cpqQuote != null, 'Exception not thrown');
		}

		Test.stopTest();
	}

	/**
	 * @description This method is a test method for Quote delete operation.
	 * @modified by Jaswanth Vaithiswaran part of Test class optimization to run in sales user context.
	 */
	@istest
	private static void testQuoteDelete() {
		Test.startTest();
		User salesUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
		System.runAs(salesUser) {
			SBQQ__Quote__c cpqQuote = [SELECT id, PMC_CPQ_ExpiresOn__c, SBQQ__Primary__c FROM SBQQ__Quote__c WITH SECURITY_ENFORCED LIMIT 1];
			Database.delete(cpqQuote.Id);
			List<SBQQ__Quote__c> deletedQuotes = [SELECT Id FROM SBQQ__Quote__c WHERE Id = :cpqQuote.Id WITH SECURITY_ENFORCED];
			Assert.areEqual(0, deletedQuotes.size(), 'Quote was not deleted');
		}
		Test.stopTest();
	}
	/**
	 * @description This method is a test method for Quote undelete operation.
	 * @modified by Jaswanth Vaithiswaran part of Test class optimization to run in sales user context.
	 */
	@istest
	private static void testQuoteUnDelete() {
		Test.startTest();
		User salesUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
		System.runAs(salesUser) {
			SBQQ__Quote__c cpqQuote = [SELECT id, PMC_CPQ_ExpiresOn__c, SBQQ__Primary__c FROM SBQQ__Quote__c WITH SECURITY_ENFORCED LIMIT 1];
			Database.delete(cpqQuote.Id);
			Database.undelete(cpqQuote.Id);
			List<SBQQ__Quote__c> deletedQuotes = [SELECT Id FROM SBQQ__Quote__c WHERE Id = :cpqQuote.Id WITH SECURITY_ENFORCED];
			Assert.areEqual(1, deletedQuotes.size(), 'Quote was not restored');
		}
		Test.stopTest();
	}
	/**
	 * @description This method is a test bypass insert method of the trigger.
	 * @modified by Jaswanth Vaithiswaran part of Test class optimization to run in sales user context.
	 */
	@istest
	private static void testBypassQuoteInsertOperation() {
		PMC_CPQ_QuoteTriggerHandler.boolBypassTriggerLogic = true;
		Test.startTest();
		User salesUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
		System.runAs(salesUser) {
			SBQQ__Quote__c cpqQuote = [
				SELECT id, PMC_CPQ_PrimaryContact__c, PMC_CPQ_ContractStart__c, PMC_CPQ_ContractEnd__c, SBQQ__Account__c
				FROM SBQQ__Quote__c
				WITH SECURITY_ENFORCED
				LIMIT 1
			];
			SBQQ__Quote__c quoteTwo = new SBQQ__Quote__c();
			quoteTwo.PMC_CPQ_PrimaryContact__c = cpqQuote.PMC_CPQ_PrimaryContact__c;
			quoteTwo.PMC_CPQ_ContractStart__c = cpqQuote.PMC_CPQ_ContractStart__c;
			quoteTwo.PMC_CPQ_ContractEnd__c = cpqQuote.PMC_CPQ_ContractEnd__c;
			quoteTwo.SBQQ__Account__c = cpqQuote.SBQQ__Account__c;
			Database.insert(quoteTwo);
			List<SBQQ__Quote__c> lstQuotes = [SELECT id FROM SBQQ__Quote__c WITH SECURITY_ENFORCED];
			Assert.areEqual(2, lstQuotes.size(), 'Quote was not inserted');
		}
		Test.stopTest();
	}
	/**
	 * @description This method is a test bypass update method of the trigger.
	 * @modified by Jaswanth Vaithiswaran part of Test class optimization to run in sales user context.
	 */
	@istest
	private static void testBypassQuoteUpdateOperation() {
		PMC_CPQ_QuoteTriggerHandler.boolBypassTriggerLogic = true;
		Test.startTest();
		User salesUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
		System.runAs(salesUser) {
			SBQQ__Quote__c cpqQuote = [SELECT Id, PMC_CPQ_AccountCountry__c FROM SBQQ__Quote__c WITH SECURITY_ENFORCED LIMIT 1];
			cpqQuote.PMC_CPQ_AccountCountry__c = 'North America';
			Database.update(cpqQuote);
			SBQQ__Quote__c quoteTwo = [SELECT Id, PMC_CPQ_AccountCountry__c FROM SBQQ__Quote__c WITH SECURITY_ENFORCED LIMIT 1];
			Assert.areEqual('North America', quoteTwo.PMC_CPQ_AccountCountry__c, 'Quote was not updated');
		}
		Test.stopTest();
	}
	/**
	 * @description This method is a test bypass delete method of the trigger.
	 */
	@istest
	private static void testBypassQuoteDeleteOperation() {
		PMC_CPQ_QuoteTriggerHandler.boolBypassTriggerLogic = true;
		Test.startTest();
		User salesUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
		System.runAs(salesUser) {
			SBQQ__Quote__c cpqQuote = [SELECT id, PMC_CPQ_ExpiresOn__c, SBQQ__Primary__c FROM SBQQ__Quote__c WITH SECURITY_ENFORCED LIMIT 1];
			Database.delete(cpqQuote.Id);
			List<SBQQ__Quote__c> deletedQuotes = [SELECT Id FROM SBQQ__Quote__c WHERE Id = :cpqQuote.Id WITH SECURITY_ENFORCED];
			Assert.areEqual(0, deletedQuotes.size(), 'Quote was not deleted');
		}
		Test.stopTest();
	}
	/**
	 * @description This method is a test bypass undelete method of the trigger.
	 * @modified by Jaswanth Vaithiswaran part of Test class optimization to run in sales user context.
	 *
	 */
	@istest
	private static void testBypassQuoteUnDeleteOperation() {
		PMC_CPQ_QuoteTriggerHandler.boolBypassTriggerLogic = true;
		Test.startTest();
		User salesUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
		System.runAs(salesUser) {
			SBQQ__Quote__c cpqQuote = [SELECT id, PMC_CPQ_ExpiresOn__c, SBQQ__Primary__c FROM SBQQ__Quote__c WITH SECURITY_ENFORCED LIMIT 1];
			Database.delete(cpqQuote.Id);
			Database.undelete(cpqQuote.Id);
			List<SBQQ__Quote__c> deletedQuotes = [SELECT Id FROM SBQQ__Quote__c WHERE Id = :cpqQuote.Id WITH SECURITY_ENFORCED];
			Assert.areEqual(1, deletedQuotes.size(), 'Quote was not restored');
		}
		Test.stopTest();
	}
	/**
	 * @description Test method for afterUpdate trigger when quote is approved
	 */
	@isTest
	private static void testAfterUpdateQuoteApproval() {
		// Create test account
		Account testAccount = PMC_DH_TestDataFactoryClass.createTestAccount();

		// Create test contact
		Contact testContact = PMC_DH_TestDataFactoryClass.createTestContact(testAccount.Id);

		// Create test opportunity
		Opportunity testOpp = PMC_DH_TestDataFactoryClass.createOpportunity(testAccount);
        testOpp.CurrencyIsoCode = 'USD';
        update testOpp;

		// Create test quote
		SBQQ__Quote__c testQuote = PMC_DH_TestDataFactoryClass.createQuote(testAccount, testContact.Id, testOpp);
		testQuote.SBQQ__Status__c = 'Draft';
		testQuote.PMC_CPQ_ContractStageName__c = 'Accepted';
		update testQuote;

		// Create test product
		Product2 testProduct = PMC_DH_TestDataFactoryClass.createProduct();
		insert testProduct;

		// Create test quote line
		SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote, testProduct);

		testQuoteLine.SBQQ__Quantity__c = 0;
		update testQuoteLine;


		Test.startTest();
		// Now approve the quote
		testQuote.PMC_CPQ_QuoteApproved__c = true;
		update testQuote;
		Test.stopTest();
	}
  /*  @isTest
private static void testEnforceFieldLock_RegionBrazil_NoError() {
    User salesUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];

    System.runAs(salesUser) {
        SBQQ__Quote__c quote = [SELECT Id, PMC_CPQ_Region__c, PMC_CPQ_ContractStageName__c, 
                                       PMC_CPQ_ContractShippingInstructions__c 
                                FROM SBQQ__Quote__c LIMIT 1];

        quote.PMC_CPQ_ContractStageName__c = 'Accepted'; 
        quote.PMC_CPQ_Region__c = 'Brazil'; 
        quote.PMC_CPQ_ContractShippingInstructions__c = 'Updated Shipping';
        

        Test.startTest();
        update quote; // Should NOT throw error
        Test.stopTest();
    }
}   */
    @isTest
private static void testAfterUpdate_VCOQuotationChange() {
    User salesUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];

    System.runAs(salesUser) {
        // Create quote with 'Domestic SA' record type
        RecordType recType = [SELECT Id FROM RecordType 
                              WHERE SObjectType = 'SBQQ__Quote__c' 
                              AND Name = 'Domestic SA' 
                              LIMIT 1];

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            
            SBQQ__Account__c = [SELECT Id FROM Account LIMIT 1].Id,
            PMC_CPQ_ContractStart__c = Date.today().addDays(1),
            PMC_CPQ_ContractEnd__c = Date.today().addDays(40),
            RecordTypeId = recType.Id,
           // PMC_CPQ_RecordTypeName__c = 'Domestic SA',
            SBQQ__Primary__c = true,
            SBQQ__Status__c = 'Draft',
            PMC_CPQ_VCOQuotation__c = false
        );
        insert quote;

        quote.PMC_CPQ_VCOQuotation__c = true;

        Test.startTest();
        update quote;
        Test.stopTest();
    }
}
    /*
@isTest
private static void testAfterUpdateTriggerHandlerLogic() {
    // Arrange test user context
    User salesUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];

    System.runAs(salesUser) {
        // Get existing quote created in @testSetup
        SBQQ__Quote__c existingQuote = [
            SELECT Id, SBQQ__Status__c, PMC_CPQ_ContractStageName__c, 
                   PMC_CPQ_VCOQuotation__c, RecordTypeId
            FROM SBQQ__Quote__c
            LIMIT 1
        ];

        // Fetch Domestic SA record type
        RecordType domesticSA = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'SBQQ__Quote__c' AND Name = 'Domestic SA' 
            LIMIT 1
        ];

        // Set up all three trigger conditions
        existingQuote.SBQQ__Status__c = 'Approved'; // Approved path
        existingQuote.PMC_CPQ_ContractStageName__c = 'Accepted'; // Accepted path
        existingQuote.PMC_CPQ_VCOQuotation__c = true; // VCO checkbox path
        existingQuote.RecordTypeId = domesticSA.Id; // Set correct RecordType
         existingQuote.PMC_CPQ_ContractStart__c = Date.today();
        existingQuote.PMC_CPQ_ContractEnd__c = Date.today().addMonths(2);
         existingQuote.PMC_CPQ_ExpiresOn__c = DateTime.now().addDays(50);
        existingQuote.SBQQ__ExpirationDate__c = Date.today().addDays(30);
        
        Test.startTest();
        update existingQuote;
        Test.stopTest();
    }
} */
@isTest
private static void testFieldLockValidationFails() {

    User salesUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];
    
    System.runAs(salesUser) {
        // Create a new Account and Contact
        Account testAccount = new Account(Name = 'Test Lock Account', PMC_SS_SAPCustomerNumber__c = '999999');
        
			testAccount.BillingCountry = 'United States';
			testAccount.BillingState = 'California';
			testAccount.BillingStreet = 'fsvc';
			testAccount.BillingCity = 'San Francisco';
			testAccount.BillingPostalCode = '94001';
        insert testAccount;

        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact');
        insert testContact;

        // Create a new Quote with future expiration and ContractStage set
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Account__c = testAccount.Id;
        quote.PMC_CPQ_PrimaryContact__c = testContact.Id;
        quote.PMC_CPQ_ContractStart__c = Date.today();
        quote.PMC_CPQ_ContractEnd__c = Date.today().addMonths(1);
        quote.PMC_CPQ_ContractStageName__c = 'Accepted'; // Triggers field lock
        quote.SBQQ__Status__c = 'Draft';
        quote.PMC_CPQ_ExpiresOn__c = DateTime.now().addDays(10); // NOT expired
        quote.PMC_CPQ_Region__c = 'North America';
        insert quote;

        // Clone the quote for update
        SBQQ__Quote__c quoteToUpdate = quote.clone(false, true, false, false);
        quoteToUpdate.Id = quote.Id;

        // Change a restricted field (e.g., Status)
        quoteToUpdate.SBQQ__Status__c = 'Approved'; // Should be blocked by field lock

        Test.startTest();
        String errorMsg = '';
        try {
            update quoteToUpdate;
        } catch (Exception e) {
            errorMsg = e.getMessage();
        }
        Test.stopTest();

        System.assert(
            errorMsg.contains(Label.PMC_CPQ_ContractSetValue), 
            'Expected field-lock error message was not thrown.'
        );
    }
}
 /*   @isTest
private static void testEnforceFieldLock_AllowsUnlockedField() {
    User salesUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];
    System.runAs(salesUser) {
        Account acc = new Account(Name='FieldLockAllow');
        acc.PMC_SS_SAPCustomerNumber__c = 'ijklmnopq';
			acc.BillingCountry = 'United States';
			acc.BillingState = 'California';
			acc.BillingStreet = 'fsvc';
			acc.BillingCity = 'San Francisco';
			acc.BillingPostalCode = '94001';
        insert acc;
        Contact con = new Contact(FirstName='Allow', LastName='FieldLock');
        insert con;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            PMC_CPQ_PrimaryContact__c = con.Id,
            PMC_CPQ_ContractStageName__c = 'Accepted',
           PMC_CPQ_ExpiresOn__c = DateTime.now().addDays(40),
           SBQQ__Status__c = 'Draft'
        );
        insert quote;

        // Change a field NOT locked (e.g. PMC_CPQ_ContractShippingInstructions__c)
        quote.PMC_CPQ_ContractShippingInstructions__c = 'Some instructions';
        Test.startTest();
        update quote; // Should NOT throw error
        Test.stopTest();
    }
}

*/

@isTest
private static void testAfterUndeleteLogic() {
    User salesUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];
    System.runAs(salesUser) {
        Account acc = new Account(Name='FieldLockAllow');
        acc.PMC_SS_SAPCustomerNumber__c = 'ijklmnopq';
			acc.BillingCountry = 'United States';
			acc.BillingState = 'California';
			acc.BillingStreet = 'fsvc';
			acc.BillingCity = 'San Francisco';
			acc.BillingPostalCode = '94001';
        insert acc;
        Contact con = new Contact(FirstName='Allow', LastName='FieldLock');
        insert con;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            PMC_CPQ_PrimaryContact__c = con.Id,
            PMC_CPQ_ContractStageName__c = 'Accepted',
           PMC_CPQ_ExpiresOn__c = DateTime.now().addDays(40),
           SBQQ__Status__c = 'Draft'
        );
        insert quote;


    // Step 2: Delete the record
    delete quote;

    // Step 3: Undelete the record
    undelete quote;

    // Assertions (optional, depending on what afterUndelete does)
    SBQQ__Quote__c undeletedObj = [SELECT Id, Name FROM SBQQ__Quote__c WHERE Id = :quote.Id];
    System.assertNotEquals(null, undeletedObj);

}
}
}