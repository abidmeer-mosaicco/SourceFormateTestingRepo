/**
 * @description       : Batch Class to do the Seacrh index rebuild 
 * @author            : Lohitha
 * @last modified on  : 10-26-2023
 * GDASF-11858
**/
public with sharing class PMC_DH_SearchIndexBatchClass implements Database.Batchable<SObject>{
    
    /**
    * @description 
    * @author Lohitha | 10-26-2023 
    * @param objBatchableContext 
    * @return Database.QueryLocator 
    **/
    public Database.QueryLocator start(Database.BatchableContext objBatchableContext){
        return Database.getQueryLocator([SELECT Id, Name FROM Webstore WHERE Name = 'Mosaic Direct']);
        }
    /**
    * @description 
    * @author Lohitha | 10-26-2023 
    * @param objBatchableContext
    * @param  lstWebStore
    * @return: void 
    **/
    public void execute(Database.BatchableContext objBatchableContext, List<Webstore> lstWebStore){
        String strWebstoreId = lstWebStore[0].Id;
        //ConnectApi.CommerceSearchIndexBuildType indexBuildType = ConnectApi.CommerceSearchIndexBuildType.Full; 
        //result = ConnectApi.CommerceSearchSettings.createCommerceSearchIndex(strWebstoreId,ConnectApi.CommerceSearchIndexBuildType.Full);
        if(!Test.isRunningTest()){
            ConnectApi.CommerceSearchSettings.createCommerceSearchIndex(strWebstoreId);   
        }else{
           ConnectApi.CommerceSearchIndex result = new ConnectApi.CommerceSearchIndex();
            result.createdDate = system.now();
            result.completionDate = system.now();
            result.id = 'Test';
            result.isIncrementable = True;
            result.lastCatalogSnapshotTime = system.now();
        }
    }
    /**
    * @description 
    * @author Lohitha | 10-26-2023 
    * @param objBatchableContext 
    * @return: Void
    **/
    public void finish(Database.BatchableContext objBatchableContext){
        Database.executeBatch(new PMC_DH_DelegatedAccountAccessBatch());
    }
}