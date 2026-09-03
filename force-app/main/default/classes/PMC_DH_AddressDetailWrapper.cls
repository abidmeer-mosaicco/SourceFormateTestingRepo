/**
* @description : Wrapper for PMC_DH_AddressesDetailController Class
* @author      : Krishan Jangir
* @last modified on 2023-05-17
* @last modified by @Ajeet
**/
public with sharing class PMC_DH_AddressDetailWrapper {
/**
* @description Wrapper List for address data
* @author @KrishanJangir 
* 
**/  
@AuraEnabled
public List<AddressDetails> addressData{get;set;}

        /**
* @description Wrapper for picklist values
* @author @Lohitha sai
**/ 
@AuraEnabled
public List<PMC_DH_PicklistWrapper> lstPickList{get;set;}
/**
* @description Status Code and message
* @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*/
@AuraEnabled
public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
/**
* @description Wrapper class for address data
* @author @KrishanJangir    
*/
public class AddressDetails{
        /**
* @description Id of the Junction Object
* @return  String 
*/
        @AuraEnabled
        public string strJunctionRecId{get;set;}
        /**
* @description Account Number of Account
* @return  String 
*/
        @AuraEnabled
        public string strShipToAccountNumber{get;set;}
        /**
* @description Record Id of Account
* @return  String 
*/
        @AuraEnabled
        public string strRecId{get;set;}
        /**
* @description Phone Number of Account
* @return  String 
*/
        @AuraEnabled
        public string strNumber{get;set;}
        /**
* @description Name of Account
* @return  String 
*/
        @AuraEnabled
        public string strAddressName{get;set;}
        /**
* @description CNPJ of Account
* @return  String 
*/
        @AuraEnabled
        public String strCnpj{get;set;}
        /**
* @description Type of Account
* @return  String 
*/
        @AuraEnabled
        public string strAddressType{get;set;}
        /**
* @description address of Account
* @return  String 
*/
        @AuraEnabled
        public string strAddress{get;set;}
        /**
* @description City of Account
* @return  String 
*/
        @AuraEnabled
        public string strCity{get;set;}
        /**
* @description State of Account
* @return  String 
*/
        @AuraEnabled
        public string strState{get;set;}
        /**
* @description Status of Account
* @return  String 
*/
        @AuraEnabled
        public string strStatus{get;set;}
        /**
* @description Zipcode of Account
* @return  String 
*/
        @AuraEnabled
        public string strZipcode{get;set;}

/**
* @description search string
* @return  String 
*/
        @AuraEnabled
        public string strSearchString{get;set;}
        /**
* @description Wrapper for parent Info
* @author @KrishanJangir 
* 
**/  
        @AuraEnabled
        public ParentDetails parent{get;set;}

        /**
         * @description State Subscription
         * @return String // added as a part of GDASF-19874
         */
        @AuraEnabled
        public String strStateSubscription{get;set;}

        /**
         * @description CPF
         * @return String // added as a part of GDASF-19874
         */
        @AuraEnabled
        public String strCPF{get;set;}
         /**
                * @description  Property Farm Name
                * @return  String 
                */
                @AuraEnabled
                public string strPropertyFarmName{get;set;}

}

        /**
* @description Wrapper Class for parent Info
* @author @KrishanJangir 
* 
**/  
public class ParentDetails{
        /**
* @description Id of Parent Account
* @return  String 
*/
        @AuraEnabled
        public string strId {get;set;}
  
        /**
* @description Name of Parent Account
* @return  String 
*/
        @AuraEnabled
        public string strName {get;set;}
        /**
* @description Account number of Parent Account
* @return  String 
*/
        @AuraEnabled
        public string strAccountNumber {get;set;} 
}

}