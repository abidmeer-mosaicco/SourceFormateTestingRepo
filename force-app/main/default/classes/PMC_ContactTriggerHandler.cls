/**
* @description This class will be used to handle all trigger operations of Contact object
* @author Sayali Shinde
* @storynumber GDASF-8472
*/

public without sharing class PMC_ContactTriggerHandler extends PMC_TriggerHandler {

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
    private static Boolean alreadyProcessed = false;
    
    
    @testVisible
    public static Boolean boolBypassTriggerLogic = false;
    
    /**
	* These variables will hold the copy of trigger variables
	*/
    private List<Contact> lstNewContacts;
    private Map<Id,Contact> mapNewContacts;
    private List<Contact> lstOldContacts;
    private Map<Id,Contact> mapOldContacts;
    
    /**
	* @description This static block initializes the trigger switches when the class is invoked
	*/
    static{
        
        PMC_TriggerSwitches__mdt operationSwitches = PMC_TriggerSwitches__mdt.getInstance('Contact');
        
        BOOL_BYPASS_BEFORE_INSERT = operationSwitches.PMC_BeforeInsert__c;
        BOOL_BYPASS_BEFORE_UPDATE = operationSwitches.PMC_BeforeUpdate__c;
        BOOL_BYPASS_BEFORE_DELETE = operationSwitches.PMC_BeforeDelete__c;
        BOOL_BYPASS_AFTER_INSERT = operationSwitches.PMC_AfterInsert__c;
        BOOL_BYPASS_AFTER_UPDATE = operationSwitches.PMC_AfterUpdate__c;
        BOOL_BYPASS_AFTER_DELETE = operationSwitches.PMC_AfterDelete__c;
        BOOL_BYPASS_AFTER_UNDELETE = operationSwitches.PMC_AfterUndelete__c;

        // GLPA-1134 - Start
        for(Profile objProfile : [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() WITH SYSTEM_MODE])
        {
            if(objProfile.Name.contains(PMC_SS_ConstantClass.MISKI_MAYO_MESA_DE_PARTES_PROFILE))
            {
                boolBypassTriggerLogic = true;
            }
            else if(objProfile.Name.contains(PMC_SS_ConstantClass.MESA_DE_PARTES_PROFILE))
            {
                boolBypassTriggerLogic = true;
            }
        }
        // GLPA-1134 - End
    }

    
    /**
	* @description Constructor method to initialize class level variables and store the trigger collections and add the max loop count of trigger
	*/
    
    public PMC_ContactTriggerHandler(){    
        
        //Instantiating local class variables from trigger variables
        this.lstNewContacts = Trigger.new;
        this.mapNewContacts = (Map<Id, Contact>) Trigger.newMap;
        this.lstOldContacts = Trigger.old;
        this.mapOldContacts = (Map<Id, Contact>) Trigger.oldMap;
        
        //Set the maximum calls allowed for the class
        this.setMaxLoopCount(8);
    }
    
    /**
	* @description This method will perform the operation for before insert trigger
	*/
    
    public override void beforeInsert(){
        if(BOOL_BYPASS_BEFORE_INSERT  || boolBypassTriggerLogic){
            return;
        }
        
        PMC_ContactTriggerHelper.checkDuplicateContactNos(null, lstNewContacts);
    }
    
    
    /**
	* @description This method will perform the operation for before update trigger
	*/
    
    public override void beforeUpdate(){
        if(BOOL_BYPASS_BEFORE_UPDATE  || boolBypassTriggerLogic){
            return;
        }
        
        PMC_ContactTriggerHelper.checkDuplicateContactNos(mapOldContacts, lstNewContacts);
    }

/**
	* @description Modified this logic to prevent Recursion - Prashanth Kamma - 08/05/2025.
	*/

	public override void afterInsert() {
    	if (BOOL_BYPASS_AFTER_INSERT || boolBypassTriggerLogic) return;
    	if (PMC_SS_TriggerRecursionGuard.isAlreadyProcessed('Contact_afterInsert')) return;
    
    	PMC_SS_TriggerRecursionGuard.markProcessed('Contact_afterInsert');

    	PMC_ContactTriggerHelper.validateAndUpdateEmailValidity(lstNewContacts);
   }

    public override void afterUpdate() {
    	if (BOOL_BYPASS_AFTER_UPDATE || boolBypassTriggerLogic) return;
    	if (PMC_SS_TriggerRecursionGuard.isAlreadyProcessed('Contact_afterUpdate')) return;

    	List<Contact> changedEmailContacts = new List<Contact>();
    	for (Contact c : lstNewContacts) {
        	String oldEmail = mapOldContacts.get(c.Id).Email;
        	if (c.Email != oldEmail) {
            	changedEmailContacts.add(c);
            }
        }

    if (!changedEmailContacts.isEmpty()) {
        PMC_SS_TriggerRecursionGuard.markProcessed('Contact_afterUpdate');
        PMC_ContactTriggerHelper.validateAndUpdateEmailValidity(changedEmailContacts);
    }
}

    /*public override void afterInsert() {
        if (BOOL_BYPASS_AFTER_INSERT || boolBypassTriggerLogic || alreadyProcessed) return;
        alreadyProcessed = true;
        try {
            PMC_ContactTriggerHelper.validateAndUpdateEmailValidity(lstNewContacts);
        } finally {
            alreadyProcessed = false;
        }
    }

     public override void afterUpdate() {
        if (BOOL_BYPASS_AFTER_UPDATE || boolBypassTriggerLogic || alreadyProcessed) return;

        List<Contact> changedEmailContacts = new List<Contact>();
        for (Contact c : lstNewContacts) {
            String oldEmail = mapOldContacts.get(c.Id).Email;
            if (c.Email != oldEmail) {
                changedEmailContacts.add(c);
            }
        }
        if (!changedEmailContacts.isEmpty()) {
            alreadyProcessed = true;
            try {
                PMC_ContactTriggerHelper.validateAndUpdateEmailValidity(changedEmailContacts);
            } finally {
                alreadyProcessed = false;
            }
        }
    }*/
}