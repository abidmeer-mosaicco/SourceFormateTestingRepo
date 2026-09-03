@isTest
private class PMC_CPQ_QuoteContractCreateActionTest {
    
    /**
     * @description Mock class for HTTP Callouts
     */
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    /**
     * @description Mock class for Null HTTP Callouts
     */
    private class MockNullResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Returning null or throwing an exception to trigger the catch block in utility
            throw new CalloutException('Simulated Exception');
        }
    }

    /**
     * @description Setup test data
     */
    @testSetup
    static void setup() {
        // Get System Administrator profile
        Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        // Create User correctly
        User objUser = new User(
            LastName = 'System Administrator Test',
            Alias = 'sysadm',
            Email = 'sysadmin@test.com',
            Username = 'sysadmin' + DateTime.now().getTime() + '@test.com',
            ProfileId = objProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            PMC_CPQ_SalesRegion__c = 'Global'
        );
        insert objUser;
        
        System.runAs(objUser) {
            // Create Opportunity
            List<Opportunity> lstOpp = PMC_TestUtilityClass.createOpportunity(1, 'Master');
            Opportunity opp = [SELECT AccountId FROM Opportunity WHERE Id = :lstOpp[0].Id LIMIT 1];

            // Ensure Account has Customer Type 'Sold-to' to satisfy custom validation
            Account acc = [SELECT Id, Type FROM Account WHERE Id = :opp.AccountId LIMIT 1];
            acc.Type = 'Sold-to';
            update acc;

            // Create Contact
            List<Contact> lstCon = PMC_TestUtilityClass.createContact(1, 'Master');

            // Create Quote manually to ensure success and required fields
            SBQQ__Quote__c objQuote = new SBQQ__Quote__c();
            objQuote.SBQQ__Opportunity2__c = opp.Id;
            objQuote.SBQQ__Account__c = opp.AccountId;
            objQuote.PMC_CPQ_ContractStart__c = System.today().addDays(3);
            objQuote.PMC_CPQ_ContractEnd__c = System.today().addDays(35);
            objQuote.SBQQ__PrimaryContact__c = lstCon[0].Id;
            objQuote.PMC_CPQ_PrimaryContact__c = lstCon[0].Id;
            objQuote.PMC_CPQ_CustomCreatedDate__c = System.now();
            insert objQuote;
        }
    }

    /**
     * @description Test covering postInfoToCPI and Queueable execute with success
     */
    @isTest
    static void testPostInfoToCPI() {
        User objUser = [SELECT Id FROM User WHERE LastName = 'System Administrator Test' LIMIT 1];

        System.runAs(objUser) {
            List<SBQQ__Quote__c> lstQuotes = [SELECT Id FROM SBQQ__Quote__c];
            System.assertNotEquals(0, lstQuotes.size(), 'Quotes should exist');

            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            
            Test.startTest();
            PMC_CPQ_QuoteContractCreateActionClass.postInfoToCPI(lstQuotes);
            Test.stopTest();
        }
    }

    /**
     * @description Test execute with response as null
     */
    @isTest
    static void testExecuteWithNullResponse() {
        User objUser = [SELECT Id FROM User WHERE LastName = 'System Administrator Test' LIMIT 1];

        System.runAs(objUser) {
            List<SBQQ__Quote__c> lstQuotes = [SELECT Id FROM SBQQ__Quote__c];
            System.assertNotEquals(0, lstQuotes.size(), 'Quotes should exist');
            
            List<Id> lstIds = new List<Id>();
            for(SBQQ__Quote__c q : lstQuotes) {
                lstIds.add(q.Id);
            }

            Test.setMock(HttpCalloutMock.class, new MockNullResponseGenerator());
            
            PMC_CPQ_QuoteContractCreateActionClass job = new PMC_CPQ_QuoteContractCreateActionClass(lstQuotes, lstIds);
            
            Test.startTest();
            System.enqueueJob(job);
            Test.stopTest();
        }
    }
}