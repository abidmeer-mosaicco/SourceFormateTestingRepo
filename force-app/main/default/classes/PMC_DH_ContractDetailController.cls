/**
* @description : class for the methods that will be used for RFQ
* @author      : Rohan Undale
* @last modified on  : 05-03-2024
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
public without sharing class PMC_DH_ContractDetailController {
    private static final String CLASS_CONST_VARIABLE2 = '000'; //GPT-34482
    private static final String CLASS_CONST_VARIABLE3 = '100';
    private static final String CARTITEMS_UPDATE = 'CartItemsUpdate'; //GPT-34482
    private static final String ERROR = 'All';
    private static final String STATUS = 'RTD';
    private static final String CLASS_CONST_VARIABLE = '111'; //GPT-34482
    private static final String DUPLICATE_CARTITEM = 'DuplicateCartItem'; //GPT-34482

    /*************************************************************************
* @method Name  : addCartItem
* @description : Method to add new cart items
* @param objCartItemWrapper
* @param strInputJSON
* @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*****************************************************************************/
@AuraEnabled
public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper addCartItem(CartItemWrapper objCartItemWrapper, String strInputJSON){
    List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper> lstCartItemWrapper = (List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>)JSON.deserialize(strInputJSON, List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>.Class);
    PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
    List<CartItem> lstCartitems = new List<CartItem>();
    try{
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        List<CartDeliveryGroup> lstCartDeliverGrp= [select id from CartDeliveryGroup where cartid=:objCartItemWrapper.strCartId  WITH SECURITY_ENFORCED limit 1];
        List<CartItem> lstExistingCartitems = new List<CartItem>();
        if(Schema.sObjectType.CartItem.isAccessible()){
                lstExistingCartitems = [Select Id, Quantity, Product2Id, Product2.StockKeepingUnit, PMC_DH_Source__c, PMC_DH_ShipTo__c, PMC_DH_DeliveryMode__c, PMC_DH_Incoterms__c, PMC_DH_PlantShipFrom__c, PMC_DH_Contract__c, PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c  from CartItem where CartId = :objCartItemWrapper.strCartId]; // GPT-34482
        }
        WebCart objWebCart = [SELECT Id, Status, AccountId, PMC_DH_ContractStartDate__c, PMC_DH_ContractEndDate__c, PMC_DH_Currency__c, PMC_DH_PaymentMethod__c, PMC_DH_PaymentTerms__c, PMC_DH_QuoteFriendlyName__c, CurrencyIsoCode ,
                                PMC_DH_Account__c
                                  FROM WebCart
                                  WHERE Id =: objCartItemWrapper.strCartId WITH SECURITY_ENFORCED LIMIT 1];
        objWebCart.PMC_DH_Account__c=objWebCart.Accountid;
        if(Schema.sObjectType.WebCart.isUpdateable())
        {
            update objWebCart;
        }
            CartItem objExistingCartItem; //GPT-34482
        for(PMC_DH_RequestForQuoteWrapper.CartItemWrapper cartItemWrap : lstCartItemWrapper){
            CartItem objCartItem = new CartItem();
                objCartItem = checkCartItemPresent(cartItemWrap, lstExistingCartitems, objCartItemWrapper.strContractId);
                objExistingCartItem = objCartItem; //GPT-34482
                //objCartItem.PMC_DH_FromContract__c = true;
                if(String.isBlank(objCartItem.Id)){
                    //objCartItem.Quantity = objCartItem.Quantity + Decimal.valueof(cartItemWrap.strQuantity);
                    objCartItem.CartId = objCartItemWrapper.strCartId;
                    objCartItem.Name = cartItemWrap.strProductName;
                    objCartItem.CartDeliveryGroupId = lstCartDeliverGrp[0].id;
                    objCartItem.Product2Id = cartItemWrap.strProductId; 
                    objCartItem.Type = PMC_DH_ConstantClass.PRODUCT_TYPE;
                    objCartItem.Quantity =Decimal.valueof(cartItemWrap.strQuantity);
                    objCartItem.PMC_DH_ShipTo__c =cartItemWrap.strShipTo;
                    objCartItem.PMC_DH_DeliveryMode__c = cartItemWrap.strdeliveryMode;
                    objCartItem.PMC_DH_Incoterms__c = cartItemWrap.strIncoterms;
                    objCartItem.PMC_DH_PlantShipFrom__c = cartItemWrap.strShipFrom;
                    objCartItem.PMC_DH_Source__c = cartItemWrap.strSource;
                    objCartItem.CurrencyIsoCode = objWebCart.CurrencyIsoCode;
                    objCartItem.PMC_DH_Contract__c = objCartItemWrapper.strContractId;
                    objCartItem.PMC_DH_Subscription__c = cartItemWrap.strContractItemId;
                    //objCartItem.PMC_DH_Currency__c = strCurrency;
                    //objCartItem.SalesPrice = cartItemWrap.decNetUnitPrice;
                    //objCartItem.TotalPrice = objCartItem.Quantity * objCartItem.SalesPrice;
                    //objCartItem.TotalLineAmount = objCartItem.Quantity * objCartItem.SalesPrice;
                    lstCartitems.add(objCartItem);
                }   
        }
            result = PMC_DH_OrderHelper.checkNewOrDuplicateCartItems(lstCartitems, objExistingCartItem); //GPT-34482
            /*
        if(!lstCartitems.isEmpty() && (Schema.sObjectType.CartItem.isCreateable()||Schema.sObjectType.CartItem.isUpdateable())){
            //List<Database.UpsertResult> rt = Database.upsert(lstCartitems, false, AccessLevel.USER_MODE);
            Upsert lstCartitems;
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(CLASS_CONST_VARIABLE2, CARTITEMS_UPDATE);
        }
            else if(String.isNotBlank(objExistingCartItem.Id)){ //GPT-34482
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(CLASS_CONST_VARIABLE, DUPLICATE_CARTITEM);
            }
            */
    }catch(Exception ex){
        result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(CLASS_CONST_VARIABLE3, ERROR);
            result.strStatusMessage = result.strStatusMessage + ' : '+ex.getMessage() + ' : '+ex.getStackTraceString();
    }
    return result;
}

    private static CartItem checkCartItemPresent(PMC_DH_RequestForQuoteWrapper.CartItemWrapper cartItemWrap, List<CartItem> lstExistingCartitems, String strContractId){
    CartItem objCartItem = new CartItem();
        String strConcatWrapperValues = cartItemWrap.strProductId + STATUS + cartItemWrap.strShipTo + cartItemWrap.strdeliveryMode + cartItemWrap.strIncoterms + cartItemWrap.strShipFrom + strContractId + cartItemWrap.strContractType; //GPT-34482
    for(CartItem objCrtItm : lstExistingCartitems){
            // changes added as part of GPT-34482
            String strConcatCartItemValues = objCrtItm.Product2Id + objCrtItm.PMC_DH_Source__c + objCrtItm.PMC_DH_ShipTo__c + objCrtItm.PMC_DH_DeliveryMode__c + objCrtItm.PMC_DH_Incoterms__c + objCrtItm.PMC_DH_PlantShipFrom__c + objCrtItm.PMC_DH_Contract__c + objCrtItm.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c; //GPT-34482
            if(strConcatWrapperValues == strConcatCartItemValues){
            objCartItem = objCrtItm;
            break;
        }
            // end of changes as part of GPT-34482
    }
    return objCartItem;
}

/**
* @description Wrapper class for CartItem
* @author @rohanundale
* 
**/
public with sharing class CartItemWrapper{
    /**
* @description Cart Id
* @return  String 
*/
    @AuraEnabled
    public String strCartId{get;set;}
    /**
* @description Currency
* @return  String 
*/
    @AuraEnabled
    public String strCurrency{get;set;}
    /**
* @description Contract Id
* @return  String 
*/
    @AuraEnabled
    public String strContractId{get;set;}

}

/*************************************************************************
* @method Name  : addContractItemToMap
* @description  : Method to add Contract Item To Map
* @param mapContractItem
* @param sku
* @return       : Map<String,List<PMC_DH_RequestToDeliverWrapper.ContractItem>>
*****************************************************************************/
public static Map<String,List<PMC_DH_RequestToDeliverWrapper.ContractItem>> addContractItemToMap(Map<String,List<PMC_DH_RequestToDeliverWrapper.ContractItem>> mapContractItem, String sku){
    if(!mapContractItem.containsKey(sku)){
        mapContractItem.put(sku,new List<PMC_DH_RequestToDeliverWrapper.ContractItem>()); 
     }
     return mapContractItem;
}
    /*************************************************************************
* @method Name  : addShipToMap
* @description  : Method to add ShipTo to Map
* @param mapShipTo
* @param sku
* @return       : Map<String,List<PMC_DH_PicklistWrapper>>
*****************************************************************************/
public static Map<String,List<PMC_DH_PicklistWrapper>> addShipToMap(Map<String,List<PMC_DH_PicklistWrapper>> mapShipTo, String sku){
    if(!mapShipTo.containsKey(sku)){
        mapShipTo.put(sku,new List<PMC_DH_PicklistWrapper>()); 
     }
     return mapShipTo;
}
    /*************************************************************************
* @method Name  : addShipFromMap
* @description  : Method to add Shipfrom to Map
* @param mapShipFrom
* @param sku
* @return       : Map<String,List<PMC_DH_PicklistWrapper>>
*****************************************************************************/
public static Map<String,List<PMC_DH_PicklistWrapper>> addShipFromMap(Map<String,List<PMC_DH_PicklistWrapper>> mapShipFrom, String sku){
    if(!mapShipFrom.containsKey(sku)){
        mapShipFrom.put(sku,new List<PMC_DH_PicklistWrapper>()); 
     }
     return mapShipFrom;
}
    /*************************************************************************
* @method Name  : addIncotermsMap
* @description  : Method to add Incoterms To Map
* @param mapIncoterms
* @param sku
* @return       : Map<String,List<PMC_DH_PicklistWrapper>>
*****************************************************************************/
public static Map<String,List<PMC_DH_PicklistWrapper>> addIncotermsMap(Map<String,List<PMC_DH_PicklistWrapper>> mapIncoterms, String sku){
    if(!mapIncoterms.containsKey(sku)){
        mapIncoterms.put(sku,new List<PMC_DH_PicklistWrapper>()); 
     }
     return mapIncoterms;
}
    /*************************************************************************
* @method Name  : addDeliverModeMap
* @description  : Method to add delivery mode To Map
* @param addDeliverModeMap
* @param sku
* @return       : Map<String,List<PMC_DH_PicklistWrapper>>
*****************************************************************************/
public static Map<String,List<PMC_DH_PicklistWrapper>> addDeliverModeMap(Map<String,List<PMC_DH_PicklistWrapper>> addDeliverModeMap, String sku){
    if(!addDeliverModeMap.containsKey(sku)){
        addDeliverModeMap.put(sku,new List<PMC_DH_PicklistWrapper>());   
     }
     return addDeliverModeMap;
}

/*************************************************************************
* @method Name  : retriveShipmentInfoFromCartItem
* @description  : Method to retrive Shipment Info From Cart Item
* @param mapSkuToWrapper
* @return       : Map<String,List<PMC_DH_RequestToDeliverWrapper.ContractItem>>
*****************************************************************************/
public static Map<String,List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper>> retriveShipmentInfoFromCartItem(Map<String,List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper>> mapSkuToWrapper){
    Map<String,List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper>> mapSkuToWrapperRefined = new Map<String,List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper>>();
    Set<String> lstKeys = mapSkuToWrapper.keySet();
    for(String mapKey : lstKeys){
        List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper> lstCartItem = mapSkuToWrapper.get(mapKey);
        List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper> lstCartItemNew = new List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper>();
        for(PMC_DH_RequestToDeliverWrapper.CartItemWrapper cartItem : lstCartItem){
            PMC_DH_RequestToDeliverWrapper.CartItemWrapper objCartItem = checkCartItemWrapperPresent(cartItem, lstCartItemNew);
            if(String.isBlank(objCartItem.strCartItemId)){
                List<PMC_DH_RequestToDeliverWrapper.ShipmentPlanWrapper> lstShipmentPlan = new List<PMC_DH_RequestToDeliverWrapper.ShipmentPlanWrapper>();
                PMC_DH_RequestToDeliverWrapper.ShipmentPlanWrapper shipmentPlan = new PMC_DH_RequestToDeliverWrapper.ShipmentPlanWrapper();
                shipmentPlan.strCartItemId = cartItem.strCartItemId;
                shipmentPlan.intQuantity = cartItem.intQuantity;
                shipmentPlan.strDeliveryPONumber = cartItem.strDeliveryPONumber;
                shipmentPlan.datRequestedShipmentDate = cartItem.datRequestedShipmentDate;
                lstShipmentPlan.add(shipmentPlan);
                objCartItem = cartItem;
                objCartItem.boolShipmentPlan = false;
                objCartItem.lstShipmentPlan = lstShipmentPlan;
                lstCartItemNew.add(objCartItem);
            }else{
                PMC_DH_RequestToDeliverWrapper.ShipmentPlanWrapper shipmentPlan = new PMC_DH_RequestToDeliverWrapper.ShipmentPlanWrapper();
                shipmentPlan.strCartItemId = cartItem.strCartItemId;
                shipmentPlan.intQuantity = cartItem.intQuantity;
                shipmentPlan.strDeliveryPONumber = cartItem.strDeliveryPONumber;
                shipmentPlan.datRequestedShipmentDate = cartItem.datRequestedShipmentDate;
                objCartItem.boolShipmentPlan = true;
                objCartItem.lstShipmentPlan.add(shipmentPlan);
            }
        }
        mapSkuToWrapperRefined.put(mapKey, lstCartItemNew);
    }
    return mapSkuToWrapperRefined;
}

private Static PMC_DH_RequestToDeliverWrapper.CartItemWrapper checkCartItemWrapperPresent(PMC_DH_RequestToDeliverWrapper.CartItemWrapper cartItemWrap, List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper> lstExistingCartitems){
    PMC_DH_RequestToDeliverWrapper.CartItemWrapper objCartItem = new PMC_DH_RequestToDeliverWrapper.CartItemWrapper();
    for(PMC_DH_RequestToDeliverWrapper.CartItemWrapper objCrtItm : lstExistingCartitems){
        if(objCrtItm.strSource == STATUS &&
        objCrtItm.strShipTo == cartItemWrap.strShipTo && objCrtItm.strdeliveryMode == cartItemWrap.strdeliveryMode &&
               objCrtItm.strIncoterms == cartItemWrap.strIncoterms && objCrtItm.strShipFrom == cartItemWrap.strShipFrom
              ){
            objCartItem = objCrtItm;
            break;
        }
    }
    return objCartItem;
}

    /*************************************************************************
    * @method Name  : addShipToMap
    * @description  : Method to add Ship To Map
    * @param objCont
    * @return       : Map<String,List<PMC_DH_PicklistWrapper>>
    *****************************************************************************/
    public static Map<String,List<PMC_DH_PicklistWrapper>> addShipToMap(Contract objCont){
        Map<String,List<PMC_DH_PicklistWrapper>> mapShipTo = new Map<String,List<PMC_DH_PicklistWrapper>>();
        for(SBQQ__Subscription__c objSubs : objCont.SBQQ__Subscriptions__r){  
            if(objSubs.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.PMC_DH_Account_Status__c!=PMC_DH_ConstantClass.ACCOUNT_INACTIVE_STATUS && objSubs.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.PMC_SS_MDMVerified__c==TRUE){
                PMC_DH_PicklistWrapper shipTo = new PMC_DH_PicklistWrapper();
                shipTo.Label = objSubs.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.Name + ' ' + objSubs.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingStreet + ', ' + objSubs.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingCity + ', ' + objSubs.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingState + ' ' +objSubs.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingPostalCode; // GPT-40363
                //shipTo.Value = objSubs.SBQQ__QuoteLine__r.PMC_CPQ_SoldToShipToJunction__c; // modified as part of GDASF-17324
                shipTo.Value = objSubs.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__c; 
                mapShipTo = PMC_DH_ContractDetailController.addShipToMap(mapShipTo, objSubs.SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit);
                mapShipTo.get(objSubs.SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit).add(shipTo);
            }
        }
        return mapShipTo;
    }
}