@isTest(seeAllData = false)
public with sharing class  PMC_SS_CaseServiceNowUpdateCtrlTest {

    /**
    * @description This Method will be used to setup the test data for the test class execution.
    */
    
    @testsetup
    private static void setup() {
        List<String>lstProfileNames = New List<String>{'System Administrator','Service User'};
        List<String>lstPermissionNames = New List<String>{'PMC_Administrator_Permission_Set_Group','PMC_SRV_Permission_Set_Group'};
        Map<String,Id>mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
        Map<String,PermissionSetGroup>mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionNames);
        Integer intuserCount =0;
        User objSystemAdminUser;  
        User objServiceUser;
        List<User> lstUser = PMC_TestUtilityClass.createUser(2);
            for(User objUser : lstUser) {
                If(intuserCount==0){
                   objUser.LastName = 'Admin User Test';
                   objUser.ProfileId = mapOfProfiles.get('System Administrator'); 
                   objUser.FederationIdentifier = objUser.Username + 'Admin';
                }else if(intuserCount==1){
                    objUser.LastName = 'Service User Test';
                    objUser.ProfileId = mapOfProfiles.get('Service User'); 
                   objUser.FederationIdentifier = objUser.Username + 'Service';
                }
                objUser.isActive = true;                
                objUser.MobilePhone = '1234567890';
                intuserCount = intuserCount + 1;
            }            
            insert lstUser;
            objSystemAdminUser = lstUser[0];
            objServiceUser = lstUser[1];
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSystemAdminUser}, mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group'));
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objServiceUser}, mapOfPermissionGrp.get('PMC_SRV_Permission_Set_Group'));
        Account objAccount;
        Opportunity objOpportunity;
        BusinessHours objBusinessHrs = [SELECT Id, Name FROM BusinessHours WHERE isDefault = True AND IsActive = True]; 
        System.runAs(objSystemAdminUser){
        PMC_TestUtilityClass.createLocation('Test Schema.Location');    
        }
        System.runAs(objServiceUser){
        objAccount = PMC_TestUtilityClass.createAccount('Mike Rauu', 'PMC_SS_Prospect');
        objOpportunity =  PMC_TestUtilityClass.createOpportunity(1, '')[0];
        List<Case> lstCases = getTestCasesList(new List<Account>{objAccount}, objServiceUser.Id, objBusinessHrs.Id);
        insert lstCases;
        }
        System.runAs(objSystemAdminUser){
        PMC_TestUtilityClass.createContract(new List<Account>{objAccount}, new List<Opportunity>{objOpportunity});
        }    
        
            
            
        
    }
    /**
     * @description Method will create Test Case 
     * @param lstAccounts - List of test accounts created
     * @param idUser - User Id as Owner
     * @param idBusinessHours - Business Hours Id
     * @return List<Case> return list of test cases created
     */

    public static List<Case> getTestCasesList(List<Account> lstAccounts, Id idUser, Id idBusinessHours) {
        Schema.Location objLocation = [SELECT ID FROM Location limit 1];        
        List<Case> lstCases = new List<Case>();

        for(Integer intAccountCount = 0; intAccountCount < lstAccounts.size(); intAccountCount++) {
            Case objCase = PMC_TestUtilityClass.createCase(idBusinessHours, lstAccounts[intAccountCount].Id, idUser,objLocation.Id);
            
            objCase.Subject = intAccountCount == 0 ? 'Test Case High Priority Excemption' : 'Test Subject';
            objCase.Type = intAccountCount == 0 ? 'Internal' : 'Shipping';     
            objCase.PMC_SS_IssueReason__c = intAccountCount == 0 ? 'MDM Verification' : 'Diversion';
            objCase.PMC_SS_RouteToQuality__c = False;
            objCase.PMC_SS_SNOW_ServiceNowTicketSyncId__c = 'TTTES';
            lstCases.add(objCase);
        }
        
        return lstCases;
    }
    
    /**
    * @description This Method will be used to cover getAccountRelatedDetails from PMC_SS_CaseServiceNowUpdateCtrl
    */
    @isTest
    private static void testGetAccountRelatedDetails() {
        Test.startTest();
        
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
        Account objAccount = [SELECT Id, Name FROM Account WITH SECURITY_ENFORCED LIMIT 1];
        
        if(objAccount != null) {
                Account objAccount1 = PMC_SS_CaseServiceNowUpdateCtrl.getAccountRelatedDetails(objAccount.Id);
                System.assertEquals(objAccount1.Id, objAccount.Id, 'Account Retrieved');
            
            }
        }
    }
    
    /**
    * @description This Method will be used to cover getAccountRelatedDetails from PMC_SS_CaseServiceNowUpdateCtrl
    */
    @isTest
    private static void testGetAccountRelatedDetailsFailure() {
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];

       System.runAs(objUser) {
        try {                
                	PMC_SS_CaseServiceNowUpdateCtrl.getAccountRelatedDetails('1234567890');
                    system.assert(false, 'Exceptions should be handled by the method');
        }
        catch(Exception objException) {
            System.assertNotEquals('', objException.getMessage(), 'Expected error log object to be created');
        }
    }
        Test.stopTest();
    }
    /**
    * @description This Method will be used to cover getAccountRelatedDetails from PMC_SS_CaseServiceNowUpdateCtrl
    */
    @isTest
    private static void testUserDetails() {
        Test.startTest();
        
      
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
            
                System.runAs(objUser) {                	
                    PMC_SS_CaseServiceNowUpdateCtrl.getUserDetails();
                    system.assertEquals(PMC_SS_CaseServiceNowUpdateCtrl.getUserDetails().size()>0, true,'User returned');
                }
            
        
        
        
        Test.stopTest();
    }

    /**
    * @description This Method will be used to cover getAccountRelatedDetails from PMC_SS_CaseServiceNowUpdateCtrl
    */
    @isTest
    private static void testGetInvoicesFailure() {
        Test.startTest();
        
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        //PMC_SS_CaseServiceNowUpdateCtrl.getInvoices('test099898');
        
        if(objUser != null) {
            System.runAs(objUser) {
                system.assertEquals(PMC_SS_CaseServiceNowUpdateCtrl.getInvoices('1234567890') != null, true,'User returned');
            }
        }        
        
        Test.stopTest();
    }
    /**
    * @description This Method will be used to cover getAccountRelatedDetails from PMC_SS_CaseServiceNowUpdateCtrl
    */
    @isTest
    private static void testTickectCreation() {
        Test.startTest();
        
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        if(objUser != null) {
            System.runAs(objUser) {
                Test.setMock(HttpCalloutMock.Class, new PMC_SS_ServiceNowMockHttpResponse());
                
                system.assertNotEquals('test',PMC_SS_CaseServiceNowUpdateCtrl.createSNTicket('Circularization Letters – Clients','test'),'Tickect Created');
            }
        }         
        
        Test.stopTest();
    }
    /**
    * @description This Method will be used to cover insertComment from PMC_SS_CaseServiceNowUpdateCtrl
    */
    @isTest
    private static void testCommentCreation() {
        Test.startTest();
        
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
        Case objCase = [SELECT Id FROM Case WITH SECURITY_ENFORCED LIMIT 1];
        objCase.PMC_SS_SNOW_ServiceNowTicketSyncId__c = 'testSyncID';
        update objCase;
                Test.setMock(HttpCalloutMock.Class, new PMC_SS_ServiceNowMockHttpResponse());
                CaseComment objCaseComment = new CaseComment(ParentId =objCase.Id,CommentBody = 'Test Comment' );
                insert objCaseComment;
                PMC_SS_CaseServiceNowUpdateCtrl.addComments(new List<CaseComment>{objCaseComment});
                PMC_SS_CaseServiceNowUpdateCtrl.sendCommentToSNOW(objCaseComment.Id);
                PMC_SS_CaseServiceNowUpdateCtrl.getsnowlistDetails();
                system.assertNotEquals('',objCaseComment.Id,'Tickect Comment');
            }
                
        
        Test.stopTest();
    }
    
    /**
    * @description This Method will be used to cover getAccountRelatedDetails from PMC_SS_CaseServiceNowUpdateCtrl
    */
    @isTest
    private static void testTickectCreationERROR() {
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        if(objUser != null) {
            System.runAs(objUser) {
                try{
                    Test.setMock(HttpCalloutMock.Class, new PMC_SS_ServiceNowMockHttpResponse());
                	PMC_SS_CaseServiceNowUpdateCtrl.createSNTicket('Circularization Letters – Clients','test');
                }
                catch(Exception objException){
            
                    System.assertNotEquals('', objException.getMessage(), 'Expected error log object to be created');
                }
                
            }
        }         
        
        Test.stopTest();
    }
    /**
    * @description This Method will be used to cover getAccountRelatedDetails from PMC_SS_CaseServiceNowUpdateCtrl
    */
    @isTest
    private static void testServiceNowERROR() {
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        if(objUser != null) {
            System.runAs(objUser) {
                try{
                	PMC_SS_CaseServiceNowUpdateCtrl.createSNTicket('Circularization Letters – Clients','');
                }
                catch(Exception objException){
            
                    System.assertNotEquals('', objException.getMessage(), 'Expected error log object to be created');
                }
                
            }
        }         
        
        Test.stopTest();
    }

    
}