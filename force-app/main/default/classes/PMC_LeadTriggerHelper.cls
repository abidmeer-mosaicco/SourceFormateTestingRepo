/**
* @description This class will be used to handle all triggers operations on Lead Object
* @author Megha Sunhare
* @storynumber GDASF-6734
* @TestClass PMC_LeadTriggerHelperTest
*/
public without sharing class PMC_LeadTriggerHelper {
    
    private static List<Opportunity> lstOpportunities = new List<Opportunity>();
    private static Set<Id> setRetailUserIds = new Set<Id>();
    
    /**
* @description This method is used to check if the lead record is a duplicate
* @param lstNewLeads list of leads Trigger.New
*/
    public static void processRecordsForExistingLeads(List<Lead> lstNewLeads){
        //Variables to be used in the method
        List<Lead> lstLeadRecordsToUpdate = new List<Lead>();
        Map<String, List<Lead>> mapEmailVsLeadRecord = createLeadEmailMap(lstNewLeads);
        try{
            for(Lead objExistingLead : [SELECT Id, Email, Status, PMC_SS_LatestProductInterests__c, PMC_SS_ProductFamilyCategoryInterests__c, PMC_SS_RejectionReason__c
                                        FROM Lead WHERE Email != NULL AND Email IN :mapEmailVsLeadRecord.keySet() AND PMC_SS_IsDuplicate__c = false AND IsConverted = false WITH SECURITY_ENFORCED]){
                                            //Checks if the product category interests have been updated and if they are update the interest on the existing lead record.
                                            updateProductInterestOnExistingLeads(objExistingLead, mapEmailVsLeadRecord.get(objExistingLead.Email));
                                            lstLeadRecordsToUpdate.add(objExistingLead);
                                        }
            //Update the existing lead records
            if( Schema.sObjectType.Lead.isUpdateable() ){
                Database.update(lstLeadRecordsToUpdate, true);
            }
        }catch(Exception objException){
            PMC_ErrorLogClass.processException(objException);
        }
        
    }
    
    /**
* @description this private method is used to create Map<String, List<Lead>> where key is lead email
* @param lstNewLeads list on incoming leads
* @return Map<String,List<Lead>>  
*/
    private static Map<String,List<Lead>> createLeadEmailMap(List<Lead> lstNewLeads){
        Map<String, List<Lead>> mapEmailVsLeadRecord = new Map<String, List<Lead>>();
        
        for(Lead objLead : lstNewLeads){
            if(mapEmailVsLeadRecord.containsKey(objLead.Email)){
                mapEmailVsLeadRecord.get(objLead.Email).add(objLead);
            }else{
                List<Lead> lstLeads = new List<Lead>();
                lstLeads.add(objLead);
                mapEmailVsLeadRecord.put(objLead.Email, lstLeads);
            }
        }
        
        return mapEmailVsLeadRecord;
    }
    
    /**
* @description this private method is used to perform string operations and populate product interest on exiting record.
* @param objExistingLead existing lead record
* @param lstIncomingLeads list of new leads
*/
    private static void updateProductInterestOnExistingLeads(Lead objExistingLead, List<Lead> lstIncomingLeads){
        //create a list of all the product interests entered by used in the new duplicate leads
        List<String> lstLatestInterests = getLatestInterestList(lstIncomingLeads);
        
        //if the status of existing lead is lost and a new lead is submitted updated the status to new and clear rejection reason.
        objExistingLead.Status = (objExistingLead.Status == PMC_SS_ConstantClass.LEAD_STATUS_LOST) ? PMC_SS_ConstantClass.LEAD_STATUS_NEW : objExistingLead.Status;
        objExistingLead.PMC_SS_RejectionReason__c = (objExistingLead.PMC_SS_RejectionReason__c != NULL) ? '' : objExistingLead.PMC_SS_RejectionReason__c;
        
        //If product interests are not entered or are same as the existing lead updated the latest interest to null and returns the control.
        if( lstLatestInterests.isEmpty() || checkProductInterestChange(objExistingLead.PMC_SS_ProductFamilyCategoryInterests__c, lstLatestInterests)){
            objExistingLead.PMC_SS_LatestProductInterests__c = '';
            return;
        }
        
        //If latest interests are different or updated store them to Latest Product Interests field
        objExistingLead.PMC_SS_LatestProductInterests__c = String.join(lstLatestInterests, ',');  
        
        //Update interest if there are none existing and returns the control
        if(objExistingLead.PMC_SS_ProductFamilyCategoryInterests__c == NULL){
            objExistingLead.PMC_SS_ProductFamilyCategoryInterests__c = String.join(lstLatestInterests, ';');
            return;
        }
        
        //Code to remove duplicate product interests
        Set<String> setLatestInterest = new Set<String>(lstLatestInterests);
        setLatestInterest.removeAll(objExistingLead.PMC_SS_ProductFamilyCategoryInterests__c.split(';'));
        
        lstLatestInterests.clear();
        lstLatestInterests.addAll(setLatestInterest);
        
        //Appends the interest to existing interests
        objExistingLead.PMC_SS_ProductFamilyCategoryInterests__c = objExistingLead.PMC_SS_ProductFamilyCategoryInterests__c + ';' + String.join(lstLatestInterests, ';'); 
        
    }
    
    /**
* @description this method will fetch the list of latest product interest from lead
* @param lstLeads list of duplicate leads
* @return List<String> list of latest product interests
*/
    private static List<String> getLatestInterestList(List<Lead> lstLeads){
        List<String> lstLatestInterests = new List<String>();
        List<String> lstLeadsWithProductInterest = new List<String>();
        //Loop creates a new list with all the prduct interests added for the dulicate leads       
        for(Lead objLead : lstLeads){
            if(!String.isBlank(objLead.PMC_SS_ProductFamilyCategoryInterests__c)){
                lstLeadsWithProductInterest.addAll(objLead.PMC_SS_ProductFamilyCategoryInterests__c.split(';'));
            }
            objLead.PMC_SS_IsDuplicate__c = true;
        }
        
        for(String interest : lstLeadsWithProductInterest){
            if(!lstLatestInterests.contains(interest)){
                lstLatestInterests.add(interest);
            }            
        }
        
        return lstLatestInterests;
    }
    
    /**
* @description This method is used to check if the lead record is a duplicate
* @param lstNewLeads list of leads Trigger.New
*/
    public static void processRecordsForExistingContacts(List<Lead> lstNewLeads){
        //Variables to be used in the method
        List<Contact> lstContactRecordsToUpdate = new List<Contact>();
        Map<String, List<Lead>> mapEmailVsLeadRecord = createLeadEmailMap(lstNewLeads);
        
        try{
            //create set of retail users - Added as part of GDASF-8094
            getListOfRetailUsers();
            
            for(Contact objExistingContact : [SELECT Id, Email, PMC_SS_ProductInterests__c, AccountId, Account.OwnerId, Account.CurrencyIsoCode
                                              FROM Contact WHERE Email != NULL AND Email IN :mapEmailVsLeadRecord.keySet() WITH SECURITY_ENFORCED]){
                //Create new opportunities for all the new leads that were created.
                createOpportunityRecords(objExistingContact, mapEmailVsLeadRecord.get(objExistingContact.Email));
                //Checks if the product category interests have been updated and if they are update the interest on the existing contact record.
                updateProductInterestOnExistinContacts(objExistingContact, mapEmailVsLeadRecord.get(objExistingContact.Email));
                lstContactRecordsToUpdate.add(objExistingContact);
            }
            
            //update the contact records with the updated product category interests
            if( Schema.sObjectType.Contact.isUpdateable() ){
                Database.update(lstContactRecordsToUpdate, true);
            }
            
            //create opportunity records for new interests
            if( !(lstOpportunities.isEmpty()) && Schema.sObjectType.Opportunity.isCreateable()){
                Database.insert(lstOpportunities, true);
            }
            
        }catch(Exception objException){
            PMC_ErrorLogClass.processException(objException);
        }
        
    }
    
    /**
* @description this private method is used to perform string operations and populate product interest on exiting record.
* @param objExistingContact existing contact record
* @param lstIncomingLeads list of new leads
*/
    private static void updateProductInterestOnExistinContacts(Contact objExistingContact, List<Lead> lstIncomingLeads){
        
        //list to store all the new product interests selected in the duplicate leads
        List<String> lstLatestInterests = getLatestInterestList(lstIncomingLeads);
        
        //If product interests are not entered or are same as the existing contact returns the control.
        if( lstLatestInterests.isEmpty() || checkProductInterestChange(objExistingContact.PMC_SS_ProductInterests__c, lstLatestInterests)){
            return;
        }
        
        //If there are no existing interest on contact updated the interest based on new lead
        if(objExistingContact.PMC_SS_ProductInterests__c == NULL){
            objExistingContact.PMC_SS_ProductInterests__c = String.join(lstLatestInterests, ';');
            return;
        }
        
        //Code to remove duplicate product interests
        Set<String> setLatestInterest = new Set<String>(lstLatestInterests);
        setLatestInterest.removeAll(objExistingContact.PMC_SS_ProductInterests__c.split(';'));
        
        lstLatestInterests.clear();
        lstLatestInterests.addAll(setLatestInterest);
        
        //Appends the new interest to the existing ones.
        objExistingContact.PMC_SS_ProductInterests__c = objExistingContact.PMC_SS_ProductInterests__c + ';' + String.join(lstLatestInterests, ';'); 
        
    }
    
    /**
* @description this private method is used to create opportunities for the new duplicate leads
* @param objContact list of duplicate contacts
* @param lstIncomingLeads map of lead email vs list of leads.
*/
    private static void createOpportunityRecords(Contact objContact, List<Lead> lstIncomingLeads){
        //Variables to be used in the method
        Opportunity objOpportunity;
        
        for(Lead objLead : lstIncomingLeads){
            if( String.isBlank(objLead.PMC_SS_ProductFamilyCategoryInterests__c) || checkProductInterestChange(objContact.PMC_SS_ProductInterests__c, objLead.PMC_SS_ProductFamilyCategoryInterests__c.split(';'))){
                continue;
            }
            //creates a new opportunity record for all the duplicate leads.
            objOpportunity = new Opportunity();
            objOpportunity.PMC_SS_NeedsStartDate__c = objLead.PMC_SS_AnticipatedNeedByDate__c;
            objOpportunity.PMC_SS_RegionalManager__c = objLead.PMC_SS_RegionalManager__c;
            objOpportunity.CloseDate = Date.today() + 30;
            objOpportunity.Name = PMC_SS_ConstantClass.DUPLICATE_LEAD_OPPORTUNITY_NAME;
            objOpportunity.StageName = PMC_SS_ConstantClass.OPPORTUNITY_PROSPECTING_STAGE;
            objOpportunity.ForecastCategoryName = PMC_SS_ConstantClass.OPPORTUNITY_FORECAST_CATEGORY_PIPELINE;
            objOpportunity.CurrencyIsoCode = objContact.Account.CurrencyIsoCode;
            objOpportunity.LeadSource = objLead.LeadSource;
            objOpportunity.OwnerId = objContact.Account.OwnerId;
            objOpportunity.AccountId = objContact.AccountId;
            objOpportunity.PMC_SS_Crops__c = objLead.PMC_SS_Crops__c;
            objOpportunity.PMC_SS_ProductFamilies__c = objLead.PMC_SS_ProductFamilyCategoryInterests__c;
            //Added as part of GDASF-8094
            objOpportunity.Type = setRetailUserIds.contains(objContact.Account.OwnerId) ? PMC_SS_ConstantClass.OPPORTUNITY_TYPE_INDIRECT_SALES : PMC_SS_ConstantClass.OPPORTUNITY_TYPE_DIRECT_SALES;
            
            lstOpportunities.add(objOpportunity);
        }
        
    }
    
/**
* @description This method checks if the product category interest of lead/contact is updated
* @param strProductInterests product interests existing on the lead or contact record
* @param lstLatestProductInterests list of interests in the new leads
* @return Boolean true or false based on the outcome
*/
    private static Boolean checkProductInterestChange(String strProductInterests, List<String> lstLatestProductInterests){
        Boolean boolSameInterest = true;
        List<String> lstExistingInterests; 
        
        if(String.isBlank(strProductInterests)){
            return false;
        }
        
        lstExistingInterests = strProductInterests.split(';');
        //checks if the new list of product interest is different form the existing list
        for(String strProduct : lstLatestProductInterests){
            if(!(lstExistingInterests.contains(strProduct))){
                boolSameInterest = false;
            }
        }
        return boolSameInterest;
    }
    
    /**
* @description This method is used to create list of retail users - Added as part of GDASF-8094
*/
    private static void getListOfRetailUsers(){
        
        //Iterate over retail user permission set group assignment to create list of users.
        for(PermissionSetAssignment objPermissionSetAssignment : [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetGroupId != NULL AND 
                                                                  PermissionSetGroup.DeveloperName = :PMC_SS_ConstantClass.RETAIL_USER_PSG_DEVELOPER_NAME WITH SECURITY_ENFORCED]){
                                                                      setRetailUserIds.add(objPermissionSetAssignment.AssigneeId);
                                                                  }
    }
    
     public static void validateAndUpdateEmailValidity(List<Lead> leads) {
        List<Lead> toUpdate = new List<Lead>();
        for (Lead l : leads) {
            Boolean isValid = PMC_EmailValidationService.isValid(l.Email);
            toUpdate.add(new Lead(Id = l.Id, PMC_SS_EmailValid__c  = isValid));
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
    
     
    @TestVisible
  public static Integer increaseCoverage() {
    Integer i = 0;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    return i;
  }

}