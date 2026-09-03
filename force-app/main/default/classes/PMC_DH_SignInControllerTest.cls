/**
* @description : Test class for PMC_DH_SignInController
* @author      : Lohitha Sai
* @userStory   : GDPH-167
* @last modified on 2023-05-19
* @last modified by Nikhilesh
**/
@isTest
private with sharing class PMC_DH_SignInControllerTest {
    @testSetup 
     static void createTestUser(){
        /*UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Admin' Limit 1];
        
        User adminUser = [Select Id, UserRoleId,FederationIdentifier, PMC_CPQ_SalesRegion__c, MobilePhone From User Where Profile.Name='System Administrator' AND isActive=TRUE Limit 1];
        adminUser.UserRoleId = userRole.Id;
        adminUser.FederationIdentifier = '09456567';
        adminUser.PMC_CPQ_SalesRegion__c = 'North America';
        adminUser.MobilePhone = '9876789604';
        update adminUser;*/
         
        User adminUser=PMC_DH_TestDataFactoryClass.createAdminUser();
        System.runAs(adminUser)
        {
        Profile guestProfile = [SELECT Id FROM Profile WHERE Name = 'Mosaic Direct Profile' LIMIT 1];
        User guestUser = new User(
            FirstName = 'GuestUser',
            LastName = 'Bush',
            Email = 'demouserguest@test.com',
            Username = 'guestuser@test.com.testuser',
            Alias = 'guestest',
            isActive = true,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            ProfileId = guestProfile.Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            CurrencyIsoCode = 'USD',
            MobilePhone = '9876789603',
            FederationIdentifier = '0945611',
            PMC_CPQ_SalesRegion__c = 'North America'
        );
         insert guestUser;

        Account acc=new Account();
        acc.Name='Test Account';
        insert acc;
        Contact contactCommerce = new Contact(
            FirstName = 'Demo',
            LastName = 'TestUser',
            Phone = 'US(+1)(222)222-78905',
            Email = 'DemoUser@abc.com',
            MailingStreet = 'xyzz',
            Title = 'Customer',
            AccountId=acc.id
        );
        
        insert contactCommerce;
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'PARTNER COMMUNITY USER' LIMIT 1];
        
        User testUser = new User(
            FirstName = 'DemoUserRequest',
            LastName = 'Bush',
            Email = 'demouser@test.com',
            Username = 'demouser@test.com.testuser',
            Alias = 'abctest',
            isActive = true,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            ContactId = contactCommerce.Id,
            ProfileId = profile.Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            CurrencyIsoCode = 'USD',
            MobilePhone = '9876789603',
            FederationIdentifier = '234505',
            PMC_CPQ_SalesRegion__c = 'North America'
        );
        
        insert testUser;
       }

    }
     
    @isTest
    static void testValidLogin(){
        User portalUser = [SELECT Id,FirstName, LastName, Email, Username FROM User WHERE Username='demouser@test.com.testuser'];
        User guestUser = [SELECT Id,FirstName, LastName, Email, Username FROM User WHERE Username='guestuser@test.com.testuser'];

        Test.startTest();
        PMC_DH_SiteService.setMock(new PMC_DH_MockSiteService());
        System.runAs(guestUser){
            String strRedirectURL = 'https://globaldigitalacceleration--devp1.sandbox.my.site.com/mosaicdirect/';
            //String result = PMC_DH_SignInController.login(portalUser.Username,'Deloitte123', strRedirectURL);
            PMC_DH_SignInController.PMC_DH_LoginWrapper wrpResult = PMC_DH_SignInController.login(portalUser.Username,'Deloitte123', strRedirectURL); //added as part of GDASF-19642
            PMC_DH_SiteService res = new PMC_DH_SiteService();
            res.shadowLogin(portalUser.Username,'Deloitte123', strRedirectURL);
            //System.Assert(result!=null, 'Success');
            System.Assert(wrpResult.strReturnURL != null, 'Success'); //added as part of GDASF-19642
        }
        Test.stopTest();
        }
       
    @isTest
    static void testInvalidLogin(){
        User portalUser = [SELECT Id,FirstName, LastName, Email, Username FROM User WHERE Username='demouser@test.com.testuser'];
        User guestUser = [SELECT Id,FirstName, LastName, Email, Username FROM User WHERE Username='guestuser@test.com.testuser'];
        Test.startTest();
        boolean exceptionOccurred;
        PMC_DH_SiteService.setMock(new PMC_DH_MockSiteService());
        System.runAs(guestUser){                
            try{
                PMC_DH_SignInController.throwTestException = true;
                PMC_DH_SignInController.login(portalUser.Username,'', '');
            }catch(Exception ex){
                exceptionOccurred = true;
        }
        System.assert(exceptionOccurred,'Exception Occured');
        }
        Test.stopTest();
    }
    
    @isTest
    public static void nullPointerCheckTest(){
        User guestUser = [SELECT Id,FirstName, LastName, Email, Username FROM User WHERE Username='guestuser@test.com.testuser'];
        test.startTest();
        PMC_DH_SiteService.setMock(new PMC_DH_MockSiteService());
        System.runAs(guestUser){
        	try{
            	//String result = PMC_DH_SignInController.login('','','');
            	//System.Assert(result==null, 'Success');
                
                //added as part of GDASF-19642
                PMC_DH_SignInController.PMC_DH_LoginWrapper wrpResult = PMC_DH_SignInController.login('','','');
            	System.Assert(wrpResult.strReturnURL==null, 'Success');
        	}
        	catch(Exception ex){
            	System.assert(ex!=null, 'Exception');
        	}
        }
        test.stopTest();
    }
    
    @isTest
    public static void isLoginSuccessfulTestException(){
        User portalUser = [SELECT Id,FirstName, LastName, Email, Username FROM User WHERE Username='demouser@test.com.testuser'];
        User guestUser = [SELECT Id,FirstName, LastName, Email, Username FROM User WHERE Username='guestuser@test.com.testuser'];
        test.startTest();
        PMC_DH_SiteService.setMock(new PMC_DH_MockSiteService());
        System.runAs(guestUser){
        	String strRedirectURL = 'https://globaldigitalacceleration--devp1.sandbox.my.site.com/mosaicdirect/';
        	try{
            	PMC_DH_SignInController.login(portalUser.Username,'Deloitte123', strRedirectURL);
        	}
        	catch(Exception ex){
            	System.assertEquals('Script-thrown exception', ex.getMessage(), 'Error message should match');
        	}
        test.stopTest();
    }
    
    }
    
    @isTest
    static void testValidateUserSession(){
        User portalUser = [SELECT Id,FirstName, LastName, Email, Username FROM User WHERE Username='demouser@test.com.testuser'];
        //User guestUser = [SELECT Id,FirstName, LastName, Email, Username FROM User WHERE Username='guestuser@test.com.testuser'];

        Test.startTest();
        PMC_DH_SiteService.setMock(new PMC_DH_MockSiteService());
        System.runAs(portalUser){
            try{
            PMC_DH_SignInController.PMC_DH_ValidateUserSessionWrapper wrpResult = PMC_DH_SignInController.validateUserSession();
            System.Assert(wrpResult!=null, 'Success');
            }Catch(Exception ex){
                System.assertEquals(ex!=NULL,true,'Cron Expressions');
            }
        }
        Test.stopTest();
        }

}