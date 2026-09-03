/**
 * @description       : Main Class for the User Registration
 * @author            : @siddharth.pradhan
 * @group             : 
 * @last modified on  : 03-20-2024
 * @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/

public without  sharing class PMC_DH_ContactUtils {
    /**
    * @description Create user and assign required permissions according to role
    * 
    * @param emailId String emailId for check in Contact
    * @param roleLabel String role Label for assigning permissions accordingly
    * @return  PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    * @author rravindraundale@deloitte.com
    * @date 2023-05-05
    */
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper createNewUser(String emailId, String roleLabel){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        try{
            String strEmailId = emailId.toLowerCase();
            List<Contact> lstContact;
            Id profileId=getProfileIdForNewUser(roleLabel);

            if(Schema.sObjectType.Contact.isAccessible()){ 
            lstContact = [SELECT Id, FirstName, LastName, PMC_DH_Language__c, Phone, Email, AccountId, MailingCountry, MailingState, MailingCity
                                        FROM Contact 
                                        WHERE Email = :strEmailId LIMIT 1];
            }

            if(lstContact.isEmpty()){
                return PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.FAILURE_STATUS_CODE, PMC_DH_ConstantClass.NEW_USER);
            }
   
            User objUser = new user();
            objUser.FirstName = lstContact[0].FirstName;
            objUser.LastName = lstContact[0].LastName;
            objUser.Email = lstContact[0].Email;
            objUser.Phone = lstContact[0].Phone;
            objUser.IsActive = true;
            objUser.ContactId = lstContact[0].Id;
            objUser.Alias = lstContact[0].Email.substring(0, 2);
            objUser.Username = lstContact[0].Email + System.label.PMC_DH_OrgName;
            objUser.Country = lstContact[0].MailingCountry;
            objUser.State = lstContact[0].MailingState;
            objUser.City = lstContact[0].MailingCity;
            String strNickname = getUserNickname(strEmailId);
            
            objUser.CommunityNickname = strNickname;
            objUser.LocaleSidKey = 'en_US';
            objUser.LanguageLocaleKey = 'en_US';
            if(lstContact[0].PMC_DH_Language__c!=NULL &&  lstContact[0].PMC_DH_Language__c!=''){
                PMC_DH_Store_Language__mdt config = PMC_DH_Store_Language__mdt.getInstance(lstContact[0].PMC_DH_Language__c);
                objUser.LocaleSidKey =  config.User_Locale__c;
                objUser.LanguageLocaleKey = config.User_Locale__c;
            }
            objUser.TimeZoneSidKey = 'GMT';
            objUser.ProfileID = profileId;
            objUser.EmailEncodingKey = 'UTF-8';
            objUser.FederationIdentifier = strEmailId;
            if(Schema.sObjectType.User.isCreateable()){
                insert objUser;
                //assignPermissionsToUser(objUser.Id, roleLabel); // commeneted as part of the Hyper Care and handled in the Trigger
            }
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE,PMC_DH_ConstantClass.NEW_USER);
        }
        catch(Exception ex){
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
            //throw new AuraHandledException(ex.getMessage());
        }
        return result;
    }

    /**
    * @description assign required permissions according to role
    * 
    * @param strEmailId String strEmailId for creating nickname
    * @return String strNickname is nickname assigned for user
    * @author rravindraundale@deloitte.com
    * @date 2023-05-11
    */
    public static String getUserNickname(String strEmailId){
        String strNickname;
        if(String.isNotBlank(strEmailId)) {
            strNickname = strEmailId.substring(0, strEmailId.indexOf('@'));
            if(strNickname.length() > 25) {
                strNickname = strNickname.substring(0, 25);
            }
        }
        return strNickname;
    }

/**
    * @description get Profile Name according to role
    * 
    * @param roleLabel String roleLabel for fetching related permissions
    * @return String
    * @author rravindraundale@deloitte.com
    * @date 2023-05-05
    */
    public static String getProfileName(String roleLabel){
        PMC_DH_PersonaPermissionSetGroup__mdt[] lstPersonaPermissionSetGroup = PMC_DH_PersonaPermissionSetGroup__mdt.getAll().values();
        String strProfileName = '';
        for(PMC_DH_PersonaPermissionSetGroup__mdt objPersonaPermissionSetGroup : lstPersonaPermissionSetGroup){
            if(objPersonaPermissionSetGroup.DeveloperName == roleLabel){
                strProfileName = objPersonaPermissionSetGroup.strProfile__c;
                break;
            }
        }
        return strProfileName;
    }

    /**
    * @description assign required permissions according to role
    * 
    * @param userId String userId for check in User
    * @param roleLabel String roleLabel for fetching related permissions
    *
    * @author rravindraundale@deloitte.com
    * @date 2023-05-05
    */
    
    /*@Future
    public static void assignPermissionsToUser(String userId, String roleLabel){
        PMC_DH_PersonaPermissionSetGroup__mdt[] lstPersonaPermissionSetGroup = PMC_DH_PersonaPermissionSetGroup__mdt.getAll().values();
        String strPermissionSetGroup = '';
        for(PMC_DH_PersonaPermissionSetGroup__mdt objPersonaPermissionSetGroup : lstPersonaPermissionSetGroup){
            if(objPersonaPermissionSetGroup.DeveloperName == roleLabel){
                strPermissionSetGroup = objPersonaPermissionSetGroup.strPermissionSetGroup__c;
                break;
            }
        }
        PermissionSetGroup permsGrp=[SELECT Id,Status FROM PermissionSetGroup WHERE DeveloperName =: strPermissionSetGroup];
        if(permsGrp.Status!=PMC_DH_ConstantClass.UPDATED)
        {
            Test.calculatePermissionSetGroup(permsGrp.Id);
        }
        PermissionSetAssignment assignment = new PermissionSetAssignment(  PermissionSetGroupId = permsGrp.id,AssigneeId = userId);
        insert as system assignment;
        
         System.enqueueJob(new PMC_DH_NotificatonQueueable(new List<String>{userId})); 
        //PMC_DH_NotificationPreferenceController.createNotificationPref(userId);
        
    }*/
    /**
* @description create Partner Contact from portal
* @author @siddharth.pradhan| 05-24-2023 
* @param userInfoData 
* @return Contact 
**/
    public static Contact createPartnerContact(PMC_DH_RegisterUserWrapper userInfoData)
    {
        Contact objContact = new Contact();
        User objUser=[Select ContactId, Country from user where id=:UserInfo.getUserId()  WITH SECURITY_ENFORCED ];
        objContact.PMC_DH_Language__c = 'English';
        if(userInfoData.strLanguage!=null && String.IsNotBlank(userInfoData.strLanguage)){
            objContact.PMC_DH_Language__c = userInfoData.strLanguage;
        }
        objContact.FirstName = userInfoData.strFirstName;
        objContact.LastName = userInfoData.strLastName;
        objContact.Email = userInfoData.strEmail;
        objContact.PMC_DH_CountryCode__c=userInfoData.strCountryCode;
        objContact.Phone = userInfoData.strPhoneNumber; //PMC_DH_DigitalHubB2BUtils.getFormattedPhone(userInfoData.strCountryCode,userInfoData.strPhoneNumber);
        objContact.MailingCountry = objUser.Country; // country element needs to be added to UI 
        objContact.MailingState = userInfoData.strState;
        
        objContact.MailingCity = userInfoData.strCity;
        objContact.PMC_SS_DigitalHubUser__c=true; 
        objContact.PMC_Source__c=PMC_DH_ConstantClass.PMC_DH_SOURCE_SUPERBUYER;
        objContact.AccountId = userInfoData.strAccountId;        
        objContact.PMC_DH_Approver__c = objUser.ContactId;
        objContact.PMC_SS_Status__c= PMC_DH_ConstantClass.ACTIVE_STATUS;
        If(Schema.sObjectType.Contact.isCreateable())
        {
        insert objContact;
        }
       // Below ACR creation code is commented as required for GPT-31150
        /*List<PMC_SS_AccountPartnerRelationships__c> lstShippingAccount = [SELECT Id, PMC_SS_Account__c,PMC_SS_RelatedAccount__c
                                                               FROM PMC_SS_AccountPartnerRelationships__c WHERE PMC_SS_Account__c=:userInfoData.strAccountId
                                                               AND  PMC_SS_Type__c=:PMC_DH_ConstantClass.ACCOUNT_TYPE AND PMC_SS_RelatedAccount__r.PMC_SS_MDMVerified__c = TRUE
                                                               WITH SECURITY_ENFORCED];
        List<PMC_SS_AccountPartnerRelationships__c> lstShippingAccountProcessed = PMC_DH_QuoteManagementHelper.removeDuplicateRelatedAccountsFromList(lstShippingAccount);
        List<AccountContactRelation> lstAccountContactRelation = new List<AccountContactRelation>();
        if(objContact.Id != null && Schema.sObjectType.AccountContactRelation.isCreateable() ){
            lstAccountContactRelation = PMC_DH_RegistrationController.getAccountContactRelations(lstShippingAccountProcessed,objContact);
            Database.insert(lstAccountContactRelation, false);
        }*/
        
        return objContact;
    }
    
    /**
    * @description get profile Id based on selected role by Super Buyer 
    * @author siddharth.pradhan@mosaicco.com | Digital Hub | 06-17-2023 
    * @param role 
    * @return Id 
    * @see createNewUser | creates user when super buyer assigns role
    **/
    private static Id getProfileIdForNewUser(String role)
    {
        String strProfileName = getProfileName(role);
        Map<String,Id> mapProfileToIDs=PMC_DH_CommonSystemUtils.getExternalProfileIds(role);
        return mapProfileToIDs.get(strProfileName);
    }
    /**
* @description class wrapper for user details
* @author @hemant| 05-25-2023 
* @param null 
* @return null
**/
    
    public with sharing class PMC_DH_RegisterUserWrapper{
          /**
         *@description strLastName
         *@return  String 
         */
        @AuraEnabled
        public String strLanguage{get;set;}

        /**\
         *@description  strFirstName
         * @return  String 
         */
        @AuraEnabled
        public String strFirstName {get;set;}

        /**
         *@description strLastName
         *@return  String 
         */
        @AuraEnabled
        public String strLastName {get;set;}

        /**
         *@description strEmail
         * @return  String 
         */
        
        @AuraEnabled
        public String strEmail {get;set;}

        /**
         *@description strCountryCode
         * @return  String 
         */
        @AuraEnabled
        public String strCountryCode {get;set;}

        /**
         *@description strPhoneNumber
         * @return  String 
         */
        @AuraEnabled
        public String strPhoneNumber {get;set;}

        /**
         *@description strCountry
         * @return  String 
         */
        @AuraEnabled
        public String strCountry {get;set;}

        /**
         *@description strState
         * @return  String 
         */
        @AuraEnabled
        public String strState {get;set;}

        /**
         *@description strCity
         * @return  String 
         */
        @AuraEnabled
        public String strCity{get;set;}

        /**
         *@description strAccountNumber
         * @return  String 
         */
        @AuraEnabled
        public String strAccountId{get;set;}

        /**
         *@description strUserType
         * @return  String 
         */
        @AuraEnabled
        public String strUserType{get;set;}
    }

/**
* @description class wrapper for dup check on registration
* @author @Ajeet| 06-01-2023 
* @param null 
* @return null
**/
    
public with sharing class PMC_DH_RegisterUtilWrapper{
    
    /**
     *@description strLastName
     *@return  String 
     */
    @AuraEnabled
    public String strLastName{get;set;}

    /**
     *@description strEmail
     * @return  String 
     */
    
     @AuraEnabled
     public String strEmail{get;set;}

     /**
     *@description strCountryCode
     * @return  String 
     */
    @AuraEnabled
    public String strCountryCode{get;set;}

    /**
     *@description strPhoneNumber
     * @return  String 
     */
    @AuraEnabled
    public String strPhoneNumber{get;set;}
}
}