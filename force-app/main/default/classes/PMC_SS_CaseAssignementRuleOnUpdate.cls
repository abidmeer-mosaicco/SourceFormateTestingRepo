/**
* @description This class is used to reassign the Case owner on update
* @autor Satish Baragali
*/
public with sharing class PMC_SS_CaseAssignementRuleOnUpdate {
    /**
    * @description This method will be used to assign the MDM Status when the case is created  
    * @param mapOldCases - map of old case records
    * @param lstNewCases - List of new case records
    */
    public static void caseAssignmentRule(Map<Id, Case> mapOldCases, List<Case> lstNewCases) {
         // Added as part of GDASF-21937 Gaurav
        // Query relevant EmailMessage records related to the new cases
        List<EmailMessage> relatedEmails = [
            SELECT Id, Subject, ParentId, ToAddress FROM EmailMessage WHERE ParentId IN :lstNewCases
        ];
         // Added as part of GDASF-21937 Gaurav
        // Create a map of case Ids to their related email messages
        Map<Id, List<EmailMessage>> caseEmailMap = new Map<Id, List<EmailMessage>>();
        for (EmailMessage email : relatedEmails) {
            if (!caseEmailMap.containsKey(email.ParentId)) {
                caseEmailMap.put(email.ParentId, new List<EmailMessage>());
            }
            caseEmailMap.get(email.ParentId).add(email);
        }
        List<Group> lstQueues = [
            SELECT Id, DeveloperName, Type FROM Group 
            WHERE Type = :PMC_SS_ConstantClass.QUEUE AND DeveloperName IN :new List<String>{
                PMC_SS_ConstantClass.SA_GTM_QUEUE, 
                PMC_SS_ConstantClass.KNOWLEDGE_CREATOR_QUEUE, 
                PMC_SS_ConstantClass.GTM_QUEUE, 
                PMC_SS_ConstantClass.PRODUCT_QUEUE, 
                PMC_SS_ConstantClass.MASTER_DATA_QUEUE
            } 
            WITH SECURITY_ENFORCED
        ];
 
        Map<String, Id> mapQueues = new Map<String, Id>();
        for (Group queue : lstQueues) {
            mapQueues.put(queue.DeveloperName, queue.Id);
        }
 
        for (Case objCase : lstNewCases) {
             // Added as part of GDASF-21937 Gaurav
            // Check the ToAddress field in related email messages
            Boolean emailConditionMet = false;
            List<EmailMessage> emails = caseEmailMap.get(objCase.Id);
               
          		if (emails != null && !emails.isEmpty()) {
                	for (EmailMessage email : emails) {
                    	if (email.ToAddress != null && (email.ToAddress.contains(PMC_SS_ConstantClass.To_Address_China) || email.ToAddress.contains(PMC_SS_ConstantClass.To_Address_India))) {
                            if (objCase.OwnerId == null){
                            	objCase.OwnerId = mapQueues.get(PMC_SS_ConstantClass.MASTER_DATA_QUEUE);
                            }
                       		emailConditionMet = true;
                        }
                    }
                }
            
 
            if (!emailConditionMet) {
                queueAssignmentForProductAndArticleRequest(mapOldCases, objCase, mapQueues);
                queueAssignmentForRebateAndIncorrectProduct(mapOldCases, objCase, mapQueues);
            }
        }
    }
 
    /**
    * @description This method will be used to assign the MDM Status when the case is created  
    * @param mapOldCases - map of old case records
    * @param objCase - a case record
    * @param mapQueues - map of Queue
    */
    @TestVisible
    private static void queueAssignmentForProductAndArticleRequest(Map<Id, Case> mapOldCases, Case objCase, Map<String, Id> mapQueues) {
        if (objCase.PMC_SS_IssueReason__c == PMC_SS_ConstantClass.PRODUCT_REQUEST && mapOldCases.get(objCase.id).PMC_SS_IssueReason__c != PMC_SS_ConstantClass.PRODUCT_REQUEST) {
            objCase.OwnerId = mapQueues.get(PMC_SS_ConstantClass.SA_GTM_QUEUE);
            objCase.PMC_SS_MDMStatus__c = PMC_SS_ConstantClass.WAITING_FOR_PRODUCT_FORM_COMPLETION;
        } else if (objCase.PMC_SS_IssueReason__c == PMC_SS_ConstantClass.ARTICLE_REQUEST && mapOldCases.get(objCase.id).PMC_SS_IssueReason__c != PMC_SS_ConstantClass.ARTICLE_REQUEST) {
            objCase.OwnerId = mapQueues.get(PMC_SS_ConstantClass.KNOWLEDGE_CREATOR_QUEUE);
        }
    
    }
 
    /**
    * @description This method will be used to assign the MDM Status when the case is created  
    * @param mapOldCases - map of old case records
    * @param objCase - a case record
    * @param mapQueues - map of Queue
    */
    @TestVisible
    private static void queueAssignmentForRebateAndIncorrectProduct(Map<Id, Case> mapOldCases, Case objCase, Map<String, Id> mapQueues) {
        if (objCase.PMC_SS_IssueReason__c == PMC_SS_ConstantClass.REBATE_ISSUE_REASON && mapOldCases.get(objCase.id).PMC_SS_IssueReason__c != PMC_SS_ConstantClass.REBATE_ISSUE_REASON) {
            objCase.OwnerId = mapQueues.get(PMC_SS_ConstantClass.GTM_QUEUE);
        } else if (objCase.PMC_SS_IssueReason__c == PMC_SS_ConstantClass.INCORRECT_PRODUCT_ISSUE_REASON && mapOldCases.get(objCase.id).PMC_SS_IssueReason__c != PMC_SS_ConstantClass.INCORRECT_PRODUCT_ISSUE_REASON) {
            objCase.OwnerId = mapQueues.get(PMC_SS_ConstantClass.PRODUCT_QUEUE);
        }
   
    }
}