/**
* @description : Test class for PMC_DH_TestDataFactoryClass
* @author      : Sugunakar Routhu
* @modified by : Ajeet
* @Created on   06/29/2023
**/
@isTest
public with sharing class PMC_DH_TestDataFactoryClassTest {
    
    @isTest
    private static void webStoreTest(){
        Test.startTest();
        Webstore testWebStore = PMC_DH_TestDataFactoryClass.createTestWebStore();
        String netWorkId=PMC_DH_TestDataFactoryClass.getNetworkId(testWebStore.Id);
        PMC_DH_TestDataFactoryClass.getWebStoreId(netWorkId);
        System.assertEquals('TestWebStore', testWebStore.Name, 'Incorrect');
        Test.stopTest();
    }
    
    @isTest
    private static void commerceEntitlemntData(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.BUYER_PERSONA LIMIT 1];
        
        Account parentAcc = PMC_DH_TestDataFactoryClass.createParentTestAccount();
        PMC_DH_TestDataFactoryClass.createTestUser(parentAcc.Id,profile.Id);
        user usr = [Select id,contactId,accountId,Contact.FirstName, Contact.LastName from User where Username='demouser@test.com.testuser'];
        
        Product2 pro=PMC_DH_TestDataFactoryClass.createProduct();
        insert pro;
        
        BuyerAccount bAcc = new BuyerAccount();
        bAcc.BuyerId=parentAcc.Id;
        bAcc.Name=parentAcc.Name;
        bAcc.PMC_DH_isBuyerProcessed__c=false;
        bAcc.BuyerStatus='Active';
        bAcc.IsActive = TRUE;
        insert bAcc;
        
        
        PMC_DH_TestDataFactoryClass.createEntitlementRules(parentAcc.Id, pro.Id);
        CommerceEntitlementPolicy testCommerceEntPolicy = PMC_DH_TestDataFactoryClass.createEntitlementPolicy();
        BuyerGroup testBuyerGroup = PMC_DH_TestDataFactoryClass.createBuyerGroup();
        PMC_DH_TestDataFactoryClass.createBuyerGroupMember(parentAcc.Id, testBuyerGroup.Id);
        PMC_DH_TestDataFactoryClass.createCommerceEntitlementBuyerGroup(testCommerceEntPolicy.Id, testBuyerGroup.Id);
        PMC_DH_TestDataFactoryClass.createCommerceEntitlementProduct(testCommerceEntPolicy.Id, pro.Id);
        PMC_DH_TestDataFactoryClass.createIndividual(usr);
        
        System.assertEquals(bAcc.BuyerId, parentAcc.Id, 'Incorrect');
    }
    
    @isTest
    private static void commerceDataTest(){
        
        BusinessHours bh=[SELECT name,id from BusinessHours where name='Default' limit 1];
        Webstore testWebStore = PMC_DH_TestDataFactoryClass.createTestWebStore();
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.BUYER_PERSONA LIMIT 1];
        Account parentAcc = PMC_DH_TestDataFactoryClass.createParentTestAccount();
        
        Account shipToAccount = PMC_DH_TestDataFactoryClass.createShipToTestAccount(parentAcc);
        PMC_DH_TestDataFactoryClass.createTestUser(parentAcc.Id,profile.Id);
        user usr = [Select id,contactId,accountId,Contact.FirstName, Contact.LastName from User where Username='demouser@test.com.testuser'];
        PMC_DH_TestDataFactoryClass.createContact(parentAcc.Id);
        PMC_DH_TestDataFactoryClass.createOpportunity(parentAcc);
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(usr.Id,lstPermSet1);
        Contact con = PMC_DH_TestDataFactoryClass.createTestContact(parentAcc.Id);
        
        List<Product2> proList = new List<Product2>();
        Product2 pro=PMC_DH_TestDataFactoryClass.createProduct();
        proList.add(pro);
        
        insert proList;
        Schema.Location scLoc=PMC_DH_TestDataFactoryClass.createLocation();
        
        PMC_CPQ_ProductLocation__c proloc=PMC_DH_TestDataFactoryClass.createProductLocation(proList[0], scLoc);
        WebCart cart=PMC_DH_TestDataFactoryClass.buildCart(testWebStore.Id, parentAcc.Id);
        insert cart;
        CartDeliveryGroup cartDgroup=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cart.Id);
        PMC_DH_TestDataFactoryClass.buildCartItem(cart.Id,proList[0].id, cartDgroup.Id);
        PMC_DH_TestDataFactoryClass.CartItemObject cartObj = new PMC_DH_TestDataFactoryClass.CartItemObject();
        cartObj.strCartId=cart.Id;
        cartObj.strProductId=proList[0].Id;
        cartObj.strDeliveryGroupId=cartDgroup.Id;
        cartObj.strShipToAccId=shipToAccount.Id;
        cartObj.strShipFromId=proloc.Id;
        CartItem ci = PMC_DH_TestDataFactoryClass.buildCartItem1(cartObj); 
        Case testCase = PMC_DH_TestDataFactoryClass.createCaseRecord(parentAcc.Id,con.Id, bh.Id);
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'testdocument.txt',
            VersionData = Blob.valueOf('Test Content Data')
        );
        insert cv;
        Id cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        insert new ContentDocumentLink(
            LinkedEntityId = testCase.Id,
            ContentDocumentId = cdId,
            ShareType = 'V'
        );
        PMC_DH_TestDataFactoryClass.createTestAccountTeamMember(parentAcc.Id, Userinfo.getUserId(), PMC_DH_ConstantClass.ACCOUNT_TEAMMEMBERSSR);
        Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(parentAcc);
        Test.startTest();
        SBQQ__Quote__c testQuote = PMC_DH_TestDataFactoryClass.createQuote(parentAcc,con.Id,opp);
        SBQQ__QuoteLine__c line1= PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote, proList[0]);
        PMC_DH_TestDataFactoryClass.createCadence(line1);
        Contract testContract = PMC_DH_TestDataFactoryClass.createContract(testQuote.Id, parentAcc.Id);
        PMC_DH_TestDataFactoryClass.createSubscription(cartObj);
        Order testOrder = PMC_DH_TestDataFactoryClass.createOrder(parentAcc, testContract, cart.Id);
        PMC_DH_TestDataFactoryClass.creatOrderLine(testOrder, ci);
        PMC_DH_TestDataFactoryClass.createShipment(testOrder);
        Test.stopTest();
        
        List<PMC_SS_SalesArea__c> lstSalesAreas= PMC_TestUtilityClass.createSalesArea(2, '');
        PMC_DH_TestDataFactoryClass.createCommerceEntitlementSalesArea(parentAcc.Id, proList[0].Id, lstSalesAreas[0].Id);        
        System.assertEquals('Ship To Account123', shipToAccount.Name, 'Incorrect');
        
        
    }
    
    
    
    @isTest
    private static void commerceDataTest2(){
        
        BusinessHours bh=[SELECT name,id from BusinessHours where name='Default' limit 1];
        Webstore testWebStore = PMC_DH_TestDataFactoryClass.createTestWebStore();
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.BUYER_PERSONA LIMIT 1];
        Account parentAcc = PMC_DH_TestDataFactoryClass.createParentTestAccount();
        Account shipToAccount = PMC_DH_TestDataFactoryClass.createShipToTestAccount(parentAcc);
        PMC_DH_TestDataFactoryClass.createTestUser(parentAcc.Id,profile.Id);
        user usr = [Select id,contactId,accountId,Contact.FirstName, Contact.LastName from User where Username='demouser@test.com.testuser'];
        PMC_DH_TestDataFactoryClass.createContact(parentAcc.Id);
        PMC_DH_TestDataFactoryClass.createOpportunity(parentAcc);
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(usr.Id,lstPermSet1);
        Contact con = PMC_DH_TestDataFactoryClass.createTestContact(parentAcc.Id);
        
        List<Product2> proList = new List<Product2>();
        Product2 pro=PMC_DH_TestDataFactoryClass.createProduct();
        proList.add(pro);
        Product2 pro1=PMC_DH_TestDataFactoryClass.createProduct();
        pro1.Name='Test Product1';
        pro1.ProductCode='GH-12345';
        pro1.StockKeepingUnit='12345';
        proList.add(pro1);
        insert proList;
        Schema.Location scLoc=PMC_DH_TestDataFactoryClass.createLocation();
        
        PMC_CPQ_ProductLocation__c proloc=PMC_DH_TestDataFactoryClass.createProductLocation(proList[0], scLoc);
        WebCart cart=PMC_DH_TestDataFactoryClass.buildCart(testWebStore.Id, parentAcc.Id);
        insert cart;
        CartDeliveryGroup cartDgroup=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cart.Id);
        PMC_DH_TestDataFactoryClass.buildCartItem(cart.Id,proList[0].id, cartDgroup.Id);
        PMC_DH_TestDataFactoryClass.CartItemObject cartObj = new PMC_DH_TestDataFactoryClass.CartItemObject();
        cartObj.strCartId=cart.Id;
        cartObj.strProductId=proList[0].Id;
        cartObj.strDeliveryGroupId=cartDgroup.Id;
        cartObj.strShipToAccId=shipToAccount.Id;
        cartObj.strShipFromId=proloc.Id;
        CartItem ci = PMC_DH_TestDataFactoryClass.buildCartItem1(cartObj); 
        Case testCase = PMC_DH_TestDataFactoryClass.createCaseRecord(parentAcc.Id,con.Id, bh.Id);
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'testdocument.txt',
            VersionData = Blob.valueOf('Test Content Data')
        );
        insert cv;
        Id cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        insert new ContentDocumentLink(
            LinkedEntityId = testCase.Id,
            ContentDocumentId = cdId,
            ShareType = 'V'
        );
        PMC_DH_TestDataFactoryClass.createTestAccountTeamMember(parentAcc.Id, Userinfo.getUserId(), PMC_DH_ConstantClass.ACCOUNT_TEAMMEMBERSSR);
        Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(parentAcc);
        Test.startTest();
        SBQQ__Quote__c testQuote = PMC_DH_TestDataFactoryClass.createQuote(parentAcc,con.Id,opp);
        SBQQ__QuoteLine__c line1= PMC_DH_TestDataFactoryClass.creatQuoteLine2(testQuote, proList[0]);
        PMC_DH_TestDataFactoryClass.createCadence(line1);
        Contract testContract = PMC_DH_TestDataFactoryClass.createContract(testQuote.Id, parentAcc.Id);
        PMC_DH_TestDataFactoryClass.createSubscription(cartObj);
        Order testOrder = PMC_DH_TestDataFactoryClass.createOrder(parentAcc, testContract, cart.Id);
        PMC_DH_TestDataFactoryClass.creatOrderLine(testOrder, ci);
        PMC_DH_TestDataFactoryClass.createShipment(testOrder);
        Test.stopTest();
        
        List<PMC_SS_SalesArea__c> lstSalesAreas= PMC_TestUtilityClass.createSalesArea(2, '');
        PMC_DH_TestDataFactoryClass.createCommerceEntitlementSalesArea(parentAcc.Id, proList[0].Id, lstSalesAreas[0].Id);        
        System.assertEquals('Ship To Account123', shipToAccount.Name, 'Incorrect');
        
        
    }
    
    @isTest
    private static void createPortalUserTest(){
        Test.startTest();
        PMC_DH_TestDataFactoryClass.createTestAccount();
        PMC_DH_TestDataFactoryClass.createPortalUser();
        List<User> userList=[Select Id from User where Username='demouser@test.com.testuser' LIMIT 1]; 
        System.Assert( userList!=NULL,'Exception Occured');
        Test.stopTest();
        
    }
    @isTest
    private static void createTestUserTest(){
        User userAdmin=PMC_DH_TestDataFactoryClass.createAdminUser();
        System.runAs(userAdmin){
            Test.startTest();
            Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
            Account parentAcc = PMC_DH_TestDataFactoryClass.createParentTestAccount();
            PMC_DH_TestDataFactoryClass.createOpportunity2(parentAcc);
            PMC_DH_TestDataFactoryClass.createTestUser(parentAcc.Id,profile.Id);
            List<String> lstUserIds = new List<String>();
            Map<Id,String> mapUserIdProfileName = new Map<Id,String>();
            for(User objUser : [Select Id, Profile.Name from User where Username='demouser@test.com.testuser']){
                lstUserIds.add(objUser.Id);
                mapUserIdProfileName.put(objUser.Id,objUser.Profile.Name);
            }
            PMC_DH_UserTriggerHandler.assignPermissionsToUser(lstUserIds, mapUserIdProfileName);
            System.assertEquals('Parent Test Account', parentAcc.Name, 'Incorrect');
            Test.stopTest();
        }
    }
    
    
    
}