/**
 * @description       : 
 * @author            : Hemant Giri Goswami | hegoswami@deloitte.com
 * @group             : 
 * @last modified on  : 04-26-2024
 * @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/

public without sharing class PMC_DH_OrderListViewController {
    public final static String ORDER_RELATIVE_PATH = 'order/';
    public final static String ORDER_NUMBER = '?orderNumber=';
    public final static String ORDER_ID = '&orderId=';
    /**
* * @description   : To fetch the Order records
* * @return        : PMC_DH_OrderListViewWrapper
* * @param searchParams : Search term for filter
* * @param strEffectiveAccId : Effective Account Id
* * @param strLocale : Country of User- NA/ Brazil
* * @author        : @Lohitha Sai
* */
    @AuraEnabled
    public static PMC_DH_OrderListViewWrapper getOrderRecords(OrderSearchParameterWrapper searchParams, String strEffectiveAccId,String strLocale) {
        PMC_DH_OrderListViewWrapper orderWrapper = new PMC_DH_OrderListViewWrapper();
       
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
           
            if(searchParams.strStatus==PMC_DH_ConstantClass.ORDER_SUMMARY_STATUS && strLocale==PMC_DH_ConstantClass.Brazil)
            {  
                orderWrapper.lstOrders=new List<PMC_DH_OrderListViewWrapper.OrderInfoWrapper>();
                orderWrapper.lstProductFilters= new List<PMC_DH_PicklistWrapper>();
            }
            else
            {
                orderWrapper= requestedOrderWithoutApi(searchParams, strEffectiveAccId);
               
            }
            orderWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, PMC_DH_ConstantClass.FETCH_ORDERS_SUCCESS_MODULE);
        }
       
        catch(Exception ex){
            orderWrapper.statusCodeMessage =  PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
            //throw new AuraHandledException(e.getMessage());
        }
        return orderWrapper;
    }
 
    private static void generateProductIdNameMap(Map<String,String> mapWithProductIdName, OrderItem lineItem) {
        if(!mapWithProductIdName.containsKey(lineItem.Product2Id)){
            mapWithProductIdName.put(lineItem.Product2Id,lineItem.Product2.Name);
        }
    }
 
    /**
     * @method getTotalOrderItemPrice
     * @description Get total price of order Item
     * @param lineItem
     * @param totalPrice
     * @param isFPDOrder
     * @return Decimal
     */
    private static Decimal getTotalOrderItemPrice(OrderItem lineItem, Decimal totalPrice, Boolean isFPDOrder) {
        /** If call price is requested by system/customer and AM agreed for a price which means PMC_CPQ_FinalAgreedPrice__c has a value
         * PMC_CPQ_FinalAgreedPrice__c - Populated only for FPD orders
         */
        if(isFPDOrder) {
            if(lineItem.PMC_DH_CustomerCallPriceDate__c!=null && lineItem.PMC_CPQ_FinalAgreedPrice__c!=null) {
                totalPrice+=(lineItem.PMC_CPQ_FinalAgreedPrice__c*lineItem.Quantity.longValue());
            }
        }
        else {
            totalPrice+=lineItem.TotalPrice;
        }
        return totalPrice;
    }
 
    /**
* @description method to handle requested to country other than BRAZIL  
* @param searchParams    
* @param strEffectiveAccId  
* @return PMC_DH_OrderListViewWrapper
*/
    private static PMC_DH_OrderListViewWrapper requestedOrderWithoutApi( OrderSearchParameterWrapper searchParams,String strEffectiveAccId )
    {  
        PMC_DH_OrderListViewWrapper orderWrapper=new PMC_DH_OrderListViewWrapper();
        List<PMC_DH_PicklistWrapper> lstProductWrapper = new List<PMC_DH_PicklistWrapper>();
        List<PMC_DH_OrderListViewWrapper.OrderInfoWrapper> lstOrderInfoWrapper = new List<PMC_DH_OrderListViewWrapper.OrderInfoWrapper>();
        Map<String,String> mapAllLineProductIdName = new Map<String,String>();
        String strQuery = getOrderSearchQuery(searchParams,strEffectiveAccId);
        String queryRes = strQuery.replace('\\', '');
        List<Order> lstOrder = new List<Order>();
        lstOrder = Database.query(queryRes);
        for(Order ord :lstOrder){
            PMC_DH_OrderListViewWrapper.OrderInfoWrapper orderInfo = new PMC_DH_OrderListViewWrapper.OrderInfoWrapper();
            Map<String,String> mapWithProductIdName = new Map<String,String>();
            Map<String,String> mapWithShippingIdName = new Map<String,String>();
            Set<Date> setWithRequestedShipDate = new Set<Date>();
            Set<String> setWithProductSKU = new Set<String>();
           
            orderInfo.strOrderNumber = ord.PMC_CPQ_SAPOrderNumber__c!=NULL ? ord.PMC_CPQ_SAPOrderNumber__c : ord.OrderNumber;
            orderInfo.strContractNumber =PMC_DH_ConstantClass.DOC_TAG+ord.Contract.SBQQ__Quote__r.PMC_CLM_DocumentNumber__c; //Contract.ContractNumber;
            orderInfo.strPONumber =ord.PMC_CPQ_PO__c;// Quote PO descoped- x Contract.SBQQ__Quote__r.PMC_CPQ_PO__c
            orderInfo.orderDateCreated =ord.CreatedDate;
            orderInfo.orderDetailLink = ORDER_RELATIVE_PATH+ord.id+ORDER_NUMBER+ord.OrderNumber+ORDER_ID+ord.id;
            orderInfo.totalQuantity = ord.PMC_DH_TotalQuantity__c != null?ord.PMC_DH_TotalQuantity__c.doubleValue():0;//GDASF-30410
            orderInfo.totalPrice = 0;
            String strSearchable=orderInfo.strOrderNumber+' '+orderInfo.strContractNumber+' '+orderInfo.strPONumber+' ';
            for(OrderItem lineItem : ord.OrderItems){
                String strShipToLabel = lineItem.PMC_CPQ_ShipTo__r.Name + ' ' + lineItem.PMC_CPQ_ShipTo__r.ShippingStreet + ', ' + lineItem.PMC_CPQ_ShipTo__r.ShippingCity + ', ' + lineItem.PMC_CPQ_ShipTo__r.ShippingState + ' ' + lineItem.PMC_CPQ_ShipTo__r.ShippingPostalCode;
                getProductWrapper(mapAllLineProductIdName, lineItem, lstProductWrapper);
                generateProductIdNameMap(mapWithProductIdName,lineItem);
               
                if(!mapWithShippingIdName.containsKey(lineItem.PMC_CPQ_ShipTo__c)){
                   
                    mapWithShippingIdName.put(lineItem.PMC_CPQ_ShipTo__c,  strShipToLabel);
                }
                if(!setWithRequestedShipDate.contains(lineItem.PMC_CPQ_RequestedShipDate__c)){
                    setWithRequestedShipDate.add(lineItem.PMC_CPQ_RequestedShipDate__c);
                }
                setWithProductSKU.add(lineItem.Product2.StockKeepingUnit);
                strSearchable+=lineItem.Product2.Name+' '+strShipToLabel+' ';
                Boolean isFPDOrderLine = lineItem.SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c == PMC_DH_ConstantClass.FPD;
                orderInfo.totalPrice = getTotalOrderItemPrice(lineItem, orderInfo.totalPrice, isFPDOrderLine);
            }
            orderInfo.setSKU = new List<String>(setWithProductSKU);
            orderInfo.strProducts=getProductOrShipToName(mapWithProductIdName, PMC_DH_ConstantClass.BLANK_STRING);
            orderInfo.shipTo=getProductOrShipToName(mapWithShippingIdName, PMC_DH_ConstantClass.BLANK_STRING);
            orderInfo.orderShipmentDate=getRequestedShipDate(setWithRequestedShipDate, PMC_DH_ConstantClass.BLANK_STRING);
            orderInfo.strSearchable=strSearchable;
            lstOrderInfoWrapper.add(orderInfo);
        }
        orderWrapper.lstOrders=lstOrderInfoWrapper;
        orderWrapper.lstProductFilters=lstProductWrapper;
        return orderWrapper;
    }
   
   
    private static String getProductOrShipToName(Map<String,String> mapProductorShipName, String proOrShipName )
    {
        if(mapProductorShipName.size()==1){
            proOrShipName = mapProductorShipName.values()[0];
        }else if(mapProductorShipName.size()>=2){
            proOrShipName = System.label.pmc_requestToDeliverShippingInformation_multiple;
        }
        return proOrShipName;
    }
   
    private static String getRequestedShipDate( Set<Date> setWithRequestedShipDate, String orderShipmentDate) {
        if (setWithRequestedShipDate.size() == 1) {
            orderShipmentDate = String.valueOf(new List<Date> (setWithRequestedShipDate).get(0));
        } else if (setWithRequestedShipDate.size() >= 2) {
            orderShipmentDate = System.label.pmc_requestToDeliverShippingInformation_multiple;
        }
        return orderShipmentDate;
    }
   
    private static void getProductWrapper(Map<String,String> mapAllLineProductIdName, OrderItem lineItem, List<PMC_DH_PicklistWrapper> lstProductWrapper){
        if(!mapAllLineProductIdName.containsKey(lineItem.Product2Id) && lineItem.Product2Id!=NULL ){
            PMC_DH_PicklistWrapper productWrapper = new PMC_DH_PicklistWrapper();
            productWrapper.Label = lineItem.Product2.Name;
            productWrapper.Value = lineItem.Product2.StockKeepingUnit;
            lstProductWrapper.add(productWrapper);
            mapAllLineProductIdName.put(lineItem.Product2Id,lineItem.Product2.Name);
        }
    }
   
    private static String getOrderSearchQuery(OrderSearchParameterWrapper searchParams, String strEffectiveAccId){
       
        String strQuery = 'SELECT Id, Name, OrderNumber, PMC_CPQ_SAPOrderNumber__c, Contract.ContractNumber, Contract.SBQQ__Quote__r.PMC_CPQ_PO__c, Contract.SBQQ__Quote__r.PMC_CLM_DocumentNumber__c, CreatedDate,PMC_DH_TotalPrice__c,PMC_DH_TotalQuantity__c,Status,PMC_CPQ_PO__c,';
        strQuery += ' (SELECT id, Product2Id,Product2.Id,Product2.Name,Product2.StockKeepingUnit,PMC_CPQ_RequestedShipDate__c,PMC_CPQ_ShipTo__c, PMC_CPQ_ShipTo__r.Name,PMC_CPQ_ShipTo__r.ShippingStreet,';
        strQuery += ' PMC_CPQ_ShipTo__r.ShippingCity,PMC_CPQ_ShipTo__r.ShippingState,PMC_CPQ_ShipTo__r.ShippingCountry, PMC_CPQ_ShipTo__r.ShippingPostalCode,PMC_CPQ_ShipTo__r.ShippingStateCode, SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c, PMC_DH_CustomerCallPriceDate__c, Quantity, TotalPrice, PMC_CPQ_FinalAgreedPrice__c FROM OrderItems)';
        strQuery += ' FROM Order Where AccountId=:strEffectiveAccId AND PMC_DH_OrderTypeCode__c IN ' ;
        strQuery += Label.PMC_DH_OrderTypes; //added as part of GPT-28211 and Updated as part of GDASF-20299
       
        String strOrderCondition = '';
        if(searchParams.strStatus==PMC_DH_ConstantClass.ORDER_CONFIRMED )
        {
            strQuery+='AND PMC_CPQ_SAPOrderNumber__c!=null' ;
            strOrderCondition =  ' Order.PMC_CPQ_SAPOrderNumber__c LIKE';
        }
        else {
            strQuery+='AND PMC_CPQ_SAPOrderNumber__c=null' ;
            strOrderCondition = ' Order.OrderNumber LIKE ';
        }
        if(String.isNotBlank(searchParams.strSearchTerm)){
            String searchPattern = '\'%' + String.escapeSingleQuotes(searchParams.strSearchTerm) + '%\'';
            strQuery += ' AND ( Id IN (SELECT OrderId FROM OrderItem';
            strQuery += ' WHERE  '+ strOrderCondition + searchPattern  +' OR Order.Contract.SBQQ__Quote__r.PMC_CLM_DocumentNumber__c LIKE '+ searchPattern +'OR Order.PMC_CPQ_PO__c  LIKE '+ searchPattern +' OR Product2.Name LIKE '+ searchPattern +' OR PMC_DH_ProtocolIdentifier__c LIKE '+ searchPattern +' ' ;
            strQuery += ' OR PMC_CPQ_ShipTo__r.Name LIKE '+ searchPattern +' OR PMC_CPQ_ShipTo__r.ShippingCountry LIKE '+ searchPattern +' OR PMC_CPQ_ShipTo__r.ShippingPostalCode LIKE '+ searchPattern +' OR PMC_CPQ_ShipTo__r.ShippingCity LIKE '+ searchPattern +' OR PMC_CPQ_ShipTo__r.ShippingState LIKE '+ searchPattern +' OR PMC_CPQ_ShipTo__r.ShippingStateCode LIKE '+ searchPattern +' OR PMC_CPQ_ShipTo__r.ShippingStreet LIKE '+ searchPattern +'))';
        }
        if (searchParams.datFromDate != null && searchParams.datToDate != null) {
            strQuery += ' AND (CreatedDate >= ' + String.valueOf(searchParams.datFromDate) + PMC_DH_ConstantClass.START_TIME;
            strQuery += ' AND ';
            strQuery += 'CreatedDate <= ' + String.valueOf(searchParams.datToDate) + PMC_DH_ConstantClass.END_TIME;
            strQuery += ')';
        }
       
        strQuery += ' WITH SECURITY_ENFORCED Order BY CreatedDate DESC LIMIT 1001';
        return strQuery;
   
    }
    /**
* @description Method to get the orders in transit for homepage
* @return List<PMC_DH_HomePageWrapper.OrdersinTransit>
* @param lstOrder
* @param mapOrderShip
*/
   
    public static List<PMC_DH_HomePageWrapper.OrdersinTransit> getOrdersinTransitCall(List<Order>lstOrder,Map<String,SHIPMENTITEM> mapOrderShip )
    {
        List<PMC_DH_HomePageWrapper.OrdersinTransit> wrpOrderinTransit=new List<PMC_DH_HomePageWrapper.OrdersinTransit>();
        for(Order ordL:lstOrder)
        {
            Map<String,String> mapDeliveryModeOrderLine=new Map<String,String>();
            Map<String,String> mapWithProductIdName= new Map<String,String>();
            for(OrderItem ordItem:ordL.orderitems)
            {
               
                if(!mapWithProductIdName.containsKey(ordItem.product2Id)){
                    mapWithProductIdName.put(ordItem.product2Id,ordItem.Product2.Name);
                }
                if(!mapDeliveryModeOrderLine.containsKey(ordItem.id))
                {
                    mapDeliveryModeOrderLine.put(ordItem.id,ordItem.PMC_CPQ_ModeOfTransportation__c);
                }  
               
            }  
            PMC_DH_HomePageWrapper.OrdersinTransit ordInst=new PMC_DH_HomePageWrapper.OrdersinTransit();
            ordInst.strOrderId=ordL.Id;
            ordInst.strOrderNumber=ordL.PMC_CPQ_SAPOrderNumber__c;
            ordInst.strProduct=getProductOrShipToName(mapWithProductIdName,'');
            ordInst.strDeliveryMode=PMC_DH_HomePageController.getDeliveryMode(mapDeliveryModeOrderLine,ordL);
            //ordInst.strStatus=System.label.pmc_orderStatus_partiallyShipped;  // added explicitly because the order list contains only records with 'partially shipped' status
            ordInst.strStatus=System.label.PMC_DH_InProgress;  // change for GDASF-21480: added explicitly because the order list contains only records with 'In Progress'
            ordInst.datShipment=PMC_DH_HomePageController.getShipmentDate(mapOrderShip,ordL.Id);
            ordInst.strDetailPageUrl=PMC_DH_ConstantClass.ORDER_RELATIVE_PATH+ordInst.strOrderId+PMC_DH_ConstantClass.ORDER_NUMBER+ordL.OrderNumber+PMC_DH_ConstantClass.ORDER_ID+ordInst.strOrderId;
            wrpOrderinTransit.add(ordInst);
        }
        return wrpOrderinTransit;
       
    }
   
   
   
    /**
* * @description       : Wrapper for the Search Params
* * @author            : @Lohitha sai
* * @Created on        : 07-27-2023
**/
    public with sharing class OrderSearchParameterWrapper {
        /**
* * @description String searchterm
* * @return String
* */
        @AuraEnabled
        public String strSearchTerm { get; set; }
        /**
* * @description Date of From date
* * @return Date
* */
        @AuraEnabled
        public Date datFromDate { get; set; }
        /**
* * @description Date of To date
* * @return Date
* */
        @AuraEnabled
        public  Date datToDate { get; set; }
       
        /**
* @description status of order whether confirmed or requested
* @return String
*/
        @AuraEnabled
        public String strStatus {get; set;}
    }
}