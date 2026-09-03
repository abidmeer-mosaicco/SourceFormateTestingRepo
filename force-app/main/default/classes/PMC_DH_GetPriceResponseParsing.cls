/**
* @description : class for the methods that will be used for PriceInfo
* @author      : Krishan Jangir
* @last modified on  : 02-22-2024
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
public with sharing class PMC_DH_GetPriceResponseParsing {
    static final Integer INT_STATUSCODE200 = 200;
    static final Integer INT_STATUSCODE201 = 201;
    static final Integer INT_STATUSCODE500 = 500;
    static final List<Integer> LISTINT_SUCCESSCODES = new List<Integer>{INT_STATUSCODE200,INT_STATUSCODE201};
    public static final String TEST_EXCEPTION_MESSAGE = 'Test Error';
    public static boolean throwUsersTestException = false;
        
        
    

    /**
    * @description 
    * @author Digital Hub | 08-02-2023 
    * @param cartId 
    * @return Map<String, PMC_DH_PriceInfoWrapper> 
    **/
    public static Map<String,PMC_DH_PriceInfoWrapper>  getPriceInfo(WebCart cartId){
        List<WebCart> webCarts=new List<WebCart>();
        webCarts.add(cartId);
        HttpResponse response;
            Map<String,PMC_DH_PriceInfoWrapper> mapOfListPrices;
            String strInterface = 'ProductsExternalPricing';
            PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(strInterface); 
            String strEndpoint = strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c;
            response=PMC_DH_GetPriceQuoteService.makeCallOutRequest(webCarts);
            PMC_DH_LoggingUtils.parseJSONGetPriceInterface(webCarts,response,strEndpoint);
            if(LISTINT_SUCCESSCODES.contains(response.getStatusCode())){
                
                Map<String,Object> jsonResponse = (Map<String, Object>)((Map<String, Object>)((Map<String, Object>)JSON.deserializeUntyped(response.getBody())).get('HeaderSet')).get('Header');
                mapOfListPrices=new Map<String,PMC_DH_PriceInfoWrapper>();
        
        List<Object> lstPrcCondTemp = (List<Object>)jsonResponse.get('Price_CondSet');
        Map<String, Object> mapPriceCondSet = (Map<String,Object>)lstPrcCondTemp[0];
        List<Object> lstPriceCond = (List<Object>)mapPriceCondSet.get('Price_Cond');
        
                

        List<PMC_CPQ_IntegrationFieldMap__mdt> lstPriceCondMap = [select MasterLabel,PMC_CPQ_DataType__c,PMC_CPQ_ApexAPIName__c,PMC_CPQ_SFObject__c,  PMC_CPQ_AttributeKey__c from PMC_CPQ_IntegrationFieldMap__mdt where (PMC_CPQ_SFObject__c = 'Price_Cond' AND PMC_CPQ_IsLookup__c = false ) WITH SECURITY_ENFORCED order by MasterLabel ASC];
        Map<String, String> mapPriceCond = new Map<String, String>();//map of CondType and Apex API Name
        Map<String, String> mapDataTypePrcCond = new Map<String, String>();
        for(PMC_CPQ_IntegrationFieldMap__mdt priceCondLine: lstPriceCondMap){
                mapPriceCond.put(priceCondLine.PMC_CPQ_AttributeKey__c, priceCondLine.PMC_CPQ_ApexAPIName__c);
                mapDataTypePrcCond.put(priceCondLine.PMC_CPQ_AttributeKey__c, priceCondLine.PMC_CPQ_DataType__c);
        }

        Map<String, Object> mapResponseLine = new Map<String, Object>();

      
        PMC_DH_PriceInfoWrapper prcWrap;
        for(Object responseKey: lstPriceCond){
                mapResponseLine = (Map<String, Object>)responseKey;
            if((String)mapResponseLine.get('CondType') == 'ZLST'){
                prcWrap=new PMC_DH_PriceInfoWrapper();
                prcWrap.strItemNumber=(String)mapResponseLine.get('ItmNumber');
                prcWrap.strPrice=(String)mapResponseLine.get('CondValue');
                prcWrap.strCurrency=(String)mapResponseLine.get('Currency');
                mapOfListPrices.put(prcWrap.strItemNumber,prcWrap);
            }
    }
            }
            return mapOfListPrices;
        }
    
    private static void generateCartItemMap(Map<String,List<CartItem>> mapSkuToCartItem,List<CartItem> lstCartitems) {
        for(CartItem objCartItem : lstCartitems) 
        {
            if(!mapSkuToCartItem.containsKey(objCartItem.Product2.StockKeepingUnit)){
                mapSkuToCartItem.put(objCartItem.Product2.StockKeepingUnit,new List<CartItem>());
            }
            mapSkuToCartItem.get(objCartItem.Product2.StockKeepingUnit).add(objCartItem);
        }
    }
    
    
    /*************************************************************************
* @method Name  : convertPriceInfoToResponseWrapper
* @description : Method to convert Price Info To Response Wrapper
* @param strCartId
* @return  PMC_DH_PricingDetailWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_PricingDetailWrapper convertPriceInfoToResponseWrapper(String strCartId)
    {
        PMC_DH_PricingDetailWrapper objPricingDetailWrapper = new PMC_DH_PricingDetailWrapper();
        try{
            //GDASF-15432
            PMC_DH_RequestForQuoteHelper.PMC_DH_SalesAreaForCartWrapper salesAreaCartWrapper=PMC_DH_RequestForQuoteHelper.getSalesAreaForCart(strCartId);
            PMC_DH_RequestForQuoteHelper.PMC_DH_SalesAreaForCartWrapper salesAgreementWrapper=PMC_DH_SalesAgreementUtils.updateSalesAgreementId(strCartId);         
            if(salesAreaCartWrapper.boolIsPriceEnabled==false && salesAgreementWrapper.boolIsPriceEnabled != null){
                objPricingDetailWrapper.boolIsPriceEnabled=false;
            } 
            else if (salesAreaCartWrapper.boolIsPriceEnabled==true && salesAgreementWrapper.boolIsPriceEnabled != null){
                objPricingDetailWrapper.boolIsPriceEnabled=true;
                PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();          
                WebCart objWebCart = [Select Id,PMC_DH_GetPriceCallComplete__c from WebCart where Id =: strCartId WITH USER_MODE];               
                Map<String,PMC_DH_PriceInfoWrapper> mapOfListPrices = getPriceInfo(objWebCart);
                List<CartItem> lstCartitems = [Select id,Quantity,Product2.StockKeepingUnit,Product2.Name, PMC_DH_UnitofMeasure__c, PMC_DH_RequestedShipmentDate__c,PMC_DH_ShipTo__c,PMC_DH_PlantShipFrom__c, PMC_DH_Incoterms__c, PMC_DH_DeliveryMode__c, PMC_DH_DeliveryPONumber__c, PMC_DH_Frequency__c, PMC_DH_POIncrementBy__c, CurrencyIsoCode, TotalLineAmount, PMC_DH_Number__c from CartItem 
                                            where cartId=:strCartId WITH USER_MODE];
                if(mapOfListPrices==null){
                    getVolumeperSKU(objPricingDetailWrapper,lstCartitems); //added GPT-31746
                    return objPricingDetailWrapper;
                }
                Map<String,List<CartItem>> mapSkuToCartItem = new Map<String,List<CartItem>>();     
                generateCartItemMap(mapSkuToCartItem,lstCartitems);               
            Map<String,PMC_DH_OrderManagementController.PMC_DH_PriceQuantityWrapper> mapSkuPriceQuantityWrapper = new Map<String,PMC_DH_OrderManagementController.PMC_DH_PriceQuantityWrapper>();
            mapSkuPriceQuantityWrapper=getMapPriceData(lstCartitems,mapOfListPrices);
            objPricingDetailWrapper.strCurrencyIsoCode = mapOfListPrices.get(String.valueOf(lstCartitems[0].PMC_DH_Number__c)).strCurrency;
            Decimal decTotalPrice = 0;
            Set<string> setProdSku = mapSkuToCartItem.keyset();
            List<PMC_DH_PricingDetailWrapper.PMC_DH_PricingSummaryWrapper> lstPriceSummary = new List<PMC_DH_PricingDetailWrapper.PMC_DH_PricingSummaryWrapper>();
            for(String strSku : setProdSku){
				List<PMC_DH_PricingDetailWrapper.PMC_DH_CartLineItemWrapper> lstCartLineItem = new List<PMC_DH_PricingDetailWrapper.PMC_DH_CartLineItemWrapper>();
                List<CartItem> lstCartItem = mapSkuToCartItem.get(strSku);
                PMC_DH_PricingDetailWrapper.PMC_DH_PricingSummaryWrapper objPriceSummary = new PMC_DH_PricingDetailWrapper.PMC_DH_PricingSummaryWrapper();
                objPriceSummary.strProductName = lstCartItem[0].Product2.Name;
                objPriceSummary.strProductSKU = lstCartItem[0].Product2.StockKeepingUnit;
                    //objPriceSummary.strUOM = getUnitOfMeasureValue(lstCartItem[0].Product2.PMC_CPQ_QuantityUnitOfMeasure__c);
                    objPriceSummary.strUOM = getUnitOfMeasureValue(lstCartItem[0].PMC_DH_UnitofMeasure__c);//Added as part of GPT-16863
                    PMC_DH_OrderManagementController.PMC_DH_PriceQuantityWrapper objPriceQuantityWrapper=mapSkuPriceQuantityWrapper.get(strSku);
                    objPriceSummary.intQuantity=Long.Valueof(String.valueOf(lstCartItem[0].Quantity)); //added GPT-31746
                    if(objPriceQuantityWrapper.intQuantity!=null) //added GPT-31746
                    {
                objPriceSummary.intQuantity = objPriceQuantityWrapper.intQuantity;
                objPriceSummary.decPrice = objPriceQuantityWrapper.decPrice.setScale(2, RoundingMode.HALF_UP);
                decTotalPrice = decTotalPrice + objPriceSummary.decPrice;
                objPriceSummary.lstCartLineItem = getLstCartLineItem(lstCartItem);
                    }
                lstPriceSummary.add(objPriceSummary);
            }
            objPricingDetailWrapper.decTotalPrice = decTotalPrice;
            objPricingDetailWrapper.lstPriceSummary = lstPriceSummary;
                objPricingDetailWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, 'PriceInfo'); 
                        }
        }catch(Exception ex){
            objPricingDetailWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL); //changes as part of GDASF-19642
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return objPricingDetailWrapper;
    }
    
    private static void getVolumeperSKU(PMC_DH_PricingDetailWrapper objPricingDetailWrapper,List<CartItem> lstCartitems)  //added GPT-31746
    { PMC_DH_PricingDetailWrapper.PMC_DH_PricingSummaryWrapper  subWrapper;
        List<PMC_DH_PricingDetailWrapper.PMC_DH_PricingSummaryWrapper> lstPriceDetail=new List<PMC_DH_PricingDetailWrapper.PMC_DH_PricingSummaryWrapper>();
        for(CartItem cartI:lstCartitems)
        {
            subWrapper=new PMC_DH_PricingDetailWrapper.PMC_DH_PricingSummaryWrapper();
            subWrapper.intQuantity=Long.valueof(String.valueOf(cartI.Quantity));
            subWrapper.strProductSKU=cartI.Product2.StockKeepingUnit;
            subWrapper.strProductName=cartI.Product2.Name;
            lstPriceDetail.add(subWrapper);
        }
        objPricingDetailWrapper.lstPriceSummary=lstPriceDetail;
        objPricingDetailWrapper.statusCodeMessage=PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, 'PriceInfo'); 


    }
    
private static Map<String,PMC_DH_OrderManagementController.PMC_DH_PriceQuantityWrapper> getMapPriceData(List<CartItem> lstCartitems,Map<String,PMC_DH_PriceInfoWrapper> mapOfListPrices )
{
    Map<String,PMC_DH_OrderManagementController.PMC_DH_PriceQuantityWrapper> mapSkuPriceQuantityWrapper = new Map<String,PMC_DH_OrderManagementController.PMC_DH_PriceQuantityWrapper>();

    for(CartItem objCartItem : lstCartitems){
        if(!mapSkuPriceQuantityWrapper.containsKey(objCartItem.Product2.StockKeepingUnit)){
            mapSkuPriceQuantityWrapper.put(objCartItem.Product2.StockKeepingUnit,new PMC_DH_OrderManagementController.PMC_DH_PriceQuantityWrapper());
        }
        PMC_DH_OrderManagementController.PMC_DH_PriceQuantityWrapper objPriceQuantityWrapper=mapSkuPriceQuantityWrapper.get(objCartItem.Product2.StockKeepingUnit);
            if(objCartItem.Quantity != null) {
                objPriceQuantityWrapper.intQuantity = objPriceQuantityWrapper.intQuantity + objCartItem.Quantity.longValue();//GDASF-10697->Integer.valueOf()
            }
        PMC_DH_PriceInfoWrapper objPriceInfoWrapper = mapOfListPrices.get(String.valueOf(objCartItem.PMC_DH_Number__c));
        objCartItem.SalesPrice = Decimal.valueOf(objPriceInfoWrapper.strPrice);
        objCartItem.TotalPrice = objCartItem.Quantity * objCartItem.SalesPrice;
        objPriceQuantityWrapper.decPrice = objPriceQuantityWrapper.decPrice + objCartItem.TotalPrice;
        //objPriceQuantityWrapper.decPrice = objPriceQuantityWrapper.decPrice.setScale(2, RoundingMode.HALF_UP);
        mapSkuPriceQuantityWrapper.put(objCartItem.Product2.StockKeepingUnit,objPriceQuantityWrapper);
    }
    return mapSkuPriceQuantityWrapper;
    }
    
    private static List<PMC_DH_PricingDetailWrapper.PMC_DH_CartLineItemWrapper> getLstCartLineItem(List<CartItem> lstCartItem){
        List<PMC_DH_PricingDetailWrapper.PMC_DH_CartLineItemWrapper> lstCartLineItem = new List<PMC_DH_PricingDetailWrapper.PMC_DH_CartLineItemWrapper>();
        for(CartItem objCartItem : lstCartitem){
            PMC_DH_PricingDetailWrapper.PMC_DH_CartLineItemWrapper objCartLineItem = new PMC_DH_PricingDetailWrapper.PMC_DH_CartLineItemWrapper();
            objCartLineItem.strcartItemId = objCartItem.Id;
            objCartLineItem.decPrice = objCartItem.SalesPrice.setScale(2, RoundingMode.HALF_UP);
            lstCartLineItem.add(objCartLineItem);
        }
        return lstCartLineItem;
    }

    /**
     * @description  wrapper class for Price Info
     * @author Krishan
     * @since 08-02-2023
     */
    public class PMC_DH_PriceInfoWrapper{
        /**
     * @description Item Number
     * @return String
     */
        public string strItemNumber{get;set;}
        /**
     * @description Price
     * @return String
     */
        public string strPrice{get;set;}
        /**
     * @description Currency
     * @return String
     */
        public string strCurrency{get;set;}
    }


/*************************************************************************
* @method Name  : getPricingSummaryForQuote
* @description : Method to get Pricing Summary For Quote
* @param strQuoteId
* @return PMC_DH_PricingDetailWrapper 
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_PricingDetailWrapper getPricingSummaryForQuote(String strQuoteId)
    {
        PMC_DH_PricingDetailWrapper objPricingDetailWrapper = new PMC_DH_PricingDetailWrapper();
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            Map<String,List<SBQQ__QuoteLine__c>> mapSkuToQuoteLine = new Map<String,List<SBQQ__QuoteLine__c>>();
            List<SBQQ__QuoteLine__c> lstQuoteLines = [SELECT Id, CurrencyIsoCode, SBQQ__Quote__c, SBQQ__Quantity__c, SBQQ__Product__r.Id, SBQQ__Product__r.Name, SBQQ__Product__r.StockKeepingUnit, PMC_CPQ_UnitofMeasure__c, PMC_CPQ_CustomerPrice__c, PMC_CPQ_LineTotalPrice__c,PMC_CPQ_FinalPricePerTonne__c,PMC_CPQ_QuoteRecordType__c
													  FROM SBQQ__QuoteLine__c
													  WHERE SBQQ__Quote__c=:strQuoteId WITH SYSTEM_MODE];
            
            for(SBQQ__QuoteLine__c objQuoteLine : lstQuoteLines) 
            {
                if(!mapSkuToQuoteLine.containsKey(objQuoteLine.SBQQ__Product__r.StockKeepingUnit)){
                    mapSkuToQuoteLine.put(objQuoteLine.SBQQ__Product__r.StockKeepingUnit,new List<SBQQ__QuoteLine__c>());
                }
                mapSkuToQuoteLine.get(objQuoteLine.SBQQ__Product__r.StockKeepingUnit).add(objQuoteLine);
            }

            Map<String,PMC_DH_OrderManagementController.PMC_DH_PriceQuantityWrapper> mapSkuPriceQuantityWrapper = new Map<String,PMC_DH_OrderManagementController.PMC_DH_PriceQuantityWrapper>();
            for(SBQQ__QuoteLine__c objQuoteLine : lstQuoteLines){
                if(!mapSkuPriceQuantityWrapper.containsKey(objQuoteLine.SBQQ__Product__r.StockKeepingUnit)){
                    mapSkuPriceQuantityWrapper.put(objQuoteLine.SBQQ__Product__r.StockKeepingUnit,new PMC_DH_OrderManagementController.PMC_DH_PriceQuantityWrapper());
                }
                PMC_DH_OrderManagementController.PMC_DH_PriceQuantityWrapper objPriceQuantityWrapper=mapSkuPriceQuantityWrapper.get(objQuoteLine.SBQQ__Product__r.StockKeepingUnit);
                PMC_DH_OrderManagementUtil.updatePriceAndQuantity(objPriceQuantityWrapper, objQuoteLine);
                mapSkuPriceQuantityWrapper.put(objQuoteLine.SBQQ__Product__r.StockKeepingUnit,objPriceQuantityWrapper);
            }
			
            objPricingDetailWrapper.strCurrencyIsoCode = lstQuoteLines[0].CurrencyIsoCode;
            Decimal decTotalPrice = 0;
            Set<string> setProdSku = mapSkuToQuoteLine.keyset();
            List<PMC_DH_PricingDetailWrapper.PMC_DH_PricingSummaryWrapper> lstPriceSummary = new List<PMC_DH_PricingDetailWrapper.PMC_DH_PricingSummaryWrapper>();
            for(String strSku : setProdSku){
                List<SBQQ__QuoteLine__c> lstQuoteLine = mapSkuToQuoteLine.get(strSku);
                PMC_DH_PricingDetailWrapper.PMC_DH_PricingSummaryWrapper objPriceSummary = new PMC_DH_PricingDetailWrapper.PMC_DH_PricingSummaryWrapper();
                objPriceSummary.strProductName = lstQuoteLine[0].SBQQ__Product__r.Name;
                objPriceSummary.strProductSKU = lstQuoteLine[0].SBQQ__Product__r.StockKeepingUnit;
                objPriceSummary.strUOM = getUnitOfMeasureValue(lstQuoteLine[0].PMC_CPQ_UnitofMeasure__c);//Added as part of GPT-16863
                PMC_DH_OrderManagementController.PMC_DH_PriceQuantityWrapper objPriceQuantityWrapper=mapSkuPriceQuantityWrapper.get(strSku);
                objPriceSummary.intQuantity = objPriceQuantityWrapper.intQuantity;
                objPriceSummary.decPrice = objPriceQuantityWrapper.decPrice.setScale(2, RoundingMode.HALF_UP);//Added as part of GPT-16862
                decTotalPrice = decTotalPrice + objPriceQuantityWrapper.decPrice.setScale(2, RoundingMode.HALF_UP);//Added as part of GPT-16862
                objPriceSummary.lstQuoteLine = PMC_DH_OrderManagementUtil.getLstQuoteLine(lstQuoteLine);
                lstPriceSummary.add(objPriceSummary);
            }
            objPricingDetailWrapper.decTotalPrice = decTotalPrice;
            objPricingDetailWrapper.lstPriceSummary = lstPriceSummary;
            objPricingDetailWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, 'PriceInfo'); 
            
            
        }catch(Exception ex){
            objPricingDetailWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL); //changes as part of GDASF-19642
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
    }
        return objPricingDetailWrapper;

    }

    /*************************************************************************
* @method Name  : getUnitOfMeasureValue
* @description : Method to get Unit Of Measure Value
* @param strSapApiName
* @return String 
*****************************************************************************/
    public static String getUnitOfMeasureValue(String strSapApiName){
        List<PMC_DH_UnitConversionMapping__mdt> lstUnitConversionMapping = [SELECT Id, MasterLabel, DeveloperName, PMC_DH_SAPAPIName__c, PMC_DH_MDAPIName__c
                                                                            FROM PMC_DH_UnitConversionMapping__mdt WITH USER_MODE];
        String strMdApiName = '';
        for(PMC_DH_UnitConversionMapping__mdt objUnitConversionMapping : lstUnitConversionMapping){
            if(objUnitConversionMapping.PMC_DH_SAPAPIName__c == strSapApiName){
                strMdApiName = objUnitConversionMapping.PMC_DH_MDAPIName__c;
                break;
            }
        }

        String strUnitOfMeasureValue = '';
        if(String.isNotBlank(strMdApiName)){
            strUnitOfMeasureValue = System.Label.get('', strMdApiName , UserInfo.getLocale());
        }
        return strUnitOfMeasureValue;
    }
}