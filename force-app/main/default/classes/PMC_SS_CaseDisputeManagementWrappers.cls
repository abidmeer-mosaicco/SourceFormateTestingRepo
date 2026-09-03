/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-05-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class PMC_SS_CaseDisputeManagementWrappers {
    /**
     * @description - Wrapper class to hold the order related details
     */

    public class OrderDetailsWrapper {
        /**
         * @description - holds the account details
         */
        @AuraEnabled
        public PMC_SS_ObjectDetailsWrapper objAccountWrapper{get;set;}

        /**
         * @description - holds the contract details
         */
        @AuraEnabled
        public PMC_SS_ObjectDetailsWrapper objContractWrapper{get;set;}

        /**
         * @description - holds the sold-to account details
         */
        @AuraEnabled
        public PMC_SS_ObjectDetailsWrapper objSoldToAccountWrapper{get;set;}
        
        /**
         * @description - holds the order object
         */
        @AuraEnabled
        public Order objOrder{get;set;}
        
        /**
         * @description - holds the list of order related order products
         */
        @AuraEnabled
        public List<OrderItem> lstOrderItems{get;set;}

        /**
         * @description - holds the list of order related order products
         */
        @AuraEnabled
        public List<PMC_CPQ_Invoice__c> lstInvoices{get;set;}

        
        /**
         * @description - holds the list of order related deliveries
         */
        @AuraEnabled
        public List<Shipment> lstDeliveries{get;set;}
    }
}