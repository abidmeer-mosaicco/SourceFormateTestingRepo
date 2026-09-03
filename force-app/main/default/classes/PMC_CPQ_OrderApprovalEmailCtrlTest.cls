@IsTest
private class PMC_CPQ_OrderApprovalEmailCtrlTest {

private static Pricebook2 ensureStandardPricebookActive() {
    Id stdPbId = Test.getStandardPricebookId();

    try {
        update new Pricebook2(Id = stdPbId, IsActive = true);
    } catch (DmlException e) {
    }

    return new Pricebook2(Id = stdPbId);
}

    private static Product2 ensureProduct(String name) {
        List<Product2> ps = [SELECT Id, Name, IsActive FROM Product2 WHERE Name = :name LIMIT 1];
        if (ps.isEmpty()) {
            Product2 p = new Product2(Name = name, IsActive = true);
            insert p;
            return p;
        }
        if (!ps[0].IsActive) {
            ps[0].IsActive = true;
            update ps[0];
        }
        return ps[0];
    }

    private static PricebookEntry ensurePbe(Pricebook2 pb, Product2 p, Decimal unitPrice) {
        List<PricebookEntry> existing = [
            SELECT Id, IsActive FROM PricebookEntry
            WHERE Pricebook2Id = :pb.Id AND Product2Id = :p.Id
            LIMIT 1
        ];
        if (existing.isEmpty()) {
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = pb.Id,
                Product2Id   = p.Id,
                UnitPrice    = unitPrice,
                IsActive     = true,
                UseStandardPrice = false
            );
            insert pbe;
            return pbe;
        }
        if (!existing[0].IsActive) {
            existing[0].IsActive = true;
            update existing[0];
        }
        return existing[0];
    }

    private static Account ensureAccount(String name) {
        List<Account> accs = [SELECT Id, Name FROM Account WHERE Name = :name LIMIT 1];
        if (accs.isEmpty()) {
            Account a = new Account(Name = name);
            insert a;
            return a;
        }
        return accs[0];
    }

    private static Order ensureOrder(Account a, Pricebook2 pb) {
        List<Order> os = [
            SELECT Id, AccountId, Pricebook2Id
            FROM Order
            WHERE AccountId = :a.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (!os.isEmpty()) {
            Order o = os[0];
            if (o.Pricebook2Id == null) {
                o.Pricebook2Id = pb.Id;
                update o;
            }
            return o;
        }
        Order ord = new Order(
            AccountId    = a.Id,
            EffectiveDate= Date.today(),
            Status       = 'Draft',
            Pricebook2Id = pb.Id
        );
        insert ord;
        return ord;
    }

    private static OrderItem ensureOrderItem(Order o, PricebookEntry pbe, Decimal unitPrice) {
        List<OrderItem> ois = [
            SELECT Id, OrderId, PricebookEntryId, UnitPrice, Quantity, ApprovalStatus__c,
                   PricebookEntry.Product2.Name
            FROM OrderItem
            WHERE OrderId = :o.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (!ois.isEmpty()) return ois[0];

        OrderItem oi = new OrderItem(
            OrderId         = o.Id,
            PricebookEntryId= pbe.Id,
            Quantity        = 1,
            UnitPrice       = unitPrice,
            ApprovalStatus__c = 'Pending Approval',
            PMC_CPQ_FinalAgreedPrice__c = unitPrice,
            PMC_CPQ_EstFreightPrice__c = 10,
            PMC_CPQ_PriceGuidanceCeiling__c = 150,
            PMC_CPQ_FPDPricefromPriceFx__c = 100
        );
        insert oi;
        return oi;
    }

    private static SBAA__Approval__c ensureApprovalForItem(OrderItem oi, String status, Boolean sendEmail) {
        List<SBAA__Approval__c> aps = [
            SELECT Id, sbaa__Status__c, PMC_CPQ_SendEmail__c
            FROM SBAA__Approval__c
            WHERE OrderItem__c = :oi.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (aps.isEmpty()) {
            SBAA__Approval__c ap = new SBAA__Approval__c(
                sbaa__ApprovalStep__c = 1,
                sbaa__RecordField__c  = 'ApprovalStatus__c',
                OrderItem__c          = oi.Id,
                sbaa__Status__c       = status,
                PMC_CPQ_SendEmail__c  = sendEmail
            );
            insert ap;
            return ap;
        }
        SBAA__Approval__c upd = aps[0];
        upd.sbaa__Status__c = status;
        upd.PMC_CPQ_SendEmail__c = sendEmail;
        update upd;
        return upd;
    }

    private class TestGraph {
        Account acc;
        Pricebook2 pb;
        Product2 product;
        PricebookEntry pbe;
        Order ord;
        OrderItem oi;
        SBAA__Approval__c approval;
    }
    private static TestGraph ensureGraph() {
        TestGraph tg = new TestGraph();
        tg.acc     = ensureAccount('Test Account');
        tg.pb      = ensureStandardPricebookActive();
        tg.product = ensureProduct('Test Product 0');
        tg.pbe     = ensurePbe(tg.pb, tg.product, 100);
        tg.ord     = ensureOrder(tg.acc, tg.pb);
        tg.oi      = ensureOrderItem(tg.ord, tg.pbe, 100);
        tg.approval= ensureApprovalForItem(tg.oi, 'Requested', true);
        return tg;
    }

    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        List<User> testUsers = new List<User>();
        for (Integer i = 0; i < 3; i++) {
            testUsers.add(new User(
                FirstName = 'Test',
                LastName = 'User ' + i,
                Email = 'testuser' + i + '@example.com',
                Username = 'testuser' + i + '+' + System.currentTimeMillis() + '@example.com',
                Alias = ('tuser' + i).left(8),
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Los_Angeles',
                ProfileId = p.Id
            ));
        }
        insert testUsers;

        try {
            List<Order> lstOrders = PMC_CPQ_OrderIntegrationTest.createOrders(1);
            if (!lstOrders.isEmpty()) {
                PMC_TestUtilityClass.createOrderProducts(1, lstOrders);
            }
        } catch (Exception ignore) { /* fallback handled in tests */ }

        List<OrderItem> seeded = [SELECT Id FROM OrderItem LIMIT 1];
        if (!seeded.isEmpty()) {
            List<SBAA__Approval__c> aps = new List<SBAA__Approval__c>{
                new SBAA__Approval__c(
                    sbaa__ApprovalStep__c = 1,
                    sbaa__RecordField__c  = 'ApprovalStatus__c',
                    OrderItem__c          = seeded[0].Id,
                    sbaa__Status__c       = 'Requested',
                    PMC_CPQ_SendEmail__c  = true
                )
            };
            insert aps;
        }
    }


    @IsTest
    static void testGetOrderRecord() {
        TestGraph tg = ensureGraph();

        Test.startTest();
        PMC_CPQ_OrderApprovalEmailCtrl controller = new PMC_CPQ_OrderApprovalEmailCtrl();
        controller.orderId = tg.ord.Id;
        PMC_CPQ_OrderApprovalEmailCtrl.OrderWrapper result = controller.getOrderRecord();
        Test.stopTest();

        System.assertNotEquals(null, result, 'OrderWrapper should not be null');
        System.assertEquals('Test Account', result.accountName, 'Account name should match');
    }

    @IsTest
    static void testGetOrderItemWrappers() {
        TestGraph tg = ensureGraph();

        tg.oi = [
            SELECT Id, ApprovalStatus__c, OrderId, PricebookEntry.Product2.Name
            FROM OrderItem WHERE Id = :tg.oi.Id LIMIT 1
        ];
        tg.oi.ApprovalStatus__c = 'Pending Approval';
        update tg.oi;

        tg.approval = ensureApprovalForItem(tg.oi, 'Requested', true);

        Test.startTest();
        PMC_CPQ_OrderApprovalEmailCtrl controller = new PMC_CPQ_OrderApprovalEmailCtrl();
        controller.orderId = tg.ord.Id;
        controller.approvalStatus = 'Requested';
        List<PMC_CPQ_OrderApprovalEmailCtrl.OrderItemWrapper> results = controller.getOrderItemWrappers();
        Test.stopTest();

        System.assertNotEquals(null, results, 'OrderItemWrappers should not be null');
        System.assertEquals(1, results.size(), 'Should return one OrderItemWrapper');
        System.assertEquals(
            tg.oi.PricebookEntry.Product2.Name,
            results[0].productName,
            'Product name should match'
        );
    }

    @IsTest
    static void testBaseUrlProperties() {
        PMC_CPQ_OrderApprovalEmailCtrl controller = new PMC_CPQ_OrderApprovalEmailCtrl();
        Test.startTest();
        String baseUrl = controller.baseUrl;
        String listViewUrl = controller.listViewUrl;
        Test.stopTest();

        System.assertNotEquals(null, baseUrl, 'Base URL should not be null');
        System.assertNotEquals(null, listViewUrl, 'List view URL should not be null');
    }

    @IsTest
    static void testOrderUrl() {
        TestGraph tg = ensureGraph();

        Test.startTest();
        PMC_CPQ_OrderApprovalEmailCtrl controller = new PMC_CPQ_OrderApprovalEmailCtrl();
        controller.orderId = tg.ord.Id;
        String orderUrl = controller.orderUrl;
        Test.stopTest();

        System.assertNotEquals(null, orderUrl, 'Order URL should not be null');
        System.assert(orderUrl.contains(tg.ord.Id), 'Order URL should contain order ID');
    }

    @IsTest
    static void testListViewUrlForMaterialGroups() {
        Test.startTest();
        PMC_CPQ_OrderApprovalEmailCtrl controller = new PMC_CPQ_OrderApprovalEmailCtrl();

        controller.materialGroup = 'Potash';
        String potashUrl = controller.listViewUrl;

        controller.materialGroup = 'Phosphate';
        String phosphateUrl = controller.listViewUrl;

        controller.materialGroup = 'Other';
        String defaultUrl = controller.listViewUrl;
        Test.stopTest();

        System.assert(potashUrl.contains('Potash_FPD_Approval_Requests'), 'Should return Potash filter URL');
        System.assert(phosphateUrl.contains('Phosphate_FPD_Approval_Requests'), 'Should return Phosphate filter URL');
        System.assert(defaultUrl.contains('FPD_Approval_Requests'), 'Should return default filter URL');
    }

    @IsTest
    static void testFormatMethods() {
        Test.startTest();
        PMC_CPQ_OrderApprovalEmailCtrl controller = new PMC_CPQ_OrderApprovalEmailCtrl();

        Date testDate = Date.newInstance(2023, 1, 15);
        String formattedDate = controller.formatDate(testDate);

        String formattedCurrency1 = controller.formatCurrency(123.4567);
        String formattedCurrency2 = controller.formatCurrency(null);
        Test.stopTest();

        System.assertEquals('01/15/2023', formattedDate, 'Date should be formatted correctly');
        System.assertEquals('123.46', formattedCurrency1, 'Currency should be formatted with 2 decimals');
    }

    @IsTest
    static void testEmptyOrderId() {
        Test.startTest();
        PMC_CPQ_OrderApprovalEmailCtrl controller = new PMC_CPQ_OrderApprovalEmailCtrl();
        PMC_CPQ_OrderApprovalEmailCtrl.OrderWrapper orderWrapper = controller.getOrderRecord();
        List<PMC_CPQ_OrderApprovalEmailCtrl.OrderItemWrapper> orderItemWrappers = controller.getOrderItemWrappers();
        Test.stopTest();

        System.assertEquals(null, orderWrapper, 'OrderWrapper should be null when no orderId is set');
        System.assertEquals(null, orderItemWrappers, 'OrderItemWrappers should be null when no orderId is set');
    }
}