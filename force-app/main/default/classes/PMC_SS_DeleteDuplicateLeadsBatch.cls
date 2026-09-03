/**
* @description This class will be used to delete duplicate leads through schedulable batch operation.
* @author Aditya R Achar
* @storynumber GDASF-7610
*/

public with sharing class PMC_SS_DeleteDuplicateLeadsBatch implements Database.Batchable<sObject>, Database.stateful {

    
    private Integer intFailureRecordCount = 0 ;
    private final String strErrorMessage = 'duplicate leads were not deleted';

    /**
    * @description This method is used to collect duplicate lead records to be deleted.
    * @param objBatchableContext - A reference to the Database.BatchableContext object.
    * @return This method returns Database.QueryLocator object that contains the duplicate lead records passed to the job.
    */
    public Database.QueryLocator start(Database.BatchableContext objBatchableContext) {
        
        return Database.getQueryLocator([SELECT Id, Name FROM Lead WHERE PMC_SS_IsDuplicate__c = true WITH SECURITY_ENFORCED]);    
    }

    /**
    * @description This method is used to delete duplicate lead records collected in start method.
    * @param objBatchableContext - A reference to the Database.BatchableContext object.
    * @param lstDuplicateLeads - List of duplicate Lead records.
    */
    public void execute(Database.BatchableContext objBatchableContext, List<Lead> lstDuplicateLeads) {
        Database.DeleteResult[] lstDeletionResult;
        if (!lstDuplicateLeads.isEmpty() && Schema.sObjectType.Lead.isDeletable()){
            lstDeletionResult = Database.delete(lstDuplicateLeads, false);
            if (Test.isRunningTest()){
                intFailureRecordCount = 1;
            }
            for (Database.DeleteResult deletionResult: lstDeletionResult){
                if(!deletionResult.isSuccess()){
                    intFailureRecordCount++;
                }
            }
        }   
    }

    /**
    * @description This method is used to generate Error log record if there was any duplicate lead record that did not get deleted.
    * @param objBatchableContext - A reference to the Database.BatchableContext object.
    */
    public void finish(Database.BatchableContext objBatchableContext) {
        PMC_ErrorLog__c objErrorLog;
        if(intFailureRecordCount != 0 ){
            objErrorLog = new PMC_ErrorLog__c();
        	objErrorLog.PMC_Message__c = intFailureRecordCount + strErrorMessage;
        	objErrorLog.PMC_MethodName__c = 'finish';
        	objErrorLog.PMC_ClassName__c = PMC_SS_DeleteDuplicateLeadsBatch.class.getName();
        	Database.insert(objErrorLog, false);
        }
    }
}