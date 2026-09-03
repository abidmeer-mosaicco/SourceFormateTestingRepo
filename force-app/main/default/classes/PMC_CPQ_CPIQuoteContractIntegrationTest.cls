@isTest(SeeAllData=false)
private class PMC_CPQ_CPIQuoteContractIntegrationTest {

    @TestSetup
    static void setup() {
        PMC_ProcessSwitches__c bypass = PMC_ProcessSwitches__c.getOrgDefaults();
        bypass.PMC_BypassValidationRule__c = true;
        bypass.PMC_BypassFlow__c = true;
        upsert bypass;

        Account acct = new Account(Name = 'Test Integration Account', Type = 'Sold-To');
        insert acct;

        SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__Account__c = acct.Id);
        insert q;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q.Id,
            SBQQ__Product__c = prod.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ListPrice__c = 10
        );
        insert ql;

        SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
            SBQQ__QuoteLine__c = ql.Id,
            SBQQ__Quantity__c = 1
        );
        insert sub;

        bypass.PMC_BypassValidationRule__c = false;
        bypass.PMC_BypassFlow__c = false;
        upsert bypass;
    }

    @isTest
    static void testGetFilteredListDedupes() {
        Map<String, Object> rec1 = new Map<String, Object>{
            'OBJECT_NUMBER' => 'SAP001', 'SFRecordId' => '001000000000001AAA',
            'ObjectName' => 'Contract', 'statusCode' => 201, 'responsetext' => 'Created'
        };
        Map<String, Object> rec2 = new Map<String, Object>{
            'OBJECT_NUMBER' => 'SAP001', 'SFRecordId' => '001000000000001AAA',
            'ObjectName' => 'Contract', 'statusCode' => 201, 'responsetext' => 'Created'
        };
        Map<String, Object> rec3 = new Map<String, Object>{
            'OBJECT_NUMBER' => 'SAP002', 'SFRecordId' => '001000000000002AAA',
            'ObjectName' => 
            'Quote', 'statusCode' => 200, 'responsetext' => 'OK'
        };

        List<Object> filtered = PMC_CPQ_CPIQuoteContractIntegrationClass.getFilteredList(
            new List<Object>{ rec1, rec2, rec3 }
        );

        System.assertEquals(2, filtered.size(), 'Should have deduped records');
    }

    @isTest
    static void testGetQuoteErrorStatus() {
        System.assertEquals('Partial Success', PMC_CPQ_CPIQuoteContractIntegrationClass.getQuoteErrorStatus(3, 1));
        System.assertEquals('Error', PMC_CPQ_CPIQuoteContractIntegrationClass.getQuoteErrorStatus(2, 2));
    }

    @isTest
    static void testParseQuoteContractFilteredList_success() {
        SBQQ__Quote__c q = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        List<Object> filteredList = new List<Object>{
            new Map<String, Object>{ 'OBJECT_NUMBER' => '', 'SFRecordId' => q.Id, 'ObjectName' => 'Quote', 'statusCode' => 201, 'responsetext' => 'Created' },
            new Map<String, Object>{ 'OBJECT_NUMBER' => 'SAP123', 'SFRecordId' => q.Id, 'ObjectName' => 'Contract', 'statusCode' => 201, 'responsetext' => 'Created' }
        };

        Test.startTest();
        PMC_CPQ_CPIQuoteContractIntegrationClass.parseQuoteContractFilteredList(
            new List<SBQQ__Quote__c>{ q }, filteredList, 'dummyEndpoint'
        );
        Test.stopTest();

        System.assertEquals('Success', q.PMC_CPQ_IntegrationStatus__c);
        System.assertEquals('SAP123', q.PMC_CPQ_SAPContractReference__c);
        System.assertEquals('Success', PMC_CPQ_CPIQuoteContractIntegrationClass.getOverallTransactionStatus());
    }

    @isTest
    static void testParseQuoteContractFilteredList_error() {
        SBQQ__Quote__c q = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        List<Object> filteredList = new List<Object>{
            new Map<String, Object>{ 'OBJECT_NUMBER' => '', 'SFRecordId' => q.Id, 'ObjectName' => 'Quote', 'statusCode' => 406, 'responsetext' => 'Not Acceptable' },
            new Map<String, Object>{ 'OBJECT_NUMBER' => '0020009926', 'SFRecordId' => q.Id, 'ObjectName' => 'Contract', 'statusCode' => 406, 'responsetext' => 'Not Acceptable' }
        };

        Test.startTest();
        PMC_CPQ_CPIQuoteContractIntegrationClass.parseQuoteContractFilteredList(
            new List<SBQQ__Quote__c>{ q }, filteredList, 'dummyEndpoint'
        );
        Test.stopTest();

        System.assertEquals('Error', q.PMC_CPQ_IntegrationStatus__c);
        System.assertEquals('Error', PMC_CPQ_CPIQuoteContractIntegrationClass.getOverallTransactionStatus());
    }

    @isTest
    static void testGetFilteredErrorList() {
        SBQQ__Quote__c q = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Map<String, Object> errRec = new Map<String, Object>{
            'TYPE' => 'E', 'Z_REFSFCONITM' => 'QI-001',
            'SFRecordId' => q.Id, 'MESSAGE' => 'Line-level failure'
        };
        List<SBQQ__Quote__c> lstQuotes = new List<SBQQ__Quote__c>{ q };

        Test.startTest();
        PMC_CPQ_CPIQuoteContractIntegrationClass.getFilteredErrorList(
            new List<Object>{ errRec }, lstQuotes, new List<SBQQ__QuoteLine__c>(), 'dummyEndpoint'
        );
        Test.stopTest();

        System.assertNotEquals(null, lstQuotes[0].PMC_CPQ_IntegrationMessage__c);
        System.assert(lstQuotes[0].PMC_CPQ_IntegrationMessage__c.contains('Line-level failure'));
    }

    @isTest
    static void testUpdateQuoteExceptionStatusMsg() {
        SBQQ__Quote__c q = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        PMC_CPQ_CPIRemoteCalloutUtilityClass.strExceptionMsg = 'Some Exception Occurred';

        Test.startTest();
        PMC_CPQ_CPIQuoteContractIntegrationClass.updateQuoteExceptionStatusMsg(
            new List<SBQQ__Quote__c>{ q }, 'dummyEndpoint'
        );
        Test.stopTest();

        SBQQ__Quote__c refreshed = [SELECT PMC_CPQ_IntegrationStatus__c, PMC_CPQ_IntegrationMessage__c FROM SBQQ__Quote__c WHERE Id = :q.Id];
        System.assertEquals('Error', refreshed.PMC_CPQ_IntegrationStatus__c);
        System.assert(refreshed.PMC_CPQ_IntegrationMessage__c.contains('Some Exception Occurred'));
    }

    @isTest
    static void testParseJSONQuoteContractInterface_success() {
        SBQQ__Quote__c q = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        List<Map<String, Object>> respList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'OBJECT_NUMBER' => '', 'SFRecordId' => q.Id, 'ObjectName' => 'Quote', 'statusCode' => 200, 'responsetext' => 'OK' },
            new Map<String, Object>{ 'OBJECT_NUMBER' => 'SAP123', 'SFRecordId' => q.Id, 'ObjectName' => 'Contract', 'statusCode' => 201, 'responsetext' => 'Created' }
        };
        HttpResponse fakeResponse = new HttpResponse();
        fakeResponse.setStatusCode(200);
        fakeResponse.setBody(JSON.serialize(respList));
        PMC_CPQ_CPIRemoteCalloutUtilityClass.request = new HttpRequest();
        PMC_CPQ_CPIRemoteCalloutUtilityClass.request.setBody('REQ');

        Test.startTest();
        PMC_CPQ_CPIQuoteContractIntegrationClass.parseJSONQuoteContractInterface(
            new List<SBQQ__Quote__c>{ q }, fakeResponse, 'dummyEndpoint'
        );
        Test.stopTest();

        SBQQ__Quote__c refreshed = [SELECT PMC_CPQ_IntegrationStatus__c, PMC_CPQ_SAPContractReference__c FROM SBQQ__Quote__c WHERE Id = :q.Id];
        System.assertEquals('Success', refreshed.PMC_CPQ_IntegrationStatus__c);
        System.assertEquals('SAP123', refreshed.PMC_CPQ_SAPContractReference__c);
    }

    @isTest
    static void testParseJSONQuoteContractInterface_errorCodes() {
        SBQQ__Quote__c q = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        List<Map<String, Object>> respList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'TYPE' => 'E', 'OBJECT_NUMBER' => '', 'SFRecordId' => q.Id,
                'ObjectName' => 'Quote', 'statusCode' => 406, 'responsetext' => 'Not Acceptable',
                'OBJECT_ITEM' => 0, 'J_1BCFOP' => '', 'MESSAGE' => 'Integration error' }
        };
        HttpResponse fakeResponse = new HttpResponse();
        fakeResponse.setStatusCode(200);
        fakeResponse.setBody(JSON.serialize(respList));
        PMC_CPQ_CPIRemoteCalloutUtilityClass.request = new HttpRequest();
        PMC_CPQ_CPIRemoteCalloutUtilityClass.request.setBody('REQ');

        Test.startTest();
        PMC_CPQ_CPIQuoteContractIntegrationClass.parseJSONQuoteContractInterface(
            new List<SBQQ__Quote__c>{ q }, fakeResponse, 'dummyEndpoint'
        );
        Test.stopTest();

        SBQQ__Quote__c refreshed = [SELECT PMC_CPQ_IntegrationStatus__c FROM SBQQ__Quote__c WHERE Id = :q.Id];
        System.assertEquals('Error', refreshed.PMC_CPQ_IntegrationStatus__c);
    }

    @isTest
    static void testParseJSONQuoteContractInterface_nonSuccessHttpStatus() {
        SBQQ__Quote__c q = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        HttpResponse fakeResponse = new HttpResponse();
        fakeResponse.setStatusCode(500);
        fakeResponse.setBody('Internal Server Error');
        PMC_CPQ_CPIRemoteCalloutUtilityClass.request = new HttpRequest();
        PMC_CPQ_CPIRemoteCalloutUtilityClass.request.setBody('REQ');

        Test.startTest();
        PMC_CPQ_CPIQuoteContractIntegrationClass.parseJSONQuoteContractInterface(
            new List<SBQQ__Quote__c>{ q }, fakeResponse, 'dummyEndpoint'
        );
        Test.stopTest();

        SBQQ__Quote__c refreshed = [SELECT PMC_CPQ_IntegrationStatus__c FROM SBQQ__Quote__c WHERE Id = :q.Id];
        System.assertEquals('Error', refreshed.PMC_CPQ_IntegrationStatus__c);
    }
}