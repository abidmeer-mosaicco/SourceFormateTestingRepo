/** 
* @description Controller for fetching Contract Details 
* @author Nikhilesh
* @last modified on 2023-August-11
* @last modified by Nikhilesh
* Created On       :2023-June-28
**/
public without sharing class PMC_DH_ContractManagementController {
    public final static String ACTION_PENDING_STATUS = 'Action Pending';
    public final static String AMENDMENT_TYPE = 'Amendment';
    private final static String KEY_SEPARATOR = '-';
    /*************************************************************************
* @method Name  : getContractDetails
* @description  : Method to get the Contract Details Page info in wrapper class 
* @param        strCommunityId 
* @param        strEffectiveAccountId 
* @param        strContractId
* @return       : PMC_DH_ContractDetailsWrapper
*****************************************************************************/
    @AuraEnabled(cacheable=true)
    public static PMC_DH_ContractDetailsWrapper getContractDetails(String strCommunityId,String strEffectiveAccountId, String strContractId){
        PMC_DH_ContractDetailsWrapper contractDetailsWrapper; 
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            contractDetailsWrapper = new PMC_DH_ContractDetailsWrapper();
            contractDetailsWrapper.boolIsPOEditable=false;
            // get the sObject type from the Id passed (SBQQ__Quote__c or Contract)
            Id contractOrQuoteId = Id.valueOf(strContractId);
            String sobjectType = contractOrQuoteId.getSObjectType().getDescribe().getName();
            if(sobjectType == 'SBQQ__Quote__c'){
                contractDetailsWrapper = PMC_DH_ContractManagementHelper.getQuoteDetails(strCommunityId, strEffectiveAccountId, strContractId);
            }
            else{ //sobjectType == 'Contract'

                // method to fetch Contract details
                Contract contract = getContract(strContractId, strEffectiveAccountId);
                Boolean isAmendment;
                if(contract.PMC_CPQ_LatestQuote__c != null && contract.PMC_CPQ_LatestQuote__r.SBQQ__Type__c == AMENDMENT_TYPE){
                // indicator that quote/contract has gone through amendment
                isAmendment = true;
                // method to assign Contract Number
                contractDetailsWrapper.strContractNumber = PMC_DH_ConstantClass.DOC_TAG + contract.PMC_CPQ_LatestQuote__r.PMC_CLM_DocumentNumber__c;
                // method to assign Quote Id value
                contractDetailsWrapper.strQuoteId = contract.PMC_CPQ_LatestQuote__c;
                contractDetailsWrapper.productInfoWrapper = PMC_DH_ContractAmendmentController.getProductInfoforAmendment(strCommunityId,strEffectiveAccountId,contract);
                }
                else{
                    // indicator that quote/contract has NOT gone through amendment
                    isAmendment = false;
                    // method to assign Contract Number
                    contractDetailsWrapper.strContractNumber =PMC_DH_ConstantClass.DOC_TAG+contract.SBQQ__Quote__r.PMC_CLM_DocumentNumber__c;
                    // method to assign Quote Id value
                    contractDetailsWrapper.strQuoteId = contract.SBQQ__Quote__c;
                    contractDetailsWrapper.productInfoWrapper = getProductInfo(strCommunityId,strEffectiveAccountId,contract);
                }
                // method to assign Contract Summary details in a wrapper
                contractDetailsWrapper.contractSummaryWrapper = PMC_DH_ContractAmendmentController.getContractSummarywithAmendment(contract,isAmendment);
                // method to assign Payment Info details in a wrapper
                contractDetailsWrapper.paymentInfoWrapper = PMC_DH_ContractAmendmentController.getPaymentInfowithAmendment(contract, isAmendment);                

                // method to assign Quote of Origin details in a wrapper
                contractDetailsWrapper.lstQuoteOfOriginWrapper = getQuoteOfOrigin(contract);
                if(contract.SBQQ__Quote__r.PMC_CPQ_ContractStageName__c==null)
                {
                    contractDetailsWrapper.boolIsPOEditable=true;
                }
                contractDetailsWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'ContractRecord');
                if(String.isBlank(contract.id)){
                    contractDetailsWrapper= new PMC_DH_ContractDetailsWrapper();
                    contractDetailsWrapper.statusCodeMessage=PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.ACCESS_DENIED_CODE, PMC_DH_ConstantClass.GETCONTRACT_ACESSDENIED); 
                }
                        
            } 
            
        }
        catch(Exception ex){
            contractDetailsWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); 
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
            //throw new AuraHandledException(ex.getMessage()+ex.getLineNumber());
        }
        return contractDetailsWrapper;
    }
    
    /*************************************************************************
* @method Name  : getContract
* @description  : Method to fetch Contract Details
* @param         strContractId
* @param		 strEffectiveAccountId
* @return       : Contract
*****************************************************************************/
    public static Contract getContract(String strContractId, String strEffectiveAccountId){
        List<Contract> lstContract=new List<Contract>();
        Contract contract=new Contract();
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            // fetch Contract and SBQQ__Subscription__c using SOQL 
            
            List<Contract> lstContractData = [ SELECT Id, PMC_CPQ_Contract_Blocked__c, PMC_CPQ_LatestQuote__c, PMC_CPQ_LatestQuote__r.SBQQ__Type__c, PMC_CPQ_LatestQuote__r.PMC_CPQ_PO__c, PMC_CPQ_LatestQuote__r.PMC_CPQ_PrimaryContact__r.Name, PMC_CPQ_LatestQuote__r.SBQQ__PaymentTerms__c, PMC_CPQ_LatestQuote__r.PMC_DH_PaymentMethod__c, PMC_CPQ_LatestQuote__r.CurrencyIsoCode,
                                            (SELECT Id, CreatedDate, SBQQ__Quantity__c, SBQQ__RevisedSubscription__c, SBQQ__Contract__c, SBQQ__QuoteLine__r.SBQQ__Number__c,SBQQ__Quoteline__r.SBQQ__Quote__c, SBQQ__Quoteline__r.PMC_CLM_QuoteLineNumber__c
                                            FROM SBQQ__Subscriptions__r Order By CreatedDate DESC, Id DESC )
                                            FROM Contract WHERE Id =: strContractId  WITH SECURITY_ENFORCED Order By CreatedDate DESC]; //PMC_CPQ_LatestQuote__c added for GPT-40342
            Map<String, Id> mapUniqueSubscriptionIds = getMapOfSubscriptionIds(lstContractData);
            lstContract = [SELECT Id, PMC_CPQ_Contract_Blocked__c, PMC_CPQ_ContractType__c, StartDate, EndDate, tolabel(Status) contractStatus,Status, AccountId,SBQQ__Quote__r.PMC_CPQ_ContractStageName__c , 
                        SBQQ__Quote__c, SBQQ__Quote__r.Name, SBQQ__Quote__r.SBQQ__Status__c, SBQQ__Quote__r.PMC_CLM_DocumentNumber__c, SBQQ__Quote__r.PMC_CPQ_PO__c, 
                        SBQQ__Quote__r.PMC_CPQ_PrimaryContact__r.Name, toLabel(SBQQ__Quote__r.SBQQ__PaymentTerms__c), SBQQ__Quote__r.PMC_DH_PaymentMethod__c, 
                        SBQQ__Quote__r.CurrencyIsoCode, SBQQ__Quote__r.PMC_CPQ_TotalQuantity__c,
                        PMC_CPQ_LatestQuote__c, PMC_CPQ_LatestQuote__r.SBQQ__Type__c, PMC_CPQ_LatestQuote__r.PMC_CPQ_PO__c, 
                        PMC_CPQ_LatestQuote__r.PMC_CPQ_PrimaryContact__r.Name, PMC_CPQ_LatestQuote__r.PMC_CLM_DocumentNumber__c, 
                        toLabel(PMC_CPQ_LatestQuote__r.SBQQ__PaymentTerms__c), PMC_CPQ_LatestQuote__r.PMC_DH_PaymentMethod__c, PMC_CPQ_LatestQuote__r.CurrencyIsoCode, PMC_CPQ_LatestQuote__r.SBQQ__StartDate__c, PMC_CPQ_LatestQuote__r.SBQQ__EndDate__c,
                        (SELECT Id, CreatedDate, SBQQ__Quantity__c, SBQQ__RevisedSubscription__c, PMC_CPQ_TotalOrderedQuantity__c, PMC_CPQ_TotalAvailableQuantity__c, SBQQ__Product__r.StockKeepingUnit,
                            SBQQ__Quoteline__r.SBQQ__Quote__r.Name,SBQQ__Quoteline__r.SBQQ__Quote__c,SBQQ__Quoteline__r.SBQQ__Quote__r.SBQQ__Status__c,
                            SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__c, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.Name, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingStreet, 
                            SBQQ__QuoteLine__r.SBQQ__Quantity__c,
                            SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingCity, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingState,
                            SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingPostalCode, SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__c,
                            SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name,//toLabel(SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c) QuoteLIneIncoterm,
                            SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c,
                            //toLabel(SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c) QuotelineMOT, 
                            SBQQ__QuoteLine__r.SBQQ__NetPrice__c,SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c,
                            //toLabel(SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c) QuotelineContractType, 
                            SBQQ__QuoteLine__r.PMC_CPQ_PackageType__c, SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c,SBQQ__contract__c,
                            SBQQ__QuoteLine__r.PMC_CPQ_PackType__c,SBQQ__QuoteLine__r.PMC_CPQ_UnitofMeasure__c,SBQQ__QuoteLine__r.PMC_CLM_QuoteLineNumber__c
                            FROM SBQQ__Subscriptions__r WHERE Id IN : mapUniqueSubscriptionIds.values() )
                        // Order By CreatedDate DESC )
                        FROM Contract WHERE Id =: strContractId AND AccountId =: strEffectiveAccountId WITH SECURITY_ENFORCED]; //PMC_CPQ_LatestQuote__c added for GPT-40342
            if(!lstContract.isEmpty()){
                contract = lstContract[0];
            }
        return contract;
    }
    
    
    
    /*************************************************************************
* @method Name  : getMapOfSubscriptionIds
* @description  : Method to fetch getMapOfSubscriptionIds
* @param         lstContract
* @return       : Map<String,Id>
*****************************************************************************/
    
    public static Map<String,Id> getMapOfSubscriptionIds(List<Contract> lstContract){
        Map<String, SBQQ__Subscription__c> mapUniqueSubscriptions = new Map<String, SBQQ__Subscription__c>();
        for(Contract cont : lstContract){
            Map<Id, SBQQ__Subscription__c> mapSubscriptionsById = new Map<Id, SBQQ__Subscription__c>(cont.SBQQ__Subscriptions__r);
            for(SBQQ__Subscription__c subscription : cont.SBQQ__Subscriptions__r){
                String unquieString = buildSubscriptionKey(cont.Id, subscription, mapSubscriptionsById);
                SBQQ__Subscription__c selectedSubscription = mapUniqueSubscriptions.get(unquieString);
                if(selectedSubscription == null || isPreferredContractItem(subscription, selectedSubscription)){
                    mapUniqueSubscriptions.put(unquieString, subscription);
                }
            }
        }
        Map<String, Id> mapUniqueSubscriptionIds = new Map<String, Id>();
        for(String strSubscriptionKey : mapUniqueSubscriptions.keySet()){
            mapUniqueSubscriptionIds.put(strSubscriptionKey, mapUniqueSubscriptions.get(strSubscriptionKey).Id);
        }
        return mapUniqueSubscriptionIds;
    }

    /*************************************************************************
* @method Name  : buildSubscriptionKey
* @description  : Method to build the unique contract line key for a subscription
* @param         strContractId
* @param         subscription
* @param         mapSubscriptionsById
* @return       : String
*****************************************************************************/

    public static String buildSubscriptionKey(Id strContractId, SBQQ__Subscription__c subscription, Map<Id, SBQQ__Subscription__c> mapSubscriptionsById){
        String strContractLineNumber = subscription.SBQQ__QuoteLine__r != null ? subscription.SBQQ__QuoteLine__r.PMC_CLM_QuoteLineNumber__c : null;
        if(String.isNotBlank(strContractLineNumber)){
            return strContractId + KEY_SEPARATOR + strContractLineNumber;
        }
        return strContractId + KEY_SEPARATOR + resolveOriginalSubscriptionId(subscription, mapSubscriptionsById);
    }

    /*************************************************************************
* @method Name  : resolveOriginalSubscriptionId
* @description  : Method to walk the amendment revision chain up to the original subscription
* @param         subscription
* @param         mapSubscriptionsById
* @return       : Id
*****************************************************************************/

    private static Id resolveOriginalSubscriptionId(SBQQ__Subscription__c subscription, Map<Id, SBQQ__Subscription__c> mapSubscriptionsById){
        Id originalSubscriptionId = subscription.Id;
        SBQQ__Subscription__c currentSubscription = subscription;
        Set<Id> setVisitedSubscriptionIds = new Set<Id>();
        while(currentSubscription != null && currentSubscription.SBQQ__RevisedSubscription__c != null && !setVisitedSubscriptionIds.contains(currentSubscription.Id)){
            setVisitedSubscriptionIds.add(currentSubscription.Id);
            originalSubscriptionId = currentSubscription.SBQQ__RevisedSubscription__c;
            currentSubscription = mapSubscriptionsById != null ? mapSubscriptionsById.get(originalSubscriptionId) : null;
        }
        return originalSubscriptionId;
    }

    /*************************************************************************
* @method Name  : isPreferredContractItem
* @description  : Method to decide which subscription represents the contract line
* @param         subscriptionCandidate
* @param         subscriptionSelected
* @return       : Boolean
*****************************************************************************/

    private static Boolean isPreferredContractItem(SBQQ__Subscription__c subscriptionCandidate, SBQQ__Subscription__c subscriptionSelected){
        Boolean isCandidateReversal = isReversalContractItem(subscriptionCandidate);
        Boolean isSelectedReversal = isReversalContractItem(subscriptionSelected);
        if(isCandidateReversal != isSelectedReversal){
            return !isCandidateReversal;
        }
        if(subscriptionCandidate.CreatedDate != subscriptionSelected.CreatedDate){
            return subscriptionCandidate.CreatedDate > subscriptionSelected.CreatedDate;
        }
        return String.valueOf(subscriptionCandidate.Id) > String.valueOf(subscriptionSelected.Id);
    }

    /*************************************************************************
* @method Name  : isReversalContractItem
* @description  : Method to identify amendment reversal subscriptions
* @param         subscription
* @return       : Boolean
*****************************************************************************/

    private static Boolean isReversalContractItem(SBQQ__Subscription__c subscription){
        return subscription.SBQQ__Quantity__c != null && subscription.SBQQ__Quantity__c < 0;
    }
    
    /*************************************************************************
* @method Name  : getSubscriptionDetails
* @description  : Method to fetch subscription Details
* @param         contract
* @return       : Map<String,List<PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper>>
*****************************************************************************/
    public static Map<String,List<PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper>> getSubscriptionDetails(Contract contract){
        Map<String,List<PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper>> mapSubscriptions = new Map<String,List<PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper>>();
        PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper objSubscriptionWrap;
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        //fetching the subscription Details and assigning the values to wrapper
        if(contract.SBQQ__Subscriptions__r != null){
            for(SBQQ__Subscription__c subscription : contract.SBQQ__Subscriptions__r)
            { 
                objSubscriptionWrap = new PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper(); 
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
                objSubscriptionWrap.strContractType =subscription.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c;
                objSubscriptionWrap.strDeliveryMode = subscription.SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c;
                objSubscriptionWrap.strIncoterm = subscription.SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c;
                objSubscriptionWrap.strProductUOM= subscription.SBQQ__QuoteLine__r.PMC_CPQ_UnitofMeasure__c;
                objSubscriptionWrap.strPackType = subscription.SBQQ__QuoteLine__r.PMC_CPQ_PackType__c;
                objSubscriptionWrap.strPackageType = subscription.SBQQ__QuoteLine__r.PMC_CPQ_PackageType__c;
                objSubscriptionWrap.strDeliveryModeLabel=PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_ModeofTransportation__c.getDescribe(),subscription.SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c);
                objSubscriptionWrap.strIncotermLabel=PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_Incoterms1__c.getDescribe(),subscription.SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c);
                objSubscriptionWrap.strPackTypeLabel=PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_PackType__c.getDescribe(),subscription.SBQQ__QuoteLine__r.PMC_CPQ_PackType__c);
                objSubscriptionWrap.strPackageTypeLabel=PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_PackageType__c.getDescribe(),subscription.SBQQ__QuoteLine__r.PMC_CPQ_PackageType__c);
                objSubscriptionWrap.strProductUOMLabel  = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_UnitofMeasure__c.getDescribe(),subscription.SBQQ__QuoteLine__r.PMC_CPQ_UnitofMeasure__c);
                objSubscriptionWrap.strContractTypeLabel= PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_ContractType__c.getDescribe(),subscription.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c);
                //objSubscriptionWrap.decNetUnitPrice = subscription.SBQQ__QuoteLine__r.SBQQ__NetPrice__c;
                //Checking if map contains sku and assigning the Subscription Wrapper
                
                if(!mapSubscriptions.containsKey(subscription.SBQQ__Product__r.StockKeepingUnit))
                {
                    mapSubscriptions.put(subscription.SBQQ__Product__r.StockKeepingUnit, new List<PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper>());
                }
                mapSubscriptions.get(subscription.SBQQ__Product__r.StockKeepingUnit).add(objSubscriptionWrap);
            }
        }
        return mapSubscriptions;
    }
    
    /*************************************************************************
* @method Name  : getProductInfo
* @description  : Method to fetch Contract product info
* @param         strCommunityId
* @param         strEffectiveAccountId
* @param         contract
* @return       : PMC_DH_RequestForQuoteWrapper
*****************************************************************************/
    public static PMC_DH_RequestForQuoteWrapper getProductInfo(String strCommunityId,String strEffectiveAccountId,Contract contract){
        PMC_DH_RequestForQuoteWrapper productInfoWrapper = new PMC_DH_RequestForQuoteWrapper();
        List<PMC_DH_RequestForQuoteWrapper.CartWrapper> lstContractItemsWrapper = new List<PMC_DH_RequestForQuoteWrapper.CartWrapper>();
        PMC_DH_RequestForQuoteWrapper.CartWrapper contractItemsWrapper;
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        //method to get subscription Details
        Map<String,List<PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper>> mapSubscriptions = getSubscriptionDetails(contract);
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
* @method Name  : getQuoteOfOrigin
* @description  : Method to fetch Contract Summary
* @param         contract
* @return       : PMC_DH_ContractDetailsWrapper.QuoteOfOriginWrapper
*****************************************************************************/
    public static List<PMC_DH_ContractDetailsWrapper.QuoteOfOriginWrapper> getQuoteOfOrigin(Contract contract){
        List<PMC_DH_ContractDetailsWrapper.QuoteOfOriginWrapper> lstQuotes=new List<PMC_DH_ContractDetailsWrapper.QuoteOfOriginWrapper>();
        Set<Id> setQuoteId=new Set<Id>();
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        
        //assign contract values in Quote of origin wrapper
        for(SBQQ__Subscription__c subscription :[SELECT ID,SBQQ__QUOTELINE__R.SBQQ__QUOTE__C,SBQQ__QUOTELINE__R.SBQQ__QUOTE__R.NAME,
                                                SBQQ__QUOTELINE__R.SBQQ__QUOTE__R.SBQQ__STATUS__C FROM SBQQ__SUBSCRIPTION__C WHERE SBQQ__CONTRACT__C=:CONTRACT.ID
                                                AND SBQQ__QUOTELINE__R.SBQQ__QUOTE__R.SBQQ__MasterContract__c =null AND SBQQ__QUOTELINE__R.SBQQ__QUOTE__R.SBQQ__Type__c !=: AMENDMENT_TYPE 
                                                WITH SECURITY_ENFORCED])
        { 
            if(!setQuoteId.contains(subscription.SBQQ__Quoteline__r.SBQQ__Quote__c))
            {
                PMC_DH_ContractDetailsWrapper.QuoteOfOriginWrapper quoteOfOriginWrapper = new PMC_DH_ContractDetailsWrapper.QuoteOfOriginWrapper();
                quoteOfOriginWrapper.strQuoteId=subscription.SBQQ__Quoteline__r.SBQQ__Quote__c;
                quoteOfOriginWrapper.strQuoteNumber=subscription.SBQQ__Quoteline__r.SBQQ__Quote__r.Name;
                quoteOfOriginWrapper.strQuoteStatus=subscription.SBQQ__Quoteline__r.SBQQ__Quote__r.SBQQ__Status__c;
                lstQuotes.add(quoteOfOriginWrapper);
                setQuoteId.add(subscription.SBQQ__Quoteline__r.SBQQ__Quote__c);
            }            
        }
        return lstQuotes;
    }
    
    /*************************************************************************
* @method Name  : updateContractPoNumber
* @description  : Method to update Contract PO Number
* @param         strQuoteId
* @param         strPoNumber
* @return       : PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper updateContractPoNumber(String strQuoteId, String strPoNumber){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        SBQQ__Quote__c objQuote = new SBQQ__Quote__c();
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            objQuote.Id = strQuoteId;
            objQuote.PMC_CPQ_PO__c = strPoNumber;
            if(Schema.sObjectType.SBQQ__Quote__c.isUpdateable()){
                update objQuote; 
            }
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'PONumberUpdate');
        }
        catch (Exception ex) {
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return result;
    }
    /*************************************************************************
* @method Name  : contractRequestSignature
* @description  : Method to request siganture for action pending contracts on detail page.
* @param         strEffectiveAccountId
* @param         strQuoteId
* @return       : None
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper contractRequestSignature(String strEffectiveAccountId, String strQuoteId){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        try{
            Account objAccRecord;
            if(Schema.sObjectType.Account.isAccessible()){
                objAccRecord = [SELECT Id, Owner.Id  FROM Account WHERE Id=:strEffectiveAccountId and Owner.Id!=NULL WITH SECURITY_ENFORCED];
            }
            if(objAccRecord!=Null){
                Task tsk = new Task();
                tsk.Subject =  PMC_DH_ConstantClass.TASK_SUBJECT_FOR_CONTRACT;
                tsk.Status = 'Open';
                tsk.Description =  PMC_DH_ConstantClass.TASK_SUBJECT_FOR_CONTRACT;
                tsk.Priority = 'High';
                tsk.WhatId = strQuoteId;
                tsk.OwnerId = objAccRecord.Owner.Id; 
                if(Schema.sObjectType.Task.isCreateable()){
                    insert tsk;
                }
                result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'RequestSignature');
            }else{
                result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('001', 'RequestSignature');
            }
        }Catch(Exception ex){
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return result;
    }
}