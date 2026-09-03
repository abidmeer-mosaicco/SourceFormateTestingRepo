@IsTest
private class OrderTriggerHandlerTest {

    private static final String ORDER_TYPE_CODE = 'ZOR';

    private static Contract_Line_Item__c getCliLinkedToOrder(Id orderId) {
        OrderItem oi = [
            SELECT SBQQ__Subscription__r.Contract_Line_Item__c
            FROM OrderItem
            WHERE OrderId = :orderId AND SBQQ__Subscription__r.Contract_Line_Item__c != null
            LIMIT 1
        ];
        return new Contract_Line_Item__c(Id = oi.SBQQ__Subscription__r.Contract_Line_Item__c);
    }

    @TestSetup
    static void setupTestData() {
        PMC_ProcessSwitches__c bypassSetting = PMC_ProcessSwitches__c.getOrgDefaults();
        bypassSetting.PMC_BypassFlow__c = true;
        upsert bypassSetting;

        SBQQ__Subscription__c sub = new SBQQ__Subscription__c(SBQQ__Quantity__c = 100);
        insert sub;

        CLIBalanceTriggerHandler.boolBypassTriggerLogic = true;
        Contract_Line_Item__c cli = new Contract_Line_Item__c(
            Quantity__c      = 10,
            Subscription__c  = sub.Id
        );
        insert cli;
        CLIBalanceTriggerHandler.boolBypassTriggerLogic = false;

        SBQQ.TriggerControl.disable();
        Database.update(new SBQQ__Subscription__c(Id = sub.Id, Contract_Line_Item__c = cli.Id), false);
        SBQQ.TriggerControl.enable();

        Account acc = new Account(
            Name          = 'Test Account',
            BillingCity   = 'Tampa',
            BillingStreet = '1 Mosaic Ave'
        );
        insert acc;

        Id stdPbId = Test.getStandardPricebookId();

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id   = prod.Id,
            UnitPrice    = 0,
            IsActive     = true
        );
        insert pbe;

        Order ord = new Order(
            AccountId               = acc.Id,
            EffectiveDate           = Date.today(),
            Status                  = 'Draft',
            Pricebook2Id            = stdPbId,
            PMC_DH_OrderTypeCode__c = ORDER_TYPE_CODE
        );
        insert ord;

        OrderItemTriggerHandler.boolBypassTriggerLogic = true;
        insert new OrderItem(
            OrderId                = ord.Id,
            PricebookEntryId       = pbe.Id,
            Quantity               = 5,
            UnitPrice              = 0,
            SBQQ__Subscription__c  = sub.Id
        );
        OrderItemTriggerHandler.boolBypassTriggerLogic = false;
    }

    /*
    @IsTest
    static void testCancellation_RecalculatesCLIBalance() {
        Order ord = [SELECT Id, Status FROM Order LIMIT 1];
        Contract_Line_Item__c cli = getCliLinkedToOrder(ord.Id);

        Test.startTest();
        ord.Status = 'Cancelled';
        update ord;
        Test.stopTest();

        Contract_Line_Item__c result = [
            SELECT Total_Ordered_Quantity__c, Total_Available_Quantity__c
            FROM Contract_Line_Item__c WHERE Id = :cli.Id
        ];
        Assert.areEqual(0,  result.Total_Ordered_Quantity__c,
            'Ordered quantity deve zerar pois o unico item pertence a uma Order cancelada');
        Assert.areEqual(10, result.Total_Available_Quantity__c,
            'Available deve voltar a igualar Quantity__c (10) apos o cancelamento');
    }*/

    @IsTest
    static void testStatusChangeNotToCancelled_CalculatorNotInvoked() {
        Order ord = [SELECT Id, Status FROM Order LIMIT 1];
        Contract_Line_Item__c cli = getCliLinkedToOrder(ord.Id);

        Test.startTest();
        ord.Status = 'Activated';
        update ord;
        Test.stopTest();

        Contract_Line_Item__c result = [
            SELECT Total_Ordered_Quantity__c, Total_Available_Quantity__c
            FROM Contract_Line_Item__c WHERE Id = :cli.Id
        ];
        Assert.isNull(result.Total_Ordered_Quantity__c,
            'Calculator nao deve rodar quando a Order nao muda para Cancelled');
        Assert.isNull(result.Total_Available_Quantity__c,
            'Calculator nao deve rodar quando a Order nao muda para Cancelled');
    }

    @IsTest
    static void testAlreadyCancelledOrder_NoReprocessing() {
        Order ord = [SELECT Id, Status FROM Order LIMIT 1];
        ord.Status = 'Cancelled';
        update ord;

        Contract_Line_Item__c cli = getCliLinkedToOrder(ord.Id);
        update new Contract_Line_Item__c(Id = cli.Id, Total_Available_Quantity__c = 999);

        Test.startTest();
        ord = [SELECT Id, Status, Description FROM Order LIMIT 1];
        ord.Description = 'no-op update, still Cancelled';
        update ord;
        Test.stopTest();

        Contract_Line_Item__c result = [
            SELECT Total_Available_Quantity__c FROM Contract_Line_Item__c WHERE Id = :cli.Id
        ];
        Assert.areEqual(999, result.Total_Available_Quantity__c,
            'Calculator nao deve reprocessar quando a Order ja estava Cancelled antes do update');
    }

    @IsTest
    static void testOrderTypeCodeChange_CalculatorRecalculatesCLIBalance() {
        Order ord = [SELECT Id, PMC_DH_OrderTypeCode__c FROM Order LIMIT 1];
        Contract_Line_Item__c cli = getCliLinkedToOrder(ord.Id);

        Test.startTest();
        ord.PMC_DH_OrderTypeCode__c = 'ZOFA';
        update ord;
        Test.stopTest();

        Contract_Line_Item__c result = [
            SELECT Total_Ordered_Quantity__c, Total_Available_Quantity__c
            FROM Contract_Line_Item__c WHERE Id = :cli.Id
        ];
        Assert.areEqual(5, result.Total_Ordered_Quantity__c,
            'Ordered quantity deve refletir a quantidade do OrderItem apos a mudanca do OrderTypeCode');
        Assert.areEqual(5, result.Total_Available_Quantity__c,
            'Available deve ser Quantity__c (10) menos o ordered quantity (5)');
    }

    @IsTest
    static void testOrderTypeCodeUnchanged_CalculatorNotInvoked() {
        Order ord = [SELECT Id, PMC_DH_OrderTypeCode__c, Description FROM Order LIMIT 1];
        Contract_Line_Item__c cli = getCliLinkedToOrder(ord.Id);

        Test.startTest();
        ord.Description = 'no-op update, OrderTypeCode unchanged';
        update ord;
        Test.stopTest();

        Contract_Line_Item__c result = [
            SELECT Total_Ordered_Quantity__c, Total_Available_Quantity__c
            FROM Contract_Line_Item__c WHERE Id = :cli.Id
        ];
        Assert.isNull(result.Total_Ordered_Quantity__c,
            'Calculator nao deve rodar quando o PMC_DH_OrderTypeCode__c nao muda');
        Assert.isNull(result.Total_Available_Quantity__c,
            'Calculator nao deve rodar quando o PMC_DH_OrderTypeCode__c nao muda');
    }

    @IsTest
    static void testOrderItemWithoutSubscription_NoErrorNoCalculatorCall() {
        Account acc = new Account(Name = 'No Sub Account', BillingCity = 'Tampa', BillingStreet = '2 Mosaic Ave');
        insert acc;

        Id stdPbId = Test.getStandardPricebookId();
        Product2 prod = new Product2(Name = 'No Sub Product', IsActive = true);
        insert prod;
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId, Product2Id = prod.Id, UnitPrice = 0, IsActive = true
        );
        insert pbe;

        Order ord = new Order(
            AccountId               = acc.Id,
            EffectiveDate           = Date.today(),
            Status                  = 'Draft',
            Pricebook2Id            = stdPbId,
            PMC_DH_OrderTypeCode__c = ORDER_TYPE_CODE
        );
        insert ord;

        insert new OrderItem(
            OrderId          = ord.Id,
            PricebookEntryId = pbe.Id,
            Quantity         = 1,
            UnitPrice        = 0
        );

        Test.startTest();
        ord.Status = 'Cancelled';
        update ord;
        Test.stopTest();

        Order result = [SELECT Status FROM Order WHERE Id = :ord.Id];
        Assert.areEqual('Cancelled', result.Status,
            'Order deve ser cancelada normalmente mesmo sem CLI associado ao item');
    }

    /*
    @IsTest
    static void testBulkCancellation_NoLimitsExceeded() {
        List<SBQQ__Subscription__c> subs = new List<SBQQ__Subscription__c>();
        for (Integer i = 0; i < 20; i++) {
            subs.add(new SBQQ__Subscription__c(SBQQ__Quantity__c = 100));
        }
        insert subs;

        CLIBalanceTriggerHandler.boolBypassTriggerLogic = true;
        List<Contract_Line_Item__c> clis = new List<Contract_Line_Item__c>();
        for (SBQQ__Subscription__c sub : subs) {
            clis.add(new Contract_Line_Item__c(Quantity__c = 10, Subscription__c = sub.Id));
        }
        insert clis;
        CLIBalanceTriggerHandler.boolBypassTriggerLogic = false;

        List<SBQQ__Subscription__c> subsToLink = new List<SBQQ__Subscription__c>();
        for (Integer i = 0; i < subs.size(); i++) {
            subsToLink.add(new SBQQ__Subscription__c(Id = subs[i].Id, Contract_Line_Item__c = clis[i].Id));
        }
        SBQQ.TriggerControl.disable();
        Database.update(subsToLink, false);
        SBQQ.TriggerControl.enable();

        Account acc = new Account(Name = 'Bulk Account', BillingCity = 'Tampa', BillingStreet = '3 Mosaic Ave');
        insert acc;

        Id stdPbId = Test.getStandardPricebookId();
        Product2 prod = new Product2(Name = 'Bulk Product', IsActive = true);
        insert prod;
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId, Product2Id = prod.Id, UnitPrice = 0, IsActive = true
        );
        insert pbe;

        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < 20; i++) {
            orders.add(new Order(
                AccountId               = acc.Id,
                EffectiveDate           = Date.today(),
                Status                  = 'Draft',
                Pricebook2Id            = stdPbId,
                PMC_DH_OrderTypeCode__c = ORDER_TYPE_CODE
            ));
        }
        insert orders;

        List<OrderItem> items = new List<OrderItem>();
        for (Integer i = 0; i < orders.size(); i++) {
            items.add(new OrderItem(
                OrderId               = orders[i].Id,
                PricebookEntryId      = pbe.Id,
                Quantity              = 5,
                UnitPrice             = 0,
                SBQQ__Subscription__c = subs[i].Id
            ));
        }
        insert items;

        for (Order ord : orders) {
            ord.Status = 'Cancelled';
        }

        Test.startTest();
        update orders;
        Test.stopTest();

        List<Contract_Line_Item__c> results = [
            SELECT Total_Ordered_Quantity__c, Total_Available_Quantity__c
            FROM Contract_Line_Item__c WHERE Id IN :new Map<Id, Contract_Line_Item__c>(clis).keySet()
        ];
        Assert.areEqual(20, results.size(), 'Todos os 20 CLIs devem ter sido recalculados');
        for (Contract_Line_Item__c cli : results) {
            Assert.areEqual(0,  cli.Total_Ordered_Quantity__c,  'Ordered deve zerar apos cancelamento em massa');
            Assert.areEqual(10, cli.Total_Available_Quantity__c, 'Available deve voltar a igualar Quantity__c');
        }
    }*/
}