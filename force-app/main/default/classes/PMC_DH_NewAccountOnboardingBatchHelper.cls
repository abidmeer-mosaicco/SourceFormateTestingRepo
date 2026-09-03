/**
* @description       : Batch Helper Class for New Account Onboarding
* @created on        : 11-16-2023
* @author            : Rohan Undale
* @last modified on  : 12-03-2023
* @last modified by  : Mosaic Direct | Dev Team
**/
public with sharing class PMC_DH_NewAccountOnboardingBatchHelper {
    private static final String ENTITLEMENTPOLICY = 'Entitlement Policy';
    private static final String BUYERGROUP = 'Buyer Group';
    //private static final String STANDARDPRICEBOOK = 'DH Price Book';
    private static final String DELIMITER = '-';
    private static final String WEBSTORENAME = 'Mosaic Direct';
  
    /**
    * @description Execute helper method for PMC_DH_NewAccountOnboardingBatch
    * @created on 11-16-2023
    * @author Rohan Undale
    * @param mapAccountSalesArea
    * @param lstProductSalesArea 
    **/
    public static void executeHelper(Map<Id, Set<Id>> mapAccountSalesArea, List<PMC_CPQ_ProductSalesArea__c> lstProductSalesArea){
        try{
            List<CommerceEntitlementProduct> lstCommerceEntitlementProductAll = new List<CommerceEntitlementProduct>();
            //System.debug('=mapAccountIdExistingPolicy='+PMC_DH_NewAccountOnboardingBatch.mapAccountIdExistingPolicy);
            //System.debug('=mapAccSFNumber='+PMC_DH_NewAccountOnboardingBatch.mapAccSFNumber);
            Set<String> setAccIdProductId = PMC_DH_NewAccountOnboardingBatchUtil.getAccountIdProductIdSet(mapAccountSalesArea.keySet());
            for(Id accId : mapAccountSalesArea.keySet()){
                //System.debug('=accId='+PMC_DH_NewAccountOnboardingBatch.mapAccSFNumber.get(accId));
                //System.debug('=check con='+PMC_DH_NewAccountOnboardingBatch.mapAccountIdExistingPolicy.containsKey(PMC_DH_NewAccountOnboardingBatch.mapAccSFNumber.get(accId)));
                if(!PMC_DH_NewAccountOnboardingBatch.mapAccountIdExistingPolicy.containsKey(PMC_DH_NewAccountOnboardingBatch.mapAccSFNumber.get(accId))){
                    for(Id salesAreaId : mapAccountSalesArea.get(accId)){
                        lstCommerceEntitlementProductAll.addAll(PMC_DH_NewAccountOnboardingBatchUtil.createCommerceEntitlementSalesArea(accId+ DELIMITER +salesAreaId, lstProductSalesArea, setAccIdProductId));
                    }
                }
            }
            PMC_DH_NewAccountOnboardingBatchUtil.insertCommerceEntitlementProduct(lstCommerceEntitlementProductAll);
        }
        Catch(Exception ex){
            //System.debug(ex.getLineNumber()+ex.getMessage()+ex.getStackTraceString()+ex.getCause());
            throw new AuraHandledException(ex.getMessage()+ex.getStackTraceString());
        }
    }

    /**
    * @description get Account Id SalesArea Map
    * @created on 1-19-2024
    * @author Sugunakar
    * @param accountIdSet
    * @param setSalesArea 
    * @return Map<Id, Set<Id>>
    **/
    public static  Map<Id, Set<Id>> getAccountIdSalesAreaMap(Set<Id> accountIdSet, Set<Id> setSalesArea){
        Map<Id, Set<Id>> mapAccountSalesArea = new Map<Id,Set<Id>>();
        for(PMC_SS_AccountSalesAreaRelationship__c aars : [SELECT Id, Name, PMC_SS_Account__c, PMC_SS_SalesArea__c
                                                           FROM PMC_SS_AccountSalesAreaRelationship__c
                                                           WHERE PMC_SS_Account__c IN :accountIdSet
                                                           WITH USER_MODE])
        {
            if(!mapAccountSalesArea.containsKey(aars.PMC_SS_Account__c)){
                mapAccountSalesArea.put(aars.PMC_SS_Account__c, new Set<Id>());
            }
            mapAccountSalesArea.get(aars.PMC_SS_Account__c).add(aars.PMC_SS_SalesArea__c);
            setSalesArea.add(aars.PMC_SS_SalesArea__c);
        }
        return mapAccountSalesArea;
        
    }
    
    /**
    * @description process Commerce Data
    * @created on 1-19-2024
    * @author Sugunakar
    * @param lstBuyerAccount
    * @param accountIdSet
    **/
    public static void processCommerceData(List<BuyerAccount> lstBuyerAccount, Set<Id> accountIdSet){
        Set<Id> setProcessedAccounts = new Set<Id>();
        for(BuyerGroupMember bgm : [SELECT Id,BuyerId  FROM BuyerGroupMember Where BuyerId IN : accountIdSet WITH USER_MODE]){
            setProcessedAccounts.add(bgm.BuyerId);
        }
        
        List<BuyerAccount> lstBuyerAccountUnProcessed =  [SELECT Id, BuyerId, Buyer.Name, Buyer.AccountNumber, Buyer.PMC_SS_SAPCustomerNumber__c, PMC_DH_isBuyerProcessed__c
                                                          FROM BuyerAccount WHERE PMC_DH_isBuyerProcessed__c = FALSE 
                                                          AND Buyer.IsBuyer=TRUE AND Buyer.Type='Sold-To'
                                                          AND BuyerId IN : accountIdSet AND BuyerId NOT IN : setProcessedAccounts
                                                          WITH USER_MODE];
        
        if(!lstBuyerAccountUnProcessed.isEmpty()){
            Map<Id, BuyerGroup> mapAccountIdBuyerGroup = createBuyerGroupForAccount(lstBuyerAccountUnProcessed);
            createBuyerGroupMember(mapAccountIdBuyerGroup);
            createWebStoreBuyerGroup(mapAccountIdBuyerGroup);
            Map<Id, CommerceEntitlementPolicy> mapAccountIdPolicy = createPolicyForAccount(lstBuyerAccountUnProcessed);
            createCommerceEntitlementBuyerGroup(mapAccountIdBuyerGroup, mapAccountIdPolicy);
        }
        PMC_DH_NewAccountOnboardingBatch.mapAccountIdPolicyId = PMC_DH_NewAccountOnboardingBatchUtil.getAccountIdPolicyIdMap(lstBuyerAccount);
        PMC_DH_NewAccountOnboardingBatch.mapAccSFNumber =  PMC_DH_NewAccountOnboardingBatchUtil.getAccountIdSAPnumberMap(lstBuyerAccount);
        PMC_DH_NewAccountOnboardingBatch.mapAccountIdExistingPolicy = PMC_DH_NewAccountOnboardingBatchUtil.getAccountIdExistingPolicyMap(lstBuyerAccount, false);
    }
    
    /**
    * @description get Buyer Accounts
    * @created on 1-19-2024
    * @author Sugunakar 
    * @return List<BuyerAccount>
    **/
     public static List<BuyerAccount> getBuyerAccounts(){
        return [SELECT Id, BuyerId, Buyer.Name, Buyer.AccountNumber, Buyer.PMC_SS_SAPCustomerNumber__c, PMC_DH_isBuyerProcessed__c
                FROM BuyerAccount WHERE PMC_DH_isBuyerProcessed__c = FALSE 
                AND Buyer.IsBuyer=TRUE AND Buyer.Type='Sold-To'
                AND BuyerId NOT IN (SELECT BuyerId from BuyerGroupMember)  WITH USER_MODE Order By Buyer.Name ASC LIMIT 5];
    }

    /**
    * @description generate buyer group based on processing flag that are yet to be processed.
    * @author Mosaic Direct | Dev Team | 12-03-2023 
    * @param lstBuyerAccount 
    * @return Map<Id, BuyerGroup> 
    **/
    // codereview | todo: : Duplicate Check on Processed Records but are not marked in the BuyerAccount Record
    //codereview | todo: : capture the errored out records in the error logs
    private static Map<Id, BuyerGroup> createBuyerGroupForAccount(List<BuyerAccount> lstBuyerAccount){
        Map<Id, BuyerGroup> mapAccountIdBuyerGroup = new Map<Id, BuyerGroup>();
       // List<BuyerGroup> lstBuyerGroup = new list<BuyerGroup>();
       // Set<Id> lstAccountId = mapAccountToBeProcessed.keySet();
        for(BuyerAccount ba : lstBuyerAccount){
            BuyerGroup bg = new BuyerGroup();
            bg.Name = BUYERGROUP + DELIMITER + ba.Buyer.Name + DELIMITER + ba.Buyer.AccountNumber;
            bg.description = BUYERGROUP + ' for Account ' + ba.Buyer.Name + DELIMITER + ba.Buyer.AccountNumber;
           // lstBuyerGroup.add(bg);
            mapAccountIdBuyerGroup.put(ba.BuyerId, bg);
        }
        if(!mapAccountIdBuyerGroup.isEmpty() && Schema.sObjectType.BuyerGroup.isCreateable()){
            Database.insert(mapAccountIdBuyerGroup.values(), false);
        }
        return mapAccountIdBuyerGroup;
    }

    /**
    * @description generates the buyer group member from the buyer group list
    * @author Mosaic Direct | Dev Team | 12-03-2023 
    * @param mapAccountIdBuyerGroup 
    **/
    //codereview | todo:: Custom Pricebook Needs to be associated to the buyer group members
    //codereview | todo: : capture the errored out records in the error logs
    private static void createBuyerGroupMember(Map<Id, BuyerGroup> mapAccountIdBuyerGroup){
        List<BuyerGroupMember> lstBuyerGroupMember = new List<BuyerGroupMember>();
        //List<BuyerGroupPricebook> lstBuyerGroupPricebook = new List<BuyerGroupPricebook>();
        /*Pricebook2 stdPricebook = [SELECT Id, Name FROM Pricebook2
                                   WHERE Name =: STANDARDPRICEBOOK WITH USER_MODE LIMIT 1];*/
        for(Id accId : mapAccountIdBuyerGroup.keySet()){
            BuyerGroupMember bgm = new BuyerGroupMember();
            bgm.BuyerId = accId;
            bgm.BuyerGroupId = mapAccountIdBuyerGroup.get(accId).Id;
            lstBuyerGroupMember.add(bgm);
            /*BuyerGroupPricebook objBuyerGroupPricebook = new BuyerGroupPricebook();
            objBuyerGroupPricebook.BuyerGroupId = mapAccountIdBuyerGroup.get(accId).Id;
            objBuyerGroupPricebook.Pricebook2Id = stdPricebook.Id;
            objBuyerGroupPricebook.IsActive = true;
            lstBuyerGroupPricebook.add(objBuyerGroupPricebook);*/
        }
        if(!lstBuyerGroupMember.isEmpty() && Schema.sObjectType.BuyerGroupMember.isCreateable()){
            Database.insert(lstBuyerGroupMember, false);
        }
        /*if(!lstBuyerGroupPricebook.isEmpty() && Schema.sObjectType.BuyerGroupPricebook.isCreateable()){
            Database.insert(lstBuyerGroupPricebook, false);
        }*/
    }

    /**
    * @description generate entitlement policy in account 
    * @author Mosaic Direct | Dev Team | 12-03-2023 
    * @param lstBuyerAccount 
    * @return Map<Id, CommerceEntitlementPolicy> 
    **/
    //codereview | todo:: accId should be replaced by Name / Account Number 
    private static Map<Id, CommerceEntitlementPolicy> createPolicyForAccount(List<BuyerAccount> lstBuyerAccount){
        Map<Id, CommerceEntitlementPolicy> mapAccountIdPolicy = new Map<Id, CommerceEntitlementPolicy>();
        //List<String> updatedAccIds = new List<String>();
       // Map<String, String> accountIdSAPNumberMap = PMC_DH_NewAccountOnboardingBatchUtil.getAccountIdSAPnumberMap(lstBuyerAccount);
        Map<String, CommerceEntitlementPolicy> mapAccountIdExistingPolicyBefore =  PMC_DH_NewAccountOnboardingBatchUtil.getAccountIdExistingPolicyMap(lstBuyerAccount, true); 
        //List<CommerceEntitlementPolicy> lstCommerceEntitlementPolicy = new list<CommerceEntitlementPolicy>();
        for(BuyerAccount ba : lstBuyerAccount ){
            if(mapAccountIdExistingPolicyBefore.ContainsKey(ba.Buyer.PMC_SS_SAPCustomerNumber__c)){
                CommerceEntitlementPolicy objExistingCommerceEntitlementPolicy = mapAccountIdExistingPolicyBefore.get(ba.Buyer.PMC_SS_SAPCustomerNumber__c);
                objExistingCommerceEntitlementPolicy.PMC_DH_SAPCustomerNumber__c = ba.Buyer.PMC_SS_SAPCustomerNumber__c;
                mapAccountIdPolicy.put(ba.BuyerId, objExistingCommerceEntitlementPolicy);
            }else{
                CommerceEntitlementPolicy objCommerceEntitlementPolicy = new CommerceEntitlementPolicy();
                objCommerceEntitlementPolicy.Name = ENTITLEMENTPOLICY + DELIMITER + ba.Buyer.Name + DELIMITER + ba.Buyer.AccountNumber;
                objCommerceEntitlementPolicy.IsActive = true;
                objCommerceEntitlementPolicy.Description = ENTITLEMENTPOLICY + ' for Account ' + ba.Buyer.Name + DELIMITER + ba.Buyer.AccountNumber;
                objCommerceEntitlementPolicy.CanViewPrice = true;
                objCommerceEntitlementPolicy.CanViewProduct = true;
                objCommerceEntitlementPolicy.PMC_DH_SAPCustomerNumber__c = ba.Buyer.PMC_SS_SAPCustomerNumber__c;
                mapAccountIdPolicy.put(ba.BuyerId, objCommerceEntitlementPolicy);
            }
        }
        if(!mapAccountIdPolicy.isEmpty() && (Schema.sObjectType.CommerceEntitlementPolicy.isCreateable() && Schema.sObjectType.CommerceEntitlementPolicy.isUpdateable())){
             Database.upsert(mapAccountIdPolicy.values(), CommerceEntitlementPolicy.PMC_DH_SAPCustomerNumber__c);
            //updatedAccIds.addAll(PMC_DH_NewAccountOnboardingBatchUtil.getupdatedSKUIds(mapAccountIdPolicy ,results));
        }
        //PMC_DH_NewAccountOnboardingBatch.mapAccountIdExistingPolicy = PMC_DH_NewAccountOnboardingBatchUtil.getAccountIdExistingPolicyMap(updatedAccIds);
        return mapAccountIdPolicy;
    }


    /**
    * @description associate the entitlement record with the buyer group
    * @author Mosaic Direct | Dev Team | 12-03-2023 
    * @param mapAccountIdBuyerGroup 
    * @param mapAccountIdPolicy 
    **/
    //codereview | todo: capture error logs
    private static void createCommerceEntitlementBuyerGroup(Map<Id, BuyerGroup> mapAccountIdBuyerGroup, Map<Id, CommerceEntitlementPolicy> mapAccountIdPolicy){
        Map<String,String> mapAccountIdSAPNumberMap = PMC_DH_NewAccountOnboardingBatch.mapAccSFNumber;
        List<CommerceEntitlementBuyerGroup> lstCommerceEntitlementBuyerGroup = new List<CommerceEntitlementBuyerGroup>();
        for(Id accId : mapAccountIdBuyerGroup.keySet()){
            if(mapAccountIdPolicy.ContainsKey(accId)){
                CommerceEntitlementBuyerGroup cebg = new CommerceEntitlementBuyerGroup();
                cebg.PolicyId = mapAccountIdPolicy.get(accId).Id;
                cebg.PMC_DH_SAPCustomerNumber__c= mapAccountIdSAPNumberMap.get(accId);
                cebg.BuyerGroupId = mapAccountIdBuyerGroup.get(accId).Id;
                lstCommerceEntitlementBuyerGroup.add(cebg);
            }
        }
        if(!lstCommerceEntitlementBuyerGroup.isEmpty() && Schema.sObjectType.CommerceEntitlementBuyerGroup.isCreateable()){
            Database.insert(lstCommerceEntitlementBuyerGroup, false);
        }
    }

    private static void createWebStoreBuyerGroup(Map<Id, BuyerGroup> mapAccountIdBuyerGroup){
        List<WebStoreBuyerGroup> lstWebStoreBuyerGroup = new List<WebStoreBuyerGroup>();
        WebStore store = [SELECT Id, Name
                          FROM WebStore
                          WHERE Name =: WEBSTORENAME 
                          WITH USER_MODE
                          LIMIT 1];
        for(BuyerGroup bg : mapAccountIdBuyerGroup.values()){
            WebStoreBuyerGroup objWebStoreBuyerGroup = new WebStoreBuyerGroup();
            objWebStoreBuyerGroup.WebStoreId = store.Id;
            objWebStoreBuyerGroup.BuyerGroupId = bg.Id;
            lstWebStoreBuyerGroup.add(objWebStoreBuyerGroup);
        }
        if(!lstWebStoreBuyerGroup.isEmpty() && Schema.sObjectType.WebStoreBuyerGroup.isCreateable()){
            Database.insert(lstWebStoreBuyerGroup, false);
        }
    } 
}