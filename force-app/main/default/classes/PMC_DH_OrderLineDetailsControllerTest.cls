@isTest
public class PMC_DH_OrderLineDetailsControllerTest {

    @testSetup
    static void setupData() {
        
        Account acc = PMC_DH_TestDataFactoryClass.createParentTestAccount();
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
        
        User user = [SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strContactId = [SELECT contactId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1][0].contactId;
        Id lstPermSet2 = [select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet2);
        Id lstPermSet = [select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet);
        Id lstPermSet1 = [select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet1);
        Id lstPermSet3 = [select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet3);
        PMC_DH_TestDataFactoryClass.createTestAccountTeamMember(acc.Id, user.id, PMC_DH_ConstantClass.ACCOUNT_TEAMMEMBERACC);

        WebStore webStore=PMC_DH_TestDataFactoryClass.createTestWebStore();
        
        system.runAs(user) {
            
            WebCart cartObj = PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
        	insert cartObj;
            
        	Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
        	insert prod;
            
        	CartDeliveryGroup testCartDeliveryGroup = PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj.id);
        	insert testCartDeliveryGroup;
            
        	CartItem cartItem = PMC_DH_TestDataFactoryClass.buildCartItem(cartObj.id, prod.id,testCartDeliveryGroup.Id);
        	cartItem.Quantity = 5;
        	cartItem.TotalLineAmount = 5100;
        	insert cartItem;
        
        	Account shipToAcc = PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
        	Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
        	PMC_CPQ_ProductLocation__c prodLocation = PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
        	PMC_DH_TestDataFactoryClass.CartItemObject objCartItem = new PMC_DH_TestDataFactoryClass.CartItemObject();
        	objCartItem.strCartId = cartObj.id;
        	objCartItem.strProductId = prod.id;
        	objCartItem.strDeliveryGroupId = testCartDeliveryGroup.id;
        	objCartItem.strShipToAccId = shipToAcc.id;
        	objCartItem.strShipFromId = prodLocation.id;
        	CartItem cartItem1 = PMC_DH_TestDataFactoryClass.buildCartItem1(objCartItem);
        	cartItem1.Quantity = 10;
        	cartItem1.TotalLineAmount = 100;
        	insert cartItem1;
            
            Opportunity opp = PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            
            SBQQ__Quote__c testQuote = PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
            SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,prod);
            
            Test.startTest();
           	Contract testContract = PMC_DH_TestDataFactoryClass.createContract(testQuote.id,acc.id); 
            testContract.Status = 'Activated';
            update testContract;
            
            objCartItem.strAccId = acc.Id;
            objCartItem.strContractId = testContract.Id;
            objCartItem.strQuoteLineId = testQuoteLine.Id;
            
            PMC_DH_TestDataFactoryClass.createSubscription(objCartItem);
            
            Order testOrder = PMC_DH_TestDataFactoryClass.createOrder(acc, testContract, cartObj.id);
            OrderItem oi1 = PMC_DH_TestDataFactoryClass.creatOrderLine(testOrder, cartItem);
            oi1.PMC_CPQ_ConfirmedQuantity__c = 50;
        	oi1.PMC_CPQ_OrderLineStatus__c = 'Placed';
            update oi1;
            
        	Shipment shipmnt = PMC_DH_TestDataFactoryClass.createShipment(testOrder);        	
        	PMC_DH_TestDataFactoryClass.createShipmentItem(oi1,shipmnt);
        	shipmnt.PMC_CPQ_DeliveryStatus__c = 'Completely Shipped';
            shipmnt.status='Open';
        	update shipmnt;
             // Create and insert a test shipment item linked to the shipment with required Quantity field
        ShipmentItem shipmentItem = new ShipmentItem( ShipmentId = shipmnt.Id,
            PMC_CPQ_DeliveryItemID__c = 'ITEM-56789',
            Quantity = 10 // Required field
        );
        insert shipmentItem;
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

    @isTest
    static void testGetOrderLineDetails() {
        // Get inserted order item
        OrderItem testOrderItem = [SELECT Id FROM OrderItem LIMIT 1];

        // Call method
        Test.startTest();
        PMC_DH_OrderLineDetailsWrapper result = PMC_DH_OrderLineDetailsController.getOrderLineDetails(testOrderItem.Id, 'en_US');
        Test.stopTest();

    }

    @isTest
    static void testGetOrderDocumentMethod() {

        OrderItem testOrderItem = [SELECT Id, (SELECT Id, PMC_CPQ_OrderProduct__c FROM Delivery_Items__r), (SELECT Id, PMC_CPQ_OrderProduct__c, PMC_CPQ_Invoice__c FROM InvoiceItems__r) FROM OrderItem LIMIT 1];

        Test.startTest();
        try {
            Map<String, List<PMC_DH_PicklistWrapper>> result = PMC_DH_OrderLineDetailsController.getOrderDocument(testOrderItem, 'en_US');
        } catch(Exception e) {}
        
        Test.stopTest();
    }

    @isTest
    static void testGetDocumentDataMethod() {
        OrderItem testOrderItem = [SELECT Id, (SELECT Id, PMC_CPQ_Invoice__c, PMC_CPQ_OrderProduct__c FROM InvoiceItems__r) FROM OrderItem LIMIT 1];

        Test.startTest();
        try {
            Map<String, Map<String, String>> docData = PMC_DH_OrderLineDetailsController.getDocumentData(testOrderItem, 'NA');
        } catch (Exception e) {}
        
        Test.stopTest();
    }
    
}