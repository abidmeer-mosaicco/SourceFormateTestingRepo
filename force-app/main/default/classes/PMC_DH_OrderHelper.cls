/** 
* @description Helper class for order
* @author Mosaic Direct Dev 
* Created On       :2023-11-27
**/
public without sharing class PMC_DH_OrderHelper {
    private static final String CONST_VARIABLE_CODE2 = '000'; //GPT-34482
    private static final String CARTITEMS_UPDATE = 'CartItemsUpdate'; //GPT-34482
    private static final String CONST_VARIABLE_CODE = '111'; //GPT-34482
    private static final String DUPLICATE_CARTITEM = 'DuplicateCartItem'; //GPT-34482
	 /*************************************************************************
* @method Name  : getPackType
* @description  : Method to get PackType for shipment Items
* @param        ordItem
* @return       : String
*****************************************************************************/
    public static String getPackType(OrderItem ordItem){
        String strPackType = '';
          if(String.isNotBlank(ordItem.PMC_CPQ_PackageType__c) && ordItem.PMC_CPQ_PackageType__c != Null){
                strPackType = 'Packed';
            }
            else{
               strPackType = 'Bulk';
            }
        return strPackType;
    } 
     
 /*************************************************************************
    * @method Name  : updateSystemCustomerCallPriceDate
    * @author Mosaic Direct Dev 
    * @description  : Method to validate System Customer Call PriceDate
    * @param         lstOrderItemIDs
    * @param         strOrderId
    * @return   List<OrderItem>
    *****************************************************************************/  
    public static List<OrderItem> updateSystemCustomerCallPriceDate(List<String> lstOrderItemIDs, String strOrderId){
        if(!lstOrderItemIDs.isEmpty()){
            PMC_DH_OrderManagementController.validateOrderItemsList(lstOrderItemIDs);    
        }
        List<OrderItem> lstOrderItem =[SELECT Id,PMC_CPQ_SAPOrderLineID__c, PMC_CPQ_RequestedShipDate__c, PMC_DH_ItemNumber__c, PMC_CPQ_ShipTo__c, PMC_CPQ_ShipTo__r.Name, 
                         PMC_CPQ_ShipTo__r.ShippingStreet, PMC_CPQ_ShipTo__r.ShippingCity, PMC_CPQ_ShipTo__r.ShippingState,PMC_CPQ_ReasonOfRejectionOfItem__c, 
                         PMC_CPQ_ShipTo__r.ShippingPostalCode, PMC_CPQ_ProductLocation__c, PMC_CPQ_ProductLocation__r.Name, 
                         PMC_CPQ_ModeofTransportation__c, PMC_CPQ_Incoterms__c, Product2.StockKeepingUnit, Quantity, AvailableQuantity, 
                         PMC_CPQ_ConfirmedQuantity__c, PMC_CPQ_OrderLineStatus__c, LineNumber, PMC_DH_ShippedQuantity__c, 
                         SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PriceByDate__c,PMC_DH_CustomerCallPriceDate__c,PMC_CPQ_FPDPricefromPriceFx__c,
                         PMC_CPQ_FinalAgreedPrice__c,PMC_DH_CallPriceRequestedBySystem__c,OrderId, Product2Id
                        FROM OrderItem  WHERE OrderId =:strOrderId WITH SECURITY_ENFORCED];
        return lstOrderItem;
    }

    //GPT-34482
     /*************************************************************************
    * @method       checkNewOrDuplicateCartItems
    * @author       Mosaic Direct Dev 
    * @description  Method to check if cart item(s) are already present in cart
    * @param        lstCartitems 
    * @param        objExistingCartItem 
    * @return       PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    *****************************************************************************/  

    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper checkNewOrDuplicateCartItems(List<CartItem> lstCartitems, CartItem objExistingCartItem){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        if(!lstCartitems.isEmpty() && (Schema.sObjectType.CartItem.isCreateable()||Schema.sObjectType.CartItem.isUpdateable())){
            //List<Database.UpsertResult> rt = Database.upsert(lstCartitems, false, AccessLevel.USER_MODE);
            Upsert lstCartitems;
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(CONST_VARIABLE_CODE2, CARTITEMS_UPDATE);
        }
        else if(String.isNotBlank(objExistingCartItem.Id)){ 
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(CONST_VARIABLE_CODE, DUPLICATE_CARTITEM);
        }
        return result;
    }
    
}