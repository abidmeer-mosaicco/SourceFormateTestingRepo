/**
 * PMC_SS_ApprovalController
 *
 * Exposes methods for Lightning components to:
 * - Retrieve pending approval records assigned to the current user (directly or via Groups)
 * - Process an approval decision (Approve/Reject) with optional comments
 *
 * Data model references (managed package objects):
 * - sbaa__Approval__c: Approval record
 * - sbaa__Approver__c: Approver (may reference a User or Group)
 * - sbaa__ApprovalChain__c: Approval chain used to scope the query
 *
 * All methods are designed for use by LWC via @AuraEnabled. Read methods are cacheable.
 */
public with sharing class PMC_SS_ApprovalController {
    
    /**
     * Returns up to 50 pending approval items for the logged-in user.
     * Includes approvals where the user is the approver or belongs to a Group that is the approver.
     * Results are ordered by CreatedDate DESC and scoped to the "Case Cancel/Rebill Approval Chain".
     *
     * @return List<ApprovalItemDTO> simplified approval rows for UI consumption
     */
    @AuraEnabled(cacheable=true)
    public static List<ApprovalItemDTO> getMyPendingApprovals() {
        List<ApprovalItemDTO> results = new List<ApprovalItemDTO>();
        List<GroupMember> usrGroupLst =  [SELECT Id,GroupId,Group.name,UserOrGroupId,UserOrGroup.name FROM GroupMember WHERE UserOrGroupId =:userinfo.getUserId()];
		List<Id> grpId = new List<Id>();
        for(GroupMember grpM: usrGroupLst){
            grpId.add(grpM.GroupId);
        }
        
        for (sbaa__Approval__c appr : [
            SELECT Id,name,sbaa__Approver__c,sbaa__Approver__r.name,sbaa__Status__c,Case__c,CreatedDate,Case__r.CaseNumber  
            FROM sbaa__Approval__c
            WHERE (sbaa__Approver__r.sbaa__User__c=: userinfo.getUserId() OR 
                   sbaa__Approver__r.sbaa__GroupId__c IN :grpId)
            AND sbaa__Status__c ='Requested' 
            AND sbaa__ApprovalChain__r.name='Case Cancel/Rebill Approval Chain'
            ORDER BY CreatedDate DESC
            LIMIT 50
        ]) {
            ApprovalItemDTO row = new ApprovalItemDTO();
            row.recordId = appr.Id;
            row.approvalNumber = appr.Name;
            row.caseId = appr.Case__c;
            row.caseNumber = appr.Case__r.CaseNumber; 
            row.createdDate = appr.CreatedDate;
            row.status = appr.sbaa__Status__c;
            results.add(row);
        }
        return results;
    }
    
    /**
     * Updates the approval record status to Approved/Rejected and sets comments.
     *
     * @param approvalId Id of the sbaa__Approval__c record
     * @param isApprove true to approve, false to reject
     * @param comments optional comments to store on the approval
     */
    @AuraEnabled
    public static void processApprovalRecord(String approvalId, Boolean isApprove, String comments) {
        if (String.isBlank(approvalId)) {
            throw new AuraHandledException('Approval Id is required.');
        }

        sbaa__Approval__c approval = new sbaa__Approval__c(Id = approvalId);
        approval.sbaa__Status__c = (isApprove == true) ? 'Approved' : 'Rejected';
        approval.sbaa__CommentsLong__c = comments;
        update approval;
    }

    /**
     * Lightweight DTO for surfacing approval data to LWC.
     */
    public class ApprovalItemDTO {
        @AuraEnabled public String recordId;
        @AuraEnabled public String approvalNumber;
        @AuraEnabled public String caseId;
        @AuraEnabled public String caseNumber; 
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String status;
    }
}