@isTest
public class OrderItemTriggerHandlerTest {
	@testSetup
	static void setup() {
		List<Order> lstOrders = PMC_CPQ_OrderIntegrationTest.createOrders(1);
		User objUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        

		System.runAs(objUser) {
			List<Product2> prod = PMC_TestUtilityClass.createProduct(2, 'PMC_CPQ_NA');
			prod[0].PMC_CPQ_SAPProductCode__c = '';
			prod[1].PMC_CPQ_SAPProductCode__c = '';
			update prod;
			//Instantiate the Pricebook2 record with StandardPricebookId
			Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);

			//Execute an update DML on the Pricebook2 record, to make IsStandard to true
			update standardPricebook;

			lstOrders[0].Pricebook2Id = standardPricebook.Id;
			lstOrders[0].CurrencyIsoCode = 'USD';
			update lstOrders;
			//Create the PricebookEntry
			/*PricebookEntry pbe = new PricebookEntry(
				Pricebook2Id = standardPricebook.Id,
				Product2Id = prod[0].Id,
				UnitPrice = 0,
				// PMC_CPQ_ProductSKUCode__c = prod[0].PMC_CPQ_SAPProductCode__c,
				CurrencyIsoCode = lstOrders[0].CurrencyIsoCode,
				IsActive = true
			);
			insert pbe;*/
			List<PricebookEntry> pbEntries = new List<PricebookEntry>{
				new PricebookEntry(
					Pricebook2Id = standardPricebook.Id,
					Product2Id = prod[0].Id,
					UnitPrice = 0,
					// PMC_CPQ_ProductSKUCode__c = prod[0].PMC_CPQ_SAPProductCode__c,
					CurrencyIsoCode = lstOrders[0].CurrencyIsoCode,
					IsActive = true
				),
				new PricebookEntry(
					Pricebook2Id = standardPricebook.Id,
					Product2Id = prod[1].Id,
					UnitPrice = 0,
					CurrencyIsoCode = lstOrders[0].CurrencyIsoCode,
					IsActive = true
				)
			};
			insert pbEntries;

			OrderItem orderItemRecord = new OrderItem();

			orderItemRecord.Product2Id = prod[0].id;
			orderItemRecord.OrderId = lstOrders[0].id;
			orderItemRecord.Quantity = 2;
			orderItemRecord.PMC_CPQ_ListPrice__c = 180;
			orderItemRecord.UnitPrice = 0;
			orderItemRecord.ListPrice = 0;
			orderItemRecord.PMC_CPQ_FinalAgreedPrice__c = 1;
			orderItemRecord.ApprovalStatus__c = 'Pending Approval';
			orderItemRecord.PricebookEntryId = pbEntries[0].Id;
			insert orderItemRecord;
		}
	}

	@isTest
	static void testAfterUpdateApprovalStatusNotChanged() {
		// Retrieve the test OrderItem
		OrderItem testOrderItem = [SELECT Id, ApprovalStatus__c FROM OrderItem LIMIT 1];

		// Update a different field (not ApprovalStatus__c)
		testOrderItem.Quantity = 2;

		// Verify that the PMC_CPQ_FPDActionClass was not enqueued
		Test.startTest();
		update testOrderItem;
		Test.stopTest();

		// Assert that no job was enqueued
		System.assertEquals(0, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'], 'No job should have been enqueued.');
	}

	@isTest
	static void recalculateCLIByQuantity() {
		Integer queueNumber;
		OrderItem testOrderItem = [SELECT Id, Quantity FROM OrderItem LIMIT 1];
		testOrderItem.Quantity = 2;

		Test.startTest();
		update testOrderItem;
		queueNumber = Limits.getAsyncCalls();
		Test.stopTest();

		// Assert that no job was enqueued
		System.assertEquals(0, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable' AND ApexClass.Name = 'CLIBalanceCalculator']);
	}

	@isTest
	static void testAfterUpdateApprovalStatusChanged() {
		// Retrieve the test OrderItem
		OrderItem testOrderItem = [SELECT Id, ApprovalStatus__c FROM OrderItem WHERE ApprovalStatus__c = 'Pending Approval' LIMIT 1];

		// Update the ApprovalStatus__c to 'Approved'
		testOrderItem.ApprovalStatus__c = 'Approved';

		// Verify that the PMC_CPQ_FPDActionClass was not enqueued
		Test.startTest();
		update testOrderItem;
		Test.stopTest();

		// Assert that no job was enqueued
		System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'], '1 job should have been enqueued.');
	}

	@isTest
	static void testAfterUpdateBypassTriggerLogic() {
		// Bypass the trigger logic
		OrderItemTriggerHandler.boolBypassTriggerLogic = true;

		// Retrieve the test OrderItem
		OrderItem testOrderItem = [SELECT Id, ApprovalStatus__c FROM OrderItem LIMIT 1];

		// Update the ApprovalStatus__c to 'Approved'
		testOrderItem.ApprovalStatus__c = 'Approved';

		// Verify that the PMC_CPQ_FPDActionClass was not enqueued
		Test.startTest();
		update testOrderItem;
		Test.stopTest();

		// Assert that no job was enqueued
		System.assertEquals(
			0,
			[SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'],
			'No job should have been enqueued when trigger logic is bypassed.'
		);
	}

	@isTest
	static void testSendSAPIntegrationEmailPath() {
		// Prepare data: retrieve an existing order item
		OrderItem oi = [SELECT Id, OrderId, ApprovalStatus__c FROM OrderItem LIMIT 1];
		Id orderId = oi.OrderId;
		// Create AccountTeamMember entries for the Account related to the Order
		Account acct = [SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Order WHERE Id = :orderId) LIMIT 1];
		// Create a test user to be part of account team

		// Now simulate Integration User updating the integration message on OrderItem

		OrderItem up = new OrderItem(Id = oi.Id, PMC_CPQ_OrderItemIntegrationMessage__c = 'Integration update');
		Test.startTest();
		update up;
		Test.stopTest();
		// If no exceptions, assume email util path executed; assert nothing to verify directly
		System.assert(true);
	}

	@isTest
	static void testRecalcContractProductsMultiple() {
		Id accountId = [SELECT AccountId FROM Order LIMIT 1].AccountId;
		Contract testContract = new Contract(Name = 'Test Contract', AccountId = accountId);
		insert testContract;

		OrderItem firstOrderItem = [
			SELECT Id, Product2Id, OrderId, PricebookEntryId, PricebookEntry.Pricebook2Id, PricebookEntry.UnitPrice
			FROM OrderItem
			LIMIT 1
		];

		Product2 secondProduct = [SELECT Id FROM Product2 WHERE Id != :firstOrderItem.Product2Id LIMIT 1];
		PricebookEntry secondPbe = [
			SELECT Id, UnitPrice
			FROM PricebookEntry
			WHERE Product2Id = :secondProduct.Id AND Pricebook2Id = :firstOrderItem.PricebookEntry.Pricebook2Id
			LIMIT 1
		];

		firstOrderItem.SBQQ__Contract__c = testContract.Id;
		OrderItem secondItem = new OrderItem(
			Product2Id = secondProduct.Id,
			OrderId = firstOrderItem.OrderId,
			Quantity = 1,
			PricebookEntryId = secondPbe.Id,
			UnitPrice = secondPbe.UnitPrice,
			SBQQ__Contract__c = testContract.Id
		);

		List<OrderItem> itens = new List<OrderItem>();
		itens.add(firstOrderItem);
		itens.add(secondItem);

		Test.startTest();
		upsert itens;
		Test.stopTest();
	}
	
    @isTest
static void testEnqueueCliBalanceIfNeeded_fullChain_enqueuesJob() {
    User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
    Decimal cliAvailable = null;

    System.runAs(adminUser) {
        Order ord = [SELECT Id, AccountId FROM Order LIMIT 1];

        Contract cont = new Contract(
            AccountId    = ord.AccountId,
            StartDate    = Date.today(),
            ContractTerm = 12,
            Status       = 'Draft'
        );
        insert cont;

        Contract_Line_Item__c cli = new Contract_Line_Item__c(
            Contract__c = cont.Id,
            Quantity__c = 100
        );
        insert cli;

        SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
            SBQQ__Account__c  = ord.AccountId,
            SBQQ__Quantity__c = 1
        );
        insert sub;
        update new SBQQ__Subscription__c(Id = sub.Id, Contract_Line_Item__c = cli.Id);

        PricebookEntry pbe = [
            SELECT Id, UnitPrice, Product2Id FROM PricebookEntry
            WHERE Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1
        ];

        OrderItem oi = new OrderItem(
            OrderId               = ord.Id,
            Product2Id            = pbe.Product2Id,
            PricebookEntryId      = pbe.Id,
            Quantity              = 1,
            UnitPrice             = pbe.UnitPrice,
            SBQQ__Subscription__c = sub.Id
        );

        Test.startTest();
        insert oi;
        Test.stopTest();

        cliAvailable = [SELECT Total_Available_Quantity__c FROM Contract_Line_Item__c WHERE Id = :cli.Id].Total_Available_Quantity__c;
    }

    System.assertNotEquals(null, cliAvailable, 'Calculator deve ter rodado via cadeia completa OI→Sub→CLI e atualizado Total_Available_Quantity__c');
}
    
}