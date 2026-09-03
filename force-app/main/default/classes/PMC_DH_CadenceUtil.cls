/** 
* @description Class for get Cadence Records
* @author Ajeet
* @last modified on 
* @last modified by 
* Created On       :2023-Nov-16
**/
public without sharing class PMC_DH_CadenceUtil {
    /*************************************************************************
* @method Name  : createCadence
* @description  : Method to create cadence record
* @param 		  strQuoteId
* @param 		  boolIsContractPeriodChanged
* @return         PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper 
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper createCadence(String strQuoteId, Boolean boolIsContractPeriodChanged){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        try{
            List<SBQQ__QuoteLine__c> lstQuoteLine = [select id,SBQQ__Quote__c,PMC_CPQ_IsQuantityUpdated__c, SBQQ__Quantity__c, SBQQ__Quote__r.PMC_CPQ_IsContractPeriodChanged__c, SBQQ__Quote__r.name, SBQQ__Quote__r.PMC_CPQ_LastContractStart__c, 
                                                    SBQQ__Quote__r.PMC_CPQ_LastContractEnd__c, SBQQ__Quote__r.PMC_CPQ_QuantityChangedCount__c, SBQQ__Quote__r.PMC_CPQ_ContractPeriod__c, SBQQ__Quote__r.PMC_CPQ_ContractStart__c, SBQQ__Quote__r.PMC_CPQ_ContractEnd__c   
                                                    from SBQQ__QuoteLine__c where SBQQ__Quote__c=: strQuoteId WITH SECURITY_ENFORCED];
            
            // added by Nikhilesh as part of GDASF-19031
            List<PMC_CPQ_Cadence__c> lstCadence = [select id, PMC_CPQ_QuoteLine__c from PMC_CPQ_Cadence__c where PMC_CPQ_QuoteLine__r.SBQQ__Quote__c =: strQuoteId WITH SECURITY_ENFORCED];
            // condition 1: contract period has changed and cadence records exist
            // action: delete existing cadence records, create new ones based on date range
            if(boolIsContractPeriodChanged && !lstCadence.isEmpty()){
                PMC_CPQ_CadenceController.deleteCadenceRecord(lstCadence);
                PMC_CPQ_CadenceController.createCadenceRecord(lstQuoteLine);
            }
            // condition 2: no cadence record exists
            // action: create cadence records based on date range
            else if(lstCadence.isEmpty()){
               PMC_CPQ_CadenceController.createCadenceRecord(lstQuoteLine); 
            }
            // end of changes as part of GDASF-19031
            
            statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, PMC_DH_ConstantClass.CADENCE);
        }catch(Exception ex){
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
            statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL); 
        }
        return statusCodeMessage;
    }	
     
    /*************************************************************************
* @method Name  : getCadenceRecords
* @description  : Method to get cadence record along with their quoteId
* @param 		  strQuoteId
* @return         PMC_DH_QuoteAndCadenceLstResponseWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_QuoteAndCadenceLstResponseWrapper getCadenceRecords(String strQuoteId){
        PMC_DH_QuoteAndCadenceLstResponseWrapper quoteCadenceRecordsWrapper = new PMC_DH_QuoteAndCadenceLstResponseWrapper();
        List<PMC_DH_QuoteAndCadenceWrapper> lstQuoteAndCadenceWrapper = new List<PMC_DH_QuoteAndCadenceWrapper>();
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            List<SBQQ__QuoteLine__c> lstQuoteLine = [SELECT Id, Name, SBQQ__Quote__c, SBQQ__Product__r.Name, PMC_CPQ_ShipTo__r.Name, 
                                                    PMC_CPQ_ShipTo__r.ShippingStreet, PMC_CPQ_ShipTo__r.ShippingCity, PMC_CPQ_ShipTo__r.ShippingState, 
                                                    PMC_CPQ_ShipTo__r.ShippingCountry, toLabel(PMC_CPQ_ModeofTransportation__c), toLabel(PMC_CPQ_Incoterms1__c), 
                                                    PMC_CPQ_ProductLocation__r.Name,  SBQQ__Quantity__c, SBQQ__Quote__r.SBQQ__DocumentStatus__c, SBQQ__Quote__r.PMC_CPQ_ContractStart__c, SBQQ__Quote__r.PMC_CPQ_ContractEnd__c, 
                                                    (SELECT Id, PMC_CPQ_RequestedDate__c, PMC_CPQ_RequestedQuantity__c FROM Cadences__r ORDER BY PMC_CPQ_RequestedDate__c) 
                                                    from SBQQ__QuoteLine__c where SBQQ__Quote__c = :strQuoteId WITH SECURITY_ENFORCED];
            if(!lstQuoteLine.isEmpty()){
                for(SBQQ__QuoteLine__c quoteLine:lstQuoteLine){
                    PMC_DH_QuoteAndCadenceWrapper quoteAndCadenceWrapper = new PMC_DH_QuoteAndCadenceWrapper();
                    quoteAndCadenceWrapper.strQuoteLineId = quoteLine.Id;
                    quoteAndCadenceWrapper.strProductName = quoteLine.SBQQ__Product__r.Name;
                    quoteAndCadenceWrapper.strShipTo = quoteLine.PMC_CPQ_ShipTo__r.Name + ' ' + quoteLine.PMC_CPQ_ShipTo__r.ShippingStreet + ' ' + quoteLine.PMC_CPQ_ShipTo__r.ShippingCity + ' ' + quoteLine.PMC_CPQ_ShipTo__r.ShippingState + ' ' + quoteLine.PMC_CPQ_ShipTo__r.ShippingCountry;
                    quoteAndCadenceWrapper.strDeliveryInfo = quoteLine.PMC_CPQ_ModeofTransportation__c + '-' + quoteLine.PMC_CPQ_Incoterms1__c;
                    quoteAndCadenceWrapper.strShipFrom = quoteLine.PMC_CPQ_ProductLocation__r.Name;
                    quoteAndCadenceWrapper.intTotalQuantity = quoteLine.SBQQ__Quantity__c != null?quoteLine.SBQQ__Quantity__c.longValue():0;//GDASF-10697 - Integer.valueOf()
                    quoteAndCadenceWrapper.strStartDate = String.valueOf(quoteLine.SBQQ__Quote__r.PMC_CPQ_ContractStart__c);
                    quoteAndCadenceWrapper.strEndDate = String.valueOf(quoteLine.SBQQ__Quote__r.PMC_CPQ_ContractEnd__c);
                    List<PMC_DH_CadenceWrapper> lstCadenceWrapper = new List<PMC_DH_CadenceWrapper>();
                    getCadenceData(quoteLine.Cadences__r,lstCadenceWrapper);
                    quoteAndCadenceWrapper.lstCadence = lstCadenceWrapper;
                    quoteAndCadenceWrapper.boolCadenceAvailable = false;
                    if(!lstCadenceWrapper.isEmpty()){
                        quoteAndCadenceWrapper.boolCadenceAvailable = true;
                    }
                    lstQuoteAndCadenceWrapper.add(quoteAndCadenceWrapper);
                }
            }
            quoteCadenceRecordsWrapper.lstQuoteCadenceRecords = lstQuoteAndCadenceWrapper;
            quoteCadenceRecordsWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, PMC_DH_ConstantClass.CADENCE);
        }catch(Exception ex){
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
            quoteCadenceRecordsWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.FAILURE_STATUS_CODE, PMC_DH_ConstantClass.ALL); 
            //throw new AuraHandledException(ex.getMessage());
        }
        return quoteCadenceRecordsWrapper;
        //return lstQuoteAndCadenceWrapper;
    }
    /*************************************************************************
* @method Name  : getCadenceData
* @description  : Method to get cadence record
* @param 		  lstCadence
* @param          lstCadenceWrapper
*****************************************************************************/
    private static void getCadenceData(List<PMC_CPQ_Cadence__c> lstCadence, List<PMC_DH_CadenceWrapper> lstCadenceWrapper){
        if(!lstCadence.isEmpty()){
            for(PMC_CPQ_Cadence__c cadence:lstCadence){
                PMC_DH_CadenceWrapper cadenceWrapper = new PMC_DH_CadenceWrapper();
                cadenceWrapper.strCadenceId = cadence.Id;
                cadenceWrapper.intQuantity = cadence.PMC_CPQ_RequestedQuantity__c != null?cadence.PMC_CPQ_RequestedQuantity__c.longValue():0;//GDASF-10697 - Integer.valueOf()
                cadenceWrapper.strMonth = String.valueOf(cadence.PMC_CPQ_RequestedDate__c.month()+'/'+cadence.PMC_CPQ_RequestedDate__c.year());
                lstCadenceWrapper.add(cadenceWrapper);
            }
        }
    }
    /*************************************************************************
* @method Name  : updateCadence
* @description  : Method to update cadence record
* @param          lstCadenceWrapper
* @return         PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper updateCadence(List<PMC_DH_CadenceWrapper> lstCadenceWrapper){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        try{
            if(!lstCadenceWrapper.isEmpty()){
                List<PMC_CPQ_Cadence__c> lstCadence = new List<PMC_CPQ_Cadence__c>();
                for(PMC_DH_CadenceWrapper cadenceWrp: lstCadenceWrapper){
                    PMC_CPQ_Cadence__c cadence = new PMC_CPQ_Cadence__c();
                    cadence.Id = cadenceWrp.strCadenceId;
                    cadence.PMC_CPQ_RequestedQuantity__c = cadenceWrp.intQuantity;
                    lstCadence.add(cadence);
                }
                if(Schema.sObjectType.PMC_CPQ_Cadence__c.isUpdateable()){
                    update lstCadence;
                }
            }
            statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, PMC_DH_ConstantClass.CADENCE);
        }catch(Exception ex){
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
            statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.FAILURE_STATUS_CODE, PMC_DH_ConstantClass.ALL); 
            return statusCodeMessage;
        }
        return statusCodeMessage;
    }

/**
* @description       : Wrapper for Quote and Cadence Records List and response status
* @author            : @manishasingh9
* @Created on        : 2023-Dec-23
**/
public class PMC_DH_QuoteAndCadenceLstResponseWrapper{
    /**
    * @description List of Quote and Cadence Records
    * @return List<PMC_DH_QuoteAndCadenceWrapper>
    */
    @AuraEnabled
    public List<PMC_DH_QuoteAndCadenceWrapper> lstQuoteCadenceRecords { get; set; }

     /**
     * @description Status Code and message
     * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
     */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}

}
/**
* @description       : Wrapper for Quote and Cadence Records
* @author            : @Ajeet
* @Created on        : 2023-Nov-16
**/
public class PMC_DH_QuoteAndCadenceWrapper{
    /**
* @description QuoteLine Id
* @return String
*/
    @AuraEnabled
    public String strQuoteLineId { get; set; }
    /**
* @description Product on QuoteLine
* @return String
*/
    @AuraEnabled
    public String strProductName { get; set; }
    /**
* @description Ship to Address
* @return String
*/
    @AuraEnabled
    public String strShipTo { get; set; }
    /**
* @description Delivery information
* @return String
*/
    @AuraEnabled
    public String strDeliveryInfo { get; set; }
    /**
* @description Ship From loaction
* @return String
*/
    @AuraEnabled
    public String strShipFrom { get; set; }
    /**
* @description Quantity of quote line item
* @return Long
*/
        @AuraEnabled
        public Long intTotalQuantity { get; set; }
    /**
* @description Ship From loaction
* @return String
*/
    @AuraEnabled
    public String strStartDate { get; set; }
    /**
* @description Ship From loaction
* @return String
*/
    @AuraEnabled
    public String strEndDate { get; set; }
    /**
* @description Flag for Cadence present or not
* @return Boolean
*/
    @AuraEnabled
    public Boolean boolCadenceAvailable { get; set; }
    /**
* @description List of Cadence
* @return List<PMC_DH_CadenceWrapper>
*/
    @AuraEnabled
    public List<PMC_DH_CadenceWrapper> lstCadence { get; set; }
}

/**
* @description       : Wrapper for Quote and Cadence Records
* @author            : @Ajeet
* @Created on        : 2023-Nov-16
**/
public class PMC_DH_CadenceWrapper{
    /**
* @description Cadence Id
* @return String
*/
    @AuraEnabled
    public String strCadenceId { get; set; }
    /**
* @description Cadence Month
* @return String
*/
    @AuraEnabled
    public String strMonth { get; set; }
    /**
* @description Cadence quantity
* @return Long
*/
        @AuraEnabled
        public Long intQuantity { get; set; }
}
}