/**
* @description : Test class for PMC_DH_ContractUtil
* @author      : Rohan Undale
* @userStory   : GDASF-142 & GDASF-8927 
* @last modified by Rohan Undale
* @last modified on 06-29-2023
**/
@isTest
public with sharing class PMC_DH_ContractUtilTest {
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
            Test.startTest();
            Account shipToAcc=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
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
            PMC_DH_TestDataFactoryClass.createSubscription(objCartItem);
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
        
        CartItem cartItems =[select id,Product2.Name,Product2Id,Product2.StockKeepingUnit, PMC_DH_ShipTo__c, PMC_DH_PlantShipFrom__c, PMC_DH_DeliveryMode__c, PMC_DH_Incoterms__c, Type, CartDeliveryGroupId, Quantity from CartItem where cartid=:strCartId and Name='Test Cart Item1'];
        List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper> lstCartItemWrap = new List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper>();
        PMC_DH_RequestToDeliverWrapper.CartItemWrapper cartItemWrap = new PMC_DH_RequestToDeliverWrapper.CartItemWrapper();
        cartItemWrap.strCartItemId = cartItems.id;
        cartItemWrap.intQuantity = integer.valueOf(PMC_DH_ConstantClass.PRODUCT_QUANTITY);
        cartItemWrap.strShipTo = cartItems.PMC_DH_ShipTo__c;
        cartItemWrap.strIncoterms =cartItems.PMC_DH_Incoterms__c;
        cartItemWrap.strDeliveryMode =cartItems.PMC_DH_DeliveryMode__c;
        cartItemWrap.strShipFrom =cartItems.PMC_DH_PlantShipFrom__c;
        cartItemWrap.strSource ='RTD';
        lstCartItemWrap.add(cartItemWrap);
        
        List<PMC_DH_RequestToDeliverWrapper.CartWrapper> lstCartWrapper = new List<PMC_DH_RequestToDeliverWrapper.CartWrapper>();
        PMC_DH_RequestToDeliverWrapper.CartWrapper objCartWrapper = new PMC_DH_RequestToDeliverWrapper.CartWrapper();
        objCartWrapper.lstCartItems = lstCartItemWrap;
        objCartWrapper.strProductId = cartItems.Product2Id;
        objCartWrapper.strProductName = cartItems.Product2.Name;
        lstCartWrapper.add(objCartWrapper);
        system.runAs(user){
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result=PMC_DH_ContractUtil.addCartItems(strCartId, lstCartWrapper);
            PMC_DH_ContractUtil.isNumericOrDecimal('20.00');
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
        
        CartItem cartItems =[select id,Product2.Name,Product2Id,Product2.StockKeepingUnit, PMC_DH_ShipTo__c, PMC_DH_PlantShipFrom__c, PMC_DH_DeliveryMode__c, PMC_DH_Incoterms__c, Type, CartDeliveryGroupId, Quantity from CartItem where cartid=:strCartId and Name='Test Cart Item1'];
        List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper> lstCartItemWrap = new List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper>();
        PMC_DH_RequestToDeliverWrapper.CartItemWrapper cartItemWrap = new PMC_DH_RequestToDeliverWrapper.CartItemWrapper();
        cartItemWrap.strCartItemId = cartItems.id;
        cartItemWrap.intQuantity = integer.valueOf(PMC_DH_ConstantClass.PRODUCT_QUANTITY);
        cartItemWrap.strShipTo = cartItems.PMC_DH_ShipTo__c;
        cartItemWrap.strIncoterms =cartItems.PMC_DH_Incoterms__c;
        cartItemWrap.strDeliveryMode =cartItems.PMC_DH_DeliveryMode__c;
        cartItemWrap.strShipFrom =cartItems.PMC_DH_PlantShipFrom__c;
        cartItemWrap.strSource ='RTD';
        lstCartItemWrap.add(cartItemWrap);
        
        List<PMC_DH_RequestToDeliverWrapper.CartWrapper> lstCartWrapper = new List<PMC_DH_RequestToDeliverWrapper.CartWrapper>();
        PMC_DH_RequestToDeliverWrapper.CartWrapper objCartWrapper = new PMC_DH_RequestToDeliverWrapper.CartWrapper();
        objCartWrapper.lstCartItems = lstCartItemWrap;
        objCartWrapper.strProductId = cartItems.Product2Id;
        objCartWrapper.strProductName = cartItems.Product2.Name;
        lstCartWrapper.add(objCartWrapper);
        system.runAs(user){
            Boolean exceptionOccurred;
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result=new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
            try{
                PMC_DH_DigitalHubB2BUtils.throwTestException = true;
                result=PMC_DH_ContractUtil.addCartItems(strCartId, lstCartWrapper);
            }catch(Exception ex){
                exceptionOccurred = true;
            }
            System.assertEquals(result.strStatusCode,'100','success');
        }
        Test.stopTest();
        
    }
    
    /**
* @description Test Method for contract summary
* @param: none
* @return: void
* @author Ajeet 
*/  
    @isTest
    public static void getContractSummaryTest(){
        User usr=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Account acc = PMC_DH_TestDataFactoryClass.createTestAccount();
        acc.PMC_SS_SAPCustomerNumber__c='12343434';
        update acc;
        Contact con = PMC_DH_TestDataFactoryClass.createContact(acc.Id);
           
            Opportunity opp = PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            SBQQ__Quote__c quot = PMC_DH_TestDataFactoryClass.createQuote(acc,con.Id,opp);
            Product2 prod1 = [Select id from Product2 where StockKeepingUnit='1234' limit 1];
            SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(quot,prod1);
            Test.startTest();
            Contract cont1 = PMC_DH_TestDataFactoryClass.createContract(quot.Id,acc.Id);
            cont1.Status='Activated';
            SBQQ__Subscription__c sub1 = [Select Id, SBQQ__Contract__c from SBQQ__Subscription__c Limit 1];
            sub1.SBQQ__Contract__c = cont1.Id;
            sub1.SBQQ__QuoteLine__c = testQuoteLine.Id;
            update sub1;
            update cont1;
            Test.stopTest();
            System.runAs(usr){
                PMC_DH_RequestToDeliverWrapper.ContractSummaryWrapper contResult = PMC_DH_ContractUtil.getContractSummary(cont1.Id);
                System.assert(contResult!=null, 'Success');
            }
    }

       /**
* @description Test Method for contract summary for amendment
* @param: none
* @return: void
*/  
@isTest
public static void getContractSummaryTest2(){
    User usr=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
    Account acc = PMC_DH_TestDataFactoryClass.createTestAccount();
    acc.PMC_SS_SAPCustomerNumber__c='12343434';
    update acc;
    Contact con = PMC_DH_TestDataFactoryClass.createContact(acc.Id);
       
        Opportunity opp = PMC_DH_TestDataFactoryClass.createOpportunity(acc);
        SBQQ__Quote__c quot = PMC_DH_TestDataFactoryClass.createQuote(acc,con.Id,opp);
        quot.SBQQ__Type__c  = 'Amendment';
        update quot;

        Product2 prod1 = [Select id from Product2 where StockKeepingUnit='1234' limit 1];
        SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(quot,prod1);
        Test.startTest();
        Contract cont1 = PMC_DH_TestDataFactoryClass.createContract(quot.Id,acc.Id);
        cont1.PMC_CPQ_LatestQuote__c=quot.Id;
        cont1.Status='Activated';
        SBQQ__Subscription__c sub1 = [Select Id, SBQQ__Contract__c from SBQQ__Subscription__c Limit 1];
        sub1.SBQQ__Contract__c = cont1.Id;
        sub1.SBQQ__QuoteLine__c = testQuoteLine.Id;
        update sub1;
        update cont1;
        Test.stopTest();
        System.runAs(usr){
            PMC_DH_RequestToDeliverWrapper.ContractSummaryWrapper contResult = PMC_DH_ContractUtil.getContractSummary(cont1.Id);
            System.assert(contResult!=null, 'Success');
        }
}



    

}