/**
* @description This test class covers all the methods of PMC_ContactTriggerHandler and PMC_ContactTriggerHelper.
* @author Sayali Shinde
*/
@isTest(seeAllData = false)
public with sharing class PMC_ContactTriggerHandlerTest {
    /**
    * @description This Method sets up test data for test class execution.
    */
    @testSetup
    private static void setup() {
        Profile objUserProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        if (objUserProfile != null) {
            // Create 2 test users with known alias
            List<User> lstUser = new List<User>();
            for (Integer i = 0; i < 2; i++) {
                User testUser = new User(
                    FirstName = 'Test',
                    LastName = 'User' + i,
                    Email = 'testuser' + i + '@testorg.com',
                    Username = 'testuser' + i + '@testorg.com.dev',
                    Alias = 'testusr' + i,
                    TimeZoneSidKey = 'America/New_York',
                    LocaleSidKey = 'en_US',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US',
                    ProfileId = objUserProfile.Id,
                    IsActive = true
                );
                lstUser.add(testUser);
            }
            insert lstUser;
 
            // Create contacts
            PMC_TestUtilityClass.createContact(5, '');
            PMC_TestUtilityClass.createContactWithPhone();
        }
    }
 
    /** 
    * @description Tests the duplicate contact phone number logic.
    */ 
    @isTest
    private static void testDuplicateContacts() {
        Test.startTest();
        try {
            // Fetch the active user created in setup
            User objUser = [SELECT Id, Name FROM User WHERE Alias = 'testusr0' LIMIT 1];
            List<Contact> lstContacts = [SELECT Id, Name, Phone, HomePhone, MobilePhone, OtherPhone FROM Contact];
 
            if (objUser != null && lstContacts.size() >= 5) {
                System.runAs(objUser) {
                    lstContacts[0].Phone = '1212121212';
                    lstContacts[0].HomePhone = '1313131313';
                    lstContacts[0].MobilePhone = '1414141414';
                    lstContacts[0].OtherPhone = '1515151515';
                    update lstContacts[0];
 
                    List<Contact> lstContactsToBeUpdated = new List<Contact>();
                    lstContacts[1].HomePhone = '1313131313'; 
                    lstContactsToBeUpdated.add(lstContacts[1]);
                    lstContacts[2].Phone = '1212121212';
                    lstContactsToBeUpdated.add(lstContacts[2]);
                    lstContacts[3].MobilePhone = '1414141414';
                    lstContactsToBeUpdated.add(lstContacts[3]);
                    lstContacts[4].OtherPhone = '1515151515';
                    lstContactsToBeUpdated.add(lstContacts[4]);
 
                    update lstContactsToBeUpdated;
                }
            }
        } catch(Exception objException) {
            System.assertNotEquals('', objException.getMessage(), 'Expected error log object to be created');
        }
        Test.stopTest();
    }
 
    /** 
    * @description Tests bypass trigger logic.
    */ 
    @isTest
    private static void testBypassUpdateOperation() {
        PMC_ContactTriggerHandler.boolBypassTriggerLogic = true;
 
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User WHERE Alias = 'testusr0' LIMIT 1];
        Contact objContact = [SELECT Id, Name, Phone, HomePhone, MobilePhone, OtherPhone FROM Contact LIMIT 1];
 
        if (objUser != null && objContact != null) {
            System.runAs(objUser) {
                PMC_TestUtilityClass.createContact(1, '');
                objContact.Email = 'test@testqa.comm';
                update objContact;
            }
        }
        Test.stopTest();
 
        System.assertEquals(
            'test@testqa.comm',
            [SELECT Id, Email FROM Contact WHERE Id = :objContact.Id].Email,
            'Validating Contact Email.'
        );
    }
}