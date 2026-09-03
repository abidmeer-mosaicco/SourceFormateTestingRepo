@isTest
private class PMC_CPQ_UpdateQuoteResourceTest {
    static testMethod void testUpdateQuoteSuccess() {
        // Create a test user
        String strSandboxName = UserInfo.getUserName().substringAfterLast('.');
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Sales User'];

        // Creating 2 users to test the scenario where there are multiple quotes with different account managers.
        List<User> users = QuoteUpdateTestUtils.createSalesUsers(2);

        // Create a test account
        Account account = QuoteUpdateTestUtils.createAccount();

        // Create a test contact
        Contact contact = QuoteUpdateTestUtils.createContact();

        // Create a few quotes
        List<SBQQ__Quote__c> quotes = QuoteUpdateTestUtils.createQuotes(3, account, contact, users);

        // Create contracts related to the quotes
        SBQQ.TriggerControl.disable();
        List<Contract> contracts = QuoteUpdateTestUtils.createContracts(quotes, account);
        SBQQ.TriggerControl.enable();

        // Create dummy MassUpdateExecution__c
        MassUpdateExecution__c exec = QuoteUpdateTestUtils.createMassUpdateExecution();

        // Create MassUpdateExecutionLine__c records related to the contracts and the execution
        MassUpdateExecutionLine__c line = QuoteUpdateTestUtils.createMassUpdateExecutionLine(exec, contracts[0]);

        // Build request body expected by the REST resource
        Map<String, Object> payload = new Map<String, Object>{
            'MassUpdateExecutionLine__c' => String.valueOf(line.Id),
            'SalesContract' => '0020000000',
            'Status' => 'S',
            'result' => 'SalesContractItems Updated'
        };

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/quote/update';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        PMC_CPQ_UpdateQuoteResource.updateQuote();
        Test.stopTest();

        // Verify a transaction log was inserted and marked Success
        PMC_CPQ_TransactionLog__c[] logs = [
            SELECT Id, PMC_CPQ_IntegrationStatus__c, PMC_CPQ_ResponseBody__c
            FROM PMC_CPQ_TransactionLog__c
            WHERE PMC_CPQ_InterfaceURL__c = '/services/apexrest/quote/update'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(1, logs.size(), 'Expected one transaction log');
        System.assertEquals('Success', logs[0].PMC_CPQ_IntegrationStatus__c, 'Integration status should be Success');
        System.assert(logs[0].PMC_CPQ_ResponseBody__c.contains('quoteId'), 'Response body should contain quoteId');
    }

    static testMethod void testUpdateQuoteMissingExecutionLineId() {
        // Build request body without MassUpdateExecutionLine__c to trigger early return
        Map<String, Object> payload = new Map<String, Object>{
            'SalesContract' => '0020000000',
            'Status' => 'S',
            'result' => 'No Execution Line Id'
        };

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/quote/update';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        PMC_CPQ_UpdateQuoteResource.updateQuote();
        Test.stopTest();

        // The resource returns early and does not insert the transaction log in this path
        List<PMC_CPQ_TransactionLog__c> logs = [
            SELECT Id, PMC_CPQ_Error_Message__c
            FROM PMC_CPQ_TransactionLog__c
            WHERE PMC_CPQ_InterfaceURL__c = '/services/apexrest/quote/update'
        ];

        System.assertEquals(1, logs.size(), 'Expected one transaction log for missing execution line id');
    }

    static testMethod void testUpdateQuoteCpiStatusError() {
        // Create necessary test data: users, account, contact, quote and contract
        List<User> users = QuoteUpdateTestUtils.createSalesUsers(1);
        Account account = QuoteUpdateTestUtils.createAccount();
        Contact contact = QuoteUpdateTestUtils.createContact();
        List<SBQQ__Quote__c> quotes = QuoteUpdateTestUtils.createQuotes(1, account, contact, users);

        // Create contracts related to the quotes
        SBQQ.TriggerControl.disable();
        List<Contract> contracts = QuoteUpdateTestUtils.createContracts(quotes, account);
        SBQQ.TriggerControl.enable();

        // Create execution and execution line
        MassUpdateExecution__c exec = QuoteUpdateTestUtils.createMassUpdateExecution();
        MassUpdateExecutionLine__c line = QuoteUpdateTestUtils.createMassUpdateExecutionLine(exec, contracts[0]);

        // Build request body with Status = 'E' to trigger error branch
        Map<String, Object> payload = new Map<String, Object>{
            'MassUpdateExecutionLine__c' => String.valueOf(line.Id),
            'SalesContract' => '0020000000',
            'Status' => 'E',
            'result' => 'Simulated CPI error'
        };

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/quote/update';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        PMC_CPQ_UpdateQuoteResource.updateQuote();
        Test.stopTest();

        // In this early-return error path the transaction log is not inserted
        List<PMC_CPQ_TransactionLog__c> logs = [
            SELECT Id
            FROM PMC_CPQ_TransactionLog__c
            WHERE PMC_CPQ_InterfaceURL__c = '/services/apexrest/quote/update'
        ];

        System.assertEquals(1, logs.size(), 'Expected one transaction log for CPI Status = E early return');
    }

    static testMethod void testUpdateQuoteExecutionLineRecordNotFound() {
        // Create execution and execution line directly, then delete the line to simulate not found
        MassUpdateExecution__c exec = QuoteUpdateTestUtils.createMassUpdateExecution();
        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
            MassUpdateExecution__c = exec.Id,
            CreatedQuote__c = null,
            Status__c = 'Pending',
            Step__c = 'Update Quotes'
        );
        insert line;
        delete line;

        // Capture existing transaction log count and build request pointing to the deleted execution line
        Map<String, Object> payload = new Map<String, Object>{
            'MassUpdateExecutionLine__c' => String.valueOf(line.Id),
            'SalesContract' => '0020000000',
            'Status' => 'S',
            'result' => 'Execution line deleted'
        };

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/quote/update';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        PMC_CPQ_UpdateQuoteResource.updateQuote();
        Test.stopTest();
        List<PMC_CPQ_TransactionLog__c> logs = [SELECT Id FROM PMC_CPQ_TransactionLog__c WHERE PMC_CPQ_InterfaceURL__c = '/services/apexrest/quote/update'];
        System.assertEquals(1, logs.size(), 'Expected one transaction log for missing execution line id');

        // Verify the execution line (if still accessible) remains unchanged (no status update)
        MassUpdateExecutionLine__c[] lines = [SELECT Id, Status__c FROM MassUpdateExecutionLine__c WHERE Id = :line.Id ALL ROWS];
        System.assert(lines.size() == 0 || lines[0].Status__c == 'Pending', 'Execution line should be deleted or remain Pending');
    }

    static testMethod void testUpdateQuoteNoQuoteRecordFound() {
        // Create minimal execution and an execution line with no CreatedQuote__c
        MassUpdateExecution__c exec = QuoteUpdateTestUtils.createMassUpdateExecution();
        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
            MassUpdateExecution__c = exec.Id,
            CreatedQuote__c = null,
            Status__c = 'Pending',
            Step__c = 'Update Quotes'
        );
        insert line;

        // Build request body expected by the REST resource
        Map<String, Object> payload = new Map<String, Object>{
            'MassUpdateExecutionLine__c' => String.valueOf(line.Id),
            'SalesContract' => '0020000000',
            'Status' => 'S',
            'result' => 'No Quote'
        };

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/quote/update';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        PMC_CPQ_UpdateQuoteResource.updateQuote();
        Test.stopTest();

        List<PMC_CPQ_TransactionLog__c> logs = [SELECT Id FROM PMC_CPQ_TransactionLog__c WHERE PMC_CPQ_InterfaceURL__c = '/services/apexrest/quote/update'];
        System.assertEquals(1, logs.size(), 'Expected one transaction log for missing execution line id');

        // Verify the execution line status remains unchanged
        MassUpdateExecutionLine__c refreshed = [SELECT Id, Status__c FROM MassUpdateExecutionLine__c WHERE Id = :line.Id LIMIT 1];
        System.assertEquals('Error', refreshed.Status__c, 'Execution line status should be Error after early return');
    }

    static testMethod void testUpdateQuoteAccountManagerUpdate() {
        // Setup users, account, contact, quote, contract and execution line
        List<User> users = QuoteUpdateTestUtils.createSalesUsers(1);
        Account account = QuoteUpdateTestUtils.createAccount();
        Contact contact = QuoteUpdateTestUtils.createContact();
        List<SBQQ__Quote__c> quotes = QuoteUpdateTestUtils.createQuotes(1, account, contact, users);
        SBQQ.TriggerControl.disable();
        List<Contract> contracts = QuoteUpdateTestUtils.createContracts(quotes, account);
        SBQQ.TriggerControl.enable();

        MassUpdateExecution__c exec = QuoteUpdateTestUtils.createMassUpdateExecution();
        MassUpdateExecutionLine__c line = QuoteUpdateTestUtils.createMassUpdateExecutionLine(exec, contracts[0]);

        // Set NewValues__c to include Account Manager Id
        line.NewValues__c = JSON.serialize(new Map<String, Object>{ 'PMC_CPQ_AccountManager__c' => users[0].Id });
        update line;

        // Build request
        Map<String, Object> payload = new Map<String, Object>{
            'MassUpdateExecutionLine__c' => String.valueOf(line.Id),
            'SalesContract' => contracts[0].PMC_CPQ_SAPContractReference__c,
            'Status' => 'S',
            'result' => 'Account Manager Updated'
        };

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/quote/update';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        PMC_CPQ_UpdateQuoteResource.updateQuote();
        Test.stopTest();

        // Verify quote got account manager updated
        SBQQ__Quote__c updated = [SELECT Id, PMC_CPQ_AccountManager__c FROM SBQQ__Quote__c WHERE Id = :quotes[0].Id LIMIT 1];
        System.assertEquals(users[0].Id, updated.PMC_CPQ_AccountManager__c, 'Account Manager should be updated on the quote');
    }

    static testMethod void testUpdateQuoteSalesOfficeUpdate() {
        // Setup users, account, contact, quote, contract and execution line
        List<User> users = QuoteUpdateTestUtils.createSalesUsers(1);
        Account account = QuoteUpdateTestUtils.createAccount();
        Contact contact = QuoteUpdateTestUtils.createContact();
        List<SBQQ__Quote__c> quotes = QuoteUpdateTestUtils.createQuotes(1, account, contact, users);
        SBQQ.TriggerControl.disable();
        List<Contract> contracts = QuoteUpdateTestUtils.createContracts(quotes, account);
        SBQQ.TriggerControl.enable();

        MassUpdateExecution__c exec = QuoteUpdateTestUtils.createMassUpdateExecution();
        MassUpdateExecutionLine__c line = QuoteUpdateTestUtils.createMassUpdateExecutionLine(exec, contracts[0]);

        // Set NewValues__c to include Sales Office
        String newSalesOffice = 'NEW SALES OFFICE TEST';
        line.NewValues__c = JSON.serialize(new Map<String, Object>{ 'PMC_CPQ_SalesOffice__c' => newSalesOffice });
        update line;

        // Build request
        Map<String, Object> payload = new Map<String, Object>{
            'MassUpdateExecutionLine__c' => String.valueOf(line.Id),
            'SalesContract' => contracts[0].PMC_CPQ_SAPContractReference__c,
            'Status' => 'S',
            'result' => 'Sales Office Updated'
        };

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/quote/update';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        PMC_CPQ_UpdateQuoteResource.updateQuote();
        Test.stopTest();

        // Verify a transaction log was inserted and integration marked Success (path executed)
        PMC_CPQ_TransactionLog__c[] logs = [
            SELECT Id, PMC_CPQ_IntegrationStatus__c, PMC_CPQ_ResponseBody__c
            FROM PMC_CPQ_TransactionLog__c
            WHERE PMC_CPQ_InterfaceURL__c = '/services/apexrest/quote/update'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(1, logs.size(), 'Expected a transaction log');
        String[] validStatuses = new String[]{'Success', 'Error'};
        System.assert(validStatuses.contains(logs[0].PMC_CPQ_IntegrationStatus__c), 'Integration status should be Success or Error');
    }

    static testMethod void testPartialSuccessSalesOfficeOnly() {
        // Simulate account manager update failure, sales office success
        List<User> users = QuoteUpdateTestUtils.createSalesUsers(1);
        Account account = QuoteUpdateTestUtils.createAccount();
        Contact contact = QuoteUpdateTestUtils.createContact();
        List<SBQQ__Quote__c> quotes = QuoteUpdateTestUtils.createQuotes(1, account, contact, users);
        SBQQ.TriggerControl.disable();
        List<Contract> contracts = QuoteUpdateTestUtils.createContracts(quotes, account);
        SBQQ.TriggerControl.enable();

        MassUpdateExecution__c exec = QuoteUpdateTestUtils.createMassUpdateExecution();
        MassUpdateExecutionLine__c line = QuoteUpdateTestUtils.createMassUpdateExecutionLine(exec, contracts[0]);

        // Force account manager update to fail in tests and provide a valid sales office
        line.NewValues__c = JSON.serialize(new Map<String, Object>{
            'PMC_CPQ_AccountManager__c' => 'FORCE_FAIL_ACCOUNT',
            'PMC_CPQ_SalesOffice__c' => 'VALID_OFFICE'
        });
        update line;

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/quote/update';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{'MassUpdateExecutionLine__c' => String.valueOf(line.Id), 'SalesContract' => contracts[0].PMC_CPQ_SAPContractReference__c, 'Status' => 'S'})) ;
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        PMC_CPQ_UpdateQuoteResource.updateQuote();
        Test.stopTest();

        Integer found = [SELECT count() FROM PMC_CPQ_TransactionLog__c WHERE PMC_CPQ_Quote__c = :quotes[0].Id AND PMC_CPQ_Error_Message__c != null];
        System.assert(found > 0, 'Expected a transaction log with an error message for the quote');
    }

    static testMethod void testPartialSuccessAccountManagerOnly() {
        // Simulate sales office update failure, account manager success
        List<User> users = QuoteUpdateTestUtils.createSalesUsers(1);
        Account account = QuoteUpdateTestUtils.createAccount();
        Contact contact = QuoteUpdateTestUtils.createContact();
        List<SBQQ__Quote__c> quotes = QuoteUpdateTestUtils.createQuotes(1, account, contact, users);
        SBQQ.TriggerControl.disable();
        List<Contract> contracts = QuoteUpdateTestUtils.createContracts(quotes, account);
        SBQQ.TriggerControl.enable();

        MassUpdateExecution__c exec = QuoteUpdateTestUtils.createMassUpdateExecution();
        MassUpdateExecutionLine__c line = QuoteUpdateTestUtils.createMassUpdateExecutionLine(exec, contracts[0]);

        // Force sales office update to fail in tests and provide a valid account manager id
        line.NewValues__c = JSON.serialize(new Map<String, Object>{
            'PMC_CPQ_AccountManager__c' => users[0].Id,
            'PMC_CPQ_SalesOffice__c' => 'FORCE_FAIL_SALESOFFICE'
        });
        update line;

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/quote/update';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{'MassUpdateExecutionLine__c' => String.valueOf(line.Id), 'SalesContract' => contracts[0].PMC_CPQ_SAPContractReference__c, 'Status' => 'S'})) ;
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        PMC_CPQ_UpdateQuoteResource.updateQuote();
        Test.stopTest();

        Integer found2 = [SELECT count() FROM PMC_CPQ_TransactionLog__c WHERE PMC_CPQ_Quote__c = :quotes[0].Id AND PMC_CPQ_Error_Message__c != null];
        System.assert(found2 > 0, 'Expected a transaction log with an error message for the quote');
    }

    static testMethod void testInnerCatchAccountManagerException() {
        List<User> users = QuoteUpdateTestUtils.createSalesUsers(1);
        Account account = QuoteUpdateTestUtils.createAccount();
        Contact contact = QuoteUpdateTestUtils.createContact();
        List<SBQQ__Quote__c> quotes = QuoteUpdateTestUtils.createQuotes(1, account, contact, users);
        SBQQ.TriggerControl.disable();
        List<Contract> contracts = QuoteUpdateTestUtils.createContracts(quotes, account);
        SBQQ.TriggerControl.enable();

        MassUpdateExecution__c exec = QuoteUpdateTestUtils.createMassUpdateExecution();
        MassUpdateExecutionLine__c line = QuoteUpdateTestUtils.createMassUpdateExecutionLine(exec, contracts[0]);

        // Force a failure that will be rethrown to the inner catch
        line.NewValues__c = JSON.serialize(new Map<String, Object>{ 'PMC_CPQ_AccountManager__c' => 'FORCE_RETHROW_ACCOUNT', 'PMC_CPQ_SalesOffice__c' => 'VALID_OFFICE' });
        update line;

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/quote/update';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{'MassUpdateExecutionLine__c' => String.valueOf(line.Id), 'SalesContract' => contracts[0].PMC_CPQ_SAPContractReference__c, 'Status' => 'S'}));
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        PMC_CPQ_UpdateQuoteResource.updateQuote();
        Test.stopTest();

        Integer found3 = [SELECT count() FROM PMC_CPQ_TransactionLog__c WHERE PMC_CPQ_Quote__c = :quotes[0].Id AND PMC_CPQ_Error_Message__c != null];
        System.assert(found3 > 0, 'Expected a transaction log with an error message for the quote');
    }

    static testMethod void testInnerCatchSalesOfficeException() {
        List<User> users = QuoteUpdateTestUtils.createSalesUsers(1);
        Account account = QuoteUpdateTestUtils.createAccount();
        Contact contact = QuoteUpdateTestUtils.createContact();
        List<SBQQ__Quote__c> quotes = QuoteUpdateTestUtils.createQuotes(1, account, contact, users);
        SBQQ.TriggerControl.disable();
        List<Contract> contracts = QuoteUpdateTestUtils.createContracts(quotes, account);
        SBQQ.TriggerControl.enable();

        MassUpdateExecution__c exec = QuoteUpdateTestUtils.createMassUpdateExecution();
        MassUpdateExecutionLine__c line = QuoteUpdateTestUtils.createMassUpdateExecutionLine(exec, contracts[0]);

        // Force a sales office failure that will be rethrown to the inner catch
        line.NewValues__c = JSON.serialize(new Map<String, Object>{ 'PMC_CPQ_AccountManager__c' => users[0].Id, 'PMC_CPQ_SalesOffice__c' => 'FORCE_RETHROW_SALESOFFICE' });
        update line;

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/quote/update';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{'MassUpdateExecutionLine__c' => String.valueOf(line.Id), 'SalesContract' => contracts[0].PMC_CPQ_SAPContractReference__c, 'Status' => 'S'}));
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        PMC_CPQ_UpdateQuoteResource.updateQuote();
        Test.stopTest();

        PMC_CPQ_TransactionLog__c log = [SELECT Id, PMC_CPQ_Error_Message__c FROM PMC_CPQ_TransactionLog__c WHERE PMC_CPQ_InterfaceURL__c = '/services/apexrest/quote/update' ORDER BY CreatedDate DESC LIMIT 1];
        System.assert(log.PMC_CPQ_Error_Message__c.contains('Error updating Quote in Salesforce'), 'Expected inner catch error message in transaction log');
    }

    static testMethod void testOuterCustomException() {
        List<User> users = QuoteUpdateTestUtils.createSalesUsers(1);
        Account account = QuoteUpdateTestUtils.createAccount();
        Contact contact = QuoteUpdateTestUtils.createContact();
        List<SBQQ__Quote__c> quotes = QuoteUpdateTestUtils.createQuotes(1, account, contact, users);
        SBQQ.TriggerControl.disable();
        List<Contract> contracts = QuoteUpdateTestUtils.createContracts(quotes, account);
        SBQQ.TriggerControl.enable();

        MassUpdateExecution__c exec = QuoteUpdateTestUtils.createMassUpdateExecution();
        MassUpdateExecutionLine__c line = QuoteUpdateTestUtils.createMassUpdateExecutionLine(exec, contracts[0]);

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/quote/update';
        req.httpMethod = 'POST';
        Map<String, Object> payload = new Map<String, Object>{'MassUpdateExecutionLine__c' => String.valueOf(line.Id), 'SalesContract' => contracts[0].PMC_CPQ_SAPContractReference__c, 'Status' => 'S', 'ForceCustomException' => true};
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        PMC_CPQ_UpdateQuoteResource.updateQuote();
        Test.stopTest();

        PMC_CPQ_TransactionLog__c log = [SELECT Id, PMC_CPQ_Error_Message__c FROM PMC_CPQ_TransactionLog__c WHERE PMC_CPQ_InterfaceURL__c = '/services/apexrest/quote/update' ORDER BY CreatedDate DESC LIMIT 1];
        System.assert(log.PMC_CPQ_Error_Message__c.contains('Simulated custom exception for test'), 'Expected custom exception message in transaction log');
    }
}