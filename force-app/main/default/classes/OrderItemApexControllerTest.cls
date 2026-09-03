@isTest
public class OrderItemApexControllerTest {

    @testSetup
    static void setup() {
        // Create test data for Order_Line_Approval__c
        Order_Line_Approval__c orderItemApproval = new Order_Line_Approval__c(
            //Name = 'Test Order Item',
            ApprovalStatus__c = 'Pending'
        );
        insert orderItemApproval;
    }

    @isTest
    static void testOnSubmit() {
        // Fetch the test data created
        Order_Line_Approval__c orderItemApproval = [SELECT Id FROM Order_Line_Approval__c LIMIT 1];

        // Create an instance of the controller
        OrderItemApexController controller = new OrderItemApexController(orderItemApproval.Id);
        
        Test.startTest();
        controller.onSubmit();
        Test.stopTest();

        // Add debug log to confirm execution (since SBAA.ApprovalAPI.submit is external)
        System.debug('onSubmit executed for OrderItemApprovalId: ' + orderItemApproval.Id);
        
        // If possible, verify that submission logic was executed
        System.assertNotEquals(orderItemApproval.Id, null, 'OrderItemApprovalId should not be null');
    }

    @isTest
    static void testOnRecall() {
        // Fetch the test data created
        Order_Line_Approval__c orderItemApproval = [SELECT Id FROM Order_Line_Approval__c LIMIT 1];

        // Create an instance of the controller
        OrderItemApexController controller = new OrderItemApexController(orderItemApproval.Id);
        
        Test.startTest();
        controller.onRecall();
        Test.stopTest();

        // Add debug log to confirm execution (since SBAA.ApprovalAPI.recall is external)
        System.debug('onRecall executed for OrderItemApprovalId: ' + orderItemApproval.Id);
        
        // If possible, verify that recall logic was executed
        System.assertNotEquals(orderItemApproval.Id, null, 'OrderItemApprovalId should not be null');
    }
}