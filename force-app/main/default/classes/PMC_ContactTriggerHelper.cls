/**
* @description This class will be used to handle all triggers on Contact object.
* @author Sayali Shinde
* @storynumber GDASF-8472
*/

public with sharing class PMC_ContactTriggerHelper {


    /**
    * @description Wrapper Class to hold the Contact related info.
	*/    

    public class ContactWrapper {
        public String strContactName;
        public String strContactErrorLabel;
        public Contact objContact;

        /**
        * @description Wrapper constructor to hold the Contact related info.
        * @param strContactName - holds Contact Name
        * @param strContactErrorLabel - holds Custom Label Value
        * @param objContact - Actual Contact Record
        * 
		*/
        
        public ContactWrapper(String strContactName, String strContactErrorLabel, Contact objContact) {
            this.strContactName = strContactName;
            this.strContactErrorLabel = strContactErrorLabel;
            this.objContact = objContact;
        }
    }
	

    /**
    * @description This method will be used to check the duplicate phone, mobile, whats app no.s across all the records.
    * @param mapOldContacts - Map of Old contact records
    * @param lstNewContacts - List of triggering Contact records.
    */

    public static void checkDuplicateContactNos(Map<Id, Contact> mapOldContacts, List<Contact> lstNewContacts) {
        
        try {

            List<Contact> lstContacts = new List<Contact>();
            
            Map<String,String> setPhoneNos = prepareTriggeringContactPhoneSet(mapOldContacts, lstNewContacts);
            Set<String> setPhonenumbers = new Set<String>();
            Set<String> setHomePhonenumbers = new Set<String>();
            Set<String> setMobilePhonenumbers = new Set<String>();
            Set<String> setOtherPhonenumbers = new Set<String>();
            for(String keyval:setPhoneNos.keySet()){
                if(keyVal == 'Phone'){
                    setPhonenumbers.add(setPhoneNos.get('Phone'));
                }else if(keyVal == 'HomePhone'){
                    setHomePhonenumbers.add(setPhoneNos.get('HomePhone'));
                }else if(keyVal == 'MobilePhone'){
                    setMobilePhonenumbers.add(setPhoneNos.get('MobilePhone'));
                }else if(keyVal == 'OtherPhone'){
                    setOtherPhonenumbers.add(setPhoneNos.get('OtherPhone'));
                }
            }
			
            lstContacts = [SELECT Id, Name, Phone, HomePhone, MobilePhone, OtherPhone 
                                            FROM Contact 
                                            WHERE Phone IN: setPhonenumbers OR
                                            HomePhone IN: setHomePhonenumbers OR 
                                            MobilePhone IN: setMobilePhonenumbers OR
                                            OtherPhone IN: setOtherPhonenumbers WITH SECURITY_ENFORCED]; 
            
            if(lstContacts.size() > 0) {
                
                Map<String, ContactWrapper> mapExistingContactPhones = new Map<String, ContactWrapper>();
                
                for(Contact objContact : lstContacts) {
                    mapExistingContactPhones.putAll(addNewPhoneNosToSet(objContact));
                }
                                    
                showErrorOnDuplicatePhone(mapExistingContactPhones, lstNewContacts);
            }
            else {
                showErrorOnDuplicatePhone(null, lstNewContacts);
            }
        }
        catch(Exception objQueryException) {
            PMC_ErrorLogClass.processException(objQueryException);
        }
    }
    
    /**
    * @description This method will be used to add the phone, mobile, whats app no.s from triggering Contact record to a Set.
    * @param mapOldContacts - Map of Old contact records
    * @param lstNewContacts - List of triggering Contact records.    
    * @return Set<String> - triggering Contact record's phone field values
    */
    
    public static Map<String,String> prepareTriggeringContactPhoneSet(Map<Id, Contact> mapOldContacts, List<Contact> lstNewContacts) {
        Map<String,String> setPhoneNos = new Map<String,String>();
        
        for(Contact objContact : lstNewContacts) {
            
            if(mapOldContacts != null) {
                setPhoneNos.putAll(PMC_ContactTriggerHelperMethod.addOldPhoneNosToSet(mapOldContacts, objContact));                
            }
            else {
                setPhoneNos.putAll(PMC_ContactTriggerHelperMethod.addNewPhoneNosToMap(objContact));    
            }
        }
        
        return setPhoneNos;
    }

    
     /**
    * @description This method will be used to add the phone, mobile, whats app no.s from triggering Contact record to a Set.
    * @param objContact - contact records
    * @return Map<String, Contact> - Map of contact phone nos.
	*/    

      public static Map<String, ContactWrapper> addNewPhoneNosToSet(Contact objContact) {
        
        Map<String, ContactWrapper> mapExistingContactPhones = new Map<String, ContactWrapper>();

        String strContactName = objContact.Name != null ? objContact.Name : getNewContactName(objContact);

        if(objContact.Phone != null) {
            ContactWrapper objContactWrapper = new ContactWrapper(strContactName, Label.PMC_SS_DuplicatePhone_NoContactError, objContact);
            mapExistingContactPhones.put(objContact.Phone, objContactWrapper);
        }
        
        if(objContact.HomePhone != null) {
            ContactWrapper objContactWrapper = new ContactWrapper(strContactName, Label.PMC_SS_DuplicateHomePhone_NoContactError, objContact);
            mapExistingContactPhones.put(objContact.HomePhone, objContactWrapper);
        }
        
        if(objContact.MobilePhone != null) {
            ContactWrapper objContactWrapper = new ContactWrapper(strContactName, Label.PMC_SS_DuplicateMobile_NoContactError, objContact);
            mapExistingContactPhones.put(objContact.MobilePhone, objContactWrapper);
        }
        
        if(objContact.OtherPhone != null) {
            ContactWrapper objContactWrapper = new ContactWrapper(strContactName, Label.PMC_SS_DuplicateWhatsApp_NoContactError, objContact);
            mapExistingContactPhones.put(objContact.OtherPhone, objContactWrapper);
        }
        
        return mapExistingContactPhones;
    }
	
    
    
        
    /**
    * @description This method will be used to show error message on duplicate phone no.s.
    * @param mapExistingContactPhones - Map of duplicate contact records
    * @param lstNewContacts - List of triggering Contact records.
    */
    
    public static void showErrorOnDuplicatePhone(Map<String, ContactWrapper> mapExistingContactPhones, List<Contact> lstNewContacts) {
            
        try {
            for(Contact objContact : lstNewContacts) {
                                    
                String strErrorMsg = '';
                                
                if(mapExistingContactPhones != null) {
                    strErrorMsg = getErrorMessage(mapExistingContactPhones, objContact);
                }
                else {
                    mapExistingContactPhones = new Map<String, ContactWrapper>();
                }
                
                if(!String.isBlank(strErrorMsg)) {
                    objContact.addError(strErrorMsg);
                }
                else {
                    mapExistingContactPhones.putAll(addNewPhoneNosToSet(objContact));
                }
            }
        }
        catch(Exception objQueryException) {
            PMC_ErrorLogClass.processException(objQueryException);
        }
    }

    /**
    * @description This method will be used to prepare contact name
    * @param mapExistingContactPhones - Map of Contact & their phones
    * @param objContact - Contact records.
    * @return String - Returns contact name
    */
    
    public static String getErrorMessage(Map<String, ContactWrapper> mapExistingContactPhones, Contact objContact) {
        String strErrorMsg = '';

        if(mapExistingContactPhones.containsKey(objContact.Phone)) {
            ContactWrapper objContactWrapper = mapExistingContactPhones.get(objContact.Phone);
            strErrorMsg = objContactWrapper.strContactErrorLabel.replace('#', objContactWrapper.strContactName);
        }
        else if(mapExistingContactPhones.containsKey(objContact.HomePhone)) {
            ContactWrapper objContactWrapper = mapExistingContactPhones.get(objContact.HomePhone);
            strErrorMsg = objContactWrapper.strContactErrorLabel.replace('#', objContactWrapper.strContactName);
        }  
        else if(mapExistingContactPhones.containsKey(objContact.MobilePhone)) {
            ContactWrapper objContactWrapper = mapExistingContactPhones.get(objContact.MobilePhone);
            strErrorMsg = objContactWrapper.strContactErrorLabel.replace('#', objContactWrapper.strContactName);
        }   
        else if(mapExistingContactPhones.containsKey(objContact.OtherPhone)) {
            ContactWrapper objContactWrapper = mapExistingContactPhones.get(objContact.OtherPhone);
            strErrorMsg = objContactWrapper.strContactErrorLabel.replace('#', objContactWrapper.strContactName);
        }
                
        return strErrorMsg;
    }

    /**
    * @description This method will be used to prepare contact name
    * @param objContact - Contact records.
    * @return String - Returns contact name
    */

    public static String getNewContactName(Contact objContact) {
       return objContact.FirstName != null ? objContact.FirstName + ' ' + objContact.LastName : objContact.LastName;
    }
    
    /**
     * Valida e atualiza o campo PMC_SS_EmailValid__c para cada Contact informado.
     */
    public static void validateAndUpdateEmailValidity(List<Contact> contacts) {
        List<Contact> toUpdate = new List<Contact>();
        for (Contact c : contacts) {
            Boolean isValid = PMC_EmailValidationService.isValid(c.Email);
            toUpdate.add(new Contact(Id = c.Id, PMC_SS_EmailValid__c = isValid));
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
    
    
}