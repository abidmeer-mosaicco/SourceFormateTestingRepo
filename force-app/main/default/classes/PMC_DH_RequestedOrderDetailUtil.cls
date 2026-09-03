/**
* @description       : 
* @author            : Mosaic Direct | Dev Team
* @group             : 
* @last modified on  : 03-01-2024
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
public with sharing class PMC_DH_RequestedOrderDetailUtil {
    /**
* @description method to get contract details for validation
* @author Mosaic Direct | Dev Team  | 10-16-2023 
* @param strContractId 
* @param respData
* @return List<PMC_DH_OrderDetailsWrapper.ContractWrapper>
**/
    public static List<PMC_DH_OrderDetailsWrapper.ContractWrapper> getContractValidationWrapper(String strContractId, List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> respData){
        Map<String,List<PMC_DH_RequestToDeliverWrapper.ContractItem>> mapContractsItems = new Map<String,List<PMC_DH_RequestToDeliverWrapper.ContractItem>>();
        Set<String> setSku = new Set<String>();
        PMC_DH_OrderDetailsWrapper.ContractWrapper contractValidationWrapper;
        List<PMC_DH_OrderDetailsWrapper.ContractWrapper> lstContractWrapper = new List<PMC_DH_OrderDetailsWrapper.ContractWrapper>();
        for(PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper wrap : respData){
            setSku.add(wrap.strMaterial);            
        }
        List<Contract> lstContract = [SELECT Id,PMC_CPQ_Contract_Blocked__c,SBQQ__Quote__r.PMC_CPQ_PO__c,SBQQ__Quote__r.PMC_CPQ_TotalQuantity__c,(SELECT Id,SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit,SBQQ__Quantity__c, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__c,PMC_CPQ_TotalAvailableQuantity__c,PMC_CPQ_TotalOrderedQuantity__c, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.Name,SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name,SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.Id,SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c,SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c FROM SBQQ__Subscriptions__r where SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit IN :setSKU) FROM Contract WHERE Id=:strContractId WITH SECURITY_ENFORCED];
        //removed SBQQ__Quote__r.PMC_CPQ_VCOQuotation__c,have to add this after destructive changeset to the soql.
        //removed Account.PMC_SS_AccountSubType__c,have to add this after destructive changeset to the soql.
        if(!lstContract.isEmpty()){
            mapContractsItems = PMC_DH_ContractUtil.getContractItems(lstContract[0]);
            for(PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper wrap : respData){
                if(mapContractsItems.containsKey(wrap.strMaterial)){
                    for(PMC_DH_RequestToDeliverWrapper.ContractItem contractItem : mapContractsItems.get(wrap.strMaterial)){
                        contractValidationWrapper = new PMC_DH_OrderDetailsWrapper.ContractWrapper();
                        contractValidationWrapper.strAvailableQty = String.ValueOf(contractItem.intAvailableQuantity);
                        contractValidationWrapper.strIncoterm = contractItem.strIncoterms;
                        contractValidationWrapper.strDeliveryMode = wrap.strMot;
                        contractValidationWrapper.strShipFrom =PMC_DH_RequestedOrderHelper.getShipFrom(contractItem.strShipFrom,contractItem.strShipTo,strContractId);
                        contractValidationWrapper.strShipTo = PMC_DH_RequestedOrderHelper.getShipTo(contractItem.strShipFrom,contractItem.strShipTo,strContractId);//.leftPad(10,'0')
                        contractValidationWrapper.strSku = wrap.strMaterial;
                        lstContractWrapper.add(contractValidationWrapper);
                    }
                }
            }
        }
        return lstContractWrapper;
    }
   
    /**
* @description 
* @author Mosaic Direct | Dev Team  | 10-16-2023 
* @param respData 
* @return Map<string, Double> 
**/
    public static Map<string,Double> getPricePerUnit(List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> respData){
        Map<String,Double> mapOfSkuPrice = new Map<String,Double>();
        for(PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper wrap : respData){
            mapOfSkuPrice.put(wrap.strMaterial, Double.ValueOf(wrap.strGeneralPrice));
        }
        return mapOfSkuPrice;
    }
    /**
* @description 
* @author Mosaic Direct | Dev Team  | 10-30-2023 
* @param strReqDelDate 
* @return Boolean
**/    
    public static Boolean checkEdit(String strReqDelDate){
        Boolean isDisabled = false;
        Date dateToday = System.Today();
        Date dateReqShipmentDate = getShipmentDate(strReqDelDate);
        Integer intDiff = dateToday.daysBetween(dateReqShipmentDate);
        if(intDiff < 14){
            isDisabled = true;
        }
        return isDisabled;
    }
    /**
* @description 
* @author Mosaic Direct | Dev Team  | 10-30-2023 
* @param strShipDate 
* @return Date
**/    
    public static Date getShipmentDate(String strShipDate){
        Date datShipmentDate;
        if(String.isNotBlank(strShipDate)){
            List<String> lstDate = strShipDate.split('[.-]');
            
            if(lstDate.size()>=2){
                datShipmentDate = Date.newInstance(Integer.ValueOf(lstDate[0]),Integer.ValueOf(lstDate[1]),Integer.ValueOf(lstDate[2]));
            }
        }
        return datShipmentDate;
    }
    /**
* @description 
* @author Mosaic Direct | Dev Team  | 10-16-2023 
* @param respData 
* @return Map<String, Double> 
**/
    public static Map<String,Double> getProductVolume(List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> respData){//GPT-32983
        Map<String,Double> mapOfSkuVolume = new Map<String,Double>();//GPT-32983
        Double volume = 0;//GPT-32983
        for(PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper wrap : respData){
            if(!mapOfSkuVolume.containsKey(wrap.strMaterial)){
                volume += Double.ValueOf(wrap.strRequestQty);//GPT-32983
            }
            else{
                volume += mapOfSkuVolume.get(wrap.strMaterial);               
                
            }
            mapOfSkuVolume.put(wrap.strMaterial, volume);
        }
        return mapOfSkuVolume;
    }
    /*************************************************************************
* @method Name  : getTotalShipmentItemQty
* @description  : Method to get total requested quantity and confirmed quantity for shipment items
* @param         lstShipmentPlan
* @param         objShipmentItemWrap
*****************************************************************************/
    public static void getTotalShipmentItemQty(List<PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper> lstShipmentPlan, PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper objShipmentItemWrap){
        Double intTotRequestedQty = 0;// GDASF-30410
        Double intTotConfirmedQty = 0;// GDASF-30410
        for(PMC_DH_OrderDetailsWrapper.ShipmentPlanWrapper siwrp : lstShipmentPlan)
        {
            intTotRequestedQty += siwrp.intRequestedQty;
            intTotConfirmedQty += siwrp.intConfirmedQty;
        }
        objShipmentItemWrap.intRequestedQty = intTotRequestedQty;
        objShipmentItemWrap.intConfirmedQty = intTotConfirmedQty;
    }
    /**
* @description processing contract number
* @author  Mosaic Direct Dev 
* @param mapOfIdResponse
* @return Map<String, String>(); 
**/   
    public static Map<String, String> getContractInfo(Map<String, List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper>> mapOfIdResponse){
        List<String> lstContractNumber = new List<String>();
        Map<String, List<String>> mapReqContract = new Map<String, List<String>>();
        Map<String,String> mapContractDoc = new Map<String, String>();
        for(String strReqId : mapOfIdResponse.keySet()){
            lstContractNumber.add(mapOfIdResponse.get(strReqId)[0].strContractFinalized);
            if(!mapReqContract.containsKey(mapOfIdResponse.get(strReqId)[0].strContractFinalized)){
                mapReqContract.put(mapOfIdResponse.get(strReqId)[0].strContractFinalized, new List<String>());
            }
            mapReqContract.get(mapOfIdResponse.get(strReqId)[0].strContractFinalized).add(strReqId) ;
        }
        List<Contract> lstcont = [SELECT Id, PMC_CPQ_Contract_Blocked__c,PMC_CPQ_ContractNumberIdentifier__c,PMC_CPQ_ContractType__c, StartDate, EndDate, tolabel(Status), AccountId, 
                                    SBQQ__Quote__c, SBQQ__Quote__r.Name, SBQQ__Quote__r.SBQQ__Status__c, SBQQ__Quote__r.PMC_CLM_DocumentNumber__c, SBQQ__Quote__r.PMC_CPQ_PO__c, SBQQ__Quote__r.PMC_CPQ_PrimaryContact__r.Name, SBQQ__Quote__r.SBQQ__PaymentTerms__c, SBQQ__Quote__r.PMC_DH_PaymentMethod__c, SBQQ__Quote__r.PMC_CPQ_Currency__c, SBQQ__Quote__r.PMC_CPQ_TotalQuantity__c, SBQQ__Quote__r.PMC_CPQ_ModeOfTransportation__c,
                                    (SELECT Id, PMC_CPQ_TotalOrderedQuantity__c, PMC_CPQ_TotalAvailableQuantity__c, SBQQ__Product__r.StockKeepingUnit,
                                    SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__c, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.Name, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingStreet, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingCity, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingState, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingPostalCode, SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__c,SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name, SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c, SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c, SBQQ__QuoteLine__r.SBQQ__NetPrice__c, SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c
                                    FROM SBQQ__Subscriptions__r) 
                                    FROM Contract where PMC_CPQ_ContractNumberIdentifier__c IN :lstContractNumber WITH SECURITY_ENFORCED];
        
        
        for(Contract cont : lstcont){
            if(mapReqContract.containsKey(cont.PMC_CPQ_ContractNumberIdentifier__c)) {
                for(String strReqId : mapReqContract.get(cont.PMC_CPQ_ContractNumberIdentifier__c)){
                    mapContractDoc.put(strReqId,PMC_DH_ConstantClass.DOC_TAG+cont.SBQQ__Quote__r.PMC_CLM_DocumentNumber__c);               
                }
            }
        }
        
        return mapContractDoc;
    }  
     /**
* @description 
* @author Mosaic Direct Dev 
* @param strCreatedDate 
* @return DateTime 
**/
    public static DateTime getCreatedDate(String strCreatedDate){
        TimeZone userTimeZone = UserInfo.getTimeZone();
        String strFormattedDate;
        DateTime dateTimeValue;
        if(strCreatedDate != Null && String.isNotBlank(strCreatedDate)){
            List<String> strDatePart = strCreatedDate.split('-');
            List<String> strTimePart = (strCreatedDate.substringAfter('T').split('\\.'))[0].split(':'); 
            DateTime dateTimeString = DateTime.newInstance(Integer.ValueOf(strDatePart[0]), Integer.ValueOf(strDatePart[1]), Integer.ValueOf(strDatePart[2].substring(0, 2)),Integer.ValueOf(strTimePart[0]), Integer.ValueOf(strTimePart[1]), Integer.ValueOf(strTimePart[2])) ;  
            strFormattedDate = dateTimeString.format('yyyy-MM-dd hh:mm:ss', String.ValueOf(userTimeZone));
            dateTimeValue = DateTime.valueOf(strFormattedDate);

        }
             
        return dateTimeValue;       
        
    }

     /**
    * @description  method to find if a contract is VCO
    * @author  Mosaic Direct Dev 
    * @param  strContractNumber
    * @param  orderItemNo
    * @return Boolean
    **/ 
    //Added as part of GDASF-20003
    public static Boolean isVCOContract(String strContractNumber, String orderItemNo) {
        Boolean isVCO = false;
        List<CartItem> cartItems = PMC_DH_CommerceCartQueryUtilsClass.getSingleCartItem(orderItemNo);
        if(cartItems.size()>0) {// If it is an MD request
            isVCO = cartItems[0].PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c;  
        }
        else {
            List<SBQQ__Subscription__c> lstSubs= [ Select id, SBQQ__Contract__r.PMC_CPQ_ContractNumberIdentifier__c,SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c from SBQQ__Subscription__c 
            where SBQQ__Contract__r.PMC_CPQ_ContractNumberIdentifier__c=:strContractNumber WITH SECURITY_ENFORCED];
            if(lstSubs.size()>0) {
                isVCO = lstSubs[0].SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c;
            }
        }
        return isVCO;
    }

    /**
     * @description method to get pack and package type
     * @author Mosaic Direct Dev 
     * @param  strPackType
     * @param  strPackageType
     * @return Map<String,String>
     */
    public static Map<String,String> getPackandPackagingType(String strPackType, String strPackageType) {
        Map<String,String> mapPackOrPackageType = new Map<String,String>();
        if((strPackageType.toLowerCase() == 'bulk' && strPackType == '') || strPackType.toLowerCase() == 'bulk'){
            mapPackOrPackageType.put('strPackageType','');
            mapPackOrPackageType.put('strPackType',strPackageType);
        }
        else{
            mapPackOrPackageType.put('strPackType', strPackType);
            mapPackOrPackageType.put('strPackageType', strPackageType);
        }
        return mapPackOrPackageType;
    }

    /**
     * @description Trim leading 0's from Sales Order Number
     * @param salesOrderNo
     * @return String
     */
    public static String getSalesOrderNumber(String salesOrderNo) {
        if(String.isNotBlank(salesOrderNo) && salesOrderNo.startsWith('00') && salesOrderNo.length()>2) {
            return salesOrderNo.substring(2);
        }
        return salesOrderNo;
    }
}