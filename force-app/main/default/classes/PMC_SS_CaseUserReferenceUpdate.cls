/**
* @description This class will be used to handle case user reference fields updates from case trigger.
* @author Vedashri
*/

public with sharing class PMC_SS_CaseUserReferenceUpdate {
	/**
    * @description This method will be used to update Case owner to billing queue for credit and debit action.
    * @param mapOldCases - A map of previous version of Case records.
    * @param lstNewCases - List of updated Case records. 
    */
    public static void updateBillingQueue(Map<Id,Case> mapOldCases, List<Case> lstNewCases){
        try {
        	List<Case> lstCasesToUpdate = new List<Case>();
        	for(Case objCase: lstNewCases) {
            	if((mapOldCases.get(objCase.Id).PMC_SS_ActionReason__c != objCase.PMC_SS_ActionReason__c || mapOldCases.get(objCase.Id).PMC_SS_ApprovalStatus__c != objCase.PMC_SS_ApprovalStatus__c) &&
             	((objCase.PMC_SS_ActionReason__c ==PMC_SS_ConstantClass.CREDIT && (objCase.PMC_SS_ApprovalStatus__c == PMC_SS_ConstantClass.FINAL_APPROVED || objCase.PMC_SS_ApprovalStatus__c == PMC_SS_ConstantClass.AUTO_APPROVED)) || objCase.PMC_SS_ActionReason__c ==PMC_SS_ConstantClass.DEBIT)){
                	lstCasesToUpdate.add(objCase);
            	}
        	}
        	updateCaseOwnerToBillingQueue (lstCasesToUpdate);
        }
         catch(Exception objQueryException) {
            PMC_ErrorLogClass.processException(objQueryException);
        }
      
    }
    /**
    * @description This method will be used to update Case owner to billing queue for credit and debit action.
    * @param lstCasesToUpdate - List of updated Case records. 
    */
    private static void updateCaseOwnerToBillingQueue(List<Case> lstCasesToUpdate){
        
        if(!lstCasesToUpdate.isEmpty()) {
            List<Group> lstBillingQueue = new List<Group>([SELECT Id, DeveloperName  FROM Group 
                                                                WHERE Type =:PMC_SS_ConstantClass.QUEUE AND 
                                                             DeveloperName =: PMC_SS_ConstantClass.BILLINGQUEUE_DEVNAME  WITH SECURITY_ENFORCED LIMIT 1]);
            if(!lstBillingQueue.isEmpty())
            {
                for(Case objCaseToUpdate: lstCasesToUpdate){
                    objCaseToUpdate.OwnerId = lstBillingQueue[0].Id;
                }
            }                                                    
        }
    }
    
    /**
    * @description This method will be used to populate Account and Regional Manager field on case creation.
    * @param mapOldCases - A map of previous version of Case records.
    * @param lstNewCases - List of new Case records.
    */
    public static void addAccountAndRegionalManagerOnInsertUpdate(Map<Id,Case> mapOldCases, List<Case> lstNewCases) {
        try{
        	Set<Id> setAccountIds = new Set<Id>();
        	Map<Id,Account> mapAccountIdAndAccount = new Map<Id,Account>();
        
        	for(Case objCase: lstNewCases){
            	if( mapOldCases == null || (mapOldCases.get(objCase.Id).AccountId != objCase.AccountId && objCase.AccountId != NULL)){
                	setAccountIds.add(objCase.AccountId);
            	} 
        	}        
        	if(!setAccountIds.isEmpty()) {
            	mapAccountIdAndAccount = new Map<Id,Account>([SELECT Id,OwnerId, Owner.ManagerId FROM Account WHERE ID in :setAccountIds WITH SECURITY_ENFORCED]);
        	}
        	updateManagersOnCase(lstNewCases,mapAccountIdAndAccount);
        }
         catch(Exception objQueryException) {
            PMC_ErrorLogClass.processException(objQueryException);
        }
    }
    /**
    * @description This method will be used to populate Account and  Regional Manager on case.
    * @param lstNewCases - List of new Case records.  
    * @param mapAccountIdAndAccount -  Account Manager or Regional Manger Update.
    */
    private static void updateManagersOnCase(List<Case> lstNewCases,Map<Id,Account> mapAccountIdAndAccount) { 

        for(Case objCaseToUpdate: lstNewCases) {
            if(objCaseToUpdate.AccountId != NULL && mapAccountIdAndAccount.containsKey(objCaseToUpdate.AccountId)) {
                updateManagers(objCaseToUpdate,mapAccountIdAndAccount.get(objCaseToUpdate.AccountId).OwnerId,mapAccountIdAndAccount.get(objCaseToUpdate.AccountId).Owner.ManagerId);
            }
        }
        
    }
    
    /**
    * @description This method will be used to populate Account and  Regional Manager field on case.
    * @param objCaseToUpdate - Case to Update Managers.  
    * @param idAccountManager - AM Id to update on case.
    * @param idRegionalManager - RM Id to update on Case.
    */
    private static void updateManagers(Case objCaseToUpdate, Id idAccountManager,Id idRegionalManager) {  
        
        if(Schema.sObjectType.Case.fields.PMC_SS_AccountManager__c.isUpdateable() ) {
            objCaseToUpdate.PMC_SS_AccountManager__c = idAccountManager;
        }
        if(Schema.sObjectType.Case.fields.PMC_SS_RegionalManager__c.isUpdateable()) {
            objCaseToUpdate.PMC_SS_RegionalManager__c = idRegionalManager;
        }
    }
}