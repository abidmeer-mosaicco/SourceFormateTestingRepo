/**
* @description This class will be used to handle all triggers on Case object.
* @author Vedashri
* @storynumber GDASF-11309
*/
public with sharing class PMC_CaseTriggerHelperMethodExtension {
    /**
    * @description This method will be used to lock closed case.
    * @param mapOldCases - Map of old values of case records.
    * @param lstNewCases - List of triggering case records.
    */
    public static void lockClosedCase(Map<Id, Case> mapOldCases, List<Case> lstNewCases) {
        System.debug(LoggingLevel.FINE, 'Starting lockClosedCase method');
        try {
            List<Id> lstCaseIdToLock = new List<Id>();
            for(Case objCase: lstNewCases) {
                if(objCase.Status != PMC_SS_ConstantClass.RE_OPEN && mapOldCases.get(objCase.id).Status == PMC_SS_ConstantClass.CLOSED) {
                    lstCaseIdToLock.add(objCase.id);
                }
            }
            System.debug(LoggingLevel.FINE, 'Cases to lock: ' + lstCaseIdToLock);
            if(!lstCaseIdToLock.isEmpty()) {
                Approval.lock(lstCaseIdToLock);
            }
        } catch(Exception objQueryException) {
            System.debug(LoggingLevel.ERROR, 'Exception in lockClosedCase: ' + objQueryException);
            PMC_ErrorLogClass.processException(objQueryException);
        }
    }

    /** 
    * @description This method will be used to calculate invoice difference.
    * @param mapOldCases - Map of old values of case records.
    * @param lstNewCases - List of triggering case records.
    */ 
    public static void updateInvoiceDifference(Map<Id, Case> mapOldCases, List<Case> lstNewCases) {
        System.debug(LoggingLevel.FINE, 'Starting updateInvoiceDifference method');
        for(Case objCase : lstNewCases) {
            if(objCase.Type == PMC_SS_ConstantClass.INVOICE && objCase.PMC_SS_IssueReason__c == PMC_SS_ConstantClass.INVOICE_ADJUSTMENTS && string.isBlank(objCase.PMC_SS_ActionReason__c)) {
               // objCase.PMC_SS_InvoiceDifference__c = objCase.PMC_SS_OriginalInvoiceAmount__c - objCase.PMC_SS_RebillAmount__c;
                objCase.PMC_SS_InvoiceDifference__c = objCase.PMC_SS_RebillAmount__c - objCase.PMC_SS_OriginalInvoiceAmount__c;
   
                System.debug(LoggingLevel.FINE, 'Updated Invoice Difference for Case: ' + objCase.Id + ' to: ' + objCase.PMC_SS_InvoiceDifference__c);
            }
        }
    }

    /**
    * @description This method will be used to lock closed case.
    * @param mapOldCases - Map of old values of case records.
    * @param lstNewCases - List of triggering case records.
    */
    public static void updateStatusForSN(Map<Id, Case> mapOldCases, List<Case> lstNewCases) {
        System.debug(LoggingLevel.FINE, 'Starting updateStatusForSN method');
        try {
            Map<String, PMC_SS_SNOW_StatusMapping__mdt> mapSNStatus = new Map<String, PMC_SS_SNOW_StatusMapping__mdt>();
            for(PMC_SS_SNOW_StatusMapping__mdt objSNStatus : [SELECT Id, PMC_SS_SNOW_Status__c, PMC_SS_CaseStatus__c, PMC_SS_SNOW_StatusTranslatedLabel__c FROM PMC_SS_SNOW_StatusMapping__mdt WITH SECURITY_ENFORCED]) {
                mapSNStatus.put(objSNStatus.PMC_SS_SNOW_Status__c, objSNStatus);
                mapSNStatus.put(objSNStatus.PMC_SS_SNOW_StatusTranslatedLabel__c, objSNStatus);
            }
            System.debug(LoggingLevel.FINE, 'ServiceNow Status Mapping: ' + mapSNStatus);
            for(Case objCase: lstNewCases) {
                if(objCase.PMC_SS_SNOW_ServiceNowTicketNumber__c != null && objCase.PMC_SS_SNOW_StatusLabel__c != mapOldCases.get(objCase.id).PMC_SS_SNOW_StatusLabel__c && mapSNStatus.containsKey(objCase.PMC_SS_SNOW_StatusLabel__c)) {
                    objCase.Status = mapSNStatus.get(objCase.PMC_SS_SNOW_StatusLabel__c).PMC_SS_CaseStatus__c;
                    objCase.PMC_SS_SNOW_Status__c = mapSNStatus.get(objCase.PMC_SS_SNOW_StatusLabel__c).PMC_SS_SNOW_Status__c;
                    System.debug(LoggingLevel.FINE, 'Updated Case Status for Case: ' + objCase.Id + ' to: ' + objCase.Status);
                }
            }
        } catch(Exception objQueryException) {
            System.debug(LoggingLevel.ERROR, 'Exception in updateStatusForSN: ' + objQueryException);
            PMC_ErrorLogClass.processException(objQueryException);
        }
    }   

    /**
    * @description This method will be used to lock closed case.
    * @param lstNewCases - List of triggering case records.
    */
    public static void addAccountTeamMembersToCaseOnInsert(List<Case> lstNewCases) {
        System.debug(LoggingLevel.FINE, 'Starting addAccountTeamMembersToCaseOnInsert method');
        Set<Id> setAccountIds = new Set<Id>(); 
        for(Case objCase: lstNewCases) {
            setAccountIds.add(objCase.AccountId);
        }
        System.debug(LoggingLevel.FINE, 'Account Ids: ' + setAccountIds);
        
        Map<Id, Map<String,Id>> mapAccountWithManagers = new Map<Id, Map<String,Id>>();
        for (AccountTeamMember objAccountteammember : [SELECT Id, TeamMemberRole, AccountId, UserId FROM AccountTeamMember WHERE AccountId IN :setAccountIds WITH SECURITY_ENFORCED]) {
            if(mapAccountWithManagers.containsKey(objAccountteammember.AccountId)) {
                mapAccountWithManagers.get(objAccountteammember.AccountId).put(objAccountteammember.TeamMemberRole, objAccountteammember.UserId);
            } else {
                mapAccountWithManagers.put(objAccountteammember.AccountId, new Map<String,Id>{objAccountteammember.TeamMemberRole => objAccountteammember.UserId});
            }
        }
        System.debug(LoggingLevel.FINE, 'Account Team Members: ' + mapAccountWithManagers);
        PMC_CaseTriggerHelperMethodExtension.updateCasesManagers(lstNewCases, mapAccountWithManagers);
    }

    /**
    * @description This method will be used to lock closed case.
    * @param lstNewCases - List of triggering case records.
    * @param mapAccountWithManagers -  Map of 
    */
    private static void updateCasesManagers(List<Case> lstNewCases, Map<Id, Map<String, Id>> mapAccountWithManagers) {
        System.debug(LoggingLevel.FINE, 'Starting updateCasesManagers method');
        for (Case objCase: lstNewCases) {
            if (objCase.AccountId != null && mapAccountWithManagers.containsKey(objCase.AccountId)) {
                objCase.PMC_SS_NationalDirector__c = mapAccountWithManagers.get(objCase.AccountId).containsKey(PMC_SS_ConstantClass.NATIONAL_DIRECTOR) ? mapAccountWithManagers.get(objCase.AccountId).get('National Director') : objCase.PMC_SS_NationalDirector__c;
                objCase.PMC_SS_RegionalDirector__c = mapAccountWithManagers.get(objCase.AccountId).containsKey(PMC_SS_ConstantClass.REGIONAL_DIRECTOR) ? mapAccountWithManagers.get(objCase.AccountId).get('Regional Director') : objCase.PMC_SS_RegionalDirector__c;
                objCase.PMC_SS_SNOW_SegmentManager__c = mapAccountWithManagers.get(objCase.AccountId).containsKey(PMC_SS_ConstantClass.SEGMENT_MANAGER) ? mapAccountWithManagers.get(objCase.AccountId).get('Segment Manager') : objCase.PMC_SS_SNOW_SegmentManager__c;
                System.debug(LoggingLevel.FINE, 'Updated Managers for Case: ' + objCase.Id);
            }
        }
    }

    /**
    * @description This method will be used to lock closed case.
    * @param mapOldCases - List of triggering case records.
    * @param lstNewCases -  Map of 
    */
    public static void updateCaseToAutoApproved(Map<Id, Case> mapOldCases, List<Case> lstNewCases) { 
        System.debug(LoggingLevel.FINE, 'Starting updateCaseToAutoApproved method');
        Boolean isNAUser = PMC_CaseTriggerHelperMethodExtension.checkForNaUser();
        for(Case objCase : lstNewCases) {
            if(objCase.PMC_SS_ActionReason__c != mapOldCases.get(objCase.Id).PMC_SS_ActionReason__c && objCase.AccountId != null && PMC_CaseTriggerHelperMethodExtension.checkForActionAndAmount(objCase, isNAUser)) {
                objCase.PMC_SS_ApprovalStatus__c = PMC_SS_ConstantClass.AUTOAPPROVED;
                System.debug(LoggingLevel.FINE, 'Case set to Auto Approved for Case: ' + objCase.Id);
            }
        }
    }
    
    /**
    * @description This method will be used to lock closed case.
    * @param objCase - List of triggering case records.
    * @param isNAUser - List of triggering case records.
    * @return isAutoApproval - List of triggering case records.
    */
    private static boolean checkForActionAndAmount(Case objCase, Boolean isNAUser) {
        System.debug(LoggingLevel.FINE, 'Checking for Action and Amount for Case: ' + objCase.Id);
        boolean isAutoApproval = (((objCase.PMC_SS_ActionReason__c == PMC_SS_ConstantClass.CANCEL && objCase.PMC_SS_CancelAmount__c <= PMC_SS_ConstantClass.THOUSAND) || 
                                   (objCase.PMC_SS_ActionReason__c == PMC_SS_ConstantClass.REBILL && objCase.PMC_SS_RebillAmount__c <= PMC_SS_ConstantClass.THOUSAND) || 
                                   (objCase.PMC_SS_ActionReason__c == PMC_SS_ConstantClass.CREDIT && objCase.PMC_SS_CreditDebitAmount__c <= PMC_SS_ConstantClass.THOUSAND) || 
                                   (objCase.PMC_SS_ActionReason__c == PMC_SS_ConstantClass.ACTIONRETURN && objCase.PMC_SS_ReturnAmount__c <= PMC_SS_ConstantClass.THOUSAND) || 
                                   (objCase.PMC_SS_ActionReason__c == PMC_SS_ConstantClass.REVERSESHIPMENT && isNAUser && objCase.PMC_SS_DollarAmount__c <= PMC_SS_ConstantClass.THOUSAND )) && 
                                  objCase.PMC_SS_OriginalInvoiceAmount__c < PMC_SS_ConstantClass.ONEMILLION);
        System.debug(LoggingLevel.FINE, 'Auto Approval Check Result: ' + isAutoApproval);
        return isAutoApproval;
    }

    /**
    * @description This method will be used to lock closed case.
    * @return isNaUser - List of triggering case records.
    */
    private static boolean checkForNaUser() {
        System.debug(LoggingLevel.FINE, 'Checking if user is NA User');
        for(User objUser : [SELECT Id, Name, UserRole.Name FROM User WHERE Id = :UserInfo.getUserId() AND UserRoleId != null WITH SYSTEM_MODE]) {
            if(PMC_SS_ConstantClass.SSR_ROLES.contains(objUser.UserRole.Name)) {
                System.debug(LoggingLevel.FINE, 'User is an NA User');
                return true;
            }
        }
        System.debug(LoggingLevel.FINE, 'User is not an NA User');
        return false;
    }
}