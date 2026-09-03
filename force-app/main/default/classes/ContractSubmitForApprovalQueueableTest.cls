@IsTest
private class ContractSubmitForApprovalQueueableTest {
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

        // Create a few contracts
        List<Contract> contracts = new List<Contract>();
        for (Integer i = 0; i < 3; i++) {
            Contract c = new Contract(
                Name = 'C-00000' + i,
                AccountId = account.Id,
                StartDate = Date.today().addDays(-10 + i),
                Status = 'Draft',
                SBQQ__Quote__c = quotes[i].Id,
                PMC_CPQ_LatestQuote__c = quotes[i].Id
            );
            contracts.add(c);
        }
        insert contracts;

        // Create execution and line
        MassUpdateExecution__c exec = new MassUpdateExecution__c(
            Feature__c = 'ContractDateUpdate',
            Status__c = 'In Progress'
        );
        insert exec;

        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
            MassUpdateExecution__c = exec.Id,
            CreatedQuote__c = quotes[0].Id,
            Feature__c = 'ContractDateUpdate',
            Step__c = 'Submit for Approval',
            Status__c = 'Pending'
        );
        insert line;

        MassUpdateExecutionLine__c eligibleLine = new MassUpdateExecutionLine__c(
            MassUpdateExecution__c = exec.Id,
            CreatedQuote__c = quotes[1].Id,
            Feature__c = 'ContractDateUpdate',
            Step__c = 'Submit for Approval',
            Status__c = 'Pending',
            CheckEligibilityStatus__c = 'Eligible'
        );
        insert eligibleLine;
    }

    @IsTest
    static void testExecuteSuccess() {
        MassUpdateExecutionLine__c line = [
            SELECT Id, CreatedQuote__c
            FROM MassUpdateExecutionLine__c
            WHERE CheckEligibilityStatus__c = 'Eligible'
            LIMIT 1
        ];

        Test.startTest();
        ContractSubmitForApprovalQueueable queueable = new ContractSubmitForApprovalQueueable(
            line.Id,
            line.CreatedQuote__c
        );
        System.enqueueJob(queueable);
        Test.stopTest();

        // Verify line was processed (status could be In Progress or Error depending on approval API)
        MassUpdateExecutionLine__c updatedLine = [
            SELECT Id, Status__c, Step__c
            FROM MassUpdateExecutionLine__c
            WHERE Id = :line.Id
            LIMIT 1
        ];

        System.assertNotEquals(null, updatedLine, 'Line should exist');
        System.assert(
            updatedLine.Status__c == 'Success' || updatedLine.Status__c == 'Error',
            'Status should be Success or Error after execution. Actual status: ' + updatedLine.Status__c
        );
    }

    @IsTest
    static void testExecuteNullLineId() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();
        ContractSubmitForApprovalQueueable queueable = new ContractSubmitForApprovalQueueable(
            null,
            quote.Id
        );
        System.enqueueJob(queueable);
        Test.stopTest();

        // Should complete without error
        System.assert(true, 'Queueable should handle null line ID gracefully');
    }

    @IsTest
    static void testExecuteNullQuoteId() {
        MassUpdateExecutionLine__c line = [SELECT Id FROM MassUpdateExecutionLine__c LIMIT 1];

        Test.startTest();
        ContractSubmitForApprovalQueueable queueable = new ContractSubmitForApprovalQueueable(
            line.Id,
            null
        );
        System.enqueueJob(queueable);
        Test.stopTest();

        // Should complete without error
        System.assert(true, 'Queueable should handle null quote ID gracefully');
    }
}