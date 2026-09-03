/**
 * @description wrapper class for pricing detail
 * @author hemant giri goswami
 * @since  07-27-2023
 * @last modified by @hemant giri goswami
 */
public without sharing class PMC_DH_PricingDetailWrapper {
    /**
     * @description Price widget
     * @return Boolean
     */
    @AuraEnabled
    public Boolean boolIsPriceEnabled{get;set;}
    /**
     * @description currency iso code
     * @return String
     */
    @AuraEnabled
    public String strCurrencyIsoCode{get;set;}

    /**
     * @description Total Price
     * @return Decimal
     */
    @AuraEnabled
    public Decimal decTotalPrice{get;set;}


    /**
     * @description Status Code and message
     * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
     */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}

    /**
     * @description  pricing summary wrapper
     * @return list<PMC_DH_PricingSummaryWrapper>
     */
    @AuraEnabled
    public List<PMC_DH_PricingSummaryWrapper> lstPriceSummary{get;set;}
    

/**
     * @description  wrapper class for pricing summary of Brazil Sold To's
     * @author Hemant giri goswami
     * @since 07-27-2023
     */

public class PMC_DH_PricingSummaryWrapper{

     /**
     * @description Product Name
     * @return String
     */
    @AuraEnabled
    public String strProductName{get;set;}

     /**
     * @description product sku
     * @return String
     */
    @AuraEnabled
    public String strProductSKU{get;set;}
     /**
     * @description Unit of Measure
     * @return String
     */
    @AuraEnabled
    public String strUOM{get;set;}

     /**
     * @description Quantity
     * @return String
     */
    @AuraEnabled
    public Long intQuantity{get;set;}

     /**
     * @description Price
     * @return Decimal
     */
    @AuraEnabled
    public Decimal decPrice{get;set;}
    /**
     * @description  Cart Line Item wrapper
     * @return list<PMC_DH_CartLineItemWrapper>
     */
    @AuraEnabled
    public List<PMC_DH_CartLineItemWrapper> lstCartLineItem{get;set;}
    /**
     * @description  Quote Line wrapper
     * @return list<PMC_DH_QuoteLineWrapper>
     */
    @AuraEnabled
    public List<PMC_DH_QuoteLineWrapper> lstQuoteLine{get;set;}
}
/**
     * @description  wrapper class for Cart Line Item
     * @author Rohan
     * @since 08-02-2023
     */

     public class PMC_DH_CartLineItemWrapper{
        /**
     * @description strcartItemId
     * @return String
     */
        @AuraEnabled
        public String strcartItemId{get;set;}
        /**
     * @description Price
     * @return Decimal
     */
    @AuraEnabled
    public Decimal decPrice{get;set;}
}
/**
     * @description  wrapper class for Quote Line
     * @author Rohan
     * @since 08-10-2023
     */

     public class PMC_DH_QuoteLineWrapper{
          /**
       * @description strcartItemId
       * @return String
       */
          @AuraEnabled
          public String strQuoteLineId{get;set;}
          /**
       * @description Price
       * @return Decimal
       */
      @AuraEnabled
      public Decimal decPrice{get;set;}
       }      
}