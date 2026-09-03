/**
 * @description       : 
 * @author            : @siddharth.pradhan
 * @group             : 
 * @last modified on  : 02-01-2024
 * @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
public without sharing class PMC_DH_RegistrationUtils {
    private static final String TEST_EXCEPTION_MESSAGE = 'Test Error thrown from PMC_DH_RegistrationUtil';
    @testVisible
    private static boolean throwTestException = false;

    
    /**
    * @description throw aura handled exception for test class
    * @author rravindraundale@deloitte.com
    * @date 2023-04-24
    */
    public static void throwTestExceptionForTest(){
        if (throwTestException && Test.isRunningTest()) {
            throw new AuraHandledException(TEST_EXCEPTION_MESSAGE);
        }
    }

    /**
    * @description varify if Email Id is already used in Contact
    * @param userinfo
    * @return  PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper with containing Status Code, Status Message and Module
    * @author rravindraundale@deloitte.com
    * @modified by Ajeet
    * @date 2023-04-24
    */
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper isContactEmailPresent(PMC_DH_ContactUtils.PMC_DH_RegisterUtilWrapper userinfo){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        try{
            throwTestExceptionForTest();
            String strPhn = PMC_DH_DigitalHubB2BUtils.getFormattedPhone(userinfo.strCountryCode,userinfo.strPhoneNumber);
            List<Contact> lstContact = PMC_DH_DigitalHubB2BUtils.getMatchingContacts(userinfo.strEmail, userinfo.strLastName, strPhn);

            if(lstContact.isEmpty()){
                result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'Registration');
            }else{
                result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('001', 'Registration');
            }
        }
        catch(Exception ex){
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'Registration');
            //throw new AuraHandledException(ex.getMessage());
        }
        return result;
    }

    /**
    * @description varify if account details are valid
    * 
    * @param accNumber String accNumber for check in Account
    * @param managerEmailId String managerEmailId for check with User associated with Account
    * 
    * @return  True if account info is valid
    *
    * @author rravindraundale@deloitte.com
    * @date 2023-04-24
    */
    @AuraEnabled
    public static Boolean isAccountInfoValid(String accNumber, String managerEmailId){
        try{
        Boolean isAccountInfoLalid = false;
            throwTestExceptionForTest();
        List<Account> lstAccount = [SELECT Id, AccountNumber 
                            FROM Account 
                            WHERE AccountNumber = :accNumber AND Owner.Email=:managerEmailId
                            WITH SYSTEM_MODE LIMIT 1];
        if(!lstAccount.isEmpty()){
            isAccountInfoLalid = true;
        }
        return isAccountInfoLalid;
    }
    catch(Exception ex){
        throw new AuraHandledException(ex.getMessage());
    }
    }

    /**
    * @description get information used for registration form
    * 
    * @return details required for user registration (Preferences option and Country States mapping)
    *
    * @author rravindraundale@deloitte.com
    * @date 2023-04-25
    */
    @AuraEnabled(cacheable=true)
    public static string getUserRegistationDetails(){
        PMC_DH_RegistrationUtilWrappers.PMC_DH_UserRegistationDetails userRegistationDetail = new PMC_DH_RegistrationUtilWrappers.PMC_DH_UserRegistationDetails();
        try{
            throwTestExceptionForTest();
        PMC_Country__mdt[] pmcContryRecords = PMC_Country__mdt.getAll().values();
        userRegistationDetail.lstCountryState = pmcContryRecords;
		PMC_DH_DigitalHubB2BUtils.PhoneFormatWrapper phnFrmt=PMC_DH_DigitalHubB2BUtils.getCountryCodePhoneFormat();	
         userRegistationDetail.countryCodePhoneFormat=phnFrmt;
            
        List<PMC_DH_PicklistWrapper> preferenceValuesList= new List<PMC_DH_PicklistWrapper>();
		Schema.DescribeFieldResult fieldResult = Contact.PMC_DH_Preferences__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
            PMC_DH_PicklistWrapper instWrp=new PMC_DH_PicklistWrapper();
            instWrp.label=pickListVal.getLabel();
            instWrp.value=pickListVal.getValue();
			//preferenceValuesList.add(pickListVal.getLabel());
            preferenceValuesList.add(instWrp);
		}  
        userRegistationDetail.lstPreferenceValuesList = preferenceValuesList;
        userRegistationDetail.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'Registration');
    }
    catch(Exception ex){
        userRegistationDetail.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
        //throw new AuraHandledException(ex.getMessage());
    }
    return JSON.serialize(userRegistationDetail);
}

    /**
    * @description varify access for user creation and provide necessary information
    * 
    * @param emailId String emailId for check in Contact
    * 
    * @return  Stringify JSON with required information
    *
    * @author rravindraundale@deloitte.com
    * @date 2023-05-03
    */
    @AuraEnabled
    public static String verifyAccessForUserCreation(String emailId){
        PMC_DH_RegistrationUtilWrappers.PMC_DH_VerifyAccessForUserCreationWrapper objVerifyAccessForUserCreationWrapper = new PMC_DH_RegistrationUtilWrappers.PMC_DH_VerifyAccessForUserCreationWrapper();
        try{
            throwTestExceptionForTest();
            String strEmailId = emailId.toLowerCase();
            List<User> lstUser = [SELECT Id, Email FROM User WHERE Email =: strEmailId WITH SYSTEM_MODE];
            if(!lstUser.isEmpty()){
                objVerifyAccessForUserCreationWrapper.boolIsUserExisting = True;
                objVerifyAccessForUserCreationWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'UserCreationAccess');
                return JSON.serialize(objVerifyAccessForUserCreationWrapper);
            }
            
            List<Profile> lstProfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() WITH SYSTEM_MODE LIMIT 1];
            if(lstProfile[0].Name != PMC_DH_ConstantClass.USER_PROFILE_DH_SUPER_BUYER){
                objVerifyAccessForUserCreationWrapper.boolIsSuperBuyerAuthorized = false;
                objVerifyAccessForUserCreationWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'UserCreationAccess');
                return JSON.serialize(objVerifyAccessForUserCreationWrapper);
            }
            
            List<Contact> lstContact = [SELECT Id, FirstName, LastName, Phone, Email, AccountId FROM Contact WHERE Email = :strEmailId WITH SYSTEM_MODE LIMIT 1];
            List<AccountContactRelation> lstAccountContactRelation = [Select Id from AccountContactRelation where AccountId =:lstContact[0].AccountId AND  ContactId IN (Select Id FROM Contact WHERE Email = :userinfo.getUserEmail()) WITH SYSTEM_MODE];
            if(lstAccountContactRelation.isEmpty()){
                objVerifyAccessForUserCreationWrapper.boolIsSuperBuyerAuthorized = false;
                objVerifyAccessForUserCreationWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'UserCreationAccess');
                return JSON.serialize(objVerifyAccessForUserCreationWrapper);
            }

            PMC_DH_PersonaPermissionSetGroup__mdt[] lstPersonaPermissionSetGroup = PMC_DH_PersonaPermissionSetGroup__mdt.getAll().values();
            List<PMC_DH_PersonaPermissionSetGroup__mdt> sortedData=sortByDisplayOrder(lstPersonaPermissionSetGroup);
            List<PMC_DH_PicklistWrapper> lstPicklistWrapper = new List<PMC_DH_PicklistWrapper>();
            for(PMC_DH_PersonaPermissionSetGroup__mdt objPersonaPermissionSetGroup : sortedData){ 
                if(objPersonaPermissionSetGroup.DeveloperName != 'Digital_Hub_Super_Buyer'){
                    PMC_DH_PicklistWrapper objPicklistWrapper = new PMC_DH_PicklistWrapper();
                    objPicklistWrapper.label = objPersonaPermissionSetGroup.MasterLabel; 
                    objPicklistWrapper.value = objPersonaPermissionSetGroup.DeveloperName;
                    lstPicklistWrapper.add(objPicklistWrapper);
                }
            }
            objVerifyAccessForUserCreationWrapper.lstUserType = lstPicklistWrapper;
            objVerifyAccessForUserCreationWrapper.strFirstName = lstContact[0].FirstName;
            objVerifyAccessForUserCreationWrapper.strLastName = lstContact[0].LastName;
            objVerifyAccessForUserCreationWrapper.strPhoneNumber = lstContact[0].Phone;
            objVerifyAccessForUserCreationWrapper.strEmail = lstContact[0].Email;
            objVerifyAccessForUserCreationWrapper.boolIsUserExisting = False;
            objVerifyAccessForUserCreationWrapper.boolIsSuperBuyerAuthorized = True;
            objVerifyAccessForUserCreationWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'UserCreationAccess');
        }
        catch(Exception ex){
            objVerifyAccessForUserCreationWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); 
            //throw new AuraHandledException(ex.getMessage());
        }
        return JSON.serialize(objVerifyAccessForUserCreationWrapper);
    }

    /**
    * @description sort By Display Order
    * 
    * @param metadataList list of metadata records
    * 
    * @return  List<PMC_DH_PersonaPermissionSetGroup__mdt> sorted list
    */
    public static List<PMC_DH_PersonaPermissionSetGroup__mdt> sortByDisplayOrder(List<PMC_DH_PersonaPermissionSetGroup__mdt> metadataList)
    {
        for (Integer i = 0; i < metadataList.size() - 1; i++) {
            for (Integer j = 0; j < metadataList.size() - i - 1; j++) {
                
                if (metadataList[j].intDisplayOrder__c  > metadataList[j + 1].intDisplayOrder__c ) {
                   
                    PMC_DH_PersonaPermissionSetGroup__mdt temp = metadataList[j];
                    metadataList[j] = metadataList[j + 1];
                    metadataList[j + 1] = temp;
                }
            }
        }
        return metadataList;
    }
}