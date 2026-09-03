/**
* @description This class will be used to handle all triggers on Case object.
* @author Satish
*/
public with sharing class PMC_SS_CaseMDMProcess {
   /**
    * @description This method will be used to lock closed case.
    * @param mapOldCases - Map of old values of case records.
    * @param lstNewCases - List of triggering case records.
    */
    public static void checkForCaseAttachment(Map<Id, Case> mapOldCases, List<Case> lstNewCases){
         Set<Id> setCaseIds = new Set<Id>();
         Map<Id, Id> mapContentDocumentLink = new Map<Id, Id>(); 
         ID idSAGTMQUEUE;
         idSAGTMQUEUE = [select id,Type,DeveloperName from Group WHERE (Type =:PMC_SS_ConstantClass.QUEUE and DeveloperName =:PMC_SS_ConstantClass.SA_GTM_QUEUE) WITH SECURITY_ENFORCED LIMIT 1].id;        
         
         for (Case objCase : lstNewCases) {
             
             if(objCase.PMC_SS_MDMStatus__c == PMC_SS_ConstantClass.WAITING_FOR_MASTER_DATA_MANAGEMENT && mapOldCases.get(objCase.id).PMC_SS_MDMStatus__c !=PMC_SS_ConstantClass.WAITING_FOR_MASTER_DATA_MANAGEMENT){
                 setCaseIds.add(objCase.Id);  
             } 
             else if((objCase.PMC_SS_MDMStatus__c == PMC_SS_ConstantClass.WAITING_FOR_PRODUCT_COSTING_SETUP && mapOldCases.get(objCase.id).PMC_SS_MDMStatus__c != PMC_SS_ConstantClass.WAITING_FOR_PRODUCT_COSTING_SETUP) || (objCase.PMC_SS_MDMStatus__c == PMC_SS_ConstantClass.WAITING_FOR_PRODUCT_CREATION_ASSIGNMENT && mapOldCases.get(objCase.id).PMC_SS_MDMStatus__c != PMC_SS_ConstantClass.WAITING_FOR_PRODUCT_CREATION_ASSIGNMENT) ) {
                objCase.OwnerId = idSAGTMQUEUE;
             }            
         }
         
         if(!setCaseIds.isEmpty()){  
             mapContentDocumentLink = PMC_SS_CaseMDMProcess.checkForContentDocumentLink(setCaseIds);
             PMC_SS_CaseMDMProcess.assignToMDMQueue(mapContentDocumentLink,lstNewCases,mapOldCases);
         }
         
        
        
    }
    /**
    * @description This method will be used to return the map of attached documents 
    * @param setCaseIds - Set of case record 
    * @return mapContentDocumentLink - map of attached documents 
    */
     private static map<Id, Id> checkForContentDocumentLink(Set<Id> setCaseIds){
         List<ContentDocumentLink> lstContentDocumentLink = [SELECT Id,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :setCaseIds WITH SECURITY_ENFORCED];
         Map<Id, Id> mapContentDocumentLink = new Map<Id, Id>();
         if(!lstContentDocumentLink.isEmpty()){
             for (ContentDocumentLink objContentDocumentLink : lstContentDocumentLink) {
                 if (!mapContentDocumentLink.containsKey(objContentDocumentLink.LinkedEntityId)) {
                     mapContentDocumentLink.put(objContentDocumentLink.LinkedEntityId,objContentDocumentLink.Id );                    
                 } 
             }
         }
           return mapContentDocumentLink;  
     }

    /**
    * @description This method will be used to lock closed case.
    * @param mapContentDocumentLink - Map of contentdocumentlink.
    * @param lstNewCases - List of triggering case records.
    * @param mapOldCases - List of old cases.
    */
    private static void assignToMDMQueue(Map<Id, Id> mapContentDocumentLink,List<case> lstNewCases,Map<Id, Case> mapOldCases){
        ID idMDMQueue;
            idMDMQueue = [select id,Type,DeveloperName from Group WHERE (Type =:PMC_SS_ConstantClass.QUEUE and DeveloperName =:PMC_SS_ConstantClass.MASTER_DATA_TEAM_QUEUE) WITH SECURITY_ENFORCED LIMIT 1].id;
        for (case objCase : lstNewCases) {
             if (!mapContentDocumentLink.containsKey(objCase.Id) && objCase.PMC_SS_MDMStatus__c == 'Waiting for Master Data Management' && mapOldCases.get(objCase.id).PMC_SS_MDMStatus__c != PMC_SS_ConstantClass.WAITING_FOR_MASTER_DATA_MANAGEMENT && !(objCase.Subject.startsWith(PMC_SS_ConstantClass.MDM_CASE_SUBJECT) && objCase.PMC_SS_IssueReason__c == PMC_SS_ConstantClass.MDM_VERIFICATION)) {
                 objCase.addError(System.Label.PMC_SS_MDMCase_ErrorMessage,true);
             } else if (objCase.PMC_SS_MDMStatus__c == PMC_SS_ConstantClass.WAITING_FOR_MASTER_DATA_MANAGEMENT && mapOldCases.get(objCase.id).PMC_SS_MDMStatus__c != PMC_SS_ConstantClass.WAITING_FOR_MASTER_DATA_MANAGEMENT) {
                objCase.OwnerId = idMDMQueue;    
             }
    	}
	}
    /**
    * @description This method will be used to Assingn the MDM Status when the case is created  
    * @param lstNewCases - List of case record
    */
    public static void mdmStatusUpdateForProductRequest(List<Case> lstNewCases) {
        for(case objCase : lstNewCases){
            if(objCase.PMC_SS_IssueReason__c == PMC_SS_ConstantClass.PRODUCT_REQUEST){
                objCase.PMC_SS_MDMStatus__c =PMC_SS_ConstantClass.WAITING_FOR_PRODUCT_FORM_COMPLETION;
            }
        }
    }
    
}