trigger OrderLineApproval on Order_Line_Approval__c(after insert) {
	/*for (Order_Line_Approval__c oi : Trigger.new) {
        OrderItemApprovalHandler.redirectToVisualForcePage(oi.Id);
    }*/
	if (Trigger.isInsert || Trigger.isUpdate) {
		OrderItemApprovalHandler.handleOrderItemSubmission(Trigger.new);
	}

}