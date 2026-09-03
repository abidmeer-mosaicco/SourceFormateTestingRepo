/* Class Name      :PMC_DH_UserInfoControllerTest
* Description      :Test Class for fetching and updating user deatil 
* Created By       :Ajeet
* Created On       :2023-May-06
*/
/** 
* @description Controller for fetching and updating user detail  
* @author Ajeet
* @last modified on 05-15-2023
* @last modified by Nikhilesh
* Created On       :2023-May-03
**/
@isTest
public with sharing class PMC_DH_UserInfoControllerTest {
    /**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* 
* @param: none
* 
* @return: void
*
* @author Ajeet
* @date 2023-05-15
*/
    @TestSetup
    public static void makeData(){
        Account accParent= PMC_DH_TestDataFactoryClass.createParentTestAccount(); 
       Account acc = PMC_DH_TestDataFactoryClass.createTestAccount();
        acc.Name='TestAccount';
       acc.ParentId=accParent.Id;
        update acc;
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.BUYER_PERSONA LIMIT 1];
        User usr = PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id); 
        
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        //String strContactId=[SELECT contactId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1][0].contactId;
        Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet2);
        Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet);
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet1);
        Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet3);
        
        AccountShare accShare = new AccountShare();
        accShare.AccountId=accParent.Id;
        accShare.AccountAccessLevel='Edit';
        accShare.OpportunityAccessLevel='Read';
        accShare.CaseAccessLevel='Read';
        //accShare.RowCause = 'Manual';
        accShare.UserOrGroupId=usr.Id;
        insert accShare;
        
        
 
    }
    
    /**
* @description Method for testing data for logged in User
* 
* @param: none
* 
* @return: void
*
* @author Ajeet
* @date 2023-05-15
*/
    @isTest
    public static void testGetUserInfo() {
        User usr =[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        usr.phone='+55 99803455';
        update usr;
        System.runAs(usr) {
            Test.startTest();
            String strResult;
            strResult= PMC_DH_UserInfoController.getUserInfo();
            System.Assert(String.isNotBlank(strResult), 'Success');
            Test.stopTest();
        }
    }
    
    /**
* @description Method for testing updated data for logged in User
* 
* @param: none
* 
* @return: void
*
* @author Ajeet
* @date 2023-05-15
*/
    @isTest
    public static void testUpdateUserInfo() {
        User usr = [SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_Buyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(usr.Id,lstPermSet1);
        System.runAs(usr) {
            Test.startTest();
            String strResult=PMC_DH_UserInfoController.updateUserInfo('TestUserLastName','US +1','5767298268178');
            System.Assert(strResult!=null, 'Success');
            Test.stopTest();
        }
    }
    
    
    /**
* @description Method for negative testing updated data for logged in User
* 
* @param: none
* 
* @return: void
*
* @author Ajeet
* @date 2023-05-15
*/
    /*
    @isTest
    public static void testUpdateUserInfoNT() {
        User usr = [SELECT Id from User WHERE Email = 'demouser@test.com'];
        
        System.runAs(usr) {
            Test.startTest();
            Boolean exceptionOccurred;
            try{
                PMC_DH_UserInfoController.throwUsersTestException = true;
                PMC_DH_UserInfoController.updateUserInfo('TestUserLastName','US +1','5767298178');
            }catch(exception e){
                exceptionOccurred=true;
            }
            
            Test.stopTest();
            System.assert(exceptionOccurred, 'An Exception was not thrown');
        }
    }
    */
    
     /** 
   * @description : Method to test creation of user by Super-Buyer
   * 
   * @param : none
   * @author : Hemant
   * @date :2023-05-24
   */
   @isTest
   public static void testcreateNewUserWithoutApproval()
   {
	
     Test.startTest();
     User usrr=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1]; 
     Account accRO=[SELECT Id,AccountNumber,name from Account where AccountNumber='Test002' LIMIT 1];
     
     
     PMC_DH_ContactUtils.PMC_DH_RegisterUserWrapper wrpUserDetail=new PMC_DH_ContactUtils.PMC_DH_RegisterUserWrapper();
       wrpUserDetail.strFirstName='Yaminigs';
       wrpUserDetail.strLastName='Sodddigs';
       wrpUserDetail.strCountryCode='US +1';
       wrpUserDetail.strEmail='YP1@shwbg.com';
       wrpUserDetail.strPhoneNumber='986147856';
       wrpUserDetail.strAccountId=accRO.Id;
       wrpUserDetail.strCountry='India';
       wrpUserDetail.strState='';
       wrpUserDetail.strCity='Pune';
       wrpUserDetail.strUserType='Digital Hub Buyer';
       System.runAs(usrr) 
       {
            
           
         PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper r= PMC_DH_UserInfoController.createNewUserWithoutApproval(wrpUserDetail);
         System.assert(r!=null,'Success');
        // PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper wrpFailure= PMC_DH_UserInfoController.createNewUserWithoutApproval(wrpUserDetail);
       }
       test.stopTest();
   }

    /**
     *  @description : Method to test creation of user by Super-Buyer 
     * 
     * @param : none
     * @author : Hemant	
     * @date :2023-05-25
     * */
    
       @isTest
    public static void testCreateNewUserWithoutApprovalNT() {
	User usrr=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
     Account accRO=[SELECT Id,AccountNumber,name from Account where AccountNumber='Test002' LIMIT 1];
     
     PMC_DH_ContactUtils.PMC_DH_RegisterUserWrapper wrpUserDetail=new PMC_DH_ContactUtils.PMC_DH_RegisterUserWrapper();
       wrpUserDetail.strFirstName='yaani';
       wrpUserDetail.strLastName='Soddd';
       wrpUserDetail.strCountryCode='US +1';
       wrpUserDetail.strEmail='YP@shb.com';
       wrpUserDetail.strPhoneNumber='9857072111';
       wrpUserDetail.strAccountId=accRO.Id;
       wrpuserDetail.strUserType='Buyer';
       wrpUserDetail.strCountry='India';
       wrpUserDetail.strState='Maharashtra';
       wrpUserDetail.strCity='Pune';   
        Test.startTest();
        System.runAs(usrr) {
                PMC_DH_UserInfoController.throwUsersTestException = true;
                PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper r= PMC_DH_UserInfoController.createNewUserWithoutApproval(wrpUserDetail);
                System.assert(r!=null,'sucess');  
        }
        Test.stopTest();
    }
    
    /**
     *  @description : Method to test modal values
     * 
     * @param : none
     * @author : Hemant	
     * @date :2023-05-25
     * */
    
    @isTest
    public static void testModalValues()
    { user usrr = [SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        
     System.runAs(usrr)
     {
         Test.startTest();
         String strUsrId=userinfo.getUserId();
          String strR=PMC_DH_UserInfoController.getModalDetails(strUsrId);
         
         System.assert(strR!=null,'Success');
         
     }
         
     }
        
      /**
     *  @description : Method to test deactivate User
     * 
     * @param : none
     * @author : Ajeet	
     * @date :2023-06-05
     * */
    @isTest
    public static void testDeactivateUser(){
        User usr = [SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        PermissionSetAssignment psAssignment = new PermissionSetAssignment(); 
		psAssignment.AssigneeId = usr.Id;
		//psAssignment.PermissionSetGroupId = '0PGDT000000DNAd4AO'; 
        psAssignment.PermissionSetGroupId = [SELECT Id from PermissionSetGroup WHERE DeveloperName = 'PMC_DH_Buyer_Permission_Set_Group' LIMIT 1][0].Id;
        Test.startTest();
        PMC_DH_UserInfoController.deactivateUserAndDisablePartner(usr.Id);        
        Test.stopTest();
        List<User> updatedUsr = [SELECT Id, Email, Username, isActive from User WHERE Email = 'demouser@test.com'];
        System.assert(updatedUsr.size()==0,'Success');
    }

    /**
     *  @description : Method to test deactivate User Negative Scenario
     * 
     * @param : none
     * @author : Ajeet	
     * @date :2023-06-05
     * */
    @isTest
    public static void testDeactivateUserNegative(){
        User usr = [SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        PermissionSetAssignment psAssignment = new PermissionSetAssignment();
		psAssignment.AssigneeId = usr.Id;
		//psAssignment.PermissionSetGroupId = '0PGDT000000DNAd4AO';
        psAssignment.PermissionSetGroupId = [SELECT Id from PermissionSetGroup WHERE DeveloperName = 'PMC_DH_Buyer_Permission_Set_Group' LIMIT 1][0].Id;
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper usrData;
        Test.startTest();
        usrData = PMC_DH_UserInfoController.deactivateUserAndDisablePartner(usr.Id);
        //usrData.isActive = true;
        Test.stopTest();
        System.assertEquals(usrData.strStatusCode,'000','Success');
    }

}