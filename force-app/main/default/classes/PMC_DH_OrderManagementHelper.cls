/** 
* @description Helper for fetching Order Management Controller 
* @author Mosaic Direct Dev
* Created On       :2023-Oct-13
**/

public without sharing class PMC_DH_OrderManagementHelper {
    Private static final String STATUS_OPEN ='Open';
    Private static final String PRIORITY_HIGH = 'High';
    
    /*************************************************************************
* @method Name  : callPriceRequestForOrder
* @description  : Method to request call price to update the price on order review page in FPD order flow
* @param         lstOrderItems
* @param         lstSKUId
* @author        Lohitha
* @return        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper 
*****************************************************************************/
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper callPriceRequestForOrders(List<OrderItem> lstOrderItems, List<String> lstSKUId){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        try{
            if(!lstOrderItems.isEmpty()){
                createAndInsertTask(lstOrderItems, lstSKUId);
                result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'CallPriceRequest');            }else{                result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('001', 'CallPriceRequest');
            }
            
        }Catch(Exception ex){
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return result;
    }
    
    
    /*************************************************************************
* @method Name  : createAndInsertTask
* @description  : Method to request create and Insert Task in orders
* @param         lstOrderItems
* @param         lstSKUId
* @author        Mosaic Direct Dev
*****************************************************************************/
    private static void createAndInsertTask(List<OrderItem> lstOrderItems, List<String> lstSKUId) {
        List<Task> lstTask = new List<Task>();
        for(OrderItem objOrderItem:lstOrderItems){
            Task tsk = new Task();
            tsk.Subject = PMC_DH_ConstantClass.TASK_SUBJECT_FOR_ORDER;
            tsk.Status = STATUS_OPEN;
            if(!lstSKUId.isEmpty()){
                tsk.Description = PMC_DH_ConstantClass.TASK_SUBJECT_FOR_ORDER + String.join(lstSKUId, ',');
            }else{
                tsk.Description = PMC_DH_ConstantClass.TASK_SUBJECT_FOR_ORDER + objOrderItem.Product2.StockKeepingUnit + objOrderItem.Id;
            }
            tsk.Priority = PRIORITY_HIGH;
            tsk.WhatId = objOrderItem.OrderId;
            tsk.OwnerId = objOrderItem.Order.Account.OwnerId;
            lstTask.add(tsk);
        }
        if (Schema.sObjectType.Task.isCreateable()) {
            insert lstTask;
        }
        
    }
    /*************************************************************************
* @method Name  : checkPricePerTonAndTotalPrice
* @description  : Method to calculate PricePerTon and TotalPrice
* @param         objOrderLineWrap
* @param         decFinalAgreedPrice
* @author        Mosaic Direct Dev
* @return        Map<String, String> 
*****************************************************************************/
    public static Map<String, String> checkPricePerTonAndTotalPrice(PMC_DH_OrderDetailsWrapper.OrderLineWrapper objOrderLineWrap,Decimal decFinalAgreedPrice){
        Map<String, String> mapValues = new Map<String, String>();
        String strPricePerTon;
        String strTotalPrice;
        if(objOrderLineWrap.boolCustomerCallPriceDate && decFinalAgreedPrice != NULL){
            strPricePerTon = String.valueOf(decFinalAgreedPrice);
            strTotalPrice =  String.valueOf(decFinalAgreedPrice * Integer.valueOf(objOrderLineWrap.strTotalQuantity));
            mapValues.put('strPricePerTon', strPricePerTon);
            mapValues.put('strTotalPrice', strTotalPrice);
        }
        else{
            strPricePerTon = 'TBD';
            strTotalPrice ='TBD';
            mapValues.put('strPricePerTon', strPricePerTon);
            mapValues.put('strTotalPrice', strTotalPrice);
        }
        return mapValues;
    }
    /*************************************************************************
* @method Name  : validateCustomerCallPriceDate
* @description  : Method to validate Customer Call Price Date
* @param         datCallPriceDate
* @author        Mosaic Direct Dev
* @return        Boolean
*****************************************************************************/
    public static Boolean validateCustomerCallPriceDate(Date datCallPriceDate){
        Boolean result = false;
        if(datCallPriceDate != null){
            result = true;
        }
        return result;
    }
    /*************************************************************************
* @method Name  : validateFPDPricefromPriceFx
* @description  : Method to validate FPDPricefromPriceFx
* @param         decFPDPrice
* @author        Mosaic Direct Dev
* @return        Boolean
*****************************************************************************/
    public static Boolean validateFPDPricefromPriceFx(Decimal decFPDPrice){
        Boolean result = false;
        if(decFPDPrice != null){
            result = true;
        }
        return result;
    }
    /*************************************************************************
* @method Name  : validateShippedQuantity
* @description  : Method to validate Shipped Quantity
* @param         intShippedQuantity
* @author        Mosaic Direct Dev
* @return        String
*****************************************************************************/
    public static String validateShippedQuantity(Decimal intShippedQuantity){
        String strShippedQuantity = '0';
        if(intShippedQuantity != null){
            strShippedQuantity = String.valueOf(intShippedQuantity);
        }
        return strShippedQuantity;
    }   
    
    /*************************************************************************
* @method Name  : validatePendingQuantity
* @description  : Method to validate Pending Quantity
* @param         orderItem
* @param         strShippedQuantity
* @param         deliverQuantity
* @author        Mosaic Direct Dev
* @return        String
*****************************************************************************/
    public static String validatePendingQuantity(orderItem orderItem,String strShippedQuantity,String deliverQuantity){
        Double intPendingQuantity = 0;// GDASF-30410
        String strPendingQuantity;
        if(orderItem.PMC_CPQ_ConfirmedQuantity__c != null && orderItem.PMC_CPQ_OrderLineStatus__c!='Shipped'){
            intPendingQuantity = orderItem.PMC_CPQ_ConfirmedQuantity__c.doubleValue() - Double.valueOf(strShippedQuantity) - Double.valueOf(deliverQuantity);// GDASF-30410      
        }
        strPendingQuantity = String.valueOf(intPendingQuantity);
        return strPendingQuantity;
    } 
    /*************************************************************************
* @method Name  : getOrderSummary
* @author Nikhilesh
* @description  : Method to fetch Order Summary
* @param         order
* @return       : PMC_DH_OrderDetailsWrapper.orderSummaryWrapper
*****************************************************************************/
    public static PMC_DH_OrderDetailsWrapper.OrderSummaryWrapper getOrderSummary(Order order){
        PMC_DH_OrderDetailsWrapper.OrderSummaryWrapper orderSummaryWrapper;
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            orderSummaryWrapper = new PMC_DH_OrderDetailsWrapper.OrderSummaryWrapper();
            //assign Order values in Order Summary wrapper
            if(order != null){
                
                // need to bulk update the custom primary contact field values
                orderSummaryWrapper.strCustomerName = order.Account.Name;
                orderSummaryWrapper.strOrderPlacedBy = order.CreatedBy.Name;
                String strFieldDev=order.Status.replace(' ','_');
                String  strTransStatus=PMC_DH_Quote_Management_Status__mdt.getInstance(strFieldDev).PMC_DH_StatusLabel__c;
                orderSummaryWrapper.strSummaryStatus =System.label.get(null,strTransStatus,userinfo.getLocale());
                orderSummaryWrapper.datDatePlaced = order.CreatedDate.date();
                orderSummaryWrapper.strSalesChannel = order.PMC_DH_SalesChannel__c;
                orderSummaryWrapper.strCurrencyIsoCode = order.CurrencyIsoCode;
                //GDASF-21528
                orderSummaryWrapper.strProtocolNo=PMC_DH_OrderManagementUtil.getProtocolNo(order);
                Set<String> setReqNo=PMC_DH_OrderManagementUtil.getRequestNo(order);
                List<String> lstReqNo=new List<String>(setReqNo);
                orderSummaryWrapper.lstRequestNo=lstReqNo;
            }
        }
        catch(Exception ex){
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
            //throw new AuraHandledException(ex.getMessage());
        }
        return orderSummaryWrapper;
    }
    
    /*************************************************************************
* @method Name  : getContractInfo
* @author Nikhilesh
* @description  : Method to fetch Contract Info
* @param         contractSummaryWrapper
* @return       : PMC_DH_OrderDetailsWrapper.ContractInfoWrapper
*****************************************************************************/
    public static PMC_DH_OrderDetailsWrapper.ContractInfoWrapper getContractInfo(PMC_DH_RequestToDeliverWrapper.ContractSummaryWrapper contractSummaryWrapper){
        PMC_DH_OrderDetailsWrapper.ContractInfoWrapper contractInfoWrapper;
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            contractInfoWrapper = new PMC_DH_OrderDetailsWrapper.ContractInfoWrapper();
            //assign reqd values from contract details wrapper
            if(contractSummaryWrapper != null){
                contractInfoWrapper.strContractNumber = contractSummaryWrapper.strContractNumber;
                contractInfoWrapper.strPoNumber = contractSummaryWrapper.strPoNumber;
                contractInfoWrapper.datContractStartDate = contractSummaryWrapper.datContractStartDate;
                contractInfoWrapper.datContractEndDate = contractSummaryWrapper.datContractEndDate;
                contractInfoWrapper.strContractType = contractSummaryWrapper.strContractType;
                contractInfoWrapper.strPaymentTerms = contractSummaryWrapper.strPaymentTermSelected;
                contractInfoWrapper.strContractStatus = contractSummaryWrapper.strContractStatus;
            }
        }
        catch(Exception ex){
            // PMC_ErrorLogClass.processException(ex); // MDErrorLog
            throw new AuraHandledException(ex.getMessage());
        }
        return contractInfoWrapper;
    }
    /*************************************************************************
* @method Name  : getTotalShipmentItemQty
* @description  : Method to get total requested quantity for shipment items
* @param         lstShipmentPlan
* @return       : Double
*****************************************************************************/
    public static Double getTotalShipmentItemQty(List<PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper> lstShipmentPlan){// GDASF-30410
        Double intTotRequestedQty = 0;// GDASF-30410
        for(PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper siwrp : lstShipmentPlan)
        {
            intTotRequestedQty += siwrp.intRequestedQty;
        }
        return intTotRequestedQty;
    }
    /*************************************************************************
* @method Name  : getTotalConfirmedQty
* @description  : Method to get total Confirmed quantity for shipment items
* @param         lstOrderItems
* @return       : Double
*****************************************************************************/
    public static Double getTotalConfirmedQty(List<OrderItem> lstOrderItems){// GDASF-30410
        Double intTotConfirmedQty = 0;// GDASF-30410
        for(OrderItem oi : lstOrderItems)
        {
            if(oi.PMC_CPQ_ConfirmedQuantity__c != null){
                intTotConfirmedQty += oi.PMC_CPQ_ConfirmedQuantity__c.doubleValue();// GDASF-30410
            }
        }
        return intTotConfirmedQty;
    }
    /*************************************************************************
* @method Name  : getDeliveredQuantityMap
* @description  : Method to get DeliveredQuantity
* @param         orderItems
* @return       : Map<String, Double>
*****************************************************************************/
    public static Map<String, Double> getDeliveredQuantityMap(List<OrderItem> orderItems){// GDASF-30410
        Set<String> setOrderItemIds = new Set<String>();
        for(OrderItem oi : orderItems){
            setOrderItemIds.add(oi.Id);
        }
        //Set<String> setStatus = new Set<String>{PICKED_STATUS, PICKED_DELIVERED};
        List<ShipmentItem> lstShipmentItem = [SELECT Id, PMC_CPQ_DeliveryLineStatus__c, PMC_CPQ_DeliveryQuantity__c, PMC_CPQ_OrderProduct__c FROM ShipmentItem 
                                              WHERE PMC_CPQ_OrderProduct__c IN :setOrderItemIds AND Shipment.Status !='Delivery Deleted' //GSMD-1492
                                              WITH SECURITY_ENFORCED];
        
        Map<String, Double> mapDeliveredQuantity = new Map<String, Double>();// GDASF-30410
        Set<String> setUniqueIds = new Set<String>();
        for(ShipmentItem si : lstShipmentItem){
            Double intDeliveredQuantity = 0;// GDASF-30410
            String strUniqueId = si.PMC_CPQ_OrderProduct__c;
            if(!setUniqueIds.contains(strUniqueId)){
                setUniqueIds.add(strUniqueId);
            }
            else{
                intDeliveredQuantity = mapDeliveredQuantity.get(strUniqueId);
            }
            intDeliveredQuantity = intDeliveredQuantity + (si.PMC_CPQ_DeliveryQuantity__c != null?si.PMC_CPQ_DeliveryQuantity__c.doubleValue():0);// GDASF-30410
            mapDeliveredQuantity.put(strUniqueId, intDeliveredQuantity);
        }
        return mapDeliveredQuantity;
    }
    /*************************************************************************
* @method Name  : getCallPriceDate
* @author Mosaic Direct Dev
* @description  : Method to validate Call Price Date
* @param         objOrderItemData
* @return   Date
*****************************************************************************/    
    public static Date getCallPriceDate(OrderItem objOrderItemData){
        Date datCallPriceDate = objOrderItemData.SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PriceByDate__c; 
        List<OrderItem> lstorderItem = [SELECT Id, SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PriceByDate__c,
                                        OrderId, Product2Id from OrderItem  where OrderId=:objOrderItemData.OrderId and 
                                        Product2.Id=: objOrderItemData.Product2Id and SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PriceByDate__c!=null WITH SECURITY_ENFORCED LIMIT 1];
        if(!lstorderItem.isEmpty() && datCallPriceDate == NULL){
            datCallPriceDate = lstorderItem[0].SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PriceByDate__c;
        }
        return datCallPriceDate;
    }
    public static Map<String,Date> getCallPriceDateMap(List<OrderItem> objOrderItemData){
        //List<OrderItem>=[];
        Map<String,Date> mapOfResult=new map<String,Date>();
        Set<string> proIds=new set<String>();
        String OrderIdTest;
        for(OrderItem oi:objOrderItemData)
        {
            proIds.add(oi.Product2Id);
            OrderIdTest=oi.OrderId;
        }
          List<OrderItem> lstorderItemAll = [SELECT Id, SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PriceByDate__c,
                                            OrderId, Product2Id from OrderItem  where OrderId=:OrderIdTest and 
                                            Product2.Id IN: proIds and SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PriceByDate__c!=null  ];
        Map<String,DAte> mapOfResultAll=new Map<String,date>();
        for(OrderItem oit:lstorderItemAll)        {             mapOfResultAll.put(oit.Id,oit.SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PriceByDate__c);
         }
        for(OrderItem oi:objOrderItemData)
        {
            Date datCallPriceDate = oi.SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PriceByDate__c; 
            
          if(!lstorderItemAll.isEmpty() && datCallPriceDate == NULL){                datCallPriceDate = mapOfResultAll.get(oi.id);
            } 
            mapOfResult.put(oi.Id,datCallPriceDate);  
        }
            
       
        
        
        return mapOfResult;
    }
    
    public static Map<OrderItem,Date> getCallPriceDate1(Set<OrderItem> objOrderItemData){
        Map<OrderItem,Date> mymap=new Map<OrderItem,Date>();  
        Set<ID>Orderid=new  Set<ID>();
        Set<ID>Productid=new  Set<ID>();  
        List<Date> datCallPriceDate=new List<Date>();
        for(OrderItem oid:objOrderItemData){            
            Orderid.add(oid.OrderId);
            Productid.add(oid.Product2Id);
            if(oid.SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PriceByDate__c==null){
                datCallPriceDate.add(oid.SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PriceByDate__c);
            }
        }         
        
        List<OrderItem> lstorderItem = [SELECT Id, SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PriceByDate__c,
                                        OrderId, Product2Id from OrderItem  where OrderId=:Orderid and 
                                        Product2.Id=: Productid and 
                                        SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PriceByDate__c!=null 
                                        WITH SECURITY_ENFORCED LIMIT 1];
        if(!lstorderItem.isEmpty() && !datCallPriceDate.isEmpty()){
            for(OrderItem lio:lstorderItem){
                if(lio.SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PriceByDate__c<Date.today()){
                    mymap.put(lio,lio.SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PriceByDate__c); 
                }               
            }
        }
        return mymap;
    }
}