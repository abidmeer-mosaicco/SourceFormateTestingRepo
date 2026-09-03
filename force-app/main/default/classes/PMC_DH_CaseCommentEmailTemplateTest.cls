/**
* @description : Test class for PMC_DH_CaseCommentEmailTemplate
* @author      : Lohitha
* @userStory   : GDASF-13391
* @Created on  : 26-Sep-2023
**/
@isTest
public with sharing class PMC_DH_CaseCommentEmailTemplateTest {
    /**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* @param: none
* @return: void
* @author Lohitha
*/
@testSetup  static void setup()
{
    Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
    //Account shipToAcc=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
    Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
    PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
    
    User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
    String strContactId=[SELECT Id, contactId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1][0].contactId;
    BusinessHours strBusinessHoursId = [select name,id from BusinessHours where name='Default' limit 1];
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
        PMC_DH_TestDataFactoryClass.createCaseRecord(acc.Id,strContactId,strBusinessHoursId.Id);
    
    }
}
    /**
* @description Test Method for sendEmailWithTemplate method
* @param: none
* @return: void
* @author Lohitha
*/
@isTest
public static void sendEmailWithTemplateTest(){
    Test.startTest();
    User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
    system.runAs(user){
        String strCaseId=[SELECT ID FROM Case WHERE Subject='test case demo'][0].Id;
        List<Id> testIds = new List<Id>();
        testIds.add(strCaseId);
        List<Boolean> result = PMC_DH_CaseCommentEmailTemplate.sendEmailWithTemplate(testIds);
        System.assert(result != null, 'Success');
    }
    Test.stopTest();
}
}