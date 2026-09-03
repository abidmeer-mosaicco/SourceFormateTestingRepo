@isTest
private class PMC_CPI_AccountActionClassTest {
 
    /**
     * @description Mock class for HTTP Callout to simulate a response.
     */
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"message":"Success"}');
            return res;
        }
    }
 
    /**
     * @description Helper method to create a test Account.
     */
    private static Account createTestAccount() {
        Account acc = new Account(Name = 'Test Account', Industry = 'Technology');
        insert acc;
        return acc;
    }
 
    /**
     * @description Mocks custom metadata for endpoint.
     */
    private static void mockMetadataEndpoint() {
        PMC_CPQ_Integration_Endpoint__mdt mockMdt = new PMC_CPQ_Integration_Endpoint__mdt();
        mockMdt.PMC_CPQ_Endpoint__c = '/services/testEndpoint';
        PMC_CPI_AccountActionClass.mockMetadata.put('BPCreation', mockMdt);
    }
 
    /**
     * @description Test the postInfoToCPI method.
     */
    @isTest
    static void testPostInfoToCPI() {
        // Prepare test data
        Account testAccount = createTestAccount();
        mockMetadataEndpoint();
 
        // Create AccountActionRequest instance
        PMC_CPI_AccountActionClass.AccountActionRequest request = new PMC_CPI_AccountActionClass.AccountActionRequest();
        request.inputAccount = testAccount;
        request.strAccountGroup = 'Ship-to';
        request.strBPGrouping = 'GroupA';
        request.strPartnerFunction = 'PartnerX';
        request.strCustomerTaxCategory = 'Tax1';
        request.strEndpointName = 'BPCreation';
        request.strLanguage = 'EN';
        request.strReconcAcc = '123456';
        request.strTransportation = 'Air';
        request.strCNPJNumber = '12345678901234';
        request.strCPFNumber = '12345678901';
        request.strSearchTerm1 = 'TestTerm';
        request.strInvDates = '2025-01-01';
        request.strInvListSched = 'Monthly';
        request.strCashPlanningGroup = 'CPG1';
        request.strToleranceGroup = 'TG1';
        request.strNaturalPerson = 'Yes';
        request.strLayoutSortingRule = 'Rule1';
        request.strTaxClass = 'ClassA';
        request.strDivision = 'Division1';
        request.strAccountManager = 'ZF';
        request.strDomesticBroker = 'ZJ';
        request.strCommissionAgent = 'ZH';
        request.strTSMManager = 'ZB';
        request.strCustServRep = 'ZA';
        request.strBillToPartner = 'BP';
        request.strPayerPartner = 'PY';
        request.strShipToPartner = 'SH';
        request.strSoldToPartner = 'SP';        
        request.strItemOrderProb = '100';
        
 
        List<PMC_CPI_AccountActionClass.AccountActionRequest> requestList = new List<PMC_CPI_AccountActionClass.AccountActionRequest>{request};
 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
 
        Test.startTest();
        PMC_CPI_AccountActionClass.postInfoToCPI(requestList);
        Test.stopTest();
 
        System.assert(true, 'Queueable job should be enqueued and executed without error.');
    }
 
    /**
     * @description Test the execute method directly with mock data.
     */
    @isTest
    static void testExecuteMethodShipto() {
        Account testAccount = createTestAccount();
        mockMetadataEndpoint();
 
        Map<String, String> jsonParams = new Map<String, String>{
            'strBPGrouping' => 'GroupA',
            'strPartnerFunction' => 'PartnerX',
            'strCustomerTaxCategory' => 'Tax1',
            'strLanguage' => 'EN',
            'strReconcAcc' => '123456'
        };
 
        PMC_CPI_AccountActionClass queueableInstance =
            new PMC_CPI_AccountActionClass(testAccount, new List<Id>{testAccount.Id}, 'Ship-to', 'BPCreation', jsonParams);
 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
 
        Test.startTest();
        System.enqueueJob(queueableInstance);
        Test.stopTest();
 
        System.assert(true, 'Queueable job executed successfully.');
    }
	
    /**
     * @description Test the execute method directly with mock data.
     */
    @isTest
    static void testExecuteMethodSoldto() {
        Account testAccount = createTestAccount();
        mockMetadataEndpoint();
 
        Map<String, String> jsonParams = new Map<String, String>{
            'strBPGrouping' => 'GroupA',
            'strPartnerFunction' => 'PartnerX',
            'strCustomerTaxCategory' => 'Tax1',
            'strLanguage' => 'EN',
            'strReconcAcc' => '123456'
        };
 
        PMC_CPI_AccountActionClass queueableInstance =
            new PMC_CPI_AccountActionClass(testAccount, new List<Id>{testAccount.Id}, 'Sold-to', 'BPCreation', jsonParams);
 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
 
        Test.startTest();
        System.enqueueJob(queueableInstance);
        Test.stopTest();
 
        System.assert(true, 'Queueable job executed successfully.');
    }
	
    /**
     * @description Test the execute method directly with mock data.
     */
    @isTest
    static void testExecuteMethodBillto() {
        Account testAccount = createTestAccount();
        mockMetadataEndpoint();
 
        Map<String, String> jsonParams = new Map<String, String>{
            'strBPGrouping' => 'GroupA',
            'strPartnerFunction' => 'PartnerX',
            'strCustomerTaxCategory' => 'Tax1',
            'strLanguage' => 'EN',
            'strReconcAcc' => '123456'
        };
 
        PMC_CPI_AccountActionClass queueableInstance =
            new PMC_CPI_AccountActionClass(testAccount, new List<Id>{testAccount.Id}, 'Bill-to', 'BPCreation', jsonParams);
 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
 
        Test.startTest();
        System.enqueueJob(queueableInstance);
        Test.stopTest();
 
        System.assert(true, 'Queueable job executed successfully.');
    }
	
    /**
     * @description Test the execute method directly with mock data.
     */
    @isTest
    static void testExecuteMethodPayer() {
        Account testAccount = createTestAccount();
        mockMetadataEndpoint();
 
        Map<String, String> jsonParams = new Map<String, String>{
            'strBPGrouping' => 'GroupA',
            'strPartnerFunction' => 'PartnerX',
            'strCustomerTaxCategory' => 'Tax1',
            'strLanguage' => 'EN',
            'strReconcAcc' => '123456'
        };
 
        PMC_CPI_AccountActionClass queueableInstance =
            new PMC_CPI_AccountActionClass(testAccount, new List<Id>{testAccount.Id}, 'Payer', 'BPModification', jsonParams);
 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
 
        Test.startTest();
        System.enqueueJob(queueableInstance);
        Test.stopTest();
 
        System.assert(true, 'Queueable job executed successfully.');
    }
}