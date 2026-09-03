/**
* @description This is the test class for the controller class for Advanced Approvals on SBQQ__Quote__c
*/
@isTest
public class PMC_CPQ_QuoteExtControllerTest {
    /*
* This Method will be used to setup the data for the test class execution.
*/   
    @TestSetup
    private static void testSetup(){
        List<String>lstPermissionNames = New List<String>{'PMC_SLS_Permission_Set_Group'};
            User objUserAM = PMC_CPQ_CPIRemoteCalloutUtilityTest.createCPQTestUser('Sales User',lstPermissionNames);
        system.runAs(objUserAM){
            List<Contact> lstContacts = PMC_TestUtilityClass.createContact(1,'Master');
            List<Opportunity> lstOpty = PMC_TestUtilityClass.createOpportunity(1,'Master');
            Account objAccount = [select Id from Account where Id =: lstOpty.get(0).AccountId];
            objAccount.PMC_SS_AccountExternalID__c = '5389521474';
            objAccount.PMC_SS_SAPCustomerNumber__c = '5389521474';
            update objAccount;
            List<SBQQ__Quote__c> lstquote = PMC_TestUtilityClass.createCPQQuotes(1,lstOpty,lstContacts);
            lstquote[0].PMC_CPQ_ContactPhone__c = '6298123489';
            update lstquote;
        }
    }
    /*
* This Method will be used to test the Submit for Approval Functionality.
*/   
    @istest
    public static void testSubmit() {
        User objUserAM = [select Id from User where LastName = 'Sales User Test' LIMIT 1 ];
        system.runAs(objUserAM){
            List<SBQQ__Quote__c> lstquote = [select Id from SBQQ__Quote__c];
            if(!lstquote.isEmpty()){
                Test.startTest();
                QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(lstquote[0]));
                con.onSubmit();
                SBQQ__Quote__c quote = [SELECT ApprovalStatus__c,PMC_CPQ_PrimaryContact__c FROM SBQQ__Quote__c WHERE Id =: lstquote[0].Id LIMIT 1];
                Test.stopTest();
            	System.assertEquals('Approved', quote.ApprovalStatus__c, 'Error in approving Quote');
            }
        }
    }
    /*
* This Method will be used to test the Recall Approval Functionality.
*/   
    @isTest
    public static void testRecall() {
        User objUserAM = [select Id from User where LastName = 'Sales User Test' LIMIT 1 ];
        system.runAs(objUserAM){
            List<SBQQ__Quote__c> lstquote = [select Id from SBQQ__Quote__c];
            if(!lstquote.isEmpty()){
                Test.startTest();
                QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(lstquote[0]));
                con.onRecall();
                SBQQ__Quote__c quote = [SELECT ApprovalStatus__c,PMC_CPQ_PrimaryContact__c  FROM SBQQ__Quote__c WHERE Id = :lstquote[0].Id LIMIT 1];
                Test.stopTest();
            	System.assertEquals('Recalled', quote.ApprovalStatus__c, 'Error in recalling Quote');
            }
        }
    }
}