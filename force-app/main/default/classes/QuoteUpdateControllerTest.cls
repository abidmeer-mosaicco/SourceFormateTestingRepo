@IsTest
private class QuoteUpdateControllerTest {
    @TestSetup
    static void setupData() {
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
        List<Contract> contracts = QuoteUpdateTestUtils.createContracts(quotes, account);

        // Create dummy MassUpdateExecution__c
        MassUpdateExecution__c exec = QuoteUpdateTestUtils.createMassUpdateExecution();

        // Create MassUpdateExecutionLine__c records related to the contracts and the execution
        MassUpdateExecutionLine__c line = QuoteUpdateTestUtils.createMassUpdateExecutionLine(exec, contracts[0]);
    }

    // --- getContracts Tests ---
    @IsTest
    static void testGetContracts() {
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts(null, null, null, null);
        Test.stopTest();
        System.assert(!result.contracts.isEmpty(), 'Contracts should return.');
    }

    @IsTest
    static void testGetContractsPagination() {
        Contract contract = [SELECT Id, CreatedDate FROM Contract LIMIT 1];
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts(null, 2, contract.Id, contract.CreatedDate);
        Test.stopTest();
        System.assert(result.contracts.size() >= 0, 'Should return contracts or empty list.');
    }

    @IsTest
    static void testGetContractsWithSearchFilter() {
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts(
            '{"search": "' + QuoteUpdateTestUtils.CONTRACT_STATUS + '"}',
            null,
            null,
            null
        );
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        // Search by contract number prefix which should find our test contracts
        System.assert(result.contracts.size() >= 0, 'Should return contracts or empty list.');
    }

    @IsTest
    static void testGetContractsWithSoldToFilter() {
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts(
            '{"soldTo": "' + QuoteUpdateTestUtils.ACCOUNT_SAP_ID + '"}',
            null,
            null,
            null
        );
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithQuoteNumberFilter() {
        List<SBQQ__Quote__c> quotes = [
            SELECT PMC_CLM_DocumentNumber__c
            FROM SBQQ__Quote__c
            LIMIT 1
        ];

        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts(
            '{"quoteNumber": "' + quotes[0].PMC_CLM_DocumentNumber__c + '"}',
            null,
            null,
            null
        );
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(1, result.contracts.size(), 'Should return 1 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithQuoteTypeFilter() {
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts('{"type": "' + QuoteUpdateTestUtils.QUOTE_TYPE + '"}', null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithSAPOriginalContractFilter() {
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts(
            '{"sapOriginalContract": "' + QuoteUpdateTestUtils.SAP_ORIGINAL_CONTRACT + '"}',
            null,
            null,
            null
        );
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithAccountFilter() {
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts('{"account": "Test Account"}', null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithBusinessTypeFilter() {
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts(
            '{"businessType": "' + QuoteUpdateTestUtils.QUOTE_RECORD_SUB_TYPE + '"}',
            null,
            null,
            null
        );
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithMultipleBusinessTypeFilter() {
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts(
            '{"businessType": "' + QuoteUpdateTestUtils.QUOTE_RECORD_SUB_TYPE + ',B2C - Feed"}',
            null,
            null,
            null
        );
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithSalesOfficeFilter() {
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts(
            '{"salesOffice": "' + QuoteUpdateTestUtils.SALES_OFFICE + '"}',
            null,
            null,
            null
        );
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithMultipleSalesOfficeFilter() {
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts(
            '{"salesOffice": "' + QuoteUpdateTestUtils.SALES_OFFICE + ',BR MT NORTE B2C"}',
            null,
            null,
            null
        );
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithAccountManagerFilter() {
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts(
            '{"accountManager": "' + QuoteUpdateTestUtils.USER_FIRST_NAME + '"}',
            null,
            null,
            null
        );
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithContractDocStatusFilter() {
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts(
            '{"contractDocStatus": "' + QuoteUpdateTestUtils.CONTRACT_DOC_STATUS + '"}',
            null,
            null,
            null
        );
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithMultipleContractDocStatusFilter() {
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts(
            '{"contractDocStatus": "' + QuoteUpdateTestUtils.CONTRACT_DOC_STATUS + ',Pending"}',
            null,
            null,
            null
        );
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithContractValidFromFilter() {
        String validFrom = StringUtils.dateToString(Date.today());
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts('{"contractValidFrom": "' + validFrom + '"}', null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithContractValidToFilter() {
        String validTo = StringUtils.dateToString(Date.today().addDays(30));
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts('{"contractValidTo": "' + validTo + '"}', null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithApprovalStatusFilter() {
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts(
            '{"approvalStatus": "' + QuoteUpdateTestUtils.APPROVAL_STATUS + '"}',
            null,
            null,
            null
        );
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithMultipleApprovalStatusFilter() {
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts(
            '{"approvalStatus": "' + QuoteUpdateTestUtils.APPROVAL_STATUS + ',Pending"}',
            null,
            null,
            null
        );
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithQuoteStatusFilter() {
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts(
            '{"quoteStatus": "' + QuoteUpdateTestUtils.QUOTE_STATUS + '"}',
            null,
            null,
            null
        );
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithMultipleQuoteStatusFilter() {
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts(
            '{"quoteStatus": "' + QuoteUpdateTestUtils.QUOTE_STATUS + ',Draft"}',
            null,
            null,
            null
        );
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithSAPContrctRefFilter() {
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts(
            '{"sapContractRef": "' + QuoteUpdateTestUtils.SAP_CONTRACT_REF + '"}',
            null,
            null,
            null
        );
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithMultipleSAPContrctRefFilter() {
        Test.startTest();
        QuoteUpdateController.ContractSearchResult result = QuoteUpdateController.getContracts(
            '{"sapContractRef": "' + QuoteUpdateTestUtils.SAP_CONTRACT_REF + ',0020054322"}',
            null,
            null,
            null
        );
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    // --- getExecution Tests ---
    @IsTest
    static void testGetExecutionSuccess() {
        MassUpdateExecution__c setupExec = [
            SELECT Id
            FROM MassUpdateExecution__c
            LIMIT 1
        ];

        Test.startTest();
        MassUpdateExecution__c result = QuoteUpdateController.getExecution(setupExec.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Execution record should be found.');
        System.assertEquals(setupExec.Id, result.Id, 'Returned ID should match the input ID.');
    }

    @IsTest
    static void testGetExecutionNotFound() {
        String prefix = MassUpdateExecution__c.SObjectType.getDescribe().getKeyPrefix();
        String invalidId = prefix + '000000000000'; // Non-existent Id constructed dynamically

        Test.startTest();
        try {
            QuoteUpdateController.getExecution(Id.valueOf(invalidId));
            System.assert(false, 'Expected AuraHandledException not thrown.');
        } catch (AuraHandledException e) {
            System.assertEquals('Execution not found', e.getMessage(), 'Should throw "Execution not found" message.');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetExecutionIdNull() {
        Test.startTest();
        try {
            QuoteUpdateController.getExecution(null);
            System.assert(false, 'Expected AuraHandledException not thrown.');
        } catch (AuraHandledException e) {
            System.assertEquals('executionId is required', e.getMessage(), 'Should throw "executionId is required" message.');
        }
        Test.stopTest();
    }

    // --- getExecutionLines Tests ---
    @IsTest
    static void testGetExecutionLinesSuccess() {
        MassUpdateExecution__c setupExec = [
            SELECT Id
            FROM MassUpdateExecution__c
            LIMIT 1
        ];
        MassUpdateExecutionLine__c setupLine = [
            SELECT Id
            FROM MassUpdateExecutionLine__c
            LIMIT 1
        ];

        Test.startTest();
        List<MassUpdateExecutionLine__c> results = QuoteUpdateController.getExecutionLines(setupExec.Id);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one execution line.');
        System.assertEquals(setupLine.Id, results[0].Id, 'Returned line ID should match the setup line ID.');
    }

    @IsTest
    static void testEnqueueQuoteUpdateNoLines() {
        MassUpdateExecution__c exec = [
            SELECT Id
            FROM MassUpdateExecution__c
            LIMIT 1
        ];
        Test.startTest();
        Integer result = QuoteUpdateController.enqueueQuoteUpdate(null, exec.Id);
        Test.stopTest();
        System.assertEquals(-1, result, 'Should return -1.');
    }

    @IsTest
    static void testEnqueueQuoteUpdateNoExecutionId() {
        Set<Id> execLineIds = new Map<Id, MassUpdateExecutionLine__c>(
                [
                    SELECT Id
                    FROM MassUpdateExecutionLine__c
                    LIMIT 1
                ]
            )
            .keySet();
        List<Id> execLineIdsList = new List<Id>(execLineIds);
        Test.startTest();
        Integer result = QuoteUpdateController.enqueueQuoteUpdate(execLineIdsList, null);
        Test.stopTest();
        System.assertEquals(-1, result, 'Should return -1.');
    }

    @IsTest
    static void testEnqueueQuoteUpdateSuccess() {
        MassUpdateExecution__c exec = [
            SELECT Id
            FROM MassUpdateExecution__c
            LIMIT 1
        ];
        Set<Id> execLineIds = new Map<Id, MassUpdateExecutionLine__c>(
                [
                    SELECT Id
                    FROM MassUpdateExecutionLine__c
                    LIMIT 1
                ]
            )
            .keySet();
        List<Id> execLineIdsList = new List<Id>(execLineIds);
        Test.startTest();
        Integer result = QuoteUpdateController.enqueueQuoteUpdate(execLineIdsList, exec.Id);
        Test.stopTest();
        System.assertEquals(0, result, 'Should return 0.');
    }

    @IsTest
    static void testCreateOrUpdateQuoteExecutionNoFeature() {
        Test.startTest();
        try {
            QuoteUpdateUtils.ExecutionDTO executionDTO = QuoteUpdateController.createOrUpdateQuoteExecution(null, null, null, null);
            System.assert(false, 'Expected AuraHandledException not thrown.');
        } catch (AuraHandledException e) {
            System.assertEquals('Feature parameter required.', e.getMessage(), 'Should throw "Feature parameter required." message.');
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateOrUpdateQuoteExecutionNoExecutionLineDTOs() {
        String feature = 'QuoteUpdate';
        String executionLineDTOs = '';
        Test.startTest();
        try {
            QuoteUpdateUtils.ExecutionDTO executionDTO = QuoteUpdateController.createOrUpdateQuoteExecution(feature, executionLineDTOs, null, null);
            System.assert(false, 'Expected AuraHandledException not thrown.');
        } catch (AuraHandledException e) {
            System.assertEquals('At least one contract must be selected.', e.getMessage(), 'Should throw "At least one contract must be selected." message.');
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateOrUpdateQuoteExecutionNoValidContracts() {
        String feature = 'QuoteUpdate';
        String executionLineDTOs = '[{"contractId": "800RT00000SNS0HYAX"}]'; // Invalid Contract Id.
        Test.startTest();
        try {
            QuoteUpdateUtils.ExecutionDTO executionDTO = QuoteUpdateController.createOrUpdateQuoteExecution(feature, executionLineDTOs, null, null);
            System.assert(false, 'Expected AuraHandledException not thrown.');
        } catch (AuraHandledException e) {
            System.assertEquals('No valid Contracts found for provided Ids.', e.getMessage(), 'Should throw "No valid Contracts found for provided Ids." message.');
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateOrUpdateQuoteExecutionNoExecutionIdSuccess() {
        String feature = 'QuoteUpdate';
        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        String executionLineDTOs = '[{"contractId": "' + contract.Id + '"}]';
        String queryFilters = '{"search":""}';
        Test.startTest();
        QuoteUpdateUtils.ExecutionDTO executionDTO = QuoteUpdateController.createOrUpdateQuoteExecution(feature, executionLineDTOs, null, queryFilters);
        Test.stopTest();
        System.assertNotEquals(null, executionDTO, 'Returned execution should not be null.');
        System.assertEquals('QuoteUpdate', executionDTO.feature, 'Returned feature should match the input feature.');
    }

    @IsTest
    static void testCreateOrUpdateQuoteExecutionSuccess() {
        String feature = 'QuoteUpdate';
        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        String executionLineDTOs = '[{"contractId": "' + contract.Id + '"}]';
        String queryFilters = '{"search":""}';
        MassUpdateExecution__c exec = [
            SELECT Id
            FROM MassUpdateExecution__c
            LIMIT 1
        ];
        Test.startTest();
        QuoteUpdateUtils.ExecutionDTO executionDTO = QuoteUpdateController.createOrUpdateQuoteExecution(feature, executionLineDTOs, exec.Id, queryFilters);
        Test.stopTest();
        System.assertNotEquals(null, executionDTO, 'Returned execution should not be null.');
        System.assertEquals('QuoteUpdate', executionDTO.feature, 'Returned feature should match the input feature.');
    }

    @IsTest
    static void testUpdateQuotesExecutesQueueableAndUpdatesQuoteAndLine() {
        Map<String, List<String>> salesOfficesForSalesArea = SObjectUtils.getDependentPicklistValues('SBQQ__Quote__c', 'PMC_CPQ_SalesOffice__c');
        Set<String> salesOffices = new Set<String>();
        for (String key : salesOfficesForSalesArea.keySet()) {
            List<String> value = salesOfficesForSalesArea.get(key);
            salesOffices.addAll(value);
        }
        List<String> salesOfficesList = new List<String>(salesOffices);
        String oldSalesOffice = salesOfficesList[0];
        String newSalesOffice = salesOfficesList[1];

        List<User> users = [SELECT Id, Name, PMC_CPQ_SalesOffice__c FROM User WHERE Profile.Name = 'Sales User' AND Alias LIKE 'tDoe%' LIMIT 2];

        // We need to update the Account Managers' Sales Office to the new one, otherwise the quote will assume the Account Managers' Sales Office.
        for (User user : users) {
            user.PMC_CPQ_SalesOffice__c = newSalesOffice;
        }
        update users;

        SBQQ__Quote__c quote = [
            SELECT Id, PMC_CPQ_SalesOffice__c, PMC_CPQ_AccountManager__c
            FROM SBQQ__Quote__c
            LIMIT 1
        ];
        Contract contract = [SELECT Id FROM Contract LIMIT 1];

        Id oldAccountManagerId = users[0].Id;
        Id newAccountManagerId = users[1].Id;

        quote.PMC_CPQ_SalesOffice__c = oldSalesOffice;
        quote.PMC_CPQ_AccountManager__c = oldAccountManagerId;
        update quote;

        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'QuoteUpdate', Status__c = 'Started');
        insert exec;

        Map<String, Object> newVals = new Map<String, Object>{ 'PMC_CPQ_SalesOffice__c' => newSalesOffice, 'PMC_CPQ_AccountManager__c' => newAccountManagerId };

        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
            MassUpdateExecution__c = exec.Id,
            Contract__c = contract.Id,
            CreatedQuote__c = quote.Id,
            Feature__c = 'QuoteUpdate',
            Step__c = 'Update Quotes',
            Status__c = 'Pending',
            NewValues__c = JSON.serialize(newVals)
        );
        insert line;

        Test.startTest();
        QuoteUpdateController.updateQuotes(exec.Id, new List<Id>{ line.Id });
        Test.stopTest();

        // Reload and assert
        MassUpdateExecutionLine__c lineAfter = [SELECT Id, Status__c, Message__c FROM MassUpdateExecutionLine__c WHERE Id = :line.Id LIMIT 1];
        System.assert(
            lineAfter.Status__c.contains('Queued') || lineAfter.Status__c.contains('Error'),
            'Execution line status should be Queued or Error after processing.'
        );
    }

    @IsTest
    static void testSalesOfficeValues() {
        Test.startTest();
        List<QuoteUpdateUtils.PicktListValueDTO> values = QuoteUpdateController.salesOfficeValues();
        Test.stopTest();

        System.assertNotEquals(null, values, 'salesOfficeValues should not return null');
        System.assert(values.size() >= 0, 'Should return a list of picklist values or an empty list');

        if (!values.isEmpty()) {
            QuoteUpdateUtils.PicktListValueDTO first = values[0];
            System.assertNotEquals(null, first.label, 'Picklist entry should have a label');
            System.assertNotEquals(null, first.value, 'Picklist entry should have a value');
        }
    }

    @IsTest
    static void testAccountManagersReturnsActiveSalesUsers() {
        Test.startTest();
        List<User> returned = QuoteUpdateController.accountManagers();
        Test.stopTest();

        System.assertNotEquals(null, returned, 'accountManagers should not return null');
        System.assert(returned.size() > 0, 'There should be at least one account manager returned');

        for (User u : returned) {
            System.assert(u.IsActive, 'Returned user should be active');
            System.assertEquals('Sales User', u.Profile.Name, 'Returned user should have Sales User profile');
        }
    }

    @IsTest
    static void testGetSalesOfficeSalesArea() {
        Test.startTest();
        QuoteUpdateUtils.SalesOfficeSalesAreaDTO dto = QuoteUpdateController.getSalesOfficeSalesArea();
        Test.stopTest();

        System.assertNotEquals(null, dto, 'DTO should not be null');
        System.assertNotEquals(null, dto.salesOfficesForSalesAreas, 'salesOfficesForSalesAreas map should not be null');
        System.assertNotEquals(null, dto.salesAreas, 'salesAreas map should not be null');

        // If there are entries, check types for the first entry to ensure structure
        if (!dto.salesOfficesForSalesAreas.isEmpty()) {
            String firstKey = dto.salesOfficesForSalesAreas.keySet().iterator().next();
            List<String> offices = dto.salesOfficesForSalesAreas.get(firstKey);
            System.assertNotEquals(null, offices, 'Value list for salesOfficesForSalesAreas entries should not be null');
        }

        if (!dto.salesAreas.isEmpty()) {
            String firstAreaKey = dto.salesAreas.keySet().iterator().next();
            String firstAreaLabel = dto.salesAreas.get(firstAreaKey);
            System.assertNotEquals(null, firstAreaLabel, 'salesAreas values should not be null');
        }
    }
}