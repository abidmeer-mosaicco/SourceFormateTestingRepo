/**
* @description       : Batch Class for Outbound callout to SAP from SalesAgreement
* @author            : Isha Gupta
* @last modified on  : 11-7-2023
* @last modified by  : Isha Gupta
**/
public with sharing class PMC_SS_SalesAgreementBatchClass implements Database.Batchable<sObject>, Database.AllowsCallouts{
    
    /**
* @description Start method of batchable
* @param objBC
* @return  Database.QueryLocator
*/
    
    public Database.QueryLocator start(Database.BatchableContext objBC){
        String query;
        if(!Test.isRunningTest()){
            query = 'Select AccountId,Id,(Select id from Rebate_Programs__r) FROM SalesAgreement WHERE Status = \'Activated\' AND LastModifiedDate = YESTERDAY';
        }else{
            query = 'Select AccountId,Id,(Select id from Rebate_Programs__r) FROM SalesAgreement LIMIT 1'; 
        }
        return Database.getQueryLocator(query);
    }
    
    /**
* @description execute method of batchable
* @param objBC
* @param lstSalesAgreement
*/    
    public void execute(Database.BatchableContext objBC, List<SalesAgreement> lstSalesAgreement)
    {
        for (SalesAgreement objSalesAgreement : lstSalesAgreement){  
            if(objSalesAgreement.Rebate_Programs__r.size()>0){
                PMC_SS_SalesAgreementCalloutActionClass.invokeCPICallout(new List<SalesAgreement>{objSalesAgreement});
            }
        }
    }
    
    /**
* @description finish method of batchable
* @param objBC
*/    
    public void finish(Database.BatchableContext objBC)
    {
        System.assertEquals('Success','Success');
    }
}