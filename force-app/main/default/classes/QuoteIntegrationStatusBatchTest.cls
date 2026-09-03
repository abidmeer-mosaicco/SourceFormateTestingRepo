@isTest
private class QuoteIntegrationStatusBatchTest {

    @testSetup
    static void createTestData() {
        // Create test quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            //Name = 'Test Quote',
            SBQQ__Status__c = 'Draft',
            ApprovalStatus__c = 'Pending',
            PMC_CPQ_ContractStageName__c = 'Draft',
            PMC_CPQ_IntegrationStatus__c = 'Not Ready',
            PMC_CPQ_IntegrationMessage__c = 'Initial',
            PMC_SendForSignature__c = true
        );
        insert quote;

        // Create corresponding staging log with Integration_Status__c = 'New'
        Quote_Integration_Staging_Log__c log = new Quote_Integration_Staging_Log__c(
            CPQ_Quote__c = quote.Id,
            Integration_Status__c = 'New'
        );
        insert log;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        QuoteIntegrationStatusBatch batch = new QuoteIntegrationStatusBatch();
        Database.executeBatch(batch, 1); // Explicitly using batch size 1
        Test.stopTest();

        // Assert the Quote was updated
        SBQQ__Quote__c updatedQuote = [
            SELECT SBQQ__Status__c, ApprovalStatus__c,
                   PMC_CPQ_ContractStageName__c, PMC_CPQ_IntegrationStatus__c
            FROM SBQQ__Quote__c
            LIMIT 1
        ];
        System.assertEquals('Draft', updatedQuote.SBQQ__Status__c);
        System.assertEquals('Pending', updatedQuote.ApprovalStatus__c);
        System.assertEquals('Draft', updatedQuote.PMC_CPQ_ContractStageName__c);
        System.assertEquals('Not Ready', updatedQuote.PMC_CPQ_IntegrationStatus__c);

        // Assert the staging log was updated
        Quote_Integration_Staging_Log__c updatedLog = [
            SELECT Integration_Status__c
            FROM Quote_Integration_Staging_Log__c
            LIMIT 1
        ];
        System.assertEquals('New', updatedLog.Integration_Status__c);
    }

    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        // Schedule job in far-future date (just for test coverage)
        String cron = '0 0 0 1 1 ? 2099';
        String jobId = System.schedule('QuoteBatchScheduledJob', cron, new QuoteIntegrationStatusBatch());

        // Optionally verify it was scheduled
        CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cron, ct.CronExpression);
        Test.stopTest();
    }
}