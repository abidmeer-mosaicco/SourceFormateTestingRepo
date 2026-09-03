/**
* @description       : Test Class for Quote Management Helper class
* @author            : Rohan Undale | rravindraundale@deloitte.com
* @group             : Mosaic Direct
* @last modified on  : 03-25-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class PMC_DH_QuoteManagementHelperTest {
     
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
            Account shipToAcc=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);  
            shipToAcc.PMC_SS_MDMVerified__c = TRUE;
            shipToAcc.PMC_DH_Account_Status__c='Active';
            update shipToAcc;
            PMC_SS_SalesArea__c testSalesArea = new PMC_SS_SalesArea__c();
            testSalesArea.PMC_SS_SalesOrganization__c = 'Mosaic Global Sales LLC';
            testSalesArea.PMC_SS_DistributionChannel__c = '0';
            testSalesArea.PMC_SS_Division__c = '10';
            insert testSalesArea;
            List<Account> lstAccounts = new List<Account>();
            lstAccounts.add(acc);
            List<PMC_SS_SalesArea__c> lstSalesAreas = new List<PMC_SS_SalesArea__c>();
            lstSalesAreas.add(testSalesArea);
            PMC_SS_AccountSalesAreaRelationship__c relObj = new PMC_SS_AccountSalesAreaRelationship__c(PMC_SS_Account__c = acc.Id, PMC_SS_SalesArea__c = testSalesArea.Id);
            insert relObj;
            PMC_SS_AccountPartnerRelationships__c accPartnrRel = PMC_DH_TestDataFactoryClass.createSoldToShipToAccountJunction(shipToAcc.Id, acc.Id);
            accPartnrRel.PMC_SS_RelatedAccountSalesArea__c = relObj.Id;
            update accPartnrRel;
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            insert prod;
            Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
            testQuote.SBQQ__Status__c='Accepted';
            WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
            insert cartObj;
            CartDeliveryGroup testCartDeliveryGroup=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj.id);
            insert testCartDeliveryGroup;
            CartItem cartItem=PMC_DH_TestDataFactoryClass.buildCartItem(cartObj.id, prod.id,testCartDeliveryGroup.Id);
            cartItem.Quantity = 5;
            cartItem.TotalLineAmount = 5100;
            insert cartItem;  
            test.startTest();
            Map<String, String> result;
            result = PMC_DH_QuoteManagementHelper.getShipToIdSoldToShipToJunctionIdMap(accPartnrRel.id); 
            System.assert(result!=null, 'Success');
            test.stopTest();
       }
        
    }
    
    /*
* @description Test Method for createQuoteFromCartHelper method
* @param         cartId
* @param         objQuote
* @param         objWebCart
* @return       : Map<String, String>
*/
    @isTest
    public static void createQuoteFromCartHelperTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        WebCart cartObj=[select id ,AccountId from WebCart where  Name= 'Test Web Cart' limit 1];
        Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
        Account strTestAcct1=[SELECT id FROM Account WHERE Name='Ship To Account123' limit 1][0];
        PMC_SS_AccountPartnerRelationships__c soldToShipToAccount;   
        if(!String.isBlank(strTestAcct1.Id)) 
            {
            List<PMC_SS_SalesArea__c> lstSalesArea = [SELECT Id FROM PMC_SS_SalesArea__c WITH SECURITY_ENFORCED LIMIT 1];
            PMC_SS_AccountSalesAreaRelationship__c relObj = new PMC_SS_AccountSalesAreaRelationship__c(PMC_SS_Account__c = strTestAcct.Id, PMC_SS_SalesArea__c = lstSalesArea[0].Id);
            insert relObj;
        List<PMC_SS_AccountPartnerRelationships__c> existingRelationships = [
            SELECT Id 
            FROM PMC_SS_AccountPartnerRelationships__c 
            WHERE PMC_SS_Account__c = :strTestAcct.Id 
            AND PMC_SS_RelatedAccount__c = :strTestAcct1.Id 
            AND PMC_SS_Type__c = :PMC_DH_ConstantClass.ACCOUNT_TYPE 
            WITH SECURITY_ENFORCED 
            LIMIT 1
        ];
           
            if (!existingRelationships.isEmpty()) {
            soldToShipToAccount = existingRelationships[0];
        } else {
            soldToShipToAccount = new PMC_SS_AccountPartnerRelationships__c();
            soldToShipToAccount.PMC_SS_Account__c = strTestAcct.Id; 
            soldToShipToAccount.PMC_SS_RelatedAccount__c = strTestAcct1.Id;
            soldToShipToAccount.CurrencyIsoCode = 'USD'; 
            soldToShipToAccount.PMC_SS_Type__c = PMC_DH_ConstantClass.ACCOUNT_TYPE; 
            soldToShipToAccount.PMC_SS_RelatedAccountSalesArea__c = relObj.Id; 
            insert soldToShipToAccount; 
            }
            }
        SBQQ__Quote__c testQuote = [SELECT Id ,PMC_CPQ_SalesArea__c ,PMC_CPQ_QuoteRecordSubType__c FROM SBQQ__Quote__c WHERE PMC_DH_QuoteFriendlyName__c = 'Test Quote' LIMIT 1];
        List<SBQQ__QuoteLine__c> result;
        System.runAs(user){
            result = PMC_DH_QuoteManagementHelper.createQuoteFromCartHelper(cartObj.id,testQuote,cartObj);      
        }
        System.assert(result!=null, 'Success');
        Test.stopTest();
    }
    /**
* @description Test Method for getMapProductDetail method
* @param: none
* @return: void
* @author Rohan Undale
*/
    @isTest
    public static void getMapProductDetailTest(){
        Test.startTest();
        List<ConnectApi.ProductOverview> lstProducts = new List<ConnectApi.ProductOverview>();
        ConnectApi.ProductOverview prdOvrview = New ConnectApi.ProductOverview();
        prdOvrview.sku = 'TestSKU';
        prdOvrview.success = true;
        lstProducts.add(prdOvrview);
        List<String> skus = new List<String>();
        skus.add('TestSKU');
        Map<String , PMC_DH_RequestForQuoteController.ConnectApiWrapper> mapProductDetail = new Map<String , PMC_DH_RequestForQuoteController.ConnectApiWrapper>();
        Boolean isException = false;
        try{
            PMC_DH_QuoteManagementHelper.getMapProductDetail(lstProducts, skus, mapProductDetail);
        }catch(Exception ex){
            isException = true;
        }
        system.Assert(isException, 'Success');
        Test.stopTest();
    }
    
    /**
* @description Test Method for getInactiveProductDetails method
* @param: none
* @return: void
* @author Rohan Undale
*/
    @isTest
    public static void getInactiveProductDetailsTest(){
        Test.startTest();
        Product2 prod=[select id,name,StockKeepingUnit,PMC_CPQ_ProductFamily__c, PMC_CPQ_QuantityUnitOfMeasure__c,PMC_CPQ_PackType__c from Product2];
        List<Product2> lstInactiveProducts = new List<Product2>();
        lstInactiveProducts.add(prod);
        Map<String , PMC_DH_RequestForQuoteController.ConnectApiWrapper> mapProductDetail = new Map<String , PMC_DH_RequestForQuoteController.ConnectApiWrapper>();
        
        Map<String , PMC_DH_RequestForQuoteController.ConnectApiWrapper> result = PMC_DH_QuoteManagementHelper.getInactiveProductDetails(mapProductDetail, lstInactiveProducts);
        system.Assert(result!=null, 'Success');
        
        Test.stopTest();
    } 
    /**
* @description Test Method for getContractsForQuote method
* @param: objQuote
* @return: List<PMC_DH_QuoteDetailsWrapper.ContractsWrapper>
* @author Rohan Undale
*/
    @isTest
    public static void getContractsForQuoteTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        
        SBQQ__Quote__c objQuote=[select id,PMC_CLM_DocumentNumber__c,SBQQ__Status__c,PMC_CPQ_ContractStageName__c from SBQQ__Quote__c limit 1];
        objQuote.SBQQ__Status__c='Accepted';
        objQuote.PMC_CPQ_ContractStageName__c='Pending Signature';
        update objQuote;
        List<PMC_DH_QuoteDetailsWrapper.ContractsWrapper> result;
        System.runAs(user){
            result = PMC_DH_QuoteManagementHelper.getContractsForQuote(objQuote);      
        }
        System.assert(result!=null, 'Success');
        Test.stopTest();
    }
    /**
* @description Test Method for getUnitOfMeasureForQuoteLine method
* @param: cartItemWrap
* @param: strUserCountry
* @return: String
*/
    @isTest
    public static void getUnitOfMeasureForQuoteLineTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        PMC_DH_RequestForQuoteWrapper.CartItemWrapper cartItemWrap = new PMC_DH_RequestForQuoteWrapper.CartItemWrapper();
        
        string result;
        System.runAs(user){
            result = PMC_DH_QuoteManagementHelper.getUnitOfMeasureForQuoteLine(cartItemWrap,'Brazil');      
        }
        System.assert(result!=null, 'Success');
        Test.stopTest();
    }
    @isTest
    public static void productUnitOfMeasureListTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        List<PMC_DH_PicklistWrapper> result;
        System.runAs(user){
            result =PMC_DH_QuoteManagementHelper.getProductUnitOfMeasureList();
             }
        System.assert(result!=null, 'Success');
        Test.stopTest();
    }
    @isTest
    public static void getPackagingTypeListTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        List<PMC_DH_PicklistWrapper> result;
        System.runAs(user){
             result =PMC_DH_QuoteManagementHelper.getPackagingTypeList();
           }
        System.assert(result!=null, 'Success');
        Test.stopTest();
    }
    @isTest
    public static void getPackTypeListTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        List<PMC_DH_PicklistWrapper> result;
        System.runAs(user){
             result =PMC_DH_QuoteManagementHelper.getPackTypeList();
           }
        System.assert(result!=null, 'Success');
        Test.stopTest();
    }
    @isTest
    public static void getPackTypeForQuoteTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        List<PMC_DH_PicklistWrapper> result;
        System.runAs(user){
     result =PMC_DH_QuoteManagementHelper.getPackTypeForQuote();
        }
        System.assert(result!=null, 'Success');
        Test.stopTest();
    }
   
   
    /**
* @description Test Method for updateQuoteLineProdInfo method
* @param: strUOM
* @param: lstLineItemsIds
* @return: PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*/
    @isTest
    public static void updateQuoteLineProdInfoTest(){
        Test.startTest();
        list<SBQQ__QuoteLine__c> quoteLines=[select id,PMC_CPQ_UnitofMeasure__c from SBQQ__QuoteLine__c ];
        list<string> lstIds= new List<string>();
        for(SBQQ__QuoteLine__c qc :quoteLines){
            lstIds.add(qc.id);
        }
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result;
           User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
     
        System.runAs(user){
            result =PMC_DH_QuoteManagementHelper.updateQuoteLineProdInfo('MTN',lstIds);
            Test.stopTest();
        } 
        system.Assert(result!=null, 'Success');
        
    }   


@IsTest
    public static void testGetPackTypeForQuote(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        List<PMC_DH_PicklistWrapper> result;
        System.runAs(user){
     result =PMC_DH_QuoteManagementHelper.getPackTypeForQuote();
        }
        System.assert(result!=null, 'Success');
        Test.stopTest();
    }
}