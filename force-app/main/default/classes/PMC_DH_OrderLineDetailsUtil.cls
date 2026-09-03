/** 
* @description Controller for fetching Delivery Item Details 
* @author Krishan
* @last modified on 2/21/2024
* @last modified by Lohitha
* Created On       :2023-Oct-25
**/
public without sharing class PMC_DH_OrderLineDetailsUtil {
    public final static String SHIPPER_LABEL='Mosaic Global Sales LLC';
    public final static String STATUS_COMPLETELY_SHIPPED='Completely Shipped';
    public final static String TRACKER_STATE_ACTIVE='Active';
    public final static String TRACKER_STATE_PENDING='Pending';
    public final static String TRACKER_STATE_COMPLETED='Completed';
    public final static String DELIVERY_TRACKER_STAGE_1=System.label.PMC_DH_ShipmentRequested;
    public final static String DELIVERY_TRACKER_STAGE_2=System.label.PMC_DH_ShipmentScheduled;
    public final static String DELIVERY_TRACKER_STAGE_3=System.label.PMC_DH_Shipped;
    public final static String DELIVERY_TRACKER_STAGE_4=System.label.pmc_shipmentDetails_inTransit;
    public final static String DELIVERY_TRACKER_STAGE_5=System.label.PMC_DH_EstimatedDelivery;
    public final static String DELIVERY_TRACKER_STAGE_6=System.label.pmc_shipmentDetails_delivered;

    public enum PROGRESS_TRACKER_STAGES {
        SHIPMENT_REQUESTED,
        SHIPMENT_SCHEDULED,
        SHIPPED,
        IN_TRANSIT,
        EST_DELIVERY
    }

    /*************************************************************************
* @method Name  : getDeliveryTracking
* @description  : Method to get deliver Track
* @param        strOrderLineId
* @param        strVehicleId
* @return       : PMC_DH_DeliveryTrackerWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_DeliveryTrackerWrapper getDeliveryTracking(String strOrderLineId,String strVehicleId){
        PMC_DH_DeliveryTrackerWrapper delTrackWrapper = new PMC_DH_DeliveryTrackerWrapper();
        try{
            List<OrderItem> lstOrderItem = [SELECT Id,Product2.Name,Order.PMC_CPQ_SAPOrderNumber__c,PMC_CPQ_ProductLocation__r.PMC_CPQ_Address__c,PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_Street__c,PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_City__c,PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_State__c,PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_Country__c,PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_Region__c,(SELECT Id, Shipment.PMC_CPQ_CurrentCarrier__c,PMC_CPQ_LinePONumber__c, Shipment.ShipmentNumber,Shipment.PMC_CPQ_CurrentCoordinates__Latitude__s,Shipment.PMC_CPQ_CurrentCoordinates__Longitude__s,
            PMC_CPQ_DeliveryLineStatus__c,PMC_CPQ_Origin__c,Shipment.PMC_CPQ_DeliveryStatus__c,Shipment.PMC_CPQ_DeliveryPlannedGIDate__c,PMC_CPQ_ShippedDate__c,PMC_CPQ_OrderProduct__r.PMC_CPQ_ShipTo__r.ShippingCity,PMC_CPQ_OrderProduct__r.PMC_CPQ_ShipTo__r.ShippingStateCode, Shipment.PMC_CPQ_CurrentLocation__c, Shipment.PMC_CPQ_ShippedDate__c, Shipment.PMC_CPQ_ETA__c, Shipment.PMC_CPQ_VehicleID__c from Delivery_Items__r WHERE Shipment.PMC_CPQ_VehicleID__c =:strVehicleId)
                                            FROM OrderItem WHERE Id=:strOrderLineId WITH SECURITY_ENFORCED]; //GDASF-20619
            
            for(ShipmentItem objShipmentItem : lstOrderItem[0].Delivery_Items__r){
                List<PMC_DH_DeliveryTrackerWrapper.Mapmarker> lstwrapMarker= new List<PMC_DH_DeliveryTrackerWrapper.Mapmarker>();
                PMC_DH_DeliveryTrackerWrapper.Mapmarker wrapMarker= new PMC_DH_DeliveryTrackerWrapper.Mapmarker();
                PMC_DH_DeliveryTrackerWrapper.Location wrapLocation= new PMC_DH_DeliveryTrackerWrapper.Location();
                delTrackWrapper.strOrderNumber = lstOrderItem[0].Order.PMC_CPQ_SAPOrderNumber__c;
                delTrackWrapper.strProductName = lstOrderItem[0].Product2.Name;
                delTrackWrapper.strShipper = SHIPPER_LABEL;
                delTrackWrapper.strCarrier = objShipmentItem.Shipment.PMC_CPQ_CurrentCarrier__c;
                //delTrackWrapper.datETA = objShipmentItem.PMC_CPQ_ETA__c;
                delTrackWrapper.datETA = getETAOrShippedDate(objShipmentItem); //GDASF-20619
                if(objShipmentItem.PMC_CPQ_DeliveryLineStatus__c!=null){
                    String strFieldDev = objShipmentItem.PMC_CPQ_DeliveryLineStatus__c.replace(' ','_');
                    String strTransStatus = PMC_DH_Quote_Management_Status__mdt.getInstance(strFieldDev).PMC_DH_StatusLabel__c;
                    delTrackWrapper.strDeliveryStatus = System.label.get(null,strTransStatus,userinfo.getlocale());
                }
                if(objShipmentItem.Shipment.PMC_CPQ_CurrentCoordinates__Latitude__s !=null && objShipmentItem.Shipment.PMC_CPQ_CurrentCoordinates__Longitude__s !=null){
                    wrapLocation.strLatitude = String.valueof(objShipmentItem.Shipment.PMC_CPQ_CurrentCoordinates__Latitude__s);
                    wrapLocation.strLongitude = String.valueof(objShipmentItem.Shipment.PMC_CPQ_CurrentCoordinates__Longitude__s);
                    wrapMarker.location = wrapLocation;               
                }
                else{
                    wrapLocation.strStreet = lstOrderItem[0].PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_Street__c;
                    wrapLocation.strCity = lstOrderItem[0].PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_City__c;
                    wrapLocation.strState = lstOrderItem[0].PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_State__c;
                    wrapLocation.strCountry = lstOrderItem[0].PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_Country__c;
                    wrapMarker.location = wrapLocation; 
                }
                wrapMarker.strTitle = objShipmentItem.Shipment.PMC_CPQ_CurrentLocation__c; //GDASF-20619
                wrapMarker.strDescription = lstOrderItem[0].PMC_CPQ_ProductLocation__r.PMC_CPQ_Address__c;
                lstwrapMarker.add(wrapMarker);
                delTrackWrapper.mapMarkers = lstwrapMarker;
                delTrackWrapper.lstProgressTracker = getProgressTracker(objShipmentItem, lstOrderItem[0]);
                delTrackWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'DeliveryTracking');
            }
        }catch(Exception ex){
            delTrackWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return delTrackWrapper;
        
    }

    //GDASF-20619
    /*************************************************************************
    * @method Name  : getETAOrShippedDate
    * @description  : Method to set ETA value 
    * @param         objShipmentItem
    * @return        Date
    *****************************************************************************/
    private static Date getETAOrShippedDate(ShipmentItem objShipmentItem){
        Date datETA;
        if(objShipmentItem.Shipment.PMC_CPQ_ETA__c != null){
            datETA = objShipmentItem.Shipment.PMC_CPQ_ETA__c;
        }
        else{
            datETA = objShipmentItem.Shipment.PMC_CPQ_ShippedDate__c;
        }
        return datETA;
    }

    /*************************************************************************
    * @method Name  : setInTransitStatus
    * @description  : Method to set In Transit Status
    * @param         objShipmentItem
    * @param         wrapDelTracker
    *****************************************************************************/
    private static void setInTransitStatus(ShipmentItem objShipmentItem, PMC_DH_DeliveryTrackerWrapper.ProgressTracker wrapDelTracker) {
        if(objShipmentItem.Shipment.PMC_CPQ_DeliveryStatus__c == STATUS_COMPLETELY_SHIPPED){
            wrapDelTracker.strStatus = TRACKER_STATE_COMPLETED;
            wrapDelTracker.datDate = Date.Today();
        }
        else if(objShipmentItem.PMC_CPQ_ShippedDate__c != NULL){
            wrapDelTracker.strStatus = TRACKER_STATE_ACTIVE;
            wrapDelTracker.datDate = Date.Today();
        }
    }

    /*************************************************************************
    * @method Name  : setScheduledShipmentStat
    * @description  : Method to set Scheduled Shipment Status
    * @param         objShipmentItem
    * @param         wrapDelTracker
    *****************************************************************************/
    private static void setScheduledShipmentStat(ShipmentItem objShipmentItem, PMC_DH_DeliveryTrackerWrapper.ProgressTracker wrapDelTracker) {
        if(objShipmentItem.Shipment.PMC_CPQ_DeliveryStatus__c == STATUS_COMPLETELY_SHIPPED || objShipmentItem.PMC_CPQ_ShippedDate__c != NULL) {
            wrapDelTracker.strStatus = TRACKER_STATE_COMPLETED;
        }
        else if(objShipmentItem.Shipment.PMC_CPQ_DeliveryPlannedGIDate__c !=NULL){
            wrapDelTracker.strStatus = TRACKER_STATE_ACTIVE;
        }
    }

    /*************************************************************************
    * @method Name  : getProgressTracker
    * @description  : Method to get progress tracker data
    * @param        objShipmentItem
    * @param        orderItem
    * @return       : List<PMC_DH_DeliveryTrackerWrapper.ProgressTracker>
    *****************************************************************************/ 
    private static List<PMC_DH_DeliveryTrackerWrapper.ProgressTracker> getProgressTracker(ShipmentItem objShipmentItem, OrderItem orderItem) {
        Map<PROGRESS_TRACKER_STAGES,String> mapProgressTracker = new Map<PROGRESS_TRACKER_STAGES,String>{
            PROGRESS_TRACKER_STAGES.SHIPMENT_REQUESTED => DELIVERY_TRACKER_STAGE_1, 
            PROGRESS_TRACKER_STAGES.SHIPMENT_SCHEDULED => DELIVERY_TRACKER_STAGE_2, 
            PROGRESS_TRACKER_STAGES.SHIPPED => DELIVERY_TRACKER_STAGE_3, 
            PROGRESS_TRACKER_STAGES.IN_TRANSIT => DELIVERY_TRACKER_STAGE_4, 
            PROGRESS_TRACKER_STAGES.EST_DELIVERY => DELIVERY_TRACKER_STAGE_5
        };
        List<PMC_DH_DeliveryTrackerWrapper.ProgressTracker> lstProgessTracker = new List<PMC_DH_DeliveryTrackerWrapper.ProgressTracker>();
        for(PROGRESS_TRACKER_STAGES stage : mapProgressTracker.keySet()){
            PMC_DH_DeliveryTrackerWrapper.ProgressTracker wrapDelTracker = new PMC_DH_DeliveryTrackerWrapper.ProgressTracker();
            wrapDelTracker.strTitle = mapProgressTracker.get(stage);
            wrapDelTracker.strStatus = TRACKER_STATE_PENDING;
            switch on(stage) {
                when SHIPMENT_REQUESTED {
                    wrapDelTracker.strStatus = TRACKER_STATE_ACTIVE;
                    wrapDelTracker.strCustOrderNumber = objShipmentItem.PMC_CPQ_LinePONumber__c;
                    wrapDelTracker.strUniqueNumber = objShipmentItem.Shipment.PMC_CPQ_VehicleID__c+'#'+objShipmentItem.Shipment.ShipmentNumber; //GDASF-20619
                    if(objShipmentItem.Shipment.PMC_CPQ_DeliveryStatus__c == STATUS_COMPLETELY_SHIPPED || objShipmentItem.PMC_CPQ_ShippedDate__c != NULL || objShipmentItem.Shipment.PMC_CPQ_DeliveryPlannedGIDate__c !=NULL) {
                        wrapDelTracker.strStatus = TRACKER_STATE_COMPLETED;
                    }
                }
                when SHIPMENT_SCHEDULED {
                    wrapDelTracker.datDate = objShipmentItem.Shipment.PMC_CPQ_DeliveryPlannedGIDate__c;
                    wrapDelTracker.strLocation = orderItem.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_City__c +' , '+  orderItem.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_Region__c;
                    setScheduledShipmentStat(objShipmentItem, wrapDelTracker);
                }
                when SHIPPED {
                    wrapDelTracker.datDate = objShipmentItem.PMC_CPQ_ShippedDate__c;
                    wrapDelTracker.strLocation = orderItem.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_City__c +' , '+  orderItem.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_Region__c;
                    if(objShipmentItem.Shipment.PMC_CPQ_DeliveryStatus__c == STATUS_COMPLETELY_SHIPPED ||  objShipmentItem.PMC_CPQ_ShippedDate__c != NULL){
                        wrapDelTracker.strStatus = TRACKER_STATE_COMPLETED;
                }
                }
                when IN_TRANSIT {
                    wrapDelTracker.strLocation = objShipmentItem.Shipment.PMC_CPQ_CurrentLocation__c; //GDASF-20619
                    setInTransitStatus(objShipmentItem, wrapDelTracker);
                }
                when EST_DELIVERY {
                    //wrapDelTracker.datDate = objShipmentItem.Shipment.PMC_CPQ_ETA__c;
                    wrapDelTracker.datDate = getETAOrShippedDate(objShipmentItem); //GDASF-20619
                    wrapDelTracker.strLocation = objShipmentItem.PMC_CPQ_OrderProduct__r.PMC_CPQ_ShipTo__r.ShippingCity +' , '+ objShipmentItem.PMC_CPQ_OrderProduct__r.PMC_CPQ_ShipTo__r.ShippingStateCode;
                    if(objShipmentItem.Shipment.PMC_CPQ_DeliveryStatus__c == STATUS_COMPLETELY_SHIPPED) {
                        wrapDelTracker.strTitle = DELIVERY_TRACKER_STAGE_6;
                        wrapDelTracker.strStatus = TRACKER_STATE_ACTIVE;
                    }
                }
            }
            lstProgessTracker.add(wrapDelTracker);
        }
        return lstProgessTracker;
    }
    /*************************************************************************
* @method Name  : getBoolValues
* @description  : Method to get boolean values
* @param        orderLineSummary
* @param        lstOrderItem
* @return       : Boolean
*****************************************************************************/
    public static Boolean getBoolValues(PMC_DH_OrderLineDetailsWrapper.OrderLineSummaryWrapper orderLineSummary,List<OrderItem> lstOrderItem){
        
        if(lstOrderItem[0].PMC_DH_CustomerCallPriceDate__c==null && lstOrderItem[0].PMC_CPQ_FPDPricefromPriceFx__c==null){
            orderLineSummary.boolCheckModal = false;
        }else if((lstOrderItem[0].PMC_DH_CustomerCallPriceDate__c!=null && lstOrderItem[0].PMC_CPQ_FPDPricefromPriceFx__c==null) || ((lstOrderItem[0].PMC_DH_CustomerCallPriceDate__c!=null && lstOrderItem[0].PMC_CPQ_FPDPricefromPriceFx__c!=null))){
            Date datCustomerCallprice = lstOrderItem[0].PMC_DH_CustomerCallPriceDate__c;
            DateTime updateDatCustomerCallprice = DateTime.newInstance(datCustomerCallprice.year(), datCustomerCallprice.month(), datCustomerCallprice.day(),11, 59, 59);
            DateTime datCallValue = updateDatCustomerCallprice.addHours(24);
            if(datCallValue<Date.today()){ 
                orderLineSummary.boolCheckModal = false;
            }else{
                orderLineSummary.boolCheckModal = true;
            }
        }
        return orderLineSummary.boolCheckModal;
    }
    
    // added by Nikhilesh as part of GPT-27880
    /*************************************************************************
* @method Name  : getDeliveries
* @description  : Method to get deliveries
* @param        orderItem
* @param        mapPicklistWrapper
* @return       : List<PMC_DH_OrderLineDetailsWrapper.DeliveriesWrapper>
*****************************************************************************/
    public static List<PMC_DH_OrderLineDetailsWrapper.DeliveriesWrapper> getDeliveries(OrderItem orderItem, Map<String,List<PMC_DH_PicklistWrapper>> mapPicklistWrapper){
        List<PMC_DH_OrderLineDetailsWrapper.DeliveriesWrapper> lstDeliveriesWrapper = new List<PMC_DH_OrderLineDetailsWrapper.DeliveriesWrapper>();
        String strRegion = PMC_DH_ShipmentHistoryListHelper.getUserRegion(); //GPT-44509
        for(ShipmentItem shipItem: orderItem.Delivery_Items__r){
            PMC_DH_OrderLineDetailsWrapper.DeliveriesWrapper deliveries = new PMC_DH_OrderLineDetailsWrapper.DeliveriesWrapper();
            if(shipItem.PMC_CPQ_DeliveryQuantity__c > 0){
                deliveries.strDeliveryId = shipItem.Id;
                deliveries.strPONumber = shipItem.PMC_CPQ_LinePONumber__c;
                deliveries.strProductName = shipItem.Product2.Name;
                deliveries.strVehicleId = shipItem.Shipment.PMC_CPQ_VehicleID__c; //GDASF-20619
                deliveries.datEstimatedShipmentDate = shipItem.PMC_CPQ_ShippedDate__c;
                deliveries.strDeliveryQuantity = String.valueOf(shipItem.PMC_CPQ_DeliveryQuantity__c);
                deliveries.strETA = String.valueOf(getETAOrShippedDate(shipItem)); //GDASF-20619
                deliveries.strCurrentLocation = shipItem.Shipment.PMC_CPQ_CurrentLocation__c; //GDASF-20619
                deliveries.lstDocument = mapPicklistWrapper.get(shipItem.Id);
                deliveries.strStatus = PMC_DH_OrderUtilHelper.getStatusOrdLine(shipItem.PMC_CPQ_DeliveryLineStatus__c);
                //deliveries.mapDocRecord = PMC_DH_OrderLineDetailsController.getDocumentData(orderItem);
                deliveries.mapDocRecord = PMC_DH_OrderLineDetailsController.getDocumentData(orderItem, strRegion);
                lstDeliveriesWrapper.add(deliveries);
            }
        }
        return lstDeliveriesWrapper;
    }
  
}