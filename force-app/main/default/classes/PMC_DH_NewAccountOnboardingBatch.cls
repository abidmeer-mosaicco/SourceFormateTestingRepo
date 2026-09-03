/**
 * @description       : Batch Class for Product Onboarding
 * @created on        : 11-16-2023 
 * @author            : Rohan Undale
 * @last modified on  : 
 * @last modified by  : 
**/
public with sharing class PMC_DH_NewAccountOnboardingBatch implements Database.Batchable<sObject>, Schedulable {

    //private static final String DELIMITER = '-';
    private static final Set<String> SETSALESAREADIVISION = new Set<String>{'10'};
    public List<BuyerAccount> buyerAccountList = new List<BuyerAccount>();
    public Set<Id> accountIdSet = new  Set<Id>();
    public Set<Id> setSalesArea = new Set<Id>();
    public Map<Id, Set<Id>> mapAccountSalesArea = new Map<Id, Set<Id>> ();
    public static Map<Id, Id> mapAccountIdPolicyId = new Map<Id, Id>();
    public static Map<String, String> mapAccSFNumber = new Map<String, String>();
    public static Map<String, CommerceEntitlementPolicy> mapAccountIdExistingPolicy = new Map<String, CommerceEntitlementPolicy>();
  
    /**
    * @description Constructor method of batchable
    * @date 11-16-2023
    */
    public PMC_DH_NewAccountOnboardingBatch(){
        buyerAccountList = PMC_DH_NewAccountOnboardingBatchHelper.getBuyerAccounts();
        for(BuyerAccount ba : buyerAccountList) {
            accountIdSet.add(ba.BuyerId);
        }
        mapAccountSalesArea = PMC_DH_NewAccountOnboardingBatchHelper.getAccountIdSalesAreaMap(accountIdSet, setSalesArea);
    }
    
    /**
    * @description Start method of batchable
    * @param objBatchableContext
    * @return  Database.QueryLocator
    * @date 11-16-2023
    */
    public Database.QueryLocator start(Database.BatchableContext objBatchableContext) {
        return Database.getQueryLocator([SELECT Id, Name, PMC_CPQ_Product__c, PMC_CPQ_Sales_Area__c, PMC_CPQ_Product__r.StockKeepingUnit
                                         FROM PMC_CPQ_ProductSalesArea__c
                                         WHERE PMC_CPQ_Sales_Area__c IN :setSalesArea  
                                         AND PMC_CPQ_Sales_Area__r.PMC_SS_Division__c IN :SETSALESAREADIVISION
                                         WITH USER_MODE]); 
    }
    
    /**
    * @description execute method of batchable
    * @param objBatchableContext
    * @param lstProductSalesArea
    * @date 11-16-2023
    */
    public void execute(Database.BatchableContext objBatchableContext , List<PMC_CPQ_ProductSalesArea__c> lstProductSalesArea){
        PMC_DH_NewAccountOnboardingBatchHelper.processCommerceData(buyerAccountList, accountIdSet);
        PMC_DH_NewAccountOnboardingBatchHelper.executeHelper(mapAccountSalesArea, lstProductSalesArea );
    }
    
    /**
    * @description finish method of batchable
    * @param objBatchableContext
    * @date 11-16-2023
    */
    public void finish(Database.BatchableContext objBatchableContext){
        
        PMC_DH_NewAccountOnboardingBatchUtil.updateBuyerAccount(buyerAccountList);
        List<BuyerAccount> pendingBuyerAccounts = PMC_DH_NewAccountOnboardingBatchHelper.getBuyerAccounts();
        if(!pendingBuyerAccounts.isEmpty()){
            PMC_DH_Store_Configuration__mdt config = PMC_DH_Store_Configuration__mdt.getInstance('Account_Onboarding_Batch_Size');
            Database.executeBatch(new PMC_DH_NewAccountOnboardingBatch(), Integer.Valueof(config.PMC_DH_Batch_Size__c));
            
        }else{
            // here it will call the batch indexing Job
            PMC_DH_Store_Configuration__mdt config = PMC_DH_Store_Configuration__mdt.getInstance('Product_Onboarding_Batch_Size');
            if(!Test.isRunningTest()){
                Database.executeBatch(new PMC_DH_ProductOnboardingBatch(), Integer.Valueof(config.PMC_DH_Batch_Size__c));
            }
        }
       
    }

    /**
    * @description execute method of Schedulable
    * @param objSchedulableContext
    * @date 11-16-2023
    */
    public void execute(SchedulableContext objSchedulableContext){
        PMC_DH_Store_Configuration__mdt config = PMC_DH_Store_Configuration__mdt.getInstance('Account_Onboarding_Batch_Size');
        Database.executeBatch(new PMC_DH_NewAccountOnboardingBatch(), Integer.Valueof(config.PMC_DH_Batch_Size__c));
    }
}