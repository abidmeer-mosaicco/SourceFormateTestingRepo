/**
* @description : Test class for PMC_DH_ContactUtils
*
* @author      : Rohan Undale
**/
@isTest
public with sharing class PMC_DH_ContactUtilsTest {
    @testSetup  static void setup()
    {   Account acc;
        User user;
        User userAdmin=PMC_DH_TestDataFactoryClass.createAdminUser();
        System.runAs(userAdmin){
        acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
        
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
        user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet2);
        Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet);
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet1);
        Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet3);
        }
        System.runAs(user)
        {
            Contact con = PMC_DH_TestDataFactoryClass.createContact(acc.Id);
            con.PMC_DH_Language__c='English';
            update con;
        }

    }

    @isTest
    public static void createNewUserTest(){
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        System.runAs(user){
        Test.startTest();
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_ContactUtils.createNewUser('DemoUser1@abc.com','Digital_Hub_Buyer');
        //Assert.isTrue(result,'Failed');
        System.assertEquals('000', result.strStatusCode, 'Success');
        Test.stopTest();
        }
    }
    
    @isTest
    public static void createPartnerContactTest(){
        Account acc = [Select Id from Account where AccountNumber='Test002'];
        PMC_DH_ContactUtils.PMC_DH_RegisterUserWrapper userInfoData = new PMC_DH_ContactUtils.PMC_DH_RegisterUserWrapper();
        userInfoData.strFirstName = 'Hemant';
        userInfoData.strLastName = 'Goswami';
        userInfoData.strEmail = 'hm@mail.com';
        userInfoData.strPhoneNumber = '98764321009';
        userInfoData.strCountry = 'Brazil';
        userInfoData.strCountryCode = 'BR +55';
        userInfoData.strState = '';
        userInfoData.strCity = 'San Antonio';
        userInfoData.strAccountId = acc.Id;
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        System.runAs(user){
        test.startTest();
        	Contact result = PMC_DH_ContactUtils.createPartnerContact(userInfoData);
        test.stopTest();
        System.assertEquals('Hemant', result.FirstName, 'Success');
        }
    }
}