/**
 * @description This class is used to create get the current environment in which the instance is running
 * i.e : Sandbox/Production
 * @author Chetna
 * @storynumber GDASF-15052
 * @TestClass PMC_SS_ScheduleOrderControllerTest
 */
public with sharing class PMC_SS_ScheduleOrderController {
     /**
    * @description This method is called from pmc_ss_scheduleOrderLWC component
    * @author Chetna
    * @return Boolean returns whether org is Sandbox or not
    */
    @AuraEnabled(cacheable=true) 
    public static Boolean checkSandbox() {
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
     }
}