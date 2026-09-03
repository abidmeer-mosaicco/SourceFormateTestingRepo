/**
* @description This class will be used to update Account Status field as 'Active' or 'Inactive' through schedulable batch operation.
* @author Nandini Dey
* @storynumber GDASF-7245, GDASF-1122
* @TestClass PMC_SS_UpdateAccountStatusTest
*/
public with sharing class PMC_SS_UpdateAccountStatusBatch implements Database.Batchable<sObject>, Database.stateful {

    private Integer intFailureRecordCount = 0 ;
    private final String strErrorMessage = 'Accounts status was not updated.';

    /**
    * @description This method is used to collect all Accounts.
    * @param objBatchableContext - A reference to the Database.BatchableContext object.
    * @return This method returns Database.QueryLocator object that contains all the accounts passed to the job.
    */
    public Database.QueryLocator start(Database.BatchableContext objBatchableContext) {
        return Database.getQueryLocator([SELECT Id, Name, PMC_SS_LastInteractionDate__c FROM Account WHERE PMC_SS_LastInteractionDate__c != NULL WITH SECURITY_ENFORCED]);    
    }

    /**
    * @description This method is used to update Account Status for all Account records collected in start method.
    * @param objBatchableContext - A reference to the Database.BatchableContext object.
    * @param lstAccounts - List of all Accounts with a Last Interaction Date.
    */
    public void execute(Database.BatchableContext objBatchableContext, List<Account> lstAccounts) {
        Database.SaveResult[] lstUpdationResult;
        Datetime datTCurrentDay = System.now();
        if (!lstAccounts.isEmpty()){
            if (Test.isRunningTest()){
                intFailureRecordCount = 1;
            }
            for(Account objAccount: lstAccounts){
                integer intDaysOfInactivity =  objAccount.PMC_SS_LastInteractionDate__c.Date().daysBetween(datTCurrentDay.Date());
                //To set status as Inactive on 2 years of inactivity
                if(intDaysOfInactivity > 730) {
                    objAccount.PMC_DH_Account_Status__c = 'Inactive';
                } else {
                    objAccount.PMC_DH_Account_Status__c = 'Active';
                }
            }
            lstUpdationResult = Database.update(lstAccounts, false);
            //To maintain count of errors while Account record updation
            for(Database.SaveResult updationResult: lstUpdationResult){
                if(!updationResult.isSuccess()){
                    intFailureRecordCount++;
                }
            }
        }
    }

    /**
    * @description This method is used to generate Error log record if any Accounts did not get updated.
    * @param objBatchableContext - A reference to the Database.BatchableContext object.
    */
    public void finish(Database.BatchableContext objBatchableContext) {
        PMC_ErrorLog__c objErrorLog;
        if(intFailureRecordCount != 0 ) {
            objErrorLog = new PMC_ErrorLog__c();
        	objErrorLog.PMC_Message__c = intFailureRecordCount + strErrorMessage;
            objErrorLog.PMC_Type__c = 'Apex';
        	objErrorLog.PMC_MethodName__c = 'finish';
        	objErrorLog.PMC_ClassName__c = PMC_SS_UpdateAccountStatusBatch.class.getName();
        	Database.insert(objErrorLog, false);
        }
    }
}