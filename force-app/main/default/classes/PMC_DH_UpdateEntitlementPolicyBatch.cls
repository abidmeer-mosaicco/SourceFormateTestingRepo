/**
 * @description       : Batch Class for Update the entitlement Policy
 * @author            : Krishan Jangir
 * @last modified on  : 11-22-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class PMC_DH_UpdateEntitlementPolicyBatch implements Database.Batchable<sObject>,Schedulable {
    /**
    * @description Start method of batchable
    * @param objBatchableContext
    * @return  Database.QueryLocator 
    * @date 2023-09-13
    */
    public Database.QueryLocator start(Database.BatchableContext objBatchableContext) {
        return Database.getQueryLocator(
            [SELECT Id, Name,CreatedDate, PMC_DH_SoldToAccount__c, PMC_DH_Product__c, 
             PMC_DH_isActive__c, PMC_DH_isProcessed__c, Error_Log__c, PMC_DH_Type__c FROM PMC_DH_EntitlementRules__c 
             WHERE PMC_DH_Product__c!=NULL AND PMC_DH_isActive__c=TRUE AND PMC_DH_isProcessed__c=FALSE
             WITH SYSTEM_MODE ORDER BY PMC_DH_SoldToAccount__c ASC
            ]);                
    }
    /**
    * @description execute method of batchable
    * @param objBatchableContext
    * @param lstEntitlementRules
    * @date 2023-09-13
    */
    public void execute(Database.BatchableContext objBatchableContext , List<PMC_DH_EntitlementRules__c> lstEntitlementRules){
         PMC_DH_UpdateEntitlementBatchHelper.executeHelper(lstEntitlementRules);
    }
    /**
    * @description finish method of batchable
    * @param objBatchableContext
    * @date 2023-09-13
    */
    public void finish(Database.BatchableContext objBatchableContext){
        // here it will call the batch indexing Job
        Database.executeBatch(new PMC_DH_SearchIndexBatchClass());
    }
    /**
    * @description execute method of Schedulable
    * @param objSchedulableContext
    * @date 2023-09-13
    */
    public void execute(SchedulableContext objSchedulableContext){
        PMC_DH_Store_Configuration__mdt config = PMC_DH_Store_Configuration__mdt.getInstance('Batch_Size');
        Database.executeBatch(new PMC_DH_UpdateEntitlementPolicyBatch(), Integer.Valueof(config.PMC_DH_Batch_Size__c));
    }

      /**
* @description get Commerece Entitlement Products for Delete / Existing Commerece Entitlement Products from Enablement
* @param mapProdEntPolicies
* @return List<CommerceEntitlementProduct>
* @date 2023-09-14
*/
public static List<CommerceEntitlementProduct> getEntitlementRecords(Map<Id,Set<Id>> mapProdEntPolicies){
    List<CommerceEntitlementProduct> lstEntProds = new  List<CommerceEntitlementProduct>();
    if(!mapProdEntPolicies.isEmpty()){
       String strQuery='SELECT Id, PolicyId, ProductId FROM CommerceEntitlementProduct Where';
        for(Id prodId : mapProdEntPolicies.KeySet()){
            for(Id policyId : mapProdEntPolicies.get(prodId)){
                //added escape single quote('')
                 strQuery+=' (PolicyId = \''+String.escapeSingleQuotes(policyId) +'\' AND ProductId = \''+String.escapeSingleQuotes(prodId) +'\') OR';
            }
        }
        String finalstrQuery=strQuery.removeEnd('OR') + ' WITH SYSTEM_MODE';
        lstEntProds = Database.query(finalstrQuery);
    }
    return lstEntProds;
}
}