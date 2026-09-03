/** 
* @description Utility class for OrderManagementController 
* @author Nikhilesh
* @last modified on 2023-August-02
* @last modified by Nikhilesh
* Created On       :2023-August-02
**/

public without sharing class PMC_DH_OrderUtil{
    private static final String CLASS_CONST_VARIABLE2 = '000';
    private static final String CLASS_CONST_VARIABLE3 = '100';
    private static final String ERRORMODULE = 'CartItemsUpdate';
    private static final String ERROR = 'All';
    private static final String STATUS = 'RTD';
    private static final String PICKED_STATUS = 'Picked';
    private static final String PICKED_DELIVERED = 'Delivered';

    //Map used in getShipmentPlanDetails
    public static Map<String, List<OrderItem>> mapOrderItem = new Map <String, List<OrderItem>>();
    /*************************************************************************
* @method Name  : getShipmentPlanDetails
* @description  : Method to fetch shipment Pan Details
* @param          orderItems
* @return       : Map<String,List<PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper>>
*****************************************************************************/
public static Map<String,List<PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper>> getShipmentPlanDetails(List<OrderItem> orderItems){
    Map<String, List<PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper>> mapShipmentPlan = new Map<String,List<PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper>>();
        Set<String> setUniqueIds = new Set<String>();
        List<PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper> lstShipmentPlanWrapper;
        PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper objShipmentPlanWrap;
        List<OrderItem> lstOrderItems;
        for(OrderItem oi : orderItems){
            objShipmentPlanWrap = new PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper();
            objShipmentPlanWrap.strOrderItemId = oi.Id;
            objShipmentPlanWrap.strRequestedShipmentDate = String.valueOf(oi.PMC_CPQ_RequestedShipDate__c);
            objShipmentPlanWrap.intRequestedQty = oi.Quantity.doubleValue();// GDASF-30410
            String strUniqueId = String.valueOf(oi.PMC_CPQ_ShipTo__c) + String.valueOf(oi.PMC_CPQ_ProductLocation__c) + oi.PMC_CPQ_ModeofTransportation__c + oi.PMC_CPQ_Incoterms__c + oi.Product2.StockKeepingUnit;
            if(!setUniqueIds.contains(strUniqueId)){
                setUniqueIds.add(strUniqueId);
                lstShipmentPlanWrapper = new List<PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper>();
                lstOrderItems = new List<OrderItem>();
            }
            else{
                lstShipmentPlanWrapper = mapShipmentPlan.get(strUniqueId);
                lstOrderItems = mapOrderItem.get(strUniqueId);
            }
            lstShipmentPlanWrapper.add(objShipmentPlanWrap);
            mapShipmentPlan.put(strUniqueId, lstShipmentPlanWrapper);
            lstOrderItems.add(oi);
            mapOrderItem.put(strUniqueId, lstOrderItems);
        }
    
    return mapShipmentPlan;
}
    /*************************************************************************
* @method Name  : getShipmentItemDetails
* @description  : Method to fetch shipment item Details
* @param         order
* @return       : Map<String,List<PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper>>
*****************************************************************************/
    public static Map<String,List<PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper>> getShipmentItemDetails(Order order){
        Map<String,List<PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper>> mapShipmentItems = new Map<String,List<PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper>>();
        PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper objShipmentItemWrap;
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            if(order.OrderItems != null){
                Map<String, List<PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper>> mapShipmentPlan = getShipmentPlanDetails(order.OrderItems);
                Map<String, List<PMC_DH_OrderDetailsWrapper.OrderLineWrapper>> mapOrderLine = getOrderLineDetails(order.OrderItems);
                Map<String, Schema.DescribeFieldResult> mapOfFieldSet = PMC_DH_OrderUtilHelper.createFieldSetmap();
                for(String s : mapShipmentPlan.keyset()){
                    objShipmentItemWrap = new PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper();
                    objShipmentItemWrap.boolShipmentPlan = false;
                    List<OrderItem> lstOrderItems = mapOrderItem.get(s);
                    OrderItem oi = lstOrderItems[0];
                    
                    PMC_DH_PicklistWrapper wrpShipTo = new PMC_DH_PicklistWrapper();
                    wrpShipTo.label = oi.PMC_CPQ_ShipTo__r.Name + + ' ' + oi.PMC_CPQ_ShipTo__r.ShippingStreet + ', ' + oi.PMC_CPQ_ShipTo__r.ShippingCity + ', ' + oi.PMC_CPQ_ShipTo__r.ShippingState + ' ' + oi.PMC_CPQ_ShipTo__r.ShippingPostalCode;
                    wrpShipTo.value = oi.PMC_CPQ_ShipTo__c;
                    objShipmentItemWrap.wrpShipTo = wrpShipTo;

                    PMC_DH_PicklistWrapper wrpShipFrom = new PMC_DH_PicklistWrapper();
                    wrpShipFrom.label = oi.PMC_CPQ_ProductLocation__r.Name;
                    wrpShipFrom.value = oi.PMC_CPQ_ProductLocation__c;
                    objShipmentItemWrap.wrpShipFrom = wrpShipFrom;
                    objShipmentItemWrap.strDeliveryMode = oi.PMC_CPQ_ModeofTransportation__c;
                    objShipmentItemWrap.strIncoterm = oi.PMC_CPQ_Incoterms__c;
                    objShipmentItemWrap.strPackageType = oi.PMC_CPQ_PackageType__c;
                    objShipmentItemWrap.strPackType = PMC_DH_OrderHelper.getPackType(oi);
                    objShipmentItemWrap.strProductUOM = oi.SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_UnitOfMeasure__c;
                    PMC_DH_OrderUtilHelper.setTranslatedValuesForPicklist(objShipmentItemWrap,oi,mapOfFieldSet);
                    objShipmentItemWrap.strOrderItemId = oi.Id;
                    objShipmentItemWrap.strRequestedShipmentDate = String.valueOf(oi.PMC_CPQ_RequestedShipDate__c);
                    objShipmentItemWrap.intRequestedQty = PMC_DH_OrderManagementHelper.getTotalShipmentItemQty(mapShipmentPlan.get(s));
                    objShipmentItemWrap.intConfirmedQty = PMC_DH_OrderManagementHelper.getTotalConfirmedQty(lstOrderItems); 
                    objShipmentItemWrap.intTotalPricedQty = getTotalPricedQty(lstOrderItems); 
                    objShipmentItemWrap.intTotalUnpricedQty = objShipmentItemWrap.intConfirmedQty - objShipmentItemWrap.intTotalPricedQty; 
                    objShipmentItemWrap.lstShipmentPlan = mapShipmentPlan.get(s);
                    objShipmentItemWrap.lstOrderLines = mapOrderLine.get(s);
                    //objShipmentItemWrap.decTotalPrice = oi.PMC_CPQ_NetTotalPrice__c;
                        if((mapShipmentPlan.get(s)).size() > 1){
                            objShipmentItemWrap.boolShipmentPlan = true;
                            objShipmentItemWrap.strRequestedShipmentDate = System.label.pmc_requestToDeliverShippingInformation_multiple;
                        }
                        //Checking if map contains sku and assigning the Subscription Wrapper
                        if(!mapShipmentItems.containsKey(oi.Product2.StockKeepingUnit))
                        {
                            mapShipmentItems.put(oi.Product2.StockKeepingUnit, new List<PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper>());
                        }
                        mapShipmentItems.get(oi.Product2.StockKeepingUnit).add(objShipmentItemWrap);
                }
            }
        }
        catch(Exception ex){
            PMC_ErrorLogClass.processException(ex);
            throw new AuraHandledException(ex.getMessage());
        }
        return mapShipmentItems;
    } 

/*************************************************************************
* @method Name  : getTotalPricedQty
* @description  : Method to get total Priced quantity for shipment items
* @param         lstOrderItems
* @return       : Double
*****************************************************************************/
    public static Double getTotalPricedQty(List<OrderItem> lstOrderItems){// GDASF-30410
        Double intTotPricedQty = 0;// GDASF-30410
        Map<String, Double> mapDeliveredQuantity = PMC_DH_OrderManagementHelper.getDeliveredQuantityMap(lstOrderItems);// GDASF-30410
        Set<String> keySetDeliveredQuantityMap = mapDeliveredQuantity.keySet();
        for(OrderItem oi : lstOrderItems)
            {
                if(oi.PMC_DH_CustomerCallPriceDate__c != null && oi.PMC_CPQ_FinalAgreedPrice__c != null && keySetDeliveredQuantityMap.contains(oi.Id)){
                    intTotPricedQty += (oi.PMC_DH_ShippedQuantity__c != null?oi.PMC_DH_ShippedQuantity__c.doubleValue():0)+mapDeliveredQuantity.get(oi.Id);// GDASF-30410 ( whole operation was under Integer.valueOf())
                }
            }
        return intTotPricedQty;
    }  
     

    /*************************************************************************
    * @method Name  : getTotalShipmentItemQty
    * @description  : Method to get total requested quantity and confirmed quantity for shipment items
    * @param         objReorderDetailsWrapper
    * @param         lstProductInfoWrapper
    * @param         order
    * @return       : PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    *****************************************************************************/
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper addListOfCartItemForReorder(PMC_DH_OrderManagementController.PMC_DH_ReorderDetailsWrapper objReorderDetailsWrapper, List<PMC_DH_OrderDetailsWrapper.ProductInfoWrapper> lstProductInfoWrapper, Order order){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        List<CartItem> lstCartitems = new List<CartItem>();
        List<CartDeliveryGroup> lstCartDeliverGrp= [SELECT Id 
                                                    FROM CartDeliveryGroup 
                                                    WHERE cartid =: objReorderDetailsWrapper.strCartId  WITH USER_MODE LIMIT 1];
        WebCart objWebCart = [SELECT Id, Status, AccountId, PMC_DH_ContractStartDate__c, PMC_DH_ContractEndDate__c, PMC_DH_Currency__c, PMC_DH_PaymentMethod__c, PMC_DH_PaymentTerms__c, PMC_DH_QuoteFriendlyName__c, CurrencyIsoCode  
                              FROM WebCart
                              WHERE Id =: objReorderDetailsWrapper.strCartId WITH USER_MODE LIMIT 1];
        
        List<CartItem> lstExistingCartitems = new List<CartItem>();                      
        if(Schema.sObjectType.CartItem.isAccessible()){
            lstExistingCartitems = [Select Id, Quantity, Product2Id, Product2.StockKeepingUnit, PMC_DH_Source__c, PMC_DH_ShipTo__c, PMC_DH_DeliveryMode__c, PMC_DH_Incoterms__c, PMC_DH_PlantShipFrom__c from CartItem where CartId =: objReorderDetailsWrapper.strCartId];
        }
        for(PMC_DH_OrderDetailsWrapper.ProductInfoWrapper objProductInfoWrapper : lstProductInfoWrapper){
            for(PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper objShipmentItemsWrapper : objProductInfoWrapper.lstShipmentItems){
                CartItem objCartItem = new CartItem();
                objCartItem = checkCartItemPresent(objProductInfoWrapper, objShipmentItemsWrapper, lstExistingCartitems);
                if(String.isBlank(objCartItem.Id)){
                    objCartItem.CartId = objReorderDetailsWrapper.strCartId;
                    objCartItem.CartDeliveryGroupId = lstCartDeliverGrp[0].id; 
                    objCartItem.Type = PMC_DH_ConstantClass.PRODUCT_TYPE;
                    objCartItem.PMC_DH_IsReorder__c = true;
                    //objCartItem.Quantity =Decimal.valueof(cartItemWrap.strQuantity);
                    objCartItem.PMC_DH_ShipTo__c =objShipmentItemsWrapper.wrpShipTo.value;
                    objCartItem.PMC_DH_DeliveryMode__c = objShipmentItemsWrapper.strdeliveryMode;
                    objCartItem.PMC_DH_Incoterms__c = objShipmentItemsWrapper.strIncoterm;
                    objCartItem.PMC_DH_PlantShipFrom__c = objShipmentItemsWrapper.wrpShipFrom.value;
                    objCartItem.PMC_DH_Source__c = STATUS;
                    objCartItem.CurrencyIsoCode = objWebCart.CurrencyIsoCode;
                    objCartItem.PMC_DH_Contract__c = objReorderDetailsWrapper.strContractId;
                    objCartItem.PMC_DH_Subscription__c = order.OrderItems[0].SBQQ__Subscription__c;
                    objCartItem.Name = objProductInfoWrapper.strProductName;
                    objCartItem.Product2Id = objProductInfoWrapper.strProductId;
                    lstCartitems.add(objCartItem);
                }
            }
        }

        if(!lstCartitems.isEmpty() && Schema.sObjectType.CartItem.isCreateable()){
            Insert lstCartitems;
        }
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(CLASS_CONST_VARIABLE2, ERRORMODULE);
        if(!Schema.sObjectType.CartItem.isCreateable()) {            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(CLASS_CONST_VARIABLE3, ERROR);
        }
        return result;
    }

    private Static CartItem checkCartItemPresent(PMC_DH_OrderDetailsWrapper.ProductInfoWrapper objProductInfoWrapper, PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper objShipmentItemsWrapper, List<CartItem> lstExistingCartitems){
        CartItem objCartItem = new CartItem();
        for(CartItem objCrtItm : lstExistingCartitems){
            if(objCrtItm.PMC_DH_ShipTo__c == objShipmentItemsWrapper.wrpShipTo.value &&
            objCrtItm.PMC_DH_DeliveryMode__c == objShipmentItemsWrapper.strdeliveryMode &&
            objCrtItm.PMC_DH_Incoterms__c == objShipmentItemsWrapper.strIncoterm &&
            objCrtItm.PMC_DH_PlantShipFrom__c == objShipmentItemsWrapper.wrpShipFrom.value &&
            objCrtItm.Product2Id == objProductInfoWrapper.strProductId){                objCartItem = objCrtItm;
                break;
            }
        }
        return objCartItem;
    }

    /*************************************************************************
    * @method Name  : getOrderLineDetails
    * @description  : Method to fetch Order Line Items
    * @param          orderItems
    * @return       : Map<String,List<PMC_DH_OrderDetailsWrapper.OrderLineWrapper>>
    *****************************************************************************/
    public static Map<String,List<PMC_DH_OrderDetailsWrapper.OrderLineWrapper>> getOrderLineDetails(List<OrderItem> orderItems){
        Map<String, List<PMC_DH_OrderDetailsWrapper.OrderLineWrapper>> mapOrderLine = new Map<String,List<PMC_DH_OrderDetailsWrapper.OrderLineWrapper>>();
        Set<String> setUniqueIds = new Set<String>();
        List<PMC_DH_OrderDetailsWrapper.OrderLineWrapper> lstOrderLineWrapper;
        PMC_DH_OrderDetailsWrapper.OrderLineWrapper objOrderLineWrap;
        Map<String, Double> mapDeliveredQuantity = PMC_DH_OrderManagementHelper.getDeliveredQuantityMap(orderItems);// GDASF-30410
        Set<String> keySetDeliveredQuantityMap = mapDeliveredQuantity.keySet();
        List<String> lstOrderItemIDs = new List<String>();
       
        /*for(OrderItem oi : orderItems){
            Date datCallPriceDate = PMC_DH_OrderManagementHelper.getCallPriceDate(oi);
            if(datCallPriceDate < Date.today() && oi.PMC_DH_CustomerCallPriceDate__c == null && oi.PMC_CPQ_FPDPricefromPriceFx__c == null){
                lstOrderItemIDs.add(oi.Id);
            } 
        }*/
        Set<OrderItem>Orderitemid=new  Set<OrderItem>();
        for(OrderItem oi : orderItems){
            if( oi.PMC_DH_CustomerCallPriceDate__c == null && oi.PMC_CPQ_FPDPricefromPriceFx__c == null){
                Orderitemid.add(oi);  
            }                   
        }
        Map<OrderItem,Date> mymapOfOrderitemDate=new Map<OrderItem,Date>();  
        mymapOfOrderitemDate = PMC_DH_OrderManagementHelper.getCallPriceDate1(Orderitemid);
        for(OrderItem oi:mymapOfOrderitemDate.keyset()){                lstOrderItemIDs.add(oi.Id);
            } 
         System.debug('lstOrderItemIDs_____________'+lstOrderItemIDs);
        
        List<OrderItem> lstOrderItem = PMC_DH_OrderHelper.updateSystemCustomerCallPriceDate(lstOrderItemIDs,orderItems[0].OrderId);
        System.debug('lstOrderItem_____________'+lstOrderItem);
      Map<String,date> mapIddatePrice=PMC_DH_OrderManagementHelper.getCallPriceDateMap(lstOrderItem);
        for(OrderItem oi : lstOrderItem){
            objOrderLineWrap = new PMC_DH_OrderDetailsWrapper.OrderLineWrapper();
            objOrderLineWrap.strOrderItemId = oi.Id;
            objOrderLineWrap.strOrderItemNumber = String.valueOf(oi.LineNumber);
            objOrderLineWrap.datRequestedShipmentDate = oi.PMC_CPQ_RequestedShipDate__c;
            objOrderLineWrap.strSapOrderLine = oi.PMC_CPQ_SAPOrderLineID__c; //GSMD-1867
            objOrderLineWrap.strShippedQuantity = PMC_DH_OrderManagementHelper.validateShippedQuantity(oi.PMC_DH_ShippedQuantity__c);
            objOrderLineWrap.strDeliverQuantity = '0';
            if(keySetDeliveredQuantityMap.contains(oi.Id)){
                objOrderLineWrap.strDeliverQuantity = String.valueOf(mapDeliveredQuantity.get(oi.Id));
            }          
            objOrderLineWrap.strPendingQuantity = PMC_DH_OrderManagementHelper.validatePendingQuantity(oi,objOrderLineWrap.strShippedQuantity,objOrderLineWrap.strDeliverQuantity);
            objOrderLineWrap.strDeliveryStatus = PMC_DH_OrderUtilHelper.setDeliveryStatus(oi); // Added as a fix to GPT-40402
            objOrderLineWrap.boolCustomerCallPriceDate = PMC_DH_OrderManagementHelper.validateCustomerCallPriceDate(oi.PMC_DH_CustomerCallPriceDate__c);
            objOrderLineWrap.datCallPriceDate = mapIddatePrice.get(oi.Id);
            objOrderLineWrap.boolAMFPDPrice = PMC_DH_OrderManagementHelper.validateFPDPricefromPriceFx(oi.PMC_CPQ_FPDPricefromPriceFx__c);

            //if(objOrderLineWrap.datCallPriceDate < Date.today() && oi.PMC_DH_CustomerCallPriceDate__c == null && oi.PMC_CPQ_FPDPricefromPriceFx__c == null){
               // lstOrderItemIDs.add(oi.Id);
            //}
            objOrderLineWrap.boolCallPriceRequestedBySystem = oi.PMC_DH_CallPriceRequestedBySystem__c;
            objOrderLineWrap.strTotalQuantity = String.valueOf(Double.valueOf(objOrderLineWrap.strPendingQuantity)+Double.valueOf(objOrderLineWrap.strShippedQuantity)+Double.valueOf(objOrderLineWrap.strDeliverQuantity));// GDASF-30410
            Map<String,String> mapValues = PMC_DH_OrderManagementHelper.checkPricePerTonAndTotalPrice(objOrderLineWrap,oi.PMC_CPQ_FinalAgreedPrice__c);
            objOrderLineWrap.strPricePerTon = mapValues.get('strPricePerTon');
            objOrderLineWrap.strTotalPrice = mapValues.get('strTotalPrice');
            //objOrderLineWrap.strUnitOfMeasure = oi.PMC_CPQ_UnitOfMeasure__c;

            String strUniqueId = String.valueOf(oi.PMC_CPQ_ShipTo__c) + String.valueOf(oi.PMC_CPQ_ProductLocation__c) + oi.PMC_CPQ_ModeofTransportation__c + oi.PMC_CPQ_Incoterms__c + oi.Product2.StockKeepingUnit;
            if(!setUniqueIds.contains(strUniqueId)){
                setUniqueIds.add(strUniqueId);
                lstOrderLineWrapper = new List<PMC_DH_OrderDetailsWrapper.OrderLineWrapper>();
            }
            else{                lstOrderLineWrapper = mapOrderLine.get(strUniqueId);
            }
            lstOrderLineWrapper.add(objOrderLineWrap);
            mapOrderLine.put(strUniqueId, lstOrderLineWrapper);
        }
        //PMC_DH_OrderManagementHelper.validateOrderItemsList(lstOrderItemIDs);
        return mapOrderLine;
    }
   
}