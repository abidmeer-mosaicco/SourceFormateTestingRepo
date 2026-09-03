/**
* @description This class will be used to handle all trigger operations of Opportunity object
* @author Megha Sunhare
* @storynumber GDASF-2588
*/

public with sharing class PMC_OpportunityTriggerHandler extends PMC_TriggerHandler {
    
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
    private List<Opportunity> lstNewOpportunities;
    private Map<Id,Opportunity> mapNewOpportunities;
    private List<Opportunity> lstOldOpportunities;
    private Map<Id,Opportunity> mapOldOpportunities;
    

    /**
     * @description This static block initializes the trigger switches when the class is invoked
     */
    static{
        
        PMC_TriggerSwitches__mdt operationSwitches = PMC_TriggerSwitches__mdt.getInstance('Opportunity');
        
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
    public PMC_OpportunityTriggerHandler(){    
        
        //Instantiating local class variables from trigger variables
        this.lstNewOpportunities = Trigger.new;
		this.mapNewOpportunities = (Map<Id, Opportunity>) Trigger.newMap;
        this.lstOldOpportunities = Trigger.old;
        this.mapOldOpportunities = (Map<Id, Opportunity>) Trigger.oldMap;
        
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
        
        //Update Analysis Stage Date if Stage name is set to Analysis
        PMC_OpportunityTriggerHelper.updateAnalysisStageDate(lstNewOpportunities, mapNewOpportunities, mapOldOpportunities);
        
        //Update Opportunity Type as Indirect Sales if Owner is a retailer (user with Digital Hub Buyer Profile)
        PMC_OpportunityTriggerHelper.updateTypeIndirectSales(lstNewOpportunities);
    }
    
    /**
     * @description This method will perform the operation for before update trigger
     */
    public override void beforeUpdate(){
        if(BOOL_BYPASS_BEFORE_UPDATE  || boolBypassTriggerLogic){
            return;
        }

        //Update Analysis Stage Date if Stage name is set to Analysis
        PMC_OpportunityTriggerHelper.updateAnalysisStageDate(lstNewOpportunities, mapNewOpportunities, mapOldOpportunities);
        
        //Update Opportunity Type as Indirect Sales if Owner is a retailer (user with Digital Hub Buyer Profile)
        PMC_OpportunityTriggerHelper.updateTypeIndirectSales(lstNewOpportunities);
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
        if(BOOL_BYPASS_AFTER_INSERT  || boolBypassTriggerLogic){
            return;
        }
      
if (Trigger.new == null || Trigger.new.isEmpty()) return;

    // Use the map to get Ids in a generic-safe way
    Set<Id> oppIds = Trigger.newMap.keySet();
    if (oppIds.isEmpty()) return;

    try {
               UserLookupControllerOppTeams.applyDefaultOppTeamOnInsert(oppIds);
    } catch (Exception e) {
        System.debug('afterInsert — failed to apply default team: ' + e.getMessage());
    }


    }
    
    /**
     * @description This method will perform the operation for after update trigger
     */
    public override void afterUpdate(){
        if(BOOL_BYPASS_AFTER_UPDATE || boolBypassTriggerLogic){
            return;
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
    
}