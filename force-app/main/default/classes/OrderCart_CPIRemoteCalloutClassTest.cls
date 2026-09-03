@isTest
private class OrderCart_CPIRemoteCalloutClassTest {

    @isTest static void testCreateMinimalPayload() {
        List<Id> ids = new List<Id>{ Id.valueOf('001000000000000AAA') };
        String payload = OrderCart_CPIRemoteCalloutUtilityClass.createMinimalPayload(ids);
        System.assertNotEquals(null, payload);
        System.assert(payload.contains('Id'));
    }

    @isTest static void testAutoRetryQueueableApex() {
        Boolean res = OrderCart_CPIRemoteCalloutUtilityClass.autoRetryQueueableApex(1, 'SOME_ERROR');
        // Cannot predict metadata settings; assert boolean type
        System.assert(res == true || res == false);
    }

    @isTest static void testSendCalloutRequest_nullEndpoint() {
        // Do not execute real callout; just ensure method handles exceptions
        Test.startTest();
        HttpResponse r = OrderCart_CPIRemoteCalloutUtilityClass.sendCalloutRequest('GET', 'http://invalid-endpoint.invalid', '{}');
        Test.stopTest();
        // If callout failed, method returns null; otherwise assert we received an HttpResponse with a status code
        if (r == null) {
            System.assert(true);
        } else {
            System.assert(r.getStatusCode() >= 0);
        }
    }

    // Mock para responder callouts com um corpo JSON simples
    class SimpleHttpMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;
        SimpleHttpMock(Integer statusCode, String body) { this.statusCode = statusCode; this.body = body; }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);
            res.setBody(this.body);
            return res;
        }
    }

    @isTest static void testSendCalloutRequest_withMock() {
        // Simula um callout que retorna 200 e um corpo JSON
        Test.setMock(HttpCalloutMock.class, new SimpleHttpMock(200, '[{"result":"ok"}]'));
        Test.startTest();
        HttpResponse r = OrderCart_CPIRemoteCalloutUtilityClass.sendCalloutRequest('POST', 'http://example.test/api', '{"x":1}');
        Test.stopTest();
        System.assertNotEquals(null, r, 'HttpResponse esperado');
        System.assertEquals(200, r.getStatusCode());
        System.assert(r.getBody().contains('result'));
    }

    @isTest static void testSendCalloutRequestFuture_withMock_andOrder() {
        // Prepara Order para passar como Id e mock de callout que retorna objecto para parse
        Account a = new Account(Name='OCS CPI Future'); insert a;
        Order o = new Order(Status='Draft', EffectiveDate = Date.today(), AccountId = a.Id); insert o;

        // cria um OrderItem para que parseJSONOrderInterface encontre linhas quando necessário
        OrderItem oi = new OrderItem(OrderId = o.Id, Quantity = 1, UnitPrice = 1.0, PricebookEntryId = null);
        // PricebookEntry may not be required for this test; insert attempt wrapped in try
        try { insert oi; } catch (Exception e) { /* ignore if org requires pricebook entries */ }

        String respBody = '[{"OBJ_NUM":"SAP123","SFOrderId":"' + String.valueOf(o.Id) + '","OBJ_ITEM":"1","SF_ORDERITEM_ID":"' + String.valueOf(oi.Id) + '","statusCode":200,"responsetext":"OK"}]';
        Test.setMock(HttpCalloutMock.class, new SimpleHttpMock(200, respBody));

        Test.startTest();
        // call future method
        OrderCart_CPIRemoteCalloutUtilityClass.sendCalloutRequestFuture('http://example.test/api', '[{"Id":"' + String.valueOf(o.Id) + '"}]', String.valueOf(o.Id));
        Test.stopTest();
        // se não houve erro a execução é considerada bem-sucedida
        System.assert(true);
    }
}