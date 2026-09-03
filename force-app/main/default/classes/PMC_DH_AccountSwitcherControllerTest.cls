/**
* @description       : 
* @author            : @siddharth.pradhan
* @group             : 
* @last modified on  : 07-18-2024
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
@isTest
private with sharing class PMC_DH_AccountSwitcherControllerTest  {

	@testsetup static void testSetup() {
        
        User userAdmin = PMC_DH_TestDataFactoryClass.createAdminUser();
        String strContactId;
        User user;
		System.runAs(userAdmin){
                
            Account acc = PMC_DH_TestDataFactoryClass.createParentTestAccount();  
            acc.name='TestAccount';
            update acc;
                
            Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
            PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
                
            user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
            strContactId=[SELECT contactId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1][0].contactId;
        
            Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
            PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet2);
            Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
            PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet);
            Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
            PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet1);
            Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
			PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet3);
		} 
	}
    
	@isTest
	public static void testGetAccountForModal() {
            
		// Create test data
        User usrObjRecord=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        System.runAs(usrObjRecord) {
            
        	Account accParent=[SELECT ID,NAME FROM ACCOUNT WHERE NAME='TestAccount' WITH SECURITY_ENFORCED LIMIT 1];
            Account accChild= PMC_DH_TestDataFactoryClass.createTestAccount(); 
            accChild.Name='Parent Test Account';
            //accChild.ParentId=accParent.Id; 
            update accChild;
            
            test.startTest();
            
            String strEffectiveAccountId='effId1';
            String strCommunityId='Coom 123';
            PMC_DH_AccountSwitcherController.PMC_DH_AccountSwitcherModalWrapper strModal= PMC_DH_AccountSwitcherController.getAccountForModal(strEffectiveAccountId,strCommunityId);
            System.Assert(strModal!=null, 'Success'); 
            
        }
        
		test.stopTest();    
	}
    
    @isTest
    public static void exceptionTest(){
        User usrObjRecord=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strEffectiveAccountId='effId1';
        String strCommunityId='Coom 123';
        test.startTest();
        
        System.runAs(usrObjRecord)
        {
        
        Boolean expectedVal=false;
        PMC_DH_AccountSwitcherController.PMC_DH_AccountSwitcherModalWrapper strModal;
        
            try{
                PMC_DH_AccountSwitcherController.boolthrowTestException = true;
                strModal=PMC_DH_AccountSwitcherController.getAccountForModal(strEffectiveAccountId,strCommunityId);
                
            }
            catch(Exception e)
            {
                expectedVal=true;
            }
            System.Assert(!expectedVal,'An Exception was thrown');
        }
        Test.stopTest();
        
    }
    
    @IsTest 
public static void getEffectiveAccountDetailsTest(){
        
        test.startTest();
        user usrObjRecord = [SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(usrObjRecord){
            PMC_DH_AccountSwitcherController.PMC_DH_EffectiveAccountDetails res= PMC_DH_AccountSwitcherController.getEffectiveAccountDetails();
            System.assertNotEquals(null, res,'effective acc details');
        }
        test.stopTest();
    }
}