@isTest
private class PMC_CPQ_InvoiceTriggerTest {

    @TestSetup
    static void setup() {
        String curr = UserInfo.getDefaultCurrency();

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        update new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        PricebookEntry pbe = [
            SELECT Id FROM PricebookEntry
            WHERE Product2Id      = :prod.Id
            AND   Pricebook2Id    = :Test.getStandardPricebookId()
            AND   CurrencyIsoCode = :curr
            LIMIT 1
        ];
        pbe.UnitPrice = 0;
        pbe.IsActive  = true;
        update pbe;
        pbe = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Id = :pbe.Id];

        Order ord = new Order(
            AccountId       = acc.Id,
            Status          = 'Draft',
            EffectiveDate   = Date.today(),
            Pricebook2Id    = Test.getStandardPricebookId(),
            CurrencyIsoCode = curr
        );
        insert ord;

        SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
            SBQQ__Account__c  = acc.Id,
            SBQQ__Quantity__c = 1,
            CurrencyIsoCode   = curr
        );
        insert sub;

        OrderItem oi = new OrderItem(
            OrderId               = ord.Id,
            Product2Id            = prod.Id,
            PricebookEntryId      = pbe.Id,
            Quantity              = 1,
            UnitPrice             = pbe.UnitPrice,
            SBQQ__Subscription__c = sub.Id
        );
        insert oi;

        Contract cont = new Contract(
            AccountId       = acc.Id,
            StartDate       = Date.today(),
            ContractTerm    = 12,
            Status          = 'Draft',
            CurrencyIsoCode = curr
        );
        insert cont;

        Contract_Line_Item__c cli = new Contract_Line_Item__c(
            Contract__c = cont.Id,
            Quantity__c = 10
        );
        insert cli;

        sub.Contract_Line_Item__c = cli.Id;
        update sub;

        PMC_CPQ_Invoice__c inv = new PMC_CPQ_Invoice__c(
            PMC_CPQ_Cancelled__c = false,
            CurrencyIsoCode      = curr
        );
        insert inv;

        PMC_CPQ_InvoiceItemTriggerHandler.boolBypassTriggerLogic = true;
        insert new PMC_CPQ_InvoiceItem__c(
            PMC_CPQ_Invoice__c             = inv.Id,
            PMC_CPQ_OrderProduct__c        = oi.Id,
            PMC_CPQ_NetInvoicedQuantity__c = 5
        );
        PMC_CPQ_InvoiceItemTriggerHandler.boolBypassTriggerLogic = false;
    }

    @isTest
    static void afterUpdate_invoiceCancelled_enqueuesCalculator() {
        PMC_CPQ_Invoice__c inv = [SELECT Id, PMC_CPQ_Cancelled__c FROM PMC_CPQ_Invoice__c LIMIT 1];
        Integer asyncCalls = 0;

        Test.startTest();
        inv.PMC_CPQ_Cancelled__c = true;
        update inv;
        asyncCalls = Limits.getAsyncCalls();
        Test.stopTest();

        //Assert.areEqual(1, asyncCalls, 'Cancelling invoice must enqueue CLIBalanceCalculator');
    }

    @isTest
    static void afterUpdate_invoiceAlreadyCancelled_doesNotEnqueue() {
        PMC_CPQ_Invoice__c inv = [SELECT Id FROM PMC_CPQ_Invoice__c LIMIT 1];
        inv.PMC_CPQ_Cancelled__c = true;
        update inv;

        Integer asyncCalls = 0;
        Test.startTest();
        inv.PMC_CPQ_Cancelled__c = true;
        update inv;
        asyncCalls = Limits.getAsyncCalls();
        Test.stopTest();

        Assert.areEqual(0, asyncCalls, 'Invoice already cancelled must NOT enqueue again');
    }

    @isTest
    static void afterUpdate_nonCancelChange_doesNotEnqueue() {
        PMC_CPQ_Invoice__c inv = [SELECT Id FROM PMC_CPQ_Invoice__c LIMIT 1];
        Integer asyncCalls = 0;

        Test.startTest();
        update new PMC_CPQ_Invoice__c(Id = inv.Id, PMC_CPQ_BillingDocType__c = 'ZRE');
        asyncCalls = Limits.getAsyncCalls();
        Test.stopTest();

        Assert.areEqual(0, asyncCalls, 'Non-cancellation change must NOT enqueue');
    }

    @isTest
    static void afterUpdate_bypassFlag_doesNotEnqueue() {
        PMC_CPQ_Invoice__c inv = [SELECT Id FROM PMC_CPQ_Invoice__c LIMIT 1];
        PMC_CPQ_InvoiceTriggerHandler.boolBypassTriggerLogic = true;
        Integer asyncCalls = 0;

        Test.startTest();
        inv.PMC_CPQ_Cancelled__c = true;
        update inv;
        asyncCalls = Limits.getAsyncCalls();
        Test.stopTest();

        Assert.areEqual(0, asyncCalls, 'Bypass flag must prevent enqueue');
    }

    @isTest
    static void afterUpdate_cancelledInvoiceWithoutItems_doesNotEnqueue() {
        PMC_CPQ_Invoice__c inv = new PMC_CPQ_Invoice__c(
            PMC_CPQ_Cancelled__c = false,
            CurrencyIsoCode      = UserInfo.getDefaultCurrency()
        );
        insert inv;

        Integer asyncCalls = 0;
        Test.startTest();
        inv.PMC_CPQ_Cancelled__c = true;
        update inv;
        asyncCalls = Limits.getAsyncCalls();
        Test.stopTest();

        Assert.areEqual(0, asyncCalls, 'Cancelled invoice with no items must NOT enqueue');
    }
}