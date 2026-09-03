/**
* @description : Test class for PMC_DH_HeaderDetails
* @author      : Humera Rahath
* @userStory   : GDPH-299 & GDPH -185
* @last modified by Nikhilesh
* @last modified on 05-15-2023
**/
@isTest 
public with sharing class PMC_DH_HeaderDetailsTest {
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
        Account acc=PMC_DH_TestDataFactoryClass.createTestAccount();
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Digital Hub Super Buyer' LIMIT 1];
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
            ProductCatalog testCatalog=PMC_DH_TestDataFactoryClass.createTestCatalog();
            PMC_DH_TestDataFactoryClass.CreateTestParentCategory(testCatalog.id);
            WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
            cartObj.CurrencyIsoCode='BRL';
            insert cartObj;
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            insert prod;
            CartDeliveryGroup testCartDeliveryGroup=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj.id);
            insert testCartDeliveryGroup;
            CartItem cartItem=PMC_DH_TestDataFactoryClass.buildCartItem(cartObj.id, prod.id,testCartDeliveryGroup.Id);
            cartItem.CurrencyIsoCode='BRL';
            insert cartItem;
        }
        
    }
    
    /**
* @description Test Method for getting header details
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/
    @isTest
    public static void getHeadereDetailsTest(){
        test.startTest();
        User user=[SELECT id from User WHERE Username = 'demouser@test.com.testuser'];
        system.runAs(user){
            String strTestAcct=[SELECT id FROM Account WHERE Name='Test Account' LIMIT 1].Id;
            PMC_DH_HeaderDetailsWrapper str = PMC_DH_HeaderDetails.getHeaderDetails(strTestAcct);
            System.Assert(str!=null, 'Success');
        }
        test.stopTest();
    }
    
    /**
* @description Test Method for getting test user's account data
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/
    @isTest
    public static void getMyAccountDataTest(){
        test.startTest();
        User user=[SELECT id from User WHERE Username = 'demouser@test.com.testuser'];
        Account acc=[SELECT id,RecordType.Name FROM Account WHERE Name='Test Account' LIMIT 1];
        acc.RecordType.Name='Retailer';
        update acc;
        system.runAs(user){
             // added as part of GDASF-19642
            PMC_DH_PermissionsFrameworkUtilClass.PMC_DH_FeatureVisibilityWrapper wrpResult = PMC_DH_PermissionsFrameworkUtilClass.getFeatureVisibilityMyAccountData(acc.Id);
            System.Assert(wrpResult.strResult != null, 'Success');
        }
        test.stopTest();
    }
    
    /**
* @description 
* @author Hemant Giri Goswami | hegoswami@deloitte.com | 10-31-2023 
**/
    @isTest
    public static void getMyAccountDataTestContinue(){
        test.startTest();
        User user=[SELECT id from User WHERE Username = 'demouser@test.com.testuser'];
        Account acc=[SELECT id,PMC_SS_Channel__c FROM Account WHERE Name='Test Account' LIMIT 1];
        acc.PMC_SS_Channel__c='Feed';
        update acc;
        system.runAs(user){
            // added as part of GDASF-19642
            PMC_DH_PermissionsFrameworkUtilClass.PMC_DH_FeatureVisibilityWrapper wrpResult = PMC_DH_PermissionsFrameworkUtilClass.getFeatureVisibilityMyAccountData(acc.Id);
            System.Assert(wrpResult.strResult != null, 'Success');
        }
        test.stopTest();
    }
    
    @isTest
    public static void getHeaderDetailsExceptionTest(){
        test.startTest();
        User user=[SELECT id from User WHERE Username = 'demouser@test.com.testuser'];
        system.runAs(user){
            PMC_DH_HeaderDetailsWrapper str = PMC_DH_HeaderDetails.getHeaderDetails('abcd');
            System.Assert(str!=null, 'Success');
        }
        test.stopTest();
    }
    
    
     /**
* @description 
* @author Hemant Giri Goswami | hegoswami@deloitte.com |
**/ 
    @isTest
    public static void testExceptionCases()
    {
        test.startTest();
        User user=[SELECT id from User WHERE Username = 'demouser@test.com.testuser'];
        system.runAs(user){
            String strResult='';
            List<PMC_DH_FeatureVisibility__mdt> lstNavData;
            try{
                PMC_DH_DigitalHubB2BUtils.throwTestException=true;
            PMC_DH_PermissionsFrameworkUtilClass.getFeatureVisibilityNavigationData('demo',lstNavData);
            }
            catch(Exception ex)
            {
                strResult='Pass';
            }
            System.Assert(strResult=='Pass', 'Success');
        }
        test.stopTest();
	
    }
     
}