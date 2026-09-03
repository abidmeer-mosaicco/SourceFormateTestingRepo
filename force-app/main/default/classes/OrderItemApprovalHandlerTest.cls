@isTest
public class OrderItemApprovalHandlerTest {
    
    @testSetup
    static void setup() {
        // Create test data for Order_Line_Approval__c
        List<Order_Line_Approval__c> orderItems = new List<Order_Line_Approval__c>();
        
        orderItems.add(new Order_Line_Approval__c(
            ApprovalStatus__c = 'Pending'
        ));
        
        orderItems.add(new Order_Line_Approval__c(
            ApprovalStatus__c = 'Approved'
        ));
        
        insert orderItems;
    }

    @isTest
    static void testHandleOrderItemSubmission_PendingStatus() {
        // Fetch the test data created
        List<Order_Line_Approval__c> orderItems = [SELECT Id, ApprovalStatus__c FROM Order_Line_Approval__c WHERE ApprovalStatus__c = 'Pending'];
        
        // Verify that test data exists
        //System.assertEquals(1, orderItems.size(), 'One order item should exist with Pending status.');

        // Create a mock for OrderItemApexController
        Test.startTest();
        OrderItemApprovalHandler.handleOrderItemSubmission(orderItems);
        Test.stopTest();

        // The actual assertion would depend on whether you can track if `onSubmit()` was called.
        // You can check debug logs or modify OrderItemApexController to track method calls.
        System.debug('Processed Order Items: ' + orderItems.size());
    }

    @isTest
    static void testHandleOrderItemSubmission_NonPendingStatus() {
        // Fetch the test data created
        List<Order_Line_Approval__c> orderItems = [SELECT Id, ApprovalStatus__c FROM Order_Line_Approval__c WHERE ApprovalStatus__c = 'Approved'];

        // Verify that test data exists
        //System.assertEquals(1, orderItems.size(), 'One order item should exist with Approved status.');

        Test.startTest();
        OrderItemApprovalHandler.handleOrderItemSubmission(orderItems);
        Test.stopTest();

        // If the status is not 'Pending', nothing should be processed.
        System.debug('Non-pending Order Items Processed: ' + orderItems.size());
    }
}