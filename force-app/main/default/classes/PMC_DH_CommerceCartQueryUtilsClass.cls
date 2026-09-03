/**
 * @description       : 
 * @author            : Mosaic Direct | Dev Team
 * @group             : 
 * @last modified on  : 03-01-2024
 * @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
public without sharing class PMC_DH_CommerceCartQueryUtilsClass {

    /****************************************************************************
    * @method Name  : getCartItemsForSingleCart
    * @description  : Method to get the List of Cart Items of the Cart
    * @param     strCartId
    * @return    List<CartItem>
    */
    //change log - query update for GPT-28361 | added PMC_CPQ_FinalPricePerTonne__c
    public static List<CartItem> getCartItemsForSingleCart(Id strCartId) {
        // PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PackageType__c-> Added as part of 20003
        List<CartItem> lstCartItems=[select id,PMC_DH_ProtocolNumber__c,cart.PMC_DH_CartReferenceNumber__c,cartId,PMC_DH_SAPRequestReferenceNumber__c,PMC_DH_PackType__c,PMC_DH_PackageType__c,Cart.AccountId,PMC_DH_PlantShipFrom__r.PMC_CPQ_Location__r.PMC_CPQ_Plant__c,product2.StockKeepingUnit,Product2.Name,PMC_DH_Incoterms__c,cart.CreatedBy.Name,PMC_DH_NotaFiscalNumber__c,PMC_DH_NotaFiscalDate__c,
            TotalPrice,PMC_DH_RequestedShipmentDate__c,PMC_DH_Contract__r.ContractNumber,PMC_DH_ItemNumber__c,PMC_DH_PlantShipFrom__r.PMC_CPQ_Address__c, PMC_DH_ShipTo__r.ShippingAddress,PMC_DH_ShipTo__r.PMC_SS_SAPCustomerNumber__c,PMC_DH_SellOutPrice__c,PMC_DH_DeliveryInstructions__c,PMC_DH_DeliveryMode__c,
            cart.PMC_DH_Account__r.RecordType.name,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c,PMC_DH_ShipTo__r.Type,PMC_DH_DeliveryPONumber__c,cart.PMC_DH_PaymentTerms__c,PMC_DH_ShipTo__r.PMC_SS_Channel__c,Quantity,cart.PMC_DH_Account__r.PMC_SS_AccountExternalID__c,PMC_DH_Subscription__r.Name,PMC_DH_ShipTo__r.PMC_SS_AccountExternalID__c,
            PMC_DH_UnitofMeasure__c, PMC_DH_Contract__r.PMC_CPQ_ContractNumberIdentifier__c, PMC_DH_Subscription__r.PMC_CPQ_SubscriptionNumberIdentifier__c,PMC_DH_Subscription__r.PMC_CPQ_FinalPricePerTonne__c,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_FinalPricePerTonne__c, PMC_DH_Contract__r.SBQQ__Quote__r.SBQQ__PaymentTerms__c, PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_UnitofMeasure__c,
            PMC_DH_Subscription__r.SBQQ__RevisedSubscription__c, PMC_DH_Subscription__r.SBQQ__RevisedSubscription__r.name,PMC_DH_Subscription__r.SBQQ__RevisedSubscription__r.PMC_CPQ_FinalPricePerTonne__c,PMC_DH_Subscription__r.SBQQ__RevisedSubscription__r.SBQQ__QuoteLine__r.PMC_CPQ_UnitofMeasure__c,PMC_DH_Subscription__r.SBQQ__RevisedSubscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PackageType__c,
            PMC_DH_ShipTo__r.PMC_SS_CPF__c, PMC_DH_ShipTo__r.PMC_SS_TaxIDOrCNPJOrCPF__c,PMC_DH_ShipTo__r.PMC_SS_StateTaxNumber__c, PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PackageType__c,PMC_DH_Contract__r.PMC_CPQ_LatestQuote__r.Name,
            PMC_DH_Subscription__r.SBQQ__QuoteLine__r.SBQQ__UpgradedSubscription__r.Name,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.SBQQ__Product__r.Name from cartitem where CartId=:strCartId WITH SECURITY_ENFORCED]; // added as part of GDASF-19767         
        return lstCartItems;
    }
    /****************************************************************************
    * @method Name  : getAccountExternalId
    * @description  : Method to get the Account id
    * @param     strAccountId
    * @return    String
    */
    public static String getAccountExternalId(Id strAccountId) {
        List<Account> lstAccount=[select Id, PMC_SS_AccountExternalID__c from Account where Id = :strAccountId WITH SECURITY_ENFORCED];
        return  lstAccount[0].PMC_SS_AccountExternalID__c; 
    }
     /**
* @description  method to get cartitem based on orderLinenumber for order edit
* @author  Mosaic Direct Dev 
* @param  strOrderLineId
* @return List<CartItem>
**/ 
    
    public static List<CartItem> getSingleCartItem(String strOrderLineId){
        List<CartItem> lstCartItems = new List<CartItem>();
		lstCartItems = [SELECT id,PMC_DH_ProtocolNumber__c,PMC_DH_SAPRequestReferenceNumber__c,PMC_DH_PackType__c,PMC_DH_PackageType__c,
                            Cart.AccountId,PMC_DH_PlantShipFrom__r.PMC_CPQ_Location__r.PMC_CPQ_Plant__c,PMC_DH_UnitofMeasure__c,
                            product2.StockKeepingUnit,Product2.Name,PMC_DH_Incoterms__c,cart.CreatedBy.Name,
                            PMC_DH_NotaFiscalNumber__c,PMC_DH_NotaFiscalDate__c,TotalPrice,PMC_DH_RequestedShipmentDate__c,
                            PMC_DH_Contract__r.ContractNumber,PMC_DH_ItemNumber__c,PMC_DH_PlantShipFrom__r.PMC_CPQ_Address__c,
                            PMC_DH_ShipTo__r.ShippingAddress,PMC_DH_ShipTo__r.PMC_SS_SAPCustomerNumber__c,
                            PMC_DH_SellOutPrice__c,PMC_DH_DeliveryInstructions__c,PMC_DH_DeliveryMode__c,
                            PMC_DH_DeliveryPONumber__c,cart.PMC_DH_PaymentTerms__c,Quantity,
                            cart.PMC_DH_Account__r.PMC_SS_AccountExternalID__c, PMC_DH_Subscription__r.Name,
                            cart.PMC_DH_Account__r.RecordType.name,PMC_DH_ShipTo__r.PMC_SS_Channel__c,
                            PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c,PMC_DH_ShipTo__r.Type,
                            PMC_DH_ShipTo__r.PMC_SS_AccountExternalID__c, PMC_DH_Contract__r.SBQQ__Quote__r.SBQQ__PaymentTerms__c, PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_UnitofMeasure__c,
                            PMC_DH_ShipTo__r.PMC_SS_CPF__c, PMC_DH_ShipTo__r.PMC_SS_TaxIDOrCNPJOrCPF__c,PMC_DH_ShipTo__r.PMC_SS_StateTaxNumber__c,PMC_DH_Contract__r.PMC_CPQ_LatestQuote__r.Name from cartitem 
                            WHERE PMC_DH_SAPRequestReferenceNumber__c = :strOrderLineId WITH SECURITY_ENFORCED];
        return lstCartItems;         
    }

    /**
    * @description  method to get Packagetype
    * @author  Mosaic Direct Dev 
    * @param  strPackType
    * @param strPackageType
    * @return String
    **/ 
    public static String getPackOrPackageType(String strPackType, String strPackageType){
        if(strPackType.toLowerCase() == 'bulk'){
            return strPackType;
        }
        else{
            return strPackageType;
        }
    }
    
}