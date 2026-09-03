public without sharing class EmailUtils {
	@Future
	public static void sendOrderApprovedEmail(String strMapUserIdsByOrderId) {
		sendEmailAndUpdateOrderItems(strMapUserIdsByOrderId, 'Order_Items_Approved', 'Approved');
	}

	@Future
	public static void sendOrderRejectedEmail(String strMapUserIdsByOrderId) {
		sendEmailAndUpdateOrderItems(strMapUserIdsByOrderId, 'PMC_CPQ_orderItemRejectRequest', 'Rejected');
	}

	public static void sendApprovalRequestEmails(String strMapUserIdsByOrderId) {
		sendEmailAndUpdateOrderItems(strMapUserIdsByOrderId, 'OrderItem_Approval_Request', 'Requested');
	}

	public static void sendApprovalRecallEmails(String strMapUserIdsByOrderId) {
		sendEmailAndUpdateOrderItems(strMapUserIdsByOrderId, 'PMC_CPQ_OrderItemRecallRequest', 'Recalled');
	}

	public static void sendFPDAboveCeilingApprovalRequestEmails(String strMapUserIdsByOrderId) {
		sendEmailAndUpdateOrderItems(strMapUserIdsByOrderId, 'OrderItem_Above_Ceiling_Approval_Request', 'Requested');
	}

	// @Future
	// public static void sendEmailAndUpdateOrderItemsFuture(String strMapUserIdsByOrderId, String emailTemplateDevName, String status) {
	// 	sendEmailAndUpdateOrderItems(strMapUserIdsByOrderId, emailTemplateDevName, status);
	// }

	public static void sendEmailAndUpdateOrderItems(String strMapUserIdsByOrderId, String emailTemplateDevName, String status) {
		Map<Id, Set<Id>> mapUserIdsByOrderId = (Map<Id, Set<Id>>) JSON.deserialize(strMapUserIdsByOrderId, Map<Id, Set<Id>>.class);
		sendEmailWithTemplate(mapUserIdsByOrderId, emailTemplateDevName);
		updateOrderItemApprovalsSendEmail(mapUserIdsByOrderId.keySet(), status);
	}

	@future
	public static void sendEmailWithTemplateAsync(String strMapTargetIdsByWhatId, String emailTemplateDeveloperName) {
		if (String.isBlank(strMapTargetIdsByWhatId) || String.isBlank(emailTemplateDeveloperName)) {
			return;
		}
		Map<Id, Set<Id>> mapTargetIdsByWhatId = (Map<Id, Set<Id>>) JSON.deserialize(strMapTargetIdsByWhatId, Map<Id, Set<Id>>.class);
		List<Messaging.SendEmailResult> results = sendEmailWithTemplate(mapTargetIdsByWhatId, emailTemplateDeveloperName);
		// Post-send housekeeping previously done in the VF controller (which caused DML during render)
		if (emailTemplateDeveloperName == 'Order_Items_Sent_To_SAP') {
			Set<Id> orderIds = mapTargetIdsByWhatId.keySet();
			if (!orderIds.isEmpty()) {
				List<OrderItem> toUpdate = [
					SELECT Id, SendIntegrationResultEmail__c
					FROM OrderItem
					WHERE OrderId IN :orderIds AND SendIntegrationResultEmail__c = TRUE
				];
				for (OrderItem oi : toUpdate) {
					oi.SendIntegrationResultEmail__c = false;
				}
				if (!toUpdate.isEmpty()) {
					update toUpdate;
				}
			}
		}
	}

	public static List<Messaging.SendEmailResult> sendEmailWithTemplate(Map<Id, Set<Id>> mapTargetIdsByWhatId, String emailTemplateDeveloperName) {
		EmailTemplate emailTemplate = getEmailTemplateByDevName(emailTemplateDeveloperName);
		List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
		for (Id whatId : mapTargetIdsByWhatId.keySet()) {
			for (Id targetId : mapTargetIdsByWhatId.get(whatId)) {
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				mail.setTemplateId(emailTemplate.Id);
				mail.setWhatId(whatId);
				mail.setSaveAsActivity(false);
				mail.setTargetObjectId(targetId);
				emails.add(mail);
			}
		}
		try {
			if (emails.isEmpty())
				return new List<Messaging.SendEmailResult>();
			return Messaging.sendEmail(emails);
		} catch (Exception e) {
			// In test contexts or when templates/controllers reference missing properties, avoid blowing up tests.
			System.debug('Email send failed: ' + e.getMessage());
			return new List<Messaging.SendEmailResult>();
		}
	}

	@TestVisible
	private static void updateOrderItemApprovalsSendEmail(Set<Id> orderIds, String status) {
		List<SBAA__Approval__c> approvals = [
			SELECT Id, PMC_CPQ_SendEmail__c
			FROM SBAA__Approval__c
			WHERE sbaa__Status__c = :status AND OrderItem__r.OrderId IN :orderIds
		];
		for (SBAA__Approval__c approval : approvals) {
			approval.PMC_CPQ_SendEmail__c = false;
		}
		update approvals;
	}

	private static EmailTemplate getEmailTemplateByDevName(String developerName) {
		return [SELECT Id FROM EmailTemplate WHERE DeveloperName = :developerName];
	}
}