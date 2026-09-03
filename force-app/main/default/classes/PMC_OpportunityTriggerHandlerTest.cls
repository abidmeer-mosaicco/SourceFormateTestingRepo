/**
 * @description This test class will be used to cover all the methods of PMC_OpportunityTriggerHandler and PMC_OpportunityTriggerHelper.
 * @author Nandini Dey
 * @storynumber GDASF-2588
 */

@isTest(seeAllData = false)
private with sharing class PMC_OpportunityTriggerHandlerTest {
    /**
    * @description This Method will be used to setup the data for the test class execution.
    */
    @testsetup
    private static void setup() {
        List<String> lstProfileNames = New List<String>{'System Administrator','Sales User'};
        List<String> lstPermissionNames = New List<String>{'PMC_Administrator_Permission_Set_Group','PMC_SLS_Permission_Set_Group'};
                
        Map<String,Id> mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
        Map<String,PermissionSetGroup> mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionNames);
        
        List<Profile> lstAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        List<Account> lstAccounts = new List<Account>();
        Account objAccount;
        
        UserRole objAdminUserRole = [SELECT Id FROM UserRole WHERE Name = 'Admin' LIMIT 1];
        List<User> lstUser;
        if(lstAdminProfile != null && !lstAdminProfile.isEmpty()) {
            lstUser = PMC_TestUtilityClass.createUser(1);
            if(lstUser != null && !lstUser.isEmpty()) {
                lstUser[0].LastName = 'Admin User Test';
                lstUser[0].ProfileId = mapOfProfiles.get('System Administrator');
                lstUser[0].userRoleId = objAdminUserRole.Id;
                lstUser[0].isActive = true;
            }
            insert lstUser;
        }
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{lstUser[0]}, mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group'));
        System.runAs(lstUser[0]){
            PMC_OpportunityTriggerHandlerTest.portalUserSetup();
        }
        
        System.runAs(lstUser[0]){
            for(Integer intAccountCount = 0; intAccountCount < 3; intAccountCount++) {
                objAccount = new Account();
                objAccount = PMC_TestUtilityClass.createAccount('The Mosaic Company'+intAccountCount,'PMC_SS_Prospect');
                lstAccounts.add(objAccount);
            }
            
            List<Id> lstAccountId = new List<Id>();
            for (Integer intAccountCount = 0; intAccountCount < 3; intAccountCount++) {
                lstAccounts[intAccountCount].Name = 'Account #' + intAccountCount;
                lstAccountId.add(lstAccounts[intAccountCount].Id);
            }
            update lstAccounts;
            
            List<PMC_SS_SalesArea__c> lstSalesAreas = PMC_TestUtilityClass.createSalesArea(3,'Master');
            List<Id> lstSalesAreaId = new List<Id>();
            for (Integer intSalesAreaCount = 0; intSalesAreaCount < 3; intSalesAreaCount++) {
                lstSalesAreas[intSalesAreaCount].Name = 'Sales Area #' + intSalesAreaCount;
                lstSalesAreaId.add(lstSalesAreas[intSalesAreaCount].Id);
            }
            update lstSalesAreas;
            
            PMC_TestUtilityClass.createAccountSalesAreaRelationship(lstAccounts,lstSalesAreas);
            
            List<Opportunity> lstOpportunities = PMC_TestUtilityClass.createOpportunity(3,'Master');
            
            for (Integer intOpportunityCount = 0; intOpportunityCount < 3; intOpportunityCount++) {
                lstOpportunities[intOpportunityCount].Name = 'Opportunity #' + intOpportunityCount;
                lstOpportunities[intOpportunityCount].AccountId = lstAccounts[intOpportunityCount].Id;
            }
            update lstOpportunities;
            
            PMC_TestUtilityClass.createAccountSalesAreaRelationship(lstAccounts,lstSalesAreas);
        }
    }

    /** 
     * @description This Method will be used to setup the Portal User data for the test class execution.
     */
     private static void portalUserSetup() {
         Profile objDHBuyerProfile = [SELECT Id FROM Profile WHERE Name = 'Digital Hub Buyer' LIMIT 1];
         PermissionSetGroup perSetGrpDhBuyer = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'PMC_DH_Buyer_Permission_Set_Group'];
         List<User> lstPortalUsers;
         if(objDHBuyerProfile != null) {
             lstPortalUsers = PMC_TestUtilityClass.createPortalUser(1, objDHBuyerProfile);
             PMC_TestUtilityClass.assignPermissionSetGroupToUsers(lstPortalUsers, perSetGrpDhBuyer);
         }
     }

    /** 
    * @description This method is a test method for Opportunity delete operation
    */ 
    @isTest
    private static void testOpportunityDelete() {
        test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
            Opportunity objOpportunity = [SELECT Id, Name FROM Opportunity WHERE Name='Opportunity #2' WITH SECURITY_ENFORCED LIMIT 1];
            Database.delete(objOpportunity.Id);
            test.stopTest();
            
            List<Opportunity> objDeletedOpportunity  = [SELECT Id, Name FROM Opportunity WHERE Id = :objOpportunity.Id WITH SECURITY_ENFORCED];
            System.assertEquals(0, objDeletedOpportunity.size(), 'The opportunity was not deleted');
        }
    }

    /** 
    * @description This method is a test method for Opportunity undelete operation
    */ 
    @isTest
    private static void testOpportunityUndelete() {
        test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
            Opportunity objOpportunity = [SELECT Id, Name FROM Opportunity WHERE Name='Opportunity #2' WITH SECURITY_ENFORCED LIMIT 1];
            Database.delete(objOpportunity.Id);
            Database.undelete(objOpportunity.Id);
            test.stopTest();
            
            List<Opportunity> objDeletedOpportunity  = [SELECT Id, Name FROM Opportunity WHERE Id = :objOpportunity.Id WITH SECURITY_ENFORCED];
            System.assertEquals(1, objDeletedOpportunity.size(), 'The opportunity was not restored');
        }
    }

    /** 
    * @description This method is a test method for Opportunity Analysis stage date update.
    */ 
    @isTest
    private static void testUpdateAnalysisStageDate() {
        test.startTest();
        Opportunity objOpportunity = [SELECT Id, Name, StageName FROM Opportunity WHERE Name='Opportunity #0' WITH SECURITY_ENFORCED LIMIT 1 ];
        User objUser = [SELECT Id, Name FROM User Where LastName='Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
            objOpportunity.StageName = PMC_SS_ConstantClass.OPPORTUNITY_ANALYSIS_STAGE;
            Database.update(objOpportunity, false);
            Opportunity objOpportunityUpdated = [SELECT Id, Name, StageName FROM Opportunity WHERE Name='Opportunity #0' WITH SECURITY_ENFORCED LIMIT 1];
            System.assertEquals(objOpportunity.StageName, objOpportunityUpdated.StageName, 'Stage Name Not Matched');
            test.stopTest();
        }
    }

    /**
    * @description This method is used to test the bypasses update operation of trigger 
    */
    @isTest
    private static void testBypassUpdateOperation() {
        PMC_OpportunityTriggerHandler.boolBypassTriggerLogic = true;
        test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
            Opportunity objOpportunity = [SELECT Id, Name, StageName FROM Opportunity WHERE Name='Opportunity #0' WITH SECURITY_ENFORCED LIMIT 1 ];
            objOpportunity.Name = 'Updating Opportunity';
            Update objOpportunity;
            test.stopTest();
            
            Opportunity objOpportunityUpdated = [SELECT Name FROM Opportunity WHERE Id = :objOpportunity.Id];
            System.assertEquals('Updating Opportunity', objOpportunityUpdated.Name, 'Expected Opportunity Name to be updated');
        }
    }
    
    /**
    * @description This method is used to test the bypasses deletion operation of trigger 
    */
    @isTest
    private static void testBypassDeleteOperation() {
        PMC_OpportunityTriggerHandler.boolBypassTriggerLogic = true;
        test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
            Opportunity objOpportunity = [SELECT Id, Name, StageName FROM Opportunity WHERE Name='Opportunity #0' WITH SECURITY_ENFORCED LIMIT 1 ];
            Delete objOpportunity;
            test.stopTest();
            
            List<Opportunity> lstOpportunities = [SELECT Name FROM Opportunity WHERE Id = :objOpportunity.Id];
            System.assertEquals(0, lstOpportunities.size(), 'Expected Opportunity to be deleted');
        }
    }

     /** 
     * @description This method is used to test that the type of Opportunity is Indirect Sales when a user with DH Buyer Profile Creates an Opportunity.
     */ 
     @isTest
     private static void testUpdateTypeIndirectSalesCreate() {
      
         test.startTest();
         User objDhBuyerUser = [SELECT Id, Name FROM User WHERE Profile.Name = 'Digital Hub Buyer' AND FirstName = 'Test Portal' WITH SECURITY_ENFORCED LIMIT 1];
         List<Opportunity>lstOpportunity = PMC_TestUtilityClass.createOpportunity(1,'Opportunity');
         If(!lstOpportunity.isEmpty()){
             lstOpportunity[0].OwnerId = objDhBuyerUser.Id;
             Update lstOpportunity[0];
         }

         if(objDhBuyerUser != null) {
             System.runAs(objDhBuyerUser) {
                 Opportunity objOpportunityInserted = [SELECT Id, Name, Type FROM Opportunity WHERE Name = 'test Opportunity Name0' WITH SECURITY_ENFORCED LIMIT 1];
                 System.assertEquals(PMC_SS_ConstantClass.OPPORTUNITY_TYPE_INDIRECT_SALES, objOpportunityInserted.Type, 'Type is Indirect Sales when DH Buyer Profile user creates an opportunity');
             }
         }
         test.stopTest();
     }
     
     /** 
     * @description This method is a test method for Opportunity type update to Indirect Sales when Owner is a retailer(Update case)
     */ 
     @isTest
     private static void testUpdateTypeIndirectSales() {
         
         test.startTest();
         User objUser = [SELECT Id, Name FROM User Where LastName='Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
         Opportunity objOpportunity = [SELECT Id, Name, Type FROM Opportunity WHERE Name='Opportunity #0' WITH SECURITY_ENFORCED LIMIT 1 ];
         User objDhBuyerUser = [SELECT Id, Name FROM User WHERE Profile.Name = 'Digital Hub Buyer' AND FirstName = 'Test Portal' WITH SECURITY_ENFORCED LIMIT 1];
         if(objUser != null && objOpportunity != null) {
             System.runAs(objUser) {
                 objOpportunity.OwnerId = objDhBuyerUser.Id;
                 Database.update(objOpportunity, false);
                 Opportunity objOpportunityUpdated = [SELECT Id, Name, Type FROM Opportunity WHERE Name='Opportunity #0' WITH SECURITY_ENFORCED LIMIT 1];
                 System.assertEquals(PMC_SS_ConstantClass.OPPORTUNITY_TYPE_INDIRECT_SALES, objOpportunityUpdated.Type, 'Type updated to Indirect Sales when Opportunity Owner is a user from DH Buyer Profile');
             }
         }
         test.stopTest();
     }
}