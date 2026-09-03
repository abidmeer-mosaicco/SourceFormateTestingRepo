/**
* @description       : Test Class for the PMC_DH_MiniCartTest
* @author            : @Sugunakar Routhu
* @group             : 
* Created On         : 25-Apr-2023
* JIRA Story         : GDASF-28
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            version     Date              Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Sugunakar              1.0       25-Apr-2023        Initial code 
*/
@isTest
public with sharing class PMC_DH_MiniCartTest {
    /*************************************************************************
* @method Name  : dataSetup
* @description  : test data setup for the mini cart
*****************************************************************************/
    
    @testSetup public static void dataSetup()
    {
        
        Account objAcc=PMC_DH_TestDataFactoryClass.createTestAccount();
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Digital Hub Super Buyer' LIMIT 1];
        User usr=PMC_DH_TestDataFactoryClass.createTestUser(objAcc.Id,profile.Id);
        //PMC_DH_TestDataFactoryClass.createTestWebStore();
        Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(usr.Id,lstPermSet2);
        Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(usr.Id,lstPermSet);
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(usr.Id,lstPermSet1);
        Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(usr.Id,lstPermSet3);
        
        WebStore storeRec= PMC_DH_TestDataFactoryClass.createTestWebStore();
         /*
        WebStoreNetwork wbN =new WebStoreNetwork();
        wbN.WebStoreId=storeRec.Id;
        wbN.NetworkId= [SELECT NetworkId FROM NetworkMember LIMIT 1].NetworkId;
        insert wbN;*/
        
        Product2 objprodData = PMC_DH_TestDataFactoryClass.createProduct();
        insert objprodData;
        
        System.runAs(usr){
       
        
        WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(storeRec.Id,objAcc.Id);
        Insert cartObj;
        
        CartDeliveryGroup objcartDeliveryGroup = PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj.Id);
        insert objcartDeliveryGroup;
        
        
        CartItem objcartItemData = PMC_DH_TestDataFactoryClass.buildCartItem(cartObj.Id, objprodData.Id, objcartDeliveryGroup.Id);
        insert objcartItemData;
        }
        
    }
    
    /*************************************************************************
* @method Name  : fetchCartItemsTest
* @description  : To cover the fetch Cart Items Logic
*****************************************************************************/
    
    
    @isTest
    public static void fetchCartItemsTest(){
        Test.startTest();
        
        User objCommereceUser=[SELECT id from User WHERE Username = 'demouser@test.com.testuser'];
        String strTestAcctId = [SELECT Id,Name from Account LIMIT 1].Id;
        String strwebStoreId = [SELECT Id,Name from WebStore Where Name='TestWebStore' LIMIT 1].Id;
        
        system.runAs(objCommereceUser){
            String strNetworkId= PMC_DH_TestDataFactoryClass.getNetworkId(strwebStoreId);
            try{
                PMC_DH_MiniCart.fetchMiniCartItems(strTestAcctId, strNetworkId);
            }
            Catch(Exception ex){
                System.assertEquals('Script-thrown exception', ex.getMessage(),'Actual & Excepted values are not same');
            }
            
        }
        Test.stopTest();
    } 
    
    
     /*************************************************************************
* @method Name  : miniCartWrapper
* @description  : To cover wrapper of mini cart
*****************************************************************************/
    @isTest
    public static void miniCartWrapperTest(){
        User objCommereceUser=[SELECT id from User WHERE Username = 'demouser@test.com.testuser'];
        CartItem cartItemRec= [SELECT Id,Name, CartId, Cart.PMC_DH_PaymentTerms__c, SKU from CartItem LIMIT 1];
        System.runAs(objCommereceUser){
            List<PMC_DH_MiniCartWrapper.cartItemData> lstcartItemData = new List<PMC_DH_MiniCartWrapper.cartItemData>();
            PMC_DH_MiniCartWrapper.CartItemData objCartItemData = new PMC_DH_MiniCartWrapper.CartItemData();
            objCartItemData.strCartIId=cartItemRec.cartId;
            objCartItemData.strCartItemId=cartItemRec.Id;
            objCartItemData.strCartItemName =cartItemRec.Name;
            objCartItemData.strproductSKUCode = cartItemRec.SKU;
            lstcartItemData.add(objCartItemData);
            PMC_DH_MiniCartWrapper miniWrapper = new  PMC_DH_MiniCartWrapper();
            miniWrapper.cartItemsList=lstcartItemData;
            PMC_DH_MiniCart.updatePrepayField(cartItemRec);
            System.assertEquals(false, miniWrapper.cartItemsList.isEmpty(),'Actual & Excepted values are not same');
        }
    }
        
        
    
    
    /*************************************************************************
* @method Name  : deleteCartItemsTest
* @description  : To cover the delete Cart Item try Logic
*****************************************************************************/
    @isTest
    public static void deleteCartItemsTest(){
        Test.startTest();
        User objCommereceUser=[SELECT id from User WHERE Username = 'demouser@test.com.testuser'];
        CartItem cartItemRec= [SELECT Id, CartId, Product2.StockKeepingUnit from CartItem LIMIT 1];
        system.runAs(objCommereceUser){
            PMC_DH_MiniCart.deleteCartItems(cartItemRec.Product2.StockKeepingUnit, cartItemRec.CartId);
            List<CartItem> lstCartItem= [SELECT Id, CartId, Product2.StockKeepingUnit from CartItem Where Product2.StockKeepingUnit=:cartItemRec.Product2.StockKeepingUnit];
            System.assertEquals(true, lstCartItem.isEmpty(), 'Actual & Excepted values are not same');
        }
        Test.stopTest();
    } 
    
     /*************************************************************************
* @method Name  : deleteCartItemsCatchTest
* @description  : To cover the delete Cart Item Catch Logic
*****************************************************************************/
    @isTest
    public static void deleteCartItemsCatchTest(){
        Test.startTest();
        try{
            User objCommereceUser=[SELECT id from User WHERE Username = 'demouser@test.com.testuser'];
            CartItem cartItemRec= [SELECT Id, CartId, Product2.StockKeepingUnit from CartItem LIMIT 1];
            system.runAs(objCommereceUser){
                PMC_DH_MiniCart.throwTestException=true;
                PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper resp = PMC_DH_MiniCart.deleteCartItems(cartItemRec.Product2.StockKeepingUnit, cartItemRec.CartId);
                // List<CartItem> lstCartItem= [SELECT Id, CartId, Product2.StockKeepingUnit from CartItem Where Product2.StockKeepingUnit=:cartItemRec.Product2.StockKeepingUnit];
                System.assertEquals(true, resp.strStatusCode == '100', 'Actual & Excepted values are not same');
            }
        }Catch(Exception ex){
            System.assertEquals(true, ex.getMessage()!=NULL, 'Actual & Excepted values are not same');
        }
        Test.stopTest();
    } 
    
    
}