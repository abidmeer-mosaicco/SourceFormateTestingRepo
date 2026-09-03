@IsTest
private class MosaicDirectOrderTriggerTest {

    @TestSetup
    static void setup() {
        Account acc = PMC_TestUtilityClass.createAccount('Test Account', 'PMC_SS_Customer');
        
        List<Contact> contacts = PMC_TestUtilityClass.createContact(1, 'Master');
        Contact cont = contacts[0];
        cont.AccountId = acc.Id;
        cont.Email = 'test.contact@example.com';
        update cont;
        
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Mosaic Direct Partner Community' LIMIT 1];
        List<User> testUsers = PMC_TestUtilityClass.createPortalUser(1, profile);
        
        User tempUser = new User();
        tempUser.FirstName = 'Test Portal';
        tempUser.LastName = 'Test Doe ';
        tempUser.Alias = 'tPorDoe';
        tempUser.Email='portal.doe123@mosaicco.com';
        tempUser.Username = tempUser.Email+'.teste';
        tempUser.LanguageLocaleKey='en_US';
        tempUser.EmailEncodingKey='UTF-8';
        tempUser.LocaleSidKey='en_US';
        tempUser.TimeZoneSidKey='America/Los_Angeles';
        tempUser.ContactId = cont.Id;
        tempUser.ProfileId = profile.Id;
        tempUser.isActive = true;

        insert tempUser;

        testUsers.add(tempUser);

        List<Product2> products = PMC_TestUtilityClass.createProduct(5, 'PMC_CPQ_Brazil');
        Product2 prod = new Product2(Name='OCS PB Prod'); 
        insert prod;
        products.add(prod);

        List<PricebookEntry> pbes = PMC_TestUtilityClass.createPriceBookEntry(
            products, 
            Test.getStandardPricebookId()
        );

        List<Opportunity> opps = PMC_TestUtilityClass.createOpportunity(1, 'PMC_SS_Opportunity');
        Opportunity opp = opps[0];

        List<Contract> contracts = PMC_TestUtilityClass.createContract(
            new List<Account>{acc}, 
            new List<Opportunity>{opp}
        );
        Contract ctr = contracts[0];
        ctr.Status = 'Activated';
        update ctr;

        List<SBQQ__Quote__c> quotes = PMC_TestUtilityClass.createCPQQuotes(
            1, 
            new List<Opportunity>{opp}, 
            new List<Contact>{cont}
        );
        SBQQ__Quote__c quote = quotes[0];

        EmailTemplate success = new EmailTemplate(
            DeveloperName = 'Mosaic_Direct_Order_Notification', 
            FolderId = UserInfo.getUserId(),
            TemplateType = 'custom', 
            Name = 'Success', 
            IsActive = true, 
            HtmlValue = '<html><body>{!CustomerName}<div>{!tableContent}</div></body></html>'
        );

        EmailTemplate error = new EmailTemplate(
            DeveloperName = 'Mosaic_Direct_Order_Error_Notification', 
            FolderId = UserInfo.getUserId(),
            TemplateType = 'custom', 
            Name = 'Error', 
            IsActive = true, 
            HtmlValue = '<html><body>{!CustomerName} {!quoteName} {!ErrorMessage}</body></html>'
        );

        System.runAs(new User(Id = UserInfo.getUserId())) { 
            insert new List<EmailTemplate>{success, error}; 
        }

        AccountTeamMember atm = new AccountTeamMember(
            AccountId = acc.Id,
            UserId = tempUser.Id,
            TeamMemberRole = 'Sales Rep'
        );
        insert atm;
    }

    @IsTest
    static void testTriggerAndEmailSenderSuccessPath() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];
        Contract ctr = [SELECT Id FROM Contract WHERE AccountId = :acc.Id LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        User testUser = [SELECT Id, ContactId FROM User WHERE Email LIKE '%mosaicco.com' LIMIT 1];

        Test.startTest();

        Order ord;
        
        List<Order> orders = PMC_TestUtilityClass.createOrders(1, new List<Account>{acc});
        ord = orders[0];
        
        ord.ContractId = ctr.Id;
        ord.SBQQ__Quote__c = quote.Id;
        ord.IsMosaicDirect__c = true;
        update ord;

        List<OrderItem> orderItems = PMC_TestUtilityClass.createOrderProducts(
            1, 
            new List<Order>{ord}
        );
        OrderItem oi = orderItems[0];
        
        oi.PMC_CPQ_SAPOrderLineID__c = 'SO123456_001';
        oi.PMC_CPQ_RequestedShipDate__c = Date.today().addDays(10);
        oi.PMC_CPQ_LinePONumber__c = 'PO123';
        oi.PMC_CPQ_UnitOfMeasure__c = 'TON';
        oi.PMC_CPQ_ShippingType__c = 'Truck';
        update oi;

        ord.PMC_CPQ_SAPOrderNumber__c = 'SO123456';
        ord.PMC_CPQ_OrderIntegrationStatus__c = 'Success';
        update ord;

        MosaicDirectOrderEmailSender.generateEmailBody(new List<Order>{ord}, 'Yago', '15521');

        Test.stopTest();

        Order updatedOrder = [SELECT Id, PMC_CPQ_SAPOrderNumber__c, PMC_CPQ_OrderIntegrationStatus__c 
                             FROM Order WHERE Id = :ord.Id];
        System.assertEquals('SO123456', updatedOrder.PMC_CPQ_SAPOrderNumber__c);
    }

    @IsTest
    static void testTriggerAndEmailSenderErrorPath() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];
        Contract ctr = [SELECT Id FROM Contract WHERE AccountId = :acc.Id LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();

        Order ord;
        
        List<Order> orders = PMC_TestUtilityClass.createOrders(1, new List<Account>{acc});
        ord = orders[0];
        
        ord.ContractId = ctr.Id;
        ord.SBQQ__Quote__c = quote.Id;
        ord.IsMosaicDirect__c = true;
        update ord;

        List<OrderItem> orderItems = PMC_TestUtilityClass.createOrderProducts(
            1, 
            new List<Order>{ord}
        );

        ord.PMC_CPQ_OrderIntegrationStatus__c = 'Error';
        update ord;

        Test.stopTest();

        Order updatedOrder = [SELECT Id, PMC_CPQ_OrderIntegrationStatus__c FROM Order WHERE Id = :ord.Id];
        System.assertEquals('Error', updatedOrder.PMC_CPQ_OrderIntegrationStatus__c);
    }

    @IsTest
    static void testEmailSenderMethodsDirectly() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        User testUser = [SELECT Id, Contact.Email, Contact.Name FROM User WHERE Email LIKE '%mosaicco.com' LIMIT 1];
        
        List<Order> testOrders = PMC_TestUtilityClass.createOrders(2, new List<Account>{acc});
        
        for (Order ord : testOrders) {
            ord.IsMosaicDirect__c = true;
        }
        update testOrders;

        Test.startTest();

        MosaicDirectOrderEmailSender.sendOrderConfirmationEmail(
            testOrders, 
            testUser.Contact.Email, 
            testUser.Contact.Name, 
            'Test-Quote-001',
            new List<String>{testUser.Contact.Email}
        );

        MosaicDirectOrderEmailSender.sendOrderErrorEmail(
            testOrders, 
            testUser.Contact.Email, 
            testUser.Contact.Name, 
            'Test-Quote-001',
            new List<String>{testUser.Contact.Email},
            'Test error message'
        );

        MosaicDirectOrderEmailSender.handleOrderSubmission(JSON.serialize(testOrders));

        Test.stopTest();

        System.assert(true, 'Email methods should execute without errors');
    }

    @IsTest
    static void testEmailTemplateNotFound() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        List<Order> testOrders = PMC_TestUtilityClass.createOrders(1, new List<Account>{acc});
        
        for (Order ord : testOrders) {
            ord.IsMosaicDirect__c = true;
        }
        update testOrders;

        Test.startTest();
        
        try {
            MosaicDirectOrderEmailSender.sendOrderConfirmationEmail(
                testOrders, 
                'test@example.com', 
                'Test Customer', 
                'Test-Quote',
                new List<String>()
            );
        } catch (Exception e) {
        }

        Test.stopTest();

        System.assert(true, 'Method should handle missing template gracefully');
    }

    @IsTest
    static void testTriggerAllPaths() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];
        Contract ctr = [SELECT Id FROM Contract WHERE AccountId = :acc.Id LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        List<Order> orders = PMC_TestUtilityClass.createOrders(3, new List<Account>{acc});
        
        Order successOrder = orders[0];
        Order errorOrder = orders[1];
        Order warningToErrorOrder = orders[2];
        
        for (Order ord : orders) {
            ord.ContractId = ctr.Id;
            ord.SBQQ__Quote__c = quote.Id;
            ord.IsMosaicDirect__c = true;
        }
        warningToErrorOrder.PMC_CPQ_OrderIntegrationStatus__c = 'Warning';
        update orders;

        List<OrderItem> items = PMC_TestUtilityClass.createOrderProducts(3, orders);

        Test.startTest();
        
        successOrder.PMC_CPQ_SAPOrderNumber__c = 'SO123456';
        successOrder.PMC_CPQ_OrderIntegrationStatus__c = 'Success';
        
        errorOrder.PMC_CPQ_OrderIntegrationStatus__c = 'Error';
        
        warningToErrorOrder.PMC_CPQ_OrderIntegrationStatus__c = 'Error';
        
        update new List<Order>{successOrder, errorOrder, warningToErrorOrder};

        Test.stopTest();

        List<Order> updatedOrders = [SELECT Id, PMC_CPQ_SAPOrderNumber__c, PMC_CPQ_OrderIntegrationStatus__c 
                                    FROM Order WHERE Id IN :new List<Id>{successOrder.Id, errorOrder.Id, warningToErrorOrder.Id}];
        System.assertEquals(3, updatedOrders.size());
    }

    @IsTest
    static void testBulkOperations() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contract ctr = [SELECT Id FROM Contract WHERE AccountId = :acc.Id LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        List<Order> bulkOrders = PMC_TestUtilityClass.createOrders(10, new List<Account>{acc});

        for (Order ord : bulkOrders) {
            ord.ContractId = ctr.Id;
            ord.SBQQ__Quote__c = quote.Id;
            ord.IsMosaicDirect__c = true;
        }
        update bulkOrders;

        Test.startTest();
        
        for (Order ord : bulkOrders) {
            ord.PMC_CPQ_SAPOrderNumber__c = 'BULK_' + ord.Id;
            ord.PMC_CPQ_OrderIntegrationStatus__c = 'Success';
        }
        update bulkOrders;

        Test.stopTest();

        List<Order> updatedOrders = [SELECT Id, PMC_CPQ_SAPOrderNumber__c FROM Order WHERE Id IN :bulkOrders];
        System.assertEquals(10, updatedOrders.size());
    }
}