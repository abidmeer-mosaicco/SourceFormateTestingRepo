@isTest
private class PMC_CPIAccountIntegrationClass_Test {
 
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Account',
            PMC_CPI_IntegrationStatus__c = 'Pending',
            PMC_CPI_IntegrationMessage__c = '',
            PMC_SS_MDMSyncStatus__c = 'Pending'
        );
        insert testAccount;
    }
 
    // ✅ Test for getOverallTransactionStatus method
    @isTest
    static void testGetOverallTransactionStatus() {
        Test.startTest();
        String result = PMC_CPIAccountIntegrationClass.getOverallTransactionStatus();
        System.assertEquals('Success', result, 'Expected Success when no errors');
        Test.stopTest();
    }
 
    // ✅ Test for parseJSONAccountInterface method with successful response
    @isTest
    static void testParseJSONAccountInterfaceSuccess() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
 
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"SAPRefId":"12345"}');
 
        Test.startTest();
        PMC_CPIAccountIntegrationClass.parseJSONAccountInterface(testAccount, mockResponse, 'https://test.endpoint.com');
        Test.stopTest();
 
        testAccount = [SELECT PMC_CPI_IntegrationStatus__c, PMC_SS_MDMSyncStatus__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Success', testAccount.PMC_CPI_IntegrationStatus__c);
        System.assertEquals('Success', testAccount.PMC_SS_MDMSyncStatus__c);
    }
 
    // ✅ Test for parseJSONAccountInterface method with failed response
    @isTest
    static void testParseJSONAccountInterfaceFailure() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
 
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(500);
        mockResponse.setBody('Internal Server Error');
 
        Test.startTest();
        PMC_CPIAccountIntegrationClass.parseJSONAccountInterface(testAccount, mockResponse, 'https://test.endpoint.com');
        Test.stopTest();
 
        testAccount = [SELECT PMC_CPI_IntegrationStatus__c, PMC_SS_MDMSyncStatus__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Error', testAccount.PMC_CPI_IntegrationStatus__c);
        System.assertEquals('Failure', testAccount.PMC_SS_MDMSyncStatus__c);
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
        System.assertEquals('Error', testAccount.PMC_CPI_IntegrationStatus__c);
        System.assertEquals('Failure', testAccount.PMC_SS_MDMSyncStatus__c);
    }
 
    // ✅ Test for parseXMLAccountInterface method with successful response
    @isTest
    static void testParseXMLAccountInterfaceSuccess() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
 
        String xmlResponse = '<?xml version="1.0"?><root><batchChangeSet>' +
                             '<batchChangeSetPartResponse><statusCode>201</statusCode></batchChangeSetPartResponse>' +
                             '</batchChangeSet></root>';
 
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(201);
        mockResponse.setBody(xmlResponse);
 
        Test.startTest();
        PMC_CPIAccountIntegrationClass.parseXMLAccountInterface(testAccount, mockResponse, 'https://test.endpoint.com');
        Test.stopTest();
 
        testAccount = [SELECT PMC_CPI_IntegrationStatus__c, PMC_SS_MDMSyncStatus__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Success', testAccount.PMC_CPI_IntegrationStatus__c);
        System.assertEquals('Success', testAccount.PMC_SS_MDMSyncStatus__c);
    }
 
    // ✅ Test for parseXMLAccountInterface method with failed response
    @isTest
    static void testParseXMLAccountInterfaceFailure() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
 
        String xmlResponse = '<?xml version="1.0"?><root><batchChangeSet>' +
                             '<batchChangeSetPartResponse><statusCode>400</statusCode></batchChangeSetPartResponse>' +
                             '</batchChangeSet></root>';
 
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(400);
        mockResponse.setBody(xmlResponse);
 
        Test.startTest();
        PMC_CPIAccountIntegrationClass.parseXMLAccountInterface(testAccount, mockResponse, 'https://test.endpoint.com');
        Test.stopTest();
 
        testAccount = [SELECT PMC_CPI_IntegrationStatus__c, PMC_SS_MDMSyncStatus__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Error', testAccount.PMC_CPI_IntegrationStatus__c);
        System.assertEquals('Failure', testAccount.PMC_SS_MDMSyncStatus__c);
    }
 
    // ✅ Test for updateAccountExceptionStatusMsg
    @isTest
    static void testUpdateAccountExceptionStatusMsg() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
 
        Test.startTest();
        PMC_CPIAccountIntegrationClass.updateAccountExceptionStatusMsg(testAccount, 'https://test.endpoint.com');
        Test.stopTest();
 
        testAccount = [SELECT PMC_CPI_IntegrationStatus__c, PMC_SS_MDMSyncStatus__c, PMC_CPI_IntegrationMessage__c FROM Account WHERE Id = :testAccount.Id];
 
        System.assertEquals('Error', testAccount.PMC_CPI_IntegrationStatus__c);
        System.assertEquals('Failure', testAccount.PMC_SS_MDMSyncStatus__c);
//        System.assertContains(testAccount.PMC_CPI_IntegrationMessage__c, 'https://test.endpoint.com');
//		System.assert(result.contains('testAccount.PMC_CPI_IntegrationMessage__c'), 'https://test.endpoint.com');

 
    }
}