/**
* @description This class will be used to handle all trigger operations of Sales Agreement Sales Area Relation object
* @author Swakeerth Gadda
* @storynumber GDASF-9729
*/
public without sharing class PMC_SS_SalesAgreeSalesAreaRelHandler extends PMC_TriggerHandler {
	/**
    * These boolean variables are used to bypass the trigger operations
    */
    private static final Boolean BOOL_BYPASS_BEFORE_INSERT;
    private static final Boolean BOOL_BYPASS_BEFORE_UPDATE;
	private static final Boolean BOOL_BYPASS_AFTER_INSERT;
    private static final Boolean BOOL_BYPASS_AFTER_UPDATE;
    private static final Boolean BOOL_BYPASS_BEFORE_DELETE;
    private static final Boolean BOOL_BYPASS_AFTER_DELETE;
    private static final Boolean BOOL_BYPASS_AFTER_UNDELETE;

    @testVisible
    private static Boolean boolBypassTriggerLogic = false;
    
    /**
    * These variables will hold the copy of trigger variables
    */
    private List<PMC_SalesAgreementSalesAreaRelation__c> lstNewSalesAgreeSalesAreaRel;
    
    /**
    * @description This static block initializes the trigger switches when the class is invoked
    */
    static{
        
        PMC_TriggerSwitches__mdt operationSwitches = PMC_TriggerSwitches__mdt.getInstance('PMC_SalesAgreementSalesAreaRelation');
        
        BOOL_BYPASS_BEFORE_INSERT = operationSwitches.PMC_BeforeInsert__c;
        BOOL_BYPASS_BEFORE_UPDATE = operationSwitches.PMC_BeforeUpdate__c;
		BOOL_BYPASS_AFTER_INSERT = operationSwitches.PMC_AfterInsert__c;
        BOOL_BYPASS_AFTER_UPDATE = operationSwitches.PMC_AfterUpdate__c;
        BOOL_BYPASS_BEFORE_DELETE = operationSwitches.PMC_BeforeDelete__c;
        BOOL_BYPASS_AFTER_DELETE = operationSwitches.PMC_AfterDelete__c;
        BOOL_BYPASS_AFTER_UNDELETE = operationSwitches.PMC_AfterUndelete__c;

    }
    
    /**
    * @description Constructor method to initialize class level variables and store the trigger collections and add the max loop count of trigger
    */
    public PMC_SS_SalesAgreeSalesAreaRelHandler(){    
        
        //Instantiating local class variables from trigger variables
        this.lstNewSalesAgreeSalesAreaRel = Trigger.New;
    }
    
    
    /**
    * @description This method will perform the operation for before insert trigger
    */
    public override void beforeInsert(){
        if(BOOL_BYPASS_BEFORE_INSERT  || boolBypassTriggerLogic){
            return;
        }
        
        PMC_SS_SalesAgreeSalesAreaRelHelper.salesAgreementToSalesAreaValidation(lstNewSalesAgreeSalesAreaRel);
    }
    
    
    /**
    * @description This method will perform the operation for before update trigger
    */
    public override void beforeUpdate(){
        if(BOOL_BYPASS_BEFORE_UPDATE  || boolBypassTriggerLogic){
            return;
        }
        
        PMC_SS_SalesAgreeSalesAreaRelHelper.salesAgreementToSalesAreaValidation(lstNewSalesAgreeSalesAreaRel);

    }
    
    /**
    * @description This method will perform the operation for after insert trigger
    */
    public override void afterInsert(){
        if(BOOL_BYPASS_AFTER_INSERT  || boolBypassTriggerLogic){
            return;
        }
    }
    
    /**
    * @description This method will perform the operation for after update trigger
    */
    public override void afterUpdate(){
        if(BOOL_BYPASS_AFTER_UPDATE  || boolBypassTriggerLogic){
            return;
        }
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
    * @description This method will perform the operation for after delete trigger
    */
    public override void afterDelete(){
        if(BOOL_BYPASS_AFTER_DELETE  || boolBypassTriggerLogic){
            return;
        }
    }
    /**
    * @description This method will perform the operation for after undelete trigger
    */
    public override void afterUndelete(){
        if(BOOL_BYPASS_AFTER_UNDELETE  || boolBypassTriggerLogic){
            return;
        }
    }
    
}