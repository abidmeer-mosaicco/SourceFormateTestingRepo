/**
* @description       : Controller for fetching Contract History
* @author            : @Lohitha sai
* @last modified on 08-10-2023
* @last modified by Nikhilesh Mohanty
* @Created on        : 07-13-2023
**/
public without sharing class PMC_DH_ContractListViewController { //{all shiptos not coming when using 'with sharing'}
    public final static String ACTIVE_STATUS = 'Activated'; // changed this prevsly we were using label(Active), but now going with API value
    public final static String INACTIVE_STATUS = 'Inactive';
    public final static String ACCEPTED_STATUS = 'Accepted';
    public final static String REJECTED_STATUS = 'Rejected';
    public final static String EXPIRED_STATUS = 'Expired';

    public final static String PENDING_SIGNATURE_STATUS = 'Pending Signature';
    public final static String PARTIALLY_EXECUTED_STATUS = 'Partially Executed';
    public final static String ACTION_PENDING_STATUS = 'Action Pending';
    public final static String QUOTE_TYPE_AMENDMENT = 'Amendment';
    public final static String QUOTE_STATUS_REQUEST = 'Request';
    public final static String QUOTE_STATUS_DRAFT = 'Draft';
    public final static String QUOTE_STATUS_APPROVED = 'Approved';
    public final static String QUOTE_STATUS_PRESENTED = 'Presented';


    public static Set<Id> setlatestSubScriptionIds = new Set<Id>();
    /**
* @description   : To fetch the Quote records
* @param         searchParams
* @param         effAccId
* @return        PMC_DH_ContractListViewWrapper
* @author        @Lohitha
*/
    @AuraEnabled
    public static PMC_DH_ContractListViewWrapper getContractRecords(ContractSearchParameterWrapper searchParams,String effAccId){
        PMC_DH_ContractListViewWrapper contractWrapper = new PMC_DH_ContractListViewWrapper();
        setlatestSubScriptionIds.clear();
        try{
            // build the SOQL for quotes ('Action Pending' on contract details page)
            String strQuoteQuery = getQuoteSearchQuery(searchParams, effAccId);
            String quoteQueryRes = strQuoteQuery.replace('\\', '');
            List<SBQQ__Quote__c> lstQuotes = new List <SBQQ__Quote__c>();
             //added espace single Quote in the getQuoteSearchQuery method
            lstQuotes = Database.query(quoteQueryRes);
            System.debug('lstQuotes_______________'+lstQuotes);
            contractWrapper = addQuotesToWrapper(lstQuotes, contractWrapper);
            // build the SOQL for contracts ('Active' and 'Inactive' on contract details page)
            String strContractQuery = '';
            
            List<Contract> lstContracts = new List<Contract>();
            Integer numberOfQuotes = contractWrapper.lstContracts.size();
            if(numberOfQuotes <= 1000){
                Integer updatedLimit = Integer.valueOf(1001 - numberOfQuotes);
                 //added espace single Quote in the getContractSearchQuery method
                strContractQuery = getContractSearchQuery(searchParams,effAccId,updatedLimit);
                String contractQueryRes = strContractQuery.replace('\\', '');
                System.debug('contractQueryRes=>'+contractQueryRes);
                lstContracts = Database.query(contractQueryRes); 
                System.debug('lstContracts=>'+lstContracts);

                Map<String,Id> mapUniqueSubscriptionIds = PMC_DH_ContractManagementController.getMapOfSubscriptionIds(lstContracts);              setlatestSubScriptionIds.addAll(mapUniqueSubscriptionIds.Values()); strContractQuery = getContractSearchQuery(searchParams,effAccId, updatedLimit);
                String contractQueryfinalRes = strContractQuery.replace('\\', '');  lstContracts = Database.query(contractQueryfinalRes); } contractWrapper = addContractsToWrapper(lstContracts, contractWrapper);
        }
        
        catch(Exception ex){
            contractWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
            PMC_ErrorLogClass.processException(ex); // MDErrorLog 
            //throw new AuraHandledException(ex.getMessage()+ex.getLineNumber());
        }
        return contractWrapper;
    }
    
    private static String getOneOrMultiple(Map<String,String> mapObj, String strObj)
    {    
        if(mapObj.size()==1){
            strObj = mapObj.values()[0];        }else if(mapObj.size()>=2){            strObj = System.label.pmc_requestToDeliverShippingInformation_multiple;
        }
        return strObj;
    }
    
    private static String getOneOrMultiple(Set<String> setObj, String strObj) {
        if (setObj.size() == 1) {
            strObj = new List<String> (setObj).get(0);        } else if (setObj.size() >= 2) {            strObj = System.label.pmc_requestToDeliverShippingInformation_multiple;
        }
        return strObj;
    }
    
    // product wrapper for subscription
    private static void getProductWrapper(Map<String,String> mapAllLineProductIdName, Product2 prod, List<PMC_DH_PicklistWrapper> lstProductWrapper){
        if(!mapAllLineProductIdName.containsKey(prod.Id) && prod !=NULL ){
            PMC_DH_PicklistWrapper productWrapper = new PMC_DH_PicklistWrapper();
            productWrapper.Label = prod.Name;
            productWrapper.Value = prod.StockKeepingUnit;
            lstProductWrapper.add(productWrapper);
            mapAllLineProductIdName.put(prod.Id, prod.Name);
        }
    }
    
    private static void getContractTypeWrapper(Map<String,String> mapAllLineContractType, String contractType, List<PMC_DH_PicklistWrapper> lstContractTypeWrapper){
        if(!mapAllLineContractType.containsKey(contractType) && contractType!=NULL ){
            PMC_DH_PicklistWrapper contractTypeWrapper = new PMC_DH_PicklistWrapper();
            ContractTypeWrapper.Label = contractType;
            ContractTypeWrapper.Value = contractType;
            lstContractTypeWrapper.add(contractTypeWrapper);
            mapAllLineContractType.put(contractType,contractType);
        }
    }
    
    
    // querying all quotes with Contract Document Status = 'Pending Signature' or 'Partially Executed'
    private static String getQuoteSearchQuery(ContractSearchParameterWrapper searchParams, String effAccId){
        String strQuery = 'SELECT Id, SBQQ__Account__c ,PMC_CLM_DocumentNumber__c , Name, PMC_CPQ_PO__c, CurrencyIsoCode, PMC_CPQ_ContractStart__c, PMC_CPQ_ContractEnd__c, SBQQ__Status__c, PMC_CPQ_TotalQuantity__c, PMC_CPQ_SumOfLineTotalPrice__c, PMC_CPQ_ContractStageName__c,';
        strQuery += ' (SELECT Id,SBQQ__Quantity__c, SBQQ__Product__c,PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_State__c ,PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name,PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_City__c,PMC_CPQ_ProductLocation__c,PMC_CPQ_ShipTo__c,PMC_CPQ_ShipTo__r.Name ,PMC_CPQ_ShipTo__r.ShippingStreet,PMC_CPQ_ShipTo__r.ShippingCity,PMC_CPQ_ShipTo__r.ShippingState ,PMC_CPQ_ShipTo__r.ShippingPostalCode, SBQQ__Product__r.StockKeepingUnit, SBQQ__Product__r.Name, PMC_CPQ_Incoterms1__c, toLabel(PMC_CPQ_ModeofTransportation__c), toLabel(PMC_CPQ_ContractType__c)';
        strQuery += ' FROM  SBQQ__LineItems__r)';
        strQuery += ' FROM SBQQ__Quote__c WHERE SBQQ__Account__c =: effAccId AND ((SBQQ__Status__c =: ACCEPTED_STATUS AND (PMC_CPQ_ContractStageName__c =: PENDING_SIGNATURE_STATUS OR PMC_CPQ_ContractStageName__c =: PARTIALLY_EXECUTED_STATUS OR PMC_CPQ_ContractStageName__c =: QUOTE_STATUS_DRAFT OR PMC_CPQ_ContractStageName__c = NULL)) OR (SBQQ__Type__c =: QUOTE_TYPE_AMENDMENT AND (SBQQ__Status__c =: QUOTE_STATUS_REQUEST OR SBQQ__Status__c =: QUOTE_STATUS_DRAFT OR SBQQ__Status__c =: QUOTE_STATUS_APPROVED OR SBQQ__Status__c =: QUOTE_STATUS_PRESENTED))) AND PMC_CPQ_ContractEnd__c >= TODAY';
        if(String.isNotBlank(searchParams.strSearchTerm)){
            
            String searchPattern = '\'%' + String.escapeSingleQuotes(searchParams.strSearchTerm) + '%\'';
            strQuery += ' AND ( Id IN (SELECT SBQQ__Quote__c FROM SBQQ__QuoteLine__c'; 
            strQuery += ' WHERE SBQQ__Quote__r.PMC_CLM_DocumentNumber__c LIKE '+ searchPattern +
            ' OR SBQQ__Quote__r.PMC_CPQ_PO__c LIKE '+ searchPattern +
                //GSMD-762
              
             ' OR SBQQ__Quote__r.SBQQ__MasterContract__r.PMC_CPQ_LatestQuote__r.name LIKE '+ searchPattern + 
			' OR SBQQ__Quote__r.PMC_CPQ_SAPContractReference__c LIKE '+ searchPattern + 
			' OR SBQQ__Quote__r.SBQQ__MasterContract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_SAPContractReference__c LIKE '+ searchPattern +
			' OR SBQQ__Quote__r.SBQQ__OriginalQuote__r.name LIKE '+ searchPattern + 
                ' OR toLabel(PMC_CPQ_ContractType__c) LIKE '+ searchPattern +' OR SBQQ__Product__r.Name LIKE '+ searchPattern +' OR PMC_CPQ_ModeofTransportation__c LIKE '+ searchPattern + ' OR PMC_CPQ_Incoterms1__c LIKE '+ searchPattern + ' OR PMC_CPQ_ShipTo__r.ShippingState LIKE '+ searchPattern+' OR PMC_CPQ_ShipTo__r.ShippingCity LIKE '+searchPattern +' OR PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_State__c LIKE '+searchPattern+ '';//PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_City__c LIKE
            strQuery += ' OR PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_City__c LIKE '+searchPattern+  '';
            if(PMC_DH_ContractUtil.isNumericOrDecimal(searchParams.strSearchTerm)){  
                              Decimal searchPatternDec = Decimal.Valueof(searchParams.strSearchTerm);                strQuery +=' OR SBQQ__Quote__r.PMC_CPQ_TotalQuantity__c='+ searchPatternDec +' OR SBQQ__Quote__r.PMC_CPQ_SumOfLineTotalPrice__c='+ searchPatternDec ;
            }
            strQuery += ' ))';
        }
        if (searchParams.datFromDate != null && searchParams.datToDate != null) {
            strQuery += ' AND (PMC_CPQ_ContractStart__c >= ' + String.valueOf(searchParams.datFromDate);
            strQuery += ' AND ';
            strQuery += 'PMC_CPQ_ContractStart__c <= ' + String.valueOf(searchParams.datToDate);
            strQuery += ')';
        }
        strQuery += ' WITH SECURITY_ENFORCED ORDER BY PMC_CPQ_ContractEnd__c ASC LIMIT 1001';
        return strQuery;
    }
    
    // querying all Active/Inactive contracts
    private static String getContractSearchQuery(ContractSearchParameterWrapper searchParams, String effAccId, Integer updatedLimit){
        String endQuery = '';
        String strQuery = 'SELECT Id,PMC_CPQ_LatestQuote__c,PMC_CPQ_LatestQuote__r.SBQQ__Status__c,Latest_Amendment_Created__c,Latest_Amendment_Created__r.SBQQ__Status__c, PMC_CPQ_Contract_Blocked__c, CreatedById, SBQQ__Quote__r.PMC_CLM_DocumentNumber__c , Name, CurrencyIsoCode, SBQQ__Quote__r.PMC_CPQ_PO__c, StartDate, EndDate, tolabel(Status),SBQQ__Quote__r.PMC_CPQ_TotalQuantity__c, SBQQ__Quote__r.PMC_CPQ_SumOfLineTotalPrice__c, toLabel(SBQQ__Quote__r.PMC_CPQ_ContractType__c), CreatedDate,';
        strQuery += ' (SELECT Id, CreatedDate, SBQQ__Quantity__c, SBQQ__RevisedSubscription__c, SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_City__c,PMC_CPQ_CustomerPrice__c,SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_State__c ,SBQQ__Product__c,SBQQ__Product__r.StockKeepingUnit,SBQQ__Product__r.Name,SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c, toLabel(SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c),toLabel( SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c), SBQQ__QuoteLine__r.SBQQ__Quantity__c,  SBQQ__QuoteLine__r.PMC_CPQ_LineTotalPrice__c, SBQQ__QuoteLine__r.SBQQ__Number__c,SBQQ__QuoteLine__r.PMC_CLM_QuoteLineNumber__c, SBQQ__QuoteLine__c, PMC_CPQ_TotalAvailableQuantity__c,SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name,SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__c ,SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__c,SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.Name,SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingStreet,SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingCity,SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingState ,SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingPostalCode ';
        if(setlatestSubScriptionIds.isEmpty()){
            strQuery += '  FROM  SBQQ__Subscriptions__r Order By CreatedDate DESC, Id DESC)';
            endQuery = ' )))';
        }else{            strQuery += ' FROM  SBQQ__Subscriptions__r Where Id IN : setlatestSubScriptionIds Order By CreatedDate DESC, Id DESC)';           endQuery = ' ) AND ID IN : setlatestSubScriptionIds ))';
        }
        strQuery += ' FROM Contract WHERE AccountId =: effAccId AND ((Status=:ACTIVE_STATUS OR Status=:INACTIVE_STATUS)' + 'AND ( ' +
        '   Latest_Amendment_Created__c = NULL ' +
        '   OR (Latest_Amendment_Created__r.SBQQ__Status__c = :ACCEPTED_STATUS AND Latest_Amendment_Created__r.PMC_CPQ_ContractStageName__c =: ACCEPTED_STATUS )' +
        '   OR Latest_Amendment_Created__r.SBQQ__Status__c = :REJECTED_STATUS ' +
        '   OR Latest_Amendment_Created__r.SBQQ__Status__c = :EXPIRED_STATUS ' +
        '))';
        if(String.isNotBlank(searchParams.strSearchTerm)){
        
            String searchPattern = '\'%' + String.escapeSingleQuotes(searchParams.strSearchTerm) + '%\'';
            strQuery += ' AND ( Id IN (SELECT SBQQ__Contract__c FROM SBQQ__Subscription__c'; 
            strQuery += ' WHERE (SBQQ__Contract__r.SBQQ__Quote__r.PMC_CLM_DocumentNumber__c  LIKE '+ searchPattern +' OR SBQQ__Contract__r.SBQQ__Quote__r.PMC_CPQ_PO__c LIKE '+ searchPattern +
            
              ' OR SBQQ__Contract__r.SBQQ__Quote__r.SBQQ__MasterContract__r.PMC_CPQ_LatestQuote__r.name LIKE '+ searchPattern + 
			' OR SBQQ__Contract__r.SBQQ__Quote__r.PMC_CPQ_SAPContractReference__c LIKE '+ searchPattern + 
			' OR SBQQ__Contract__r.SBQQ__Quote__r.SBQQ__MasterContract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_SAPContractReference__c LIKE '+ searchPattern +
			' OR SBQQ__Contract__r.SBQQ__Quote__r.SBQQ__OriginalQuote__r.name LIKE '+ searchPattern + 
            
            ' OR toLabel(SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c) LIKE '+ searchPattern +' OR SBQQ__Product__r.Name LIKE '+ searchPattern +' OR SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c LIKE '+ searchPattern +'';
            strQuery += ' OR SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c LIKE '+ searchPattern +' OR SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingState LIKE '+searchPattern+' OR SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingCity LIKE '+searchPattern+' OR SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_State__c LIKE '+searchPattern+   ''; //SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_City__c LIKE
            strQuery +=' OR SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_City__c LIKE '+searchPattern+ '';
            if(PMC_DH_ContractUtil.isNumericOrDecimal(searchParams.strSearchTerm)){                Decimal searchPatternDec = Decimal.Valueof(searchParams.strSearchTerm);                strQuery +=' OR SBQQ__Contract__r.SBQQ__Quote__r.PMC_CPQ_TotalQuantity__c='+ searchPatternDec +' OR SBQQ__Contract__r.SBQQ__Quote__r.PMC_CPQ_SumOfLineTotalPrice__c='+ searchPatternDec ;
            }
            
            strQuery += endQuery;
            
            //OR SBQQ__Quote__r.PMC_CPQ_TotalQuantity__c LIKE '+ searchPattern +' OR SBQQ__Quote__r.PMC_CPQ_SumOfLineTotalPrice__c LIKE '+ searchPattern +'))';
        }
        if (searchParams.datFromDate != null && searchParams.datToDate != null) {
            strQuery += ' AND (StartDate >= ' + String.valueOf(searchParams.datFromDate);
            strQuery += ' AND ';
            strQuery += 'StartDate <= ' + String.valueOf(searchParams.datToDate);
            strQuery += ')';
        }
        strQuery += ' WITH SECURITY_ENFORCED ORDER BY EndDate ASC LIMIT :updatedLimit';
        return strQuery;
    }
    
    // add all quotes in "Action Pending" to main Wrapper
    private static PMC_DH_ContractListViewWrapper addQuotesToWrapper(List<SBQQ__Quote__c> lstQuotes, PMC_DH_ContractListViewWrapper contractWrapper){
        List<PMC_DH_PicklistWrapper> lstProductWrapper = new List<PMC_DH_PicklistWrapper>();
        List<PMC_DH_PicklistWrapper> lstContractTypeWrapper = new List<PMC_DH_PicklistWrapper>();
        List<PMC_DH_ContractListViewWrapper.ContractInfoWrapper> lstContractInfoWrapper = new List<PMC_DH_ContractListViewWrapper.ContractInfoWrapper>();
        
        Map<String,String> mapAllLineProductIdName = new Map<String,String>();
        Map<String,String> mapAllLineContractType = new Map<String,String>();
        
        for(SBQQ__Quote__c quote : lstQuotes){
            Map<String,String> mapWithProductIdName = new Map<String,String>();
            Map<String,String> mapWithIncoterm = new Map<String,String>();
            Set<String> setWithDeliveryModeName = new Set<String>();
            Set<String> setWithProductSKU = new Set<String>();
            Set<String> setwithContractType = new Set<String>();
            PMC_DH_ContractListViewWrapper.ContractInfoWrapper quoteInfo = new PMC_DH_ContractListViewWrapper.ContractInfoWrapper();
            PMC_DH_Store_Configuration__mdt config = PMC_DH_Store_Configuration__mdt.getInstance('ActionPendingContractUrl');
            Map<String,PMC_DH_AddressWrapper.AddressViewDetails> mapShipto=new Map<String,PMC_DH_AddressWrapper.AddressViewDetails> ();
            Map<String,PMC_DH_AddressWrapper.AddressViewDetails> mapShipFrom=new Map<String,PMC_DH_AddressWrapper.AddressViewDetails> ();
            //PMC_DH_AddressWrapper.AddressViewDetails wrpAddress;
            quoteInfo.strContractId = quote.Id;
            quoteInfo.strContractNumber =PMC_DH_ConstantClass.DOC_TAG+quote.PMC_CLM_DocumentNumber__c;
            quoteInfo.strPONumber = quote.PMC_CPQ_PO__c;
            quoteInfo.datContractStartDate = quote.PMC_CPQ_ContractStart__c;
            quoteInfo.datContractEndDate = quote.PMC_CPQ_ContractEnd__c;
            quoteInfo.strStatus = System.label.pmc_quoteDetailsFlow_statusActionPending; //quote.SBQQ__Status__c;
            quoteInfo.strContractDetailLink = config.PMC_DH_PageUrl__c + quote.id;
            quoteInfo.decTotalQuantity = quote.PMC_CPQ_TotalQuantity__c;
            quoteInfo.decTotalPrice = quote.PMC_CPQ_SumOfLineTotalPrice__c;
            quoteInfo.strCurrencyIsoCode = quote.CurrencyIsoCode;
            
            Decimal decAvailQty = 0;
            for(SBQQ__QuoteLine__c qli : quote.SBQQ__LineItems__r){
                
                decAvailQty +=PMC_DH_ContractManagementHelper.getLineItemQty(qli.SBQQ__Quantity__c);
                
                Product2 prod = new Product2(Id = qli.SBQQ__Product__c, Name = qli.SBQQ__Product__r.Name, StockKeepingUnit = qli.SBQQ__Product__r.StockKeepingUnit);
                getProductWrapper(mapAllLineProductIdName, prod, lstProductWrapper);
                getContractTypeWrapper(mapAllLineContractType, qli.PMC_CPQ_ContractType__c, lstContractTypeWrapper);
                if(!mapWithProductIdName.containsKey(qli.SBQQ__Product__c)){
                    mapWithProductIdName.put(qli.SBQQ__Product__c, qli.SBQQ__Product__r.Name);
                }
                if(!mapWithIncoterm.containsKey(qli.PMC_CPQ_Incoterms1__c)){
                    mapWithIncoterm.put(qli.PMC_CPQ_Incoterms1__c, qli.PMC_CPQ_Incoterms1__c);
                }
                PMC_DH_CartValidationUtil.mapCreationShipTo(mapShipto,qli);
                PMC_DH_ContractUtil.mapCreationShipFrom(mapShipFrom,qli);
                setWithDeliveryModeName.add(qli.PMC_CPQ_ModeofTransportation__c);
                setWithProductSKU.add(qli.SBQQ__Product__r.StockKeepingUnit);
                setwithContractType.add(qli.PMC_CPQ_ContractType__c);
            }
            quoteInfo.shipFrom=PMC_DH_ContractManagementHelper.getMapShipsObject(mapShipFrom);
            quoteInfo.shipTo=PMC_DH_ContractManagementHelper.getMapShipsObject(mapShipTo);
            quoteInfo.decAvailableQuantity=decAvailQty;
            quoteInfo.setSKU = new List<String>(setWithProductSKU);
            quoteInfo.setContractTypes = new List<String>(setwithContractType);
            quoteInfo.strProducts = getOneOrMultiple(mapWithProductIdName, PMC_DH_ConstantClass.BLANK_STRING);
            quoteInfo.strIncoterm = getOneOrMultiple(mapWithIncoterm, PMC_DH_ConstantClass.BLANK_STRING);
            quoteInfo.strDeliveryMode = getOneOrMultiple(setWithDeliveryModeName, PMC_DH_ConstantClass.BLANK_STRING);
            quoteInfo.strContractType = getOneOrMultiple(setwithContractType, PMC_DH_ConstantClass.BLANK_STRING);
            lstContractInfoWrapper.add(quoteInfo);
        }
        contractWrapper.lstContracts = lstContractInfoWrapper;
        contractWrapper.lstProductFilters = lstProductWrapper;
        contractWrapper.lstContractType = lstContractTypeWrapper;
        
        return contractWrapper;
    }
    
    // add all Active/Inactive Contracts to main Wrapper
    private static PMC_DH_ContractListViewWrapper addContractsToWrapper(List<Contract> lstContracts, PMC_DH_ContractListViewWrapper contractWrapper){        List<PMC_DH_PicklistWrapper> lstProductWrapper = contractWrapper.lstProductFilters;        List<PMC_DH_PicklistWrapper> lstContractTypeWrapper = contractWrapper.lstContractType;        List<PMC_DH_ContractListViewWrapper.ContractInfoWrapper> lstContractInfoWrapper = contractWrapper.lstContracts;        Map<String,String> mapAllLineProductIdName = new Map<String,String>(); Map<String,String> mapAllLineContractType = new Map<String,String>();
        
        // class with 'comparable' interface used to sort contracts based on status
        PMC_DH_ContractCustomSortOrder[] lstContractSorted = new List<PMC_DH_ContractCustomSortOrder>();        for(Contract con : lstContracts){            Map<String,String> mapWithProductIdName = new Map<String,String>();            Map<String,String> mapWithIncoterm = new Map<String,String>();            Set<String> setWithDeliveryModeName = new Set<String>();
            Set<String> setWithProductSKU = new Set<String>();            Set<String> setwithContractType = new Set<String>();
            Map<String,PMC_DH_AddressWrapper.AddressViewDetails> mapShipto=new Map<String,PMC_DH_AddressWrapper.AddressViewDetails> ();
            Map<String,PMC_DH_AddressWrapper.AddressViewDetails> mapShipFrom=new Map<String,PMC_DH_AddressWrapper.AddressViewDetails> ();
            PMC_DH_ContractListViewWrapper.ContractInfoWrapper contractInfo = new PMC_DH_ContractListViewWrapper.ContractInfoWrapper();
            //PMC_DH_AddressWrapper.AddressViewDetails wrpAddress;
            PMC_DH_Store_Configuration__mdt config = PMC_DH_Store_Configuration__mdt.getInstance('ContractUrl');
            contractInfo.strContractId=con.Id;            contractInfo.strContractNumber =PMC_DH_ConstantClass.DOC_TAG+con.SBQQ__Quote__r.PMC_CLM_DocumentNumber__c;
            contractInfo.strPONumber=con.SBQQ__Quote__r.PMC_CPQ_PO__c;            contractInfo.datContractStartDate=con.StartDate;
            contractInfo.datContractEndDate=con.EndDate;            contractInfo.strStatus = PMC_DH_ContractManagementHelper.getContractStatusAndReason(con)[0];            contractInfo.strContractDetailLink=config.PMC_DH_PageUrl__c+con.id;            contractInfo.strCurrencyIsoCode=con.CurrencyIsoCode;
            Decimal totalQty = 0;            Decimal decAvailQty = 0;            Decimal totalPrice = 0;
            list<SBQQ__Subscription__c> subsListForContract= con.SBQQ__Subscriptions__r;                                                                                                                                    
            for(SBQQ__Subscription__c subItem : con.SBQQ__Subscriptions__r){               totalQty += PMC_DH_ContractManagementHelper.getLineItemQty(subItem.SBQQ__QuoteLine__r.SBQQ__Quantity__c);                totalPrice += PMC_DH_ContractManagementHelper.getLineItemAmount(subItem);                Product2 prod = new Product2(Id = subItem.SBQQ__Product__c, Name = subItem.SBQQ__Product__r.Name, StockKeepingUnit = subItem.SBQQ__Product__r.StockKeepingUnit);
                getProductWrapper(mapAllLineProductIdName, prod, lstProductWrapper);                getContractTypeWrapper(mapAllLineContractType, subItem.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c,lstContractTypeWrapper);                if(!mapWithProductIdName.containsKey(subItem.SBQQ__Product__c)){                    mapWithProductIdName.put(subItem.SBQQ__Product__c,subItem.SBQQ__Product__r.Name);
                }
                if(!mapWithIncoterm.containsKey(subItem.SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c)){                    mapWithIncoterm.put(subItem.SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c,subItem.SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c);                }                PMC_DH_CartValidationUtil.mapCreationShipTo(mapShipto,subItem.SBQQ__QuoteLine__r);                PMC_DH_ContractUtil.mapCreationShipFrom(mapShipFrom,subItem.SBQQ__QuoteLine__r);
                decAvailQty+=PMC_DH_ContractManagementHelper.getLineItemQty(subItem.PMC_CPQ_TotalAvailableQuantity__c);                setWithDeliveryModeName.add(subItem.SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c);
                setWithProductSKU.add(subItem.SBQQ__Product__r.StockKeepingUnit);                setwithContractType.add(subItem.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c);
            }
            contractInfo.decAvailableQuantity=decAvailQty;            contractInfo.shipFrom=PMC_DH_ContractManagementHelper.getMapShipsObject(mapShipFrom);            contractInfo.shipTo=PMC_DH_ContractManagementHelper.getMapShipsObject(mapShipto);
            contractInfo.decTotalQuantity = totalQty;            contractInfo.decTotalPrice = totalPrice;
            contractInfo.setSKU = new List<String>(setWithProductSKU);            contractInfo.setContractTypes = new List<String>(setwithContractType);
            contractInfo.strProducts = getOneOrMultiple(mapWithProductIdName, PMC_DH_ConstantClass.BLANK_STRING);
               //added for GSMD- 1669
               if (contractInfo.strProducts == System.label.pmc_requestToDeliverShippingInformation_multiple) {
                    contractInfo.decPricePerTon = '-';
                 }
               else if (contractInfo.strProducts != System.label.pmc_requestToDeliverShippingInformation_multiple){
                       if(!subsListForContract.isEmpty()){
                    contractInfo.decPricePerTon = String.Valueof(subsListForContract[0].PMC_CPQ_CustomerPrice__c);}
                } 
                                                                                                                                             //
            contractInfo.strIncoterm = getOneOrMultiple(mapWithIncoterm, PMC_DH_ConstantClass.BLANK_STRING);
            contractInfo.strDeliveryMode = getOneOrMultiple(setWithDeliveryModeName, PMC_DH_ConstantClass.BLANK_STRING);            contractInfo.strContractType = getOneOrMultiple(setwithContractType, PMC_DH_ConstantClass.BLANK_STRING);
            lstContractSorted.add(new PMC_DH_ContractCustomSortOrder(contractInfo));
        }
        lstContractSorted.sort();
        lstContractInfoWrapper = sortingContractInfoRecords(lstContractSorted, lstContractInfoWrapper);        contractWrapper.lstContracts = lstContractInfoWrapper;        contractWrapper.lstProductFilters = lstProductWrapper;        contractWrapper.lstContractType = lstContractTypeWrapper;        contractWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'ContractRecord');
        return contractWrapper;
    }

    

    private static List<PMC_DH_ContractListViewWrapper.ContractInfoWrapper> sortingContractInfoRecords(List<PMC_DH_ContractCustomSortOrder> lstContractSorted, List<PMC_DH_ContractListViewWrapper.ContractInfoWrapper> lstContractInfoWrapper){        for(Integer i = 0; i < lstContractSorted.size(); i++){             lstContractInfoWrapper.add(lstContractSorted[i].contractInfo);         }        return lstContractInfoWrapper;
    }
    /**
* @description       : Class for custom sorting of contracts based on status
* @author            : @Nikhilesh Mohanty
* @last modified on 08-17-2023
* @last modified by Nikhilesh Mohanty
* @Created on        : 08-17-2023
**/
// added with sharing
    public with sharing class PMC_DH_ContractCustomSortOrder implements Comparable{
        PMC_DH_ContractListViewWrapper.ContractInfoWrapper contractInfo;
        Map<String, Integer> statusOrder = new Map<String, Integer>{            ACTION_PENDING_STATUS => 1,                ACTIVE_STATUS => 2,                INACTIVE_STATUS => 3                };
                    /**
* @description       : Constructor for PMC_DH_ContractCustomSortOrder
* @author            : @Nikhilesh Mohanty
* @param               contractInfo
* @Created on        : 08-17-2023
**/
                    public PMC_DH_ContractCustomSortOrder(PMC_DH_ContractListViewWrapper.ContractInfoWrapper contractInfo){                        this.contractInfo = contractInfo;
                    }
        
        /**
* @description       : Method to compare two records
* @author            : @Nikhilesh Mohanty
* @param               obj
* @return            : Integer
* @Created on        : 08-17-2023
**/
        public Integer compareTo(Object obj) {            PMC_DH_ContractCustomSortOrder objRecord = (PMC_DH_ContractCustomSortOrder)obj;            if (this.contractInfo.strStatus > objRecord.contractInfo.strStatus) {
                return 1;            } else if (this.contractInfo.strStatus < objRecord.contractInfo.strStatus) {                return -1;
            } else {                if (this.contractInfo.datContractEndDate > objRecord.contractInfo.datContractEndDate) {                    return 1;
                } else if (this.contractInfo.datContractEndDate < objRecord.contractInfo.datContractEndDate) {
                    return -1;                } else {                    return 0;
                }          
            }       
        }
    }
    
    /**
* @description       : Wrapper for the Search Params
* @author            : @krishanJangir
* @Created on        : 07-17-2023
**/
// added with sharing
    public with sharing class  ContractSearchParameterWrapper {
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
}