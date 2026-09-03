/**
 * @description       : Batch Class for Delegated Account Access
 * @created on		  : 11-21-2023 
 * @author            : Rohan Undale
 * @last modified on  : 02-13-2024
 * @last modified by  : Rohan Undale
**/
public with sharing class PMC_DH_DelegatedAccountAccessBatch implements Database.Batchable<sObject> {
    /**
    * @description Start method of batchable
    * @param objBatchableContext
    * @return  Database.QueryLocator
    * @date 11-21-2023
    */
    public Database.QueryLocator start(Database.BatchableContext objBatchableContext) {
        return Database.getQueryLocator(
            [SELECT Id, AccountId, ContactId, PMC_DH_isProcessed__c
             FROM AccountContactRelation 
             WHERE Account.Type = 'Sold-to' 
             AND PMC_DH_isProcessed__c = false 
             AND ContactId in (SELECT ContactId FROM User WHERE IsActive = true)
             WITH USER_MODE]);
    }
    
    /**
    * @description execute method of batchable
    * @param objBatchableContext
    * @param lstAccountContactRelation
    * @date 11-21-2023
    */
    public void execute(Database.BatchableContext objBatchableContext , List<AccountContactRelation> lstAccountContactRelation){
        PMC_DH_DelegatedAccountAccessBatchHelper.executeHelper(lstAccountContactRelation);
    }
    
    /**
    * @description finish method of batchable
    * @param objBatchableContext
    * @date 11-21-2023
    */
    public void finish(Database.BatchableContext objBatchableContext){
        //PMC_DH_DelegatedAccountAccessBatchHelper.finishHelper();
        String jobId;
        jobId = objBatchableContext.getJobId();
    }
}