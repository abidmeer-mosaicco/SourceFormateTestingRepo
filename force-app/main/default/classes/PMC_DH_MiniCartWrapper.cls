/**
 * @description       : 
 * @author            : @sugunakar
 * @group             : DIGITAL HUB
 * @last modified on  : 05-18-2023
 * @last modified by  : @siddharth.pradhan
**/
public class PMC_DH_MiniCartWrapper {
    
    /**
    * @description FETCHES CARTITEM LIST FOR MINI CART
    * @author @SUGUNAKAR | 05-06-2023 
    * @return List<cartItemData> cartItemsList
    **/
    @AuraEnabled
    public List<CartItemData> cartItemsList{get;set;}
    /**
    * @description Status Code and message
    * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
       
          /**
    * @description Wrapper Class for List of cart items
    * @author @SUGUNAKAR | 05-06-2023 
    **/
    public class CartItemData{
        /**
    * @description FETCHES CART ID
    * @author @SUGUNAKAR | 05-06-2023 
    * @return string strCartIId
    **/
        @AuraEnabled
        public string strCartIId{get;set;}
        /**
    * @description FETCHES CART ITEM ID 
    * @author @SUGUNAKAR | 05-06-2023 
    * @return string strCartItemId
    **/

        @AuraEnabled
        public string strCartItemId{get;set;}
        /**
    * @description FETCHES CART ITEM NAME
    * @author @SUGUNAKAR | 05-06-2023 
    * @return string strCartItemName
    **/

        @AuraEnabled
        public string strCartItemName{get;set;}
        /**
    * @description FETCHES CART ITEM SKU
    * @author @SUGUNAKAR | 05-06-2023 
    * @return string strproductSKUCode
    **/
        @AuraEnabled
        public string strproductSKUCode{get;set;}
    }
}