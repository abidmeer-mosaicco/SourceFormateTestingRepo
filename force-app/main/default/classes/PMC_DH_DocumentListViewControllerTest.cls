/**
* @description : Test class for PMC_DH_DocumentListViewController
* @author      : Humera Rahath
* @userStory   : GDASF-463
* @last modified by Humera
* @last modified on 10-23-2023
**/
@isTest
public with sharing class PMC_DH_DocumentListViewControllerTest {
   
    /**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* @param: none
* @return: void
* @author Humera 
*/
    @testSetup  
    static void setup()
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
        Id lstPermSet4=[select id from PermissionSet where Name ='PMC_DH_CR_TransactionLogs'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet4);
        
        WebStore webStore=PMC_DH_TestDataFactoryClass.createTestWebStore();
        AccountShare accountShare = new AccountShare();
        accountShare.AccountId = acc.Id;        
        accountShare.UserOrGroupId = user.Id;        
        accountShare.AccountAccessLevel = 'Read';
        accountShare.ContactAccessLevel = 'Read';
        accountShare.OpportunityAccessLevel = 'Read';
        insert accountShare;
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
            OrderItem oi1 = PMC_DH_TestDataFactoryClass.creatOrderLine(orderRecord,cartItem1);
            oi1.PMC_CPQ_ConfirmedQuantity__c = 50;
            update oi1;
        	Shipment shipmnt = PMC_DH_TestDataFactoryClass.createShipment(orderRecord);
            shipmnt.PMC_CPQ_SAPDeliveryID__c = '5678';
            shipmnt.PMC_DH_SAPDeliveryCreatedDate__c = Date.today();
            update shipmnt;
        	ShipmentItem si = PMC_DH_TestDataFactoryClass.createShipmentItem(oi1,shipmnt);
        	si.PMC_CPQ_DeliveryLineStatus__c = 'Completely Shipped';
        	update si;
        	PMC_CPQ_Invoice__c invoice = new PMC_CPQ_Invoice__c();
            invoice.PMC_CPQ_Order__c = orderRecord.Id;
            invoice.PMC_CPQ_InvoiceNumber__c = '1234';
            invoice.PMC_CPQ_OrderProduct__c = oi1.Id;
            invoice.PMC_DH_SAPInvoiceCreatedDate__c = Date.today();
            invoice.PMC_CPQ_BillingDocType__c = 'ZL2'; //DBM
            insert invoice;
            PMC_CPQ_InvoiceItem__c invoiceItem = new PMC_CPQ_InvoiceItem__c();
            invoiceItem.PMC_CPQ_Invoice__c = invoice.Id;
            invoiceItem.PMC_CPQ_OrderProduct__c =  oi1.Id;
            insert invoiceItem;
            Test.stopTest();
        }
    }

        /**
* @description Test Method for fetchDocumentRecords
* @param: none
* @return: void
* @author        : @Nikhilesh
*/
    @isTest
    public static void fetchDocumentRecordsTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Account acc = [SELECT Id,Name FROM Account Where Name='Parent Test Account' LIMIT 1];
        system.runAs(user){
            PMC_DH_DocumentListViewHelper.PMC_DH_DocumentSearchParameterWrapper searchWrapper = new PMC_DH_DocumentListViewHelper.PMC_DH_DocumentSearchParameterWrapper();
            PMC_DH_DocumentListViewWrapper res = PMC_DH_DocumentListViewController.fetchDocumentRecords(searchWrapper, acc.Id);
            System.assert(res!=null, 'Success');
        }
        Test.stopTest();
    }
           /**
* @description Test Method for fetchDocumentRecords
* @param: none
* @return: void
* @author        : @Nikhilesh
*/
    @isTest
    public static void fetchDocumentRecordsWithSearchParamsTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Account acc = [SELECT Id,Name FROM Account Where Name='Parent Test Account' LIMIT 1];
        system.runAs(user){
            Date datToday = Date.today();
            Date datYesterday = datToday.addDays(-1);
            Date datTomm = datToday.addDays(1);
            PMC_DH_DocumentListViewHelper.PMC_DH_DocumentSearchParameterWrapper searchWrapper = new PMC_DH_DocumentListViewHelper.PMC_DH_DocumentSearchParameterWrapper();
            searchWrapper.strSearchTerm='Debit Memo_1234';
            searchWrapper.datFromDate=datYesterday;
            searchWrapper.datToDate=datTomm;
            PMC_DH_DocumentListViewWrapper res = PMC_DH_DocumentListViewController.fetchDocumentRecords(searchWrapper, acc.Id);
            System.assert(res!=null, 'Success');
        }
        Test.stopTest();
    } 
}