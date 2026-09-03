/**
 * @description       : 
 * @author            : @krishan
 * @group             : 
 * @last modified on  : 05-29-2023
 * @last modified by  : @digital.hub
**/

public class PMC_DH_ShipToAddressCreationWrapper{
            /**
* @description listofstate
* @return  String 
*/
    @AuraEnabled 
    public List<LstState> lstState{get;set;}
    /**
* @description list of countries
* @return  String 
*/
    @AuraEnabled 
    public List<PMC_DH_PicklistWrapper> lstcountries{get;set;}
    /**
        * @description Status Code and message
        * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
        */
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
            /**
 * @description Wrapper class for Cart
 * @author @krishan 
 * 
**/
    public class LstState{
                /**
* @description label
* @return  String 
*/
        @AuraEnabled 
        public String strLabel{get;set;}
                /**
* @description value
* @return  String 
*/
        @AuraEnabled 
        public String strValue{get;set;}
        
    }
            /**
* @description list of address type
* @return  String 
*/
    @AuraEnabled
    public List<AddressType> lstAddressType{get;set;}
            /**
 * @description Wrapper class for AddressType
 * @author @krishan 
 * 
**/
    public class AddressType{
                /**
* @description strLabel
* @return  String 
*/
        @AuraEnabled 
        public String strLabel{get;set;}
                /**
* @description strValue
* @return  String 
*/
        @AuraEnabled 
        public String strValue{get;set;}
        
    }


    /**
* @description list of Person Or Organization
* @return  String 
*/
    @AuraEnabled
    public List<PersonOrOrganization> lstPersonOrOrganization{get;set;}
            /**
 * @description Wrapper class for AddressType
 * @author @krishan 
 * 
**/
    public class PersonOrOrganization{
                /**
* @description strLabel
* @return  String 
*/
        @AuraEnabled 
        public String strLabel{get;set;}
                /**
* @description strValue
* @return  String 
*/
        @AuraEnabled 
        public String strValue{get;set;}
        
    }
    
}