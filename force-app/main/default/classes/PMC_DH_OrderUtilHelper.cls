/** 
* @description Helper class for PMC_DH_OrderUtil
* @author Mosaic Direct Dev
* Created On       :2023-Nov-29
**/

public without sharing class PMC_DH_OrderUtilHelper {

    /*************************************************************************
    * @method Name  : getTotalOrderItems
    * @description : Method to get Total OrderItems
    * @param lstOrderItems
    * @return Map<String, OrderItem> 
    *****************************************************************************/
    public static Map<String, OrderItem> getTotalOrderItems(List<OrderItem> lstOrderItems){
        Map<String, OrderItem> mapOrderItems = new Map<String, OrderItem>();
        if(!lstOrderItems.isEmpty()){
            for(OrderItem objOrderItem : lstOrderItems){
                mapOrderItems.put(objOrderItem.Id, objOrderItem);
            }
        }
        return mapOrderItems;
    }
    /*************************************************************************
    * @method Name  : getShipmentOrderItems
    * @description : Method to get Shipment related OrderItems
    * @param mapOrderItems
    * @param lstShipmentOrderIds
    * @return List<OrderItem> 
    *****************************************************************************/
    public static List<OrderItem> getShipmentOrderItems(Map<String, OrderItem> mapOrderItems, List<String> lstShipmentOrderIds){
        List<OrderItem> lstShipmentOrderItems = new List<OrderItem>();
        for(String strOrderItemId : lstShipmentOrderIds){
            if(mapOrderItems.containsKey(strOrderItemId)){
                lstShipmentOrderItems.add(mapOrderItems.get(strOrderItemId));
            }
        }
        return lstShipmentOrderItems;
    }

    /**
    * @description getStatusOrdLine
    * @author Hemant Giri Goswami | hegoswami@deloitte.com | 12-12-2023 
    * @param strStatus 
    * @return String 
    **/
    public static String getStatusOrdLine(String strStatus)
    {   
        String strFieldDev='';
        String strReturn='';
        String strTransStatus='';
        if(!String.isBlank(strStatus))
        {
        strFieldDev=strStatus.replace(' ','_');
        strTransStatus= PMC_DH_Quote_Management_Status__mdt.getInstance(strFieldDev).PMC_DH_StatusLabel__c;
        strReturn=System.label.get(null,strTransStatus,userinfo.getLocale());
        }
        return strReturn;
    }

    /**
    * @description Set Order Line Status
    * @param oi 
    * @return String 
    **/
    public static String setDeliveryStatus(OrderItem oi) {
        String strDeliveryStatus = System.label.pmc_orderDetails_statusPlaced;

        if(!String.isBlank(oi.PMC_CPQ_OrderLineStatus__c) && String.isBlank(oi.PMC_CPQ_ReasonOfRejectionOfItem__c) ) {
            strDeliveryStatus = getStatusOrdLine(oi.PMC_CPQ_OrderLineStatus__c);
        }
        else if(!String.isBlank(oi.PMC_CPQ_ReasonOfRejectionOfItem__c)){
            strDeliveryStatus = System.label.PMC_DH_Cancelled;

        }
        
        return strDeliveryStatus;
    }

    /**
     * @description Check if set contains the value
     * @param parentSet
     * @param val
     * @return boolean
     */
    public static Boolean checkIfSetContainsValue(Set<String> parentSet, String val) {
        if(String.isNotBlank(val) && !parentSet.contains(val)){
            return true;
        }
        return false;
    }

     /**
* @description formatting shipment date
* @author  Mosaic Direct Dev 
* @param strReqdeldate
* @return  String
**/
public static String formatShipmentDate(String strReqdeldate) {
    String strDelDate;
    if(strReqdeldate.contains('.')){
        List<String> lstDelDate = strReqdeldate.split('\\.');
        if(lstDelDate.size()==3) {
            strDelDate = lstDelDate[2]+'-'+lstDelDate[1] +'-'+ lstDelDate[0];
        }
    }
    if(strReqdeldate.contains('-')){
        List<String> lstDelDate = strReqdeldate.split('-');
        if(lstDelDate.size()==3) {
            strDelDate = lstDelDate[0]+'-'+lstDelDate[1] +'-'+ lstDelDate[2];
        }
    }
    return strDelDate;
}

 /**
* @description  getProductNames
* @param lstProducts 
* @return Map<String, String> 
**/ 
    
public static Map<String, String> getProductNames(List<Product2> lstProducts){
    Map<String, String> mapOfProdSKUName = new Map<String, String>();
    for (Product2 prod : lstProducts){
        mapOfProdSKUName.put(prod.StockKeepingUnit, prod.Name);
    }
    return mapOfProdSKUName;
}


/*************************************************************************
* @method Name  : createFieldSetmap
* @description  : Method to create a field set map
* @return       : Map<String, Schema.DescribeFieldResult>
*****************************************************************************/
public static Map<String, Schema.DescribeFieldResult> createFieldSetmap() {
    Schema.DescribeFieldResult mot = OrderItem.PMC_CPQ_ModeofTransportation__c.getDescribe();
    Schema.DescribeFieldResult incoterms = OrderItem.PMC_CPQ_Incoterms__c.getDescribe();     
    Schema.DescribeFieldResult packType = SBQQ__QuoteLine__c.PMC_CPQ_PackType__c.getDescribe();     
    Schema.DescribeFieldResult packagingType = OrderItem.PMC_CPQ_PackageType__c.getDescribe();     
    Schema.DescribeFieldResult uom = SBQQ__QuoteLine__c.PMC_CPQ_UnitOfMeasure__c.getDescribe(); 
    Map<String, Schema.DescribeFieldResult> mapOfFieldSet = new Map<String, Schema.DescribeFieldResult>{'mot' => mot, 'incoterms' => incoterms, 'packType' => packType, 'packagingType' => packagingType, 'uom' => uom};
    return mapOfFieldSet;
}


/*************************************************************************
* @method Name  : setTranslatedValuesForPicklist
* @description  : Method to set translated fields
* @param         objShipmentItemWrap
* @param         oi
* @param         mapOfFieldSet
*****************************************************************************/
public static void setTranslatedValuesForPicklist(PMC_DH_OrderDetailsWrapper.ShipmentItemsWrapper objShipmentItemWrap, OrderItem oi,Map<String, Schema.DescribeFieldResult> mapOfFieldSet) {
    objShipmentItemWrap.strDeliveryModeLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(mapOfFieldSet.get('mot'),oi.PMC_CPQ_ModeofTransportation__c);
    objShipmentItemWrap.strIncotermLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(mapOfFieldSet.get('incoterms'),oi.PMC_CPQ_Incoterms__c);
    objShipmentItemWrap.strPackageTypeLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(mapOfFieldSet.get('packagingType'),oi.PMC_CPQ_PackageType__c);
    objShipmentItemWrap.strPackTypeLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(mapOfFieldSet.get('packType'),objShipmentItemWrap.strPackType);
    objShipmentItemWrap.strProductUOMLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(mapOfFieldSet.get('uom'),oi.SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_UnitOfMeasure__c);
}

   /**
    * @description 
    * @author Hemant Giri Goswami | hegoswami@deloitte.com | 06-04-2024 
    * @param docType 
    * @param orderItem 
    * @param lstWrp 
    * @return Map<String, Map<String, String>> 
    **/
    public static Map<String,Map<String,String>> generateMaps(PMC_DH_DocumentType__mdt docType,OrderItem orderItem,PMC_DH_OrderLineDetailsController.ListWrapper lstWrp)
    {
        for(ShipmentItem shipItem: orderItem.Delivery_Items__r){
            if(docType.PMC_DH_DocumentCode__c == PMC_DH_ConstantClass.BOL && shipItem.Shipment.PMC_CPQ_SAPDeliveryID__c!=null && lstWrp.lstRegions.contains(lstWrp.strRegion)){ //GPT-44509
                Map<String,String> mapString = new Map<String,String>();
                mapString.put(docType.PMC_DH_Identifier__c,shipItem.Shipment.PMC_CPQ_SAPDeliveryID__c);
                lstWrp.mapResult.put(docType.PMC_DH_DocumentCode__c,mapString);
            }
            if(docType.PMC_DH_DocumentCode__c == PMC_DH_ConstantClass.COA && shipItem.Shipment.PMC_CPQ_SAPDeliveryID__c!=null && shipItem.PMC_CPQ_DeliveryItemID__c!=null && lstWrp.lstRegions.contains(lstWrp.strRegion)){ //GPT-44509
                Map<String,String> mapString = new Map<String,String>();
                mapString.put(lstWrp.lstString[0],shipItem.Shipment.PMC_CPQ_SAPDeliveryID__c);
                mapString.put(lstWrp.lstString[1],shipItem.PMC_CPQ_DeliveryItemID__c);
                lstWrp.mapResult.put(docType.PMC_DH_DocumentCode__c,mapString);
            }
        }
        return lstWrp.mapResult;
    }
}