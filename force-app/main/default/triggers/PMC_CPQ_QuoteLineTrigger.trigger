trigger PMC_CPQ_QuoteLineTrigger on SBQQ__QuoteLine__c(before insert, before update, after update, before delete) {
	new PMC_CPQ_QuoteLineTriggerHandler().run();
}