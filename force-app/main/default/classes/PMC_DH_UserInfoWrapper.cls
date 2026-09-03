/**
* @description : Wrapper class for PMC_DH_UserInfoController
* @author      : Humera Rahath
* @userStory   : GDASF-540 & GDASF-5516 
* @last modified on 05-16-2023
* @last modified by @mhumerarahath
**/
public class PMC_DH_UserInfoWrapper {
    /**
* @description RecordId of User
* @return  String 
*/
    @AuraEnabled
    public String strRecId{get;set;}
    /**
* @description ContactId of User
* @return  String 
*/
    @AuraEnabled
    public String strContactId{get;set;}
    /**
* @description FirstName of User
* @return  String 
*/
    @AuraEnabled
    public String strFirstName{get;set;}
    /**
* @description LastName of User
* @return  String 
*/
    @AuraEnabled
    public String strLastName{get;set;}
    /**
* @description Phone of User
* @return  String 
*/
    @AuraEnabled
    public String strPhone{get;set;}
    /**
* @description Email of User
* @return  String 
*/
    @AuraEnabled
    public String strEmail{get;set;}
    /**
* @description Country of User
* @return  String 
*/
    @AuraEnabled
    public String strCountry{get;set;}
    /**
* @description Country Code of Contact
* @return  String 
*/
    @AuraEnabled
    public String strCountryCode{get;set;}
    /**
* @description Lastname of related Contact
* @return  String 
*/
    @AuraEnabled
    public String strContactLastName{get;set;}
    /**
* @description Phone of related Contact
* @return  String 
*/
    @AuraEnabled
    public String strContactPhone{get;set;}
    /**
* @description BirthDate of related Contact
* @return  String 
*/
    @AuraEnabled
    public String strContactBirthdate{get;set;}
    /**
* @description username of User
* @return  String 
*/
    @AuraEnabled
    public String strUsername{get;set;}
    /**
* @description Class for PhoneFormat
* @return  PMC_DH_DigitalHubB2BUtils.PhoneFormatWrapper 
*/
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PhoneFormatWrapper countryCodePhoneFormat {get;set;}

    /**
* @description Class for Status Code Message
* @return  PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper 
*/
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage {get;set;}
    
}