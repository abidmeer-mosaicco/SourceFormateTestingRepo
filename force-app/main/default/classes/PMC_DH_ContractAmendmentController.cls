/** 
* @description Controller for fetching Contract Details 
* @author Sugunakar Rouhtu
* @last modified on 2024-May-09
* @last modified by Sugunakar Routhu
* Created On       : 2024-May-09
**/
public without sharing class  PMC_DH_ContractAmendmentController {
    
    
    /*************************************************************************
* @method Name  : getProductInfoforAmendment
* @description  : Method to fetch Contract product info for amended contracts
* @param         strCommunityId
* @param         strEffectiveAccountId
* @param         contract
* @return       : PMC_DH_RequestForQuoteWrapper
*****************************************************************************/
    
    public static PMC_DH_RequestForQuoteWrapper getProductInfoforAmendment(String strCommunityId,String strEffectiveAccountId,Contract contract){
        PMC_DH_RequestForQuoteWrapper productInfoWrapper = new PMC_DH_RequestForQuoteWrapper();
        List<PMC_DH_RequestForQuoteWrapper.CartWrapper> lstContractItemsWrapper = new List<PMC_DH_RequestForQuoteWrapper.CartWrapper>();
        PMC_DH_RequestForQuoteWrapper.CartWrapper contractItemsWrapper;
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        // get the latest Quote and line Item details for the amendment
        
        
        Map<String,List<PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper>> mapSubscriptions = getSubscriptionDetailsforAmendment(contract);
        
        Set<String> setSku = mapSubscriptions.keyset();
        List<String> lstSku = new List<String>(setSku);
        //method to get Product Details using connectApi 
        if(!lstSku.isEmpty()){
            Map<String,PMC_DH_RequestForQuoteController.ConnectApiWrapper> mapProductDetail = PMC_DH_QuoteManagementControllerClass.getproductConnectApi(strCommunityId,strEffectiveAccountId,lstSku); 
            
            if(contract.SBQQ__Subscriptions__r != null){
                for(String quoteLineSku : mapSubscriptions.keyset()){
                    contractItemsWrapper = new PMC_DH_RequestForQuoteWrapper.CartWrapper();
                    //method to assign product Details in Wrapper
                    PMC_DH_RequestForQuoteController.ConnectApiWrapper objconnectapiProduct = mapProductDetail.get(quoteLineSku);
                    contractItemsWrapper.strProductName = objconnectapiProduct.strProductName;
                    contractItemsWrapper.strSku = objconnectapiProduct.strSku;
                    contractItemsWrapper.strProductId = objconnectapiProduct.strProductId;
                    contractItemsWrapper.strImgSrc = objconnectapiProduct.strImgSrc;
                    contractItemsWrapper.strProductUOM = mapSubscriptions.get(quoteLineSku)[0].strProductUOM;
                    contractItemsWrapper.strProductUOMLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_UnitofMeasure__c.getDescribe(),contractItemsWrapper.strProductUOM);
                    contractItemsWrapper.lstContractItems = mapSubscriptions.get(quoteLineSku);
                    Double intTotalQty = 0.00;// GDASF-10697 /GPT-ActiveHome
                    for(PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper ciwrp : contractItemsWrapper.lstContractItems)
                    {
                        intTotalQty += ciwrp.intQty;
                    }
                    contractItemsWrapper.strTotalQty = intTotalQty;
                    lstContractItemsWrapper.add(contractItemsWrapper);
                }
                productInfoWrapper.lstCartWrapper = lstContractItemsWrapper;
            }
        }
        return productInfoWrapper;
    }
    
    /*************************************************************************
* @method Name  : getSubscriptionDetailsData
* @description  : Method to get the Subscription Details information 
* @param         subscription
* @return        PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper
*****************************************************************************/
    
    public static PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper  getSubscriptionDetailsData(SBQQ__Subscription__c subscription ){
        
        PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper objSubscriptionWrap = new PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper(); 
        objSubscriptionWrap.strContractItemId = subscription.Id;
        if(subscription.PMC_CPQ_TotalOrderedQuantity__c != null && subscription.PMC_CPQ_TotalAvailableQuantity__c != null){
            objSubscriptionWrap.intOrderedQty = subscription.PMC_CPQ_TotalOrderedQuantity__c.doubleValue();// GDASF-10697
            objSubscriptionWrap.intAvailableQty = subscription.PMC_CPQ_TotalAvailableQuantity__c.DoubleValue();// GDASF-10697
        }
        objSubscriptionWrap.intQty = subscription.SBQQ__QuoteLine__r.SBQQ__Quantity__c.doubleValue();// GDASF-10697
        PMC_DH_PicklistWrapper wrpShipTo = new PMC_DH_PicklistWrapper();
        PMC_DH_PicklistWrapper wrpShipFrom = new PMC_DH_PicklistWrapper();
        wrpShipTo.label = subscription.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.Name + ' ' + subscription.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingStreet + ', ' + subscription.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingCity + ', ' + subscription.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingState + ' ' + subscription.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingPostalCode;
        wrpShipTo.value = subscription.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__c;
        wrpShipFrom.label = subscription.SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name;
        wrpShipFrom.value = subscription.SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__c;
        objSubscriptionWrap.wrpShipTo = wrpShipTo;
        objSubscriptionWrap.wrpShipFrom = wrpShipFrom;
        objSubscriptionWrap.strContractType = subscription.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c ;
        objSubscriptionWrap.strDeliveryMode = subscription.SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c;
        objSubscriptionWrap.strIncoterm = subscription.SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c;
        objSubscriptionWrap.strProductUOM= subscription.SBQQ__QuoteLine__r.PMC_CPQ_UnitofMeasure__c;
        objSubscriptionWrap.strPackType = subscription.SBQQ__QuoteLine__r.PMC_CPQ_PackType__c;
        objSubscriptionWrap.strPackageType = subscription.SBQQ__QuoteLine__r.PMC_CPQ_PackageType__c;
        
        //GPT-43943
        objSubscriptionWrap.strDeliveryModeLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_ModeofTransportation__c.getDescribe(),subscription.SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c);
        objSubscriptionWrap.strIncotermLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_Incoterms1__c.getDescribe(),subscription.SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c);
        objSubscriptionWrap.strPackTypeLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_PackType__c.getDescribe(),subscription.SBQQ__QuoteLine__r.PMC_CPQ_PackType__c);
        objSubscriptionWrap.strPackageTypeLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_PackageType__c.getDescribe(),subscription.SBQQ__QuoteLine__r.PMC_CPQ_PackageType__c);
        objSubscriptionWrap.strProductUOMLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_UnitofMeasure__c.getDescribe(),subscription.SBQQ__QuoteLine__r.PMC_CPQ_UnitofMeasure__c);
        objSubscriptionWrap.strContractTypeLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_ContractType__c.getDescribe(),subscription.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c);
        
        return objSubscriptionWrap;
    }
    
    
    /*************************************************************************
* @method Name  : getQuoteSubscriptionDetailsMap
* @description  : Method to get the Quote Line Details information 
* @param         quoteLine
* @param         subscription
* @param         mapofSubscriptionId
* @param         mapSubscriptionsById
* @return        PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper
*****************************************************************************/
    public static PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper getQuoteSubscriptionDetailsMap(SBQQ__QuoteLine__c quoteLine, SBQQ__Subscription__c subscription , Map<String,Id> mapofSubscriptionId, Map<Id, SBQQ__Subscription__c> mapSubscriptionsById){
        PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper objSubscriptionWrap = new PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper();
        objSubscriptionWrap.strContractItemId = mapofSubscriptionId.get(PMC_DH_ContractManagementController.buildSubscriptionKey(subscription.SBQQ__contract__c, subscription, mapSubscriptionsById));
        if(subscription.PMC_CPQ_TotalOrderedQuantity__c != null && subscription.PMC_CPQ_TotalAvailableQuantity__c != null){
            objSubscriptionWrap.intOrderedQty = subscription.PMC_CPQ_TotalOrderedQuantity__c.doubleValue();// GDASF-10697
            objSubscriptionWrap.intAvailableQty = subscription.PMC_CPQ_TotalAvailableQuantity__c.DoubleValue();// GDASF-10697
        }
        objSubscriptionWrap.intQty = subscription.SBQQ__QuoteLine__r.SBQQ__Quantity__c.doubleValue();// GDASF-10697
        
        PMC_DH_PicklistWrapper wrpShipTo = new PMC_DH_PicklistWrapper();
        PMC_DH_PicklistWrapper wrpShipFrom = new PMC_DH_PicklistWrapper();
        wrpShipTo.label = quoteLine.PMC_CPQ_ShipTo__r.Name + ' ' + quoteLine.PMC_CPQ_ShipTo__r.ShippingStreet + ', ' + quoteLine.PMC_CPQ_ShipTo__r.ShippingCity + ', ' + quoteLine.PMC_CPQ_ShipTo__r.ShippingState + ' ' + quoteLine.PMC_CPQ_ShipTo__r.ShippingPostalCode;
        wrpShipTo.value = quoteLine.PMC_CPQ_ShipTo__c;
        wrpShipFrom.label = quoteLine.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name;
        wrpShipFrom.value = quoteLine.PMC_CPQ_ProductLocation__c;
        objSubscriptionWrap.wrpShipTo = wrpShipTo;
        objSubscriptionWrap.wrpShipFrom = wrpShipFrom;
        objSubscriptionWrap.strContractType = quoteLine.PMC_CPQ_ContractType__c ;
        objSubscriptionWrap.strDeliveryMode = quoteLine.PMC_CPQ_ModeofTransportation__c;
        objSubscriptionWrap.strIncoterm = quoteLine.PMC_CPQ_Incoterms1__c;
        objSubscriptionWrap.strProductUOM= quoteLine.PMC_CPQ_UnitofMeasure__c;
        objSubscriptionWrap.strPackType = quoteLine.PMC_CPQ_PackType__c;
        objSubscriptionWrap.strPackageType = quoteLine.PMC_CPQ_PackageType__c;
        //objSubscriptionWrap.decNetUnitPrice = subscription.SBQQ__QuoteLine__r.SBQQ__NetPrice__c;
        //Checking if map contains sku and assigning the Subscription Wrapper
        
        //GPT-43943
        objSubscriptionWrap.strDeliveryModeLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_ModeofTransportation__c.getDescribe(),quoteLine.PMC_CPQ_ModeofTransportation__c);
        objSubscriptionWrap.strIncotermLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_Incoterms1__c.getDescribe(),quoteLine.PMC_CPQ_Incoterms1__c);
        objSubscriptionWrap.strPackTypeLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_PackType__c.getDescribe(),quoteLine.PMC_CPQ_PackType__c);
        objSubscriptionWrap.strPackageTypeLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_PackageType__c.getDescribe(),quoteLine.PMC_CPQ_PackageType__c);
        objSubscriptionWrap.strProductUOMLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_UnitofMeasure__c.getDescribe(),quoteLine.PMC_CPQ_UnitofMeasure__c);
        objSubscriptionWrap.strContractTypeLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_ContractType__c.getDescribe(),quoteLine.PMC_CPQ_ContractType__c);
        
        return objSubscriptionWrap;
    }
    
    
    /*************************************************************************
* @method Name  : getSubscriptionDetailsforAmendment
* @description  : Method to get the Subscription Details information 
* @param         contract
* @return        Map<String,List<PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper>>
*************************************************************************/
    
    public static Map<String,List<PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper>> getSubscriptionDetailsforAmendment(Contract contract){
        
        Map<String,List<PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper>> mapSubscriptions = new Map<String,List<PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper>>();
        
        
        Map<String, SBQQ__QuoteLine__c > latestAmenededLineItemsMap = new Map<String, SBQQ__QuoteLine__c >();
        Map<String,Id> mapofSubscriptionId = PMC_DH_ContractManagementController.getMapOfSubscriptionIds(new List<Contract>{contract});
        Map<Id, SBQQ__Subscription__c> mapSubscriptionsById = new Map<Id, SBQQ__Subscription__c>(contract.SBQQ__Subscriptions__r);
        List<SBQQ__QuoteLine__c> quoteLineList = [SELECT Id, PMC_CLM_QuoteLineNumber__c,SBQQ__Quote__r.Name,SBQQ__Quote__c,SBQQ__Quote__r.SBQQ__Status__c,
                                                  PMC_CPQ_ShipTo__c, PMC_CPQ_ShipTo__r.Name, PMC_CPQ_ShipTo__r.ShippingStreet, SBQQ__Quantity__c,
                                                  PMC_CPQ_ShipTo__r.ShippingCity, PMC_CPQ_ShipTo__r.ShippingState, PMC_CPQ_ShipTo__r.ShippingPostalCode,
                                                  PMC_CPQ_ProductLocation__c,PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name, 
                                                  //toLabel( PMC_CPQ_Incoterms1__c) labelIncoterm, toLabel( PMC_CPQ_ModeofTransportation__c) labelMOT, toLabel( PMC_CPQ_ContractType__c) labelContractType, toLabel(PMC_CPQ_PackageType__c) labelPackageType, toLabel(PMC_CPQ_PackType__c) labelPackType, toLabel(PMC_CPQ_UnitofMeasure__c) labelUOM,
                                                  PMC_CPQ_Incoterms1__c, PMC_CPQ_ModeofTransportation__c, SBQQ__NetPrice__c, PMC_CPQ_ContractType__c, PMC_CPQ_PackageType__c, PMC_CPQ_PackType__c,  
                                                  PMC_CPQ_UnitofMeasure__c, SBQQ__Product__c,SBQQ__Product__r.StockKeepingUnit
                                                  FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=:contract.PMC_CPQ_LatestQuote__c 
                                                  WITH SECURITY_ENFORCED];
        
        for( SBQQ__QuoteLine__c qline : quoteLineList){
            latestAmenededLineItemsMap.put(String.ValueOf(qline.PMC_CLM_QuoteLineNumber__c), qline);
        }
        
        for(SBQQ__Subscription__c subscription : contract.SBQQ__Subscriptions__r){
            if((latestAmenededLineItemsMap.containsKey(subscription.SBQQ__QuoteLine__r.PMC_CLM_QuoteLineNumber__c)) && 
               (latestAmenededLineItemsMap.get(subscription.SBQQ__QuoteLine__r.PMC_CLM_QuoteLineNumber__c).SBQQ__Quote__c == subscription.SBQQ__QuoteLine__r.SBQQ__Quote__c)){
                   // need to get the Information from new Quote subcription
                   PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper objSubscriptionWrap = getSubscriptionDetailsData(subscription);
                   
                   if(!mapSubscriptions.containsKey(subscription.SBQQ__Product__r.StockKeepingUnit))
                   {
                       mapSubscriptions.put(subscription.SBQQ__Product__r.StockKeepingUnit, new List<PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper>());
                   }
                   mapSubscriptions.get(subscription.SBQQ__Product__r.StockKeepingUnit).add(objSubscriptionWrap);
               } 
            else{
                
                SBQQ__QuoteLine__c quoteLine = latestAmenededLineItemsMap.get(String.ValueOf(subscription.SBQQ__QuoteLine__r.PMC_CLM_QuoteLineNumber__c));
                PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper objSubscriptionWrap = getQuoteSubscriptionDetailsMap(quoteLine, subscription, mapofSubscriptionId, mapSubscriptionsById);
                if(!mapSubscriptions.containsKey(quoteLine.SBQQ__Product__r.StockKeepingUnit))
                {
                    mapSubscriptions.put(quoteLine.SBQQ__Product__r.StockKeepingUnit, new List<PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper>());
                }
                mapSubscriptions.get(quoteLine.SBQQ__Product__r.StockKeepingUnit).add(objSubscriptionWrap);
            }
            
        }
        
        return mapSubscriptions;
        
        
    }
    
    /*************************************************************************
* @method Name  : getContractSummarywithAmendment
* @description  : Method to fetch Contract Summary
* @param         contract
* @param         isAmendment
* @return       : PMC_DH_ContractDetailsWrapper.ContractSummaryWrapper
*****************************************************************************/
    public static PMC_DH_ContractDetailsWrapper.ContractSummaryWrapper getContractSummarywithAmendment(Contract contract, Boolean isAmendment){
        PMC_DH_ContractDetailsWrapper.ContractSummaryWrapper contractSummaryWrapper; 
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        contractSummaryWrapper = new PMC_DH_ContractDetailsWrapper.ContractSummaryWrapper();
        //assign contract values in Contract summary wrapper
        if(contract != null){
            if(isAmendment){
                contractSummaryWrapper.strPoNumber = contract.PMC_CPQ_LatestQuote__r.PMC_CPQ_PO__c;
                contractSummaryWrapper.strCustomerName = contract.PMC_CPQ_LatestQuote__r.PMC_CPQ_PrimaryContact__r.Name;
                contractSummaryWrapper.datContractStartDate = contract.PMC_CPQ_LatestQuote__r.SBQQ__StartDate__c; //GPT-35789
                contractSummaryWrapper.datContractEndDate = contract.PMC_CPQ_LatestQuote__r.SBQQ__EndDate__c; //GPT-35789
            }
            else{
                contractSummaryWrapper.strPoNumber = contract.SBQQ__Quote__r.PMC_CPQ_PO__c;
                contractSummaryWrapper.strCustomerName = contract.SBQQ__Quote__r.PMC_CPQ_PrimaryContact__r.Name;
                contractSummaryWrapper.datContractStartDate = contract.StartDate; //GPT-35789
                contractSummaryWrapper.datContractEndDate = contract.EndDate; //GPT-35789
            }
            List<String> lstStatusAndReason = PMC_DH_ContractManagementHelper.getContractStatusAndReason(contract);
            contractSummaryWrapper.strSummaryStatus = lstStatusAndReason[0]; // Active/Inactive
            contractSummaryWrapper.strInactiveReason = lstStatusAndReason[1]; // Completed/Expired if Status = 'Inactive'
        }
        return contractSummaryWrapper;
    }
    
    /*************************************************************************
* @method Name  : getPaymentInfowithAmendment
* @description  : Method to fetch Payment Info
* @param         contract
* @param         isAmendment
* @return       : PMC_DH_QuoteDetailsWrapper.PaymentInformationWrapper
*****************************************************************************/
    public static PMC_DH_QuoteDetailsWrapper.PaymentInformationWrapper getPaymentInfowithAmendment(Contract contract, Boolean isAmendment){
        PMC_DH_QuoteDetailsWrapper.PaymentInformationWrapper paymentInfoWrapper; 
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        paymentInfoWrapper = new PMC_DH_QuoteDetailsWrapper.PaymentInformationWrapper();
        //assign contract values in Payment information wrapper
        if(contract != null){
            if(isAmendment){
                paymentInfoWrapper.strPaymentTermSelected = contract.PMC_CPQ_LatestQuote__r.SBQQ__PaymentTerms__c;
                paymentInfoWrapper.strPaymentMethodSelected = contract.PMC_CPQ_LatestQuote__r.PMC_DH_PaymentMethod__c;
                paymentInfoWrapper.strCurrencySelected = contract.PMC_CPQ_LatestQuote__r.CurrencyIsoCode;
            }
            else{
                paymentInfoWrapper.strPaymentTermSelected = contract.SBQQ__Quote__r.SBQQ__PaymentTerms__c;
                paymentInfoWrapper.strPaymentMethodSelected = contract.SBQQ__Quote__r.PMC_DH_PaymentMethod__c;
                paymentInfoWrapper.strCurrencySelected = contract.SBQQ__Quote__r.CurrencyIsoCode;
            }
            paymentInfoWrapper.boolIsBoletoAvailable = false; //to be changed once Boleto feature is ready
        }
        return paymentInfoWrapper;
    }
    
}