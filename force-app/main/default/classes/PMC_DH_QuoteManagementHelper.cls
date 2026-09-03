/**
* @description Helper class for management class for QuoteRelated Item
* @author Rohan Undale
* @since  09-15-2023
*/
public without sharing class PMC_DH_QuoteManagementHelper {
    public final static String ACCEPTED_STATUS = 'Accepted';
    public final static String PENDING_SIGNATURE_STATUS = 'Pending Signature';
    public final static String PARTIALLY_EXECUTED_STATUS = 'Partially Executed';
    public final static String ACTION_PENDING_STATUS = 'Action Pending';
    public final static String UOM_STN = 'STN';
    public final static String UOM_MTN = 'MTN';
    /*************************************************************************
* @method Name  : getContractsForQuote
* @param        objQuote
* @description  : Method to get Contracts for Quote
* @return       : List<PMC_DH_QuoteDetailsWrapper.ContractsWrapper>
*****************************************************************************/
    public static List<PMC_DH_QuoteDetailsWrapper.ContractsWrapper> getContractsForQuote(SBQQ__Quote__c objQuote){
        List<PMC_DH_QuoteDetailsWrapper.ContractsWrapper> lstContractWrapper=new List<PMC_DH_QuoteDetailsWrapper.ContractsWrapper>();
        PMC_DH_QuoteMgmtRelatedItemsClass.PMC_DH_ContractListWrapper wrpContractList = new PMC_DH_QuoteMgmtRelatedItemsClass.PMC_DH_ContractListWrapper();  //changes as part of GDASF-19642
        PMC_DH_Store_Configuration__mdt config = PMC_DH_Store_Configuration__mdt.getInstance('ContractUrl');
        if(objQuote.SBQQ__Status__c == ACCEPTED_STATUS && (objQuote.PMC_CPQ_ContractStageName__c == PENDING_SIGNATURE_STATUS || objQuote.PMC_CPQ_ContractStageName__c == PARTIALLY_EXECUTED_STATUS)){
            PMC_DH_QuoteDetailsWrapper.ContractsWrapper objContract=new PMC_DH_QuoteDetailsWrapper.ContractsWrapper();
            objContract.strContractStatus = System.Label.PMC_DH_ActionPending; //ACTION_PENDING_STATUS;
            objContract.strContractNumber =objQuote.PMC_CLM_DocumentNumber__c;
            objContract.strContractUrl = config.PMC_DH_PageUrl__c+objQuote.Id;
            lstContractWrapper.add(objContract);
        }else{
            wrpContractList = PMC_DH_QuoteMgmtRelatedItemsClass.getContracts(objQuote.Id); //changes as part of GDASF-19642
            lstContractWrapper = wrpContractList.lstContractWrapper; //changes as part of GDASF-19642
        }
        return lstContractWrapper;
    }
    
    /*************************************************************************
* @method Name  : getUnitOfMeasureForQuoteLine
* @param        cartItemWrap
* @param        strUserCountry
* @description  : Method to get Unit Of Measure For Quote Line Product
* @return       : String
*****************************************************************************/
    public static String getUnitOfMeasureForQuoteLine(PMC_DH_RequestForQuoteWrapper.CartItemWrapper cartItemWrap, String strUserCountry){
        String strProductUOM = cartItemWrap.strProductUOM;
        if(String.isBlank(strProductUOM)){
            List<PMC_DH_Store_Configuration__mdt> lstStoreConfigMtd = [SELECT Id, PMC_DH_Country__c, PMC_DH_DefaultUOMForCountry__c
                                                                       FROM PMC_DH_Store_Configuration__mdt
                                                                       WHERE PMC_DH_Country__c =: strUserCountry AND PMC_DH_DefaultUOMForCountry__c != NULL
                                                                       WITH USER_MODE];
            if (lstStoreConfigMtd.size()>0) {
                strProductUOM = lstStoreConfigMtd[0].PMC_DH_DefaultUOMForCountry__c;
            }
        }
        return strProductUOM;
    }
    
    /*************************************************************************
* @method Name  : getProductUnitOfMeasure
* @description  : Method to get 'Product Unit Of Measure' information in wrapper form
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/
    @AuraEnabled
    public static List<PMC_DH_PicklistWrapper> getProductUnitOfMeasureList(){
        Schema.DescribeFieldResult fieldResult = SBQQ__QuoteLine__c.PMC_CPQ_UnitofMeasure__c.getDescribe();
        List<PMC_DH_PicklistWrapper> lstProductUOM = PMC_DH_DigitalHubB2BUtils.getPicklistFromSchema(fieldResult); //DevOps Removed for SSM Feature fix
        List<PMC_DH_PicklistWrapper> lstFinalProductUOM = new List<PMC_DH_PicklistWrapper>();
        for(PMC_DH_PicklistWrapper pw : lstProductUOM){ 
            if(pw.value == UOM_STN || pw.value == UOM_MTN){
                lstFinalProductUOM.add(pw);
            }
        }
        return lstFinalProductUOM;
    }
    
    /*************************************************************************
* @method Name  : getPackagingTypeList
* @description  : Method to get 'Packaging Type' information in wrapper form
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/
    @AuraEnabled
    public static List<PMC_DH_PicklistWrapper> getPackagingTypeList(){
        Schema.DescribeFieldResult fieldResult = SBQQ__QuoteLine__c.PMC_CPQ_PackageType__c.getDescribe();
        List<PMC_DH_PicklistWrapper> lstPackagingType = PMC_DH_DigitalHubB2BUtils.getPicklistFromSchema(fieldResult);
        return lstPackagingType;
    }
    
    /*************************************************************************
* @method Name  : getPackTypeList
* @description  : Method to get 'Pack Type' information in wrapper form
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/
    @AuraEnabled
    public static List<PMC_DH_PicklistWrapper> getPackTypeList(){
        Schema.DescribeFieldResult fieldResult = SBQQ__QuoteLine__c.PMC_CPQ_PackType__c.getDescribe();
        List<PMC_DH_PicklistWrapper> lstPackType = PMC_DH_DigitalHubB2BUtils.getPicklistFromSchema(fieldResult);
        return lstPackType;
    }
    /*************************************************************************

* @method Name  : updateQuoteLineProdInfo

* @description  : Method to update UOM forthe Product Info

* @param         strUOM
* @param         lstLineItemsIds

* @return       : PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper

*****************************************************************************/  
    
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper updateQuoteLineProdInfo(String strUOM, List<String> lstLineItemsIds) {
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new  PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        List<SBQQ__QuoteLine__c> lstQuoteLineProdUpdate = new List<SBQQ__QuoteLine__c>();
        try {
            for (SBQQ__QuoteLine__c  qlineItem : [SELECT Id, PMC_CPQ_UnitofMeasure__c FROM SBQQ__QuoteLine__c Where Id IN : lstLineItemsIds WITH SECURITY_ENFORCED]){ 
                qlineItem.PMC_CPQ_UnitofMeasure__c=strUOM; 
                lstQuoteLineProdUpdate.add(qlineItem);
            }
            if(Schema.sObjectType.SBQQ__QuoteLine__c.isUpdateable()){
                update lstQuoteLineProdUpdate;
                result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'QuoteLineDetailUpdate');
            }
            
            
        } catch (Exception ex) {
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
            // PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return result;
        
    }  
    /*************************************************************************
* @author : Dishari Mondal
* @method Name  : getPackTypeForQuote
* @description  : Method to get Pack Type
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/
    public static List<PMC_DH_PicklistWrapper> getPackTypeForQuote(){
        Schema.DescribeFieldResult fieldResult = CartItem.PMC_DH_PackType__c.getDescribe();
        List<PMC_DH_PicklistWrapper> lstPackType = PMC_DH_DigitalHubB2BUtils.getPicklistFromSchema(fieldResult);
        return lstPackType;
    }
/*************************************************************************
* @author : Dishari Mondal
* @method Name  : getPackagingTypeForQuote
* @description  : Method to get Packaging Type
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/
    public static List<PMC_DH_PicklistWrapper> getPackagingTypeForQuote(){
        Schema.DescribeFieldResult fieldResult = CartItem.PMC_DH_PackageType__c.getDescribe();
        List<PMC_DH_PicklistWrapper> lstPackagingType = PMC_DH_DigitalHubB2BUtils.getPicklistFromSchema(fieldResult);
        return lstPackagingType;
    }
    /*************************************************************************
* @method Name  : mapToGetShipTo
* @description  : class to get map of soldToShipToJunctionId and ShipToId
* @param          effAccId
* @return       : Map<String, String>
*****************************************************************************/  
    public static Map<String, String> mapToGetShipTo(String effAccId){
        Map<String, String> mapShipTo = new Map<String, String>();
        List<PMC_SS_AccountPartnerRelationships__c> lstSoldToShipTo = [select Id, PMC_SS_Account__c, PMC_SS_RelatedAccount__c from PMC_SS_AccountPartnerRelationships__c WHERE PMC_SS_RelatedAccount__r.PMC_SS_MDMVerified__c=TRUE AND PMC_SS_Account__c=:effAccId  AND PMC_SS_Type__c=:PMC_DH_ConstantClass.ACCOUNT_TYPE AND PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c!=:PMC_DH_ConstantClass.ACCOUNT_INACTIVE_STATUS AND PMC_SS_RelatedAccountSalesArea__c!=NULL WITH SECURITY_ENFORCED];
        List<PMC_SS_AccountPartnerRelationships__c> lstSoldtoShiptoProcessed = removeDuplicateRelatedAccountsFromList(lstSoldToShipTo);  
        for(PMC_SS_AccountPartnerRelationships__c objSoldToShipTo : lstSoldtoShiptoProcessed){
            mapShipTo.put(objSoldToShipTo.Id, objSoldToShipTo.PMC_SS_RelatedAccount__c); 
        }
        return mapShipTo;
    }
    
    /*************************************************************************
* @method Name  : getShipToIdSoldToShipToJunctionIdMap
* @description  : class to get map of ShipToId and soldToShipToJunctionId
* @param          effAccId
* @return       : Map<String, String>
*****************************************************************************/  
    public static Map<String, String> getShipToIdSoldToShipToJunctionIdMap(String effAccId){
        Map<String, String> mapShipTo = new Map<String, String>();
        List<PMC_SS_AccountPartnerRelationships__c> lstSoldToShipTo = [select Id, PMC_SS_Account__c, PMC_SS_RelatedAccount__c from PMC_SS_AccountPartnerRelationships__c WHERE PMC_SS_RelatedAccount__r.PMC_SS_MDMVerified__c=TRUE AND PMC_SS_Account__c=:effAccId AND PMC_SS_Type__c=:PMC_DH_ConstantClass.ACCOUNT_TYPE AND PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c!=:PMC_DH_ConstantClass.ACCOUNT_INACTIVE_STATUS  AND PMC_SS_RelatedAccountSalesArea__c!=NULL WITH SECURITY_ENFORCED];
        List<PMC_SS_AccountPartnerRelationships__c> lstSoldtoShiptoProcessed = removeDuplicateRelatedAccountsFromList(lstSoldToShipTo);  
        for(PMC_SS_AccountPartnerRelationships__c objSoldToShipTo : lstSoldtoShiptoProcessed){
            mapShipTo.put(objSoldToShipTo.PMC_SS_RelatedAccount__c, objSoldToShipTo.Id); 
        }
        return mapShipTo;
    }
    
    /*************************************************************************
* @method Name  : createQuoteFromCartHelper
* @description  : Helper method for createQuoteFromCart
* @param         cartId
* @param         objQuote
* @param         objWebCart
* @return       : Map<String, String>
*****************************************************************************/  
    public static List<SBQQ__QuoteLine__c> createQuoteFromCartHelper(String cartId, SBQQ__Quote__c objQuote, WebCart objWebCart){
        List<SBQQ__QuoteLine__c> lstQuoteItems = new List<SBQQ__QuoteLine__c>();
        List<CartItem> lstCartItems = [SELECT Id,Quantity,Product2Id,PMC_DH_ShipTo__c, PMC_DH_AccountPartnerRelationship__c, PMC_DH_Incoterms__c, PMC_DH_DeliveryMode__c, PMC_DH_PlantShipFrom__c, CurrencyIsoCode,Product2.PMC_CPQ_QuantityUnitOfMeasure__c,Product2.PMC_CPQ_CropType__c,PMC_DH_UnitofMeasure__c,PMC_DH_PackType__c,Cart.PMC_DH_Currency__c
                                       FROM CartItem
                                       WHERE Cart.Id =: cartId
                                       WITH SECURITY_ENFORCED];//PMC_DH_PackageType__c,->Removed as part of GDASF-20003
        
        SBQQ__Quote__c createdQuote = [SELECT Name, SBQQ__Account__c, RecordType.Name, PMC_CPQ_QuoteRecordSubType__c FROM SBQQ__Quote__c WHERE Id =: objQuote.Id WITH SECURITY_ENFORCED LIMIT 1];
        String quoteId = objQuote.Id;
        //String quoteNumber = createdQuote.Name;
        Map<String, String> mapSoldToShipTo = mapToGetShipTo(createdQuote.SBQQ__Account__c);  //----> to identify sold-to changes
        for(CartItem ci: lstCartItems){
            SBQQ__QuoteLine__c quoteItem = new SBQQ__QuoteLine__c();
            quoteItem.SBQQ__Product__c         	 = ci.Product2Id;
            quoteItem.PMC_CPQ_UnitofMeasure__c   = ci.PMC_DH_UnitofMeasure__c;
            quoteItem.PMC_CPQ_CropType__c        = ci.Product2.PMC_CPQ_CropType__c;
            quoteItem.PMC_CPQ_Account__c 		 = objWebCart.AccountId;
            quoteItem.PMC_CPQ_SalesArea__c	     = objQuote.PMC_CPQ_SalesArea__c;
            //quoteItem.PMC_CPQ_ShipTo__c          = ci.PMC_DH_ShipTo__c;
            quoteItem.PMC_CPQ_ShipTo__c          = mapSoldToShipTo.get(ci.PMC_DH_AccountPartnerRelationship__c);// added as part of quick fix
            quoteItem.PMC_CPQ_SoldToShipToJunction__c = ci.PMC_DH_AccountPartnerRelationship__c; // added as part of GDASF-17324
            //quoteitem.PMC_CPQ_SoldToShipToJunction__c='a4UDT000001Odbp2AC';
            quoteItem.PMC_CPQ_ProductLocation__c = ci.PMC_DH_PlantShipFrom__c;
            quoteItem.PMC_CPQ_Incoterms1__c      = ci.PMC_DH_Incoterms__c;
            quoteItem.PMC_CPQ_ModeofTransportation__c     = ci.PMC_DH_DeliveryMode__c;
            quoteItem.CurrencyIsoCode = ci.Cart.PMC_DH_Currency__c;
            quoteItem.SBQQ__Quantity__c=ci.Quantity;
            quoteItem.SBQQ__Quote__c             = quoteId;
            quoteItem.PMC_CPQ_QuoteRecordType__c = createdQuote.RecordType.Name;
            quoteItem.PMC_CPQ_QuoteRecordSubType__c= objQuote.PMC_CPQ_QuoteRecordSubType__c; 
            quoteItem.PMC_CPQ_PackType__c = ci.PMC_DH_PackType__c;
            //quoteItem.PMC_CPQ_PackageType__c = ci.PMC_DH_PackageType__c;//Removed as part of GDASF-20003
            lstQuoteItems.add(quoteItem);
        }
        return lstQuoteItems;
    }
    
    /*************************************************************************
* @method Name  : removeDuplicateRelatedAccountsFromList
* @description  : Remove Duplicate Related Accounts From List
* @param         lstAccountPartnerRelationshipsOriginal
* @return       : List<PMC_SS_AccountPartnerRelationships__c>
*****************************************************************************/
    public static List<PMC_SS_AccountPartnerRelationships__c> removeDuplicateRelatedAccountsFromList(List<PMC_SS_AccountPartnerRelationships__c> lstAccountPartnerRelationshipsOriginal){
        List<PMC_SS_AccountPartnerRelationships__c> lstAccountPartnerRelationshipsProcessed = new List<PMC_SS_AccountPartnerRelationships__c>();
        Set<String> lstProcessedKeys = new Set<String>();
        
        for(PMC_SS_AccountPartnerRelationships__c apr : lstAccountPartnerRelationshipsOriginal){
            if(!lstProcessedKeys.contains(apr.PMC_SS_Account__c+''+apr.PMC_SS_RelatedAccount__c)){
                lstAccountPartnerRelationshipsProcessed.add(apr);
                lstProcessedKeys.add(apr.PMC_SS_Account__c+''+apr.PMC_SS_RelatedAccount__c);
            }
        }
        
        return lstAccountPartnerRelationshipsProcessed;
    }  
    
    // added by Nikhilesh as part of GDASF-17525
    
    /*************************************************************************
* @method Name  : getMapProductDetail
* @description  : Method to get map of Product Details Using ConnectApi
* @param         lstProducts
* @param         skus
* @param         mapProductDetail
*@return        :Map<String , PMC_DH_RequestForQuoteController.ConnectApiWrapper>
*****************************************************************************/
    
    public static Map<String , PMC_DH_RequestForQuoteController.ConnectApiWrapper> getMapProductDetail(List<ConnectApi.ProductOverview> lstProducts, List<String> skus,Map<String , PMC_DH_RequestForQuoteController.ConnectApiWrapper> mapProductDetail){
        List<ConnectApi.ProductOverview> lstActiveProductsFromConnectApi = new List<ConnectApi.ProductOverview>();
        List<Product2> lstInactiveProducts = new List<Product2>();
        List<String> lstActiveSkus = new List<String>();
        List<String> lstInactiveSkus = new List<String>();
        
        for(ConnectApi.ProductOverview prod : lstProducts){
            // if the connectapi response for the product is successful, add it to the list of active products
            if(prod.success){
                lstActiveProductsFromConnectApi.add(prod);
                lstActiveSkus.add(prod.sku);
            }  
        }
        for(String sku : skus){
            if(!lstActiveSkus.contains(sku)){
                lstInactiveSkus.add(sku);
            }
        }
        // if all the products are active, pass the list of products to get product details
        if(lstActiveSkus.size() == skus.size()){
            mapProductDetail=PMC_DH_QuoteMgmtActionController.getProd(lstProducts, lstInactiveProducts);
        }
        // if all products are not active, query the details of inactive products and pass both lists to get product details
        else{
            lstInactiveProducts = [SELECT Id, Name, StockKeepingUnit, PMC_CPQ_ProductFamily__c, PMC_CPQ_QuantityUnitOfMeasure__c, PMC_CPQ_PackType__c from Product2 
                                   WHERE StockKeepingUnit IN: lstInactiveSkus WITH SECURITY_ENFORCED];
            mapProductDetail=PMC_DH_QuoteMgmtActionController.getProd(lstActiveProductsFromConnectApi, lstInactiveProducts);
        }
        return mapProductDetail;
    }

        /*************************************************************************
* @method Name  : getInactiveProductDetails
* @description  : Method to get map of Product Details Using ConnectApi
* @param         mapProductDetail
* @param         lstInactiveProducts
*@return        :Map<String , PMC_DH_RequestForQuoteController.ConnectApiWrapper>
*****************************************************************************/
    
    public static Map<String , PMC_DH_RequestForQuoteController.ConnectApiWrapper> getInactiveProductDetails(Map<String , PMC_DH_RequestForQuoteController.ConnectApiWrapper> mapProductDetail, List<Product2> lstInactiveProducts){
        PMC_DH_RequestForQuoteController.ConnectApiWrapper objconnectapiProduct;
        for(Product2 prod : lstInactiveProducts){
            //assigning the product details in Wrapper
            objconnectapiProduct = new PMC_DH_RequestForQuoteController.ConnectApiWrapper();
            objconnectapiProduct.strProductName = prod.Name;
            objconnectapiProduct.strProductId = prod.Id;
            objconnectapiProduct.strSku = prod.StockKeepingUnit;
            objconnectapiProduct.strImgSrc = '';
            objconnectapiProduct.strProductFamily = prod.PMC_CPQ_ProductFamily__c;
            objconnectapiProduct.strProductUOM = prod.PMC_CPQ_QuantityUnitOfMeasure__c;
            objconnectapiProduct.strProductPackType = prod.PMC_CPQ_PackType__c;
            
            //assigning the wrapper in map based on sku
            if(!mapProductDetail.containsKey(objconnectapiProduct.strSku)){
                mapProductDetail.put(objconnectapiProduct.strSku,objconnectapiProduct);
            }
        }
        return mapProductDetail;
    }
    // end of changes added by Nikhilesh as part of GDASF-17525

    /*************************************************************************
* @method Name  : createPaymentTermsMapFrTranslations
* @description  : Method to create a map of translated values of Payment Terms
* @param       	fieldResult
* @return       : Map<String,String>
*****************************************************************************/
    public static Map<String,String> createPaymentTermsMapFrTranslations(Schema.DescribeFieldResult fieldResult){
        Map<String,String> mapTranslatedPaymentTerms = new Map<String,String>();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for(Schema.PicklistEntry pickListVal : ple){
                    mapTranslatedPaymentTerms.put(pickListVal.getValue(),pickListVal.getLabel());        
                } 
        return mapTranslatedPaymentTerms;
    }
}