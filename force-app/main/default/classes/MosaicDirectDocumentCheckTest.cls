@isTest
public class MosaicDirectDocumentCheckTest {
    @isTest(SeeAllData=true)
    static void testCheckDocumentButtons_ValidInput() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Customer'
        );
        insert testAccount;
        
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            PMC_CPQ_SAPOrderNumber__c = 'SAP123456'
        );
        insert testOrder;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product1a',
            IsActive = true
        );
        insert testProduct;

        Product2 testProduct2 = new Product2(
            Name = 'Test Product2b',
            IsActive = true
        );
        insert testProduct2;

        Product2 testProduct3 = new Product2(
            Name = 'Test Product3c',
            IsActive = true
        );
        insert testProduct3;
        
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testOrderItem;
        
        OrderItem testOrderItem2 = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = testProduct2.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testOrderItem2;
        
        OrderItem testOrderItem3 = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = testProduct3.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testOrderItem3;
        
        Shipment testShipment = new Shipment(
            ShipToName = 'Test Ship To'
        );
        insert testShipment;
        
        ShipmentItem testShipmentItem = new ShipmentItem(
            ShipmentId = testShipment.Id,
            PMC_CPQ_OrderProduct__c = testOrderItem.Id,
            Quantity = 1
        );
        insert testShipmentItem;
        
        ShipmentItem testShipmentItem2 = new ShipmentItem(
            ShipmentId = testShipment.Id,
            PMC_CPQ_OrderProduct__c = testOrderItem2.Id,
            Quantity = 1
        );
        insert testShipmentItem2;
        
        ShipmentItem testShipmentItem3 = new ShipmentItem(
            ShipmentId = testShipment.Id,
            PMC_CPQ_OrderProduct__c = testOrderItem.Id,
            Quantity = 1
        );
        insert testShipmentItem3;
        
        PMC_CPQ_Invoice__c testInvoice = new PMC_CPQ_Invoice__c(
            PMC_CPQ_InvoiceNumber__c = 'INV123456'
        );
        insert testInvoice;
        
        PMC_CPQ_InvoiceItem__c testInvoiceItem = new PMC_CPQ_InvoiceItem__c(
            PMC_CPQ_Invoice__c = testInvoice.Id,
            PMC_CPQ_DeliveryItem__c = testShipmentItem.Id
        );
        insert testInvoiceItem;

        List<OrderItem> orderProducts = [SELECT Id FROM OrderItem ORDER BY CreatedDate DESC LIMIT 3];
        List<Map<String, Object>> shipmentItems = new List<Map<String, Object>>();

        for (OrderItem op : orderProducts) {
            shipmentItems.add(new Map<String, Object>{'PMC_CPQ_OrderProduct__c' => op.Id});
        }

        String inputJson = JSON.serialize(shipmentItems);
        
        Test.startTest();
        String result = MosaicDirectDocumentCheckAvailability.checkDocumentButtons(inputJson);
        Test.stopTest();

        List<Object> rawItems = (List<Object>) JSON.deserializeUntyped(result);
        List<Map<String, Object>> newShipmentItems = new List<Map<String, Object>>();

        for (Object item : rawItems) {
            if (item instanceof Map<String, Object>) {
                newShipmentItems.add((Map<String, Object>) item);
            }
        }

        System.assertEquals(3, newShipmentItems.size(), 'Expected 3 items in result');
        System.assertEquals(newShipmentItems[0].get('invoiceFounded') != null, true);
        System.assertEquals(newShipmentItems[0].get('bolFounded') != null, true);
        System.assertEquals(newShipmentItems[0].get('coaFounded') != null, true);
    }

    @isTest(SeeAllData=true)
    static void testCheckDocumentButtons_InvalidJson() {
        String inputJson = '[]';

        Test.startTest();
        try {
            MosaicDirectDocumentCheckAvailability.checkDocumentButtons(inputJson);
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }

        Test.stopTest();
    }
}