/**
* @description : Service class for order submit integration 
* @author      : Mosaic Direct Dev 
* @userStory   : GDSAF-12228
* */
public without sharing class PMC_DH_OrderSubmitUtils{  
    
    public static Map<String,PMC_SS_AccountPartnerRelationships__c> cpfShipToMap;    
    
    /**
* @description 
* @author  Mosaic Direct Dev 
* @param responseWrapper 
* @param strEffectiveAccountId
* @return PMC_DH_OrderListViewWrapper 
**/
    public static PMC_DH_OrderListViewWrapper createOrderHistoryWrapper(List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> responseWrapper, String strEffectiveAccountId){
        PMC_DH_OrderFetchWrapper ordItemsWrapper = new PMC_DH_OrderFetchWrapper();
        PMC_DH_OrderListViewWrapper orderWrapper=new PMC_DH_OrderListViewWrapper();
        List<String> lstSku = new List<String>(); 
        List<PMC_DH_PicklistWrapper> lstProductWrapper = new List<PMC_DH_PicklistWrapper>();
        List<PMC_DH_OrderListViewWrapper.OrderInfoWrapper> lstOrderHistoryWrapper = new List<PMC_DH_OrderListViewWrapper.OrderInfoWrapper>();
        Map<String, List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper>> mapOfIdResponse = new Map<String, List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper>>();
        List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> lstProdFilters = new List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper>();
        mapOfIdResponse = getOrdItemsWrapper(responseWrapper, lstSku, mapOfIdResponse);
        List<Product2> lstProducts = [SELECT Id, StockKeepingUnit, Description, Name from Product2 where StockKeepingUnit IN :lstSku WITH SECURITY_ENFORCED ];
        Map<String, String> mapOfProdSKUName = PMC_DH_OrderUtilHelper.getProductNames(lstProducts);
        Map<String, String> mapContractNumber = PMC_DH_RequestedOrderDetailUtil.getContractInfo(mapOfIdResponse);
        
        cpfShipToMap = PMC_DH_OrderSubmitController.getCPFAccountMap(strEffectiveAccountId);
        //GSMD-339
        Map<String,PMC_SS_AccountPartnerRelationships__c> cpfShipToLegacyMap = PMC_DH_OrderSubmitController.getCPFAccountMapLegacy(strEffectiveAccountId);
        if(cpfShipToLegacyMap != null){
            cpfShipToMap.putAll(cpfShipToLegacyMap);
        }
        //processing for each order
        for(String strReqId : mapOfIdResponse.keySet()){
            List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> orderItemRecs = mapOfIdResponse.get(strReqId);
            lstProdFilters.addAll(orderItemRecs);
            PMC_DH_OrderListViewWrapper.OrderInfoWrapper ordHistoryWrap = processOrderItems(orderItemRecs,mapOfProdSkuName, strReqId);
            ordHistoryWrap.strPONumber =  String.isBlank(orderItemRecs[0].strContractFinalized) ? '' : orderItemRecs[0].strPoNumber;
            ordHistoryWrap.strContractNumber = String.isBlank(orderItemRecs[0].strContractFinalized) ? '' : mapContractNumber.get(strReqId);//orderItemRecs[0].strContractFinalized;
            ordHistoryWrap.orderDateCreated = PMC_DH_RequestedOrderDetailUtil.getCreatedDate(orderItemRecs[0].strCreatedOn);
            if(String.isNotBlank(strReqId) && strReqId != Null && (strReqId.split('-')).size()>1){
                ordHistoryWrap.strOrderNumber = ((strReqId).split('-'))[0]+ '-'+ ((strReqId).split('-'))[1];               
            }
            lstProductWrapper = getProductWrapper(lstProdFilters, mapOfProdSKUName);
            ordItemsWrapper.lstData = orderItemRecs;
            ordHistoryWrap.strOrderItems = JSON.Serialize(ordItemsWrapper);
            System.debug('utils->'+ordHistoryWrap.strOrderItems);
            
            lstOrderHistoryWrapper.add(ordHistoryWrap);  
        } 
        orderWrapper.lstProductFilters = lstProductWrapper;
        orderWrapper.lstOrders = lstOrderHistoryWrapper;
        orderWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'UserModalDetails');
        return orderWrapper;
    }
    
    /**
* @description processing each order item
* @author  Mosaic Direct Dev 
* @param responseWrapper
* @param lstSku
* @param mapOfIdResponse
* @return PMC_DH_OrderFetchWrapper 
**/ 
    private static Map<String, List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper>> getOrdItemsWrapper(List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> responseWrapper, List<String> lstSku,  Map<String, List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper>> mapOfIdResponse ){
        PMC_DH_OrderFetchWrapper ordItemsWrapper = new PMC_DH_OrderFetchWrapper();
        for(PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper responseWrap : responseWrapper){
            lstSku.add(responseWrap.strMaterial);
            if(String.isNotBlank(responseWrap.strReqId) && responseWrap.strReqId != Null && (responseWrap.strReqId.split('-')).size()>1){
                String strReqId = (responseWrap.strReqid).split('-')[0]+'-'+(responseWrap.strReqid).split('-')[1];
                
                if(!mapOfIdResponse.containsKey(strReqId)){
                    mapOfIdResponse.put(strReqId, new List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper>());
                }
                mapOfIdResponse.get(strReqId).add(responseWrap);
                ordItemsWrapper.lstData = mapOfIdResponse.get(strReqId);
            }
        }
        return mapOfIdResponse;
    }
    
    /**
* @description processing each order item
* @author Mosaic Direct Dev
* @param orderItemRecs
* @param mapOfProdSkuName
* @param strReqId
* @return PMC_DH_OrderListViewWrapper.OrderInfoWrapper 
**/
    private static PMC_DH_OrderListViewWrapper.OrderInfoWrapper processOrderItems(List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> orderItemRecs, 
                                                                                  Map<String, String> mapOfProdSkuName, String strReqId)
    {
        Map<String,String> mapOfAllProdSkuName = new Map<String,String>();
        Map<String,String> mapOfShiptToIdAdd = new Map<String,String>();
        Set<String> setReqShipmentDate = new Set<String>();
        Set<String> setProdSKUs = new Set<String>();
        Set<String> setProtocolNo = new Set<String>();
        Set<String> setSalesOrders = new Set<String>();
        Double intTotalQuantity = 0 ;//GPT-32983
        Double doubleTotalPrice = 0.0;
        String strSearchable;
        PMC_DH_OrderListViewWrapper.OrderInfoWrapper ordHistoryWrap = new PMC_DH_OrderListViewWrapper.OrderInfoWrapper();
        for(PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper wrap : orderItemRecs){
            if(PMC_DH_OrderUtilHelper.checkIfSetContainsValue(setProdSKUs,wrap.strMaterial)){
                setProdSKUs.add(wrap.strMaterial);
            }
            if(PMC_DH_OrderUtilHelper.checkIfSetContainsValue(setProtocolNo,wrap.strProtocolNo)){
                setProtocolNo.add(wrap.strProtocolNo);
            }
            if(PMC_DH_OrderUtilHelper.checkIfSetContainsValue(setSalesOrders,wrap.strSalesOrder)){
                setSalesOrders.add(PMC_DH_RequestedOrderDetailUtil.getSalesOrderNumber(wrap.strSalesOrder));
            }
            if(!mapOfAllProdSkuName.containsKey(wrap.strMaterial)){
                mapOfAllProdSkuName.put(wrap.strMaterial, mapOfProdSKUName.get(wrap.strMaterial));
            }
            if(PMC_DH_OrderUtilHelper.checkIfSetContainsValue(setReqShipmentDate,wrap.strReqdeldate)){
                String strDelDate = PMC_DH_OrderUtilHelper.formatShipmentDate(wrap.strReqdeldate);   
                setReqShipmentDate.add(strDelDate);
            }
            
            // added as part of GDASF-19767 
            mapOfShiptToIdAdd = PMC_DH_OrderSubmitController.updateShipToAddressMap(mapOfShiptToIdAdd, wrap, cpfShipToMap);
            
            intTotalQuantity += Double.valueOf(wrap.strRequestqty);//GPT-32983
            doubleTotalPrice += Double.ValueOf(wrap.strTotprice);
            strSearchable = formatReqId(strReqId, wrap, mapOfProdSKUName );
        }
        setOrderProductDetails(ordHistoryWrap, mapOfAllProdSkuName, setProdSKUs);
        setRequestedShipDate(ordHistoryWrap, setReqShipmentDate);
        setShipToDetails(ordHistoryWrap, mapOfShiptToIdAdd);
        ordHistoryWrap.strProtocolNo = getProtocolNoOrSalesOrder(setProtocolNo);
        ordHistoryWrap.strSalesOrder = getProtocolNoOrSalesOrder(setSalesOrders);
        ordHistoryWrap.totalQuantity = intTotalQuantity;
        ordHistoryWrap.totalPrice = doubleTotalPrice;
        ordHistoryWrap.strSearchable = strSearchable + ' ' + ordHistoryWrap.strProtocolNo.replace(';',',');        
        return ordHistoryWrap;
    }

    /**
     * @description Set Ship To
     * @param ordHistoryWrap
     * @param mapOfShiptToIdAdd
     */
    private static void setShipToDetails(PMC_DH_OrderListViewWrapper.OrderInfoWrapper ordHistoryWrap, Map<String,String> mapOfShiptToIdAdd) {
        ordHistoryWrap.shipTo = getShipTOorProductName(mapOfShiptToIdAdd);
        ordHistoryWrap.strShipToNames = String.join(mapOfShiptToIdAdd.values(), ';');
    }

    /**
     * @description Set product Names and SKU related to order
     * @param ordHistoryWrap
     * @param mapOfAllProdSkuName
     * @param setProdSKUs
     */
    private static void setOrderProductDetails(PMC_DH_OrderListViewWrapper.OrderInfoWrapper ordHistoryWrap, Map<String,String> mapOfAllProdSkuName,  Set<String> setProdSKUs) {
        ordHistoryWrap.strProducts = getShipTOorProductName(mapOfAllProdSkuName);
        ordHistoryWrap.strProductNames = String.join(mapOfAllProdSkuName.values(), ';');
        ordHistoryWrap.setSKU = new List<String>(setProdSKUs);
    }
    
    /**
* @description formatting shipment date
* @author  Mosaic Direct Dev 
* @param strReqId
* @param wrap
* @param mapOfProdSKUName
* @return  String
**/
    public static String formatReqId(String strReqId, PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper wrap, Map<String,String> mapOfProdSKUName){
        String strSearchable;
        if(String.isNotBlank(strReqId) && strReqId != Null && strReqId.split('-').size()>1){
            strSearchable=strReqId.split('-')[1] +' '+wrap.strContractFinalized+' '+wrap.strPONumber+' ';
            strSearchable+=mapOfProdSKUName.get(wrap.strMaterial)+' '+wrap.strShiptoAdd;
            
        }
        return strSearchable;
    }
    
    /**
* @description 
* @author  Mosaic Direct Dev 
* @param orderItemRecs 
* @param mapOfProdSKUName
* @return List<PMC_DH_PicklistWrapper> 
**/
    private static List<PMC_DH_PicklistWrapper> getProductWrapper(List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> orderItemRecs,
                                                                  Map<String,String> mapOfProdSKUName)
    {                                                                      
        List<PMC_DH_PicklistWrapper> lstProductWrapper = new List<PMC_DH_PicklistWrapper>();
        lstProductWrapper = getListFilter(mapOfProdSKUName,mapOfProdSKUName.keySet());
        
        return lstProductWrapper;
    }



     /**
* @description 
* @author  Mosaic Direct Dev 
* @param setValues 
* @return String 
**/
public static String getProtocolNoOrSalesOrder(Set<String> setValues){
    String strProtoOrOrderNo = '' ;
    if(setValues.size()==1 ){
        strProtoOrOrderNo = String.valueOf(new List<String> (setValues).get(0));
    }
    else if(setValues.size() > 1){
        strProtoOrOrderNo = String.join(setValues, ';');//'Multiple';
    }
    return strProtoOrOrderNo;
}
    
    /**
* @description 
* @author  Mosaic Direct Dev 
* @param mapOfProorShipToName 
* @return String 
**/
    public static String getShipTOorProductName(Map<String,String> mapOfProorShipToName){
        String prodOrShipToName = '' ;
        if(mapOfProorShipToName.size()==1 ){
            prodOrShipToName = mapOfProorShipToName.values()[0];
        }
        else if(mapOfProorShipToName.size() > 1){
            prodOrShipToName = System.label.pmc_requestToDeliverShippingInformation_multiple;
        }
        return prodOrShipToName;
    }
    
    /**
* @description 
* @author  Mosaic Direct Dev 
* @param ordHistoryWrap
* @param setReqShipmentDate 
**/
    public Static void setRequestedShipDate(PMC_DH_OrderListViewWrapper.OrderInfoWrapper ordHistoryWrap, Set<String> setReqShipmentDate){
        String strReqShipmentDate = '';
        if(setReqShipmentDate.size()==1){
            strReqShipmentDate = String.ValueOf(new List<String> (setReqShipmentDate).get(0));
        }
        else if(setReqShipmentDate.size() >1){
            strReqShipmentDate = System.label.pmc_requestToDeliverShippingInformation_multiple;
        }
        ordHistoryWrap.orderShipmentDate = strReqShipmentDate;
        ordHistoryWrap.strReqShipDates = String.join(setReqShipmentDate, ';');
    }
    
    /**
* @description 
* @author  Mosaic Direct Dev 
* @param mapOfProdSKUName 
* @param  setSku
* @return List<PMC_DH_PicklistWrapper> 
**/
    public static List<PMC_DH_PicklistWrapper> getListFilter(Map<String, String> mapOfProdSKUName, Set<String> setSku){
        List<PMC_DH_PicklistWrapper> lstProductWrapper = new List<PMC_DH_PicklistWrapper>();
        for(String strSku : setSku){
            PMC_DH_PicklistWrapper productWrapper = new PMC_DH_PicklistWrapper(); 
            productWrapper.Label = mapOfProdSKUName.get(strSku);
            productWrapper.Value = strSku;                    
            
            lstProductWrapper.add(productWrapper);
        }           
        
        
        return lstProductWrapper;
    }
}