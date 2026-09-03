/**
 * 
 * @description Wrapper classes for user registration
 * @author @rravindraundale
 * @last modified on 05-11-2023
 * @last modified by @rravindraundale
 * 
**/

public with sharing class PMC_DH_RegistrationUtilWrappers {
    /**
 * @description Wrapper class for country states
 * @author @rravindraundale 
 * 
**/
public class PMC_DH_UserRegistationDetails{
    /**
     * @description Custom Metadata List for CountryState
     * @return List<PMC_Country__mdt>
     */
    public List<PMC_Country__mdt> lstCountryState;
    /**
     * @description List of Preferences
     * @return List<PMC_DH_PicklistWrapper>
     */
    public List<PMC_DH_PicklistWrapper> lstPreferenceValuesList;
    /**
     * @description countrycode and phone format wrapper
     * @return  PMC_DH_DigitalHubB2BUtils.PhoneFormatWrapper
     */
    public PMC_DH_DigitalHubB2BUtils.PhoneFormatWrapper countryCodePhoneFormat {get;set;} 
    /**
    * @description Status Code and message
    * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
}

/**
* @description       : Wrapper class for VerifyAccessForUserCreation method
* @author            : @rravindraundale 
* 
**/
public class PMC_DH_VerifyAccessForUserCreationWrapper{
    /**
     * @description First Name of User
     * @return FirstName value
     */
    public String strFirstName{get;set;}
    /**
     * @description Last Name of User
     * @return LastName value
     */
    public String strLastName{get;set;}
    /**
     * @description Phone Number of User
     * @return PhoneNumber value
     */
    public String strPhoneNumber{get;set;}
    /**
     * @description Email of User
     * @return Email value
     */
    public String strEmail{get;set;}
    /**
     * @description Check if user is already exist
     * @return boolean value true if present
     */
    public Boolean boolIsUserExisting{get;set;}
    /**
     * @description Check if Super Buyer is Authorized
     * @return boolean value true if Authorized
     */
    public Boolean boolIsSuperBuyerAuthorized{get;set;}
    /**
     * @description List of user types
     * @return list of user types
     */
    public List<PMC_DH_PicklistWrapper> lstUserType{get;set;}
    /**
    * @description Status Code and message
    * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
}
   
}