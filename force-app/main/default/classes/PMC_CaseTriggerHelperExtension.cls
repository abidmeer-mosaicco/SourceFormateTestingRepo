/**
* @description This class will be used to handle all triggers on Case object.
* @storynumber GDASF-1706
*/
public with sharing class PMC_CaseTriggerHelperExtension {

    /**
    * @description This method will be used to update the isEscaCase Type based on Case Subject.
    * @param lstNewCases - List of triggering case records.
    */
    public static void updateCaseTypebasedOnSubject(List<Case> lstNewCases) {
        System.debug(LoggingLevel.FINE, 'Starting updateCaseTypebasedOnSubject method');
        
        try {
            List<Case> lstCaseFromEmail = new List<Case>();
            //changed if condition from origin to email to case--
            for(Case objCase : lstNewCases) {
                if((String.isNotBlank(objCase.SuppliedEmail)||String.isNotBlank(objCase.SourceId)) && String.isNotBlank(objCase.Subject)) {
                    lstCaseFromEmail.add(objCase);
                }
            }

            System.debug(LoggingLevel.FINE, 'Cases from Email: ' + lstCaseFromEmail);

            if(!lstCaseFromEmail.isEmpty()) {
                List<PMC_SS_CaseSubjectToType__mdt> lstCaseSubjectToType = [SELECT MasterLabel, PMC_SS_CaseType__c FROM PMC_SS_CaseSubjectToType__mdt WITH SECURITY_ENFORCED];

                for(Case objCase : lstCaseFromEmail) {
                    setCaseTypebasedOnSubject(objCase, lstCaseSubjectToType);                                       
                }
            }
        } catch(Exception objQueryException) {
            System.debug(LoggingLevel.ERROR, 'Exception in updateCaseTypebasedOnSubject: ' + objQueryException);
            PMC_ErrorLogClass.processException(objQueryException);
        }
    }

    /**
    * @description This method will be used to update the isEscaCase Type based on Case Subject.
    * @param objCase - Triggering case records.
    * @param lstCaseSubjectToType - List of case Type assignment metadata
    */
    public static void setCaseTypebasedOnSubject(Case objCase, List<PMC_SS_CaseSubjectToType__mdt> lstCaseSubjectToType) {
        System.debug(LoggingLevel.FINE, 'Starting setCaseTypebasedOnSubject method');
        
        // Added for GSMD- 1446
        String subject = objCase.Subject != null ? objCase.Subject.toLowerCase() : '';
        String description = objCase.Description != null ? objCase.Description.toLowerCase() : '';
        Boolean hasCadastro=(subject.contains('cadastro') && subject.contains('material')) ||(description.contains('cadastro') && description.contains('material'));
        Boolean hasRenovacao=(subject.contains('renovação') && subject.contains('credito')) ||(description.contains('renovação') && description.contains('credito'));
        Boolean hasLimite=(subject.contains('limite') && subject.contains('credito')) ||(description.contains('limite') && description.contains('credito'));
       // --- Custom rule: for Case Type Internal ---
        if(hasCadastro || hasRenovacao || hasLimite){
          objCase.Type = 'Internal';
       System.debug(LoggingLevel.FINE, 'Case Type set to Internal due to rule');
       return;  
        }
        // adding only else word for GSMD-1729
     else if ((subject.contains('nota') && subject.contains('credito')) ||(description.contains('nota') && description.contains('credito'))) {
       objCase.Type = 'Transactions';
       System.debug(LoggingLevel.FINE, 'Case Type set to Transactions due to rule');
       //return; // No need to continue checking other mappings
   }
      

        for(PMC_SS_CaseSubjectToType__mdt objCaseSubjectByType : lstCaseSubjectToType) {
            String regString=objCaseSubjectByType.MasterLabel ;

            String regex = '(?is).*\\b' + regString + '\\b.*';
 
        Pattern MyPattern = Pattern.compile(regex);
            String inputString= objCase.Subject;
            String inputStringDesc=objCase.Description;
                                Matcher MyMatcher = MyPattern.matcher(inputString);     
            Matcher MyMatcher1 = MyPattern.matcher(inputStringDesc);  
System.debug('Match Result: ' + Pattern.matches(regex,inputString)); 
System.debug('Match Result: ' + Pattern.matches(regex,inputStringDesc)); 
if(Pattern.matches(regex,inputString))
{
     objCase.Type = objCaseSubjectByType.PMC_SS_CaseType__c;
}
            else if(Pattern.matches(regex,inputStringDesc))
            {
                  objCase.Type = objCaseSubjectByType.PMC_SS_CaseType__c;
            }}

/*            if(objCase.Subject.containsOnly(objCaseSubjectByType.MasterLabel)) {
                
                objCase.Type = objCaseSubjectByType.PMC_SS_CaseType__c;
                System.debug(LoggingLevel.FINE, 'Case Type set to: ' + objCase.Type);
                //break;
            }
            //Added for GSMD-212
            Else if(objCase.Description.containsOnly(objCaseSubjectByType.MasterLabel)) {
                objCase.Type = objCaseSubjectByType.PMC_SS_CaseType__c;
                System.debug(LoggingLevel.FINE, 'Case Type set to: ' + objCase.Type);
                break;
            }
        }*/
        
       
        if(String.isBlank(objCase.Type)) {
            objCase.Type = PMC_SS_ConstantClass.CASETYPE_OTHER;
            System.debug(LoggingLevel.FINE, 'Case Type set to other as no match found');
        }
        //Added for GSMD- 3975 -- If CaseType is Transactions, then RecordType to Customer Service
         if (objCase.Type == 'Transactions') {
           if (Schema.SObjectType.Case.RecordTypeInfosByName.containsKey('Customer Service')) {
              objCase.RecordTypeId = Schema.SObjectType.Case.RecordTypeInfosByName.get('Customer Service').RecordTypeId;
              System.debug(LoggingLevel.FINE, 'RecordType set to Customer Service for Transactions case Type');} 
             else {
           System.debug(LoggingLevel.WARN, 'Customer Service Record Type not found on Case object!');}}
}

    

    /**
    * @description This method will be used to update the isEscalated flag on cases.
    * @param mapOldCases - Map of old values of case records.
    * @param lstNewCases - List of triggering case records.
    */
    public static void updateIsEscalatedFlag(Map<Id, Case> mapOldCases, List<Case> lstNewCases) {
        System.debug(LoggingLevel.FINE, 'Starting updateIsEscalatedFlag method');
            
        for(Case objCase : lstNewCases) {
            if(mapOldCases != null) {
                if(objCase.Status == PMC_SS_ConstantClass.ESCALATED && mapOldCases.get(objCase.Id).Status != PMC_SS_ConstantClass.ESCALATED) {
                    objCase.IsEscalated = true;
                } else if(objCase.Status != PMC_SS_ConstantClass.ESCALATED && mapOldCases.get(objCase.Id).Status == PMC_SS_ConstantClass.ESCALATED) {
                    objCase.IsEscalated = false;
                }
            } else {
                objCase.IsEscalated = objCase.Status == PMC_SS_ConstantClass.ESCALATED ? true : false;
            }

            System.debug(LoggingLevel.FINE, 'Case IsEscalated set to: ' + objCase.IsEscalated);
        }
    }

    /**
    * @description This method will populate Web Email and Web Name on Case when Type is Internal and Issue Reason is Article Request
    * @param lstNewCases - List of triggering case records.
    */
    public static void updateWebEmailandWebName(List<Case> lstNewCases) {
        System.debug(LoggingLevel.FINE, 'Starting updateWebEmailandWebName method');
            
        for(Case objCase : lstNewCases) {
            if(objCase.Type == PMC_SS_ConstantClass.INTERNAL && objCase.PMC_SS_IssueReason__c == PMC_SS_ConstantClass.ARTICLE_REQUEST) {
                objCase.SuppliedEmail = UserInfo.getUserEmail();
                objCase.SuppliedName = UserInfo.getName();
                System.debug(LoggingLevel.FINE, 'Updated Case SuppliedEmail: ' + objCase.SuppliedEmail + ', SuppliedName: ' + objCase.SuppliedName);
            }
        }
    }

    /**
    * @description This method will be used to route a Case to Quality Team for inspection.
    * @param mapOldCases - A map of previous version of Case records.
    * @param lstNewCases - List of updated Case records.
    */
    public static void updateCaseOwnerBasedOnRouteToQuality(Map<Id, Case> mapOldCases, List<Case> lstNewCases) {
        System.debug(LoggingLevel.FINE, 'Starting updateCaseOwnerBasedOnRouteToQuality method');

        List<Case> lstCasesToRoute = new List<Case>();
        for(Case objCase : lstNewCases) {
            if(mapOldCases.get(objCase.Id).PMC_SS_RouteToQuality__c != true && objCase.PMC_SS_RouteToQuality__c == true) {
                lstCasesToRoute.add(objCase);
            }
        }

        System.debug(LoggingLevel.FINE, 'Cases to route to Quality: ' + lstCasesToRoute);

        if(lstCasesToRoute != null) {
            Group objQueue = [SELECT Id, Name, DeveloperName, Email, Type FROM Group WHERE Type = :PMC_SS_ConstantClass.QUEUE AND DeveloperName = :PMC_SS_ConstantClass.QUEUE_DEVNAME WITH SECURITY_ENFORCED LIMIT 1];
            for(Case objCaseToRoute : lstCasesToRoute) {
                objCaseToRoute.OwnerId = objQueue.Id;
                System.debug(LoggingLevel.FINE, 'Case Owner updated to Quality Queue: ' + objQueue.Id);
            }
        }
    }  

    /**
    * @description This method will be used to pause the Milestone if the status is updated for SA Accounts.
    * @param mapOldCases - A map of previous version of Case records.
    * @param lstNewCases - List of updated Case records.
    */
    public static void updateCaseMilestoneTriggerToPause(Map<Id, Case> mapOldCases, List<Case> lstNewCases) {
        System.debug(LoggingLevel.FINE, 'Starting updateCaseMilestoneTriggerToPause method');

        List<Case> lstCasesToUpdate = new List<Case>();
        Set<Id> accountIds = new Set<Id>();
        for(Case objCase : lstNewCases) {
            system.debug('objCase.Account.BillingCountry: '+objCase.Account.BillingCountry);
            if((objCase.Status == 'Pending' && mapOldCases.get(objCase.Id).Status == 'Working') || 
               (objCase.Status == 'Working' && mapOldCases.get(objCase.Id).Status == 'Pending') || 
               (objCase.Status == 'Escalated' && mapOldCases.get(objCase.Id).Status != 'Escalated')){
                   accountIds.add(objCase.AccountId);
                   lstCasesToUpdate.add(objCase);
               }
        }

        System.debug(LoggingLevel.FINE, 'Cases to Pause Milestone: ' + lstCasesToUpdate);

        if(accountIds != null) {
            Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Name,BillingCountry FROM Account WHERE ID IN: accountIds AND BillingCountry IN ('Brazil','Paraguay') WITH SECURITY_ENFORCED]);
            for(Case objCase : lstCasesToUpdate) {
                if (accountMap!=null && accountMap.get(objCase.AccountId) != null) {
                    objCase.IsStopped = objCase.Status == 'Pending';
                    System.debug(LoggingLevel.FINE, 'Updated IsStopped: ' + objCase.IsStopped);
                }
            }
        }
    }  
    
    /**
    * @description This method will be used to complete the Milestone if the status is updated for SA Accounts.
    * @param mapOldCases - A map of previous version of Case records.
    * @param lstNewCases - List of updated Case records.
    */
    public static void updateCaseMilestoneTriggerToComplete(Map<Id, Case> mapOldCases, List<Case> lstNewCases) {
        System.debug(LoggingLevel.FINE, 'Starting updateCaseMilestoneTriggerToComplete method');

        List<Id> workingCaseIds = new List<Id>();
        List<Id> closedCaseIds = new List<Id>();
        Id cusServRecTypeId = Schema.SObjectType.Case.getrecordtypeinfosbydevelopername().get('CustomerService').getRecordTypeId();
        for(Case objCase : lstNewCases) {
            if(objCase.Status == 'Working' && mapOldCases.get(objCase.Id).Status == 'New' && objCase.RecordTypeId == cusServRecTypeId){
                workingCaseIds.add(objCase.Id);
            }
            if(objCase.Status == PMC_SS_ConstantClass.CLOSED && mapOldCases.get(objCase.Id).Status != PMC_SS_ConstantClass.CLOSED && objCase.RecordTypeId == cusServRecTypeId){
                closedCaseIds.add(objCase.Id);
            }
        }

        System.debug(LoggingLevel.FINE, 'CaseMilestone Case Ids: ' + workingCaseIds);
        PMC_CaseTriggerHelperExtension.updateCaseMilestones(workingCaseIds, new List<String>{PMC_SS_ConstantClass.FIRST_CONTACT});
        
        System.debug(LoggingLevel.FINE, 'CaseMilestone Case Ids: ' + closedCaseIds);
        PMC_CaseTriggerHelperExtension.updateCaseMilestones(closedCaseIds, PMC_SS_ConstantClass.SLA_MILESTONES);
    }
    
    /**
    * @description This method will be used to complete case milestones.
    * @param caseIds - List of case Ids.
    * @param milestoneName -  name of the milestones
    */
    private static void updateCaseMilestones(List<Id> caseIds, List<String> milestoneNames) {
        
        if(!caseIds.isEmpty()) {
            System.debug(LoggingLevel.FINE, 'Starting updateCasesManagers method');
            List<CaseMilestone> cmsToUpdate = [SELECT Id, completionDate
                                               FROM CaseMilestone
                                               WHERE caseId in :caseIds and MilestoneType.Name IN:milestoneNames AND completionDate = null  WITH SECURITY_ENFORCED];
            if (!cmsToUpdate.isEmpty()){
                for (CaseMilestone cm : cmsToUpdate){
                    cm.completionDate = System.Now();
                }
                update cmsToUpdate;
            }
        }
    }
    
    /**
    * @description This method will be used to populate the First_Date_Time_Case_Closed__c when case is closed.
    * @param mapOldCases - Map of old values of case records.
    * @param lstNewCases - List of triggering case records.
    */
    public static void updateCaseFirstTimeClosed(Map<Id, Case> mapOldCases, List<Case> lstNewCases) {
        
        for(Case objCase : lstNewCases) {
            if(objCase.Status == PMC_SS_ConstantClass.CLOSED && mapOldCases.get(objCase.Id).Status != objCase.Status && objCase.First_Date_Time_Case_Closed__c == null){
                objCase.First_Date_Time_Case_Closed__c = System.now();
            }
        }
    }
}