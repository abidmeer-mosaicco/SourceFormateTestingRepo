/** 
* @description Controller for fetching and updating user detail 
* @author Ajeet
* @last modified on 05-15-2023
* @last modified by Ajeet
* Created On       :2023-June-02
**/
public without sharing class PMC_DH_UserInfoController {
    //GPT-40427- changed to without sharing as user is not deactivated as user's email is not received in deactivateUserAndDisablePartner method   
	// Hardcoded String Variable Decleration Start
	private static final String CLASS_CONST_VARIABLE1 = ' ';
	private static final String CLASS_CONST_VARIABLE2 = '000';
	private static final String CLASS_CONST_VARIABLE3 = '001';
	private static final String USERINFO = 'UserInfo';
	// Hardcoded String Variable Decleration ends
    public static final String TEST_EXCEPTION_MESSAGE = 'Test Error';
    public static final String MOSAIC_DIRECT = 'Mosaic Direct';
    public static boolean throwUsersTestException = false;
    
/**
* @description fetches user info
* @return String
* @author Ajeet
* @date 2023-05-15
*/
    @AuraEnabled(cacheable=true)
    public static String getUserInfo(){
        String strResult;
        PMC_DH_UserInfoWrapper userDetails=new PMC_DH_UserInfoWrapper();
        PMC_DH_DigitalHubB2BUtils.PhoneFormatWrapper phnFrmt;
        try {
            String strUserId=System.userInfo.getUserId();
           List<User> lstUser=PMC_DH_UserUtil.getUserData(strUserId);
            if(!lstUser.isEmpty())
            {
            	userDetails.strRecId=lstUser[0].Id;
                userDetails.strContactId=lstUser[0].ContactId;
                userDetails.strFirstName=lstUser[0].FirstName;
                userDetails.strLastName=lstUser[0].LastName;
                if(lstUser[0].Phone != null){
                    String phonenumber = lstUser[0].Phone;
                    List<String> lstPhnnumber = phonenumber.split(' ',2);
                    if(lstPhnnumber.size()>1){
                        userDetails.strPhone= lstPhnnumber[1];
                    }
                    userDetails.strContactPhone= userDetails.strPhone;
                }
                //userDetails.strPhone  = lstUser[0].Phone;
                userDetails.strEmail=lstUser[0].Email;
                userDetails.strCountry=lstUser[0].Country;
                userDetails.strCountryCode=lstUser[0].Contact.PMC_DH_CountryCode__c;
                userDetails.strContactLastName=lstUser[0].Contact.LastName;
                userDetails.strContactBirthdate=String.valueOf(lstUser[0].Contact.Birthdate);
                userDetails.strUsername=lstUser[0].Username;
            }
            phnFrmt=PMC_DH_DigitalHubB2BUtils.getCountryCodePhoneFormat();	
            userDetails.countryCodePhoneFormat=phnFrmt;
            userDetails.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, PMC_DH_ConstantClass.USER_INFO);
            strResult=json.serialize(userDetails);                
            
        } catch (Exception e) {
            PMC_ErrorLogClass.processException(e); // MDErrorLog
            userDetails.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
            strResult=json.serialize(userDetails); 
            //throw new AuraHandledException(e.getMessage());
          }
        return strResult;
    }
    /**
* @description update user detail
* 
* @param strLastName String strLastName
* @param strPhoneCode String strPhoneCode
* @param strPhoneNumber String strPhoneNumber
* 
* @return List<User>
*
* @author Ajeet
* @date 2023-05-15
*/
    @AuraEnabled
    public static String updateUserInfo(String strLastName,String strPhoneCode, String strPhoneNumber) {
        String strResult;
        List<User> lstUsers = new List<User>();
        List<Contact> lstcontact= new List<Contact>();
        PMC_DH_UserInfoWrapper userDetails=new PMC_DH_UserInfoWrapper();
        try{
            String strUserId=System.userInfo.getUserId();
            if (throwUsersTestException && Test.isRunningTest()) {
                throw new AuraHandledException(TEST_EXCEPTION_MESSAGE);
            }
             List<User> lstUser=PMC_DH_UserUtil.getUserData(strUserId); 
            if(!lstUser.isEmpty())
            {
                List<String> lstPhnCode=strPhoneCode.split(' ');
                string strPhn=lstPhnCode[1];
                String strPhone=strPhn+' '+strPhoneNumber;
                lstUser[0].LastName = strLastName;
                lstUser[0].Phone = strPhone;
                lstUser[0].Contact.PMC_DH_CountryCode__c = strPhoneCode;
                List<Contact> lstMatchingContact = PMC_DH_DigitalHubB2BUtils.getMatchingContacts(lstUser[0].Email, strLastName, strPhone);
                userDetails.statusCodeMessage = PMC_DH_UserUtil.validateUserInfo(lstUsers, lstUser[0], lstMatchingContact);
                if (lstUser[0].ContactId != null && lstMatchingContact.isEmpty())
                {   
                    Contact conObjRecord=new Contact( Id=lstUser[0].ContactId);
                    conObjRecord.LastName = strLastName;
                    //lstUser[0].Contact.Phone = strPhoneNumber;
                    conObjRecord.PMC_DH_CountryCode__c=strPhoneCode;
                    conObjRecord.Phone = strPhone;
                    lstcontact.add(conObjRecord);
                }
                userDetails.strRecId=lstUser[0].Id;
                userDetails.strContactId=lstUser[0].ContactId;
                userDetails.strFirstName=lstUser[0].FirstName;
                userDetails.strLastName=lstUser[0].LastName;
                userDetails.strPhone=strPhone;
                userDetails.strEmail=lstUser[0].Email;
                userDetails.strCountry=lstUser[0].Country;
                userDetails.strCountryCode=lstUser[0].Contact.PMC_DH_CountryCode__c;
                userDetails.strContactLastName=lstUser[0].Contact.LastName;
                userDetails.strContactPhone=strPhone;
                userDetails.strContactBirthdate=String.valueOf(lstUser[0].Contact.Birthdate);
                userDetails.strUsername=lstUser[0].Username;
             }
             PMC_DH_UserUtil.updateUserInfo(lstUsers,lstcontact);
             userDetails.strPhone = strPhoneNumber;
             userDetails.strContactPhone = strPhoneNumber;
            strResult=json.serialize(userDetails);
        }catch (Exception e) {
            PMC_ErrorLogClass.processException(e); // MDErrorLog
            userDetails.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
            strResult=json.serialize(userDetails); 
            //throw new AuraHandledException(e.getMessage());
        }
        return strResult;
    }

   
/**
* @description submit method for super buyer to create new users from portal
* @author @siddharth.pradhan| 05-24-2023 
* @param userInfoData 
* @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper 
**/
@AuraEnabled
public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper createNewUserWithoutApproval(PMC_DH_ContactUtils.PMC_DH_RegisterUserWrapper userInfoData){
    PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();              

    try {
        if (throwUsersTestException && Test.isRunningTest()) 
        {
        throw new AuraHandledException(TEST_EXCEPTION_MESSAGE);
            }
	
    String strPhone = PMC_DH_DigitalHubB2BUtils.getFormattedPhone(userInfoData.strCountryCode,userInfoData.strPhoneNumber);
    //PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();              
    List<Contact> lstContact = PMC_DH_DigitalHubB2BUtils.getMatchingContactsForUsrCreation(userInfoData.strEmail, userInfoData.strLastName, strPhone);
    
    if(lstContact.isEmpty())
    {
        userInfoData.strPhoneNumber = strPhone;
        Contact con=PMC_DH_ContactUtils.createPartnerContact(userInfoData);
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper boolIsUserCreated=PMC_DH_ContactUtils.createNewUser(con.Email,userInfoData.strUserType);
        if(boolIsUserCreated.strStatusCode == '000'){
            statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', USERINFO);   
        }
    }
    else 
    {
            statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('001', USERINFO);   
    }  
    } 
    catch (Exception e) {
    PMC_ErrorLogClass.processException(e); // MDErrorLog
    statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); 
    }
    return statusCodeMessage;
}
    
    /**
* @description : Apex wrapper  for picklist used in FrontEnd part
* @author      : hemant.goswami
* @created on  : 2023-05-19
**/
    public with sharing class PicklistWrapper{
        /**
         * @description : lstCountryCode
         * @return : List<String>
         */
        @AuraEnabled
        public String lstCountryCode{get;set;}

        /**
         * @description : lstUserType
         * @return : List<String>
         */
        @AuraEnabled
        public String lstUserType {get;set;}

        /**
         * @description : accWrp
         * @return : List<AccountWrapper>
         */
        @AuraEnabled
        public  String lstaccWrp {get; set;}

        /**
        * @description Status Code and message
        * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
        */
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    }


/**
* @description submit method for super buyer to create new users from portal
* @author @siddharth.pradhan| 05-24-2023 
* @param strcurrentUserId 
* @return String 
**/
    @AuraEnabled(cacheable=true)
    public static String getModalDetails(String strcurrentUserId){
        
      PicklistWrapper valueWrapper=new PicklistWrapper();
      try{
        PMC_DH_PicklistWrapper wrpCountryCode;
        List<PMC_DH_PicklistWrapper> lstCodeWrapper=new List<PMC_DH_PicklistWrapper>();
        List<PMC_DH_Phone_Number_Format__mdt> lstPhoneMetadata= PMC_DH_Phone_Number_Format__mdt.getAll().values();
        if(!lstPhoneMetadata.isEmpty() )
            {
                for(PMC_DH_Phone_Number_Format__mdt phoneFormat:lstPhoneMetadata)
                {
                    String strCountryCode=phoneFormat.PMC_DH_Country__c+' '+phoneFormat.PMC_DH_Country_Code__c;
                    wrpCountryCode=new PMC_DH_PicklistWrapper();
                    wrpCountryCode.label=strCountryCode;
                    wrpCountryCode.value=strCountryCode;
                    lstCodeWrapper.add(wrpCountryCode);

                }
            }
            String strWrapperCountCode= JSON.serialize(lstCodeWrapper);
            valueWrapper.lstCountryCode=strWrapperCountCode;
            PMC_DH_PicklistWrapper wrpUser;
            List<PMC_DH_PicklistWrapper> lstUserWrapper=new List<PMC_DH_PicklistWrapper>();

            List<PMC_DH_PersonaPermissionSetGroup__mdt> lstPersonaPermissionSetGroup= PMC_DH_PersonaPermissionSetGroup__mdt.getAll().values();
            List<PMC_DH_PersonaPermissionSetGroup__mdt> sortedData=PMC_DH_RegistrationUtils.sortByDisplayOrder(lstPersonaPermissionSetGroup);         // if(!lstPersona.isEmpty())
            
                for(PMC_DH_PersonaPermissionSetGroup__mdt persona:sortedData)
                { if(persona.Label!='Super Buyer')
                    {

                    wrpUser=new PMC_DH_PicklistWrapper();
                    wrpUser.label=persona.MasterLabel;
                    wrpUser.value=persona.DeveloperName;
                    
                    lstUserWrapper.add(wrpUser );
            }

                }
            
            String strWrapperUserType= JSON.serialize(lstUserWrapper);
            valueWrapper.lstUserType=strWrapperUserType;

            PMC_DH_PicklistWrapper wrpAccount;
            List<PMC_DH_PicklistWrapper> lstAccountWrapper=new List<PMC_DH_PicklistWrapper>();
            
          
        //String strComm=[SELECT Id,Name FROM Network WITH SECURITY_ENFORCED LIMIT 1].Id;
        String strComm=[SELECT Id,Name FROM Network WHERE Name = :MOSAIC_DIRECT WITH SECURITY_ENFORCED LIMIT 1].Id;
        String strWebStoreId = PMC_DH_DigitalHubB2BUtils.getWebStoreId(strComm);
        List<ConnectApi.ExternalManagedAccountOutput> lstExternalManagedAccounts=new List<ConnectApi.ExternalManagedAccountOutput>();
        
        if(!Test.isRunningTest())
        {
        ConnectApi.ExternalManagedAccountCollectionOutput conManagedAccounts = ConnectApi.ExternalManagedAccount.getExternalManagedAccounts(strWebStoreId,true);   
          lstExternalManagedAccounts= conManagedAccounts.externalManagedAccounts;
        }
        
        else
        {
			lstExternalManagedAccounts=new List<ConnectApi.ExternalManagedAccountOutput>();
          ConnectApi.ExternalManagedAccountOutput conAccParent=new  ConnectApi.ExternalManagedAccountOutput();
          conAccParent.accountId=[Select ID,NAME from Account where name='TestAccount' WITH SECURITY_ENFORCED LIMIT 1].Id;
          lstExternalManagedAccounts.add(conAccParent);
          ConnectApi.ExternalManagedAccountOutput conAccChild=new  ConnectApi.ExternalManagedAccountOutput();
          conAccChild.accountId=[Select ID,NAME from Account where name='Parent Test Account' WITH SYSTEM_MODE LIMIT 1].Id;
			
          lstExternalManagedAccounts.add(conAccChild);            
        }
            Set<Id> setBuyerAccs=new Set<Id>();
            for(ConnectApi.ExternalManagedAccountOutput conAccounts:lstExternalManagedAccounts)
            {   setBuyerAccs.add(conAccounts.accountId);  
            }  
            if(Schema.sObjectType.Account.isAccessible())
            {
            List<Account> lstAccount=[Select Id,Name from Account where Id IN:setBuyerAccs WITH SECURITY_ENFORCED ];
            for (Account acc : lstAccount) {

                wrpAccount=new PMC_DH_PicklistWrapper();
                wrpAccount.label=acc.Name;
                wrpAccount.value=acc.Id;
                lstAccountWrapper.add(wrpAccount);

            }   
        }   
          
            String strWrapperSoldTo= JSON.serialize(lstAccountWrapper);
            valueWrapper.lstaccWrp=strWrapperSoldTo;
            valueWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'UserModalDetails');
    }catch(Exception e){
        PMC_ErrorLogClass.processException(e); // MDErrorLog
        valueWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); 
    }

    return json.serialize(valueWrapper);
}

/**
* @description deactivate user
* @param userId
* @return User
* @author Ajeet
* @date 2023-05-31
*/ 
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper deactivateUserAndDisablePartner(String userId){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        User usrData;
        try{
            //PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            if(Schema.sObjectType.User.isAccessible()){
            usrData = [SELECT Id, IsActive, IsPortalEnabled, Email, Username, ContactId, FederationIdentifier, Contact.LastName, Contact.Email, Contact.PMC_SS_Status__c FROM User WHERE Id = :userId AND Contact.PMC_SS_Status__c = 'Active' LIMIT 1];
            }
            String randomNumberEmail=String.valueOf(Math.random() * 100)+'.inactive';
            if(!String.isBlank(usrData.ContactId)){
                //deactivateUserAccess(usrData.Id,usrData.Email,usrData.Username);
                Contact c=new Contact();
                c.Id=usrData.ContactId;
                c.PMC_SS_Status__c = 'Inactive';
                c.Email=usrData.Contact.Email+randomNumberEmail;
                if (Schema.sObjectType.Contact.isUpdateable()) {
                update c;
                }
                deactivateUserAccess(usrData.Id,usrData.Email,usrData.Username);
                statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'UserInfo');
            }
        }catch(Exception e) {
            PMC_ErrorLogClass.processException(e); // MDErrorLog
            statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); 
            //throw new AuraHandledException(e.getMessage());
        }  
        return statusCodeMessage;     
    }
    
     /**
* @description fetches user info
* @author Ajeet
* @param userId
* @param email
* @param username
* @date 2023-05-15
*/
    
    @future
    private static void deactivateUserAccess(String userId,String email,String username) {
        String randomNumberEmail=String.valueOf(Math.random() * 100)+'.inactive';
        User usrData=new User();
        usrData.Id=userId;
        usrData.Email = email+ randomNumberEmail;
        usrData.Username = username + randomNumberEmail;
        usrData.IsActive = false;
        //usrData.IsPortalEnabled = false;
        update as system usrData;
        List<PermissionSetAssignment> lstRemovePermission = [SELECT Id, PermissionSetGroup.Id from PermissionSetAssignment Where AssigneeId = :userId AND PermissionSet.IsOwnedByProfile = false AND PermissionSet.IsCustom = true WITH SYSTEM_MODE];
        if(!lstRemovePermission.isEmpty()){
            delete lstRemovePermission;
        }
        
        
    }
}