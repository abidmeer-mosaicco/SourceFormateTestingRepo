/**
* @description : Test class for PMC_DH_ContractManagementHelper
* @author      : Rohan
* @userStory   : GDASF-15397
* @last modified by Rohan
* @last modified on 2023-Oct-16
**/
@isTest
public with sharing class PMC_DH_ContractManagementHelperTest {
    /**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/
    @testSetup  static void setup()
    {
        Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
        WebStore webStore=PMC_DH_TestDataFactoryClass.createTestWebStore();
        Webcart wr = PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
        insert wr;
        CartDeliveryGroup testCartDeliveryGroup=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(wr.id);
        insert testCartDeliveryGroup;
        
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
        PMC_DH_TestDataFactoryClass.createTestAccountTeamMember(acc.Id, user.id, PMC_DH_ConstantClass.ACCOUNT_TEAMMEMBERACC);
        
        system.runAs(user){
            
            PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            insert prod;
            Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
            Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
            PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
            Test.startTest();

            SBQQ__QuoteLine__c testQuoteLine=new SBQQ__QuoteLine__c();
            testQuoteLine.SBQQ__Product__c = prod.id;
            testQuoteLine.SBQQ__Quantity__c = 25;
            testQuoteLine.PMC_CPQ_Incoterms1__c = 'CIF';
            testQuoteLine.PMC_CPQ_ModeofTransportation__c = 'Vessel';
            testQuoteLine.PMC_CPQ_ContractType__c = 'Priced';
            testQuoteLine.SBQQ__Quote__c = testQuote.id;
            testQuoteLine.PMC_CPQ_QuoteRecordType__c = 'Domestic NA';
            testQuoteLine.PMC_CPQ_QuoteRecordSubType__c = 'Feed';
            testQuoteLine.PMC_CPQ_FinalPricePerTonne__c = 20;
            testQuoteLine.PMC_CPQ_CustomerPrice__c = 20;
            testQuoteLine.PMC_CPQ_UnitofMeasure__c = 'MTN';
            testQuoteLine.PMC_CPQ_PackType__c = 'Packed';
            testQuoteLine.PMC_CPQ_PackageType__c = 'Saco 50 kg';
            testQuoteLine.PMC_CPQ_VCOQuotation__c = true;
			insert testQuoteLine;
            
           	Contract testContract=PMC_DH_TestDataFactoryClass.createContract(testQuote.id,acc.id); 
            PMC_DH_TestDataFactoryClass.CartItemObject objCartItem=new PMC_DH_TestDataFactoryClass.CartItemObject();
            objCartItem.strAccId = acc.Id;
            objCartItem.strContractId = testContract.Id;
            objCartItem.strQuoteLineId = testQuoteLine.Id;
            objCartItem.strProductId=prod.id;
            objCartItem.strCartId = wr.Id;
            SBQQ__Subscription__c sub = PMC_DH_TestDataFactoryClass.createSubscription(objCartItem);
            CartItem cartItem=PMC_DH_TestDataFactoryClass.buildCartItem(wr.id, prod.id,testCartDeliveryGroup.Id);
        	cartItem.PMC_DH_Subscription__c = sub.Id;
            insert cartItem;
            Test.stopTest();
        }
    } 
        
    /**
* @description Test Method for getContractSummary method
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/
    @isTest
    public static void getContractSummaryTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            WebCart objCart = [SELECT ID FROM WebCart LIMIT 1];
            Contract testContract = [SELECT ID, Status FROM Contract WHERE SBQQ__Quote__r.PMC_CPQ_QuoteShortNameDescription__c = 'TestDH Quote'][0];
            testContract.Status='Activated';
            update testContract;
            PMC_DH_RequestToDeliverWrapper.ContractSummaryWrapper result = PMC_DH_ContractManagementHelper.getContractSummary(testContract.Id, objCart.Id);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    /**
* @description Test Exception Method for getContractSummary method
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/
    @isTest
    public static void getContractSummaryTestException(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Boolean exceptionOccurred=true;
            try{
                Contract testContract = [SELECT ID, Status FROM Contract WHERE SBQQ__Quote__r.PMC_CPQ_QuoteShortNameDescription__c = 'TestDH Quote'][0];
                testContract.Status='Activated';
                update testContract;
                PMC_DH_ContractManagementHelper.getContractSummary(testContract.Id, 'xyz');
            }
            catch(exception e){
                exceptionOccurred=true;
            }            
            System.assert(exceptionOccurred, 'An Exception was not thrown');
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
* @author Rohan
* 
*/
    @isTest
    public static void getQuoteDetailsTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            PMC_DH_ContractDetailsWrapper result = PMC_DH_ContractManagementHelper.getQuoteDetails('', '', '');
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for getLineItemQty method
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/
    @isTest
    public static void getLineItemQtyTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Decimal result = PMC_DH_ContractManagementHelper.getLineItemQty(10.0);
            system.Assert(result==10.0, 'Success');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for getLineItemAmount method
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/
    @isTest
    public static void getLineItemAmountTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            SBQQ__Subscription__c subItem = [SELECT Id, SBQQ__QuoteLine__r.PMC_CPQ_LineTotalPrice__c FROM SBQQ__Subscription__c LIMIT 1];
            Decimal result = PMC_DH_ContractManagementHelper.getLineItemAmount(subItem);
            system.Assert(result!=Null, 'Success');
        }
        Test.stopTest();
    }
    
    @isTest
    public static void shouldGetQuoteDetails() {
        
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c,SBQQ__Type__c, Name, PMC_CPQ_PO__c, PMC_CPQ_PrimaryContact__r.Name, PMC_CPQ_ContractStart__c, PMC_CPQ_ContractEnd__c, SBQQ__PaymentTerms__c, PMC_DH_PaymentMethod__c, CurrencyIsoCode, 
                                (SELECT Id, SBQQ__Quantity__c, PMC_CPQ_ShipTo__r.Name, PMC_CPQ_ShipTo__r.ShippingStreet, PMC_CPQ_ShipTo__r.ShippingCity, PMC_CPQ_ShipTo__r.ShippingState, PMC_CPQ_ShipTo__r.ShippingPostalCode, PMC_CPQ_ShipTo__c, PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name, PMC_CPQ_ProductLocation__c, PMC_CPQ_ContractType__c, PMC_CPQ_ModeofTransportation__c, PMC_CPQ_Incoterms1__c, PMC_CPQ_UnitofMeasure__c, PMC_CPQ_PackType__c, PMC_CPQ_PackageType__c, SBQQ__Product__r.StockKeepingUnit FROM SBQQ__LineItems__r ) 
                                FROM SBQQ__Quote__c LIMIT 1];
        
        WebStore storeRec = PMC_DH_TestDataFactoryClass.createTestWebStore();
        
        Test.startTest();
        PMC_DH_ContractManagementHelper.getQuoteSummary(quote);
        PMC_DH_ContractManagementHelper.getQuotePaymentInfo(quote);
        PMC_DH_ContractManagementHelper.getQuoteLineItemDetails(quote);
        PMC_DH_ContractManagementHelper.getQuoteProductInfo(storeRec.Id, '', quote);
        PMC_DH_ContractManagementHelper.getQuoteOfOrigin(quote);
        Test.stopTest();
        
    }
}