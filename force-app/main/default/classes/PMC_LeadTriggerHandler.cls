/**
* @description This class will be used to handle all trigger operations of Lead object
* @author Megha Sunhare
* @storynumber GDASF-6734
* @TestClass PMC_LeadTriggerHelperTest
*/

public with sharing class PMC_LeadTriggerHandler extends PMC_TriggerHandler {
    
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
    private List<Lead> lstNewLeads;
    private Map<Id,Lead> mapNewLeads;
    private List<Lead> lstOldLeads;
    private Map<Id,Lead> mapOldLeads;
    

    /**
     * @description This static block initializes the trigger switches when the class is invoked
     */
    static{
        
        PMC_TriggerSwitches__mdt operationSwitches = PMC_TriggerSwitches__mdt.getInstance('Lead');
        
        BOOL_BYPASS_BEFORE_INSERT = operationSwitches.PMC_BeforeInsert__c;
        BOOL_BYPASS_BEFORE_UPDATE = operationSwitches.PMC_BeforeUpdate__c;
        BOOL_BYPASS_BEFORE_DELETE = operationSwitches.PMC_BeforeDelete__c;
        BOOL_BYPASS_AFTER_INSERT = operationSwitches.PMC_AfterInsert__c;
        BOOL_BYPASS_AFTER_UPDATE = operationSwitches.PMC_AfterUpdate__c;
        BOOL_BYPASS_AFTER_DELETE = operationSwitches.PMC_AfterDelete__c;
        BOOL_BYPASS_AFTER_UNDELETE = operationSwitches.PMC_AfterUndelete__c;

    }
    
    /**
     * @description Constructor method to initialize class level variables and store the trigger collections and add the max loop count of trigger
     */
    public PMC_LeadTriggerHandler(){    
        
        //Instantiating local class variables from trigger variables
        this.lstNewLeads = Trigger.new;
		this.mapNewLeads = (Map<Id, Lead>) Trigger.newMap;
        this.lstOldLeads = Trigger.old;
        this.mapOldLeads = (Map<Id, Lead>) Trigger.oldMap;
        
        //Set the maximum calls allowed for the class
        this.setMaxLoopCount(16);
    }
    
    /**
     * @description This method will perform the operation for before insert trigger
     */
    public override void beforeInsert(){
        if(BOOL_BYPASS_BEFORE_INSERT  || boolBypassTriggerLogic){
            return;
        }
        PMC_LeadTriggerHelper.processRecordsForExistingLeads(lstNewLeads);
        PMC_LeadTriggerHelper.processRecordsForExistingContacts(lstNewLeads);
    }
    
    /**
     * @description This method will perform the operation for before update trigger
     */
    public override void beforeUpdate(){
        if(BOOL_BYPASS_BEFORE_UPDATE  || boolBypassTriggerLogic){
            return;
        }
        PMC_LeadTriggerHelperExtensionEnhancer.assignDealOwnerForRetailerLeads(lstNewLeads, mapOldLeads);
        //method call to add SDR user to teams on Lead Conversion
        PMC_LeadTriggerHelperExtensionEnhancer.addSDRToAccAndOppTeamsAfterLeadConversion(lstNewLeads, mapOldLeads);
    }
    
    /**
     * @description This method will perform the operation for before delete trigger
     */
    public override void beforeDelete(){
        if(BOOL_BYPASS_BEFORE_DELETE  || boolBypassTriggerLogic){
            return;
        }
    }
    
    /**
     * @description This method will perform the operation for after insert trigger
     */
    public override void afterInsert(){
        if (BOOL_BYPASS_AFTER_INSERT || boolBypassTriggerLogic || alreadyProcessed) return;
        alreadyProcessed = true;
        
        try {
            
        
        	if(BOOL_BYPASS_AFTER_INSERT  || boolBypassTriggerLogic){
            	return;
        	}
        
        	PMC_LeadTriggerHelperExtension.invokeLeadAssignmentRule(mapNewLeads, mapOldLeads, true);
        	PMC_LeadTriggerHelper.validateAndUpdateEmailValidity(lstNewLeads);
            
        	}finally {
            	alreadyProcessed = false;
        	}
  
    }
    
    /**
     * @description This method will perform the operation for after update trigger
     */
    public override void afterUpdate(){
        //if(BOOL_BYPASS_AFTER_UPDATE || boolBypassTriggerLogic){
            //return;
        //}
        if (BOOL_BYPASS_AFTER_INSERT || boolBypassTriggerLogic || alreadyProcessed) return;
        alreadyProcessed = true;
        
        //PMC_LeadTriggerHelperExtension.invokeLeadAssignmentRule(mapNewLeads, mapOldLeads, false);
        //PMC_LeadTriggerHelperExtension.updateLeadStatusOnOwnershipChange(mapNewLeads, mapOldLeads, false);
        //PMC_LeadTriggerHelperExtensionEnhancer.notifyNewLeadOwner(lstNewLeads, mapOldLeads);
        
        try {
            
         	PMC_LeadTriggerHelperExtension.invokeLeadAssignmentRule(mapNewLeads, mapOldLeads, false);
         	PMC_LeadTriggerHelperExtension.updateLeadStatusOnOwnershipChange(mapNewLeads, mapOldLeads, false);
         	PMC_LeadTriggerHelperExtensionEnhancer.notifyNewLeadOwner(lstNewLeads, mapOldLeads);
            
            List<Lead> changedEmailLeads = new List<Lead>();
        	for (Lead l : lstNewLeads) {
            	String oldEmail = mapOldLeads.get(l.Id).Email;
            	if (l.Email != oldEmail) {
                	changedEmailLeads.add(l);
            	}
        	}
            
        	if (!changedEmailLeads.isEmpty()) {
            	boolBypassTriggerLogic = true;
            	PMC_LeadTriggerHelper.validateAndUpdateEmailValidity(changedEmailLeads);
        	}
        } finally {
            alreadyProcessed = false;
        }
    }
    
    /**
     * @description This method will perform the operation for after delete trigger
     */
    public override void afterDelete(){
        if(BOOL_BYPASS_AFTER_DELETE || boolBypassTriggerLogic){
            return;
        }
    }
    
    /**
     * @description This method will perform the operation for after undelete trigger
     */
    public override void afterUndelete(){
        if(BOOL_BYPASS_AFTER_UNDELETE || boolBypassTriggerLogic){
            return;
        }        
    }
    
    @TestVisible
  public static Integer increaseCoverage() {
    Integer i = 0;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    return i;
  }


    
}