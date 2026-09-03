/** 
* @description Controller for fetching  QuoteDetails 
* @author Humera Rahath
* @last modified on 2023-June-01
* @last modified by Humera Rahath
* Created On       :2023-June-01
**/
public without sharing class PMC_DH_QuoteManagementControllerClass { // removed 'with sharing ' as this class is using ShipTo field

    
    /*************************************************************************
* @method Name  : getQuoteDetails
* @description  : Method to assign the ShipmentInformation of Quote Checkout in wrapper class
* @param        strCommunityId 
* @param        strEffectiveAccountId 
* @param        strQuoteId
* @return       : PMC_DH_QuoteDetailsWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_QuoteDetailsWrapper getQuoteDetails(String strCommunityId,String strEffectiveAccountId,String strQuoteId) 
    {
        PMC_DH_QuoteDetailsWrapper quoteDetailsWrapper=new PMC_DH_QuoteDetailsWrapper(); 
        try{
            
            //method to fetch SBQQ__Quote__c and SBQQ__QuoteLine__c using SOQL 
            SBQQ__Quote__c quoteDetails=getQuote(strQuoteId,strEffectiveAccountId);
            if(quoteDetails.id!=null)
            {
            // method to assign quote Summary details in a wrapper
            quoteDetailsWrapper.quoteSummaryWrapper=getQuoteSummary(quoteDetails);
            // method to assign Payment Info  in a wrapper
            quoteDetailsWrapper.paymentInformationWrapper=getPaymentInfo(quoteDetails);
            // method to assign contract Info in a wrapper
            quoteDetailsWrapper.requestedContractInfoWrapper=getContractInfo(quoteDetails);
            // method to assign quote line details in a wrapper
            quoteDetailsWrapper.productInfoWrapper=getProductDetails(strCommunityId,strEffectiveAccountId,quoteDetails);
            //method to assign contracts in a wrapper
            quoteDetailsWrapper.lstContracts=PMC_DH_QuoteManagementHelper.getContractsForQuote(quoteDetails);
            quoteDetailsWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, 'Quote Creation Success');
            }
            if(quoteDetails.id==null)
            {
                quoteDetailsWrapper=new PMC_DH_QuoteDetailsWrapper();
                quoteDetailsWrapper.statusCodeMessage=PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.ACCESS_DENIED_CODE, PMC_DH_ConstantClass.GETQUOTE_ACESSDENIED);

            }
        }
        catch(Exception ex){
            quoteDetailsWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return quoteDetailsWrapper; 
        
    }
    /*************************************************************************
* @method Name  : getQuote
* @description  : Method to fetch Quote Details
* @param         strQuoteId
* @param         strEffectiveAccountId
* @return       : List<SBQQ__Quote__c>
*****************************************************************************/
    public static SBQQ__Quote__c getQuote(String strQuoteId, String strEffectiveAccountId)
    {
        SBQQ__Quote__c quoteDetails= new SBQQ__Quote__c();
        List<SBQQ__Quote__c> lstQuote=new List<SBQQ__Quote__c>();
            List<String> lstQuoteOrigin = new List<String>{PMC_DH_ConstantClass.REQUEST,PMC_DH_ConstantClass.DRAFT};
                PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            //fetch SBQQ__Quote__c and SBQQ__QuoteLine__c using SOQL
            lstQuote= [SELECT Id,PMC_DH_QuoteFriendlyName__c,PMC_DH_QuoteInactiveTime__c,
                    createdby.name,createdby.country,SBQQ__Account__r.Id,SBQQ__Account__r.name,
                    PMC_CPQ_ExpiresOn__c,PMC_CPQ_CustomerAcceptanceMethod__c,SBQQ__Status__c,
                    CreatedDate,PMC_CPQ_ContractStart__c,PMC_CPQ_ContractEnd__c, SBQQ__PaymentTerms__c,
                    PMC_DH_PaymentMethod__c,CurrencyIsoCode,tolabel(PMC_DH_Summary_Reason__c), PMC_CPQ_RejectedReason__c,
                    PMC_CLM_OtherRejectionReason__c,PMC_CPQ_ContractStageName__c,PMC_CLM_DocumentNumber__c,PMC_CPQ_PaymentDate__c, (select id,SBQQ__Product__c,SBQQ__Product__r.name,SBQQ__Product__r.StockKeepingUnit,SBQQ__Product__r.PMC_CPQ_PackType__c,SBQQ__Quantity__c,PMC_CPQ_ShipTo__c,toLabel(PMC_CPQ_Incoterms1__c),PMC_CPQ_ModeofTransportation__c,PMC_CPQ_ProductLocation__c , PMC_CPQ_PackageType__c,PMC_CPQ_PackType__c, PMC_CPQ_UnitofMeasure__c,PMC_CPQ_SoldToShipToJunction__c from SBQQ__LineItems__r) 
                    from SBQQ__Quote__c WHERE ID=:strQuoteId AND SBQQ__Account__r.ID=:strEffectiveAccountId AND (PMC_CPQ_QuoteOrigin__c= :PMC_DH_ConstantClass.DH_REQUEST OR (PMC_CPQ_QuoteOrigin__c != :PMC_DH_ConstantClass.DH_REQUEST AND (SBQQ__Status__c Not in :lstQuoteOrigin))) WITH SECURITY_ENFORCED];
            // Empty check on List<SBQQ__Quote__c> and assign it to a quote instance
            if(!lstQuote.isEmpty() && !(PMC_DH_QuoteListViewController.getQuoteFiltered(lstQuote[0].PMC_DH_QuoteInactiveTime__c)) )
            {
                quoteDetails=lstQuote[0];
                
            }
        return quoteDetails;
    }
    
    
    
    /*************************************************************************
* @method Name  : getQuoteSummary
* @description  : Method to fetch Quote Summary Details
* @param         quoteDetails
* @return       : PMC_DH_QuoteDetailsWrapper.quoteSummaryWrapper
*****************************************************************************/
    
    public static  PMC_DH_QuoteDetailsWrapper.quoteSummaryWrapper getQuoteSummary(SBQQ__Quote__c quoteDetails){
        
        PMC_DH_QuoteDetailsWrapper.quoteSummaryWrapper quoteSummaryWrapper = new PMC_DH_QuoteDetailsWrapper.quoteSummaryWrapper(); 
        try{
            
            //assign quote values in Quote summary wrapper
            quoteSummaryWrapper.strQuoteId=quoteDetails.PMC_DH_QuoteFriendlyName__c; 
            quoteSummaryWrapper.strCustomerName=quoteDetails.createdby.name;
            quoteSummaryWrapper.strCustomerRegion=quoteDetails.createdby.country;
            quoteSummaryWrapper.strSoldToAccount=quoteDetails.SBQQ__Account__r.name;
            // fetching status with reference to CPQ SBQQ__Status__c field maintained in a metadata and assigning it to respective values
            PMC_DH_QuoteMgmtActionController.PMC_DH_QuoteStatusWrapper quoteStatusWrapper=PMC_DH_QuoteMgmtActionController.getStatus(quoteDetails);
            //this PMC_DH_Summary_Reason__c be updated by CPQ 
            if(quoteDetails.SBQQ__Status__c==PMC_DH_ConstantClass.STATUS_EXPIRED){
                quoteSummaryWrapper.strSummaryReason=quoteDetails.SBQQ__Status__c;
            }
            else{
                quoteSummaryWrapper.strSummaryReason =quoteDetails.PMC_DH_Summary_Reason__c;
            }
            quoteSummaryWrapper.strRejectionReason=PMC_DH_QuoteMgmtActionController.getRejectionReason(quoteDetails.PMC_CLM_OtherRejectionReason__c,quoteDetails.PMC_CPQ_RejectedReason__c);
            
            quoteSummaryWrapper.datRequestedDate=PMC_DH_QuoteUtils.getDateTimeToDate(quoteDetails.createdDate);
            
            PMC_DH_QuoteMgmtActionController.PMC_DH_QuoteStatusWrapper objQuoteWrapper=PMC_DH_RequestForQuoteHelper.getExpiryDate(quoteDetails,quoteStatusWrapper);
            quoteSummaryWrapper.datTExpiresIn=objQuoteWrapper.datTExpiresIn;
            quoteSummaryWrapper.datTCurrentDateTime=objQuoteWrapper.datTCurrentDateTime;
            quoteSummaryWrapper.strProgressIndicatorStatus=objQuoteWrapper.strProgressIndicatorStatus;
            quoteSummaryWrapper.strSummaryStatus=objQuoteWrapper.strSummaryStatus;
            if(String.isBlank(quoteDetails.PMC_CPQ_ContractStageName__c)){
                quoteSummaryWrapper.boolDocumentAvailable = false;
            }else{
                quoteSummaryWrapper.boolDocumentAvailable = true;
            }
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getLineNumber()+ex.getMessage()+ex.getStackTraceString()+ex.getCause());
        }
        return quoteSummaryWrapper;
    }
    
    
    /*************************************************************************
* @method Name  : getPaymentInfo
* @description  : Method to fetch Payment Information
* @param         quoteDetails
* @return       : PMC_DH_QuoteDetailsWrapper.paymentInformationWrapper
*****************************************************************************/
    public static PMC_DH_QuoteDetailsWrapper.paymentInformationWrapper getPaymentInfo(SBQQ__Quote__c quoteDetails){
        PMC_DH_QuoteDetailsWrapper.paymentInformationWrapper paymentInformationWrapper=new PMC_DH_QuoteDetailsWrapper.paymentInformationWrapper();
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            String strUserId=userInfo.getUserId();
            List<User> lstUser=PMC_DH_UserUtil.getUserData(strUserId);
            //assign quote values in payment info wrapper
            paymentInformationWrapper.strPaymentTermSelected=quoteDetails.SBQQ__PaymentTerms__c;
            paymentInformationWrapper.strPaymentMethodSelected=quoteDetails.PMC_DH_PaymentMethod__c;
            paymentInformationWrapper.strCurrencySelected=quoteDetails.CurrencyIsoCode;  
            //Added as part of GDASF-19809
            paymentInformationWrapper.datPrepaymentDate=quoteDetails.PMC_CPQ_PaymentDate__c;
            PMC_DH_RequestForQuoteController.PaymentInfoWrapper paymentInfo=PMC_DH_DigitalHubB2BUtils.getPicklistValuesForPayment(lstUser[0].country);
             //methods to fetch picklist values of Payment terms, payment methods , currency of Quote
            paymentInformationWrapper.lstPaymentTerms = paymentInfo.lstPaymentTerms;
            paymentInformationWrapper.lstPaymentMethods = paymentInfo.lstPaymentMethods;
            paymentInformationWrapper.lstCurrency = paymentInfo.lstCurrencyIsoCode;
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getLineNumber()+ex.getMessage()+ex.getStackTraceString()+ex.getCause());
        }
        return paymentInformationWrapper;
    }
    /*************************************************************************
* @method Name  : getContractInfo
* @description  : Method to fetch Contract Information
* @param         quoteDetails
* @return       : PMC_DH_QuoteDetailsWrapper.RequestedContractInfoWrapper
*****************************************************************************/
    public static PMC_DH_QuoteDetailsWrapper.RequestedContractInfoWrapper getContractInfo(SBQQ__Quote__c quoteDetails){
        
        PMC_DH_QuoteDetailsWrapper.RequestedContractInfoWrapper requestedContractInfoWrapper=new PMC_DH_QuoteDetailsWrapper.RequestedContractInfoWrapper();
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            //assign quote values in Contract Info wrapper
            requestedContractInfoWrapper.datStartDate=quoteDetails.PMC_CPQ_ContractStart__c;
            requestedContractInfoWrapper.datEndDate=quoteDetails.PMC_CPQ_ContractEnd__c;
            
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getLineNumber()+ex.getMessage()+ex.getStackTraceString()+ex.getCause());
        }
        return requestedContractInfoWrapper;
        
    }
    
    /*************************************************************************
* @method Name  : getQuoteLineDetails
* @description  : Method to fetch Quote Line Details
* @param         quoteDetails
* @return       : Map<String,List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>>
*****************************************************************************/
    public static Map<String,List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>> getQuoteLineDetails(SBQQ__Quote__c quoteDetails){
        
        Map<String,List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>> mapQuoteLine=new Map<String,List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>>();
        PMC_DH_RequestForQuoteWrapper.CartItemWrapper objQuoteLineWrap;
        try
        {
            
            //fetching the SBQQ__QuoteLine__c Details and assigning the values to wrapper
            for(SBQQ__QuoteLine__c quoteLineItem:quoteDetails.SBQQ__LineItems__r)
            {
                
                objQuoteLineWrap=new PMC_DH_RequestForQuoteWrapper.CartItemWrapper(); 
                objQuoteLineWrap.strCartItemId=quoteLineItem.Id;
                Decimal decQuan=quoteLineItem.SBQQ__Quantity__c;
                if(decQuan != null) {
                    objQuoteLineWrap.strQuantity=decQuan.DoubleValue();
                }
                objQuoteLineWrap.strShipTo=quoteLineItem.PMC_CPQ_ShipTo__c;
                objQuoteLineWrap.strDeliveryMode=quoteLineItem.PMC_CPQ_ModeofTransportation__c; // toLabel removed bcos FE is utilising label-value pair to show translated.
                objQuoteLineWrap.strIncoterms=quoteLineItem.PMC_CPQ_Incoterms1__c;
                objQuoteLineWrap.strShipFrom=quoteLineItem.PMC_CPQ_ProductLocation__c;
                objQuoteLineWrap.strPackType=quoteLineItem.PMC_CPQ_PackType__c;
                objQuoteLineWrap.strProductUOM = quoteLineItem.PMC_CPQ_UnitofMeasure__c;
                objQuoteLineWrap.strSkuPackType = quoteLineItem.SBQQ__Product__r.PMC_CPQ_PackType__c;
                objQuoteLineWrap.strPackageType=quoteLineItem.PMC_CPQ_PackageType__c;
                //Checking if map contains sku and assiging the QuoteLine Wrapper
                if(!mapQuoteLine.containsKey(quoteLineItem.SBQQ__Product__r.StockKeepingUnit))
                {
                    mapQuoteLine.put(quoteLineItem.SBQQ__Product__r.StockKeepingUnit,new List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>());
                }
                mapQuoteLine.get(quoteLineItem.SBQQ__Product__r.StockKeepingUnit).add(objQuoteLineWrap);
                
            }
            
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getLineNumber()+ex.getMessage()+ex.getStackTraceString()+ex.getCause());
        }
        return mapQuoteLine;
    }
    
    /*************************************************************************
* @method Name  : getProductDetails
* @description  : Method to fetch assign product and QuoteLine Details in Wrapper
* @param         strCommunityId
* @param         strEffectiveAccountId
* @param         quoteDetails
* @return       : PMC_DH_RequestForQuoteWrapper
*****************************************************************************/  
    public static PMC_DH_RequestForQuoteWrapper getProductDetails(String strCommunityId,String strEffectiveAccountId,SBQQ__Quote__c quoteDetails)
    {
        
        PMC_DH_RequestForQuoteWrapper productInfoWrapper=new PMC_DH_RequestForQuoteWrapper();
        List<PMC_DH_RequestForQuoteWrapper.CartWrapper> lstQuoteLineWrapper=new List<PMC_DH_RequestForQuoteWrapper.CartWrapper>();
        PMC_DH_RequestForQuoteWrapper.CartWrapper objQuoteLineWrapper;
        try{
            //method to get QuotLine Details
            Map<String,List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>> mapQuoteLine=getQuoteLineDetails(quoteDetails);
            //Assinging the skus in Set
            Set<String> setSku=mapQuoteLine.keyset();
            //method to fetch Incoterms
            String strAcctMgrBusinessType=PMC_DH_RequestForQuoteHelper.getUserBusinessType(strEffectiveAccountId);
            List<PMC_DH_PicklistWrapper> lstIncoterms=PMC_DH_QuoteUtils.getIncotermsForQuote(strAcctMgrBusinessType);
            //method to fetch Mode of Transportation
            String strRecordTypeName=PMC_DH_RequestForQuoteHelper.getQuoteRecordTypeName();
            List<PMC_DH_PicklistWrapper> lstDeliveryMode=PMC_DH_QuoteUtils.getModeOfTransportationForQuote(strRecordTypeName);
            //method to fetch ship to based on strEffectiveAccountId
            List<PMC_DH_PicklistWrapper> lstShipTo=PMC_DH_QuoteUtils.getShipToForQuote(strEffectiveAccountId);
            //method to fetch ship from nbased on sku
            Map<String,List<PMC_DH_PicklistWrapper>> mapShipFrom=PMC_DH_QuoteUtils.getShipFromForQuote(setSku);
            List<String> lstSku = new List<String>(setSku);
            
            //method to get Product Details using connectApi 
            Map<String,PMC_DH_RequestForQuoteController.ConnectApiWrapper> mapProductDetail=getproductConnectApi(strCommunityId,strEffectiveAccountId,lstsku);
            //method to fetch Pack Type
            List<PMC_DH_PicklistWrapper> lstPackType=PMC_DH_QuoteManagementHelper.getPackTypeForQuote();
            //method to fetch Packaging Type
            List<PMC_DH_PicklistWrapper> lstPackagingType=PMC_DH_QuoteManagementHelper.getPackagingTypeForQuote();
            //method to fetch Unit of measure
            List<PMC_DH_PicklistWrapper> lstUnitOfMeasure =PMC_DH_QuoteManagementHelper.getProductUnitOfMeasureList();
            
            for(String quoteLineSku:mapQuoteLine.keyset())
            {
                objQuoteLineWrapper=new PMC_DH_RequestForQuoteWrapper.CartWrapper();
                //method to assign product Details in Wrapper
                PMC_DH_RequestForQuoteController.ConnectApiWrapper objconnectapiProduct=mapProductDetail.get(quoteLineSku);
                
                objQuoteLineWrapper.strProductName=objconnectapiProduct.strProductName;
                objQuoteLineWrapper.strSku=objconnectapiProduct.strSku;
                objQuoteLineWrapper.strProductId=objconnectapiProduct.strProductId;
                objQuoteLineWrapper.strImgSrc=objconnectapiProduct.strImgSrc;
                objQuoteLineWrapper.strProductUOM= mapQuoteLine.get(quoteLineSku)[0].strProductUOM;
                
                //Ship to based on strEffectiveAccountId
                objQuoteLineWrapper.lstShipTo=lstShipTo;
                //Incoterms 
                objQuoteLineWrapper.lstIncoterms=lstIncoterms;
                //Mode of transportation
                objQuoteLineWrapper.lstDeliveryModes=lstDeliveryMode;
                //ShipFrom based on product sku
                objQuoteLineWrapper.lstShipFrom=mapShipFrom.get(quoteLineSku);
                //List of QuoteLine based on sku
                objQuoteLineWrapper.lstCartItems=mapQuoteLine.get(quoteLineSku);
                //List of Pack Type
                objQuoteLineWrapper.lstPackType=lstPackType;
                objQuoteLineWrapper.lstProductUOM=lstUnitOfMeasure;
                //List of Packaging Type
                objQuoteLineWrapper.lstPackagingType=lstPackagingType;
                //List of Mode of transportation for incoterm CPT
                objQuoteLineWrapper.lstDeliveryModesCPT = PMC_DH_RequestForQuoteUtil.getModeOfTransportationForCPT();
                lstQuoteLineWrapper.add(objQuoteLineWrapper);
            }
            productInfoWrapper.lstCartWrapper=lstQuoteLineWrapper;
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getLineNumber()+ex.getMessage()+ex.getStackTraceString()+ex.getCause());
        }
        return productInfoWrapper;
    }
    
    
    /*************************************************************************
* @method Name  : getproductConnectApi
* @description  : Method to fetch Product Details Using ConnectApi
* @param         strCommunityId
* @param         strEffectiveAccountId
* @param         skus
*@return        :Map<String , PMC_DH_RequestForQuoteController.ConnectApiWrapper>
*****************************************************************************/
    public static Map<String , PMC_DH_RequestForQuoteController.ConnectApiWrapper> getproductConnectApi(String strCommunityId,String strEffectiveAccountId,List<String> skus){
        
        //method to fetch strwebStoreId
        String strwebStoreId=PMC_DH_MiniCart.getWebStoreId(strCommunityId);
        List<String> fields = PMC_DH_CommonSystemUtils.getListStoreConfigbyFeature(PMC_DH_ConstantClass.PRODUCT_API_FIELDS);
            ConnectApi.ProductOverviewCollection getProductDetails;
        Map<String , PMC_DH_RequestForQuoteController.ConnectApiWrapper> mapProductDetail=new Map<String,PMC_DH_RequestForQuoteController.ConnectApiWrapper>();
        try
        {
            if(!test.isRunningTest()){
                //connectApi call to get product Details
                                System.debug('strwebStoreId'+strwebStoreId);
                    System.debug('strEffectiveAccountId'+strEffectiveAccountId);
                    System.debug('skus'+skus);
                    System.debug('fields'+fields);
                    List<ConnectApi.ProductOverview> lstProducts = new List<ConnectApi.ProductOverview>();
                    for (Integer i = 0; i < skus.size(); i += 20) {
                        Integer endIndex = Math.min(i + 20, skus.size());
                        List<String> batch = new List<String>();
                        for (Integer j = i; j < endIndex; j++) {
                            batch.add(skus[j]);
                        }
                        ConnectApi.ProductOverviewCollection resp = ConnectApi.CommerceCatalog.getProducts(strwebStoreId, strEffectiveAccountId, null, batch, fields, false, true);
                        lstProducts.addAll(resp.products);
                    }
                    mapProductDetail = PMC_DH_QuoteManagementHelper.getMapProductDetail(lstProducts, skus, mapProductDetail);
                
                // added by Nikhilesh as part of GDASF-17525

                System.debug('mapProductDetail_________PMC_DH_QuoteManagementControllerClass_____'+mapProductDetail);
                // end of changes by Nikhilesh as part of GDASF-17525
            }
            else
            {
                getProductDetails=new ConnectApi.ProductOverviewCollection();
                List<ConnectApi.ProductOverview> lstProducts=new List<ConnectApi.ProductOverview>();
                ConnectApi.ProductOverview productDet=new ConnectApi.ProductOverview();
                Product2 prod = new Product2();
                prod.Name='Test Product';
                prod.ProductCode='GH-1234';
                prod.Description='Test New Description';
                prod.StockKeepingUnit='testSKU';
                prod.IsActive=TRUE;
                prod.Family='Simple';
                // if(Schema.sObjectType.Product2.isCreateable()){
                    //     insert prod;    
                // }
                productDet.sku='1234';
                productDet.Id=prod.Id;
                Map<String, String> mapFields = new Map<String, String>{'Name'=>'Test Product', 'PMC_CPQ_ProductFamily__c'=>'K-MAG', 'PMC_CPQ_QuantityUnitOfMeasure__c'=>'STN'};
                    productDet.fields=mapFields;
                ConnectApi.ProductMedia objProductMediaDetails=new ConnectApi.ProductMedia();
                objProductMediaDetails.url='https://test.com';
                productDet.defaultImage=objProductMediaDetails;
                lstProducts.add(productDet);
                ConnectApi.ProductOverview productDet2=new ConnectApi.ProductOverview();
                Product2 prod2 = new Product2(name='Test21',StockKeepingUnit='944876',isactive=true);
                
                productDet2.sku='944876';
                productDet2.Id=prod2.Id;
                Map<String, String> mapFields2 = new Map<String, String>{'Name'=>'Test21', 'PMC_CPQ_ProductFamily__c'=>'K-MAG', 'PMC_CPQ_QuantityUnitOfMeasure__c'=>'STN'};
                productDet2.fields=mapFields2;
                ConnectApi.ProductMedia objProductMediaDetails2=new ConnectApi.ProductMedia();
                objProductMediaDetails2.url='https://test.com';
                productDet2.defaultImage=objProductMediaDetails2;
                lstProducts.add(productDet2);
                getProductDetails.products=lstProducts;
                List<Product2> lstInactiveProducts = new List<Product2>();
                mapProductDetail=PMC_DH_QuoteMgmtActionController.getProd(lstProducts, lstInactiveProducts); // second parameter added by Nikhilesh as part of GDASF-17525
            }
        }
        catch(Exception ex){
            System.debug('error '+ex.getLineNumber()+ex.getMessage()+ex.getStackTraceString()+ex.getCause());
            throw new AuraHandledException(ex.getLineNumber()+ex.getMessage()+ex.getStackTraceString()+ex.getCause());
        }
        return mapProductDetail; 
    }
   
    
    /*************************************************************************

* @method Name  : updateQuote

* @description  : Method to update Quote Detail in Wrapper

* @param         quoteUpdateWrap

* @return       : PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper

*****************************************************************************/  
    
    @AuraEnabled 
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper updateQuote(PMC_DH_QuoteUpdateWrapper quoteUpdateWrap) {
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result;
        try {
            result=PMC_DH_QuoteMgmtActionController.getUpdateQuote(quoteUpdateWrap);
        }
        catch (Exception ex) {
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return result;        
    }
    
    
    /*************************************************************************

* @method Name  : updateQuoteLineItem

* @description  : Method to update QuoteLine Details in Wrapper

* @param         quoteLineItemUpdateWrap

* @return       : PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper

*****************************************************************************/  
    
    @AuraEnabled(cacheable=false)
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper updateQuoteLineItem(PMC_DH_QuoteLineUpdateWrapper quoteLineItemUpdateWrap) {
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result ;       
        try {
            
            result=PMC_DH_QuoteMgmtActionController.getUpdateQuoteLineItem(quoteLineItemUpdateWrap);
            
            
        } catch (Exception ex) {
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return result;
        
    }   
    
}