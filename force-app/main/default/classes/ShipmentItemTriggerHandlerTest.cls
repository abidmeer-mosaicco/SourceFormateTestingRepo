@isTest
public class ShipmentItemTriggerHandlerTest {
    
    @isTest
    static void testCheckShipmentItemVisibilityInCreation_SingleItem() {
        String FPDrecordTypeId = Schema.SObjectType.Shipment.getRecordTypeInfosByName().get('FPD Delivery').getRecordTypeId();
        Account testAccount = new Account(
            Name = 'Test Account', 
            Type = 'Customer'
        );
        insert testAccount;

        Order testOrder = new Order(
            AccountId = testAccount.Id, 
            Status = 'Draft', 
            EffectiveDate = Date.today()
        );
        insert testOrder;

        Product2 testProduct = new Product2(
            Name = 'Test Product - A1', 
            IsActive = true
        );
        insert testProduct;

        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id, 
            Product2Id = testProduct.Id, 
            Quantity = 1, 
            UnitPrice = 100
        );
        insert testOrderItem;

        Shipment testShipment = new Shipment(
            ShipToName = 'Test Ship To', 
            RecordTypeId = FPDrecordTypeId, 
            PMC_CPQ_Order__c = testOrder.Id, 
            Status = 'Completed', 
            PMC_CPQ_DeliveryStatus__c = 'Completely Shipped'
        );
        insert testShipment;

        ShipmentItem ship1 = new ShipmentItem();
        ship1.ShipmentId = testShipment.Id;
        ship1.PMC_CPQ_OrderProduct__c = testOrderItem.Id;
        ship1.Quantity = 1;

        ShipmentItem ship2 = new ShipmentItem();
        ship2.ShipmentId = testShipment.Id;
        ship2.PMC_CPQ_OrderProduct__c = testOrderItem.Id;
        ship2.Quantity = 1;

        List<ShipmentItem> items = new List<ShipmentItem>();
        items.add(ship1);
        items.add(ship2);

        Test.startTest();
        insert items;
        Test.stopTest();

        List<ShipmentItem> insertedItems = [SELECT Id, isVisible__c FROM ShipmentItem WHERE ShipmentId = :testShipment.Id ORDER BY CreatedDate ASC];
        System.assertEquals(2, insertedItems.size(), 'Deve ter 2 itens');
        System.assertEquals(true, insertedItems[0].isVisible__c, 'Primeiro item deve ter o isVisible true');
        System.assertEquals(false, insertedItems[1].isVisible__c, 'Segundo item deve ter o isVisible false');
    }

    @isTest
    static void testTotalShippedQuantityRollup() {
        Id fpdRecordTypeId = Schema.SObjectType.Shipment.getRecordTypeInfosByName().get('FPD Delivery').getRecordTypeId();

        Account testAccount = new Account(Name = 'Rollup Account', Type = 'Customer');
        insert testAccount;

        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert testOrder;

        Product2 testProduct = new Product2(Name = 'Rollup Product', IsActive = true);
        insert testProduct;

        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testOrderItem;

        OrderItem excludedOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert excludedOrderItem;

        Shipment activeShipment = new Shipment(
            ShipToName = 'Active Shipment',
            RecordTypeId = fpdRecordTypeId,
            PMC_CPQ_Order__c = testOrder.Id,
            Status = 'Completed',
            PMC_CPQ_DeliveryStatus__c = 'Completely Shipped'
        );
        insert activeShipment;

        Shipment deletedShipment = new Shipment(
            ShipToName = 'Deleted Shipment',
            RecordTypeId = fpdRecordTypeId,
            PMC_CPQ_Order__c = testOrder.Id,
            Status = 'Delivery Deleted',
            PMC_CPQ_DeliveryStatus__c = 'Completely Shipped'
        );
        insert deletedShipment;

        ShipmentItem mainItem = new ShipmentItem(
            ShipmentId = activeShipment.Id,
            PMC_CPQ_OrderProduct__c = testOrderItem.Id,
            PMC_CPQ_DeliveryQuantity__c = 10,
            Quantity = 10
        );
        ShipmentItem deletedShipmentItem = new ShipmentItem(
            ShipmentId = deletedShipment.Id,
            PMC_CPQ_OrderProduct__c = excludedOrderItem.Id,
            PMC_CPQ_DeliveryQuantity__c = 999,
            Quantity = 999
        );

        Test.startTest();
        insert new List<ShipmentItem>{ mainItem, deletedShipmentItem };

        OrderItem afterInsert = [SELECT ActualShippedQuantity__c FROM OrderItem WHERE Id = :testOrderItem.Id];
        System.assertEquals(10, afterInsert.ActualShippedQuantity__c, 'Should sum TT visible items from non-deleted shipments');

        OrderItem afterInsertExcluded = [SELECT ActualShippedQuantity__c FROM OrderItem WHERE Id = :excludedOrderItem.Id];
        System.assertEquals(0, afterInsertExcluded.ActualShippedQuantity__c, 'Should exclude items on deleted shipments');

        mainItem.PMC_CPQ_DeliveryQuantity__c = 25;
        update mainItem;

        OrderItem afterUpdate = [SELECT ActualShippedQuantity__c FROM OrderItem WHERE Id = :testOrderItem.Id];
        System.assertEquals(25, afterUpdate.ActualShippedQuantity__c, 'Update should refresh the rollup');

        delete mainItem;

        OrderItem afterDelete = [SELECT ActualShippedQuantity__c FROM OrderItem WHERE Id = :testOrderItem.Id];
        System.assertEquals(0, afterDelete.ActualShippedQuantity__c, 'Delete should refresh the rollup');

        undelete mainItem;

        OrderItem afterUndelete = [SELECT ActualShippedQuantity__c FROM OrderItem WHERE Id = :testOrderItem.Id];
        System.assertEquals(25, afterUndelete.ActualShippedQuantity__c, 'Undelete should refresh the rollup');
        Test.stopTest();
    }
}