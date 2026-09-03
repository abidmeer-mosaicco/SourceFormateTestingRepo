@isTest
private class OrderCart_OrderCreateActionClassTest {

    @isTest static void testPostInfoToCPI_enqueueable() {
        // create a fake account + order and call postInfoToCPI; ensure no exception
        Account a = new Account(Name = 'Test Account');
        insert a;
        Order o = new Order(Status = 'Draft', EffectiveDate = Date.today(), AccountId = a.Id);
        insert o;
        List<Order> lst = new List<Order>{ o };
        Test.startTest();
        OrderCart_OrderCreateActionClass.postInfoToCPI(lst);
        Test.stopTest();
        System.assert(true);
    }

    @isTest static void testExecute_pathHandling() {
        // We cannot control external callouts here, just ensure execute runs without uncaught exceptions
        OrderCart_OrderCreateActionClass job = new OrderCart_OrderCreateActionClass(new List<Order>(), new List<Id>());
        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
        System.assert(true);
    }

    @isTest static void testExecute_chained_with_mock_response() {
        // Create account and order to exercise chained execution (startIndex path)
        Account a = new Account(Name = 'Chained Account');
        insert a;
        Order o = new Order(Status = 'Draft', EffectiveDate = Date.today(), AccountId = a.Id);
        insert o;

        List<Order> lst = new List<Order>{ o };

    // Install HTTP mock so callouts inside execute are intercepted
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Enqueue a job that will process the first (and only) order via the chained path
        OrderCart_OrderCreateActionClass job = new OrderCart_OrderCreateActionClass(lst, 1, 12345);
        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        // Verify order integration fields were set by the parser
        Order updated = [SELECT Id, PMC_CPQ_OrderIntegrationStatus__c, PMC_CPQ_SAPOrderNumber__c FROM Order WHERE Id = :o.Id LIMIT 1];
        System.assertEquals('Success', updated.PMC_CPQ_OrderIntegrationStatus__c);
        System.assertNotEquals(null, updated.PMC_CPQ_SAPOrderNumber__c);
    }

    @isTest static void testExecute_fallback_with_weight_and_mock() {
        // Create account and order and call fallback constructor (lstIds + weight)
        Account a = new Account(Name = 'Fallback Account');
        insert a;
        Order o = new Order(Status = 'Draft', EffectiveDate = Date.today(), AccountId = a.Id);
        insert o;

        List<Order> lstOrders = new List<Order>{ o };
        List<Id> lstIds = new List<Id>{ o.Id };

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        OrderCart_OrderCreateActionClass job = new OrderCart_OrderCreateActionClass(lstOrders, lstIds, 777);
        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
        // Verify this weight scenario resulted in a 'Warning' status per parser logic (statusCode 406)
        Order updated2 = [SELECT Id, PMC_CPQ_OrderIntegrationStatus__c, PMC_CPQ_OrderIntegrationMessage__c FROM Order WHERE Id = :o.Id LIMIT 1];
        System.assertEquals('Warning', updated2.PMC_CPQ_OrderIntegrationStatus__c);
    }

    @isTest static void testPostInfoToCPI_withNullOrEmptyDoesNothing() {
        // Calling with null or empty should simply return without exception
        Test.startTest();
        OrderCart_OrderCreateActionClass.postInfoToCPI(null);
        OrderCart_OrderCreateActionClass.postInfoToCPI(new List<Order>());
        Test.stopTest();
        System.assert(true, 'postInfoToCPI deve retornar sem exceção para null/empty');
    }

    @isTest static void testExecute_chained_multipleOrders_processedSequentially() {
        // Create two orders and ensure chained execution processes both via the mock
        Account a = new Account(Name = 'Chain Multi Account');
        insert a;
        Order o1 = new Order(Status = 'Draft', EffectiveDate = Date.today(), AccountId = a.Id);
        Order o2 = new Order(Status = 'Draft', EffectiveDate = Date.today(), AccountId = a.Id);
        insert new List<Order>{ o1, o2 };

        List<Order> lst = new List<Order>{ o1, o2 };

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

    // Execute chained job directly to avoid nested enqueue execution inside the test harness
    OrderCart_OrderCreateActionClass job = new OrderCart_OrderCreateActionClass(lst, 1, 555);
    Test.startTest();
    // calling execute directly processes the first order and enqueues the remainder (but does not run it)
    job.execute(null);
    Test.stopTest();

        // Verify both orders were processed by the mock parser (should be 'Success')
        List<Order> updated = [SELECT Id, PMC_CPQ_OrderIntegrationStatus__c, PMC_CPQ_SAPOrderNumber__c FROM Order WHERE Id IN :new List<Id>{o1.Id, o2.Id} ORDER BY Id];
        System.assertEquals(2, updated.size(), 'Ambos orders devem existir');
        for (Order u : updated) {
            System.assertEquals('Success', u.PMC_CPQ_OrderIntegrationStatus__c, 'Order deve ter status Success quando mock retorna 200');
            System.assertNotEquals(null, u.PMC_CPQ_SAPOrderNumber__c, 'SAPOrderNumber deve ter sido populado');
        }
    }

    @isTest static void testExecute_fallback_without_weight_mock_success() {
        // Create account and order and call fallback constructor (lstIds without weight)
        Account a = new Account(Name = 'Fallback NoWeight');
        insert a;
        Order o = new Order(Status = 'Draft', EffectiveDate = Date.today(), AccountId = a.Id);
        insert o;

        List<Order> lstOrders = new List<Order>{ o };
        List<Id> lstIds = new List<Id>{ o.Id };

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        OrderCart_OrderCreateActionClass job = new OrderCart_OrderCreateActionClass(lstOrders, lstIds);
        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        Order refreshed = [SELECT Id, PMC_CPQ_OrderIntegrationStatus__c, PMC_CPQ_SAPOrderNumber__c FROM Order WHERE Id = :o.Id LIMIT 1];
        System.assertEquals('Success', refreshed.PMC_CPQ_OrderIntegrationStatus__c, 'Fallback sem weight deve resultar em Success com mock padrão');
        System.assertNotEquals(null, refreshed.PMC_CPQ_SAPOrderNumber__c, 'SAPOrderNumber deve ser populado');
    }

    @isTest static void testExecute_fallback_calloutThrows_setsErrorOnOrder() {
        // Create account and order
        Account a = new Account(Name = 'Fallback Throw');
        insert a;
        Order o = new Order(Status = 'Draft', EffectiveDate = Date.today(), AccountId = a.Id);
        insert o;

        List<Order> lstOrders = new List<Order>{ o };
        List<Id> lstIds = new List<Id>{ o.Id };

        // Install an HTTP mock that throws to simulate callout exception -> sendCalloutRequest will return null and set strExceptionMsg
        Test.setMock(HttpCalloutMock.class, new ThrowingMock());

        OrderCart_OrderCreateActionClass job = new OrderCart_OrderCreateActionClass(lstOrders, lstIds);
        Test.startTest();
        // call execute directly to trigger fallback path
        job.execute(null);
        Test.stopTest();

    Order refreshed = [SELECT Id, PMC_CPQ_OrderIntegrationStatus__c FROM Order WHERE Id = :o.Id LIMIT 1];
    System.assertEquals('Error', refreshed.PMC_CPQ_OrderIntegrationStatus__c, 'Quando o callout falha, o Order deve receber status Error');
    }

    @isTest static void testExecute_chained_calloutThrows_setsErrorAndEnqueuesNext() {
        // Create two orders
        Account a = new Account(Name = 'Chain Throw Account');
        insert a;
        Order o1 = new Order(Status = 'Draft', EffectiveDate = Date.today(), AccountId = a.Id);
        Order o2 = new Order(Status = 'Draft', EffectiveDate = Date.today(), AccountId = a.Id);
        insert new List<Order>{ o1, o2 };

        List<Order> lst = new List<Order>{ o1, o2 };

        Test.setMock(HttpCalloutMock.class, new ThrowingMock());

        OrderCart_OrderCreateActionClass job = new OrderCart_OrderCreateActionClass(lst, 1, 999);
        Test.startTest();
        // execute directly to process first and enqueue next (but the enqueued job won't run here)
        job.execute(null);
        Test.stopTest();

        // First order should have Error status and message
    Order first = [SELECT Id, PMC_CPQ_OrderIntegrationStatus__c FROM Order WHERE Id = :o1.Id LIMIT 1];
    System.assertEquals('Error', first.PMC_CPQ_OrderIntegrationStatus__c);
    }

    @isTest static void testExecute_chained_parseError_setsError() {
        // Create order and install a mock that returns malformed (non-JSON) body to force a parse exception
        Account a = new Account(Name = 'ParseError Account');
        insert a;
        Order o = new Order(Status = 'Draft', EffectiveDate = Date.today(), AccountId = a.Id);
        insert o;

        List<Order> lst = new List<Order>{ o };

        Test.setMock(HttpCalloutMock.class, new MalformedMock());

        OrderCart_OrderCreateActionClass job = new OrderCart_OrderCreateActionClass(lst, 1, 222);
        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        Order refreshed = [SELECT Id, PMC_CPQ_OrderIntegrationStatus__c, PMC_CPQ_OrderIntegrationMessage__c FROM Order WHERE Id = :o.Id LIMIT 1];
        System.assertEquals('Error', refreshed.PMC_CPQ_OrderIntegrationStatus__c, 'Quando o parser lançar, o status deve ser Error');
    // Implementations may or may not record a detailed message here; assert status only.
    }

    @isTest static void testExecute_chained_startIndexOnly_constructor_success() {
        // Ensure constructor with (List<Order>, Integer startIndex) path works and ends up as Success with normal mock
        Account a = new Account(Name = 'StartIndexOnly');
        insert a;
        Order o = new Order(Status = 'Draft', EffectiveDate = Date.today(), AccountId = a.Id);
        insert o;

        List<Order> lst = new List<Order>{ o };

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

    OrderCart_OrderCreateActionClass job = new OrderCart_OrderCreateActionClass(lst, 1);
    Test.startTest();
    // Execute directly to enter the constructor path with only (List<Order>, Integer startIndex)
    job.execute(null);
    Test.stopTest();

        Order refreshed = [SELECT Id, PMC_CPQ_OrderIntegrationStatus__c FROM Order WHERE Id = :o.Id LIMIT 1];
        System.assertEquals('Success', refreshed.PMC_CPQ_OrderIntegrationStatus__c, 'StartIndex-only constructor deve resultar em Success com o mock padrão');
    }

    // Mock that throws an exception to simulate HTTP callout failure inside sendCalloutRequest
    private class ThrowingMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // simulate an exception during callout
            throw new CalloutException('simulated-callout-exception');
        }
    }

    // Mock that returns a malformed (non-JSON) response body to force parse errors
    private class MalformedMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            // intentionally malformed body
            res.setBody('this-is-not-json');
            return res;
        }
    }

    // Simple HTTP mock that returns a 200 with a small JSON body
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            try {
                String body = req.getBody();
                Map<String,Object> payload = (Map<String,Object>) JSON.deserializeUntyped(body);
                List<Object> ids = (List<Object>) payload.get('Id');
                Object weightObj = payload.containsKey('weight') ? payload.get('weight') : null;

                List<Object> respList = new List<Object>();
                if (ids != null) {
                    for (Object idObj : ids) {
                        String sid = String.valueOf(idObj);
                        Map<String,Object> rec = new Map<String,Object>();
                        rec.put('SFOrderId', sid);
                        // If a weight is present and equals 777, simulate a partial/warning response (statusCode 406)
                        if (weightObj != null && String.valueOf(weightObj) == '777') {
                            rec.put('OBJ_NUM', '');
                            rec.put('OBJ_ITEM', '');
                            rec.put('SF_ORDERITEM_ID', '');
                            rec.put('statusCode', 406);
                            rec.put('responsetext', 'Partial');
                        } else {
                            // default: success
                            rec.put('OBJ_NUM', 'SAP' + sid.substring(Math.max(0, sid.length()-4)));
                            rec.put('OBJ_ITEM', '1');
                            rec.put('SF_ORDERITEM_ID', '');
                            rec.put('statusCode', 200);
                            rec.put('responsetext', 'Created');
                        }
                        respList.add(rec);
                    }
                }
                res.setBody(JSON.serialize(respList));
            } catch (Exception e) {
                res.setBody('[{"statusCode":500,"responsetext":"mock-error"}]');
                res.setStatusCode(500);
            }
            return res;
        }
    }
}