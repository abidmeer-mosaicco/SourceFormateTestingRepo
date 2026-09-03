@IsTest
private class QuoteUpdateContractsServiceTest {
    // ---------- Mock Classes ----------
    // Success mock (HTTP 200)
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Validate request composition
            System.assertEquals('POST', req.getMethod(), 'Method must be POST');
            System.assertEquals('application/json;charset=UTF-8', req.getHeader('Content-Type'), 'Content-Type mismatch');
            System.assertNotEquals(null, req.getBody(), 'Body should not be null');
            System.assert(req.getEndpoint().startsWith('callout:PMC_CPQ_NamedCredential'), 'Endpoint must start with Named Credential prefix');

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setBody('{"result":"ok","msg":"contracts updated"}');
            return res;
        }
    }

    // Failure mock (non-200)
    private class FailureMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setStatus('Server Error');
            res.setBody('{"error":"downstream failure"}');
            return res;
        }
    }

    // Exception mock (simulate transport error / timeout)
    private class ExceptionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Socket timeout');
        }
    }

    // ---------- Helper ----------
    private static String sampleJsonBody() {
        Map<String, Object> payload = new Map<String, Object>{
            'batchId' => 'UT-' + String.valueOf(DateTime.now().getTime()),
            'contracts' => new List<Object>{
                new Map<String, Object>{ 'ContractNumber' => 'C-0001', 'Status' => 'Activated' },
                new Map<String, Object>{ 'ContractNumber' => 'C-0002', 'Status' => 'Activated' }
            }
        };
        return JSON.serialize(payload);
    }

    // ---------- Tests ----------
    @IsTest
    static void testSendContractsSuccess() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        QuoteUpdateContractsService.CPIResponse resp = QuoteUpdateContractsService.sendContracts(sampleJsonBody());
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Response should not be null');
        System.assertEquals(true, resp.isSuccess, 'Expected success=true on 200');
        System.assert(resp.message.contains('"result":"ok"'), 'Should carry the success payload body');
    }

    @IsTest
    static void testSendContractsFailureStatus() {
        Test.setMock(HttpCalloutMock.class, new FailureMock());

        Test.startTest();
        QuoteUpdateContractsService.CPIResponse resp = QuoteUpdateContractsService.sendContracts(sampleJsonBody());
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Response should not be null');
        System.assertEquals(false, resp.isSuccess, 'Expected success=false on non-200');
        System.assert(resp.message.contains('status code'), 'Message should mention status code for diagnostics');
    }

    @IsTest
    static void testSendContractsExceptionPath() {
        Test.setMock(HttpCalloutMock.class, new ExceptionMock());

        Test.startTest();
        QuoteUpdateContractsService.CPIResponse resp = QuoteUpdateContractsService.sendContracts(sampleJsonBody());
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Response should not be null');
        System.assertEquals(false, resp.isSuccess, 'Expected success=false when exception occurs');
        System.assert(resp.message.startsWith('Error during CPI callout'), 'Message should include the standard error prefix');
    }
}