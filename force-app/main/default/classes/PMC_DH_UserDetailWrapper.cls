/**
 * 
 * Class Name      :PMC_DH_UserDetailWrapper
 * @description    :wrapper for PMC_DH_UserDetailController 
 * @author       :Krishan
 * @last modified by Nikhilesh
 * @last modified on 05-15-2023
 * Created On       :2023-04-24 
**/
public class PMC_DH_UserDetailWrapper {
    /**
    * @description List of user
    * @return List of UserDetailsDate type
    */
   @AuraEnabled
   public List<UserDetailsData> userList{get;set;}

   /**
    * @description Status Code and message
    * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    */
   @AuraEnabled
   public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}

   /**
   * @description Wrapper class for user details
   * @author Krishan 
   * 
   **/
   public class UserDetailsData { 
       /**
       * @description Record Id of user
       * @return Record Id value
       */
       @AuraEnabled public String strRecId {get;set;}
       /**
       * @description Username of user
       * @return Username value
       */
       @AuraEnabled public String struserName {get;set;}
       /**
       * @description Type of user
       * @return User type value 
       */
       @AuraEnabled public String strUserType {get;set;}
       /**
       * @description Email of user
       * @return User email value
       */
       @AuraEnabled public String strUserEmail {get;set;}
       /**
       * @description Phone of user
       * @return User phone value
       */
       @AuraEnabled public String strPhone {get;set;}
       /**
       * @description Local of user
       * @return User local value
       */
       @AuraEnabled public String strLocal {get;set;}
       /**
       * @description Status of user
       * @return User status value
       */
       @AuraEnabled public String strStatus {get;set;}
       /**
       * @description Country code of user
       * @return User country code value
       */
       @AuraEnabled public String strCountryCode {get;set;}
   }

}