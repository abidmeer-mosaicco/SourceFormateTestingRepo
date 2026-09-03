/** 
* @description Class for Shipment History Page
* @author Ajeet
* @last modified on 2023-Nov-03
* @last modified by Nikhilesh
* Created On       :2023-Nov-01
**/
public without sharing class PMC_DH_ShipmentHistoryList {
    private static final String SCHEDULED_STATUS = 'Scheduled';
    private static final String IN_TRANSIT_STATUS = 'In Transit';
    private static final String NOT_YET_SHIPPED_STATUS = 'Not Yet Shipped';
    private static final String COMPLETELY_SHIPPED_STATUS = 'Completely Shipped';
    private static final String NOT_YET_SCHEDULED_STATUS = 'Not Yet Scheduled';
    private static final String DELAYED_STATUS = 'Delayed';
    private static final String ON_TIME_STATUS = 'On Time';
    private static final String PARTIALLY_SHIPPED_STATUS = 'Partially Shipped';
    private static final String FETCH_SHIPMENTS_SUCCESS_MODULE = 'ShipmentRecords';
    
    /*************************************************************************
* @method Name  : getShipmentRecords
* @description  : Method to get the Shipment Records info in wrapper class
* @param 		  searchParams
* @param 		  effAccountId
* @param 		  strLocale
* @return       : PMC_DH_ShipmentHistoryListWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_ShipmentHistoryListWrapper getShipmentRecords(PMC_DH_ShipmentSearchParameterWrapper searchParams, String effAccountId, String strLocale){ //added as part of GDASF-19642
        PMC_DH_ShipmentHistoryListWrapper wrpShipmentHistoryList = new PMC_DH_ShipmentHistoryListWrapper(); //added as part of GDASF-19642
        List<PMC_DH_ShipmentHistoryWrapper> lstShipmentWrapper = new List<PMC_DH_ShipmentHistoryWrapper>();
        Map<String, List<PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper>> mapDestinationToSI = new Map<String, List<PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper>>();
        Map<String, PMC_DH_ShipmentItemCustomSortOrder[]> mapDestinationToSortSI = new Map<String, PMC_DH_ShipmentItemCustomSortOrder[]>();
        Map<String, String> mapDestIdToName = new Map<String, String>();
        try{
            String strQuery = PMC_DH_ShipmentHistoryListHelper.getShipmentQuery(searchParams, effAccountId);
            String queryRes = strQuery.replace('\\', '');
            List<OrderItem> lstOrderItem = new List<OrderItem>();
            lstOrderItem = Database.query(queryRes);
            if(!lstOrderItem.isEmpty()){
                for(OrderItem ordItem:lstOrderItem){
                    Map<String,List<PMC_DH_PicklistWrapper>> mapPicklistWrapper = PMC_DH_OrderLineDetailsController.getOrderDocument(ordItem,strLocale);
                    List<PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper> lstShipmentItemsWrapper = new List<PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper>();
                    PMC_DH_ShipmentItemCustomSortOrder[] lstShipmentItemsSorted = createOrUpdateSortedList(mapDestinationToSI, mapDestinationToSortSI, ordItem);
                    if(lstShipmentItemsSorted.isEmpty()){
                        mapDestIdToName.put(ordItem.PMC_CPQ_ShipTo__c, ordItem.PMC_CPQ_ShipTo__r.Name);
                    }
                    if(!ordItem.Delivery_Items__r.isEmpty()){
                        for(ShipmentItem shipItem: ordItem.Delivery_Items__r){
                            PMC_DH_ShipmentItemInfoParameterWrapper shipmentItemInfoWrapper = new PMC_DH_ShipmentItemInfoParameterWrapper();
                            shipmentItemInfoWrapper.shipItem = shipItem;
                            shipmentItemInfoWrapper.mapPicklistWrapper = mapPicklistWrapper;
                            shipmentItemInfoWrapper.ordItem = ordItem;
                            shipmentItemInfoWrapper.shipmentStatus = searchParams.strStatus;
                            //updateShipmentItemSortedList(shipmentItemInfoWrapper, lstShipmentItemsSorted);
                            updateShipmentItemSortedList(shipmentItemInfoWrapper, lstShipmentItemsSorted,strLocale);
                            lstShipmentItemsSorted.sort();
                        }
                        lstShipmentItemsWrapper = sortingShipmentItemRecords(lstShipmentItemsSorted, lstShipmentItemsWrapper);
                        mapDestinationToSortSI.put(ordItem.PMC_CPQ_ShipTo__c, lstShipmentItemsSorted);
                        mapDestinationToSI.put(ordItem.PMC_CPQ_ShipTo__c,lstShipmentItemsWrapper);
                    }
                }
            }
            lstShipmentWrapper = addShipmentWrapperToList(mapDestinationToSI, mapDestIdToName, lstShipmentWrapper);
            wrpShipmentHistoryList.lstShipmentWrapper = lstShipmentWrapper;
            wrpShipmentHistoryList.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, FETCH_SHIPMENTS_SUCCESS_MODULE);
            
        }catch(Exception ex){
            wrpShipmentHistoryList.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
            PMC_ErrorLogClass.processException(ex);
        }
        return wrpShipmentHistoryList; //added as part of GDASF-19642
    }
    
    /*************************************************************************
* @method Name  : createOrUpdateSortedList
* @description  : Method to create/update the shipment item sorted list
* @param 		  mapDestinationToSI
* @param          mapDestinationToSortSI
* @param		  ordItem
* @return         PMC_DH_ShipmentItemCustomSortOrder[]
*****************************************************************************/
    private static PMC_DH_ShipmentItemCustomSortOrder[] createOrUpdateSortedList(Map<String, List<PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper>> mapDestinationToSI, Map<String, PMC_DH_ShipmentItemCustomSortOrder[]> mapDestinationToSortSI, OrderItem ordItem){
        PMC_DH_ShipmentItemCustomSortOrder[] lstShipmentItemsSorted;
        
        // Check if destination exist in map. If Yes, retrieve list of values.
        if(mapDestinationToSI.containsKey(ordItem.PMC_CPQ_ShipTo__c)){
            lstShipmentItemsSorted = mapDestinationToSortSI.get(ordItem.PMC_CPQ_ShipTo__c);
        }else{
            lstShipmentItemsSorted = new List<PMC_DH_ShipmentItemCustomSortOrder>();
        }
        return lstShipmentItemsSorted;
    }
    
    /*************************************************************************
* @method Name  : updateShipmentItemSortedList
* @description  : Method to get the shipment item info and update the sorted list
* @param 		  shipmentItemInfoWrapper
* @param		  lstShipmentItemsSorted
*****************************************************************************/
    private static void updateShipmentItemSortedList(PMC_DH_ShipmentItemInfoParameterWrapper shipmentItemInfoWrapper, PMC_DH_ShipmentItemCustomSortOrder[] lstShipmentItemsSorted,String strLocale){
        if((shipmentItemInfoWrapper.shipmentStatus == SCHEDULED_STATUS && shipmentItemInfoWrapper.shipItem.PMC_CPQ_DeliveryLineStatus__c == NOT_YET_SHIPPED_STATUS) || (shipmentItemInfoWrapper.shipmentStatus == IN_TRANSIT_STATUS && (shipmentItemInfoWrapper.shipItem.PMC_CPQ_DeliveryLineStatus__c == COMPLETELY_SHIPPED_STATUS || shipmentItemInfoWrapper.shipItem.PMC_CPQ_DeliveryLineStatus__c == PARTIALLY_SHIPPED_STATUS))){
            // null check on qty added by Nikhilesh for GPT-29777
            if(shipmentItemInfoWrapper.shipItem.PMC_CPQ_DeliveryQuantity__c > 0){
                PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper shipmentItemsWrapper = getShipmentItemInfo(shipmentItemInfoWrapper,strLocale);
                lstShipmentItemsSorted.add(new PMC_DH_ShipmentItemCustomSortOrder(shipmentItemsWrapper));
            }
            
        }
    }
    
    /*************************************************************************
* @method Name  : getShipmentItemInfo
* @description  : Method to map the Shipment Item info to wrapper
* @param          shipmentItemInfoWrapper
* @return       : PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper
*****************************************************************************/
    private static PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper getShipmentItemInfo(PMC_DH_ShipmentItemInfoParameterWrapper shipmentItemInfoWrapper,String strLocale){
        PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper shipmentItemsWrapper = new PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper();
        shipmentItemsWrapper.strOrderId = shipmentItemInfoWrapper.shipItem.PMC_CPQ_OrderProduct__r.Order.Id;
        shipmentItemsWrapper.strOrderNumber = shipmentItemInfoWrapper.shipItem.PMC_CPQ_OrderProduct__r.Order.PMC_CPQ_SAPOrderNumber__c;
        shipmentItemsWrapper.strOrderLineId = shipmentItemInfoWrapper.shipItem.PMC_CPQ_OrderProduct__c;
        shipmentItemsWrapper.strDeliveryItemId = shipmentItemInfoWrapper.shipItem.Id;
        shipmentItemsWrapper.strPONumber = shipmentItemInfoWrapper.shipItem.PMC_CPQ_LinePONumber__c;
        shipmentItemsWrapper.strProductName = shipmentItemInfoWrapper.shipItem.Product2.Name;
        shipmentItemsWrapper.strVehicleId = shipmentItemInfoWrapper.shipItem.shipment.PMC_CPQ_VehicleID__c; // GDASF-20619
        if(shipmentItemInfoWrapper.shipItem.PMC_CPQ_DeliveryQuantity__c != null) {
            shipmentItemsWrapper.strDeliveryQuantity = String.valueOf(shipmentItemInfoWrapper.shipItem.PMC_CPQ_DeliveryQuantity__c);//GDASF-10697->Integer.valueOf()
        }
        shipmentItemsWrapper.lstDocument = shipmentItemInfoWrapper.mapPicklistWrapper.get(shipmentItemInfoWrapper.shipItem.Id);
        //shipmentItemsWrapper.mapDocRecord = PMC_DH_OrderLineDetailsController.getDocumentData(shipmentItemInfoWrapper.ordItem);
        //String strRegion = PMC_DH_ShipmentHistoryListHelper.getUserRegion(); //GPT-44509
        String strRegion = PMC_DH_CommonSystemUtils.getUserRegion(strLocale);
        shipmentItemsWrapper.mapDocRecord = PMC_DH_OrderLineDetailsController.getDocumentData(shipmentItemInfoWrapper.ordItem, strRegion);
        shipmentItemsWrapper.strStatus = getShipmentItemStatus(shipmentItemInfoWrapper.shipItem, shipmentItemInfoWrapper.shipmentStatus);
        
        if(shipmentItemInfoWrapper.shipmentStatus == SCHEDULED_STATUS && shipmentItemInfoWrapper.shipItem.PMC_CPQ_DeliveryLineStatus__c == NOT_YET_SHIPPED_STATUS){
            shipmentItemsWrapper.datShipDate = shipmentItemInfoWrapper.shipItem.shipment.PMC_CPQ_DeliveryPlannedGIDate__c;
            shipmentItemsWrapper.strETA = '';
            shipmentItemsWrapper.strCurrentLocation = '';
        }
        else if(shipmentItemInfoWrapper.shipmentStatus == IN_TRANSIT_STATUS && (shipmentItemInfoWrapper.shipItem.PMC_CPQ_DeliveryLineStatus__c == COMPLETELY_SHIPPED_STATUS || shipmentItemInfoWrapper.shipItem.PMC_CPQ_DeliveryLineStatus__c == PARTIALLY_SHIPPED_STATUS)){
            shipmentItemsWrapper.datShipDate = shipmentItemInfoWrapper.shipItem.PMC_CPQ_ShippedDate__c; // exact date needed, hence shipped date of delivery line
            // shipmentItemsWrapper.strETA = String.valueOf(shipmentItemInfoWrapper.shipItem.PMC_CPQ_ETA__c); 
            // GDASF-20619
            shipmentItemsWrapper.strCurrentLocation = shipmentItemInfoWrapper.shipItem.shipment.PMC_CPQ_CurrentLocation__c;
            if(shipmentItemInfoWrapper.shipItem.shipment.PMC_CPQ_ETA__c != null){
                shipmentItemsWrapper.strETA = String.valueOf(shipmentItemInfoWrapper.shipItem.shipment.PMC_CPQ_ETA__c);
            }
            else{
                shipmentItemsWrapper.strETA = String.valueOf(shipmentItemInfoWrapper.shipItem.shipment.PMC_CPQ_ShippedDate__c); // est. date needed, hence shipped date of delivery
            }
        }
        return shipmentItemsWrapper;
    }
    
    /*************************************************************************
* @method Name  : getShipmentItemStatus
* @description  : Method to get the Shipment Item status
* @param 		  shipmentItem
* @param		  shipmentStatus
* @return       : String
*****************************************************************************/
    @TestVisible
    private static String getShipmentItemStatus(ShipmentItem shipmentItem, String shipmentStatus){
        String shipmentItemStatus;
        if(shipmentStatus == SCHEDULED_STATUS){
            if(shipmentItem.shipment.PMC_CPQ_DeliveryPlannedGIDate__c == null){
                shipmentItemStatus = System.Label.PMC_DH_NotYetScheduled;
            }
            else{
                if(Date.today() > shipmentItem.shipment.PMC_CPQ_DeliveryPlannedGIDate__c){
                    shipmentItemStatus = System.Label.PMC_DH_Delayed;
                }
                else{
                    shipmentItemStatus = System.Label.pmc_shipmentDetails_scheduled;
                }
            }
        }
        
        else if(shipmentStatus == IN_TRANSIT_STATUS){
            // GDASF-20619
            // if ETA = null, status = On Time
            // if Shipped Date of Delivery is greater than ETA, status = Delayed
            if(shipmentItem.shipment.PMC_CPQ_ETA__c != null && shipmentItem.shipment.PMC_CPQ_ShippedDate__c > shipmentItem.shipment.PMC_CPQ_ETA__c){
                shipmentItemStatus = System.Label.PMC_DH_Delayed;
            }else{
                shipmentItemStatus = System.Label.PMC_DH_OnTime;
            }
        }        
        return shipmentItemStatus;
    }
    
    /*************************************************************************
* @method Name  : sortingShipmentItemRecords
* @description  : Method to sort the shipment item records and add to the list
* @param          lstShipmentItemsSorted
* @param          lstShipmentItemsWrapper
* @return       : List<PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper>
*****************************************************************************/
    private static List<PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper> sortingShipmentItemRecords(List<PMC_DH_ShipmentItemCustomSortOrder> lstShipmentItemsSorted, List<PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper> lstShipmentItemsWrapper){
        for(Integer i = 0; i < lstShipmentItemsSorted.size(); i++){ 
            lstShipmentItemsWrapper.add(lstShipmentItemsSorted[i].shipmentItemInfo); 
        }
        return lstShipmentItemsWrapper;
    }
    
    /*************************************************************************
* @method Name  : addShipmentWrapperToList
* @description  : Method to add the shipment wrappers to the final list
* @param 		  mapDestinationToSI
* @param		  mapDestIdToName
* @param          lstShipmentWrapper
* @return         List<PMC_DH_ShipmentHistoryWrapper>
*****************************************************************************/
    private static List<PMC_DH_ShipmentHistoryWrapper> addShipmentWrapperToList(Map<String, List<PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper>> mapDestinationToSI, Map<String, String> mapDestIdToName, List<PMC_DH_ShipmentHistoryWrapper> lstShipmentWrapper){
        for(String destId : mapDestinationToSI.keySet()){
            if(!mapDestinationToSI.get(destId).isEmpty()){
                PMC_DH_ShipmentHistoryWrapper wrpShipment = new PMC_DH_ShipmentHistoryWrapper();
                wrpShipment.strDestinationId = destId;
                wrpShipment.strDestination = mapDestIdToName.get(destId);
                wrpShipment.lstDeliveriesWrapper = mapDestinationToSI.get(destId);
                lstShipmentWrapper.add(wrpShipment);
            }
        }
        return lstShipmentWrapper;
    }
    
    /**
* @description       : Class for custom sorting of shipment items based on date
* @author            : @Nikhilesh Mohanty
* @last modified on    11-07-2023
* @last modified by    Nikhilesh Mohanty
* @Created on        : 11-07-2023
**/
    public with sharing class PMC_DH_ShipmentItemCustomSortOrder implements Comparable{
        PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper shipmentItemInfo;
        
        /**
* @description       : Constructor for PMC_DH_ShipmentItemCustomSortOrder
* @author            : @Nikhilesh Mohanty
* @param               shipmentItemInfo
* @Created on        : 11-07-2023
**/
        public PMC_DH_ShipmentItemCustomSortOrder(PMC_DH_ShipmentHistoryWrapper.PMC_DH_DeliveryItemsWrapper shipmentItemInfo){
            this.shipmentItemInfo = shipmentItemInfo;
        }
        
        /**
* @description       : Method to compare two records
* @author            : @Nikhilesh Mohanty
* @param               obj
* @return            : Integer
* @Created on        : 11-07-2023
**/
        public Integer compareTo(Object obj) {
            PMC_DH_ShipmentItemCustomSortOrder objRecord = (PMC_DH_ShipmentItemCustomSortOrder)obj;
            if (this.shipmentItemInfo.datShipDate > objRecord.shipmentItemInfo.datShipDate) {
                return 1;
            } else if (this.shipmentItemInfo.datShipDate < objRecord.shipmentItemInfo.datShipDate) {
                return -1;
            } else {
                return 0;
            }          
        }     
    }
    
    
    /**
* * @description       : Wrapper for the getShipmentItemInfo method
* * @author            : @Nikhilesh
* * @Created on        : 11-03-2023

**/
    public with sharing class PMC_DH_ShipmentItemInfoParameterWrapper{
        /**
* * @description Shipment Item
* * @return ShipmentItem
* */
        @AuraEnabled
        public ShipmentItem shipItem { get; set; }
        /**
* * @description Map that stores Order Document
* * @return  Map<String,List<PMC_DH_PicklistWrapper>>
* */
        @AuraEnabled
        public Map<String,List<PMC_DH_PicklistWrapper>> mapPicklistWrapper { get; set; }
        /**
* * @description Order Item
* * @return OrderItem
* */
        @AuraEnabled
        public OrderItem ordItem { get; set; }
        /**
* * @description Shipment Status (Scheduled / In Transit)
* * @return String
* */
        @AuraEnabled
        public String shipmentStatus { get; set; }
    }
    
    /**
* * @description       : Wrapper for the Search Params
* * @author            : @Mosaic Direct Dev
* * @Created on        : 11-03-2023
**/
    public with sharing class PMC_DH_ShipmentSearchParameterWrapper {
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
* @description status of shipment (Scheduled / In Transit)
* @return String
*/
        @AuraEnabled
        public String strStatus {get; set;}
    }
    
    // added as part of GDASF-19642
    /**
* @description : Wrapper for List of Shipments
* @author      : Nikhilesh Mohanty
* @last modified on 2024-01-10
**/ 
    //with sharing is not yet deployed to UAT
    public with sharing class PMC_DH_ShipmentHistoryListWrapper
    {
        /**
* @description Boolean flag to indicate if user is successfully registered
* @author Nikhilesh
* @return List<PMC_DH_ShipmentHistoryWrapper>
**/ 
        @AuraEnabled
        public List<PMC_DH_ShipmentHistoryWrapper> lstShipmentWrapper{get;set;}
        
        /**
* @description Status Code and message
* @author Nikhilesh
* @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*/
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    }
}