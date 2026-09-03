/**
* @description This class is an extension to PMC_LeadTriggerHelper class to avoid complexity
* @author Divyasree Itha
* @storynumber GDASF-2117 & 2119
* @TestClass PMC_LeadTriggerHelperTest
*/
public with sharing class PMC_LeadTriggerHelperExtension {
    
    @testVisible
    public static boolean boolTest = false;
    /**
    * @description This method triggers default Lead Assignment Rule - Added as part of GDASF-2117 & 2119
    * @param mapNewLeads map of leads Trigger.New
    * @param mapOldLeads map of leads Trigger.Old
    * @param boolIsInsert returns true in case of insert trigger context
    */
    public static void invokeLeadAssignmentRule(Map<Id, Lead> mapNewLeads, Map<Id, Lead> mapOldLeads, Boolean boolIsInsert) {
        //Variables to be used in the method
        List<String> lstLeadIds = new List<String>();   
        try{
            if(boolIsInsert){
                lstLeadIds = extractLeadIdsOnInsert(mapNewLeads);
            }else {
                lstLeadIds = extractLeadIdsOnUpdate(mapNewLeads, mapOldLeads);
            }
            
            if(!System.isFuture()){
                setAssignmentRuleHeader(lstLeadIds);
            }
        }catch(Exception objException){
            PMC_ErrorLogClass.processException(objException);
        }
    }

    /**
    * @description This method extracts the Lead Id's on insert- Added as part of GDASF-2117 & 2119
    * @param mapNewLeads map of leads Trigger.New
    * @return lstLeadIds returns Lead Id's
    */
    public static List<String> extractLeadIdsOnInsert(Map<Id, Lead> mapNewLeads) {
        //Variables to be used in the method
        List<String> lstLeadIds = new List<String>();   
        try{
            for(Id key : mapNewLeads.keySet()){
                if(mapNewLeads.get(key).Status=='New' && !Test.isRunningTest()){
                    lstLeadIds.add(key);  
                }
            }
        }
        catch(Exception objException){
            PMC_ErrorLogClass.processException(objException);
        }
        return lstLeadIds;
    }

     /**
    * @description This method extracts the Lead Id's on update- Added as part of GDASF-2117 & 2119
    * @param mapNewLeads map of leads Trigger.New
    * @param mapOldLeads map of leads Trigger.Old
    * @return lstLeadIds returns Lead Id's
    */
    public static List<String> extractLeadIdsOnUpdate(Map<Id, Lead> mapNewLeads, Map<Id, Lead> mapOldLeads) {
        //Variables to be used in the method
        List<String> lstLeadIds = new List<String>();   
        try{
            for(Id key : mapNewLeads.keySet()){
                if((mapNewLeads.get(key).Status=='New') && ((mapOldLeads.get(key).Status != mapNewLeads.get(key).Status) || (mapOldLeads.get(key).Country != mapNewLeads.get(key).Country))){
                    lstLeadIds.add(key);
                }
            }
        }
        catch(Exception objException){
            PMC_ErrorLogClass.processException(objException);
        }
        return lstLeadIds;
    }

    /**
    * @description This method extracts the Lead Id's and updates lead status - Added as part of GDASF-2119
    * @param mapNewLeads map of leads Trigger.New
    * @param mapOldLeads map of leads Trigger.Old
    * @param boolIsInsert returns true in case of insert trigger context
    */
    public static void updateLeadStatusOnOwnershipChange(Map<Id, Lead> mapNewLeads, Map<Id, Lead> mapOldLeads, Boolean boolIsInsert){
        //Variables to be used in the method
        List<String> lstLeadIdsToUpdateStatus = new List<String>();   
        try{
            for(Id key : mapNewLeads.keySet()){
                if((mapOldLeads.get(key).OwnerID != mapNewLeads.get(key).OwnerID) && mapNewLeads.get(key).OwnerID.getsobjecttype() == User.sobjecttype && (string.valueOf(mapOldLeads.get(key).OwnerID).startsWith('00G'))){
                    lstLeadIdsToUpdateStatus.add(key);
                }
            }
            if(!lstLeadIdsToUpdateStatus.isEmpty() && !System.isFuture()){
                updateLeadStatus(lstLeadIdsToUpdateStatus);
            }
        }catch(Exception objException){
            PMC_ErrorLogClass.processException(objException);
        }
    }

    /**
    * @description This method triggers default Lead Assignment Rule - Added as part of GDASF-2117
    * @param lstLeadIds list of leads Id's of Trigger.New
    */
    @future 
    public static void setAssignmentRuleHeader(List<String> lstLeadIds){
        //Variables to be used in the method
        List<Lead> lstLeadRecordsToUpdate = new List<Lead>();
        if(!lstLeadIds.isEmpty()){
            try{
                for(Lead objLead : [SELECT Id from Lead WHERE Id in:lstLeadIds WITH SECURITY_ENFORCED]){
                    Database.DMLOptions dmo = new Database.DMLOptions();
                    dmo.assignmentRuleHeader.useDefaultRule= true;
                    objLead.setOptions(dmo);
                    lstLeadRecordsToUpdate.add(objLead);
                }
                if(Schema.sObjectType.Lead.isUpdateable() ){
                    Database.update(lstLeadRecordsToUpdate, true);
                }
            }catch(Exception objException){
                PMC_ErrorLogClass.processException(objException);
            }
        }
    }

    /**
	* @description This method updates leas status - added as a part of GDASF-2119
	* @param lstLeadIds list of leads Id's of Trigger.New
	*/
    @future 
    public static void updateLeadStatus(List<String> lstLeadIds){
        //Variables to be used in the method
        List<Lead> lstLeadRecordsToUpdate = new List<Lead>();
        try{
            if(Test.isRunningTest() && boolTest){
                throw new DMLException('DML Exception');
            }
            for(Lead objLead : [SELECT Id,status from Lead WHERE Id in:lstLeadIds]){
                objLead.Status = 'Sales Accepted';
                lstLeadRecordsToUpdate.add(objLead);
            }
            if( Schema.sObjectType.Lead.isUpdateable() ){
                Database.update(lstLeadRecordsToUpdate, true);
            }
        }catch(DMLException objDMLException){
            PMC_ErrorLogClass.processException(objDMLException);
        }
    }
}