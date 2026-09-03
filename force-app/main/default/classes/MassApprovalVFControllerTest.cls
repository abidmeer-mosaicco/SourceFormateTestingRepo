@isTest
public class MassApprovalVFControllerTest {
	@TestSetup
	static void setupTestData() {
		// Create test account
		Account testAccount = new Account(Name = 'Test Account');
		insert testAccount;

		// Create test users for account team
		Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
		User accountManager = new User(
			FirstName = 'Account',
			LastName = 'Manager',
			Email = 'account.manager@test.com',
			Username = 'account.manager@test.com' + System.currentTimeMillis(),
			Alias = 'amgr',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/Los_Angeles',
			ProfileId = p.Id
		);
		User salesSupport = new User(
			FirstName = 'Sales',
			LastName = 'Support',
			Email = 'sales.support@test.com',
			Username = 'sales.support@test.com' + System.currentTimeMillis(),
			Alias = 'ssup',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/Los_Angeles',
			ProfileId = p.Id
		);
		insert new List<User>{ accountManager, salesSupport };

		// Create account team members
		AccountTeamMember atm1 = new AccountTeamMember(AccountId = testAccount.Id, UserId = accountManager.Id, TeamMemberRole = 'Account Manager');
		AccountTeamMember atm2 = new AccountTeamMember(
			AccountId = testAccount.Id,
			UserId = salesSupport.Id,
			TeamMemberRole = 'Sales Support Representative'
		);
		insert new List<AccountTeamMember>{ atm1, atm2 };

		// Create test order and order items
		Order testOrder = new Order(
			AccountId = testAccount.Id,
			EffectiveDate = System.today(),
			Status = 'Draft',
			Pricebook2Id = Test.getStandardPricebookId()
		);
		insert testOrder;

		List<Product2> prod = PMC_TestUtilityClass.createProduct(1, 'PMC_CPQ_NA');
		prod[0].PMC_CPQ_SAPProductCode__c = '';
		update prod[0];
		//Instantiate the Pricebook2 record with StandardPricebookId
		Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);

		//Execute an update DML on the Pricebook2 record, to make IsStandard to true
		update standardPricebook;

		testOrder.Pricebook2Id = standardPricebook.Id;
		testOrder.CurrencyIsoCode = 'USD';
		update testOrder;
		//Create the PricebookEntry
		PricebookEntry pbe = new PricebookEntry(
			Pricebook2Id = standardPricebook.Id,
			Product2Id = prod[0].Id,
			UnitPrice = 0,
			// PMC_CPQ_ProductSKUCode__c = prod[0].PMC_CPQ_SAPProductCode__c,
			CurrencyIsoCode = testOrder.CurrencyIsoCode,
			IsActive = true
		);
		insert pbe;

		OrderItem testOrderItem = new OrderItem(
			OrderId = testOrder.Id,
			UnitPrice = 100,
			Quantity = 1,
			Product2Id = prod[0].Id,
			PricebookEntryId = pbe.Id
		);
		insert testOrderItem;

		// Create order line approval records
		Order_Line_Approval__c ola = new Order_Line_Approval__c(OrderItem__c = testOrderItem.Id, ApprovalStatus__c = 'Requested');
		insert ola;

		// Create test approvals
		List<SBAA__Approval__c> testApprovals = new List<SBAA__Approval__c>();
		testApprovals.add(
				new SBAA__Approval__c(
					sbaa__Status__c = 'Requested',
					OrderItem__c = testOrderItem.Id,
					Order_Line_Approval__c = ola.Id,
					sbaa__ApprovalStep__c = 1,
					sbaa__RecordField__c = 'Order_Line_Approval__c'
				)
			);
		//}
		insert testApprovals;
	}

	@isTest
	static void testApproveSelected() {
		List<SBAA__Approval__c> testApprovals = [SELECT Id,
		sbaa__Status__c,
		SBAA__ApprovedBy__c,
		OrderItem__r.OrderId,
		OrderItem__r.Order.AccountId,
		sbaa__ApprovalChain__r.OwnerId,
		sbaa__CommentsLong__c,
		Order_Line_Approval__c FROM SBAA__Approval__c];

		// Set up standard controller with selected records
		ApexPages.StandardSetController stdController = new ApexPages.StandardSetController(testApprovals);
		stdController.setSelected(testApprovals);

		// Add approve mode parameter
		Test.setCurrentPageReference(new PageReference('Page.MassApprovalVF'));
		ApexPages.currentPage().getParameters().put('mode', 'approve');

		// Create controller
		Test.startTest();
		MassApprovalVFController controller = new MassApprovalVFController(stdController);

		// Verify initial state
		System.assertEquals(true, controller.showModal);
		System.assertEquals(false, controller.processing);
		System.assertEquals(true, controller.approvalMode);
		System.assertEquals(1, controller.approvals.size());

		// Call approve method
		PageReference result = controller.approveSelected();
		Test.stopTest();

		// Verify results
		System.assertEquals(false, controller.showModal);
		System.assertEquals(false, controller.processing);
		System.assertEquals(true, controller.redirect);

		// Verify approvals were updated
		List<SBAA__Approval__c> updatedApprovals = [
			SELECT Id, sbaa__Status__c, SBAA__ApprovedBy__c
			FROM SBAA__Approval__c
			WHERE Id IN :testApprovals
		];
		for (SBAA__Approval__c app : updatedApprovals) {
			System.assertEquals('Approved', app.sbaa__Status__c);
			System.assertEquals(UserInfo.getUserId(), app.SBAA__ApprovedBy__c);
		}

		// Verify order line approval was updated
		Order_Line_Approval__c updatedOLA = [
			SELECT ApprovalStatus__c
			FROM Order_Line_Approval__c
			LIMIT 1
		];
		System.assertEquals('Approved', updatedOLA.ApprovalStatus__c);
	}

	@isTest
	static void testRejectSelected() {
		List<SBAA__Approval__c> testApprovals = [SELECT Id FROM SBAA__Approval__c];

		// Set up standard controller with selected records
		ApexPages.StandardSetController stdController = new ApexPages.StandardSetController(testApprovals);
		stdController.setSelected(testApprovals);

		// Create controller without approve mode parameter
		Test.setCurrentPageReference(new PageReference('Page.MassApprovalVF'));

		Test.startTest();
		MassApprovalVFController controller = new MassApprovalVFController(stdController);

		// Verify initial state (should be reject mode)
		System.assertEquals(false, controller.approvalMode);

		// Call approve method (which will actually reject in this mode)
		PageReference result = controller.approveSelected();
		Test.stopTest();

		// Verify approvals were updated to rejected
		List<SBAA__Approval__c> updatedApprovals = [
			SELECT Id, sbaa__Status__c
			FROM SBAA__Approval__c
			WHERE Id IN :testApprovals
		];
		for (SBAA__Approval__c app : updatedApprovals) {
			System.assertEquals('Rejected', app.sbaa__Status__c);
		}

		// Verify order line approval was updated
		Order_Line_Approval__c updatedOLA = [
			SELECT ApprovalStatus__c
			FROM Order_Line_Approval__c
			LIMIT 1
		];
		System.assertEquals('Rejected', updatedOLA.ApprovalStatus__c);
	}

	@isTest
	static void testEmptySelection() {
		// Set up standard controller with no selected records
		ApexPages.StandardSetController stdController = new ApexPages.StandardSetController(new List<SBAA__Approval__c>());

		Test.startTest();
		MassApprovalVFController controller = new MassApprovalVFController(stdController);
		PageReference result = controller.approveSelected();
		Test.stopTest();

		// Verify error message was added
		System.assertEquals(1, ApexPages.getMessages().size());
		System.assertEquals(false, controller.redirect);
	}

	@isTest
	static void testGetRedirectUrl() {
		MassApprovalVFController controller = new MassApprovalVFController(new ApexPages.StandardSetController(new List<SBAA__Approval__c>()));
		String url = controller.getRedirectUrl();
		System.assert(url.contains('/lightning/o/SBAA__Approval__c/list'));
	}
}