/**
* @description : Test class for PMC_DH_QuoteMgmtActionController
* @author      : Lohitha sai
* @Created on  : 06-21-2023
**/
@isTest
public with sharing class PMC_DH_QuoteMgmtActionControllerTest {
    /**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/
    @testSetup  static void setup()
    {
        Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
        
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
        
        
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strContactId=[SELECT contactId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1][0].contactId;
        Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet2);
        Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet);
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet1);
        Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet3);
        
        system.runAs(user){
            
            PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
            Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
           PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
            
        }
    }
    /**
* @description Test Method for getQuoteDetails method
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/
    @isTest
    public static void testGetCancelReasons(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            List<PMC_DH_PicklistWrapper> result = PMC_DH_QuoteMgmtActionController.getCancelReasons(); 
            System.assert(result!=null,'success');
        }
        Test.stopTest();
    }
    /**
* @description Test Method for getQuoteDetails method
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/
    @isTest
    public static void testGetRejectedReasons(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            List<PMC_DH_PicklistWrapper> result = PMC_DH_QuoteMgmtActionController.getRejectReasons();
            System.assert(result!=null,'success');
        }
        Test.stopTest();
    }
    /**
* @description Test Method for getQuoteDetails method
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/
    @istest
    public static void updateQuoteStatusTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            String strQuoteId=[SELECT ID FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote'][0].ID;
            PMC_DH_QuoteMgmtActionController.PMC_DH_ModelWrapper modelWrapper=new PMC_DH_QuoteMgmtActionController.PMC_DH_ModelWrapper();
            modelWrapper.strQuoteId=strQuoteId; 
            modelWrapper.strStatus='Accepted';
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result=PMC_DH_QuoteMgmtActionController.updateQuoteStatus(modelWrapper);
            system.Assert(result!=null,'Success');
        }
        Test.stopTest();
    }
    /**
* @description Test Method for getQuoteDetails method
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/
    @istest
    public static void updateQuoteStatusRejectedTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            String strQuoteId=[SELECT ID FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote'][0].ID;
            PMC_DH_QuoteMgmtActionController.PMC_DH_ModelWrapper modelWrapper=new PMC_DH_QuoteMgmtActionController.PMC_DH_ModelWrapper();
            modelWrapper.strQuoteId=strQuoteId; 
            modelWrapper.strStatus='Rejected';
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result=PMC_DH_QuoteMgmtActionController.updateQuoteStatus(modelWrapper);
            system.Assert(result!=null,'Success');
        }
        Test.stopTest();
    }
       /**
* @description Test Method for getQuoteDetails method
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/
    @istest
    public static void updateQuoteStatusReasonTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            String strQuoteId=[SELECT ID FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote'][0].ID;
            PMC_DH_QuoteMgmtActionController.PMC_DH_ModelWrapper modelWrapper=new PMC_DH_QuoteMgmtActionController.PMC_DH_ModelWrapper();
            modelWrapper.strQuoteId=strQuoteId; 
            modelWrapper.strStatus='Rejected';
            modelWrapper.strSelectedReason='Other';
            modelWrapper.strReason='Testing';
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result=PMC_DH_QuoteMgmtActionController.updateQuoteStatus(modelWrapper);
            system.Assert(result!=null,'Success');
        }
        Test.stopTest();
    }
}