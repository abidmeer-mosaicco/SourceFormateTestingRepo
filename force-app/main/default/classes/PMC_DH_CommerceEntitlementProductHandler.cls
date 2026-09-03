/**
* @description This class will be used to handle all trigger operations of CommerceEntitlementProduct object
* @author Rohan Undale
* @storynumber GDASF-14334
*/
public with sharing class PMC_DH_CommerceEntitlementProductHandler extends PMC_TriggerHandler{
    
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
    
   /**
    * These boolean variables are used to bypass the trigger operations
    */
    @testVisible
    public static Boolean boolBypassTriggerLogic = false;
    
    /**
     * These variables will hold the copy of trigger variables
     */
    private List<CommerceEntitlementProduct> lstNewCommerceEntitlementProduct;
    private Map<Id,CommerceEntitlementProduct> mapNewCommerceEntitlementProduct;
    private List<CommerceEntitlementProduct> lstOldCommerceEntitlementProduct;
    private Map<Id,CommerceEntitlementProduct> mapOldCommerceEntitlementProduct;
    /**
    * @description This constructor will initiate data when the class is invoked
    */
    
    /**
     * @description This static block initializes the trigger switches when the class is invoked
     */
    static{
        
        PMC_TriggerSwitches__mdt operationSwitches = PMC_TriggerSwitches__mdt.getInstance('CommerceEntitlementProduct');
        
        BOOL_BYPASS_BEFORE_INSERT = operationSwitches.PMC_BeforeInsert__c;
        BOOL_BYPASS_BEFORE_UPDATE = operationSwitches.PMC_BeforeUpdate__c;
        BOOL_BYPASS_BEFORE_DELETE = operationSwitches.PMC_BeforeDelete__c;
        BOOL_BYPASS_AFTER_INSERT = operationSwitches.PMC_AfterInsert__c;
        BOOL_BYPASS_AFTER_UPDATE = operationSwitches.PMC_AfterUpdate__c;
        BOOL_BYPASS_AFTER_DELETE = operationSwitches.PMC_AfterDelete__c;
        BOOL_BYPASS_AFTER_UNDELETE = operationSwitches.PMC_AfterUndelete__c;

    }
    /**
     * @description This static block initializes the trigger switches when the class is invoked
     */
    
    public PMC_DH_CommerceEntitlementProductHandler() {
        //Instantiating local class variables from trigger variables
        this.lstNewCommerceEntitlementProduct = Trigger.new;
        this.mapNewCommerceEntitlementProduct = (Map<Id,CommerceEntitlementProduct>) Trigger.newMap;
        this.lstOldCommerceEntitlementProduct = Trigger.old;
        this.mapOldCommerceEntitlementProduct = (Map<Id, CommerceEntitlementProduct>) Trigger.oldMap;
        //Set the maximum calls allowed for the class
        //this.setMaxLoopCount(16);
       
        
    }
    /**
     * @description This method will perform the operation for after insert trigger
     */
    public override void afterInsert(){
        if(BOOL_BYPASS_AFTER_INSERT || boolBypassTriggerLogic){
            return;
        }
        PMC_DH_CommerceEntitlementProductHelper.processRecordsForNewCommerceEntitlementProduct(lstNewCommerceEntitlementProduct, mapNewCommerceEntitlementProduct);
    }
     /**
     * @description This method will perform the operation for after delete trigger
    */
    public override void afterDelete(){
        if(BOOL_BYPASS_AFTER_DELETE || boolBypassTriggerLogic){
            return;
        }
        PMC_DH_CommerceEntitlementProductHelper.processRecordsForDeletedCommerceEntitlementProduct(lstOldCommerceEntitlementProduct, mapOldCommerceEntitlementProduct);
    }
}