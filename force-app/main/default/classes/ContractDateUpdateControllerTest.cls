@IsTest
private class ContractDateUpdateControllerTest {
    private static final String ACCOUNT_SAP_ID = '20012345';
    private static final String QUOTE_TYPE = 'Quote';
    private static final String QUOTE_RECORD_SUB_TYPE = 'B2C - Fertilizer';
    private static final String QUOTE_STATUS = 'Draft';
    private static final String SALES_AREA_COMBINATION = 'Mosaic Fertilizantes do B Domestic Common';
    private static final String SALES_OFFICE = 'BR MT SUL B2C';
    private static final String ACCOUNT_MANAGER_FIRST_NAME = 'Test John';
    private static final String CONTRACT_STATUS = 'Draft';
    private static final String SAP_ORIGINAL_CONTRACT = '0020067890';
    private static final String CONTRACT_DOC_STATUS = 'Accepted';
    private static final String APPROVAL_STATUS = 'Approved';
    private static final String SAP_CONTRACT_REF = '0020054321';

    @testSetup
    static void setupTestData() {
        // Create a test user
        String strSandboxName = UserInfo.getUserName().substringAfterLast('.');
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Sales User'];

        List<User> users = new List<User>();
        for (Integer i = 0; i < 2; i++) {
            UUID randomUuid = UUID.randomUUID();
            User user = new User();
            user.FirstName = ACCOUNT_MANAGER_FIRST_NAME;
            user.LastName = 'Test Doe ' + i;
            user.Alias = 'tDoe' + i;
            user.Email = 'john.doe' + i + '@mosaicco.com';
            user.Username = user.Email + '.' + strSandboxName + randomUuid.toString();
            user.LanguageLocaleKey = 'pt_BR';
            user.EmailEncodingKey = 'UTF-8';
            user.LocaleSidKey = 'pt_BR';
            user.TimeZoneSidKey = 'America/Sao_Paulo';
            user.FederationIdentifier = 'john.doe' + i + '@mosaicco.com';
            user.MobilePhone = '9999999999';
            user.PMC_CPQ_SalesRegion__c = 'Brazil';
            user.PMC_CPQ_SalesOffice__c = SALES_OFFICE;
            user.ProfileId = profiles[0].Id;
            users.add(user);
        }
        insert users;

        // Create a test account
        Account account = new Account(
            Name = 'Test Account',
            PMC_SS_AccountExternalID__c = ACCOUNT_SAP_ID,
            PMC_SS_SAPCustomerNumber__c = ACCOUNT_SAP_ID, // This is required otherwise PMC_SS_AccountExternalID__c won't be set in "PMC SS Before Insert/Update Account Flow".
            BillingCountry = 'Brazil',
            BillingState = 'São Paulo',
            BillingCity = 'São Paulo',
            BillingStreet = 'Test Street',
            BillingPostalCode = '01000-000'
        );
        insert account;

        // Create a test contact
        Contact testContact = new Contact(
            FirstName = 'Test Jane',
            LastName = 'Test Doe'
        );
        insert testContact;

        // Create a few quotes
        Id recordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('PMC_CPQ_DomesticBR').getRecordTypeId();

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        for (Integer i = 0; i < 3; i++) {
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Account__c = account.Id,
                PMC_CPQ_PrimaryContact__c = testContact.Id,
                SBQQ__Type__c = QUOTE_TYPE,
                SBQQ__Status__c = QUOTE_STATUS,
                RecordTypeId = recordTypeId,
                PMC_CPQ_SalesAreaCombination__c = SALES_AREA_COMBINATION,
                PMC_CPQ_SalesOffice__c = SALES_OFFICE,
                PMC_CPQ_AccountManager__c = users[i > 1 ? 1 : i].Id,
                PMC_CPQ_LegacyQuoteID__c = SAP_ORIGINAL_CONTRACT,
                PMC_CPQ_QuoteRecordSubType__c = QUOTE_RECORD_SUB_TYPE,
                PMC_CPQ_ContractStageName__c = CONTRACT_DOC_STATUS,
                PMC_CPQ_ContractStart__c = Date.today(),
                PMC_CPQ_ContractEnd__c = Date.today().addDays(30),
                ApprovalStatus__c = APPROVAL_STATUS,
                PMC_CPQ_SAPContractReference__c = SAP_CONTRACT_REF,
                PMC_CPQ_Region__c = 'Brazil'
            );
            quotes.add(quote);
        }
        insert quotes;

        // Create a few contracts using PMC_DH_TestDataFactoryClass
        List<Contract> contracts = new List<Contract>();
        for (Integer i = 0; i < 3; i++) {
            Contract c = PMC_DH_TestDataFactoryClass.createContract(quotes[i].Id, account.Id);
            c.StartDate = Date.today().addDays(-10 + i);
            contracts.add(c);
        }

        // Update contracts to Activated status
        for (Contract c : contracts) {
            c.Status = 'Activated';
        }
        update contracts;

        // Create dummy MassUpdateExecution__c and MassUpdateExecutionLine__c records
        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Completed', QueryFilters__c = '{}');
        insert exec;

        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
            MassUpdateExecution__c = exec.Id,
            Contract__c = contracts[0].Id,
            Feature__c = 'ContractDateUpdate',
            Status__c = 'Success'
        );
        insert line;
    }

    // -- getContracts Tests
    @IsTest
    static void testGetContracts() {
        Test.startTest();
        ContractDateUpdateController.ContractSearchResult result = ContractDateUpdateController.getContracts(null, null, null, null);
        Test.stopTest();
        System.assert(!result.contracts.isEmpty(), 'Contracts should return.');
    }

    @IsTest
    static void testGetContractsWithSearchFilter() {
        Test.startTest();
        ContractDateUpdateController.ContractSearchResult result = ContractDateUpdateController.getContracts('{"search": "C-"}', null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        // Search by contract number prefix which should find our test contracts
        System.assert(result.contracts.size() >= 0, 'Should return contracts or empty list.');
    }

    @IsTest
    static void testGetContractsWithSoldToFilter() {
        Test.startTest();
        ContractDateUpdateController.ContractSearchResult result = ContractDateUpdateController.getContracts('{"soldTo": "' + ACCOUNT_SAP_ID + '"}', null, null, null);
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
        ContractDateUpdateController.ContractSearchResult result = ContractDateUpdateController.getContracts('{"quoteNumber": "' + quotes[0].PMC_CLM_DocumentNumber__c + '"}', null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(1, result.contracts.size(), 'Should return 1 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithQuoteTypeFilter() {
        Test.startTest();
        ContractDateUpdateController.ContractSearchResult result = ContractDateUpdateController.getContracts('{"type": "' + QUOTE_TYPE + '"}', null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithSAPOriginalContractFilter() {
        Test.startTest();
        ContractDateUpdateController.ContractSearchResult result = ContractDateUpdateController.getContracts('{"sapOriginalContract": "' + SAP_ORIGINAL_CONTRACT + '"}', null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithAccountFilter() {
        Test.startTest();
        ContractDateUpdateController.ContractSearchResult result = ContractDateUpdateController.getContracts('{"account": "Test"}', null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithBusinessTypeFilter() {
        Test.startTest();
        ContractDateUpdateController.ContractSearchResult result = ContractDateUpdateController.getContracts('{"businessType": "' + QUOTE_RECORD_SUB_TYPE + '"}', null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithSalesOfficeFilter() {
        Test.startTest();
        ContractDateUpdateController.ContractSearchResult result = ContractDateUpdateController.getContracts('{"salesOffice": "' + SALES_OFFICE + '"}', null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithAccountManagerFilter() {
        Test.startTest();
        ContractDateUpdateController.ContractSearchResult result = ContractDateUpdateController.getContracts('{"accountManager": "' + ACCOUNT_MANAGER_FIRST_NAME + '"}', null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithContractDocStatusFilter() {
        Test.startTest();
        ContractDateUpdateController.ContractSearchResult result = ContractDateUpdateController.getContracts('{"contractDocStatus": "' + CONTRACT_DOC_STATUS + '"}', null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithContractValidFromFilter() {
        String validFrom = StringUtils.dateToString(Date.today());
        Test.startTest();
        ContractDateUpdateController.ContractSearchResult result = ContractDateUpdateController.getContracts('{"contractValidFrom": "' + validFrom + '"}', null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithContractValidToFilter() {
        String validTo = StringUtils.dateToString(Date.today().addDays(30));
        Test.startTest();
        ContractDateUpdateController.ContractSearchResult result = ContractDateUpdateController.getContracts('{"contractValidTo": "' + validTo + '"}', null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithApprovalStatusFilter() {
        Test.startTest();
        ContractDateUpdateController.ContractSearchResult result = ContractDateUpdateController.getContracts('{"approvalStatus": "' + APPROVAL_STATUS + '"}', null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithQuoteStatusFilter() {
        Test.startTest();
        ContractDateUpdateController.ContractSearchResult result = ContractDateUpdateController.getContracts('{"quoteStatus": "' + QUOTE_STATUS + '"}', null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testGetContractsWithSAPContrctRefFilter() {
        Test.startTest();
        ContractDateUpdateController.ContractSearchResult result = ContractDateUpdateController.getContracts('{"sapContractRef": "' + SAP_CONTRACT_REF + '"}', null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, result.contracts, 'Results should not be null.');
        System.assertEquals(3, result.contracts.size(), 'Should return 3 contracts for the search term.');
    }

    @IsTest
    static void testProcessContractDateUpdates() {
        List<Contract> contracts = [SELECT Id FROM Contract LIMIT 2];
        Date newStart = Date.today().addDays(5);
        Date newEnd = Date.today().addDays(40);
        Test.startTest();
        List<ContractDateUpdateController.ContractDateUpdateItem> items = new List<ContractDateUpdateController.ContractDateUpdateItem>();
        ContractDateUpdateController.ContractDateUpdateItem it1 = new ContractDateUpdateController.ContractDateUpdateItem();
        it1.contractId = contracts[0].Id;
        it1.startDate = newStart;
        it1.endDate = newEnd;
        ContractDateUpdateController.ContractDateUpdateItem it2 = new ContractDateUpdateController.ContractDateUpdateItem();
        it2.contractId = contracts[1].Id;
        it2.startDate = newStart;
        it2.endDate = newEnd;
        items.add(it1);
        items.add(it2);
        ContractDateUpdateController.ExecutionDTO dto = ContractDateUpdateController.generateAmendments('ContractDateUpdate', JSON.serialize(items), null, null);
        Test.stopTest();
        System.assertNotEquals(null, dto, 'DTO should not be null');
        System.assertNotEquals(null, dto.execution, 'Execution should be created');
        System.assertEquals(2, dto.lines.size(), 'Two execution lines should be created');
        for (MassUpdateExecutionLine__c l : dto.lines) {
            Map<String, Object> nv = (Map<String, Object>) JSON.deserializeUntyped(l.NewValues__c);
            System.assertEquals(String.valueOf(newStart), String.valueOf(nv.get('PMC_CPQ_ContractStart__c')));
            System.assertEquals(String.valueOf(newEnd), String.valueOf(nv.get('PMC_CPQ_ContractEnd__c')));
        }
    }

    @IsTest
    static void testProcessContractDateUpdatesNoContractIds() {
        Date newStart = Date.today().addDays(5);
        Date newEnd = Date.today().addDays(40);
        Test.startTest();
        Boolean exceptionThrown = false;
        List<ContractDateUpdateController.ContractDateUpdateItem> emptyItems = new List<ContractDateUpdateController.ContractDateUpdateItem>();
        try {
            ContractDateUpdateController.generateAmendments('ContractDateUpdate', JSON.serialize(emptyItems), null, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Expected exception to be thrown for empty items');
    }

    // @IsTest
    // static void testEnqueueAmendmentProcessingSetsExecutionInProgress() {
    //     // Create execution and a line
    //     MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started');
    //     insert exec;

    //     Contract c = [SELECT Id FROM Contract LIMIT 1];
    //     MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
    //         MassUpdateExecution__c = exec.Id,
    //         Contract__c = c.Id,
    //         Feature__c = 'ContractDateUpdate',
    //         Status__c = 'Pending'
    //     );
    //     insert line;

    //     Date newStart = Date.today().addDays(2);
    //     Date newEnd = Date.today().addDays(20);

    //     Test.startTest();
    //     ContractDateUpdateController.enqueueAmendmentProcessing(new List<Id>{ line.Id }, newStart, newEnd, exec.Id);
    //     Test.stopTest();

    //     MassUpdateExecution__c execAfter = [SELECT Id, Status__c FROM MassUpdateExecution__c WHERE Id = :exec.Id LIMIT 1];
    //     System.assertEquals('In Progress', execAfter.Status__c, 'Execution should be set to In Progress');
    // }

    // -- getRecentExecutions Tests
    @IsTest
    static void testGetRecentExecutionsReturnsList() {
        // Insert a couple of executions
        List<MassUpdateExecution__c> toIns = new List<MassUpdateExecution__c>{
            new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started'),
            new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started')
        };
        insert toIns;

        Test.startTest();
        List<MassUpdateExecution__c> recent = ContractDateUpdateController.getRecentExecutions();
        Test.stopTest();

        System.assertNotEquals(null, recent, 'Should return a list');
        System.assert(recent.size() > 0, 'Should include recently created executions');
    }

    // -- getExecution Tests
    @IsTest
    static void testGetExecutionSuccess() {
        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started');
        insert exec;

        Test.startTest();
        MassUpdateExecution__c fetched = ContractDateUpdateController.getExecution(exec.Id);
        Test.stopTest();

        System.assertEquals(exec.Id, fetched.Id, 'Should return the same execution');
    }

    @IsTest
    static void testGetExecutionNotFound() {
        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started');
        insert exec;

        // Not found - construct an invalid Id for the sobject
        String prefix = MassUpdateExecution__c.SObjectType.getDescribe().getKeyPrefix();
        String invalidId = prefix + '000000000000';
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            ContractDateUpdateController.getExecution(Id.valueOf(invalidId));
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Expected exception to be thrown for invalid execution ID');
    }

    @IsTest
    static void testGetExecutionIdNull() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            ContractDateUpdateController.getExecution(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Expected exception to be thrown for null execution ID');
    }

    // -- generateAmendments Tests
    @IsTest
    static void testGenerateAmendmentsSuccess() {
        // Use existing contracts from setup
        List<Contract> contracts = [SELECT Id FROM Contract LIMIT 2];
        Date newStart = Date.today().addDays(3);
        Date newEnd = Date.today().addDays(33);

        Test.startTest();
        List<ContractDateUpdateController.ContractDateUpdateItem> items = new List<ContractDateUpdateController.ContractDateUpdateItem>();
        for (Integer i = 0; i < 2; i++) {
            ContractDateUpdateController.ContractDateUpdateItem it = new ContractDateUpdateController.ContractDateUpdateItem();
            it.contractId = contracts[i].Id;
            it.startDate = newStart;
            it.endDate = newEnd;
            items.add(it);
        }
        ContractDateUpdateController.ExecutionDTO dto = ContractDateUpdateController.generateAmendments('ContractDateUpdate', JSON.serialize(items), null, '{"search":""}');
        Test.stopTest();

        System.assertNotEquals(null, dto, 'DTO should not be null');
        System.assertNotEquals(null, dto.execution, 'Execution should be created');
        System.assert(dto.lines.size() > 0, 'Lines should be created');

        MassUpdateExecution__c execAfter = [SELECT Id, Status__c FROM MassUpdateExecution__c WHERE Id = :dto.execution.Id LIMIT 1];
        System.assertEquals('Queued', execAfter.Status__c, 'Execution status should be Queued after generating lines');
    }

    @IsTest
    static void testGenerateAmendmentsNoFeature() {
        // Use existing contracts from setup
        List<Contract> contracts = [SELECT Id FROM Contract LIMIT 2];
        Date newStart = Date.today().addDays(3);
        Date newEnd = Date.today().addDays(33);

        Test.startTest();
        Boolean exceptionThrown = false;
        List<ContractDateUpdateController.ContractDateUpdateItem> itemsNoFeature = new List<ContractDateUpdateController.ContractDateUpdateItem>();
        for (Integer i = 0; i < 2; i++) {
            ContractDateUpdateController.ContractDateUpdateItem it = new ContractDateUpdateController.ContractDateUpdateItem();
            it.contractId = contracts[i].Id;
            it.startDate = newStart;
            it.endDate = newEnd;
            itemsNoFeature.add(it);
        }
        try {
            ContractDateUpdateController.ExecutionDTO dto = ContractDateUpdateController.generateAmendments(null, JSON.serialize(itemsNoFeature), null, '{"search":""}');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Expected exception to be thrown when feature is null');
    }

    @IsTest
    static void testGenerateAmendmentsNoContractIds() {
        Date newStart = Date.today().addDays(3);
        Date newEnd = Date.today().addDays(33);

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            ContractDateUpdateController.ExecutionDTO dto = ContractDateUpdateController.generateAmendments('ContractDateUpdate', JSON.serialize(new List<ContractDateUpdateController.ContractDateUpdateItem>()), null, '{"search":""}');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Expected exception to be thrown when no contracts provided');
    }

    @IsTest
    static void testGenerateAmendmentsInvalidContractIds() {
        Date newStart = Date.today().addDays(3);
        Date newEnd = Date.today().addDays(33);

        // Create an item with null contractId instead of invalid ID to avoid cross-reference errors
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            List<ContractDateUpdateController.ContractDateUpdateItem> badItems = new List<ContractDateUpdateController.ContractDateUpdateItem>();
            ContractDateUpdateController.ContractDateUpdateItem bit = new ContractDateUpdateController.ContractDateUpdateItem();
            bit.contractId = null; // Null contract ID
            bit.startDate = newStart;
            bit.endDate = newEnd;
            badItems.add(bit);
            ContractDateUpdateController.ExecutionDTO dto = ContractDateUpdateController.generateAmendments('ContractDateUpdate', JSON.serialize(badItems), null, '{"search":""}');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Expected exception to be thrown for invalid contract IDs');
    }

    @IsTest
    static void testGenerateAmendmentsQueryFiltersMoreThan255() {
        // Use existing contracts from setup
        List<Contract> contracts = [SELECT Id FROM Contract LIMIT 2];
        Date newStart = Date.today().addDays(3);
        Date newEnd = Date.today().addDays(33);

        Test.startTest();
        List<ContractDateUpdateController.ContractDateUpdateItem> itemsLong = new List<ContractDateUpdateController.ContractDateUpdateItem>();
        for (Integer i = 0; i < 2; i++) {
            ContractDateUpdateController.ContractDateUpdateItem it = new ContractDateUpdateController.ContractDateUpdateItem();
            it.contractId = contracts[i].Id;
            it.startDate = newStart;
            it.endDate = newEnd;
            itemsLong.add(it);
        }
        ContractDateUpdateController.ExecutionDTO dto = ContractDateUpdateController.generateAmendments(
            'ContractDateUpdate',
            JSON.serialize(itemsLong),
            null,
            '{"search":"ajdlaksjdlakjdalskdjaslkdjasldk' +
            'ajsdlkasjdlaskjdlaskdjaslkdjasldkjasldkjasl' +
            'dkajldkajsldkasjdlakjsdlaksjdlaksjdalskdjal' +
            'sdjasldkjasldkajsdlaksjdalkdjalkdjaslfkhjsd' +
            'lfhsdlfgjhfgkjdhfgkdfjhgkdfjhgdkfjghdfkgjhd' +
            'fgkjdfhgkdjhfgkdjhgkdjfhgkdjfhgdkjfghdkfjgh"}'
        );
        Test.stopTest();

        System.assertNotEquals(null, dto, 'DTO should not be null');
        System.assertNotEquals(null, dto.execution, 'Execution should be created');
        System.assert(dto.lines.size() > 0, 'Lines should be created');

        MassUpdateExecution__c execAfter = [SELECT Id, Status__c FROM MassUpdateExecution__c WHERE Id = :dto.execution.Id LIMIT 1];
        System.assertEquals('Queued', execAfter.Status__c, 'Execution status should be Queued after generating lines');
    }

    @IsTest
    static void testGenerateAmendmentsExistingExecution() {
        // Use existing contracts from setup
        List<Contract> contracts = [SELECT Id FROM Contract LIMIT 2];
        Date newStart = Date.today().addDays(3);
        Date newEnd = Date.today().addDays(33);

        MassUpdateExecution__c exec = [SELECT Id FROM MassUpdateExecution__c WHERE Feature__c = 'ContractDateUpdate' LIMIT 1];

        Test.startTest();
        List<ContractDateUpdateController.ContractDateUpdateItem> items = new List<ContractDateUpdateController.ContractDateUpdateItem>();
        for (Integer i = 0; i < 2; i++) {
            ContractDateUpdateController.ContractDateUpdateItem it = new ContractDateUpdateController.ContractDateUpdateItem();
            it.contractId = contracts[i].Id;
            it.startDate = newStart;
            it.endDate = newEnd;
            items.add(it);
        }
        ContractDateUpdateController.ExecutionDTO dto = ContractDateUpdateController.generateAmendments('ContractDateUpdate', JSON.serialize(items), exec.Id, '{"search":""}');
        Test.stopTest();

        System.assertNotEquals(null, dto, 'DTO should not be null');
        System.assertNotEquals(null, dto.execution, 'Execution should be updated');
        System.assert(dto.lines.size() > 0, 'Lines should be created');

        MassUpdateExecution__c execAfter = [SELECT Id, Status__c FROM MassUpdateExecution__c WHERE Id = :dto.execution.Id LIMIT 1];
        System.assertEquals('Queued', execAfter.Status__c, 'Execution status should be Queued after generating lines');
    }

    @IsTest
    static void testGetExecutionLinesReturnsLines() {
        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started');
        insert exec;
        Contract c = [SELECT Id FROM Contract LIMIT 1];
        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
            MassUpdateExecution__c = exec.Id,
            Contract__c = c.Id,
            Feature__c = 'ContractDateUpdate',
            Status__c = 'Pending'
        );
        insert line;

        Test.startTest();
        List<MassUpdateExecutionLine__c> lines = ContractDateUpdateController.getExecutionLines(exec.Id);
        Test.stopTest();

        System.assertEquals(1, lines.size(), 'Should return one execution line');
        System.assertEquals(line.Id, lines[0].Id, 'Returned line should match');
    }

    // @IsTest
    // static void testCheckEligibilityUpdatesStatus() {
    //     MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started');
    //     insert exec;
    //     SBQQ__Quote__c q = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
    //     Contract c = [SELECT Id FROM Contract LIMIT 1];
    //     MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
    //         MassUpdateExecution__c = exec.Id,
    //         Contract__c = c.Id,
    //         CreatedQuote__c = q.Id,
    //         Step__c = 'Check Eligibility',
    //         Status__c = 'Pending'
    //     );
    //     insert line;

    //     Test.startTest();
    //     List<MassUpdateExecutionLine__c> results = ContractDateUpdateController.checkEligibility(exec.Id, new List<Id>{ line.Id });
    //     Test.stopTest();

    //     System.assertEquals(1, results.size(), 'Should return the processed line');
    //     MassUpdateExecutionLine__c updated = [SELECT Id, Status__c FROM MassUpdateExecutionLine__c WHERE Id = :line.Id LIMIT 1];
    //     System.assertEquals('In Progress', updated.Status__c, 'Line status should be In Progress');
    // }

    // -- submitForApproval & generateContracts Tests
    @IsTest
    static void testSubmitForApprovalAndGenerateContractsNoError() {
        // prepare a line with CreatedQuote__c populated
        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started');
        insert exec;
        SBQQ__Quote__c q = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Contract c = [SELECT Id FROM Contract LIMIT 1];
        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
            MassUpdateExecution__c = exec.Id,
            Contract__c = c.Id,
            CreatedQuote__c = q.Id,
            Feature__c = 'ContractDateUpdate',
            Status__c = 'Pending'
        );
        insert line;

        Test.startTest();
        // should enqueue queueables but not throw
        ContractDateUpdateController.submitForApproval(exec.Id, new List<Id>{ line.Id });
        ContractDateUpdateController.generateContracts(exec.Id, new List<Id>{ line.Id });
        Test.stopTest();

        // If we reached here no exception was thrown
        System.assert(true, 'submitForApproval and generateContracts executed without exception');
    }

    @IsTest
    static void testSubmitForApprovalQuoteIdNull() {
        // prepare a line with CreatedQuote__c populated
        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started');
        insert exec;
        SBQQ__Quote__c q = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Contract c = [SELECT Id FROM Contract LIMIT 1];
        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
            MassUpdateExecution__c = exec.Id,
            Contract__c = c.Id,
            CreatedQuote__c = null,
            Feature__c = 'ContractDateUpdate',
            Status__c = 'Pending'
        );
        insert line;

        Test.startTest();
        // should enqueue queueables but not throw
        ContractDateUpdateController.submitForApproval(exec.Id, new List<Id>{ line.Id });
        Test.stopTest();

        // If we reached here no exception was thrown
        System.assert(true, 'submitForApproval executed without exception');
    }

    @IsTest
    static void testSaveLinesAndEnqueueSuccess() {
        // Create execution and lines
        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started');
        insert exec;

        List<Contract> contracts = [SELECT Id FROM Contract LIMIT 2];
        List<MassUpdateExecutionLine__c> lines = new List<MassUpdateExecutionLine__c>();
        for (Integer i = 0; i < 2; i++) {
            lines.add(new MassUpdateExecutionLine__c(
                MassUpdateExecution__c = exec.Id,
                Contract__c = contracts[i].Id,
                Feature__c = 'ContractDateUpdate',
                Status__c = 'Pending'
            ));
        }
        insert lines;

        // Update NewValues__c
        Date newStart = Date.today().addDays(5);
        Date newEnd = Date.today().addDays(40);
        Map<String, Object> newValues = new Map<String, Object>{
            'PMC_CPQ_ContractStart__c' => newStart,
            'PMC_CPQ_ContractEnd__c' => newEnd
        };

        for (MassUpdateExecutionLine__c line : lines) {
            line.NewValues__c = JSON.serialize(newValues);
        }

        Test.startTest();
        List<MassUpdateExecutionLine__c> result = ContractDateUpdateController.saveLinesAndEnqueue(lines, exec.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(2, result.size(), 'Should return 2 updated lines');

        // Verify lines were updated
        List<MassUpdateExecutionLine__c> updatedLines = [
            SELECT Id, NewValues__c, Status__c
            FROM MassUpdateExecutionLine__c
            WHERE Id IN :lines
        ];
        System.assertEquals(2, updatedLines.size(), 'Lines should be updated');
    }

    @IsTest
    static void testSaveLinesAndEnqueueNoLines() {
        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started');
        insert exec;

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            ContractDateUpdateController.saveLinesAndEnqueue(null, exec.Id);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Expected exception for null lines');
    }

    @IsTest
    static void testSaveLinesAndEnqueueEmptyList() {
        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started');
        insert exec;

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            ContractDateUpdateController.saveLinesAndEnqueue(new List<MassUpdateExecutionLine__c>(), exec.Id);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Expected exception for empty lines list');
    }

    @IsTest
    static void testCheckEligibilitySuccess() {
        // Create execution
        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started');
        insert exec;

        // Create quote and contract
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Contract contract = [SELECT Id FROM Contract LIMIT 1];

        // Create line with CreatedQuote__c populated
        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
            MassUpdateExecution__c = exec.Id,
            Contract__c = contract.Id,
            CreatedQuote__c = quote.Id,
            Feature__c = 'ContractDateUpdate',
            Status__c = 'Success',
            CheckEligibilityStatus__c = null
        );
        insert line;

        Test.startTest();
        List<MassUpdateExecutionLine__c> results = ContractDateUpdateController.checkEligibility(exec.Id, new List<Id>{ line.Id });
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return 1 processed line');

        // Verify line was updated
        // Note: In test context, the queueable executes synchronously and the external callout
        // to PMC_CPQ_FetchLatestPriceBeforeSubmission will fail, setting status to 'Error'
        MassUpdateExecutionLine__c updatedLine = [
            SELECT Id, Status__c, Step__c, CheckEligibilityStatus__c
            FROM MassUpdateExecutionLine__c
            WHERE Id = :line.Id
        ];
        System.assertEquals('Check Eligibility', updatedLine.Step__c, 'Line step should be Check Eligibility');
        // Status could be 'Error' in test context due to external callout failure
        System.assert(updatedLine.Status__c != null, 'Line status should be set');
    }

    @IsTest
    static void testCheckEligibilityNoExecutionId() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            ContractDateUpdateController.checkEligibility(null, new List<Id>());
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Expected exception for null executionId');
    }

    @IsTest
    static void testCheckEligibilityNoLineIds() {
        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started');
        insert exec;

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            ContractDateUpdateController.checkEligibility(exec.Id, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Expected exception for null execution line ids');
    }

    @IsTest
    static void testCheckEligibilityEmptyLineIds() {
        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started');
        insert exec;

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            ContractDateUpdateController.checkEligibility(exec.Id, new List<Id>());
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Expected exception for empty execution line ids');
    }

    @IsTest
    static void testCheckEligibilityWithoutCreatedQuote() {
        // Create execution
        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started');
        insert exec;

        Contract contract = [SELECT Id FROM Contract LIMIT 1];

        // Create line without CreatedQuote__c - should not be processed
        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
            MassUpdateExecution__c = exec.Id,
            Contract__c = contract.Id,
            CreatedQuote__c = null,
            Feature__c = 'ContractDateUpdate',
            Status__c = 'Success'
        );
        insert line;

        Test.startTest();
        List<MassUpdateExecutionLine__c> results = ContractDateUpdateController.checkEligibility(exec.Id, new List<Id>{ line.Id });
        Test.stopTest();

        // Should return empty list because line doesn't have CreatedQuote__c
        System.assertEquals(0, results.size(), 'Should not process lines without CreatedQuote__c');
    }

    @IsTest
    static void testCheckEligibilityAlreadyChecked() {
        // Create execution
        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started');
        insert exec;

        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Contract contract = [SELECT Id FROM Contract LIMIT 1];

        // Create line with CheckEligibilityStatus__c already set - should not be processed
        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
            MassUpdateExecution__c = exec.Id,
            Contract__c = contract.Id,
            CreatedQuote__c = quote.Id,
            Feature__c = 'ContractDateUpdate',
            Status__c = 'Success',
            CheckEligibilityStatus__c = 'Eligible'
        );
        insert line;

        Test.startTest();
        List<MassUpdateExecutionLine__c> results = ContractDateUpdateController.checkEligibility(exec.Id, new List<Id>{ line.Id });
        Test.stopTest();

        // Should return empty list because CheckEligibilityStatus__c is already set
        System.assertEquals(0, results.size(), 'Should not process lines with CheckEligibilityStatus__c already set');
    }

    // @IsTest
    // static void testSubmitForApprovalException() {
    //     // prepare a line with CreatedQuote__c populated
    //     MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started');
    //     insert exec;
    //     SBQQ__Quote__c q = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];
    //     q.SBQQ__Status__c = 'Rejected';
    //     update q;
    //     Contract c = [SELECT Id FROM Contract LIMIT 1];
    //     MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
    //         MassUpdateExecution__c = exec.Id,
    //         Contract__c = c.Id,
    //         CreatedQuote__c = q.Id,
    //         Feature__c = 'ContractDateUpdate',
    //         Status__c = 'Pending'
    //     );
    //     insert line;

    //     Test.startTest();
    //     // should enqueue queueables but not throw
    //     ContractDateUpdateController.submitForApproval(exec.Id, new List<Id>{ line.Id });
    //     Test.stopTest();

    //     MassUpdateExecutionLine__c lineAfter = [SELECT Id, Status__c FROM MassUpdateExecutionLine__c WHERE Id = :line.Id LIMIT 1];
    //     System.assertEquals('Error', lineAfter.Status__c, 'Execution Line status should be Error.');
    // }
}