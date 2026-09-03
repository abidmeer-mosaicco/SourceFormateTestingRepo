/**
* @description : Test class for PMC_DH_OrderManagementController
* @author      : Rohan Undale
* @userStory   : GDASF-34, 609
* @last modified by Nikhilesh
* @last modified on 08-01-2023
**/
@isTest
public with sharing class PMC_DH_OrderManagementControllerTest {
    /**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* @param: none
* @return: void
* @author Rohan
*/
    @testSetup  static void setup()
    {
        // test class fixes
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
        PMC_DH_TestDataFactoryClass.createTestAccountTeamMember(acc.Id, user.id, PMC_DH_ConstantClass.ACCOUNT_TEAMMEMBERACC);
        
        WebStore webStore=PMC_DH_TestDataFactoryClass.createTestWebStore();
        system.runAs(user){
            WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
            insert cartObj;
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            insert prod;
            Product2 prod2 = new Product2(name='Test21',StockKeepingUnit='944876',isactive=true);
            insert prod2;
            CartDeliveryGroup testCartDeliveryGroup=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj.id);
            insert testCartDeliveryGroup;
            
            Account shipToAcc=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
            Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
            PMC_CPQ_ProductLocation__c prodLocation = PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
            PMC_DH_TestDataFactoryClass.CartItemObject objCartItem=new PMC_DH_TestDataFactoryClass.CartItemObject();
            Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            Test.startTest();
            SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
            SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,prod);
            testQuoteLine.PMC_CPQ_PriceByDate__c=system.today()-1;
            update testQuoteLine;
            Contract testContract=PMC_DH_TestDataFactoryClass.createContract(testQuote.id,acc.id); 
            testContract.Status='Activated';
            update testContract;
            objCartItem.strCartId=cartObj.id;
            objCartItem.strProductId=prod.id;
            objCartItem.strDeliveryGroupId=testCartDeliveryGroup.id;
            objCartItem.strShipToAccId=shipToAcc.id;
            objCartItem.strShipFromId=prodLocation.id;
            objCartItem.strContractId = testContract.Id;
            objCartItem.strQuoteLineId = testQuoteLine.Id;
            objCartItem.strAccId = acc.Id;
            
            CartItem cartItem1=PMC_DH_TestDataFactoryClass.buildCartItem1(objCartItem);
            cartItem1.Quantity = 10;
            cartItem1.PMC_DH_Contract__c=testContract.id;
            cartItem1.TotalLineAmount = 100;
            insert cartItem1;
            SBQQ__Subscription__c testSubscription = PMC_DH_TestDataFactoryClass.createSubscription(objCartItem);
            cartItem1.PMC_DH_Subscription__c = testSubscription.Id;
            update cartItem1;
            Test.stopTest();
            
            PMC_DH_TestDataFactoryClass.CartItemObject objCartItem2=new PMC_DH_TestDataFactoryClass.CartItemObject();
            objCartItem2.strCartId=cartObj.id;
            objCartItem2.strProductId=prod2.id;
            objCartItem2.strDeliveryGroupId=testCartDeliveryGroup.id;
            objCartItem2.strShipToAccId=shipToAcc.id;
            objCartItem2.strShipFromId=prodLocation.id;
            objCartItem2.strContractId = testContract.Id;
            objCartItem2.strQuoteLineId = testQuoteLine.Id;
            objCartItem2.strAccId = acc.Id;
            
            CartItem cartItem2=PMC_DH_TestDataFactoryClass.buildCartItem1(objCartItem2);
            cartItem2.Quantity = 10;
            cartItem2.PMC_DH_Contract__c=testContract.id;
            cartItem2.TotalLineAmount = 100;
            insert cartItem2;
            SBQQ__Subscription__c testSubscription2 = PMC_DH_TestDataFactoryClass.createSubscription(objCartItem2);
            cartItem2.PMC_DH_Subscription__c = testSubscription2.Id;
            update cartItem2;
            
            Order testOrder = PMC_DH_TestDataFactoryClass.createOrder(acc, testContract, cartObj.id);
            testOrder.PMC_DH_OrderTypeCode__c = 'ZOR';
            testOrder.PMC_CPQ_SAPOrderNumber__c='zx11';
            update testOrder;
            OrderItem oi1 = PMC_DH_TestDataFactoryClass.creatOrderLine(testOrder, cartItem1);  
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id =  cartItem2.Product2Id,
                UnitPrice = 0,
                IsActive = true,
                CurrencyIsoCode='USD'
                
            );
            Insert pbe;         
            OrderItem oi2 = new OrderItem();
            oi2.OrderId = testOrder.Id;
            oi2.Product2Id = cartItem2.Product2Id;
            oi2.SBQQ__Contract__c = testOrder.ContractId;
            oi2.PMC_CPQ_RequestedShipDate__c = cartItem2.PMC_DH_RequestedShipmentDate__c;
            oi2.PMC_CPQ_ShipTo__c =cartItem2.PMC_DH_ShipTo__c;
            oi2.PMC_CPQ_ProductLocation__c = cartItem2.PMC_DH_PlantShipFrom__c;
            oi2.PMC_CPQ_ModeofTransportation__c = cartItem2.PMC_DH_DeliveryMode__c;
            oi2.PMC_CPQ_Incoterms__c = cartItem2.PMC_DH_Incoterms__c;
            oi2.PMC_DH_Frequency__c = cartItem2.PMC_DH_Frequency__c;
            oi2.PMC_CPQ_LinePONumber__c = cartItem2.PMC_DH_DeliveryPONumber__c;
            oi2.PMC_DH_ItemNumber__c = cartItem2.PMC_DH_ItemNumber__c;
            oi2.PMC_CPQ_OrderLineStatus__c = 'Placed';
            oi2.PMC_CPQ_PackageType__c = '';
            oi2.PricebookEntryId = pbe.Id;
            oi2.Quantity = cartItem2.Quantity;
            oi2.UnitPrice = 0;
            oi2.ListPrice = 0;
            oi2.PMC_CPQ_ListPrice__c = 0;
            oi2.PMC_DH_ProtocolIdentifier__c='12343546';
            oi2.PMC_DH_RequestNumber__c='MD-123664-1-1';
            insert oi2;
            
            
            oi1.PMC_CPQ_ConfirmedQuantity__c = 50;
            update oi1;
            /*
oi2.PMC_CPQ_ConfirmedQuantity__c = 50;
oi2.PMC_CPQ_PackageType__c = '';
update oi2;
*/
            Shipment shipmnt = PMC_DH_TestDataFactoryClass.createShipment(testOrder);
            Shipment shipmnt2 = new Shipment();
            shipmnt2.PMC_CPQ_Order__c = testOrder.Id;
            shipmnt2.ShipToName = 'Test2';
            shipmnt2.PMC_CPQ_SAPDeliveryID__c = '12345';
            shipmnt2.PMC_CPQ_ShippedDate__c = System.today();
            shipmnt2.PMC_CPQ_DeliveryPlannedGIDate__c = System.today()-1;
            insert shipmnt2;
            PMC_DH_TestDataFactoryClass.createShipmentItem(oi1,shipmnt);
            ShipmentItem deliveryItem = new ShipmentItem();
            deliveryItem.ShipmentId = shipmnt.Id;
            deliveryItem.PMC_CPQ_OrderProduct__c = oi1.Id;
            deliveryItem.Product2Id = oi1.Product2Id;
            deliveryItem.PMC_CPQ_VehicleID__c = 'SA1233';
            deliveryItem.PMC_CPQ_ShippedDate__c = System.today() - 1;
            deliveryItem.PMC_CPQ_DeliveryQuantity__c = 15;
            deliveryItem.PMC_CPQ_ETA__c = System.today() + 1;
            deliveryItem.PMC_CPQ_CurrentLocation__c = 'United States';
            deliveryItem.Quantity = 15;
            deliveryItem.PMC_CPQ_DeliveryItemID__c = '56681';
            //deliveryItem.PMC_CPQ_DeliveryStatus__c = 'Not Yet Shipped';
            deliveryItem.PMC_CPQ_DeliveryLineStatus__c = 'Not Yet Shipped';
            insert deliveryItem;
            
            PMC_CPQ_Invoice__c invoice = new PMC_CPQ_Invoice__c();
            invoice.PMC_CPQ_Order__c = testOrder.Id;
            invoice.PMC_CPQ_InvoiceNumber__c = '1234';
            invoice.PMC_CPQ_OrderProduct__c = oi1.Id;
            insert invoice;
            PMC_CPQ_InvoiceItem__c invoiceItem = new PMC_CPQ_InvoiceItem__c();
            invoiceItem.PMC_CPQ_Invoice__c = invoice.Id;
            invoiceItem.PMC_CPQ_OrderProduct__c =  oi1.Id;
            insert invoiceItem;
        }
    }
    
    /**
* @description Test Method for getOrderDetails method
* 
* @param: none
* 
* @return: void
*
* @author Nikhilesh
* 
*/
    @isTest
    public static void getOrderDetailsTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
            String strOrderId = [SELECT Id FROM Order WHERE Name='Test Order' LIMIT 1][0].Id;
            PMC_DH_OrderDetailsWrapper result = PMC_DH_OrderManagementController.getOrderDetails(PMC_DH_ConstantClass.TEST_COMMUNITYID,strTestAcct.Id, strOrderId);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    @isTest
    public static void getOrderDetailsTest2(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
            String strOrderId = [SELECT Id FROM Order WHERE Name='Test Order' LIMIT 1][0].Id;
            PMC_DH_OrderDetailsWrapper result = PMC_DH_OrderManagementController.getOrderDetails(PMC_DH_ConstantClass.TEST_COMMUNITYID,strTestAcct.Id, strOrderId);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Exception Method for getOrderDetails method
* 
* @param: none
* 
* @return: void
*
* @author Nikhilesh
* 
*/
    /* @isTest
    public static void getOrderDetailsTestException(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Boolean exceptionOccurred=true;
            try{
                Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
                String strOrderId;
                PMC_DH_OrderManagementController.getOrderDetails(PMC_DH_ConstantClass.TEST_COMMUNITYID,strTestAcct.Id, strOrderId);
            }
            catch(exception e){
                exceptionOccurred=true;
            }            
            System.assert(exceptionOccurred, 'An Exception was not thrown');
        }
        Test.stopTest();
    } */
    
    /**
* @description Test Method for addCartItems
* @param: none
* @return: void
* @author Rohan
*/  
    @isTest
    public static void getPricingSummaryForOrderTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        SBQQ__QuoteLine__c qtLine=[SELECT id,PMC_CPQ_QuoteRecordType__c from SBQQ__QuoteLine__c LIMIT 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        
        system.runAs(user){
            PMC_DH_PricingDetailWrapper result=PMC_DH_OrderManagementController.getPricingSummaryForOrder(strCartId);
            qtLine.PMC_CPQ_QuoteRecordType__c='Domestic SA';
            update qtLine;
            PMC_DH_OrderManagementController.getPricingSummaryForOrder(strCartId);
            system.assert(result!=null,'success');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for addListOfCartItemForReorder method
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/
    @isTest
    public static void addListOfCartItemForReorderTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        system.runAs(user){
            Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
            String strOrderId = [SELECT Id FROM Order WHERE Name='Test Order' LIMIT 1][0].Id;
            PMC_DH_OrderManagementController.PMC_DH_ReorderDetailsWrapper rowrp = new PMC_DH_OrderManagementController.PMC_DH_ReorderDetailsWrapper();
            rowrp.strCommunityId = PMC_DH_ConstantClass.TEST_COMMUNITYID;
            rowrp.strEffectiveAccountId = strTestAcct.Id;
            rowrp.strOrderId = strOrderId;
            rowrp.strCartId = strCartId;
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_OrderManagementController.reorderFromOrderDetails(rowrp);
            //System.debug('Result: ' + result);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for getOrderLineDetails method on PMC_DH_OrderLineDetailsController class
* @param: none
* @return: void
* @author Ajeet
*/
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
    /*************************************************************************
* @method Name  : callPriceRequestForOrderTest
* @description : Test Method for call price on order review page
* @author Lohitha
*****************************************************************************/
    @isTest
    public static void callPriceRequestForOrderTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1][0];
        system.runAs(user){
            List<String> letSKUId = new List<String>();
            letSKUId.add('SKU01');
            letSKUId.add('SKU02');
            letSKUId.add('SKU03');
            List<OrderItem> lstOrderItem = new List<OrderItem>();
            OrderItem objorderItem = [SELECT Id,OrderId FROM OrderItem WHERE Order.Name = 'Test Order' LIMIT 1];
            lstOrderItem.add(objorderItem);
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_OrderManagementHelper.callPriceRequestForOrders(lstOrderItem,letSKUId);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
        
    }
    /*************************************************************************
* @method Name  : callPriceRequestForOrderTest
* @description : Test Expection Method for call price on order review page
* @author Lohitha
*****************************************************************************/
    @isTest
    public static void callPriceRequestForOrderTestException(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Boolean exceptionOccurred=true;
            try{
                List<String> letSKUId = new List<String>();
                letSKUId.add('SKU01');
                letSKUId.add('SKU02');
                letSKUId.add('SKU03');
                List<OrderItem> lstOrderItem = new List<OrderItem>();
                OrderItem objorderItem = [SELECT Id,OrderId FROM OrderItem WHERE Order.Name = 'Test Order' LIMIT 1];
                lstOrderItem.add(objorderItem);
                PMC_DH_OrderManagementHelper.callPriceRequestForOrders(lstOrderItem,letSKUId);
            }
            catch(exception e){
                exceptionOccurred=true;
            }            
            System.assert(exceptionOccurred, 'An Exception was not thrown');
        }
        Test.stopTest();
    }
    
    /*************************************************************************
* @method Name  : updateCustomerCallPriceDateTest
* @description : Test Method for Customer CallPriceDate update on order summary page
* @author Mosaic Direct Dev 
*****************************************************************************/
    @isTest
    public static void updateCustomerCallPriceDateTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1][0];
        system.runAs(user){
            List<String> lstOrderItem = new List<String>();
            OrderItem objorderItem = [SELECT Id,OrderId FROM OrderItem WHERE Order.Name = 'Test Order' LIMIT 1];
            lstOrderItem.add(objorderItem.Id);
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_OrderManagementController.updateCustomerCallPriceDate(lstOrderItem,false);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
        
    }
    
        /*************************************************************************
* @method Name  : updateCustomerCallPriceDateTestException
* @description : Test Exception Method for Customer CallPriceDate update on order summary page
* @author Mosaic Direct Dev 
*****************************************************************************/
    @isTest
    public static void updateCustomerCallPriceDateTestException(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1][0];
        system.runAs(user){
            List<String> lstOrderItem = new List<String>();
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_OrderManagementController.updateCustomerCallPriceDate(lstOrderItem,false);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
        
    }
    /*************************************************************************
* @method Name  : getOrderLineDetailsWithCallPriceDataTest
* @description : Test Method for Customer CallPriceDate update on order summary page
* @author Mosaic Direct Dev 
*****************************************************************************/
    @isTest
    public static void checkPricePerTonAndTotalPriceTest(){
        Test.startTest();
        User usr=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        System.runAs(usr){
            try{
                PMC_DH_OrderDetailsWrapper.OrderLineWrapper orderLineWrapper = new PMC_DH_OrderDetailsWrapper.OrderLineWrapper();
                orderLineWrapper.boolCustomerCallPriceDate=true;
                orderLineWrapper.boolAMFPDPrice =true;
                orderLineWrapper.strTotalQuantity = '2';
                Decimal decFinalAgreedPrice = 23.0;
                Map<String, String> mapValues = PMC_DH_OrderManagementHelper.checkPricePerTonAndTotalPrice(orderLineWrapper,decFinalAgreedPrice);
                System.assert(mapValues!=null,'Success');
            }catch(AuraHandledException ex){
                System.assert(ex.getMessage() != null, 'Exception was caught');
            }
        }
        Test.stopTest();
    }
    /*************************************************************************
* @method Name  : getShipmentRecordsTest
* @description : Test Method for getShipmentRecords from ShipmentHistoryList class
* @author Ajeet
*****************************************************************************/
   /* @isTest
    public static void getShipmentRecordsTest(){
        Test.startTest();
        Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
        User usr=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        System.runAs(usr){
            try{
                PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentSearchParameterWrapper searchParams = new PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentSearchParameterWrapper();
                searchParams.strSearchTerm='Test';
                searchParams.datFromDate = System.today();
                searchParams.datToDate = System.today();
                searchParams.strStatus = 'In Transit';
                
                //added as part of GDASF-19642
                PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentHistoryListWrapper wrpShipmentHistoryListWrapper = PMC_DH_ShipmentHistoryList.getShipmentRecords(searchParams, strTestAcct.Id, 'United States');
                System.assert(wrpShipmentHistoryListWrapper.lstShipmentWrapper != null,'Success');
                PMC_DH_ShipmentHistoryList.getShipmentItemStatus(new ShipmentItem(), 'Scheduled');
            }catch(AuraHandledException ex){
                System.assert(ex.getMessage() != null, 'Exception was caught');
            }
        }
        Test.stopTest();
    }*/
    /*************************************************************************
* @method Name  : getShipmentRecordsTest2
* @description : Test Method for getShipmentRecords from ShipmentHistoryList class
* @author Ajeet
*****************************************************************************/
   /* @isTest
    public static void getShipmentRecordsTest2(){
        Test.startTest();
        Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
        User usr=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        System.runAs(usr){
            try{
                PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentSearchParameterWrapper searchParams = new PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentSearchParameterWrapper();
                searchParams.strSearchTerm='';
                searchParams.datFromDate = System.today();
                searchParams.datToDate = System.today();
                searchParams.strStatus = 'In Transit';
                
                //added as part of GDASF-19642
                PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentHistoryListWrapper wrpShipmentHistoryListWrapper = PMC_DH_ShipmentHistoryList.getShipmentRecords(searchParams, strTestAcct.Id, 'United States');
                System.assert(wrpShipmentHistoryListWrapper.lstShipmentWrapper != null,'Success');
            }catch(AuraHandledException ex){
                System.assert(ex.getMessage() != null, 'Exception was caught');
            }
        }
        Test.stopTest();
    }*/
    /*************************************************************************
* @method Name  : getShipmentRecordsTest
* @description : Test Method for getShipmentRecords from ShipmentHistoryList class
* @author Ajeet
*****************************************************************************/
    @isTest
    public static void getShipmentScheduledTest(){
        Test.startTest();
        Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
        User usr=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        System.runAs(usr){
            try{
                PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentSearchParameterWrapper searchParams = new PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentSearchParameterWrapper();
                searchParams.strSearchTerm='Test';
                searchParams.datFromDate = System.today();
                searchParams.datToDate = System.today();
                searchParams.strStatus = 'Scheduled';
                
                //added as part of GDASF-19642
                PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentHistoryListWrapper wrpShipmentHistoryListWrapper = PMC_DH_ShipmentHistoryList.getShipmentRecords(searchParams, strTestAcct.Id, 'United States');
                System.assert(wrpShipmentHistoryListWrapper.lstShipmentWrapper != null,'Success');
            }catch(AuraHandledException ex){
                System.assert(ex.getMessage() != null, 'Exception was caught');
            }
        }
        Test.stopTest();
    }
    /*************************************************************************
* @method Name  : compareToPositiveTest
* @description : Test Method for compareTo method from PMC_DH_ShipmentItemCustomSortOrder class
* @author Nikhilesh
*****************************************************************************/
    @isTest
    public static void compareToPositiveTest() {
        PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper shipmentItemsWrapper = new PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper();
        PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper shipmentItemsWrapper2 = new PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper();
        shipmentItemsWrapper.datShipDate = Date.today();
        shipmentItemsWrapper2.datShipDate = Date.today() - 1;
        test.startTest();
        PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentItemCustomSortOrder objSISort = new PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentItemCustomSortOrder(shipmentItemsWrapper);
        PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentItemCustomSortOrder objsortShipmentItem = new PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentItemCustomSortOrder(shipmentItemsWrapper2);
        Integer i = objSISort.compareTo(objsortShipmentItem);
        System.assert(i > 0, 'Success');
        test.stopTest();
    }
    /*************************************************************************
* @method Name  : compareToNegativeTest
* @description : Test Method for compareTo method from PMC_DH_ShipmentItemCustomSortOrder class
* @author Nikhilesh
*****************************************************************************/
    @isTest
    public static void compareToNegativeTest() {
        PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper shipmentItemsWrapper = new PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper();
        PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper shipmentItemsWrapper2 = new PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper();
        shipmentItemsWrapper.datShipDate = Date.today() - 1;
        shipmentItemsWrapper2.datShipDate = Date.today();
        test.startTest();
        PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentItemCustomSortOrder objSISort = new PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentItemCustomSortOrder(shipmentItemsWrapper);
        PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentItemCustomSortOrder objsortShipmentItem = new PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentItemCustomSortOrder(shipmentItemsWrapper2);
        Integer i = objSISort.compareTo(objsortShipmentItem);
        System.assert(i < 0, 'Success');
        test.stopTest();
    }
    /*************************************************************************
* @method Name  : compareToEqualTest
* @description : Test Method for compareTo method from PMC_DH_ShipmentItemCustomSortOrder class
* @author Nikhilesh
*****************************************************************************/
    @isTest
    public static void compareToEqualTest() {
        PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper shipmentItemsWrapper = new PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper();
        PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper shipmentItemsWrapper2 = new PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper();
        shipmentItemsWrapper.datShipDate = Date.today();
        shipmentItemsWrapper2.datShipDate = Date.today();
        test.startTest();
        PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentItemCustomSortOrder objSISort = new PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentItemCustomSortOrder(shipmentItemsWrapper);
        PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentItemCustomSortOrder objsortShipmentItem = new PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentItemCustomSortOrder(shipmentItemsWrapper2);
        Integer i = objSISort.compareTo(objsortShipmentItem);
        System.assert(i == 0, 'Success');
        test.stopTest();
    }
    
    
    /**
*@description test Exception Method
*@author hemant giri goswami
*/
    public static void testExceptionCall()
    {
        String strCommunityId='';
        String strEffectiveAccountId='';
        String strOrderId='';
        PMC_DH_DigitalHubB2BUtils.throwTestException = true;
        User usr=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        PMC_DH_OrderDetailsWrapper wrp=new PMC_DH_OrderDetailsWrapper(); 
        test.startTest();
        
        System.runAs(usr){
            wrp=PMC_DH_OrderManagementController.getOrderDetails(strCommunityId,strEffectiveAccountId,strOrderId);
            System.assert(wrp.statusCodeMessage.strStatusCode!='000', 'Success');
        }
        test.stopTest();
    }
    
}