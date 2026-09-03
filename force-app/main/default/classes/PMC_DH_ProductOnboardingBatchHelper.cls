/**
* @description       : Batch Helper Class for Product Onboarding
* @author            : Rohan Undale
* @last modified on  : 01-09-2024
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
public with sharing class PMC_DH_ProductOnboardingBatchHelper {
    private static final Set<String> SETSALESAREADIVISION = new Set<String>{'10'};
    public final static String DEFAULT_IMAGE='Default Product Image';
    /**
    * @description 
    * @author Hemant Giri Goswami | hegoswami@deloitte.com | 10-22-2023 
    * @param lstProducts 
    **/
    public static void executeHelper(List<Product2> lstProducts){
        try{
            Set<String> setProductIds = new Set<String>();
            Set<Id> setAllBuyerGroupIds = new Set<Id>();
            Map<Id, Set<Id>> mapAccountProducts = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> mapBuyerGroupMembers = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> mapEntitlementBuyerGroups = new Map<Id, Set<Id>>();
            Map<Id,Set<Id>> mapAcctoEntPolicies = new Map<Id,Set<Id>>();
            Map<Id,Set<Id>> mapProdEnableEntPolicies = new Map<Id, Set<Id>>();
            
            Schema.DescribeFieldResult fieldResultNitrogen = Product2.PMC_DH_Nitrogen__c.getDescribe();
            Map<Integer,String> mapPicklistNitrogen = PMC_DH_ProductOnboardingBatchUtil.getPicklistValueMap(fieldResultNitrogen);

            Schema.DescribeFieldResult fieldResultPhosphorous = Product2.PMC_DH_Phosphorous__c.getDescribe();
            Map<Integer,String> mapPicklistPhosphorous = PMC_DH_ProductOnboardingBatchUtil.getPicklistValueMap(fieldResultPhosphorous);

            Schema.DescribeFieldResult fieldResultPotassium = Product2.PMC_DH_Potassium__c.getDescribe();
            Map<Integer,String> mapPicklistPotassium = PMC_DH_ProductOnboardingBatchUtil.getPicklistValueMap(fieldResultPotassium);
            PMC_DH_ProductOnboardingBatchUtil.executeProductProcessing( lstProducts); //to-do have to pass list of prod with category assigned
            //system.debug('categ and media linked:');
            for(Product2 prodItem:lstProducts)
            { 
                setProductIds.add(prodItem.Id);
                prodItem.PMC_DH_isProcessed__c = true;
                prodItem.PMC_DH_Nitrogen__c = prodItem.PMC_CPQ_Nitrogen__c != NULL ? PMC_DH_ProductOnboardingBatchUtil.getMatchingPicklistValue(mapPicklistNitrogen, Integer.valueOf(prodItem.PMC_CPQ_Nitrogen__c)) : NULL;
                prodItem.PMC_DH_Phosphorous__c = prodItem.PMC_CPQ_Phosphorous__c != NULL ? PMC_DH_ProductOnboardingBatchUtil.getMatchingPicklistValue(mapPicklistPhosphorous, Integer.valueOf(prodItem.PMC_CPQ_Phosphorous__c)) : NULL;
                prodItem.PMC_DH_Potassium__c = prodItem.PMC_CPQ_Potassium__c != NULL ? PMC_DH_ProductOnboardingBatchUtil.getMatchingPicklistValue(mapPicklistPotassium, Integer.valueOf(prodItem.PMC_CPQ_Potassium__c)) : NULL;
                prodItem.PMC_DH_Micronutrients__c = PMC_DH_ProductOnboardingBatch.populateMicroNutrinents(prodItem);
                
            }

            Set<String> setAccountIds = getAccountIdSet(setProductIds, mapAccountProducts);
            mapBuyerGroupMembers = getBuyerGroupMembersMap(setAccountIds, setAllBuyerGroupIds);
            mapEntitlementBuyerGroups = getEntitlementBuyerGroupMap(setAllBuyerGroupIds);
            for(String strAccountId : setAccountIds){
                Set<Id> setAccountEntPolicies = getAccountEntPoliciesIdsSet(mapBuyerGroupMembers, mapEntitlementBuyerGroups, strAccountId);
                mapAcctoEntPolicies.put(strAccountId, setAccountEntPolicies);
            }
            mapProdEnableEntPolicies = getMapProdEnableEntPolicies(mapAcctoEntPolicies, mapAccountProducts);
            insertProductEntitlementRecords(mapProdEnableEntPolicies);

            if(Schema.sObjectType.Product2.isUpdateable()){
                Database.update(lstProducts, false);
            }
        }
        Catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
    * @description  get Account Id Set
    * @param setProductIds
    * @param mapAccountProducts
    * @return Set<String>
    * @date 2023-09-14
    */ 
    public static Set<String> getAccountIdSet(Set<String> setProductIds, Map<Id, Set<Id>> mapAccountProducts){
        List<PMC_CPQ_ProductSalesArea__c> lstProductSalesArea = [SELECT Id, Name, PMC_CPQ_Product__c, PMC_CPQ_Sales_Area__c
                                                                FROM PMC_CPQ_ProductSalesArea__c
                                                                WHERE PMC_CPQ_Product__c IN :setProductIds
                                                                AND PMC_CPQ_Sales_Area__r.PMC_SS_Division__c IN :SETSALESAREADIVISION
                                                                WITH SYSTEM_MODE];
        List<String> lstSalesArea = new List<String>();
        for(PMC_CPQ_ProductSalesArea__c psa : lstProductSalesArea){
            lstSalesArea.add(psa.PMC_CPQ_Sales_Area__c);
        }
        
        List<PMC_SS_AccountSalesAreaRelationship__c> lstAccountSalesAreaRelationship = [SELECT Id, Name, PMC_SS_Account__c, PMC_SS_SalesArea__c
                                                                                        FROM PMC_SS_AccountSalesAreaRelationship__c
                                                                                        WHERE PMC_SS_SalesArea__c IN :lstSalesArea
                                                                                        AND PMC_SS_Account__r.IsBuyer=TRUE AND PMC_SS_Account__r.Type='Sold-to' //Need review on this
                                                                                        WITH SYSTEM_MODE];
        Set<String> setAccountIds = new Set<String>();
        for(PMC_SS_AccountSalesAreaRelationship__c asar : lstAccountSalesAreaRelationship){
            setAccountIds.add(asar.PMC_SS_Account__c);
            for(PMC_CPQ_ProductSalesArea__c psa : lstProductSalesArea){
                if(asar.PMC_SS_SalesArea__c == psa.PMC_CPQ_Sales_Area__c){
                    if(!mapAccountProducts.containsKey(asar.PMC_SS_Account__c)){
                        mapAccountProducts.put(asar.PMC_SS_Account__c, new Set<Id>());
                    }
                    mapAccountProducts.get(asar.PMC_SS_Account__c).add(psa.PMC_CPQ_Product__c);
                }
            }
        }
        return setAccountIds;
    }

    /**
    * @description  To get the Map Buyer and  BuyerGroup Memeber Map
    * @param setAccountIds
    * @param setAllBuyerGroupIds
    * @return Map<Id, Set<Id>>
    * @date 2023-09-14
    */ 
    public static Map<Id,Set<Id>> getBuyerGroupMembersMap(Set<String> setAccountIds, Set<Id> setAllBuyerGroupIds){
        List<BuyerGroupMember> lstBuyerGroupMembers= [SELECT Id,Name, BuyerGroupId, BuyerId 
                                                      FROM BuyerGroupMember 
                                                      WHERE  BuyerId in: setAccountIds 
                                                      WITH SYSTEM_MODE 
                                                      ORDER BY BuyerGroupId];
        
        Map<Id, Set<Id>> mapBuyerGroupMembers = new Map<Id, Set<Id>>();
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
    public static  Map<Id, Set<Id>> getEntitlementBuyerGroupMap(Set<Id> setAllBuyerGroupIds){
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
    * @description  To get the Map Buyer and  BuyerGroup Memeber Map
    * @param mapBuyerGroupMembers
    * @param mapEntitlementBuyerGroups
    * @param strAccountId
    * @return Set<Id>
    * @date 2023-10-25
    */
    public static Set<Id> getAccountEntPoliciesIdsSet(Map<Id, Set<Id>> mapBuyerGroupMembers, Map<Id, Set<Id>> mapEntitlementBuyerGroups, String strAccountId){
        Set<Id> setAccountEntPolicies = new Set<Id>();
        if(mapBuyerGroupMembers.containsKey(strAccountId)){
            for(Id strBuyerGroupId : mapBuyerGroupMembers.get(strAccountId)){
                if(mapEntitlementBuyerGroups.containsKey(strBuyerGroupId)){
                    setAccountEntPolicies.addAll(mapEntitlementBuyerGroups.get(strBuyerGroupId));
                }
            }
        }
        return setAccountEntPolicies;
    }

    /**
    * @description  To get the Map Buyer and  BuyerGroup Memeber Map
    * @param mapAcctoEntPolicies
    * @param mapAccountProducts
    * @return Map<Id,Set<Id>>
    * @date 2023-10-25
    */
    public static Map<Id,Set<Id>> getMapProdEnableEntPolicies(Map<Id,Set<Id>> mapAcctoEntPolicies, Map<Id, Set<Id>> mapAccountProducts){
        Map<Id,Set<Id>> mapProdEnableEntPolicies = new Map<Id, Set<Id>>();
        Set<Id> setAccountIds = mapAcctoEntPolicies.keySet();
        for(String strAccountId : setAccountIds){
            Set<Id> setProductIds = mapAccountProducts.get(strAccountId);
            for(Id prodId : setProductIds){
                if(!mapProdEnableEntPolicies.containsKey(prodId)){
                    mapProdEnableEntPolicies.put(prodId, new Set<Id>());
                }
                mapProdEnableEntPolicies.get(prodId).addAll(mapAcctoEntPolicies.get(strAccountId));
            }
        }
        return mapProdEnableEntPolicies;
    }

    /**
    * @description Insert the Product Entitlement Record
    * @param mapProdEnableEntPolicies
    * @date 2023-10-25
    */
    public static void insertProductEntitlementRecords(Map<Id,Set<Id>> mapProdEnableEntPolicies){
        Map<Id,Set<Id>> mapProdToExistingEntPolicies = new Map<Id,Set<Id>>();
        List<CommerceEntitlementProduct> lstCommEntProdToInsert = new List<CommerceEntitlementProduct>();
        List<CommerceEntitlementProduct> lstCommEntProd = PMC_DH_ProductOnboardingBatchUtil.getEntitlementRecords(mapProdEnableEntPolicies);
        
        for (CommerceEntitlementProduct objEntProd : lstCommEntProd){
            if(!mapProdToExistingEntPolicies.containsKey(objEntProd.ProductId)){
                mapProdToExistingEntPolicies.put(objEntProd.ProductId, new Set<Id>());
            }
            mapProdToExistingEntPolicies.get(objEntProd.ProductId).add(objEntProd.PolicyId);
        }
        
        Map<Id,Set<Id>> mapProdToNonExistingEntPolicies = new Map<Id,Set<Id>>();
        mapProdToNonExistingEntPolicies = PMC_DH_ProductOnboardingBatchUtil.fetchProdToNonExistingEntPoliciesMap(mapProdToExistingEntPolicies, mapProdEnableEntPolicies);
        
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
    * @description getElectronicMediaId
    * @param strCategory
    * @param mapContentKey
    * @return string
    * @date 2023-10-25
    */
    public static string getElectronicMediaId(String strCategory, Map<String,String> mapContentKey){
        if(mapContentKey.containsKey(strCategory)){
            return mapContentKey.get(strCategory);
        }else{
            return mapContentKey.get(DEFAULT_IMAGE);
        }
    }

}