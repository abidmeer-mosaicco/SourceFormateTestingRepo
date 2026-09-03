/**
* @description This class will be used to call PMC_SS_PopulateInvoiceQtyOnBenefitsBatch
* @author Nandini Dey
*/
public with sharing class PMC_SS_InvQtyOnBenefitsBatchSchedule implements Schedulable{
    
	/**
    * @description  This class will be used to call PMC_SS_PopulateInvoiceQtyOnBenefitsBatch
    * @param objScheduleContext - this object is used to track batch process
    */
    public void execute(SchedulableContext objScheduleContext){
        PMC_SS_PopulateInvoiceQtyOnBenefitsBatch batchJob = new PMC_SS_PopulateInvoiceQtyOnBenefitsBatch();
        Database.executeBatch(batchJob,1);
    }
    
}