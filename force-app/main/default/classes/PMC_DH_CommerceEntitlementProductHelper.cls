/**
* @description This class will be used to handle all triggers operations on CommerceEntitlementProduct Object
* @author Rohan Undale
* @storynumber GDASF-14334
*/
// added with sharing
public with sharing class PMC_DH_CommerceEntitlementProductHelper {
    @testVisible
    public static Boolean boolTestSetup = false;
    private static final String DELIMITER = '-';

    /**
    * @description This method is used to check if the CommerceEntitlementProduct record is a duplicate
    * @param lstNewCommerceEntitlementProduct list of CommerceEntitlementProduct Trigger.New
    * @param mapNewCommerceEntitlementProduct map of new Ids and CommerceEntitlementProduct Trigger.newMap
    */
    public static void processRecordsForNewCommerceEntitlementProduct(List<CommerceEntitlementProduct> lstNewCommerceEntitlementProduct, Map<Id,CommerceEntitlementProduct> mapNewCommerceEntitlementProduct) {

         try{
            if(boolTestSetup==true){
                throw new queryexception('message');
            }

            List<PMC_DH_CommerceEntitlementSalesArea__c> lstCommerceEntitlementSalesArea = PMC_DH_CommerceEntitlementProductUtil.getListCommerceEntitlementSalesAreaToInsert(lstNewCommerceEntitlementProduct, mapNewCommerceEntitlementProduct);
            /*List<PMC_DH_CommerceEntitlementSalesArea__c> lstCommerceEntitlementSalesArea = new List<PMC_DH_CommerceEntitlementSalesArea__c>();
            Map<Id,Id> mapPolicyAccountId = getPolicyAccountMap(mapNewCommerceEntitlementProduct);
            Map<String,String> accountIdSAPMap = getAccountIdSAPMap(mapPolicyAccountId.Values());
            Map<Id, Set<Id>> mapProductSalesArea = getProductSalesAreaMap(lstNewCommerceEntitlementProduct);
            Set<String> setAccIdProductId = getAccountIdProductIdSet(mapPolicyAccountId.values(),  mapProductSalesArea.KeySet() );
            Map<ID, Product2> prodIdMap = new Map<ID, Product2>([SELECT Id,StockKeepingUnit FROM Product2 Where  StockKeepingUnit!=NULL AND Id IN : mapProductSalesArea.KeySet() ]);
            Map<ID, PMC_SS_SalesArea__c> salesAreaIdMap = new Map<ID, PMC_SS_SalesArea__c>([SELECT Id, PMC_CPQ_SAPSalesOrganization__c FROM PMC_SS_SalesArea__c Where PMC_CPQ_SAPSalesOrganization__c!=NULL]);
             
             
             for(CommerceEntitlementProduct cep : lstNewCommerceEntitlementProduct){
                 if(mapPolicyAccountId.ContainsKey(cep.PolicyId) && mapProductSalesArea.ContainsKey(cep.ProductId)){
                     Id accountId = mapPolicyAccountId.get(cep.PolicyId);
                     Set<Id> setSalesArea = mapProductSalesArea.get(cep.ProductId);
                     for(Id salesAreaId : setSalesArea){
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
                     }
                 }
             }*/

            if(!lstCommerceEntitlementSalesArea.isEmpty() && Schema.sObjectType.PMC_DH_CommerceEntitlementSalesArea__c.isCreateable()){
                Database.insert(lstCommerceEntitlementSalesArea, false); 
            }
         }catch(Exception objException){
             PMC_ErrorLogClass.processException(objException);
         }	
    }

    /**
    * @description get Account Id Product Id Set 
    * @author Mosaic Direct | Dev Team | 12-03-2023
    * @param lstAccId
    * @param productIdSet
    * @return Set<String> 
    **/
    public static Set<String> getAccountIdProductIdSet(List<Id> lstAccId, Set<Id> productIdSet ){
        Set<String> setAccIdProductId = new Set<String>();
        for(PMC_DH_CommerceEntitlementSalesArea__c cesa : [SELECT Id, PMC_DH_Account__c, PMC_DH_Product__c
                                                            FROM PMC_DH_CommerceEntitlementSalesArea__c
                                                            WHERE PMC_DH_Account__c IN: lstAccId AND PMC_DH_Product__c IN : productIdSet
                                                            WITH USER_MODE])
        {
            setAccIdProductId.add(cesa.PMC_DH_Account__c+''+cesa.PMC_DH_Product__c);
        }
        return setAccIdProductId;
    }
    
    /**
    * @description This method is used to check if the CommerceEntitlementProduct record is a duplicate
    * @param lstOldCommerceEntitlementProduct list of CommerceEntitlementProduct Trigger.Old
    * @param mapOldCommerceEntitlementProduct map of new Ids and CommerceEntitlementProduct Trigger.oldMap
    */
    public static void processRecordsForDeletedCommerceEntitlementProduct(List<CommerceEntitlementProduct> lstOldCommerceEntitlementProduct, Map<Id,CommerceEntitlementProduct> mapOldCommerceEntitlementProduct) {

        try{
            if(boolTestSetup==true){
                throw new queryexception('message');
            }

            List<PMC_DH_CommerceEntitlementSalesArea__c> lstCommerceEntitlementSalesArea = PMC_DH_CommerceEntitlementProductUtil.getListCommerceEntitlementSalesAreaToDelete(lstOldCommerceEntitlementProduct, mapOldCommerceEntitlementProduct);
            /*List<PMC_DH_CommerceEntitlementSalesArea__c> lstCommerceEntitlementSalesArea = new List<PMC_DH_CommerceEntitlementSalesArea__c>();
            Map<Id,Id> mapPolicyAccountId = getPolicyAccountMap(mapOldCommerceEntitlementProduct);
            Map<Id, Set<Id>> mapProductSalesArea = getProductSalesAreaMap(lstOldCommerceEntitlementProduct);
            Set<Id> setProductIds = getProductIdSet(lstOldCommerceEntitlementProduct);
            
            List<PMC_DH_CommerceEntitlementSalesArea__c> lstCommerceEntitlementSalesAreaAll = [SELECT Id, PMC_DH_Account__c, PMC_DH_Product__c, PMC_DH_SalesArea__c
                                                                                               FROM PMC_DH_CommerceEntitlementSalesArea__c
                                                                                               WHERE PMC_DH_Product__c IN :setProductIds
                                                                                               WITH SYSTEM_MODE];
            for(CommerceEntitlementProduct cep : lstOldCommerceEntitlementProduct){
                if(mapPolicyAccountId.ContainsKey(cep.PolicyId) && mapProductSalesArea.ContainsKey(cep.ProductId)){
                    Id accountId = mapPolicyAccountId.get(cep.PolicyId);
                    Set<Id> setSalesArea = mapProductSalesArea.get(cep.ProductId);
                    for(Id salesAreaId : setSalesArea){
                        CommerceEntitlementSalesAreaWrapper objCommerceEntitlementSalesAreaWrapper = new CommerceEntitlementSalesAreaWrapper();
                        objCommerceEntitlementSalesAreaWrapper.strAccountId = accountId;
                        objCommerceEntitlementSalesAreaWrapper.strProductId = cep.ProductId;
                        objCommerceEntitlementSalesAreaWrapper.strSalesAreaId = salesAreaId;
                        PMC_DH_CommerceEntitlementSalesArea__c objCommerceEntitlementSalesArea = getMatchingCommerceEntitlementSalesArea(objCommerceEntitlementSalesAreaWrapper, lstCommerceEntitlementSalesAreaAll);
                        if(String.isNotBlank(objCommerceEntitlementSalesArea.Id)){
                            lstCommerceEntitlementSalesArea.add(objCommerceEntitlementSalesArea);
                        }
                    }
                }
            }*/

            if(!lstCommerceEntitlementSalesArea.isEmpty() && Schema.sObjectType.PMC_DH_CommerceEntitlementSalesArea__c.isDeletable()){
                Database.delete(lstCommerceEntitlementSalesArea, false); 
            }
        }catch(Exception objException){
            PMC_ErrorLogClass.processException(objException);
        }	
   }
    
    /**
     * @description This method retrieves a map of Account Id to SAP Customer Number.
     * @param accountIdSet The set of Account Ids.
     * @return Map of Account Id to SAP Customer Number.
     */
    public static Map<String,String> getAccountIdSAPMap(List<Id> accountIdSet){
        Map<String,String> mapAccounIdSAP = new Map<String,String>();
        for(Account acc : [SELECT Id, PMC_SS_SAPCustomerNumber__c FROM Account Where Id IN : accountIdSet WITH SYSTEM_MODE]){
            mapAccounIdSAP.put(acc.Id, acc.PMC_SS_SAPCustomerNumber__c);
        }
        return mapAccounIdSAP;
    }

    /**
     * @description This method retrieves a map of Policy Id to Account Id.
     * @param mapNewCommerceEntitlementProduct The map of CommerceEntitlementProduct records.
     * @return Map of Policy Id to Account Id.
     */
    public static Map<Id,Id> getPolicyAccountMap(Map<Id,CommerceEntitlementProduct> mapNewCommerceEntitlementProduct){
        Map<Id,Id> mapPolicyAccountId = new Map<Id,Id>();
        List<Id> lstPolicyId = new List<Id>();
        Set<Id> setCommerceEntitlementProductIds = mapNewCommerceEntitlementProduct.keySet();
        for(Id objId : setCommerceEntitlementProductIds){
            CommerceEntitlementProduct objCommerceEntitlementProduct = mapNewCommerceEntitlementProduct.get(objId);
            lstPolicyId.add(objCommerceEntitlementProduct.policyId);
        }

        List<CommerceEntitlementBuyerGroup> lstCommerceEntitlementBuyerGroup = [SELECT PolicyId, BuyerGroupId
                                                                                FROM CommerceEntitlementBuyerGroup
                                                                                WHERE PolicyId IN :lstPolicyId
                                                                                WITH SYSTEM_MODE];
        
        List<Id> lstBuyerGroupId = new List<Id>();
        Map<Id,Id> mapBuyerGroupPolicy = new Map<Id,Id>();
        for(CommerceEntitlementBuyerGroup objCommerceEntitlementBuyerGroup : lstCommerceEntitlementBuyerGroup){
            lstBuyerGroupId.add(objCommerceEntitlementBuyerGroup.BuyerGroupId);
            mapBuyerGroupPolicy.put(objCommerceEntitlementBuyerGroup.BuyerGroupId, objCommerceEntitlementBuyerGroup.PolicyId);
        }

        List<BuyerGroupMember> lstBuyerGroupMember = [SELECT Id, BuyerId, BuyerGroupId 
                                                      FROM BuyerGroupMember
                                                      WHERE BuyerGroupId IN :lstBuyerGroupId
                                                      WITH SYSTEM_MODE];
                            
        Map<Id,Set<Id>> mapBuyerGroupBuyer = new Map<Id,Set<Id>>();
        for(BuyerGroupMember objBuyerGroupMember : lstBuyerGroupMember){
            if(!mapBuyerGroupBuyer.containsKey(objBuyerGroupMember.BuyerGroupId)){
                mapBuyerGroupBuyer.put(objBuyerGroupMember.BuyerGroupId, new Set<Id>());
            }
            mapBuyerGroupBuyer.get(objBuyerGroupMember.BuyerGroupId).add(objBuyerGroupMember.BuyerId);
        }

        Set<Id> setBuyerGroupId = mapBuyerGroupPolicy.keySet();
        for(Id objId : setBuyerGroupId){
            Set<Id> setAccountIds = mapBuyerGroupBuyer.get(objId);
            for(Id accId : setAccountIds){
                mapPolicyAccountId.put(mapBuyerGroupPolicy.get(objId), accId);
            }
        }
        return mapPolicyAccountId;
   }

    /**
     * @description This method retrieves a map of Product Id to Sales Area Ids.
     * @param lstNewCommerceEntitlementProduct The list of CommerceEntitlementProduct records.
     * @param setSalesArea set of Sales Area Records Id
     * @return Map of Product Id to Sales Area Ids.
     */
    public static Map<Id,Set<Id>> getProductSalesAreaMap(List<CommerceEntitlementProduct> lstNewCommerceEntitlementProduct, Set<Id> setSalesArea){
        Set<Id> setProductIds = getProductIdSet(lstNewCommerceEntitlementProduct);

       List<PMC_CPQ_ProductSalesArea__c> lstProductSalesArea = [SELECT Id, Name, PMC_CPQ_Product__c,PMC_CPQ_Product__r.StockKeepingUnit,
                                                                PMC_CPQ_Sales_Area__c FROM PMC_CPQ_ProductSalesArea__c
                                                                WHERE PMC_CPQ_Product__c IN :setProductIds AND  PMC_CPQ_Sales_Area__c IN : setSalesArea
                                                                //AND PMC_CPQ_Sales_Area__r.PMC_SS_Division__c='10'
                                                                WITH SYSTEM_MODE ORDER BY PMC_CPQ_Sales_Area__r.PMC_SS_Division__c ASC];

        Map<Id, Set<Id>> mapProductSalesArea = new Map<Id, Set<Id>>();
        for(PMC_CPQ_ProductSalesArea__c psa : lstProductSalesArea){
            if(!mapProductSalesArea.containsKey(psa.PMC_CPQ_Product__c)){
                mapProductSalesArea.put(psa.PMC_CPQ_Product__c, new Set<Id>());
            }
            mapProductSalesArea.get(psa.PMC_CPQ_Product__c).add(psa.PMC_CPQ_Sales_Area__c);
        }

        return mapProductSalesArea;
   }

    /**
     * @description This method retrieves a set of Product Ids from the list of CommerceEntitlementProduct records.
     * @param lstNewCommerceEntitlementProduct The list of CommerceEntitlementProduct records.
     * @return Set of Product Ids.
     */
    public static Set<Id> getProductIdSet(List<CommerceEntitlementProduct> lstNewCommerceEntitlementProduct){
        Set<Id> setProductIds = new Set<Id>();
        for(CommerceEntitlementProduct cep : lstNewCommerceEntitlementProduct){
            setProductIds.add(cep.ProductId);
        }
        return setProductIds;
   }

    /**
     * @description This method retrieves the matching CommerceEntitlementSalesArea record.
     * @param objCommerceEntitlementSalesAreaWrapper The wrapper class for CommerceEntitlementSalesArea.
     * @param lstCommerceEntitlementSalesAreaAll The list of CommerceEntitlementSalesArea records.
     * @return PMC_DH_CommerceEntitlementSalesArea__c The matching CommerceEntitlementSalesArea record.
     */
   public static PMC_DH_CommerceEntitlementSalesArea__c getMatchingCommerceEntitlementSalesArea(CommerceEntitlementSalesAreaWrapper objCommerceEntitlementSalesAreaWrapper, List<PMC_DH_CommerceEntitlementSalesArea__c> lstCommerceEntitlementSalesAreaAll){
    PMC_DH_CommerceEntitlementSalesArea__c objCommerceEntitlementSalesArea = new PMC_DH_CommerceEntitlementSalesArea__c();
    for(PMC_DH_CommerceEntitlementSalesArea__c cesa : lstCommerceEntitlementSalesAreaAll){
        if(cesa.PMC_DH_Account__c == objCommerceEntitlementSalesAreaWrapper.strAccountId &&
            cesa.PMC_DH_Product__c == objCommerceEntitlementSalesAreaWrapper.strProductId &&
            cesa.PMC_DH_SalesArea__c == objCommerceEntitlementSalesAreaWrapper.strSalesAreaId){
                objCommerceEntitlementSalesArea = cesa;
                break;
            }
    }
    return objCommerceEntitlementSalesArea;
   }

   /**
    * @description : Wrapper class for Commerce Entitlement Sales Area
    * @author      : Rohan
    **/
    // added with sharing
   public with sharing class CommerceEntitlementSalesAreaWrapper{
        /**
         * @description Account Id
         * @return  String 
         */
        @AuraEnabled
        public string strAccountId{get;set;}

        /**
         * @description Product Id
         * @return  String 
         */
        @AuraEnabled
        public string strProductId{get;set;}

        /**
         * @description Sales Area Id
         * @return  String 
         */
        @AuraEnabled
        public string strSalesAreaId{get;set;}
   }
}