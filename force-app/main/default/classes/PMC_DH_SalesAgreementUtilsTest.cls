@isTest
public with sharing class PMC_DH_SalesAgreementUtilsTest {
    /**
 * @description data setup
 * @since 08-11-2023
 */
    @testSetup
    public static void testData(){
        Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
        PMC_DH_TestDataFactoryClass.createTestContact(acc.id);
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
        User usr=[SELECT Id,ContactId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(usr.Id,lstPermSet2);
        Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(usr.Id,lstPermSet);
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(usr.Id,lstPermSet1);
        Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(usr.Id,lstPermSet3);
        Id lstPermSet4=[select id from PermissionSet where Name ='PMC_DH_Account_Switcher'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(usr.Id,lstPermSet4);
        
        
        WebStore webStore=PMC_DH_TestDataFactoryClass.createTestWebStore();
        //system.runAs(user){
        WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
        insert cartObj;
        Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
        insert prod;
        CartDeliveryGroup testCartDeliveryGroup=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj.id);
        insert testCartDeliveryGroup;
        CartItem cartItem=PMC_DH_TestDataFactoryClass.buildCartItem(cartObj.id, prod.id,testCartDeliveryGroup.Id);
        cartItem.Quantity = 5;
        cartItem.TotalLineAmount = 5100;
        insert cartItem;
        
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
        cartItem1.Quantity = 10;
        cartItem1.TotalLineAmount = 100;
        insert cartItem1;
        Test.startTest();
        PricebookEntry pe = new PricebookEntry(Product2Id = prod.Id, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 1);
        insert pe;
        
        
        SalesAgreement salesAgreement = new SalesAgreement();
        salesAgreement.Name = 'Test Sales Agreement';
        salesAgreement.Status = 'Draft';
        salesAgreement.StartDate = System.Today();
        salesAgreement.EndDate = System.Today() + 60;
        salesAgreement.AccountId = acc.Id;
        salesAgreement.ScheduleFrequency = 'Weekly';
        salesAgreement.ScheduleCount = 60;
        salesAgreement.CurrencyIsoCode = 'USD';
        salesAgreement.ProductLevel = 'Product';
        salesAgreement.PricebookId = Test.getStandardPricebookId();
        insert salesAgreement;
        SalesAgreementProduct sap = new SalesAgreementProduct();
        sap.name = prod.name;
        sap.SalesAgreementId = salesAgreement.id;
        sap.PricebookEntryId = pe.id;
        sap.InitialPlannedQuantity = 300;
        insert sap;
        Test.stopTest();

    }
        /**
* @description test method to 
*/
@isTest
public static void updateSalesAgreementIdTest()
{	
    Test.startTest();
    User usr=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
    String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].Id;
    System.runAs(usr)
    {  
        PMC_DH_RequestForQuoteHelper.PMC_DH_SalesAreaForCartWrapper result =PMC_DH_SalesAgreementUtils.updateSalesAgreementId(strCartId);
         system.assert(result!=null,'success');
    }
    test.stopTest();
}
}