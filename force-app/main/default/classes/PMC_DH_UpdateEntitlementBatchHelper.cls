/**
* @description       : Batch Helper Class for Update the entitlement Policy
* @author            : Krishan Jangir
* @last modified on  : 09-14-2023
* @last modified by  : Krishan jangir
**/
public with sharing class PMC_DH_UpdateEntitlementBatchHelper {
    /**
* @description Execute helper of batchable
* @param lstEntitlementRules
* @date 2023-09-14
*/
    public static void executeHelper(List<PMC_DH_EntitlementRules__c> lstEntitlementRules){
        try{
            List<PMC_DH_EntitlementRules__c> updateEntitlemntRules = new List<PMC_DH_EntitlementRules__c>();
            Set<Id> setAllBuyerGroupIds = new Set<Id>();
            Map<Id, Set<Id>> mapBuyerGroupMembers = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> mapEntitlementBuyerGroups = new Map<Id, Set<Id>>();
            Map<Id,Set<Id>> mapAcctoEntPolicies = new Map<Id,Set<Id>>();
            Map<Id,Set<Id>> mapProdRestEntPolicies = new Map<Id, Set<Id>>();
            Map<Id,Set<Id>> mapProdEnableEntPolicies = new Map<Id, Set<Id>>();
            
            mapBuyerGroupMembers = getBuyerGroupMembersMap(lstEntitlementRules, setAllBuyerGroupIds);
            mapEntitlementBuyerGroups = getEntitlementBuyerGroupMap(setAllBuyerGroupIds);
            
            for(PMC_DH_EntitlementRules__c objEntRules : lstEntitlementRules){
                Set<Id> setAccountEntPolicies = getAccountEntPoliciesIdsSet(mapBuyerGroupMembers, mapEntitlementBuyerGroups, objEntRules);
                mapAcctoEntPolicies.put(objEntRules.PMC_DH_SoldToAccount__c, setAccountEntPolicies);
                
                if(objEntRules.PMC_DH_Type__c == 'RESTRICTED'){
                    if(!mapProdRestEntPolicies.containsKey(objEntRules.PMC_DH_Product__c)){
                        mapProdRestEntPolicies.put(objEntRules.PMC_DH_Product__c, new Set<Id>());
                    }
                    mapProdRestEntPolicies.get(objEntRules.PMC_DH_Product__c).addAll(mapAcctoEntPolicies.get(objEntRules.PMC_DH_SoldToAccount__c));
                }
                else if(objEntRules.PMC_DH_Type__c == 'ENABLED'){
                    if(!mapProdEnableEntPolicies.containsKey(objEntRules.PMC_DH_Product__c)){
                        mapProdEnableEntPolicies.put(objEntRules.PMC_DH_Product__c, new Set<Id>());
                    }
                    mapProdEnableEntPolicies.get(objEntRules.PMC_DH_Product__c).addAll(mapAcctoEntPolicies.get(objEntRules.PMC_DH_SoldToAccount__c));
                }
                objEntRules.PMC_DH_isProcessed__c= TRUE;
                updateEntitlemntRules.add(objEntRules);
            }
            
            if(Schema.sObjectType.PMC_DH_EntitlementRules__c.isUpdateable()){
                Database.update(updateEntitlemntRules, false);
            }
            insertProductEntitlementRecords(mapProdEnableEntPolicies);
            deteleEntitlementProducts(mapProdRestEntPolicies);
            
        }
        Catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /**
* @description  To get the Map Buyer and  BuyerGroup Memeber Map
* @param mapBuyerGroupMembers
* @param mapEntitlementBuyerGroups
* @param objEntRules
* @return Set<Id>
* @date 2023-09-14
*/    
    private static Set<Id> getAccountEntPoliciesIdsSet(Map<Id, Set<Id>> mapBuyerGroupMembers, Map<Id, Set<Id>> mapEntitlementBuyerGroups, PMC_DH_EntitlementRules__c objEntRules){
        Set<Id> setAccountEntPolicies = new Set<Id>();
        if(mapBuyerGroupMembers.containsKey(objEntRules.PMC_DH_SoldToAccount__c)){
            for(Id strBuyerGroupId : mapBuyerGroupMembers.get(objEntRules.PMC_DH_SoldToAccount__c)){
                if(mapEntitlementBuyerGroups.containsKey(strBuyerGroupId)){
                    setAccountEntPolicies.addAll(mapEntitlementBuyerGroups.get(strBuyerGroupId));
                }
            }
        }
        return setAccountEntPolicies;
    }
    
    /**
* @description  To get the Map Buyer and  BuyerGroup Memeber Map
* @param lstEntitlementRules
* @param setAllBuyerGroupIds
* @return Map<Id, Set<Id>>
* @date 2023-09-14
*/ 
    
    private static Map<Id,Set<Id>> getBuyerGroupMembersMap(List<PMC_DH_EntitlementRules__c> lstEntitlementRules, Set<Id> setAllBuyerGroupIds){
        Set<Id> setAccountIds = new Set<Id>();
        Map<Id, Set<Id>> mapBuyerGroupMembers = new Map<Id, Set<Id>>();
        for(PMC_DH_EntitlementRules__c objEntRule : lstEntitlementRules){
            setAccountIds.add(objEntRule.PMC_DH_SoldToAccount__c);
        }
        List<BuyerGroupMember> lstBuyerGroupMembers= [SELECT Id,Name, BuyerGroupId, BuyerId FROM BuyerGroupMember 
                                                      WHERE  BuyerId in: setAccountIds WITH SYSTEM_MODE Order BY BuyerGroupId];
        
        for(BuyerGroupMember objBuyerGroupMem : lstBuyerGroupMembers){
            if(!mapBuyerGroupMembers.containsKey(objBuyerGroupMem.BuyerId)){
                mapBuyerGroupMembers.put(objBuyerGroupMem.BuyerId, new Set<Id>());
            }
            mapBuyerGroupMembers.get(objBuyerGroupMem.BuyerId).add(objBuyerGroupMem.BuyerGroupId);
            setAllBuyerGroupIds.add(objBuyerGroupMem.BuyerGroupId);
        }
        return mapBuyerGroupMembers;
    }
    
    /**
* @description get the Entitlement and Buyer Group Map
* @param setAllBuyerGroupIds
* @return Map<Id, Set<Id>>
* @date 2023-09-14
*/
    private static  Map<Id, Set<Id>> getEntitlementBuyerGroupMap(Set<Id> setAllBuyerGroupIds){
        Map<Id, Set<Id>>  mapEntitlementBuyerGroups = new Map<Id, Set<Id>>();
        List<CommerceEntitlementBuyerGroup> lstEntitlementPolicies = [SELECT Id, Name, PolicyId, BuyerGroupId 
                                                                      FROM CommerceEntitlementBuyerGroup 
                                                                      WHERE BuyerGroupId IN:setAllBuyerGroupIds 
                                                                      WITH SYSTEM_MODE  Order BY BuyerGroupId];
        
        for(CommerceEntitlementBuyerGroup objEntitlementBuyerGroups : lstEntitlementPolicies){
            if(!mapEntitlementBuyerGroups.containsKey(objEntitlementBuyerGroups.BuyerGroupId)){
                mapEntitlementBuyerGroups.put(objEntitlementBuyerGroups.BuyerGroupId, new Set<Id>());
            }
            mapEntitlementBuyerGroups.get(objEntitlementBuyerGroups.BuyerGroupId).add(objEntitlementBuyerGroups.PolicyId);
        }
        return mapEntitlementBuyerGroups;
    }
    
    /**
* @description Insert the Product Entitlement Record
* @param mapProdEnableEntPolicies
* @date 2023-09-14
*/
    private static void insertProductEntitlementRecords(Map<Id,Set<Id>> mapProdEnableEntPolicies){
        Map<Id,Set<Id>> mapProdToExistingEntPolicies = new Map<Id,Set<Id>>();
        List<CommerceEntitlementProduct> lstCommEntProdToInsert = new List<CommerceEntitlementProduct>();
        List<CommerceEntitlementProduct> lstCommEntProd = PMC_DH_UpdateEntitlementPolicyBatch.getEntitlementRecords(mapProdEnableEntPolicies);
        
        for (CommerceEntitlementProduct objEntProd : lstCommEntProd){
            if(!mapProdToExistingEntPolicies.containsKey(objEntProd.ProductId)){
                mapProdToExistingEntPolicies.put(objEntProd.ProductId, new Set<Id>());
            }
            mapProdToExistingEntPolicies.get(objEntProd.ProductId).add(objEntProd.PolicyId);
        }
        
        
        Map<Id,Set<Id>> mapProdToNonExistingEntPolicies = new Map<Id,Set<Id>>();
        mapProdToNonExistingEntPolicies=fetchProdToNonExistingEntPoliciesMap(mapProdToExistingEntPolicies, mapProdEnableEntPolicies);
        
        
        for(String strProdId : mapProdToNonExistingEntPolicies.keySet()){
            for(String strPolicyId : mapProdToNonExistingEntPolicies.get(strProdId)){
                CommerceEntitlementProduct objCommEntProd = new CommerceEntitlementProduct();
                objCommEntProd.PolicyId = strPolicyId;
                objCommEntProd.ProductId = strProdId;
                lstCommEntProdToInsert.add(objCommEntProd);
            }
        }
        
        if( !lstCommEntProdToInsert.isEmpty() && Schema.sObjectType.CommerceEntitlementProduct.isCreateable()){
            Database.insert(lstCommEntProdToInsert, false); 
        }
        
    }
    
    /**
* @description detele Entitlement Products 
* @param mapProdToExistingEntPolicies
* @param mapProdEnableEntPolicies
* @return Map<Id,Set<Id>>
* @date 2023-09-14
*/
    private static Map<Id,Set<Id>> fetchProdToNonExistingEntPoliciesMap(Map<Id,Set<Id>> mapProdToExistingEntPolicies, Map<Id,Set<Id>> mapProdEnableEntPolicies ){
        Map<Id,Set<Id>> mapProdToNonExistingEntPolicies = new Map<Id,Set<Id>>();
        Set<Id> setExistingPolIds = new Set<Id>();
        Set<Id> setNonExistingPolIds = new Set<Id>();
        Set<Id> setDiffPolIds = new Set<Id>();
        
        for(Id strprodId : mapProdEnableEntPolicies.keySet()){
            if(mapProdToExistingEntPolicies.containsKey(strprodId)){
                setExistingPolIds = mapProdToExistingEntPolicies.get(strprodId);
                if(mapProdEnableEntPolicies.containsKey(strprodId)){
                    setNonExistingPolIds = mapProdEnableEntPolicies.get(strprodId);
                    setDiffPolIds.addAll(setNonExistingPolIds);
                    setDiffPolIds.removeAll(setExistingPolIds);                    
                }
                if(!setDiffPolIds.isEmpty()){
                    mapProdToNonExistingEntPolicies.put(strprodId, setDiffPolIds); 
                }
            }
            else{
                mapProdToNonExistingEntPolicies.put(strprodId, mapProdEnableEntPolicies.get(strprodId));
            }
            
        }
        return mapProdToNonExistingEntPolicies;
    }
    
    
    
    
    /**
* @description detele Entitlement Products 
* @param mapProdRestEntPolicies
* @date 2023-09-14
*/
    private static void deteleEntitlementProducts(Map<Id,Set<Id>> mapProdRestEntPolicies ){
        List<CommerceEntitlementProduct> lstdeleteEntProds =  PMC_DH_UpdateEntitlementPolicyBatch.getEntitlementRecords(mapProdRestEntPolicies);
        if( !lstdeleteEntProds.isEmpty() && Schema.sObjectType.CommerceEntitlementProduct.isDeletable()){
            delete lstdeleteEntProds;
        }
    }
    
   
}