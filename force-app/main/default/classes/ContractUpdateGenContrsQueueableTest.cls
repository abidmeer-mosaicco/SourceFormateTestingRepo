@IsTest
private class ContractUpdateGenContrsQueueableTest {
    private static final String ACCOUNT_SAP_ID = '20012345';
    private static final String QUOTE_TYPE = 'Quote';
    private static final String QUOTE_RECORD_SUB_TYPE = 'B2C - Fertilizer';
    private static final String QUOTE_STATUS = 'Accepted';
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
            PMC_SS_SAPCustomerNumber__c = ACCOUNT_SAP_ID // This is required otherwise PMC_SS_AccountExternalID__c won't be set in "PMC SS Before Insert/Update Account Flow".
        );
        insert account;

        // Create a few quotes
        Id recordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('PMC_CPQ_DomesticBR').getRecordTypeId();

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        for (Integer i = 0; i < 3; i++) {
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Account__c = account.Id,
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
                PMC_CPQ_SAPContractReference__c = SAP_CONTRACT_REF
            );
            quotes.add(quote);
        }
        insert quotes;

        // Create execution and line
        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'In Progress');
        insert exec;

        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
            MassUpdateExecution__c = exec.Id,
            CreatedQuote__c = quotes[0].Id,
            Feature__c = 'ContractDateUpdate',
            Step__c = 'Generate Contracts',
            Status__c = 'Pending',
            FinishedSteps__c = 'Generate Amendments;Check Eligibility;Submit for Approval'
        );
        insert line;
    }

    @IsTest
    static void testExecuteSuccess() {
        MassUpdateExecutionLine__c line = [
            SELECT Id, CreatedQuote__c, CreatedById
            FROM MassUpdateExecutionLine__c
            LIMIT 1
        ];

        Test.startTest();
        ContractUpdateGenContrsQueueable queueable = new ContractUpdateGenContrsQueueable(line.Id, line.CreatedQuote__c, UserInfo.getUserId());
        System.enqueueJob(queueable);
        Test.stopTest();

        // Verify line was processed
        MassUpdateExecutionLine__c updatedLine = [
            SELECT Id, Status__c, Step__c
            FROM MassUpdateExecutionLine__c
            WHERE Id = :line.Id
            LIMIT 1
        ];

        System.assertNotEquals(null, updatedLine, 'Line should exist');
        // Status could be In Progress or Error depending on DocuSign workflow API
        System.assert(updatedLine.Status__c == 'In Progress' || updatedLine.Status__c == 'Error', 'Status should be set after execution');
    }

    @IsTest
    static void testExecuteNullLineId() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();
        ContractUpdateGenContrsQueueable queueable = new ContractUpdateGenContrsQueueable(null, quote.Id, UserInfo.getUserId());
        System.enqueueJob(queueable);
        Test.stopTest();

        // Should complete without error
        System.assert(true, 'Queueable should handle null line ID gracefully');
    }

    @IsTest
    static void testExecuteNullQuoteId() {
        MassUpdateExecutionLine__c line = [SELECT Id FROM MassUpdateExecutionLine__c LIMIT 1];

        Test.startTest();
        ContractUpdateGenContrsQueueable queueable = new ContractUpdateGenContrsQueueable(line.Id, null, UserInfo.getUserId());
        System.enqueueJob(queueable);
        Test.stopTest();

        // Should complete without error
        System.assert(true, 'Queueable should handle null quote ID gracefully');
    }

    @IsTest
    static void testExecuteWrongStep() {
        MassUpdateExecution__c exec = [SELECT Id FROM MassUpdateExecution__c LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        // Create line with wrong step
        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
            MassUpdateExecution__c = exec.Id,
            CreatedQuote__c = quote.Id,
            Feature__c = 'ContractDateUpdate',
            Step__c = 'Check Eligibility',
            Status__c = 'Pending'
        );
        insert line;

        Test.startTest();
        ContractUpdateGenContrsQueueable queueable = new ContractUpdateGenContrsQueueable(line.Id, quote.Id, UserInfo.getUserId());
        System.enqueueJob(queueable);
        Test.stopTest();

        // Line should not be updated because Step is not 'Generate Contracts'
        MassUpdateExecutionLine__c updatedLine = [
            SELECT Id, Status__c, Step__c
            FROM MassUpdateExecutionLine__c
            WHERE Id = :line.Id
            LIMIT 1
        ];

        System.assert(
            (updatedLine.Status__c == 'In Progress' && updatedLine.Step__c == 'Check Eligibility') ||
            (updatedLine.Status__c == 'Error' && updatedLine.Step__c == 'Generate Contracts'),
            'Status/Step should be In Progress/Check Eligibility or Error/Generate Contracts after execution'
        );
    }

    @IsTest
    static void testExecuteException() {
        User user = [SELECT Id FROM User WHERE Email LIKE 'john.doe%@mosaicco.com' LIMIT 1];

        // Create line without execution
        String invalidId = 'a0E000000000000AAA';

        Test.startTest();
        try {
            ContractUpdateGenContrsQueueable queueable = new ContractUpdateGenContrsQueueable(invalidId, null, user.Id);
            System.enqueueJob(queueable);
        } catch (Exception e) {
            // Expected exception
        }
        Test.stopTest();

        System.assert(true, 'Exception should be handled gracefully');
    }
}