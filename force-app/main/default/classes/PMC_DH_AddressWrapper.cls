/**
* @description       : Wrapper for Address details
* @author            : @Krishan Jangir
* @group             : 
* @last modified on  : 03-06-2024
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
public class PMC_DH_AddressWrapper {
        /**
        * @description  object of AddressViewDetails
        * @author    @Krishan Jangir
        */
        @AuraEnabled
        public AddressViewDetails addressData{get;set;}
        /**
        * @description  list of states
        * @author    @Krishan Jangir 
        */
        @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lststates{get;set;}
         /**
        * @description  list of states
        * @author    @Shubhada 
       */
        @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstcountries{get;set;} 
         /**
        * @description  list of Customer Type
        * @author    @Shubhada
        */
        @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstPersonOrOrganizationWrap{get;set;}
        /**
        * @description  list of address types
        * @author    @Krishan Jangir 
        */
        @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstAddType{get;set;}
        /**
        * @description  List of SoldToAcc
        * @author    @Krishan Jangir 
        */
        @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstSoldToAcc{get;set;} 
        /**
        * @description Status Code and message
        * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
        */
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}

        /**
        * @description       : Wrapper for Address View details
        * @author            : @Krishan Jangir
        * @group             : 
        * @last modified on  : 03-06-2024
        * @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
        **/
        public class AddressViewDetails{
                /**
                * @description Account Id
                * @return  String 
                */
                @AuraEnabled
                public string strAccountId{get;set;}
                /**
                * @description  Perso Or Organization
                * @return  String 
                */
                @AuraEnabled
                public string strPersonOrOrganization{get;set;}
                /**
                * @description  Property Farm Name
                * @return  String 
                */
                @AuraEnabled
                public string strPropertyFarmName{get;set;}
            /**
                * @description Sold to ship to junction object 
                * @return  String 
                */
                @AuraEnabled
                public string strJunctionAccountId{get;set;}
                /**
                * @description Name of address
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
                * @description Street Number  
                * @return  String 
                */
                @AuraEnabled
                public string strNumber{get;set;}
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
                * @description Country of Account
                * @return  String 
                */
                @AuraEnabled
                public string strDistrict{get;set;}
                 /**
                * @description addressNumber of Account
                * @return  String 
                */
                @AuraEnabled
                public string straddressNumber{get;set;}
                 /**
* @description 
* @author @shubhada 
* @return string 
**/
        @AuraEnabled
        public string strcontactPhone{get;set;}
         /**
* @description 
* @author @shubhada 
* @return string 
**/

        @AuraEnabled
        public string strcontactEmail{get;set;}
                
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
                * @description old sold to account
                * @return  String 
                */
                @AuraEnabled
                public string strOldSoldToAcc{get;set;}
                /**
                * @description delivery instruction of Account
                * @return  String 
                */
                @AuraEnabled
                public string strDeliveryInstructions{get;set;}
                /**
                * @description sold to  Account
                * @return  String 
                */
                @AuraEnabled
                public string strSoldToAcc{get;set;}
                /**
                * @description  Country
                * @return  String 
                */
                @AuraEnabled
                public string strCountry{get;set;}

                /**
                 * @description to valid whether mandatory fields are edited ot not
                 * @return Boolean // added as fix to GPT-29290
                 */
                @AuraEnabled
                public Boolean boolMandatoryChanged{get;set;}

                /**
                 * @description to valid whether mandatory fields are edited ot not
                 * @return Boolean // added as fix to GPT-29290
                 */
                @AuraEnabled
                public Boolean boolIsMutiple{get;set;} //used in CR | GDASF-GDASF-20198
                /**
                 * @description state subscription
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
        }     
                
}