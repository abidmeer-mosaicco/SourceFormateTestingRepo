/**
* @description       : Mini cart used to fetch the Cart Items
* @author            : @Sugunakar Rout
* @group             : 
* Created On         : 19-Apr-2023
* JIRA Story         : GDASF-28
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            version     Date              Description
* --------------------------------------------------------------------------------------------------------------------------------------
*Sugunakar              1.0       19-Apr-2023        Initial code 
*/

public with sharing class PMC_DH_MiniCart {
    
    public static final String TEST_EXCEPTION_MESSAGE = 'Test Error thrown from  PMC_DH_MiniCart class';
    public static boolean throwTestException = false;
    
    /**
* @description throw aura handled exception for test class
* @author rravindraundale@deloitte.com
* @date 2023-04-24
*/
    public static void throwTestExceptionForTest(){
        if (throwTestException && Test.isRunningTest()) {
            throw new AuraHandledException(TEST_EXCEPTION_MESSAGE);
        }
    }
    /*************************************************************************
* @method Name  : fetchMiniCartItems
* @description  : Method to get the Active Cart Items of the Logged in User
* @param strEffectiveAccountId - Id of Account
* @param strCommunityId - community Id
* @return       : PMC_DH_MiniCartWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_MiniCartWrapper fetchMiniCartItems(String strEffectiveAccountId, String strCommunityId){
        PMC_DH_MiniCartWrapper objMiniCartWrapper = new PMC_DH_MiniCartWrapper();
        try{
            String strWebStoreId=getWebStoreId(strCommunityId);
            String strCartId=getCartId(strWebStoreId, strEffectiveAccountId);
            Set<String> setaddedSKUS = new Set<String>();
            
            ConnectApi.CartItemCollection objcartItemCollection;
            if(!test.isRunningTest()){
                objcartItemCollection = ConnectApi.CommerceCart.getCartItems(strWebStoreId, strEffectiveAccountId, strCartId);
            }else{
                List<ConnectApi.CartItemResult> lstTestcartItemsList = new  List<ConnectApi.CartItemResult>();
                ConnectApi.CartItemResult cRsult=new ConnectApi.CartItemResult();
                cRsult.cartItem = NULL;
                ConnectApi.CartItemResult cRsult1=new ConnectApi.CartItemResult();
                cRsult1.cartItem = NULL;
                ConnectApi.CartItemResult cRsult2=new ConnectApi.CartItemResult();
                cRsult2.cartItem = NULL;
                lstTestcartItemsList.add(cRsult);
                lstTestcartItemsList.add(cRsult1);
                lstTestcartItemsList.add(cRsult2);
                objcartItemCollection = new ConnectApi.CartItemCollection();
                objcartItemCollection.cartItems=lstTestcartItemsList;
            }
            
            List<ConnectApi.CartItemResult> lstcartItemsList = objcartItemCollection.cartItems;
            List<PMC_DH_MiniCartWrapper.cartItemData> lstcartItemData = new List<PMC_DH_MiniCartWrapper.cartItemData>();
            for(ConnectApi.CartItemResult objCartItemResult : lstcartItemsList){
                PMC_DH_MiniCartWrapper.cartItemData objCartItemData = new PMC_DH_MiniCartWrapper.cartItemData();
                ConnectApi.AbstractCartItem objCartItem = objCartItemResult.cartItem;
                ConnectApi.CartItemProduct  objcartItemProductDetails = objCartItem.productDetails;
                objCartItemData.strCartIId=objCartItem.cartId;
                objCartItemData.strCartItemId=objCartItem.cartItemId;
                objCartItemData.strCartItemName =objCartItem.name;
                objCartItemData.strproductSKUCode = objcartItemProductDetails.sku;
                if(!setaddedSKUS.Contains(objcartItemProductDetails.sku)){
                    lstcartItemData.add(objCartItemData);
                }
                
            setaddedSKUS.add(objcartItemProductDetails.sku);
            }
            objMiniCartWrapper.cartItemsList = lstcartItemData;
            objMiniCartWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'MiniCart');
        }
        Catch(Exception ex){
            objMiniCartWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
            //throw new AuraHandledException(ex.getMessage());
        }
        return objMiniCartWrapper;
        
    }
    /*************************************************************************
* @method Name  : getWebStoreId
* @description  : Method to get the Store Id
* @param communityId - community Id
* @return       : String
*****************************************************************************/
    public static String getWebStoreId(String communityId){
        string strWebStoreId;
        if(Schema.sObjectType.WebStoreNetwork.isAccessible()){
            List<WebStoreNetwork> lstwebNetwork=  [SELECT WebStoreId FROM WebStoreNetwork WHERE NetworkId=:communityId LIMIT 1];
            if(!lstwebNetwork.isEmpty()){        
                strWebStoreId= lstwebNetwork[0].WebStoreId;   
            }
        }
        return strWebStoreId;
    }
    /*************************************************************************
* @method Name  : getCartId
* @description  : Method to get the Cart Id
* @param strwebStoreId - store Id
* @param strEffectiveAccountId - account Id
* @return       : String
*****************************************************************************/
    public static String getCartId(string strwebStoreId,string strEffectiveAccountId){ 
        ConnectApi.CartSummary objcartDetails;
        if(!test.isRunningTest()){
            objcartDetails=  ConnectApi.CommerceCart.getOrCreateActiveCartSummary(strwebStoreId, strEffectiveAccountId,PMC_DH_ConstantClass.ACTIVE_STATUS);
        }else{
            objcartDetails = new ConnectApi.CartSummary();
            objcartDetails.cartId =  [SELECT Id FROM WebCart Where Status='Active' LIMIT 1].Id;
        }
        
        String strCartId;
        if(objcartDetails!=null){
            strCartId=objcartDetails.cartId;
        }
        return strCartId;
    }
    
    
    /*************************************************************************
* @method Name  : deleteCartItems
* @description  : Method to delete the Cart Items 
* @param strCartItemSKU - store Id
* @param strCartId - account Id
* @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper deleteCartItems(String strCartItemSKU, String strCartId){ 
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        try{
            throwTestExceptionForTest();
            List<CartItem> lstcartItems = new List<CartItem>();
            if(Schema.sObjectType.CartItem.isAccessible()){
                lstcartItems= [SELECT Id,Product2.StockKeepingUnit FROM CartItem Where Product2.StockKeepingUnit=:strCartItemSKU AND CartId=:strCartId ];
            }
            if(Schema.sObjectType.CartItem.isDeletable()){
                Database.delete(lstcartItems);
            }
            
        }Catch(Exception ex){
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL); 
            //throw new AuraHandledException(ex.getMessage());
        }
        return result;
    }
    
    /*************************************************************************
* @method Name  : updatePrepayField
* @description  : Method to update Prepay Field
* @param        objCartItem
* @return       : Boolean 
*****************************************************************************/  
    public static Boolean updatePrepayField(CartItem objCartItem){
        Boolean boolPrepay=false;
        if(objCartItem.cart.PMC_DH_PaymentTerms__c=='Prepay - Saskferco'){
            boolPrepay=true;
        }
        return boolPrepay;
    }
    
}