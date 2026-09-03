/**
* @description This class will be used call PMC_SS_DeleteDuplicateLeadsSchedule and used delete duplicate lead records 
* @author Vaishnavi
* @storynumber GDASF-
*/
public without sharing class PMC_SS_DeleteDuplicateLeadsSchedule implements Schedulable{
    /**
     * @description This method will be used call PMC_SS_DeleteDuplicateLeadsSchedule and used delete duplicate lead records
    * @param objScheduleContext - this object is used to track batch process 
    */
    public void execute(SchedulableContext objScheduleContext) {
       PMC_SS_DeleteDuplicateLeadsBatch objBatch = new PMC_SS_DeleteDuplicateLeadsBatch(); 
       Database.executeBatch(objBatch,200);
    }
}