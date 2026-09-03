/**
* @description : class for the methods that will be used for RFQ
* @author      : Nikhilesh Mohanty
* @last modified on  : 03-14-2024
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
public without sharing class PMC_DH_QuoteUtils
{
    
    private static final String CLASS_CONST_VARIABLE2 = '002';
    private static final String CLASS_CONST_VARIABLE3 = '100';
    private static final String SHIPMENT = 'Shipment';
    private static final String ERROR = 'All';
    private static final String INCOTERM = 'Incoterm';
   
    public static boolean throwTestException = false;
 
    /*************************************************************************
* @method Name  : getShipFromForQuote
* @description  : Method to get 'Ship From' information in wrapper form
* @param       setSku
* @return       : Map<String,List<PMC_DH_PicklistWrapper>>
******************************************************************************/
    public static Map<String,List<PMC_DH_PicklistWrapper>> getShipFromForQuote(set<String> setSku)
        
    {
        Map<String,List<PMC_DH_PicklistWrapper>> mapShipFrom=new  Map<String,List<PMC_DH_PicklistWrapper>>();
        
        List<PMC_CPQ_ProductLocation__c> lstProductLocation;
        try{
            Map<String,Set<String>> mapUserRegion =new Map<String,Set<String>>();
            Set<STRING> setUS=new set<string>{'CA','US'};
            set<String> setBR=new set<String>{'BR'};

            mapUserRegion.put('NA',setUS );
            mapUserRegion.put('BR',setBR );

            String strUserId=userInfo.getUserId();
            List<User> lstUser=PMC_DH_UserUtil.getUserData(strUserId);
            String strUserRegion = PMC_DH_CommonSystemUtils.getUserRegion(lstUser[0].country);
            set<String> setFinalRegion = mapUserRegion.get(strUserRegion);
           // if(Schema.sObjectType.PMC_CPQ_ProductLocation__c.isAccessible()){
                lstProductLocation = [SELECT Id, PMC_CPQ_Location__r.Id, PMC_CPQ_Location__r.Name, PMC_CPQ_ProductName__r.StockKeepingUnit,PMC_CPQ_Location__r.recordType.name, PMC_CPQ_Location__r.PMC_CPQ_Country__c FROM PMC_CPQ_ProductLocation__c 
                                      WHERE PMC_CPQ_ProductName__r.StockKeepingUnit IN :setSku AND PMC_CPQ_Location__r.recordType.name='Origin Location' AND PMC_CPQ_Location__r.PMC_CPQ_Country__c IN: setFinalRegion  WITH USER_MODE];
            //}
          
            mapShipFrom=PMC_DH_RequestForQuoteHelper.getShipFromValidation(lstProductLocation,mapShipFrom);

        }catch(Exception ex){
             PMC_ErrorLogClass.processException(ex); // MDErrorLog
            throw new AuraHandledException(ex.getMessage());
        }
        return mapShipFrom;
    }


    /*************************************************************************
* @method Name  : getShipToForQuote
* @description  : Method to get 'Ship To' information in wrapper form
* @param       	  effectiveAccountId String effectiveAccountId
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/
    public static List<PMC_DH_PicklistWrapper> getShipToForQuote(String effectiveAccountId)
    {
        List<PMC_DH_PicklistWrapper> lstShipTo = new List<PMC_DH_PicklistWrapper>();
        PMC_DH_PicklistWrapper shipTo;
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            List<PMC_SS_AccountPartnerRelationships__c> lstShipTpAccount = [SELECT Id, PMC_SS_Account__c, PMC_SS_Account__r.Name,
                                                                            PMC_SS_RelatedAccount__c, PMC_SS_RelatedAccount__r.Name,PMC_SS_RelatedAccount__r.PMC_DH_StreetNumber__c, PMC_SS_RelatedAccount__r.Type,
                                                                            PMC_SS_RelatedAccount__r.ShippingStreet, PMC_SS_RelatedAccount__r.ShippingCity, PMC_SS_RelatedAccount__r.ShippingPostalCode, PMC_SS_RelatedAccount__r.ShippingState,
                                                                            PMC_SS_RelatedAccount__r.PMC_SS_TaxIDOrCNPJOrCPF__c,PMC_SS_RelatedAccount__r.ParentId,PMC_SS_RelatedAccount__r.shippingcountry,PMC_SS_RelatedAccount__r.PMC_DH_Delivery_Instruction__c  
                                                                            FROM PMC_SS_AccountPartnerRelationships__c 
                                                                            WHERE PMC_SS_Account__c=:effectiveAccountId AND PMC_SS_Type__c=:PMC_DH_ConstantClass.ACCOUNT_TYPE AND PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c!=:PMC_DH_ConstantClass.ACCOUNT_INACTIVE_STATUS AND PMC_SS_RelatedAccount__r.PMC_SS_MDMVerified__c=TRUE AND PMC_SS_RelatedAccountSalesArea__c!=NULL
                                                               WITH SECURITY_ENFORCED];
            List<PMC_SS_AccountPartnerRelationships__c> lstSoldtoShiptoProcessed = PMC_DH_QuoteManagementHelper.removeDuplicateRelatedAccountsFromList(lstShipTpAccount);
            //List<Account> lstAccount = [SELECT Id, Name, ParentId, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, Type FROM Account WHERE ParentId =:effectiveAccountId AND Type = 'Ship-to' WITH SECURITY_ENFORCED];
            if(!lstSoldtoShiptoProcessed.isEmpty()){
                for(PMC_SS_AccountPartnerRelationships__c objShipTo : lstSoldtoShiptoProcessed){
                    shipTo = new PMC_DH_PicklistWrapper();
                    String strShipToLabel = objShipTo.PMC_SS_RelatedAccount__r.Name + ' ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingStreet + ', ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingCity + ', ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingState + ' ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingPostalCode;
                    shipTo.label = strShipToLabel;
                    shipTo.value = objShipTo.PMC_SS_RelatedAccount__c;
                    //shipTo.value = objShipTo.Id; // added as part of GDASF-17324
                    lstShipTo.add(shipTo);
                }
            }
        }
        catch(Exception ex){
             PMC_ErrorLogClass.processException(ex); // MDErrorLog
            throw new AuraHandledException(ex.getMessage());
        }
        return lstShipTo;
    }
    
    /*************************************************************************
* @method Name  : getIncotermsForQuote
* @description  : Method to get 'Incoterm' information in wrapper form
* @param businessType
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/

public static List<PMC_DH_PicklistWrapper> getIncotermsForQuote(String businessType)
{
    Map<String,List<Schema.PicklistEntry>> mapBusinessTypeIncoterm = PMC_DH_CommonSystemUtils.getDependentPicklistValues(SBQQ__QuoteLine__c.PMC_CPQ_Incoterms1__c);
    Map<String, Set<String>> mapOfIncoterm =PMC_DH_RequestForQuoteHelper.getRestrictionRulesForIncoterm(INCOTERM);

    // to-do: filter criteria to remove the restricted ones from the display component
    List<PMC_DH_PicklistWrapper> lstPicklistWrapper = new List<PMC_DH_PicklistWrapper>();
    lstPicklistWrapper=PMC_DH_RequestForQuoteUtil.getRestrcIncoTerms(businessType,mapBusinessTypeIncoterm,mapOfIncoterm);
    
    return lstPicklistWrapper;
}


 

/*************************************************************************
* @method Name  : getModeOfTransportationForQuote
* @description  : Method to get 'Mode Of Transportation' information in wrapper form
* @param quoteRecordType
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/

public static List<PMC_DH_PicklistWrapper> getModeOfTransportationForQuote(String quoteRecordType){
        
        Map<String,List<Schema.PicklistEntry>> mapRecordTypeMOT = PMC_DH_CommonSystemUtils.getDependentPicklistValues(SBQQ__QuoteLine__c.PMC_CPQ_ModeofTransportation__c);
        List<PMC_DH_PicklistWrapper> lstPicklistWrapper = new List<PMC_DH_PicklistWrapper>();
        if(mapRecordTypeMOT.containsKey(quoteRecordType)){
            for(Schema.PicklistEntry picklistMOT: mapRecordTypeMOT.get(quoteRecordType)){
                PMC_DH_PicklistWrapper picklistWrapper = new PMC_DH_PicklistWrapper();
                picklistWrapper.label = picklistMOT.getLabel();
                picklistWrapper.value = picklistMOT.getValue();
                lstPicklistWrapper.add(picklistWrapper);
            }
        }
        return lstPicklistWrapper;
    }
    
    /*************************************************************************
* @method Name  : getCartItemDetails
* @description  : Method to get Cart Item Details 
* @param       	 strCartId
* @param       	 setSKu
* @param       	 mapProductDetail
* @return       : Map<String,List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>>
*****************************************************************************/
    
    public static Map<String,List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>> getCartItemDetails(String strCartId, Set<String> setSKu, Map<String,PMC_DH_RequestForQuoteController.ConnectApiWrapper> mapProductDetail){
        Map<String,List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>> mapSkuToWrapper = new Map<String,List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>>();
        List<CartItem> lstCartitems;
        try{
            if(Schema.sObjectType.CartItem.isAccessible()){
                //add delivery mode again
                
                lstCartitems= [SELECT id,Quantity,Product2.StockKeepingUnit,PMC_DH_ShipTo__c, PMC_DH_AccountPartnerRelationship__c, PMC_DH_PlantShipFrom__c, PMC_DH_Incoterms__c, PMC_DH_DeliveryMode__c, PMC_DH_UnitofMeasure__c, PMC_DH_PackType__c
                               FROM CartItem 
                               WHERE cartId=:strCartId and Product2.StockKeepingUnit  IN :setSKu];//,PMC_DH_PackageType__c ->Removed as part of GDASF-20003
            }
            for(CartItem objCartItem : lstCartitems)
            {
                PMC_DH_RequestForQuoteWrapper.CartItemWrapper cartItemWrap = new PMC_DH_RequestForQuoteWrapper.CartItemWrapper();
                cartItemWrap.strCartItemId = objCartItem.id;
                cartItemWrap.strShipTo = checkForNull(objCartItem.PMC_DH_ShipTo__c);
                //cartItemWrap.strShipTo = checkForNull(objCartItem.PMC_DH_AccountPartnerRelationship__c); // added as part of GDASF-17324
                cartItemWrap.strdeliveryMode = checkForNull(objCartItem.PMC_DH_DeliveryMode__c);
                cartItemWrap.strIncoterms = checkForNull(objCartItem.PMC_DH_Incoterms__c);
                cartItemWrap.strShipFrom = checkForNull(objCartItem.PMC_DH_PlantShipFrom__c);
                cartItemWrap.strQuantity = PMC_DH_DigitalHubB2BUtils.checkQuantity(objCartItem);
                cartItemWrap.strProductUOM = checkForNull(objCartItem.PMC_DH_UnitofMeasure__c);
                PMC_DH_RequestForQuoteController.ConnectApiWrapper objconnectapiProduct = mapProductDetail.get(objCartItem.Product2.StockKeepingUnit);
                cartItemWrap.strSkuPackType = objconnectapiProduct.strProductPackType != null?PMC_DH_RequestToDeliverUtil.getPackTypeValue(objconnectapiProduct.strProductPackType):'';
                cartItemWrap.strPackType = checkForNull(objCartItem.PMC_DH_PackType__c);
                //cartItemWrap.strPackageType = checkForNull(objCartItem.PMC_DH_PackageType__c);//Removed as part of GDASF-20003
                if(!mapSkuToWrapper.containsKey(objCartItem.Product2.StockKeepingUnit)){
                    mapSkuToWrapper.put(objCartItem.Product2.StockKeepingUnit,new List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>());
                }
                mapSkuToWrapper.get(objCartItem.Product2.StockKeepingUnit).add(cartItemWrap);
            }
            
        }catch(Exception ex){
             PMC_ErrorLogClass.processException(ex); // MDErrorLog
            throw new AuraHandledException(ex.getMessage());
        }
        return mapSkuToWrapper;
    } 
    
        /*************************************************************************
* @method Name  : checkForQuantity 
* @description : check for quantity
* @param       	 objCI
* @return       : Boolean
*****************************************************************************/
    public static Boolean checkForQuantity(CartItem objCI){
        Boolean boolisNewItem = String.IsBlank(objCI.PMC_DH_DeliveryMode__c) || String.IsBlank(objCI.PMC_DH_Incoterms__c) || String.IsBlank(objCI.PMC_DH_PlantShipFrom__c) || String.IsBlank(objCI.PMC_DH_ShipTo__c);
        return boolisNewItem;
    }
    
    private static String checkForNull(String param){
        param = String.isBlank(param)?'':param;
        return param;
    }
    
    private static CartItem createCartItem(String strCartId, PMC_DH_RequestForQuoteWrapper.CartItemWrapper cartItemWrap){
        CartItem objCartItem = new CartItem();
        if(String.isBlank(cartItemWrap.strCartItemId)){//insert
            objCartItem.CartId = strCartId;
        }
        else{
            objCartItem.Id = cartItemWrap.strCartItemId;
        }
        return objCartItem;
    }

    /*************************************************************************
* @method Name  : addCartItems
* @description : Method to add new cart items
* @param strCartId
* @param strInputJSON
* @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper addCartItems(String strCartId,String strInputJSON){
        List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper> lstCartItemWrapper = (List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>)JSON.deserialize(strInputJSON, List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>.Class);
        
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        List<CartItem> lstCartitems = new List<CartItem>();
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            
            List<CartDeliveryGroup> lstCartDeliverGrp= [select id, Cart.CurrencyIsoCode,Cart.AccountId from CartDeliveryGroup where cartid=:strCartId  WITH SECURITY_ENFORCED limit 1];
            //WebCart objWebCart = [SELECT Id, PMC_DH_Currency__c FROM WebCart WHERE Id =: strCartId WITH SECURITY_ENFORCED LIMIT 1];
            Map<String, String> mapSoldToShipTo =PMC_DH_QuoteManagementHelper.getShipToIdSoldToShipToJunctionIdMap(lstCartDeliverGrp[0].Cart.AccountId);
            for(PMC_DH_RequestForQuoteWrapper.CartItemWrapper cartItemWrap : lstCartItemWrapper){
                CartItem objCartItem = createCartItem(strCartId, cartItemWrap);
                objCartItem.Name = cartItemWrap.strProductName;
                objCartItem.CartDeliveryGroupId = lstCartDeliverGrp[0].id;
                objCartItem.Product2Id = cartItemWrap.strProductId; 
                objCartItem.Type = PMC_DH_ConstantClass.PRODUCT_TYPE;
                objCartItem.Quantity =Decimal.valueof(cartItemWrap.strQuantity);
                objCartItem.PMC_DH_ShipTo__c =cartItemWrap.strShipTo;
                //objCartItem.PMC_DH_ShipTo__c =mapSoldToShipTo.get(cartItemWrap.strShipTo); // added as part of quick fix
                objCartItem.PMC_DH_AccountPartnerRelationship__c =mapSoldToShipTo.get(cartItemWrap.strShipTo); // added as part of GDASF-17324
                objCartItem.PMC_DH_DeliveryMode__c = cartItemWrap.strdeliveryMode;
                objCartItem.PMC_DH_Incoterms__c = cartItemWrap.strIncoterms;
                objCartItem.PMC_DH_PlantShipFrom__c = cartItemWrap.strShipFrom;
                objCartItem.PMC_DH_UnitofMeasure__c = cartItemWrap.strProductUOM;
                objCartItem.PMC_DH_PackType__c = cartItemWrap.strPackType;
                objCartItem.PMC_DH_PackageType__c = cartItemWrap.strPackageType;
                PMC_DH_QuoteListViewController.assignSource(objCartItem,cartItemWrap.strSource);
                objCartItem.CurrencyIsoCode = lstCartDeliverGrp[0].Cart.CurrencyIsoCode;
                //objCartItem.PMC_DH_GroupReferenceNumber__c = Integer.ValueOf(cartItemWrap.strGroupRefNumber);
                //objCartItem.PMC_DH_ShipmentReferenceNumber__c = Integer.ValueOf(cartItemWrap.strShipmentRefNumber);
                    
                lstCartitems.add(objCartItem);
            }
            if(!lstCartitems.isEmpty() && (Schema.sObjectType.CartItem.isCreateable()||Schema.sObjectType.CartItem.isUpdateable())){
                //List<Database.UpsertResult> rt = Database.upsert(lstCartitems, false, AccessLevel.USER_MODE);
                Upsert lstCartitems;
                result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(CLASS_CONST_VARIABLE2, Shipment);
            }
            
            
        }catch(Exception ex){
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL); //changes as part of GDASF-19642
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return result;
    }
    
    
    
/*************************************************************************
* @method Name  : getCheckoutConfigs
* @param lstModule : Set of Modules
* @param strCountry : Country name
* @param strComponent : Component name
* @description  : Method to get 'Checkout Config' metadata information in wrapper form
* @return       : List<PMC_DH_CheckoutConfig__mdt>
*****************************************************************************/
public static List<PMC_DH_CheckoutConfig__mdt> getCheckoutConfigs(Set<String> lstModule, String strCountry, String strComponent)
{
    List<PMC_DH_CheckoutConfig__mdt> lstCheckoutConfig = [SELECT MasterLabel, PicklistAPI_Name__c, Module__c FROM PMC_DH_CheckoutConfig__mdt
                                                        WHERE Country__c =: strCountry AND Module__c IN :lstModule AND Component__c =: strComponent
                                                        WITH SECURITY_ENFORCED];
    return lstCheckoutConfig;
}

/*************************************************************************
* @method Name  : getActiveCartId
* @param strEffectiveAccountId - Id of Account
* @param strCommunityId - community Id
* @description  : Method to get Active Cart Id
* @return       : PMC_DH_ActiveCartIdWrapper
*****************************************************************************/
@AuraEnabled
    public static PMC_DH_ActiveCartIdWrapper getActiveCartId(String strEffectiveAccountId, String strCommunityId) //changes as part of GDASF-19642
{
        PMC_DH_ActiveCartIdWrapper wrpActiveCartId = new PMC_DH_ActiveCartIdWrapper(); //changes as part of GDASF-19642
    try{
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        String strWebStoreId=PMC_DH_MiniCart.getWebStoreId(strCommunityId);
        String strCartId=PMC_DH_MiniCart.getCartId(strWebStoreId, strEffectiveAccountId);
            wrpActiveCartId.strCartId = strCartId; //changes as part of GDASF-19642
            wrpActiveCartId.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, 'ActiveCartId'); //changes as part of GDASF-19642
            //return strCartId;
        }Catch(Exception ex){
            wrpActiveCartId.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL); //changes as part of GDASF-19642
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
    }
        return wrpActiveCartId;
}
/*************************************************************************
* @method Name  : getDateTimeToDate
* @param        datTcreatedDate
* @description  : Method to get converted Date
* @return       : Date
*****************************************************************************/
public static Date getDateTimeToDate(DateTime datTcreatedDate){
    Date createdDate;
    try{
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
    //converting DateTime to Date of CreatedDate field
    Datetime createdDateTime = DateTime.newInstance(datTcreatedDate.year(),datTcreatedDate.month(),datTcreatedDate.day());
    createdDate = createdDateTime.date();
    }
    Catch(Exception ex){
             PMC_ErrorLogClass.processException(ex); // MDErrorLog
        throw new AuraHandledException(ex.getMessage());
    }
    return createdDate;

}
 /*************************************************************************
* @author : Dishari Mondal
* @method Name  : getPackTypeForQuote
* @description  : Method to get Pack Type
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/
public static List<PMC_DH_PicklistWrapper> getPackTypeForQuote(){
    Schema.DescribeFieldResult fieldResult = CartItem.PMC_DH_PackType__c.getDescribe();
    List<PMC_DH_PicklistWrapper> lstPackType = PMC_DH_DigitalHubB2BUtils.getPicklistFromSchema(fieldResult);
    return lstPackType;
}
 /*************************************************************************
* @author : Dishari Mondal
* @method Name  : getPackagingTypeForQuote
* @description  : Method to get Packaging Type
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/
public static List<PMC_DH_PicklistWrapper> getPackagingTypeForQuote(){
    Schema.DescribeFieldResult fieldResult = CartItem.PMC_DH_PackageType__c.getDescribe();
    List<PMC_DH_PicklistWrapper> lstPackagingType = PMC_DH_DigitalHubB2BUtils.getPicklistFromSchema(fieldResult);
    return lstPackagingType;
}

/**
* @description Wrapper for getActiveCartId (as part of GDASF-19642)
* @author Nikhilesh
* @since 01-10-2024
*/
public class PMC_DH_ActiveCartIdWrapper{
        /**
    * @description Cart Id
    * @author Nikhilesh
    * @return  String
    */
    @AuraEnabled
    public String strCartId{get;set;}
    /**
    * @description Status Code and message
    * @author Nikhilesh
    * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
}

}