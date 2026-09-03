/** 
* @description Helper for PMC_DH_ContractManagementController 
* @author Nikhilesh
* @last modified on 2023-August-16
* @last modified by Nikhilesh
* Created On       :2023-August-16
**/
public without sharing class PMC_DH_ContractManagementHelper{
    public final static String ACTION_PENDING_STATUS = 'Action Pending';
    public final static String INACTIVE_STATUS = 'Inactive';
    public final static String ACTIVE_STATUS = 'Active';
    public final static String COMPLETED_REASON = 'Completed';
    public final static String EXPIRED_REASON = 'Expired';
    private static final String CONTRACT_STATUS = 'Activated';
    /*************************************************************************
* @method Name  : getContractStatusAndReason
* @description  : Method to get the Contract Status (Active/Inactive)
* @param        contract
* @return       : List<String>
*****************************************************************************/
    public static List<String> getContractStatusAndReason(Contract contract){
        List<String> lstStatusAndReason = new List<String>();
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        String conStatus = System.Label.PMC_DH_InactiveStatus;
        String inactiveReason = '';
        Double intTotalAvailableQty = getTotAvailableQty(contract);//GDASF-10697 | Double added because Long was not considering decimal values: GPT-40756
        // NOTE: Removed automatic expiration by EndDate comparison per requirements.
        // Now the contract will be considered based on available quantity and blocked flag.
        if(intTotalAvailableQty == 0){
            inactiveReason = System.label.PMC_DH_Completed;
        }
        //GSMD -760 Update
        else if(contract.PMC_CPQ_Contract_Blocked__c == TRUE){
            inactiveReason = System.label.Replaced_Reason;
        }
        else{
            conStatus = System.Label.PMC_DH_ActiveStatus;
        }
        lstStatusAndReason.add(conStatus);
        lstStatusAndReason.add(inactiveReason);
        return lstStatusAndReason;
    }
    /*************************************************************************
* @method Name  : getTotAvailableQty
* @description  : Method to get the total available quantity of subscriptions
* @param          contract 
* @return       : Long
*****************************************************************************/
    public static Double getTotAvailableQty(Contract contract){//GDASF-10697
        Double totAvailableQty = 0;//GDASF-10697
        for(SBQQ__Subscription__c subscription : contract.SBQQ__Subscriptions__r){
            if(subscription.PMC_CPQ_TotalAvailableQuantity__c != null){
                totAvailableQty += subscription.PMC_CPQ_TotalAvailableQuantity__c.doubleValue();//GDASF-10697 ->Integer.valueOf(
            }
        }
        return totAvailableQty;
    }
    /*************************************************************************
* @method Name  : getQuoteDetails
* @description  : Method to get the Contract Details (of 'Action Pending' quotes) in wrapper class
* @param        strCommunityId 
* @param        strEffectiveAccountId 
* @param        strContractId
* @return       : PMC_DH_ContractDetailsWrapper
*****************************************************************************/
    public static PMC_DH_ContractDetailsWrapper getQuoteDetails(String strCommunityId,String strEffectiveAccountId, String strContractId){
        PMC_DH_ContractDetailsWrapper contractDetailsWrapper= new PMC_DH_ContractDetailsWrapper();
        // method to fetch Quote details
        SBQQ__Quote__c quote = getQuote(strContractId,strEffectiveAccountId);
        if(quote.id!=null)
        {
        // method to assign Quote Number
        contractDetailsWrapper.strContractNumber = quote.PMC_CLM_DocumentNumber__c;
        // method to assign Quote Id value
        contractDetailsWrapper.strQuoteId = quote.Id;
        // method to assign Quote Summary details in a wrapper
        contractDetailsWrapper.contractSummaryWrapper = getQuoteSummary(quote);
        
        // method to assign Payment Info details in a wrapper
        contractDetailsWrapper.paymentInfoWrapper = getQuotePaymentInfo(quote);
        
        // method to assign Product Info details in a wrapper
        contractDetailsWrapper.productInfoWrapper = getQuoteProductInfo(strCommunityId,strEffectiveAccountId,quote);
        
        // method to assign Quote of Origin details in a wrapper
        contractDetailsWrapper.quoteOfOriginWrapper = getQuoteOfOrigin(quote);
        if(quote.PMC_CPQ_ContractStageName__c ==null)
        {
            contractDetailsWrapper.boolIsPOEditable=true;
            
        }
        contractDetailsWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'ContractRecord');
    }
    else if(String.isBlank(quote.id))
    {
        contractDetailsWrapper.statusCodeMessage=PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.ACCESS_DENIED_CODE, PMC_DH_ConstantClass.GETCONTRACT_ACESSDENIED);
    }

        
        return contractDetailsWrapper;
    }
    /*************************************************************************
* @method Name  : getQuote
* @description  : Method to fetch Quote Details
* @param         strContractId
* @param         strEffectiveAccountId
* @return       : SBQQ__Quote__c
*****************************************************************************/
    public static SBQQ__Quote__c getQuote(String strContractId, String strEffectiveAccountId){
        SBQQ__Quote__c quote=new SBQQ__Quote__c();
        List<SBQQ__Quote__c> lstQuote;
        
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            // fetch SBQQ__Quote__c and SBQQ__QuoteLine__c using SOQL
            // PMC_CPQ_UnitofMeasure__c, PMC_CPQ_PackType__c, PMC_CPQ_PackageType__c Added as part of GPT-25411
            lstQuote = [SELECT Id, SBQQ__Account__r.Id,SBQQ__Type__c, PMC_CPQ_ContractStart__c, PMC_CPQ_ContractEnd__c, PMC_CPQ_ContractStageName__c,PMC_CLM_DocumentNumber__c,
                        Name, SBQQ__Status__c, PMC_CPQ_PO__c, PMC_CPQ_PrimaryContact__r.Name, SBQQ__PaymentTerms__c, PMC_DH_PaymentMethod__c, CurrencyIsoCode, PMC_CPQ_TotalQuantity__c, PMC_CPQ_ModeOfTransportation__c, 
                        (SELECT Id, SBQQ__Product__r.StockKeepingUnit, PMC_CPQ_ShipTo__c, PMC_CPQ_ShipTo__r.Name, PMC_CPQ_ShipTo__r.ShippingStreet, PMC_CPQ_ShipTo__r.ShippingCity, PMC_CPQ_ShipTo__r.ShippingState, PMC_CPQ_ShipTo__r.ShippingPostalCode, PMC_CPQ_ProductLocation__c,PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name,toLabel(PMC_CPQ_Incoterms1__c), toLabel(PMC_CPQ_ModeofTransportation__c),SBQQ__NetPrice__c, SBQQ__Quantity__c,toLabel( PMC_CPQ_ContractType__c), PMC_CPQ_UnitofMeasure__c, PMC_CPQ_PackType__c, PMC_CPQ_PackageType__c 
                         FROM SBQQ__LineItems__r)
                        FROM SBQQ__Quote__c WHERE Id =: strContractId AND SBQQ__Account__r.ID =: strEffectiveAccountId WITH SECURITY_ENFORCED];
            if(!lstquote.isEmpty()){
                quote = lstQuote[0];
            }
            
        
        return quote;
    }
    /*************************************************************************
* @method Name  : getQuoteSummary
* @description  : Method to fetch Quote Summary
* @param         quote
* @return       : PMC_DH_ContractDetailsWrapper.ContractSummaryWrapper
*****************************************************************************/
    public static PMC_DH_ContractDetailsWrapper.ContractSummaryWrapper getQuoteSummary(SBQQ__Quote__c quote){
        PMC_DH_ContractDetailsWrapper.ContractSummaryWrapper contractSummaryWrapper; 
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        Boolean isEligibleForReqSign = TRUE;
        List<Task> lstReqSignTasks=[SELECT Id,CreatedDate FROM Task Where WhatId=:quote.Id AND Subject =:PMC_DH_ConstantClass.TASK_SUBJECT_FOR_CONTRACT WITH SECURITY_ENFORCED Order By CreatedDate DESC LIMIT 1 ];
        if(!lstReqSignTasks.isEmpty()){
            Long timeDiffence = ((System.now().getTime() - lstReqSignTasks[0].CreatedDate.getTime()) / (1000)); 
            if (timeDiffence < PMC_DH_ConstantClass.ONE_DAY_IN_SECONDS){
                isEligibleForReqSign = FALSE;
            }
        }
        contractSummaryWrapper = new PMC_DH_ContractDetailsWrapper.ContractSummaryWrapper();
        //assign contract values in Contract summary wrapper
        if(quote != null){
            contractSummaryWrapper.strPoNumber = quote.PMC_CPQ_PO__c;
            contractSummaryWrapper.strCustomerName = quote.PMC_CPQ_PrimaryContact__r.Name;
            contractSummaryWrapper.strSummaryStatus = System.label.pmc_quoteDetailsFlow_statusActionPending;
            contractSummaryWrapper.strQuoteType = quote.SBQQ__Type__c;
            contractSummaryWrapper.datContractStartDate = quote.PMC_CPQ_ContractStart__c;
            contractSummaryWrapper.datContractEndDate = quote.PMC_CPQ_ContractEnd__c;
            contractSummaryWrapper.boolIsEligibleForReqSign = isEligibleForReqSign;
        }
        return contractSummaryWrapper;
    }
    /*************************************************************************
* @method Name  : getQuotePaymentInfo
* @description  : Method to fetch Payment Info
* @param         quote
* @return       : PMC_DH_QuoteDetailsWrapper.PaymentInformationWrapper
*****************************************************************************/
    public static PMC_DH_QuoteDetailsWrapper.PaymentInformationWrapper getQuotePaymentInfo(SBQQ__Quote__c quote){
        PMC_DH_QuoteDetailsWrapper.PaymentInformationWrapper paymentInfoWrapper; 
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        paymentInfoWrapper = new PMC_DH_QuoteDetailsWrapper.PaymentInformationWrapper();
        //assign contract values in Payment information wrapper
        if(quote != null){
            paymentInfoWrapper.strPaymentTermSelected = quote.SBQQ__PaymentTerms__c;
            paymentInfoWrapper.strPaymentMethodSelected = quote.PMC_DH_PaymentMethod__c;
            paymentInfoWrapper.strCurrencySelected = quote.CurrencyIsoCode;
            paymentInfoWrapper.boolIsBoletoAvailable = true; //to be changed once Boleto feature is ready
        }
        return paymentInfoWrapper;
    }
    /*************************************************************************
* @method Name  : getQuoteLineItemDetails
* @description  : Method to fetch quote line item Details
* @param         quote
* @return       : Map<String,List<PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper>>
*****************************************************************************/
    public static Map<String,List<PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper>> getQuoteLineItemDetails(SBQQ__Quote__c quote){
        Map<String,List<PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper>> mapQuoteLineItems = new Map<String,List<PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper>>();
        PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper objQuoteLineItemWrap;
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        //fetching the quote line item Details and assigning the values to wrapper
        if(quote.SBQQ__LineItems__r != null){
            for(SBQQ__QuoteLine__c qli : quote.SBQQ__LineItems__r)
            {
                
                objQuoteLineItemWrap = new PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper(); 
                objQuoteLineItemWrap.strContractItemId = qli.Id;
                objQuoteLineItemWrap.intOrderedQty = 0; // not a contract, so cannot order
                objQuoteLineItemWrap.intAvailableQty = qli.SBQQ__Quantity__c != null?qli.SBQQ__Quantity__c.doubleValue():0;// GDASF-10697 //longvalue removed
                objQuoteLineItemWrap.intQty = objQuoteLineItemWrap.intAvailableQty;
                
                PMC_DH_PicklistWrapper wrpShipTo = new PMC_DH_PicklistWrapper();
                PMC_DH_PicklistWrapper wrpShipFrom = new PMC_DH_PicklistWrapper();
                wrpShipTo.label = qli.PMC_CPQ_ShipTo__r.Name + ' ' + qli.PMC_CPQ_ShipTo__r.ShippingStreet + ', ' + qli.PMC_CPQ_ShipTo__r.ShippingCity + ', ' + qli.PMC_CPQ_ShipTo__r.ShippingState + ' ' + qli.PMC_CPQ_ShipTo__r.ShippingPostalCode;
                wrpShipTo.value = qli.PMC_CPQ_ShipTo__c;
                wrpShipFrom.label = qli.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name;
                wrpShipFrom.value = qli.PMC_CPQ_ProductLocation__c;
                objQuoteLineItemWrap.wrpShipTo = wrpShipTo;
                objQuoteLineItemWrap.wrpShipFrom = wrpShipFrom;
                objQuoteLineItemWrap.strContractType = qli.PMC_CPQ_ContractType__c ; //referring to Contract Tye field on quote line item
                objQuoteLineItemWrap.strDeliveryMode = qli.PMC_CPQ_ModeofTransportation__c;
                objQuoteLineItemWrap.strIncoterm = qli.PMC_CPQ_Incoterms1__c;
                objQuoteLineItemWrap.strProductUOM= qli.PMC_CPQ_UnitofMeasure__c;// Added as part of GPT-25411
                objQuoteLineItemWrap.strPackType = qli.PMC_CPQ_PackType__c;// Added as part of GPT-25411
                objQuoteLineItemWrap.strPackageType = qli.PMC_CPQ_PackageType__c;// Added as part of GPT-25411
                //objQuoteLineItemWrap.decNetUnitPrice = qli.SBQQ__NetPrice__c;
                //Checking if map contains sku and assigning the Subscription Wrapper
                if(!mapQuoteLineItems.containsKey(qli.SBQQ__Product__r.StockKeepingUnit))
                {
                    mapQuoteLineItems.put(qli.SBQQ__Product__r.StockKeepingUnit, new List<PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper>());
                }
                mapQuoteLineItems.get(qli.SBQQ__Product__r.StockKeepingUnit).add(objQuoteLineItemWrap);
            }
        }
        return mapQuoteLineItems;
    }
    /*************************************************************************
* @method Name  : getQuoteProductInfo
* @description  : Method to fetch Quote product info
* @param         strCommunityId
* @param         strEffectiveAccountId
* @param         quote
* @return       : PMC_DH_RequestForQuoteWrapper
*****************************************************************************/
    public static PMC_DH_RequestForQuoteWrapper getQuoteProductInfo(String strCommunityId,String strEffectiveAccountId,SBQQ__Quote__c quote){
        PMC_DH_RequestForQuoteWrapper productInfoWrapper = new PMC_DH_RequestForQuoteWrapper();
        List<PMC_DH_RequestForQuoteWrapper.CartWrapper> lstQuoteLineItemsWrapper = new List<PMC_DH_RequestForQuoteWrapper.CartWrapper>();
        PMC_DH_RequestForQuoteWrapper.CartWrapper qliWrapper;
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        //method to get subscription Details
        Map<String,List<PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper>> mapQuoteLineItems = getQuoteLineItemDetails(quote);
        Set<String> setSku = mapQuoteLineItems.keyset();
        List<String> lstSku = new List<String>(setSku);
        //method to get Product Details using connectApi 
        if(!lstSku.isEmpty()){
            Map<String,PMC_DH_RequestForQuoteController.ConnectApiWrapper> mapProductDetail = PMC_DH_QuoteManagementControllerClass.getproductConnectApi(strCommunityId,strEffectiveAccountId,lstSku); 
            if(quote.SBQQ__LineItems__r != null){
                for(String quoteLineSku : mapQuoteLineItems.keyset()){
                    qliWrapper = new PMC_DH_RequestForQuoteWrapper.CartWrapper();
                    //method to assign product Details in Wrapper
                    PMC_DH_RequestForQuoteController.ConnectApiWrapper objconnectapiProduct = mapProductDetail.get(quoteLineSku);
                    qliWrapper.strProductName = objconnectapiProduct.strProductName;
                    qliWrapper.strSku = objconnectapiProduct.strSku;
                    qliWrapper.strProductId = objconnectapiProduct.strProductId;
                    qliWrapper.strProductUOM = mapQuoteLineItems.get(quoteLineSku)[0].strProductUOM;// Added as part of GPT-25411
                    qliWrapper.strImgSrc = objconnectapiProduct.strImgSrc;
                    qliWrapper.lstContractItems = mapQuoteLineItems.get(quoteLineSku);
                    Double intTotalQty = 0.00;// GDASF-10697 // GPT-HomeActive
                    for(PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper ciwrp : qliWrapper.lstContractItems)
                    {
                        intTotalQty += ciwrp.intQty;
                    }
                    qliWrapper.strTotalQty = intTotalQty;
                    lstQuoteLineItemsWrapper.add(qliWrapper);
                }
                productInfoWrapper.lstCartWrapper = lstQuoteLineItemsWrapper;
            }
        }
        return productInfoWrapper;
    }
    /*************************************************************************
* @method Name  : getQuoteOfOrigin
* @description  : Method to fetch Quote Summary
* @param         quote
* @return       : PMC_DH_ContractDetailsWrapper.QuoteOfOriginWrapper
*****************************************************************************/
    public static PMC_DH_ContractDetailsWrapper.QuoteOfOriginWrapper getQuoteOfOrigin(SBQQ__Quote__c quote){
        PMC_DH_ContractDetailsWrapper.QuoteOfOriginWrapper quoteOfOriginWrapper; 
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        quoteOfOriginWrapper = new PMC_DH_ContractDetailsWrapper.QuoteOfOriginWrapper();
        //assign contract values in Quote of origin wrapper
        if(quote != null){
            quoteOfOriginWrapper.strQuoteId = quote.Id;
            quoteOfOriginWrapper.strQuoteNumber = quote.Name;
            quoteOfOriginWrapper.strQuoteStatus = quote.SBQQ__Status__c;
        }
        return quoteOfOriginWrapper;
    }
    
    /*************************************************************************
* @method Name  : getContractSummary
* @description  : Method to get Contract Summary
* @param    strContractId
* @param    strCartId
* @return       : PMC_DH_RequestToDeliverWrapper.ContractSummaryWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_RequestToDeliverWrapper.ContractSummaryWrapper getContractSummary(String strContractId, String strCartId){ 
        PMC_DH_RequestToDeliverWrapper.ContractSummaryWrapper contSummary = new PMC_DH_RequestToDeliverWrapper.ContractSummaryWrapper();
        try{
            List<Contract> lstcont = [SELECT Id, PMC_CPQ_Contract_Blocked__c,PMC_CPQ_ContractType__c, StartDate, EndDate, tolabel(Status), AccountId, 
                                      SBQQ__Quote__c, SBQQ__Quote__r.Name, SBQQ__Quote__r.SBQQ__Status__c,SBQQ__Quote__r.PMC_CLM_DocumentNumber__c, SBQQ__Quote__r.PMC_CPQ_PO__c, SBQQ__Quote__r.PMC_CPQ_PrimaryContact__r.Name, SBQQ__Quote__r.SBQQ__PaymentTerms__c, SBQQ__Quote__r.PMC_DH_PaymentMethod__c, SBQQ__Quote__r.CurrencyIsoCode, SBQQ__Quote__r.PMC_CPQ_TotalQuantity__c, SBQQ__Quote__r.PMC_CPQ_ModeOfTransportation__c,
                                      (SELECT Id, PMC_CPQ_TotalOrderedQuantity__c, PMC_CPQ_TotalAvailableQuantity__c, SBQQ__Product__r.StockKeepingUnit,
                                       SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__c, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.Name, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingStreet, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingCity, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingState, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingPostalCode, SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__c,SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name, SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c, SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c, SBQQ__QuoteLine__r.SBQQ__NetPrice__c, SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c
                                       FROM SBQQ__Subscriptions__r) 
                                      FROM Contract where id=:strContractId AND Status=: CONTRACT_STATUS WITH SECURITY_ENFORCED];
            List<CartItem> lstCartItem = [SELECT Id, PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c 
                                          FROM CartItem 
                                          WHERE CartId =: strCartId 
                                          WITH SECURITY_ENFORCED];
            if(!lstcont.isEmpty()){
                contSummary.strContractNumber = PMC_DH_ConstantClass.DOC_TAG+lstcont[0].SBQQ__Quote__r.PMC_CLM_DocumentNumber__c; //ContractNumber;
                contSummary.strpoNumber = lstcont[0].SBQQ__Quote__r.PMC_CPQ_PO__c;
                contSummary.strContractType = lstCartItem[0].PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c;
                contSummary.datContractStartDate = lstcont[0].StartDate;
                contSummary.datContractEndDate = lstcont[0].EndDate;
                contSummary.strPaymentTermSelected = lstcont[0].SBQQ__Quote__r.SBQQ__PaymentTerms__c;
                List<String> lstStatusAndReason = PMC_DH_ContractManagementHelper.getContractStatusAndReason(lstcont[0]);
                contSummary.strContractStatus = lstStatusAndReason[0]; 
            }
            contSummary.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'Contract');
        }catch(Exception ex){
            contSummary.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
            //throw new AuraHandledException(ex.getMessage()+ex.getStackTraceString()); 
        }
        return contSummary;
    }
    
    
    /*************************************************************************
* @method Name  : getLineItemQty
* @description  : getLineItemQty
* @param         decQuantity
* @return       : Decimal
*/
    
    public static Decimal getLineItemQty(Decimal decQuantity){
        return (decQuantity!=NULL) ? decQuantity.longValue() : 0;  
    }
    
    /*************************************************************************
* @method Name  : getLineItemAmount
* @description  : getLineItemAmount
* @param         subItem
* @return       : Decimal
*/
    
    public static Decimal getLineItemAmount(SBQQ__Subscription__c subItem){
        return (subItem.SBQQ__QuoteLine__r.PMC_CPQ_LineTotalPrice__c!=NULL) ? subItem.SBQQ__QuoteLine__r.PMC_CPQ_LineTotalPrice__c : 0;  
    }


    /**
* @description 
* @author Hemant Giri Goswami | hegoswami@deloitte.com | 03-06-2024 
* @param mapShipFrom 
* @return PMC_DH_AddressWrapper.AddressViewDetails 
**/
public static PMC_DH_AddressWrapper.AddressViewDetails getMapShipsObject(Map<String,PMC_DH_AddressWrapper.AddressViewDetails> mapShipFrom)
{
    
    PMC_DH_AddressWrapper.AddressViewDetails wrpAdddress=new PMC_DH_AddressWrapper.AddressViewDetails();
    wrpAdddress.boolIsMutiple=TRUE;
    if(mapShipFrom.size()==1)
    {
        wrpAdddress=mapShipFrom.values()[0];
        wrpAdddress.boolIsMutiple=FALSE;
    }
     
    
    return wrpAdddress;
} 
}