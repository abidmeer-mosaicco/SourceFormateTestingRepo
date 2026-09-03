/** 
* @description Controller for fetching and updating Request for Quote flow 
* @author Humera Rahath
* @last modified on 04-15-2024
* @last modified by Humera Rahath
* Created On       :2023-May-18
**/
public without sharing class PMC_DH_RequestForQuoteController {
    
    public static final String TEST_EXCEPTION_MESSAGE = 'Test Error thrown from PMC_DH_RequestForQuoteController class';
    public static boolean throwTestException = false;
    
    /**
* @description throw aura handled exception for test class
* @author Nikhilesh
* @date 2023-05-24
*/
    public static void throwTestExceptionForTest(){
        if (throwTestException && Test.isRunningTest()) {
            throw new AuraHandledException(TEST_EXCEPTION_MESSAGE);
        }
    }
    /*************************************************************************
* @method Name  : getQuoteCheckOutShipmentInfo
* @description  : Method to assign the ShipmentInformation of Quote Checkout in wrapper class
* @param       	strCommunityId 
* @param        strEffectiveAccountId 
* @param        strCartId
* @return       : PMC_DH_RequestForQuoteWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_RequestForQuoteWrapper getQuoteCheckOutShipmentInfo(String strCommunityId,String strEffectiveAccountId,String strCartId)
        
    {
        PMC_DH_RequestForQuoteWrapper lstQuoteShipmentInfo=new PMC_DH_RequestForQuoteWrapper();
        List<PMC_DH_RequestForQuoteWrapper.CartWrapper> lstQuoteShipment=new List<PMC_DH_RequestForQuoteWrapper.CartWrapper>();
        PMC_DH_RequestForQuoteWrapper.CartWrapper objCartWrapper;
        String strwebStoreId=PMC_DH_MiniCart.getWebStoreId(strCommunityId);
        Set<String> setProdFamilies=new Set<String>();
        try{
            throwTestExceptionForTest();
            User objUser = [SELECT Id, Country 
                            FROM User 
                            WHERE Id =: UserInfo.getUserId() 
                            WITH USER_MODE];
            Map<String,ConnectApiWrapper> mapProdConnectapiResults=getConnectApiCartItemDetails(strwebStoreId,strEffectiveAccountId,strCartId);
            Set<string> setSku=mapProdConnectapiResults.keyset();
            List<String> lstSku = new List<String>();
            lstSku.addAll(setSku);
            Map<String,PMC_DH_RequestForQuoteController.ConnectApiWrapper> mapProductDetail = PMC_DH_QuoteManagementControllerClass.getproductConnectApi(strCommunityId,strEffectiveAccountId,lstSku);
            // get user region for determining record type name
            String strRecordTypeName=PMC_DH_RequestForQuoteHelper.getQuoteRecordTypeName();
            // get account manager's primary business type
            String strAcctMgrBusinessType=PMC_DH_RequestForQuoteHelper.getUserBusinessType(strEffectiveAccountId);
            // determine the incoterm based on the user primary business type
            List<PMC_DH_PicklistWrapper> lstIncoterms=PMC_DH_QuoteUtils.getIncotermsForQuote(strAcctMgrBusinessType);
            // determine the mode of transport based on the record type
            List<PMC_DH_PicklistWrapper> lstDeliveryMode=PMC_DH_QuoteUtils.getModeOfTransportationForQuote(strRecordTypeName);
            List<PMC_DH_PicklistWrapper> lstShipTo=PMC_DH_QuoteUtils.getShipToForQuote(strEffectiveAccountId);
            Map<String,List<PMC_DH_PicklistWrapper>> mapShipFrom=PMC_DH_QuoteUtils.getShipFromForQuote(setSku);
            Map<String,List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>> mapCartItems=PMC_DH_QuoteUtils.getCartItemDetails(strCartId,setSku,mapProductDetail);
            for(String strProd:mapProdConnectapiResults.keyset())
            {
                //connectApi call to fetch product details
                connectapiWrapper objProdGroupedData=mapProdConnectapiResults.get(strProd);
                objCartWrapper=new PMC_DH_RequestForQuoteWrapper.CartWrapper();
                //product Data grouped by Product sku
                objCartWrapper.strProductName=objProdGroupedData.strProductName;
                objCartWrapper.strProductId=objProdGroupedData.strProductId;
                objCartWrapper.strSku=objProdGroupedData.strSku;
                //GPT-39900
                //lstProdFamilies.add(objProdGroupedData.strProductFamily);
                objCartWrapper.strTotalQty=PMC_DH_ConstantClass.PRODUCT_QUANTITY;
                objCartWrapper.strImgSrc=objProdGroupedData.strImgSrc;
                
                //Ship to based on strEffectiveAccountId
                objCartWrapper.lstShipTo=lstShipTo;
                //Incoterms 
                objCartWrapper.lstIncoterms=lstIncoterms;
                //Mode of transportation
                objCartWrapper.lstDeliveryModes=lstDeliveryMode;
                //ShipFrom based on product sku
                objCartWrapper.lstShipFrom=mapShipFrom.get(strProd);
                //cartitems of cart
                objCartWrapper.lstCartItems=mapCartItems.get(strProd);
                //List of Product Unit Of Measure
                objCartWrapper.lstProductUOM=PMC_DH_QuoteManagementHelper.getProductUnitOfMeasureList();
                //List of Pack Type
                objCartWrapper.lstPackType=PMC_DH_QuoteManagementHelper.getPackTypeList();
                //List of Packaging Type
                //objCartWrapper.lstPackagingType=PMC_DH_QuoteManagementHelper.getPackagingTypeList();//Removed as part of GDASF-20003
                //List of Mode of transportation for incoterm CPT - GDASF-20218
                objCartWrapper.lstDeliveryModesCPT = PMC_DH_RequestForQuoteUtil.getModeOfTransportationForCPT();
                //Unit Of Measure
                objCartWrapper.strProductUOM = PMC_DH_QuoteManagementHelper.getUnitOfMeasureForQuoteLine(objCartWrapper.lstCartItems[0], objUser.Country);
                
                lstQuoteShipment.add(objCartWrapper);
            }
            setProdFamilies=getProductFamilies(strCartId,setSku);
            lstQuoteShipmentInfo.lstProductFamilies=new List<String>(setProdFamilies);//GPT-39900
            lstQuoteShipmentInfo.lstCartWrapper=lstQuoteShipment;
            lstQuoteShipmentInfo.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'Quote Creation Success');
            
        }
        catch(Exception ex){
            lstQuoteShipmentInfo.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return lstQuoteShipmentInfo;
    }
    
    /*************************************************************************
* @method Name  : getCartItemDetails
* @description  : Method to assign the ShipmentInformation of Quote Checkout in wrapper class
* @param       	strWebStoreId 
* @param        strEffectiveAccountId 
* @param        strCartId
* @return       : Map<String,ConnectApiWrapper>
*****************************************************************************/
    public static Map<String,ConnectApiWrapper> getConnectApiCartItemDetails(String strWebStoreId,String strEffectiveAccountId,String strCartId)
    {
        Map<String,ConnectApiWrapper> mapConnectapiProduct
            =new Map<String,ConnectApiWrapper>();
        connectapiWrapper objconnectapiProduct;
        ConnectApi.CartItemCollection objcartItemCollection;//try-catch removed
            String strCartItemID=[Select id from CartItem where cartId=:strCartId WITH SECURITY_ENFORCED LIMIT 1].ID;
        
        	throwTestExceptionForTest(); 
            if(!test.isRunningTest()){
                
                objcartItemCollection = ConnectApi.CommerceCart.getCartItems(strWebStoreId, strEffectiveAccountId, strCartId,null,null,null,null,null);
            }
            else
            {
                objcartItemCollection =new ConnectApi.CartItemCollection();
                List<ConnectApi.CartItemResult> lstCartItemCollection1=new List<ConnectApi.CartItemResult>();
                ConnectApi.CartItemResult cartItemsres=new ConnectApi.CartItemResult();
                ConnectApi.CartItem cartItem = new ConnectApi.CartItem();
                cartItem.cartItemId=strCartItemID;
                cartItem.quantity='25';
                ConnectApi.CartItemProduct objProductDetails=new ConnectApi.CartItemProduct();
                objProductDetails.sku='1234';
                objProductDetails.name='TestProduct';
                objProductDetails.productId='7878987899';
                Map<String,String> mapProdFields=new Map<String,String>();
                mapProdFields.put('PMC_CPQ_ProductFamily__c','K-MAG');
                objProductDetails.fields=mapProdFields;               //GPT-39900
                ConnectApi.ProductMedia objProductMediaDetails=new ConnectApi.ProductMedia();
                objProductMediaDetails.url='https://test.com';
                objProductDetails.thumbnailImage=objProductMediaDetails;
                cartItem.productDetails=objProductDetails;
                lstCartItemCollection1.add(cartItemsres);
                cartItemsres.cartItem=cartItem;
                objcartItemCollection.cartItems=lstCartItemCollection1;
            }
            List<ConnectApi.CartItemResult> lstCartItemCollection =objcartItemCollection.cartItems;
            for(ConnectApi.CartItemResult cartItemsres:lstCartItemCollection)
            {
                objconnectapiProduct=new connectapiWrapper();
                
                ConnectApi.AbstractCartItem objAbstractCartItem=cartItemsres.cartItem;
                objconnectapiProduct.strCartItemId=objAbstractCartItem.cartItemId;
                objconnectapiProduct.strTotalQty=objAbstractCartItem.Quantity;
                
                ConnectApi.CartItemProduct objProductDetails=objAbstractCartItem.productDetails;
                objconnectapiProduct.strProductName=objProductDetails.Name;
                objconnectapiProduct.strProductId=objProductDetails.productId;
                objconnectapiProduct.strSku=objProductDetails.sku;
                
                Map<String,String> mapProdFields=(Map<String,String>)objProductDetails.fields;
                objconnectapiProduct.strProductFamily=mapProdFields.get('PMC_CPQ_ProductFamily__c');
                //GPT-39900
                PMC_DH_Store_Configuration__mdt config = PMC_DH_Store_Configuration__mdt.getInstance('Default_Image_URL');
 
                String strimageUrl=config.PMC_DH_Default_Image_Url__c;            
                ConnectApi.ProductMedia objProductMedia=objProductDetails.thumbnailImage;
                if(objProductMedia!=null) {
                    strimageUrl=objProductMedia.url;
                    objconnectapiProduct.strImgSrc = PMC_DH_Store_Configuration__mdt.getInstance('Prepended_Image_Url').PMC_DH_Prepended_Image_Url__c+ objProductMedia.url;
                }
                //PMC_DH_Store_Configuration__mdt configuration = PMC_DH_Store_Configuration__mdt.getInstance('Prepended_Image_Url');
                if(strimageUrl==config.PMC_DH_Default_Image_Url__c){
                    objconnectapiProduct.strImgSrc='';
                }
                /*else{
                    PMC_DH_Store_Configuration__mdt configuration = PMC_DH_Store_Configuration__mdt.getInstance('Prepended_Image_Url');
                    objconnectapiProduct.strImgSrc = configuration.PMC_DH_Prepended_Image_Url__c+ objProductMedia.url;
                }*/
                if(!mapConnectapiProduct.containsKey(objconnectapiProduct.strSku)){
                    mapConnectapiProduct.put(objconnectapiProduct.strSku,objconnectapiProduct);
                }
            }
        
        return mapConnectapiProduct;
    }
    
    /*************************************************************************
* @method Name  : getPaymentInfoForCart
* @param strCountry : Country name
* @param strCartId : Cart Id
* @description  : Method to get the payment information of Quote Checkout in wrapper class
* @return       : PaymentInfoWrapper
*****************************************************************************/
    @AuraEnabled(cacheable=false)
    public static PaymentInfoWrapper getPaymentInfoForCart(String strCountry, String strCartId){
        PaymentInfoWrapper objPaymentInfoWrapper = new PaymentInfoWrapper();
        try
        {
            throwTestExceptionForTest();
            Set<String> lstModule = new Set<String>{'PaymentMethod', 'CurrencyCode', 'PaymentTerm'};
                List<PMC_DH_PicklistWrapper> lstCurrencyIsoCode = new List<PMC_DH_PicklistWrapper>();
            List<PMC_DH_PicklistWrapper> lstPaymentMethods = new List<PMC_DH_PicklistWrapper>();
            List<PMC_DH_PicklistWrapper> lstPaymentTerms = new List<PMC_DH_PicklistWrapper>();
            PMC_DH_PaymentInformationForQuoteWrapper objPaymentInfo = new PMC_DH_PaymentInformationForQuoteWrapper();
            Map<String,String> mapTranslatedPaymentTerms = PMC_DH_QuoteManagementHelper.createPaymentTermsMapFrTranslations(SBQQ__Quote__c.SBQQ__PaymentTerms__c.getDescribe());
            List<PMC_DH_CheckoutConfig__mdt> lstCheckoutConfig = PMC_DH_QuoteUtils.getCheckoutConfigs(lstModule, strCountry, 'RequestForQuote');
            for(PMC_DH_CheckoutConfig__mdt objCheckoutConfig : lstCheckoutConfig){
                switch on objCheckoutConfig.Module__c {
                    when 'PaymentMethod' {		// when block 1
                        PMC_DH_PicklistWrapper pickList = new PMC_DH_PicklistWrapper();
                        pickList.label = objCheckoutConfig.MasterLabel;
                        pickList.value = objCheckoutConfig.PicklistAPI_Name__c;
                        lstPaymentMethods.add(pickList);
                    }	
                    when 'CurrencyCode' {		// when block 2
                        PMC_DH_PicklistWrapper pickList = new PMC_DH_PicklistWrapper();
                        pickList.label = objCheckoutConfig.PicklistAPI_Name__c;
                        pickList.value = objCheckoutConfig.PicklistAPI_Name__c;
                        lstCurrencyIsoCode.add(pickList);
                    }
                    when 'PaymentTerm' {		// when block 3
                        if(mapTranslatedPaymentTerms.containsKey(objCheckoutConfig.PicklistAPI_Name__c)){
                        PMC_DH_PicklistWrapper pickList = new PMC_DH_PicklistWrapper();
                        pickList.label = mapTranslatedPaymentTerms.get(objCheckoutConfig.PicklistAPI_Name__c);
                        pickList.value = objCheckoutConfig.PicklistAPI_Name__c;
                        lstPaymentTerms.add(pickList);
                    }
                }
            }
            }
            
            WebCart objWebCart = [SELECT Id, PMC_DH_ContractStartDate__c, PMC_DH_ContractEndDate__c, PMC_DH_Currency__c, PMC_DH_PaymentMethod__c,PMC_DH_PaymentTerms__c,PMC_DH_PrepaymentDate__c
                                  FROM WebCart
                                  WHERE Id =: strCartId
                                  WITH SECURITY_ENFORCED LIMIT 1];
            objPaymentInfo.strCartId = objWebCart.Id;
            objPaymentInfo.datContractStartDate = objWebCart.PMC_DH_ContractStartDate__c;
            objPaymentInfo.datContractEndDate = objWebCart.PMC_DH_ContractEndDate__c;
            objPaymentInfo.strPaymentTerms = objWebCart.PMC_DH_PaymentTerms__c;
            objPaymentInfo.strPaymentMethods = objWebCart.PMC_DH_PaymentMethod__c;
            objPaymentInfo.strCurrencyIsoCode = objWebCart.PMC_DH_Currency__c;
            objPaymentInfo.datPrepaymentDate = objWebCart.PMC_DH_PrepaymentDate__c;//Added as part of GDASF-19809
            objPaymentInfoWrapper.lstCurrencyIsoCode = lstCurrencyIsoCode;
            objPaymentInfoWrapper.lstPaymentMethods = lstPaymentMethods;
            objPaymentInfoWrapper.lstPaymentTerms = lstPaymentTerms;
            objPaymentInfoWrapper.objPaymentInfo = objPaymentInfo;
            objPaymentInfoWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'Payment Information');
            //return objPaymentInfoWrapper;
        }
        
        catch(Exception ex){
            objPaymentInfoWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
             PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return objPaymentInfoWrapper;
    }

    /*************************************************************************
* @method Name  : updatePaymentInfoForCart
* @description  : Method to update the payment information of Quote Checkout in wrapper class
* @param       	paymentInfoWrapper PMC_DH_PaymentInformationForQuoteWrapper
* @return       : PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper updatePaymentInfoForCart(PMC_DH_PaymentInformationForQuoteWrapper paymentInfoWrapper){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper cartItemsResult = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        try{
            //throwTestExceptionForTest();
            WebCart objWebCart = new WebCart();
            objWebCart.Id = paymentInfoWrapper.strCartId;
            objWebCart.PMC_DH_ContractStartDate__c = paymentInfoWrapper.datContractStartDate;
            objWebCart.PMC_DH_ContractEndDate__c = paymentInfoWrapper.datContractEndDate;
            objWebCart.Status='Active';
            //objWebCart.CurrencyIsoCode = paymentInfoWrapper.strCurrencyIsoCode;
            objWebCart.PMC_DH_Currency__c = paymentInfoWrapper.strCurrencyIsoCode;
            objWebCart.PMC_DH_PaymentMethod__c = paymentInfoWrapper.strPaymentMethods;
            //GDASF-21170
            if(String.isnotBlank(paymentInfoWrapper.strPaymentTerms)){
                objWebCart.PMC_DH_PaymentTerms__c = paymentInfoWrapper.strPaymentTerms;
                objWebCart.PMC_DH_PrepaymentDate__c = PMC_DH_RequestForQuoteUtil.setPrePaymentDate(objWebCart,paymentInfoWrapper);//Added as part of GDASF- 19809
            }
            String strAccId=[Select AccountId from WebCart where Id=:paymentInfoWrapper.strCartId][0].AccountId;
            objWebCart.PMC_DH_Account__c=strAccId;
            PMC_DH_RequestForQuoteHelper.PMC_DH_SalesAreaForCartWrapper salesAreaCartWrapper=PMC_DH_RequestForQuoteHelper.getSalesAreaForCart(paymentInfoWrapper.strCartId);
            PMC_DH_RequestForQuoteHelper.PMC_DH_SalesAreaForCartWrapper salesAgreementWrapper=PMC_DH_SalesAgreementUtils.updateSalesAgreementId(paymentInfoWrapper.strCartId);
            
            if((salesAreaCartWrapper!=null) && (salesAreaCartWrapper.boolIsPriceEnabled)){
                objWebCart.PMC_DH_SalesArea__c = salesAreaCartWrapper.strSalesArea;
                
            }
            
            if((salesAgreementWrapper!=null) && (salesAgreementWrapper.boolIsPriceEnabled)){
                objWebCart.PMC_DH_SalesAgreement__c = salesAgreementWrapper.strSalesArea;
                
            }
            if(!paymentInfoWrapper.lstProductFamilies.isEmpty()){
                
                String strOppId=PMC_SS_PriceCheckOpportunityHandler.createOpportunityForGetPriceCall(strAccId,paymentInfoWrapper.lstProductFamilies, paymentInfoWrapper.strCurrencyIsoCode);  
                objWebCart.PMC_DH_Opportunity__c=strOppId;  
            }
            if(Schema.sObjectType.WebCart.isUpdateable()){
                update objWebCart;
            }
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'CartUpdate');
            cartItemsResult = updatePaymentInfoForCartItems(objWebCart);
        }
        catch(Exception e){           
            PMC_ErrorLogClass.processException(e);// MDErrorLog
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
            result.strStatusMessage = result.strStatusMessage + e.getMessage() + e.getStackTraceString();
        }
        return result;
    }
    /*************************************************************************
* @method Name  : updatePaymentInfoForCartItems
* @description  : Method to update the payment information of Quote Checkout in wrapper class
* @param       	objWebCart
* @return       : PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper updatePaymentInfoForCartItems(WebCart objWebCart){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        List<CartItem> updatedListCartItems = new List<CartItem>();
        try{
            List<CartItem> lstCartItems = [SELECT Id,cart.PMC_DH_PaymentTerms__c,PMC_DH_Number__c,CurrencyIsoCode FROM CartItem WHERE Cart.Id =: objWebCart.Id WITH SECURITY_ENFORCED ORDER BY CREATEDDATE];
            Integer cartSequenceForGetPrice=1;
            for(CartItem ci : lstCartItems){
                ci.PMC_DH_Number__c=cartSequenceForGetPrice;
                ci.PMC_DH_Prepay__c=PMC_DH_MiniCart.updatePrepayField(ci);
                updatedListCartItems.add(ci);
                cartSequenceForGetPrice=cartSequenceForGetPrice+1;
            }
            if(Schema.sObjectType.CartItem.isUpdateable()){
                update updatedListCartItems;
            }
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'CartItemsUpdate');
        }
        catch(Exception e){
            PMC_ErrorLogClass.processException(e);// MDErrorLog
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
            result.strStatusMessage = result.strStatusMessage + e.getMessage() + e.getStackTraceString();
        }
        return result;
    }
    /*************************************************************************
* @method Name  : createQuoteFromCart
* @description  : Method to create the quote for a given cart
* @param       	cartId String 
* @param        quoteName String
* @return       : PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper createQuoteFromCart(String cartId, String quoteName){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        SBQQ__Quote__c objQuote = new SBQQ__Quote__c();
        List<SBQQ__QuoteLine__c> lstQuoteItems = new List<SBQQ__QuoteLine__c>();
        String userId;
        try {
            String strUserId=userInfo.getUserId();
            List<User> lstUser=PMC_DH_UserUtil.getUserData(strUserId);
            String strUserRegion = PMC_DH_CommonSystemUtils.getUserRegion(lstUser[0].country);
            
            WebCart objWebCart = [SELECT Id, Status, AccountId, PMC_DH_Account__c, PMC_DH_Account__r.OwnerId,PMC_DH_Account__r.PMC_CPQ_PaymentTerms__c, PMC_DH_ContractStartDate__c, PMC_DH_ContractEndDate__c, PMC_DH_Currency__c, PMC_DH_PaymentMethod__c, PMC_DH_PaymentTerms__c, PMC_DH_QuoteFriendlyName__c,PMC_DH_Opportunity__c,PMC_DH_PrepaymentDate__c  
                                  FROM WebCart
                                  WHERE Id =: cartId LIMIT 1];
            objWebCart.PMC_DH_QuoteFriendlyName__c = quoteName;
            if(Schema.sObjectType.WebCart.isUpdateable()){
                update objWebCart;
            }
            
            if(objWebCart != null){
                objQuote.SBQQ__Account__c = objWebCart.AccountId;
                objQuote.PMC_CPQ_ContractStart__c = objWebCart.PMC_DH_ContractStartDate__c;
                objQuote.PMC_CPQ_ContractEnd__c  = objWebCart.PMC_DH_ContractEndDate__c;
                objQuote.PMC_DH_PaymentMethod__c = objWebCart.PMC_DH_PaymentMethod__c;
                //GDASF-21170
                if(strUserRegion=='NA'){
                    objQuote.SBQQ__PaymentTerms__c=objWebCart.PMC_DH_Account__r.PMC_CPQ_PaymentTerms__c;
                }
                else{
                    objQuote.SBQQ__PaymentTerms__c = objWebCart.PMC_DH_PaymentTerms__c;
                    //Added as part of GDASF-19809
                object obWebCart = objWebCart;
                objQuote.PMC_CPQ_PaymentDate__c = PMC_DH_RequestForQuoteUtil.setPaymentDate(obWebCart);
                }
               objQuote.PMC_DH_QuoteFriendlyName__c  = objWebCart.PMC_DH_QuoteFriendlyName__c ;
                objQuote.SBQQ__Status__c  = PMC_DH_ConstantClass.QUOTE_STATUS_REQUEST;
                objQuote.PMC_CPQ_PrimaryContact__c=lstUser[0].contactId;
                objQuote.PMC_CPQ_CustomCreatedDate__c=system.now();
                objQuote.RecordTypeId=PMC_DH_RequestForQuoteHelper.getQuoteRecordType(strUserRegion);
                objQuote.CurrencyIsoCode = objWebCart.PMC_DH_Currency__c;
                objQuote.PMC_CPQ_Currency__c = objWebCart.PMC_DH_Currency__c; //  added as part of GDASF-10075 
                objQuote.PMC_CPQ_QuoteOrigin__c = PMC_DH_ConstantClass.DH_REQUEST;
                objQuote.SBQQ__Opportunity2__c=objWebCart.PMC_DH_Opportunity__c;                   
                userId = objWebCart.PMC_DH_Account__r.OwnerId;
                objQuote.PMC_CPQ_AccountManager__c = userId;
                
                // Get primary business type and sales area from Account Owner (User)
                User userAM = [SELECT Id, PMC_CPQ_PrimaryBusinessType__c,LocaleSidKey, PMC_CPQ_SalesArea__c,PMC_CPQ_SalesRegion__c,PMC_CPQ_SalesOffice__c FROM User WHERE Id =: userId WITH SYSTEM_MODE LIMIT 1];
                objQuote.PMC_CPQ_Region__c =userAM.PMC_CPQ_SalesRegion__c;// added as GDASF-19630
                objQuote.PMC_CPQ_QuoteRecordSubType__c = userAM.PMC_CPQ_PrimaryBusinessType__c;
                objQuote.PMC_CPQ_SalesOffice__c=userAM.PMC_CPQ_SalesOffice__c;
                
				String strSalesArea = userAM.PMC_CPQ_SalesArea__c;
                objQuote.PMC_CPQ_SalesArea__c =PMC_DH_RequestForQuoteUtil.getSalesArea(strSalesArea ,objWebCart);
                // need to set values for SBQQ__StartDate__c and SBQQ__EndDate__c/PMC_CPQ_ExpirationDate__c
            }
            if(Schema.sObjectType.SBQQ__Quote__c.isCreateable()){
                insert objQuote;
            }
            PMC_DH_RequestForQuoteHelper.stampOwner(objQuote,objWebCart); // fix for cross-entity reference issue GPT-26559
            SBQQ__Quote__c createdQuote = [SELECT Name, RecordType.Name, PMC_CPQ_QuoteRecordSubType__c FROM SBQQ__Quote__c WHERE Id =: objQuote.Id WITH SECURITY_ENFORCED LIMIT 1];
            String quoteId = objQuote.Id;
            String quoteNumber = createdQuote.Name;
            lstQuoteItems = PMC_DH_QuoteManagementHelper.createQuoteFromCartHelper(cartId,objQuote,objWebCart);
            if(Schema.sObjectType.SBQQ__QuoteLine__c.isCreateable()){
                insert lstQuoteItems;
            }
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'QuoteCreation');
            PMC_DH_CadenceUtil.createCadence(quoteId, false);//Calling this method to create Cadence record
            QuoteInfoWrapper quoteWrp = new QuoteInfoWrapper();
            quoteWrp.quoteId = quoteId;
            quoteWrp.quoteNumber = quoteNumber;
            result.strData = JSON.serialize(quoteWrp);
            objWebCart.Status = PMC_DH_ConstantClass.CLOSED;
            update objWebCart;
        } catch (Exception e) {
            PMC_ErrorLogClass.processException(e);// MDErrorLog
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
            result.strStatusMessage = result.strStatusMessage + e.getMessage() + e.getStackTraceString(); 
        }
        return result;
    }
    /*************************************************************************
* @method Name  : ConnectApiWrapper
* @description  : Wrapper class for ConnectApi Result
*****************************************************************************/
    public with sharing class ConnectApiWrapper{
        /**
* @description Product Name of CartItem
* @return  String 
*/
        public string strProductName{get;set;}
        /**
* @description Product Id of CartItem
* @return  String 
*/
        public string strProductId{get;set;}
        /**
* @description Product Sku of CartItem
* @return  String 
*/
        public string strSku{get;set;}
        /**
* @description Product Img Url of CartItem
* @return  String 
*/
        public string strImgSrc{get;set;}
        /**
* @description Total Quantity of CartItem
* @return  String 
*/
        public string strTotalQty{get;set;}
        /**
* @description MoT of CartItem
* @return  String 
*/
        public string strDeliveryMode{get;set;}
        /**
* @description RecordId of CartItem
* @return  String 
*/
        public string strCartItemId{get;set;}
        /**
* @description product Family of CartItem
* @return  String 
*/
        public string strProductFamily{get;set;}
        /**
* @description product UOM of CartItem
* @return  String 
*/
        public string strProductUOM{get;set;}
        /**
* @description product Pack Type of CartItem
* @return  String 
*/
        public string strProductPackType{get;set;}
    

    }
    
    
    /*************************************************************************
* @method Name  : PaymentInfoWrapper
* @description  : Wrapper class for Payment Info
*****************************************************************************/
    public with sharing class PaymentInfoWrapper{
        /**
* @description List for value label picklist
* @return 		List<PMC_DH_PicklistWrapper>
**/
        @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstCurrencyIsoCode{get;set;}
        
        /**
* @description List for value label picklist
* @return 		List<PMC_DH_PicklistWrapper>
**/
        @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstPaymentTerms{get;set;}
        
        /**
* @description List for value label picklist
* @return 		List<PMC_DH_PicklistWrapper>
**/
        @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstPaymentMethods{get;set;}
        
        /**
* @description Cart info which is already processed
* @return 		PMC_DH_PaymentInformationForQuoteWrapper
**/
        @AuraEnabled
        public PMC_DH_PaymentInformationForQuoteWrapper objPaymentInfo{get;set;}
        /**
* @description Status Code and message
* @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*/
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    }
    
    /*************************************************************************
* @method Name  : QuoteInfoWrapper
* @description  : Wrapper class for quote Info
*****************************************************************************/
    public with sharing class QuoteInfoWrapper{
        /**
* @description Quote ID
* @return  String 
*/
        public string quoteId{get;set;}
        /**
* @description Quote Number
* @return  String 
*/
        public string quoteNumber{get;set;}
    }
    
    /*************************************************************************
* @method Name  : getProductFamilies
* @param strCartId 
* @param setSku
* @description  : Method to get the product families of cart items
* @return       : Set<String>
*****************************************************************************/
    //GPT-39900
    public static Set<String> getProductFamilies(String strCartId,Set<String> setSku){
    Set<String> setProdFamilies=new Set<String>();
        List<CartItem> lstCartItem=[Select id,Product2.PMC_CPQ_ProductFamily__c from CartItem where cartId=:strCartId and product2.StockKeepingUnit IN: setSku WITH SECURITY_ENFORCED];
        for(CartItem cartIt:lstCartItem){
            setProdFamilies.add(cartIt.Product2.PMC_CPQ_ProductFamily__c);
          }
        return setProdFamilies;
    }
    
}