@isTest
private class ShipmentItemVisibilityBatchTest {
    @TestSetup
    static void setup() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Customer'
        );
        insert testAccount;

        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Name = 'Test Order',
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert testOrder;

        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;
        
        List<OrderItem> orderItems = new List<OrderItem>();
        for (Integer i = 0; i < 5; i++) {
            orderItems.add(new OrderItem(
                OrderId = testOrder.Id,
                Product2Id = testProduct.Id,
                Quantity = 1,
                UnitPrice = 100
            ));
        }
        insert orderItems;
        
        List<Shipment> shipments = new List<Shipment>();
        for (Integer i = 0; i < 3; i++) {
            shipments.add(new Shipment(
                Status = 'Shipped',
                ShipToName = 'Test Customer ' + i
            ));
        }
        insert shipments;
        
        List<ShipmentItem> shipmentItems = new List<ShipmentItem>();
        shipmentItems.add(new ShipmentItem(
            ShipmentId = shipments[0].Id,
            PMC_CPQ_OrderProduct__c = orderItems[0].Id,
            isFPD__c = false,
            isVisible__c = false,
            Quantity = 1,
            PMC_CPQ_DeliveryQuantity__c = 10
        ));

        shipmentItems.add(new ShipmentItem(
            ShipmentId = shipments[1].Id,
            PMC_CPQ_OrderProduct__c = orderItems[0].Id,
            isFPD__c = true,
            isVisible__c = false,
            Quantity = 1,
            PMC_CPQ_DeliveryQuantity__c = 20
        ));

        shipmentItems.add(new ShipmentItem(
            ShipmentId = shipments[0].Id,
            PMC_CPQ_OrderProduct__c = orderItems[1].Id,
            isFPD__c = true,
            isVisible__c = false,
            Quantity = 1,
            PMC_CPQ_DeliveryQuantity__c = 30
        ));

        shipmentItems.add(new ShipmentItem(
            ShipmentId = shipments[1].Id,
            PMC_CPQ_OrderProduct__c = orderItems[2].Id,
            isFPD__c = false,
            isVisible__c = false,
            Quantity = 1,
            PMC_CPQ_DeliveryQuantity__c = 40
        ));

        shipmentItems.add(new ShipmentItem(
            ShipmentId = shipments[2].Id,
            PMC_CPQ_OrderProduct__c = orderItems[3].Id,
            isFPD__c = true,
            isVisible__c = false,
            Quantity = 1,
            PMC_CPQ_DeliveryQuantity__c = 50
        ));
        
        insert shipmentItems;
        
        PMC_CPQ_Invoice__c invoice = new PMC_CPQ_Invoice__c(
            PMC_CPQ_OrderProduct__c = orderItems[3].Id
        );
        insert invoice;
    }
    
    @isTest
    static void testBatchExecution_DefaultBatchSize() {
        Test.startTest();
        Id jobId = ShipmentItemVisibilityBatch.executeBatch();
        Test.stopTest();
        
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        
        System.assertEquals('Completed', job.Status, 'Batch should complete successfully');
        System.assertEquals(0, job.NumberOfErrors, 'Batch should have no errors');
        System.assertNotEquals(null, job.TotalJobItems, 'Batch should process items');
        
        List<ShipmentItem> updatedItems = [
            SELECT Id, isVisible__c, PMC_CPQ_OrderProduct__c
            FROM ShipmentItem
            ORDER BY CreatedDate DESC
        ];
        
        System.assert(!updatedItems.isEmpty(), 'Should have ShipmentItems');
        
        Set<Id> orderItemsWithVisibleShipment = new Set<Id>();
        for (ShipmentItem item : updatedItems) {
            if (item.isVisible__c) {
                orderItemsWithVisibleShipment.add(item.PMC_CPQ_OrderProduct__c);
            }
        }
        
        System.assert(!orderItemsWithVisibleShipment.isEmpty(), 
            'At least one OrderItem should have a visible ShipmentItem');
    }
    
    @isTest
    static void testBatchExecution_CustomBatchSize() {
        Test.startTest();
        Id jobId = ShipmentItemVisibilityBatch.executeBatch(50);
        Test.stopTest();
        
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        
        System.assertEquals('Completed', job.Status, 'Batch should complete successfully');
        System.assertEquals(0, job.NumberOfErrors, 'Batch should have no errors');
    }
    
    @isTest
    static void testBatchExecution_DirectInstantiation() {
        Test.startTest();
        ShipmentItemVisibilityBatch batch = new ShipmentItemVisibilityBatch(100);
        Id jobId = Database.executeBatch(batch, 100);
        Test.stopTest();
        
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        
        System.assertEquals('Completed', job.Status, 'Batch should complete successfully');
    }
    
    @isTest
    static void testBatchExecution_VerifyVisibilityLogic() {
        List<OrderItem> orderItems = [SELECT Id FROM OrderItem ORDER BY CreatedDate ASC];
        
        Test.startTest();
        ShipmentItemVisibilityBatch.executeBatch();
        Test.stopTest();
        
        List<ShipmentItem> scenario1Items = [
            SELECT Id, isVisible__c, isFPD__c
            FROM ShipmentItem
            WHERE PMC_CPQ_OrderProduct__c = :orderItems[0].Id
            ORDER BY CreatedDate DESC
        ];
        
        Integer visibleCount = 0;
        for (ShipmentItem item : scenario1Items) {
            if (item.isVisible__c) visibleCount++;
        }
        System.assertEquals(1, visibleCount, 
            'Exactly one ShipmentItem should be visible for Scenario 1');
        
        List<ShipmentItem> scenario2Items = [
            SELECT Id, isVisible__c, isFPD__c
            FROM ShipmentItem
            WHERE PMC_CPQ_OrderProduct__c = :orderItems[1].Id
        ];
        
        if (!scenario2Items.isEmpty()) {
            System.assertEquals(true, scenario2Items[0].isFPD__c, 
                'Scenario 2 should be FPD');
        }
        
        List<ShipmentItem> scenario4Items = [
            SELECT Id, isVisible__c, isFPD__c
            FROM ShipmentItem
            WHERE PMC_CPQ_OrderProduct__c = :orderItems[3].Id
        ];
        
        for (ShipmentItem item : scenario4Items) {
            System.assertEquals(false, item.isVisible__c, 
                'FPD ShipmentItem with Invoice should not be visible');
        }
    }
    
    @isTest
    static void testBatchExecution_NoShipmentItems() {
        delete [SELECT Id FROM ShipmentItem];
        
        Test.startTest();
        Id jobId = ShipmentItemVisibilityBatch.executeBatch();
        Test.stopTest();
        
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        
        System.assertEquals('Completed', job.Status, 
            'Batch should complete even with no ShipmentItems');
        System.assertEquals(0, job.NumberOfErrors, 'Should have no errors');
    }
    
    @isTest
    static void testBatchExecution_RecalculatesActualShippedQuantity() {
        List<OrderItem> orderItems = [SELECT Id FROM OrderItem ORDER BY CreatedDate ASC];

        Test.startTest();
        ShipmentItemVisibilityBatch.executeBatch();
        Test.stopTest();

        Map<Id, OrderItem> updatedOrderItems = new Map<Id, OrderItem>(
            [SELECT Id, ActualShippedQuantity__c FROM OrderItem WHERE Id IN :orderItems]
        );

        List<ShipmentItem> ttVisibleItems = [
            SELECT Id, PMC_CPQ_OrderProduct__c, PMC_CPQ_DeliveryQuantity__c
            FROM ShipmentItem
            WHERE isTTVisible__c = TRUE AND PMC_CPQ_OrderProduct__c != null
        ];

        Map<Id, Decimal> expectedTotals = new Map<Id, Decimal>();
        for (ShipmentItem item : ttVisibleItems) {
            Decimal current = expectedTotals.containsKey(item.PMC_CPQ_OrderProduct__c)
                ? expectedTotals.get(item.PMC_CPQ_OrderProduct__c)
                : 0;
            expectedTotals.put(
                item.PMC_CPQ_OrderProduct__c,
                current + (item.PMC_CPQ_DeliveryQuantity__c == null ? 0 : item.PMC_CPQ_DeliveryQuantity__c)
            );
        }

        for (Id orderItemId : expectedTotals.keySet()) {
            System.assertEquals(
                expectedTotals.get(orderItemId),
                updatedOrderItems.get(orderItemId).ActualShippedQuantity__c,
                'ActualShippedQuantity__c should match sum of TT-visible ShipmentItems'
            );
        }
    }

    @isTest
    static void testBatchExecution_VerifyFinishMethod() {
        Test.startTest();
        ShipmentItemVisibilityBatch batch = new ShipmentItemVisibilityBatch();
        Id jobId = Database.executeBatch(batch);
        Test.stopTest();
        
        AsyncApexJob job = [
            SELECT Id, Status, CompletedDate
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        
        System.assertEquals('Completed', job.Status, 'Job should be completed');
        System.assertNotEquals(null, job.CompletedDate, 
            'Job should have completion date');
    }
}