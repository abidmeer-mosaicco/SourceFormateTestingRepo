/**
* @description       : 
* @author            : Mosaic Direct | Dev Team
* @group             : 
* @last modified on  : 12-22-2023
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/

public with sharing class PMC_DH_RequestedOrderDetails {

    private static Map<String, List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper>> mapOfGroupingAndItems = new Map<String, List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper>>();
    public static List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> respData=new List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper>();
   
    public static final String ORDER_FETCH_SUCCESS_MODULE = 'Order_Creation_Success';
    public enum ORDER_REFERENCE_TYPES {
        SOURCE,
        ORDERNUMBER,
        SOURCE_ORDERNUMBER,
        SOURCE_ORDERNUMBER_GROUPNUMBER
    }
    
    /**
* @description 
* @author Mosaic Direct | Dev Team | 10-15-2023 
* @param strCommunityId 
* @param strEffectiveAccountId 
* @param responseDetails 
* @return PMC_DH_OrderDetailsWrapper 
**/
    @AuraEnabled(cacheable=false)
    public static PMC_DH_OrderDetailsWrapper getOrderDetails(String strCommunityId,String strEffectiveAccountId,String responseDetails){
        PMC_DH_OrderDetailsWrapper orderDetailsWrapper = new PMC_DH_OrderDetailsWrapper();
        try{
            if(responseDetails != null) {
            PMC_DH_OrderFetchWrapper orderFetch = (PMC_DH_OrderFetchWrapper)JSON.deserialize(responseDetails, PMC_DH_OrderFetchWrapper.Class);
            // method to fetch Order details
            respData=orderFetch.lstData;
            if(respData.isEmpty())
            {
                return orderDetailsWrapper;
            }
            
            // get key fields 
            PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper objSummaryData=respData[0];
            
            // method to filter out key information 
            
            orderDetailsWrapper.strWebReferenceNumber =getReferenceIdByType(objSummaryData.strReqId,ORDER_REFERENCE_TYPES.SOURCE_ORDERNUMBER);
            orderDetailsWrapper.strOrderStatus = system.label.pmc_orderHistory_requested;//PMC_DH_ConstantClass.ORDER_SUMMARY_STATUS;
            //Added as part of 20003
            orderDetailsWrapper.boolVCOFlag = PMC_DH_RequestedOrderDetailUtil.isVCOContract(objSummaryData.strContractFinalized, objSummaryData.strReqId);
            // method to assign Order Summary details in a wrapper
            PMC_DH_OrderDetailsWrapper.OrderSummaryWrapper orderSummaryWrapper = new PMC_DH_OrderDetailsWrapper.OrderSummaryWrapper();
            orderSummaryWrapper.strCustomerName = objSummaryData.strSoldtoName;
            orderSummaryWrapper.strOrderPlacedBy = objSummaryData.strCreateBy;
            orderSummaryWrapper.strSummaryStatus = System.label.pmc_orderDetails_statusPlaced;//'Placed';
            DateTime datTime = PMC_DH_RequestedOrderDetailUtil.getCreatedDate(objSummaryData.strCreatedOn);
            orderSummaryWrapper.datDatePlaced = Date.NewInstance(datTime.year(),datTime.Month(),datTime.Day());
            orderSummaryWrapper.strSalesChannel = objSummaryData.strCreateVia;
            orderDetailsWrapper.orderSummaryWrapper = orderSummaryWrapper;
            
            
            // get contract data from contract number
            if(String.isNotBlank(objSummaryData.strContractFinalized) && objSummaryData.strContractFinalized != Null){
                String strContractNumber=objSummaryData.strContractFinalized;
           
                String strContractId = getContractIdByNumber(strContractNumber);
                // fetch contract details using existing method
                PMC_DH_RequestToDeliverWrapper.ContractSummaryWrapper contractSummaryWrapper = PMC_DH_ContractUtil.getContractSummary(strContractId);
                orderSummaryWrapper.strCurrencyIsoCode = contractSummaryWrapper.strCurrencyIsoCode;
                // assign only the required values to contract info wrapper
                orderDetailsWrapper.contractInfoWrapper = PMC_DH_OrderManagementHelper.getContractInfo(contractSummaryWrapper);
                orderDetailsWrapper.contractInfoWrapper.strContractId = strContractId;                
                
                //Assign values to contract wrapper for validation
                orderDetailsWrapper.lstContractWrapper = PMC_DH_RequestedOrderDetailUtil.getContractValidationWrapper(strContractId,respData);                
        }                                  
           
            // method to assign Product Info details in a wrapper
            orderDetailsWrapper.productInfoWrapper = getProductInfo(strCommunityId, strEffectiveAccountId);
            orderDetailsWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, ORDER_FETCH_SUCCESS_MODULE);  
        }          
        }
        catch(Exception ex){
            orderDetailsWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
            PMC_ErrorLogClass.processException(ex);
        } 
        return orderDetailsWrapper;
        
    }
    private static String getContractIdByNumber(String strContractNumber) {
        String conId='';
        List<Contract> lstContract=[Select Id from Contract where PMC_CPQ_ContractNumberIdentifier__c = :strContractNumber WITH SECURITY_ENFORCED  LIMIT 1];
        if(!lstContract.isEmpty()){
            conId=lstContract[0].Id;
        }
        return conId;
    }
    
    /**
* @description 
* @author Mosaic Direct | Dev Team | 10-15-2023 
* @param listLineitems 
* @return Map<String, List<PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper>> 
**/
    public static Map<String,List<PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper>> getShipmentPlanDetails(List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> listLineitems){
        Map<String, List<PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper>> mapShipmentPlan = new Map<String,List<PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper>>();
        Set<String> setUniqueIds = new Set<String>();
        String strDelDate;
        List<PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper> lstShipmentPlanWrapper;
        PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper objShipmentPlanWrap;
        List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> lstOrderItems;
        //iterate over the response 
        for(PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper oi : listLineitems){
            objShipmentPlanWrap = new PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper();
            objShipmentPlanWrap.strOrderItemId = oi.strReqId;
            if(String.isNotBlank(oi.strReqDelDate)){
                if(oi.strReqdeldate.contains('.')){
                    List<String> lstDelDate = oi.strReqdeldate.split('\\.');
                    strDelDate = lstDelDate[2]+'-'+lstDelDate[1] +'-'+ lstDelDate[0];
                }
                else{
                    List<String> lstDelDate = oi.strReqdeldate.split('-');
                    strDelDate = lstDelDate[0]+'-'+lstDelDate[1] +'-'+ lstDelDate[2];
                }
                objShipmentPlanWrap.strSalesOrder = PMC_DH_RequestedOrderDetailUtil.getSalesOrderNumber(oi.strSalesOrder);
                objShipmentPlanWrap.strProtocolNo = oi.strProtocolNo;
                objShipmentPlanWrap.strRequestedShipmentDate = strDelDate;
                objShipmentPlanWrap.isEditDisabled =  String.isNotBlank(respData[0].strContractFinalized) ? PMC_DH_RequestedOrderDetailUtil.checkEdit(strDelDate) : false ;

                objShipmentPlanWrap.strPackType = (PMC_DH_RequestedOrderDetailUtil.getPackandPackagingType(oi.strPackType,oi.strPackingType)).get('strPackType');
                objShipmentPlanWrap.strPackageType = (PMC_DH_RequestedOrderDetailUtil.getPackandPackagingType(oi.strPackType,oi.strPackingType)).get('strPackageType');
            }
            objShipmentPlanWrap.intRequestedQty = Double.valueOf(oi.strRequestQty);// GDASF-30410
            objShipmentPlanWrap.intConfirmedQty = Double.valueOf(oi.strConfirmedCuttingQty);// GDASF-30410
            // in api unique id is caluculated as follows - reqId = MD-0000000001-1-1 where MD-0000000001-1 is the key
            String strUniqueId = getReferenceIdByType(oi.strReqId,ORDER_REFERENCE_TYPES.SOURCE_ORDERNUMBER_GROUPNUMBER);
            if(!setUniqueIds.contains(strUniqueId)){
                setUniqueIds.add(strUniqueId);
                lstShipmentPlanWrapper = new List<PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper>();
                lstOrderItems = new List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper>();
            }
            else{
                lstShipmentPlanWrapper = mapShipmentPlan.get(strUniqueId);
                lstOrderItems = mapOfGroupingAndItems.get(strUniqueId);
            }
            lstShipmentPlanWrapper.add(objShipmentPlanWrap);
            mapShipmentPlan.put(strUniqueId, lstShipmentPlanWrapper);
            lstOrderItems.add(oi);
            mapOfGroupingAndItems.put(strUniqueId, lstOrderItems);
        }
        
        return mapShipmentPlan;
    }
    
    
    /**
* @description 
* @author Mosaic Direct | Dev Team | 10-15-2023 
* @param listLineitems 
* @param strEffectiveAccountId
* @return Map<String, List<PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper>> 
**/
    public static Map<String,List<PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper>> getShipmentItemDetails(List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> listLineitems, String strEffectiveAccountId){
        Map<String,List<PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper>> mapShipmentItems = new Map<String,List<PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper>>();
        PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper objShipmentItemWrap;
        try{
            
            // contains the map of cartgroupId and its shipmentlist
            Map<String, List<PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper>> mapShipmentPlan = getShipmentPlanDetails(listLineitems);
            for(String s : mapShipmentPlan.keyset()){
                objShipmentItemWrap = new PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper();
                objShipmentItemWrap.boolShipmentPlan = false;
                List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> lstOrderItems = mapOfGroupingAndItems.get(s);
                PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper oi = lstOrderItems[0];
                
                PMC_DH_PicklistWrapper wrpShipTo = new PMC_DH_PicklistWrapper();
                // changes added as part of GDASF-19767
                if(String.isNotBlank(oi.strShiptoId)){
                    wrpShipTo.label = oi.strShiptoName + ' ' + oi.strShiptoAdd;//PMC_CPQ_ShipTo__r.Name + + ' ' + oi.PMC_CPQ_ShipTo__r.ShippingStreet + ', ' + oi.PMC_CPQ_ShipTo__r.ShippingCity + ', ' + oi.PMC_CPQ_ShipTo__r.ShippingState + ' ' + oi.PMC_CPQ_ShipTo__r.ShippingPostalCode;
                    wrpShipTo.value = oi.strShiptoId;
                }
                else if(String.isNotBlank(oi.strAccIdentifier)){
                    Map<String,PMC_SS_AccountPartnerRelationships__c> cpfShipToMap = PMC_DH_OrderSubmitController.getCPFAccountMap(strEffectiveAccountId);
                    PMC_SS_AccountPartnerRelationships__c objShipTo = cpfShipToMap.get(oi.strAccIdentifier);
                    if(objShipTo !=null){
                        wrpShipTo.label = objShipTo.PMC_SS_RelatedAccount__r.Name + ' ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingStreet + ', ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingCity + ', ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingState + ' ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingPostalCode;
                        wrpShipTo.value = oi.strAccIdentifier; 
                    }else{//Adding new for GSMD-339
                        Map<String,PMC_SS_AccountPartnerRelationships__c> getCPFAccountMapLegacy = PMC_DH_OrderSubmitController.getCPFAccountMapLegacy(strEffectiveAccountId);
                        PMC_SS_AccountPartnerRelationships__c objShipToLegacy = getCPFAccountMapLegacy.get(oi.strAccIdentifier);
                        if(objShipToLegacy !=null){
                            wrpShipTo.label = objShipToLegacy.PMC_SS_RelatedAccount__r.Name + ' ' + objShipToLegacy.PMC_SS_RelatedAccount__r.ShippingStreet + ', ' + objShipToLegacy.PMC_SS_RelatedAccount__r.ShippingCity + ', ' + objShipToLegacy.PMC_SS_RelatedAccount__r.ShippingState + ' ' + objShipToLegacy.PMC_SS_RelatedAccount__r.ShippingPostalCode;
                            wrpShipTo.value = oi.strAccIdentifier;
                        }
                    }
                }
                objShipmentItemWrap.wrpShipTo = wrpShipTo;
                
                PMC_DH_PicklistWrapper wrpShipFrom = new PMC_DH_PicklistWrapper();
                wrpShipFrom.label = oi.strPlantAdd;//PMC_CPQ_ProductLocation__r.Name;
                wrpShipFrom.value = oi.strPlant;//PMC_CPQ_ProductLocation__c;
                objShipmentItemWrap.wrpShipFrom = wrpShipFrom;
                
                objShipmentItemWrap.strDeliveryMode = oi.strMot;
                objShipmentItemWrap.strIncoterm = oi.strIncotterms;   
                
              
                objShipmentItemWrap.strOrderItemId = oi.strReqId;
                PMC_DH_RequestedOrderDetailUtil.getTotalShipmentItemQty(mapShipmentPlan.get(s), objShipmentItemWrap);// Confirmed Qty fix
                objShipmentItemWrap.lstShipmentPlan = mapShipmentPlan.get(s);
                if((mapShipmentPlan.get(s)).size() > 1){
                    objShipmentItemWrap.boolShipmentPlan = true;
                    objShipmentItemWrap.strRequestedShipmentDate = System.label.pmc_requestToDeliverShippingInformation_multiple;
                }
                //Checking if map contains sku and assigning the Subscription Wrapper
                if(!mapShipmentItems.containsKey(oi.strMaterial))
                {
                    mapShipmentItems.put(oi.strMaterial, new List<PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper>());
                }
                mapShipmentItems.get(oi.strMaterial).add(objShipmentItemWrap);
            }
            
            
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        return mapShipmentItems;
    } 
    
    
    /**
* @description 
* @author Mosaic Direct | Dev Team | 10-15-2023 
* @param strReqId 
* @param strType 
* @return String 
**/
    public static String getReferenceIdByType(String strReqId,ORDER_REFERENCE_TYPES strType) {
        String strRefId='';
        if(String.isBlank(strReqId)){
            return strRefId;
        }
        List<String> lstReqKey=strReqId.split('-',4);
        if(lstReqKey.size()>=4)
        {  switch on strType {
            when SOURCE {
                strRefId=lstReqKey[0]; 
            }
            when ORDERNUMBER {
                strRefId=lstReqKey[1]; 
            }
            when SOURCE_ORDERNUMBER {
                strRefId=lstReqKey[0]+'-'+lstReqKey[1]; 
            }
            when SOURCE_ORDERNUMBER_GROUPNUMBER {
                strRefId=lstReqKey[0]+'-'+lstReqKey[1]+'-'+lstReqKey[2];
            }
            when else {
                strRefId=strReqId;
            }
        }
         
        }
        return strRefId;
    }
    
    
    /**
* @description 
* @author Mosaic Direct | Dev Team | 10-15-2023 
* @param strCommunityId 
* @param strEffectiveAccountId 
* @return List<PMC_DH_OrderDetailsWrapper.ProductInfoWrapper> 
**/
    public static List<PMC_DH_OrderDetailsWrapper.ProductInfoWrapper> getProductInfo(String strCommunityId,String strEffectiveAccountId){
// List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> respData=new List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper>();
 
        List<PMC_DH_OrderDetailsWrapper.ProductInfoWrapper> lstShipmentItemsWrapper = new List<PMC_DH_OrderDetailsWrapper.ProductInfoWrapper>();
        PMC_DH_OrderDetailsWrapper.ProductInfoWrapper shipmentItemsWrapper;
        try{
            //method to get Shipment plan Details
            Map<String,List<PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper>> mapShipmentItems = getShipmentItemDetails(respData, strEffectiveAccountId);
            Set<String> setSku = mapShipmentItems.keyset();
            List<String> lstSku = new List<String>(setSku);
            //method to get Product Details using connectApi 
            if(!lstSku.isEmpty()){
                Map<String,PMC_DH_RequestForQuoteController.ConnectApiWrapper> mapProductDetail = PMC_DH_QuoteManagementControllerClass.getproductConnectApi(strCommunityId,strEffectiveAccountId,lstSku); 
                Map<String,Double> mapSkuVolume = PMC_DH_RequestedOrderDetailUtil.getProductVolume(respData);//GPT-32983
                Map<String,Double> mapSkuPrice = PMC_DH_RequestedOrderDetailUtil.getPricePerUnit(respData);
                Map<String,String> mapOfSkuItemNumber = getItemNumber();
                for(String quoteLineSku : mapShipmentItems.keyset()){
                    shipmentItemsWrapper = new PMC_DH_OrderDetailsWrapper.ProductInfoWrapper();
                    //method to assign product Details in Wrapper
                    PMC_DH_RequestForQuoteController.ConnectApiWrapper objconnectapiProduct = mapProductDetail.get(quoteLineSku);
                    shipmentItemsWrapper.strProductName = objconnectapiProduct.strProductName;
                    shipmentItemsWrapper.strSku = objconnectapiProduct.strSku;
                    shipmentItemsWrapper.strProductId = objconnectapiProduct.strProductId;
                    shipmentItemsWrapper.lstShipmentItems = mapShipmentItems.get(quoteLineSku);
                    if(mapSkuVolume.containsKey(objconnectapiProduct.strSku)){
                        shipmentItemsWrapper.intVolume = mapSkuVolume.get(objconnectapiProduct.strSku);
                    }
                    if(mapSkuPrice.containsKey(objconnectapiProduct.strSku)){
                        shipmentItemsWrapper.pricePerUnit = mapSkuPrice.get(objconnectapiProduct.strSku);
                    }
                    Double intTotRequestedQty = 0;// GDASF-30410
                    Double intTotConfirmedQty = 0;// GDASF-30410
                    for(PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper siwrp : shipmentItemsWrapper.lstShipmentItems)
                    {
                        intTotRequestedQty += siwrp.intRequestedQty;
                        intTotConfirmedQty += siwrp.intConfirmedQty;// Confirmed Qty Fix
                    }
                    shipmentItemsWrapper.intRequestedQty = intTotRequestedQty;
                    shipmentItemsWrapper.intConfirmedQty = intTotConfirmedQty;
                    shipmentItemsWrapper.strItemNumber = mapOfSkuItemNumber.get(objconnectapiProduct.strSku);
                    shipmentItemsWrapper.strProductFamily = objconnectapiProduct.strProductFamily;
                    shipmentItemsWrapper.strProductUOM = objconnectapiProduct.strProductUOM;
                    shipmentItemsWrapper.strImgSrc = objconnectapiProduct.strImgSrc;
                    
                    lstShipmentItemsWrapper.add(shipmentItemsWrapper);
                }
                
            }
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage()+ex.getStackTraceString());  
        }
        return lstShipmentItemsWrapper;
    }
     /*************************************************************************
* @method Name  : getItemNumber
* @description  : Method to get item number for shipment items
* @return       : Map<String,String>
*****************************************************************************/
    public static Map<String,String> getItemNumber(){
        Map<String,String> mapOfSKUItemNumber = new Map<String,String>();
        for(PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper wrap : respData){
            mapOfSKUItemNumber.put(wrap.strMaterial, wrap.strCustMatnr);
        }
        return mapOfSKUItemNumber;
    }


    
}