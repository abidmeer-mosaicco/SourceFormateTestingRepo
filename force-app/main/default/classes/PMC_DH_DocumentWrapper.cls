/**
 * @description       : Wrapper Class for PMC_DH_DocumentFetchService
 * @author            : Humera Rahath 
 * @last modified on  : 10-26-2023
 * @last modified by  : Humera Rahath
**/
public  with sharing class PMC_DH_DocumentWrapper {
/**
    * * @description Identifier of Document
    * * @return PMC_DH_ReqWrapper
    * */
    @AuraEnabled
    public PMC_DH_ReqWrapper objData {get;set;}
/*************************************************************************
* @method Name  : Wrapper class of Document
* @description  : Method to request Document Details
*****************************************************************************/
    public class PMC_DH_ReqWrapper{
        /**
    * * @description Document Code of Document
    * * @return String
    * */
        @AuraEnabled
        public String strDocumentCode{get;set;}
        /**
    * * @description Delivery Number of Document
    * * @return String
    * */
        @AuraEnabled
        public String strDeliveryNumber{get;set;}
        /**
    * * @description Delivery Item Number of Document
    * * @return String
    * */
        @AuraEnabled
        public String strItemNumber{get;set;}
        /**
    * * @description Billing Document Number of Document
    * * @return String
    * */
        @AuraEnabled
        public string strBillingDocNumber{get;set;}
         /**
    * * @description language of Document
    * * @return String
    * */
        @AuraEnabled
        public string strDocLanguage{get;set;}

    }
    
}