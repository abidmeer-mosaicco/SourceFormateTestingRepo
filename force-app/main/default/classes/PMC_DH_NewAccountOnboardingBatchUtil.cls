/**
* @description       : Batch Util Class for New Account Onboarding
* @created on        : 12-24-2023
* @author            : Rohan Undale
* @last modified on  : 
* @last modified by  : 
**/
public with sharing class PMC_DH_NewAccountOnboardingBatchUtil {
    private static final String ENTITLEMENTPOLICY = 'Entitlement Policy';
    private static final String DELIMITER = '-';
    /**
    * @description create Commerce Entitlement SalesArea and Commerce Entitlement Product 
    * @author Mosaic Direct | Dev Team | 12-03-2023 
    * @param strCombinedAccIdSalesAreaId
    * @param lstProductSalesArea
    * @param setAccIdProductId 
    * @return List<CommerceEntitlementProduct>
    **/
    public static List<CommerceEntitlementProduct> createCommerceEntitlementSalesArea(String strCombinedAccIdSalesAreaId, List<PMC_CPQ_ProductSalesArea__c> lstProductSalesArea, Set<String> setAccIdProductId){
        String accId = strCombinedAccIdSalesAreaId.split(DELIMITER)[0];
        String salesAreaId = strCombinedAccIdSalesAreaId.split(DELIMITER)[1];
        List<CommerceEntitlementProduct> lstCommerceEntitlementProduct = new List<CommerceEntitlementProduct>();
        for(PMC_CPQ_ProductSalesArea__c psa : lstProductSalesArea){
            if(salesAreaId == psa.PMC_CPQ_Sales_Area__c  && !setAccIdProductId.contains(accId+''+psa.PMC_CPQ_Product__c)){
                CommerceEntitlementProduct cep = new CommerceEntitlementProduct();
                cep.PolicyId = PMC_DH_NewAccountOnboardingBatch.mapAccountIdPolicyId.get(accId);
                cep.ProductId = psa.PMC_CPQ_Product__c;
                cep.PMC_DH_SoldTo_SKU__c =  PMC_DH_NewAccountOnboardingBatch.mapAccSFNumber.get(accId) + DELIMITER +  psa.PMC_CPQ_Product__r.StockKeepingUnit;
                lstCommerceEntitlementProduct.add(cep);
                setAccIdProductId.add(accId+''+psa.PMC_CPQ_Product__c);
                //System.debug('==PMC_DH_SoldTo_SKU__c=='+cep.PMC_DH_SoldTo_SKU__c);
            }
        }

        return lstCommerceEntitlementProduct;
    }

    /**
    * @description get Account Id Product Id Set 
    * @author Mosaic Direct | Dev Team | 12-03-2023 
    * @param setAccId
    * @return Set<String> 
    **/
    public static Set<String> getAccountIdProductIdSet(Set<Id> setAccId){
        Set<String> setAccIdProductId = new Set<String>();
        for(PMC_DH_CommerceEntitlementSalesArea__c cesa : [SELECT Id, PMC_DH_Account__c, PMC_DH_Product__c
                                                            FROM PMC_DH_CommerceEntitlementSalesArea__c
                                                            WHERE PMC_DH_Account__c IN: setAccId
                                                            WITH USER_MODE])
        {
            setAccIdProductId.add(cesa.PMC_DH_Account__c+''+cesa.PMC_DH_Product__c);
        }
        return setAccIdProductId;
    }

    /**
    * @description get Account Id Product Id Set 
    * @author Mosaic Direct | Dev Team | 12-03-2023 
    * @param lstBuyerAccount
    * @return Map<Id, Id> 
    **/
    public static Map<Id, Id> getAccountIdPolicyIdMap(List<BuyerAccount> lstBuyerAccount){
        Map<Id, Id> mapAccountIdPolicyId = new Map<Id, Id>();
        Map<String, Id> mapPolicyNameAccountId = new Map<String, Id>();
        for(BuyerAccount ba : lstBuyerAccount)
        {
            mapPolicyNameAccountId.put(ENTITLEMENTPOLICY+ DELIMITER + ba.Buyer.Name + DELIMITER + ba.Buyer.AccountNumber, ba.BuyerId);
        }
        for(CommerceEntitlementPolicy cep : [SELECT Id, Name
                                            FROM CommerceEntitlementPolicy
                                            WHERE Name IN : mapPolicyNameAccountId.keySet()
                                            WITH USER_MODE])
        {
            if(mapPolicyNameAccountId.containsKey(cep.Name)){
                mapAccountIdPolicyId.put(mapPolicyNameAccountId.get(cep.Name), cep.Id);
            }
        }
        return mapAccountIdPolicyId;
    }

    /**
    * @description getAccountIdSAPnumberMap 
    * @author Mosaic Direct | Dev Team | 12-03-2023 
    * @param lstBuyerAccount
    * @return Map<String, String>
    **/
    
    public static Map<String, String> getAccountIdSAPnumberMap(List<BuyerAccount> lstBuyerAccount){
        Map<String,String> accountIdSAPNumbermap = new Map<String,String>();
        for(BuyerAccount ba : lstBuyerAccount ){
            accountIdSAPNumbermap.put(ba.BuyerId,ba.Buyer.PMC_SS_SAPCustomerNumber__c);
        }
        return accountIdSAPNumbermap;
    }

    /**
    * @description Checks for the Account to Sales Area Relationship 
    * @author Mosaic Direct | Dev Team | 12-03-2023 
    * @param lstCommerceEntitlementProductAll 
    **/
    public static void insertCommerceEntitlementProduct(List<CommerceEntitlementProduct> lstCommerceEntitlementProductAll){
        if(!lstCommerceEntitlementProductAll.isEmpty() && Schema.sObjectType.CommerceEntitlementProduct.isCreateable()){
            	Database.insert(lstCommerceEntitlementProductAll, false);
        }
    }

    /**
     * @description 
     * @author Mosaic Direct | Dev Team | 12-03-2023 
     * @param lstBuyerAccount
     **/
    public static void updateBuyerAccount(List<BuyerAccount> lstBuyerAccount){
        for(BuyerAccount objBuyerAccount : lstBuyerAccount){
            objBuyerAccount.PMC_DH_isBuyerProcessed__c = true;
        }
        if(Schema.sObjectType.BuyerAccount.isUpdateable()){
            Database.update(lstBuyerAccount, false);
        }
    }

    /**
    * @description associate the entitlement record with the buyer group
    * @author Mosaic Direct | Dev Team | 12-03-2023 
    * @param lstBuyerAccount
    * @param isFirstChunk
    * @return Map<String, CommerceEntitlementPolicy> 
    **/
    public static Map<String, CommerceEntitlementPolicy> getAccountIdExistingPolicyMap(List<BuyerAccount> lstBuyerAccount, Boolean isFirstChunk){
        Map<String, String> accountIdSAPnumberMap = getAccountIdSAPnumberMap(lstBuyerAccount);
        Map<String, CommerceEntitlementPolicy> mapAccountIdExistingPolicy = new Map<String, CommerceEntitlementPolicy>();
        for(CommerceEntitlementPolicy cep : [SELECT Id,CreatedDate,LastModifiedDate,PMC_DH_SAPCustomerNumber__c FROM CommerceEntitlementPolicy Where PMC_DH_SAPCustomerNumber__c IN : accountIdSAPnumberMap.Values() WITH SYSTEM_MODE]){
            if(isFirstChunk){
                mapAccountIdExistingPolicy.put(cep.PMC_DH_SAPCustomerNumber__c, cep);
            }else if(cep.CreatedDate != cep.LastModifiedDate){
                mapAccountIdExistingPolicy.put(cep.PMC_DH_SAPCustomerNumber__c, cep);
            }
        }
        return mapAccountIdExistingPolicy;
    }
    

   /**
    * @description associate the entitlement record with the buyer group
    * @author Mosaic Direct | Dev Team | 12-03-2023 
    * @param mapAccountIdPolicy 
    * @param results
    * @return list<String>
    **/
    /*public static list<String> getupdatedSKUIds(Map<Id, CommerceEntitlementPolicy> mapAccountIdPolicy, Database.UpsertResult[] results ){
        List<String> updatedAccIds = new List<String>();
        for(Integer i = 0; i < results.size(); i++) {
            //System.debug('=results='+results);
            //System.debug('==mapAccountIdPolicy.values()=='+mapAccountIdPolicy.values());
           if(results[i].isSuccess() &&  !results[i].isCreated()) {
               //System.debug('=results updated='+mapAccountIdPolicy.values()[i].PMC_DH_SAPCustomerNumber__c);
                updatedAccIds.add(mapAccountIdPolicy.values()[i].PMC_DH_SAPCustomerNumber__c);
            }
        }
        return updatedAccIds;
    }*/
    
}