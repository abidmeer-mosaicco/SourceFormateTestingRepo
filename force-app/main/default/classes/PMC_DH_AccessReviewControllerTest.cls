/**
* @description Wrapper class for value label picklist
* @author @siddharth.pradhan 
* @last modified on 05-18-2023
* @last modified by  @siddharth.pradhan 
**/
@isTest
public with sharing class PMC_DH_AccessReviewControllerTest {
   
      @TestSetup
    private static void makeData(){
        Account acc = PMC_DH_TestDataFactoryClass.createTestAccount();
        Profile usrProfile = [SELECT id, name  from Profile where name = 'Digital Hub Super Buyer'];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,usrProfile.Id);
    }
   
   
    @isTest
    public static void emailTemplateTest(){
        test.startTest();
        PMC_DH_AccessReviewController accRev=new PMC_DH_AccessReviewController();
        Contact c=new Contact();
        c.FirstName='Ben';
        c.LastName='Parker';
        c.Email='dhbuyeraccess@mosiactestmail.com';
        c.PMC_DH_Preferences__c='Access documents;Track orders';
        insert c;
        accRev.contId=c.Id;
        accRev.contact=c;
        System.assertNotEquals(null, c.id, 'Contact Fetch Successful');
        test.stopTest();
    }
    

}