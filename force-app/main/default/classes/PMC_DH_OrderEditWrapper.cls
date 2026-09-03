/**
* @description        
* @author              Mosaic Direct Dev 
* @group              
* @last modified on   10-27-2023
* @last modified by    Mosaic Direct Dev 
**/
public with sharing class PMC_DH_OrderEditWrapper {
    /**
* * @description List of PMC_DH_RequestWrapper
* * @return PMC_DH_RequestWrapper
* */
    
    @AuraEnabled
    public PMC_DH_RequestWrapper lstResultData {get;set;}
    /**
    * @description Wrapper class for order request
    * @author  Mosaic Direct Dev 
    **/ 
    public class PMC_DH_RequestWrapper{
        /**
* * @description ReqId
* * @return String
* */
        @AuraEnabled
        public string strReqId  {get;set;}
        /**
* * @description strPlant
* * @return String
* */
        @AuraEnabled
        public string strPlant{get;set;}
        /**
* * @description strCustomerId
* * @return String
* */
        @AuraEnabled
        public string strCustomerId   {get;set;}
        /**
* * @description strMaterial
* * @return String
* */
        @AuraEnabled
        public string strMaterial  {get;set;}
        /**
* * @description strIncoterms
* * @return String
* */
        @AuraEnabled
        public string strIncoterms  {get;set;}
        /**
* * @description strCreatedBy
* * @return String
* */
        @AuraEnabled
        public string strCreatedBy {get;set;}
        /**
* * @description strCreatedVia
* * @return String
* */
        @AuraEnabled
        public string strCreatedVia  {get;set;}
        /**
* * @description strCreatedOn
* * @return String
* */
        @AuraEnabled
        public string strCreatedOn  {get;set;}
        /**
* * @description strNfeCoopCustomer
* * @return String
* */
        @AuraEnabled
        public string strNfeCoopCustomer  {get;set;}
        /**
* @description strNFEBillingDate
* @return String
*/
        @AuraEnabled
        public string strNFEBillingDate {get;set;}
        /**
* * @description strGenPricePerunit
* * @return String
* */
        @AuraEnabled
        public string strGenPricePerunit {get;set;}
        /**
* * @description strTotPrice
* * @return String
* */
        @AuraEnabled
        public string strTotPrice {get;set;}
        /**
* * @description strCustomerReqQty
* * @return String
* */
        @AuraEnabled
        public string strCustomerReqQty  {get;set;}
        /**
* * @description strReqDelDat
* * @return String
* */
        @AuraEnabled
        public string strReqDelDat {get;set;}
        /**
* * @description strContractItemNo
* * @return String
* */
        @AuraEnabled
        public string strContractItemNo {get;set;}
        /**
* * @description strShipTo
* * @return String
* */
        @AuraEnabled
        public string strShipTo {get;set;}
        /**
* * @description strProtocolPrice
* * @return String
* */
        @AuraEnabled
        public string strProtocolPrice {get;set;}
        /**
* * @description strDelInstr
* * @return String
* */
        @AuraEnabled
        public string strDelInstr {get;set;}
        /**
* * @description strMot
* * @return String
* */
        @AuraEnabled
        public string strMot  {get;set;}
        /**
* * @description strPoNo
* * @return String
* */
        @AuraEnabled
        public string strPoNo {get;set;}
        /**
* * @description strPaymentTermsn
* * @return String
* */
        @AuraEnabled
        public string strPaymentTermsn  {get;set;}
        /**
* * @description strSelfConsInd
* * @return String
* */
        @AuraEnabled
        public string strSelfConsInd {get;set;}
        /**
* * @description strCutomerMaterial
* * @return String
* */
        @AuraEnabled
        public string strCutomerMaterial  {get;set;}
                /**
* * @description strContractReq
* * @return String
* */
        @AuraEnabled
        public string strContractReq{get;set;}
    
        
    } 
}