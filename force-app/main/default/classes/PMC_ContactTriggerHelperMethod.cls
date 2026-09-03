/**
* @description This class will be used to handle all triggers on Contact object.
* @author Sayali Shinde
* @storynumber GDASF-8472
*/

public with sharing class PMC_ContactTriggerHelperMethod {
    
    
    /**
    * @description This method will be used to add the phone, mobile, whats app no.s from triggering Contact record to a Set.
    * @param mapOldContacts - Map of Old Contact records 
    * @param objContact - contact records
    * @return Set<String> - set of phone nos.
    */

    public static Map<String,String> addOldPhoneNosToSet(Map<Id, Contact> mapOldContacts, Contact objContact) {

        Map<String,String> setPhoneNos = new Map<String,String>();

        if(objContact.Phone != mapOldContacts.get(objContact.Id).Phone && objContact.Phone != null) {
            setPhoneNos.put('Phone',objContact.Phone);
        }
        
        if(objContact.HomePhone != mapOldContacts.get(objContact.Id).HomePhone && objContact.HomePhone != null) {
            setPhoneNos.put('HomePhone',objContact.HomePhone);
        }
        
        if(objContact.MobilePhone != mapOldContacts.get(objContact.Id).MobilePhone && objContact.MobilePhone != null) {
            setPhoneNos.put('MobilePhone',objContact.MobilePhone);
        }
        
        if(objContact.OtherPhone != mapOldContacts.get(objContact.Id).OtherPhone && objContact.OtherPhone != null) {
            setPhoneNos.put('OtherPhone',objContact.OtherPhone);
        }

        return setPhoneNos;
    }
    
    
    /**
    * @description This method will be used to add the phone, mobile, whats app no.s from triggering Contact record to a Map.
    * @param objContact - contact records
    * @return Map<String, String> - Map of contact phone nos.
    */

    public static Map<String,String> addNewPhoneNosToMap(Contact objContact) {
        Map<String,String> setNewPhoneNos = new Map<String,String>();
        if(objContact.Phone != null) {
            setNewPhoneNos.put('Phone',objContact.Phone);
        }
        
        if(objContact.HomePhone != null) {
            setNewPhoneNos.put('HomePhone',objContact.HomePhone);
        }
        
        if(objContact.MobilePhone != null) {
            setNewPhoneNos.put('MobilePhone',objContact.MobilePhone);
        }
        
        if(objContact.OtherPhone != null) {
            setNewPhoneNos.put('OtherPhone',objContact.OtherPhone);
        }
       
        return setNewPhoneNos;
    }
	
    
}