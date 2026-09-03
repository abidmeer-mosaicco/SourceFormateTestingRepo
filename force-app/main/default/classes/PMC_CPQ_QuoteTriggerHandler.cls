/**
 * @description This class will be used to handle all trigger operations of Quote (SBQQ_Quote__c) object
 * @author Lalit Sharma
 * @storynumber GDASF-8944
 */
public without sharing class PMC_CPQ_QuoteTriggerHandler extends PMC_TriggerHandler {
	/**
	 * These boolean variables are used to bypass the trigger operations
	 */
	private static final Boolean BOOL_BYPASS_BEFORE_INSERT;
	private static final Boolean BOOL_BYPASS_BEFORE_UPDATE;
	private static final Boolean BOOL_BYPASS_BEFORE_DELETE;
	private static final Boolean BOOL_BYPASS_AFTER_INSERT;
	private static final Boolean BOOL_BYPASS_AFTER_UPDATE;
	private static final Boolean BOOL_BYPASS_AFTER_DELETE;
	private static final Boolean BOOL_BYPASS_AFTER_UNDELETE;

	@testVisible
	public static Boolean boolBypassTriggerLogic = false;

	/**
	 * These variables will hold the copy of trigger variables
	 */
	private List<SBQQ__Quote__c> lstNewQuotes;
	private Map<Id, SBQQ__Quote__c> mapNewQuotes;
	private List<SBQQ__Quote__c> lstOldQuotes;
	private Map<Id, SBQQ__Quote__c> mapOldQuotes;

	/**
	 * @description This static block initializes the trigger switches when the class is invoked
	 */
	static {
		PMC_TriggerSwitches__mdt operationSwitches = PMC_TriggerSwitches__mdt.getInstance('Quote');

		BOOL_BYPASS_BEFORE_INSERT = operationSwitches.PMC_BeforeInsert__c;
		BOOL_BYPASS_BEFORE_UPDATE = operationSwitches.PMC_BeforeUpdate__c;
		BOOL_BYPASS_BEFORE_DELETE = operationSwitches.PMC_BeforeDelete__c;
		BOOL_BYPASS_AFTER_INSERT = operationSwitches.PMC_AfterInsert__c;
		BOOL_BYPASS_AFTER_UPDATE = operationSwitches.PMC_AfterUpdate__c;
		BOOL_BYPASS_AFTER_DELETE = operationSwitches.PMC_AfterDelete__c;
		BOOL_BYPASS_AFTER_UNDELETE = operationSwitches.PMC_AfterUndelete__c;
	}
//added by Monika -15-09
    private static final Set<String> allowedEditableFields = new Set<String>{ 
	'PMC_CPQ_ContractShippingInstructions__c', 
   'PMC_CPQ_AccountManager__c', 
   'PMC_CPQ_SalesOffice__c'
    }; 
        private static String runningProfileName;
public static void enforceFieldLock(List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap) {

	/* String runningProfileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1].Name;
    if (runningProfileName == 'System Administrator' || runningProfileName == 'API Only profile' ) {
        return;
    } */
    if (runningProfileName == null) {
        runningProfileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1].Name;
    }

    if (runningProfileName == 'System Administrator' || runningProfileName == 'API Only profile' ) {
        return;
    }

    for (SBQQ__Quote__c newRec : newList) {
        SBQQ__Quote__c oldRec = oldMap.get(newRec.Id);

        
        if (oldRec == null || String.isBlank(oldRec.PMC_CPQ_ContractStageName__c)) {
            continue;
        }
        if(newRec.SBQQ__Status__c=='Rejected')
        {
            continue;
        }
       if (newRec.PMC_CPQ_AccountManager__c != oldRec.PMC_CPQ_AccountManager__c) {
            continue; 
        }
         if (newRec.PMC_CPQ_IntegrationStatus__c != oldRec.PMC_CPQ_IntegrationStatus__c) {
            continue; 
        }

		   if (newRec.PMC_CPQ_SalesOffice__c != oldRec.PMC_CPQ_SalesOffice__c) {
            continue; 
        }
        
        Boolean hasInvalidChange = false;

        
        for (SObjectField field : SBQQ__Quote__c.SObjectType.getDescribe().fields.getMap().values()) {
            String fieldName = field.getDescribe().getName();

           
            if (fieldName.endsWith('Id') 
                || fieldName == 'CreatedDate' 
                || fieldName == 'LastModifiedDate' 
                || fieldName == 'LastModifiedById' 
                || fieldName == 'CreatedById') {
                continue;
            }

          
        /*    if (fieldName == 'PMC_CPQ_ContractStageName__c' || allowedEditableFields.contains(fieldName)) {
                continue;
            }*/

           if (fieldName == 'PMC_CPQ_ContractStageName__c')
		   {
			  continue;
		   }
		    Boolean isAllowed = false; 
               if (allowedEditableFields.contains(fieldName) && fieldName != 'PMC_CPQ_ContractShippingInstructions__c') 
                     { isAllowed = true; } 

					  if (fieldName == 'PMC_CPQ_ContractShippingInstructions__c') 
					  {
						   if(newRec.PMC_CPQ_Region__c == 'Brazil')
						   {
							  isAllowed=true;
						   }
					  }if (isAllowed) { continue; } 

            Object oldVal = oldRec.get(fieldName);
            Object newVal = newRec.get(fieldName);

            
            if ((oldVal == null && newVal != null) || (oldVal != null && !oldVal.equals(newVal))) {
                hasInvalidChange = true;
                break;
            }
        }

        if (hasInvalidChange) {
           // newRec.addError('You cannot edit these fields when Contract Stage is set.');
		    newRec.addError(System.Label.PMC_CPQ_ContractSetValue);
        }
    }


}
	// Track processed quotes to prevent infinite loops
	private static Set<Id> processedQuotes = new Set<Id>();

	/**
	 * @description Constructor method to initialize class level variables and store the trigger collections and add the max loop count of trigger
	 */
	public PMC_CPQ_QuoteTriggerHandler() {
		//Instantiating local class variables from trigger variables
		this.lstNewQuotes = Trigger.new;
		this.mapNewQuotes = (Map<Id, SBQQ__Quote__c>) Trigger.newMap;
		this.lstOldQuotes = Trigger.old;
		this.mapOldQuotes = (Map<Id, SBQQ__Quote__c>) Trigger.oldMap;

		//Set the maximum calls allowed for the class
		this.setMaxLoopCount(32);
	}

	/**
	 * @description This method will perform the operation for before insert trigger
	 */
	public override void beforeInsert() {
		if (BOOL_BYPASS_BEFORE_INSERT || boolBypassTriggerLogic) {
			return;
		}
	}

	/**
	 * @description This method will perform the operation for before update trigger
	 */
	public override void beforeUpdate() {
		if (BOOL_BYPASS_BEFORE_UPDATE || boolBypassTriggerLogic) {
			return;
		}
		PMC_CPQ_QuoteTriggerHelper.validateQuoteExpiration(lstNewQuotes, mapOldQuotes);
        
           
		//added by Monika   
		enforceFieldLock(lstNewQuotes, mapOldQuotes);
	}

	/**
	 * @description This method will perform the operation for before delete trigger
	 */
	public override void beforeDelete() {
		if (BOOL_BYPASS_BEFORE_DELETE || boolBypassTriggerLogic) {
			return;
		}
	}

	/**
	 * @description This method will perform the operation for after insert trigger
	 */
	public override void afterInsert() {
		if (BOOL_BYPASS_AFTER_INSERT || boolBypassTriggerLogic) {
			return;
		}
	}

	/**
	 * @description This method will perform the operation for after update trigger
	 */
	public override void afterUpdate() {
		if (BOOL_BYPASS_AFTER_UPDATE || boolBypassTriggerLogic) {
			return;
		}
		Set<Id> approvedQuotes = new Set<Id>();
		Set<Id> contractStageChangedIds = new Set<Id>();
		for (SBQQ__Quote__c quoteRecord : lstNewQuotes) {
			if (RecordValidator.isFieldChanged(quoteRecord, mapOldQuotes, 'SBQQ__Status__c', 'Approved')) {
				approvedQuotes.add(quoteRecord.Id);
			}
			if (RecordValidator.isFieldChanged(quoteRecord, mapOldQuotes, 'PMC_CPQ_ContractStageName__c')) {
				contractStageChangedIds.add(quoteRecord.Id);
			}
			if (RecordValidator.isFieldChanged(quoteRecord, mapOldQuotes, 'PMC_CPQ_ContractStageName__c', 'Accepted')) {
				PMC_CPQ_QuoteTriggerHelper.validateProductsEntitlementPoliciesAfterAccepted(quoteRecord.Id);
			}
		}
		if (!approvedQuotes.isEmpty() && !System.isFuture() && !System.isBatch()) {
			PMC_CPQ_QuoteTriggerHelper.deleteZeroQuantityLinesAfterApproval(approvedQuotes);
		}

		Set<Id> quotesWithVCOQuotationChanges = new Set<Id>();

		// Identify quotes where the checkbox field PMC_CPQ_VCOQuotation__c actually changed.
		for (SBQQ__Quote__c quoteRecord : lstNewQuotes) {
			SBQQ__Quote__c oldQuote = mapOldQuotes.get(quoteRecord.Id);
			if (
				quoteRecord.PMC_CPQ_RecordTypeName__c == 'Domestic SA' &&
				(quoteRecord.PMC_CPQ_VCOQuotation__c != oldQuote.PMC_CPQ_VCOQuotation__c && !processedQuotes.contains(quoteRecord.Id))
			) {
				quotesWithVCOQuotationChanges.add(quoteRecord.Id);
			}
		}

		if (!quotesWithVCOQuotationChanges.isEmpty()) {
			PMC_CPQ_QuoteTriggerHelper.updateQuoteItemsVCO(quotesWithVCOQuotationChanges, lstNewQuotes);
			// Mark these quotes as processed to prevent infinite loops
			processedQuotes.addAll(quotesWithVCOQuotationChanges);
		}

		if (!approvedQuotes.isEmpty() && !System.isFuture() && !System.isBatch()) {
			PMC_CPQ_QuoteTriggerHelper.setMassContractUpdateApprovalFinishedStep(approvedQuotes);
		}

		if (!contractStageChangedIds.isEmpty() && !System.isFuture() && !System.isBatch()) {
			PMC_CPQ_QuoteTriggerHelper.setMassContractUpdateGenDocumentStatus(contractStageChangedIds);
		}
	}

	/**
	 * @description This method will perform the operation for after delete trigger
	 */
	public override void afterDelete() {
		if (BOOL_BYPASS_AFTER_DELETE || boolBypassTriggerLogic) {
			return;
		}
	}

	/**
	 * @description This method will perform the operation for after undelete trigger
	 */
	public override void afterUndelete() {
		if (BOOL_BYPASS_AFTER_UNDELETE || boolBypassTriggerLogic) {
			return;
		}
	}
}