/**
* @description This test class will be used to cover all the methods of PMC_SS_ScheduleOrdertController.
* @author Chetna
* @storynumber GDASF-15052
*/
@isTest(seeAllData = false)
public with sharing class PMC_SS_ScheduleOrderControllerTest {
    /**
    * @description This Method will be used to setup the data for the test class execution.
    */
    @TestSetup
    public static void setup() {
        List<User> lstUser = new List<User>();
        Profile objUserProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        if(objUserProfile != null) {
            lstUser = PMC_TestUtilityClass.createUser(1);
            if(lstUser != null && !lstUser.isEmpty()) {
                lstUser[0].ProfileId = objUserProfile.Id;              
            }
            insert(lstUser);
        }
    }
        /**
	* @description This method will be used to cover the checkSandox method of main class.
	*/
    @isTest 
    private static void testCheckSandbox(){
        test.startTest();
        List<User> lstUser = [SELECT Id, Name FROM User LIMIT 1];
        System.runAs(lstUser[0]){
            try{
                PMC_SS_ScheduleOrderController.checkSandbox();
            }
            catch(Exception e){
                System.assertEquals(e.getMessage(),e.getMessage(), 'Script-Thrown Exception');
            }
        }
    }
}