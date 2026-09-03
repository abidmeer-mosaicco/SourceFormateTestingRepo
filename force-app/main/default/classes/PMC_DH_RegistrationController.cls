/**
 * @description       : 
 * @author            : @Rohan.Undale
 * @group             : 
     * @last modified on  : 12-02-2023
     * @last modified by  : Mosaic Direct | Dev Team
**/
public without sharing class PMC_DH_RegistrationController {
    
    /**
* @description : Wrapper class for PMC_DH_RegistrationController
* @author      : Humera Rahath 
* @last modified on 05-19-2023
* @last modified by @rravindraundale
**/
        public with sharing class PMC_DH_RegisterUserWrapper{
        public String strLanguage;
        public String strFirstName;
        public String strLastName;
        public String strEmail;
        public String strCountryCode;
        public String strPhoneNumber;
        public String strCountry;
        public String strState;
        public String strCity;
        public String strMarketingEmailConsent;
        public String strAccountNumber;
        public String strBrazilCpf;

        public List<String> lstPreferences;
        /**
    * @description strUserType
    */
        //public String strUserType{get;set;}
    }

    /**
    * @description create Contact based on user inputs
    * 
    * @param strRegistrationInfo JSON with input from user
    * 
        * @return PMC_DH_UserRegistrationWrapper
    *
    * @author rravindraundale@deloitte.com
    * @date 2023-04-26
    */
    @AuraEnabled
        public static PMC_DH_UserRegistrationWrapper registerUser(String strRegistrationInfo){ //added as part of GDASF-19642
            PMC_DH_UserRegistrationWrapper wrpUserRegistration = new PMC_DH_UserRegistrationWrapper(); //added as part of GDASF-19642
        Boolean boolRegistrationStatus = false;
        try{
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        PMC_DH_RegisterUserWrapper objRegisterUserWrapper = (PMC_DH_RegisterUserWrapper) JSON.deserialize(strRegistrationInfo, PMC_DH_RegisterUserWrapper.class);
        Account objAccount = [SELECT Id, AccountNumber 
                            FROM Account 
                            WHERE AccountNumber = :objRegisterUserWrapper.strAccountNumber 
                            WITH SECURITY_ENFORCED LIMIT 1 ];

        
        Contact objContact = new Contact();
        objContact.PMC_DH_Language__c = objRegisterUserWrapper.strLanguage;
        objContact.FirstName = objRegisterUserWrapper.strFirstName;
        objContact.LastName = objRegisterUserWrapper.strLastName;
        objContact.Email = objRegisterUserWrapper.strEmail;
        objContact.MailingCountry = objRegisterUserWrapper.strCountry;
        objContact.PMC_DH_CountryCode__c = objRegisterUserWrapper.strCountryCode;
        objContact.PMC_SS_CPF__c=objRegisterUserWrapper.strBrazilCpf;
        List<String> lstPhnCode=objRegisterUserWrapper.strCountryCode.split(' ');
        string strPhn=lstPhnCode[1];
        objContact.Phone =strPhn+' '+objRegisterUserWrapper.strPhoneNumber;

       // objContact.Phone = objRegisterUserWrapper.strCountryCode+' '+objRegisterUserWrapper.strPhoneNumber;
        objContact.MailingState = objRegisterUserWrapper.strState;
        objContact.MailingCity = objRegisterUserWrapper.strCity;
        objContact.PMC_SS_DigitalHubUser__c=true; //#s&s identifier
        objContact.PMC_Source__c=PMC_DH_ConstantClass.PMC_DH_APPNAME; // # property to trigger mail to super buyer
        objContact.PMC_SS_Status__c= PMC_DH_ConstantClass.ACTIVE_STATUS;
        //  @rohan clean this approach by making wrapper property as boolean instead of string
        if(String.isNotBlank(objRegisterUserWrapper.strMarketingEmailConsent)){
            objContact.PMC_DH_MarketingEmailConsent__c = Boolean.valueOf(objRegisterUserWrapper.strMarketingEmailConsent);
        }
        objContact.AccountId = objAccount.Id;

       
        objContact.PMC_DH_Preferences__c = getPreferencesString(objRegisterUserWrapper.lstPreferences);
         
            
            Set<String> setConIds = getContactIdsFromAccountContactRelations(objAccount.Id);
              
            List<User> objUser=[SELECT Id,Email, ContactId, Profile.Name FROM USER
                                WHERE Profile.Name=:PMC_DH_ConstantClass.USER_PROFILE_DH_SUPER_BUYER //AND AccountId=:objAccount.Id
                                AND ContactId IN :setConIds AND  IsActive=TRUE WITH SYSTEM_MODE];
        
        //List<Contact> objCon = [SELECT Id, Email FROM Contact WHERE Email =:objUser[0].Email];
        
            if(objUser[0].ContactId!=NULL){
                objContact.PMC_DH_Approver__c = objUser[0].ContactId;
            }
       
        
            if(Schema.sObjectType.Contact.isCreateable()){
                insert objContact;
            }
                // Below ACR creation code is commented as required for GPT-31150
                /*List<PMC_SS_AccountPartnerRelationships__c> lstShippingAccount = [SELECT Id, PMC_SS_Account__c,PMC_SS_RelatedAccount__c
                                                                                  FROM PMC_SS_AccountPartnerRelationships__c 
                                                                                  WHERE PMC_SS_Account__c=:objAccount.Id AND PMC_SS_Type__c=:PMC_DH_ConstantClass.ACCOUNT_TYPE
                                                                                  WITH SECURITY_ENFORCED];
                // to identify sold-to changes
                List<PMC_SS_AccountPartnerRelationships__c> lstSoldtoShiptoProcessed = PMC_DH_QuoteManagementHelper.removeDuplicateRelatedAccountsFromList(lstShippingAccount);                                     
        List<AccountContactRelation> lstAccountContactRelation = new List<AccountContactRelation>();
        if(objContact.Id != null && Schema.sObjectType.AccountContactRelation.isCreateable() ){
             // to identify sold-to changes   
                lstAccountContactRelation = getAccountContactRelations(lstSoldtoShiptoProcessed,objContact); 
            Database.insert(lstAccountContactRelation, false);
            }*/
        if(!String.isBlank(objContact.Id)){
            boolRegistrationStatus = true;
        }
            wrpUserRegistration.boolRegistrationStatus = boolRegistrationStatus; //added as part of GDASF-19642
            wrpUserRegistration.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'Registration'); //added as part of GDASF-19642
        //return boolRegistrationStatus;
}
catch(Exception ex){
        wrpUserRegistration.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); //added as part of GDASF-19642
    throw new AuraHandledException(ex.getMessage());
}
    return wrpUserRegistration; //added as part of GDASF-19642
}

/**
* @description create AccountContactRelation records based on inputs
* 
* @param lstShippingAccount List of accounts
* @param objContact Contact object
*
* @return List<AccountContactRelation> AccountContactRelation records
*
* @author rravindraundale@deloitte.com
* @date 2023-05-19
*/
   // Below ACR creation code is commented as required for GPT-31150
    /*public static List<AccountContactRelation> getAccountContactRelations(List<PMC_SS_AccountPartnerRelationships__c> lstShippingAccount, Contact objContact){
    List<AccountContactRelation> lstAccountContactRelation = new List<AccountContactRelation>();
        for(PMC_SS_AccountPartnerRelationships__c objSoldtoShipto : lstShippingAccount){
        AccountContactRelation objAccountContactRelation = new AccountContactRelation();
        objAccountContactRelation.ContactId = objContact.Id;
            objAccountContactRelation.AccountId = objSoldtoShipto.PMC_SS_RelatedAccount__c;
        lstAccountContactRelation.add(objAccountContactRelation);
    }
    return lstAccountContactRelation;
    }*/
//   to identify sold-to changes

/**
* @description returns list of email ids associated with account
* 
* @param accountId String
*
* @return Set<String> AccountContactRelation records
*
* @author rravindraundale@deloitte.com
* @date 2023-05-19
*/
    private static Set<String> getContactIdsFromAccountContactRelations(String accountId){
        Set<String> setConIds = new Set<String>();
        for (AccountContactRelation acr :[SELECT Id,ContactId FROM AccountContactRelation WHERE AccountId =:accountId WITH SYSTEM_MODE]) {
            setConIds.add(acr.ContactId);
    }
        return setConIds;
}


/**
* @description refactored for complexity | converts list to picklist string format
* @author siddharth.pradhan@mosaicco.com | Digital Hub | 06-17-2023 
* @param preferences 
* @return String 
**/
private static String getPreferencesString(List<String> preferences)
{
    Set<String> strPreferences= new Set<String>();
    if(!preferences.isEmpty()){
    for(String strPreference : preferences)
        {
            strPreferences.add(strPreference);
        }
    }
return  String.join(new List<String>(strPreferences), ';');
}
    
        // added as part of GDASF-19642
        /**
    * @description : Wrapper for User Registration
    * @author      : Nikhilesh Mohanty
    * @last modified on 2024-01-10
    **/ 
        public class PMC_DH_UserRegistrationWrapper
        {
            /**
            * @description Boolean flag to indicate if user is successfully registered
            * @author Nikhilesh
            * @return Boolean
            **/ 
            @AuraEnabled
            public Boolean boolRegistrationStatus{get;set;}

            /**
            * @description Status Code and message
            * @author Nikhilesh
            * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
            */
            @AuraEnabled
            public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
        }
        
}