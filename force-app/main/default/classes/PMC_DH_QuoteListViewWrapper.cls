/**
* @description       : Wrapper for fetching Quote History
* @author            : @Lohitha sai
* @Created on        : 06-30-2023
**/
public with sharing class PMC_DH_QuoteListViewWrapper {
    /**
     * * @description List of Quote
     * * @return String
     * */
    @AuraEnabled
    public List<QuoteInfoWrapper> lstQuotes { get; set; }
    /**
     * * @description List of Products in Quote
     * * @return String
     * */
    @AuraEnabled
    public List<ProductDropDownWrapper> lstProductFilters { get; set; }
    /**
    * @description Status Code and message
   * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
   */
   @AuraEnabled
   public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    /*************************************************************************
* @method Name  : Wrapper class of Quote
* @description  : Method to fetch Quote Details
*****************************************************************************/
    public class QuoteInfoWrapper {
        /**
     * * @description Id of Quote
     * * @return String
     * */
        @AuraEnabled
        public String quoteId { get; set; }
        /**
     * * @description quoteFriendlyId of Quote
     * * @return String
     * */
        @AuraEnabled
        public String quoteFriendlyId { get; set; }
        /**
     * * @description SKU of Quote
     * * @return String
     * */
        @AuraEnabled
        public List<String> setSKU { get; set; }
        /**
     * * @description quoteNumber of Quote
     * * @return String
     * */
        @AuraEnabled
        public String quoteNumber { get; set; }
        /**
     * * @description shipTo of Quote
     * * @return String
     * */
        @AuraEnabled
        public String shipTo { get; set; }
        /**
     * * @description deliveryMode of Quote
     * * @return String
     * */
        @AuraEnabled
        public String deliveryMode { get; set; }
        /**
     * * @description products of Quote
     * * @return String
     * */
        @AuraEnabled
        public String products { get; set; }
        /**
     * * @description totalQuantity of Quote
     * * @return String
     * */
        @AuraEnabled
        public Long totalQuantity { get; set; }
        /**
     * * @description totalPrice of Quote
     * * @return String
     * */
        @AuraEnabled
        public Decimal totalPrice { get; set; }
        @AuraEnabled
        /**
     * * @description currentDateTime of Quote
     * * @return String
     * */
        public DateTime currentDateTime { get; set; }
        /**
     * * @description expirationDateTime of Quote
     * * @return String
     * */
        @AuraEnabled
        public DateTime expirationDateTime { get; set; }
        /**
     * * @description status of Quote
     * * @return String
     * */
        @AuraEnabled
        public String status { get; set; }
        /**
     * * @description quoteDetailLink of Quote
     * * @return String
     * */
        @AuraEnabled
        public String quoteDetailLink { get; set; }

    }

    /*************************************************************************
* @method Name  : Wrapper class of Product 
* @description  : Method to fetch Product Quote Details
*****************************************************************************/
    public  class ProductDropDownWrapper {
        /**
     * * @description label of Quote
     * * @return String
     * */
        @AuraEnabled
        public String label { get; set; }
        /**
     * * @description value of Quote
     * * @return String
     * */
        @AuraEnabled
        public String value { get; set; }
    }
}