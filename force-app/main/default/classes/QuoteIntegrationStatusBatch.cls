/**
* @File Name : QuoteIntegrationStatusBatch.cls
* @Description :
* @Author :Kaushik BP Gohain
* @Last Modified By : Kaushik BP Gohain
* @Last Modified On : 
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 |  |   | Initial Version
**/
public class QuoteIntegrationStatusBatch implements Database.Batchable<SObject>, Schedulable {

    // Start method
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, CPQ_Quote__c
            FROM Quote_Integration_Staging_Log__c
            WHERE Integration_Status__c = 'New'
            AND CPQ_Quote__c != null
        ]);
    }

    // Execute method
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        Set<Id> quoteIds = new Set<Id>();
        Map<Id, Quote_Integration_Staging_Log__c> logMap = new Map<Id, Quote_Integration_Staging_Log__c>();

        for (Quote_Integration_Staging_Log__c log : (List<Quote_Integration_Staging_Log__c>)scope) {
            quoteIds.add(log.CPQ_Quote__c);
            logMap.put(log.CPQ_Quote__c, log);
        }

        if (quoteIds.isEmpty()) return;

        List<SBQQ__Quote__c> quotes = [
            SELECT Id, Name,
                   SBQQ__Status__c,
                   ApprovalStatus__c,
                   PMC_CPQ_ContractStageName__c,
                   PMC_CPQ_IntegrationStatus__c,
                   PMC_CPQ_IntegrationMessage__c,
                   PMC_SendForSignature__c
            FROM SBQQ__Quote__c
            WHERE Id IN :quoteIds
        ];

        List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
        List<Quote_Integration_Staging_Log__c> logsToUpdate = new List<Quote_Integration_Staging_Log__c>();

        for (SBQQ__Quote__c quote : quotes) {
                quote.SBQQ__Status__c = 'Accepted';
                quote.ApprovalStatus__c = 'Approved';
                quote.PMC_CPQ_ContractStageName__c = 'Accepted';
                quote.PMC_CPQ_IntegrationStatus__c = 'Ready';
                quotesToUpdate.add(quote);

            if (logMap.containsKey(quote.Id)) {
                Quote_Integration_Staging_Log__c log = logMap.get(quote.Id);
                //log.Integration_Error__c = quote.PMC_CPQ_IntegrationMessage__c;
                log.Integration_Status__c = 'Completed';
                logsToUpdate.add(log);
            }
        }

        try {
            if (!quotesToUpdate.isEmpty()) update quotesToUpdate;
            if (!logsToUpdate.isEmpty()) update logsToUpdate;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ERROR during update: ' + e.getMessage());
        }
    }

    // Finish method
    public void finish(Database.BatchableContext bc) {
        System.debug('FINISH: Batch execution completed successfully.');
    }

    // Schedulable implementation
    public void execute(SchedulableContext sc) {
        // Run the batch job with batch size 1
        QuoteIntegrationStatusBatch batch = new QuoteIntegrationStatusBatch();
        Database.executeBatch(batch, 1);
    }
}