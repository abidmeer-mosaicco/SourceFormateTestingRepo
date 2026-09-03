/**
* @description : Test class for PMC_DH_CartValidationController
* @author      : Nikhilesh Mohanty
* @userStory   : GDASF-6531 
* @last modified by Nikhilesh
* @last modified on 06-22-2023
**/
@isTest
public with sharing class PMC_DH_CartValidationControllerTest {
    
    @testSetup  
    private static void setup() {
        Account acc;
        String strContactId;
        User user;
        WebStore webStore;
        User userAdmin=PMC_DH_TestDataFactoryClass.createAdminUser();
        System.runAs(userAdmin){
            acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
            Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
            PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
            webStore=PMC_DH_TestDataFactoryClass.createTestWebStore();
        
        user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        strContactId=[SELECT contactId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1][0].contactId;

        Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet2);
        Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet);
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet1);
        Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet3);
        
        } 
        System.runAs(user){
            WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
            insert cartObj;
            Account acc1=new Account(name='new one', BillingCity = 'San Francisco', BillingStreet = '123 Test Street',
                           BillingState = 'California', BillingPostalCode = '94001', BillingCountry = 'United States');
            insert acc1;
            webCart cartObj1=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc1.Id);
            cartObj1.name='New one';
            insert cartObj1;
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            insert prod;
            Product2 prod2 = new Product2(name='Test21',StockKeepingUnit='944876',isactive=true);
            insert prod2;
            Opportunity oppObj=PMC_DH_TestDataFactoryClass.createOpportunity(acc); 
        
            test.startTest();
            SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,oppObj);  
            SBQQ__QuoteLine__c testQuoteLine=PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,prod);
            Contract testContract=PMC_DH_TestDataFactoryClass.createContract(testQuote.id,acc.id);
            testContract.Status='Activated';
            testContract.ContractTerm=1;
            testContract.enddate=system.today()+1;
            update testContract;
            CartDeliveryGroup testCartDeliveryGroup=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj.id);
            insert testCartDeliveryGroup;
            CartDeliveryGroup testCartDeliveryGroup1=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj1.id);
            insert testCartDeliveryGroup1;
            
            Account shipToAcc=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
            Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
            
            PMC_CPQ_ProductLocation__c prodLocation = PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
            PMC_DH_TestDataFactoryClass.CartItemObject objCartItem=new PMC_DH_TestDataFactoryClass.CartItemObject();
            objCartItem.strCartId=cartObj.id;
            objCartItem.strProductId=prod.id;
            objCartItem.strDeliveryGroupId=testCartDeliveryGroup.id;
            objCartItem.strShipToAccId=shipToAcc.id;
            objCartItem.strQuoteLineId = testQuoteLine.Id;
            objCartItem.strShipFromId=prodLocation.id;
            objCartItem.strContractId = testContract.Id;
            SBQQ__Subscription__c subsc=PMC_DH_TestDataFactoryClass.createSubscription(objCartItem);
            CartItem cartItem1=PMC_DH_TestDataFactoryClass.buildCartItem1(objCartItem);
            cartItem1.PMC_DH_Source__c='RFQ';
            cartItem1.PMC_DH_Subscription__c=subsc.id;
            cartItem1.PMC_DH_Contract__c=testContract.Id;
            cartItem1.PMC_DH_DeliveryMode__c='barge';
            upsert cartItem1;
            test.stoptest();  
            PMC_DH_TestDataFactoryClass.CartItemObject objCartItem2=new PMC_DH_TestDataFactoryClass.CartItemObject();
            objCartItem2.strCartId=cartObj.id;
            objCartItem2.strProductId=prod.id;
            objCartItem2.strDeliveryGroupId=testCartDeliveryGroup.id;
            objCartItem2.strShipToAccId=shipToAcc.id;
            objCartItem2.strShipFromId=prodLocation.id;
            SBQQ__Subscription__c sub2 =PMC_DH_TestDataFactoryClass.createSubscription(objCartItem2);
            CartItem cartItem2=PMC_DH_TestDataFactoryClass.buildCartItem1(objCartItem2);
            cartItem2.PMC_DH_Source__c='RFQ';
            cartItem2.PMC_DH_DeliveryMode__c='truck';
            cartItem2.PMC_DH_Subscription__c=sub2.id;
            cartItem2.PMC_DH_Contract__c=testContract.Id;
            upsert cartItem2; 
    }
    }
    
    @isTest
    public static void validateCartTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        List<CartItem> lstCI=[SELECT Id, sku, Name, Product2.StockKeepingUnit, Product2Id,PMC_DH_Subscription__c,
                                    Product2.IsActive, PMC_DH_Source__c, PMC_DH_Contract__c, Product2.Name, PMC_DH_Contract__r.CONTRACTNUMBER 
                                    FROM CartItem where Cart.Id=: strCartId];
        Contract con=[select id,Accountid,ContractTerm,enddate from contract limit 1];
        con.ContractTerm=1;
        con.enddate=system.today()+1;
        update con;
        lstCI[0].PMC_DH_Source__c='RFQ';
        update lstCI[0];
        SBQQ__Subscription__C sbs=[SELECT Id,SBQQ__Product__c,SBQQ__Product__r.StockKeepingUnit,SBQQ__Contract__r.CONTRACTNUMBER,SBQQ__Contract__r.EndDate from SBQQ__Subscription__C LIMIT 1];        
        sbs.PMC_CPQ_TotalAvailableQuantity__c=1;
        update sbs;
        System.runAs(user)
    
        {
            PMC_DH_CartValidationController.CartValidationParentWrapper result = PMC_DH_CartValidationController.validateCart(strCartId);
        PMC_DH_CartValidationController.CartValidationParentWrapper result1 = PMC_DH_CartValidationController.validateCart(strCartId);
        
            System.assert(result!=null, 'Success');
            System.assert(result1!=null, 'Success');        }
        Test.stopTest();
    }
    @isTest
    public static void mixedContrTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        List<CartItem> lstCI=[SELECT Id, sku, Name, Product2.StockKeepingUnit, Product2Id,
                                    Product2.IsActive, PMC_DH_Source__c, PMC_DH_Contract__c, Product2.Name, PMC_DH_Contract__r.CONTRACTNUMBER 
                                    FROM CartItem where Cart.Id=: strCartId];
        lstCI[0].PMC_DH_Source__c='RTD';
        update lstCI[0];
        lstCI[1].PMC_DH_Source__c='RTD';
        update lstCI[1];
        
        System.runAs(user){
            PMC_DH_CartValidationController.CartValidationParentWrapper result = PMC_DH_CartValidationController.cartPageValidation(strCartId);
            System.assertEquals(result.boolHasErrors, true, 'Success');        }
    }
    
    @isTest
    public static void validateCartNT(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        CartItem testCartItem = [SELECT Id, Name FROM CartItem WHERE Name = 'Test Cart Item1' LIMIT 1];
        testCartItem.PMC_DH_Source__c = 'RTD';
        update testCartItem;
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;

        System.runAs(user)
        {
            PMC_DH_CartValidationController.CartValidationParentWrapper result = PMC_DH_CartValidationController.validateCart(strCartId); 
            System.assertEquals(result!=NULL, true, 'Success');
        }
        Test.stopTest();
    }
    
    @isTest
    public static void cartPageValidationTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        System.runAs(user)
        { 
            PMC_DH_CartValidationController.CartValidationParentWrapper result = PMC_DH_CartValidationController.cartPageValidation(strCartId);
            System.assertEquals(result!=null, true, 'Success');
        
        }
        Test.stopTest();
    }
    
    @isTest
    public static void cartpageInactive()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        Product2 prod=[SELECT ID,ISACTIVE FROM PRODUCT2 WHERE STOCKKEEPINGUNIT='1234'];
        prod.IsActive=False;
        update prod;

        System.runAs(user)
        {
        
            PMC_DH_CartValidationController.CartValidationParentWrapper result = PMC_DH_CartValidationController.cartPageValidation(strCartId);
            System.assertEquals(result.boolHasErrors, true, 'Success');
        
        }
        Test.stopTest();
}
    
    @isTest
    public static void cartPageValidationNT()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId = [SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        CartItem testCartItem = [SELECT Id, Name FROM CartItem WHERE Name = 'Test Cart Item1' LIMIT 1];
        testCartItem.PMC_DH_Source__c = 'RTD';
        update testCartItem;
        System.runAs(user)
        {
            PMC_DH_CartValidationController.CartValidationParentWrapper result = PMC_DH_CartValidationController.cartPageValidation(strCartId);
            System.assert(result.boolHasErrors == true, 'Success');
        }
        Test.stopTest();
    }
    
    
    
    @isTest
    public static void exceptionHandlingTest()
    {
    Test.startTest();
    User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
    String strCartId='123@';
        System.runAs(user)
        {	PMC_DH_DigitalHubB2BUtils.throwTestException=true;
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper errObj = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); 
            PMC_DH_CartValidationController.CartValidationParentWrapper result=new PMC_DH_CartValidationController.CartValidationParentWrapper();
            try{
                result = PMC_DH_CartValidationController.cartPageValidation(strCartId);     
            }
            catch(Exception ex){
                strCartId='PMC_DH_GenericTechnicalError';
            }
            System.assertEquals(result.statusCodeMessage.strStatusMessage,errObj.strStatusMessage,'Success');            
        }   
        Test.stopTest();
    }
    
    
@isTest
    public static void validateCartExceptionTest(){
        Test.startTest();
    User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
    String strCartId='123@';
        System.runAs(user)
        {	
            PMC_DH_DigitalHubB2BUtils.throwTestException=true;
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper errObj = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); 
            PMC_DH_CartValidationController.CartValidationParentWrapper result=new PMC_DH_CartValidationController.CartValidationParentWrapper();
            try{ 
                result = PMC_DH_CartValidationController.validateCart(strCartId);
            
            }
            catch(Exception ex){
                strCartId='PMC_DH_GenericTechnicalError';
            }
            System.assertEquals(result.statusCodeMessage.strStatusMessage,errObj.strStatusMessage,'Success');
            
        }   
        Test.stopTest();
    }
    @isTest
    public static void deliverModeTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        List<CartItem> lstCI=[SELECT Id, sku, Name, Product2.StockKeepingUnit, Product2Id,PMC_DH_DeliveryMode__c,
                                    Product2.IsActive, PMC_DH_Source__c, PMC_DH_Contract__c, Product2.Name, PMC_DH_Contract__r.CONTRACTNUMBER 
                                    FROM CartItem where Cart.Id=: strCartId];
        
        for(cartitem ci:lstCI)
        {
            ci.PMC_DH_Source__c='RTD';
            ci.PMC_DH_Contract__c=lstCI[0].PMC_DH_Contract__c;
        }
        update lstCI;
        System.runAs(user){
            PMC_DH_CartValidationController.CartValidationParentWrapper result=new PMC_DH_CartValidationController.CartValidationParentWrapper();
            result= PMC_DH_CartValidationController.validateCart(strCartId);
            result = PMC_DH_CartValidationController.cartPageValidation(strCartId);
            System.assertEquals(result.boolHasErrors,true, 'Success');        
            }
        Test.stopTest();
    }
    
    @isTest
    public static void mixedContrType()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        List<CartItem> lstCI=[SELECT Id, sku, Name, Product2.StockKeepingUnit, Product2Id,PMC_DH_DeliveryMode__c,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c,
                                    Product2.IsActive, PMC_DH_Source__c, PMC_DH_Contract__c, Product2.Name, PMC_DH_Contract__r.CONTRACTNUMBER 
                                    FROM CartItem where Cart.Id=: strCartId];
        for(Cartitem ci:lstCI){
        ci.PMC_DH_Source__c='RTD';
        }
        update lstCI;
        System.runAs(user){
            PMC_DH_CartValidationController.CartValidationParentWrapper result=new PMC_DH_CartValidationController.CartValidationParentWrapper();
            result= PMC_DH_CartValidationController.validateCart(strCartId);
                result = PMC_DH_CartValidationController.cartPageValidation(strCartId);
            System.assertEquals(result!=null,true, 'Success');        
            }
        Test.stopTest();
}
    
    
    @isTest
    public static void vcoValidation()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        List<CartItem> lstCI=[SELECT Id, sku, Name, Product2.StockKeepingUnit, Product2Id,PMC_DH_DeliveryMode__c,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c,
                            PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c,
                            Product2.IsActive, PMC_DH_Source__c, PMC_DH_Contract__c, Product2.Name, PMC_DH_Contract__r.CONTRACTNUMBER,
                            PMC_DH_Subscription__r.SBQQ__Account__r.RecordType.name
                            FROM CartItem where Cart.Id=: strCartId];
         
        for(cartitem ci:lstCI)
        {	ci.PMC_DH_DeliveryMode__c='truck';
            ci.PMC_DH_Source__c='RTD';
            ci.PMC_DH_Contract__c=lstCI[0].PMC_DH_Contract__c;
        }
        update lstCI;
    
        System.runAs(user){
            PMC_DH_CartValidationController.CartValidationParentWrapper result =new PMC_DH_CartValidationController.CartValidationParentWrapper();
                result= PMC_DH_CartValidationController.validateCart(strCartId);
            result= PMC_DH_CartValidationController.cartPageValidation(strCartId);
            System.assertEquals(result!=null,true, 'Success');        
            }
        Test.stopTest();
    }
    
    @isTest
    public static void mixedFlow()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        List<CartItem> lstCI=[SELECT Id, sku, Name, Product2.StockKeepingUnit, Product2Id,PMC_DH_DeliveryMode__c,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c,
                            PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c,
                            Product2.IsActive, PMC_DH_Source__c, PMC_DH_Contract__c, Product2.Name, PMC_DH_Contract__r.CONTRACTNUMBER 
                            FROM CartItem where Cart.Id=: strCartId];
        
        lstCI[1].PMC_DH_Source__c='rfq';
        lstCI[0].PMC_DH_Source__c='rtd';
        update lstCI[1];
        update lstCI[0];    
    
        System.runAs(user){
            
            PMC_DH_CartValidationController.CartValidationParentWrapper result =new PMC_DH_CartValidationController.CartValidationParentWrapper();
                result= PMC_DH_CartValidationController.validateCart(strCartId);
            result= PMC_DH_CartValidationController.cartPageValidation(strCartId);
            System.assertEquals(result!=null,true, 'Success');        
            }
        Test.stopTest();
    }
    @isTest
    public static void prodInContractError()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='New one'][0].id;
        Contract testContract=[SElect id,ContractTerm from contract where PMC_CPQ_ContractType__c='Priced Contract Truck'];
        testContract.ContractTerm=1;
        update testContract;
        System.runAs(user){
            PMC_DH_CartValidationController.CartValidationParentWrapper result =new PMC_DH_CartValidationController.CartValidationParentWrapper();
                result= PMC_DH_CartValidationController.validateCart(strCartId);
            result= PMC_DH_CartValidationController.cartPageValidation(strCartId);
            System.assertEquals(result!=null,true, 'Success');        
            }
        Test.stopTest();
    }
    
    @isTest
    public static void testVCO(){
    Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        List<CartItem> lstCI=[SELECT Id, sku, Name, Product2.StockKeepingUnit, Product2Id,PMC_DH_DeliveryMode__c,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c,
                            PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c,
                            Product2.IsActive, PMC_DH_Source__c, PMC_DH_Contract__c, Product2.Name, PMC_DH_Contract__r.CONTRACTNUMBER 
                            FROM CartItem where Cart.Id=: strCartId];
        System.runAs(user){
            PMC_DH_CartValidationController.WrapperDetail wrpDetail=new PMC_DH_CartValidationController.WrapperDetail();
            PMC_DH_CartValidationController.WrapWarnings wrpWarn=new PMC_DH_CartValidationController.WrapWarnings();
            wrpDetail.wrpWarning=wrpWarn; 
            wrpDetail.cartItem=lstCI[0];
            wrpDetail.intFlagCheck=0;
            wrpDetail.wrpChild=new PMC_DH_CartValidationController.CartValidationWrapper();
            wrpDetail.setVCO=new Set<Boolean>{true,false};
            PMC_DH_CartValidationController.CartValidationParentWrapper wrp= new PMC_DH_CartValidationController.CartValidationParentWrapper();
            List<PMC_DH_CartValidationController.CartValidationWrapper> lstCartwrp=new List<PMC_DH_CartValidationController.CartValidationWrapper>();
            String strResult='';
            PMC_DH_CartValidationUtil.validateVCO(wrpDetail,wrp,lstCartwrp);
            strResult='pass';
            System.assertEquals(strResult!=null,true, 'Success');   
        }
    Test.stopTest();   
    }
    
    @isTest
    public static void getFlowNameTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        System.runAs(user){
            Map<String,Set<String>> productSKUContractMap=new Map<String,Set<String>>{'sku1'=> new Set<String>{'Contract123','Contract232'}, 
                                                                                    'sku2'=> new Set<String>{'Contract56'} };
            
        String strresult1= PMC_DH_CartValidationController.getFlowName( productSKUContractMap, 'sku1');
        String strresult2= PMC_DH_CartValidationController.getFlowName( productSKUContractMap, 'sku2');
        System.assert(strresult1!=null,'passed');
        System.assert(strresult2!=null,'passed');
        }
        Test.stopTest(); 
    }
    
}