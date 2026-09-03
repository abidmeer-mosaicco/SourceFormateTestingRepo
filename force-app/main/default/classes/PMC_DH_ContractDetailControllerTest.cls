/**
* @description : Test class for PMC_DH_ContractUtil
* @author      : Rohan Undale
* @userStory   : GDASF-142 & GDASF-8927 
* @last modified by Rohan Undale
* @last modified on 06-29-2023
**/
@isTest
public with sharing class PMC_DH_ContractDetailControllerTest {
    /**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* @param: none
* @return: void
* @author Rohan
*/
    @testSetup  static void setup()
    {
        Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
        
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strContactId=[SELECT contactId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1][0].contactId;
        Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet2);
        Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet);
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet1);
        Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet3);
        
        WebStore webStore=PMC_DH_TestDataFactoryClass.createTestWebStore();
        system.runAs(user){
            WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
            insert cartObj;
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            insert prod;
            CartDeliveryGroup testCartDeliveryGroup=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj.id);
            insert testCartDeliveryGroup;
            CartItem cartItem=PMC_DH_TestDataFactoryClass.buildCartItem(cartObj.id, prod.id,testCartDeliveryGroup.Id);
            insert cartItem;
            
            Account shipToAcc=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
            shipToAcc.PMC_DH_Account_Status__c = 'Active';
            shipToAcc.PMC_SS_MDMVerified__c = TRUE;
            update shipToAcc;
            Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
            PMC_CPQ_ProductLocation__c prodLocation = PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
            PMC_DH_TestDataFactoryClass.CartItemObject objCartItem=new PMC_DH_TestDataFactoryClass.CartItemObject();
            objCartItem.strCartId=cartObj.id;
            objCartItem.strProductId=prod.id;
            objCartItem.strDeliveryGroupId=testCartDeliveryGroup.id;
            objCartItem.strShipToAccId=shipToAcc.id;
            objCartItem.strShipFromId=prodLocation.id;
            CartItem cartItem1=PMC_DH_TestDataFactoryClass.buildCartItem1(objCartItem); 
            insert cartItem1;
            
            Test.startTest();
            Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
            SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,prod);
            Contract testContract=PMC_DH_TestDataFactoryClass.createContract(testQuote.id,acc.id);
            
            testQuoteLine.PMC_CPQ_VCOQuotation__c=true;
            testQuoteLine.PMC_CPQ_ShipTo__c = shipToAcc.Id;
            update testQuoteLine;
            PMC_DH_TestDataFactoryClass.CartItemObject objCartItem1=new PMC_DH_TestDataFactoryClass.CartItemObject();
            objCartItem1.strCartId=cartObj.id;
            objCartItem1.strProductId=prod.id;
            objCartItem1.strDeliveryGroupId=testCartDeliveryGroup.id;
            objCartItem1.strShipToAccId=shipToAcc.id;
            objCartItem1.strShipFromId=prodLocation.id;
            objCartItem1.strQuoteLineId = testQuoteLine.Id;
            objCartItem1.strContractId = testContract.Id;
            PMC_DH_TestDataFactoryClass.createSubscription(objCartItem1);
            Test.stopTest();
        }
    }
    
    /**
* @description Test Method for addCartItems
* @param: none
* @return: void
* @author Rohan
*/  
    @isTest
    public static void addCartItemsTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        
        CartItem cartItems =[select id,Product2.Name,Product2Id,Product2.StockKeepingUnit, PMC_DH_ShipTo__c, PMC_DH_PlantShipFrom__c, PMC_DH_DeliveryMode__c, PMC_DH_Incoterms__c, Type, CartDeliveryGroupId, Quantity, PMC_DH_Contract__c from CartItem where cartid=:strCartId and Name='Test Cart Item1'];
        cartItems.PMC_DH_Source__c = 'RTD';
        update cartItems;
        List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper> lstCartItemWrap = new List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>();
        PMC_DH_RequestForQuoteWrapper.CartItemWrapper cartItemWrap = new PMC_DH_RequestForQuoteWrapper.CartItemWrapper();
        cartItemWrap.strCartItemId = cartItems.id;
        cartItemWrap.strQuantity = PMC_DH_ConstantClass.PRODUCT_QUANTITY;
        cartItemWrap.strShipTo = cartItems.PMC_DH_ShipTo__c;
        cartItemWrap.strIncoterms =cartItems.PMC_DH_Incoterms__c;
        cartItemWrap.strDeliveryMode =cartItems.PMC_DH_DeliveryMode__c;
        cartItemWrap.strShipFrom =cartItems.PMC_DH_PlantShipFrom__c;
        cartItemWrap.strSource ='RTD';
        cartItemWrap.strProductId = cartItems.Product2Id;
        cartItemWrap.strProductName = cartItems.Product2.Name;
        lstCartItemWrap.add(cartItemWrap);
        
        PMC_DH_ContractDetailController.CartItemWrapper objCrtItemWrp = new PMC_DH_ContractDetailController.CartItemWrapper();
        objCrtItemWrp.strCartId = strCartId;
        objCrtItemWrp.strCurrency = 'USD';
        objCrtItemWrp.strContractId = cartItems.PMC_DH_Contract__c;
        String strInput = JSON.serialize(lstCartItemWrap);
        system.runAs(user){
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result=PMC_DH_ContractDetailController.addCartItem(objCrtItemWrp, strInput);
            system.assert(result!=null,'success');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for addCartItems
* @param: none
* @return: void
* @author Rohan
*/  
    @isTest
    public static void addCartItemsTest2()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        
        CartItem cartItems =[select id,Product2.Name,Product2Id,Product2.StockKeepingUnit, PMC_DH_ShipTo__c, PMC_DH_PlantShipFrom__c, PMC_DH_DeliveryMode__c, PMC_DH_Incoterms__c, Type, CartDeliveryGroupId, Quantity, PMC_DH_Contract__c from CartItem where cartid=:strCartId and Name='Test Cart Item1'];
        List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper> lstCartItemWrap = new List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>();
        PMC_DH_RequestForQuoteWrapper.CartItemWrapper cartItemWrap = new PMC_DH_RequestForQuoteWrapper.CartItemWrapper();
        cartItemWrap.strCartItemId = cartItems.id;
        cartItemWrap.strQuantity = PMC_DH_ConstantClass.PRODUCT_QUANTITY;
        cartItemWrap.strShipTo = cartItems.PMC_DH_ShipTo__c;
        cartItemWrap.strIncoterms =cartItems.PMC_DH_Incoterms__c;
        cartItemWrap.strDeliveryMode =cartItems.PMC_DH_DeliveryMode__c;
        cartItemWrap.strShipFrom =cartItems.PMC_DH_PlantShipFrom__c;
        cartItemWrap.strSource ='RTD';
        cartItemWrap.strProductId = cartItems.Product2Id;
        cartItemWrap.strProductName = cartItems.Product2.Name;
        lstCartItemWrap.add(cartItemWrap);
        PMC_DH_ContractDetailController.CartItemWrapper objCrtItemWrp = new PMC_DH_ContractDetailController.CartItemWrapper();
        objCrtItemWrp.strCartId = strCartId;
        objCrtItemWrp.strCurrency = 'USD';
        objCrtItemWrp.strContractId = cartItems.PMC_DH_Contract__c;
        
        String strInput = JSON.serialize(lstCartItemWrap);
        system.runAs(user){
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result=PMC_DH_ContractDetailController.addCartItem(objCrtItemWrp, strInput);
            system.assert(result!=null,'success');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for addCartItems
* @param: none
* @return: void
* @author Rohan
*/  
    @isTest
    public static void addCartItemsExceptionTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        
        CartItem cartItems =[select id,Product2.Name,Product2Id,Product2.StockKeepingUnit, PMC_DH_ShipTo__c, PMC_DH_PlantShipFrom__c, PMC_DH_DeliveryMode__c, PMC_DH_Incoterms__c, Type, CartDeliveryGroupId, Quantity, PMC_DH_Contract__c from CartItem where cartid=:strCartId and Name='Test Cart Item1'];
        List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper> lstCartItemWrap = new List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>();
        PMC_DH_RequestForQuoteWrapper.CartItemWrapper cartItemWrap = new PMC_DH_RequestForQuoteWrapper.CartItemWrapper();
        cartItemWrap.strCartItemId = cartItems.id;
        cartItemWrap.strQuantity = PMC_DH_ConstantClass.PRODUCT_QUANTITY;
        cartItemWrap.strShipTo = cartItems.PMC_DH_ShipTo__c;
        cartItemWrap.strIncoterms =cartItems.PMC_DH_Incoterms__c;
        cartItemWrap.strDeliveryMode =cartItems.PMC_DH_DeliveryMode__c;
        cartItemWrap.strShipFrom =cartItems.PMC_DH_PlantShipFrom__c;
        cartItemWrap.strSource ='RTD';
        cartItemWrap.strProductId = cartItems.Product2Id;
        cartItemWrap.strProductName = cartItems.Product2.Name;
        lstCartItemWrap.add(cartItemWrap);
        PMC_DH_ContractDetailController.CartItemWrapper objCrtItemWrp = new PMC_DH_ContractDetailController.CartItemWrapper();
        objCrtItemWrp.strCartId = strCartId;
        objCrtItemWrp.strCurrency = 'USD';
        objCrtItemWrp.strContractId = cartItems.PMC_DH_Contract__c;
        
        String strInput = JSON.serialize(lstCartItemWrap);
        system.runAs(user){
            Boolean exceptionOccurred;
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result=new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
            try{
                PMC_DH_DigitalHubB2BUtils.throwTestException = true;
                result=PMC_DH_ContractDetailController.addCartItem(objCrtItemWrp, strInput);
            }catch(Exception ex){
                exceptionOccurred = true;
            }
            System.assertEquals(result.strStatusCode,'100','success');
        }
        Test.stopTest();
        
    }
    
    /**
* @description Test Method for addShipToMap
* @param: none
* @return: void
* @author Rohan
*/  
    @isTest
    public static void addShipToMapFromContractTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Contract objCont=[SELECT ID, (SELECT Id, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.PMC_DH_Account_Status__c, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.PMC_SS_MDMVerified__c FROM SBQQ__Subscriptions__r) FROM Contract WHERE SBQQ__Quote__r.PMC_CPQ_QuoteShortNameDescription__c = 'TestDH Quote'][0];
            Account shipToAcc = [SELECT Id, AccountNumber, PMC_DH_Account_Status__c, PMC_SS_MDMVerified__c FROM Account WHERE AccountNumber='Test00123' LIMIT 1];
            shipToAcc.PMC_DH_Account_Status__c = 'Active';
            shipToAcc.PMC_SS_MDMVerified__c = TRUE;
            update shipToAcc;
            List<SBQQ__Subscription__c> lstSub = new List<SBQQ__Subscription__c>();
            for(SBQQ__Subscription__c objSubs : objCont.SBQQ__Subscriptions__r){
                objSubs.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__c = shipToAcc.Id;
                lstSub.add(objSubs);
            }
            update lstSub;
            
            Map<String,List<PMC_DH_PicklistWrapper>> result = PMC_DH_ContractDetailController.addShipToMap(objCont);
            system.assert(result!=null,'success');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for addShipToMap
* @param: none
* @return: void
* @author Rohan
*/  
    @isTest
    public static void addShipToMapTest()
    {
        Map<String,List<PMC_DH_PicklistWrapper>> mapShipTo = new Map<String,List<PMC_DH_PicklistWrapper>>();
        String sku = 'SKU0001';
        Test.startTest();
        Map<String,List<PMC_DH_PicklistWrapper>> result = PMC_DH_ContractDetailController.addShipToMap(mapShipTo, sku);
        system.assert(result!=null,'success');
        Test.stopTest();
    }
    
    /**
* @description Test Method for retriveShipmentInfoFromCartItem
* @param: none
* @return: void
* @author Nikhilesh
*/  
    @isTest
    public static void retriveShipmentInfoFromCartItemTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        
        CartItem objCartItem =[select id,Product2.Name,Product2Id,Product2.StockKeepingUnit, PMC_DH_ShipTo__c, PMC_DH_NotaFiscalNumber__c,  PMC_DH_DeliveryInstructions__c,
                               PMC_DH_PlantShipFrom__c, PMC_DH_DeliveryMode__c, PMC_DH_Incoterms__c, Type,  PMC_DH_NotaFiscalDate__c, PMC_DH_SellOutPrice__c,
                               CartDeliveryGroupId, Quantity, PMC_DH_Contract__c, PMC_DH_RequestedShipmentDate__c FROM CartItem 
                               where cartid=:strCartId and Name='Test Cart Item1'];
        List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper> lstCartItemWrap = new List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper>();
        PMC_DH_RequestToDeliverWrapper.CartItemWrapper cartItemWrap = new PMC_DH_RequestToDeliverWrapper.CartItemWrapper();
        cartItemWrap.intFiscalNumber = Integer.valueof(objCartItem.PMC_DH_NotaFiscalNumber__c);
        cartItemWrap.datNotaFiscalDate = objCartItem.PMC_DH_NotaFiscalDate__c;
        cartItemWrap.decSellOutPrice = objCartItem.PMC_DH_SellOutPrice__c;
        cartItemWrap.strDeliveryInstructions=objCartItem.PMC_DH_DeliveryInstructions__c;  
        cartItemWrap.strCartItemId = objCartItem.id;
        cartItemWrap.strShipTo = objCartItem.PMC_DH_ShipTo__c;
        cartItemWrap.strdeliveryMode = objCartItem.PMC_DH_DeliveryMode__c;
        cartItemWrap.strIncoterms = objCartItem.PMC_DH_Incoterms__c;
        cartItemWrap.strShipFrom = objCartItem.PMC_DH_PlantShipFrom__c;
        cartItemWrap.intQuantity = objCartItem.Quantity != null?objCartItem.Quantity.longValue():0;// GDASF-10697
        cartItemWrap.datRequestedShipmentDate = objCartItem.PMC_DH_RequestedShipmentDate__c;
        cartItemWrap.strSource = 'RTD';
        
        PMC_DH_RequestToDeliverWrapper.CartItemWrapper cartItemWrap2 = new PMC_DH_RequestToDeliverWrapper.CartItemWrapper();
        cartItemWrap2.intFiscalNumber = Integer.valueof(objCartItem.PMC_DH_NotaFiscalNumber__c);
        cartItemWrap2.datNotaFiscalDate = objCartItem.PMC_DH_NotaFiscalDate__c;
        cartItemWrap2.decSellOutPrice = objCartItem.PMC_DH_SellOutPrice__c;
        cartItemWrap2.strDeliveryInstructions=objCartItem.PMC_DH_DeliveryInstructions__c;  
        cartItemWrap2.strCartItemId = objCartItem.id;
        cartItemWrap2.strShipTo = objCartItem.PMC_DH_ShipTo__c;
        cartItemWrap2.strdeliveryMode = objCartItem.PMC_DH_DeliveryMode__c;
        cartItemWrap2.strIncoterms = objCartItem.PMC_DH_Incoterms__c;
        cartItemWrap2.strShipFrom = objCartItem.PMC_DH_PlantShipFrom__c;
        cartItemWrap2.intQuantity = objCartItem.Quantity != null?objCartItem.Quantity.longValue():0;// GDASF-10697
        cartItemWrap2.datRequestedShipmentDate = objCartItem.PMC_DH_RequestedShipmentDate__c;
        cartItemWrap2.strSource = 'RTD';
        lstCartItemWrap.add(cartItemWrap); 
        lstCartItemWrap.add(cartItemWrap2); 
        
        Map<String,List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper>> mapSkuToWrapper = new Map<String,List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper>>();
        mapSkuToWrapper.put(objCartItem.Product2.StockKeepingUnit,lstCartItemWrap);
        Map<String,List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper>> result= PMC_DH_ContractDetailController.retriveShipmentInfoFromCartItem(mapSkuToWrapper);
        system.assert(result!=null,'success');
        Test.stopTest();
    }
}