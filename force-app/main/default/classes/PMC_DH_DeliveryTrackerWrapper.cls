/**
* @description : Wrapper class for 
* @author      : Krishan
* @userStory   : GDASF-14533
* @last modified on 
* @last modified by
**/
public class PMC_DH_DeliveryTrackerWrapper {
    /**
     * @description Order Number
     * @return string
     */
    @AuraEnabled
    public string strOrderNumber{get;set;}
    /**
     * @description Product Name
     * @return string
     */
    @AuraEnabled
    public string strProductName{get;set;}
    /**
     * @description Shipper Name
     * @return string
     */
    @AuraEnabled
    public string strShipper{get;set;}
    /**
     * @description Carrier Name
     * @return string
     */
    @AuraEnabled
    public string strCarrier{get;set;}
    /**
     * @description String
     * @return Date
     */
    @AuraEnabled
    public String strDeliveryStatus{get;set;}
    /**
     * @description Date of ETA
     * @return Date
     */
    @AuraEnabled
    public Date datETA{get;set;}
    /**
     * @description List of Progress Tracker
     * @return List
     */
    @AuraEnabled
    public List<ProgressTracker> lstProgressTracker{get;set;}
    /**
     * @description List of Progress Tracker
     * @return List
     */
   // @AuraEnabled
   // public List<DeliveryProgress> lstDeliveryProgress{get;set;}
    /**
     * @description List of Progress Tracker
     * @return List
     */
    @AuraEnabled
    public List<Mapmarker> mapMarkers{get;set;}
    /**
    * @description Status Code and message
    * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    /**
     * @description Progress Tracker
     */
    public class ProgressTracker{
        /**
     * @description Title Name
     * @return string
     */
    @AuraEnabled
    public string strTitle{get;set;}
        /**
     * @description Status
     * @return string
     */
    @AuraEnabled
    public string strStatus{get;set;}
        /**
     * @description customer order number
     * @return string
     */
    @AuraEnabled
    public string strCustOrderNumber{get;set;}
        /**
     * @description unique Number
     * @return string
     */
    @AuraEnabled
    public string strUniqueNumber{get;set;}
        /**
     * @description Date Time
     * @return DateTime
     */
    @AuraEnabled
    public Date datDate{get;set;}
        /**
     * @description Date Time
     * @return String
     */
    @AuraEnabled
    public String strLocation{get;set;}
        /**
     * @description Date Time
     * @return String
     */
    }
   // public class DeliveryProgress{
        /**
     * @description date of time
     * @return datetime
     */
   // @AuraEnabled
   // public DateTime datDateTime{get;set;}
                             /**
     * @description Details
     * @return String
     */
   // @AuraEnabled
   // public string strDetails{get;set;}
   // }
    /**
     * @description Map Marker
     */
    public class Mapmarker{
        /**
     * @description Langtitude
     * @return string
     */
    @AuraEnabled
    public string strTitle{get;set;}
        /**
     * @description Address
     * @return string
     */
    @AuraEnabled
    public String strDescription{get;set;}
        
      /**
     * @description List of Progress Tracker
     * @return List
     */
    @AuraEnabled
    public Location location{get;set;}
    }
        /**
     * @description Location
     */
    public class Location{
        /**
     * @description Street
     * @return string
     */
    @AuraEnabled
    public string strStreet{get;set;}
        /**
     * @description City
     * @return string
     */
    @AuraEnabled
    public string strCity{get;set;}
       /**
     * @description State
     * @return string
     */
    @AuraEnabled
    public string strState{get;set;}
        /**
     * @description Country
     * @return string
     */
    @AuraEnabled
    public string strCountry{get;set;}
        /**
     * @description Langtitude
     * @return string
     */
    @AuraEnabled
    public string strLongitude{get;set;}
        /**
     * @description longitute
     * @return string
     */
    @AuraEnabled
    public string strLatitude{get;set;}
    }
}