/**
* @description : Test class for PMC_DH_QuoteManagementController
* @author      : Nikhilesh
* @userStory   : GDASF-104
* @last modified by Nikhilesh
* @last modified on 2023-July-04
**/
@isTest
public with sharing class PMC_DH_ContractManagementControllerTest {
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
        PMC_ProcessSwitches__c bypass = PMC_ProcessSwitches__c.getOrgDefaults();
        bypass.PMC_BypassFlow__c = true;
        upsert bypass;

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
        // Id lstPermSet4=[select id from PermissionSet where Name ='CRED_Product'][0].id;
        // PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet4);
        PMC_DH_TestDataFactoryClass.createTestAccountTeamMember(acc.Id, user.id, PMC_DH_ConstantClass.ACCOUNT_TEAMMEMBERACC);
        
        WebStore webStore=PMC_DH_TestDataFactoryClass.createTestWebStore();
        system.runAs(user){
            WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
            insert cartObj;
            
            Account strShipToAcc = PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            insert prod;
            
            Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
            Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
            PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
            SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,prod);
			testQuoteLine.PMC_CPQ_ShipTo__c = strShipToAcc.Id;
            update testQuoteLine;
            
            Test.startTest();
            Contract testContract=PMC_DH_TestDataFactoryClass.createContract(testQuote.id,acc.id); 
            PMC_DH_TestDataFactoryClass.CartItemObject objCartItem=new PMC_DH_TestDataFactoryClass.CartItemObject();
            objCartItem.strAccId = acc.Id;
            objCartItem.strContractId = testContract.Id;
            objCartItem.strQuoteLineId = testQuoteLine.Id;
            objCartItem.strProductId=prod.id;
            objCartItem.strCartId = cartObj.id;
            PMC_DH_TestDataFactoryClass.createSubscription(objCartItem);
            Test.stopTest();
        }
    } 
    /**
* @description Test Method for getQuoteDetails method of Helper class
* 
* @param: none
* 
* @return: void
*
* @author Nikhilesh
* 
*/
    @isTest
    public static void getQuoteDetailsTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
            SBQQ__Quote__c testQuote = [SELECT Id, PMC_CPQ_ContractStageName__c,PMC_CPQ_QuoteShortNameDescription__c FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c = 'TestDH Quote'][0];
            testQuote.PMC_CPQ_ContractStageName__c = 'Pending Signature';
            update testQuote;
            PMC_DH_ContractDetailsWrapper result = PMC_DH_ContractManagementController.getContractDetails(PMC_DH_ConstantClass.TEST_COMMUNITYID,strTestAcct.Id,testQuote.Id);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    /**
* @description Test Method for getContractDetails method
* 
* @param: none
* 
* @return: void
*
* @author Nikhilesh
* 
*/
    @isTest
    public static void getContractDetailsTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
            Contract testContract = [SELECT ID, Status FROM Contract WHERE SBQQ__Quote__r.PMC_CPQ_QuoteShortNameDescription__c = 'TestDH Quote'][0];
            testContract.Status='Activated';
            update testContract;
            PMC_DH_ContractDetailsWrapper result = PMC_DH_ContractManagementController.getContractDetails(PMC_DH_ConstantClass.TEST_COMMUNITYID,strTestAcct.Id ,testContract.Id);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    /**
* @description Test Exception Method for getContractDetails method
* 
* @param: none
* 
* @return: void
*
* @author Nikhilesh
* 
*/
    @isTest
    public static void getContractDetailsTestException(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Boolean exceptionOccurred=true;
            try{
                Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
                String strContractId;
                PMC_DH_ContractManagementController.getContractDetails(PMC_DH_ConstantClass.TEST_COMMUNITYID,strTestAcct.Id ,strContractId);
            }
            catch(exception e){
                exceptionOccurred=true;
            }            
            System.assert(exceptionOccurred, 'An Exception was not thrown');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for updateContractPoNumber method
* 
* @param: none
* 
* @return: void
*
* @author Nikhilesh
* 
*/
    @isTest
    public static void updateContractPoNumberTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            String strQuoteId = [SELECT Id FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote'][0].Id;
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_ContractManagementController.updateContractPoNumber(strQuoteId, 'Test PO Number');
            system.assertEquals(result.strStatusCode, '000', 'Success');
        }
        Test.stopTest();
    }
    /**
* @description Test Exception Method for updateContractPoNumber method
* 
* @param: none
* 
* @return: void
*
* @author Nikhilesh
* 
*/
    @isTest
    public static void updateContractPoNumberTestException(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Boolean exceptionOccurred=true;
            try{
                String strQuoteId;
                PMC_DH_ContractManagementController.updateContractPoNumber(strQuoteId, 'Test PO Number');
            }
            catch(exception e){
                exceptionOccurred=true;
            }            
            System.assert(exceptionOccurred, 'An Exception was not thrown');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for contractRequestSignature method
* @author lohitha
* 
*/
    @isTest
    public static void contractRequestSignatureTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            
            SBQQ__Quote__c quoteRecord = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote'];
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_ContractManagementController.contractRequestSignature(quoteRecord.SBQQ__Account__c , quoteRecord.Id);
            system.assertEquals('000', result.strStatusCode, 'Success');
        }
        Test.stopTest();
        
    }
    /**
* @description Test Excption Method for contractRequestSignature method
* @author lohitha
* 
*/
    @isTest
    public static void contractRequestSignatureTestException(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Boolean exceptionOccurred=true;
            try{
                SBQQ__Quote__c quoteRecord = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote'];
                PMC_DH_ContractManagementController.contractRequestSignature(quoteRecord.Id , quoteRecord.Id);
                
            }
            catch(exception e){
                exceptionOccurred=true;
            }            
            System.assert(exceptionOccurred, 'An Exception was not thrown');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for getContractDetails method for Amended contracts
* 
* @param: none
* 
* @return: void
*
* @author Nikhilesh
* 
*/
    @isTest
    public static void getAmendedContractDetailsTest(){
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
            SBQQ__Quote__c testQuote = [SELECT Id, SBQQ__Type__c FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c = 'TestDH Quote' LIMIT 1];
            testQuote.SBQQ__Type__c = 'Amendment';
            update testQuote;

            Contract testContract = [SELECT Id, PMC_CPQ_LatestQuote__c FROM Contract WHERE SBQQ__Quote__c = :testQuote.Id LIMIT 1];
            testContract.PMC_CPQ_LatestQuote__c = testQuote.Id;
            update testContract;

            Test.startTest();
            PMC_DH_ContractDetailsWrapper result = PMC_DH_ContractManagementController.getContractDetails(PMC_DH_ConstantClass.TEST_COMMUNITYID, strTestAcct.Id, testContract.Id);
            Test.stopTest();

            System.assertNotEquals(null, result, 'A tela de contrato deve responder para contrato com amendment');
        }
    }

    @isTest
    public static void test_getContractSummary() {
        // Get required contract and cart ID from test setup data
        Contract testContract = [SELECT Id FROM Contract WHERE SBQQ__Quote__r.PMC_CPQ_QuoteShortNameDescription__c = 'TestDH Quote' LIMIT 1];
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];

        Test.startTest();
        PMC_DH_RequestToDeliverWrapper.ContractSummaryWrapper wrapper = PMC_DH_ContractManagementHelper.getContractSummary(testContract.Id, cart.Id);
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
    }

}