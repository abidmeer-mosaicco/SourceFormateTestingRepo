/**
* @description This class will be used call PMC_SS_SalesAgreementBatchSchedule
* @author 
* @storynumber GDASF-
*/
public with sharing class PMC_SS_SalesAgreementBatchSchedule implements Schedulable {
    
     /**
    * @description  This class will be used call PMC_SS_SalesAgreementBatchSchedule
    * @param objScheduleContext - this object is used to track batch process
    */
    public void execute(SchedulableContext objScheduleContext){
        PMC_SS_SalesAgreementBatchClass batchJob = new PMC_SS_SalesAgreementBatchClass();
        Database.executeBatch(batchJob,1);
    }
}