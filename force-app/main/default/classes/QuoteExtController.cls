/**
 * @description This is the controller class for Advanced Approvals on SBQQ__Quote__c
 */
public with sharing class QuoteExtController {
	private Id quoteId;
    /**
 * @description This is the constructor of the class
 * @param stdController - The instance of the standard controller
*/
    public QuoteExtController(ApexPages.StandardController stdController) {
        quoteId = stdController.getId();
    }
    /**
 * @description Method that executes when quote is submitted for approval
 * @return The page reference to the quote
 */
	public PageReference onSubmit() {
		if (quoteId != null) {
            SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.Quote__c);
        }
        return new PageReference('/' + quoteId);
    }
    /**
 * @description Method that executes when approval is recalled
 * @return The page reference to the quote
*/
    public PageReference onRecall() {
        if (quoteId != null) {
            SBAA.ApprovalAPI.recall(quoteId, SBAA__Approval__c.Quote__c);
        }
        return new PageReference('/' + quoteId);
    }
}