/**
* @description This class will be used to link the Entitlement Record to Case When it is inserted .
* @author satish
* @storynumber GDASF-14463,14462
*/
public with sharing class PMC_SS_CaseEntitlementProcess {
    /**
    * @description This method will be used to populate the entitlement record in case object.
    * @param lstNewCases - List of new Case records.
    */
    public static void assignEntitlmentRecordToCases(List<Case> lstNewCases) {
        try {
        	Set<Id> setAccIds = new Set<Id>();
        	Set<Id> setContactIds = new Set<Id>();
        	for (Case objCase : lstNewCases) {
            	if (objCase.AccountId != null) {
                setAccIds.add(objCase.AccountId);
            	}
            	else if(objCase.ContactID != null) {
                setContactIds.add(objCase.ContactID);
            	}
        	}
        	Map<Id, Id> mapConIDtoAccouuntID = new Map<Id, Id>();
        	if(!setContactIds.isEmpty()) {
            for(Contact objContact : [SELECT ID, AccountID from Contact WHERE ID IN: setContactIds WITH SECURITY_ENFORCED])
            	{
               		mapConIDtoAccouuntID.put(objContact.Id,objContact.AccountID);
                	setAccIds.add(objContact.AccountID);
            	}
        	}
        	Map<Id, Id> mapaccountEntitlements = queryEntitlements(setAccIds);
        	createEntitlements(lstNewCases, mapaccountEntitlements,mapConIDtoAccouuntID);
        }
        catch(Exception objQueryException) {
            PMC_ErrorLogClass.processException(objQueryException);
        }
    }
    /**
    * @description This method will be used to get entitlement records if it is already linked to account.
    * @param setAccIds - List of Accounts
    * @return mapaccountEntitlements - map of old Entitlement records
    */
    private static Map<Id, Id> queryEntitlements(Set<Id> setAccIds) {
        Map<Id, Id> mapaccountEntitlements = new Map<Id, Id>();
        for (Entitlement objEntitlement : [SELECT Id, AccountId FROM Entitlement WHERE AccountId IN :setAccIds AND Status = 'Active' WITH SECURITY_ENFORCED]) {
            mapaccountEntitlements.put(objEntitlement.AccountId, objEntitlement.Id);
            setAccIds.remove(objEntitlement.AccountId);
        }
        if(!setAccIds.isEmpty()) {
            mapaccountEntitlements.putAll(insertEntitlements(setAccIds));
        }
        return mapaccountEntitlements;
    }
    /**
    * @description This method will be used to link Entitlement recods if already exist if not it will create Entitlement .
    * @param setAccIds - Set of AccountID of Case reords.
    * @return  mapaccountEntitlements - map of old Entitlement records
    */
    private static Map<Id, Id> insertEntitlements(Set<Id> setAccIds ) {
        Map<Id, Id> mapaccountEntitlements = new Map<Id, Id>();
        list<Entitlement> lstEntitlements = new List<Entitlement>();
        Id entitlementProcessID = getActiveEntitlementProcessId(PMC_SS_ConstantClass.ENTITLEMENT_PROCESS_NAME);
        if(entitlementProcessID != null) {
            for (Account objAccount : [SELECT Id,Name FROM Account WHERE Id IN:setAccIds WITH SECURITY_ENFORCED]) {                                          
                Entitlement newEntitlement = new Entitlement(
                    AccountId = objAccount.Id,
                    Name = objAccount.Name,
                    Startdate =system.today(),
                    SlaProcessId=entitlementProcessID
                );
                lstEntitlements.add(newEntitlement);
            }
        }
        if(!lstEntitlements.isEmpty()) {
            Database.SaveResult[] lstSaveResult = Database.insert(lstEntitlements, false);
            for (Integer i = 0; i < lstSaveResult.size(); i++) {
                if (lstSaveResult[i].isSuccess()) {
                    mapaccountEntitlements.put(lstEntitlements[i].AccountId, lstSaveResult[i].getId());
                }
            }
        }
       return mapaccountEntitlements;
    }
    /**
    * @description This method will be used to link Entitlement recods if already exist if not it will create Entitlement .
    * @param lstCases - List of Case reords.
    * @param  mapaccountEntitlements - map of old Entitlement records
	* @param mapConIDtoAccouuntID - map of contact id and account Id 
    */
    private static void createEntitlements(List<Case> lstCases, Map<Id, Id> mapaccountEntitlements,Map<Id, Id> mapConIDtoAccouuntID) {
        for (Case objCase : lstCases) {
            if (objCase.AccountId != null && mapaccountEntitlements.containsKey(objCase.AccountId)) {
                objCase.EntitlementId = mapaccountEntitlements.get(objCase.AccountId);
            }
            else if( objCase.ContactID != null && mapConIDtoAccouuntID.containsKey(objCase.ContactID) &&
                        mapaccountEntitlements.containsKey(mapConIDtoAccouuntID.get(objCase.ContactID))){
                objCase.EntitlementId = mapaccountEntitlements.get(mapConIDtoAccouuntID.get(objCase.ContactID));
            }
        }
    }
    /**
    * @description This method will be used to get Entitlement Process.
    * @return entitlementprocess.Id - Entitlement Process ID .
    * @param strEntitlementProcessname -string variable to pass the process name
    */
    private static Id getActiveEntitlementProcessId(String strEntitlementProcessname) {
        SlaProcess entitlementprocess = [SELECT Id FROM SlaProcess WHERE Name = :strEntitlementProcessname AND IsActive = true WITH SECURITY_ENFORCED LIMIT 1];
        return (entitlementprocess != null) ? entitlementprocess.Id : null;
    }
}