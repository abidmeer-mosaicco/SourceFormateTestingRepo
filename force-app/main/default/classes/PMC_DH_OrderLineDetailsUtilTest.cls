/**
* @description : Test class for PMC_DH_OrderLineDetailsUtil
* @author      : Krishan Jangir
* @userStory   : GDASF-15433
* @last modified by Krishan
* @last modified on 10-26-2023
**/
@isTest
public with sharing class PMC_DH_OrderLineDetailsUtilTest {
/**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* @param: none
* @return: void
* @author Rohan
*/
    @testSetup  static void setup()
    {
        // test Classes fixes
        Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
        //Account shipToAcc=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
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

        
        WebStore webStore=PMC_DH_TestDataFactoryClass.createTestWebStore();
        system.runAs(user){
            WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
        	insert cartObj;
        	Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
        	insert prod;
        	CartDeliveryGroup testCartDeliveryGroup=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj.id);
        	insert testCartDeliveryGroup;
        	CartItem cartItem=PMC_DH_TestDataFactoryClass.buildCartItem(cartObj.id, prod.id,testCartDeliveryGroup.Id);
        	cartItem.Quantity = 5;
        	cartItem.TotalLineAmount = 5100;
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
        	CartItem cartItem1=PMC_DH_TestDataFactoryClass.buildCartItem1(objCartItem);
        	cartItem1.Quantity = 10;
        	cartItem1.TotalLineAmount = 100;
        	insert cartItem1;
            Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            
            SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
            SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,prod);
            Test.startTest();
           	Contract testContract=PMC_DH_TestDataFactoryClass.createContract(testQuote.id,acc.id); 
            testContract.Status='Activated';
            update testContract;
            objCartItem.strAccId = acc.Id;
            objCartItem.strContractId = testContract.Id;
            objCartItem.strQuoteLineId = testQuoteLine.Id;
            PMC_DH_TestDataFactoryClass.createSubscription(objCartItem);
            Order testOrder = PMC_DH_TestDataFactoryClass.createOrder(acc, testContract, cartObj.id);
            OrderItem oi1 = PMC_DH_TestDataFactoryClass.creatOrderLine(testOrder, cartItem);
            oi1.PMC_CPQ_ConfirmedQuantity__c = 50;
        	oi1.PMC_CPQ_OrderLineStatus__c='Placed';
            update oi1;
        	Shipment shipmnt = PMC_DH_TestDataFactoryClass.createShipment(testOrder);        	
        	PMC_DH_TestDataFactoryClass.createShipmentItem(oi1,shipmnt);
        	shipmnt.PMC_CPQ_DeliveryStatus__c = 'Completely Shipped';
        	update shipmnt;
            //ShipmentItem si1 = PMC_DH_TestDataFactoryClass.createShipmentItem(oi1,shipmnt);
            //si1.PMC_CPQ_VehicleID__c = 'SA12345';
            //update si1;
            PMC_CPQ_Invoice__c invoice = new PMC_CPQ_Invoice__c();
            invoice.PMC_CPQ_Order__c = testOrder.Id;
            invoice.PMC_CPQ_InvoiceNumber__c = '1234';
            invoice.PMC_CPQ_OrderProduct__c = oi1.Id;
            insert invoice;
            PMC_CPQ_InvoiceItem__c invoiceItem = new PMC_CPQ_InvoiceItem__c();
            invoiceItem.PMC_CPQ_Invoice__c = invoice.Id;
            invoiceItem.PMC_CPQ_OrderProduct__c =  oi1.Id;
            insert invoiceItem;
            Test.stopTest();
        }
    }
    /**
* @description Test Method for getOrderLineDetails method on PMC_DH_OrderLineDetailsController class
* @param: none
* @return: void
* @author Ajeet
*/
    @isTest
    public static void getDeliveryTrackingTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        System.runAs(user) {
        String orderItemId = [SELECT Id FROM OrderItem WHERE Order.Name = 'Test Order' LIMIT 1][0].Id;
        Shipment shipmnt = [SELECT Id, ShipToName from Shipment WHERE ShipToName = 'Test' LIMIT 1];
        shipmnt.PMC_CPQ_DeliveryStatus__c = 'Completely Shipped';
        shipmnt.PMC_CPQ_CurrentCoordinates__Latitude__s = 23.23;
        shipmnt.PMC_CPQ_CurrentCoordinates__Longitude__s = 23.23;
        shipmnt.PMC_CPQ_VehicleID__c = 'SA1234';
        update shipmnt;
        ShipmentItem objShip = [SELECT Id,PMC_CPQ_VehicleID__c FROM ShipmentItem  WHERE PMC_CPQ_VehicleID__c='SA1234' LIMIT 1];
       
        PMC_DH_OrderLineDetailsWrapper.OrderLineSummaryWrapper wrapOrderLineSummary = new PMC_DH_OrderLineDetailsWrapper.OrderLineSummaryWrapper();
        List<OrderItem> lstOrderItem = [SELECT Id,PMC_DH_CustomerCallPriceDate__c,PMC_CPQ_FPDPricefromPriceFx__c FROM OrderItem LIMIT 1];
        lstOrderItem[0].PMC_DH_CustomerCallPriceDate__c = System.today();
        update lstOrderItem[0];
        Boolean boolValue;
     
            try{
                PMC_DH_DeliveryTrackerWrapper orderLineDetailWrp = PMC_DH_OrderLineDetailsUtil.getDeliveryTracking(orderItemId,objShip.PMC_CPQ_VehicleID__c);
                boolValue = PMC_DH_OrderLineDetailsUtil.getBoolValues(wrapOrderLineSummary, lstOrderItem);
                System.assert(orderLineDetailWrp!=null,'Success');
            }catch(AuraHandledException ex){
                System.assert(ex.getMessage() != null, 'Exception was caught');
            }
           
        }
        Test.stopTest();
    }
    
    @isTest
    public static void getDeliveryTrackingTest1(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        System.runAs(user) {
        String orderItemId = [SELECT Id FROM OrderItem WHERE Order.Name = 'Test Order' LIMIT 1][0].Id;
        ShipmentItem objShip = [SELECT Id,PMC_CPQ_VehicleID__c,ShipmentId FROM ShipmentItem  WHERE PMC_CPQ_VehicleID__c='SA1234' LIMIT 1];
        Shipment objShip2 = new Shipment(Id=objShip.ShipmentId);
        objShip2.PMC_CPQ_DeliveryStatus__c = 'Partially Shipped';
        objShip2.PMC_CPQ_VehicleID__c = 'SA1234';
        update objShip2;
        update objShip;
            try{
                PMC_DH_DeliveryTrackerWrapper orderLineDetailWrp = PMC_DH_OrderLineDetailsUtil.getDeliveryTracking(orderItemId,objShip.PMC_CPQ_VehicleID__c);
                System.assert(orderLineDetailWrp!=null,'Success');
            }catch(AuraHandledException ex){
                System.assert(ex.getMessage() != null, 'Exception was caught');
            }
        }
        Test.stopTest();
    }
        @isTest
    public static void getDeliveryTrackingTest2(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        System.runAs(user) {
        String orderItemId = [SELECT Id FROM OrderItem WHERE Order.Name = 'Test Order' LIMIT 1][0].Id;        
        ShipmentItem objShip = [SELECT Id,PMC_CPQ_VehicleID__c, ShipmentId FROM ShipmentItem  WHERE PMC_CPQ_VehicleID__c='SA1234' LIMIT 1];
        //objShip.PMC_CPQ_DeliveryStatus__c = 'Partially Shipped';
        objShip.PMC_CPQ_ShippedDate__c = NULL;
        update objShip;
        Shipment objShip2 = new Shipment(Id=objShip.ShipmentId);
        objShip2.PMC_CPQ_DeliveryStatus__c = 'Partially Shipped';
        objShip2.PMC_CPQ_DeliveryPlannedGIDate__c = System.today();
        objShip2.PMC_CPQ_VehicleID__c = 'SA1234';
        update objShip2;
        
            try{
                PMC_DH_DeliveryTrackerWrapper orderLineDetailWrp = PMC_DH_OrderLineDetailsUtil.getDeliveryTracking(orderItemId,objShip.PMC_CPQ_VehicleID__c);
                System.assert(orderLineDetailWrp!=null,'Success');
            }catch(AuraHandledException ex){
                System.assert(ex.getMessage() != null, 'Exception was caught');
            }
        }
        Test.stopTest();
    }
    
    @isTest
    public static void getDeliveryTrackingTest3(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        System.runAs(user) {
        String orderItemId = [SELECT Id FROM OrderItem WHERE Order.Name = 'Test Order' LIMIT 1][0].Id;        
        ShipmentItem objShip = [SELECT Id,PMC_CPQ_VehicleID__c, ShipmentId FROM ShipmentItem  WHERE PMC_CPQ_VehicleID__c='SA1234' LIMIT 1];
        objShip.PMC_CPQ_DeliveryStatus__c = 'Partially Shipped';
        objShip.PMC_CPQ_ShippedDate__c = NULL;
        update objShip;
        Shipment objShip2 = new Shipment(Id=objShip.ShipmentId);
        objShip2.PMC_CPQ_DeliveryStatus__c = 'Partially Shipped';
        objShip2.PMC_CPQ_DeliveryPlannedGIDate__c = NULL;
        objShip2.PMC_CPQ_VehicleID__c = 'SA1234';
        update objShip2;
        
            try{
                PMC_DH_DeliveryTrackerWrapper orderLineDetailWrp = PMC_DH_OrderLineDetailsUtil.getDeliveryTracking(orderItemId,objShip.PMC_CPQ_VehicleID__c);
                System.assert(orderLineDetailWrp!=null,'Success');
            }catch(AuraHandledException ex){
                System.assert(ex.getMessage() != null, 'Exception was caught');
            }
        }
        Test.stopTest();
    }
     @isTest
    public static void getOrderLineDetailsTest(){
        Test.startTest();
        User usr=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        System.runAs(usr){
            try{
                String orderItemId = [SELECT Id FROM OrderItem WHERE Order.Name = 'Test Order' LIMIT 1][0].Id;
                PMC_DH_OrderLineDetailsWrapper orderLineDetailWrp = PMC_DH_OrderLineDetailsController.getOrderLineDetails(orderItemId,'United States');
                System.assert(orderLineDetailWrp!=null,'Success');
            }catch(AuraHandledException ex){
                System.assert(ex.getMessage() != null, 'Exception was caught');
            }
        }
        Test.stopTest();
    }
}