/**
* @description : Wrapper class for PMC_DH_OrderSubmitController
* @author      : Mosaic Direct Dev 
* @userStory   :
* @last modified on 10-05-2023
* @last modified by @Mosaic Direct Dev 
**/
public with sharing class PMC_DH_OrderFetchWrapper {
        /**
     * @description List of Order line
     * @return List<PMC_DH_ResponseWrapper>
     */
    @AuraEnabled
    public List<PMC_DH_ResponseWrapper> lstData = new List<PMC_DH_ResponseWrapper>();
/**
 * @description Wrapper class for Response
 * @author @Ajeet    
 */
    public class PMC_DH_ResponseWrapper{
            /**
     * @description PO Number
     * @return string
     */
        public String strPoNumber{get;set;}
            /**
     * @description Ship to id
     * @return string
     */
        public String strShiptoId{get;set;}
            /**
     * @description Confirmed qty
     * @return string
     */
        public String strConfirmedCuttingQty{get;set;}
            /**
     * @description Contract number
     * @return string
     */
        public String strContractFinalized{get;set;}
            /**
     * @description Ship to address
     * @return string
     */
        public String strShiptoAdd{get;set;}
            /**
     * @description Created by
     * @return string
     */
        public String strCreateBy{get;set;}
            /**
     * @description Request id
     * @return string
     */
        public String strReqId{get;set;}
            /**
     * @description SKU
     * @return string
     */
        public String strMaterial{get;set;}
            /**
     * @description Shipment Date
     * @return string
     */
        public String strConfirmDelDate{get;set;}
            /**
     * @description strCustMatnr
     * @return string
     */
        public String strCustMatnr{get;set;}
            /**
     * @description Channed
     * @return string
     */
        public String strCreateVia{get;set;}
            /**
     * @description Requested qty
     * @return string
     */
        public String strRequestQty{get;set;}
            /**
     * @description Requested shipment date
     * @return string
     */
        public String strReqDelDate{get;set;}
            /**
     * @description Sold to name
     * @return string
     */
        public String strSoldtoName{get;set;}
            /**
     * @description ship to name
     * @return string
     */
        public String strShiptoName{get;set;}
            /**
     * @description sold to id
     * @return string
     */
        public String strSoldtoId{get;set;}
            /**
     * @description Description
     * @return string
     */
        public String strMaterialDesc{get;set;}
            /**
     * @description plant
     * @return string
     */
        public String strPlant{get;set;}
            /**
     * @description Mode of delivery
     * @return string
     */
        public String strMot{get;set;}
            /**
     * @description Total price
     * @return string
     */
        public String strTotPrice{get;set;}
            /**
     * @description strProtocolPriceUnit
     * @return string
     */
        public String strProtocolPriceUnit{get;set;}
            /**
     * @description Order line
     * @return string
     */
        public String strGeneralPrice{get;set;}
            /**
     * @description created date
     * @return string
     */
        public String strCreatedOn{get;set;}
            /**
     * @description Plant address
     * @return string
     */
        public String strPlantAdd{get;set;}
        
           /**
     * @description Incoterms
     * @return string
     */
        public String strIncotterms{get;set;}
        
         /**
     * @description Incoterms
     * @return string
     */
        public String strPackType{get;set;}

           /**
     * @description Incoterms
     * @return string
     */
    public String strPackingType{get;set;}

     /**
     * @description Sales Order Number
     * @return String
     */
    @AuraEnabled
    public string strSalesOrder{get;set;}
    
    /**
     * @description Protocol No of Order
     * @return String
     */
    @AuraEnabled
    public string strProtocolNo{get;set;}
      
              /**
* * @description strAccIdentifier
* * @return String
* */
        @AuraEnabled
        public string strAccIdentifier{get;set;} //GDASF-19767
    } 
}