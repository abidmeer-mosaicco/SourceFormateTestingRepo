public with sharing class ContractUpdateGenContrsQueueable implements Queueable, Database.AllowsCallouts {
    private Id executionLineId;
    private Id quoteId;
    private Id userId;

    public ContractUpdateGenContrsQueueable(Id executionLineId, Id quoteId, Id userId) {
        this.executionLineId = executionLineId;
        this.quoteId = quoteId;
        this.userId = userId;
    }

    public void execute(QueueableContext context) {
        if (executionLineId == null || quoteId == null) {
            return;
        }
        try {
            MassUpdateExecutionLine__c line = [
                SELECT Id, Status__c, Step__c, FinishedSteps__c, CreatedQuote__c
                FROM MassUpdateExecutionLine__c
                WHERE Id = :executionLineId AND CreatedQuote__c = :quoteId AND Step__c = 'Generate Contracts'
                LIMIT 1
            ];
            if (line == null) {
                return;
            }
            
            DocusignWorkflowService.triggerWorkflow(line.CreatedQuote__c, userId);
            
            line.Status__c = 'In Progress';
            update line;
        } catch (Exception ex) {
            System.debug('Error in ContractUpdateGenContrsQueueable: ' + ex.getMessage());
            try {
                update new MassUpdateExecutionLine__c(
                    Id = executionLineId, 
                    Status__c = 'Error', 
                    Step__c = 'Generate Contracts',
                    Message__c = ex.getMessage()
                );
            } catch (Exception dmlEx) {
                System.debug('Failed to update error status: ' + dmlEx.getMessage());
            }
        }
    }
}