/**
* @description This class will be used call PMC_SS_UpdateAccountStatusBatch and used to update Accounts
* @author Vaishnavi
* @storynumber GDASF-
*/
public without sharing class PMC_SS_UpdateAccountStatusSchedule implements Schedulable{
    /**
    * @description This Method will be used to update Accounts
    * @param objScheduleContext - this object is used to track batch process 
    */
    public void execute(SchedulableContext objScheduleContext) {
       PMC_SS_UpdateAccountStatusBatch objBatch = new PMC_SS_UpdateAccountStatusBatch(); 
       Database.executeBatch(objBatch,200);
    }
}