/**
* @description This class will be used to handle all trigger operations of Case object
* @author Sayali Shinde
* @storynumber GDASF-1941
*/
public with sharing class PMC_CaseTriggerHandler extends PMC_TriggerHandler  {
    
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
    private List<Case> lstNewCases;
    private Map<Id,Case> mapNewCases;
    private List<Case> lstOldCases;
    private Map<Id,Case> mapOldCases;
    
    /**
    * @description This static block initializes the trigger switches when the class is invoked
    */
    static{
        
        PMC_TriggerSwitches__mdt operationSwitches = PMC_TriggerSwitches__mdt.getInstance('Case');
        
        BOOL_BYPASS_BEFORE_INSERT = operationSwitches.PMC_BeforeInsert__c;
        BOOL_BYPASS_BEFORE_UPDATE = operationSwitches.PMC_BeforeUpdate__c;
        BOOL_BYPASS_BEFORE_DELETE = operationSwitches.PMC_BeforeDelete__c;
        BOOL_BYPASS_AFTER_INSERT = operationSwitches.PMC_AfterInsert__c;
        BOOL_BYPASS_AFTER_UPDATE = operationSwitches.PMC_AfterUpdate__c;
        BOOL_BYPASS_AFTER_DELETE = operationSwitches.PMC_AfterDelete__c;
        BOOL_BYPASS_AFTER_UNDELETE = operationSwitches.PMC_AfterUndelete__c;
        
        for(Profile objProfile : [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() WITH SYSTEM_MODE] ) {
            if(objProfile.Name.contains(PMC_SS_ConstantClass.DH_PROFILE))
            {
                boolBypassTriggerLogic = true;
            } 
            else if(objProfile.Name.contains(PMC_SS_ConstantClass.SYSADMIN_PROFILE))
            {
                boolBypassTriggerLogic = true;
            }
            //GLPA-1134 - Start
            else if(objProfile.Name.contains(PMC_SS_ConstantClass.MISKI_MAYO_MESA_DE_PARTES_PROFILE))
            {
                boolBypassTriggerLogic = true;
            }
            //GLPA-1134 - End
        }
    }
    /**
    * @description Constructor method to initialize class level variables and store the trigger collections and add the max loop count of trigger
    */
 
    public PMC_CaseTriggerHandler(){    
        
        //Instantiating local class variables from trigger variables
        this.lstNewCases = Trigger.new;
        this.mapNewCases = (Map<Id, Case>) Trigger.newMap;
        this.lstOldCases = Trigger.old;
        this.mapOldCases = (Map<Id, Case>) Trigger.oldMap;
        
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
        
        PMC_CaseTriggerHelperExtension.updateCaseTypebasedOnSubject(lstNewCases);
        PMC_ContactOrLeadAssignmentToCase.attachContactLeadOnCase(lstNewCases);
        PMC_CaseTriggerHelper.updateCasePriority(lstNewCases);
        PMC_CaseTriggerHelperExtension.updateIsEscalatedFlag(null, lstNewCases);
        PMC_CaseTriggerHelperExtension.updateWebEmailandWebName(lstNewCases);
        PMC_SS_CaseEntitlementProcess.assignEntitlmentRecordToCases(lstNewCases);
        PMC_SS_CaseUserReferenceUpdate.addAccountAndRegionalManagerOnInsertUpdate(null, lstNewCases);
        PMC_CaseTriggerHelperMethodExtension.updateInvoiceDifference(null, lstNewCases);
        PMC_CaseTriggerHelperMethodExtension.addAccountTeamMembersToCaseOnInsert(lstNewCases);
        PMC_SS_CaseMDMProcess.mdmStatusUpdateForProductRequest(lstNewCases);
       
    }
    
    
    /**
    * @description This method will perform the operation for before update trigger
    */

    public override void beforeUpdate(){
        if(BOOL_BYPASS_BEFORE_UPDATE  || boolBypassTriggerLogic){
            return;
        }
                
        PMC_CaseTriggerHelper.checkBusinessDaysOnCaseReOpen(mapOldCases, lstNewCases); 
        PMC_CaseTriggerHelperExtension.updateIsEscalatedFlag(mapOldCases, lstNewCases);
        PMC_CaseTriggerHelperExtension.updateCaseOwnerBasedOnRouteToQuality(mapOldCases, lstNewCases);
        PMC_SS_CaseUserReferenceUpdate.addAccountAndRegionalManagerOnInsertUpdate(mapOldCases, lstNewCases);
        PMC_SS_CaseUserReferenceUpdate.updateBillingQueue(mapOldCases, lstNewCases);
        PMC_CaseTriggerHelperMethodExtension.updateStatusForSN(mapOldCases, lstNewCases);
        PMC_CaseTriggerHelperMethodExtension.lockClosedCase(mapOldCases, lstNewCases);
        PMC_SS_ClearDependentFieldValues.clearDependentFieldValues(mapOldCases, lstNewCases);
        PMC_CaseTriggerHelperMethodExtension.updateInvoiceDifference( mapOldCases, lstNewCases);
        PMC_CaseTriggerHelperMethodExtension.updateCaseToAutoApproved( mapOldCases, lstNewCases);
        PMC_SS_CaseMDMProcess.checkForCaseAttachment( mapOldCases, lstNewCases);
        PMC_SS_CaseAssignementRuleOnUpdate.caseAssignmentRule( mapOldCases, lstNewCases);
        // GSMD-4950 - Start
        PMC_CaseTriggerHelperExtension.updateCaseMilestoneTriggerToComplete(mapOldCases, lstNewCases);
        // GSMD-4950 - End
        // GSMD-4327 - Start
        PMC_CaseTriggerHelperExtension.updateCaseMilestoneTriggerToPause(mapOldCases, lstNewCases);
        // GSMD-4327 - End
        // GSMD-5024 - Start
        PMC_CaseTriggerHelperExtension.updateCaseFirstTimeClosed(mapOldCases, lstNewCases);
        // GSMD-5024 - End
    }   
}