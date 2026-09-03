/**
* @description       : Controller for Rejecting quote
* @author            : @Lohitha
* @last modified on  : 03-14-2024
**/
public without sharing class PMC_DH_QuoteMgmtActionController {
    /*************************************************************************
* @method Name  : getCancelReasons
* @description  : Method to get Cancel reasons for Quote
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/ 
    @AuraEnabled
    public static List<PMC_DH_PicklistWrapper> getCancelReasons(){
        List<PMC_DH_PicklistWrapper>  lstCancelReasons;
        try{
            lstCancelReasons=getModalReasons('Cancelled');
            
        }
        Catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        return lstCancelReasons;
    }
    /*************************************************************************
* @method Name  : updateCancelQuote
* @description  : Method to update Quote when cancelled
*@param         modelWrapper
* @return       : PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*****************************************************************************/ 
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper updateQuoteStatus(PMC_DH_ModelWrapper modelWrapper){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        try {
            SBQQ__Quote__c objQuote= new SBQQ__Quote__c(Id=modelWrapper.strQuoteId);
            Set<String> setStatus=new Set<String>{'Cancelled','Rejected'};
                Map<String,String> mapSummaryReason=new Map<String,String>{
                    'Accepted' => 'Accepted',
                        'Rejected' => 'Rejected',
                        'Cancelled' => 'Rejected'
                        };
                            if(mapSummaryReason.containsKey(modelWrapper.strStatus))
                        {
                            objQuote.PMC_DH_Summary_Reason__c=modelWrapper.strStatus;
                            objQuote.SBQQ__Status__c=mapSummaryReason.get(modelWrapper.strStatus);
                        }
            if(setStatus.contains(modelWrapper.strStatus)){
                PMC_DH_RequestForQuoteUtil.updateRejectedReason(modelWrapper,objQuote);
                }
                else{
               PMC_DH_RequestForQuoteUtil.updateAcceptedQuote(objQuote);
            }
            if(Schema.sObjectType.SBQQ__Quote__c.isUpdateable()){
                update objQuote;
                result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, 'QuoteDetailUpdate');
               }
        }
            catch (System.DMLException ex) {
                for (Integer i = 0; i < ex.getNumDml(); i++) {
                String strMsg=ex.getDmlMessage(i);
                if(strMsg==System.Label.PMC_CPQ_QuoteExpirationValidationMessage){
                    result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.ERROR_STATUS_CODE, 'UpdateQuote');
                }
                else{
                    result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL); 
                }
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
            }
            }
                return result;
    }
    
    /**
* @description Wrapper class for Model PopUp
* @author @mhumerarahath 
* 
**/ 
    public with sharing class PMC_DH_ModelWrapper{
        /**
* @description  Id of Quote
* @return String
*/
        @AuraEnabled
        public string strQuoteId{get;set;}
        /**
* @description  Selected Reason of Quote
* @return String
*/
        @AuraEnabled
        public String strSelectedReason{get;set;}
        /**
* @description  Status of Quote
* @return String
*/
        @AuraEnabled
        public String strStatus{get;set;}
        /**
* @description  Reason(Text) for Cancel/Reject
* @return String
*/
        @AuraEnabled
        public String strReason{get;set;}
    }
    
    /*************************************************************************

* @method Name  : getUpdateQuote

* @description  : Method to update Quote Detail in Wrapper

* @param         quoteUpdateWrap

* @return       : PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper

*****************************************************************************/ 
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper getUpdateQuote(PMC_DH_QuoteUpdateWrapper quoteUpdateWrap){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        SBQQ__Quote__c objQuote=new SBQQ__Quote__c();
        
        try{
            objQuote.id=quoteUpdateWrap.strQuoteId;
            
            objQuote.PMC_CPQ_ContractStart__c=Date.ValueOf(quoteUpdateWrap.datContractStartDate);
            objQuote.PMC_CPQ_ContractEnd__c=Date.valueOf(quoteUpdateWrap.datContractEndDate);
            //added as part of GDASF-19809
            object quoteWrapdata=quoteUpdateWrap;
            objQuote.PMC_CPQ_PaymentDate__c =PMC_DH_RequestForQuoteUtil.setPaymentDate(quoteWrapdata);
            objQuote.SBQQ__PaymentTerms__c=quoteUpdateWrap.strPaymentTerms;            
            objQuote.PMC_DH_PaymentMethod__c=quoteUpdateWrap.strPaymentMethods;            
            objQuote.PMC_DH_QuoteFriendlyName__c  = quoteUpdateWrap.strFriendlyName;
            objQuote.SBQQ__Status__c  = 'Request';
            if(Schema.sObjectType.SBQQ__Quote__c.isUpdateable()){
                update objQuote;
                result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, 'QuoteDetailUpdate');
                
            }
        }
        catch (Exception ex) {
            throw new AuraHandledException(ex.getLineNumber()+ex.getStackTraceString()+ex.getCause());
        }
        return result;
    } 
    
    /*************************************************************************

* @method Name  : getUpdateQuoteLineItem

* @description  : Method to update QuoteLine Details in Wrapper

* @param         quoteLineItemUpdateWrap

* @return       : PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper

*****************************************************************************/  
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper getUpdateQuoteLineItem(PMC_DH_QuoteLineUpdateWrapper quoteLineItemUpdateWrap){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        SBQQ__QuoteLine__c quoteLine = [SELECT Id,SBQQ__Quote__r.SBQQ__Account__c FROM SBQQ__QuoteLine__c Where Id=:quoteLineItemUpdateWrap.strQuoteLineItemId WITH USER_MODE];
        Map<String, String> mapSoldToShipTo = PMC_DH_QuoteManagementHelper.getShipToIdSoldToShipToJunctionIdMap(quoteLine.SBQQ__Quote__r.SBQQ__Account__c); //----->to identify sold-to changes
        try
        {
            SBQQ__QuoteLine__c quoteLineItem=new SBQQ__QuoteLine__c();
            
            quoteLineItem.Id=quoteLineItemUpdateWrap.strQuoteLineItemId;
            
            quoteLineItem.SBQQ__Quantity__c=Decimal.valueof(quoteLineItemUpdateWrap.strQuoteLineItemQuantity);
            
            //quoteLineItem.PMC_CPQ_ShipTo__c=quoteLineItemUpdateWrap.strShipTo;
            
            quoteLineItem.PMC_CPQ_SoldToShipToJunction__c=mapSoldToShipTo.get(quoteLineItemUpdateWrap.strShipTo); // added as part of quick fix
                        
            quoteLineItem.PMC_CPQ_ShipTo__c= quoteLineItemUpdateWrap.strShipTo; // added as part of quick fix
            
            quoteLineItem.PMC_CPQ_Incoterms1__c=quoteLineItemUpdateWrap.strIncoterms;
            
            quoteLineItem.PMC_CPQ_ModeofTransportation__c=quoteLineItemUpdateWrap.strDeliveryMode;
            
            quoteLineItem.PMC_CPQ_ProductLocation__c=quoteLineItemUpdateWrap.strShipFrom;
            
            quoteLineItem.PMC_CPQ_PackType__c=quoteLineItemUpdateWrap.strPackType;

            // quoteLineItem.PMC_CPQ_PackageType__c=quoteLineItemUpdateWrap.strPackageType;//Removed as part of GDASF-20003
            if(Schema.sObjectType.SBQQ__QuoteLine__c.isUpdateable()){
                Database.update (quoteLineItem,false);
                result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, 'QuoteLineDetailUpdate');
            }
        }
        catch (Exception ex) {
            throw new AuraHandledException(ex.getLineNumber()+ex.getStackTraceString()+ex.getCause());
        }
        
        return result;
        
    }

    /*************************************************************************
* @method Name  : getprod
* @description  : Method to assign connect api result
* @param         lstActiveProducts
* @param         lstInactiveProducts
*@return        :Map<String , PMC_DH_RequestForQuoteController.ConnectApiWrapper>
*****************************************************************************/
    public static Map<String , PMC_DH_RequestForQuoteController.ConnectApiWrapper> getProd(List<ConnectApi.ProductOverview> lstActiveProducts, List<Product2> lstInactiveProducts){
        Map<String , PMC_DH_RequestForQuoteController.ConnectApiWrapper> mapProductDetail=new Map<String,PMC_DH_RequestForQuoteController.ConnectApiWrapper>();
        PMC_DH_RequestForQuoteController.ConnectApiWrapper objconnectapiProduct;
        try{
            
            // get details of active products
            for(ConnectApi.ProductOverview prod:lstActiveProducts)
            {
                //assigning the product details in Wrapper
                objconnectapiProduct=new PMC_DH_RequestForQuoteController.ConnectApiWrapper(); 
                Map<String,String> mapFields=(Map<String,String>)prod.fields;
                objconnectapiProduct.strProductName=mapFields.get('Name');
                objconnectapiProduct.strProductFamily = mapFields.get('PMC_CPQ_ProductFamily__c');
                objconnectapiProduct.strProductUOM = mapFields.get('PMC_CPQ_QuantityUnitOfMeasure__c');
                objconnectapiProduct.strProductPackType = mapFields.get('PMC_CPQ_PackType__c');
                objconnectapiProduct.strSku=prod.sku;
                ConnectApi.ProductMedia media = prod.defaultImage;
                String strimageUrl=media.url;
                PMC_DH_Store_Configuration__mdt config = PMC_DH_Store_Configuration__mdt.getInstance('Default_Image_URL');
                if(strimageUrl==config.PMC_DH_Default_Image_Url__c){
                    objconnectapiProduct.strImgSrc='';
                }
                else{
                    PMC_DH_Store_Configuration__mdt configuration = PMC_DH_Store_Configuration__mdt.getInstance('Prepended_Image_Url');
                    objconnectapiProduct.strImgSrc = configuration.PMC_DH_Prepended_Image_Url__c+ media.url;
                }
                objconnectapiProduct.strProductId=prod.id;
                
                //assigning the wrapper in map based on sku
                if(!mapProductDetail.containsKey(objconnectapiProduct.strSku)){
                    mapProductDetail.put(objconnectapiProduct.strSku,objconnectapiProduct);
                }
            }
            // added by Nikhilesh as part of GDASF-17525
            // get details of inactive products
            mapProductDetail = PMC_DH_QuoteManagementHelper.getInactiveProductDetails(mapProductDetail, lstInactiveProducts);
            // end of changes added by Nikhilesh as part of GDASF-17525
        }
        catch (Exception ex) {
            throw new AuraHandledException(ex.getLineNumber()+ex.getStackTraceString()+ex.getCause());
        }
        return mapProductDetail;
    }
   
    /*************************************************************************
* @method Name  : getModalReasons
* @param        strModalType
* @description  : Method to fetch modal reasons from Metadata
* @return       : List<PMC_DH_ModalReasonList__mdt> 
*****************************************************************************/
    private static List<PMC_DH_PicklistWrapper> getModalReasons(String strModalType){
        List<PMC_DH_PicklistWrapper> lstPicklistValues=new List<PMC_DH_PicklistWrapper>();
        try{
            List<PMC_DH_ModalReasonList__mdt> lstMetaData=[SELECT id,PMC_DH_Type__c, PMC_DH_Position__c, Label, PMC_DH_Value__c,PMC_DH_Custom_Label__c from PMC_DH_ModalReasonList__mdt 
                                                           WHERE PMC_DH_Type__c=:strModalType  WITH SECURITY_ENFORCED order by PMC_DH_Position__c ASC];
            for(PMC_DH_ModalReasonList__mdt data:lstMetaData){
                PMC_DH_PicklistWrapper objData=new PMC_DH_PicklistWrapper();
                
                objData.label=System.Label.get(null, data.PMC_DH_Custom_Label__c, userinfo.getLocale());
                objData.value=data.PMC_DH_Value__c;
                lstPicklistValues.add(objData);
                
            }
        }Catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        return  lstPicklistValues;
        
    }
    /*************************************************************************
* @method Name  : getRejectReasons
* @description  : Method to get Reject reasons for Quote
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/ 
    @AuraEnabled
    public static List<PMC_DH_PicklistWrapper> getRejectReasons(){
        List<PMC_DH_PicklistWrapper>  lstRejectReasons;
        try{
            lstRejectReasons=getModalReasons('Rejected');
            
        }
        Catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        return lstRejectReasons;
    }
   
    /*************************************************************************
* @method Name  : getStatus
* @param        quoteDetails
* @description  : Method to getStatus based on Acceptance method field
* @return       : PMC_DH_QuoteStatusWrapper
*****************************************************************************/
    public static PMC_DH_QuoteStatusWrapper getStatus(SBQQ__Quote__c quoteDetails){
        // fetching status with reference to CPQ SBQQ__Status__c field maintained in a metadata and assigning it to respective values
        PMC_DH_Quote_Management_Status__mdt statusMetadata=PMC_DH_Quote_Management_Status__mdt.getInstance(quoteDetails.SBQQ__Status__c);
        PMC_DH_QuoteStatusWrapper quotestsWrapper=new PMC_DH_QuoteStatusWrapper();
        quotestsWrapper.strProgressIndicatorStatus=statusMetadata.PMC_DH_Progress_Indicator_Status__c;
        if(quoteDetails.SBQQ__Status__c=='Accepted'){
           switch on (quoteDetails.PMC_CPQ_CustomerAcceptanceMethod__c) {
                when  'Phone Call','Email','In Person','Text/Whatsapp'  {
                    quotestsWrapper.strSummaryStatus=PMC_DH_ConstantClass.DATA_USE_PURPOSE_QUOTEACCEPTED;
                }
                when 'DocuSign','Accepted by DH Customer' {
                    quotestsWrapper.strSummaryStatus=PMC_DH_ConstantClass.ACCEPTED_QUOTE;
                }
                
            }
        }
        else
        {
            quotestsWrapper.strSummaryStatus=statusMetadata.PMC_DH_Summary_Status__c;//System.label.get(null,statusMetadata.PMC_DH_StatusLabel__c,userinfo.getlocale()); 
        }
        return quotestsWrapper;
    }
    /**
     * @description Wrapper class for GetStatus
     * @author @mhumerarahath    
     */
    public with sharing class PMC_DH_QuoteStatusWrapper{
        /**
     * @description Progress Indicator Status of Quote
     * @author @mhumerarahath    
     */
        public string strProgressIndicatorStatus{get;set;}
        /**
     * @description Summary Status of Quote
     * @author @mhumerarahath    
     */
        public string strSummaryStatus{get;set;}
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

        
    }
    /*************************************************************************
* @method Name  : getRejectionReason
* @param        strRejectionReason
*@param         strRejectedReason
* @description  : Method to get Rejected reason
* @return       : String
*****************************************************************************/
public static string getRejectionReason(String strRejectionReason,String strRejectedReason){
    string strReason;
   try{
            if(String.isNotBlank(strRejectedReason) && strRejectedReason==PMC_DH_ConstantClass.REJECTION_REASON_OTHERS){
        strReason=strRejectionReason;
        }
            else if(!String.isBlank(strRejectedReason)){
                String strTemp = strRejectedReason.replace(' ','_');
                String strTransStatus = PMC_DH_ModalReasonList__mdt.getInstance(strTemp).PMC_DH_Custom_Label__c;
                strReason=System.label.get(null,strTransStatus,userinfo.getLocale());//strRejectedReason;
        }
    }
    Catch(Exception ex){
        throw new AuraHandledException(ex.getMessage());
    }
        return strReason;
}
}