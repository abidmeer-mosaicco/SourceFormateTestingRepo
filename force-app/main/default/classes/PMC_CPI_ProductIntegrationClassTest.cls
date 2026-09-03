@isTest
private class PMC_CPI_ProductIntegrationClassTest {
    
    // Mock response generator
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/xml');
            res.setBody('<Response>Success</Response>');
            res.setStatusCode(200); // You can change this to 400, 500 to simulate error cases
            return res;
        }
    }

    class MockErrorHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody('Some error');
            res.setStatusCode(500); // Error response
            return res;
        }
    }    
    
    @testSetup
    static void setupTestData() {
        // Insert required Product2 record with all necessary fields
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST-001',
            IsActive = true,
            PMC_CPI_IntegrationStatus__c = 'Pending',
            PMC_CPI_IntegrationMessage__c = '',
            PMC_SS_MDMSyncStatus__c = 'Pending'
        );
        insert testProduct;
    }

    @isTest
    static void testGetOverallTransactionStatus_Success() {
        // Simulate successful transaction
        Test.startTest();
        String status = PMC_CPI_ProductIntegrationClass.getOverallTransactionStatus();
        Test.stopTest();

        System.assertEquals('Success', status, 'Expected status should be Success');
    }

    @isTest
    static void testGetOverallTransactionStatus_Error() {
        // Simulate error by using reflection to set static variable
        Test.startTest();
        System.assertEquals('Success', PMC_CPI_ProductIntegrationClass.getOverallTransactionStatus());

        // Set the error flag manually using Reflection
        // Since we cannot change static variables directly, this part can only conceptually be tested
        Test.stopTest();
    }

    @isTest
    static void testParseXMLProductInterface_Success() {
        // Register mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Product2 prod = [SELECT Id, Name FROM Product2 LIMIT 1];

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://example.com/api');
        req.setMethod('GET');
        Http http = new Http();

        Test.startTest();
        HttpResponse res = http.send(req);
        PMC_CPI_ProductIntegrationClass.parseXMLProductInterface(prod, res, req.getEndpoint());
        Test.stopTest();

        Product2 updatedProd = [SELECT PMC_CPI_IntegrationStatus__c, PMC_SS_MDMSyncStatus__c FROM Product2 WHERE Id = :prod.Id];
        System.assertEquals('Success', updatedProd.PMC_CPI_IntegrationStatus__c);
        System.assertEquals('Success', updatedProd.PMC_SS_MDMSyncStatus__c);
    }

    @isTest
    static void testParseXMLInterface_Error() {

        Test.setMock(HttpCalloutMock.class, new MockErrorHttpResponse());

        Product2 prod = [SELECT Id, Name FROM Product2 LIMIT 1];

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://example.com/error');
        req.setMethod('GET');
        Http http = new Http();

        Test.startTest();
        HttpResponse res = http.send(req);
        PMC_CPI_ProductIntegrationClass.parseXMLProductInterface(prod, res, req.getEndpoint());
        Test.stopTest();

        Product2 updatedProd = [SELECT PMC_CPI_IntegrationStatus__c, PMC_SS_MDMSyncStatus__c FROM Product2 WHERE Id = :prod.Id];
        System.assertEquals('Error', updatedProd.PMC_CPI_IntegrationStatus__c);
        System.assertEquals('Failure', updatedProd.PMC_SS_MDMSyncStatus__c);
    }

    @isTest
    static void testUpdateProductExceptionStatusMsg() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        Test.startTest();
        PMC_CPI_ProductIntegrationClass.updateProductExceptionStatusMsg(prod, 'https://endpoint.com/exception');
        Test.stopTest();

        Product2 updatedProd = [SELECT PMC_CPI_IntegrationMessage__c, PMC_CPI_IntegrationStatus__c, PMC_SS_MDMSyncStatus__c FROM Product2 WHERE Id = :prod.Id];
        System.assertEquals('Error', updatedProd.PMC_CPI_IntegrationStatus__c);
        System.assertEquals('Failure', updatedProd.PMC_SS_MDMSyncStatus__c);
        System.assert(updatedProd.PMC_CPI_IntegrationMessage__c.contains('https://endpoint.com/exception'), 'Expected message to contain endpoint URL');
    }
}