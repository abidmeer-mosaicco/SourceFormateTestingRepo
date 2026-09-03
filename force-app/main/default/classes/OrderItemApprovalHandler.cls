public with sharing class OrderItemApprovalHandler {
	public static void handleOrderItemSubmission(List<Order_Line_Approval__c> newOrderItemsApproval) {
		for (Order_Line_Approval__c oi : newOrderItemsApproval) {
			// Check if some condition is met for submission (for example, Status or other fields)
			//Order_Line_Approval__c oi = newOrderItemsApproval[0];
			if (oi.ApprovalStatus__c == label.pmc_fpd_pending) {
				// Create an instance of the controller and call the onSubmit method
				OrderItemApexController controller = new OrderItemApexController(oi.Id);
				controller.onSubmit(); // Or controller.onRecall() depending on your use case
			}
		}
	}
}