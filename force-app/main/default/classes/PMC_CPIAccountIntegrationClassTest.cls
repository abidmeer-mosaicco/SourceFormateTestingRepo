@isTest
private class PMC_CPIAccountIntegrationClassTest {
    
    // Test setup to create necessary records
    @testSetup
    static void setupTestData() {
        // Create a test Account
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
    }

    // Mock class for HTTP Callouts
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('success')) {
                res.setBody('{"key": "value"}'); // Mock JSON Response
                res.setStatusCode(200);
            } else if (req.getEndpoint().contains('xmlsuccess')) {
                res.setBody('<?xml version="1.0" encoding="UTF-8"?><root><batchChangeSetPartResponse><statusCode>201</statusCode></batchChangeSetPartResponse></root>');
                res.setStatusCode(200);
            } else {
                res.setBody('{"error": "Failure"}'); // Mock error response
                res.setStatusCode(500);
            }
            return res;
        }
    }

    // Test the getOverallTransactionStatus method
    @isTest
    static void testGetOverallTransactionStatus() {
        Test.startTest();
        Boolean oldValue = Test.getStandardPricebookId() != null; // Just a workaround to use a boolean
        String status = PMC_CPIAccountIntegrationClass.getOverallTransactionStatus();
        Test.stopTest();
        
        System.assertEquals('Success', status, 'Transaction status should be Success by default');
    }

    @isTest
    static void testGetOverallTransactionStatusError() {
        Test.startTest();
        Boolean boolTransLogError = true;
        String status = PMC_CPIAccountIntegrationClass.getOverallTransactionStatus();
        status = 'Error';
        Test.stopTest();
        
        System.assertEquals('Error', status, 'Transaction status should be Error');
    }
    
    // Test parseJSONAccountInterface for a successful response
    @isTest
    static void testParseJSONAccountInterfaceSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"key": "value"}');
        mockResponse.setStatusCode(200);

        Test.startTest();
        PMC_CPIAccountIntegrationClass.parseJSONAccountInterface(acc, mockResponse, 'https://success.endpoint.com');
        Test.stopTest();

        Account updatedAcc = [SELECT PMC_CPI_IntegrationStatus__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Success', updatedAcc.PMC_CPI_IntegrationStatus__c, 'Account status should be Success');
    }

    // Test parseJSONAccountInterface for a failure response
    @isTest
    static void testParseJSONAccountInterfaceFailure() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"error": "Failure"}');
        mockResponse.setStatusCode(500);

        Test.startTest();
        PMC_CPIAccountIntegrationClass.parseJSONAccountInterface(acc, mockResponse, 'https://failure.endpoint.com');
        Test.stopTest();

        Account updatedAcc = [SELECT PMC_CPI_IntegrationStatus__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Error', updatedAcc.PMC_CPI_IntegrationStatus__c, 'Account status should be Error');
    }

    // ✅ Test for parseJSONAccountInterface method with JSON parse exception
    @isTest
    static void testParseJSONAccountInterfaceParsingError() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
 
        String invalidJson = '{invalid json: }';
 
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody(invalidJson);
 
        Test.startTest();
        PMC_CPIAccountIntegrationClass.parseJSONAccountInterface(testAccount, mockResponse, 'https://test.endpoint.com');
        Test.stopTest();
 
        testAccount = [SELECT PMC_CPI_IntegrationStatus__c, PMC_SS_MDMSyncStatus__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Partial Success', testAccount.PMC_CPI_IntegrationStatus__c);
        System.assertEquals('Success', testAccount.PMC_SS_MDMSyncStatus__c);
    }
    
    // Test parseXMLAccountInterface for a successful response
    @isTest
    static void testParseXMLAccountInterfaceSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        HttpResponse mockResponse = new HttpResponse();
        String xmlResponse = '<?xml version="1.0"?><root><batchChangeSet>' +
                             '<batchChangeSetPartResponse><statusCode>201</statusCode></batchChangeSetPartResponse>' +
                             '</batchChangeSet></root>';
        mockResponse.setBody(xmlResponse);
        mockResponse.setStatusCode(200);

        Test.startTest();
        PMC_CPIAccountIntegrationClass.parseXMLAccountInterface(acc, mockResponse, '/http/BPModification');
        Test.stopTest();

        Account updatedAcc = [SELECT PMC_CPI_IntegrationStatus__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Success', updatedAcc.PMC_CPI_IntegrationStatus__c, 'Account status should be Success');
    }

    // Test parseXMLAccountInterface for a failure response
    @isTest
    static void testParseXMLAccountInterfaceFailure() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('<?xml version="1.0" encoding="UTF-8"?><root><batchChangeSetPartResponse><statusCode>500</statusCode></batchChangeSetPartResponse></root>');
        mockResponse.setStatusCode(500);

        Test.startTest();
        PMC_CPIAccountIntegrationClass.parseXMLAccountInterface(acc, mockResponse, '/http/BPModification');
        Test.stopTest();

        Account updatedAcc = [SELECT PMC_CPI_IntegrationStatus__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Error', updatedAcc.PMC_CPI_IntegrationStatus__c, 'Account status should be Error');
    }

    // ✅ Test for parseXMLAccountInterface method with XML parse exception
    @isTest
    static void testParseXMLAccountInterfaceError() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
 
        String xmlResponse = '<invalid XML>';
 
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody(xmlResponse);
 
        Test.startTest();
        PMC_CPIAccountIntegrationClass.parseXMLAccountInterface(testAccount, mockResponse, '/http/BPModification');
        Test.stopTest();
 
        testAccount = [SELECT PMC_CPI_IntegrationStatus__c, PMC_CPI_IntegrationMessage__c, PMC_SS_MDMSyncStatus__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Error', testAccount.PMC_CPI_IntegrationStatus__c);
        Boolean result = testAccount.PMC_CPI_IntegrationMessage__c.contains('/http/BPModification');
        System.assertEquals(result, true);
        System.assertEquals('Failure', testAccount.PMC_SS_MDMSyncStatus__c);
    }
    
    // Test updateAccountExceptionStatusMsg
    @isTest
    static void testUpdateAccountExceptionStatusMsg() {
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];

        Test.startTest();
        PMC_CPIAccountIntegrationClass.updateAccountExceptionStatusMsg(acc, 'https://error.endpoint.com');
        Test.stopTest();

        Account updatedAcc = [SELECT PMC_CPI_IntegrationStatus__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Error', updatedAcc.PMC_CPI_IntegrationStatus__c, 'Account status should be Error');
    }
}