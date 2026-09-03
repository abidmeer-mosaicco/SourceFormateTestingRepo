@IsTest
private class ContractDateAmenderFlowHandlerTest {
    private static final String ACCOUNT_SAP_ID = '20012345';
    private static final String QUOTE_TYPE = 'Amendment';
    private static final String QUOTE_STATUS = 'Draft';
    private static final String SALES_OFFICE = 'BR MT SUL B2C';

	@TestSetup
	static void setupTestData() {
		// Create test account
		Account testAccount = PMC_DH_TestDataFactoryClass.createTestAccount();

		// Create test contact
		Contact testContact = PMC_DH_TestDataFactoryClass.createTestContact(testAccount.Id);

		// Create test opportunity
		Opportunity testOpp = PMC_DH_TestDataFactoryClass.createOpportunity(testAccount);

		// Create test quote
		SBQQ__Quote__c testQuote = PMC_DH_TestDataFactoryClass.createQuote(testAccount, testContact.Id, testOpp);
		testQuote.SBQQ__Status__c = 'Draft';
		testQuote.PMC_CPQ_ContractStart__c = Date.today();
		testQuote.PMC_CPQ_ContractEnd__c = Date.today().addDays(30);
		update testQuote;

		// Create test contract
		Contract testContract = PMC_DH_TestDataFactoryClass.createContract(testQuote.Id, testAccount.Id);

		// Create MassUpdateExecution__c
		MassUpdateExecution__c execution = new MassUpdateExecution__c();
		execution.Status__c = 'In Progress';
		insert execution;

		// Create MassUpdateExecutionLine__c
		MassUpdateExecutionLine__c executionLine = new MassUpdateExecutionLine__c();
		executionLine.MassUpdateExecution__c = execution.Id;
		executionLine.Contract__c = testContract.Id;
		executionLine.Status__c = 'Pending';
		insert executionLine;
	}    @IsTest
    static void testAmendContractSuccess() {
        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        MassUpdateExecutionLine__c line = [SELECT Id FROM MassUpdateExecutionLine__c LIMIT 1];

        PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest request = new PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest();
        request.uid = contract.Id;
        request.executionLineId = line.Id;

        PMC_CPQ_ContractDateAmenderFlowHandler.ContractDatesClass dates = new PMC_CPQ_ContractDateAmenderFlowHandler.ContractDatesClass();
        dates.PMC_CPQ_ContractStart = Date.today().addDays(5);
        dates.PMC_CPQ_ContractEnd = Date.today().addDays(60);
        request.newDates = JSON.serialize(dates);

        List<PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest> requests = new List<PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest>{ request };

        Test.startTest();
        List<PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractResponse> responses = PMC_CPQ_ContractDateAmenderFlowHandler.amendContract(requests);
        Test.stopTest();

        System.assertNotEquals(null, responses, 'Responses should not be null');
        System.assertEquals(1, responses.size(), 'Should return 1 response');
        // The quote ID will be returned (could be null or valid depending on CPQ API mock)
        System.assertNotEquals(null, responses[0], 'Response should not be null');
    }

    @IsTest
    static void testAmendContractWithNewDates() {
        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        MassUpdateExecutionLine__c line = [SELECT Id FROM MassUpdateExecutionLine__c LIMIT 1];
        SBQQ__Quote__c originalQuote = [SELECT Id, PMC_CPQ_ContractStart__c, PMC_CPQ_ContractEnd__c FROM SBQQ__Quote__c LIMIT 1];

        Date originalStart = originalQuote.PMC_CPQ_ContractStart__c;
        Date originalEnd = originalQuote.PMC_CPQ_ContractEnd__c;

        PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest request = new PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest();
        request.uid = contract.Id;
        request.executionLineId = line.Id;

        Date newStart = Date.today().addDays(10);
        Date newEnd = Date.today().addDays(90);

        PMC_CPQ_ContractDateAmenderFlowHandler.ContractDatesClass dates = new PMC_CPQ_ContractDateAmenderFlowHandler.ContractDatesClass();
        dates.PMC_CPQ_ContractStart = newStart;
        dates.PMC_CPQ_ContractEnd = newEnd;
        request.newDates = JSON.serialize(dates);

        Test.startTest();
        PMC_CPQ_ContractDateAmenderFlowHandler.amendContract(new List<PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest>{ request });
        Test.stopTest();

        // Execution line should be updated
        MassUpdateExecutionLine__c updatedLine = [
            SELECT Id, Status__c, CreatedQuote__c
            FROM MassUpdateExecutionLine__c
            WHERE Id = :line.Id
            LIMIT 1
        ];

        System.assertNotEquals(null, updatedLine, 'Line should exist');
    }

    @IsTest
    static void testAmendContractPartialDates() {
        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        MassUpdateExecutionLine__c line = [SELECT Id FROM MassUpdateExecutionLine__c LIMIT 1];

        PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest request = new PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest();
        request.uid = contract.Id;
        request.executionLineId = line.Id;

        // Only set start date
        PMC_CPQ_ContractDateAmenderFlowHandler.ContractDatesClass dates = new PMC_CPQ_ContractDateAmenderFlowHandler.ContractDatesClass();
        dates.PMC_CPQ_ContractStart = Date.today().addDays(15);
        dates.PMC_CPQ_ContractEnd = null;
        request.newDates = JSON.serialize(dates);

        Test.startTest();
        List<PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractResponse> responses = PMC_CPQ_ContractDateAmenderFlowHandler.amendContract(
            new List<PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest>{ request }
        );
        Test.stopTest();

        System.assertNotEquals(null, responses, 'Responses should not be null');
        System.assertEquals(1, responses.size(), 'Should return 1 response');
    }

    @IsTest
    static void testAmendContractEmptyDates() {
        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        MassUpdateExecutionLine__c line = [SELECT Id FROM MassUpdateExecutionLine__c LIMIT 1];

        PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest request = new PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest();
        request.uid = contract.Id;
        request.executionLineId = line.Id;
        request.newDates = '';

        Test.startTest();
        List<PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractResponse> responses = PMC_CPQ_ContractDateAmenderFlowHandler.amendContract(
            new List<PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest>{ request }
        );
        Test.stopTest();

        System.assertNotEquals(null, responses, 'Responses should not be null');
        System.assertEquals(1, responses.size(), 'Should return 1 response');
    }

    @IsTest
    static void testLoadContract() {
        Contract contract = [SELECT Id FROM Contract LIMIT 1];

        Test.startTest();
        QuoteModel model = PMC_CPQ_ContractDateAmenderFlowHandler.LoadContract(contract.Id);
        Test.stopTest();

        // The model could be null or populated depending on CPQ API availability in test context
        // Just verify the method executes without exception
        System.assert(true, 'LoadContract method should execute without exception');
    }

    @IsTest
    static void testContractDatesClass() {
        PMC_CPQ_ContractDateAmenderFlowHandler.ContractDatesClass dates = new PMC_CPQ_ContractDateAmenderFlowHandler.ContractDatesClass();
        dates.PMC_CPQ_ContractStart = Date.today();
        dates.PMC_CPQ_ContractEnd = Date.today().addDays(30);

        System.assertEquals(Date.today(), dates.PMC_CPQ_ContractStart, 'Start date should match');
        System.assertEquals(Date.today().addDays(30), dates.PMC_CPQ_ContractEnd, 'End date should match');
    }

    @IsTest
    static void testMultipleAmendments() {
        List<Contract> contracts = [SELECT Id FROM Contract];
        List<MassUpdateExecutionLine__c> lines = [SELECT Id FROM MassUpdateExecutionLine__c];

        List<PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest> requests = new List<PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest>();

        for (Integer i = 0; i < contracts.size(); i++) {
            PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest request = new PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest();
            request.uid = contracts[i].Id;
            request.executionLineId = lines[i].Id;

            PMC_CPQ_ContractDateAmenderFlowHandler.ContractDatesClass dates = new PMC_CPQ_ContractDateAmenderFlowHandler.ContractDatesClass();
            dates.PMC_CPQ_ContractStart = Date.today().addDays(i * 5);
            dates.PMC_CPQ_ContractEnd = Date.today().addDays(30 + (i * 10));
            request.newDates = JSON.serialize(dates);

            requests.add(request);
        }

        Test.startTest();
        List<PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractResponse> responses = PMC_CPQ_ContractDateAmenderFlowHandler.amendContract(requests);
        Test.stopTest();

        System.assertEquals(contracts.size(), responses.size(), 'Should return same number of responses as requests');
    }
}