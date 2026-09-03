/**
 * 
 * Class Name      :PMC_DH_UserDetailController
 * @description      :Controller for fetching user deatil 
 * @author       :Krishan
 * @last modified by Nikhilesh
 * @last modified on 05-12-2023
 * Created On       :2023-04-24 
**/
public without  sharing class PMC_DH_UserDetailController {
    public final static String ACTIVE_STATUS = 'Active';
    public final static String OPT_IN = 'OptIn';
    public final static String OPT_OUT = 'OptOut';
    public final static String MARKETING_COMM = 'Marketing Communications';
    public final static String MARKETING_CONT = 'Opt out of Marketing Content';
    public final static String ACKNOWLEDGEMENT_PREFERENCE = 'Acknowledgement';
    
    /**
    * @description fetches user detail
    * 
    * @param effAccId String effAccId
    * 
    * @return PMC_DH_UserDetailWrapper
    *
    * @author Krishan
    * @date 2023-04-24
    **/
    @AuraEnabled
    public static PMC_DH_UserDetailWrapper getUserDetail(String effAccId){
        
        List<PMC_DH_UserDetailWrapper.UserDetailsData> userDataList = new List<PMC_DH_UserDetailWrapper.UserDetailsData>();
        PMC_DH_UserDetailWrapper userDetailWrapper = new PMC_DH_UserDetailWrapper();
        Set<Id> contactIds = new Set<Id>();
        Map<String,User> mapOfContactandUser = new Map<String,User>();
        try{
            if(effAccId!=null){
                //no SECURITY ENFORCED
                
                for(AccountContactRelation objACR : [select ContactId, id from AccountContactRelation where AccountId =:effAccId WITH SECURITY_ENFORCED]){
                    contactIds.add(objACR.ContactId);
                }
                //no SECURITY ENFORCED
                List<User> lstUser=[Select Id, Name, ContactId,Profile.Name, Contact.Email ,Contact.mailingCountry, Contact.Phone, Contact.PMC_DH_CountryCode__c 
                                FROM User where contactId in:contactIds and IsActive=true and id!=:userInfo.getUserId() WITH SYSTEM_MODE ];            
                for(User objUser : lstUser){
                    mapOfContactandUser.put(objUser.ContactId,objUser);
                                    }
                //no SECURITY ENFORCED
                for(AccountContactRelation objACR : [select id,ContactId,Contact.Name,Contact.Email,Contact.Title,Contact.mailingCountry,Contact.Phone, Contact.PMC_DH_CountryCode__c from AccountContactRelation where AccountId =:effAccId AND Contact.PMC_SS_Status__c =:ACTIVE_STATUS WITH SECURITY_ENFORCED])
                {
                    if(mapOfContactandUser.containsKey(objACR.ContactId)){
                        PMC_DH_UserDetailWrapper.UserDetailsData  userDetail = new PMC_DH_UserDetailWrapper.UserDetailsData();
                        userDetail.strRecId = mapOfContactandUser.get(objACR.ContactId).Id;
                        userDetail.struserName = mapOfContactandUser.get(objACR.ContactId).Name;
                        String profileName=(mapOfContactandUser.get(objACR.ContactId).Profile.name).replace(' ','_');
                        userDetail.strUserType = PMC_DH_PersonaPermissionSetGroup__mdt.getInstance(profileName).Label;
                        userDetail.strUserEmail = mapOfContactandUser.get(objACR.ContactId).Contact.Email;
                        userDetail.strPhone = getContactPhone(mapOfContactandUser,objACR);
                        //getUnformattedPhoneNumber(mapOfContactandUser.get(objACR.ContactId).Contact.Phone);
                        userDetail.strLocal = mapOfContactandUser.get(objACR.ContactId).Contact.mailingCountry;
                        userDetail.strStatus = System.label.PMC_DH_UserStatusActive;//PMC_DH_ConstantClass.USER_STATUS_ACTIVE;
                        userDetail.strCountryCode = mapOfContactandUser.get(objACR.ContactId).Contact.PMC_DH_CountryCode__c;
                        //userDetail.strCountryCode = PMC_DH_DigitalHubB2BUtils.getFormattedCountryCode(countryCode);
                        userDataList.add(userDetail);
                     }
                }
                
            }
            userDetailWrapper.userList = userDataList;
            userDetailWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'UserDataOperations');
            //return userDetailWrapper;
        }
        catch(Exception ex){
            userDetailWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
            //throw new AuraHandledException(ex.getMessage());
        }
        return userDetailWrapper;
    }  
    
    private static String getContactPhone(Map<String,User> mapOfContactandUser, AccountContactRelation objACR){
        String strPhone = '';
        if(objACR.Contact.Phone != null){
            strPhone = getUnformattedPhoneNumber(mapOfContactandUser.get(objACR.ContactId).Contact.Phone);
        }
        return strPhone;
    }  

    private static String getUnformattedPhoneNumber(String strFormatterPhone){
        String strUnformattedPhoneNumber = '';
        List<String> lstPhnnumber = strFormatterPhone.split(' ',2);
        if(lstPhnnumber.size()>1){
            strUnformattedPhoneNumber = lstPhnnumber[1];
        }
        return strUnformattedPhoneNumber;
    }

    /**
    * @description fetches user notification preferences detail
    * @return PMC_DH_UserNotificationPreferenceWrapper
    * @author Rohan Undale
    * @date 2023-08-24
    **/
    @AuraEnabled
    public static PMC_DH_UserNotificationPreferenceWrapper getUserNotificationPreferences(){
        PMC_DH_UserNotificationPreferenceWrapper objUserNotificationPreference = new PMC_DH_UserNotificationPreferenceWrapper();
        try{
            User objUser = [SELECT Id, ContactId, Contact.IndividualId, Contact.HasOptedOutOfEmail, Contact.PMC_SS_SMSOptOut__c, Contact.PMC_SS_WhatsappOptOut__c 
                            FROM USER 
                            WHERE Id =:UserInfo.getUserId() 
                            WITH USER_MODE 
                            LIMIT 1];
            List<ContactPointTypeConsent> lstContactPointTypeConsent = [SELECT Id, PartyId, DataUsePurpose.Id,DataUsePurpose.Name,DataUsePurpose.LegalBasis.Name, DataUsePurpose.LegalBasis.PMC_DH_Sequence__c, PrivacyConsentStatus,
                                                                        DataUsePurpose.PMC_DH_Sequence__c, ContactPointType, DataUsePurpose.PMC_DH_NotificationDisable__c, DataUsePurpose.PMC_DH_NotificationVisible__c
                                                                        FROM ContactPointTypeConsent
                                                                        WHERE PartyId =: objUser.Contact.IndividualId AND DataUsePurpose.Name!=: ACKNOWLEDGEMENT_PREFERENCE
                                                                        WITH SYSTEM_MODE
                                                                        ORDER BY DataUsePurpose.LegalBasis.PMC_DH_Sequence__c ASC];
            Map<String,List<ContactPointTypeConsent>> mapNotificationContactPointTypeConsent = new Map<String,List<ContactPointTypeConsent>>();
            for(ContactPointTypeConsent objContactPointTypeConsent : lstContactPointTypeConsent){
                if(!mapNotificationContactPointTypeConsent.containsKey(objContactPointTypeConsent.DataUsePurpose.LegalBasis.Name)){
                    mapNotificationContactPointTypeConsent.put(objContactPointTypeConsent.DataUsePurpose.LegalBasis.Name, new List<ContactPointTypeConsent>());
                }
                mapNotificationContactPointTypeConsent.get(objContactPointTypeConsent.DataUsePurpose.LegalBasis.Name).add(objContactPointTypeConsent);
            }
            List<PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ParentNotificationWrapper> lstAllUserNofications = new List<PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ParentNotificationWrapper>();
            Set<string> setNotificationNames = mapNotificationContactPointTypeConsent.keyset();
            for(String strNotificationName : setNotificationNames){
                List<ContactPointTypeConsent> lstContactPointTypeConsentForNames = mapNotificationContactPointTypeConsent.get(strNotificationName);
                PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ParentNotificationWrapper objParentNotificationWrapper = new PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ParentNotificationWrapper();
                objParentNotificationWrapper.strParentNotificationId = lstContactPointTypeConsentForNames[0].DataUsePurpose.Id;
                String strTemp1 = String.valueOf(lstContactPointTypeConsentForNames[0].DataUsePurpose.LegalBasis.Name).replace(' ','').replace('/','');
                objParentNotificationWrapper.strParentNotificationName = System.label.get(null,PMC_DH_ConstantClass.LABEL_HEADER+strTemp1,userinfo.getLocale());
                //objParentNotificationWrapper.strParentNotificationName = lstContactPointTypeConsentForNames[0].DataUsePurpose.LegalBasis.Name;
                objParentNotificationWrapper.intSequence =  Integer.valueOf(lstContactPointTypeConsentForNames[0].DataUsePurpose.LegalBasis.PMC_DH_Sequence__c);

                Map<String,List<ContactPointTypeConsent>> mapChildNotificationContactPointTypeConsent = new Map<String,List<ContactPointTypeConsent>>();
                for(ContactPointTypeConsent objContactPointTypeConsent : lstContactPointTypeConsentForNames){
                    if(!mapChildNotificationContactPointTypeConsent.containsKey(objContactPointTypeConsent.DataUsePurpose.Name)){
                        mapChildNotificationContactPointTypeConsent.put(objContactPointTypeConsent.DataUsePurpose.Name, new List<ContactPointTypeConsent>());
                    }
                    mapChildNotificationContactPointTypeConsent.get(objContactPointTypeConsent.DataUsePurpose.Name).add(objContactPointTypeConsent);
                }

                Set<string> setChildNotificationNames = mapChildNotificationContactPointTypeConsent.keyset();
                List<PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChildNotificationWrapper> lstChildNotifications = new List<PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChildNotificationWrapper>();
                for(String strChildNotificationName : setChildNotificationNames){
                    List<ContactPointTypeConsent> lstChannelType = mapChildNotificationContactPointTypeConsent.get(strChildNotificationName);
                    PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChildNotificationWrapper objChildNotificationWrapper = getChildNotificationWrapper(lstChannelType);
                    lstChildNotifications.add(objChildNotificationWrapper);
                }
                objParentNotificationWrapper.lstChildNotifications = lstChildNotifications;
                lstAllUserNofications.add(objParentNotificationWrapper);
            }
            PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ParentNotificationWrapper objParentForCommunication = getMarketingCommunicationPreferences(objUser);
            lstAllUserNofications.add(objParentForCommunication);
            objUserNotificationPreference.lstAllUserNofications = lstAllUserNofications;
            objUserNotificationPreference.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'UserDataOperations'); 
            //return objUserNotificationPreference;
        }
        catch(Exception ex){
            objUserNotificationPreference.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
            //throw new AuraHandledException(ex.getMessage()+ex.getStackTraceString());
        }
        return objUserNotificationPreference;
    }

    private static PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChildNotificationWrapper getChildNotificationWrapper(List<ContactPointTypeConsent> lstChannelType){
        PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChildNotificationWrapper objChildNotificationWrapper = new PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChildNotificationWrapper();
        String strTemp = String.valueOf(lstChannelType[0].DataUsePurpose.Name).replace(' ','').replace('/','');
                objChildNotificationWrapper.strNotificationName = System.label.get(null,PMC_DH_ConstantClass.LABEL_HEADER+strTemp,userinfo.getLocale());
        objChildNotificationWrapper.intSequence = Integer.valueOf(lstChannelType[0].DataUsePurpose.PMC_DH_Sequence__c);

        List<PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper> lstChannelTypeWrap = new List<PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper>();
        for(ContactPointTypeConsent objChannelType : lstChannelType){
            PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper objChannelTypeWrap = new PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper();
            objChannelTypeWrap.strNotificationId = objChannelType.Id;
            objChannelTypeWrap.strNotificationChannelType = objChannelType.ContactPointType;
            objChannelTypeWrap.boolSelectedValue = false;
            if(objChannelType.PrivacyConsentStatus == OPT_IN){
                objChannelTypeWrap.boolSelectedValue = true;
            }
            objChannelTypeWrap.boolDisabledNotification = objChannelType.DataUsePurpose.PMC_DH_NotificationDisable__c;
            objChannelTypeWrap.boolIsNotificationVisible = objChannelType.DataUsePurpose.PMC_DH_NotificationVisible__c;
            lstChannelTypeWrap.add(objChannelTypeWrap);
        }
        objChildNotificationWrapper.lstChannelTypes = lstChannelTypeWrap;

        return objChildNotificationWrapper;
    }

    private static PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ParentNotificationWrapper getMarketingCommunicationPreferences(User usr){
        PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ParentNotificationWrapper objParentNotificationWrapper = new PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ParentNotificationWrapper();
        objParentNotificationWrapper.strParentNotificationId = usr.ContactId;
        objParentNotificationWrapper.strParentNotificationName = System.label.PMC_DH_MarketingCommunications;//MARKETING_COMM;
        //objParentNotificationWrapper.intSequence =  Integer.valueOf(lstContactPointTypeConsentForNames[0].DataUsePurpose.LegalBasis.PMC_DH_Sequence__c);
        
		List<PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChildNotificationWrapper> lstChildNotifications = new List<PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChildNotificationWrapper>();
        PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChildNotificationWrapper objChildNotificationWrapper = new PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChildNotificationWrapper();
        objChildNotificationWrapper.strNotificationName = System.Label.PMC_DH_OptOutOfMarketingContent;//MARKETING_CONT;
        
        List<PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper> lstChannelTypeWrap = new List<PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper>();
        PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper objChannelTypeWrapWhatsapp = new PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper();
        objChannelTypeWrapWhatsapp.strNotificationId = usr.ContactId;
        objChannelTypeWrapWhatsapp.strNotificationChannelType = PMC_DH_ConstantClass.USER_NOTIFICATION_PREFERENCE_WHATSAPP;
        objChannelTypeWrapWhatsapp.boolSelectedValue = usr.Contact.PMC_SS_WhatsappOptOut__c;
        objChannelTypeWrapWhatsapp.boolDisabledNotification = False;
        objChannelTypeWrapWhatsapp.boolIsNotificationVisible = True;
        lstChannelTypeWrap.add(objChannelTypeWrapWhatsapp);
        
        PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper objChannelTypeWrapText = new PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper();
        objChannelTypeWrapText.strNotificationId = usr.ContactId;
        objChannelTypeWrapText.strNotificationChannelType = PMC_DH_ConstantClass.USER_NOTIFICATION_PREFERENCE_TEXT;
        objChannelTypeWrapText.boolSelectedValue = usr.Contact.PMC_SS_SMSOptOut__c;
        objChannelTypeWrapText.boolDisabledNotification = False;
        objChannelTypeWrapText.boolIsNotificationVisible = True;
        lstChannelTypeWrap.add(objChannelTypeWrapText);
        
        PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper objChannelTypeWrapEmail = new PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper();
        objChannelTypeWrapEmail.strNotificationId = usr.ContactId;
        objChannelTypeWrapEmail.strNotificationChannelType = PMC_DH_ConstantClass.USER_NOTIFICATION_PREFERENCE_EMAIL;
        objChannelTypeWrapEmail.boolSelectedValue = usr.Contact.HasOptedOutOfEmail;
        objChannelTypeWrapEmail.boolDisabledNotification = False;
        objChannelTypeWrapEmail.boolIsNotificationVisible = True;
        lstChannelTypeWrap.add(objChannelTypeWrapEmail);
        
        objChildNotificationWrapper.lstChannelTypes = lstChannelTypeWrap;
        lstChildNotifications.add(objChildNotificationWrapper);
        objParentNotificationWrapper.lstChildNotifications = lstChildNotifications;
        return objParentNotificationWrapper;
    }
    /**
    * @description update user notification preferences detail
    * @param objChannelTypeWrap
    * @param isMarketingComm
    * @param strNotificationChannelType
    * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    * @author Rohan Undale
    * @date 2023-08-24
    **/
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper updateUserNotificationPreferences(PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper objChannelTypeWrap, Boolean isMarketingComm, String strNotificationChannelType){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        try{
            if(isMarketingComm){
                Contact con = [SELECT Id, HasOptedOutOfEmail, PMC_SS_SMSOptOut__c, PMC_SS_WhatsappOptOut__c FROM Contact
                                WHERE Id In (SELECT ContactId FROM USER WHERE Id =: UserInfo.getUserId()) WITH USER_MODE];

                if(strNotificationChannelType == PMC_DH_ConstantClass.USER_NOTIFICATION_PREFERENCE_TEXT){
                    con.PMC_SS_SMSOptOut__c = objChannelTypeWrap.boolSelectedValue;
                }else if(strNotificationChannelType == PMC_DH_ConstantClass.USER_NOTIFICATION_PREFERENCE_EMAIL){
                    con.HasOptedOutOfEmail = objChannelTypeWrap.boolSelectedValue;
                }else if(strNotificationChannelType == PMC_DH_ConstantClass.USER_NOTIFICATION_PREFERENCE_WHATSAPP){
                    con.PMC_SS_WhatsappOptOut__c = objChannelTypeWrap.boolSelectedValue;
                }
                if(Schema.sObjectType.Contact.isUpdateable()){
                    update con; 
                }
            }else{
                ContactPointTypeConsent objChannelType = [SELECT Id, PrivacyConsentStatus FROM ContactPointTypeConsent
                                                            WHERE Id =: objChannelTypeWrap.strNotificationId WITH SYSTEM_MODE 
                                                            LIMIT 1];
                objChannelType.PrivacyConsentStatus = getOptInOptOutValue(objChannelTypeWrap.boolSelectedValue);
                if(Schema.sObjectType.ContactPointTypeConsent.isUpdateable()){
                    update objChannelType;
                }
            }
            statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'UserInfo');
        }
        catch(Exception e){
            statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); 
            return statusCodeMessage;
        }
        return statusCodeMessage;
    }

    private static String getOptInOptOutValue(Boolean boolSelectedValue){
        String strOptInOptOutValue;
        if(boolSelectedValue){
            strOptInOptOutValue = OPT_IN;
        }else{
            strOptInOptOutValue = OPT_OUT;
        }
        return strOptInOptOutValue;
    }
}