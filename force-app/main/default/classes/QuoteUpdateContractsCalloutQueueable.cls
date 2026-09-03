/**
 * @description Queueable class to handle callouts for updating contracts in S4 via CPI.
 * @author Sergio Umlauf
 * @storynumber GCPM-2771
 */
public with sharing class QuoteUpdateContractsCalloutQueueable implements Queueable, Database.AllowsCallouts {
    private String contractJson;
    private Id executionLineId;
    private Id executionId;

    public QuoteUpdateContractsCalloutQueueable(String contractJson, Id executionLineId, Id executionId) {
        this.contractJson = contractJson;
        this.executionLineId = executionLineId;
        this.executionId = executionId;
    }

    public void execute(QueueableContext context) {
        if (executionLineId == null) {
            System.debug('Execution Line ID is null. Aborting callout.');
            return;
        }
        QuoteUpdateContractsService.CPIResponse cpiResponse = QuoteUpdateContractsService.sendContracts(contractJson);
        updateExecutionWithCPIResult(executionLineId, cpiResponse);
    }

    private void updateExecutionWithCPIResult(Id executionLineId, QuoteUpdateContractsService.CPIResponse cpiResponse) {
        Boolean isSuccess = false;
        String message;

        if (cpiResponse != null && !String.isBlank(cpiResponse.message)) {
            if (cpiResponse.isSuccess && cpiResponse.message.toUpperCase() == '200 OK') {
                isSuccess = true;
                message = 'Contract Sales Office/Account Manager update enqueued.';
            } else {
                message = cpiResponse.message;
            }
        } else {
            message = 'No response from CPI';
        }

        // Update the records with the CPI result
        if (executionLineId != null) {
            updateExecutionLine(executionLineId, isSuccess, message);
        }
    }

    // Update the execution line record with the CPI result
    private void updateExecutionLine(Id executionLineId, Boolean isSuccess, String message) {
        try {
            MassUpdateExecutionLine__c line = [
                SELECT Id, Status__c, Step__c, Message__c
                FROM MassUpdateExecutionLine__c
                WHERE Id = :executionLineId
                LIMIT 1
            ];
            line.Status__c = (isSuccess ? 'In Progress' : 'Error');
            line.Step__c = 'Update Quotes';
            line.Message__c = message;
            update line;
        } catch (Exception ex3) {
            System.debug('Failed to update execution line after CPI callout: ' + ex3.getMessage());
        }
    }
}