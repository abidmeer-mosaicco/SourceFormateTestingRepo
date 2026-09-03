/**
* @description : Wrapper class for PMC_DH_HomePageController
* @author      : Humera Rahath
* @userStory   : GDASF-12392
* @last modified on 09-01-2023
* @last modified by @Humera
**/
public class PMC_DH_HomePageWrapper {
/**
* @description Wrapper class for Rececnt Quotes
* @author @mhumerarahath    
*/
    public class RecentQuotesWrapper{

        /**
         * @description Status Code and message
         * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
         */
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}

        /**
        * @description Quote History URL of Quote
        * @author @mhumerarahath    
        */   
        @AuraEnabled
        public String strQuoteHistoryUrl{get;set;}

        /**
        * @description List of recent Quotes
        * @author @mhumerarahath    
        */
        @AuraEnabled
        Public List<RecentQuotesList> lstQuotes{get;set;}
        
    }

     /**
     * @description wrapper class for contract info
     * @author hemant giri goswami
     * @since 09-01-2023
     */
    public class RecentContractWrapper{

        /**
         * @description Status Code and message
         * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
         */
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}

        /**
         * @description Contract History Page Url
         * @return String
         */
        @AuraEnabled
        public String strContractHistorPageUrl{get;set;}
        /**
         * @description list of contract (info)
         * @return List<ActiveContractInfoWrapper>
         */
        @AuraEnabled
        Public List<ActiveContractInfoWrapper> lstContracts{get;set;}
    }
/**
* @description Wrapper class for list of reccent quotes
* @author @mhumerarahath    
*/
    public class RecentQuotesList{
/**
* @description Quote Number of Quote
* @author @mhumerarahath    
*/
        @AuraEnabled
        public String strQuoteNumber{get;set;}
/**
* @description Quote URL of Quote
* @author @mhumerarahath    
*/
        @AuraEnabled
        public String strQuoteUrl{get;set;}
/**
* @description Requested time of Quote
* @author @mhumerarahath    
*/
        @AuraEnabled
        public Date datRequestedDate{get;set;}
/**
* @description  Status of Quote
* @author @mhumerarahath    
*/
        @AuraEnabled
        public String strQuoteStatus{get;set;}
    }

    /**
     * @description wrapper class for contract info
     * @author hemant giri goswami
     * @sicne 09-01-2023
     */
    public class ActiveContractInfoWrapper
    {

        /**
         * @description Contract History Page Url
         * @return String
         */
        @AuraEnabled
        public String strContractHistoryUrl{get;set;}
        /**
         * @description Contract Number
         * @return String
         */
        @AuraEnabled
        public  String strContractNumber{get;set;}

        /**
         * @description  Contract Id
         * @return string
         */
        @AuraEnabled
        public  String strContractId{get;set;}
        /**
         * @description Product Name or "multiple"
         * @return STring
         */
        @AuraEnabled
        public  String strProduct{get;set;}
        
        /**
         * @description Ship to name("multiple")
         * @return String
         */
        @AuraEnabled
        public String strShipto{get;set;}

        /**
         * @description List of ship to
         * @return List<String>
         */
        @AuraEnabled
        public List<String>lstShipTo{get;set;}

        /**
         * @description PO number
         * @return String
         */
        @AuraEnabled
        public String strPoNumber{get;set;}

        /**
         * @description Available Quantity
         * @return Long
         */
        @AuraEnabled
        public Double intAvailableQty{get;set;} //Double added because Long was not considering decimal values: GPT-40756
    }

    /**
     * @description wrapper class for order in transit widget
     * @author Hemant Giri Goswami
     * @since 10=05-2023
     */
    public class OrdersinTransit{

        /**
         * @description  order id
         * @return String
         */
        @AuraEnabled
        public String strOrderId{get;set;}
        /**
         * @description order number
         * @return string
         */
        @AuraEnabled
        public String strOrderNumber{get;set;}
        /**
         * @description DeliveryMode
         * @return string
         */
        @AuraEnabled
        public String strDeliveryMode{get;set;}
        /**
         * @description order products
         * @return List<String>
         */
        @AuraEnabled
        public String strProduct{get;set;}
        /**
         * @description order status
         * @return string
         */
        @AuraEnabled
        public String strStatus {get;set;}

        /**
         * @description Link to detail page
         * @return String
         */
        @AuraEnabled
        public String strDetailPageUrl{get;set;}

        /**
         * @description shipment date
         * @return Date
         */
        @AuraEnabled
        public Date datShipment{get;set;}
        
    }
    
}