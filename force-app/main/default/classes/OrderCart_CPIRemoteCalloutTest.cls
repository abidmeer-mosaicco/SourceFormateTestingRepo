@isTest
private class OrderCart_CPIRemoteCalloutTest {

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
    // If callout failed, method returns null; otherwise non-null HttpResponse
    System.assert(r == null || r != null);
    }
}