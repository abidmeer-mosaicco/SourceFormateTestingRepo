/**
* @description       : Controller for fetching Quote History
* @author            : @Lohitha sai
* @Created on        : 06-30-2023
**/
public without sharing class PMC_DH_QuoteListViewController { // removed 'with sharing ' as this class is using ShipTo field
    public final static String QUOTE_RELATIVE_PATH = 'quote';
    public final static String QUOTE_NUMBER = '?quoteNumber=';
    public final static String QUOTE_ID = '?quoteId=';
    public final static String PENDING_SIGNATURE_STATUS = 'Pending Signature';
    public final static String PARTIALLY_EXECUTED_STATUS = 'Partially Executed';
    public final static String ACTION_PENDING_STATUS = 'Action Pending';
    public final static String REJECTED_STATUS = 'Rejected';
    public final static String EXPIRED_STATUS = 'Expired';
    public final static List<String> QUOTE_ACTIVESTATUS=new List<String>{'Accepted','Draft','Request','Approved','Presented'};
    

 /**
* @description   : To fetch the Quote records
* @return        : PMC_DH_QuoteListViewWrapper
* @param searchParams : Search term for filter
* @param strEffectiveAccId : Effective Account Id
* @author        : @Lohitha Sai
*/
    @AuraEnabled
        public static PMC_DH_QuoteListViewWrapper fetchQuoteRecords(QuoteSearchParameterWrapper searchParams, String strEffectiveAccId){
            PMC_DH_QuoteListViewWrapper quoteWrapper = new PMC_DH_QuoteListViewWrapper();
            try{
                PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
                List<PMC_DH_QuoteListViewWrapper.ProductDropDownWrapper> lstProductDropDownWrapper = new List<PMC_DH_QuoteListViewWrapper.ProductDropDownWrapper>();
                List<PMC_DH_QuoteListViewWrapper.QuoteInfoWrapper> lstQuoteInfoWrapper = new List<PMC_DH_QuoteListViewWrapper.QuoteInfoWrapper>();
                Set<Id> setExcludedIds = getExpiredInactiveQuoteIds(strEffectiveAccId);
                String strQuery = getQuoteSearchQuery(searchParams,strEffectiveAccId, setExcludedIds);
                String queryRes = strQuery.replace('\\', '');
                List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c>();
                lstQuote = Database.query(queryRes);
                for(SBQQ__Quote__c quote :lstQuote){ 
                    lstQuoteInfoWrapper.add(getQuoteHistoryRecords(quote,lstProductDropDownWrapper));
                    quoteWrapper.lstProductFilters=lstProductDropDownWrapper;
                }
                quoteWrapper.lstQuotes=lstQuoteInfoWrapper;
                quoteWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, 'GetQuote');
            }
            catch(Exception ex){
                quoteWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL); //changes as part of GDASF-19642
                PMC_ErrorLogClass.processException(ex); // MDErrorLog
            }
            return quoteWrapper;
        }
/**
* @description   : To fetch the Quote records
* @return        : getQuoteHistoryRecords
* @param quote 
* @param lstProductDropDownWrapper
* @author        : 
*/
    private static PMC_DH_QuoteListViewWrapper.QuoteInfoWrapper getQuoteHistoryRecords(SBQQ__Quote__c  quote, List<PMC_DH_QuoteListViewWrapper.ProductDropDownWrapper> lstProductDropDownWrapper)
    //QuoteSearchParameterWrapper searchParams, String strEffectiveAccId)
    {  // PMC_DH_QuoteListViewWrapper quoteWrapper = new PMC_DH_QuoteListViewWrapper();
        Map<String,String> mapAllLineProductIdName = new Map<String,String>();
        //List<PMC_DH_QuoteListViewWrapper.ProductDropDownWrapper> lstProductDropDownWrapper = new List<PMC_DH_QuoteListViewWrapper.ProductDropDownWrapper>();
        PMC_DH_QuoteListViewWrapper.QuoteInfoWrapper quoteInfo = new PMC_DH_QuoteListViewWrapper.QuoteInfoWrapper();
        Map<String,String> mapWithProductIdName = new Map<String,String>();
        Map<String,String> mapWithShippingIdName = new Map<String,String>();
        Set<String> setWithDeliveryModeName = new Set<String>();
        Set<String> setWithProductSKU = new Set<String>();
        quoteInfo.quoteId =quote.Id;//FE
        quoteInfo.quoteFriendlyId =quote.PMC_DH_QuoteFriendlyName__c;
        quoteInfo.quoteNumber =quote.Name;
        quoteInfo.totalQuantity =quote.PMC_CPQ_TotalQuantity__c != null?quote.PMC_CPQ_TotalQuantity__c.longValue():0;// GDASF-10697
        quoteInfo.totalPrice =quote.PMC_CPQ_SumOfLineTotalPrice__c;
        quoteInfo.currentDateTime = System.now();
        if(quote.PMC_DH_FilterStatus__c!=null)
        {
        quoteInfo.status =quote.PMC_DH_FilterStatus__c;
    }
    if(quote.PMC_DH_FilterStatus__c ==ACTION_PENDING_STATUS){
        quoteInfo.expirationDateTime =quote.PMC_CPQ_ExpiresOn__c;
    }
        quoteInfo.quoteDetailLink = QUOTE_RELATIVE_PATH+QUOTE_NUMBER+quote.Name+QUOTE_ID+quote.id;
        for(SBQQ__QuoteLine__c lineItem : quote.SBQQ__LineItems__r){
            
            getProductWrapper(mapAllLineProductIdName, lineItem, lstProductDropDownWrapper);
            if(!mapWithProductIdName.containsKey(lineItem.SBQQ__Product__c)){
                mapWithProductIdName.put(lineItem.SBQQ__Product__c,lineItem.SBQQ__Product__r.Name);
            }
            if(!mapWithShippingIdName.containsKey(lineItem.PMC_CPQ_ShipTo__c)){
                String strShipToLabel = lineItem.PMC_CPQ_ShipTo__r.Name + ' ' + lineItem.PMC_CPQ_ShipTo__r.ShippingStreet + ', ' + lineItem.PMC_CPQ_ShipTo__r.ShippingCity + ', ' + lineItem.PMC_CPQ_ShipTo__r.ShippingState + ' ' + lineItem.PMC_CPQ_ShipTo__r.ShippingPostalCode;
                mapWithShippingIdName.put(lineItem.PMC_CPQ_ShipTo__c,  strShipToLabel);
            }
            if(!setWithDeliveryModeName.contains(lineItem.PMC_CPQ_ModeofTransportation__c)){
                setWithDeliveryModeName.add(lineItem.PMC_CPQ_ModeofTransportation__c);
            }
            setWithProductSKU.add(lineItem.SBQQ__Product__r.StockKeepingUnit);
        }
        quoteInfo.setSKU = new List<String>(setWithProductSKU);
        quoteInfo.products=getProductOrShipToName(mapWithProductIdName, PMC_DH_ConstantClass.BLANK_STRING);
        quoteInfo.shipTo=getProductOrShipToName(mapWithShippingIdName, PMC_DH_ConstantClass.BLANK_STRING);
        quoteInfo.deliveryMode=getDeliveryModeName(setWithDeliveryModeName, PMC_DH_ConstantClass.BLANK_STRING);
        
        
        return quoteInfo;
    }

    
/**
 * @description method to get inactive quote
 * @author  hemant
 * @since 08-28-2023
 * @param datQuoteInactive
 * @return boolean
 */

    public static boolean getQuoteFiltered(DateTime datQuoteInactive) // if this is true then don't show that quote on history page
    {
        Boolean boolFlag=false;
        try
        {
            PMC_DH_Store_Configuration__mdt mdtQoutInac= PMC_DH_Store_Configuration__mdt.getInstance(PMC_DH_ConstantClass.QUOTE_INAC_MDT);
        
        if(datQuoteInactive!=null && mdtQoutInac.PMC_DH_QuoteInactiveExtendedDays__c!=0)
        {
        datQuoteInactive=datQuoteInactive.addDays(Integer.valueOf(mdtQoutInac.PMC_DH_QuoteInactiveExtendedDays__c));
        
        }
        else if(datQuoteInactive!=null && mdtQoutInac.PMC_DH_QuoteInactiveExtendedHours__c!=0)
        {
            datQuoteInactive=datQuoteInactive.addHours(Integer.valueOf(mdtQoutInac.PMC_DH_QuoteInactiveExtendedHours__c));
            
        }
        
        
        boolFlag=datQuoteInactive<System.now(); 
       
        }
        catch(Exception ex)
        {
             throw new AuraHandledException(ex.getMessage());
        }
        return boolFlag;
    }
    
    private static Set<Id> getExpiredInactiveQuoteIds(String strEffectiveAccId){
        Set<Id> setExcludeIdSet = new Set<Id>();
        for( SBQQ__Quote__c sQuote : [SELECT Id, PMC_DH_QuoteInactiveTime__c FROM SBQQ__Quote__c WHERE SBQQ__Account__c =: strEffectiveAccId AND (SBQQ__LineItemCount__c !=0)
                                      AND (SBQQ__Status__c = : REJECTED_STATUS OR SBQQ__Status__c=:EXPIRED_STATUS ) WITH SECURITY_ENFORCED ])
        {
            if(getQuoteFiltered(sQuote.PMC_DH_QuoteInactiveTime__c)){
                setExcludeIdSet.add(sQuote.Id);
            }
            
        }
        return setExcludeIdSet;
    }

     private static String getQuoteSearchQuery(QuoteSearchParameterWrapper searchParams, String strEffectiveAccId, set<Id> setExcludedIds){
        String strQuery = 'SELECT Id, PMC_CPQ_QuoteOrigin__c, PMC_DH_QuoteFriendlyName__c, Name, PMC_CPQ_ExpiresOn__c, PMC_CPQ_TotalQuantity__c, PMC_CPQ_SumOfLineTotalPrice__c, SBQQ__Status__c, PMC_DH_FilterStatus__c, CreatedDate,PMC_CPQ_ContractStageName__c,PMC_DH_QuoteInactiveTime__c,';
            strQuery += ' (SELECT Id, SBQQ__Product__c, toLabel(SBQQ__Product__r.Name), SBQQ__Product__r.StockKeepingUnit, SBQQ__Quantity__c, PMC_CPQ_ShipTo__c, PMC_CPQ_ShipTo__r.Name, toLabel(PMC_CPQ_ModeofTransportation__c),';
            strQuery += ' PMC_CPQ_ShipTo__r.ShippingStreet, PMC_CPQ_ShipTo__r.ShippingCity, PMC_CPQ_ShipTo__r.ShippingState, PMC_CPQ_ShipTo__r.ShippingPostalCode  FROM SBQQ__LineItems__r)';
            strQuery += ' FROM SBQQ__Quote__c WHERE SBQQ__Account__c =: strEffectiveAccId AND Id NOT IN :setExcludedIds AND  (SBQQ__LineItemCount__c !=0)';
            strQuery += ' AND (PMC_CPQ_QuoteOrigin__c= \'DH Request\' OR (PMC_CPQ_QuoteOrigin__c != \'DH Request\' AND (SBQQ__Status__c NOT IN (\'Request\',\'Draft\'))))';
            strQuery += ' AND (SBQQ__MasterContract__c= null) AND (SBQQ__Type__c!= \'Amendment\') ';
            // AND (PMC_CPQ_ContractStageName__c != :PENDING_SIGNATURE_STATUS) AND (PMC_CPQ_ContractStageName__c !=:PARTIALLY_EXECUTED_STATUS)


            if(String.isNotBlank(searchParams.strSearchTerm))
            {
                String searchPattern = '\'%' + String.escapeSingleQuotes(searchParams.strSearchTerm) + '%\'';
                strQuery += ' AND ( Id IN (SELECT SBQQ__Quote__c FROM SBQQ__QuoteLine__c'; 
                strQuery += ' WHERE SBQQ__Quote__r.Name LIKE '+ searchPattern +' OR SBQQ__Quote__r.PMC_DH_QuoteFriendlyName__c LIKE '+ searchPattern +' OR SBQQ__Quote__r.PMC_DH_FilterStatus__c LIKE '+ searchPattern +' OR SBQQ__Product__r.Name LIKE '+ searchPattern +' OR PMC_CPQ_ModeofTransportation__c LIKE '+ searchPattern+'';
                strQuery += ' OR PMC_CPQ_ShipTo__r.Name LIKE '+ searchPattern +' OR PMC_CPQ_ShipTo__r.ShippingCountry LIKE '+ searchPattern +' OR PMC_CPQ_ShipTo__r.ShippingPostalCode LIKE '+ searchPattern +' OR PMC_CPQ_ShipTo__r.ShippingCity LIKE '+ searchPattern +' OR PMC_CPQ_ShipTo__r.ShippingState LIKE '+ searchPattern +' OR PMC_CPQ_ShipTo__r.ShippingStateCode LIKE '+ searchPattern +' OR PMC_CPQ_ShipTo__r.ShippingStreet LIKE '+ searchPattern +'))';
            }
            if (searchParams.datFromDate != null && searchParams.datToDate != null) {
                strQuery += ' AND (CreatedDate >= ' + String.valueOf(searchParams.datFromDate) + PMC_DH_ConstantClass.START_TIME;
                strQuery += ' AND ';
                strQuery += 'CreatedDate <= ' + String.valueOf(searchParams.datToDate) + PMC_DH_ConstantClass.END_TIME;
                strQuery += ')';
            }
            
            strQuery += ' WITH SECURITY_ENFORCED ORDER BY PMC_CPQ_ExpiresOn__c ASC LIMIT 1001';
            return strQuery;
    }

    private static String getProductOrShipToName(Map<String,String> mapProductorShipName, String proOrShipName )
    {    
        if(mapProductorShipName.size()==1){
            proOrShipName = mapProductorShipName.values()[0];
        }else if(mapProductorShipName.size()>=2){
            proOrShipName = System.Label.PMC_DH_ProductMultiple;
        }
        return proOrShipName;

    }
    
    private static String getDeliveryModeName( Set<String> setDeliveryModeName, String deliveryMode) {
        if (setDeliveryModeName.size() == 1) {
            deliveryMode = new List<String> (setDeliveryModeName).get(0);
        } else if (setDeliveryModeName.size() >= 2) {
            deliveryMode = System.Label.PMC_DH_ProductMultiple;
        }
        return deliveryMode;
    }

    private static void getProductWrapper(Map<String,String> mapAllLineProductIdName, SBQQ__QuoteLine__c lineItem, List<PMC_DH_QuoteListViewWrapper.ProductDropDownWrapper> lstProductDropDownWrapper){
        if(!mapAllLineProductIdName.containsKey(lineItem.SBQQ__Product__c) && lineItem.SBQQ__Product__c!=NULL ){
            PMC_DH_QuoteListViewWrapper.ProductDropDownWrapper productWrapper = new PMC_DH_QuoteListViewWrapper.ProductDropDownWrapper();
                productWrapper.Label = lineItem.SBQQ__Product__r.Name;
                productWrapper.Value = lineItem.SBQQ__Product__r.StockKeepingUnit;
                lstProductDropDownWrapper.add(productWrapper);
                mapAllLineProductIdName.put(lineItem.SBQQ__Product__c,lineItem.SBQQ__Product__r.Name);
        }
    }

  



    /**
* @description       : Wrapper for the Search Params
* @author            : @Lohitha sai
* @Created on        : 06-30-2023
**/
    public with sharing class QuoteSearchParameterWrapper {
        /**
     * * @description String searchterm
     * * @return String
     * */
        @AuraEnabled
        public String strSearchTerm { get; set; }
        /**
     * * @description Date of From date
     * * @return Date
     * */
        @AuraEnabled
        public Date datFromDate { get; set; }
        /**
     * * @description Date of To date
     * * @return Date
     * */
        @AuraEnabled
        public  Date datToDate { get; set; }
    }



/** 
     * 
      * @description method for validation of country
     * @since 07-27-2023
     * @uthor hemant giri goswami
     * @param strcountryRegion 
     * @return  PMC_DH_CountryValidationWrapper
    */ 
    @AuraEnabled
    public static PMC_DH_CountryValidationWrapper getCountryValidation(string strcountryRegion) //changes as part of GDASF-19642
    {   
        PMC_DH_CountryValidationWrapper wrpCountryValidation = new PMC_DH_CountryValidationWrapper(); //changes as part of GDASF-19642
        boolean boolFlag=false;
		List<String> lstCountries=new List<String>();
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            PMC_DH_Store_Configuration__mdt mdtCountryValidation= PMC_DH_Store_Configuration__mdt.getInstance(PMC_DH_ConstantClass.PRICE_SUMM);
            if(String.isNotBlank(mdtCountryValidation.PMC_DH_Country__c))
            {
            lstCountries=mdtCountryValidation.PMC_DH_Country__c.split(',');
            }
        	boolFlag= (lstCountries.contains(strcountryRegion) && mdtCountryValidation.PMC_DH_isActive__c==true );
            wrpCountryValidation.boolFlag = boolFlag; //changes as part of GDASF-19642
            wrpCountryValidation.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, 'CountryValidation'); //changes as part of GDASF-19642
    }
    catch(Exception ex)
    {
        wrpCountryValidation.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL); //changes as part of GDASF-19642
        PMC_ErrorLogClass.processException(ex); // MDErrorLog
    }
        //return boolFlag;
        return wrpCountryValidation; //changes as part of GDASF-19642
    }

    /**
     * @description method to assign source to cart item
     * @param objCartItem 
     * @param strSource   
     * @author @Hemant goswami
     * @since 08-08-2023
    
     */
    public static void assignSource( CartItem objCartItem, String strSource)
    {
        if(strSource!=null)
        {
        objCartItem.PMC_DH_Source__c =strSource;
        }
    }
    
    // added as part of GDASF-19642
    /**
* @description : Wrapper for Country Validation
* @author      : Nikhilesh Mohanty
* @last modified on 2024-01-10
**/ 
public with sharing class PMC_DH_CountryValidationWrapper
{
    /**
    * @description Boolean flag for country validation
    * @author Nikhilesh
    * @return Boolean
    **/ 
    @AuraEnabled
    public Boolean boolFlag{get;set;}

    /**
    * @description Status Code and message
    * @author Nikhilesh
    * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
}

}