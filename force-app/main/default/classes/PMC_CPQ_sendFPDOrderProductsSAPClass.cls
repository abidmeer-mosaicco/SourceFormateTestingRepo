/**
 * @description This class will be used to receive order products from fpdMassUpdate lightning web component and process it and send to SAP or receive
 * price from PriceFX
 * @storynumber GDASF-9421
 */
public without sharing class PMC_CPQ_sendFPDOrderProductsSAPClass {
	/**
	 * @description Common method to fetch OrderItems based on a list of IDs
	 * @param idOps - List of id for which the OrderItem record is to be returned
	 * @return - the result of the SOQL query
	 */
	@TestVisible
	private static List<OrderItem> fetchOrderItems(List<Id> idOps) {
		return [
			SELECT
				Id,
				OrderItemNumber,
				OrderId,
				Order.OrderNumber,
				SBQQ__Contract__r.PMC_CPQ_ContractNumberIdentifier__c,
				PMC_CPQ_LinePONumber__c,
				PMC_CPQ_ShipTo__r.Name,
				Order.AccountId,
				Order.Account.Name,
				Product2.Name,
				Quantity,
				PMC_CPQ_PricingDate__c,
				PMC_CPQ_Floorplusfreight__c,
				PMC_CPQ_FPDPricefromPriceFx__c,
				PMC_CPQ_FinalAgreedPrice__c,
				PMC_CPQ_PriceGuidanceCeiling__c,
				PMC_CPQ_EstFreightPrice__c,
				PMC_CPQ_OrderLineStatus__c,
				PMC_CPQ_OrderItemIntegrationStatus__c,
				PMC_CPQ_OrderItemIntegrationMessage__c,
				ApprovalStatus__c,
				Order.PMC_CPQ_SAPOrderNumber__c,
				(
					SELECT Id, sbaa__Status__c
					FROM Approvals__r
					ORDER BY CreatedDate DESC
					LIMIT 1
				)
			FROM OrderItem
			WHERE Id IN :idOps
		];
	}

	/**
	 * @description This method will be used to send Order products to SAP with negotiated Final Agreed Price
	 * @param lstOlines - String of List of Order Products sent from LWC component or Send To SAP from Order Product RecordPage
	 */
	@AuraEnabled
	public static String saveOPFromUI(String lstOlines) {
		return saveOPFromUI(lstOlines, 'Save and Send to SAP: FPD Component button click.');
	}

	public static String saveOPFromUI(String lstOlines, String sourceIntegrationMessage) {
		Set<Id> recallOrderItems = new Set<Id>();
		Set<Id> approvalRequestOrderItems = new Set<Id>();
		List<PMC_CPQ_OrderProductDetailsWrapperClass> params = (List<PMC_CPQ_OrderProductDetailsWrapperClass>) JSON.deserialize(
			lstOlines,
			List<PMC_CPQ_OrderProductDetailsWrapperClass>.class
		);
		List<Id> idOps = new List<Id>();
		for (PMC_CPQ_OrderProductDetailsWrapperClass wrapper : params) {
			idOps.add(wrapper.customId);
		}
		Map<Id, OrderItem> mapOrderItems = new Map<Id, OrderItem>(fetchOrderItems(idOps));
		for (Integer i = 0; i < params.size(); i++) {
			OrderItem oItem = mapOrderItems.get(params[i].customId);
			Decimal finalAgreedPrice = params[i].finalAgreedPrice != null ? params[i].finalAgreedPrice : 0;

			oItem.PMC_CPQ_FinalAgreedPrice__c = finalAgreedPrice;
			oItem.Agreed_Final_Price__c = finalAgreedPrice;
			oItem.PMC_CPQ_OrderItemIntegrationMessage__c = sourceIntegrationMessage;
			if (requiresApproval(oItem, finalAgreedPrice)) {
				oItem.ApprovalStatus__c = 'Pending Approval';
				oItem.PMC_CPQ_OrderItemIntegrationMessage__c = 'Approval Require';
				approvalRequestOrderItems.add(oItem.Id);
			} else if (oItem.Quantity > 0 && finalAgreedPrice > 0) {
				recallOrderItems.add(oItem.Id);
				oItem.Sent_to_SAP_By__c = UserInfo.getUserId();
				oItem.SendIntegrationResultEmail__c = true;
				oItem.ApprovalStatus__c = 'Approved';
				oItem.PMC_CPQ_OrderItemIntegrationMessage__c = sourceIntegrationMessage + 'Save and Send to SAP: Automatic Approval';
			}
		}

		try {
			if (
				Schema.sObjectType.OrderItem.isAccessible() &&
				Schema.sObjectType.OrderItem.isUpdateable() &&
				Schema.SObjectType.OrderItem.fields.PMC_CPQ_FinalAgreedPrice__c.isUpdateable()
			) {
				if (!approvalRequestOrderItems.isEmpty()) {
					List<SBAA__Approval__c> approvalsToRecall = [
						SELECT
							Id,
							OrderItem__r.OrderId,
							sbaa__Approver__r.sbaa__User__c,
							sbaa__Approver__r.sbaa__GroupId__c,
							sbaa__Status__c
						FROM SBAA__Approval__c
						WHERE OrderItem__c IN :approvalRequestOrderItems AND sbaa__Status__c = 'Requested'
					];

					if (!approvalsToRecall.isEmpty()) {
						Map<Id, Set<Id>> orderIdToUserIds = new Map<Id, Set<Id>>();
						Set<Id> groupIdsToQuery = new Set<Id>();

						for (SBAA__Approval__c approval : approvalsToRecall) {
							approval.sbaa__Status__c = 'Recalled';
						}
						update approvalsToRecall;
					}
				}
				OrderItemTriggerHandler.boolBypassTriggerLogic = true;
				SBQQ.TriggerControl.disable();
				update mapOrderItems.values();
				SBQQ.TriggerControl.enable();
				OrderItemTriggerHandler.boolBypassTriggerLogic = false;
				if (!approvalRequestOrderItems.isEmpty()) {
					orderItemsApprovalRequestsSendEmails(JSON.serialize(approvalRequestOrderItems));
				}

				if (!recallOrderItems.isEmpty()) {
					recallApprovalsAndNotify(JSON.serialize(recallOrderItems));
				}
			}
		} catch (DmlException objException) {
			PMC_ErrorLogClass.processException(objException);
			return 'Error saving Order Products : ' + objException.getMessage();
		}
		return sendOrderProductsToSAP(mapOrderItems.values());
	}

	@Future
	public static void recallApprovalsAndNotify(String strApprovalRequestOrderItems) {
		Set<Id> orderItemIds = (Set<Id>) JSON.deserialize(strApprovalRequestOrderItems, Set<Id>.class);
		List<SBAA__Approval__c> approvalsToRecall = [
			SELECT Id, OrderItem__r.OrderId, sbaa__Approver__r.sbaa__User__c, sbaa__Approver__r.sbaa__GroupId__c, sbaa__Status__c
			FROM SBAA__Approval__c
			WHERE OrderItem__c IN :orderItemIds AND sbaa__Status__c = 'Requested'
		];

		if (approvalsToRecall.isEmpty()) {
			return;
		}

		Map<Id, Set<Id>> orderIdToUserIds = new Map<Id, Set<Id>>();
		Set<Id> groupIdsToQuery = new Set<Id>();

		for (SBAA__Approval__c approval : approvalsToRecall) {
			approval.sbaa__Status__c = 'Recalled';
			approval.PMC_CPQ_SendEmail__c = true;
			if (String.isBlank(approval.sbaa__Approver__r.sbaa__User__c)) {
				groupIdsToQuery.add(approval.sbaa__Approver__r.sbaa__GroupId__c);
			}
		}

		Map<Id, List<GroupMember>> groupIdToMembers = new Map<Id, List<GroupMember>>();
		if (!groupIdsToQuery.isEmpty()) {
			for (GroupMember gm : [
				SELECT GroupId, UserOrGroupId
				FROM GroupMember
				WHERE GroupId IN :groupIdsToQuery
			]) {
				if (!groupIdToMembers.containsKey(gm.GroupId)) {
					groupIdToMembers.put(gm.GroupId, new List<GroupMember>());
				}
				groupIdToMembers.get(gm.GroupId).add(gm);
			}
		}

		for (SBAA__Approval__c approval : approvalsToRecall) {
			Id orderId = approval.OrderItem__r.OrderId;
			Set<Id> userIds = orderIdToUserIds.containsKey(orderId) ? orderIdToUserIds.get(orderId) : new Set<Id>();
			if (String.isNotBlank(approval.sbaa__Approver__r.sbaa__User__c)) {
				userIds.add(approval.sbaa__Approver__r.sbaa__User__c);
			} else if (groupIdToMembers.containsKey(approval.sbaa__Approver__r.sbaa__GroupId__c)) {
				for (GroupMember gm : groupIdToMembers.get(approval.sbaa__Approver__r.sbaa__GroupId__c)) {
					userIds.add(gm.UserOrGroupId);
				}
			}
			if (!userIds.isEmpty()) {
				orderIdToUserIds.put(orderId, userIds);
			}
		}
		update approvalsToRecall;
		if (!orderIdToUserIds.isEmpty()) {
			EmailUtils.sendApprovalRecallEmails(JSON.serialize(orderIdToUserIds));
		}
	}

	@Future
	public static void orderItemsApprovalRequestsSendEmails(String strApprovalRequestOrderItems) {
		Set<Id> orderItemIds = (Set<Id>) JSON.deserialize(strApprovalRequestOrderItems, Set<Id>.class);
		Map<Id, Set<Id>> orderIdToUserIds = new Map<Id, Set<Id>>();
		Map<Id, Set<Id>> aboveCeilingOrderIdToUserIds = new Map<Id, Set<Id>>();
		Set<Id> groupIdsToQuery = new Set<Id>();

		List<SBAA__Approval__c> approvalsToUpdate = [
			SELECT Id, sbaa__Approver__r.sbaa__GroupId__c, sbaa__Approver__r.sbaa__User__c, PMC_CPQ_SendEmail__c, OrderItem__r.OrderId,
				Order_Line_Approval__r.PMC_CPQ_AboveCeiling_Approval_Required__c
			FROM SBAA__Approval__c
			WHERE OrderItem__c IN :orderItemIds
		];

		for (SBAA__Approval__c approval : approvalsToUpdate) {
			if (String.isBlank(approval.sbaa__Approver__r.sbaa__User__c)) {
				groupIdsToQuery.add(approval.sbaa__Approver__r.sbaa__GroupId__c);
			}
			approval.PMC_CPQ_SendEmail__c = true;
		}

		Map<Id, List<GroupMember>> groupIdToMembers = new Map<Id, List<GroupMember>>();
		if (!groupIdsToQuery.isEmpty()) {
			for (GroupMember gm : [
				SELECT GroupId, UserOrGroupId
				FROM GroupMember
				WHERE GroupId IN :groupIdsToQuery
			]) {
				if (!groupIdToMembers.containsKey(gm.GroupId)) {
					groupIdToMembers.put(gm.GroupId, new List<GroupMember>());
				}
				groupIdToMembers.get(gm.GroupId).add(gm);
			}
		}

		for (SBAA__Approval__c approval : approvalsToUpdate) {
			Id orderId = approval.OrderItem__r.OrderId;

			Boolean isAboveCeiling = approval.Order_Line_Approval__r.PMC_CPQ_AboveCeiling_Approval_Required__c;

			if (!isAboveCeiling) {
				Set<Id> userIds = orderIdToUserIds.containsKey(orderId) ? orderIdToUserIds.get(orderId) : new Set<Id>();
				if (String.isNotBlank(approval.sbaa__Approver__r.sbaa__User__c)) {
					userIds.add(approval.sbaa__Approver__r.sbaa__User__c);
				} else if (groupIdToMembers.containsKey(approval.sbaa__Approver__r.sbaa__GroupId__c)) {
					for (GroupMember gm : groupIdToMembers.get(approval.sbaa__Approver__r.sbaa__GroupId__c)) {
						userIds.add(gm.UserOrGroupId);
					}
				}

				if (!userIds.isEmpty()) {
					orderIdToUserIds.put(orderId, userIds);
				}
			} else {
				Set<Id> aboveCeilingUserIds = aboveCeilingOrderIdToUserIds.containsKey(orderId)
					? aboveCeilingOrderIdToUserIds.get(orderId)
					: new Set<Id>();
				if (String.isNotBlank(approval.sbaa__Approver__r.sbaa__User__c)) {
					aboveCeilingUserIds.add(approval.sbaa__Approver__r.sbaa__User__c);
				} else if (groupIdToMembers.containsKey(approval.sbaa__Approver__r.sbaa__GroupId__c)) {
					for (GroupMember gm : groupIdToMembers.get(approval.sbaa__Approver__r.sbaa__GroupId__c)) {
						aboveCeilingUserIds.add(gm.UserOrGroupId);
					}
				}

				if (!aboveCeilingUserIds.isEmpty()) {
					aboveCeilingOrderIdToUserIds.put(orderId, aboveCeilingUserIds);
				}
			}
		}

		if (!approvalsToUpdate.isEmpty()) {
			update approvalsToUpdate;
		}

		if (!orderIdToUserIds.isEmpty()) {
			EmailUtils.sendApprovalRequestEmails(JSON.serialize(orderIdToUserIds));
		}
		if (!aboveCeilingOrderIdToUserIds.isEmpty()) {
			EmailUtils.sendFPDAboveCeilingApprovalRequestEmails(JSON.serialize(aboveCeilingOrderIdToUserIds));
		}
	}

	/**
	 * @description This method will be used to send Order products to SAP with negotiated Final Agreed Price and this function will block to send to SAP if Order products status is Pending Approval and Rejected
	 * @param lstOP - List of Order Products
	 */
	@AuraEnabled
	public static String sendOrderProductsToSAP(List<OrderItem> lstOP) {
		//GCPM-2008 - SAA Start
		PMC_CPQ_FPDActionClass objRef = new PMC_CPQ_FPDActionClass(lstOP, true);
		List<OrderItem> lstOrdItemApp = [
			SELECT id, ApprovalStatus__c, PMC_CPQ_OrderItemIntegrationMessage__c
			FROM OrderItem
			WHERE ID IN :lstOP
		];
		List<OrderItem> lstToUpdateIntegration = new List<OrderItem>();
		List<OrderItem> lstToIntegrate = new List<OrderItem>();
		String message = '';
		for (OrderItem lstOrdItem : lstOrdItemApp) {
			if (lstOrdItem.ApprovalStatus__c == 'Approved') {
				lstToIntegrate.add(lstOrdItem);
			} else {
				lstOrdItem.PMC_CPQ_OrderItemIntegrationMessage__c = 'Approval Require';
				lstToUpdateIntegration.add(lstOrdItem);
			}
		}
		if (!lstToIntegrate.isEmpty()) {
			objRef.bulkSendFPDtoSAPRequest(lstToIntegrate);
		}
		try {
			if (!lstToUpdateIntegration.isEmpty()) {
				update lstToUpdateIntegration;
				message = 'One or more selected Orders Lines have been sent to PM for approval.';
			}
		} catch (DmlException e) {
			message = 'Error Updating Order Item : ' + e.getMessage();
			PMC_ErrorLogClass.processException(e);
		}
		return message;

		//GCPM-2008 - SAA End
	}

	/**
	 * @description This method will be used to receive the latest price of selected order products from the Price FPD Order Line tab
	 * @param lstOlines - String of List of Order Products sent from LWC component
	 */
	@AuraEnabled
	public static void getPriceFromPriceFX(String lstOlines) {
		List<PMC_CPQ_OrderProductDetailsWrapperClass> params = (List<PMC_CPQ_OrderProductDetailsWrapperClass>) JSON.deserialize(
			lstOlines,
			List<PMC_CPQ_OrderProductDetailsWrapperClass>.class
		);
		List<Id> idOps = new List<Id>();
		for (PMC_CPQ_OrderProductDetailsWrapperClass wrapper : params) {
			idOps.add(wrapper.customId);
		}
		List<OrderItem> lstOP = fetchOrderItems(idOps);
		PMC_CPQ_GetFPDController objRef1 = new PMC_CPQ_GetFPDController(lstOP, true);
		objRef1.bulkGetFPDRequest(lstOP);
	}

	/**
	 * @description This method will retrieve the interface url from the PMC_CPQ_Integration_Endpoint__mdt
	 * @return endpoint- the interface URL string
	 */
	@AuraEnabled(cacheable=true)
	public static string sendFPDPriceFXURL() {
		String strInterface = 'SendFPD';
		PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(strInterface);
		String endpoint = JSON.serialize(strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c);
		return endpoint;
	}

	//added by Monika 05-09

	@AuraEnabled
	public static Map<String, List<PMC_CPQ_OrderProductDetailsWrapperClass>> getRowsForProcessing(
		List<Id> selectedIds,
		Map<Id, Decimal> updatedPrices
	) {
		List<PMC_CPQ_OrderProductDetailsWrapperClass> approvalRows = new List<PMC_CPQ_OrderProductDetailsWrapperClass>();
		List<PMC_CPQ_OrderProductDetailsWrapperClass> nonApprovalRows = new List<PMC_CPQ_OrderProductDetailsWrapperClass>();

		Map<Id, OrderItem> mapOrderItems = new Map<Id, OrderItem>(fetchOrderItems(selectedIds));
		for (Id id : selectedIds) {
			OrderItem oItem = mapOrderItems.get(id);

			PMC_CPQ_OrderProductDetailsWrapperClass row = convertOrderItemToWrapper(oItem); // helper to map OrderItem to wrapper
			//added
			if (updatedPrices != null && updatedPrices.containsKey(id)) {
				row.finalAgreedPrice = updatedPrices.get(id);
			}

			Decimal finalAgreedPrice = row.finalAgreedPrice != null ? row.finalAgreedPrice : 0;

			if (requiresApproval(oItem, finalAgreedPrice)) {
				approvalRows.add(row);
			} else {
				nonApprovalRows.add(row);
			}
		}

		Map<String, List<PMC_CPQ_OrderProductDetailsWrapperClass>> result = new Map<String, List<PMC_CPQ_OrderProductDetailsWrapperClass>>();
		result.put('approvalRows', approvalRows);
		result.put('nonApprovalRows', nonApprovalRows);
		return result;
	}

	@TestVisible
	private static PMC_CPQ_OrderProductDetailsWrapperClass convertOrderItemToWrapper(OrderItem oItem) {
		PMC_CPQ_OrderProductDetailsWrapperClass wrap = new PMC_CPQ_OrderProductDetailsWrapperClass();
		wrap.customId = oItem.Id;
		wrap.quantity = oItem.Quantity;
		wrap.finalAgreedPrice = oItem.PMC_CPQ_FinalAgreedPrice__c;
		wrap.productName = oItem.Product2.Name;
		wrap.orderNum = oItem.Order.OrderNumber;
		wrap.contractNum = oItem.SBQQ__Contract__r != null ? oItem.SBQQ__Contract__r.PMC_CPQ_ContractNumberIdentifier__c : null;
		wrap.freight = oItem.PMC_CPQ_EstFreightPrice__c;
		wrap.integrationMessage = oItem.PMC_CPQ_OrderItemIntegrationMessage__c;
		wrap.approvalStatus = oItem.ApprovalStatus__c;
		wrap.sapOrderNumber = oItem.Order.PMC_CPQ_SAPOrderNumber__c;
		return wrap;
	}

	/**
	 * @description Centralized approval requirement logic to avoid duplication and guarantee consistent criteria.
	 * Criteria: Quantity > 10000 OR Final Agreed Price below Floor+Freight OR (Final Agreed Price - Freight) above Ceiling
	 * Null numeric fields are treated as zero.
	 * @param oItem - OrderItem record (must include Quantity, PMC_CPQ_Floorplusfreight__c, PMC_CPQ_PriceGuidanceCeiling__c, PMC_CPQ_EstFreightPrice__c)
	 * @param finalAgreedPrice - Decimal (already defaulted to 0 if null by caller)
	 * @return Boolean indicating whether approval is required
	 */
	private static Boolean requiresApproval(OrderItem oItem, Decimal finalAgreedPrice) {
		Decimal floorPlusFreight = oItem.PMC_CPQ_Floorplusfreight__c != null ? oItem.PMC_CPQ_Floorplusfreight__c : 0;
		Decimal ceilingPrice = oItem.PMC_CPQ_PriceGuidanceCeiling__c != null ? oItem.PMC_CPQ_PriceGuidanceCeiling__c : 0;
		Decimal freightPrice = oItem.PMC_CPQ_EstFreightPrice__c != null ? oItem.PMC_CPQ_EstFreightPrice__c : 0;
		return (oItem.Quantity > 10000 || finalAgreedPrice < floorPlusFreight || (finalAgreedPrice - freightPrice) > ceilingPrice);
	}
}