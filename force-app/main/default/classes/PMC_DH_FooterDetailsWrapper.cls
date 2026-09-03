/**
* @description : Wrapper for PMC_DH_FooterController Class
* @author      : Krishan Jangir
* @last modified on 2023-04-11
* @last modified by @KrishanJangir
**/
public class PMC_DH_FooterDetailsWrapper {
    /**
 * @description Wrapper List for My Account Menu
 * @author @KrishanJangir 
 * 
**/
    @AuraEnabled
    public List<MyAccountNavItemsClass> myAccountNavItems{get;set;} 
    /**
* @description Status Code and message
* @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*/
   @AuraEnabled
   public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    /**
     * @description Wrapper class for My Account Menu
     * @author @KrishanJangir    
     */
    public class MyAccountNavItemsClass 
    {
        /**
     * @description  Label of Navigation Menu
     * @return String
     */
        @AuraEnabled
        public string strLabel{get;set;} 
         /**
     * @description  Target of Navigation Menu
     * @return String
     */
        @AuraEnabled
        public string strTarget{get;set;}
        /**
     * @description  Type of Navigation Menu
     * @return String
     */
        @AuraEnabled
        public string strType{get;set;}
    }
    /**
     * @description Wrapper for User Information
     * @author @KrishanJangir    
     */
    @AuraEnabled
    public UserDetailsClass userData{get;set;}
    /**
 * @description Wrapper class for User Information
 * @author @KrishanJangir 
 * 
**/
    public class UserDetailsClass
    {
         /**
     * @description  Location of User 
     * @return String
     */
        @AuraEnabled
        public string strUserLocation{get;set;}
    }
}