public without sharing class MassApprovalVFController {
	public List<SBAA__Approval__c> approvals { get; set; }
	public Boolean processing { get; set; }
	public Boolean redirect { get; set; }
	public String recordId { get; set; }
	public String message { get; set; }
	public Boolean showModal { get; set; }
	public Boolean approvalMode { get; set; }
	private List<Id> selectedIds = new List<Id>();

	public MassApprovalVFController(ApexPages.StandardSetController controller) {
		this.recordId = ApexPages.currentPage().getParameters().get('recordId');
		if (String.isNotBlank(this.recordId)) {
			this.approvals = new List<SBAA__Approval__c>{ new SBAA__Approval__c(Id = recordId) };
		} else {
			this.approvals = (List<SBAA__Approval__c>) controller.getSelected();
		}
		System.debug('init 1 this.approvals' + JSON.serializePretty(this.approvals));
		this.approvalMode = ApexPages.currentPage().getParameters().get('mode') == 'approve';

		for (SBAA__Approval__c approval : this.approvals) {
			selectedIds.add(approval.Id);
		}
		this.showModal = true;
		this.processing = false;
		this.redirect = false;
		this.message = '';
	}

	public PageReference approveSelected() {
		System.debug('approveSelected this.approvals' + JSON.serializePretty(this.approvals));
		System.debug('approveSelected this.selectedIds' + JSON.serializePretty(this.selectedIds));
		List<SBAA__Approval__c> recordsToUpdate = new List<SBAA__Approval__c>();
		List<Order_Line_Approval__c> orderLineApprovalsUpdate = new List<Order_Line_Approval__c>();
		List<String> errorMessages = new List<String>();
		Map<Id, Set<Id>> mapUsersByOrder = new Map<Id, Set<Id>>();

		this.processing = true;
		this.showModal = false;
		String status = this.approvalMode ? 'Approved' : 'Rejected';
		if (this.approvals == null || this.approvals.isEmpty()) {
			processing = false;
			ApexPages.addMessage(
				new ApexPages.Message(
					ApexPages.Severity.ERROR,
					'Error ' + (this.approvalMode ? 'approving' : 'rejecting ') + ' records. ' + errorMessages.size() + ' record(s) failed.'
				)
			);
			return null;
		}

		this.approvals = [
			SELECT
				Id,
				sbaa__Status__c,
				SBAA__ApprovedBy__c,
				OrderItem__r.OrderId,
				OrderItem__r.Order.AccountId,
				sbaa__ApprovalChain__r.OwnerId,
				sbaa__CommentsLong__c,
				Order_Line_Approval__c
			FROM SBAA__Approval__c
			WHERE Id IN :this.selectedIds
		];

		Map<Id, Account> mapAccounts = getMapAccounts(this.approvals);

		for (SBAA__Approval__c approval : this.approvals) {
			if (approval.sbaa__Status__c == 'Requested') {
				recordsToUpdate.add(
					new SBAA__Approval__c(
						Id = approval.Id,
						SBAA__Status__c = status,
						SBAA__ApprovedBy__c = UserInfo.getUserId(),
						sbaa__CommentsLong__c = 'Mass ' + (this.approvalMode ? 'approval' : 'reject '),
						PMC_CPQ_SendEmail__c = true
					)
				);

				orderLineApprovalsUpdate.add(new Order_Line_Approval__c(Id = approval.Order_Line_Approval__c, ApprovalStatus__c = status));
				Id accountId = approval.OrderItem__r.Order.AccountId;
				for (AccountTeamMember accTeamMember : mapAccounts.get(accountId).AccountTeamMembers) {
					Set<Id> userIds = mapUsersByOrder.get(approval.OrderItem__r.OrderId);
					if (userIds == null) {
						userIds = new Set<Id>();
					}
					userIds.add(accTeamMember.UserId);
					mapUsersByOrder.put(approval.OrderItem__r.OrderId, userIds);
				}
			}
		}

		if (!recordsToUpdate.isEmpty()) {
			List<Database.SaveResult> results = Database.update(recordsToUpdate, false);
			Integer successCount = 0;

			for (Integer i = 0; i < results.size(); i++) {
				if (results[i].isSuccess()) {
					successCount++;
				} else {
					for (Database.Error err : results[i].getErrors()) {
						errorMessages.add('Error in record' + recordsToUpdate[i].Id + ': ' + err.getMessage());
					}
				}
			}

			if (!errorMessages.isEmpty()) {
				ApexPages.addMessage(
					new ApexPages.Message(
						ApexPages.Severity.ERROR,
						'Error ' + (this.approvalMode ? 'approving' : 'rejecting ') + ' records. ' + errorMessages.size() + ' record(s) failed.'
					)
				);
				for (String msg : errorMessages) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
				}
			} else {
				ApexPages.addMessage(
					new ApexPages.Message(
						ApexPages.Severity.CONFIRM,
						successCount + ' Record(s) ' + (this.approvalMode ? 'approved' : 'rejected') + ' successfuly.'
					)
				);
			}
			update orderLineApprovalsUpdate;

			if (this.approvalMode) {
				EmailUtils.sendOrderApprovedEmail(JSON.serialize(mapUsersByOrder));
			} else {
				EmailUtils.sendOrderRejectedEmail(JSON.serialize(mapUsersByOrder));
			}
		}
		processing = false;
		redirect = true;
		return null;
	}

	public String getRedirectUrl() {
		return URL.getOrgDomainUrl().toExternalForm() +
			(String.isNotBlank(this.recordId) ? '/' + this.recordId : '/lightning/o/SBAA__Approval__c/list');
	}

	private Map<Id, Account> getMapAccounts(List<SBAA__Approval__c> approvals) {
		return new Map<Id, Account>(
			[
				SELECT (SELECT UserId FROM AccountTeamMembers WHERE TeamMemberRole IN ('Sales Support Representative', 'Account Manager'))
				FROM Account
				WHERE ID IN :getAccountIdsFromApprovals(this.approvals)
			]
		);
	}

	private Set<Id> getAccountIdsFromApprovals(List<SBAA__Approval__c> approvals) {
		Set<Id> accIds = new Set<Id>();
		for (SBAA__Approval__c approval : approvals) {
			accIds.add(approval.OrderItem__r.Order.AccountId);
		}
		return accIds;
	}
}