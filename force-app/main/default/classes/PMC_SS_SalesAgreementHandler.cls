/**
* @description This class will be used to handle all trigger operations of Sales Agreement object
* @author Swakeerth Gadda
* @storynumber GDASF-7122,GDASF-15372
*/
public class PMC_SS_SalesAgreementHandler extends PMC_TriggerHandler {
    /**
    * These boolean variables are used to bypass the trigger operations
    */
    private static final Boolean BOOL_BYPASS_BEFORE_INSERT;
    private static final Boolean BOOL_BYPASS_BEFORE_UPDATE;

    @testVisible
    private static Boolean boolBypassTriggerLogic = false;
    
    /**
    * These variables will hold the copy of trigger variables
    */
    private List<SalesAgreement> lstNewSalesAgreements;
    private Map<Id,SalesAgreement> mapNewSalesAgreements;
    private Map<Id,SalesAgreement> mapOldSalesAgreements;
    
    /**
    * @description This static block initializes the trigger switches when the class is invoked
    */
    static{
        
        PMC_TriggerSwitches__mdt operationSwitches = PMC_TriggerSwitches__mdt.getInstance('SalesAgreement');
        
        BOOL_BYPASS_BEFORE_INSERT = operationSwitches.PMC_BeforeInsert__c;
        BOOL_BYPASS_BEFORE_UPDATE = operationSwitches.PMC_BeforeUpdate__c;
    }
    
    /**
    * @description Constructor method to initialize class level variables and store the trigger collections and add the max loop count of trigger
    */
    public PMC_SS_SalesAgreementHandler(){    
        
        //Instantiating local class variables from trigger variables
        this.lstNewSalesAgreements = Trigger.New;
        this.mapNewSalesAgreements = (Map<Id, SalesAgreement>) Trigger.newMap;
        this.mapOldSalesAgreements = (Map<Id, SalesAgreement>) Trigger.oldMap;
    }
    
    
    /**
    * @description This method will perform the operation for before insert trigger
    */
    public override void beforeInsert(){
        if(BOOL_BYPASS_BEFORE_INSERT  || boolBypassTriggerLogic){
            return;
        }
    }
    
    /**
    * @description This method will perform the operation for before update trigger
    */
    public override void beforeUpdate(){
        if(BOOL_BYPASS_BEFORE_UPDATE  || boolBypassTriggerLogic){
            return;
        }
        PMC_SS_SalesAgreementHelper.updateForecastedQuantityAndProjectedIncentive(mapNewSalesAgreements,mapOldSalesAgreements); 
    }
}