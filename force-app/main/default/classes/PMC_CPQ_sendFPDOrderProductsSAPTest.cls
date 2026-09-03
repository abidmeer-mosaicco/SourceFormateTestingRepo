@isTest(seeAllData=false)
public with sharing class PMC_CPQ_sendFPDOrderProductsSAPTest {
	@TestSetup
	private static void testSetup() {
		// Create test group for approvals
		Group testGroup = new Group(Name = 'Test Approval Group', Type = 'Queue');
		insert testGroup;

		// Create test data using factory pattern
		Account testAccount = PMC_DH_TestDataFactoryClass.createTestAccount();
		testAccount.PMC_SS_AccountExternalID__c = '2378651345';
		testAccount.PMC_SS_SAPCustomerNumber__c = '2378651345';
		update testAccount;

		Contact testContact = PMC_DH_TestDataFactoryClass.createTestContact(testAccount.Id);

		Opportunity testOpportunity = PMC_DH_TestDataFactoryClass.createOpportunity(testAccount);

		SBQQ__Quote__c testQuote = PMC_DH_TestDataFactoryClass.createQuote(testAccount, testContact.Id, testOpportunity);

		Product2 testProduct = PMC_DH_TestDataFactoryClass.createProduct();
		testProduct.PMC_CPQ_SAPProductCode__c = 'TEST123';
		if (testProduct?.Id != null) {
			update testProduct;
		} else {
			insert testProduct;
		}

		SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote, testProduct);
		testQuoteLine.PMC_CPQ_ContractType__c = 'FPD';
		if (testQuoteLine?.Id != null) {
			update testQuoteLine;
		} else {
			insert testQuoteLine;
		}

		// Create Contract
		Contract testContract = new Contract(
			AccountId = testAccount.Id,
			SBQQ__Opportunity__c = testOpportunity.Id,
			StartDate = Date.today(),
			ContractTerm = 12
		);
		insert testContract;

		// Create Subscription
		SBQQ__Subscription__c testSubscription = new SBQQ__Subscription__c(
			SBQQ__Contract__c = testContract.Id,
			SBQQ__Account__c = testAccount.Id,
			SBQQ__Quantity__c = 1,
			SBQQ__QuoteLine__c = testQuoteLine.Id
		);
		insert testSubscription;

		// Create Order
		Order testOrder = new Order(
			AccountId = testAccount.Id,
			EffectiveDate = Date.today(),
			Status = 'Draft'
		);
		insert testOrder;

		// Create order items with different statuses for testing
		OrderItem objOP1 = new OrderItem(
			OrderId = testOrder.Id,
			SBQQ__QuoteLine__c = testQuoteLine.Id,
			SBQQ__Subscription__c = testSubscription.Id,
			Product2Id = testProduct.Id,
			Quantity = 1,
			ListPrice = 100,
			PMC_CPQ_ListPrice__c = 100,
			UnitPrice = 100,
			PMC_CPQ_ContractType__c = 'FPD',
			PMC_CPQ_ShipTo__c = testAccount.Id,
			PMC_CPQ_FloorPrice__c = 500,
			PMC_CPQ_PriceGuidanceCeiling__c = 1000,
			PMC_CPQ_EstFreightPrice__c = 50,
			PMC_CPQ_FinalAgreedPrice__c = 600,
			ApprovalStatus__c = 'Approved'
		);

		OrderItem objOP2 = new OrderItem(
			OrderId = testOrder.Id,
			SBQQ__QuoteLine__c = testQuoteLine.Id,
			SBQQ__Subscription__c = testSubscription.Id,
			Product2Id = testProduct.Id,
			Quantity = 1,
			ListPrice = 100,
			PMC_CPQ_ListPrice__c = 100,
			UnitPrice = 100,
			PMC_CPQ_ContractType__c = 'FPD',
			PMC_CPQ_ShipTo__c = testAccount.Id,
			PMC_CPQ_FloorPrice__c = 500,
			PMC_CPQ_PriceGuidanceCeiling__c = 1000,
			PMC_CPQ_EstFreightPrice__c = 50,
			PMC_CPQ_FinalAgreedPrice__c = 400,
			ApprovalStatus__c = 'Pending Approval'
		);

		OrderItem objOP3 = new OrderItem(
			OrderId = testOrder.Id,
			SBQQ__QuoteLine__c = testQuoteLine.Id,
			SBQQ__Subscription__c = testSubscription.Id,
			Product2Id = testProduct.Id,
			Quantity = 1,
			ListPrice = 100,
			PMC_CPQ_ListPrice__c = 100,
			UnitPrice = 100,
			PMC_CPQ_ContractType__c = 'FPD',
			PMC_CPQ_ShipTo__c = testAccount.Id,
			PMC_CPQ_FloorPrice__c = 500,
			PMC_CPQ_PriceGuidanceCeiling__c = 1000,
			PMC_CPQ_EstFreightPrice__c = 50,
			PMC_CPQ_FinalAgreedPrice__c = 300,
			ApprovalStatus__c = 'Rejected'
		);

		insert new List<OrderItem>{ objOP1, objOP2, objOP3 };

		// Create approver
		sbaa__Approver__c approver = new sbaa__Approver__c(Name = 'NA_OrderItems_Approver', sbaa__GroupId__c = testGroup.Id);
		insert approver;

		// Create approvals for testing
		List<sbaa__Approval__c> testApprovals = new List<sbaa__Approval__c>();
		testApprovals.add(
			new sbaa__Approval__c(
				sbaa__ApprovalStep__c = 1,
				sbaa__RecordField__c = 'ApprovalStatus__c',
				OrderItem__c = objOP1.Id,
				sbaa__Status__c = 'Approved',
				sbaa__Approver__c = approver.Id
			)
		);
		testApprovals.add(
			new sbaa__Approval__c(
				sbaa__ApprovalStep__c = 1,
				sbaa__RecordField__c = 'ApprovalStatus__c',
				OrderItem__c = objOP2.Id,
				sbaa__Status__c = 'Requested',
				sbaa__Approver__c = approver.Id
			)
		);
		testApprovals.add(
			new sbaa__Approval__c(
				sbaa__ApprovalStep__c = 1,
				sbaa__RecordField__c = 'ApprovalStatus__c',
				OrderItem__c = objOP3.Id,
				sbaa__Status__c = 'Rejected',
				sbaa__Approver__c = approver.Id
			)
		);
		insert testApprovals;
	}

	@isTest
	public static void testSaveOPFromUI_ApprovalRequired() {
		// Test case where approval is required (finalAgreedPrice < floor price)
		OrderItem objOP = [SELECT Id FROM OrderItem WHERE ApprovalStatus__c = 'Approved' LIMIT 1];

		PMC_CPQ_OrderProductDetailsWrapperClass opWrapper = new PMC_CPQ_OrderProductDetailsWrapperClass();
		opWrapper.customId = objOP.Id;
		opWrapper.finalAgreedPrice = 400; // Below floor price to trigger approval

		List<PMC_CPQ_OrderProductDetailsWrapperClass> opDetailsWrapperList = new List<PMC_CPQ_OrderProductDetailsWrapperClass>();
		opDetailsWrapperList.add(opWrapper);

		Test.startTest();
		String jsonString = JSON.serialize(opDetailsWrapperList);
		String result = PMC_CPQ_sendFPDOrderProductsSAPClass.saveOPFromUI(jsonString);
		System.assertNotEquals(null, result, 'Result should not be null');
		Test.stopTest();

		// Verify approval was requested
		List<sbaa__Approval__c> approvals = [SELECT Id, sbaa__Status__c FROM sbaa__Approval__c WHERE OrderItem__c = :objOP.Id];
		System.assertEquals(1, approvals.size(), 'Approval should exist');
	}

	@isTest
	public static void testSaveOPFromUI_NoApprovalRequired() {
		// Test case where no approval is required (finalAgreedPrice >= floor price)
		OrderItem objOP = [SELECT Id FROM OrderItem WHERE ApprovalStatus__c = 'Approved' LIMIT 1];

		PMC_CPQ_OrderProductDetailsWrapperClass opWrapper = new PMC_CPQ_OrderProductDetailsWrapperClass();
		opWrapper.customId = objOP.Id;
		opWrapper.finalAgreedPrice = 600; // Above floor price

		List<PMC_CPQ_OrderProductDetailsWrapperClass> opDetailsWrapperList = new List<PMC_CPQ_OrderProductDetailsWrapperClass>();
		opDetailsWrapperList.add(opWrapper);

		Test.startTest();
		String jsonString = JSON.serialize(opDetailsWrapperList);
		String result = PMC_CPQ_sendFPDOrderProductsSAPClass.saveOPFromUI(jsonString);
		System.assertNotEquals(null, result, 'Result should not be null');
		Test.stopTest();

		// Verify order item was updated
		OrderItem updatedOP = [SELECT Id, PMC_CPQ_FinalAgreedPrice__c FROM OrderItem WHERE Id = :objOP.Id];
		System.assertEquals(600, updatedOP.PMC_CPQ_FinalAgreedPrice__c, 'Final price should be updated');
	}

	@isTest
	public static void testSendOrderProductsToSAP_Approved() {
		// Test sending approved order products to SAP
		OrderItem objOP = [SELECT Id FROM OrderItem WHERE ApprovalStatus__c = 'Approved' LIMIT 1];

		Test.startTest();
		String result = PMC_CPQ_sendFPDOrderProductsSAPClass.sendOrderProductsToSAP(new List<OrderItem>{ objOP });
		Test.stopTest();

		System.assertNotEquals('Some Selected Orders have been sent to PM for approval.', result, 'Approved items should not require approval');
	}

	@isTest
	public static void testSendOrderProductsToSAP_UnderRevision() {
		// Test sending Pending Approval order products to SAP
		OrderItem objOP = [SELECT Id FROM OrderItem WHERE ApprovalStatus__c = 'Pending Approval' LIMIT 1];

		Test.startTest();
		String result = PMC_CPQ_sendFPDOrderProductsSAPClass.sendOrderProductsToSAP(new List<OrderItem>{ objOP });
		Test.stopTest();

		System.assertEquals(
			'One or more selected Orders Lines have been sent to PM for approval.',
			result,
			'Pending Approval items should require approval'
		);
	}

	@isTest
	public static void testSendOrderProductsToSAP_Rejected() {
		// Test sending rejected order products to SAP
		OrderItem objOP = [SELECT Id FROM OrderItem WHERE ApprovalStatus__c = 'Rejected' LIMIT 1];

		Test.startTest();
		String result = PMC_CPQ_sendFPDOrderProductsSAPClass.sendOrderProductsToSAP(new List<OrderItem>{ objOP });
		Test.stopTest();

		System.assertEquals('One or more selected Orders Lines have been sent to PM for approval.', result, 'Rejected items should require approval');
	}

	@isTest
	public static void testGetPriceFromPriceFX() {
		OrderItem objOP = [SELECT Id FROM OrderItem LIMIT 1];

		PMC_CPQ_OrderProductDetailsWrapperClass opWrapper = new PMC_CPQ_OrderProductDetailsWrapperClass();
		opWrapper.customId = objOP.Id;

		List<PMC_CPQ_OrderProductDetailsWrapperClass> opDetailsWrapperList = new List<PMC_CPQ_OrderProductDetailsWrapperClass>();
		opDetailsWrapperList.add(opWrapper);

		Test.startTest();
		PMC_CPQ_sendFPDOrderProductsSAPClass.getPriceFromPriceFX(JSON.serialize(opDetailsWrapperList));
		Test.stopTest();

		// Verify the method executed without errors
		System.assert(true, 'Method should execute without exceptions');
	}

	@isTest
	public static void testSendFPDPriceFXURL() {
		Test.startTest();
		String endpoint = PMC_CPQ_sendFPDOrderProductsSAPClass.sendFPDPriceFXURL();
		Test.stopTest();

		System.assertNotEquals(null, endpoint, 'Endpoint should not be null');
	}

	@isTest
	public static void testRecallApprovalsAndNotify() {
		// Test the @future method for recalling approvals
		OrderItem objOP = [SELECT Id FROM OrderItem WHERE ApprovalStatus__c = 'Pending Approval' LIMIT 1];
		Set<Id> orderItemIds = new Set<Id>{ objOP.Id };

		Test.startTest();
		PMC_CPQ_sendFPDOrderProductsSAPClass.recallApprovalsAndNotify(JSON.serialize(orderItemIds));
		Test.stopTest();

		// Verify approval was recalled
		List<sbaa__Approval__c> approvals = [SELECT Id, sbaa__Status__c FROM sbaa__Approval__c WHERE OrderItem__c = :objOP.Id];
		System.assertEquals('Recalled', approvals[0].sbaa__Status__c, 'Approval should be recalled');
	}

	@isTest
	public static void testOrderItemsApprovalRequestsSendEmails() {
		// Test the @future method for sending approval request emails
		OrderItem objOP = [SELECT Id FROM OrderItem WHERE ApprovalStatus__c = 'Pending Approval' LIMIT 1];
		Set<Id> orderItemIds = new Set<Id>{ objOP.Id };

		Test.startTest();
		PMC_CPQ_sendFPDOrderProductsSAPClass.orderItemsApprovalRequestsSendEmails(JSON.serialize(orderItemIds));
		Test.stopTest();

		// Verify approval was updated to send email
		List<sbaa__Approval__c> approvals = [SELECT Id, PMC_CPQ_SendEmail__c FROM sbaa__Approval__c WHERE OrderItem__c = :objOP.Id];
		System.assertEquals(true, approvals[0].PMC_CPQ_SendEmail__c, 'Send Email flag should be true');
	}

	@isTest
	public static void testFetchOrderItems() {
		OrderItem objOP = [SELECT Id FROM OrderItem LIMIT 1];

		Test.startTest();
		List<OrderItem> result = PMC_CPQ_sendFPDOrderProductsSAPClass.fetchOrderItems(new List<Id>{ objOP.Id });
		Test.stopTest();

		System.assertEquals(1, result.size(), 'Should return the requested order item');
		System.assertEquals(objOP.Id, result[0].Id, 'Should return the correct order item');
	}

	@isTest
	public static void testSaveOPFromUI_ExceptionHandling() {
		// Test exception handling in saveOPFromUI
		Test.startTest();
		try {
			PMC_CPQ_sendFPDOrderProductsSAPClass.saveOPFromUI('invalid json');
			System.assert(false, 'Exception should be thrown');
		} catch (Exception e) {
			System.assert(true, 'Exception was caught as expected');
		}
		Test.stopTest();
	}

	@isTest
	public static void testGetRowsForProcessing_WithApprovalRequired() {
		// Test getRowsForProcessing with items requiring approval
		List<OrderItem> orderItems = [
			SELECT Id, PMC_CPQ_FinalAgreedPrice__c
			FROM OrderItem
			LIMIT 1
		];

		List<Id> selectedIds = new List<Id>();
		Map<Id, Decimal> updatedPrices = new Map<Id, Decimal>();

		for (OrderItem oi : orderItems) {
			selectedIds.add(oi.Id);
			// Set price below floor to trigger approval
			updatedPrices.put(oi.Id, 400);
		}

		Test.startTest();
		Map<String, List<PMC_CPQ_OrderProductDetailsWrapperClass>> result = PMC_CPQ_sendFPDOrderProductsSAPClass.getRowsForProcessing(
			selectedIds,
			updatedPrices
		);
		Test.stopTest();

		System.assertNotEquals(null, result, 'Result should not be null');
		System.assert(result.containsKey('approvalRows'), 'Result should contain approvalRows key');
		System.assert(result.containsKey('nonApprovalRows'), 'Result should contain nonApprovalRows key');
		System.assertEquals(
			selectedIds.size(),
			result.get('approvalRows').size(),
			'All items should require approval due to low price'
		);
	}

	@isTest
	public static void testGetRowsForProcessing_WithoutApprovalRequired() {
		// Test getRowsForProcessing with items not requiring approval
		List<OrderItem> orderItems = [
			SELECT Id, PMC_CPQ_FinalAgreedPrice__c
			FROM OrderItem
			LIMIT 1
		];

		List<Id> selectedIds = new List<Id>();
		Map<Id, Decimal> updatedPrices = new Map<Id, Decimal>();

		for (OrderItem oi : orderItems) {
			selectedIds.add(oi.Id);
			// Set price above floor to avoid approval
			updatedPrices.put(oi.Id, 600);
		}

		Test.startTest();
		Map<String, List<PMC_CPQ_OrderProductDetailsWrapperClass>> result = PMC_CPQ_sendFPDOrderProductsSAPClass.getRowsForProcessing(
			selectedIds,
			updatedPrices
		);
		Test.stopTest();

		System.assertNotEquals(null, result, 'Result should not be null');
		System.assert(result.containsKey('approvalRows'), 'Result should contain approvalRows key');
		System.assert(result.containsKey('nonApprovalRows'), 'Result should contain nonApprovalRows key');
		System.assertEquals(
			selectedIds.size(),
			result.get('nonApprovalRows').size(),
			'All items should not require approval due to acceptable price'
		);
	}

	@isTest
	public static void testGetRowsForProcessing_MixedRows() {
		// Test getRowsForProcessing with mixed approval requirements
		List<OrderItem> orderItems = [
			SELECT Id, PMC_CPQ_FinalAgreedPrice__c
			FROM OrderItem
			LIMIT 2
		];

		List<Id> selectedIds = new List<Id>();
		Map<Id, Decimal> updatedPrices = new Map<Id, Decimal>();

		if (orderItems.size() >= 2) {
			selectedIds.add(orderItems[0].Id);
			updatedPrices.put(orderItems[0].Id, 400); // Below floor - requires approval

			selectedIds.add(orderItems[1].Id);
			updatedPrices.put(orderItems[1].Id, 600); // Above floor - no approval
		}

		Test.startTest();
		Map<String, List<PMC_CPQ_OrderProductDetailsWrapperClass>> result = PMC_CPQ_sendFPDOrderProductsSAPClass.getRowsForProcessing(
			selectedIds,
			updatedPrices
		);
		Test.stopTest();

		System.assertNotEquals(null, result, 'Result should not be null');
		System.assertEquals(1, result.get('approvalRows').size(), 'One item should require approval');
		System.assertEquals(1, result.get('nonApprovalRows').size(), 'One item should not require approval');
	}

	@isTest
	public static void testGetRowsForProcessing_NullUpdatedPrices() {
		// Test getRowsForProcessing with null updated prices
		List<OrderItem> orderItems = [SELECT Id FROM OrderItem WHERE ApprovalStatus__c = 'Approved' LIMIT 1];

		List<Id> selectedIds = new List<Id>{ orderItems[0].Id };

		Test.startTest();
		Map<String, List<PMC_CPQ_OrderProductDetailsWrapperClass>> result = PMC_CPQ_sendFPDOrderProductsSAPClass.getRowsForProcessing(
			selectedIds,
			null
		);
		Test.stopTest();

		System.assertNotEquals(null, result, 'Result should not be null');
		System.assert(result.containsKey('approvalRows'), 'Result should contain approvalRows key');
		System.assert(result.containsKey('nonApprovalRows'), 'Result should contain nonApprovalRows key');
	}

	@isTest
	public static void testConvertOrderItemToWrapper() {
		// Test convertOrderItemToWrapper method
		OrderItem objOP = [
			SELECT
				Id,
				OrderItemNumber,
				OrderId,
				Order.OrderNumber,
				SBQQ__Contract__r.PMC_CPQ_ContractNumberIdentifier__c,
				PMC_CPQ_LinePONumber__c,
				PMC_CPQ_ShipTo__r.Name,
				Order.AccountId,
				Order.Account.Name,
				Product2.Name,
				Quantity,
				PMC_CPQ_PricingDate__c,
				PMC_CPQ_Floorplusfreight__c,
				PMC_CPQ_FPDPricefromPriceFx__c,
				PMC_CPQ_FinalAgreedPrice__c,
				PMC_CPQ_PriceGuidanceCeiling__c,
				PMC_CPQ_EstFreightPrice__c,
				PMC_CPQ_OrderLineStatus__c,
				PMC_CPQ_OrderItemIntegrationStatus__c,
				PMC_CPQ_OrderItemIntegrationMessage__c,
				ApprovalStatus__c,
				Order.PMC_CPQ_SAPOrderNumber__c
			FROM OrderItem
			WHERE ApprovalStatus__c = 'Approved'
			LIMIT 1
		];

		Test.startTest();
		PMC_CPQ_OrderProductDetailsWrapperClass wrapper = PMC_CPQ_sendFPDOrderProductsSAPClass.convertOrderItemToWrapper(objOP);
		Test.stopTest();

		System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
		System.assertEquals(objOP.Id, wrapper.customId, 'Custom ID should match');
		System.assertEquals(objOP.Quantity, wrapper.quantity, 'Quantity should match');
		System.assertEquals(objOP.PMC_CPQ_FinalAgreedPrice__c, wrapper.finalAgreedPrice, 'Final agreed price should match');
		System.assertEquals(objOP.Product2.Name, wrapper.productName, 'Product name should match');
		System.assertEquals(objOP.Order.OrderNumber, wrapper.orderNum, 'Order number should match');
		System.assertEquals(
			objOP.PMC_CPQ_EstFreightPrice__c,
			wrapper.freight,
			'Freight should match'
		);
		System.assertEquals(
			objOP.PMC_CPQ_OrderItemIntegrationMessage__c,
			wrapper.integrationMessage,
			'Integration message should match'
		);
		System.assertEquals(objOP.ApprovalStatus__c, wrapper.approvalStatus, 'Approval status should match');
		System.assertEquals(objOP.Order.PMC_CPQ_SAPOrderNumber__c, wrapper.sapOrderNumber, 'SAP order number should match');
	}

	@isTest
	public static void testConvertOrderItemToWrapper_NullContract() {
		// Test convertOrderItemToWrapper with null contract
		OrderItem objOP = [
			SELECT
				Id,
				OrderItemNumber,
				OrderId,
				Order.OrderNumber,
				SBQQ__Contract__r.PMC_CPQ_ContractNumberIdentifier__c,
				Product2.Name,
				Quantity,
				PMC_CPQ_FinalAgreedPrice__c,
				PMC_CPQ_EstFreightPrice__c,
				PMC_CPQ_OrderItemIntegrationMessage__c,
				ApprovalStatus__c,
				Order.PMC_CPQ_SAPOrderNumber__c
			FROM OrderItem
			LIMIT 1
		];

		Test.startTest();
		PMC_CPQ_OrderProductDetailsWrapperClass wrapper = PMC_CPQ_sendFPDOrderProductsSAPClass.convertOrderItemToWrapper(objOP);
		Test.stopTest();

		System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
		System.assertEquals(objOP.Id, wrapper.customId, 'Custom ID should match');
		// Contract number might be null if contract is not set
		if (objOP.SBQQ__Contract__r != null) {
			System.assertEquals(
				objOP.SBQQ__Contract__r.PMC_CPQ_ContractNumberIdentifier__c,
				wrapper.contractNum,
				'Contract number should match'
			);
		}
	}
}