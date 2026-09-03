// File: PostExpiryAmendRedirect.cls
public with sharing class PostExpiryAmendRedirect {
    private final Contract contractRecord;
    private enum AmendStartRule { NONE, TODAY, ORIGINAL_END }
    private static final AmendStartRule RULE = AmendStartRule.TODAY; 
    public PostExpiryAmendRedirect(ApexPages.StandardController std) {
        this.contractRecord = (Contract) std.getRecord();
    }

    public PageReference init() {
        if (contractRecord == null || contractRecord.Id == null) {
            return new PageReference('/home/home.jsp');
        }

        // 1) Load Contract FOR UPDATE
        Contract c = [
            SELECT Id, StartDate, EndDate, Status, SBQQ__AmendmentStartDate__c
            FROM Contract
            WHERE Id = :contractRecord.Id
            FOR UPDATE
        ];

        Date today = Date.today();

        // Snapshot original end BEFORE any mutation
        Date originalEnd = c.EndDate;

        // 2) Compute desired EndDate: strictly future and not before StartDate
        Date desiredEnd = today.addDays(1); // ensures EndDate > today
        if (c.StartDate != null && c.StartDate > desiredEnd) {
            desiredEnd = c.StartDate;       // guard: End cannot precede Start
        }

        Boolean changed = false;

        // Update EndDate if behind desiredEnd (guard FLS)
        if (isFieldUpdateAllowed('Contract', 'EndDate') &&
            (c.EndDate == null || c.EndDate < desiredEnd)) {
            c.EndDate = desiredEnd;
            changed = true;
        }

        // 3) Clear Amendment Start Date FIRST (per your request)
        if (isFieldUpdateAllowed('Contract', 'SBQQ__AmendmentStartDate__c') &&
            c.SBQQ__AmendmentStartDate__c != null) {
            c.SBQQ__AmendmentStartDate__c = null;
            changed = true;
        }

        // 4) Decide if the contract was originally expired (based on originalEnd snapshot)
        Boolean wasExpired = (originalEnd == null || originalEnd < today);

        // 5) Optionally set Amendment Start Date, clamped to StartDate
        if (wasExpired && RULE != AmendStartRule.NONE &&
            isFieldUpdateAllowed('Contract', 'SBQQ__AmendmentStartDate__c')) {

            // Candidate from rule
            Date amendStartCandidate;
            if (RULE == AmendStartRule.ORIGINAL_END && originalEnd != null) {
                amendStartCandidate = originalEnd; // original end date
            } else {
                amendStartCandidate = today;       // today
            }

            // Clamp: CPQ requires Amendment Start >= Contract.StartDate
            Date amendStart = amendStartCandidate;
            if (c.StartDate != null && amendStart < c.StartDate) {
                amendStart = c.StartDate;
            }

            if (c.SBQQ__AmendmentStartDate__c != amendStart) {
                c.SBQQ__AmendmentStartDate__c = amendStart;
                changed = true;
            }
        }

        // Optional: warn if Status not Activated (common CPQ precondition)
        if (c.Status != null && c.Status.toLowerCase() != 'activated') {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.WARNING,
                'Contract Status is not Activated. The amend wizard may not proceed.'
            ));
        }

        // 6) Persist changes
        try {
            if (changed) update c;
        } catch (DmlException dmx) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.WARNING,
                'Preflight update failed: ' + dmx.getMessage()
            ));
        }

        // 7) Redirect to managed SBQQ Amend page
        PageReference pr = Page.SBQQ__AmendContract;
        pr.getParameters().put('id', c.Id);  // Contract Id
        pr.setRedirect(true);
        return pr;
    }

    // --- Helpers ---
    @TestVisible private static Boolean isFieldUpdateAllowed(String sObjectApiName, String fieldApiName) {
        try {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(sObjectApiName);
            if (objType == null) return false;
            Schema.DescribeSObjectResult objDesc = objType.getDescribe();
            Schema.SObjectField f = objDesc.fields.getMap().get(fieldApiName);
            if (f == null) return false;
            return f.getDescribe().isUpdateable();
        } catch (Exception e) {
                       return false;
        }
    }

}