/**
* @description : Test class for PMC_DH_ContractListViewController
* @author      : Lohitha Sai
* @Created on   07/17/2023
**/
@IsTest
public with sharing class PMC_DH_ContractListViewTest {
         /**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* @param: none
* @return: void
* @author Lohitha
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
        WebStore webStore=PMC_DH_TestDataFactoryClass.createTestWebStore();
        system.runAs(user){
            
            //Account shipToAcc = PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            insert prod;
            Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
            
            PMC_CPQ_ProductLocation__c prodLocation = PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
            Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            Test.startTest();
            SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
            
            SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,prod);
            
            testQuote.PMC_CPQ_CustomerAcceptanceMethod__c = 'Accepted by DH Customer';
            testQuote.SBQQ__Status__c = 'approved';
        	testQuote.ApprovalStatus__c = 'approved';
            update testQuote;
            /*testQuote.SBQQ__Status__c = 'Presented';
            update testQuote;
            testQuote.SBQQ__Status__c = 'Accepted';
            update testQuote;*/
            
            Contract testContract = PMC_DH_TestDataFactoryClass.createContract(testQuote.Id,acc.Id);
            testContract.Status = 'Activated';
            update testContract;
            // PMC_DH_TestDataFactoryClass.createContract(testQuote.Id,acc.Id);
            WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
            insert cartObj;
            //PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj.id);
            //insert testCartDeliveryGroup;
            PMC_DH_TestDataFactoryClass.CartItemObject objCartItem=new PMC_DH_TestDataFactoryClass.CartItemObject();
            objCartItem.strCartId=cartObj.id;
            objCartItem.strProductId=prod.id;
           // objCartItem.strDeliveryGroupId=testCartDeliveryGroup.id;
            //objCartItem.strShipToAccId=shipToAcc.id;
            objCartItem.strShipFromId=prodLocation.id;
            objCartItem.strQuoteLineId = testQuoteLine.Id;
            objCartItem.strContractId = testContract.Id; // new line added
            PMC_DH_TestDataFactoryClass.createSubscription(objCartItem);
            Test.stopTest();
        }
    }
    /**
* @description Test Method for getContractRecords
* @param: none
* @return: void
* @author Lohitha
*/
@isTest
    public static void testGetContractRecords()
    {
        Test.startTest();
        SBQQ__Quote__c testQuote = [SELECT id, PMC_CPQ_QuoteShortNameDescription__c, SBQQ__Status__c FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote'];
        testQuote.SBQQ__Status__c = 'Accepted';
        update testQuote;
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Account acc = [SELECT Id,Name FROM Account Where Name='Parent Test Account' LIMIT 1];
        system.runAs(user){
            Date datToday = Date.today();
            Date datYesterday = datToday.addDays(-2);
            Date datTomm = datToday.addDays(15);
            PMC_DH_ContractListViewController.ContractSearchParameterWrapper searchWrapper = new PMC_DH_ContractListViewController.ContractSearchParameterWrapper();
            searchWrapper.strSearchTerm = 'CIF';
            searchWrapper.datFromDate = datYesterday;
            searchWrapper.datToDate = datTomm;
            PMC_DH_ContractListViewWrapper result = PMC_DH_ContractListViewController.getContractRecords(searchWrapper , acc.Id);
            searchWrapper.strSearchTerm = '';
            PMC_DH_ContractListViewController.getContractRecords(searchWrapper , acc.Id);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
}