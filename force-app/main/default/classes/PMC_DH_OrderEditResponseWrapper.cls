/**
* @description : Wrapper class to return order edit re
* @author      : Gomathi Subramani
* @userStory   :
* @last modified on 10-19-2023
* @last modified by @Mosaic Direct Dev 
**/
public class PMC_DH_OrderEditResponseWrapper {
     /**
     * @description Order Item Id
     * @return string
     */
	@AuraEnabled
    public string strReqId{get;set;}       
    /**
     * @description updated quantity
     * @return string
     */
	@AuraEnabled
    public string strQty{get;set;}
        /**
     * @description updated shipmentDate
     * @return string
     */
    @AuraEnabled
    public string strShipmentDate{get;set;}
        /**
     * @description message ie.success or error
     * @return string
     */
    @AuraEnabled
    public string strMessage{get;set;}
    /**
        * @description Status Code and message
        * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
        */
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
}