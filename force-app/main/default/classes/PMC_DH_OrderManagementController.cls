/** 
* @description Controller for fetching Order Details 
* @author Nikhilesh
* @last modified on 2023-July-27
* @last modified by Nikhilesh
* Created On       :2023-July-27
**/

public without sharing class PMC_DH_OrderManagementController {
    
    private static final String ORDER_DETAILS_SUCCESS_MODULE = 'OrderDetail';
    private static final String PRICING_SUMMARY_SUCCESS_MODULE = 'PricingSummary';
    private static final String CUSTOMERCALLPRICEDATE = 'CustomerCallPriceDate';
    private static final String BR_ORDER_TYPE = 'BR Regular Sales'; //added as part of GPT-28211
    private static final String BR_THIRD_PARTY_ORDER_TYPE = 'BR Third Party Sales'; //added as part of GPT-30051
    
    //Map used in getShipmentPlanDetails
    public static Map<String, List<OrderItem>> mapOrderItem = new Map <String, List<OrderItem>>();
    /*************************************************************************
* @method Name  : getOrderDetails
* @author Nikhilesh
* @description  : Method to get the Order Details Page info in wrapper class
* @param        strCommunityId 
* @param        strEffectiveAccountId 
* @param        strOrderId
* @return       : PMC_DH_OrderDetailsWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_OrderDetailsWrapper getOrderDetails(String strCommunityId,String strEffectiveAccountId, String strOrderId){
        PMC_DH_OrderDetailsWrapper orderDetailsWrapper;
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            orderDetailsWrapper = new PMC_DH_OrderDetailsWrapper();
            orderDetailsWrapper.statusCodeMessage =  PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.ACCESS_DENIED_CODE, PMC_DH_ConstantClass.GETORDER_ACESSDENIED);      

            // method to fetch Order details
            Order order = getOrder(strOrderId,strEffectiveAccountId);
            if(order.Id!=null)
            {
            orderDetailsWrapper.strWebReferenceNumber = order.OrderNumber;
            orderDetailsWrapper.strOrderNumber = order.PMC_CPQ_SAPOrderNumber__c; // SAP Number
            
            orderDetailsWrapper.strOrderStatus = System.label.pmc_orderHistory_confirmed;
            if(String.isBlank(order.PMC_CPQ_SAPOrderNumber__c)){
                orderDetailsWrapper.strOrderStatus = System.label.pmc_orderHistory_requested; // if 'Requested', show strWebReferenceNumber. Else, show strOrderNumber.
            }
            if(order.OrderItems.size()>0){
                orderDetailsWrapper.boolVCOFlag = order.OrderItems[0].SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c;//Added as part of 20003
            }
            // method to assign Order Summary details in a wrapper
            orderDetailsWrapper.orderSummaryWrapper = PMC_DH_OrderManagementHelper.getOrderSummary(order);
            
            // String strContractId = order.ContractId;
            // fetch contract details using existing method
            PMC_DH_RequestToDeliverWrapper.ContractSummaryWrapper contractSummaryWrapper = PMC_DH_ContractUtil.getContractSummary(order.ContractId);
            
            // assign only the required values to contract info wrapper
            orderDetailsWrapper.contractInfoWrapper = PMC_DH_OrderManagementHelper.getContractInfo(contractSummaryWrapper);
            orderDetailsWrapper.contractInfoWrapper.strContractId = order.ContractId;
            orderDetailsWrapper.contractInfoWrapper.strContractType = getOrderContractType(order.Id);
            
            // method to assign Product Info details in a wrapper
            orderDetailsWrapper.productInfoWrapper = getProductInfo(strCommunityId, strEffectiveAccountId, order);    
            orderDetailsWrapper.statusCodeMessage =  PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, ORDER_DETAILS_SUCCESS_MODULE);      
        }
        }
        catch(Exception ex){
            orderDetailsWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return orderDetailsWrapper;
    }
    
    /*************************************************************************
* @method Name  : getOrderContractType
* @author Rohan
* @description  : Method to get Order Contract Type
* @param         strOrderId
* @return       : String
*****************************************************************************/
    public static String getOrderContractType(String strOrderId){
        OrderItem objOrderItems = [SELECT Id, OrderId, toLabel(SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c)
                                   FROM OrderItem
                                   WHERE OrderId =: strOrderId
                                   WITH SECURITY_ENFORCED
                                   LIMIT 1];
        return objOrderItems.SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c;
    }
    /*************************************************************************
* @method Name  : getOrder
* @author Nikhilesh
* @description  : Method to fetch Order Details
* @param         strOrderId
* @param		 strEffectiveAccountId
* @return       : Order
*****************************************************************************/
    public static Order getOrder(String strOrderId, String strEffectiveAccountId) {
        Order order=new Order();
        List<Order> lstOrder;
        
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            List<String> lstOrderTypes = PMC_DH_CommonSystemUtils.getListStoreConfigbyFeature(PMC_DH_ConstantClass.ORDER_TYPE_CODES);
            // fetch Order and OrderItem using SOQL
            lstOrder = [SELECT Id, AccountId, OrderNumber, CreatedDate, ContractId, Account.Name, CreatedBy.Name, EffectiveDate, Status, 
                        CurrencyIsoCode, toLabel(PMC_DH_SalesChannel__c), PMC_CPQ_SAPOrderNumber__c, PMC_DH_OrderTypeCode__c,
                        (SELECT Id, PMC_CPQ_RequestedShipDate__c, PMC_DH_ItemNumber__c, PMC_CPQ_ShipTo__c, PMC_CPQ_ShipTo__r.Name, 
                         PMC_CPQ_ShipTo__r.ShippingStreet, PMC_CPQ_ShipTo__r.ShippingCity, PMC_CPQ_ShipTo__r.ShippingState, 
                         PMC_CPQ_ShipTo__r.ShippingPostalCode, PMC_CPQ_ProductLocation__c, PMC_CPQ_ProductLocation__r.Name, 
                         PMC_CPQ_ModeofTransportation__c, PMC_CPQ_Incoterms__c, Product2.StockKeepingUnit, Quantity, AvailableQuantity, 
                         PMC_CPQ_ConfirmedQuantity__c, PMC_CPQ_OrderLineStatus__c, LineNumber, PMC_DH_ShippedQuantity__c, 
                         SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PriceByDate__c,PMC_DH_CustomerCallPriceDate__c,PMC_CPQ_FPDPricefromPriceFx__c,
                         PMC_CPQ_FinalAgreedPrice__c, PMC_DH_CallPriceRequestedBySystem__c,OrderId, Product2Id,
                         SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PackType__c ,SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PackageType__c, PMC_CPQ_PackageType__c, SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_UnitOfMeasure__c,
                         SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c,PMC_DH_ProtocolIdentifier__c,PMC_DH_RequestNumber__c FROM OrderItems) 
                        FROM Order WHERE Id =: strOrderId AND AccountId =: strEffectiveAccountId AND 
                        //(Type = :PMC_DH_ConstantClass.STANDARD_ORDER_TYPE OR Type = :PMC_DH_ConstantClass.PREPAY_ORDER_TYPE OR Type = :BR_ORDER_TYPE OR Type = :BR_THIRD_PARTY_ORDER_TYPE)
                        PMC_DH_OrderTypeCode__c IN :lstOrderTypes
                        WITH SECURITY_ENFORCED];
            			// added as part of GPT-28211 and Updated as part of GDASF-20299
            			
            if(!lstOrder.isEmpty()){
                order = lstOrder[0];
            }
        return order;
    }
    
    /*************************************************************************
* @method Name  : getProductInfo
* @description  : Method to fetch Contract Summary
* @param         strCommunityId
* @param         strEffectiveAccountId
* @param         order
* @return       : List<PMC_DH_OrderDetailsWrapper.ProductInfoWrapper>
*****************************************************************************/
    public static List<PMC_DH_OrderDetailsWrapper.ProductInfoWrapper> getProductInfo(String strCommunityId,String strEffectiveAccountId,Order order){
        List<PMC_DH_OrderDetailsWrapper.ProductInfoWrapper> lstShipmentItemsWrapper = new List<PMC_DH_OrderDetailsWrapper.ProductInfoWrapper>();
        PMC_DH_OrderDetailsWrapper.ProductInfoWrapper shipmentItemsWrapper;
        List<String> lstOrderProducts;
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            //method to get Shipment plan Details
            Map<String,List<PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper>> mapShipmentItems = PMC_DH_OrderUtil.getShipmentItemDetails(order);
            Set<String> setSku = mapShipmentItems.keyset();
            List<String> lstSku = new List<String>(setSku);
            //method to get Product Details using connectApi 
            if(!lstSku.isEmpty()){
                Map<String,PMC_DH_RequestForQuoteController.ConnectApiWrapper> mapProductDetail = PMC_DH_QuoteManagementControllerClass.getproductConnectApi(strCommunityId,strEffectiveAccountId,lstSku); 
                
                if(order.OrderItems != null){
                    List<OrderItem> lstOrderItem = new List<OrderItem>();
                    Map<String, OrderItem> mapOrderItems = PMC_DH_OrderUtilHelper.getTotalOrderItems(order.OrderItems);
                    
                    for(String quoteLineSku : mapShipmentItems.keyset()){
                        shipmentItemsWrapper = new PMC_DH_OrderDetailsWrapper.ProductInfoWrapper();
                        
                        //method to assign product Details in Wrapper
                        PMC_DH_RequestForQuoteController.ConnectApiWrapper objconnectapiProduct = mapProductDetail.get(quoteLineSku);
                        shipmentItemsWrapper.strProductName = objconnectapiProduct.strProductName;
                        shipmentItemsWrapper.strSku = objconnectapiProduct.strSku;
                        shipmentItemsWrapper.strProductId = objconnectapiProduct.strProductId;
                        shipmentItemsWrapper.strImgSrc = objconnectapiProduct.strImgSrc;
                        shipmentItemsWrapper.strProductFamily = objconnectapiProduct.strProductFamily;
                        //shipmentItemsWrapper.strProductUOM = objconnectapiProduct.strProductUOM;
                        shipmentItemsWrapper.lstShipmentItems = mapShipmentItems.get(quoteLineSku);
                        Double intTotRequestedQty = 0;// GDASF-30410
                        Double intTotConfirmedQty = 0;// GDASF-30410
                        lstOrderProducts = new List<String>();
                        for(PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper siwrp : shipmentItemsWrapper.lstShipmentItems)
                        {
                            intTotRequestedQty += siwrp.intRequestedQty;
                            intTotConfirmedQty += getConfirmedQuantity(siwrp.intConfirmedQty); //value TBD after SAP integration
                            lstOrderProducts.add(siwrp.strOrderItemId);
                        }
                        
                        lstOrderItem = PMC_DH_OrderUtilHelper.getShipmentOrderItems(mapOrderItems,lstOrderProducts);
                        shipmentItemsWrapper.intRequestedQty = intTotRequestedQty;
                        shipmentItemsWrapper.intConfirmedQty = intTotConfirmedQty; //value TBD after SAP integration
                        shipmentItemsWrapper.intTotalPricedQty = PMC_DH_OrderUtil.getTotalPricedQty(lstOrderItem); 
                        shipmentItemsWrapper.intTotalUnpricedQty = shipmentItemsWrapper.intConfirmedQty - shipmentItemsWrapper.intTotalPricedQty; 
                        shipmentItemsWrapper.strItemNumber = order.OrderItems[0].PMC_DH_ItemNumber__c;
                        shipmentItemsWrapper.strProductUOM = mapShipmentItems.get(quoteLineSku)[0].strProductUOM;
                        shipmentItemsWrapper.strProductUOMLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_UnitOfMeasure__c.getDescribe(),shipmentItemsWrapper.strProductUOM);
                        lstShipmentItemsWrapper.add(shipmentItemsWrapper);
                    }
                }
            }
        }
        catch(Exception ex){
            //PMC_ErrorLogClass.processException(ex); // MDErrorLog
            throw new AuraHandledException(ex.getMessage()+ex.getStackTraceString());
        }
        return lstShipmentItemsWrapper;
    }
    
    private static Double getConfirmedQuantity(Double intConfirmedQty){// GDASF-30410
        Double qty = 0;// GDASF-30410
        if(intConfirmedQty != null){
            qty = intConfirmedQty;
        }
        return qty;
    }
    /*************************************************************************
* @method Name  : getPricingSummaryForOrder
* @description : Method to get Pricing Summary For Order
* @param strCartId
* @return PMC_DH_PricingDetailWrapper 
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_PricingDetailWrapper getPricingSummaryForOrder(String strCartId)
    {
        PMC_DH_PricingDetailWrapper objPricingDetailWrapper = new PMC_DH_PricingDetailWrapper();
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            Map<String,List<CartItem>> mapSkuToCartItem = new Map<String,List<CartItem>>();
            List<CartItem> lstCartitems;
            if(Schema.sObjectType.CartItem.isAccessible()){
                lstCartitems= [Select id,Quantity,Product2.StockKeepingUnit,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_UnitofMeasure__c,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_QuoteRecordType__c,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_CustomerPrice__c,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_FinalPricePerTonne__c,PMC_DH_Contract__r.SBQQ__Quote__c,Product2.Name, Product2.PMC_CPQ_QuantityUnitOfMeasure__c, PMC_DH_RequestedShipmentDate__c,PMC_DH_ShipTo__c,PMC_DH_PlantShipFrom__c, PMC_DH_Incoterms__c, PMC_DH_DeliveryMode__c, PMC_DH_DeliveryPONumber__c, PMC_DH_Frequency__c, PMC_DH_POIncrementBy__c, CurrencyIsoCode, TotalLineAmount, PMC_DH_Contract__r.SBQQ__Quote__r.PMC_CPQ_Currency__c from CartItem 
                               where cartId=:strCartId WITH SECURITY_ENFORCED];
            }Map<String,PMC_DH_PriceQuantityWrapper> mapSkuPriceQuantityWrapper = new Map<String,PMC_DH_PriceQuantityWrapper>();
            for(CartItem objCartItem : lstCartitems){
                if(!mapSkuToCartItem.containsKey(objCartItem.Product2.StockKeepingUnit)){
                    mapSkuToCartItem.put(objCartItem.Product2.StockKeepingUnit,new List<CartItem>());
                }
                mapSkuToCartItem.get(objCartItem.Product2.StockKeepingUnit).add(objCartItem);
                if(!mapSkuPriceQuantityWrapper.containsKey(objCartItem.Product2.StockKeepingUnit)){
                    mapSkuPriceQuantityWrapper.put(objCartItem.Product2.StockKeepingUnit,new PMC_DH_PriceQuantityWrapper());
                }
                PMC_DH_PriceQuantityWrapper objPriceQuantityWrapper=mapSkuPriceQuantityWrapper.get(objCartItem.Product2.StockKeepingUnit);
                if(objCartItem.Quantity != null) {
                    objPriceQuantityWrapper.intQuantity = objPriceQuantityWrapper.intQuantity + objCartItem.Quantity.longValue();// GDASF-10697
                }
                PMC_DH_OrderManagementUtil.getCartItemTotalPrice(objPriceQuantityWrapper,objCartItem);
                mapSkuPriceQuantityWrapper.put(objCartItem.Product2.StockKeepingUnit,objPriceQuantityWrapper);
            }
            
            objPricingDetailWrapper.strCurrencyIsoCode = lstCartitems[0].PMC_DH_Contract__r.SBQQ__Quote__r.PMC_CPQ_Currency__c;
            Decimal decTotalPrice = 0;
            Set<string> setProdSku = mapSkuToCartItem.keyset();
            List<PMC_DH_PricingDetailWrapper.PMC_DH_PricingSummaryWrapper> lstPriceSummary = new List<PMC_DH_PricingDetailWrapper.PMC_DH_PricingSummaryWrapper>();
            for(String strSku : setProdSku){
                List<CartItem> lstCartItem = mapSkuToCartItem.get(strSku);
                PMC_DH_PricingDetailWrapper.PMC_DH_PricingSummaryWrapper objPriceSummary = new PMC_DH_PricingDetailWrapper.PMC_DH_PricingSummaryWrapper();
                objPriceSummary.strProductName = lstCartItem[0].Product2.Name;
                objPriceSummary.strProductSKU = lstCartItem[0].Product2.StockKeepingUnit;
                objPriceSummary.strUOM = PMC_DH_GetPriceResponseParsing.getUnitOfMeasureValue(lstCartItem[0].PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_UnitofMeasure__c); 
                PMC_DH_PriceQuantityWrapper objPriceQuantityWrapper=mapSkuPriceQuantityWrapper.get(strSku);
                objPriceSummary.intQuantity = objPriceQuantityWrapper.intQuantity;
                objPriceSummary.decPrice = objPriceQuantityWrapper.decPrice.setScale(2, RoundingMode.HALF_UP);
                decTotalPrice = decTotalPrice + objPriceQuantityWrapper.decPrice.setScale(2, RoundingMode.HALF_UP);
                lstPriceSummary.add(objPriceSummary);
            }
            objPricingDetailWrapper.decTotalPrice = decTotalPrice;
            objPricingDetailWrapper.lstPriceSummary = lstPriceSummary;
            objPricingDetailWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, PRICING_SUMMARY_SUCCESS_MODULE);
        }catch(Exception ex){
            objPricingDetailWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return objPricingDetailWrapper;
    }
    
    /*************************************************************************
* @method Name  : updateCustomerCallPriceDate
* @description : Method to update Customer Call Price Date in Order Line
* @param        lstOrderItemIDs
* @param        boolIsCustomerRequested
* @return String
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper updateCustomerCallPriceDate(List<String> lstOrderItemIDs, Boolean boolIsCustomerRequested)
    {
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        List<OrderItem> lstOrderItems = new List<OrderItem>();
        try{
            if(Schema.sObjectType.OrderItem.isAccessible()){
                lstOrderItems = [SELECT Id,OrderId,PMC_DH_CustomerCallPriceDate__c,PMC_DH_CallPriceRequestedBySystem__c,Product2.StockKeepingUnit,Order.Account.Id, Order.Account.OwnerId FROM OrderItem Where Id in: lstOrderItemIDs ];     
            }
            
            if(!lstOrderItems.isEmpty()){
                for(OrderItem objOrderItem: lstOrderItems){
                    if(!boolIsCustomerRequested){
                        objOrderItem.PMC_DH_CallPriceRequestedBySystem__c = true; 
                    }
                    objOrderItem.PMC_DH_CustomerCallPriceDate__c = Date.today();
                }
                if (Schema.sObjectType.OrderItem.isUpdateable()) {
                    update lstOrderItems;
                }
                PMC_DH_OrderManagementHelper.callPriceRequestForOrders(lstOrderItems, new List<String>());
                result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, CUSTOMERCALLPRICEDATE);
            }
            else{
                throw new QueryException();
            }
        }
        catch(Exception ex){
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return result;
    }
    
    /*************************************************************************
* @method Name  : reorderFromOrderDetails
* @description : Method to reorder From Order Details page
* @param        objReorderDetailsWrapper
* @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper 
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper reorderFromOrderDetails(PMC_DH_ReorderDetailsWrapper objReorderDetailsWrapper)
    {
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            
            // method to fetch Order details
            Order order = getOrder(objReorderDetailsWrapper.strOrderId, objReorderDetailsWrapper.strEffectiveAccountId);
            // method to assign Product Info details in a wrapper
            List<PMC_DH_OrderDetailsWrapper.ProductInfoWrapper> lstProductInfoWrapper = getProductInfo(objReorderDetailsWrapper.strCommunityId, objReorderDetailsWrapper.strEffectiveAccountId, order); 
            // Get success result
            result = PMC_DH_OrderUtil.addListOfCartItemForReorder(objReorderDetailsWrapper, lstProductInfoWrapper, order);
        }
        catch(Exception ex){
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return result;
    }
    /*************************************************************************
* @method Name  : ValidateOrderItemsList
* @author Mosaic Direct Dev
* @description  : Method to validate orderItems and update customer call price Date
* @param         lstOrderItemIDs
*****************************************************************************/
    public static void validateOrderItemsList(List<String> lstOrderItemIDs){
        if(!lstOrderItemIDs.isEmpty()){
            updateCustomerCallPriceDate(lstOrderItemIDs, false);
        }
    }
    /**
* @description wrapper class for Reorder Details
* @author Rohan Undale
* @since  09-07-2023
* @last modified by @rohan undale
*/
// added with sharing
    public with sharing class PMC_DH_ReorderDetailsWrapper {
        /**
* @description strCommunityId
* @return String
*/
        @AuraEnabled
        public String strCommunityId{get;set;}
        
        /**
* @description strEffectiveAccountId
* @return String
*/
        @AuraEnabled
        public String strEffectiveAccountId{get;set;}
        
        /**
* @description strOrderId
* @return String
*/
        @AuraEnabled
        public String strOrderId{get;set;}
        
        /**
* @description strCartId
* @return String
*/
        @AuraEnabled
        public String strCartId{get;set;}
        
        /**
* @description strContractId
* @return String
*/
        @AuraEnabled
        public String strContractId{get;set;}
    }
    
    /**
* @description wrapper class for pricing detail
* @author Rohan Undale
* @since  07-28-2023
* @last modified by @rohan undale
*/
    public with sharing class PMC_DH_PriceQuantityWrapper {
        /*************************************************************************
* @method Name  : PMC_DH_PriceQuantityWrapperx
* @description : Constructor for PMC_DH_PriceQuantityWrapper
*****************************************************************************/
        public PMC_DH_PriceQuantityWrapper(){
            this.intQuantity = 0;
            this.decPrice = 0;
            this.decTotalPrice=0;
        }
        /**
* @description Quantity
* @return Long
*/
        @AuraEnabled
        public Long intQuantity{get;set;}
        
        /**
* @description price per unit 
* @return Decimal
*/
        @AuraEnabled
        public Decimal decPrice{get;set;}
        /**
* @description Total Price
* @return Decimal
*/
        @AuraEnabled
        public Decimal decTotalPrice{get;set;}
    }
}