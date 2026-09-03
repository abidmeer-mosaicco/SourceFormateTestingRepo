/**
* @description       : Wrapper for fetching Order History
* @author            : @Ajeet
* @Created on        : 11-03-2023
**/
public class PMC_DH_ShipmentHistoryWrapper{
    /**
* @description Destination
* @return string
*/
    @AuraEnabled
    public string strDestination{get;set;}
    /**
* @description Destination Id
* @return string
*/
    @AuraEnabled
    public string strDestinationId{get;set;}
    /**
* @description List of deliveries wrapper
* @return List<PMC_DH_DeliveryItemsWrapper>
*/
    @AuraEnabled
    public List<PMC_DH_DeliveryItemsWrapper> lstDeliveriesWrapper{get;set;}
    
    /**
* @description Wrapper class for Shipment items
* @author @Ajeet    
*/
    public class PMC_DH_DeliveryItemsWrapper{
        /**
* @description Order Id
* @return string
*/
        @AuraEnabled
        public string strOrderId{get;set;}
        /**
* @description Order Number
* @return string
*/
        @AuraEnabled
        public string strOrderNumber{get;set;}
        /**
* @description OrderLine Id
* @return string
*/
        @AuraEnabled
        public string strOrderLineId{get;set;}
        /**
* @description Delivery Item Id
* @return string
*/
        @AuraEnabled
        public string strDeliveryItemId{get;set;}
        /**
* @description PO Number
* @return string
*/
        @AuraEnabled
        public string strPONumber{get;set;}
        /**
* @description Product Name
* @return string
*/
        @AuraEnabled
        public string strProductName{get;set;}
        /**
* @description Vahicle Id
* @return string
*/
        @AuraEnabled
        public string strVehicleId{get;set;}
        /**
* @description Estimated Shipment Date
* @return string
*/
        @AuraEnabled
        public Date datShipDate{get;set;}
        /**
* @description Delivery Quantity
* @return string
*/
        @AuraEnabled
        public string strDeliveryQuantity{get;set;}
        /**
* @description ETA
* @return string
*/
        @AuraEnabled
        public string strETA{get;set;}
        /**
* @description Current location
* @return string
*/
        @AuraEnabled
        public string strCurrentLocation{get;set;}
        /**
* @description Document list
* @return List<PMC_DH_PicklistWrapper>
*/
        @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstDocument{get;set;}
        /**
* @description Deliveries status
* @return string
*/
        @AuraEnabled
        public string strStatus{get;set;}
        /**
* @description Deliveries document data
* @return Map<String,Map<String, String>>
*/
        @AuraEnabled
        public Map<String,Map<String, String>> mapDocRecord{get;set;}
    }
}