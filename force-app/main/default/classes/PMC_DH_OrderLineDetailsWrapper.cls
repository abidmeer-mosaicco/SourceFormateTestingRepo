/**
* @description : Wrapper class for 
* @author      : Ajeet
* @userStory   : GDASF-14512
* @last modified on 
* @last modified by
**/
public with sharing class PMC_DH_OrderLineDetailsWrapper{
    /**
     * @description Order line
     * @return string
     */
    @AuraEnabled
    public string strOrderLine{get;set;}
    /**
     * @description Order Line Item Id
     * @return string
     */
    @AuraEnabled
    public string strOrderLineItemId{get;set;}
    /**
     * @description Order Line Summary
     * @return OrderLineSummaryWrapper
     */
    @AuraEnabled
    public OrderLineSummaryWrapper objOrderLineSummary{get;set;}
    /**
     * @description Status Code and message
     * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
     */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}

/**
 * @description Wrapper class Order line Summary
 * @author @Ajeet    
 */
public class OrderLineSummaryWrapper{
    /**
     * @description check Modal
     * @return Boolean
     */
    @AuraEnabled
    public Boolean boolCheckModal{get;set;}
    /**
     * @description callPriceRequestedBySystem
     * @return Boolean
     */
    @AuraEnabled
    public Boolean boolCallPriceRequestedBySystem{get;set;}
    /**
     * @description Product Name
     * @return string
     */
    @AuraEnabled
    public string strProductName{get;set;}
    /**
     * @description Customer Name
     * @return string
     */
    @AuraEnabled
    public string strCustomerName{get;set;}
    /**
     * @description Ship to
     * @return ShipToWrapper
     */
    @AuraEnabled
    public ShipToWrapper strShipTo{get;set;}
    /**
     * @description Delivery Information
     * @return string
     */
    @AuraEnabled
    public string strDeliveryInformation{get;set;}
    /**
     * @description Total Order line Qty
     * @return string
     */
    @AuraEnabled
    public string strTotalOrderLineQty{get;set;}
    /**
     * @description Order Line Status
     * @return string
     */
    @AuraEnabled
    public string strOrderLineStatus{get;set;}
    /**
     * @description Call Price Date
     * @return Date
     */
    @AuraEnabled
    public Date datCallPriceDate{get;set;}
    /**
     * @description Deliveries list
     * @return List<DeliveriesWrapper>
     */
    @AuraEnabled
    public List<DeliveriesWrapper> lstDeliveries{get;set;}
}

/**
 * @description Wrapper class for Ship To
 * @author @Ajeet    
 */
public class ShipToWrapper{
    /**
     * @description Ship to name
     * @return string
     */
    @AuraEnabled
    public string strAddressLine1{get;set;}
    /**
     * @description Shipping Street
     * @return string
     */
    @AuraEnabled
    public string strAddressLine2{get;set;}
    /**
     * @description Shipping City
     * @return string
     */
    @AuraEnabled
    public string strCity{get;set;}
    /**
     * @description Shipping State
     * @return string
     */
    @AuraEnabled
    public string strState{get;set;}
    /**
     * @description Shipping country
     * @return string
     */
    @AuraEnabled
    public string strCountry{get;set;}
    /**
     * @description Shipping Zipcode
     * @return string
     */
    @AuraEnabled
    public string strZipCode{get;set;}    
}

/**
 * @description Wrapper class for Delivery Item Summary
 * @author @Ajeet    
 */
    public class DeliveriesWrapper{
        /**
     * @description Delivery Id
     * @return string
     */
        @AuraEnabled
        public string strDeliveryId{get;set;}
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
        public Date datEstimatedShipmentDate{get;set;}
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