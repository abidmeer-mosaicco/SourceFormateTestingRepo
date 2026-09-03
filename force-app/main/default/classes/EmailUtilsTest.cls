@isTest
private class EmailUtilsTest {
	@TestSetup
	static void setupTestData() {
		Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
		List<User> testUsers = new List<User>();
		for (Integer i = 0; i < 3; i++) {
			testUsers.add(
				new User(
					FirstName = 'Test',
					LastName = 'User ' + i,
					Email = 'testuser' + i + '@example.com',
					Username = 'testuser' + i + '@example.com' + System.currentTimeMillis(),
					Alias = 'tuser' + i,
					EmailEncodingKey = 'UTF-8',
					LanguageLocaleKey = 'en_US',
					LocaleSidKey = 'en_US',
					TimeZoneSidKey = 'America/Los_Angeles',
					ProfileId = p.Id
				)
			);
		}

		// Use System.runAs to avoid MIXED_DML_OPERATION errors
		// This creates a new transaction context for setup object DML
		System.runAs(new User(Id = UserInfo.getUserId())) {
			insert testUsers;
		}

		// Manually create test data to avoid calling createOrders which creates more Users
		Account testAccount = new Account(Name = 'Test Account');
		insert testAccount;

		Pricebook2 standardPricebook = new Pricebook2(
			Id = Test.getStandardPricebookId(),
			IsActive = true
		);
		update standardPricebook;

		Pricebook2 testPricebook = new Pricebook2(
			Name = 'Test Pricebook',
			IsActive = true
		);
		insert testPricebook;

		Product2 testProduct = new Product2(
			Name = 'Test Product',
			PMC_CPQ_SAPProductCode__c = '123123',
			StockKeepingUnit = '123123',
			IsActive = true
		);
		insert testProduct;

		PricebookEntry pbe = new PricebookEntry(
			Pricebook2Id = testPricebook.Id,
			Product2Id = testProduct.Id,
			UnitPrice = 100,
			CurrencyIsoCode = 'USD',
			IsActive = true
		);
		insert pbe;

		Order testOrder = new Order(
			AccountId = testAccount.Id,
			EffectiveDate = Date.today(),
			Status = 'Draft',
			Pricebook2Id = testPricebook.Id,
			CurrencyIsoCode = 'USD'
		);
		insert testOrder;

		OrderItem testOrderItem = new OrderItem(
			OrderId = testOrder.Id,
			Product2Id = testProduct.Id,
			PricebookEntryId = pbe.Id,
			Quantity = 1,
			UnitPrice = 100
		);
		insert testOrderItem;

		List<OrderItem> lstOrderLines = new List<OrderItem>{testOrderItem};
		List<SBAA__Approval__c> testApprovals = new List<SBAA__Approval__c>();
		for (OrderItem oi : lstOrderLines) {
			oi.ApprovalStatus__c = 'Pending Approval';
			update oi;
			testApprovals.add(
				new SBAA__Approval__c(
					sbaa__ApprovalStep__c = 1,
					sbaa__RecordField__c = 'ApprovalStatus__c',
					OrderItem__c = oi.Id,
					sbaa__Status__c = 'Requested',
					PMC_CPQ_SendEmail__c = true
				)
			);
		}
		insert testApprovals;
	}

	@isTest
	static void testSendOrderApprovedEmail() {
		Map<Id, Set<Id>> userIdsByOrderId = new Map<Id, Set<Id>>();
		List<Order> orders = [SELECT Id FROM Order];
		List<User> users = [SELECT Id FROM User WHERE Email LIKE 'testuser%'];
		for (Order o : orders) {
			userIdsByOrderId.put(o.Id, new Set<Id>{ users[0].Id, users[1].Id });
		}
		List<SBAA__Approval__c> updatedApprovals = [
			SELECT Id, PMC_CPQ_SendEmail__c
			FROM SBAA__Approval__c
			WHERE OrderItem__r.OrderId IN :userIdsByOrderId.keySet()
		];
		if (!updatedApprovals.isEmpty()) {
			updatedApprovals[0].sbaa__Status__c = 'Approved';
			update updatedApprovals;
		}
		Test.startTest();
		EmailUtils.sendOrderApprovedEmail(JSON.serialize(userIdsByOrderId));
		Test.stopTest();
		updatedApprovals = [
			SELECT Id, PMC_CPQ_SendEmail__c
			FROM SBAA__Approval__c
			WHERE OrderItem__r.OrderId IN :userIdsByOrderId.keySet()
		];
		for (SBAA__Approval__c app : updatedApprovals) {
			System.assertEquals(false, app.PMC_CPQ_SendEmail__c, 'Send Email flag should be false');
		}
	}

	@isTest
	static void testSendOrderRejectedEmail() {
		Map<Id, Set<Id>> userIdsByOrderId = new Map<Id, Set<Id>>();
		List<Order> orders = [SELECT Id FROM Order];
		List<User> users = [SELECT Id FROM User WHERE Email LIKE 'testuser%'];
		for (Order o : orders) {
			userIdsByOrderId.put(o.Id, new Set<Id>{ users[0].Id, users[1].Id });
		}
		List<SBAA__Approval__c> updatedApprovals = [
			SELECT Id, PMC_CPQ_SendEmail__c
			FROM SBAA__Approval__c
			WHERE OrderItem__r.OrderId IN :userIdsByOrderId.keySet()
		];
		if (!updatedApprovals.isEmpty()) {
			updatedApprovals[0].sbaa__Status__c = 'Rejected';
			update updatedApprovals;
		}
		Test.startTest();
		EmailUtils.sendOrderRejectedEmail(JSON.serialize(userIdsByOrderId));
		Test.stopTest();
		updatedApprovals = [
			SELECT Id, PMC_CPQ_SendEmail__c
			FROM SBAA__Approval__c
			WHERE OrderItem__r.OrderId IN :userIdsByOrderId.keySet()
		];
		for (SBAA__Approval__c app : updatedApprovals) {
			System.assertEquals(false, app.PMC_CPQ_SendEmail__c, 'Send Email flag should be false');
		}
	}

	@isTest
	static void testSendApprovalRequestEmails() {
		Map<Id, Set<Id>> userIdsByOrderId = new Map<Id, Set<Id>>();
		List<Order> orders = [SELECT Id FROM Order];
		List<User> users = [SELECT Id FROM User WHERE Email LIKE 'testuser%'];
		for (Order o : orders) {
			userIdsByOrderId.put(o.Id, new Set<Id>{ users[0].Id, users[1].Id });
		}
		List<SBAA__Approval__c> updatedApprovals = [
			SELECT Id, PMC_CPQ_SendEmail__c
			FROM SBAA__Approval__c
			WHERE OrderItem__r.OrderId IN :userIdsByOrderId.keySet()
		];
		if (!updatedApprovals.isEmpty()) {
			updatedApprovals[0].sbaa__Status__c = 'Requested';
			update updatedApprovals;
		}
		Test.startTest();
		EmailUtils.sendApprovalRequestEmails(JSON.serialize(userIdsByOrderId));
		Test.stopTest();
		updatedApprovals = [
			SELECT Id, PMC_CPQ_SendEmail__c
			FROM SBAA__Approval__c
			WHERE OrderItem__r.OrderId IN :userIdsByOrderId.keySet()
		];
		for (SBAA__Approval__c app : updatedApprovals) {
			System.assertEquals(false, app.PMC_CPQ_SendEmail__c, 'Send Email flag should be false');
		}
	}

	@isTest
	static void testSendApprovalRecallEmails() {
		Map<Id, Set<Id>> userIdsByOrderId = new Map<Id, Set<Id>>();
		List<Order> orders = [SELECT Id FROM Order];
		List<User> users = [SELECT Id FROM User WHERE Email LIKE 'testuser%'];
		for (Order o : orders) {
			userIdsByOrderId.put(o.Id, new Set<Id>{ users[0].Id, users[1].Id });
		}
		List<SBAA__Approval__c> updatedApprovals = [
			SELECT Id, PMC_CPQ_SendEmail__c
			FROM SBAA__Approval__c
			WHERE OrderItem__r.OrderId IN :userIdsByOrderId.keySet()
		];
		if (!updatedApprovals.isEmpty()) {
			updatedApprovals[0].sbaa__Status__c = 'Recalled';
			update updatedApprovals;
		}
		Test.startTest();
		EmailUtils.sendApprovalRecallEmails(JSON.serialize(userIdsByOrderId));
		Test.stopTest();
		updatedApprovals = [
			SELECT Id, PMC_CPQ_SendEmail__c
			FROM SBAA__Approval__c
			WHERE OrderItem__r.OrderId IN :userIdsByOrderId.keySet()
		];
		for (SBAA__Approval__c app : updatedApprovals) {
			System.assertEquals(false, app.PMC_CPQ_SendEmail__c, 'Send Email flag should be false');
		}
	}

	@isTest
	static void testUpdateOrderItemApprovalsSendEmail() {
		Map<Id, Set<Id>> userIdsByOrderId = new Map<Id, Set<Id>>();
		List<Order> orders = [SELECT Id FROM Order];
		List<User> users = [SELECT Id FROM User WHERE Email LIKE 'testuser%'];
		for (Order o : orders) {
			userIdsByOrderId.put(o.Id, new Set<Id>{ users[0].Id, users[1].Id });
		}
		List<SBAA__Approval__c> updatedApprovals = [
			SELECT Id, PMC_CPQ_SendEmail__c
			FROM SBAA__Approval__c
			WHERE OrderItem__r.OrderId IN :userIdsByOrderId.keySet()
		];
		if (!updatedApprovals.isEmpty()) {
			updatedApprovals[0].sbaa__Status__c = 'Requested';
			update updatedApprovals;
		}
		Test.startTest();
		EmailUtils.updateOrderItemApprovalsSendEmail(userIdsByOrderId.keySet(), 'Requested');
		Test.stopTest();
		updatedApprovals = [
			SELECT Id, PMC_CPQ_SendEmail__c
			FROM SBAA__Approval__c
			WHERE OrderItem__r.OrderId IN :userIdsByOrderId.keySet()
		];
		for (SBAA__Approval__c app : updatedApprovals) {
			System.assertEquals(false, app.PMC_CPQ_SendEmail__c, 'Send Email flag should be false');
		}
	}

	@isTest
	static void testEmptyInputs() {
		Test.startTest();
		EmailUtils.sendOrderApprovedEmail(JSON.serialize(new Map<Id, Set<Id>>()));
		EmailUtils.sendOrderRejectedEmail(JSON.serialize(new Map<Id, Set<Id>>()));
		EmailUtils.sendApprovalRequestEmails(JSON.serialize(new Map<Id, Set<Id>>()));
		EmailUtils.sendApprovalRecallEmails(JSON.serialize(new Map<Id, Set<Id>>()));
		List<Messaging.SendEmailResult> results = EmailUtils.sendEmailWithTemplate(new Map<Id, Set<Id>>(), 'Order_Items_Approved');
		EmailUtils.sendEmailWithTemplateAsync(JSON.serialize(new Map<Id, Set<Id>>()), 'Order_Items_Sent_To_SAP');
		EmailUtils.updateOrderItemApprovalsSendEmail(new Set<Id>(), 'Requested');
		Test.stopTest();
		System.assertEquals(0, results.size(), 'No emails should be sent for empty input');
	}

	@isTest
	static void testSendEmailWithTemplateAsync() {
		Map<Id, Set<Id>> userIdsByOrderId = new Map<Id, Set<Id>>();
		List<Order> orders = [SELECT Id FROM Order];
		List<User> users = [SELECT Id FROM User WHERE Email LIKE 'testuser%'];
		for (Order o : orders) {
			userIdsByOrderId.put(o.Id, new Set<Id>{ users[0].Id, users[1].Id });
		}
		List<SBAA__Approval__c> updatedApprovals = [
			SELECT Id, PMC_CPQ_SendEmail__c
			FROM SBAA__Approval__c
			WHERE OrderItem__r.OrderId IN :userIdsByOrderId.keySet()
		];
		if (!updatedApprovals.isEmpty()) {
			updatedApprovals[0].sbaa__Status__c = 'Requested';
			update updatedApprovals;
		}
		Test.startTest();
		EmailUtils.sendEmailWithTemplateAsync(JSON.serialize(userIdsByOrderId), 'Order_Items_Sent_To_SAP');
		Test.stopTest();
		updatedApprovals = [
			SELECT Id, PMC_CPQ_SendEmail__c
			FROM SBAA__Approval__c
			WHERE OrderItem__r.OrderId IN :userIdsByOrderId.keySet()
		];
		for (SBAA__Approval__c app : updatedApprovals) {
			System.assertEquals(true, app.PMC_CPQ_SendEmail__c, 'Send Email flag should be true');
		}
	}
}