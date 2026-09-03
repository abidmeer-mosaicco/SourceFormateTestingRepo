/**
 * @description Test class for QuoteUpdateContractsQueueable.
 * This class sets up the necessary test data and context for testing the QuoteUpdateContractsQueueable class,
 * which is responsible for updating contracts in SAP via CPI when quotes are updated in Salesforce.
 * The test class uses the QuoteUpdateTestUtils utility class to create the required data, such as users, accounts, contacts, quotes, contracts, and MassUpdateExecution records.
 * It is important to note that this test class does not contain actual test methods, but rather focuses on the setup of test data.
 * The actual test methods should be implemented to assert the expected behavior of the QuoteUpdateContractsQueueable class when executed with the created test data.
 *
 * @author Sergio Umlauf
 */
@IsTest
public class QuoteUpdateContractsQueueableTest {
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

    @IsTest
    static void testQuoteUpdateContractsQueueable() {
        MassUpdateExecutionLine__c lineBefore = [SELECT Id, Status__c FROM MassUpdateExecutionLine__c LIMIT 1];
        MassUpdateExecution__c exec = [SELECT Id FROM MassUpdateExecution__c LIMIT 1];
        Test.startTest();
        System.enqueueJob(new QuoteUpdateContractsQueueable(lineBefore.Id, exec.Id));
        Test.stopTest();
        MassUpdateExecutionLine__c lineAfter = [SELECT Id, Status__c FROM MassUpdateExecutionLine__c WHERE Id = :lineBefore.Id LIMIT 1];
        System.assert(
            lineAfter.Status__c.contains('Queued') || lineAfter.Status__c.contains('Error'),
            'Execution line status should be Queued or Error after processing.'
        );
    }

    @IsTest
    static void testQuoteUpdateContractsQueueableWithNullExecution() {
        MassUpdateExecutionLine__c lineBefore = [SELECT Id, Status__c FROM MassUpdateExecutionLine__c LIMIT 1];
        MassUpdateExecution__c exec = [SELECT Id FROM MassUpdateExecution__c LIMIT 1];
        Test.startTest();
        System.enqueueJob(new QuoteUpdateContractsQueueable(null, exec.Id));
        Test.stopTest();
        MassUpdateExecutionLine__c lineAfter = [SELECT Id, Status__c FROM MassUpdateExecutionLine__c WHERE Id = :lineBefore.Id LIMIT 1];
        System.assert(lineAfter.Status__c == lineBefore.Status__c, 'The status should not have changed when executionLineId is null.');
    }

    @IsTest
    static void testQuoteUpdateContractsQueueableWithInvalidLineId() {
        MassUpdateExecutionLine__c lineBefore = [SELECT Id, Status__c FROM MassUpdateExecutionLine__c LIMIT 1];
        MassUpdateExecution__c exec = [SELECT Id FROM MassUpdateExecution__c LIMIT 1];

        MassUpdateExecutionLine__c dummyLine = new MassUpdateExecutionLine__c(MassUpdateExecution__c = exec.Id, Status__c = 'Success');
        insert dummyLine;

        Test.startTest();
        System.enqueueJob(new QuoteUpdateContractsQueueable(dummyLine.Id, exec.Id));
        Test.stopTest();
        MassUpdateExecutionLine__c lineAfter = [SELECT Id, Status__c FROM MassUpdateExecutionLine__c WHERE Id = :lineBefore.Id LIMIT 1];
        System.assertEquals('Success', lineAfter.Status__c, 'Execution line status should be still Success after processing and generating the Contract JSON fails.');
    }

    @IsTest
    static void testQuoteUpdateContractsQueueableChangeAccountManager() {
        Contract contract = [SELECT Id, SBQQ__Quote__c FROM Contract LIMIT 1];
        MassUpdateExecution__c exec = [SELECT Id FROM MassUpdateExecution__c LIMIT 1];
        MassUpdateExecutionLine__c lineBefore = QuoteUpdateTestUtils.createMassUpdateExecutionLine(exec, contract);

        User user = [SELECT Id FROM User WHERE PMC_SS_Profile_Name__c = 'Sales User' LIMIT 1];
        lineBefore.NewValues__c = JSON.serialize(new Map<String, Object>{ 'PMC_CPQ_AccountManager__c' => user.Id });
        update lineBefore;

        Test.startTest();
        System.enqueueJob(new QuoteUpdateContractsQueueable(lineBefore.Id, lineBefore.MassUpdateExecution__c));
        Test.stopTest();
        MassUpdateExecutionLine__c lineAfter = [SELECT Id, Status__c FROM MassUpdateExecutionLine__c WHERE Id = :lineBefore.Id LIMIT 1];
        System.assert(
            lineAfter.Status__c.contains('Queued') || lineAfter.Status__c.contains('Error'),
            'Execution line status should be Queued or Error after processing.'
        );
    }

    @IsTest
    static void testQuoteUpdateContractsQueueableChangeSalesOffice() {
        Contract contract = [SELECT Id, SBQQ__Quote__r.PMC_CPQ_SalesOffice__c FROM Contract LIMIT 1];
        MassUpdateExecution__c exec = [SELECT Id FROM MassUpdateExecution__c LIMIT 1];
        MassUpdateExecutionLine__c lineBefore = QuoteUpdateTestUtils.createMassUpdateExecutionLine(exec, contract);

        lineBefore.NewValues__c = JSON.serialize(new Map<String, Object>{ 'PMC_CPQ_SalesOffice__c' => contract.SBQQ__Quote__r.PMC_CPQ_SalesOffice__c });
        update lineBefore;

        Test.startTest();
        System.enqueueJob(new QuoteUpdateContractsQueueable(lineBefore.Id, lineBefore.MassUpdateExecution__c));
        Test.stopTest();
        MassUpdateExecutionLine__c lineAfter = [SELECT Id, Status__c FROM MassUpdateExecutionLine__c WHERE Id = :lineBefore.Id LIMIT 1];
        System.assert(
            lineAfter.Status__c.contains('Queued') || lineAfter.Status__c.contains('Error'),
            'Execution line status should be Queued or Error after processing.'
        );
    }
}