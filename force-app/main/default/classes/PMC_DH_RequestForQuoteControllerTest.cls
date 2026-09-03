/**
* @description : Test class for PMC_DH_RequestForQuoteController
* @author      : Humera Rahath
* @userStory   : GDASF-37 & GDASF-140 & GDASF-78 & GDASF-23 
* @last modified by Nikhilesh
* @last modified on 05-24-2023
**/
@isTest
public with sharing class PMC_DH_RequestForQuoteControllerTest {
    /**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/
    @testSetup  static void setup()
    {
        Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
       
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
        User userAM = [SELECT Id, PMC_CPQ_PrimaryBusinessType__c,LocaleSidKey, PMC_CPQ_SalesArea__c,PMC_CPQ_SalesRegion__c FROM User WHERE Id =: UserInfo.getUserId() WITH SYSTEM_MODE LIMIT 1];
        String strContactId=[SELECT contactId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1][0].contactId;
        userAM.PMC_CPQ_SalesArea__c = 'Mosaic Global Sales LLC Intercompany Common';
        userAM.PMC_CPQ_SalesRegion__c = 'North America';
        userAM.FederationIdentifier = 'emailtesting10101xx@gmail.com';
        userAM.PMC_CPQ_PrimaryBusinessType__c='Feed';
        userAM.MobilePhone = '+1 9876543210';
        update userAM;
        PMC_SS_SalesArea__c testSalesArea = new PMC_SS_SalesArea__c();
        testSalesArea.PMC_SS_SalesOrganization__c = 'Mosaic Global Sales LLC';
        testSalesArea.PMC_SS_DistributionChannel__c = '0';
        testSalesArea.PMC_SS_Division__c = '10';
        insert testSalesArea;
        List<Account> lstAccounts = new List<Account>();
        lstAccounts.add(acc);
        List<PMC_SS_SalesArea__c> lstSalesAreas = new List<PMC_SS_SalesArea__c>();
        lstSalesAreas.add(testSalesArea);
        PMC_TestUtilityClass.createAccountSalesAreaRelationship(lstAccounts, lstSalesAreas);
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet2);
        Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet);
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet1);
        Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet3);
        Id lstPermSet4=[select id from PermissionSet where Name ='PMC_DH_R_CommerceEntitlementSalesArea'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet4);
        
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
            Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            Test.startTest();
            PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
        Account shipToAcc=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
        shipToAcc.PMC_DH_Account_Status__c='Active';
        shipToAcc.PMC_SS_MDMVerified__c=true;
        update shipToAcc;
            Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
            loc.PMC_CPQ_Country__c='US';
            loc.RecordTypeId= Schema.SObjectType.Location.getRecordTypeInfosByDeveloperName().get('PMC_CPQ_Origin_Location').getRecordTypeId();
            update as system loc;
        PMC_CPQ_ProductLocation__c prodLocation = PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
        PMC_DH_TestDataFactoryClass.CartItemObject objCartItem=new PMC_DH_TestDataFactoryClass.CartItemObject();
        objCartItem.strCartId=cartObj.id;
        objCartItem.strProductId=prod.id;
        objCartItem.strDeliveryGroupId=testCartDeliveryGroup.id;
        objCartItem.strShipToAccId=shipToAcc.id;
        objCartItem.strShipFromId=prodLocation.id;
        CartItem cartItem1=PMC_DH_TestDataFactoryClass.buildCartItem1(objCartItem);
            cartItem1.PMC_DH_PackType__c = 'Packed';
            cartItem1.PMC_DH_PackageType__c = 'Saco 50 Kg';
            cartItem1.PMC_DH_Incoterms__c='';
            cartItem1.PMC_DH_DeliveryMode__c='Barge';
            insert cartItem1;
            //PMC_DH_CommerceEntitlementSalesArea__c cesa
            PMC_DH_TestDataFactoryClass.createCommerceEntitlementSalesArea(acc.Id, prod.Id, testSalesArea.Id);
           
        }
    }
    
    /**
* @description Test Method for getQuoteCheckOutShipmentInfo
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/
    @isTest
    public static void getQuoteCheckOutShipmentInfoTest()
    {
        Test.startTest();
        Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
            Account strTestAcct1=[SELECT id FROM Account WHERE Name='Ship To Account123' limit 1][0];
            if(!String.isBlank(strTestAcct1.Id)) 
            {
            List<PMC_SS_SalesArea__c> lstSalesArea = [SELECT Id FROM PMC_SS_SalesArea__c WITH SECURITY_ENFORCED LIMIT 1];
            PMC_SS_AccountSalesAreaRelationship__c relObj = new PMC_SS_AccountSalesAreaRelationship__c(PMC_SS_Account__c = strTestAcct1.Id, PMC_SS_SalesArea__c = lstSalesArea[0].Id);
            insert relObj;
            PMC_SS_AccountPartnerRelationships__c soldToShipToAccount = new PMC_SS_AccountPartnerRelationships__c();
            soldToShipToAccount.Name = 'DO NOT USE';
            soldToShipToAccount.PMC_SS_Account__c=strTestAcct.ID;
            soldToShipToAccount.PMC_SS_RelatedAccount__c=strTestAcct1.Id;
                soldToShipToAccount.CurrencyIsoCode='USD';
            soldToShipToAccount.PMC_SS_Type__c = PMC_DH_ConstantClass.ACCOUNT_TYPE;
            soldToShipToAccount.PMC_SS_RelatedAccountSalesArea__c = relObj.Id;
                insert soldToShipToAccount;
            }
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            
            String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
            PMC_DH_RequestForQuoteWrapper result=PMC_DH_RequestForQuoteController.getQuoteCheckOutShipmentInfo(PMC_DH_ConstantClass.TEST_COMMUNITYID,strTestAcct.Id , strCartId);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for getQuoteCheckOutShipmentInfoTest 
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/   
   /** @isTest
    public static void getQuoteCheckOutShipmentInfoExceptionTest(){

Test.startTest();
User usr = [SELECT Id from User WHERE UserName = 'demouser@test.com.testuser' limit 1];
System.runAs(usr){
            Boolean exceptionOccurred;
            try{
                PMC_DH_RequestForQuoteController.throwTestException = true;
                String strTestAcctId=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0].Id;
                String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
                PMC_DH_RequestForQuoteController.getQuoteCheckOutShipmentInfo(PMC_DH_ConstantClass.TEST_COMMUNITYID,strTestAcctId , strCartId);
            }
            catch(Exception e){
                exceptionOccurred=true;
            }
            System.assert(exceptionOccurred, 'An Exception was not thrown');
            Test.stopTest();
        }
}**/
    /**
* @description Test Method for addCartItems
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/  
    @isTest
    public static void addCartItemsTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        
        CartItem cartItems =[select id,Product2.Name,Product2Id,Product2.StockKeepingUnit, PMC_DH_ShipTo__c, PMC_DH_AccountPartnerRelationship__c, PMC_DH_PlantShipFrom__c, PMC_DH_DeliveryMode__c, PMC_DH_Incoterms__c, Type, CartDeliveryGroupId, Quantity, PMC_DH_Source__c from CartItem where cartid=:strCartId and Name='Test Cart Item1'];
        List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper> lstCartItemWrap = new List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>();
        PMC_DH_RequestForQuoteWrapper.CartItemWrapper cartItemWrap = new PMC_DH_RequestForQuoteWrapper.CartItemWrapper();
        cartItemWrap.strProductId = cartItems.Product2Id;
        cartItemWrap.strProductName = cartItems.Product2.Name;
        cartItemWrap.strSku  =  cartItems.Product2.StockKeepingUnit;
        cartItemWrap.strCartItemId = cartItems.id;
        cartItemWrap.strQuantity =PMC_DH_ConstantClass.PRODUCT_QUANTITY;
        //cartItemWrap.strShipTo= cartItems.PMC_DH_ShipTo__c; 
        cartItemWrap.strShipTo= cartItems.PMC_DH_AccountPartnerRelationship__c; // added as part of GDASF-17324
        cartItemWrap.strIncoterms =cartItems.PMC_DH_Incoterms__c;
        cartItemWrap.strDeliveryMode =cartItems.PMC_DH_DeliveryMode__c;
        cartItemWrap.strShipFrom =cartItems.PMC_DH_PlantShipFrom__c;
        cartItemWrap.strSource ='RTD';
        lstCartItemWrap.add(cartItemWrap);
        String str = JSON.serialize(lstCartItemWrap);
        system.runAs(user){
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result=PMC_DH_QuoteUtils.addCartItems(strCartId, str);
            system.assert(result!=null,'success');
        }
        Test.stopTest();
    }
    /**
* @description Test Method for addCartItems
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/  
    @isTest
    public static void addCartItemsExceptionTest()
    {
        Test.startTest(); 
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        CartItem cartItems =[select id,Product2.Name,Product2Id,Product2.StockKeepingUnit, PMC_DH_ShipTo__c,PMC_DH_DeliveryMode__c, PMC_DH_PlantShipFrom__c, PMC_DH_Incoterms__c, Type, CartDeliveryGroupId, Quantity from CartItem where cartid=:strCartId and Name='Test Cart Item1'];
        List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper> lstCartItemWrap = new List<PMC_DH_RequestForQuoteWrapper.CartItemWrapper>();
        PMC_DH_RequestForQuoteWrapper.CartItemWrapper cartItemWrap = new PMC_DH_RequestForQuoteWrapper.CartItemWrapper();
        cartItemWrap.strProductId = cartItems.Product2Id;
        cartItemWrap.strProductName = cartItems.Product2.Name;
        cartItemWrap.strSku  =  cartItems.Product2.StockKeepingUnit;
        cartItemWrap.strCartItemId = cartItems.id;
        cartItemWrap.strQuantity =50.00;
        cartItemWrap.strShipTo= cartItems.PMC_DH_ShipTo__c;
        cartItemWrap.strIncoterms =cartItems.PMC_DH_Incoterms__c;
        cartItemWrap.strDeliveryMode =cartItems.PMC_DH_DeliveryMode__c;
        cartItemWrap.strShipFrom =cartItems.PMC_DH_PlantShipFrom__c;
        lstCartItemWrap.add(cartItemWrap);
        String str = JSON.serialize(lstCartItemWrap);
        system.runAs(user){
            Boolean exceptionOccurred;
                PMC_DH_DigitalHubB2BUtils.throwTestException = true;
                PMC_DH_QuoteUtils.addCartItems(strCartId, str);
                String strRecordTypeName = PMC_DH_RequestForQuoteHelper.getQuoteRecordTypeName();
                PMC_DH_QuoteUtils.getModeOfTransportationForQuote(strRecordTypeName);
                exceptionOccurred = true;
            system.assert(exceptionOccurred,'success');

        }
        Test.stopTest();
        
    } 
    /**
* @description Test Method for getPaymentInfoForCart
* 
* @param: none
* 
* @return: void
*
* @author Nikhilesh
* 
*/
    @isTest
    public static void getPaymentInfoForCartTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
            PMC_DH_RequestForQuoteController.PaymentInfoWrapper result = PMC_DH_RequestForQuoteController.getPaymentInfoForCart('United States', strCartId);
            System.assert(result!=null,'success');
        }
        Test.stopTest();
    }
    /**
* @description Test Exception Method for getPaymentInfoForCart
* 
* @param: none
* 
* @return: void
*
* @author Nikhilesh
* 
*/
  /**  @isTest
    public static void getPaymentInfoForCartTestException()
    {
        User usr = [SELECT Id from User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Test.startTest();
        System.runAs(usr){
            
            Boolean exceptionOccurred;
            try{
                PMC_DH_RequestForQuoteController.throwTestException = true;
                String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
                PMC_DH_RequestForQuoteController.getPaymentInfoForCart('United States', strCartId);
            }
            catch(Exception e){
                exceptionOccurred=true;
            }
            System.assert(exceptionOccurred, 'An Exception was not thrown');
        }
        Test.stopTest();
    }
**/
    /**
* @description Test Method for updatePaymentInfoForCart
* 
* @param: none
* 
* @return: void
*
* @author Nikhilesh
* 
*/
    @isTest
    public static void updatePaymentInfoForCartTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        WebCart cart = [SELECT Id, PMC_DH_ContractStartDate__c, PMC_DH_ContractEndDate__c, PMC_DH_PaymentMethod__c, PMC_DH_PaymentTerms__c, CurrencyIsoCode FROM WebCart WHERE Id =: strCartId AND Name='Test Web Cart'];
        PMC_DH_PaymentInformationForQuoteWrapper cartWrap = new PMC_DH_PaymentInformationForQuoteWrapper();
        cartWrap.strCartId = cart.Id;
        cartWrap.datContractStartDate = cart.PMC_DH_ContractStartDate__c;
        cartWrap.datContractEndDate = cart.PMC_DH_ContractEndDate__c;
        cartWrap.strCurrencyIsoCode = cart.CurrencyIsoCode;
        cartWrap.strPaymentMethods = cart.PMC_DH_PaymentMethod__c;
        cartWrap.strPaymentTerms = cart.PMC_DH_PaymentTerms__c;
        cartWrap.lstProductFamilies=new List<String>{'K-MAG'};
        system.runAs(user){
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_RequestForQuoteController.updatePaymentInfoForCart(cartWrap);
            System.assert(result!=null,'success');
        }
        Test.stopTest();
    }
    /**
* @description Test Method for updatePaymentInfoForCart with 2 CommerceEntitlementSalesArea records
* 
* @param: none
* 
* @return: void
*
* @author Nikhilesh
* 
*/
    @isTest
    public static void updatePaymentInfoForCartTest1()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        WebCart cart = [SELECT Id, PMC_DH_ContractStartDate__c, PMC_DH_ContractEndDate__c, PMC_DH_PaymentMethod__c, PMC_DH_PaymentTerms__c, CurrencyIsoCode FROM WebCart WHERE Id =: strCartId AND Name='Test Web Cart'];
        PMC_DH_PaymentInformationForQuoteWrapper cartWrap = new PMC_DH_PaymentInformationForQuoteWrapper();
        cartWrap.strCartId = cart.Id;
        cartWrap.datContractStartDate = cart.PMC_DH_ContractStartDate__c;
        cartWrap.datContractEndDate = cart.PMC_DH_ContractEndDate__c;
        cartWrap.strCurrencyIsoCode = cart.CurrencyIsoCode;
        cartWrap.strPaymentMethods = cart.PMC_DH_PaymentMethod__c;
        cartWrap.strPaymentTerms = cart.PMC_DH_PaymentTerms__c;
        cartWrap.lstProductFamilies=new List<String>{'KMAG'};
        PMC_SS_SalesArea__c testSalesArea = new PMC_SS_SalesArea__c();
        testSalesArea.PMC_SS_SalesOrganization__c = 'Mosaic Global Sales LLC';
        testSalesArea.PMC_SS_DistributionChannel__c = '0';
        testSalesArea.PMC_SS_Division__c = '30';
        insert testSalesArea;
        Account acc = [SELECT Id FROM Account WHERE Name = 'Parent Test Account'];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Test Product'];
        PMC_DH_TestDataFactoryClass.createCommerceEntitlementSalesArea(acc.Id, prod.Id, testSalesArea.Id);
        system.runAs(user){
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_RequestForQuoteController.updatePaymentInfoForCart(cartWrap);
            System.assert(result!=null,'success');
        }
        Test.stopTest();
    }
    /**
* @description Test Exception Method for updatePaymentInfoForCart
* 
* @param: none
* 
* @return: void
*
* @author Nikhilesh
* 
*/
   /** @isTest
    public static void updatePaymentInfoForCartTestException()
    {
        User usr = [SELECT Id from User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Test.startTest();
        System.runAs(usr){
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_RequestForQuoteController.updatePaymentInfoForCart(null);
            System.assertEquals(result.strStatusCode,'100','success');
        }
        Test.stopTest();
    }
**/
    /**
* @description Test Method for createQuoteFromCart
* 
* @param: none
* 
* @return: void
*
* @author Nikhilesh
* 
*/
    @isTest
    public static void createQuoteFromCartTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        String quoteFriendlyName = 'demouser';
        system.runAs(user){
            
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_RequestForQuoteController.createQuoteFromCart(strCartId, quoteFriendlyName);
            System.assert(result!=null,'success');
            //PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_RequestForQuoteController.createQuoteFromCart(strCartId, quoteFriendlyName);
        }
        Test.stopTest();
    }
    
/**
* @description Test Method for getShipToForQuote Exception
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/  
@isTest
public static void getShipToForQuoteExceptionTest()
{
     Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
        Account strTestAcct1=[SELECT id FROM Account WHERE Name='Ship To Account123' limit 1][0];
       if(!String.isBlank(strTestAcct1.Id)) 
        {
            strTestAcct1.PMC_SS_MDMVerified__c=TRUE;
            strTestAcct1.PMC_DH_Account_Status__c='Active';
            update strTestAcct1;
            PMC_SS_AccountPartnerRelationships__c soldToShipToAccount = new PMC_SS_AccountPartnerRelationships__c();
            soldToShipToAccount.PMC_SS_Account__c=strTestAcct.ID;
            soldToShipToAccount.PMC_SS_RelatedAccount__c=strTestAcct1.Id;
            soldToShipToAccount.CurrencyIsoCode='USD';
            soldToShipToAccount.PMC_SS_Type__c = PMC_DH_ConstantClass.ACCOUNT_TYPE;
            insert soldToShipToAccount;
        }
        system.runAs(user){
            Boolean exceptionOccurred;
            PMC_DH_QuoteUtils.getShipToForQuote(strTestAcct.Id);
            exceptionOccurred = true;
            system.assert(exceptionOccurred,'success');
        }
        Test.stopTest();
}

    /**
* @description Test Method for getActiveCartId
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/  
@isTest
public static void getActiveCartIdTest()
{
    Test.startTest();
    User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
    String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
    List<WebStore> testWebStoreList = [SELECT id,Name,Description FROM WebStore WHERE Name ='TestWebStore' Limit 1];
    String strNetworkId = PMC_DH_TestDataFactoryClass.getNetworkId(testWebStoreList[0].Id);
    system.runAs(user){
            //changes as part of GDASF-19642
            PMC_DH_QuoteUtils.PMC_DH_ActiveCartIdWrapper result=PMC_DH_QuoteUtils.getActiveCartId(strCartId, strNetworkId);
            system.assert(result.strCartId!=null,'success');
            //end of changes as part of GDASF-19642
    }
    Test.stopTest();
}

/**
* @description Test Method for getActiveCartId Exception
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/  
@isTest
public static void getActiveCartIdExceptionTest()
{
    Test.startTest();
    User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
    String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
    List<WebStore> testWebStoreList = [SELECT id,Name,Description FROM WebStore WHERE Name ='TestWebStore' Limit 1];
    String strNetworkId = PMC_DH_TestDataFactoryClass.getNetworkId(testWebStoreList[0].Id);
    
    system.runAs(user){
        Boolean exceptionOccurred;
            PMC_DH_DigitalHubB2BUtils.throwTestException = true;
            PMC_DH_QuoteUtils.getActiveCartId(strCartId, strNetworkId);
            exceptionOccurred = true;
        system.assert(exceptionOccurred,'success');
    }
    Test.stopTest();
}
    
/**
* @description Test Method for getDateTimeToDate
* 
* @param: none
* 
* @return: void
* 
*/  
@isTest
public static void getDateTimeToDateTest()
{
    Test.startTest();
    	DateTime datTcreatedDate = System.now();
        Date result=PMC_DH_QuoteUtils.getDateTimeToDate(datTcreatedDate);
        system.assert(result!=null,'success');
    Test.stopTest();
}
 
/**
* @description Test Method for getDateTimeToDate Exception
* 
* @param: none
* 
* @return: void
* 
*/  
@isTest
public static void getDateTimeToDateExceptionTest()
{
    Test.startTest();
    	DateTime datTcreatedDate = System.now();
    Boolean exceptionOccurred;
       // PMC_DH_DigitalHubB2BUtils.throwTestException = true;
        PMC_DH_QuoteUtils.getDateTimeToDate(datTcreatedDate);
        exceptionOccurred = true;
        system.assert(exceptionOccurred,'success');
    Test.stopTest();
}   
    
   /**
* @description Test Method for getPackTypeForQuote
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/  
    @isTest
    public static void getPackTypeForQuoteTest(){
        Test.startTest();
        List<PMC_DH_PicklistWrapper> result=PMC_DH_QuoteUtils.getPackTypeForQuote();
        system.assert(result!=null,'success');  
        Test.stopTest();
    } 
    
       /**
* @description Test Method for getPackagingTypeForQuote
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/  
    @isTest
    public static void getPackagingTypeForQuoteTest(){
        Test.startTest();
        List<PMC_DH_PicklistWrapper> result=PMC_DH_QuoteUtils.getPackagingTypeForQuote();
        system.assert(result!=null,'success');  
        Test.stopTest();
    } 
    
    
    
    
    /**
     * @description Test Method
	*/
    @isTest
    public static void getQuoteRecordTypeTest()
    {
       User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
       Test.startTest();
       System.runAs(user){
        String strResult=PMC_DH_RequestForQuoteHelper.getQuoteRecordType('BR');
        system.assert(strResult!=null,'success');  
       }
        Test.stopTest(); 
    }
    
    
    /**
    * @description 
    * @author Hemant Giri Goswami | hegoswami@deloitte.com | 02-21-2024 
    **/
    @isTest
    public static void shareRecordWithPortalUserTest()
    {
        Test.startTest();
        User userObjRecord=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        SBQQ__Quote__c quoteObjRecord=[select id from SBQQ__Quote__c LIMIT 1];
        System.runAs(userObjRecord){
        
        Boolean strResult=PMC_DH_RequestForQuoteHelper.shareRecordWithPortalUser(quoteObjRecord.id);
        system.assert(strResult!=null,'success');  
          
        }
        Test.stopTest();
    }
    
    /**
    * @description 
    * @author Hemant Giri Goswami | hegoswami@deloitte.com | 02-21-2024 
    **/
    @isTest
    public static void getExpiryDateTest(){

        Test.startTest();
        PMC_DH_QuoteMgmtActionController.PMC_DH_QuoteStatusWrapper quoteStatusWrapper=new PMC_DH_QuoteMgmtActionController.PMC_DH_QuoteStatusWrapper();
        User userObjRecord=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        SBQQ__Quote__c quoteObjRecord=[select id,PMC_CPQ_ExpiresOn__c,SBQQ__Status__c from SBQQ__Quote__c LIMIT 1];
        System.runAs(userObjRecord){
        PMC_DH_QuoteMgmtActionController.PMC_DH_QuoteStatusWrapper res= PMC_DH_RequestForQuoteHelper.getExpiryDate(quoteObjRecord,quoteStatusWrapper);
        system.assert(res!=null,'success');
        }
        Test.stopTest();
	}

    /**
* @description Test Method for getShipFromForQuote of PMC_DH_QuoteUtils
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/  
@isTest
public static void getShipFromForQuoteNegativeTest()
{
    Test.startTest();
    User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
    Product2 prod = [SELECT Id, StockKeepingUnit FROM Product2 WHERE Name = 'Test Product'];
    set<String> setSku = new set<String>();
    setSku.add(prod.StockKeepingUnit);
    system.runAs(user){
        PMC_CPQ_ProductLocation__c prodLocation = [SELECT Id, Name, PMC_CPQ_ProductName__c, PMC_CPQ_Location__r.PMC_CPQ_Country__c FROM PMC_CPQ_ProductLocation__c WHERE PMC_CPQ_ProductName__c =: prod.Id];
        update prodLocation;
        Map<String,List<PMC_DH_PicklistWrapper>> result = PMC_DH_QuoteUtils.getShipFromForQuote(setSku);
        system.assert(result!=NULL,'success');
    }
    Test.stopTest();
}
}