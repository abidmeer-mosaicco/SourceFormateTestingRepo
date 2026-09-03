/**
* @description : Test class for PMC_DH_OrderListViewController
* @author      : Lohitha Sai
* @Created on   07/31/2023
**/
@IsTest
public with sharing class PMC_DH_OrderListViewTest {
     /**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* @param: none
* @return: void
* @author Lohitha
*/
    @testSetup  static void setup()
    {
        // test class fixes
        Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
        
        Profile profile = [SELECT Id FROM Profile WHERE Name =:PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
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
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            insert prod;
            Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
            SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,prod);
            Test.startTest();
           	Contract testContract=PMC_DH_TestDataFactoryClass.createContract(testQuote.id,acc.id); 
            testContract.Status='Activated';
            update testContract;
            
            WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
            cartObj.PMC_DH_PaymentMethod__c = 'PO';
            insert cartObj;
            
            CartDeliveryGroup testCartDeliveryGroup=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj.id);
            insert testCartDeliveryGroup;
            CartItem cartItem=PMC_DH_TestDataFactoryClass.buildCartItem(cartObj.id, prod.id,testCartDeliveryGroup.Id);
            cartItem.PMC_DH_Contract__c = testContract.Id;
            insert cartItem;
            
            Account shipToAcc=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
            Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
            PMC_CPQ_ProductLocation__c prodLocation = PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
            PMC_DH_TestDataFactoryClass.CartItemObject objCartItem=new PMC_DH_TestDataFactoryClass.CartItemObject();
            objCartItem.strCartId=cartObj.id;
            objCartItem.strProductId=prod.id;
            objCartItem.strDeliveryGroupId=testCartDeliveryGroup.id;
            objCartItem.strShipToAccId=shipToAcc.id;
            objCartItem.strShipFromId=prodLocation.id;
            objCartItem.strQuoteLineId = testQuoteLine.Id;
            objCartItem.strContractId = testContract.Id;
            PMC_DH_TestDataFactoryClass.createSubscription(objCartItem);
            CartItem cartItem1=PMC_DH_TestDataFactoryClass.buildCartItem1(objCartItem);
            insert cartItem1;
            Order orderRecord = PMC_DH_TestDataFactoryClass.createOrder(acc,testContract,cartObj.id);
            orderRecord.PMC_DH_OrderTypeCode__c = 'ZOR';
            update orderRecord;
            //System.debug('order->'+orderRecord);
            PMC_DH_TestDataFactoryClass.creatOrderLine(orderRecord,cartItem1);
            Test.stopTest();
        }
    }
    
    /**
* @description Test Method for getOrderRecords
* @param: none
* @return: void
* @author Lohitha
*/
    @isTest
    public static void testGetOrderRecords()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Account acc = [SELECT Id,Name FROM Account Where Name='Parent Test Account' LIMIT 1];
        system.runAs(user){

            Date datToday = Date.today();
            Date datYesterday = datToday.addDays(-1);
            Date datTomm = datToday.addDays(1);
            PMC_DH_OrderListViewController.OrderSearchParameterWrapper searchWrapper = new PMC_DH_OrderListViewController.OrderSearchParameterWrapper();
            searchWrapper.strSearchTerm='SAP1234';
            searchWrapper.datFromDate=datYesterday;
            searchWrapper.datToDate=datTomm;
            searchWrapper.strStatus='Confirmed';
            PMC_DH_OrderListViewWrapper result = PMC_DH_OrderListViewController.getOrderRecords(searchWrapper,acc.Id,'United States');
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    
    
    
    
    @isTest
    public static void testGetOrderRecordsBrazil()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Account acc = [SELECT Id,Name FROM Account Where Name='Parent Test Account' LIMIT 1];
        system.runAs(user){

            Date datToday = Date.today();
            Date datYesterday = datToday.addDays(-1);
            Date datTomm = datToday.addDays(1);
            PMC_DH_OrderListViewController.OrderSearchParameterWrapper searchWrapper = new PMC_DH_OrderListViewController.OrderSearchParameterWrapper();
            searchWrapper.strSearchTerm='SAP1234';
            searchWrapper.datFromDate=datYesterday;
            searchWrapper.datToDate=datTomm;
            searchWrapper.strStatus='Confirmed';
            PMC_DH_OrderListViewWrapper result = PMC_DH_OrderListViewController.getOrderRecords(searchWrapper,acc.Id,'Brazil');
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    
         /**
* @description Test Method for getOrderRecords Exception
* @param: none
* @return: void
* @author Lohitha
*/
@isTest
public static void testGetOrderRecordsException()
{
    Test.startTest();
    User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
    Account acc = [SELECT Id,Name FROM Account Where Name='Parent Test Account' LIMIT 1];
    system.runAs(user){
            //Boolean exceptionOccurred;
            //try{
        PMC_DH_DigitalHubB2BUtils.throwTestException = true;
        PMC_DH_OrderListViewController.OrderSearchParameterWrapper searchWrapper = new PMC_DH_OrderListViewController.OrderSearchParameterWrapper();
        searchWrapper.strSearchTerm='';
        searchWrapper.datFromDate=NULL;
        searchWrapper.datToDate=NULL;
         searchWrapper.strStatus='Draft';
                PMC_DH_OrderListViewWrapper result = PMC_DH_OrderListViewController.getOrderRecords(searchWrapper,acc.Id,'Brazil');
            //}
            //catch(exception e){
                //exceptionOccurred=true;
            //}
            System.AssertEquals(result.statusCodeMessage.strStatusCode, '100','success');
    }
    Test.stopTest();
}

}