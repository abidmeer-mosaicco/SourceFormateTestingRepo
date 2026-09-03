/**
 * @description This test class will be used to cover all the methods of PMC_SS_AllocationTriggerHandler and PMC_SS_AllocationTriggerHelper.
 * @author Aravind Chaganti
 * @storynumber GDASF-16609
 */
@isTest(seeAllData = false)
private with sharing class PMC_SS_AllocationTriggerHandlerTest {
    /**
    * @description This Method will be used to setup the data for the test class execution.
    */
    @testsetup
    private static void setup() {
        
        List<String>lstProfileNames = New List<String>{'System Administrator','API Only profile','Sales User'};
        List<String>lstPermissionNames = New List<String>{'PMC_Administrator_Permission_Set_Group','PMC_CPQ_IntegrationUserPermissionSetGroup','PMC_SLS_Permission_Set_Group'};
     	Id allocationPermissionSetId=[SELECT ID FROM PermissionSet WHERE Name='PMC_SS_CREAllocations'].ID;
        Map<String,Id>mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
        Map<String,PermissionSetGroup>mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionNames);
        Integer intuserCount =0;
        User objSystemAdminUser;  
        User objIntegrationUser;
        User objSalesUser;
        List<User> lstUsers = PMC_TestUtilityClass.createUser(3);
            for(User objUser : lstUsers) {
                If(intuserCount==0){
                   objUser.LastName = 'Admin User Test';
                   objUser.ProfileId = mapOfProfiles.get('System Administrator');
                }else if(intuserCount==1){
                    objUser.LastName = 'Integration User Test';
                    objUser.ProfileId = mapOfProfiles.get('API Only profile');
                }
                else if(intuserCount==2){
                    objUser.LastName = 'Sales User Test';
                    objUser.ProfileId = mapOfProfiles.get('Sales User');
                }
                objUser.isActive = true;                
                objUser.MobilePhone = '1234567890';
                intuserCount = intuserCount + 1;
            }            
            insert lstUsers;
            objSystemAdminUser = lstUsers[0];
            objIntegrationUser = lstUsers[1];
        	objSalesUser = lstUsers[2];

        system.runAs(objSystemAdminUser){
            PMC_TestUtilityClass.createLocation('LA New Orleans');
            PMC_TestUtilityClass.createProduct(1,'PMC_CPQ_NA');
            PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSystemAdminUser}, mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group'));
            PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objIntegrationUser}, mapOfPermissionGrp.get('PMC_CPQ_IntegrationUserPermissionSetGroup'));
        	PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSalesUser}, mapOfPermissionGrp.get('PMC_SLS_Permission_Set_Group'));
                PermissionSetAssignment permissionAssign=new PermissionSetAssignment();
                permissionAssign.AssigneeId=objSalesUser.Id;
                permissionAssign.permissionSetId=allocationPermissionSetId;
                insert permissionAssign;
             PermissionSetAssignment permissionAssignIntegrationUser=new PermissionSetAssignment();
                permissionAssignIntegrationUser.AssigneeId=objSystemAdminUser.Id;
                permissionAssignIntegrationUser.permissionSetId=allocationPermissionSetId;
                insert permissionAssignIntegrationUser;
            }
    }
    /**
     * @description This Method will be used to the test class execution for allocation create.
     */
    @isTest
    private static void testAllocationCreate() {

        List<Product2> lstProducts = new List<Product2>();
        List<Schema.Location> lstLocations;
        
        User objAdminUser = [SELECT Id, Name FROM User WHERE Lastname = 'Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        system.runAs(objAdminUser){
            lstProducts=[SELECT ID FROM PRODUCT2 ];
            lstLocations=[SELECT ID FROM Location];
            test.startTest();
            List<PMC_SS_Allocation__c> lstAllocations=PMC_TestUtilityClass.createAllocation(1,lstProducts[0].Id,lstLocations[0].Id);
            insert lstAllocations;
            test.stopTest();
            List<PMC_SS_Allocation__c> lstAllocation= [SELECT ID,PMC_SS_AllocationSummary__c FROM PMC_SS_Allocation__c];
            System.assertEquals(1, lstAllocation.size(), 'The Allocation Summary record is record created');
        }
        
    }
    /**
     * @description This Method will be used to the test class execution for creation of 2 Allocation records.
     */
    @isTest
    private static void testSecondAllocationCreate() {
        List<Product2> lstProducts = new List<Product2>();
        List<Schema.Location> lstLocations;
        
        User objAdminUser = [SELECT Id, Name FROM User WHERE Lastname = 'Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        system.runAs(objAdminUser){
            lstProducts=[SELECT ID FROM PRODUCT2 ];
            lstLocations=[SELECT ID FROM Location];
            test.startTest();
            List<PMC_SS_Allocation__c> lstAllocations=PMC_TestUtilityClass.createAllocation(2,lstProducts[0].Id,lstLocations[0].Id);
            insert lstAllocations;
            test.stopTest();
            List<PMC_SS_Allocation__c> lstAllocation= [SELECT ID,PMC_SS_AllocationSummary__c FROM PMC_SS_Allocation__c];
            System.assertEquals(2, lstAllocation.size(), 'The Allocation Summary record is record created');
        }
        
    }
    /**
     * @description This Method will be used to the test class execution for insert of Allocation record which have Allocation Summary.
     */
    @isTest
    private static void testThirdAllocationCreate() {
        List<Product2> lstProducts = new List<Product2>();
        List<Schema.Location> lstLocations;
        
        User objAdminUser = [SELECT Id, Name FROM User WHERE Lastname = 'Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        system.runAs(objAdminUser){
            lstProducts=[SELECT ID FROM PRODUCT2 ];
            lstLocations=[SELECT ID FROM Location];
            test.startTest();
            List<PMC_SS_Allocation__c> lstAllocations=PMC_TestUtilityClass.createAllocation(2,lstProducts[0].Id,lstLocations[0].Id);
            insert lstAllocations;
            List<PMC_SS_Allocation__c> lstAllocation= [SELECT ID,PMC_SS_AllocationSummary__c FROM PMC_SS_Allocation__c];
            List<PMC_SS_Allocation__c> lstNewAllocation=PMC_TestUtilityClass.createAllocation(1,lstProducts[0].Id,lstLocations[0].Id);
            lstNewAllocation[0].PMC_SS_AllocationSummary__c=lstAllocation[0].PMC_SS_AllocationSummary__c;
            insert lstNewAllocation;
            test.stopTest();
            List<PMC_SS_AllocationSummary__c> lstAllocationSummary= [SELECT ID,PMC_SS_TotalAllocationQuantity__c FROM PMC_SS_AllocationSummary__c];
            System.assertEquals(285, lstAllocationSummary[0].PMC_SS_TotalAllocationQuantity__c, 'The Allocation Summary Total Allocation Quantity is 285');
        }
        
    }
    /**
     * @description This Method will be used to the test class execution for insert of Allocation record which have Allocation Summary as a Account Manager.
     */
    @isTest
    private static void testAllocationUpdate() {
        List<Product2>lstProducts;
        List<Schema.Location> lstLocations;
        
        User objAdminUser = [SELECT Id, Name FROM User WHERE Lastname = 'Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        User objSalesUser = [SELECT Id, Name FROM User WHERE Lastname = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
   
        test.startTest();
        system.runAs(objAdminUser){
            lstProducts=[SELECT ID FROM PRODUCT2 ];
            lstLocations=[SELECT ID FROM Location];
            List<PMC_SS_Allocation__c> lstAllocations=PMC_TestUtilityClass.createAllocation(2,lstProducts[0].Id,lstLocations[0].Id);
            insert lstAllocations;
        }
        List<PMC_SS_Allocation__c> lstAllocation= [SELECT ID,PMC_SS_AllocationSummary__c,PMC_SS_AllocationSummary__r.PMC_SS_TotalAllocationQuantity__c FROM PMC_SS_Allocation__c];
        system.runAs(objSalesUser){
            List<PMC_SS_Allocation__c> lstNewAllocation=PMC_TestUtilityClass.createAllocation(1,lstProducts[0].Id,lstLocations[0].Id);
            lstNewAllocation[0].PMC_SS_AllocationSummary__c=lstAllocation[0].PMC_SS_AllocationSummary__c;
            if (lstAllocation[0].PMC_SS_AllocationSummary__c!= NULL && lstAllocation[0].PMC_SS_AllocationSummary__r.PMC_SS_TotalAllocationQuantity__c!=NULL ){
                lstNewAllocation[0].PMC_SS_AllocatedActualQuantity__c=lstAllocation[0].PMC_SS_AllocationSummary__r.PMC_SS_TotalAllocationQuantity__c+130;
            }
            Database.SaveResult[] results = Database.insert(lstNewAllocation, false);
            System.assertNotEquals(true, results[0].isSuccess(),'Allocation should not have saved');
        }
        test.stopTest();
    }
    
    /**
     * @description This method is used to test the bypasses insert operation of trigger 
     */
     @isTest
     private static void testBypassInsertOperation() {
         PMC_SS_AllocationTriggerHandler.boolBypassTriggerLogic = true;
         List<Product2> lstProducts = new List<Product2>();
         List<Schema.Location> lstLocations;
        
         User objAdminUser = [SELECT Id, Name FROM User WHERE Lastname = 'Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        system.runAs(objAdminUser){
             lstProducts=[SELECT ID FROM PRODUCT2 ];
             lstLocations=[SELECT ID FROM Location];
             test.startTest();
             List<PMC_SS_Allocation__c> lstAllocations=PMC_TestUtilityClass.createAllocation(2,lstProducts[0].Id,lstLocations[0].Id);
             insert lstAllocations;
             test.stopTest();
             System.assertEquals(100, lstAllocations[0].PMC_SS_RequestedQuantity__c, 'Expected Allocation Requested Quantity to be inserted');
         }
     }
    
    /**
     * @description This method is used to test the bypasses update operation of trigger 
     */
     @isTest
     private static void testBypassUpdateOperation() {
         PMC_SS_AllocationTriggerHandler.boolBypassTriggerLogic = true;
         List<Product2> lstProducts = new List<Product2>();
         List<Schema.Location> lstLocations;
         
         User objAdminUser = [SELECT Id, Name FROM User WHERE Lastname = 'Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        system.runAs(objAdminUser){
             lstProducts=[SELECT ID FROM PRODUCT2 ];
             lstLocations=[SELECT ID FROM Location];
             test.startTest();
             List<PMC_SS_Allocation__c> lstAllocations=PMC_TestUtilityClass.createAllocation(2,lstProducts[0].Id,lstLocations[0].Id);
             insert lstAllocations;
             lstAllocations[0].PMC_SS_RequestedQuantity__c = 105;
             Update lstAllocations;
             test.stopTest();
             List<PMC_SS_Allocation__c> lstUpdatedAllocation = [SELECT ID,PMC_SS_RequestedQuantity__c FROM PMC_SS_Allocation__c];
             System.assertEquals(105, lstUpdatedAllocation[0].PMC_SS_RequestedQuantity__c, 'Expected Allocation Requested Quantity to be updated');
         }
     }
}