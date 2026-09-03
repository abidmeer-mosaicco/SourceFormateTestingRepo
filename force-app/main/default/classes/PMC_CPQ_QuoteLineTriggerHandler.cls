public class PMC_CPQ_QuoteLineTriggerHandler extends PMC_TriggerHandler {
	private static final Boolean BOOL_BYPASS_BEFORE_INSERT;
	private static final Boolean BOOL_BYPASS_BEFORE_UPDATE;
	private static final Boolean BOOL_BYPASS_BEFORE_DELETE;
	private static final Boolean BOOL_BYPASS_AFTER_INSERT;
	private static final Boolean BOOL_BYPASS_AFTER_UPDATE;
	private static final Boolean BOOL_BYPASS_AFTER_DELETE;
	private static final Boolean BOOL_BYPASS_AFTER_UNDELETE;

	@testVisible
	public static Boolean boolBypassTriggerLogic = false;

	private List<SBQQ__QuoteLine__c> newList;
	private Map<Id, SBQQ__QuoteLine__c> newMap;
	private List<SBQQ__QuoteLine__c> oldList;
	private Map<Id, SBQQ__QuoteLine__c> oldMap;

	/**
	 * @description This static block initializes the trigger switches when the class is invoked
	 */
	static {
		PMC_TriggerSwitches__mdt operationSwitches = PMC_TriggerSwitches__mdt.getInstance('QuoteLine');
		BOOL_BYPASS_BEFORE_INSERT = operationSwitches.PMC_BeforeInsert__c;
		BOOL_BYPASS_BEFORE_UPDATE = operationSwitches.PMC_BeforeUpdate__c;
		BOOL_BYPASS_BEFORE_DELETE = operationSwitches.PMC_BeforeDelete__c;
		BOOL_BYPASS_AFTER_INSERT = operationSwitches.PMC_AfterInsert__c;
		BOOL_BYPASS_AFTER_UPDATE = operationSwitches.PMC_AfterUpdate__c;
		BOOL_BYPASS_AFTER_DELETE = operationSwitches.PMC_AfterDelete__c;
		BOOL_BYPASS_AFTER_UNDELETE = operationSwitches.PMC_AfterUndelete__c;
	}

	public PMC_CPQ_QuoteLineTriggerHandler() {
		//Instantiating local class variables from trigger variables
		this.newList = Trigger.new;
		this.newMap = (Map<Id, SBQQ__QuoteLine__c>) Trigger.newMap;
		this.oldList = Trigger.old;
		this.oldMap = (Map<Id, SBQQ__QuoteLine__c>) Trigger.oldMap;

		//Set the maximum calls allowed for the class
		this.setMaxLoopCount(8);
	}

	public override void beforeInsert() {
		if (BOOL_BYPASS_BEFORE_INSERT || boolBypassTriggerLogic) {
			return;
		}
		PMC_CPQ_QuoteLineTriggerHelper.copyAmendmentQuoteLineDetails(newList);
		PMC_CPQ_QuoteLineTriggerHelper.updateVCOInsertedLineItems(newList);
	}

	public override void beforeDelete() {
		if (BOOL_BYPASS_BEFORE_DELETE || boolBypassTriggerLogic) {
			return;
		}
		for (SBQQ__QuoteLine__c ql : this.oldList) {
			// Prevent approved Quote Lines deletion
			if (ql.PMC_CPQ_QuoteApprovedExtractor__c) {
				ql.addError(Label.PMC_CPQ_DeleteApprovedQuoteLineErrorMsg);
			}
		}
	}

	public override void afterUpdate() {
		if (BOOL_BYPASS_AFTER_UPDATE || boolBypassTriggerLogic) {
			return;
		}
		PMC_CPQ_QuoteLineTriggerHelper.setContractUpdateCheckEligibilityStatus(newList, oldMap);
	}
}