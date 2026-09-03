/**
 * @description       : Test Class for Delegated Account Access Batch Job
 * @author            : Rohan Undale
 * @created on        : 11-23-2023
 * @group             : Mosaic Direct
 * @last modified on  : 02-13-2024
 * @last modified by  : Rohan Undale
**/
@isTest
public with sharing class PMC_DH_DelegatedAccountAccessBatchTest {
	@TestSetup
    static void testSetup()
    {
        PMC_DH_TestDataFactoryClass.createPortalUser();
    }
    
    /**
    * @description       : Test Class method for Delegated Account Access Batch Job
    * @author            : Rohan Undale
    * @created on        : 11-23-2023
    **/
    @isTest
    public static void testExecuteBatch()
    {
        Contact con = [SELECT Id FROM Contact WHERE Email = 'demouser@test.com' LIMIT 1];
        Account acc = new Account(
            Name = 'Test Account for Delegated Account Access',
            Type = 'Sold-to',
            AccountNumber = '123456708'
        );
        Database.insert(acc);
        AccountContactRelation acr = new AccountContactRelation();
        acr.ContactId = con.Id;
        acr.AccountId = acc.Id;
        insert acr;
        
		PMC_DH_DelegatedAccountAccessBatch batchJob=new PMC_DH_DelegatedAccountAccessBatch();
     	
        Test.startTest();
        Database.executeBatch(batchJob);
        Test.stopTest();
        List<DelegatedAccount> lstDelegatedAccount = [SELECT Id, ParentId, TargetId, ManagedById FROM DelegatedAccount];
        system.Assert(lstDelegatedAccount.Size() > 0, 'Success');
    }
    
    /**
    * @description       : Test Class method for Delegated Account Access Batch Job
    * @author            : Rohan Undale
    * @created on        : 11-23-2023
    **/
    /*@isTest
    public static void testFinishBatch()
    {
        Contact con = [SELECT Id FROM Contact WHERE Email = 'demouser@test.com' LIMIT 1];
        Account acc = new Account(
            Name = 'TestAccount',
            Type = 'Sold-to',
            AccountNumber = '123456708'
        );
        Database.insert(acc);
        AccountContactRelation acr = new AccountContactRelation();
        acr.ContactId = con.Id;
        acr.AccountId = acc.Id;
        insert acr;
        
        User objUser = [SELECT Id, AccountId, ContactId
                        FROM User
                        WHERE ContactId =: con.Id];
        DelegatedAccount objDelegatedAccount = new DelegatedAccount();
        objDelegatedAccount.Name = 'Account '+ acc.Id + objUser.Id;
        objDelegatedAccount.TargetId = acc.Id;
        objDelegatedAccount.ManagedById = objUser.Id;
        objDelegatedAccount.AccessBuyFor = true;
        objDelegatedAccount.AccessManageUsers = true;
        insert objDelegatedAccount;
        
        Test.startTest();
		PMC_DH_DelegatedAccountAccessBatch batchJob=new PMC_DH_DelegatedAccountAccessBatch();
        
        List<AccountContactRelation> lstAccountContactRelation = [SELECT Id, AccountId, ContactId, PMC_DH_isProcessed__c FROM AccountContactRelation];
        Database.Delete(lstAccountContactRelation, false);
        
        Database.executeBatch(batchJob);
        Test.stopTest();
        List<DelegatedAccount> lstDelegatedAccount = [SELECT Id, ParentId, TargetId, ManagedById FROM DelegatedAccount];
        system.Assert(lstDelegatedAccount.Size() == 0, 'Success');
    }*/
}