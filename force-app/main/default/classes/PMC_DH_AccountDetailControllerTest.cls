/**
* @description : Test class for PMC_DH_AccountDetailController
* @author      : Krishan Jangir
* @last modified on 2023-05-15
* @last modified by Nikhilesh
**/
@isTest
public with sharing class PMC_DH_AccountDetailControllerTest {
    
    @testSetup  static void setup()
    {
        //test class fixes
        PMC_DH_TestDataFactoryClass.createTestAccount();
       // PMC_DH_TestDataFactoryClass.createPortalUser();
        
    }
    
   
    @isTest

    public static void getAccountDetailsTest1(){
        test.startTest();
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        UUID randomUuid = UUID.randomUUID(); // added as fix for Username Duplicacy Error
        String strSandboxName = UserInfo.getUserName().substringAfterLast('.');// added as fix for Username Duplicacy Error
        User portalAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond()+strSandboxName+randomUuid.toString()+ 'test2@test.com',
            Alias = 'batman',
            phone = '+1 9988665544',
            Country='United States',
            Email='bruce.wayne@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago',
            CurrencyIsoCode = 'USD',
            MobilePhone = '9876789103',
            FederationIdentifier = '0745611',
            PMC_CPQ_SalesRegion__c = 'North America'
        );
        Database.insert(portalAccountOwner1);
        System.runAs ( portalAccountOwner1 ) {
            Account portalAccount2 = new Account(
                Name = 'TestAccount',
                OwnerId = portalAccountOwner1.Id
            );
            Database.insert(portalAccount2);
            Profile portalProfile = [SELECT Id FROM Profile where Name = 'Digital Hub Super Buyer' Limit 1];
            PMC_DH_TestDataFactoryClass.createTestUser(portalAccount2.id,portalProfile.Id);
            User user=[SELECT id from User WHERE Username = 'demouser@test.com.testuser'];
            PMC_DH_TestDataFactoryClass.createTestAccountTeamMember(portalAccount2.id,user.id,PMC_DH_ConstantClass.ACCOUNT_TEAMMEMBERSSR);
            PMC_DH_AccountDetailController.AccounStatusWrapper result = PMC_DH_AccountDetailController.getAccountDetail(portalAccount2.id);
            System.Assert(result!=null, 'Success');
        }
        
        test.stopTest();
    }
    @isTest
    public static void getAccountDetailsTest2(){
        test.startTest();
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User portalAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'test245@test.com',
            Alias = 'batman',
            phone = '+1 9988665544',
            Country='United States',
            Email='bruce.wayne@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago',
            CurrencyIsoCode = 'USD',
            MobilePhone = '9876719103',
            FederationIdentifier = '0645611',
            PMC_CPQ_SalesRegion__c = 'North America'
        );
        Database.insert(portalAccountOwner1);
        System.runAs ( portalAccountOwner1 ) {
            Account portalAccount2 = new Account(
                Name = 'TestAccount',
                OwnerId = portalAccountOwner1.Id
            );
            Database.insert(portalAccount2);
            Profile portalProfile = [SELECT Id FROM Profile where Name = 'Digital Hub Super Buyer' Limit 1];
            PMC_DH_TestDataFactoryClass.createTestUser(portalAccount2.id,portalProfile.Id);
            User user=[SELECT id from User WHERE Username = 'demouser@test.com.testuser'];
            PMC_DH_TestDataFactoryClass.createTestAccountTeamMember(portalAccount2.id,user.id,PMC_DH_ConstantClass.ACCOUNT_TEAMMEMBERACC);
            PMC_DH_AccountDetailController.AccounStatusWrapper result = PMC_DH_AccountDetailController.getAccountDetail(portalAccount2.id);
            System.Assert(result!=null, 'Success');
        }
        
        test.stopTest();
    }
    
    
    

    @isTest
    public static void getAccountManagerNameTest()
    {	
        Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
        //Account shipToAcc=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id); 
        User usrr=[SELECT Id,email,Name,AccountId,Account.Name,ContactId from User WHERE Username = 'demouser@test.com.testuser' LIMIT 1 ];
        Account acc1=[Select id from Account where name='Parent Test Account'];
        Test.startTest();
        System.runAs(usrr)
        {
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper strName=PMC_DH_AccountDetailController.getAccountManagerName(acc1.id);
            System.assert(strName!=null,'Success');
            
           
        }
        Test.stopTest();
    }
    
    
    
     @isTest
    public static void getAccountManagerNameTestNT()
    {	
        Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
        
        User usrr=[SELECT Id,email,Name,AccountId,Account.Name,ContactId from User WHERE Username = 'demouser@test.com.testuser' LIMIT 1 ];
        Account acc1=[Select id from Account where name='Parent Test Account'];
        AccountTeamMember accTeam=new AccountTeamMember(UserId=usrr.Id,
                                        AccountId=acc1.id,TeamMemberRole='Account Manager');
        insert accTeam;
        Test.startTest();
        System.runAs(usrr)
        {   PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper strName;
            try{
                PMC_DH_AccountDetailController.boolThrowException=true;
               strName=PMC_DH_AccountDetailController.getAccountManagerName(acc1.id);  
                
            }
            catch(Exception e){
                strName.strStatusMessage='Exception';
            }
         System.assert(strName!=null,'Passed');
        }
        Test.stopTest();
    }
}