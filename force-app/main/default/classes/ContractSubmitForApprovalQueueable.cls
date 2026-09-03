/**
 * Queueable class to submit approval for a quote and update execution line status/step.
 */
public with sharing class ContractSubmitForApprovalQueueable implements Queueable, Database.AllowsCallouts {
    private Id executionLineId;
    private Id quoteId;

    public ContractSubmitForApprovalQueueable(Id executionLineId, Id quoteId) {
        this.executionLineId = executionLineId;
        this.quoteId = quoteId;
    }

    public void execute(QueueableContext context) {
        if (executionLineId == null || quoteId == null) {
            return;
        }

        // MassUpdateExecutionLine__c line = [SELECT Id, Status__c, Step__c FROM MassUpdateExecutionLine__c WHERE Id = :executionLineId LIMIT 1];
        // try {
        //     // Fire approval submission
        //     SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.Quote__c);
        //     line.Status__c = 'In Progress';
        //     line.Step__c = 'Submit for Approval';
        //     update line;
        // } catch (Exception ex) {
        //     line.Status__c = 'Error';
        //     line.Step__c = 'Submit for Approval';
        //     update line;
        //     throw ex;
        // }

        List<MassUpdateExecutionLine__c> lines = [
            SELECT Id, CreatedQuote__c, Status__c, Step__c, FinishedSteps__c, Contract__c, Contract__r.PMC_CLM_AmendmentNumber__c
            FROM MassUpdateExecutionLine__c
            WHERE Id = :executionLineId AND CheckEligibilityStatus__c = 'Eligible'
        ];
        try {
            List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
            for (MassUpdateExecutionLine__c line : lines) {
                if (line.CreatedQuote__c != null) {
                    line.Status__c = 'Success';
                    line.Step__c = 'Submit for Approval';
                    line.FinishedSteps__c = StringUtils.addPicklistValueToMultiSelect(line.FinishedSteps__c, 'Submit for Approval');
                    quotes.add(
                        new SBQQ__Quote__c(
                            Id = line.CreatedQuote__c,
                            SBQQ__Status__c = 'Approved',
                            ApprovalStatus__c = 'Approved',
                            PMC_CPQ_FlowVRByPassToggle__c = true,
                            PMC_CPQ_AutoApprovedToggle__c = true,
                            SubmittedUser__c = UserInfo.getUserId()
                        )
                    );
                }
            }
            if (!lines.isEmpty()) {
                SBQQ.TriggerControl.disable();
                update lines;
                update quotes;
                SBQQ.TriggerControl.enable();
            }
            // Update the quote status to accepted so that the PMC_CPQ_AfterCreateUpdateQuoteFlow updates contract's PMC_CLM_AmendmentNumber__c correctly.
            if (!quotes.isEmpty()) {
                for (SBQQ__Quote__c quote : quotes) {
                    quote.SBQQ__Status__c = 'Accepted';
                }
                SBQQ.TriggerControl.disable();
                update quotes;
                SBQQ.TriggerControl.enable();
            }
        } catch (Exception ex) {
            update new MassUpdateExecutionLine__c(
                Id = executionLineId,
                Message__c = ex.getMessage(),
                Status__c = 'Error',
                Step__c = 'Submit for Approval'
            );
        }
    }
}