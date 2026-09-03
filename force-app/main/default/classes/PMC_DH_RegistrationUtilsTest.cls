/**
* @description : Test class for PMC_DH_RegistrationUtils
* @author      : Rohan Undale
* @last modified on 2023-06-02
* @last modified by Ajeet
**/
@isTest
public with sharing class PMC_DH_RegistrationUtilsTest {
	@testSetup  static void setup()
    {
        Account acc=PMC_DH_TestDataFactoryClass.createTestAccount();
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Digital Hub Super Buyer' LIMIT 1];
        PMC_DH_TestDataFactoryClass.createContact(acc.Id);
        User usr = PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
        String role = 'Account Manager';
        PMC_DH_TestDataFactoryClass.createTestAccountTeamMember(acc.Id,usr.Id,role);
    }
    
    @isTest
    public static void isContactEmailPresentTest(){
        PMC_DH_ContactUtils.PMC_DH_RegisterUtilWrapper userWrapper = new PMC_DH_ContactUtils.PMC_DH_RegisterUtilWrapper();
        userWrapper.strLastName = 'TestUserXYZ';
        userWrapper.strEmail = 'demouser123@abc.com';
        userWrapper.strCountryCode = 'US +1'; 
        userWrapper.strPhoneNumber = '1872573568';
        test.startTest();
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_RegistrationUtils.isContactEmailPresent(userWrapper);
        System.assertEquals('000', result.strStatusCode, 'Code should be 000');
        test.stopTest();
    }
    
    @isTest
    public static void isContactEmailPresentTestNegative(){
        PMC_DH_ContactUtils.PMC_DH_RegisterUtilWrapper userWrapper = new PMC_DH_ContactUtils.PMC_DH_RegisterUtilWrapper();
        userWrapper.strLastName = 'TestUser';
        userWrapper.strEmail = 'demouser1@abc.com';
        userWrapper.strCountryCode = 'US +1'; 
        userWrapper.strPhoneNumber = '1872573868';
        test.startTest();
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_RegistrationUtils.isContactEmailPresent(userWrapper);
        System.assertEquals('001', result.strStatusCode, 'Code should be 001');
        test.stopTest();
    }

    @isTest
    public static void isContactEmailPresentTestException(){
        PMC_DH_ContactUtils.PMC_DH_RegisterUtilWrapper userWrapper = new PMC_DH_ContactUtils.PMC_DH_RegisterUtilWrapper();
        userWrapper.strLastName = 'TestUser';
        userWrapper.strEmail = 'demouser1@abc.com';
        userWrapper.strCountryCode = 'US+1'; 
        userWrapper.strPhoneNumber = '1872573568';
        test.startTest();
        PMC_DH_RegistrationUtils.throwTestException = true;
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_RegistrationUtils.isContactEmailPresent(userWrapper);
        System.assertEquals('100', result.strStatusCode, 'Code should be 100');
        test.stopTest();
    }
    
    @isTest
    public static void isAccountInfoValidTest(){
        test.startTest();
        Boolean result = PMC_DH_RegistrationUtils.isAccountInfoValid('Test001','DemoUser1@abc.com');
        System.assertEquals(false, result, 'Success');
        test.stopTest();
    }
    
    @isTest
    public static void isAccountInfoValidTestNegative(){
        test.startTest();
        Boolean result = PMC_DH_RegistrationUtils.isAccountInfoValid('Test000','DemoUser1@abc.com');
        Assert.isFalse(result,'Assertion Failed');
        System.assertEquals(false, result, 'Success');
        test.stopTest();
    }

    @isTest
    public static void isAccountInfoValidTestException(){
        test.startTest();
        PMC_DH_RegistrationUtils.throwTestException = true;
        try{
            PMC_DH_RegistrationUtils.isAccountInfoValid('Test000','DemoUser1@abc.com');
        }
        catch(Exception ex){
            System.assertEquals('Script-thrown exception', ex.getMessage(), 'Error message should match');
        }
        test.stopTest();
    }
    
    @isTest
    public static void getUserRegistationDetailsTest(){
        test.startTest();
        String result = PMC_DH_RegistrationUtils.getUserRegistationDetails();
        System.assert(result != null, 'Success');
        test.stopTest();
    }

    @isTest
    public static void getUserRegistationDetailsTestException(){
        test.startTest();
        PMC_DH_RegistrationUtils.throwTestException = true;
        try{
            PMC_DH_RegistrationUtils.getUserRegistationDetails();
        }
        catch(Exception ex){
            System.assertEquals('Script-thrown exception', ex.getMessage(), 'Error message should match');
        }
        test.stopTest();
    }

    @isTest
    public static void verifyAccessForUserCreationTest(){
        String result;
        test.startTest();
        User usr = [SELECT Id,Email FROM User WHERE Email = 'demouser@test.com' LIMIT 1];
        System.runAs(usr){
            result = PMC_DH_RegistrationUtils.verifyAccessForUserCreation('DemoUser1@abc.com');
            System.assert(result != null, 'Success');
        }
        test.stopTest();
    }

    @isTest
    public static void verifyAccessForUserCreationTestUserExistNegative(){
        String result;
        test.startTest();
        User usr = [SELECT Id,Email FROM User WHERE Email = 'demouser@test.com' LIMIT 1];
        System.runAs(usr){
            result = PMC_DH_RegistrationUtils.verifyAccessForUserCreation('demouser@test.com');
            PMC_DH_RegistrationUtilWrappers.PMC_DH_VerifyAccessForUserCreationWrapper resultJson = (PMC_DH_RegistrationUtilWrappers.PMC_DH_VerifyAccessForUserCreationWrapper) JSON.deserialize(result, PMC_DH_RegistrationUtilWrappers.PMC_DH_VerifyAccessForUserCreationWrapper.class);
            System.assertEquals(resultJson.boolIsUserExisting, true, 'User should be present');
        }
        test.stopTest();
    }

    @isTest
    public static void verifyAccessForUserCreationTestNegative(){
        String result;
        test.startTest();
        //User usr = [SELECT Id,Email FROM User WHERE Email = 'demouser@test.com' LIMIT 1];
        User testOwner = [SELECT TimeZoneSidKey, UserRoleId FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(testOwner){
            result = PMC_DH_RegistrationUtils.verifyAccessForUserCreation('DemoUser1@abc.com');
            PMC_DH_RegistrationUtilWrappers.PMC_DH_VerifyAccessForUserCreationWrapper resultJson = (PMC_DH_RegistrationUtilWrappers.PMC_DH_VerifyAccessForUserCreationWrapper) JSON.deserialize(result, PMC_DH_RegistrationUtilWrappers.PMC_DH_VerifyAccessForUserCreationWrapper.class);
            System.assertEquals(resultJson.boolIsSuperBuyerAuthorized, false, 'User not autorised');
        }
        test.stopTest();
    }

    @isTest
    public static void verifyAccessForUserCreationTestException(){
        test.startTest();
        PMC_DH_RegistrationUtils.throwTestException = true;
        User usr = [SELECT Id,Email FROM User WHERE Email = 'demouser@test.com' LIMIT 1];
        System.runAs(usr){
            try{
                PMC_DH_RegistrationUtils.verifyAccessForUserCreation('DemoUser1@abc.com');
            }
            catch(Exception ex){
                System.assertEquals('Script-thrown exception', ex.getMessage(), 'Error message should match');
            }
        }
        test.stopTest();
    }
}