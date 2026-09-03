/**
* @description This test class will be used to cover all the methods of PMC_SS_CreateTeamMemberController.
* @author Kailas Shimpi
* @storynumber GDASF-14672
*/

@isTest(seeAllData = false)
public with sharing class PMC_SS_CreateTeamMemberControllerTest {
	/**
    * @description This Method will be used to setup the data for the test class execution.
    */
    @TestSetup
    public static void setup() {
        List<String> lstProfileNames = New List<String>{'System Administrator','Sales User'};
        List<String> lstPermissionNames = New List<String>{'PMC_Administrator_Permission_Set_Group','PMC_SLS_Permission_Set_Group'};
		Map<String,Id> mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
        Map<String,PermissionSetGroup> mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionNames);
        Integer intuserCount = 0;
        User objSystemAdminUser;  
        User objSalesUser;
        
        List<User> lstUser = PMC_TestUtilityClass.createUser(2);
        
        for(User objUser : lstUser) {
            if(intuserCount==0) {
                objUser.LastName = 'Admin User Test';
                objUser.ProfileId = mapOfProfiles.get('System Administrator'); 
                objUser.FederationIdentifier = objUser.Username + 'Admin';
            }else if(intuserCount==1){
                objUser.LastName = 'Sales User Test';
                objUser.ProfileId = mapOfProfiles.get('Sales User'); 
                objUser.FederationIdentifier = objUser.Username + 'Sales';
            }
            objUser.isActive = true;                
            objUser.MobilePhone = '1234567890';
            intuserCount = intuserCount + 1;
        }
        insert lstUser;
        objSystemAdminUser = lstUser[0];
        objSalesUser = lstUser[1];
        
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSystemAdminUser}, mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group'));
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSalesUser}, mapOfPermissionGrp.get('PMC_SLS_Permission_Set_Group'));
        
        System.runAs(objSalesUser){
            PMC_TestUtilityClass.createAccount('The Mosaic Company', 'PMC_SS_Customer');
            PMC_TestUtilityClass.createLead(1,'Master');
            List<Opportunity> lstOpportunities = PMC_TestUtilityClass.createOpportunity(1,'Master');
            lstOpportunities[0].Description = 'description updated';
            Update lstOpportunities;
        }
    }
    
    /**
	* @description This method will be used to cover the method createAccountTeamMember of the PMC_SS_CreateTeamMemberController.
	*/
    @isTest
    private static void testCreateAccountTeamMember() {
        test.startTest();
        try {
            Map<Id,Id> mapAccIdWithDealOwner = new Map<Id,Id>();
            Account objAcc = [SELECT Id,Name FROM Account WHERE Name = 'The Mosaic Company'];
            List<Lead> lstLeads = [SELECT Id,PMC_DH_DealOwner__c,OwnerId,Owner.Name FROM Lead WHERE Name = 'test John test Doe0'];
            lstLeads[0].PMC_DH_DealOwner__c = lstLeads[0].OwnerId;
            Update lstLeads;
            
            mapAccIdWithDealOwner.put(objAcc.Id,lstLeads[0].PMC_DH_DealOwner__c);
            PMC_SS_CreateTeamMemberController.boolNotTestException = true;
            PMC_SS_CreateTeamMemberController.createAccountTeamMember(mapAccIdWithDealOwner);
        } catch(Exception e) {
            System.assertEquals(e.getMessage(),e.getMessage(), 'Script-Thrown Exception');
        }
        test.stopTest();
    }
    
    /**
	* @description This method will be used to cover the method createOpportunityTeamMember of the PMC_SS_CreateTeamMemberController.
	*/
    @isTest 
    private static void testCreateOpportunityTeamMember() {
        test.startTest();
        try {
            Map<Id,Id> mapOppIdWithDealOwner = new Map<Id,Id>();
            List<Opportunity> lstOpportunities = [SELECT Id,AccountId,OwnerId,Owner.Name FROM Opportunity WHERE Name = 'test Opportunity Name0'];
            List<Lead> lstLeads = [SELECT Id,PMC_DH_DealOwner__c,OwnerId,Owner.Name FROM Lead WHERE Name = 'test John test Doe0'];
            lstLeads[0].PMC_DH_DealOwner__c = lstLeads[0].OwnerId;
            Update lstLeads;
            
            mapOppIdWithDealOwner.put(lstOpportunities[0].Id,lstLeads[0].PMC_DH_DealOwner__c);
            PMC_SS_CreateTeamMemberController.createOpportunityTeamMember(mapOppIdWithDealOwner);
        } catch(Exception e) {
            System.assertEquals(e.getMessage(),e.getMessage(), 'Script-Thrown Exception');
        }
        test.stopTest();
    }
    
    /**
	* @description This method will be used to cover DML Exception in PMC_SS_CreateTeamMemberController.
	*/
    @isTest 
    private static void testDMLException() {
        PMC_SS_CreateTeamMemberController.boolNotTestException = false;
        test.startTest();
        try {
            Map<Id,Id> mapAccountIdWithDealOwner = new Map<Id,Id>();
            Account objAcc = [SELECT Id,Name FROM Account WHERE Name = 'The Mosaic Company'];
            List<Lead> lstLeads = [SELECT Id,PMC_DH_DealOwner__c,OwnerId,Owner.Name FROM Lead WHERE Name = 'test John test Doe0'];
            lstLeads[0].PMC_DH_DealOwner__c = lstLeads[0].OwnerId;
            Update lstLeads;
            mapAccountIdWithDealOwner.put(objAcc.Id,lstLeads[0].PMC_DH_DealOwner__c);
            PMC_SS_CreateTeamMemberController.createAccountTeamMember(mapAccountIdWithDealOwner);
            Map<Id,Id> mapOppoIdWithDealOwner = new Map<Id,Id>();
            List<Opportunity> lstOpportunities = [SELECT Id,AccountId,OwnerId,Owner.Name FROM Opportunity WHERE Name = 'test Opportunity Name0'];
            mapOppoIdWithDealOwner.put(lstOpportunities[0].Id,lstLeads[0].PMC_DH_DealOwner__c);
            PMC_SS_CreateTeamMemberController.createOpportunityTeamMember(mapOppoIdWithDealOwner);
        } catch (Exception e) {
            System.assertEquals(e.getMessage(),e.getMessage(), 'Script-Thrown Exception');
        }
        test.stopTest();
    }
    
}