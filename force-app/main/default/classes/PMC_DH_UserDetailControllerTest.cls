/**
* @description : Test class for PMC_DH_UserDetailController
* @author      : Krishan Jangir
* @userStory   : GDPH-1091
**/
@IsTest
public with sharing class PMC_DH_UserDetailControllerTest {
    /**
    * @description 
    * @author @krishan | 05-19-2023 
    **/
    @testsetup static void testSetup(){
       Account acc=PMC_DH_TestDataFactoryClass.createTestAccount();
        Contact con = PMC_DH_TestDataFactoryClass.createTestContact(acc.id);
        con.phone = '+55 9138842875';
        update con;
        
		Profile profile = [SELECT Id FROM Profile WHERE Name =:PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
        User user=[SELECT id, Contact.IndividualId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet2);
        Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet);
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet1);
        Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet3);
    }
    
    /**
    * @description 
    * @author @krishan | 05-19-2023 
    **/
    @isTest
    public static void getUserDetailsTest1(){
        test.startTest();
        	Account portalAccount2 = [SELECT Id, name FROM Account WHERE Name =: 'Test Account'];
            PMC_DH_UserDetailWrapper data=PMC_DH_UserDetailController.getUserDetail(portalAccount2.id);
            System.assertNotEquals(null, data,'User List Found');
        test.stopTest();
    }
    
    /**
    * @description 
    * @author @krishan | 05-19-2023 
    **/
    @isTest
    public static void getUserDetailsTest2(){
        test.startTest();
            Account objAcc = [select id from account where name='Test Account'];
            PMC_DH_UserDetailWrapper data=PMC_DH_UserDetailController.getUserDetail(objAcc.Id);
            System.assertNotEquals(null, data,'User List Found');
        
        test.stopTest();
    }
    
    /**
    * @description get User Notification Preferences Test
    * @author @rohan | 08-31-2023 
    **/
    @isTest
    public static void getUserNotificationPreferencesTest(){
        User user=[SELECT id, ContactId, Contact.FirstName, Contact.LastName FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Id conId = user.ContactId;
        Contact con = [SELECT Id, IndividualId FROM Contact WHERE Id =: conId LIMIT 1];
        //if(con.IndividualId == null){
            Individual ind = PMC_DH_TestDataFactoryClass.createIndividual(user);
            con.IndividualId = ind.Id;
            update con;
            DataUseLegalBasis dulb = new DataUseLegalBasis(Name = 'Quotes');
            insert dulb;
            DataUsePurpose dup = new DataUsePurpose(Name = 'Accepted by Account Manager', LegalBasisId = dulb.Id);
            insert dup;
            ContactPointTypeConsent cptc = new ContactPointTypeConsent(ContactPointType = 'Email', 
                                                                       PrivacyConsentStatus = 'OptIn',
                                                                       Name = dup.Name,
                                                                       DataUsePurposeId = dup.Id,
                                                                       PartyId = con.IndividualId);
            insert cptc;
        system.runAs(user){
            PMC_DH_UserNotificationPreferenceWrapper result = PMC_DH_UserDetailController.getUserNotificationPreferences();
            system.Assert(result!=null, 'Success');
        }
    }
    
    /**
    * @description Update User Notification Preferences Test
    * @author @rohan | 08-31-2023 
    **/
    @isTest
    public static void updateUserNotificationPreferencesTextTest(){
        User user=[SELECT id, Contact.IndividualId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        PMC_DH_NotificationPreferenceController.createNotificationPref(user.id);
        PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper objChannelTypeWrap = new PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper();
        objChannelTypeWrap.boolSelectedValue = true;
        system.runAs(user){
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_UserDetailController.updateUserNotificationPreferences(objChannelTypeWrap, true, 'Text');
            system.Assert(result!=null, 'Success');
        }
    }
    
    /**
    * @description Update User Notification Preferences Test
    * @author @rohan | 08-31-2023 
    **/
    @isTest
    public static void updateUserNotificationPreferencesEmailTest(){
        User user=[SELECT id, Contact.IndividualId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        PMC_DH_NotificationPreferenceController.createNotificationPref(user.id);
        PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper objChannelTypeWrap = new PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper();
        objChannelTypeWrap.boolSelectedValue = true;
        system.runAs(user){
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_UserDetailController.updateUserNotificationPreferences(objChannelTypeWrap, true, 'Email');
            system.Assert(result!=null, 'Success');
        }
    }
    
    /**
    * @description Update User Notification Preferences Test
    * @author @rohan | 08-31-2023 
    **/
    @isTest
    public static void updateUserNotificationPreferencesWhatsappTest(){
        User user=[SELECT id, Contact.IndividualId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        PMC_DH_NotificationPreferenceController.createNotificationPref(user.id);
        PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper objChannelTypeWrap = new PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper();
        objChannelTypeWrap.boolSelectedValue = true;
        system.runAs(user){
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_UserDetailController.updateUserNotificationPreferences(objChannelTypeWrap, true, 'Whatsapp');
            system.Assert(result!=null, 'Success');
        }
    }
    
    /**
    * @description Update User Notification Preferences Test
    * @author @rohan | 08-31-2023 
    **/
    @isTest
    public static void updateUserNotificationPreferencesTest(){
        User user=[SELECT id, Contact.IndividualId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        PMC_DH_NotificationPreferenceController.createNotificationPref(user.id);
        ContactPointTypeConsent objChannelType = [SELECT Id, PrivacyConsentStatus 
                                                  FROM ContactPointTypeConsent WITH SYSTEM_MODE 
                                                  LIMIT 1];
        PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper objChannelTypeWrap = new PMC_DH_UserNotificationPreferenceWrapper.PMC_DH_ChannelTypeWrapper();
        objChannelTypeWrap.strNotificationId = objChannelType.Id;
        objChannelTypeWrap.boolSelectedValue = true;
        system.runAs(user){
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_UserDetailController.updateUserNotificationPreferences(objChannelTypeWrap, false, 'Whatsapp');
            system.Assert(result!=null, 'Success');
        }
    }
}