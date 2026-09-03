/**
* @description Utility class for on PMC_DH_CommerceEntitlementProductHelper
* @author Rohan Undale
*/
public with sharing class PMC_DH_CommerceEntitlementProductUtil {
    public static final String DELIMITER = '-';
    public static Set<String> setAccIdProductId = new Set<String>();
    public static Map<String,String> accountIdSAPMap = new Map<String,String>();
    public static Map<ID, Product2> prodIdMap = new Map<ID, Product2>();
    public static Map<ID, PMC_SS_SalesArea__c> salesAreaIdMap = new Map<ID, PMC_SS_SalesArea__c>();
    /**
     * @description Retrieves the list of CommerceEntitlementSalesArea records to insert.
     * @param lstNewCommerceEntitlementProduct The list of new CommerceEntitlementProduct records.
     * @param mapNewCommerceEntitlementProduct The map of new CommerceEntitlementProduct records.
     * @return List<PMC_DH_CommerceEntitlementSalesArea__c> The list of CommerceEntitlementSalesArea records to insert.
     */
    public static List<PMC_DH_CommerceEntitlementSalesArea__c> getListCommerceEntitlementSalesAreaToInsert(List<CommerceEntitlementProduct> lstNewCommerceEntitlementProduct, Map<Id,CommerceEntitlementProduct> mapNewCommerceEntitlementProduct){
        List<PMC_DH_CommerceEntitlementSalesArea__c> lstCommerceEntitlementSalesArea = new List<PMC_DH_CommerceEntitlementSalesArea__c>();
        Map<Id,Id> mapPolicyAccountId = PMC_DH_CommerceEntitlementProductHelper.getPolicyAccountMap(mapNewCommerceEntitlementProduct);
        accountIdSAPMap = PMC_DH_CommerceEntitlementProductHelper.getAccountIdSAPMap(mapPolicyAccountId.Values());
        Set<Id> accountIdSet= new Set<Id>();
        Set<Id> salesAreaSet= new Set<Id>();
        accountIdSet.addAll(mapPolicyAccountId.Values());
        Map<Id, Set<Id>> mapAccountSalesArea = PMC_DH_NewAccountOnboardingBatchHelper.getAccountIdSalesAreaMap(accountIdSet, salesAreaSet); 
        Map<Id, Set<Id>> mapProductSalesArea = PMC_DH_CommerceEntitlementProductHelper.getProductSalesAreaMap(lstNewCommerceEntitlementProduct, salesAreaSet);
        setAccIdProductId = PMC_DH_CommerceEntitlementProductHelper.getAccountIdProductIdSet(mapPolicyAccountId.values(),  mapProductSalesArea.KeySet() );
        prodIdMap = new Map<ID, Product2>([SELECT Id,StockKeepingUnit FROM Product2 Where  StockKeepingUnit!=NULL AND Id IN : mapProductSalesArea.KeySet() ]);
        salesAreaIdMap = new Map<ID, PMC_SS_SalesArea__c>([SELECT Id, PMC_CPQ_SAPSalesOrganization__c FROM PMC_SS_SalesArea__c Where PMC_CPQ_SAPSalesOrganization__c!=NULL]);
        
        
        for(CommerceEntitlementProduct cep : lstNewCommerceEntitlementProduct){
            if(mapPolicyAccountId.ContainsKey(cep.PolicyId) && mapProductSalesArea.ContainsKey(cep.ProductId)){
                Id accountId = mapPolicyAccountId.get(cep.PolicyId);
                Set<Id> setSalesArea = mapProductSalesArea.get(cep.ProductId);
                for(Id salesAreaId : mapAccountSalesArea.get(accountId)){
                    lstCommerceEntitlementSalesArea.addAll(getCommerceEntitlementSalesAreaList(setSalesArea, accountId+ DELIMITER +salesAreaId, cep));
                }
                /*for(Id salesAreaId : setSalesArea){
                    if(!setAccIdProductId.contains(accountId+''+cep.ProductId)){
                        PMC_DH_CommerceEntitlementSalesArea__c objCommerceEntitlementSalesArea = new PMC_DH_CommerceEntitlementSalesArea__c();
                        objCommerceEntitlementSalesArea.PMC_DH_Account__c = accountId;
                        objCommerceEntitlementSalesArea.PMC_DH_Product__c = cep.ProductId;
                        objCommerceEntitlementSalesArea.PMC_DH_SalesArea__c = salesAreaId;
                        String accId =  accountIdSAPMap.containskey(accountId) ? accountIdSAPMap.get(accountId) : '';
                        String proSKU =  prodIdMap.containskey(cep.ProductId) ? prodIdMap.get(cep.ProductId).StockKeepingUnit : '';
                        String salesAreaSAPId =  salesAreaIdMap.containskey(salesAreaId) ? salesAreaIdMap.get(salesAreaId).PMC_CPQ_SAPSalesOrganization__c : '';
                        objCommerceEntitlementSalesArea.PMC_DH_SoldTo_SKU_SaleAreaId__c = accId + DELIMITER + proSKU + DELIMITER + salesAreaSAPId;
                        lstCommerceEntitlementSalesArea.add(objCommerceEntitlementSalesArea);
                        setAccIdProductId.add(accountId+''+cep.ProductId);
                    }
                }*/
            }
        }
        return lstCommerceEntitlementSalesArea;
    }

    private static List<PMC_DH_CommerceEntitlementSalesArea__c> getCommerceEntitlementSalesAreaList(Set<Id> setSalesArea, String strCombinedAccIdSalesAreaId, CommerceEntitlementProduct cep){
        String accountId = strCombinedAccIdSalesAreaId.split(DELIMITER)[0];
        String accountSalesAreaId = strCombinedAccIdSalesAreaId.split(DELIMITER)[1];
        List<PMC_DH_CommerceEntitlementSalesArea__c> lstCommerceEntitlementSalesArea = new List<PMC_DH_CommerceEntitlementSalesArea__c>();
        for(Id salesAreaId : setSalesArea){
            if( accountSalesAreaId == salesAreaId &&  !setAccIdProductId.contains(accountId+''+cep.ProductId)){
                PMC_DH_CommerceEntitlementSalesArea__c objCommerceEntitlementSalesArea = new PMC_DH_CommerceEntitlementSalesArea__c();
                objCommerceEntitlementSalesArea.PMC_DH_Account__c = accountId;
                objCommerceEntitlementSalesArea.PMC_DH_Product__c = cep.ProductId;
                objCommerceEntitlementSalesArea.PMC_DH_SalesArea__c = salesAreaId;
                String accId =  accountIdSAPMap.containskey(accountId) ? accountIdSAPMap.get(accountId) : '';
                String proSKU =  prodIdMap.containskey(cep.ProductId) ? prodIdMap.get(cep.ProductId).StockKeepingUnit : '';
                String salesAreaSAPId =  salesAreaIdMap.containskey(salesAreaId) ? salesAreaIdMap.get(salesAreaId).PMC_CPQ_SAPSalesOrganization__c : '';
                objCommerceEntitlementSalesArea.PMC_DH_SoldTo_SKU_SaleAreaId__c = accId + DELIMITER + proSKU + DELIMITER + salesAreaSAPId;
                lstCommerceEntitlementSalesArea.add(objCommerceEntitlementSalesArea);
                setAccIdProductId.add(accountId+''+cep.ProductId);
            }
        }
        return lstCommerceEntitlementSalesArea;
    }
    /**
     * @description Retrieves the list of CommerceEntitlementSalesArea records to delete.
     * @param lstOldCommerceEntitlementProduct The list of old CommerceEntitlementProduct records.
     * @param mapOldCommerceEntitlementProduct The map of old CommerceEntitlementProduct records.
     * @return List<PMC_DH_CommerceEntitlementSalesArea__c> The list of CommerceEntitlementSalesArea records to delete.
     */
    public static List<PMC_DH_CommerceEntitlementSalesArea__c> getListCommerceEntitlementSalesAreaToDelete(List<CommerceEntitlementProduct> lstOldCommerceEntitlementProduct, Map<Id,CommerceEntitlementProduct> mapOldCommerceEntitlementProduct){
        List<PMC_DH_CommerceEntitlementSalesArea__c> lstCommerceEntitlementSalesArea = new List<PMC_DH_CommerceEntitlementSalesArea__c>();
        Map<Id,Id> mapPolicyAccountId = PMC_DH_CommerceEntitlementProductHelper.getPolicyAccountMap(mapOldCommerceEntitlementProduct);
        Set<Id> accountIdSet= new Set<Id>();
        Set<Id> salesAreaSet= new Set<Id>();
        accountIdSet.addAll(mapPolicyAccountId.Values());
        PMC_DH_NewAccountOnboardingBatchHelper.getAccountIdSalesAreaMap(accountIdSet, salesAreaSet); 
        Map<Id, Set<Id>> mapProductSalesArea = PMC_DH_CommerceEntitlementProductHelper.getProductSalesAreaMap(lstOldCommerceEntitlementProduct, salesAreaSet);
        Set<Id> setProductIds = PMC_DH_CommerceEntitlementProductHelper.getProductIdSet(lstOldCommerceEntitlementProduct);
        
        List<PMC_DH_CommerceEntitlementSalesArea__c> lstCommerceEntitlementSalesAreaAll = [SELECT Id, PMC_DH_Account__c, PMC_DH_Product__c, PMC_DH_SalesArea__c
                                                                                            FROM PMC_DH_CommerceEntitlementSalesArea__c
                                                                                            WHERE PMC_DH_Product__c IN :setProductIds AND PMC_DH_Account__c IN : accountIdSet AND PMC_DH_SalesArea__c IN : salesAreaSet
                                                                                            WITH SYSTEM_MODE];
        for(CommerceEntitlementProduct cep : lstOldCommerceEntitlementProduct){
            if(mapPolicyAccountId.ContainsKey(cep.PolicyId) && mapProductSalesArea.ContainsKey(cep.ProductId)){
                Id accountId = mapPolicyAccountId.get(cep.PolicyId);
                Set<Id> setSalesArea = mapProductSalesArea.get(cep.ProductId);
                for(Id salesAreaId : setSalesArea){
                    PMC_DH_CommerceEntitlementProductHelper.CommerceEntitlementSalesAreaWrapper objCommerceEntitlementSalesAreaWrapper = new PMC_DH_CommerceEntitlementProductHelper.CommerceEntitlementSalesAreaWrapper();
                    objCommerceEntitlementSalesAreaWrapper.strAccountId = accountId;
                    objCommerceEntitlementSalesAreaWrapper.strProductId = cep.ProductId;
                    objCommerceEntitlementSalesAreaWrapper.strSalesAreaId = salesAreaId;
                    PMC_DH_CommerceEntitlementSalesArea__c objCommerceEntitlementSalesArea = PMC_DH_CommerceEntitlementProductHelper.getMatchingCommerceEntitlementSalesArea(objCommerceEntitlementSalesAreaWrapper, lstCommerceEntitlementSalesAreaAll);
                    if(String.isNotBlank(objCommerceEntitlementSalesArea.Id)){
                        lstCommerceEntitlementSalesArea.add(objCommerceEntitlementSalesArea);
                    }
                }
            }
        }
        return lstCommerceEntitlementSalesArea;
    }
}