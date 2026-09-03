/**
* @description : Wrapper class for PMC_DH_QuoteDetailsWrapper
* @author      : Humera Rahath
* @userStory   : GDASF-121
* @last modified on 06-28-2023
* @last modified by @Nikhilesh
**/
public with sharing class PMC_DH_QuoteDetailsWrapper {
     /**
     * @description Wrapper class for QuoteSummary
     * @author @mhumerarahath    
     */
    @AuraEnabled
    public QuoteSummaryWrapper quoteSummaryWrapper {get;set;}
     /**
     * @description Wrapper class for PaymentInformation
     * @author @mhumerarahath    
     */
    @AuraEnabled
    public PaymentInformationWrapper paymentInformationWrapper {get;set;}
     /**
     * @description Wrapper class for Requested ContractInformation
     * @author @mhumerarahath    
     */
    @AuraEnabled
    public RequestedContractInfoWrapper requestedContractInfoWrapper {get;set;}
/**
     * @description Wrapper class for ProductInformation
     * @author @mhumerarahath    
     */
    @AuraEnabled
    public PMC_DH_RequestForQuoteWrapper productInfoWrapper{get;set;}
    /** 
    * @description Wrapper class for Contracts
    * @author @mhumerarahath    
    */
    @AuraEnabled
    public List<ContractsWrapper> lstContracts{get;set;}
    /**
     * @description Status Code and message
     * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
     */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    
    /**
     * @description Wrapper class for QuoteSummary
     * @author @mhumerarahath    
     */
public class QuoteSummaryWrapper
{
    /**
     * @description Quote Id of Quote
     * @author @mhumerarahath    
     */
    @AuraEnabled
    public string strQuoteId{get;set;}
     /**
     * @description Customer Name of Quote
     * @author @mhumerarahath    
     */
    @AuraEnabled
    public String strCustomerName{get;set;}
     /**
     * @description Customer Region of related Quote
     * @author @mhumerarahath    
     */
    @AuraEnabled
    public String strCustomerRegion{get;set;}
    /**
     * @description Sold To Account of Quote
     * @author @mhumerarahath    
     */
    @AuraEnabled
    public String strSoldToAccount{get;set;}
    /**
     * @description Requested Date of Quote
     * @author @mhumerarahath    
     */
    @AuraEnabled
    public Date datRequestedDate{get;set;}
    /**
     * @description ExpiryDate of Quote
     * @author @mhumerarahath    
     */
    @AuraEnabled
    public DateTime datTExpiresIn{get;set;}
     /**
     * @description Current DateTime of Quote
     * @author @mhumerarahath    
     */
    @AuraEnabled
    public DateTime datTCurrentDateTime{get;set;}
    /**
     * @description Status of Quote
     * @author @mhumerarahath    
     */
    @AuraEnabled
    public String strSummaryStatus{get;set;}
    /**
     * @description Progress Indicator Status of Quote
     * @author @mhumerarahath    
     */
    @AuraEnabled
    public String strProgressIndicatorStatus{get;set;}
    /**
     * @description  Summary Reason
     * @return String
     */
    @AuraEnabled
    public string strSummaryReason{get;set;}
    /**
     * @description  Rejection reason
     * @return String
     */
    @AuraEnabled
    public string strRejectionReason{get;set;}
    /**
    * @description Flag for document present or not
    * @return Boolean
    */
    @AuraEnabled
    public Boolean boolDocumentAvailable { get; set; }
}

/**
     * @description Wrapper class for PaymentInformation
     * @author @mhumerarahath    
     */
    public class PaymentInformationWrapper {
        /**
     * @description Selected Payment Term of Quote
     * @author @mhumerarahath    
     */
    @AuraEnabled
        public String strPaymentTermSelected {get; set;}
        /**
     * @description Selected Payment Method of Quote
     * @author @mhumerarahath    
     */
    @AuraEnabled
        public String strPaymentMethodSelected { get; set; }
        /**
     * @description Selected Currency of Quote
     * @author @mhumerarahath    
     */
    @AuraEnabled
        public String strCurrencySelected { get; set; }
        /**
     * @description Boolean check for Boleto in document
     * @author @Nikhilesh    
     */
    @AuraEnabled
    public Boolean boolIsBoletoAvailable { get; set; }
        /**
     * @description Prepayment Date of Quote
     * @author @kreddylakshmi    
     */
    @AuraEnabled
    public date datPrepaymentDate { get; set; }//added as part of GDASF-19809

        /**
     * @description List of Payment Term for Quote
     * @author @mhumerarahath    
     */
    @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstPaymentTerms { get; set; }
        /**
     * @description List of Payment Method for Quote
     * @author @mhumerarahath    
     */
    @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstPaymentMethods { get; set; }
        /**
     * @description List of Currency for Quote
     * @author @mhumerarahath    
     */
    @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstCurrency { get; set; }
    }

    /**
     * @description Wrapper class for Requested Contract Information
     * @author @mhumerarahath    
     */
    public class RequestedContractInfoWrapper {
        /**
     * @description Start Date of Contract
     * @author @mhumerarahath    
     */
    @AuraEnabled
        public Date datStartDate {get;set;}
        /**
     * @description End Date of Contract
     * @author @mhumerarahath    
     */
    @AuraEnabled
        public Date datEndDate {get;set;}
    }
/**
     * @description Wrapper class for Contracts
     * @author @mhumerarahath    
     */
    public class ContractsWrapper{
         /**
     * @description Contract Number
     * @author @mhumerarahath    
     */
    @AuraEnabled
        public String strContractNumber{get;set;}
         /**
     * @description Contract Status
     * @author @mhumerarahath    
     */
    @AuraEnabled
        public String strContractStatus{get;set;}
         /**
     * @description Contract Url
     * @author @mhumerarahath    
     */
    @AuraEnabled
        public String strContractUrl{get;set;}
        }


/**
 * @description wrapper class for conversation history
 * @author @hegoswami
 * @since 06-28-2023
 */
public class QuoteHistoryWrapper implements Comparable{
    /**
     * @description String User Name
     */
    @AuraEnabled
    public String strUsrName{get;set;}
    /**
     * @description Object Original Value(old)
     */
    @AuraEnabled
    public Object strOriginalValue{get;set;}
    /**
     * @description Object New value
     */
    @AuraEnabled
    public Object strNewValue{get;set;}
    /**
     * @description String Field Name
     */
    @AuraEnabled
    public String strFieldName{get;set;}

    /**
     * @description Date Modified Date
     */
    @AuraEnabled
    public DateTime datModifiedDate{get;set;}

/**
 * @description Method for sorting 
 * @author hemant.goswami@mosaicco.com
 * @since 06-30-2023
 * @param objToCompare 
 * @return             `Integer`
 */
    public Integer compareTo(Object objToCompare) {
            QuoteHistoryWrapper qwrapperObj = (QuoteHistoryWrapper)objToCompare;
            if (datModifiedDate == qwrapperObj.datModifiedDate){
                return 0;
            }
            else if (datModifiedDate < qwrapperObj.datModifiedDate){
                return 1;
            }
            else{
                return -1;        
            }
        }
}

    }