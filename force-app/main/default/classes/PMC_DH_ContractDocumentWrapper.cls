/**
 * @description Wrapper class for contract document
 * @author Hemant Giri Goswami
 * @since 09-07-2023
 */

public class PMC_DH_ContractDocumentWrapper {

    /**
     * @description wrapper for contract doc ingo
     * @author hemant giri goswami
     */
    public class PMC_DH_ContractDocInfo
    {   
        /**
         * @description list of child wrapper
         * @author hemant giri  goswami
         */
        @AuraEnabled
        public List<PMC_DH_ContractDocInfoInst> lstContractDoc{get;set;}
        /**
        * @description Status Code and message
        * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
        */
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    }

    /**
     * @description wrapper for contract doc instance
     * @author hemant giri goswami
     */
    public class PMC_DH_ContractDocInfoInst
    {
    /**
     * @description String to store Document Name
     * @author Hemant Giri Goswami
     * @return String 
     */
    @AuraEnabled
    public String strDocName{get;set;}

    /**
     * @description String to store Contract Type
     * @author Hemant Giri Goswami
     * @return String 
     */
    @AuraEnabled
    public String strContractType{get;set;}


    /**
     * @description String to store Delivery Mode of Contract
     * @author Hemant Giri Goswami
     * @return String 
     */
    @AuraEnabled
    public String strDeliveryMode{get;set;}


    /**
     * @description String to store Document Id
     * @author Hemant Giri Goswami
     * @return String 
     */
    @AuraEnabled
    public String strDocId{get;set;}
    }


    /**
     * @description wrapper class for document data to store url for the docs
     * @author Hemant giri goswami
     * @since 09-07-2023
     */
    public Class PMC_DH_ContractDocData
    {
        /**
     * @description String to store Document Body
     * @author Hemant Giri Goswami
     * @return Blob
     */
        @AuraEnabled
        public String strDownloadLink{get;set;}

        /**
     * @description String to store Document Download Url from SF N&A
     * @author Hemant Giri Goswami
     * @return String 
     */
        @AuraEnabled
        public String strViewData{get;set;}
        /**
        * @description Status Code and message
        * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
        */
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
        }
}