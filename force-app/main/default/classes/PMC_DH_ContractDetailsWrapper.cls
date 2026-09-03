/**
* @description : Wrapper class for PMC_DH_ContractManagementController
* @author      : Nikhilesh
* @userStory   : GDASF-104
* @last modified on 06-28-2023
* @last modified by @Nikhilesh
**/
public with sharing class PMC_DH_ContractDetailsWrapper{
    /**
     * @description Contract number
     * @author @Nikhilesh    
     */
    @AuraEnabled
    public String strContractNumber {get;set;}
    /**
     * @description Quote ID
     * @author @Nikhilesh    
     */
    @AuraEnabled
    public String strQuoteId {get;set;}
    /**
     * @description Wrapper class for Contract Summary
     * @author @Nikhilesh    
     */
    @AuraEnabled
    public ContractSummaryWrapper contractSummaryWrapper {get;set;}
     /**
     * @description Wrapper class for Payment Info
     * @author @Nikhilesh    
     */
    @AuraEnabled
    public PMC_DH_QuoteDetailsWrapper.PaymentInformationWrapper paymentInfoWrapper {get;set;}
    /**
     * @description Wrapper class for Product Info
     * @author @Nikhilesh    
     */
    @AuraEnabled
    public PMC_DH_RequestForQuoteWrapper productInfoWrapper {get;set;}
    /**
     * @description Wrapper class for Quote of Origin
     * @author @Nikhilesh    
     */
    @AuraEnabled
    public QuoteOfOriginWrapper quoteOfOriginWrapper {get;set;}
    /**
     * @description Wrapper class for List of Quote of Origin
     * @author @Hemant    
     */
    @AuraEnabled
    public List<QuoteOfOriginWrapper> lstQuoteOfOriginWrapper {get;set;}
/**
    * @description Status Code and message
    * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    

    /**
     * @description Wrapper class for Contract Summary
     * @author @Nikhilesh    
     */
    public class ContractSummaryWrapper{
            /**
         * @description PO Number of Contract
         * @author @Nikhilesh    
         */
        @AuraEnabled
        public string strPoNumber{get;set;}
        /**
         * @description Customer Name of Contract
         * @author @Nikhilesh    
         */
        @AuraEnabled
        public string strCustomerName{get;set;}
                /**
         * @description Status of Contract
         * @author @Nikhilesh    
         */
        @AuraEnabled
        public string strSummaryStatus{get;set;}
         /**
         * @description Status of Contract
         * @author @Sampreeth    
         */
        @AuraEnabled
        public string strQuoteType{get;set;}
                /**
         * @description Start Date of Contract
         * @author @Nikhilesh    
         */
        @AuraEnabled
        public Date datContractStartDate{get;set;}
                /**
         * @description End Date of Contract
         * @author @Nikhilesh    
         */
        @AuraEnabled
        public Date datContractEndDate{get;set;}
                /**
         * @description Reason for 'Inactive' status of Contract (Completed/Expired)
         * @author @Nikhilesh    
         */
        @AuraEnabled
        public string strInactiveReason{get;set;}
        
        /**
         * @description eligbile for for the Request Signture 
         * @author @Sugunakar    
         */
        @AuraEnabled
        public Boolean boolIsEligibleForReqSign{get;set;}
    }
    /**
     * @description Wrapper class for Quote of Origin
     * @author @Nikhilesh    
     */
    public class QuoteOfOriginWrapper{
        /**
         * @description Quote Number
         * @author @Nikhilesh    
         */
        @AuraEnabled
        public string strQuoteNumber{get;set;}
        /**
         * @description Quote Id
         * @author @Nikhilesh    
         */
        @AuraEnabled
        public string strQuoteId{get;set;}
        /**
         * @description Quote Status
         * @author @Nikhilesh    
         */
        @AuraEnabled
        public string strQuoteStatus{get;set;}
    }
    
    /**
     * @description can edit PO number or not
     * @author Hemant Giri Goswami
     */
    @AuraEnabled
    public Boolean boolIsPOEditable{get;set;}
}