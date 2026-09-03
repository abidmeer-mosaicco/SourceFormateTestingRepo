public without sharing class OrderItemApexController {
	private Id orderItemApprovalId;

	// Constructor takes an Id directly instead of StandardController
	public OrderItemApexController(Id orderItemApprovalId) {
		this.orderItemApprovalId = orderItemApprovalId;
	}

	// Submit Method
	public void onSubmit() {
		if (orderItemApprovalId != null) {
			SBAA.ApprovalAPI.submit(orderItemApprovalId, SBAA__Approval__c.Order_Line_Approval__c);
		}
	}

	// Recall Method
	public void onRecall() {
		if (orderItemApprovalId != null) {
			SBAA.ApprovalAPI.recall(orderItemApprovalId, SBAA__Approval__c.Order_Line_Approval__c);
		}
	}
}