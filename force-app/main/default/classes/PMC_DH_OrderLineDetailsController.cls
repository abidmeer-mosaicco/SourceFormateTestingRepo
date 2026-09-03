/** 
* @description Controller for fetching OrderLine Details 
* @author Ajeet
* @last modified on 
* @last modified by 
* Created On       :2023-Sep-21
**/
public without sharing class PMC_DH_OrderLineDetailsController {

    public static final String ORDER_LINE_SUCCESS_MODULE = 'OrderLine';
    /*************************************************************************
* @method Name  : getOrderLineDetails
* @description  : Method to get the Order Details Page info in wrapper class
* @param        orderLineId
* @param strLocale
* @return       : List<PMC_DH_OrderLineDetailsWrapper>
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_OrderLineDetailsWrapper getOrderLineDetails(String orderLineId, String strLocale){
        PMC_DH_OrderLineDetailsWrapper orderLineItem = new PMC_DH_OrderLineDetailsWrapper();
        try{
            List<OrderItem> lstOrderItem;
            if(!String.isBlank(orderLineId)){
                lstOrderItem = [SELECT Id, Order.Account.Name,LineNumber,SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PriceByDate__c,  Product2.name,PMC_CPQ_ShipTo__r.Name, PMC_CPQ_ShipTo__r.ShippingStreet,
                PMC_CPQ_ShipTo__r.ShippingCity,PMC_CPQ_ShipTo__r.ShippingState,PMC_CPQ_ShipTo__r.ShippingCountry, PMC_CPQ_ShipTo__r.ShippingPostalCode,PMC_DH_CustomerCallPriceDate__c,PMC_CPQ_FPDPricefromPriceFx__c,
                toLabel(PMC_CPQ_Incoterms__c),toLabel(PMC_CPQ_ModeofTransportation__c),PMC_CPQ_ConfirmedQuantity__c,PMC_CPQ_OrderLineStatus__c,PMC_DH_CallPriceRequestedBySystem__c,PMC_CPQ_ReasonOfRejectionOfItem__c,
                (SELECT Id,Product2.Name, PMC_CPQ_LinePONumber__c, PMC_CPQ_ShippedDate__c,PMC_CPQ_DeliveryQuantity__c,
                PMC_CPQ_DeliveryLineStatus__c,ShipmentItemNumber,PMC_CPQ_DeliveryItemID__c,Shipment.PMC_CPQ_SAPDeliveryID__c, Shipment.ShipmentNumber, Shipment.PMC_CPQ_VehicleID__c, Shipment.PMC_CPQ_ETA__c, Shipment.PMC_CPQ_CurrentLocation__c, Shipment.PMC_CPQ_ShippedDate__c ,Shipment.status from Delivery_Items__r where Shipment.status!='Delivery Deleted'),
                //549
                (select id, PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c,PMC_CPQ_DeliveryItem__c FROM InvoiceItems__r) FROM OrderItem 
                where Id=:orderLineId WITH SECURITY_ENFORCED]; //GDASF-20619
            }
            if(!lstOrderItem.isEmpty()){
            PMC_DH_OrderLineDetailsWrapper.ShipToWrapper shipToWraper = new PMC_DH_OrderLineDetailsWrapper.ShipToWrapper();
            shipToWraper.strAddressLine1 = lstOrderItem[0].PMC_CPQ_ShipTo__r.Name;
            shipToWraper.strAddressLine2 = lstOrderItem[0].PMC_CPQ_ShipTo__r.ShippingStreet;
            shipToWraper.strCity = lstOrderItem[0].PMC_CPQ_ShipTo__r.ShippingCity;
            shipToWraper.strState = lstOrderItem[0].PMC_CPQ_ShipTo__r.ShippingState;
            shipToWraper.strCountry = lstOrderItem[0].PMC_CPQ_ShipTo__r.ShippingCountry;
            shipToWraper.strZipCode = lstOrderItem[0].PMC_CPQ_ShipTo__r.ShippingPostalCode;
    
            List<PMC_DH_OrderLineDetailsWrapper.DeliveriesWrapper> lstDeliveriesWrapper = new List<PMC_DH_OrderLineDetailsWrapper.DeliveriesWrapper>();
                Map<String,List<PMC_DH_PicklistWrapper>> mapPicklistWrapper = getOrderDocument(lstOrderItem[0],strLocale);
            if(!lstOrderItem[0].Delivery_Items__r.isEmpty()){
                // added by Nikhilesh as part of GPT-27880
                    lstDeliveriesWrapper = PMC_DH_OrderLineDetailsUtil.getDeliveries(lstOrderItem[0], mapPicklistWrapper);
            }
    		
                PMC_DH_OrderLineDetailsWrapper.OrderLineSummaryWrapper orderLineSummary = new PMC_DH_OrderLineDetailsWrapper.OrderLineSummaryWrapper();
                orderLineSummary.boolCheckModal = PMC_DH_OrderLineDetailsUtil.getBoolValues(orderLineSummary,lstOrderItem);
                orderLineSummary.boolCallPriceRequestedBySystem = lstOrderItem[0].PMC_DH_CallPriceRequestedBySystem__c;
                orderLineSummary.strProductName = lstOrderItem[0].Product2.name;
                orderLineSummary.strCustomerName = lstOrderItem[0].Order.Account.Name;
                orderLineSummary.strShipTo = shipToWraper;
                orderLineSummary.strDeliveryInformation = lstOrderItem[0].PMC_CPQ_Incoterms__c + ' - ' + lstOrderItem[0].PMC_CPQ_ModeofTransportation__c;
                orderLineSummary.strTotalOrderLineQty = String.valueOf(lstOrderItem[0].PMC_CPQ_ConfirmedQuantity__c);
                orderLineSummary.strOrderLineStatus = PMC_DH_OrderUtilHelper.setDeliveryStatus(lstOrderItem[0]); //.PMC_CPQ_OrderLineStatus__c
                orderLineSummary.datCallPriceDate = lstOrderItem[0].SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PriceByDate__c;
                orderLineSummary.lstDeliveries = lstDeliveriesWrapper;
        
                orderLineItem.strOrderLine = String.valueOf(lstOrderItem[0].LineNumber);
                orderLineItem.strOrderLineItemId = orderLineId;
                orderLineItem.objOrderLineSummary = orderLineSummary;
                orderLineItem.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, ORDER_LINE_SUCCESS_MODULE); 
            }
        }catch(Exception ex){
            orderLineItem.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return orderLineItem;
    }    

/*************************************************************************
* @method Name  : getOrderDocument
* @description  : Method to get 'Type' information in wrapper form
* @param orderItem
* @param strLocale
* @return       : Map<String,List<PMC_DH_PicklistWrapper>>
*****************************************************************************/
public static Map<String,List<PMC_DH_PicklistWrapper>> getOrderDocument(OrderItem orderItem, String strLocale){
    Map<String,List<PMC_DH_PicklistWrapper>> mapPicklist = new Map<String,List<PMC_DH_PicklistWrapper>>();
    if(!orderItem.Delivery_Items__r.isEmpty()){
        getDeliveryData(orderItem.Delivery_Items__r,mapPicklist,strLocale);
    }
    if(!orderItem.InvoiceItems__r.isEmpty()){
        getInvoiceData(orderItem.InvoiceItems__r,mapPicklist, strLocale);
    }
    return mapPicklist;
}

private static void getDeliveryData(List<ShipmentItem> lstShipmentItem, Map<String,List<PMC_DH_PicklistWrapper>> mapPicklist, String strLocale){
    // From user's country (United States/Canada/Brazil), get the region (NA/BR)
    String strRegion = PMC_DH_CommonSystemUtils.getUserRegion(strLocale); //GPT-44509
    Map<String, PMC_DH_DocumentType__mdt> mapDocTypeMetadata = PMC_DH_DocumentType__mdt.getAll(); //GPT-44509
    
    PMC_DH_DocumentType__mdt mdtBOL = mapDocTypeMetadata.get('BillOfLading'); //GPT-44509
    List<String> lstBOLRegions = mdtBOL.PMC_DH_Region__c.split(';'); //GPT-44509
    PMC_DH_DocumentType__mdt mdtCOA = mapDocTypeMetadata.get('CertificateOfAnalysis'); //GPT-44509
    List<String> lstCOARegions = mdtCOA.PMC_DH_Region__c.split(';'); //GPT-44509
    for(ShipmentItem shipItem: lstShipmentItem){
        List<PMC_DH_PicklistWrapper> lstOrderDocument = new List<PMC_DH_PicklistWrapper>();
        Set<String> setProductDoc = new Set<String>();

        if(shipItem.Shipment.ShipmentNumber != null && !setProductDoc.contains(PMC_DH_ConstantClass.BOL) && lstBOLRegions.contains(strRegion)){ //GPT-44509
            PMC_DH_PicklistWrapper orderDocument1 = new PMC_DH_PicklistWrapper();
            orderDocument1.label = System.Label.PMC_DH_BillofLading;
            orderDocument1.value = PMC_DH_ConstantClass.BOL;
            lstOrderDocument.add(orderDocument1); 
            setProductDoc.add(PMC_DH_ConstantClass.BOL);
        }
        
        if(shipItem.Shipment.ShipmentNumber != null && shipItem.ShipmentItemNumber != null && lstCOARegions.contains(strRegion) && !setProductDoc.contains(PMC_DH_ConstantClass.COA)){
            PMC_DH_PicklistWrapper orderDocument2 = new PMC_DH_PicklistWrapper();
            orderDocument2.label = System.Label.PMC_DH_CertificateofAnalysis;
            orderDocument2.value = PMC_DH_ConstantClass.COA;
            lstOrderDocument.add(orderDocument2);
            setProductDoc.add(PMC_DH_ConstantClass.COA);
        }
        mapPicklist.put(shipItem.Id,lstOrderDocument);
    }
    
    /* for(ShipmentItem shipItem: lstShipmentItem){
        List<PMC_DH_PicklistWrapper> lstOrderDocument = new List<PMC_DH_PicklistWrapper>();
        Set<String> setProductDoc = new Set<String>();
        if(shipItem.Shipment.ShipmentNumber != null && !setProductDoc.contains(PMC_DH_ConstantClass.BOL)){ 
            PMC_DH_PicklistWrapper orderDocument1 = new PMC_DH_PicklistWrapper();
            orderDocument1.label = System.Label.PMC_DH_BillofLading;
            orderDocument1.value = PMC_DH_ConstantClass.BOL;
            lstOrderDocument.add(orderDocument1); 
            setProductDoc.add(PMC_DH_ConstantClass.BOL);
        }
        if(shipItem.Shipment.ShipmentNumber != null && shipItem.ShipmentItemNumber != null && strLocale == PMC_DH_ConstantClass.UNITEDSTATES &&!setProductDoc.contains(PMC_DH_ConstantClass.COA)){
            PMC_DH_PicklistWrapper orderDocument2 = new PMC_DH_PicklistWrapper();
            orderDocument2.label = System.Label.PMC_DH_CertificateofAnalysis;
            orderDocument2.value = PMC_DH_ConstantClass.COA;
            lstOrderDocument.add(orderDocument2);
            setProductDoc.add(PMC_DH_ConstantClass.COA);
        }
        mapPicklist.put(shipItem.Id,lstOrderDocument);
    } */
}

private static void getInvoiceData(List<PMC_CPQ_InvoiceItem__c> lstInvoiceItem,Map<String,List<PMC_DH_PicklistWrapper>> mapPicklist, String strLocale){
    // From user's country (United States/Canada/Brazil), get the region (NA/BR)
    String strRegion = PMC_DH_CommonSystemUtils.getUserRegion(strLocale); //GPT-44509
    Map<String, PMC_DH_DocumentType__mdt> mapDocTypeMetadata = PMC_DH_DocumentType__mdt.getAll(); //GPT-44509
    
    PMC_DH_DocumentType__mdt mdtINV = mapDocTypeMetadata.get(PMC_DH_ConstantClass.INV_MDT); //GPT-44509
    List<String> lstINVRegions = mdtINV.PMC_DH_Region__c.split(';'); //GPT-44509
    PMC_DH_DocumentType__mdt mdtNFE = mapDocTypeMetadata.get('NotaFiscal'); //GPT-44509
    List<String> lstNFERegions = mdtNFE.PMC_DH_Region__c.split(';'); //GPT-44509
    for(PMC_CPQ_InvoiceItem__c invoiceItem: lstInvoiceItem){
        List<PMC_DH_PicklistWrapper> lstOrderDocument = new List<PMC_DH_PicklistWrapper>();
        Set<String> setInvoiceDoc = new Set<String>();
        if(invoiceItem.PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c!=null && !setInvoiceDoc.contains(PMC_DH_ConstantClass.INV) && lstINVRegions.contains(strRegion)){ //GPT-44509
            PMC_DH_PicklistWrapper orderDocument3 = new PMC_DH_PicklistWrapper();
            orderDocument3.label = System.Label.PMC_DH_Invoice;
            orderDocument3.value = PMC_DH_ConstantClass.INV;
            lstOrderDocument.add(orderDocument3);
            setInvoiceDoc.add(PMC_DH_ConstantClass.INV);
        }
        if(invoiceItem.PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c!=null && lstNFERegions.contains(strRegion) && !setInvoiceDoc.contains(PMC_DH_ConstantClass.NFE)){
            PMC_DH_PicklistWrapper orderDocument4 = new PMC_DH_PicklistWrapper();
            orderDocument4.label = System.Label.PMC_DH_NotaFiscal;
            orderDocument4.value = PMC_DH_ConstantClass.NFE;
            lstOrderDocument.add(orderDocument4);
            setInvoiceDoc.add(PMC_DH_ConstantClass.NFE);
        }
        if(mapPicklist.containsKey(invoiceItem.PMC_CPQ_DeliveryItem__c)){
            mapPicklist.get(invoiceItem.PMC_CPQ_DeliveryItem__c).addAll(lstOrderDocument);
        }else{
            mapPicklist.put(invoiceItem.PMC_CPQ_DeliveryItem__c,lstOrderDocument);
        }
    }
    
    /*
    for(PMC_CPQ_InvoiceItem__c invoiceItem: lstInvoiceItem){
        List<PMC_DH_PicklistWrapper> lstOrderDocument = new List<PMC_DH_PicklistWrapper>();
        Set<String> setInvoiceDoc = new Set<String>();
        if(invoiceItem.PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c!=null && !setInvoiceDoc.contains(PMC_DH_ConstantClass.INV)){
            PMC_DH_PicklistWrapper orderDocument3 = new PMC_DH_PicklistWrapper();
            orderDocument3.label = System.Label.PMC_DH_Invoice;
            orderDocument3.value = PMC_DH_ConstantClass.INV;
            lstOrderDocument.add(orderDocument3);
            setInvoiceDoc.add(PMC_DH_ConstantClass.INV);
        }
        if(invoiceItem.PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c!=null && strLocale == PMC_DH_ConstantClass.BRAZIL && !setInvoiceDoc.contains(PMC_DH_ConstantClass.NFE)){
            PMC_DH_PicklistWrapper orderDocument4 = new PMC_DH_PicklistWrapper();
            orderDocument4.label = System.Label.PMC_DH_NotaFiscal;
            orderDocument4.value = PMC_DH_ConstantClass.NFE;
            lstOrderDocument.add(orderDocument4);
            setInvoiceDoc.add(PMC_DH_ConstantClass.NFE);
        }
        if(mapPicklist.containsKey(invoiceItem.PMC_CPQ_DeliveryItem__c)){
            mapPicklist.get(invoiceItem.PMC_CPQ_DeliveryItem__c).addAll(lstOrderDocument);
        }else{
            mapPicklist.put(invoiceItem.PMC_CPQ_DeliveryItem__c,lstOrderDocument);
        }
    } */
}
/*************************************************************************
* @method Name  : getDocumentData
* @description  : Method to get download information
* @param orderItem
* @param strRegion
* @return       : Map<String,Map<String,String>> 
*****************************************************************************/
public static Map<String,Map<String,String>> getDocumentData(OrderItem orderItem, String strRegion){
    Map<String,Map<String,String>> mapResult = new Map<String,Map<String,String>>();
    List<PMC_DH_DocumentType__mdt> lstDocType = [SELECT Id, PMC_DH_DocumentCode__c, PMC_DH_Identifier__c, PMC_DH_Region__c FROM PMC_DH_DocumentType__mdt WITH USER_MODE];
    for(PMC_DH_DocumentType__mdt docType: lstDocType){
        ListWrapper lstWrp=new ListWrapper();
        lstWrp.lstString = docType.PMC_DH_Identifier__c.split(';');
        lstWrp.lstRegions = docType.PMC_DH_Region__c.split(';'); //GPT-44509
        lstWrp.mapResult=mapResult;
        lstWrp.strRegion=strRegion;
        mapResult=PMC_DH_OrderUtilHelper.generateMaps(docType,orderItem,lstWrp);
        if((docType.PMC_DH_DocumentCode__c == PMC_DH_ConstantClass.INV || docType.PMC_DH_DocumentCode__c == PMC_DH_ConstantClass.NFE)
           && lstWrp.lstRegions.contains(strRegion)){ //GPT-44509
            getInvoiceItem(orderItem.InvoiceItems__r,docType, mapResult);
        }
    }
    return mapResult;
}

    

    private static void getInvoiceItem(List<PMC_CPQ_InvoiceItem__c> lstInvoiceItem, PMC_DH_DocumentType__mdt docType, Map<String,Map<String,String>> mapResult){
        for(PMC_CPQ_InvoiceItem__c invoiceItem: lstInvoiceItem){
            if(invoiceItem.PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c!=null){
                Map<String,String> mapString = new Map<String,String>();
                mapString.put(docType.PMC_DH_Identifier__c,invoiceItem.PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c);
                mapResult.put(docType.PMC_DH_DocumentCode__c,mapString);
            }
            /*if((docType.PMC_DH_DocumentCode__c == PMC_DH_ConstantClass.INV || docType.PMC_DH_DocumentCode__c == PMC_DH_ConstantClass.NFE) && invoiceItem.PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c!=null){
                Map<String,String> mapString = new Map<String,String>();
                mapString.put(docType.PMC_DH_Identifier__c,invoiceItem.PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c);
                mapResult.put(docType.PMC_DH_DocumentCode__c,mapString);
            }*/
        }
    }

/**
    * @description Wrapper Class for returning list
    **/
    public with sharing class ListWrapper
    {
        /**
         * @description list of string for regions
         * @return List<String>
         */
        @AuraEnabled
        public List<String> lstString{get;set;}

        /**
         * @description list of string for regions
         * @return List<String>
         */
        @AuraEnabled
        public List<String> lstRegions{get;set;}
        
        /**
         * @description list of string for regions
         * @return Map<String,Map<String,String>>
         */
        @AuraEnabled
        public Map<String,Map<String,String>> mapResult{get;set;}

         /**
         * @description  string for regions
         * @return String
         */
        @AuraEnabled
        public String strRegion{get;set;}
    }
    
}