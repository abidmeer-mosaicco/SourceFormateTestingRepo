@isTest
public class PMC_CPQ_SAPOrderIntegrationEmailCtrlTest {
	@testSetup
	static void setup() {
		// Create test data using factory pattern
		Account testAccount = PMC_DH_TestDataFactoryClass.createTestAccount();

		Contact testContact = PMC_DH_TestDataFactoryClass.createTestContact(testAccount.Id);

		Opportunity testOpportunity = PMC_DH_TestDataFactoryClass.createOpportunity(testAccount);

		SBQQ__Quote__c testQuote = PMC_DH_TestDataFactoryClass.createQuote(testAccount, testContact.Id, testOpportunity);

		Product2 testProduct = PMC_DH_TestDataFactoryClass.createProduct();
		testProduct.PMC_CPQ_SAPProductCode__c = '';
		if (testProduct.Id != null) {
			update testProduct;
		} else {
			insert testProduct;
		}

		Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
		update standardPricebook;

		PricebookEntry pbe = new PricebookEntry(
			Pricebook2Id = standardPricebook.Id,
			Product2Id = testProduct.Id,
			UnitPrice = 0,
			CurrencyIsoCode = 'USD',
			IsActive = true
		);
		insert pbe;

		Order testOrder = new Order(
			AccountId = testAccount.Id,
			EffectiveDate = Date.today(),
			Status = 'Draft',
			Pricebook2Id = standardPricebook.Id,
			CurrencyIsoCode = 'USD',
			SBQQ__Quote__c = testQuote.Id
		);
		insert testOrder;

		OrderItem orderItemRecord = new OrderItem();
		orderItemRecord.Product2Id = testProduct.Id;
		orderItemRecord.OrderId = testOrder.Id;
		orderItemRecord.Quantity = 2;
		orderItemRecord.PMC_CPQ_ListPrice__c = 180;
		orderItemRecord.UnitPrice = 0;
		orderItemRecord.ListPrice = 0;
		orderItemRecord.PMC_CPQ_FinalAgreedPrice__c = 1;
		orderItemRecord.PricebookEntryId = pbe.Id;
		orderItemRecord.SendIntegrationResultEmail__c = true;
		orderItemRecord.PMC_CPQ_OrderItemIntegrationMessage__c = 'Save and Send to SAP: Order Updated Successfully';
		orderItemRecord.ApprovalStatus__c = 'Approved';
		insert orderItemRecord;
	}

	@isTest
	static void testControllerLoadsCorrectData() {
		Order testOrder = [SELECT Id FROM Order LIMIT 1];

		Test.startTest();
		PMC_CPQ_SAPOrderIntegrationEmailCtrl ctrl = new PMC_CPQ_SAPOrderIntegrationEmailCtrl();
		ctrl.orderId = testOrder.Id;

		PMC_CPQ_SAPOrderIntegrationEmailCtrl.OrderWrapper ord = ctrl.getOrderRecord();
		List<PMC_CPQ_SAPOrderIntegrationEmailCtrl.OrderItemWrapper> lines = ctrl.getFilteredOrderItemWrappers();
		Test.stopTest();

		System.assertNotEquals(null, ord, 'OrderWrapper should not be null');
		System.assertEquals(1, lines.size(), 'Should return 1 order item wrapper');
		System.assertEquals('Save and Send to SAP: Order Updated Successfully', lines[0].integrationMessage);
	}
}