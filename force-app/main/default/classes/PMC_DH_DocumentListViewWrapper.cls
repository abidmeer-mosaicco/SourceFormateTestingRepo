/**
* @description       : Wrapper for fetching Document History
* @author            : @Nikhilesh
* @Created on        : 10-19-2023
**/

public with sharing class PMC_DH_DocumentListViewWrapper {
    /**
* * @description List of Documents
* * @return List<DocumentInfoWrapper>
* */
    @AuraEnabled
    public List<DocumentInfoWrapper> lstDocuments { get; set; }
        /**
* * @description List of Documents
* * @return List<DocumentInfoWrapper>
* */
    @AuraEnabled
    public List<PMC_DH_PicklistWrapper> lstDocumentTypes { get; set; }
/**
* @description Status Code and message
* @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*/
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    
    /*************************************************************************
* @method Name  : Wrapper class of Document
* @description  : Method to fetch Document Details
*****************************************************************************/
    public class DocumentInfoWrapper {
        
        @AuraEnabled
        public String inspLotUsageDecision { get; set; }
        
        /**
* * @description Order Number
* * @return String
* */
        @AuraEnabled
        public String strOrderNumber { get; set; }
        /**
* * @description Type of Document
* * @return String
* */
        @AuraEnabled
        public String strDocumentType { get; set; }
        /**
* * @description Name of Document
* * @return String
* */
        @AuraEnabled
        public String strDocumentName { get; set; }
        /**
* * @description Document Created Date 
* * @return Date
* */
        @AuraEnabled
        public Date datDocumentAddedDate { get; set; }
        /**
* * @description Identifier of Document
* * @return Map<String, String>
* */
        @AuraEnabled
        public Map<String, String> mapDocumentIdentifier { get; set; }
        /**
* * @description Document Code
* * @return String
* */
        @AuraEnabled
        public String strDocumentCode { get; set; }
        /**
* * @description Unique document Key GSMD-2233
* * @return String
* */
        @AuraEnabled
        public String strInvoiceNumber { get; set; }
    }
    
    
}