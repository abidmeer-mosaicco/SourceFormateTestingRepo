/**
* @description This test class will be used to cover all the methods of PMC_SS_DeleteDuplicateLeadsBatch.
* @author Aditya R Achar
* @storynumber GDASF-7610
*/

@isTest(seeAllData = false)
private with sharing class PMC_SS_DeleteDuplicateLeadsTest {

    /**
    * @description This Method will be used to setup the data for the test class execution.
    */
    @TestSetup
    public static void testDuplicateLeadDataSetup() {
        List<Lead> lstLeadsToInsert = new List<Lead>();
        List<User> lstUser = new List<User>();
        PermissionSetGroup perSetGrpAdmin = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'PMC_Administrator_Permission_Set_Group'];
        Profile objUserProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        if(objUserProfile != null) {
            lstUser = PMC_TestUtilityClass.createUser(1);
            if(lstUser != null && !lstUser.isEmpty()) {
                lstUser[0].ProfileId = objUserProfile.Id;
                lstUser[0].LastName = 'Admin User Test';
                lstUser[0].isActive = true;
            }
            Database.upsert(lstUser) ;
            PMC_TestUtilityClass.assignPermissionSetGroupToUsers(lstUser, perSetGrpAdmin);
        }
        User objSystemAdminUser = lstUser[0];
        System.runAs(objSystemAdminUser){
            lstLeadsToInsert = PMC_TestUtilityClass.createLead(50,'Lead');
            for (Integer intDuplicateLeadCounter = 0; intDuplicateLeadCounter < 15; intDuplicateLeadCounter++) {
                lstLeadsToInsert[intDuplicateLeadCounter].PMC_SS_IsDuplicate__c = true;               
            }
            Database.upsert(lstLeadsToInsert); 
        }
    }

    @isTest
    private static void testDeleteDuplicateLeadsSchedule() {		
        Test.startTest();
        User objAdminUser = [SELECT Id, Name FROM User WHERE Lastname = 'Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        if(objAdminUser != NULL) {
            System.runAs(objAdminUser) {
                PMC_SS_DeleteDuplicateLeadsSchedule objScheduler = new PMC_SS_DeleteDuplicateLeadsSchedule();
        		String sch = '0 0 23 * * ?';
        		System.schedule('Delete Duplicate Leads Schedule', sch, objScheduler );
                
                System.assertNotEquals(0,[SELECT count() FROM Lead WHERE PMC_SS_IsDuplicate__c = true], 'Duplicate lead records exists');
            }
        }
        Test.stopTest();
	}
}