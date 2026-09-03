/**
 * @description Test class for PMC_CPQ_NoCalcUpdateInvocable.
 * @author Raphael Soares
 * @storynumber back-to-draft-fix
 */
@isTest(seeAllData = false)
private with sharing class PMC_CPQ_NoCalcUpdateInvocableTest {

    @TestSetup
    static void setup() {
        List<String> lstProfileNames = new List<String>{ 'System Administrator', 'Sales User' };
        List<String> lstPermissionSetGroupNames = new List<String>{ 'PMC_Administrator_Permission_Set_Group', 'PMC_SLS_Permission_Set_Group' };
        Map<String, Id> mapProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
        Map<String, PermissionSetGroup> mapPermGroups = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionSetGroupNames);

        Integer intUserCount = 0;
        User objSystemAdminUser;
        User objSalesUser;
        List<User> lstUsers = PMC_TestUtilityClass.createUser(2);
        for (User objUser : lstUsers) {
            if (intUserCount == 0) {
                objUser.LastName = 'Admin User Test';
                objUser.ProfileId = mapProfiles.get('System Administrator');
                objUser.FederationIdentifier = objUser.Username + 'Admin';
            } else if (intUserCount == 1) {
                objUser.LastName = 'Sales User Test';
                objUser.ProfileId = mapProfiles.get('Sales User');
                objUser.FederationIdentifier = objUser.Username + 'Sales';
            }
            objUser.isActive = true;
            objUser.MobilePhone = '1234567890';
            objUser.UserPermissionsKnowledgeUser = true;
            objUser.LanguageLocaleKey = 'en_US';
            objUser.PMC_CPQ_SalesRegion__c = 'North America';
            objUser.PMC_CPQ_PrimaryBusinessType__c = 'Feed';
            objUser.PMC_CPQ_SalesArea__c = 'Mosaic Global Sales LLC Domestic Common';
            intUserCount++;
        }
        insert lstUsers;
        objSystemAdminUser = lstUsers[0];
        objSalesUser = lstUsers[1];
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(
            new List<User>{ objSystemAdminUser },
            mapPermGroups.get('PMC_Administrator_Permission_Set_Group')
        );
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(
            new List<User>{ objSalesUser },
            mapPermGroups.get('PMC_SLS_Permission_Set_Group')
        );

        System.runAs(objSystemAdminUser) {
            List<PMC_SS_SalesArea__c> lstSalesArea = PMC_TestUtilityClass.createSalesArea(1, 'Master');
            lstSalesArea[0].PMC_SS_SalesOrganization__c = 'Mosaic Global Sales LLC';
            lstSalesArea[0].PMC_CPQ_SAPSalesOrganization__c = '10020010';
            lstSalesArea[0].PMC_SS_DistributionChannel__c = '00';
            lstSalesArea[0].PMC_SS_Division__c = '10';
            update lstSalesArea;
        }
    }

    @isTest
    static void updateWithoutCalc_handlesNullRequest() {
        Test.startTest();
        try {
            PMC_CPQ_NoCalcUpdateInvocable.updateWithoutCalc(null);
        } catch (Exception e) {
            System.assert(false, 'null request should not throw: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void updateWithoutCalc_handlesEmptyRequest() {
        Test.startTest();
        try {
            PMC_CPQ_NoCalcUpdateInvocable.updateWithoutCalc(new List<PMC_CPQ_NoCalcUpdateInvocable.Request>());
        } catch (Exception e) {
            System.assert(false, 'empty request should not throw: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void updateWithoutCalc_handlesRequestWithNullFields() {
        List<PMC_CPQ_NoCalcUpdateInvocable.Request> lstRequests = new List<PMC_CPQ_NoCalcUpdateInvocable.Request>{
            new PMC_CPQ_NoCalcUpdateInvocable.Request()
        };

        Test.startTest();
        try {
            PMC_CPQ_NoCalcUpdateInvocable.updateWithoutCalc(lstRequests);
        } catch (Exception e) {
            System.assert(false, 'request with null fields should not throw: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void updateWithoutCalc_updatesQuoteSuccessfully() {
        List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];
        System.runAs(lstUser[0]) {
            List<SBQQ__Quote__c> lstQuotes = PMC_CPQ_SetPriceResourceTest.createQuotes(1, lstUser);

            SBQQ__Quote__c objQuoteToUpdate = new SBQQ__Quote__c(
                Id = lstQuotes[0].Id,
                PMC_CPQ_IntegrationMessage__c = 'Updated via invocable test'
            );
            PMC_CPQ_NoCalcUpdateInvocable.Request req = new PMC_CPQ_NoCalcUpdateInvocable.Request();
            req.quote = objQuoteToUpdate;

            Test.startTest();
            PMC_CPQ_NoCalcUpdateInvocable.updateWithoutCalc(
                new List<PMC_CPQ_NoCalcUpdateInvocable.Request>{ req }
            );
            Test.stopTest();

            SBQQ__Quote__c objAfter = [
                SELECT PMC_CPQ_IntegrationMessage__c FROM SBQQ__Quote__c WHERE Id = :lstQuotes[0].Id
            ];
            System.assertEquals(
                'Updated via invocable test',
                objAfter.PMC_CPQ_IntegrationMessage__c,
                'Quote should have been updated by the invocable'
            );
        }
    }

    @isTest
    static void updateWithoutCalc_updatesQuoteLinesSuccessfully() {
        List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];
        System.runAs(lstUser[0]) {
            List<SBQQ__Quote__c> lstQuotes = PMC_CPQ_SetPriceResourceTest.createQuotes(1, lstUser);
            List<SBQQ__QuoteLine__c> lstQuoteLines = [
                SELECT Id, PMC_CPQ_FinalPricePerTon__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :lstQuotes[0].Id
            ];
            System.assert(!lstQuoteLines.isEmpty(), 'Setup should have created a quote line');

            for (SBQQ__QuoteLine__c objQl : lstQuoteLines) {
                objQl.PMC_CPQ_FinalPricePerTon__c = 99.99;
            }
            PMC_CPQ_NoCalcUpdateInvocable.Request req = new PMC_CPQ_NoCalcUpdateInvocable.Request();
            req.quoteLines = lstQuoteLines;

            Test.startTest();
            PMC_CPQ_NoCalcUpdateInvocable.updateWithoutCalc(
                new List<PMC_CPQ_NoCalcUpdateInvocable.Request>{ req }
            );
            Test.stopTest();

            List<SBQQ__QuoteLine__c> lstAfter = [
                SELECT PMC_CPQ_FinalPricePerTon__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :lstQuotes[0].Id
            ];
            System.assertEquals(
                99.99,
                lstAfter[0].PMC_CPQ_FinalPricePerTon__c,
                'QuoteLine should have been updated by the invocable'
            );
        }
    }

    @isTest
    static void updateWithoutCalc_updatesQuoteAndLinesInSameRequest() {
        List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];
        System.runAs(lstUser[0]) {
            List<SBQQ__Quote__c> lstQuotes = PMC_CPQ_SetPriceResourceTest.createQuotes(1, lstUser);
            List<SBQQ__QuoteLine__c> lstQuoteLines = [
                SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :lstQuotes[0].Id
            ];

            SBQQ__Quote__c objQuoteToUpdate = new SBQQ__Quote__c(
                Id = lstQuotes[0].Id,
                PMC_CPQ_IntegrationMessage__c = 'Combined update'
            );
            for (SBQQ__QuoteLine__c objQl : lstQuoteLines) {
                objQl.PMC_CPQ_FinalPricePerTon__c = 55.55;
            }
            PMC_CPQ_NoCalcUpdateInvocable.Request req = new PMC_CPQ_NoCalcUpdateInvocable.Request();
            req.quote = objQuoteToUpdate;
            req.quoteLines = lstQuoteLines;

            Test.startTest();
            PMC_CPQ_NoCalcUpdateInvocable.updateWithoutCalc(
                new List<PMC_CPQ_NoCalcUpdateInvocable.Request>{ req }
            );
            Test.stopTest();

            SBQQ__Quote__c objQuoteAfter = [
                SELECT PMC_CPQ_IntegrationMessage__c FROM SBQQ__Quote__c WHERE Id = :lstQuotes[0].Id
            ];
            List<SBQQ__QuoteLine__c> lstLinesAfter = [
                SELECT PMC_CPQ_FinalPricePerTon__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :lstQuotes[0].Id
            ];

            System.assertEquals('Combined update', objQuoteAfter.PMC_CPQ_IntegrationMessage__c);
            System.assertEquals(55.55, lstLinesAfter[0].PMC_CPQ_FinalPricePerTon__c);
        }
    }
}