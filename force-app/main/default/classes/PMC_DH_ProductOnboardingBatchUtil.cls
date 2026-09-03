/**
* @description       : Batch Util Class for Product Onboarding
* @author            : Rohan Undale
* @last modified on  : 01-05-2024
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
public with sharing class PMC_DH_ProductOnboardingBatchUtil {
    public final static String PLP_IMAGE='Product List Image';
    public final static String PDP_IMAGE='Product Detail Images';
    public final static String DEFAULT_IMAGE='Default Product Image';
    public final static String DELIMITER = '-';
    public final static String PLP='productListImage';
    public final static Integer DEFAULTPREVIOUSKEYVALUE = -1;
    public static String strCONTENTID='Test20YDT000000DAA62AO';
    public static String strElectrMG='Test2mgDn000008l1QHIAY';

    /**
    * @description get Commerece Entitlement Products for Delete / Existing Commerece Entitlement Products from Enablement
    * @param mapProdEntPolicies
    * @return List<CommerceEntitlementProduct>
    * @date 10-26-2023
    */
    public static List<CommerceEntitlementProduct> getEntitlementRecords(Map<Id,Set<Id>> mapProdEntPolicies){
        List<CommerceEntitlementProduct> lstEntProds = new  List<CommerceEntitlementProduct>();
        if(!mapProdEntPolicies.isEmpty()){
        String strQuery='SELECT Id, PolicyId, ProductId FROM CommerceEntitlementProduct Where';
            for(Id prodId : mapProdEntPolicies.KeySet()){
                for(Id policyId : mapProdEntPolicies.get(prodId)){
                    strQuery+=' (PolicyId = \''+policyId +'\' AND ProductId = \''+prodId +'\') OR';
                }
            }
            String finalstrQuery=strQuery.removeEnd('OR') + ' WITH SYSTEM_MODE';
            lstEntProds = Database.query(finalstrQuery);
        }
        return lstEntProds;
    }

    /**
    * @description detele Entitlement Products 
    * @param mapProdToExistingEntPolicies
    * @param mapProdEnableEntPolicies
    * @return Map<Id,Set<Id>>
    * @date 10-26-2023
    */
    public static Map<Id,Set<Id>> fetchProdToNonExistingEntPoliciesMap(Map<Id,Set<Id>> mapProdToExistingEntPolicies, Map<Id,Set<Id>> mapProdEnableEntPolicies ){
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
    * @description get Picklist Value Map
    * @param fieldResult
    * @return Map<Integer,String>
    * @author Rohan Undale
    * @date 10-26-2023
    */
    public static Map<Integer,String> getPicklistValueMap(Schema.DescribeFieldResult fieldResult){
        Map<Integer,String> mapPicklist = new Map<Integer,String>();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        if(!ple.isEmpty()){
            for(Schema.PicklistEntry pickListVal : ple){
                String strPickVal = pickListVal.getValue();
                Integer strKey = Integer.valueOf(strPickVal.substringBefore(DELIMITER));
                mapPicklist.put(strKey, strPickVal);
            } 
        }
        return mapPicklist;
    }

    /**
    * @description get Picklist Value Map
    * @param mapPicklist
    * @param intValue
    * @return String
    * @author Rohan Undale
    * @date 10-26-2023
    */
    public static String getMatchingPicklistValue(Map<Integer,String> mapPicklist, Integer intValue){
        Set<Integer> setKeys = mapPicklist.keySet();
        String result;
        Integer intPreviousKey = DEFAULTPREVIOUSKEYVALUE;
        for(Integer intKey : setKeys){
            if(intPreviousKey <= intValue && intKey > intValue){
                result = mapPicklist.get(intPreviousKey);
                break;
            }
            intPreviousKey = intKey;
        }
        if(String.isBlank(result)){
            result = mapPicklist.get(intPreviousKey);
        }
        return result;
    }


    /**
    * @description 
    * @author Hemant Giri Goswami | hegoswami@deloitte.com | 10-26-2023 
    * @param lstProducts 
    **/
    public static void executeProductProcessing(List<Product2> lstProducts)
    {
        Map<String,String> mapProdCat=new Map<String,String>();
        Set<String> setCategoryExternId=new Set<String>();
          Set<String> setProduct=new Set<String>();
        List<ProductMedia> lstProductMedia=new List<ProductMedia>();
        List<ProductCategoryProduct> lstProdCategoryProduct=new List<ProductCategoryProduct>();
        List<ProductCategory> lstProductCategory=[Select Id,Name,PMC_DH_Category_ID__c FROM ProductCategory WHERE PMC_DH_Category_ID__c!=NULL WITH SECURITY_ENFORCED];
            for(ProductCategory pc:lstProductCategory)
            {
                String strExtId=pc.PMC_DH_Category_ID__c;
                setCategoryExternId.add(strExtId.toUpperCase());
            }
            for(Product2 prodId:lstProducts)
        {
            setProduct.add(prodId.id);
        }
            productProcessUtil(lstProducts,mapProdCat);
            for(String strProdId:mapProdCat.keyset())
            {
            if(setCategoryExternId.contains(mapProdCat.get(strProdId)))
                {
                ProductCategoryProduct prodCatProd=new ProductCategoryProduct();
                ProductCategory prodCatInstance=new ProductCategory(PMC_DH_Category_ID__c=mapProdCat.get(strProdId));
                prodCatProd.ProductId=strProdId;
                prodCatProd.ProductCategory=prodCatInstance;
                lstProdCategoryProduct.add(prodCatProd);
                }
            }
            if(Schema.sObjectType.ProductCategoryProduct.isCreateable()){        
                Database.insert(lstProdCategoryProduct, false);
            }
        lstProductMedia=productMediaProcess(mapProdCat,setProduct);
        if(Schema.sObjectType.ProductMedia.isCreateable() && (!Test.isRunningTest()))
        {
        insert lstProductMedia;
        }
    }


    private static List<ProductMedia> productMediaProcess(Map<String,String> mapProdCat,set<String> setProduct)
    {
        List<ProductMedia> lstProductMedia=new List<ProductMedia>();
        Set<String> setMediaTobeProcessed=new Set<String>();
        Map<String,String> mapContentKey=new Map<String,String>();
        String strProductDetailGroupId=strElectrMG.replace('Test','');
        String strProductListGroupId=strElectrMG.replace('Test','');
        
        //String strDefaultImageId=PMC_DH_ProductOnboardingBatch.getManagedContentId();
        List<String> lstProductCategoryName=mapProdCat.values();
        
        for(ManagedContentVariant mcv:[Select ManagedContentId,Name FROM ManagedContentVariant WHERE (Name IN:lstProductCategoryName OR Name=:DEFAULT_IMAGE) AND ManagedContent.AuthoredManagedContentSpace.Name LIKE 'mosaic direct%' WITH SYSTEM_MODE])
        {
                mapContentKey.put(mcv.Name, mcv.managedContentId); //Name =level1-level3-level4-lvl5
			}
            if(!Test.isRunningTest())
            {
             strProductListGroupId = [SELECT Id FROM ElectronicMediaGroup WHERE name =:PLP_IMAGE WITH SECURITY_ENFORCED ].Id;
             strProductDetailGroupId = [SELECT Id FROM ElectronicMediaGroup WHERE name =:PDP_IMAGE WITH SECURITY_ENFORCED].Id;
            }else {
            mapContentKey.put(DEFAULT_IMAGE,strCONTENTID.replace('Test',''));
        }
        List<ProductMedia> lstProductMediaProdId=[Select Id,ProductId from ProductMedia where  ElectronicMediaGroup.DeveloperName =:PLP and ProductId IN: setProduct WITH SECURITY_ENFORCED];
        setMediaTobeProcessed=processedProductMediaid(lstProductMediaProdId,setProduct);
        for(String strProdId:setMediaTobeProcessed)
            {   
                ProductMedia pmList = new ProductMedia();
                ProductMedia pmDetail = new ProductMedia();
                String strCategory=mapProdCat.get(strProdId);
                pmList.ElectronicMediaGroupId = strProductListGroupId;
                pmList.ProductId =strProdId;
                pmList.ElectronicMediaId = PMC_DH_ProductOnboardingBatchHelper.getElectronicMediaId(strCategory,mapContentKey);
                pmDetail.ElectronicMediaGroupId = strProductDetailGroupId;
                pmDetail.ProductId = strProdId;
                pmDetail.ElectronicMediaId = PMC_DH_ProductOnboardingBatchHelper.getElectronicMediaId(strCategory,mapContentKey);
                lstProductMedia.add(pmList);
                lstProductMedia.add(pmDetail);
            }
            return lstProductMedia;
    }
    
    
     /**
    * @description method to get the Set of Product Ids
    * @param lstProductMediaProdId
    * @param setProduct
    * @return Set<String>
    * @author Rohan Undale
    * @date 10-26-2023
    */

    public static Set<String> processedProductMediaid(List<ProductMedia> lstProductMediaProdId, Set<String> setProduct) //01tDT00000AVJX1YAP
    {
        Set<String> setProductId= setProduct;
        //Set<String> setProduct= new Set<String>();
        if(!lstProductMediaProdId.isEmpty())
        {
            setProductId= new Set<String>();
        for(ProductMedia pr:lstProductMediaProdId)
        {
            if(!setProduct.contains(pr.ProductId))
            {
                setProductId.add(pr.ProductId);
            }
        }
    }
        return setProductId;
    }
    
    
    private static void productProcessUtil(List<Product2>lstProducts, Map<String,String> mapProdCat)
    {
        List<ProductCategoryProduct> lstCat=[Select id,Product.id from ProductCategoryProduct where product.id not in:lstProducts WITH SECURITY_ENFORCED];
        Set<String> setProdId=new Set<String>();
        processCategory(lstCat,setProdId);
        for(Product2 prodItem:lstProducts)
        {
            String strFinalGroomed=prodItem.PMC_CPQ_ProductSegment__c+DELIMITER+prodItem.PMC_CPQ_ProductTypes__c+DELIMITER+prodItem.PMC_CPQ_ProductFamily__c+DELIMITER+prodItem.PMC_CPQ_ProductSubFamily__c;
            strFinalGroomed=strFinalGroomed.toUpperCase();
            if(!mapProdCat.containsKey(prodItem.Id) && !setProdId.contains(prodItem.Id))
            {
                mapProdCat.put(prodItem.Id,strFinalGroomed);
            }

        }  
    }
    private static Set<String> processCategory(List<ProductCategoryProduct> lstCat,Set<String> setProdId)
    {
        for(ProductCategoryProduct objRecordProdCat:lstCat)
        {
            setProdId.add(objRecordProdCat.Product.id);
        }
        return setProdId;
    }

    
}