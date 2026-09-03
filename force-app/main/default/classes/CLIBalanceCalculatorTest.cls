@isTest
private class CLIBalanceCalculatorTest {

    private static final String STANDARD_ORDER_CODE = 'ZORB';
    private static final String RETURN_ORDER_CODE   = 'ZRE';
    private static final String UNKNOWN_ORDER_CODE  = 'XXX';
    private static final String NORMAL_BILLING_DOC  = 'ZF2B';
    private static final Decimal UNIT_PRICE         = 0;

    private static final Id CUSTOMER_RECORD_TYPE_ID = Schema.SObjectType.Account
        .getRecordTypeInfosByDeveloperName()
        .get('PMC_SS_Customer')
        .getRecordTypeId();


    @isTest
    static void testStandardOrderAndInvoice() {
        Contract_Line_Item__c cli = createCli(100);
        SBQQ__Subscription__c sub = createSubscription(cli.Id, getAccountId(cli.Id));
        OrderItem oi = createOrderItem(getAccountId(cli.Id), sub.Id, STANDARD_ORDER_CODE, 30, null);
        createInvoiceItem(oi.Id, 20, 'ZRE', false, 'Standard');

        Test.startTest();
        new CLIBalanceCalculator(new Set<Id>{ cli.Id }).execute();
        Test.stopTest();

        Contract_Line_Item__c result = queryCli(cli.Id);
        Assert.areEqual(10,  result.Total_Ordered_Quantity__c,   'C2 = totalOrdered - returnQty = 30 - 20 = 10');
        Assert.areEqual(-20, result.Invoiced_Quantity__c,        'C5 = invoicedQty - returnQty = 0 - 20 = -20');
        Assert.areEqual(30,  result.Total_Consumed_Quantity__c,  'C4 = C2 - (invoicedQty - returnQty) = 10 - (0 - 20) = 30');
        Assert.areEqual(90, result.Total_Available_Quantity__c, 'C3 = C1 - C2 = 100 - 10 = 90');
    }

    /**
     * Cenário do bug corrigido (replica o log de produção):
     * pedido 80, invoice normal 80 (ZF2B), devolução 40 (ZREB).
     * Antes: C4 = 40 - 80 = -40. Depois: C4 = 40 - (80 - 40) = 0.
     */
    @isTest
    static void testStandardInvoiceWithReturn_consumedIsZero() {
        Contract_Line_Item__c cli = createCli(130);
        Id accId = getAccountId(cli.Id);
        SBQQ__Subscription__c sub = createSubscription(cli.Id, accId);
        OrderItem oi = createOrderItem(accId, sub.Id, STANDARD_ORDER_CODE, 80, null);

        createInvoiceItem(oi.Id, 80, NORMAL_BILLING_DOC, true,  'Standard'); // cancelada: ignorada
        createInvoiceItem(oi.Id, 80, NORMAL_BILLING_DOC, false, 'Standard'); // invoicedQty = 80
        createInvoiceItem(oi.Id, 40, 'ZREB',             false, 'Return');   // returnQty = 40

        Test.startTest();
        new CLIBalanceCalculator(new Set<Id>{ cli.Id }).execute();
        Test.stopTest();

        Contract_Line_Item__c result = queryCli(cli.Id);
        Assert.areEqual(40, result.Total_Ordered_Quantity__c,   'C2 = 80 - 40 = 40');
        Assert.areEqual(40, result.Invoiced_Quantity__c,        'C5 = invoicedQty - returnQty = 80 - 40 = 40 (invoice cancelada ignorada)');
        Assert.areEqual(0,  result.Total_Consumed_Quantity__c,  'C4 = C2 - (invoicedQty - returnQty) = 40 - (80 - 40) = 0');
        Assert.areEqual(90, result.Total_Available_Quantity__c, 'C3 = 130 - 40 = 90');
    }

    @isTest
    static void testReturnOrder_increasesAvailable() {
        Contract_Line_Item__c cli = createCli(100);
        Id accId = getAccountId(cli.Id);
        SBQQ__Subscription__c sub = createSubscription(cli.Id, accId);
        OrderItem stdOi = createOrderItem(accId, sub.Id, STANDARD_ORDER_CODE, 40, null);
        createInvoiceItem(stdOi.Id, 25, 'ZRE', false, 'Standard');

        OrderItem retOi = createOrderItem(accId, sub.Id, RETURN_ORDER_CODE, 10, null);
        createInvoiceItem(retOi.Id, 10, 'ZRE', false, 'Return');

        Test.startTest();
        new CLIBalanceCalculator(new Set<Id>{ cli.Id }).execute();
        Test.stopTest();

        Contract_Line_Item__c result = queryCli(cli.Id);
        Assert.areEqual(5,   result.Total_Ordered_Quantity__c,   'C2 = 40 (ZORB) - 35 (returnQty) = 5');
        Assert.areEqual(-35, result.Invoiced_Quantity__c,        'C5 = invoicedQty - returnQty = 0 - 35 = -35 (todos os invoices são ZRE billing)');
        Assert.areEqual(95, result.Total_Available_Quantity__c, 'C3 = C1 - C2 = 100 - 5 = 95');
    }

    @isTest
    static void testReturnWithoutInvoice_doesNotAffectAvailable() {
        Contract_Line_Item__c cli = createCli(100);
        Id accId = getAccountId(cli.Id);
        SBQQ__Subscription__c sub = createSubscription(cli.Id, accId);

        OrderItem stdOi = createOrderItem(accId, sub.Id, STANDARD_ORDER_CODE, 30, null);
        createInvoiceItem(stdOi.Id, 20, 'ZRE', false, 'Standard');
        createOrderItem(accId, sub.Id, RETURN_ORDER_CODE, 15, null);

        Test.startTest();
        new CLIBalanceCalculator(new Set<Id>{ cli.Id }).execute();
        Test.stopTest();

        Contract_Line_Item__c result = queryCli(cli.Id);
        Assert.areEqual(10,  result.Total_Ordered_Quantity__c,   'C2 = 30 - 20 = 10 (retorno sem invoice não afeta)');
        Assert.areEqual(-20, result.Invoiced_Quantity__c,        'C5 = invoicedQty - returnQty = 0 - 20 = -20');
        Assert.areEqual(90, result.Total_Available_Quantity__c, 'C3 = 100 - 10 = 90');
    }

    @isTest
    static void testCancelledInvoice_isReversal() {
        Contract_Line_Item__c cli = createCli(100);
        Id accId = getAccountId(cli.Id);
        SBQQ__Subscription__c sub = createSubscription(cli.Id, accId);
        OrderItem oi = createOrderItem(accId, sub.Id, STANDARD_ORDER_CODE, 30, null);
        createInvoiceItem(oi.Id, 15, 'ZRE', true, 'Standard');

        Test.startTest();
        new CLIBalanceCalculator(new Set<Id>{ cli.Id }).execute();
        Test.stopTest();

        Contract_Line_Item__c result = queryCli(cli.Id);
        Assert.areEqual(30, result.Total_Ordered_Quantity__c,   'C2 = 30 (invoice cancelada não reduz C2)');
        Assert.areEqual(0,  result.Invoiced_Quantity__c,        'C5 = 0 (invoice cancelada ignorada)');
        Assert.areEqual(70, result.Total_Available_Quantity__c, 'C3 = 100 - 30 = 70');
        Assert.areEqual(30, result.Total_Consumed_Quantity__c,  'C4 = C2 - (invoicedQty - returnQty) = 30 - (0 - 0) = 30');
    }

    @isTest
    static void testFaInvoice_isSkipped() {
        Contract_Line_Item__c cli = createCli(100);
        Id accId = getAccountId(cli.Id);
        SBQQ__Subscription__c sub = createSubscription(cli.Id, accId);
        OrderItem oi = createOrderItem(accId, sub.Id, STANDARD_ORDER_CODE, 30, null);
        createInvoiceItem(oi.Id, 25, 'FA', false, 'Standard');

        Test.startTest();
        new CLIBalanceCalculator(new Set<Id>{ cli.Id }).execute();
        Test.stopTest();

        Contract_Line_Item__c result = queryCli(cli.Id);
        Assert.areEqual(30, result.Total_Ordered_Quantity__c,   'C2 = 30 (FA não afeta)');
        Assert.areEqual(0,  result.Invoiced_Quantity__c,        'C5 = 0 (FA ignorada)');
        Assert.areEqual(70, result.Total_Available_Quantity__c, 'C3 = 100 - 30 = 70');
    }

    @isTest
    static void testRejectedOrderItem_isExcluded() {
        Contract_Line_Item__c cli = createCli(100);
        Id accId = getAccountId(cli.Id);
        SBQQ__Subscription__c sub = createSubscription(cli.Id, accId);
        // Item rejeitado não entra em totalOrdered
        createOrderItem(accId, sub.Id, STANDARD_ORDER_CODE, 20, 'Reshipment');
        createOrderItem(accId, sub.Id, STANDARD_ORDER_CODE, 15, null);

        Test.startTest();
        new CLIBalanceCalculator(new Set<Id>{ cli.Id }).execute();
        Test.stopTest();

        Contract_Line_Item__c result = queryCli(cli.Id);
        Assert.areEqual(15, result.Total_Ordered_Quantity__c,   'C2 = 15 (item rejeitado excluído)');
        Assert.areEqual(85, result.Total_Available_Quantity__c, 'C3 = 100 - 15 = 85');
    }

    @isTest
    static void testUnknownOrderTypeCode_isExcluded() {
        Contract_Line_Item__c cli = createCli(100);
        Id accId = getAccountId(cli.Id);
        SBQQ__Subscription__c sub = createSubscription(cli.Id, accId);
        createOrderItem(accId, sub.Id, UNKNOWN_ORDER_CODE, 25, null);

        Test.startTest();
        new CLIBalanceCalculator(new Set<Id>{ cli.Id }).execute();
        Test.stopTest();

        Contract_Line_Item__c result = queryCli(cli.Id);
        Assert.areEqual(0,   result.Total_Ordered_Quantity__c,   'C2 = 0 (tipo desconhecido excluído)');
        Assert.areEqual(100, result.Total_Available_Quantity__c, 'C3 = C1 inalterado');
    }

    @isTest
    static void testNegativeBalance_c2_viaReturns() {
        Contract_Line_Item__c cli = createCli(100);
        Id accId = getAccountId(cli.Id);
        SBQQ__Subscription__c sub = createSubscription(cli.Id, accId);
        OrderItem oi = createOrderItem(accId, sub.Id, STANDARD_ORDER_CODE, 100, null);
        createInvoiceItem(oi.Id, 100.05, 'ZRE', false, 'Standard');

        Test.startTest();
        new CLIBalanceCalculator(new Set<Id>{ cli.Id }).execute();
        Test.stopTest();

        // C2 = 100 - 100.05 = -0.05
        Contract_Line_Item__c result = queryCli(cli.Id);
        Assert.areEqual(-0.05,  result.Total_Ordered_Quantity__c,   'C2 = 100 - 100.05 = -0.05');
        Assert.areEqual(-100.05, result.Invoiced_Quantity__c,       'C5 = invoicedQty - returnQty = 0 - 100.05 = -100.05 (ZRE billing)');
        Assert.areEqual(100.05, result.Total_Available_Quantity__c, 'C3 = 100 - (-0.05) = 100.05');
        Assert.areEqual(100,    result.Total_Consumed_Quantity__c,  'C4 = C2 - (invoicedQty - returnQty) = -0.05 - (0 - 100.05) = 100');
    }

    @isTest
    static void testNegativeBalance_c3_viaReversals() {
        Contract_Line_Item__c cli = createCli(50);
        Id accId = getAccountId(cli.Id);
        SBQQ__Subscription__c sub = createSubscription(cli.Id, accId);
        OrderItem oi = createOrderItem(accId, sub.Id, STANDARD_ORDER_CODE, 50, null);
        createInvoiceItem(oi.Id, 10, 'ZRE', true, 'Standard');

        Test.startTest();
        new CLIBalanceCalculator(new Set<Id>{ cli.Id }).execute();
        Test.stopTest();

        Contract_Line_Item__c result = queryCli(cli.Id);
        Assert.areEqual(50, result.Total_Ordered_Quantity__c,   'C2 = 50 (invoice cancelada ignorada)');
        Assert.areEqual(0,  result.Total_Available_Quantity__c, 'C3 = 50 - 50 = 0');
    }

    @isTest
    static void testCli_withoutChildren() {
        Contract_Line_Item__c cli = createCli(75);

        Test.startTest();
        new CLIBalanceCalculator(new Set<Id>{ cli.Id }).execute();
        Test.stopTest();

        Contract_Line_Item__c result = queryCli(cli.Id);
        Assert.areEqual(0,  result.Total_Ordered_Quantity__c,   'C2 = 0 sem pedidos');
        Assert.areEqual(0,  result.Invoiced_Quantity__c,        'C5 = 0 sem invoices');
        Assert.areEqual(0,  result.Total_Consumed_Quantity__c,  'C4 = 0');
        Assert.areEqual(75, result.Total_Available_Quantity__c, 'C3 = C1 = 75');
    }

    @isTest
    static void testMultipleSubscriptions_perCli() {
        Contract_Line_Item__c cli = createCli(200);
        Id accId = getAccountId(cli.Id);
        SBQQ__Subscription__c sub1 = createSubscription(cli.Id, accId);
        SBQQ__Subscription__c sub2 = createSubscription(cli.Id, accId);

        OrderItem oi1 = createOrderItem(accId, sub1.Id, STANDARD_ORDER_CODE, 60, null);
        OrderItem oi2 = createOrderItem(accId, sub2.Id, STANDARD_ORDER_CODE, 40, null);
        createInvoiceItem(oi1.Id, 30, 'ZRE', false, 'Standard');
        createInvoiceItem(oi2.Id, 20, 'ZRE', false, 'Standard');

        Test.startTest();
        new CLIBalanceCalculator(new Set<Id>{ cli.Id }).execute();
        Test.stopTest();

        Contract_Line_Item__c result = queryCli(cli.Id);
        Assert.areEqual(50,  result.Total_Ordered_Quantity__c,   'C2 = 100 - 50 (returnQty) = 50');
        Assert.areEqual(-50, result.Invoiced_Quantity__c,        'C5 = invoicedQty - returnQty = 0 - 50 = -50 (ZRE billing)');
        Assert.areEqual(100, result.Total_Consumed_Quantity__c,  'C4 = C2 - (invoicedQty - returnQty) = 50 - (0 - 50) = 100');
        Assert.areEqual(150, result.Total_Available_Quantity__c, 'C3 = 200 - 50 = 150');
    }

    @isTest
    static void testBulkProcessing() {
        final Integer NUM = 5;

        Account acc = new Account(Name = generateRandomizedName('BULK'), RecordTypeId = CUSTOMER_RECORD_TYPE_ID, BillingCity = 'Tampa', BillingStreet = '1 Mosaic Ave');
        insert acc;

        String curr = [SELECT CurrencyIsoCode FROM Account WHERE Id = :acc.Id].CurrencyIsoCode;

        Contract ctr = new Contract(AccountId = acc.Id, Status = 'Draft', StartDate = Date.today(), ContractTerm = 12);
        insert ctr;

        SBQQ.TriggerControl.disable();
        OrderItemTriggerHandler.boolBypassTriggerLogic = true;
        try {
            Product2 prod = new Product2(Name = generateRandomizedName('PROD'), IsActive = true);
            insert prod;

            Id stdPbId = Test.getStandardPricebookId();
            PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = prod.Id, UnitPrice = UNIT_PRICE, IsActive = true, CurrencyIsoCode = curr);
            insert stdPbe;

            Order ord = new Order(AccountId = acc.Id, EffectiveDate = Date.today(), Status = 'Draft', Pricebook2Id = stdPbId, CurrencyIsoCode = curr, PMC_DH_OrderTypeCode__c = STANDARD_ORDER_CODE);
            insert ord;
            ord = [SELECT Id, Pricebook2Id, CurrencyIsoCode FROM Order WHERE Id = :ord.Id];

            PricebookEntry effectivePbe;
            if (ord.Pricebook2Id == stdPbId) {
                effectivePbe = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Id = :stdPbe.Id AND CurrencyIsoCode = :ord.CurrencyIsoCode];
            } else {
                PricebookEntry customPbe = new PricebookEntry(Pricebook2Id = ord.Pricebook2Id, Product2Id = prod.Id, UnitPrice = UNIT_PRICE, IsActive = true, CurrencyIsoCode = ord.CurrencyIsoCode);
                insert customPbe;
                effectivePbe = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Id = :customPbe.Id];
            }

            List<Contract_Line_Item__c> clis = new List<Contract_Line_Item__c>();
            for (Integer i = 0; i < NUM; i++) {
                clis.add(new Contract_Line_Item__c(Contract__c = ctr.Id, Quantity__c = 100));
            }
            insert clis;

            List<SBQQ__Subscription__c> subs = new List<SBQQ__Subscription__c>();
            for (Integer i = 0; i < NUM; i++) {
                subs.add(new SBQQ__Subscription__c(SBQQ__Account__c = acc.Id, SBQQ__Contract__c = ctr.Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionStartDate__c = Date.today(), SBQQ__SubscriptionEndDate__c = Date.today().addYears(1)));
            }
            insert subs;

            List<SBQQ__Subscription__c> subsToLink = new List<SBQQ__Subscription__c>();
            for (Integer i = 0; i < NUM; i++) {
                subsToLink.add(new SBQQ__Subscription__c(Id = subs[i].Id, Contract_Line_Item__c = clis[i].Id));
            }
            Database.update(subsToLink, false);

            List<OrderItem> ois = new List<OrderItem>();
            for (Integer i = 0; i < NUM; i++) {
                ois.add(new OrderItem(OrderId = ord.Id, PricebookEntryId = effectivePbe.Id, Quantity = 10, UnitPrice = effectivePbe.UnitPrice, SBQQ__Subscription__c = subs[i].Id));
            }
            insert ois;

            PMC_CPQ_InvoiceItemTriggerHandler.boolBypassTriggerLogic = true;
            List<PMC_CPQ_Invoice__c> invs = new List<PMC_CPQ_Invoice__c>();
            for (Integer i = 0; i < NUM; i++) {
                invs.add(new PMC_CPQ_Invoice__c(PMC_CPQ_BillingDocType__c = 'ZRE', PMC_CPQ_Cancelled__c = false, PMC_CPQ_Type__c = 'Standard', CurrencyIsoCode = curr));
            }
            insert invs;

            List<PMC_CPQ_InvoiceItem__c> iis = new List<PMC_CPQ_InvoiceItem__c>();
            for (Integer i = 0; i < NUM; i++) {
                iis.add(new PMC_CPQ_InvoiceItem__c(PMC_CPQ_Invoice__c = invs[i].Id, PMC_CPQ_OrderProduct__c = ois[i].Id, PMC_CPQ_NetInvoicedQuantity__c = 5));
            }
            insert iis;
            PMC_CPQ_InvoiceItemTriggerHandler.boolBypassTriggerLogic = false;

            Set<Id> cliIds = new Map<Id, Contract_Line_Item__c>(clis).keySet();

            Test.startTest();
            new CLIBalanceCalculator(cliIds).execute();
            Test.stopTest();

            for (Contract_Line_Item__c c : [
                SELECT Total_Ordered_Quantity__c, Invoiced_Quantity__c,
                       Total_Available_Quantity__c, Total_Consumed_Quantity__c
                FROM Contract_Line_Item__c WHERE Id IN :cliIds
            ]) {
                Assert.areEqual(5,  c.Total_Ordered_Quantity__c,   'Bulk: C2 = 10 - 5 = 5');
                Assert.areEqual(-5, c.Invoiced_Quantity__c,        'Bulk: C5 = invoicedQty - returnQty = 0 - 5 = -5 (ZRE billing)');
                Assert.areEqual(10, c.Total_Consumed_Quantity__c,  'Bulk: C4 = C2 - (invoicedQty - returnQty) = 5 - (0 - 5) = 10');
                Assert.areEqual(95, c.Total_Available_Quantity__c, 'Bulk: C3 = 100 - 5 = 95');
            }
        } finally {
            SBQQ.TriggerControl.enable();
            OrderItemTriggerHandler.boolBypassTriggerLogic = false;
        }
    }

    /**
     * Cenário do bug: item cancelado no SAP mas o volume não zerava.
     * Regra de prioridade: Subscription com PMC_CPQ_RejectionReason__c preenchido
     * deve forçar Total_Available_Quantity__c = 0, independente do cálculo normal.
     */
    @isTest
    static void testSubscriptionRejected_forcesAvailableToZero() {
        Contract_Line_Item__c cli = createCli(100);
        Id accId = getAccountId(cli.Id);
        SBQQ__Subscription__c sub = createSubscription(cli.Id, accId);
        OrderItem oi = createOrderItem(accId, sub.Id, STANDARD_ORDER_CODE, 30, null);
        createInvoiceItem(oi.Id, 20, 'ZRE', false, 'Standard');

        update new SBQQ__Subscription__c(Id = sub.Id, PMC_CPQ_RejectionReason__c = '9C');

        Test.startTest();
        new CLIBalanceCalculator(new Set<Id>{ cli.Id }).execute();
        Test.stopTest();

        Contract_Line_Item__c result = queryCli(cli.Id);
        Assert.areEqual(10, result.Total_Ordered_Quantity__c,   'C2 continua calculado normalmente = 30 - 20 = 10');
        Assert.areEqual(0,  result.Total_Available_Quantity__c, 'C3 deve ser forçado a 0 quando a Subscription está rejeitada');
    }

    @isTest
    static void testPropagation_subscriptionMirror() {
        Contract_Line_Item__c cli = createCli(100);
        Id accId = getAccountId(cli.Id);
        SBQQ__Subscription__c sub = createSubscription(cli.Id, accId);
        OrderItem oi = createOrderItem(accId, sub.Id, STANDARD_ORDER_CODE, 30, null);
        createInvoiceItem(oi.Id, 20, 'ZRE', false, 'Standard');

        Test.startTest();
        new CLIBalanceCalculator(new Set<Id>{ cli.Id }).execute();
        Test.stopTest();

        Contract_Line_Item__c result = queryCli(cli.Id);
        SBQQ__Subscription__c mirror = [
            SELECT PMC_CPQ_TotalAvailableQuantity__c, PMC_CPQ_TotalOrderedQuantity__c
            FROM SBQQ__Subscription__c WHERE Id = :sub.Id
        ];
        Assert.areEqual(result.Total_Available_Quantity__c, mirror.PMC_CPQ_TotalAvailableQuantity__c,
            'C3 deve ser espelhado na Subscription');
        Assert.areEqual(result.Total_Ordered_Quantity__c, mirror.PMC_CPQ_TotalOrderedQuantity__c,
            'C2 deve ser espelhado na Subscription');
    }

    private static Contract_Line_Item__c createCli(Decimal cliQuantity) {
        Account acc = new Account(
            Name          = generateRandomizedName('ACCOUNT'),
            RecordTypeId  = CUSTOMER_RECORD_TYPE_ID,
            BillingCity   = 'Tampa',
            BillingStreet = '1 Mosaic Ave'
        );
        insert acc;

        Contract ctr = new Contract(
            AccountId    = acc.Id,
            Status       = 'Draft',
            StartDate    = Date.today(),
            ContractTerm = 12
        );
        insert ctr;

        Contract_Line_Item__c cli = new Contract_Line_Item__c(
            Contract__c = ctr.Id,
            Quantity__c = cliQuantity
        );
        insert cli;

        return queryCli(cli.Id);
    }

    private static Contract_Line_Item__c queryCli(Id cliId) {
        return [
            SELECT Id, Quantity__c, Total_Ordered_Quantity__c, Total_Available_Quantity__c,
                   Total_Consumed_Quantity__c, Invoiced_Quantity__c
            FROM Contract_Line_Item__c
            WHERE Id = :cliId
        ];
    }

    private static Id getAccountId(Id cliId) {
        return [SELECT Contract__r.AccountId FROM Contract_Line_Item__c WHERE Id = :cliId]
               .Contract__r.AccountId;
    }

    private static SBQQ__Subscription__c createSubscription(Id cliId, Id accountId) {
        Id contractId = [SELECT Contract__c FROM Contract_Line_Item__c WHERE Id = :cliId].Contract__c;

        SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
            SBQQ__Account__c               = accountId,
            SBQQ__Contract__c              = contractId,
            SBQQ__Quantity__c              = 1,
            SBQQ__SubscriptionStartDate__c = Date.today(),
            SBQQ__SubscriptionEndDate__c   = Date.today().addYears(1)
        );
        insert sub;

        Database.update(
            new SBQQ__Subscription__c(Id = sub.Id, Contract_Line_Item__c = cliId),
            false
        );

        CLIBalanceTriggerHandler.boolBypassTriggerLogic = true;
        try {
            update new Contract_Line_Item__c(Id = cliId, Subscription__c = sub.Id);
        } finally {
            CLIBalanceTriggerHandler.boolBypassTriggerLogic = false;
        }

        return [SELECT Id, Contract_Line_Item__c FROM SBQQ__Subscription__c WHERE Id = :sub.Id];
    }

    private static OrderItem createOrderItem(Id accountId, Id subId, String orderTypeCode,
                                             Decimal qty, String rejectionReason) {
        SBQQ.TriggerControl.disable();
        OrderItemTriggerHandler.boolBypassTriggerLogic = true;
        try {
            String currencyCode = [SELECT CurrencyIsoCode FROM Account WHERE Id = :accountId].CurrencyIsoCode;

            Product2 prod = new Product2(Name = generateRandomizedName('PRODUCT') + orderTypeCode, IsActive = true);
            insert prod;

            Id stdPbId = Test.getStandardPricebookId();

            PricebookEntry stdPbe = new PricebookEntry(
                Pricebook2Id    = stdPbId,
                Product2Id      = prod.Id,
                UnitPrice       = UNIT_PRICE,
                IsActive        = true,
                CurrencyIsoCode = currencyCode
            );
            insert stdPbe;

            Order ord = new Order(
                AccountId               = accountId,
                EffectiveDate           = Date.today(),
                Status                  = 'Draft',
                Pricebook2Id            = stdPbId,
                CurrencyIsoCode         = currencyCode,
                PMC_DH_OrderTypeCode__c = orderTypeCode
            );
            insert ord;

            ord = [SELECT Id, Pricebook2Id, CurrencyIsoCode FROM Order WHERE Id = :ord.Id];

            PricebookEntry effectivePbe;
            if (ord.Pricebook2Id == stdPbId) {
                effectivePbe = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Id = :stdPbe.Id AND CurrencyIsoCode = :ord.CurrencyIsoCode];
            } else {
                PricebookEntry customPbe = new PricebookEntry(
                    Pricebook2Id    = ord.Pricebook2Id,
                    Product2Id      = prod.Id,
                    UnitPrice       = UNIT_PRICE,
                    IsActive        = true,
                    CurrencyIsoCode = ord.CurrencyIsoCode
                );
                insert customPbe;
                effectivePbe = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Id = :customPbe.Id];
            }

            OrderItem oi = new OrderItem(
                OrderId                            = ord.Id,
                PricebookEntryId                   = effectivePbe.Id,
                Quantity                           = qty,
                UnitPrice                          = effectivePbe.UnitPrice,
                SBQQ__Subscription__c              = subId,
                PMC_CPQ_ReasonOfRejectionOfItem__c = rejectionReason
            );
            insert oi;
            return oi;
        } finally {
            SBQQ.TriggerControl.enable();
            OrderItemTriggerHandler.boolBypassTriggerLogic = false;
        }
    }

    private static PMC_CPQ_InvoiceItem__c createInvoiceItem(Id orderItemId, Decimal qty,
                                                            String docType, Boolean cancelled,
                                                            String invoiceType) {
        PMC_CPQ_InvoiceItemTriggerHandler.boolBypassTriggerLogic = true;
        try {
            PMC_CPQ_Invoice__c inv = new PMC_CPQ_Invoice__c(
                PMC_CPQ_BillingDocType__c = docType,
                PMC_CPQ_Cancelled__c      = cancelled,
                PMC_CPQ_Type__c           = invoiceType
            );
            insert inv;

            PMC_CPQ_InvoiceItem__c ii = new PMC_CPQ_InvoiceItem__c(
                PMC_CPQ_Invoice__c             = inv.Id,
                PMC_CPQ_OrderProduct__c        = orderItemId,
                PMC_CPQ_NetInvoicedQuantity__c = qty
            );
            insert ii;
            return ii;
        } finally {
            PMC_CPQ_InvoiceItemTriggerHandler.boolBypassTriggerLogic = false;
        }
    }

    public static String generateRandomizedName(String baseName) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        String randomSuffix = '';
        while (randomSuffix.length() < 3) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randomSuffix += chars.substring(idx, idx + 1);
        }
        return baseName + '-' + randomSuffix;
    }
}