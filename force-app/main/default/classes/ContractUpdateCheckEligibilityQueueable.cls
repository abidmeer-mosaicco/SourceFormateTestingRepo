/**
 * Queueable class to process MassUpdateExecutionLine__c records and call eligibility check logic asynchronously.
 */
public with sharing class ContractUpdateCheckEligibilityQueueable implements Queueable, Database.AllowsCallouts {
    private Id executionLineId;
    private Id executionId;

    public ContractUpdateCheckEligibilityQueueable(Id executionLineId, Id executionId) {
        this.executionLineId = executionLineId;
        this.executionId = executionId;
    }

    public void execute(QueueableContext context) {
        if (executionLineId == null) {
            return;
        }
        MassUpdateExecutionLine__c line = [SELECT Id, CreatedQuote__c, Status__c, Step__c, CheckEligibilityStatus__c FROM MassUpdateExecutionLine__c WHERE Id = :executionLineId LIMIT 1];
        Boolean isSuccess = false;
        try {
            SBQQ__Quote__c quote = new SBQQ__Quote__c(Id = line.CreatedQuote__c);
            List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>{ quote };
            List<Boolean> result = PMC_CPQ_FetchLatestPriceBeforeSubmission.postInfoToCPIFromLWC(quotes);
            isSuccess = result != null && result.size() > 0 && result[0];
        } catch (Exception ex) {
            line = new MassUpdateExecutionLine__c(
                Id = line.Id,
                Message__c = ex.getMessage()
            );
        }
        if(!isSuccess){
            line.Message__c = String.isNotBlank(line.Message__c) ? line.Message__c : 'Eligibility check callout failed.';
            line.Status__c = 'Error';
            line.CheckEligibilityStatus__c = 'Error';
        } else {
            line.Status__c = 'In Progress';
        }
        line.Step__c = 'Check Eligibility';
        update line;
    }
}