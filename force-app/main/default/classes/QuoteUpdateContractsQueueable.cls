/**
 * @description This Queueable class is responsible for processing the update of contracts related to quote updates. 
 * 
 * It is designed to be executed asynchronously to avoid hitting governor limits in Salesforce. 
 * 
 * The class retrieves the necessary information from the MassUpdateExecutionLine__c record, generates a JSON payload for the contract update, 
 * and then enqueues another Queueable job to perform the actual callout to the external system (like SAP/CPI) for updating the contracts. 
 * 
 * The status of the execution line is updated accordingly based on the success or failure of the operations.
 * 
 * @author Sergio Umlauf
 * @storynumber GCPM-2771
 */
public with sharing class QuoteUpdateContractsQueueable implements Queueable, Database.AllowsCallouts {
    private Id executionLineId;
    private Id executionId;

    /**
     * @description Constructor for the Queueable class.
     * @param executionLineId - The Id of the MassUpdateExecutionLine__c record.
     * @param executionId - The Id of the MassUpdateExecution__c record.
     */
    public QuoteUpdateContractsQueueable(Id executionLineId, Id executionId) {
        this.executionLineId = executionLineId;
        this.executionId = executionId;
    }

    /**
     * @description This method executes the Queueable job to update contracts in SAP via CPI.
     * @param context - The QueueableContext provided by the system.
     */
    public void execute(QueueableContext context) {
        if (executionLineId == null || executionId == null) {
            return;
        }

        Boolean isSuccess = true;
        String message;
        String contractJson;
        update new MassUpdateExecutionLine__c(Id = executionLineId, Status__c = 'In Progress', Step__c = 'Update Quotes');

        try {
            QuoteUpdateUtils.ContractJsonResult contractJsonResult = new QuoteUpdateUtils().createContractJson(executionLineId);
            if (!contractJsonResult.success) {
                isSuccess = false;
                message = contractJsonResult.message;
            } else {
                contractJson = contractJsonResult.json;
                // Enqueue a separate Queueable to perform the CPI callout (no pending DML in this transaction).
                System.enqueueJob(new QuoteUpdateContractsCalloutQueueable(contractJson, this.executionLineId, this.executionId));
            }
        } catch (Exception ex) {
            isSuccess = false;
            message = ex.getMessage();
        } finally {
            update new MassUpdateExecutionLine__c(
                Id = executionLineId, 
                Status__c = isSuccess ? 'Queued' : 'Error', 
                Step__c = 'Update Quotes', 
                Message__c = String.isBlank(message) ? (isSuccess ? 'Callout enqueued' : contractJSON) : message
            );
        }
    }
}