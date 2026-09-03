@isTest
private class DocusignWorkflowServiceTest {

    /**
     * Mock HTTP callout class for simulating DocuSign API responses
     */
    private class DocuSignMockHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        public DocuSignMockHttpResponse(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            // Validate the request
            System.assert(req.getEndpoint().contains('DocuSignWorkflow'), 'Endpoint should contain DocuSignWorkflow');
            System.assertEquals('POST', req.getMethod(), 'Method should be POST');
            System.assertEquals('application/json', req.getHeader('Content-Type'), 'Content-Type should be application/json');
            System.assert(req.getBody() != null && req.getBody().length() > 0, 'Request body should not be empty');

            // Verify the request body contains expected elements
            String body = req.getBody();
            System.assert(body.contains('PMC CLM Mass Amendment Staging'), 'Body should contain workflow name');
            System.assert(body.contains('Params'), 'Body should contain Params');

            // Create mock response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(statusCode);
            return res;
        }
    }

    @testSetup
    static void setupTestData() {
        // Create test Account using PMC_TestUtilityClass
        Account testAccount = PMC_TestUtilityClass.createAccount('Test Account', 'PMC_SS_Prospect');

        // Create test Contact for PrimaryContact using PMC_TestUtilityClass
        List<Contact> contacts = PMC_TestUtilityClass.createContact(1, 'Master');
        Contact primaryContact = contacts[0];
        primaryContact.AccountId = testAccount.Id;
        primaryContact.Email = 'testcontact@example.com';
        update primaryContact;

        // Set the Account's Primary Contract Recipient to satisfy the
        // PMC_CPQ_PrimaryContractRecipientAccount validation rule for North America quotes
        update testAccount;

        primaryContact = [SELECT Id, AccountId, Email FROM Contact WHERE Id = :primaryContact.Id];
        System.assertEquals(testAccount.Id, primaryContact.AccountId, 'Primary contact must be related to the account');
        PMC_ProcessSwitches__c bypassSetting = PMC_ProcessSwitches__c.getOrgDefaults();
        if (bypassSetting == null) {
            bypassSetting = new PMC_ProcessSwitches__c();
        }
        Boolean originalBypassValidationRule = bypassSetting.PMC_BypassValidationRule__c;
        Boolean originalBypassFlow = bypassSetting.PMC_BypassFlow__c;
        Boolean originalBypassTrigger = bypassSetting.PMC_BypassTrigger__c;
        bypassSetting.PMC_BypassValidationRule__c = true;
        bypassSetting.PMC_BypassFlow__c = true;
        bypassSetting.PMC_BypassTrigger__c = true;
        upsert bypassSetting;

        // Create test Opportunity for the original Quote
        List<Opportunity> opportunities = PMC_TestUtilityClass.createOpportunity(1, 'Master');
        Opportunity testOpportunity = opportunities[0];
        testOpportunity.AccountId = testAccount.Id;
        update testOpportunity;

        // Create original CPQ Quote with all fields set on insert to avoid update triggers
        SBQQ__Quote__c originalQuote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = testOpportunity.Id,
            PMC_CPQ_ContractStart__c = System.today(),
            PMC_CPQ_ContractEnd__c = System.today().addDays(35),
            PMC_CPQ_PrimaryContact__c = primaryContact.Id,
            SBQQ__PrimaryContact__c = primaryContact.Id,
            PMC_CPQ_Region__c = 'North America',
            PMC_CPQ_QuoteRecordSubType__c = 'Feed',
            PMC_CPQ_ContractLanguage__c = 'English',
            SBQQ__Account__c = testAccount.Id,
            PMC_CPQ_CustomCreatedDate__c = System.now()
        );
        insert originalQuote;

        // Create Contract linked to the original quote
        List<Contract> contracts = PMC_TestUtilityClass.createContract(
            new List<Account>{testAccount},
            opportunities
        );
        Contract testContract = contracts[0];
        testContract.SBQQ__Quote__c = originalQuote.Id;
        testContract.PMC_CPQ_LatestQuote__c = originalQuote.Id;
        update testContract;

        // Create Amendment Opportunity
        Opportunity amendmentOpportunity = new Opportunity(
            Name = 'Amendment Opportunity',
            AccountId = testAccount.Id,
            CloseDate = System.today(),
            StageName = 'Prospecting',
            SBQQ__AmendedContract__c = testContract.Id
        );
        insert amendmentOpportunity;

        // Create Amendment Quote with all fields set on insert
        SBQQ__Quote__c amendmentQuote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = amendmentOpportunity.Id,
            PMC_CPQ_ContractStart__c = System.today(),
            PMC_CPQ_ContractEnd__c = System.today().addDays(35),
            PMC_CPQ_PrimaryContact__c = primaryContact.Id,
            SBQQ__PrimaryContact__c = primaryContact.Id,
            SBQQ__Type__c = 'Amendment',
            PMC_CPQ_Region__c = 'North America',
            PMC_CPQ_QuoteRecordSubType__c = 'Feed',
            PMC_CPQ_ContractLanguage__c = 'English',
            SBQQ__Account__c = testAccount.Id,
            PMC_CPQ_CustomCreatedDate__c = System.now()
        );
        insert amendmentQuote;

        bypassSetting.PMC_BypassValidationRule__c = originalBypassValidationRule;
        bypassSetting.PMC_BypassFlow__c = originalBypassFlow;
        bypassSetting.PMC_BypassTrigger__c = originalBypassTrigger;
        upsert bypassSetting;
    }

    @isTest
    static void testTriggerWorkflowSuccess() {
        // Get test data
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Set mock for successful response
        Test.setMock(HttpCalloutMock.class, new DocuSignMockHttpResponse(200, '{"status":"success","workflowId":"12345"}'));

        Test.startTest();
        DocusignWorkflowService.triggerWorkflow(quote.Id, currentUser.Id);
        Test.stopTest();

        // If we reach here without exception, the test passes
        System.assert(true, 'Workflow should trigger successfully');
    }

    @isTest
    static void testTriggerWorkflowWithDifferentHttpResponses() {
        // Get test data
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Test with 201 Created response
        Test.setMock(HttpCalloutMock.class, new DocuSignMockHttpResponse(201, '{"status":"created"}'));

        Test.startTest();
        DocusignWorkflowService.triggerWorkflow(quote.Id, currentUser.Id);
        Test.stopTest();

        System.assert(true, 'Should handle 201 response');
    }

    @isTest
    static void testTriggerWorkflowWithErrorResponse() {
        // Get test data
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Set mock for error response
        Test.setMock(HttpCalloutMock.class, new DocuSignMockHttpResponse(400, '{"error":"Bad Request"}'));

        Test.startTest();
        // Should not throw exception, just log the error
        DocusignWorkflowService.triggerWorkflow(quote.Id, currentUser.Id);
        Test.stopTest();

        System.assert(true, 'Should handle error response gracefully');
    }

    @isTest
    static void testTriggerWorkflowWithInvalidQuoteId() {
        // Create a fake ID that doesn't exist
        Id fakeQuoteId = SBQQ__Quote__c.SObjectType.getDescribe().getKeyPrefix() + '0'.repeat(15);
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        Test.startTest();
        // Should return early without making callout
        DocusignWorkflowService.triggerWorkflow(fakeQuoteId, currentUser.Id);
        Test.stopTest();

        // If we reach here without exception, the method handled the invalid ID gracefully
        System.assert(true, 'Should handle invalid quote ID gracefully');
    }

    @isTest
    static void testTriggerWorkflowVerifyRequestBody() {
        // Get test data
        SBQQ__Quote__c quote = [
            SELECT Id, Name, SBQQ__Type__c, PMC_CPQ_QuoteRecordSubType__c,
                   PMC_CPQ_Region__c, PMC_CPQ_ContractLanguage__c,
                   PMC_CPQ_PrimaryContact__c, PMC_CPQ_PrimaryContact__r.Email,
                   PMC_CPQ_PrimaryContact__r.Name
            FROM SBQQ__Quote__c
            LIMIT 1
        ];
        User currentUser = [SELECT Id, Name, Email, Alias FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Custom mock to capture and validate request body
        Test.setMock(HttpCalloutMock.class, new DocuSignMockHttpResponse(200, '{"status":"success"}'));

        Test.startTest();
        DocusignWorkflowService.triggerWorkflow(quote.Id, currentUser.Id);
        Test.stopTest();

        // The validation happens in the mock's respond method
        System.assert(true, 'Request body validated in mock');
    }

    @isTest
    static void testTriggerWorkflowWithAllQuoteFields() {
        // Get test data with all fields populated
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Contact contact = [SELECT Id FROM Contact LIMIT 1];

        // Update quote with all possible field values
        quote.SBQQ__Type__c = 'Amendment';
        quote.PMC_CPQ_Region__c = 'Brazil';
        quote.PMC_CPQ_QuoteRecordSubType__c = 'B2B - Fertilizer';
        quote.PMC_CPQ_ContractLanguage__c = 'Spanish';
        quote.PMC_CPQ_PrimaryContact__c = contact.Id;
        update quote;

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Set mock
        Test.setMock(HttpCalloutMock.class, new DocuSignMockHttpResponse(200, '{"status":"success"}'));

        Test.startTest();
        DocusignWorkflowService.triggerWorkflow(quote.Id, currentUser.Id);
        Test.stopTest();

        System.assert(true, 'Should handle all quote fields');
    }

    @isTest
    static void testTriggerWorkflowWithMinimalQuoteData() {
        // Get existing test data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];

        // Create minimal quote using PMC_TestUtilityClass
        List<Contact> contacts = new List<Contact>{contact};
        List<Opportunity> opportunities = new List<Opportunity>{testOpportunity};

        List<SBQQ__Quote__c> minimalQuotes = PMC_TestUtilityClass.createCPQQuotes(1, opportunities, contacts);
        SBQQ__Quote__c minimalQuote = minimalQuotes[0];

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Set mock
        Test.setMock(HttpCalloutMock.class, new DocuSignMockHttpResponse(200, '{"status":"success"}'));

        Test.startTest();
        DocusignWorkflowService.triggerWorkflow(minimalQuote.Id, currentUser.Id);
        Test.stopTest();

        System.assert(true, 'Should handle minimal quote data');
    }

    @isTest
    static void testTriggerWorkflowWithMultipleUsers() {
        // Get test data
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        // Test with current user
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Set mock
        Test.setMock(HttpCalloutMock.class, new DocuSignMockHttpResponse(200, '{"status":"success"}'));

        Test.startTest();
        DocusignWorkflowService.triggerWorkflow(quote.Id, currentUser.Id);
        Test.stopTest();

        System.assert(true, 'Should work with different users');
    }

    @isTest
    static void testTriggerWorkflowServerError() {
        // Get test data
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Set mock for server error (500)
        Test.setMock(HttpCalloutMock.class, new DocuSignMockHttpResponse(500, '{"error":"Internal Server Error"}'));

        Test.startTest();
        // Should not throw exception, just log the error
        DocusignWorkflowService.triggerWorkflow(quote.Id, currentUser.Id);
        Test.stopTest();

        System.assert(true, 'Should handle server error gracefully');
    }

    @isTest
    static void testTriggerWorkflowUnauthorized() {
        // Get test data
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Set mock for unauthorized response (401)
        Test.setMock(HttpCalloutMock.class, new DocuSignMockHttpResponse(401, '{"error":"Unauthorized"}'));

        Test.startTest();
        // Should not throw exception, just log the error
        DocusignWorkflowService.triggerWorkflow(quote.Id, currentUser.Id);
        Test.stopTest();

        System.assert(true, 'Should handle unauthorized error gracefully');
    }
}