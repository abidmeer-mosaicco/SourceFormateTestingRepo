/**
 * @description Test class for QuoteUpdateContractsCalloutQueueable
 * This class tests the asynchronous processing of contract updates and the handling of CPI responses.
 * It covers scenarios such as successful callouts, callouts with null execution line IDs, 
 * and the proper updating of execution line records based on CPI responses.
 * 
 * @author Sergio Umlauf
 * @storynumber GCPM-2771
 */
@IsTest
public class QuoteUpdateContractsCalloutQueueableTest {
    @TestSetup
    static void setupData() {
        // Create a test user
        String strSandboxName = UserInfo.getUserName().substringAfterLast('.');
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Sales User'];

        // Creating 2 users to test the scenario where there are multiple quotes with different account managers.
        List<User> users = QuoteUpdateTestUtils.createSalesUsers(2);

        // Create a test account
        Account account = QuoteUpdateTestUtils.createAccount();

        // Create a test contact
        Contact contact = QuoteUpdateTestUtils.createContact();

        // Create a few quotes
        List<SBQQ__Quote__c> quotes = QuoteUpdateTestUtils.createQuotes(3, account, contact, users);

        // Create contracts related to the quotes
        SBQQ.TriggerControl.disable();
        List<Contract> contracts = QuoteUpdateTestUtils.createContracts(quotes, account);
        SBQQ.TriggerControl.enable();

        // Create dummy MassUpdateExecution__c
        MassUpdateExecution__c exec = QuoteUpdateTestUtils.createMassUpdateExecution();

        // Create MassUpdateExecutionLine__c records related to the contracts and the execution
        MassUpdateExecutionLine__c line = QuoteUpdateTestUtils.createMassUpdateExecutionLine(exec, contracts[0]);
    }

    /**
     * @description Test the execute method of QuoteUpdateContractsCalloutQueueable with valid data.
     * It verifies that the execution line status is updated to 'Queued' or 'Error' based on the CPI response and that a message is populated.
     * Expected Result: The execution line status should be 'Queued' or 'Error', and the message should not be blank.
     */
    @IsTest
    static void testExecute() {
        MassUpdateExecutionLine__c lineBefore = [SELECT Id, Status__c FROM MassUpdateExecutionLine__c LIMIT 1];
        MassUpdateExecution__c exec = [SELECT Id FROM MassUpdateExecution__c LIMIT 1];
        QuoteUpdateUtils.ContractJsonResult contractJsonResult = new QuoteUpdateUtils().createContractJson(lineBefore.Id);
        Test.startTest();
        System.enqueueJob(new QuoteUpdateContractsCalloutQueueable(contractJsonResult.json, lineBefore.Id, exec.Id));
        Test.stopTest();
        MassUpdateExecutionLine__c lineAfter = [SELECT Id, Status__c, Message__c FROM MassUpdateExecutionLine__c WHERE Id = :lineBefore.Id LIMIT 1];
        System.assert(
            lineAfter.Status__c.contains('Queued') || lineAfter.Status__c.contains('Error'),
            'Execution line status should be Queued or Error after processing.'
        );
        System.assert(!String.isBlank(lineAfter.Message__c), 'Execution line message should be populated after processing.');
    }

    /**
     * @description Test the execute method of QuoteUpdateContractsCalloutQueueable with a null execution line ID.
     * It verifies that the method handles the null execution line ID gracefully without throwing exceptions and that 
     * the execution line status remains unchanged.
     * Expected Result: The execution line status should remain unchanged, and no exceptions should be thrown.
     * Note: This test assumes that the initial status of the execution line is 'Success' for validation purposes.
     */
    @IsTest
    static void testExecuteWithNullLineId() {
        MassUpdateExecutionLine__c lineBefore = [SELECT Id, Status__c FROM MassUpdateExecutionLine__c LIMIT 1];
        MassUpdateExecution__c exec = [SELECT Id FROM MassUpdateExecution__c LIMIT 1];
        QuoteUpdateUtils.ContractJsonResult contractJsonResult = new QuoteUpdateUtils().createContractJson(lineBefore.Id);
        Test.startTest();
        System.enqueueJob(new QuoteUpdateContractsCalloutQueueable(contractJsonResult.json, null, exec.Id));
        Test.stopTest();
        MassUpdateExecutionLine__c lineAfter = [SELECT Id, Status__c, Message__c FROM MassUpdateExecutionLine__c WHERE Id = :lineBefore.Id LIMIT 1];
        System.assertEquals('Success', lineAfter.Status__c, 'Execution line status should remain Success after processing with null execution line Id.');
    }
}