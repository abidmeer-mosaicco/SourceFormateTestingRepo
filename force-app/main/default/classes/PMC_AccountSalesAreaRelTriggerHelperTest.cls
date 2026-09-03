/**
* @description This class is a test class for PMC_AccountSalesAreaRelTriggerHelper and PMC_AccountSalesAreaRelTriggerHandler
* @author Megha Sunhare
* @storynumber GDASF-1065
*/
@isTest(seeAllData=false)
private with sharing class PMC_AccountSalesAreaRelTriggerHelperTest {

    /**
     * @description Test Setup method to perpare data for the test class
     */
    @testsetup
    private static void testSetup(){
        
        List<Profile> userProfile = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce'];
        if(userProfile != null && !userProfile.isEmpty()) {
            List<User> lstUser = PMC_TestUtilityClass.createUser(1);
            if(lstUser != null && !lstUser.isEmpty()) {
                lstUser[0].ProfileId = userProfile[0].Id;
            }
            insert lstUser;
        }
        //Create Accounts of type Agent
        List<Account> lstAccountAgents = new List<Account>();
        Account objAgentAccountMosaic = PMC_TestUtilityClass.createAccount('The Mosaic Company', 'PMC_SS_Agent');
        Account objAgentAccountDeloitte = PMC_TestUtilityClass.createAccount('Deloitte', 'PMC_SS_Agent');
        lstAccountAgents.add(objAgentAccountMosaic);
        lstAccountAgents.add(objAgentAccountDeloitte);
        Integer i = 0;
        for(Account objAccount : lstAccountAgents){
            objAccount.Name = 'Account #'+i;
            objAccount.Type = 'Agents';
            i = i+1;
        }
        update lstAccountAgents;
        //Create Account record of type Customer
        List<Account> lstAccountCustomers = new List<Account>();
        Account objCustomerAccountDeloitte = PMC_TestUtilityClass.createAccount('Deloitte', 'PMC_SS_Customer');
        lstAccountCustomers.add(objCustomerAccountDeloitte);
        
        for(Account objAccount : lstAccountCustomers){
            objAccount.Name = 'Account #'+i;
            objAccount.Type = 'Sold-to';
            i = i+1;
        }
        update lstAccountCustomers;
        
        List<PMC_SS_SalesArea__c> lstSalesAreas= PMC_TestUtilityClass.createSalesArea(2, '');

        List<Account> lstAccounts = new List<Account>();
        lstAccounts.add(lstAccountAgents.get(0));
        List<PMC_SS_SalesArea__c> lstSalesAreas1 = new List<PMC_SS_SalesArea__c>();
        lstSalesAreas1.add(lstSalesAreas.get(0));
        
        //Create AccountSalesAreaRelationship account for Agent Account
        List<PMC_SS_AccountSalesAreaRelationship__c> lstAccountSalesAreaRelAgent = PMC_TestUtilityClass.createAccountSalesAreaRelationship(lstAccounts , lstSalesAreas1);
        for(PMC_SS_AccountSalesAreaRelationship__c objAccountSalesAreaRel : lstAccountSalesAreaRelAgent){
            objAccountSalesAreaRel.CurrencyIsoCode = 'USD';
        }		
        Update lstAccountSalesAreaRelAgent;
        //Create AccountSalesAreaRelationship account for Customer Account
        List<PMC_SS_AccountSalesAreaRelationship__c> lstAccountSalesAreaRelCustomer = PMC_TestUtilityClass.createAccountSalesAreaRelationship(lstAccountCustomers, lstSalesAreas1);
        for(PMC_SS_AccountSalesAreaRelationship__c objAccountSalesAreaRel : lstAccountSalesAreaRelCustomer){
            objAccountSalesAreaRel.CurrencyIsoCode = 'USD';
        }		
        Update lstAccountSalesAreaRelCustomer;
    }
    
    /**
     * @description this method is to test creation of first AccountSalesAreaRelationship for agent accounts
     */
    @isTest
    private static void testSingleAccountSAAssociationAgent(){

        test.startTest();
        Account objAccount = [SELECT Id, Name FROM Account WHERE Name = 'Account #1' AND RecordType.DeveloperName = 'PMC_SS_Agent' WITH SECURITY_ENFORCED LIMIT 1];
        PMC_SS_SalesArea__c objSalesArea = [SELECT Id, Name FROM PMC_SS_SalesArea__c WHERE Name = 'test Sales Area Name0' WITH SECURITY_ENFORCED LIMIT 1];
        
        PMC_SS_AccountSalesAreaRelationship__c objAccSARelationship = new PMC_SS_AccountSalesAreaRelationship__c();
        objAccSARelationship.PMC_SS_Account__c = objAccount.Id;
        objAccSARelationship.PMC_SS_SalesArea__c = objSalesArea.Id;

        insert objAccSARelationship;
        
        test.stopTest();

        List<PMC_SS_AccountSalesAreaRelationship__c> objAccSARelationshipUpdated = [SELECT Id FROM PMC_SS_AccountSalesAreaRelationship__c WHERE PMC_SS_Account__c = :objAccount.Id WITH SECURITY_ENFORCED];

        System.assertEquals(1, objAccSARelationshipUpdated.size(), 'Expected one accountSalesAreaRelationship record to be returned');

    }
    
    /**
     * @description this method is to test exception handling
     */
    @isTest
    private static void testSingleAccountSAAssociationException(){

        test.startTest();
        PMC_AccountSalesAreaRelTriggerHelper.boolThrowException = true;
        Account objAccount = [SELECT Id, Name FROM Account WHERE Name = 'Account #1' AND RecordType.DeveloperName = 'PMC_SS_Agent' WITH SECURITY_ENFORCED LIMIT 1];
        PMC_SS_SalesArea__c objSalesArea = [SELECT Id, Name FROM PMC_SS_SalesArea__c WHERE Name = 'test Sales Area Name0' WITH SECURITY_ENFORCED LIMIT 1];

        PMC_SS_AccountSalesAreaRelationship__c objAccSARelationship = new PMC_SS_AccountSalesAreaRelationship__c();
        objAccSARelationship.PMC_SS_Account__c = objAccount.Id;
        objAccSARelationship.PMC_SS_SalesArea__c = objSalesArea.Id;

        insert objAccSARelationship;             
        
        List<PMC_ErrorLog__c> objErrorLogs = [SELECT Id FROM PMC_ErrorLog__c];
        test.stopTest();
        
        System.assertEquals(0, objErrorLogs.size(), 'Expected error log object to be created');
    }

    /**
     * @description this method is to test creation of second AccountSalesAreaRelationship for agent accounts
     */
    @isTest
    private static void testSingleAccountSAAssociationAgentFail(){

        Boolean boolErrorCaught = false;

        test.startTest();
        Account objAccount = [SELECT Id, Name FROM Account WHERE Name = 'Account #0' AND RecordType.DeveloperName = 'PMC_SS_Agent' LIMIT 1];
        PMC_SS_SalesArea__c objSalesArea = [SELECT Id, Name FROM PMC_SS_SalesArea__c WHERE Name = 'test Sales Area Name1' WITH SECURITY_ENFORCED LIMIT 1];
        
        PMC_SS_AccountSalesAreaRelationship__c objAccSARelationship = new PMC_SS_AccountSalesAreaRelationship__c();
        objAccSARelationship.PMC_SS_Account__c = objAccount.Id;
        objAccSARelationship.PMC_SS_SalesArea__c = objSalesArea.Id;

        try{
            insert objAccSARelationship;
        }catch(Exception ex){
            boolErrorCaught = true;
        }

        test.stopTest();
		System.assertEquals(true, boolErrorCaught, 'Expected error on association of second AccountSalesAreaRelationship for Agent accounts');
    }

    /**
     * @description this method is to test creation of second AccountSalesAreaRelationship for agent accounts
     */
    @isTest
    private static void testSingleAccountSAAssociationCustomerAccount(){

        test.startTest();
        Account objAccount = [SELECT Id, Name FROM Account WHERE Name = 'Account #2' AND RecordType.DeveloperName = 'PMC_SS_Customer' WITH SECURITY_ENFORCED LIMIT 1];
        PMC_SS_SalesArea__c objSalesArea = [SELECT Id, Name FROM PMC_SS_SalesArea__c WHERE Name = 'test Sales Area Name1' WITH SECURITY_ENFORCED LIMIT 1];
        
        PMC_SS_AccountSalesAreaRelationship__c objAccSARelationship = new PMC_SS_AccountSalesAreaRelationship__c();
        objAccSARelationship.PMC_SS_Account__c = objAccount.Id;
        objAccSARelationship.PMC_SS_SalesArea__c = objSalesArea.Id;

        Database.insert(objAccSARelationship);
       
        test.stopTest();

        List<PMC_SS_AccountSalesAreaRelationship__c> objAccSARelationshipUpdated = [SELECT Id FROM PMC_SS_AccountSalesAreaRelationship__c WHERE PMC_SS_Account__c = :objAccount.Id WITH SECURITY_ENFORCED];

        System.assertEquals(2, objAccSARelationshipUpdated.size(), 'Expected two accountSalesAreaRelationship record to be returned');

    }

    /** 
    * @description This method is a test method for AccountSalesAreaRelationship delete operation
    */ 
    @isTest
    private static void testAccountSalesAreaRelationshipUpdate() {
        test.startTest();   
        PMC_AccountSalesAreaRelTriggerHandler.boolBypassTriggerLogic = true;
		PMC_SS_AccountSalesAreaRelationship__c objAccountSalesAreaRelationship = [SELECT Id, Name FROM PMC_SS_AccountSalesAreaRelationship__c WITH SECURITY_ENFORCED LIMIT 1];
        
        objAccountSalesAreaRelationship.CurrencyIsoCode = 'CAD';
        update objAccountSalesAreaRelationship;
        test.stopTest();

        LIST<PMC_SS_AccountSalesAreaRelationship__c> objAccountSalesAreaRelationshipDel = [SELECT Id, CurrencyIsoCode FROM PMC_SS_AccountSalesAreaRelationship__c WHERE Id = :objAccountSalesAreaRelationship.Id WITH SECURITY_ENFORCED LIMIT 1];

        System.assertEquals('CAD', objAccountSalesAreaRelationshipDel.get(0).CurrencyIsoCode, 'Expected SalesArea to be updated.');
    }

    /** 
    * @description This method is a test method for AccountSalesAreaRelationship delete operation
    */ 
    @isTest
    private static void testAccountSalesAreaRelationshipDelete() {
        test.startTest();   
        PMC_AccountSalesAreaRelTriggerHandler.boolBypassTriggerLogic = true;
		Account objAccount = [SELECT Id, Name FROM Account WHERE Name = 'Account #2' AND RecordType.DeveloperName = 'PMC_SS_Customer' WITH SECURITY_ENFORCED LIMIT 1];
        PMC_SS_AccountSalesAreaRelationship__c objAccountSalesAreaRelationship = [SELECT Id, Name FROM PMC_SS_AccountSalesAreaRelationship__c WHERE PMC_SS_Account__c = :objAccount.Id WITH SECURITY_ENFORCED LIMIT 1];
        Database.delete(objAccountSalesAreaRelationship.Id);

        test.stopTest();

        LIST<PMC_SS_AccountSalesAreaRelationship__c> objAccountSalesAreaRelationshipDel = [SELECT Id, Name FROM PMC_SS_AccountSalesAreaRelationship__c WHERE Id = :objAccountSalesAreaRelationship.Id WITH SECURITY_ENFORCED LIMIT 1];

        System.assertEquals(0, objAccountSalesAreaRelationshipDel.size(), 'Expected AccountSalesAreaRelationship record to be deleted');
    }

    /** 
    * @description This method is a test method for AccountSalesAreaRelationship  undelete operation
    */ 
    @isTest
    private static void testAccountSalesAreaRelationshipUndelete() {
        test.startTest(); 
        PMC_AccountSalesAreaRelTriggerHandler.boolBypassTriggerLogic = true;
		Account objAccount = [SELECT Id, Name FROM Account WHERE Name = 'Account #2' AND RecordType.DeveloperName = 'PMC_SS_Customer' WITH SECURITY_ENFORCED LIMIT 1];
        PMC_SS_AccountSalesAreaRelationship__c objAccountSalesAreaRelationship = [SELECT Id, Name FROM PMC_SS_AccountSalesAreaRelationship__c WHERE PMC_SS_Account__c = :objAccount.Id WITH SECURITY_ENFORCED LIMIT 1];
        Database.delete(objAccountSalesAreaRelationship.Id);
        Database.undelete(objAccountSalesAreaRelationship.Id);

        test.stopTest();

        LIST<PMC_SS_AccountSalesAreaRelationship__c> objAccountSalesAreaRelationshipDel = [SELECT Id, Name FROM PMC_SS_AccountSalesAreaRelationship__c WHERE Id = :objAccountSalesAreaRelationship.Id WITH SECURITY_ENFORCED LIMIT 1];

        System.assertEquals(1, objAccountSalesAreaRelationshipDel.size(), 'Expected AccountSalesAreaRelationship record to be restored');
    }
    
}