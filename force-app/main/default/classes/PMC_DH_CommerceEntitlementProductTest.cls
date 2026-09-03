/**
* @description : Test class for PMC_DH_CommerceEntitlementProductTrigger
* @author      : Rohan Undale
* @Created on   10/30/2023
**/
@IsTest
public class PMC_DH_CommerceEntitlementProductTest {
    /**
    * @description Method for getting test data from PMC_DH_TestDataFactoryClass
    * @param: none
    * @return: void
    * @author Rohan
    */
    @testSetup  static void setup()
    {
        Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
        //Account acc2=PMC_DH_TestDataFactoryClass.createParentTestAccount();
        PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
        Test.startTest();
        
        Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
        prod.ProductCode='AB-45678';
        prod.StockKeepingUnit='45678';
        insert prod; 
        Test.stopTest();
        BuyerGroup bGrp = PMC_DH_TestDataFactoryClass.createBuyerGroup();
        BuyerAccount buyerAccount = new BuyerAccount();
        buyerAccount.BuyerId = acc.Id;
        buyerAccount.Name = 'Test Buyer Account (BA-AJ)';
        buyerAccount.IsActive = true;
        insert buyerAccount;
        PMC_DH_TestDataFactoryClass.createBuyerGroupMember(buyerAccount.BuyerId,bGrp.Id);
        CommerceEntitlementPolicy objPolicy = PMC_DH_TestDataFactoryClass.createEntitlementPolicy();
        PMC_DH_TestDataFactoryClass.createCommerceEntitlementBuyerGroup(objPolicy.Id,bGrp.Id);
        WebStore testWebStore = PMC_DH_TestDataFactoryClass.createTestWebStore();
        testWebStore.Name = 'Mosaic Direct';
        update testWebStore;
        
        PMC_SS_SalesArea__c testSalesArea = new PMC_SS_SalesArea__c();
        testSalesArea.PMC_SS_SalesOrganization__c = 'Mosaic Global Sales LLC';
        //testSalesArea.PMC_CPQ_MosaicLLP__c= '1002';
        testSalesArea.PMC_SS_DistributionChannel__c = '0';
        testSalesArea.PMC_SS_Division__c = '10';
        insert testSalesArea;
        
        PMC_CPQ_ProductSalesArea__c tetProSalesArea=new PMC_CPQ_ProductSalesArea__c();
        tetProSalesArea.PMC_CPQ_Product__c=prod.Id;
        tetProSalesArea.PMC_CPQ_Sales_Area__c=testSalesArea.Id;
        insert tetProSalesArea;
        
        PMC_SS_AccountSalesAreaRelationship__c testAccSalesArea=new PMC_SS_AccountSalesAreaRelationship__c();
        testAccSalesArea.PMC_SS_Account__c=acc.Id;
        testAccSalesArea.PMC_SS_SalesArea__c=testSalesArea.Id;
        insert testAccSalesArea;
        
        PMC_DH_TestDataFactoryClass.createCommerceEntitlementProduct(objPolicy.Id,prod.Id);
    }
    
	/**
    * @description test Commerce Entitlement Product Delete
    * @author Rohan Undale
    **/
    @isTest
    public static void testCommerceEntitlementProductDelete(){
        Test.startTest();
        CommerceEntitlementProduct testEntitlementProduct = [SELECT Id FROM CommerceEntitlementProduct LIMIT 1];
        Delete testEntitlementProduct;
        Test.stopTest();
        List<CommerceEntitlementProduct> lstEntitlementProduct = [SELECT Id FROM CommerceEntitlementProduct];
        System.assertEquals(0, lstEntitlementProduct.Size(), 'Success');
    } 
    
    /**
    * @description test Commerce Entitlement Product Delete
    * @author Rohan Undale
    **/
    @isTest
    public static void testCommerceEntitlementProductDeleteBypass(){
        Test.startTest();
        PMC_DH_CommerceEntitlementProductHandler.boolBypassTriggerLogic = true;
        CommerceEntitlementProduct testEntitlementProduct = [SELECT Id FROM CommerceEntitlementProduct LIMIT 1];
        Delete testEntitlementProduct;
        Test.stopTest();
        List<CommerceEntitlementProduct> lstEntitlementProduct = [SELECT Id FROM CommerceEntitlementProduct];
        System.assertEquals(0, lstEntitlementProduct.Size(), 'Success');
    } 
}