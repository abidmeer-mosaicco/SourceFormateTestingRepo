/**
 * @description Test class for PMC_CPQ_QuoteLineTriggerHandler's beforeDelete method
 * @author Raphael Soares
 * @storynumber GCPM-977
 */
@isTest
private class PMC_CPQ_QuoteLineTriggerHandlerTest {
	@testSetup
	static void setupTestData() {
		// Create test account
		Account testAccount = PMC_DH_TestDataFactoryClass.createTestAccount();

		// Create test contact
		Contact testContact = PMC_DH_TestDataFactoryClass.createTestContact(testAccount.Id);

		// Create test opportunity
		Opportunity testOpp = PMC_DH_TestDataFactoryClass.createOpportunity(testAccount);

		// Create test quote
		SBQQ__Quote__c testQuote = PMC_DH_TestDataFactoryClass.createQuote(testAccount, testContact.Id, testOpp);
		testQuote.SBQQ__Status__c = 'Draft';
		update testQuote;

		// Create test product
		Product2 testProduct = PMC_DH_TestDataFactoryClass.createProduct();
		insert testProduct;

		// Create test quote line
		SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote, testProduct);
	}

	/**
	 * @description Test deleting an approved quote line - should be prevented
	 */
	@isTest
	static void testDeleteApprovedQuoteLine() {
		SBQQ__Quote__c testQuote = [SELECT Id, PMC_CPQ_QuoteApproved__c FROM SBQQ__Quote__c LIMIT 1];
		testQuote.PMC_CPQ_QuoteApproved__c = true;
		testQuote.SBQQ__Status__c = 'Approved';
		update testQuote;

		// Get the approved quote line
		SBQQ__QuoteLine__c approvedQuoteLine = [
			SELECT Id
			FROM SBQQ__QuoteLine__c
			WHERE PMC_CPQ_QuoteApprovedExtractor__c = TRUE
			LIMIT 1
		];

		Test.startTest();
		try {
			delete approvedQuoteLine;
			System.assert(false, 'Expected an exception when deleting approved quote line');
		} catch (DmlException e) {
			System.assert(
				e.getMessage().contains(Label.PMC_CPQ_DeleteApprovedQuoteLineErrorMsg),
				'Expected error message: ' + Label.PMC_CPQ_DeleteApprovedQuoteLineErrorMsg
			);
		}
		Test.stopTest();

		// Verify the quote line still exists
		List<SBQQ__QuoteLine__c> remainingLines = [
			SELECT Id
			FROM SBQQ__QuoteLine__c
			WHERE Id = :approvedQuoteLine.Id
		];
		System.assertEquals(1, remainingLines.size(), 'Approved quote line should not be deleted');
	}

	/**
	 * @description Test deleting an unapproved quote line - should be allowed
	 */
	@isTest
	static void testDeleteUnapprovedQuoteLine() {
		// Get the unapproved quote line
		SBQQ__QuoteLine__c unapprovedQuoteLine = [
			SELECT Id
			FROM SBQQ__QuoteLine__c
			WHERE PMC_CPQ_QuoteApprovedExtractor__c = FALSE
			LIMIT 1
		];

		Test.startTest();
		delete unapprovedQuoteLine;
		Test.stopTest();

		// Verify the quote line was deleted
		List<SBQQ__QuoteLine__c> remainingLines = [
			SELECT Id
			FROM SBQQ__QuoteLine__c
			WHERE Id = :unapprovedQuoteLine.Id
		];
		System.assertEquals(0, remainingLines.size(), 'Unapproved quote line should be deleted');
	}

	/**
	 * @description Test deleting quote lines when trigger is bypassed
	 */
	@isTest
	static void testDeleteWithBypassTriggerLogic() {
		// Get both approved and unapproved quote lines
		List<SBQQ__QuoteLine__c> quoteLines = [
			SELECT Id, PMC_CPQ_QuoteApprovedExtractor__c
			FROM SBQQ__QuoteLine__c
		];

		// Enable bypass
		PMC_CPQ_QuoteLineTriggerHandler.boolBypassTriggerLogic = true;

		Test.startTest();
		delete quoteLines;
		Test.stopTest();

		// Verify all quote lines were deleted (bypass should allow deleting approved lines)
		List<SBQQ__QuoteLine__c> remainingLines = [
			SELECT Id
			FROM SBQQ__QuoteLine__c
			WHERE Id IN :quoteLines
		];
		System.assertEquals(0, remainingLines.size(), 'All quote lines should be deleted when bypass is enabled');
	}
}