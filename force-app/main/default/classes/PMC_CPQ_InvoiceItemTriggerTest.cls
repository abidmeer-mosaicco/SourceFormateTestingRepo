@isTest
private class PMC_CPQ_InvoiceItemTriggerTest {

    @TestSetup
    static void setup() {
        String curr = UserInfo.getDefaultCurrency();
        //User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

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
            AccountId               = acc.Id,
            Status                  = 'Draft',
            EffectiveDate           = Date.today(),
            Pricebook2Id            = Test.getStandardPricebookId(),
            CurrencyIsoCode         = curr,
            PMC_DH_OrderTypeCode__c = 'ZOR'
        );
        insert ord;

        Contract cont = new Contract(
            AccountId       = acc.Id,
            StartDate       = Date.today(),
            ContractTerm    = 12,
            Status          = 'Draft',
            CurrencyIsoCode = curr
        );
        insert cont;

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

            
            Contract_Line_Item__c cli = new Contract_Line_Item__c(
                Contract__c     = cont.Id,
                Subscription__c = sub.Id,
                Quantity__c     = 10
            );
           Database.insert(cli, System.AccessLevel.SYSTEM_MODE);

            sub.Contract_Line_Item__c = cli.Id;
            update sub;
        

        PMC_CPQ_Invoice__c inv = new PMC_CPQ_Invoice__c(CurrencyIsoCode = curr);
        insert inv;
    }

    @isTest
    static void afterInsert_validChain_enqueuesCalculator() {
        SBQQ__Subscription__c subBefore = [
            SELECT Id, Contract_Line_Item__r.Total_Ordered_Quantity__c
            FROM SBQQ__Subscription__c
            WHERE Contract_Line_Item__c != null
            LIMIT 1
        ];

        Test.startTest();
        insert buildInvoiceItem();
        Test.stopTest();

        SBQQ__Subscription__c subAfter = [
            SELECT Id, Contract_Line_Item__r.Total_Ordered_Quantity__c
            FROM SBQQ__Subscription__c
            WHERE Id = :subBefore.Id
        ];

        Assert.areNotEqual(
            subBefore.Contract_Line_Item__r.Total_Ordered_Quantity__c,
            subAfter.Contract_Line_Item__r.Total_Ordered_Quantity__c,
            'Insert com cadeia completa deve recalcular o saldo do CLI'
        );
    }

    @isTest
    static void afterInsert_nullOrderProduct_doesNotEnqueue() {
        Integer asyncCalls = 0;
        Test.startTest();
        insert new PMC_CPQ_InvoiceItem__c(
            PMC_CPQ_Invoice__c             = [SELECT Id FROM PMC_CPQ_Invoice__c LIMIT 1].Id,
            PMC_CPQ_NetInvoicedQuantity__c = 5
        );
        asyncCalls = Limits.getAsyncCalls();
        Test.stopTest();

        Assert.areEqual(0, asyncCalls, 'Sem OrderProduct nao deve enfileirar');
    }

    @isTest
    static void afterInsert_bypassFlag_doesNotEnqueue() {
        PMC_CPQ_InvoiceItemTriggerHandler.boolBypassTriggerLogic = true;
        Integer asyncCalls = 0;
        Test.startTest();
        insert buildInvoiceItem();
        asyncCalls = Limits.getAsyncCalls();
        Test.stopTest();

        Assert.areEqual(0, asyncCalls, 'Bypass ativo deve impedir enqueue no insert');
    }

    @isTest
    static void afterInsert_orderItemWithoutSubscription_doesNotEnqueue() {
        String curr = UserInfo.getDefaultCurrency();

        Order ord = new Order(
            AccountId       = [SELECT Id FROM Account LIMIT 1].Id,
            Status          = 'Draft',
            EffectiveDate   = Date.today(),
            Pricebook2Id    = Test.getStandardPricebookId(),
            CurrencyIsoCode = curr
        );
        insert ord;

        PricebookEntry pbe = [
            SELECT Id, UnitPrice, Product2Id
            FROM PricebookEntry
            WHERE Pricebook2Id    = :Test.getStandardPricebookId()
            AND   CurrencyIsoCode = :curr
            LIMIT 1
        ];
        OrderItem oi = new OrderItem(
            OrderId          = ord.Id,
            Product2Id       = pbe.Product2Id,
            PricebookEntryId = pbe.Id,
            Quantity         = 1,
            UnitPrice        = pbe.UnitPrice
        );
        insert oi;

        Integer asyncCalls = 0;
        Test.startTest();
        insert new PMC_CPQ_InvoiceItem__c(
            PMC_CPQ_OrderProduct__c        = oi.Id,
            PMC_CPQ_Invoice__c             = [SELECT Id FROM PMC_CPQ_Invoice__c LIMIT 1].Id,
            PMC_CPQ_NetInvoicedQuantity__c = 5
        );
        asyncCalls = Limits.getAsyncCalls();
        Test.stopTest();

        Assert.areEqual(0, asyncCalls, 'OrderItem sem Subscription nao deve enfileirar');
    }

    @isTest
    static void afterUpdate_quantityChanged_enqueuesCalculator() {
        Id iiId = insertBypassed(buildInvoiceItem()).Id;

        SBQQ__Subscription__c subBefore = [
            SELECT Id, Contract_Line_Item__r.Total_Ordered_Quantity__c
            FROM SBQQ__Subscription__c
            WHERE Contract_Line_Item__c != null
            LIMIT 1
        ];

        Test.startTest();
        update new PMC_CPQ_InvoiceItem__c(Id = iiId, PMC_CPQ_NetInvoicedQuantity__c = 20);
        Test.stopTest();

        SBQQ__Subscription__c subAfter = [
            SELECT Id, Contract_Line_Item__r.Total_Ordered_Quantity__c
            FROM SBQQ__Subscription__c
            WHERE Id = :subBefore.Id
        ];

        Assert.areNotEqual(
            subBefore.Contract_Line_Item__r.Total_Ordered_Quantity__c,
            subAfter.Contract_Line_Item__r.Total_Ordered_Quantity__c,
            'Update com mudanca de quantidade deve recalcular o saldo do CLI'
        );
    }

    @isTest
    static void afterUpdate_noRelevantChange_doesNotEnqueue() {
        Id iiId = insertBypassed(buildInvoiceItem()).Id;
        Integer asyncCalls = 0;
        Test.startTest();
        update new PMC_CPQ_InvoiceItem__c(Id = iiId, PMC_CPQ_NetInvoicedQuantity__c = 5);
        asyncCalls = Limits.getAsyncCalls();
        Test.stopTest();

        Assert.areEqual(0, asyncCalls, 'Update sem mudanca relevante nao deve enfileirar');
    }

    @isTest
    static void afterUpdate_bypassFlag_doesNotEnqueue() {
        Id iiId = insertBypassed(buildInvoiceItem()).Id;
        PMC_CPQ_InvoiceItemTriggerHandler.boolBypassTriggerLogic = true;
        Integer asyncCalls = 0;
        Test.startTest();
        update new PMC_CPQ_InvoiceItem__c(Id = iiId, PMC_CPQ_NetInvoicedQuantity__c = 99);
        asyncCalls = Limits.getAsyncCalls();
        Test.stopTest();

        Assert.areEqual(0, asyncCalls, 'Bypass ativo deve impedir enqueue no update');
    }

    @isTest
    static void collectOrderItemIds_insert_returnsAllNonNullOrderProducts() {
        Id oiId = [SELECT Id FROM OrderItem LIMIT 1].Id;

        PMC_CPQ_InvoiceItem__c iiWithOi  = new PMC_CPQ_InvoiceItem__c(PMC_CPQ_OrderProduct__c = oiId);
        PMC_CPQ_InvoiceItem__c iiWithout = new PMC_CPQ_InvoiceItem__c();

        Set<Id> result = PMC_CPQ_InvoiceItemTriggerHandler.collectOrderItemIds(
            new List<PMC_CPQ_InvoiceItem__c>{ iiWithOi, iiWithout }, null
        );

        Assert.areEqual(1, result.size(), 'Deve retornar apenas o OrderItem nao nulo');
        Assert.isTrue(result.contains(oiId), 'Deve conter o Id do OrderItem correto');
    }

    @isTest
    static void collectOrderItemIds_update_returnsOnlyChangedRecords() {
        Id oiId   = [SELECT Id FROM OrderItem LIMIT 1].Id;
        Id invId  = [SELECT Id FROM PMC_CPQ_Invoice__c LIMIT 1].Id;
        Id fakeId = Schema.SObjectType.PMC_CPQ_InvoiceItem__c.getKeyPrefix() +
                    '000000000001';

        PMC_CPQ_InvoiceItem__c changed = new PMC_CPQ_InvoiceItem__c(
            Id = fakeId, PMC_CPQ_OrderProduct__c = oiId, PMC_CPQ_NetInvoicedQuantity__c = 10
        );
        PMC_CPQ_InvoiceItem__c unchanged = new PMC_CPQ_InvoiceItem__c(
            Id = fakeId, PMC_CPQ_OrderProduct__c = oiId, PMC_CPQ_NetInvoicedQuantity__c = 5
        );
        PMC_CPQ_InvoiceItem__c oldVersion = new PMC_CPQ_InvoiceItem__c(
            Id = fakeId, PMC_CPQ_OrderProduct__c = oiId, PMC_CPQ_NetInvoicedQuantity__c = 5
        );

        Set<Id> changedResult = PMC_CPQ_InvoiceItemTriggerHandler.collectOrderItemIds(
            new List<PMC_CPQ_InvoiceItem__c>{ changed },
            new Map<Id, PMC_CPQ_InvoiceItem__c>{ fakeId => oldVersion }
        );
        Set<Id> unchangedResult = PMC_CPQ_InvoiceItemTriggerHandler.collectOrderItemIds(
            new List<PMC_CPQ_InvoiceItem__c>{ unchanged },
            new Map<Id, PMC_CPQ_InvoiceItem__c>{ fakeId => oldVersion }
        );

        Assert.areEqual(1, changedResult.size(),   'Registro com mudanca deve ser coletado');
        Assert.areEqual(0, unchangedResult.size(), 'Registro sem mudanca nao deve ser coletado');
    }

    @isTest
    static void hasRelevantChange_quantityChanged_returnsTrue() {
        PMC_CPQ_InvoiceItem__c newRec = new PMC_CPQ_InvoiceItem__c(PMC_CPQ_NetInvoicedQuantity__c = 10);
        PMC_CPQ_InvoiceItem__c oldRec = new PMC_CPQ_InvoiceItem__c(PMC_CPQ_NetInvoicedQuantity__c = 5);

        Assert.isTrue(PMC_CPQ_InvoiceItemTriggerHandler.hasRelevantChange(newRec, oldRec),
            'Mudanca de quantidade deve ser relevante');
    }

    @isTest
    static void hasRelevantChange_invoiceChanged_returnsTrue() {
        Id invId = [SELECT Id FROM PMC_CPQ_Invoice__c LIMIT 1].Id;

        PMC_CPQ_InvoiceItem__c newRec = new PMC_CPQ_InvoiceItem__c(
            PMC_CPQ_NetInvoicedQuantity__c = 5, PMC_CPQ_Invoice__c = invId
        );
        PMC_CPQ_InvoiceItem__c oldRec = new PMC_CPQ_InvoiceItem__c(
            PMC_CPQ_NetInvoicedQuantity__c = 5
        );

        Assert.isTrue(PMC_CPQ_InvoiceItemTriggerHandler.hasRelevantChange(newRec, oldRec),
            'Mudanca de Invoice deve ser relevante');
    }

    @isTest
    static void hasRelevantChange_noChange_returnsFalse() {
        Id invId = [SELECT Id FROM PMC_CPQ_Invoice__c LIMIT 1].Id;

        PMC_CPQ_InvoiceItem__c rec = new PMC_CPQ_InvoiceItem__c(
            PMC_CPQ_NetInvoicedQuantity__c = 5, PMC_CPQ_Invoice__c = invId
        );

        Assert.isFalse(PMC_CPQ_InvoiceItemTriggerHandler.hasRelevantChange(rec, rec),
            'Sem mudancas relevantes deve retornar false');
    }

    @isTest
    static void getSubscriptionIds_validOrderItem_returnsSubId() {
        OrderItem oi = [SELECT Id, SBQQ__Subscription__c FROM OrderItem
                        WHERE SBQQ__Subscription__c != null LIMIT 1];

        Set<Id> result = PMC_CPQ_InvoiceItemTriggerHandler.getSubscriptionIds(
            new Set<Id>{ oi.Id }
        );

        Assert.areEqual(1, result.size(), 'Deve retornar 1 Subscription');
        Assert.isTrue(result.contains(oi.SBQQ__Subscription__c),
            'Deve conter o Id da Subscription correta');
    }

    @isTest
    static void getCLIIds_validSubscription_returnsCLIId() {
        SBQQ__Subscription__c sub = [SELECT Id, Contract_Line_Item__c
                                     FROM SBQQ__Subscription__c
                                     WHERE Contract_Line_Item__c != null LIMIT 1];

        Set<Id> result = PMC_CPQ_InvoiceItemTriggerHandler.getCLIIds(
            new Set<Id>{ sub.Id }
        );

        Assert.areEqual(1, result.size(), 'Deve retornar 1 CLI');
        Assert.isTrue(result.contains(sub.Contract_Line_Item__c),
            'Deve conter o Id do CLI correto');
    }

    @isTest
    static void enqueueIfNeeded_emptyOiIds_doesNotEnqueue() {
        Integer asyncCalls = 0;
        Test.startTest();
        PMC_CPQ_InvoiceItemTriggerHandler.enqueueIfNeeded(new Set<Id>());
        asyncCalls = Limits.getAsyncCalls();
        Test.stopTest();

        Assert.areEqual(0, asyncCalls, 'Set vazio nao deve enfileirar');
    }


    private static PMC_CPQ_InvoiceItem__c buildInvoiceItem() {
        return new PMC_CPQ_InvoiceItem__c(
            PMC_CPQ_OrderProduct__c        = [
                SELECT Id FROM OrderItem
                WHERE SBQQ__Subscription__c != null
                LIMIT 1
            ].Id,
            PMC_CPQ_Invoice__c             = [SELECT Id FROM PMC_CPQ_Invoice__c LIMIT 1].Id,
            PMC_CPQ_NetInvoicedQuantity__c = 5
        );
    }

    private static PMC_CPQ_InvoiceItem__c insertBypassed(PMC_CPQ_InvoiceItem__c ii) {
        PMC_CPQ_InvoiceItemTriggerHandler.boolBypassTriggerLogic = true;
        insert ii;
        PMC_CPQ_InvoiceItemTriggerHandler.boolBypassTriggerLogic = false;
        return ii;
    }
}