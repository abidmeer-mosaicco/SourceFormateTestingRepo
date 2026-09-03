/**
* @description This class will be used to handle all trigger operations of Allocations object
* @author Aravind Chaganti
* @storynumber:GDASF-16609
* Test Class: PMC_SS_AllocationTriggerHandlerTest
*/

public without sharing class PMC_SS_AllocationTriggerHandler extends PMC_TriggerHandler{
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
    private List<PMC_SS_Allocation__c> lstNewAllocations;
    private Map<Id, PMC_SS_Allocation__c> mapNewAllocations;
    private List<PMC_SS_Allocation__c> lstOldAllocations;
    private Map<Id,	PMC_SS_Allocation__c> mapOldAllocations;
    

    /**
     * @description This static block initializes the trigger switches when the class is invoked
     */
    static{
        
        PMC_TriggerSwitches__mdt operationSwitches = PMC_TriggerSwitches__mdt.getInstance('PMC_SS_Allocation');
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
    public PMC_SS_AllocationTriggerHandler(){    
        
        //Instantiating local class variables from trigger variables
        this.lstNewAllocations = Trigger.new;
		this.mapNewAllocations = (Map<Id, PMC_SS_Allocation__c>) Trigger.newMap;
        this.lstOldAllocations = Trigger.old;
        this.mapOldAllocations = (Map<Id, PMC_SS_Allocation__c>) Trigger.oldMap;
    }
    
    /**
     * @description This method will perform the operation for before insert trigger
     */
    public override void beforeInsert(){
        if(BOOL_BYPASS_BEFORE_INSERT || boolBypassTriggerLogic){
            return;
        }

        //to populate the Product Location month Key
        PMC_SS_AllocationTriggerHelperExtension.populateFieldsOnAllocation(lstNewAllocations);
        PMC_SS_AllocationTriggerHelper.populateProductLocationMonthKey(lstNewAllocations);
        PMC_SS_AllocationTriggerHelper.restrictAllocationExceedingQuantity(lstNewAllocations,mapOldAllocations);
    }
    
    /**
     * @description This method will perform the operation for before update trigger
     */
    public override void beforeUpdate(){
        if(BOOL_BYPASS_BEFORE_UPDATE || boolBypassTriggerLogic){
            
            return;
        }
        PMC_SS_AllocationTriggerHelper.populateProductLocationMonthKey(lstNewAllocations);
        PMC_SS_AllocationTriggerHelper.restrictAllocationExceedingQuantity(lstNewAllocations,mapOldAllocations);
    }
    /**
     * @description This method will perform the operation for after insert trigger
     */
    public override void afterInsert(){
        if(BOOL_BYPASS_AFTER_INSERT || boolBypassTriggerLogic){
            return;
        }
        PMC_SS_AllocationTriggerHelper.createAllocationSummary(lstNewAllocations);
    }
    
    /**
     * @description This method will perform the operation for after update trigger
     */
    public override void afterUpdate(){
        if(BOOL_BYPASS_AFTER_UPDATE || boolBypassTriggerLogic){
            return;
        }
        PMC_SS_AllocationTriggerHelper.createAllocationSummary(lstNewAllocations);
    }
}