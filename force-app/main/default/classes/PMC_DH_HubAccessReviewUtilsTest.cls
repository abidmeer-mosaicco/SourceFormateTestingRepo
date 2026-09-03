/**
 * @description       : 
 * @author            : @siddharth.pradhan
 * @group             : 
 * @last modified on  : 03-20-2024
 * @last modified by  : Mosaic Direct | Dev Team
**/
@isTest
public with sharing class PMC_DH_HubAccessReviewUtilsTest {
    
    /**
    * @description 
    * @author @siddharth.pradhan | 05-07-2023 
    **/
    @isTest
    public static void validateEmailSend(){
        test.startTest();
        Account acc=PMC_DH_TestDataFactoryClass.createTestAccount();
        Contact con = PMC_DH_TestDataFactoryClass.createContact(acc.Id);
        con.PMC_DH_Preferences__c='Access documents;Track orders';
        update con;
        Profile usrProfile = [SELECT id, name  from Profile where name = 'Digital Hub Super Buyer'];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,usrProfile.Id);
        List<Contact> lstCon=new List<Contact>();
        lstCon.add(con);
        PMC_DH_HubAccessReviewUtils.sendEmail(lstCon);
        System.assertNotEquals(null, con.Id,'super buyer found');
        test.stopTest();
        
    }


    
}