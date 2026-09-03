/**
* @description This class will be used to assign Contact & leads to Case
* @author Sayali Shinde
* @storynumber GDASF-1170
*/

public with sharing class PMC_ContactOrLeadAssignmentToCase {

    /**
    * @description Wrapper Class to hold the List Of Cases & respective Email Id & Phone info.
    */

    public Class CaseDetailsWrapper {

        public List<Case> lstCases;
        public Set<String> setWebEmailPhone;

        /**
        * @description Wrapper constructor to hold the List Of Cases & respective Email Id & Phone info.
        * @param lstCases - List of cases which are not tagged with Contact Id
        * @param setWebEmailPhone - set of Case Email or phone
        */
        public CaseDetailsWrapper(List<Case> lstCases, Set<String> setWebEmailPhone) {
            this.lstCases = lstCases;
            this.setWebEmailPhone = setWebEmailPhone;
        }
    }

    /**
	 * @description this method checks case details exists in contact or lead. If not then create the Lead
	 * @param lstNewCases - List of triggering case records
	 */
    
     public static void attachContactLeadOnCase(List<Case> lstNewCases) {
        
        try {
            Set<String> setWebEmailPhone = new Set<String>();
            List<Case> lstCases = new List<Case>();
            
            CaseDetailsWrapper objCaseDetailsWrapper = getNonAssignedContactCases(lstNewCases);

            if(!objCaseDetailsWrapper.lstCases.isEmpty() && !objCaseDetailsWrapper.setWebEmailPhone.isEmpty()) {              

                List<Lead> lstLeads = [SELECT Id, Email FROM Lead 
                                        WHERE Email IN: objCaseDetailsWrapper.setWebEmailPhone  
                                        WITH SECURITY_ENFORCED];

                Map<String, Id> mapContactEmailPhone = prepareMapContactEmailPhone(objCaseDetailsWrapper.setWebEmailPhone);   
                Map<String, Id> mapLeadEmailPhone = prepareMapLeadEmailPhone(lstLeads);  

                lstCases = tagContactLeadOnCase(objCaseDetailsWrapper.lstCases, mapContactEmailPhone, mapLeadEmailPhone);
                
                List<Lead> lstLeadToInsert = createLeadsForCases(lstCases);
                Set<Id> setLeadIds = createAndAssignLeadToCases(lstLeadToInsert);

                if(!setLeadIds.isEmpty()) {
                    Map<String, Id> mapLeadEmailPhone1 = prepareMapLeadEmailPhone([SELECT Id, Email FROM Lead WHERE Id IN: setLeadIds WITH SECURITY_ENFORCED]);
                tagContactLeadOnCase(lstCases, new Map<String, Id>(), mapLeadEmailPhone1);
            }
        }
        }
        catch(QueryException objQueryException) {
            PMC_ErrorLogClass.processException(objQueryException);
        }
    }


    /**
	 * @description this method checks contact tagged for case or not
	 * @param lstNewCases - List of triggering case records
     * @return CaseDetailsWrapper - Case detail wrapper
	 */
    public static CaseDetailsWrapper getNonAssignedContactCases(List<Case> lstNewCases) {

        List<Case> lstCases = new List<Case>();
        Set<String> setWebEmailPhone = new Set<String>();

        for(Case objCase : lstNewCases) {
            
            if(objCase.ContactId == null) {
                lstCases.add(objCase);
                setWebEmailPhone.addAll(getCaseEmailPhone(objCase));
            }
        }
        CaseDetailsWrapper objCaseDetailsWrapper = new CaseDetailsWrapper(lstCases, setWebEmailPhone);
        return objCaseDetailsWrapper;
    }   
    

    /**
	 * @description this method checks for Case email & phone
	 * @param objCase - triggering case records
     * @return Set<String> - Set of Case email & Phone
     */

    public static Set<String> getCaseEmailPhone(Case objCase) {
        Set<String> setWebEmailPhone = new Set<String>();

            if(objCase.SuppliedEmail != null) {
                setWebEmailPhone.add(objCase.SuppliedEmail);
            }
            
            if(objCase.SuppliedPhone != null) {
                setWebEmailPhone.add(objCase.SuppliedPhone);
            }
        return setWebEmailPhone;
    }

    /**
	 * @description this method prepares the Map of EMail & Phone of Contact along with Id
	 * @param setWebEmailPhone - Set of EMail & Phone triggering of cases 
     * @return Map<String, Id> - Map of EMail & Phone of Contact along with Id
	 */
    
    public static Map<String, Id> prepareMapContactEmailPhone(Set<String> setWebEmailPhone) {
        Map<String, Id> mapContactEmailPhone = new Map<String, Id>();
        
        
        for(Contact objContact : [SELECT Id, Email 
                                    FROM Contact 
                                    WHERE Email IN: setWebEmailPhone  WITH SECURITY_ENFORCED]) {
            
            if(objContact.Email != null) {
                mapContactEmailPhone.put(objContact.Email, objContact.Id);
            }
        }
        
        return mapContactEmailPhone;
    }


    /**
	 * @description this method prepares the Map of EMail & Phone of Lead along with Id
	 * @param lstLeads - List of Leads 
     * @return Map<String, Id> - Map of EMail & Phone of Lead along with Id
	 */
    
    public static Map<String, Id> prepareMapLeadEmailPhone(List<Lead> lstLeads) {
        Map<String, Id> mapLeadEmailPhone = new Map<String, Id>();
        
        for(Lead objLead : lstLeads) {
            
            if(objLead.Email != null) {
                mapLeadEmailPhone.put(objLead.Email, objLead.Id);
            }
            
            }            
        return mapLeadEmailPhone;
    }


    /**
	 * @description this method Assign the Contact Id to Case
	 * @param lstNewCases - List of Triggering Cases 
     * @param mapContactEmailPhone - Map of EMail & Phone of Contact along with Id
     * @param mapLeadEmailPhone - Map of EMail & Phone of Lead along with Id
     * @return List<Case> - Returns cases which are not assigned to ContactId or Lead
	 */
    
    public static List<Case> tagContactLeadOnCase(List<Case> lstNewCases, Map<String, Id> mapContactEmailPhone, Map<String, Id> mapLeadEmailPhone) {
        
        List<Case> lstCases = new List<Case>();

        for(Case objCase : lstNewCases) {
            
            if(mapContactEmailPhone.containsKey(objCase.SuppliedEmail)) {
                objCase.ContactId = mapContactEmailPhone.get(objCase.SuppliedEmail);
            }
                else if(mapLeadEmailPhone.containsKey(objCase.SuppliedEmail)) {
                objCase.PMC_SS_Lead__c = mapLeadEmailPhone.get(objCase.SuppliedEmail);
            }
            else {
                lstCases.add(objCase);
            }
        }
        return lstCases;
    }


    /**
	 * @description this method is used to Create Lead Records
	 * @param lstNewCases - List of Triggering Cases 
     * @return List<Lead> - Returns the list of prepared Leads
	 */
    
    public static List<Lead> createLeadsForCases(List<Case> lstNewCases) {

        List<Lead> lstLeadToInsert = new List<Lead>();
        Set<String> setLeadEmailPhone = new Set<String>();
        Id idNewLeadQueue = [SELECT Queue.Id, Queue.Name FROM QueueSObject WHERE Queue.Name =: PMC_SS_ConstantClass.NEW_LEADS_QUEUE WITH SECURITY_ENFORCED LIMIT 1].Queue.Id;
        
        for(Case objCase : lstNewCases) { 
            Lead objLead = new Lead();
            String strName = objCase.SuppliedName != null ? objCase.SuppliedName : objCase.SuppliedEmail.split('@')[0] != null ? objCase.SuppliedEmail.split('@')[0] : '';
            objLead.LastName = strName;
            objLead.MobilePhone = objCase.SuppliedPhone != null ? objCase.SuppliedPhone : '';
            objLead.Email = objCase.SuppliedEmail;
            objLead.Status = PMC_SS_ConstantClass.LEAD_STATUS_NEW;
            objLead.Company = strName;
            objLead.OwnerId = idNewLeadQueue;
            
            if(!setLeadEmailPhone.contains(objCase.SuppliedEmail) && !setLeadEmailPhone.contains(objCase.SuppliedPhone)) {
                lstLeadToInsert.add(objLead);
                setLeadEmailPhone.add(objCase.SuppliedEmail);
                setLeadEmailPhone.add(objCase.SuppliedPhone);
            }
        }
        
        return lstLeadToInsert;
    }


    /**
	 * @description this method is used to insert Lead Records and retrieve success result of insert DML
	 * @param lstLeadToInsert - List of Leads to be inserted
     * @return Set<Id> - Returns the set of id of success result of insert DML
	 */

    public static Set<Id> createAndAssignLeadToCases(List<Lead> lstLeadToInsert) {

        List<Database.SaveResult> lstSaveResult = Database.insert(lstLeadToInsert, false);
        
        Set<Id> setLeadId = new Set<Id>();
        
        for(Database.SaveResult objDbSaveResult : lstSaveResult) {
            if(objDbSaveResult.isSuccess()) {
                setLeadId.add(objDbSaveResult.getId());
            }
        }
        
        return setLeadId;

    }
    
}