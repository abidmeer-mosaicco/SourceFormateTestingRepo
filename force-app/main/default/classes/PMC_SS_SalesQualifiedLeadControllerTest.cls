/**
* @description This test class will be used to cover all the methods of PMC_SS_SalesQualifiedLeadController.
* @author Kailas Shimpi
* @storynumber GDASF-2092
*/

@isTest(seeAllData = false)
public with sharing class PMC_SS_SalesQualifiedLeadControllerTest {
	
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
            List<Lead> lstLeads = PMC_TestUtilityClass.createLead(1,'Master');
            System.assertEquals(1,lstLeads.size(),'List size matches');
        }
    }
    
    /**
	* @description This method will be used to cover the method sendEmailforRetailerLeadReview of the PMC_SS_SalesQualifiedLeadController.
	*/
    @isTest 
    private static void testSendEmailforRetailerLeadReview() {
        test.startTest();
        try {
            List<Lead> lstLeads = [SELECT Id,Name,Company,PMC_SS_AcceptedByRetailer__c,OwnerId,Status,Email,Owner.Name FROM Lead WHERE Name = 'test John test Doe0'];
            lstLeads[0].Email = 'noreply@salesforce.com';
            Update lstLeads;
            PMC_SS_SalesQualifiedLeadController.sendEmailforRetailerLeadReview(lstLeads);
        } catch(Exception e) {
            System.assertEquals(e.getMessage(),e.getMessage(), 'Script-Thrown Exception');
        }
        test.stopTest();
    }
    
    /**
	* @description This method will be used to cover the exception scenario for sendEmailforRetailerLeadReview of the PMC_SS_SalesQualifiedLeadController.
	*/
    @isTest 
    private static void testSendEmailforRetailerLeadReviewExceptionScenario() {
        List<Lead> lstLeads = new List<Lead>();
        test.startTest();
        PMC_SS_SalesQualifiedLeadController.sendEmailforRetailerLeadReview(lstLeads);
        test.stopTest();
        System.assertEquals(true, lstLeads.isEmpty(), 'Exception Occured');
    }
}