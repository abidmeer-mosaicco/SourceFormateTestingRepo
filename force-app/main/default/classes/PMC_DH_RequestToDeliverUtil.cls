/**
* @description : class for the methods that will be used for RTD
* @author      : Krishan Jangir
* @last modified on  : 05-20-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class PMC_DH_RequestToDeliverUtil { 
    private static final String STATUS = 'RTD';
    private static final String DISTRIBUTOR_CHANNEL = 'Distributor';
    private static final String BLANK='';
    private static final String SHIP_TO = 'Ship-to';
    private static final String REGION_BRAZIL = 'Brazil';
    Public Static Boolean CheckTrueadvancebill=FALSE;   //	GSMD-871
    Public static String shiptoacc = null;          //	GSMD-871
    
    /**
* @description 
* @author Mosaic Direct | Dev Team | 11-23-2023 
* @param cartItemWrp 
* @param strUserRegion 
* @param mapProductDetail 
* @return Map<String, List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper>> 
**/
    public static Map<String,List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper>> getCartItemDetails(CartItemParamWrapper cartItemWrp, String strUserRegion, Map<String,PMC_DH_RequestForQuoteController.ConnectApiWrapper> mapProductDetail){
        Map<String,List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper>> mapSkuToWrapper = new Map<String,List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper>>();
        List<CartItem> lstCartitems;
        try{
            
               //  PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();              
            if(Schema.sObjectType.CartItem.isAccessible()){  
                lstCartitems= [Select id,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PackType__c,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PackageType__c,Quantity, PMC_DH_NotaFiscalNumber__c,PMC_DH_NotaFiscalDate__c,PMC_DH_SellOutPrice__c,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.PMC_SS_SAPCustomerNumber__c,    Product2.StockKeepingUnit,PMC_DH_RequestedShipmentDate__c,PMC_DH_PackType__c,   PMC_DH_ShipTo__c,PMC_DH_PlantShipFrom__c, PMC_DH_Incoterms__c,PMC_DH_PackageType__c,  PMC_DH_DeliveryMode__c, PMC_DH_DeliveryPONumber__c,PMC_DH_ItemNumber__c ,  PMC_DH_Frequency__c, PMC_DH_POIncrementBy__c,PMC_DH_DeliveryInstructions__c,SalesPrice,PMC_DH_IsReorder__c,PMC_DH_Subscription__c,PMC_DH_SAPRequestReferenceNumber__c, PMC_DH_Subscription__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.PMC_CPQ_AdvanceBilling__c from CartItem  where cartId=:cartItemWrp.strCartId and Product2.StockKeepingUnit  IN :cartItemWrp.setSKu];
                }
            
            Contract cont = [SELECT Id,(Select Id, SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c,SBQQ__QuoteLine__r.SBQQ__Quote__r.PMC_CPQ_AdvanceBilling__c  FROM SBQQ__Subscriptions__r ), SBQQ__Quote__c, SBQQ__Quote__r.PMC_CPQ_PO__c, Account.RecordType.Name FROM Contract WHERE Id =:cartItemWrp.strContractId WITH SECURITY_ENFORCED LIMIT 1];
            // Map<String, String> mapPackType = getPackType(cont);
            for(CartItem objCartItem : lstCartitems)    {                
                PMC_DH_RequestToDeliverWrapper.CartItemWrapper cartItemWrap = new PMC_DH_RequestToDeliverWrapper.CartItemWrapper();
                cartItemWrap.intFiscalNumber = Integer.valueof(objCartItem.PMC_DH_NotaFiscalNumber__c);
                cartItemWrap.datNotaFiscalDate = objCartItem.PMC_DH_NotaFiscalDate__c;
                cartItemWrap.decSellOutPrice = objCartItem.PMC_DH_SellOutPrice__c;
                cartItemWrap.strDeliveryInstructions=objCartItem.PMC_DH_DeliveryInstructions__c;               
                cartItemWrap.strCartItemId = objCartItem.id;             
                cartItemWrap.strShipTo = getShipToForTP(cartItemWrap,objCartItem,cont);       
                cartItemWrap.strdeliveryMode = objCartItem.PMC_DH_DeliveryMode__c;       
                cartItemWrap.strIncoterms = objCartItem.PMC_DH_Incoterms__c;     
                cartItemWrap.strShipFrom = objCartItem.PMC_DH_PlantShipFrom__c;
                cartItemWrap.intQuantity = objCartItem.Quantity != null?objCartItem.Quantity.longValue():0;// GDASF-10697
                cartItemWrap.datRequestedShipmentDate = objCartItem.PMC_DH_RequestedShipmentDate__c;              
                cartItemWrap.strSource = STATUS;            
                cartItemWrap.strDeliveryPONumber = getPoNumber(cont.SBQQ__Quote__r.PMC_CPQ_PO__c,
                objCartItem.PMC_DH_DeliveryPONumber__c, strUserRegion);
                cartItemWrap.intPONumberIncrement = Integer.valueof(objCartItem.PMC_DH_POIncrementBy__c);          
                cartItemWrap.strFrequency = objCartItem.PMC_DH_Frequency__c;
                cartItemWrap.strSubscriptionId = objCartItem.PMC_DH_Subscription__c;      
                cartItemWrap.strCartItemReferenceNumber=objCartItem.PMC_DH_SAPRequestReferenceNumber__c;     
                cartItemWrap.strPackType = checkForNull(objCartItem.PMC_DH_PackType__c);       
                PMC_DH_RequestForQuoteController.ConnectApiWrapper objconnectapiProduct = mapProductDetail.get(objCartItem.Product2.StockKeepingUnit);         
                cartItemWrap.strSkuPackType = objconnectapiProduct.strProductPackType != null?getPackTypeValue(objconnectapiProduct.strProductPackType):'';
               // if(objCartItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c) 
               // { 
                
                // String quoteId=[select id,SBQQ__Quote__r.Id from contract where Id=:cartItemWrp.strContractId LIMIT 1].SBQQ__Quote__r.Id;
                // cartItemWrap.strPackType=[select id,SBQQ__Quote__r.Id,PMC_CPQ_PackageType__c, PMC_CPQ_PackType__c from SBQQ__QuoteLine__c   where SBQQ__Quote__c =:quoteId and SBQQ__Product__r.StockKeepingUnit  =:objCartItem.Product2.StockKeepingUnit limit 1].PMC_CPQ_PackType__c;
                // cartItemWrap.strSkuPackType =  [select id,SBQQ__Quote__r.Id,PMC_CPQ_PackageType__c, PMC_CPQ_PackType__c from SBQQ__QuoteLine__c   where SBQQ__Quote__c =:quoteId and SBQQ__Product__r.StockKeepingUnit  =:objCartItem.Product2.StockKeepingUnit limit 1].PMC_CPQ_PackType__c;
                // cartItemWrap.strPackageType=[select id,SBQQ__Quote__r.Id,PMC_CPQ_PackageType__c, PMC_CPQ_PackType__c from SBQQ__QuoteLine__c   where SBQQ__Quote__c =:quoteId and SBQQ__Product__r.StockKeepingUnit  =:objCartItem.Product2.StockKeepingUnit limit 1].PMC_CPQ_PackageType__c;
                // cartItemWrap.strPackageTypeOld=[select id,SBQQ__Quote__r.Id,PMC_CPQ_PackageType__c, PMC_CPQ_PackType__c from SBQQ__QuoteLine__c   where SBQQ__Quote__c =:quoteId and SBQQ__Product__r.StockKeepingUnit  =:objCartItem.Product2.StockKeepingUnit limit 1].PMC_CPQ_PackageType__c;

                         cartItemWrap.strPackageType = checkForNull(objCartItem.PMC_DH_PackageType__c);
                 cartItemWrap.strPackType=checkForNull(objCartItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PackType__c);
                  cartItemWrap.strSkuPackType =checkForNull(objCartItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PackType__c);
                   cartItemWrap.strPackageType=checkForNull(objCartItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PackageType__c);
                  cartItemWrap.strPackageTypeOld=checkForNull(objCartItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PackageType__c);
                    
                   
                    if(cartItemWrap.strPackType=='Packed')
                    {
                        cartItemWrap.strPackageTypeFlag=false;
                        }
                    else
                    {
                    cartItemWrap.strPackageTypeFlag=true;
                    }
               //}
                // cartItemWrap.strSkuPackType = mapPackType.get(objCartItem.Product2.StockKeepingUnit);
                //cartItemWrap.decNetUnitPrice = objCartItem.SalesPrice;
                if(!mapSkuToWrapper.containsKey(objCartItem.Product2.StockKeepingUnit)){
                    mapSkuToWrapper.put(objCartItem.Product2.StockKeepingUnit,new List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper>());                
                }
                mapSkuToWrapper.get(objCartItem.Product2.StockKeepingUnit).add(cartItemWrap);                
                cartItemWrap.strIncotermsLabel=PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(SBQQ__QuoteLine__c.PMC_CPQ_Incoterms1__c.getDescribe(),objCartItem.PMC_DH_Incoterms__c);
                cartItemWrap.strDeliveryModeLabel = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(cartItem.PMC_DH_DeliveryMode__c.getDescribe(),objCartItem.PMC_DH_DeliveryMode__c);
                if(objCartItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r != null){
                    shiptoacc = objCartItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.PMC_SS_SAPCustomerNumber__c;

            }
            }
            mapSkuToWrapper = PMC_DH_ContractDetailController.retriveShipmentInfoFromCartItem(mapSkuToWrapper);
            /*List<Contract> cobb = [SELECT Id,Account.PMC_SS_SAPCustomerNumber__c from contract WHERE Id =:cartItemWrp.strContractId LIMIT 1];
            if(cobb.size()>0){   shiptoacc = cobb[0].Account.PMC_SS_SAPCustomerNumber__c;} */
            
            
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());  
        }
        return mapSkuToWrapper;
    }
    
    /** 
* @method getPackTypeValue
* @description Get pack type value based on its label 
* @param packType
* @return String
*/
    public static String getPackTypeValue(String packType){
        Schema.DescribeFieldResult fieldResult = Product2.PMC_CPQ_PackType__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        if(!ple.isEmpty()){
            for(Schema.PicklistEntry pickListVal : ple){
                if(pickListVal.getLabel() == packType){
                    return pickListVal.getValue();
                }
            } 
        } 
        return null;
    }
    
    public static String getShipToForTP(PMC_DH_RequestToDeliverWrapper.CartItemWrapper cartItemWrap,CartItem objCartItem,Contract cont)
    {   
        PMC_DH_RequestToDeliverWrapper.CartWrapper cartWrapper = new PMC_DH_RequestToDeliverWrapper.CartWrapper();
        cartWrapper.boolThirdParty = getThirdParty(objCartItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c);
        
        if(objCartItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c==TRUE && objCartItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.PMC_CPQ_AdvanceBilling__c==TRUE ){    CheckTrueadvancebill=TRUE;
           }
        if(cartWrapper.boolThirdParty==false || objCartItem.PMC_DH_IsReorder__c == true) {            cartItemWrap.strShipTo=objCartItem.PMC_DH_ShipTo__c; 
            //cartItemWrap.strShipTo=objCartItem.PMC_DH_SoldToShipToJunction__c; // added as part of GDASF-17324
        }
        else {            cartItemWrap.strShipTo = getShipToTP(cartItemWrap,objCartItem);
        }
        return cartItemWrap.strShipTo;
    }
    
    /*************************************************************************
* @description  : Wrapper class CartItemParamWrapper
*****************************************************************************/
    public with sharing class CartItemParamWrapper{
        /**
* @description Cart Id
* @return  String 
*/
        @AuraEnabled
        public String strCartId{get;set;} 
        /**
* @description set of sku
* @return  Set<String> 
*/
        @AuraEnabled
        public Set<String> setSKu{get;set;}
        /**
* @description Delivery PO Number
* @return  String 
*/
        @AuraEnabled
        public String deliveryPoNumber{get;set;} 
        /**
* @description PO Increment By
* @return  Integer 
*/
        @AuraEnabled
        public Integer poNumberIncrement{get;set;} 
        /**
* @description Contract Id
* @return  String 
*/
        @AuraEnabled
        public String strContractId{get;set;} 
    }
    /*************************************************************************
* @method Name  : getPoNumber
* @description  : Method to get and set Delivery PO number on contract shipment
* @param    strQuotePoNumber
* @param    deliveryPoNumber
* @param    strUserRegion
* @return       : String
*****************************************************************************/
    public static String getPoNumber(String strQuotePoNumber, String deliveryPoNumber, String strUserRegion){
        String deliverPoNumber;
        // if(String.isNotBlank(deliveryPoNumber)){
        //     deliverPoNumber = deliveryPoNumber;
        // }else{
        //     deliverPoNumber = strQuotePoNumber;
        // }
        if(strUserRegion == REGION_BRAZIL){            deliverPoNumber = strQuotePoNumber;
        }
        else{ // strUserRegion = 'Canada' or 'United States'
            deliverPoNumber = deliveryPoNumber;
        }
        return deliverPoNumber;
    }
    /*************************************************************************
* @method Name  : getShipToForContract
* @description  : Method to get 'Ship To' information in wrapper form
* @param       	  strEffectiveAccountId
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/
    public static List<PMC_DH_PicklistWrapper> getShipToForContract(String strEffectiveAccountId)
    {        
        List<PMC_DH_PicklistWrapper> lstShipTo = new List<PMC_DH_PicklistWrapper>();
        
        List<PMC_SS_AccountPartnerRelationships__c> lstShipTpAccount = [SELECT Id, PMC_SS_Account__c, PMC_SS_Account__r.Name,
                                                                        PMC_SS_RelatedAccount__c, PMC_SS_RelatedAccount__r.Name,PMC_SS_RelatedAccount__r.PMC_DH_StreetNumber__c, PMC_SS_RelatedAccount__r.Type,
                                                                        PMC_SS_RelatedAccount__r.ShippingStreet, PMC_SS_RelatedAccount__r.ShippingCity, PMC_SS_RelatedAccount__r.ShippingPostalCode, PMC_SS_RelatedAccount__r.ShippingState,
                                                                        PMC_SS_RelatedAccount__r.PMC_SS_TaxIDOrCNPJOrCPF__c,PMC_SS_RelatedAccount__r.PMC_SS_StateTaxNumber__c,PMC_SS_RelatedAccount__r.ParentId,PMC_SS_RelatedAccount__r.shippingcountry,PMC_SS_RelatedAccount__r.PMC_DH_Delivery_Instruction__c  
                                                                        FROM PMC_SS_AccountPartnerRelationships__c WHERE PMC_SS_Account__c=:strEffectiveAccountId                                                                           
                                                                        AND PMC_SS_Type__c=:PMC_DH_ConstantClass.ACCOUNT_TYPE 
                                                                        AND PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c = 'Active'//GSMD-1284
                                                                        //AND PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c!=:PMC_DH_ConstantClass.ACCOUNT_INACTIVE_STATUS 
                                                                        WITH SECURITY_ENFORCED]; // removed PMC_SS_RelatedAccount__r.PMC_SS_MDMVerified__c=True condition as part of GDASF-19767
        if(!lstShipTpAccount.isEmpty()){
            for(PMC_SS_AccountPartnerRelationships__c objShipTo :PMC_DH_QuoteManagementHelper.removeDuplicateRelatedAccountsFromList(lstShipTpAccount)){  
                PMC_DH_PicklistWrapper shipTo = new PMC_DH_PicklistWrapper();
                String strShipToLabel = objShipTo.PMC_SS_RelatedAccount__r.Name + ' ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingStreet + ', ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingCity + ', ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingState + ' ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingPostalCode+' '+objShipTo.PMC_SS_RelatedAccount__r.PMC_SS_StateTaxNumber__c;
                shipTo.label = strShipToLabel;                shipTo.value = objShipTo.PMC_SS_RelatedAccount__c;                lstShipTo.add(shipTo);
            }
        }       
        return lstShipTo;
    }
    
    public static List<PMC_DH_PicklistWrapper> getShipToForContractNA(String strEffectiveAccountId)
    {
        List<PMC_DH_PicklistWrapper> lstShipTo = new List<PMC_DH_PicklistWrapper>();       
        List<PMC_SS_AccountPartnerRelationships__c> lstShipTpAccount = [SELECT Id, PMC_SS_Account__c, PMC_SS_Account__r.Name,
                                                                        PMC_SS_RelatedAccount__c, PMC_SS_RelatedAccount__r.Name,PMC_SS_RelatedAccount__r.PMC_DH_StreetNumber__c, PMC_SS_RelatedAccount__r.Type,
                                                                        PMC_SS_RelatedAccount__r.ShippingStreet, PMC_SS_RelatedAccount__r.ShippingCity, PMC_SS_RelatedAccount__r.ShippingPostalCode, PMC_SS_RelatedAccount__r.ShippingState,
                                                                        PMC_SS_RelatedAccount__r.PMC_SS_TaxIDOrCNPJOrCPF__c,PMC_SS_RelatedAccount__r.PMC_SS_StateTaxNumber__c,PMC_SS_RelatedAccount__r.ParentId,PMC_SS_RelatedAccount__r.shippingcountry,PMC_SS_RelatedAccount__r.PMC_DH_Delivery_Instruction__c  
                                                                        FROM PMC_SS_AccountPartnerRelationships__c WHERE PMC_SS_Account__c=:strEffectiveAccountId  AND
                                                                        PMC_SS_RelatedAccount__r.PMC_SS_MDMVerified__c=True
                                                                        AND PMC_SS_Type__c=:PMC_DH_ConstantClass.ACCOUNT_TYPE
                                                                        AND  PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c = 'Active'//GSMD-1284
                                                                        //AND  PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c!=:PMC_DH_ConstantClass.ACCOUNT_INACTIVE_STATUS
                                                                        WITH SECURITY_ENFORCED];                                                                 
        if(!lstShipTpAccount.isEmpty()){
            for(PMC_SS_AccountPartnerRelationships__c objShipTo :PMC_DH_QuoteManagementHelper.removeDuplicateRelatedAccountsFromList(lstShipTpAccount)){  
                PMC_DH_PicklistWrapper shipTo = new PMC_DH_PicklistWrapper();
                String strShipToLabel = objShipTo.PMC_SS_RelatedAccount__r.Name + ' ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingStreet + ', ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingCity + ', ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingState + ' ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingPostalCode+' '+objShipTo.PMC_SS_RelatedAccount__r.PMC_SS_StateTaxNumber__c;
                shipTo.label = strShipToLabel;
                shipTo.value = objShipTo.PMC_SS_RelatedAccount__c;
                lstShipTo.add(shipTo);
            }
        }
          
        return lstShipTo;
    }
    public static List<PMC_DH_PicklistWrapper> getShipToForContractforVCOANDBilling(String strEffectiveAccountId)
    {
        
        List<PMC_DH_PicklistWrapper> lstShipTo = new List<PMC_DH_PicklistWrapper>();

        List<PMC_SS_AccountPartnerRelationships__c> lstShipTpAccount = 
            [SELECT Id, PMC_SS_Account__c, PMC_SS_Account__r.Name, PMC_SS_RelatedAccount__r.PMC_SS_SAPCustomerNumber__c,
            PMC_SS_RelatedAccount__c, PMC_SS_RelatedAccount__r.Name, PMC_SS_RelatedAccount__r.PMC_DH_StreetNumber__c, 
            PMC_SS_RelatedAccount__r.Type, PMC_SS_RelatedAccount__r.ShippingStreet, PMC_SS_RelatedAccount__r.ShippingCity, 
            PMC_SS_RelatedAccount__r.ShippingPostalCode, PMC_SS_RelatedAccount__r.ShippingState, 
            PMC_SS_RelatedAccount__r.PMC_SS_TaxIDOrCNPJOrCPF__c, PMC_SS_RelatedAccount__r.PMC_SS_StateTaxNumber__c, 
            PMC_SS_RelatedAccount__r.ParentId, PMC_SS_RelatedAccount__r.ShippingCountry, 
            PMC_SS_RelatedAccount__r.PMC_DH_Delivery_Instruction__c  
            FROM PMC_SS_AccountPartnerRelationships__c 
            WHERE PMC_SS_Account__c=:strEffectiveAccountId 
             AND PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c ='Active'//GSMD-1284
             AND (PMC_SS_RelatedAccount__r.PMC_SS_SAPCustomerNumber__c =:shiptoacc  OR (PMC_SS_RelatedAccountSAPId__c LIKE '300%' OR PMC_SS_RelatedAccountSAPId__c = null))  
             AND PMC_SS_Type__c=:PMC_DH_ConstantClass.ACCOUNT_TYPE
             WITH SECURITY_ENFORCED];       
            
        if(!lstShipTpAccount.isEmpty()){            
            for(PMC_SS_AccountPartnerRelationships__c objShipTo :PMC_DH_QuoteManagementHelper.removeDuplicateRelatedAccountsFromList(lstShipTpAccount)){  
                PMC_DH_PicklistWrapper shipTo = new PMC_DH_PicklistWrapper();                
                String strShipToLabel = objShipTo.PMC_SS_RelatedAccount__r.Name + ' ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingStreet + ', ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingCity + ', ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingState + ' ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingPostalCode+' '+objShipTo.PMC_SS_RelatedAccount__r.PMC_SS_StateTaxNumber__c;                shipTo.label = strShipToLabel;                shipTo.value = objShipTo.PMC_SS_RelatedAccount__c;                lstShipTo.add(shipTo);
            }
        }
        
        return lstShipTo;
    }
    @TestVisible
    private static String checkForNull(String param){
        param = String.isBlank(param)?'':param;
        return param;
    }
    
    /**
* @description 
* @author Hemant Giri Goswami | hegoswami@deloitte.com | 11-06-2023 
* @param boolVCO   
* @return boolean 
**/
    public static boolean getThirdParty(Boolean boolVCO){
        Boolean isThirdParty=false;
        //To do CLM need to confirm contract type
        if(boolVCO)
        {     
            isThirdParty = true;
        } 
        
        return isThirdParty;
    }
    /*************************************************************************
* @method Name  : getShipToTP
* @description  : Method to get third party Ship To
* @param cartItemWrap
* @param objCartItem
* @return       : String
*****************************************************************************/
    @TestVisible
    private static String getShipToTP(PMC_DH_RequestToDeliverWrapper.CartItemWrapper cartItemWrap,CartItem objCartItem){
        if(objCartItem.PMC_DH_SellOutPrice__c!=null && objCartItem.PMC_DH_RequestedShipmentDate__c!=null)  
        {
            cartItemWrap.strShipTo=objCartItem.PMC_DH_ShipTo__c; 
            //cartItemWrap.strShipTo=objCartItem.PMC_DH_SoldToShipToJunction__c; // added as part of GDASF-17324
        }
        else {
            cartItemWrap.strShipTo=BLANK;
        }
        return cartItemWrap.strShipTo;
    }
    
    
    /*************************************************************************
* @method Name  : getCartItemObject
* @description : Method to get Cart Item Object
* @param strCartItemId
* @param strCartId
* @return CartItem
*****************************************************************************/
    public static CartItem getCartItemObject(String strCartItemId, String strCartId){
        CartItem objCartItem = new CartItem();
        if(String.isBlank(strCartItemId)){//insert
            objCartItem.CartId = strCartId;
        }else{
            objCartItem.Id = strCartItemId;
        }
        return objCartItem;
    }
    
    //added as part of GDASF-19767
    /*************************************************************************
* @method Name  : getThirdPartyAddresses
* @description  : Method to get third party addresses
* @param strEffectiveAccountId
* @param boolThirdParty
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/
    public static List<PMC_DH_PicklistWrapper> getThirdPartyAddresses(String strEffectiveAccountId, Boolean boolThirdParty){
        List<PMC_DH_PicklistWrapper> lstThirdPartyAddresses = new List<PMC_DH_PicklistWrapper>();
        String DefaultCurrency = UserInfo.getDefaultCurrency();           
        if(boolThirdParty){
            System.debug('CheckTrueadvancebill_______________'+CheckTrueadvancebill);
            if(CheckTrueadvancebill==TRUE && DefaultCurrency!='USD'){                
                lstThirdPartyAddresses = getShipToForContractforVCOANDBilling(strEffectiveAccountId); //  For Brazil User only--- GSMD-871
                System.debug('________________getShipToForContractforVCOANDBilling');
            }else{
                if(DefaultCurrency=='USD' ){
                    lstThirdPartyAddresses = getShipToForContractNA(strEffectiveAccountId);  
                    System.debug('________________getShipToForContractNA');
                }else{  
                    lstThirdPartyAddresses = getShipToForContract(strEffectiveAccountId); //GDASF-19767
                    System.debug('________________getShipToForContract');
                }  
            }
            
        }
        
        /* if(boolThirdParty){
lstThirdPartyAddresses = getShipToForContract(strEffectiveAccountId); //GDASF-19767
}*/ 
        
        return lstThirdPartyAddresses;
    }
    
    /*************************************************************************
* @method Name  : getDeliveryPONumber
* @description  : Method to get delivery PO Number of Order
* @param lstCartItems
* @return       : String
*****************************************************************************/
    public static String getOrderDeliveryPONumber(List<CartItem> lstCartItems) {
        String poNumber = ' ';
        if(lstCartItems.size()==1) {
            poNumber = lstCartItems[0].PMC_DH_DeliveryPONumber__c;
        }
        return poNumber;
    }
    
    /*************************************************************************
* @method Name  : getLineItemPO
* @description  : Method to get delivery PO Number of order line item
* @param lstCartItems
* @param ci
* @return       : String
*****************************************************************************/
    public static String getLineItemPO(List<CartItem> lstCartItems, CartItem ci) {
        String poNumber = '';
        if(lstCartItems.size()>1) {            return ci.PMC_DH_DeliveryPONumber__c;
        }
        return poNumber;
    }
}