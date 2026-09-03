/**
* @description : class for the methods that will be used for RFQ
* @author      : Rohan Undale
* @last modified on  : 07-20-2024
* @last modified by  : Dev Team 
**/
public without sharing class PMC_DH_ContractUtil {
    private static final String SUCCESS_CODE = '002'; 
    private static final String ERROR_CODE = '100';
    private static final String SHIPMENT = 'Shipment';
    private static final String ERROR = 'All';
    private static final String STATUS = 'RTD';
    private static final String CONTRACT_STATUS = 'Activated';
    public final static String AMENDMENT_TYPE = 'Amendment';
    
    /*************************************************************************
* @method Name  : addCartItems
* @description : Method to add new cart items
* @param strCartId
* @param lstCartWrapper
* @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper addCartItems(String strCartId,List<PMC_DH_RequestToDeliverWrapper.CartWrapper> lstCartWrapper){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        List<CartItem> lstCartitems = new List<CartItem>();
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            
            List<CartDeliveryGroup> lstCartDeliverGrp= [select id from CartDeliveryGroup where cartid=:strCartId  WITH SECURITY_ENFORCED limit 1];
            for(PMC_DH_RequestToDeliverWrapper.CartWrapper cartWrap : lstCartWrapper){
                for(PMC_DH_RequestToDeliverWrapper.CartItemWrapper cartItemWrap : cartWrap.lstCartItems){
                    CartItem objCartItem = new CartItem();
                    if(String.isBlank(cartItemWrap.strCartItemId)){//insert
                        objCartItem.CartId = strCartId;
                    }
                    if(String.isNotBlank(cartItemWrap.strCartItemId)){
                        objCartItem.Id = cartItemWrap.strCartItemId;
                    }
                    
                    objCartItem.Name = cartWrap.strProductName;
                    objCartItem.CartDeliveryGroupId = lstCartDeliverGrp[0].id;
                    objCartItem.Product2Id = cartWrap.strProductId; 
                    objCartItem.Type = PMC_DH_ConstantClass.PRODUCT_TYPE;
                    objCartItem.Quantity = cartItemWrap.intQuantity;
                    objCartItem.PMC_DH_ShipTo__c =cartItemWrap.strShipTo;
                    objCartItem.PMC_DH_DeliveryMode__c = cartItemWrap.strdeliveryMode;
                    objCartItem.PMC_DH_Incoterms__c = cartItemWrap.strIncoterms;
                    objCartItem.PMC_DH_PlantShipFrom__c = cartItemWrap.strShipFrom;
                    objCartItem.PMC_DH_Source__c = cartItemWrap.strSource;
                    objCartItem.PMC_DH_RequestedShipmentDate__c = cartItemWrap.datRequestedShipmentDate;
                    objCartItem.PMC_DH_ItemNumber__c = cartWrap.strItemNumber;
                    lstCartitems.add(objCartItem);
                }
            }
            if(!lstCartitems.isEmpty() && (Schema.sObjectType.CartItem.isCreateable()||Schema.sObjectType.CartItem.isUpdateable())){
                //List<Database.UpsertResult> rt = Database.upsert(lstCartitems, false, AccessLevel.USER_MODE);
                Upsert lstCartitems;
                result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(SUCCESS_CODE, Shipment);
            }
        }catch(Exception ex){
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(ERROR_CODE, ERROR);
            result.strStatusMessage = result.strStatusMessage + ex.getMessage() + ex.getStackTraceString();
            
        }
        return result;
    }

    /*************************************************************************
* @method Name  : getShipToForContract
* @description  : Method to get ship To 
* @param objCont
* @return       : Map<String,List<PMC_DH_PicklistWrapper>>
*****************************************************************************/
    public static Map<String,List<PMC_DH_PicklistWrapper>> getShipToForContract(Contract objCont){ 
        Map<String,List<PMC_DH_PicklistWrapper>> mapShipTo = new Map<String,List<PMC_DH_PicklistWrapper>>();        
           if(objCont.SBQQ__Subscriptions__r !=null){
               mapShipTo = PMC_DH_ContractDetailController.addShipToMap(objCont);
            }
        return mapShipTo;
    }
    
public static Map<String,List<PMC_DH_PicklistWrapper>> getShipToForContractUS(List<Contract> objCont){ 
        Map<String,List<PMC_DH_PicklistWrapper>> mapShipTo = new Map<String,List<PMC_DH_PicklistWrapper>>();
        for(Contract c:objCont){
                if(c.SBQQ__Subscriptions__r !=null){
                mapShipTo = PMC_DH_ContractDetailController.addShipToMap(c);
            }
        }           
        return mapShipTo;
    }
    /*************************************************************************
* @method Name  : getShipFromForContract
* @description  : Method to get ship from
* @param objCont
* @return       : Map<String,List<PMC_DH_PicklistWrapper>>
*****************************************************************************/
    public static Map<String,List<PMC_DH_PicklistWrapper>> getShipFromForContract(Contract objCont){
        Map<String,List<PMC_DH_PicklistWrapper>> mapShipFrom = new Map<String,List<PMC_DH_PicklistWrapper>>();
            if(objCont.SBQQ__Subscriptions__r != null){
                    for(SBQQ__Subscription__c objSubs : objCont.SBQQ__Subscriptions__r){
                        PMC_DH_PicklistWrapper shipFrom = new PMC_DH_PicklistWrapper();
                        shipFrom.Label = objSubs.SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name;
                        shipFrom.Value = objSubs.SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__c;
                        mapShipFrom = PMC_DH_ContractDetailController.addShipFromMap(mapShipFrom, objSubs.SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit);
                        mapShipFrom.get(objSubs.SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit).add(shipFrom);
                    }
            }
            
        return mapShipFrom;
    }
    /*************************************************************************
* @method Name  : getIncotermsForContract
* @description  : Method to get Incoterms
* @param objCont
* @return       : Map<String,List<PMC_DH_PicklistWrapper>>
*****************************************************************************/
    public static Map<String,List<PMC_DH_PicklistWrapper>> getIncotermsForContract(Contract objCont){
        Map<String,List<PMC_DH_PicklistWrapper>> mapIncoterms = new Map<String,List<PMC_DH_PicklistWrapper>>();
            if(objCont.SBQQ__Subscriptions__r!=null){
                    for(SBQQ__Subscription__c objSubs : objCont.SBQQ__Subscriptions__r){
                        PMC_DH_PicklistWrapper incoterm = new PMC_DH_PicklistWrapper();
                    //    incoterm.Label = objSubs.SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c;
                        incoterm.Label = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_Incoterms1__c.getDescribe(),objSubs.SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c);
                        incoterm.Value = objSubs.SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c;
                        mapIncoterms = PMC_DH_ContractDetailController.addIncotermsMap(mapIncoterms, objSubs.SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit);
                        mapIncoterms.get(objSubs.SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit).add(incoterm);
                    }
            }
            
        return mapIncoterms;
        
    }
    /*************************************************************************
* @method Name  : getDeliveryModesForContract
* @description  : Method to get Delivery Modes
* @param objCont
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/
    public static Map<String,List<PMC_DH_PicklistWrapper>> getDeliveryModesForContract(Contract objCont){ 
        Map<String,List<PMC_DH_PicklistWrapper>> mapDeliveryMode = new Map<String,List<PMC_DH_PicklistWrapper>>();
            if(objCont.SBQQ__Subscriptions__r!=null){
                    for(SBQQ__Subscription__c objSubs : objCont.SBQQ__Subscriptions__r){
                        PMC_DH_PicklistWrapper deliveryMode = new PMC_DH_PicklistWrapper();
                    //    deliveryMode.Label = objSubs.SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c;
                        deliveryMode.Label =PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_ModeofTransportation__c.getDescribe(),objSubs.SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c);
                        deliveryMode.Value = objSubs.SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c;
                        mapDeliveryMode = PMC_DH_ContractDetailController.addDeliverModeMap(mapDeliveryMode, objSubs.SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit);
                        mapDeliveryMode.get(objSubs.SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit).add(deliveryMode);
                    }
            }
        return mapDeliveryMode;
        
    }
    /*************************************************************************
* @method Name  : getContractItems
* @description  : Method to get Contract Items
* @param objCont
* @return       : Map<String,List<PMC_DH_RequestToDeliverWrapper.ContractItem>>
*****************************************************************************/
    public static Map<String,List<PMC_DH_RequestToDeliverWrapper.ContractItem>> getContractItems(Contract objCont){
        Map<String,List<PMC_DH_RequestToDeliverWrapper.ContractItem>> mapContractItem = new Map<String,List<PMC_DH_RequestToDeliverWrapper.ContractItem>>();
        //List<PMC_DH_RequestToDeliverWrapper.ContractItem> lstcontractItems = new List<PMC_DH_RequestToDeliverWrapper.ContractItem>();
        //List<Contract> lstContract = [SELECT Id,(SELECT Id,SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit,SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Id,SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__c,SBQQ__Quantity__c,PMC_CPQ_TotalAvailableQuantity__c,PMC_CPQ_TotalOrderedQuantity__c,SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.Name,SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name,SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.Id,SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c,SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c FROM SBQQ__Subscriptions__r where SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit IN :strSKU) FROM Contract where Id=:strContractId WITH SECURITY_ENFORCED];
            if(objCont.SBQQ__Subscriptions__r!=null){
                    for(SBQQ__Subscription__c objSubs : objCont.SBQQ__Subscriptions__r){
                        PMC_DH_RequestToDeliverWrapper.ContractItem contWrap = new PMC_DH_RequestToDeliverWrapper.ContractItem();
                        contWrap.strContractItemId = objSubs.Id; 
                        contWrap.intQuantity = objSubs.SBQQ__Quantity__c != null?objSubs.SBQQ__Quantity__c.longValue():0;//GDASF-10697
                        contWrap.intAvailableQuantity = objSubs.PMC_CPQ_TotalAvailableQuantity__c != null?objSubs.PMC_CPQ_TotalAvailableQuantity__c.longValue():0;//GDASF-10697
                        contWrap.intOrderQuantity = objSubs.PMC_CPQ_TotalOrderedQuantity__c != null?objSubs.PMC_CPQ_TotalOrderedQuantity__c.longValue():0;//GDASF-10697
                        contWrap.strShipTo = objSubs.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__c;
                        //contWrap.strShipTo = objSubs.SBQQ__QuoteLine__r.PMC_CPQ_SoldToShipToJunction__c; // modified as part of GDASF-17324
                        contWrap.strDeliveryMode = objSubs.SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c;
                        contWrap.strIncoterms = objSubs.SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c;
                        contWrap.strShipFrom = objSubs.SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__c;
                        mapContractItem = PMC_DH_ContractDetailController.addContractItemToMap(mapContractItem, objSubs.SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit);
                        mapContractItem.get(objSubs.SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit).add(contWrap);
                        
                    }
            }
        return mapContractItem;
        
    }

/*************************************************************************
* @method Name  : getContractSummary
* @description  : Method to get Contract Summary
* @param    strContractId
* @return       : PMC_DH_RequestToDeliverWrapper.ContractSummaryWrapper
*****************************************************************************/
@AuraEnabled
public static PMC_DH_RequestToDeliverWrapper.ContractSummaryWrapper getContractSummary(String strContractId){ 
    PMC_DH_RequestToDeliverWrapper.ContractSummaryWrapper contSummary = new PMC_DH_RequestToDeliverWrapper.ContractSummaryWrapper();
    try{
    List<Contract> lstcont = [SELECT Id,PMC_CPQ_Contract_Blocked__c,tolabel(PMC_CPQ_ContractType__c), StartDate, EndDate, tolabel(Status), AccountId, CurrencyIsoCode,
    SBQQ__Quote__c, SBQQ__Quote__r.Name, SBQQ__Quote__r.SBQQ__Status__c, SBQQ__Quote__r.PMC_CLM_DocumentNumber__c, SBQQ__Quote__r.PMC_CPQ_PO__c, SBQQ__Quote__r.PMC_CPQ_PrimaryContact__r.Name, toLabel(SBQQ__Quote__r.SBQQ__PaymentTerms__c), SBQQ__Quote__r.PMC_DH_PaymentMethod__c, SBQQ__Quote__r.PMC_CPQ_Currency__c, SBQQ__Quote__r.PMC_CPQ_TotalQuantity__c, SBQQ__Quote__r.PMC_CPQ_ModeOfTransportation__c,PMC_CPQ_LatestQuote__c,PMC_CPQ_LatestQuote__r.SBQQ__Type__c,PMC_CPQ_LatestQuote__r.PMC_CLM_DocumentNumber__c,PMC_CPQ_LatestQuote__r.PMC_CPQ_PO__c,PMC_CPQ_LatestQuote__r.PMC_CPQ_PrimaryContact__r.Name,PMC_CPQ_LatestQuote__r.SBQQ__StartDate__c,PMC_CPQ_LatestQuote__r.SBQQ__EndDate__c,PMC_CPQ_LatestQuote__r.SBQQ__PaymentTerms__c,
    (SELECT Id, PMC_CPQ_TotalOrderedQuantity__c, PMC_CPQ_TotalAvailableQuantity__c, SBQQ__Product__r.StockKeepingUnit,
    SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__c, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.Name, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingStreet, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingCity, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingState, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingPostalCode, SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__c,SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name, SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c,toLabel(SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c), SBQQ__QuoteLine__r.SBQQ__NetPrice__c, toLabel(SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c)
    FROM SBQQ__Subscriptions__r) 
    FROM Contract where id=:strContractId AND Status=: CONTRACT_STATUS WITH SECURITY_ENFORCED];
    if(!lstcont.isEmpty()){
        //GOHS-3266 | Amendement Dates on RTD fix || FIX START     
        Boolean isAmendment=(lstcont[0].PMC_CPQ_LatestQuote__c != null && lstcont[0].PMC_CPQ_LatestQuote__r.SBQQ__Type__c == AMENDMENT_TYPE);
        contSummary.strContractNumber =PMC_DH_ConstantClass.DOC_TAG+ lstcont[0].SBQQ__Quote__r.PMC_CLM_DocumentNumber__c; //ContractNumber;
        Id strAmendmentQuoteId = lstcont[0].PMC_CPQ_LatestQuote__c;
           
        if(isAmendment){
            contSummary.strPoNumber = lstcont[0].PMC_CPQ_LatestQuote__r.PMC_CPQ_PO__c;
            contSummary.datContractStartDate = lstcont[0].PMC_CPQ_LatestQuote__r.SBQQ__StartDate__c; 
            contSummary.datContractEndDate = lstcont[0].PMC_CPQ_LatestQuote__r.SBQQ__EndDate__c;
            contSummary.strPaymentTermSelected = lstcont[0].PMC_CPQ_LatestQuote__r.SBQQ__PaymentTerms__c;
            contSummary.strContractType = lstcont[0].SBQQ__Subscriptions__r[0].SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c; 
        }
        else{
            contSummary.strPoNumber = lstcont[0].SBQQ__Quote__r.PMC_CPQ_PO__c;
            contSummary.datContractStartDate = lstcont[0].StartDate;
            contSummary.datContractEndDate = lstcont[0].EndDate;
            contSummary.strPaymentTermSelected = lstcont[0].SBQQ__Quote__r.SBQQ__PaymentTerms__c;
            String strContractTypeAmendment=[Select toLabel(PMC_CPQ_ContractType__c) from SBQQ__QuoteLine__c where  SBQQ__Quote__c=:strAmendmentQuoteId LIMIT 1].PMC_CPQ_ContractType__c;
            contSummary.strContractType = strContractTypeAmendment ?? '';
        }
        //GOHS-3266 | Amendement Dates on RTD fix || FIX END

        //contSummary.strCurrencyIsoCode =  lstcont[0].CurrencyIsoCode; commented due to vald error-deployment;Hemant
        List<String> lstStatusAndReason = PMC_DH_ContractManagementHelper.getContractStatusAndReason(lstcont[0]);
        contSummary.strContractStatus = lstStatusAndReason[0]; 
        }
    }catch(Exception ex){
        throw new AuraHandledException(ex.getMessage()); 
    }
    return contSummary;
}
/*************************************************************************
* @method Name  : getFrequency
* @description  : Method to get Frequency of Shipment Plan
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/
    public static List<PMC_DH_PicklistWrapper> getFrequency()
    {
        Schema.DescribeFieldResult fieldResult = CartItem.PMC_DH_Frequency__c.getDescribe();
        List<PMC_DH_PicklistWrapper> lstFrequency = PMC_DH_DigitalHubB2BUtils.getPicklistFromSchema(fieldResult);
        return lstFrequency;
    }

    /*************************************************************************
* @method Name  : createShipmentInfoCartItems
* @description  : Method to create Cart Item for each Shipment Info
* @param strCartId
* @param objInitialCartItem
* @param cartItemWrap
* @return       : List<CartItem>
*****************************************************************************/
public static List<CartItem> createShipmentInfoCartItems(String strCartId, CartItem objInitialCartItem, PMC_DH_RequestToDeliverWrapper.CartItemWrapper cartItemWrap){
    List<CartItem> lstCartitems = new List<CartItem>();
    List<PMC_DH_RequestToDeliverWrapper.ShipmentPlanWrapper> lstShipmentPlan = cartItemWrap.lstShipmentPlan;
    objInitialCartItem.Quantity = lstShipmentPlan[0].intQuantity;
    objInitialCartItem.PMC_DH_DeliveryPONumber__c = lstShipmentPlan[0].strDeliveryPONumber;
    objInitialCartItem.PMC_DH_RequestedShipmentDate__c = lstShipmentPlan[0].datRequestedShipmentDate;
    lstCartitems.add(objInitialCartItem);
    for(Integer i = 1; i < lstShipmentPlan.size(); i++){
        CartItem objCartItem = PMC_DH_RequestToDeliverUtil.getCartItemObject(lstShipmentPlan[i].strCartItemId,strCartId);
        //objCartItem.CartId = strCartId;
        objCartItem.PMC_DH_NotaFiscalNumber__c = objInitialCartItem.PMC_DH_NotaFiscalNumber__c;
        objCartItem.PMC_DH_NotaFiscalDate__c = objInitialCartItem.PMC_DH_NotaFiscalDate__c;
        objCartItem.PMC_DH_SellOutPrice__c = objInitialCartItem.PMC_DH_SellOutPrice__c;
        objCartItem.PMC_DH_Contract__c = objInitialCartItem.PMC_DH_Contract__c;
        objCartItem.Name = objInitialCartItem.Name;
        objCartItem.CartDeliveryGroupId = objInitialCartItem.CartDeliveryGroupId; 
        objCartItem.Product2Id = objInitialCartItem.Product2Id;
        objCartItem.Type = objInitialCartItem.Type;
        objCartItem.PMC_DH_ShipTo__c = objInitialCartItem.PMC_DH_ShipTo__c;
        objCartItem.PMC_DH_DeliveryMode__c = objInitialCartItem.PMC_DH_DeliveryMode__c;
        objCartItem.PMC_DH_Incoterms__c = objInitialCartItem.PMC_DH_Incoterms__c; 
        objCartItem.PMC_DH_PlantShipFrom__c = objInitialCartItem.PMC_DH_PlantShipFrom__c; 
        objCartItem.PMC_DH_Source__c = objInitialCartItem.PMC_DH_Source__c;
        //objCartItem.PMC_DH_DeliveryInstructions__c = objInitialCartItem.PMC_DH_DeliveryInstructions__c;
        //objCartItem.PMC_DH_RequestedShipmentDate__c = objInitialCartItem.PMC_DH_RequestedShipmentDate__c;
        objCartItem.PMC_DH_ItemNumber__c = objInitialCartItem.PMC_DH_ItemNumber__c;
        objCartItem.PMC_DH_Frequency__c = objInitialCartItem.PMC_DH_Frequency__c; 
        objCartItem.PMC_DH_POIncrementBy__c = objInitialCartItem.PMC_DH_POIncrementBy__c;
        objCartItem.PMC_DH_BasePONumber__c = objInitialCartItem.PMC_DH_BasePONumber__c;
        objCartItem.PMC_DH_Subscription__c = objInitialCartItem.PMC_DH_Subscription__c;
        objCartItem.CurrencyIsoCode = objInitialCartItem.CurrencyIsoCode;
        objCartItem.PMC_DH_PackType__c = objInitialCartItem.PMC_DH_PackType__c;
        objCartItem.PMC_DH_PackageType__c = objInitialCartItem.PMC_DH_PackageType__c;
        //objCartItem.SalesPrice = objInitialCartItem.SalesPrice;
        
        objCartItem.Quantity = lstShipmentPlan[i].intQuantity;
        objCartItem.PMC_DH_DeliveryPONumber__c = lstShipmentPlan[i].strDeliveryPONumber;
        objCartItem.PMC_DH_RequestedShipmentDate__c = lstShipmentPlan[i].datRequestedShipmentDate;
        objCartItem.PMC_DH_GroupReferenceNumber__c = Integer.ValueOf(lstShipmentPlan[i].strCartItemReferenceNumber.split('-')[2]);
        objCartItem.PMC_DH_ShipmentReferenceNumber__c = Integer.ValueOf(lstShipmentPlan[i].strCartItemReferenceNumber.split('-')[3]);
        //objCartItem.TotalPrice = objCartItem.Quantity * objCartItem.SalesPrice;
        //objCartItem.TotalLineAmount = objCartItem.Quantity * objCartItem.SalesPrice;
        lstCartitems.add(objCartItem);
    }
    return lstCartitems;
}

/*************************************************************************
* @method Name  : createShipmentInfoCartItems
* @description  : Method to Indicate String having numeric or Decimal Value or not
* @param searchTerm
* @return       : Boolean
*/
public static Boolean isNumericOrDecimal(String searchTerm){
    if(searchTerm.contains('.') && searchTerm.indexOf('.') == searchTerm.lastIndexOf('.')){
    searchTerm = searchTerm.replace('.','');
    }
    return searchTerm.isNumeric();
}



/**
* @description 
* @author Hemant Giri Goswami | hegoswami@deloitte.com | 03-06-2024 
* @param mapShipFrom 
* @param quoteLineObjRecord 
**/
public static void mapCreationShipFrom(Map<String,PMC_DH_AddressWrapper.AddressViewDetails> mapShipFrom,SBQQ__QuoteLine__c quoteLineObjRecord)
{
    PMC_DH_AddressWrapper.AddressViewDetails wrpAddress;
    if(!mapShipFrom.containsKey(quoteLineObjRecord.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__c))
                {
                    wrpAddress=new PMC_DH_AddressWrapper.AddressViewDetails();
                    wrpAddress.strCity=quoteLineObjRecord.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_City__c;
                    wrpAddress.strState=quoteLineObjRecord.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_State__c;
                    mapShipFrom.put(quoteLineObjRecord.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__c,wrpAddress);
                }
            
}
}