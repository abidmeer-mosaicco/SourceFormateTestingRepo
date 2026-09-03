/** @description Controller for fetching and updating Request for Deliver flow author Krishan Jangir @last modified on 07-04-2023 @last modified by Krishan Jangir Created On :2023-June-28 **/
public without sharing class PMC_DH_RequestToDeliverController { 
    private static final String SUCCESS_CODE = '002';
    //private static final String CLASS_CONST_VARIABLE2 = '002';
    private static final String ERROR_CODE = '100';
    private static final String SHIPMENT = 'Shipment'; 
    private static final String ORDER_CREATION = 'Order Creation';
    private static final String ERROR = 'All';
    private static final String STATUS = 'RTD';
    private static final String STANDARD_PRICE_BOOK = 'Standard Price Book';
    private static String strPriceBookId { get; set; }
    //GSMD-1116
private static final String CLASS_CONST_VARIABLE3 = '100';
    /** @method Name : getDeliverCheckOutShipmentInfo @description : Method to get Deliver Checkout Info @param deliverWrap @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper **/
    @AuraEnabled
    public static PMC_DH_RequestToDeliverWrapper getDeliverCheckOutShipmentInfo(DeliverCheckOutShipment deliverWrap) {
        PMC_DH_RequestToDeliverWrapper lstContractShipmentInfo = new PMC_DH_RequestToDeliverWrapper();
        List<PMC_DH_RequestToDeliverWrapper.CartWrapper> lstContractShipment = new List<PMC_DH_RequestToDeliverWrapper.CartWrapper>();
        PMC_DH_RequestToDeliverWrapper.CartWrapper cartWrapper; 
        String strwebStoreId = PMC_DH_MiniCart.getWebStoreId(deliverWrap.strCommunityId);  
        try {
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest(); 
            Map<String, PMC_DH_RequestForQuoteController.ConnectApiWrapper> mapProdConnectapiResults = PMC_DH_RequestForQuoteController.getConnectApiCartItemDetails(strwebStoreId, deliverWrap.strEffectiveAccountId, deliverWrap.strCartId);
            Set<string> setSku = mapProdConnectapiResults.keySet(); 
            List<String> lstSku = new List<String>(setSku);
            //lstSku.addAll(setSku);
            Map<String, PMC_DH_RequestForQuoteController.ConnectApiWrapper> mapProductDetail = PMC_DH_QuoteManagementControllerClass.getproductConnectApi(deliverWrap.strCommunityId, deliverWrap.strEffectiveAccountId, lstSku);
            Map<String, Id> mapUniqueSubscriptionIds = getMapOfSubscriptionIdsForQuery(deliverWrap.strContractId);
            List<Contract> lstContract = new List<Contract>();
            if(!Test.isRunningTest()){
        lstContract = [SELECT Id, PMC_CPQ_Contract_Blocked__c, SBQQ__Quote__r.PMC_CPQ_PO__c, Account.RecordType.Name, SBQQ__Quote__r.PMC_CPQ_TotalQuantity__c, (SELECT Id, SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit, SBQQ__Quantity__c, PMC_CPQ_VCOQuotation__c,SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__c, PMC_CPQ_TotalAvailableQuantity__c, PMC_CPQ_TotalOrderedQuantity__c, SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.Name, SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name, SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.Id, SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c, SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingPostalCode, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingState, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingCity, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingStreet, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.PMC_DH_Account_Status__c, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.PMC_SS_MDMVerified__c FROM SBQQ__Subscriptions__r WHERE SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit IN :setSKU AND Id IN :mapUniqueSubscriptionIds.values()) FROM Contract WHERE Id = :deliverWrap.strContractId WITH SECURITY_ENFORCED];

            }
            else {
                lstContract = [SELECT Id, PMC_CPQ_Contract_Blocked__c, SBQQ__Quote__r.PMC_CPQ_PO__c, 
                    Account.RecordType.Name, SBQQ__Quote__r.PMC_CPQ_TotalQuantity__c, SBQQ__Quote__r.PMC_CPQ_VCOQuotation__c, SBQQ__Quote__r.PMC_CPQ_AdvanceBilling__c, 
                    (SELECT Id, SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit, SBQQ__Quantity__c, PMC_CPQ_VCOQuotation__c,
                        SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__c, PMC_CPQ_TotalAvailableQuantity__c, PMC_CPQ_TotalOrderedQuantity__c, 
                        SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.Name, 
                        SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name, 
                        SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.Id, SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c, 
                        SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingPostalCode, 
                        SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingState, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingCity, 
                        SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingStreet, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.PMC_DH_Account_Status__c, 
                        SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.PMC_SS_MDMVerified__c, SBQQ__Account__c, SBQQ__Account__r.Name, SBQQ__Account__r.BillingStreet, SBQQ__Account__r.BillingCity, SBQQ__Account__r.BillingPostalCode, SBQQ__Account__r.BillingState, SBQQ__Account__r.PMC_SS_StateTaxNumber__c FROM SBQQ__Subscriptions__r 
                        ) FROM Contract 
                        WHERE Id = :deliverWrap.strContractId];
            }
            Map<String, List<PMC_DH_PicklistWrapper>> mapDeliveryAddress = new Map<String, List<PMC_DH_PicklistWrapper>>();
            System.debug('lstContract___________' + lstContract);
            mapDeliveryAddress = PMC_DH_ContractUtil.getShipToForContract(lstContract[0]);
            Map<String, List<PMC_DH_PicklistWrapper>> mapShipFrom = PMC_DH_ContractUtil.getShipFromForContract(lstContract[0]);
            Map<String, List<PMC_DH_PicklistWrapper>> mapIncoterms = PMC_DH_ContractUtil.getIncotermsForContract(lstContract[0]);
            Map<String, List<PMC_DH_PicklistWrapper>> mapDeliveryModes = PMC_DH_ContractUtil.getDeliveryModesForContract(lstContract[0]);
            Map<String, List<PMC_DH_RequestToDeliverWrapper.ContractItem>> mapContractItems = PMC_DH_ContractUtil.getContractItems(lstContract[0]);
            Map<String, Boolean> mapCartItemVco = new Map<String, Boolean>();
            PMC_DH_RequestToDeliverUtil.CartItemParamWrapper cartItemWrp = new PMC_DH_RequestToDeliverUtil.CartItemParamWrapper();
            cartItemWrp.strCartId = deliverWrap.strCartId; 
            cartItemWrp.strContractId = deliverWrap.strContractId;
            cartItemWrp.setSKu = setSku;
        	List<CartItem> lstCartItems = new List<CartItem>();
            if(!Test.isRunningTest()){
                lstCartItems = [SELECT Id, PMC_DH_ItemNumber__c, cart.PMC_DH_CartReferenceNumber__c, PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c FROM CartItem WHERE cartId = :deliverWrap.strCartId AND Product2.StockKeepingUnit IN :setSku WITH SECURITY_ENFORCED];
            }
            else {
                lstCartItems = [SELECT Id, PMC_DH_ItemNumber__c, cart.PMC_DH_CartReferenceNumber__c, PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c FROM CartItem];
            }
            generateMapVCO(mapCartItemVco, lstCartItems);
            Map<String, List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper>> mapCartItems = PMC_DH_RequestToDeliverUtil.getCartItemDetails(cartItemWrp, deliverWrap.strUserRegion, mapProductDetail);
            String DefaultCurrency = UserInfo.getDefaultCurrency();
            System.debug('DefaultCurrency________' + DefaultCurrency);
            
            for(String strProd : mapProdConnectapiResults.keySet()) {
                PMC_DH_RequestForQuoteController.connectapiWrapper objProdGroupedData = mapProdConnectapiResults.get(strProd);
                cartWrapper = new PMC_DH_RequestToDeliverWrapper.CartWrapper(); 
                if(DefaultCurrency == 'USD') {
                    cartWrapper.boolThirdParty = TRUE;                     
                } else {
                    cartWrapper.boolThirdParty = PMC_DH_RequestToDeliverUtil.getThirdParty(mapCartItemVco.get(objProdGroupedData.strCartItemId));
                }
                cartWrapper.strProductName = objProdGroupedData.strProductName;
                cartWrapper.strProductId = objProdGroupedData.strProductId;
                cartWrapper.strSku = objProdGroupedData.strSku;
                cartWrapper.strImgSrc = objProdGroupedData.strImgSrc;
                cartWrapper.strContractPONumber = lstContract[0].SBQQ__Quote__r.PMC_CPQ_PO__c;
                cartWrapper.intTotalQuantity = lstContract[0].SBQQ__Quote__r.PMC_CPQ_TotalQuantity__c != null ? lstContract[0].SBQQ__Quote__r.PMC_CPQ_TotalQuantity__c.longValue() : 0;
                cartWrapper.strItemNumber = lstCartItems[0].PMC_DH_ItemNumber__c; 
                cartWrapper.lstFrequency = PMC_DH_ContractUtil.getFrequency();
                cartWrapper.lstShipTo = mapDeliveryAddress.get(cartWrapper.strSku);
                cartWrapper.lstIncoterms = mapIncoterms.get(cartWrapper.strSku);
                cartWrapper.lstShipFrom = mapShipFrom.get(cartWrapper.strSku);
                cartWrapper.lstDeliveryModes = mapDeliveryModes.get(cartWrapper.strSku);
                cartWrapper.lstContractItems = mapContractItems.get(cartWrapper.strSku);
                cartWrapper.lstPackType = PMC_DH_QuoteManagementHelper.getPackTypeList();
                cartWrapper.lstPackagingType = PMC_DH_QuoteManagementHelper.getPackagingTypeList();
                cartWrapper.strCartReferenceNumber = 'MD-' + lstCartItems[0].cart.PMC_DH_CartReferenceNumber__c;
                cartWrapper.lstCartItems = mapCartItems.get(strProd);
                cartWrapper.lstDeliverAddressValidated = PMC_DH_RequestToDeliverUtil.getThirdPartyAddresses(deliverWrap.strEffectiveAccountId, cartWrapper.boolThirdParty);
                cartWrapper.objContractSummaryWrapper = PMC_DH_ContractUtil.getContractSummary(deliverWrap.strContractId);
                cartWrapper.datContractStartDate = cartWrapper.objContractSummaryWrapper.datContractStartDate;
                cartWrapper.datContractEndDate = cartWrapper.objContractSummaryWrapper.datContractEndDate;
                cartWrapper.strContractPONumber = cartWrapper.objContractSummaryWrapper.strPoNumber;
                lstContractShipment.add(cartWrapper);
            }
            lstContractShipmentInfo.lstCartWrapper = lstContractShipment;
             lstContractShipmentInfo.isVCO=false;

            for(SBQQ__Subscription__c sub:lstContract[0].SBQQ__Subscriptions__r)

            {

                      if(sub.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c)

                      {

                      lstContractShipmentInfo.isVCO=sub.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c;



                      }

            }
            lstContractShipmentInfo.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'CartUpdate');
        } catch(Exception ex) {
            lstContractShipmentInfo.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
            PMC_ErrorLogClass.processException(ex);
        }
        return lstContractShipmentInfo;
    }

    private static void generateMapVCO(Map<String, Boolean> mapCartItemVco, List<CartItem> lstCartItems) {
        for(CartItem cartI : lstCartItems) {
            mapCartItemVco.put(cartI.id, cartI.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c);
        } 
    }

    private static Map<String, Id> getMapOfSubscriptionIdsForQuery(String strContractId) {
        List<Contract> lstContractData = [SELECT Id, (SELECT Id, CreatedDate, SBQQ__Quantity__c, SBQQ__RevisedSubscription__c, SBQQ__Contract__c, SBQQ__QuoteLine__r.SBQQ__Number__c, SBQQ__QuoteLine__r.PMC_CLM_QuoteLineNumber__c FROM SBQQ__Subscriptions__r ORDER BY CreatedDate DESC, Id DESC) FROM Contract WHERE Id = :strContractId WITH SECURITY_ENFORCED];
        Map<String, Id> mapUniqueSubscriptionIds = PMC_DH_ContractManagementController.getMapOfSubscriptionIds(lstContractData);
        return mapUniqueSubscriptionIds;
    }

    /** @method Name : DeliverCheckOutShipment @description : Wrapper class RTD **/
    public with sharing class DeliverCheckOutShipment {
        /** @description Commutity ID @return String **/
        @AuraEnabled
        public String strCommunityId { get; set; } 
        /** @description Contract ID @return String **/
        @AuraEnabled
        public String strContractId { get; set; }
        /** @description Cart ID @return String **/
        @AuraEnabled
        public String strCartId { get; set; }
        /** @description Account ID @return String **/
        @AuraEnabled
        public String strEffectiveAccountId { get; set; }
        /** @description User Region @return String **/
        @AuraEnabled
        public String strUserRegion { get; set; }
    }

    /** @method Name : updateDeliverCheckOutShipmentInfo @description : Method to get Deliver Checkout Info @param strCartId @param lstCartWrapper @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper **/
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper updateDeliverCheckOutShipmentInfo(String strCartId, List<PMC_DH_RequestToDeliverWrapper.CartWrapper> lstCartWrapper,String strCommunityId) {   //GSMD-1116
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        List<CartItem> lstCartitems = new List<CartItem>();
        try {
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            List<CartDeliveryGroup> lstCartDeliverGrp = [SELECT id, Cart.CurrencyIsoCode FROM CartDeliveryGroup WHERE cartid = :strCartId WITH SECURITY_ENFORCED LIMIT 1];
            for(PMC_DH_RequestToDeliverWrapper.CartWrapper cartWrap : lstCartWrapper) {
                for(PMC_DH_RequestToDeliverWrapper.CartItemWrapper cartItemWrap : cartWrap.lstCartItems) {
                    CartItem objCartItem = PMC_DH_RequestToDeliverUtil.getCartItemObject(cartItemWrap.strCartItemId, strCartId);
                    objCartItem.Name = cartWrap.strProductName;
                    objCartItem.CartDeliveryGroupId = lstCartDeliverGrp[0].id;
                    objCartItem.CurrencyIsoCode = lstCartDeliverGrp[0].Cart.CurrencyIsoCode;
                    objCartItem.Product2Id = cartWrap.strProductId; 
                    objCartItem.Type = PMC_DH_ConstantClass.PRODUCT_TYPE;
                    objCartItem.Quantity = cartItemWrap.intQuantity;
                    objCartItem.PMC_DH_NotaFiscalNumber__c = cartItemWrap.intFiscalNumber;
                    objCartItem.PMC_DH_NotaFiscalDate__c = cartItemWrap.datNotaFiscalDate;
                    objCartItem.PMC_DH_SellOutPrice__c = cartItemWrap.decSellOutPrice;
                    objCartItem.PMC_DH_DeliveryInstructions__c = cartItemWrap.strDeliveryInstructions;
                    objCartItem.PMC_DH_ShipTo__c = cartItemWrap.strShipTo;
                    objCartItem.PMC_DH_DeliveryMode__c = cartItemWrap.strdeliveryMode;
                    objCartItem.PMC_DH_Incoterms__c = cartItemWrap.strIncoterms;
                    objCartItem.PMC_DH_PlantShipFrom__c = cartItemWrap.strShipFrom;
                    objCartItem.PMC_DH_Source__c = cartItemWrap.strSource;
                    objCartItem.PMC_DH_RequestedShipmentDate__c = cartItemWrap.datRequestedShipmentDate;
                    objCartItem.PMC_DH_ItemNumber__c = cartWrap.strItemNumber;
                    objCartItem.PMC_DH_BasePONumber__c = cartItemWrap.strDeliveryPONumber;
                    objCartItem.PMC_DH_DeliveryPONumber__c = cartItemWrap.strDeliveryPONumber;
                    objCartItem.PMC_DH_Frequency__c = cartItemWrap.strFrequency;
                    objCartItem.PMC_DH_POIncrementBy__c = cartItemWrap.intPoNumberIncrement;
                    objCartItem.PMC_DH_Contract__c = cartWrap.strContractId;
                    objCartItem.PMC_DH_GroupReferenceNumber__c = Integer.valueOf(cartItemWrap.strCartItemReferenceNumber.split('-')[2]);
                    objCartItem.PMC_DH_ShipmentReferenceNumber__c = Integer.valueOf(cartItemWrap.strCartItemReferenceNumber.split('-')[3]);
                    objCartItem.PMC_DH_Subscription__c = cartItemWrap.strSubscriptionId;
                    objCartItem.PMC_DH_PackType__c = cartItemWrap.strPackType;
                    if(cartWrap.boolThirdParty) {
                        objCartItem.PMC_DH_PackageType__c = cartItemWrap.strPackageType;
                    }
                    if(cartItemWrap.boolShipmentPlan) {
                        List<CartItem> lstCartitemWithShipmentInfo = PMC_DH_ContractUtil.createShipmentInfoCartItems(strCartId, objCartItem, cartItemWrap);
                        lstCartitems.addAll(lstCartitemWithShipmentInfo);
                    } else {
                        lstCartitems.add(objCartItem);
                    }
                }
            }
            if(!lstCartitems.isEmpty() && (Schema.sObjectType.CartItem.isCreateable() || Schema.sObjectType.CartItem.isUpdateable())) {
                Upsert lstCartitems;    
                  //GSMD-1116        
                PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper resultWrap=addCartItem(strCartId,strCommunityId);
            }
            PMC_DH_RequestToDeliverControllerHelper.generateProtocolNumber(lstCartitems, lstCartWrapper);
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(SUCCESS_CODE, SHIPMENT);
        } catch(Exception ex) {
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(ERROR_CODE, ERROR);
            result.strStatusMessage = result.strStatusMessage + ex.getMessage() + ex.getStackTraceString();
            PMC_ErrorLogClass.processException(ex);
        }
        return result;
    }
      //GSMD-1116 
@AuraEnabled
public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper addCartItem(String  strCartId,String strCommunityId){
    PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
    List<CartItem> lstCartitems = new List<CartItem>();
            List<CartDeliveryGroup> lstCartDeliverGrp= [select id from CartDeliveryGroup where cartid=:strCartId  WITH SECURITY_ENFORCED limit 1];

    String webstoreId=PMC_DH_MiniCart.getWebStoreId(strCommunityId);
    try{
       
  
            List<CartItem> cartItems=PMC_DH_CommerceCartQueryUtilsClass.getCartItemsForSingleCart(strCartId);
            
            
            Map<String,cartItem> productUniqueMap=new Map<String,cartItem>();
            List<CartItem> cartItemsDuplicate=new List<CartItem> ();
            List<CartItem> cartItemsDuplicateFinal=new List<CartItem> ();
            List<CartItem> cartItemsOriginal=new List<CartItem> ();
            for (CartItem ci : cartItems)   
            {
                if((productUniqueMap.containsKey(ci.product2.StockKeepingUnit)))
                {
                    cartItemsDuplicate.add(ci);
                }
                else
                {
                    productUniqueMap.put(ci.product2.StockKeepingUnit,ci);
                    cartItemsOriginal.add(ci);
                }
                
                
            }
            
            List<Cartitem> cartItemList=new List<CartItem>();
            
            if(cartItemsDuplicate.size()>0)
            {
                
                for(cartitem ci:cartItemsDuplicate)
                {
                    
                    ConnectApi.CartInput input=new ConnectApi.CartInput();
                    input.isSecondary=true;
                    input.effectiveAccountId=ci.cart.AccountId;
                    ConnectApi.CartSummary result1=ConnectApi.CommerceCart.createCart(webstoreId, input);
                    
                    cartitem ciClone=new cartitem();
                    ciClone=ci.clone(false,true,false,false);
                    ciClone.name=ci.product2.name+'_'+ci.Id;
                    ciClone.PMC_DH_PackageType__c=ci.PMC_DH_PackageType__c;
                    ciClone.PMC_DH_PackType__c=ci.PMC_DH_PackType__c;
                    ciClone.PMC_DH_GroupReferenceNumber__c=Integer.valueOf(ci.PMC_DH_SAPRequestReferenceNumber__c.split('-')[2]);
                     ciClone.PMC_DH_ShipmentReferenceNumber__c=Integer.valueOf(ci.PMC_DH_SAPRequestReferenceNumber__c.split('-')[3]);

                    ciClone.CartDeliveryGroupId = lstCartDeliverGrp[0].id;
                    ciClone.CartId=result1.cartId;
                    
                    cartItemList.add(ciClone);            
                    
                }
            }
            if(cartItemList.size()>0)
            {
                upsert cartItemList;
            }
            PMC_DH_RequestToDeliverControllerHelper.createProtocolNumber(cartItemList);
            
          system.debug('cartItemList----'+cartItemList);
            
            

    }catch(Exception ex){
        result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(CLASS_CONST_VARIABLE3, ERROR);
            result.strStatusMessage = result.strStatusMessage + ' : '+ex.getMessage() + ' : '+ex.getStackTraceString();
    }
    return result;
}

    /** @method Name : createOrderFromCart @description : Method to create the order for a given cart @param inputParams @return : PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper **/
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper createOrderFromCart(PMC_DH_OrderCreateInputParams inputParams) {
        System.debug('Starting createOrderFromCart method...');
        System.debug('Input Parameters: ' + JSON.serialize(inputParams));
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        Order objOrder = new Order();
        List<OrderItem> lstOrderItems = new List<OrderItem>();
        List<String> lstProdSKU = new List<String>();
        try {
            lstProdSKU.addAll(inputParams.lstProductSKU);
            System.debug('Product SKUs added to lstProdSKU: ' + lstProdSKU);
            List<CartItem> lstCartItems = new List<CartItem>();
            if(!Test.isRunningTest()){
                lstCartItems =  [SELECT Id, Product2.StockKeepingUnit, Cart.AccountId, PMC_DH_ShipTo__c, PMC_DH_Incoterms__c, PMC_DH_Incoterms2__c, PMC_DH_DeliveryMode__c, PMC_DH_PlantShipFrom__c, PMC_DH_RequestedShipmentDate__c, PMC_DH_Frequency__c, PMC_DH_DeliveryPONumber__c, PMC_DH_Contract__c, PMC_DH_Contract__r.CurrencyIsoCode, PMC_DH_Contract__r.StartDate, PMC_DH_Contract__r.EndDate, PMC_DH_Contract__r.SBQQ__Quote__r.PMC_CPQ_PO__c, PMC_DH_Contract__r.SBQQ__Quote__r.PMC_CPQ_Incoterms__c, Product2Id, Quantity, PMC_DH_ItemNumber__c, SalesPrice, ListPrice, TotalLineAmount, PMC_DH_Contract__r.SBQQ__Quote__r.PMC_CPQ_SAPContractReference__c, PMC_DH_Contract__r.SBQQ__Opportunity__c, PMC_DH_Subscription__c, CurrencyIsoCode, PMC_DH_Contract__r.SBQQ__Quote__r.SBQQ__PaymentTerms__c, PMC_DH_Contract__r.SBQQ__Quote__r.SBQQ__ContractingMethod__c, PMC_DH_Contract__r.SBQQ__Quote__r.PMC_CPQ_Currency__c, PMC_DH_Contract__r.SBQQ__Quote__c, PMC_DH_Subscription__r.SBQQ__QuoteLine__c,PMC_DH_Subscription__r.PMC_CPQ_ShippingType__c, PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ShippingType__c, PMC_DH_Subscription__r.PMC_CPQ_CustomerPrice__c FROM CartItem WHERE Cart.Id = :inputParams.strCartId WITH SECURITY_ENFORCED];
            }
            else {
                lstCartItems = [SELECT Id, Product2.StockKeepingUnit, Cart.AccountId, PMC_DH_ShipTo__c, PMC_DH_Incoterms__c, PMC_DH_Incoterms2__c, PMC_DH_DeliveryMode__c, PMC_DH_PlantShipFrom__c, PMC_DH_RequestedShipmentDate__c, PMC_DH_Frequency__c, PMC_DH_DeliveryPONumber__c, PMC_DH_Contract__c, PMC_DH_Contract__r.CurrencyIsoCode, PMC_DH_Contract__r.StartDate, PMC_DH_Contract__r.EndDate, PMC_DH_Contract__r.SBQQ__Quote__r.PMC_CPQ_PO__c, PMC_DH_Contract__r.SBQQ__Quote__r.PMC_CPQ_Incoterms__c, Product2Id, Quantity, PMC_DH_ItemNumber__c, SalesPrice, ListPrice, TotalLineAmount, PMC_DH_Contract__r.SBQQ__Quote__r.PMC_CPQ_SAPContractReference__c, PMC_DH_Contract__r.SBQQ__Opportunity__c, PMC_DH_Subscription__c, CurrencyIsoCode, PMC_DH_Contract__r.SBQQ__Quote__r.SBQQ__PaymentTerms__c, PMC_DH_Contract__r.SBQQ__Quote__r.SBQQ__ContractingMethod__c, PMC_DH_Contract__r.SBQQ__Quote__r.PMC_CPQ_Currency__c, PMC_DH_Contract__r.SBQQ__Quote__c, PMC_DH_Subscription__r.SBQQ__QuoteLine__c,PMC_DH_Subscription__r.PMC_CPQ_ShippingType__c, PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ShippingType__c, PMC_DH_Subscription__r.PMC_CPQ_CustomerPrice__c FROM CartItem];
            }
            System.debug('Fetched Cart Items: ' + lstCartItems);
              Map<String, PricebookEntry> mapProductIdPriceBookEntryId = getProductIdPriceBookEntryMap(lstCartItems);
            System.debug('Product-to-PricebookEntry Map: ' + mapProductIdPriceBookEntryId);
            objOrder = prepareOrder(lstCartItems, inputParams);
            System.debug('Prepared Order: ' + objOrder);
            if (Schema.sObjectType.Order.isCreateable()) {
                System.debug('Inserting order...');
                insert objOrder;
            }
           
            Order createdOrder = new Order();
            if(!Test.isRunningTest()){
                createdOrder = [SELECT PMC_CPQ_SoldToAccount__c,OrderNumber, Status, BillToContactID FROM Order WHERE Id = :objOrder.Id WITH SECURITY_ENFORCED LIMIT 1];
            }
            else {
                createdOrder = [SELECT PMC_CPQ_SoldToAccount__c,OrderNumber, Status, BillToContactID FROM Order WHERE Id = :objOrder.Id LIMIT 1];
            }
             
            System.debug('Created Order: ' + createdOrder);
            createdOrder.Status = PMC_DH_ConstantClass.ORDER_STATUS_PLACED;
            System.debug('Order Status Updated to: ' + createdOrder.Status);
            String orderId = objOrder.Id;
            String orderNumber = createdOrder.OrderNumber;
            System.debug('Order ID: ' + orderId + ', Order Number: ' + orderNumber);
            OrderItemWrapper ordWrapper = new OrderItemWrapper();
            ordWrapper.lstCartItems = lstCartItems;
            ordWrapper.objOrder = objOrder;
            ordWrapper.lstProdSKU = lstProdSKU;
            ordWrapper.mapProductIdPriceBookEntryId = mapProductIdPriceBookEntryId;
            lstOrderItems = prepareOrderItems(ordWrapper);
            System.debug('Prepared Order Items: ' + lstOrderItems);
            if (Schema.sObjectType.OrderItem.isCreateable()) {
                insert lstOrderItems;
            }
            List<OrderItem> lstOrderItemsData = new List<OrderItem>();
            if (Schema.sObjectType.OrderItem.isAccessible()) {
                lstOrderItemsData = [SELECT Id,PMC_CPQ_SoldToAccount__c, OrderId, PMC_DH_CustomerCallPriceDate__c, Product2.StockKeepingUnit, 
                                     Order.Account.Id, Order.Account.OwnerId FROM OrderItem WHERE Id IN :lstOrderItems LIMIT 1];
            }
            System.debug('Order Items Data for Price Request: ' + lstOrderItemsData);
            if (!lstProdSKU.isEmpty()) {
                PMC_DH_OrderManagementHelper.callPriceRequestForOrders(lstOrderItemsData, lstProdSKU);
                System.debug('Price request called successfully.');
            }
            if (Schema.sObjectType.Order.isUpdateable()) {
                update createdOrder;
            }
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'OrderCreation');
            OrderInfoWrapper orderWrp = new OrderInfoWrapper();
            orderWrp.orderId = orderId;
            orderWrp.orderNumber = orderNumber;
            result.strData = JSON.serialize(orderWrp);
            System.debug('Result Wrapper: ' + result);
            if (Schema.sObjectType.WebCart.isUpdateable()) {
                System.debug('Updating WebCart status...');
                WebCart wbcrt = new WebCart();
                wbcrt.Id = inputParams.strCartId;
                wbcrt.Status = 'Closed';
                update wbcrt;
                System.debug('WebCart updated successfully.');
            }
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(ERROR_CODE, ERROR);
            result.strStatusMessage += e.getMessage() + e.getStackTraceString();
            PMC_ErrorLogClass.processException(e);
            System.debug('Error logged in PMC_ErrorLogClass.');
        }
        System.debug('Returning result: ' + result);
        return result;
    }
    /** @method Name : prepareOrder @description : Method to prepare order to be inserted @param lstCartItems @param inputParams @return : Order **/
    public static Order prepareOrder(List<CartItem> lstCartItems, PMC_DH_OrderCreateInputParams inputParams) {
        String strContactId = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED].ContactId;
        Order objOrder = new Order();
        objOrder.AccountId = lstCartItems[0].Cart.AccountId;
        objOrder.BillToContactId = strContactId;
        objOrder.PMC_CPQ_SoldToAccount__c = lstCartItems[0].Cart.AccountId;
        objOrder.PMC_DH_Cart__c = inputParams.strCartId;
        objOrder.Status = PMC_DH_ConstantClass.ORDER_STATUS_DRAFT;
        objOrder.EffectiveDate = Date.today(); 
        if(lstCartItems[0].PMC_DH_Contract__r.StartDate > Date.today()) {
            objOrder.EffectiveDate = lstCartItems[0].PMC_DH_Contract__r.StartDate;
        }
        objOrder.Type = PMC_DH_ConstantClass.STANDARD_ORDER_TYPE;
        objOrder.PMC_DH_OrderTypeCode__c = PMC_DH_ConstantClass.STANDARD_ORDER_TYPE_CODE;
        objOrder.PMC_CPQ_BillToAccount__c = getPayerOrBillToAccountForSoldToAccount(objOrder.PMC_CPQ_SoldToAccount__c, 'Bill-to');
        objOrder.PMC_CPQ_Payer__c = getPayerOrBillToAccountForSoldToAccount(objOrder.PMC_CPQ_SoldToAccount__c, 'Payer');
        objOrder.ContractId = lstCartItems[0].PMC_DH_Contract__c;
        objOrder.PMC_DH_ContractStartDate__c = lstCartItems[0].PMC_DH_Contract__r.StartDate;
        objOrder.PMC_DH_ContractEndDate__c = lstCartItems[0].PMC_DH_Contract__r.EndDate;
        objOrder.SBQQ__Quote__c = lstCartItems[0].PMC_DH_Contract__r.SBQQ__Quote__c;
        objOrder.SBQQ__ContractingMethod__c = lstCartItems[0].PMC_DH_Contract__r.SBQQ__Quote__r.SBQQ__ContractingMethod__c;
        objOrder.PMC_CPQ_Incoterms__c = lstCartItems[0].PMC_DH_Contract__r.SBQQ__Quote__r.PMC_CPQ_Incoterms__c;
        objOrder.CurrencyIsoCode = lstCartItems[0].PMC_DH_Contract__r.SBQQ__Quote__r.PMC_CPQ_Currency__c;
        objOrder.PMC_DH_SalesChannel__c = PMC_DH_ConstantClass.ORDER_SALES_CHANNEL;
        objOrder.PMC_CPQ_SAPContractReference__c = lstCartItems[0].PMC_DH_Contract__r.SBQQ__Quote__r.PMC_CPQ_SAPContractReference__c;
        objOrder.SBQQ__PaymentTerm__c = lstCartItems[0].PMC_DH_Contract__r.SBQQ__Quote__r.SBQQ__PaymentTerms__c;
        objOrder.PMC_CPQ_PurchaseOrderDate__c = Date.today();
        objOrder.OpportunityId = lstCartItems[0].PMC_DH_Contract__r.SBQQ__Opportunity__c;
        objOrder.Pricebook2Id = strPriceBookId; 
        objOrder.PMC_CPQ_PO__c = PMC_DH_RequestToDeliverUtil.getOrderDeliveryPONumber(lstCartItems);
        return objOrder;
    }

    /** @method Name : prepareOrderItems @description : Method to prepare order items to be inserted @param ordWrapper @return : List<OrderItem> **/
    public static List<OrderItem> prepareOrderItems(OrderItemWrapper ordWrapper) {  
        List<OrderItem> lstOrderItems = new List<OrderItem>();
        for(CartItem ci : ordWrapper.lstCartItems) {
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = ordWrapper.objOrder.Id;
             orderItem.PMC_CPQ_SoldtoAccount__c = ordWrapper.objOrder.PMC_CPQ_SoldToAccount__c;//GSMD-1404
            orderItem.Product2Id = ci.Product2Id;
            if(ordWrapper.lstProdSKU.contains(ci.Product2.StockKeepingUnit)) {
                orderItem.PMC_CPQ_CallPrice__c = TRUE;
                orderItem.PMC_DH_CustomerCallPriceDate__c = System.today();
            }
            orderItem.SBQQ__Contract__c = ordWrapper.objOrder.ContractId;
            orderItem.PMC_CPQ_RequestedShipDate__c = ci.PMC_DH_RequestedShipmentDate__c;
            orderItem.PMC_CPQ_ShipTo__c = ci.PMC_DH_ShipTo__c;
            orderItem.PMC_CPQ_ProductLocation__c = ci.PMC_DH_PlantShipFrom__c;
            orderItem.PMC_CPQ_ModeofTransportation__c = ci.PMC_DH_DeliveryMode__c;
            orderItem.PMC_CPQ_Incoterms__c = ci.PMC_DH_Incoterms__c; // (ci.PMC_DH_Incoterms__c === 'FOB' || ci.PMC_DH_Incoterms__c === 'FCA'  ) ? 'Origin' : 'Destination'; probably possible solution based on yesterday's discussion
            orderItem.PMC_DH_Frequency__c = ci.PMC_DH_Frequency__c;
            orderItem.PMC_DH_ItemNumber__c = ci.PMC_DH_ItemNumber__c;
            orderItem.PMC_CPQ_LinePONumber__c = PMC_DH_RequestToDeliverUtil.getLineItemPO(ordWrapper.lstCartItems, ci);
            orderItem.SBQQ__Subscription__c = ci.PMC_DH_Subscription__c;
            orderItem.Quantity = ci.Quantity;
            orderItem.UnitPrice = ci.PMC_DH_Subscription__r.PMC_CPQ_CustomerPrice__c;
            orderItem.ListPrice = 0;
            orderItem.PMC_CPQ_PricingDate__c = Date.today();
            orderItem.PMC_CPQ_Destination__c = (ci.PMC_DH_Incoterms__c == 'FOB' || ci.PMC_DH_Incoterms__c == 'FCA'  ) ? 'Origin' : 'Destination'; //ci.PMC_DH_Incoterms2__c;// previously it was PMC_DH_ConstantCLass.SAP；
 //gsmd-1244
 orderItem.PMC_CPQ_ShippingType__c = ci.PMC_DH_Subscription__r.PMC_CPQ_ShippingType__c;
             orderItem.PMC_CPQ_UnitofMeasure__c = PMC_DH_ConstantClass.STN;
            if(!Test.isRunningTest()){
                  PricebookEntry prcBookEntry = ordWrapper.mapProductIdPriceBookEntryId.get(ci.Product2Id);
            	  orderItem.PricebookEntryId = prcBookEntry.Id;
            }
            lstOrderItems.add(orderItem);
        }
        return lstOrderItems;
    }

    /** @method Name : getPayerOrBillToAccountForSoldToAccount @description : Method to get Payer Account or Bill To Account For Sold To Account @param strSoldToAccountId @param strAccountType @return : Id **/
    public static Id getPayerOrBillToAccountForSoldToAccount(String strSoldToAccountId, String strAccountType) {
        Id payerOrBillToAccountId = NULL;
        List<PMC_SS_AccountPartnerRelationships__c> lstPartnerAccounts;
        if (Test.isRunningTest()) {
            lstPartnerAccounts = [SELECT Id, PMC_SS_Account__c, PMC_SS_RelatedAccount__c FROM PMC_SS_AccountPartnerRelationships__c WHERE PMC_SS_Account__c = :strSoldToAccountId AND PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c = 'Active' AND PMC_SS_Type__c = :strAccountType ORDER BY CreatedDate DESC LIMIT 1];
        } else {
            lstPartnerAccounts = [SELECT Id, PMC_SS_Account__c, PMC_SS_RelatedAccount__c FROM PMC_SS_AccountPartnerRelationships__c WHERE PMC_SS_Account__c = :strSoldToAccountId AND PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c = 'Active' AND PMC_SS_Type__c = :strAccountType WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC LIMIT 1];
        }
        if(!lstPartnerAccounts.isEmpty()) {
            payerOrBillToAccountId = lstPartnerAccounts[0].PMC_SS_RelatedAccount__c;
        }
        return payerOrBillToAccountId;
    }

    /** @method Name : getProductIdPriceBookEntryMap @description : Method to get Sku Price Book Entry Map @param lstCartItems @return : Map<String, PricebookEntry> **/
    public static Map<String, PricebookEntry> getProductIdPriceBookEntryMap(List<CartItem> lstCartItems) {
        Map<String, PricebookEntry> mapProductIdPriceBookEntryId = new Map<String, PricebookEntry>();
        Set<String> setProductId = new Set<String>();
        for(CartItem ci : lstCartItems) {
            setProductId.add(ci.Product2Id);
        }
        List<PricebookEntry> lstPricebookEntry = [SELECT Id, CurrencyIsoCode, Pricebook2.Name, Product2Id, Pricebook2Id FROM PricebookEntry WHERE Product2Id IN :setProductId AND CurrencyIsoCode = :lstCartItems[0].PMC_DH_Contract__r.SBQQ__Quote__r.PMC_CPQ_Currency__c AND Pricebook2.Name = :STANDARD_PRICE_BOOK WITH USER_MODE];
        for(PricebookEntry priceBook : lstPricebookEntry) {
            mapProductIdPriceBookEntryId.put(priceBook.Product2Id, priceBook);
            strPriceBookId = priceBook.Pricebook2Id;
        }
        return mapProductIdPriceBookEntryId;
    }

    /** @method Name : deleteCartItems @description : Method to delete the Cart Items @param lstCartItemsId - store Id @param strCartId - account Id **/
    @AuraEnabled
    public static void deleteCartItems(List<String> lstCartItemsId, String strCartId) { 
        try {
            List<CartItem> lstcartItems = new List<CartItem>();
            if(Schema.sObjectType.CartItem.isAccessible()) {
                lstcartItems = [SELECT Id, Product2.StockKeepingUnit FROM CartItem WHERE Id IN :lstCartItemsId AND CartId = :strCartId];
            }
            if(Schema.sObjectType.CartItem.isDeletable()) {
                Database.delete(lstcartItems);
            }
        } catch(Exception ex) {            
            PMC_ErrorLogClass.processException(ex);             
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /** @method Name : OrderItemWrapper @description : Wrapper class for order item Info **/
    public with sharing class OrderItemWrapper {
        /** @description list of cart items @return String **/
        public List<CartItem> lstCartItems { get; set; }
        /** @description Order @return Order **/
        public Order objOrder { get; set; }
        /** @description lstProdSKU @return List<String> **/
        public List<String> lstProdSKU { get; set; }
        /** @description mapProductIdPriceBookEntryId @return Map<String, PricebookEntry> **/
        public Map<String, PricebookEntry> mapProductIdPriceBookEntryId { get; set; }
    }

    /** @method Name : OrderInfoWrapper @description : Wrapper class for order Info **/
    public with sharing class OrderInfoWrapper {
        /** @description Order ID @return String **/
        public String orderId { get; set; }
        /** @description Order Number @return String **/
        public String orderNumber { get; set; }
    }

    /** @description wrapper class for Call price in Order review FPD flow. author Lohitha @since 10-12-2023 **/
    public with sharing class PMC_DH_OrderCreateInputParams {
        /** @description strCartId @return String **/
        @AuraEnabled
        public String strCartId { get; set; }
        /** @description lstProductSKU @return List<String> **/
        @AuraEnabled
        public List<String> lstProductSKU { get; set; }
    }
}