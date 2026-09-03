/**
* @description : Wrapper class for PMC_DH_HeaderDetails
* @author      : Humera Rahath
* @userStory   : GDPH-299 & GDPH -185
* @last modified on 05-11-2023
* @last modified by @mhumerarahath
**/

public class PMC_DH_HeaderDetailsWrapper 
{
     /**
     * @description Status Code and message
     * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
     */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}

     /**
 * @description Wrapper List for My Account Menu
 * @author @mhumerarahath 
 * 
**/ 
    @AuraEnabled
    public List<MyAccountNavItemsClass> myAccountNavItems{get;set;}
    /**
     * @description Wrapper class for My Account Menu
     * @author @mhumerarahath    
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
     * @author @mhumerarahath    
     */
    @AuraEnabled
    public UserDetailsClass userData{get;set;}
     /**
 * @description Wrapper class for User Information
 * @author @mhumerarahath 
 * 
**/ 
    public class UserDetailsClass
    {
        /**
     * @description  UserName of User
     * @return String
     */
        @AuraEnabled
        public string strUserName{get;set;}
        /**
     * @description  Location of User 
     * @return String
     */
        @AuraEnabled
        public string strUserLocation{get;set;}
    }
      /**
 * @description Wrapper List for Navigation Menu
 * @author @mhumerarahath 
 * 
**/ 
    @AuraEnabled
    public List<NavigationMenuItemsClass> navigationMenuItems{get;set;}
          /**
 * @description Wrapper class for Navigation Menu
 * @author @mhumerarahath 
 * 
**/
    public class NavigationMenuItemsClass
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
     * @description Type of Navigation Menu  
     * @return String
     */
        @AuraEnabled
        public string strType{get;set;}
        
    }
    /**
     * @description Wrapper for language preference
     * @author Hemant giri goswami
     * @since 09-25-2023
     */
    @AuraEnabled
    public  PMC_DH_LanguagePreferenceController.LanguagePreferenceWrapper langPrefeWrapper{get;set;}
  



    /**
     * @description  Cart Access 
     * @return Boolean
     */
    @AuraEnabled
    public Boolean boolIsCart{get;set;}
    
    /**
     * @description bool seedz Access
     * @return Boolean
     */
    @AuraEnabled
    public Boolean boolIsSeedZAccess{get;set;}
    
}