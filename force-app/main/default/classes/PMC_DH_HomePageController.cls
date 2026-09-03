/**
 * @description       : 
 * @author            : Hemant Giri Goswami | hegoswami@deloitte.com
 * @group             : 
 * @last modified on  : 04-26-2024
 * @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/

public without sharing class PMC_DH_HomePageController { //added as a fix for GPT-34165- to handle shipmentitem records
    public final static String ACTIVE_STATUS = 'Active';
    public final static String QUOTE_HISTORY_URL='/quotes';
    public final static String CONTRACT_HISTORY_URL='/contracts';
    public final static String QUOTE_RELATIVE_PATH = 'quote';
    public final static String QUOTE_NUMBER = '?quoteNumber=';
    public final static String QUOTE_ID = '?quoteId=';
    public final static String ACCEPTED_STATUS = 'Accepted';
    public final static String PENDING_SIGNATURE_STATUS = 'Pending Signature';
    public final static String ACTION_PENDING_STATUS = System.label.PMC_DH_ActionPending;//'Action Pending';
    public final static String PARTIALLY_EXECUTED_STATUS = 'Partially Executed';
    public final static String SALES_QUALIFIED='Sales Qualified';
    public final static String RETAILERS_TYPE='Retailer';
    public final static String MULTIPLE=System.label.PMC_DH_ProductMultiple;
    public final static String DIGITAL_HUB='Digital Hub%';
/*************************************************************************
* @method Name  : getRecentQuotes
* @description  : Method to assign the recent Quotes in wrapper class
* @param        strEffectiveAccountId
* @return       : PMC_DH_HomePageWrapper.RecentQuotesWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_HomePageWrapper.RecentQuotesWrapper getRecentQuotes(String strEffectiveAccountId){
        PMC_DH_HomePageWrapper.RecentQuotesWrapper recentQuotesWrapper=new PMC_DH_HomePageWrapper.RecentQuotesWrapper();
        List<PMC_DH_HomePageWrapper.RecentQuotesList> lstQuoteWrap=new List<PMC_DH_HomePageWrapper.RecentQuotesList>();
        recentQuotesWrapper.strQuoteHistoryUrl=QUOTE_HISTORY_URL;
        PMC_DH_Store_Configuration__mdt configLimit = PMC_DH_Store_Configuration__mdt.getInstance(PMC_DH_ConstantClass.CONFIG_LIMIT_QUOTES);
        String strTemp;
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        List<SBQQ__Quote__c> lstQuote=[SELECT id,CreatedDate,SBQQ__Status__c,Name,PMC_CPQ_CustomerAcceptanceMethod__c,SBQQ__LineItemCount__c
                                       FROM SBQQ__Quote__c  WHERE SBQQ__Account__c=:strEffectiveAccountId and SBQQ__LineItemCount__c!=0
                                       WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC LIMIT: Integer.valueOf(configLimit.PMC_DH_Product_Max_Result__c) ];
        if(!lstQuote.isEmpty()){
            for(SBQQ__Quote__c quote:lstQuote){
                PMC_DH_HomePageWrapper.RecentQuotesList objQuoteWrap=new PMC_DH_HomePageWrapper.RecentQuotesList();
                PMC_DH_QuoteMgmtActionController.PMC_DH_QuoteStatusWrapper quoteStatusWrap=PMC_DH_QuoteMgmtActionController.getStatus(quote);
                objQuoteWrap.strQuoteNumber=quote.Name;
                objQuoteWrap.datRequestedDate=PMC_DH_QuoteUtils.getDateTimeToDate(quote.CreatedDate);
                strTemp= PMC_DH_Quote_Management_Status__mdt.getinstance(quoteStatusWrap.strSummaryStatus.replace(' ','_')).PMC_DH_StatusLabel__c;
                objQuoteWrap.strQuoteStatus=System.label.get(null,strTemp,userinfo.getLocale());
                objQuoteWrap.strQuoteUrl=QUOTE_RELATIVE_PATH+QUOTE_NUMBER+quote.Name+QUOTE_ID+quote.id;
                lstQuoteWrap.add(objQuoteWrap);
            }
        }
 
        recentQuotesWrapper.lstQuotes=lstQuoteWrap;
        recentQuotesWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, PMC_DH_ConstantClass.RECENT_QUOTES_SUCCESS_MODULE);
    }
    catch (Exception e) {
        recentQuotesWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.FAILURE_STATUS_CODE, PMC_DH_ConstantClass.ALL);
        PMC_ErrorLogClass.processException(e); // MDErrorLog
    }
        return recentQuotesWrapper;
}
 
 
    /**
     * @description Method to get the 2 ACTIVE contracts with earliest expiry date
     * @param strEffectiveAccountId
     * @return void
     * @author hemant giri goswami
     * @since 09-01-2023                  
     */
    @AuraEnabled
    public static PMC_DH_HomePageWrapper.RecentContractWrapper  getActiveContracts(String strEffectiveAccountId){
 
        PMC_DH_HomePageWrapper.RecentContractWrapper wrpContr=new PMC_DH_HomePageWrapper.RecentContractWrapper();
        List<PMC_DH_HomePageWrapper.ActiveContractInfoWrapper> lstContractInfoWrp= new List<PMC_DH_HomePageWrapper.ActiveContractInfoWrapper>();
        PMC_DH_Store_Configuration__mdt config = PMC_DH_Store_Configuration__mdt.getInstance(PMC_DH_ConstantClass.URL_CONTR);
        PMC_DH_Store_Configuration__mdt configLimit = PMC_DH_Store_Configuration__mdt.getInstance(PMC_DH_ConstantClass.CONFIG_LIMIT_CONTR);
        try {
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            Date datCurr=System.now().date();
           // GSMD-5102
            List<Contract> lstContractData = [ SELECT Id, PMC_CPQ_Contract_Blocked__c,PMC_CPQ_LatestQuote__c, PMC_CPQ_LatestQuote__r.SBQQ__Type__c, PMC_CPQ_LatestQuote__r.PMC_CPQ_PO__c, PMC_CPQ_LatestQuote__r.PMC_CPQ_PrimaryContact__r.Name, PMC_CPQ_LatestQuote__r.SBQQ__PaymentTerms__c, PMC_CPQ_LatestQuote__r.PMC_DH_PaymentMethod__c, PMC_CPQ_LatestQuote__r.CurrencyIsoCode,
                                              (SELECT Id, CreatedDate, SBQQ__Quantity__c, SBQQ__RevisedSubscription__c, SBQQ__Contract__c, SBQQ__QuoteLine__r.SBQQ__Number__c,SBQQ__Quoteline__r.SBQQ__Quote__c, SBQQ__Quoteline__r.PMC_CLM_QuoteLineNumber__c
                                               FROM SBQQ__Subscriptions__r Order By CreatedDate DESC, Id DESC )
                                              FROM Contract WHERE ACCOUNTID=:strEffectiveAccountId  
                                              AND Status=:PMC_DH_ConstantClass.CONTRACT_ACTIVE AND 
                                              Id IN (SELECT SBQQ__CONTRACT__C FROM SBQQ__Subscription__c WHERE SBQQ__Contract__r.AccountId =:strEffectiveAccountId AND PMC_CPQ_TotalAvailableQuantity__c>0)
                                              WITH SECURITY_ENFORCED ORDER BY SBQQ__EXPIRATIONDATE__C ASC LIMIT: Integer.valueOf(configLimit.PMC_DH_Product_Max_Result__c)];
            Map<String, Id> mapUniqueSubscriptionIds = PMC_DH_ContractManagementController.getMapOfSubscriptionIds(lstContractData);   
            List<Contract> lstContract=[ SELECT Id, PMC_CPQ_Contract_Blocked__c,PMC_CPQ_ContractType__c, StartDate, EndDate, tolabel(Status), AccountId,
                                        SBQQ__Quote__c, SBQQ__Quote__r.Name, SBQQ__Quote__r.SBQQ__Status__c, SBQQ__Quote__r.PMC_CLM_DocumentNumber__c, SBQQ__Quote__r.PMC_CPQ_PO__c, SBQQ__Quote__r.PMC_CPQ_PrimaryContact__r.Name, SBQQ__Quote__r.SBQQ__PaymentTerms__c, SBQQ__Quote__r.PMC_DH_PaymentMethod__c, SBQQ__Quote__r.PMC_CPQ_Currency__c, SBQQ__Quote__r.PMC_CPQ_TotalQuantity__c, SBQQ__Quote__r.PMC_CPQ_ModeOfTransportation__c,
                                        (SELECT Id, PMC_CPQ_TotalOrderedQuantity__c, PMC_CPQ_TotalAvailableQuantity__c, SBQQ__Product__r.StockKeepingUnit,
                                         SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__c,SBQQ__Product__c, SBQQ__Product__r.Name,SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.Name, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingStreet, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingCity, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingState, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingPostalCode, SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__c,SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name, SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c, SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c, SBQQ__QuoteLine__r.SBQQ__NetPrice__c, SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c
                                         FROM SBQQ__Subscriptions__r WHERE Id IN : mapUniqueSubscriptionIds.values())
                                        FROM Contract WHERE ACCOUNTID=:strEffectiveAccountId 
                                        AND Status=:PMC_DH_ConstantClass.CONTRACT_ACTIVE 
                                        AND Id IN (SELECT SBQQ__CONTRACT__C FROM SBQQ__Subscription__c WHERE SBQQ__Contract__r.AccountId =:strEffectiveAccountId AND PMC_CPQ_TotalAvailableQuantity__c>0)
                                        WITH SECURITY_ENFORCED ORDER BY SBQQ__EXPIRATIONDATE__C ASC LIMIT: Integer.valueOf(configLimit.PMC_DH_Product_Max_Result__c)];
            
            for(Contract cntr : lstContract){  
                PMC_DH_HomePageWrapper.ActiveContractInfoWrapper contInfo=new PMC_DH_HomePageWrapper.ActiveContractInfoWrapper();
                contInfo.strContractId=cntr.id;
                contInfo.strPoNumber=cntr.SBQQ__Quote__r.PMC_CPQ_PO__c;
                contInfo.strContractHistoryUrl=config.PMC_DH_PageUrl__c+contInfo.strContractId;
                contInfo.strContractNumber=PMC_DH_ConstantClass.DOC_TAG+cntr.SBQQ__Quote__r.PMC_CLM_DocumentNumber__c;
                contInfo.strShipto=getShipToValue(cntr);
                contInfo.strProduct=getProductValue(cntr);
                contInfo.intAvailableQty=PMC_DH_ContractManagementHelper.getTotAvailableQty(cntr);
                lstContractInfoWrp.add(contInfo);
            }
 
            wrpContr.lstContracts=lstContractInfoWrp;
            wrpContr.strContractHistorPageUrl=CONTRACT_HISTORY_URL;
            wrpContr.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, PMC_DH_ConstantClass.ACTIVE_CONTRACTS_SUCCESS_MODULE);
        }
        catch (Exception e) {
            wrpContr.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.FAILURE_STATUS_CODE, PMC_DH_ConstantClass.ALL);          
            PMC_ErrorLogClass.processException(e); // MDErrorLog
        }
       
        return wrpContr;
    }
 
 
    private static String getProductValue(Contract cntr)
    {   String strReturn='';
        Map<String,String> mapProductIdName=new Map<String,String>();
        for(SBQQ__Subscription__c subItem : cntr.SBQQ__Subscriptions__r)
        {  
           if(!mapProductIdName.containsKey(subItem.SBQQ__Product__c) )
            {  
                mapProductIdName.put(subItem.SBQQ__Product__c,subItem.SBQQ__Product__r.Name);
            }
           
        }
     
        if(mapProductIdName.size()==1)
        {
            strReturn=mapProductIdName.values()[0];
        }
        else if(mapProductIdName.size()>=2){
            strReturn = MULTIPLE;
        }
     
        return strReturn;
    }
 
 
 
    private static String getShipToValue(Contract cntr)
    {   String strReturn='';
 
        Map<String,String> mapShipTos=new Map<String,String>();
        for(SBQQ__Subscription__c subItem : cntr.SBQQ__Subscriptions__r)
        {String strShipCompAdd=subItem.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.Name + ' ' + subItem.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingStreet + ', ' + subItem.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingCity + ', ' + subItem.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingState + ' ' + subItem.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingPostalCode;
            if(!mapShipTos.containsKey(subItem.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__c) )
            {  
                mapShipTos.put(subItem.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__c,strShipCompAdd);
            }
        }
        if(mapShipTos.size()==1)
        {
            strReturn=mapShipTos.values()[0];
        }
        else if(mapShipTos.size()>=2){
            strReturn = MULTIPLE;
        }
       
        return strReturn;
    }
 
    /**
    * @description Wrapper Class for In Transit Orders
    * @author @manishasingh9
    **/
    // added with sharing
    public with sharing class PMC_DH_OrdersInTransitWrapper {
 
        /**
        * @description List of In Transit Orders
        * @return List<PMC_DH_HomePageWrapper.OrdersinTransit>
        **/
        @AuraEnabled
        public List<PMC_DH_HomePageWrapper.OrdersinTransit> lstInTransitOrders{get;set;}
 
        /**
         * @description Status Code and message
         * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
        **/
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
 
    }
 
    /**
     * @description Method to get the order in transit for homepage
     * @author Hemant Giri Goswami
     * @param strEffectiveAccountId
     * @return PMC_DH_OrdersInTransitWrapper
     */
    @AuraEnabled
    public static PMC_DH_OrdersInTransitWrapper getOrdersinTransit(String strEffectiveAccountId)
    {  
        PMC_DH_OrdersInTransitWrapper orderStatusWrapper = new PMC_DH_OrdersInTransitWrapper();
        List<PMC_DH_HomePageWrapper.OrdersinTransit> wrpOrderinTransit=new List<PMC_DH_HomePageWrapper.OrdersinTransit>();
        Set<String> setOrderId=new Set<String> ();
 
        Map<String,SHIPMENTITEM> mapOrderShip=new Map<String,SHIPMENTITEM>();
        try{
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        List<String> lstOrderTypes = PMC_DH_CommonSystemUtils.getListStoreConfigbyFeature(PMC_DH_ConstantClass.ORDER_TYPE_CODES);
        PMC_DH_Store_Configuration__mdt configLimit = PMC_DH_Store_Configuration__mdt.getInstance(PMC_DH_ConstantClass.CONFIG_ORD_LIMIT);
        List<AggregateResult> lstResults=[SELECT PMC_CPQ_RequestedShipDate__c,OrderId OrdId
                                                From OrderItem  WHERE  Order.Status=:PMC_DH_ConstantClass.IN_PROGRESS AND
                                                Order.AccountId=:strEffectiveAccountId
                                                AND Order.PMC_DH_OrderTypeCode__c IN :lstOrderTypes
                                                WITH SECURITY_ENFORCED
                                                GROUP BY PMC_CPQ_RequestedShipDate__c,OrderId
                                                ORDER BY MIN(PMC_CPQ_RequestedShipDate__c)  ASC NULLS Last
                                                LIMIT: Integer.ValueOf(configLimit.PMC_DH_Product_Max_Result__c)]; //change for GDASF-21480: Order.Status = 'In Progress'
        for(AggregateResult aggI:lstResults)
        {
            setOrderId.add((String)aggI.get('OrdId'));
        }
 
        List<Order> lstOrder=[Select Id,OrderNumber,Status,PMC_CPQ_SAPOrderNumber__c,
                                (SELECT id,product2.name,product2id,toLabel(PMC_CPQ_ModeOfTransportation__c) FROM ORDERITEMS
                                ORDER BY PMC_CPQ_RequestedShipDate__c ASC)
                                from ORDER
                                WHERE Id IN:setOrderId
                                WITH SECURITY_ENFORCED
                                LIMIT: Integer.ValueOf(configLimit.PMC_DH_Product_Max_Result__c) ];
 
       List<SHIPMENTITEM> lstShipment=[SELECT id, SHIPMENT.PMC_CPQ_Order__r.name,SHIPMENT.PMC_CPQ_Order__c,
                            Product2.name,SHIPMENT.PMC_CPQ_Order__r.OrderNumber, Shipment.PMC_CPQ_ShippedDate__c
                            FROM SHIPMENTITEM WHERE SHIPMENT.PMC_CPQ_Order__c IN:setOrderId WITH SECURITY_ENFORCED
                            ORDER BY Shipment.PMC_CPQ_ShippedDate__c ASC]; //GDASF-20619
 
         for(SHIPMENTITEM sh:lstShipment)
         {
            if(!mapOrderShip.containsKey(sh.SHIPMENT.PMC_CPQ_Order__c))
            {
                mapOrderShip.put(sh.SHIPMENT.PMC_CPQ_Order__c,sh);
            }
 
         }    
 
        wrpOrderinTransit= PMC_DH_OrderListViewController.getOrdersinTransitCall(lstOrder,mapOrderShip);
        orderStatusWrapper.lstInTransitOrders =  wrpOrderinTransit;
        orderStatusWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, PMC_DH_ConstantClass.ORDERS_SUCCESS_MODULE);
    }
    catch (Exception e) {
        orderStatusWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.FAILURE_STATUS_CODE, PMC_DH_ConstantClass.ALL);
        PMC_ErrorLogClass.processException(e); // MDErrorLog
    }
    return orderStatusWrapper;
        //return wrpOrderinTransit;
    }
 
    /**
     * @description Method to get shipment date of order
     * @param mapOrderShip
     * @param strOrderId        
     * @return                     `String`
     */
    public static Date getShipmentDate(Map<String,SHIPMENTITEM> mapOrderShip ,String strOrderId)
    {
        Date datR;
        if(!mapOrderShip.isEmpty())
        {
           
            datR=mapOrderShip.get(strOrderId).Shipment.PMC_CPQ_ShippedDate__c; //GDASF-20619
        }
        return datR;
    }
 
    /**
     * @description Method to get delivery mode
     * @param mapDeliveryModeOrderLine
     * @param ordIt        
     * @return                     `String`
     */
    public static String getDeliveryMode(Map<String,String> mapDeliveryModeOrderLine,Order ordIt)
    {   String strResult;
        if(mapDeliveryModeOrderLine.size()!=0)
        {
            for(Orderitem ord:ordIt.orderitems)
            {
                strResult= mapDeliveryModeOrderLine.get(ord.id);
            }
        }
        return strResult;
    }
 
    /**
    * @description Wrapper Class for returning counts
    * @author @Dishari | 05-10-2023
    **/
    //added with sharing
    public with sharing class RecentUpdatesWrapper{
        /**
         * @description Integer intNoOfActionPendingQuotes
        * @return Integer
        **/
        @AuraEnabled
        public Integer intNoOfActionPendingQuotes{get;set;}
        /**
         * @description Integer intNoOfActionPendingContracts
        * @return Integer
        **/
        @AuraEnabled
        public Integer intNoOfActionPendingContracts{get;set;}
        /**
         * @description Integer intNoOfNewLeads
        * @return Integer
        **/
        @AuraEnabled
        public Integer intNoOfNewLeads{get;set;}
        /**
         * @description Integer intNoOfNewCaseComments
        * @return Integer
        **/
        @AuraEnabled
        public Integer intNoOfNewCaseComments{get;set;}
        /**
         * @description Boolean boolIsRetailersType
        * @return Boolean
        **/
        @AuraEnabled
        public Boolean boolIsRetailersType{get;set;}
        /**
         * @description Status Code and message
         * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
        **/
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
 
    }
    /*************************************************************************
    * @method Name  : fetchRecentUpdates
    * @description  : Method to assign the recent Updates in Home Page
    * @param        strEffectiveAccountId
    * @return       : recentUpdatesWrapper
    *****************************************************************************/
    @AuraEnabled
    public static RecentUpdatesWrapper fetchRecentUpdates(String strEffectiveAccountId){
        RecentUpdatesWrapper result = new RecentUpdatesWrapper();
        try {
 
            List<Account> lstAccount = [SELECT Id,Name, RecordType.Name, PMC_SS_Channel__c FROM Account WHERE Id =: strEffectiveAccountId WITH SECURITY_ENFORCED];
            result.boolIsRetailersType = false;
            if (!lstAccount.isEmpty()){
                if(lstAccount[0].RecordType.Name == RETAILERS_TYPE || lstAccount[0].PMC_SS_Channel__c == PMC_DH_ConstantClass.RETAILERS_CHNL) {
                    result.boolIsRetailersType = true;
                }
            }
 
            // Action Pending Quotes
            List<AggregateResult> lstQuoteAggRsult = [SELECT Count(Id)totalRows from SBQQ__Quote__c WHere SBQQ__Account__c = :strEffectiveAccountId  AND PMC_DH_FilterStatus__c = :ACTION_PENDING_STATUS WITH SECURITY_ENFORCED ];
            result.intNoOfActionPendingQuotes = Integer.ValueOf(lstQuoteAggRsult[0].get('totalRows'));
 
            // Action Pending Contracts
            List<AggregateResult> lstContractAggRsult = [SELECT Count(Id)totalRows from SBQQ__Quote__c Where SBQQ__Account__c  = :strEffectiveAccountId AND SBQQ__Status__c = :ACCEPTED_STATUS AND (PMC_CPQ_ContractStageName__c = :PENDING_SIGNATURE_STATUS OR PMC_CPQ_ContractStageName__c =:PARTIALLY_EXECUTED_STATUS) AND PMC_CPQ_ContractEnd__c >= :System.today() WITH SECURITY_ENFORCED];
            result.intNoOfActionPendingContracts = Integer.ValueOf(lstContractAggRsult[0].get('totalRows'));
 
            // New Leads
            List<AggregateResult> lstLeadAggRsult = [SELECT Count(Id)totalRows from Lead WHERE  Status = :SALES_QUALIFIED WITH USER_MODE];
            result.intNoOfNewLeads = Integer.ValueOf(lstLeadAggRsult[0].get('totalRows'));
             // Case Comments
            DateTime datLoginTime = NULL;
            List<LoginHistory> lstLgnHistory = [SELECT UserId, LoginTime FROM LoginHistory WHERE UserId =: UserInfo.getUserId() WITH SECURITY_ENFORCED ORDER BY LoginTime DESC LIMIT 2 ];
            if(lstLgnHistory.size()==1){
                datLoginTime = lstLgnHistory[0].LoginTime;
            }else if(lstLgnHistory.size()==2){
                datLoginTime = lstLgnHistory[1].LoginTime;
            }
            List<AggregateResult> lstCaseCommentAggRsult = [SELECT Count(Id)totalRows FROM CaseComment WHERE Parent.AccountId =: strEffectiveAccountId AND CreatedDate >: datLoginTime AND (NOT CreatedBy.Profile.Name LIKE :DIGITAL_HUB) WITH SYSTEM_MODE]; // AND (NOT CreatedBy.Profile.Name LIKE :DIGITAL_HUB)
           
            result.intNoOfNewCaseComments = Integer.ValueOf(lstCaseCommentAggRsult[0].get('totalRows'));
            result.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, PMC_DH_ConstantClass.RECENT_UPDATES_SUCCESS_MODULE);
        }
        catch (Exception e) {
            result.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.FAILURE_STATUS_CODE, PMC_DH_ConstantClass.ALL);
            PMC_ErrorLogClass.processException(e); // MDErrorLog
        }
        return result;
    }
}