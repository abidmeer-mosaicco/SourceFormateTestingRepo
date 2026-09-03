/**
* @description       : Wrapper for fetching Order History
* @author            : @Lohitha sai
* @Created on        : 07-26-2023
**/
public with sharing class PMC_DH_OrderListViewWrapper {
   /**
    * * @description List of Order
    * * @return String
    * */
   @AuraEnabled
   public List<OrderInfoWrapper> lstOrders { get; set; }
   /**
    * * @description List of Products in Order
    * * @return String
    * */
   @AuraEnabled
   public List<PMC_DH_PicklistWrapper> lstProductFilters { get; set; }
   /**
    * @description Status Code and message
   * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
   */
   @AuraEnabled
   public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}

           /*************************************************************************
* @method Name  : Wrapper class of Order
* @description  : Method to fetch Order Details
*****************************************************************************/
public class OrderInfoWrapper {
   /**
* * @description Id of Contract
* * @return String
* */
   @AuraEnabled
   public String strOrderNumber { get; set; }
   /**
* * @description Number of Contract
* * @return String
* */
@AuraEnabled
public String strContractNumber { get; set; }
   /**
* * @description SKU of Order
* * @return String
* */
   @AuraEnabled
   public List<String> setSKU { get; set; }
   /**
* * @description Order PONumber
* * @return String
* */
   @AuraEnabled
   public String strPONumber { get; set; }
   /**
   /**
* * @description products of Contract
* * @return String
* */
   @AuraEnabled
   public String strProducts { get; set; }
   /**
    * * @description shipTo of Order
    * * @return String
    * */
   @AuraEnabled
   public String shipTo { get; set; }
   /**
    * * @description Requested Shipment date of Order
    * * @return String
    * */
    @AuraEnabled
   public String orderShipmentDate { get; set; }
   /**
    * * @description created Datetime of Order
    * * @return String
    * */
    @AuraEnabled
   public DateTime orderDateCreated { get; set; }
   /**
    * * @description orderDetailLink of Order
    * * @return String
    * */
   @AuraEnabled
   public String orderDetailLink { get; set; }
        /**
     * * @description status of Order
     * * @return String
     * */
    @AuraEnabled
    public String strStatus { get; set; }
            /**
     * * @description totalQuantity of Order
     * * @return Double
     * */
    @AuraEnabled
    public Double totalQuantity { get; set; }
    /**
 * * @description totalPrice of Order
 * * @return String
 * */
    @AuraEnabled
    public Decimal totalPrice { get; set;}

    /**
     * @description searchable string for search
     * @return String
     */
    @AuraEnabled
    public String strSearchable{get;set;}
    
     /**
     * @description contains details for an order
     * @return String
     */
    @AuraEnabled
    public string strOrderItems{get;set;}
    
    /**
     * @description Sales Order Number
     * @return String
     */
    @AuraEnabled
    public string strSalesOrder{get;set;}

    /**
     * @description comma separated string of Product names
     * @return String
     */
    @AuraEnabled
    public string strProductNames{get;set;}

    /**
     * @description comma separated string of Ship To's
     * @return String
     */
    @AuraEnabled
    public string strShipToNames{get;set;}

    /**
     * @description comma separated string of Requested Shipment Dates
     * @return String
     */
    @AuraEnabled
    public string strReqShipDates{get;set;}

   // GPT-40681
    /**
     * @description Protocol No of Order
     * @return String
     */
    @AuraEnabled
    public string strProtocolNo{get;set;}

}
    }