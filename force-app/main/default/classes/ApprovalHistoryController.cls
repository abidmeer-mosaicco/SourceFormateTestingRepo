public with sharing class ApprovalHistoryController {

    @AuraEnabled(cacheable=true)
    public static List<ApprovalWorkItemWrapper> getApprovalHistory(Id recordId) {
        List<ApprovalWorkItemClone__c> items = [
            SELECT Id, Name, Comments__c, Status__c, ReviewedById__c, ReviewedById__r.Name,
                   Assigned_To__c, ReviewedDate__c
            FROM ApprovalWorkItemClone__c
            WHERE RelatedRecordId__c = :recordId
            ORDER BY CreatedDate DESC
        ];

        List<ApprovalWorkItemWrapper> result = new List<ApprovalWorkItemWrapper>();
        for (ApprovalWorkItemClone__c item : items) {
            result.add(new ApprovalWorkItemWrapper(
                item.Id,
                item.Name,
                item.Comments__c,
                item.Status__c,
                item.ReviewedById__c,
                item.ReviewedById__r != null ? item.ReviewedById__r.Name : null,
                item.Assigned_To__c,
                null,
                item.ReviewedDate__c
            ));
        }
        return result;
    }

    public class ApprovalWorkItemWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String comments;
        @AuraEnabled public String status;
        @AuraEnabled public String reviewedById;
        @AuraEnabled public String reviewedByName;
        @AuraEnabled public String assignedToId;
        @AuraEnabled public String assignedToName;
        @AuraEnabled public DateTime reviewedDate;

        public ApprovalWorkItemWrapper(String id, String name, String comments, String status,
                                       String reviewedById, String reviewedByName,
                                       String assignedToId, String assignedToName,
                                       DateTime reviewedDate) {
            this.id = id;
            this.name = name;
            this.comments = comments;
            this.status = status;
            this.reviewedById = reviewedById;
            this.reviewedByName = reviewedByName;
            this.assignedToId = assignedToId;
            this.assignedToName = assignedToName;
            this.reviewedDate = reviewedDate;
        }
    }
}