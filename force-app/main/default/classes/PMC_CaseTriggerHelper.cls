/**
* @description This class will be used to handle all triggers on Case object.
* @storynumber GDASF-1941
*/
public with sharing class PMC_CaseTriggerHelper {

    // Variable to cover the exception part
    @testVisible
    private static Boolean boolThrowException = false; 

    /**
    * @description This method will be used to update the Case priority on cases.
    * @param lstNewCases - List of triggering case records.
    */
    public static void updateCasePriority(List<Case> lstNewCases) {
        System.debug(LoggingLevel.FINE, 'Starting updateCasePriority method');
        
        try {
            Set<Id> setAccountIds = new Set<Id>();
            Map<Id, String> mapContactAccountIds = new Map<Id, String>();

            for(Case objCase : lstNewCases) {
                if(objCase.AccountId != null) {
                    setAccountIds.add(objCase.AccountId);
                } else if(objCase.ContactId != null) {
                    mapContactAccountIds.put(objCase.ContactId, '');
                }
            }
            
            System.debug(LoggingLevel.FINE, 'Account Ids: ' + setAccountIds);
            System.debug(LoggingLevel.FINE, 'Contact to Account Ids: ' + mapContactAccountIds);

            if(!mapContactAccountIds.isEmpty()) {
                for(Contact objContact : [SELECT Id, AccountId FROM Contact WHERE Id IN : mapContactAccountIds.keySet() WITH SECURITY_ENFORCED]) {
                    mapContactAccountIds.put(objContact.Id, objContact.AccountId);
                }
            }
            
            Map<String, Account> mapAccounts = new Map<String, Account>();
            if(!setAccountIds.isEmpty() || !mapContactAccountIds.isEmpty()) {
                mapAccounts = new Map<String, Account>([SELECT Id, PMC_SS_Segmentation__c FROM Account WHERE (Id IN : setAccountIds OR Id IN : mapContactAccountIds.values()) AND PMC_SS_Segmentation__c != Null WITH SECURITY_ENFORCED]);
            }
            
            System.debug(LoggingLevel.FINE, 'Accounts Map: ' + mapAccounts);
            
            checkAndAssignPriorityToCase(lstNewCases, mapAccounts, mapContactAccountIds);
        } catch(Exception objQueryException) {
            System.debug(LoggingLevel.ERROR, 'Exception in updateCasePriority: ' + objQueryException);
            PMC_ErrorLogClass.processException(objQueryException);
        }
    }

    /**
    * @description This method will be used to check the case type and retrieve the corresponding Case priority on cases.
    * @param lstNewCases - List of triggering case records.
    * @param mapAccounts - Map of Account Id & Account Record
    * @param mapContactAccountIds - Map of Contact Id & associated Account Id
    */
    public static void checkAndAssignPriorityToCase(List<Case> lstNewCases, Map<String, Account> mapAccounts, Map<Id, String> mapContactAccountIds) {
        System.debug(LoggingLevel.FINE, 'Starting checkAndAssignPriorityToCase method');

        Map<String, PMC_SS_CasePriorityAssignment__mdt> mapCasePriorityAssignments = getCasePriorityAssignments();
        System.debug(LoggingLevel.FINE, 'Case Priority Assignments: ' + mapCasePriorityAssignments);
        
        for(Case objCase : lstNewCases) {
            String strKey = objCase.AccountId != null && mapAccounts.containsKey(objCase.AccountId) ? objCase.Type + '_' + objCase.PMC_SS_IssueReason__c + '_' + mapAccounts.get(objCase.AccountId).PMC_SS_Segmentation__c : 
                            objCase.ContactId != null && mapAccounts.containsKey(mapContactAccountIds.get(objCase.ContactId)) ? objCase.Type + '_' + objCase.PMC_SS_IssueReason__c + '_' + mapAccounts.get(mapContactAccountIds.get(objCase.ContactId)).PMC_SS_Segmentation__c : '';
            
            System.debug(LoggingLevel.FINE, 'Case Key: ' + strKey);
            
            updatePriority(objCase, mapCasePriorityAssignments, strKey);
        } 
    }

    /**
    * @description This method will be used to check the case type and retrieve the corresponding Case priority on cases.
    * @param objCase - Case To update priority.
    * @param mapCasePriorityAssignments - Map of priority metadata
    * @param strKey - Case type, Issue reason and segmetation combination string.
    * @added - origin not equal to email in medium & low priority
    */
    public static void updatePriority(Case objCase, Map<String, PMC_SS_CasePriorityAssignment__mdt> mapCasePriorityAssignments, String strKey) {
        System.debug(LoggingLevel.FINE, 'Starting updatePriority method');
        if(objCase.Type == PMC_SS_ConstantClass.INTERNAL && objCase.PMC_SS_IssueReason__c == PMC_SS_ConstantClass.MDM_VERIFICATION) {
            objCase.Priority = PMC_SS_ConstantClass.HIGH;
        } else if(String.isBlank(objCase.PMC_SS_IssueReason__c) && objCase.Origin!=PMC_SS_ConstantClass.CASE_ORIGIN_EMAIL) {
        objCase.Priority = PMC_SS_ConstantClass.MEDIUM;
        } else if(mapCasePriorityAssignments.containsKey(strKey)) {
            objCase.Priority = mapCasePriorityAssignments.get(strKey).PMC_SS_Priority__c;
        } else if(objCase.Origin!=PMC_SS_ConstantClass.CASE_ORIGIN_EMAIL){
            objCase.Priority = PMC_SS_ConstantClass.LOW;
        }
        
        System.debug(LoggingLevel.FINE, 'Updated Case Priority: ' + objCase.Priority);
    }

    /**
    * @description This method will be used to retrieve Custom Metadata.
    * @return Map<String, PMC_SS_CasePriorityAssignment__mdt> where record's Master Label is key and record is value
    */
    public static Map<String, PMC_SS_CasePriorityAssignment__mdt> getCasePriorityAssignments() {
        System.debug(LoggingLevel.FINE, 'Starting getCasePriorityAssignments method');

        Map<String, PMC_SS_CasePriorityAssignment__mdt> mapCasePriorityAssignments = new Map<String, PMC_SS_CasePriorityAssignment__mdt>();

        for(PMC_SS_CasePriorityAssignment__mdt objCasePriorityDetails : [SELECT MasterLabel, PMC_SS_Priority__c, PMC_SS_Segmentation__c, PMC_SS_IssueReason__c, PMC_SS_Type__c 
                                                                         FROM PMC_SS_CasePriorityAssignment__mdt WITH SECURITY_ENFORCED]) {
            mapCasePriorityAssignments.put(objCasePriorityDetails.PMC_SS_Type__c + '_' + objCasePriorityDetails.PMC_SS_IssueReason__c + '_' + objCasePriorityDetails.PMC_SS_Segmentation__c, objCasePriorityDetails);
        }
        
        System.debug(LoggingLevel.FINE, 'Retrieved Case Priority Assignments: ' + mapCasePriorityAssignments);
        
        return mapCasePriorityAssignments;
    }

    /**
    * @description This method will be used to calculate business days post case closure.
    * @param mapOldCases - Map of old values of case records.
    * @param lstNewCases - List of triggering case records.
    */
    public static void checkBusinessDaysOnCaseReOpen(Map<Id, Case> mapOldCases, List<Case> lstNewCases) {
        System.debug(LoggingLevel.FINE, 'Starting checkBusinessDaysOnCaseReOpen method');
            
        try {
            List<Case> lstCases = new List<Case>();

            for(Case objCase : lstNewCases) {
                if(objCase.Status == PMC_SS_ConstantClass.RE_OPEN && (mapOldCases.get(objCase.Id).Status == PMC_SS_ConstantClass.CLOSED || mapOldCases.get(objCase.Id).Status == PMC_SS_ConstantClass.CLOSUREPENDING)) {
                    lstCases.add(objCase);
                }
            }

            System.debug(LoggingLevel.FINE, 'Cases to validate: ' + lstCases);

            if(!lstCases.isEmpty()) {
                BusinessHours objBusinessHrs = [SELECT Id, Name FROM BusinessHours WHERE isDefault = True AND IsActive = True WITH SECURITY_ENFORCED];

                for(Case objCase : lstCases) {
                    validateReopenTimeFrame(objCase, mapOldCases.get(objCase.Id), objBusinessHrs);
                }
            }            
        } catch(QueryException objQueryException) {
            System.debug(LoggingLevel.ERROR, 'Exception in checkBusinessDaysOnCaseReOpen: ' + objQueryException);
            PMC_ErrorLogClass.processException(objQueryException);
        }
    }

    /**
    * @description This method will be used to update the isEscalated flag on cases.
    * @param objNewCase - Triggering case record.
    * @param objOldCase - Old Case record values
    * @param objBusinessHrs - Default Business Hours
    */
    public static void validateReopenTimeFrame(Case objNewCase, Case objOldCase, BusinessHours objBusinessHrs) {
        System.debug(LoggingLevel.FINE, 'Starting validateReopenTimeFrame method');

        Id idBusinessHrs = objNewCase.BusinessHoursId != null ? objNewCase.BusinessHoursId : objBusinessHrs.Id;
        System.debug(LoggingLevel.FINE, 'Business Hours Id: ' + idBusinessHrs);
                                    
        DateTime dateTimeExpectedReOpenDate = BusinessHours.addGmt(idBusinessHrs, objOldCase.ClosedDate, PMC_SS_ConstantClass.RE_OPEN_DATE_FORMULA);
        System.debug(LoggingLevel.FINE, 'Expected Reopen Date: ' + dateTimeExpectedReOpenDate);

        // adding if condition for GSMD-1096
        Profile objProfile = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() WITH SYSTEM_MODE];
        if(!objProfile.Name.contains(PMC_SS_ConstantClass.SRVUSER_PROFILE))
        {
          if(System.now() > dateTimeExpectedReOpenDate || (Test.isRunningTest() && boolThrowException)) {
            objNewCase.addError(Label.PMC_SS_ReopenPeriodForClosedCase);
            System.debug(LoggingLevel.WARN, 'Reopen period exceeded or exception thrown in test');
            return;
          } else if(objNewCase.Origin != PMC_SS_ConstantClass.CASE_ORIGIN_EMAIL && UserInfo.getUserId() != objOldCase.OwnerId) {
            objNewCase.OwnerId = UserInfo.getUserId();
          }
          System.debug(LoggingLevel.FINE, 'Updated Case Owner: ' + objNewCase.OwnerId);
        }
    }
}