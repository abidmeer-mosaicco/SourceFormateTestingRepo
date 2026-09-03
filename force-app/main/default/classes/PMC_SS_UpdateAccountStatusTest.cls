/**
* @description This test class will be used to cover all the methods of PMC_SS_UpdateAccountStatusBatch.
* @author Nandini Dey
* @storynumber GDASF-7245, GDASF-1122
*/

@isTest(seeAllData = false)
private with sharing class PMC_SS_UpdateAccountStatusTest {

    /**
    * @description This Method will be used to setup the data for the test class execution.
    */
    @TestSetup
    public static void testUpdateAccountStatusDataSetup() {
     
        List<Account> lstAccountsToUpdate = new List<Account>();
        
        User loggedInUser = [Select Id from User where Id=:UserInfo.getUserId()];
            Datetime today = System.now();
            Datetime pastOneYear = today.addDays(-368);
            Datetime pastTwoYears = today.addDays(-735);
        
        System.runAs(loggedInUser){

            Account objAccountActive = PMC_TestUtilityClass.createAccount('Test Active Account', 'PMC_SS_Customer');
            objAccountActive.PMC_SS_LastInteractionDate__c = pastOneYear;
            objAccountActive.PMC_DH_Account_Status__c = 'Active';
            lstAccountsToUpdate.add(objAccountActive);
            Account objAccountInactive = PMC_TestUtilityClass.createAccount('Test Inactive Account', 'PMC_SS_Customer');
            objAccountInactive.PMC_SS_LastInteractionDate__c = pastTwoYears;
            objAccountInactive.PMC_DH_Account_Status__c = 'Inactive';
            lstAccountsToUpdate.add(objAccountInactive);
            Database.upsert(lstAccountsToUpdate); 
            
        }
    }

    @isTest
    private static void testUpdateAccountStatusSchedule() {
		test.startTest();
        system.runAs(new User (Id = UserInfo.getUserId())){
            Id permissionSetId = [SELECT Id FROM PermissionSet 
                                 WHERE Name = 'PMC_CREAccount' limit 1].Id;
        	insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permissionSetId); 
        }
        
         system.runAs(new User (Id = UserInfo.getUserId())){
			PMC_SS_UpdateAccountStatusSchedule objScheduler = new PMC_SS_UpdateAccountStatusSchedule();
        	String sch = '0 0 23 * * ?';
        	System.schedule('Update Account Status Schedule', sch, objScheduler );
            Account activeAcc = [SELECT Id, Name, PMC_DH_Account_Status__c, PMC_SS_LastInteractionDate__c FROM Account WHERE Name = 'Test Active Account' WITH SECURITY_ENFORCED];
            System.assertEquals('Active', activeAcc.PMC_DH_Account_Status__c, 'Active status updated for Account');
            Account inactiveAcc = [SELECT Id, Name, PMC_DH_Account_Status__c, PMC_SS_LastInteractionDate__c FROM Account WHERE Name = 'Test Inactive Account' WITH SECURITY_ENFORCED];
            System.assertEquals('Inactive', inactiveAcc.PMC_DH_Account_Status__c, 'Inactive status updated for Account');
            }
        test.stopTest();      
    }
}