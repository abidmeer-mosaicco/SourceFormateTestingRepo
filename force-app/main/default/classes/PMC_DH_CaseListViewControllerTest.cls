/**
* @description : Test class for PMC_DH_CaseListViewController
* @author      : Lohitha Sai
* @modified by : Ajeet
* @Created on   06/29/2023
**/
@isTest
public with sharing class PMC_DH_CaseListViewControllerTest {
    
    /**
 * @description test data for searchCaseRecords method
 * @author Lohitha sai
 */
    @testSetup
    public static void testData(){
        BusinessHours bh=[SELECT name,id from BusinessHours where name='Default' limit 1];
        Account acc1=PMC_DH_TestDataFactoryClass.createParentTestAccount();
        Contact con=PMC_DH_TestDataFactoryClass.createTestContact(acc1.id); 
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc1.Id, profile.Id);
        User userRecord=[SELECT id,Name from User Where UserName = 'demouser@test.com.testuser'];
        Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(userRecord.Id,lstPermSet2);
        Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(userRecord.Id,lstPermSet);
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(userRecord.Id,lstPermSet1);
        Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(userRecord.Id,lstPermSet3);
        System.runAs(userRecord){
             PMC_DH_TestDataFactoryClass.createCaseRecord(acc1.Id,con.Id,bh.Id);
        }

    }
    /*
    @isTest
    public static void testSearchCaseRecordsException() {
        User usr=[SELECT id,Name from User Where UserName = 'demouser@test.com.testuser'];
        PMC_DH_CaseListViewController.PMC_DH_CaseWrapper caseWrapper = new PMC_DH_CaseListViewController.PMC_DH_CaseWrapper();
        caseWrapper.strSearchTerm = 'Test';
        Account acc1= [SELECT id from Account where name='Parent Test Account' LIMIT 1];
        System.runAs(usr) {
            Test.startTest();
            Boolean exceptionOccurred;
            try{
                PMC_DH_DigitalHubB2BUtils.throwTestException = true;
                PMC_DH_CaseListViewController.searchCaseRecords(caseWrapper,acc1.Id);
            }catch(exception e){
                exceptionOccurred=true;
            }
            System.assert(exceptionOccurred, 'An Exception was not thrown');
            Test.stopTest();
        }
    }
*/
    @isTest
    public static void testSearchCaseRecords() {
        Test.startTest();
        PMC_DH_CaseListViewController.PMC_DH_CaseListWrapper result;
        User userRecord=[SELECT id,Name from User Where UserName = 'demouser@test.com.testuser'];
        PMC_DH_CaseListViewController.PMC_DH_CaseWrapper caseWrapper = new PMC_DH_CaseListViewController.PMC_DH_CaseWrapper();
        caseWrapper.strSearchTerm = 'Test';
        Account acc1= [SELECT id from Account where name='Parent Test Account' LIMIT 1];
        System.runAs(userRecord){
            result = PMC_DH_CaseListViewController.searchCaseRecords(caseWrapper,acc1.Id);
        }
        Test.stopTest();
        System.assert(result!=null, 'Incorrect');
    }

    @isTest
    public static void testSearchCaseRecords2() {
        Test.startTest();
        PMC_DH_CaseListViewController.PMC_DH_CaseListWrapper result;
        User userRecord=[SELECT id,Name from User Where UserName = 'demouser@test.com.testuser'];
        PMC_DH_CaseListViewController.PMC_DH_CaseWrapper caseWrapper = new PMC_DH_CaseListViewController.PMC_DH_CaseWrapper();
        caseWrapper.strFromDate = String.valueOf(Date.today());
        caseWrapper.strToDate = String.valueOf(Date.today());
        Account acc1= [SELECT id from Account where name='Parent Test Account' LIMIT 1];
        System.runAs(userRecord){
            result = PMC_DH_CaseListViewController.searchCaseRecords(caseWrapper,acc1.Id);
        }
        Test.stopTest();
        //System.assertEquals(1, result.size(), 'Incorrect');
        System.assert(result!=null, 'Incorrect');
    }

    @isTest
    public static void testSearchCaseRecords3() {
        Test.startTest();
        PMC_DH_CaseListViewController.PMC_DH_CaseListWrapper result;
        User userRecord=[SELECT id,Name from User Where UserName = 'demouser@test.com.testuser'];
        PMC_DH_CaseListViewController.PMC_DH_CaseWrapper caseWrapper = new PMC_DH_CaseListViewController.PMC_DH_CaseWrapper();
        caseWrapper.strSearchTerm = 'Test';
        caseWrapper.strFromDate = String.valueOf(Date.today());
        caseWrapper.strToDate = String.valueOf(Date.today());
        Account acc1= [SELECT id from Account where name='Parent Test Account' LIMIT 1];
        System.runAs(userRecord){
            result = PMC_DH_CaseListViewController.searchCaseRecords(caseWrapper,acc1.Id);
        }
        Test.stopTest();
        //System.assertEquals(1, result.size(), 'Incorrect');
        System.assert(result!=null, 'Incorrect');
    }

    @isTest
    public static void testFetchCaseRecords() {
        Test.startTest();
        PMC_DH_CaseListViewController.PMC_DH_CaseListWrapper result;
        User userRecord=[SELECT id,Name from User Where UserName = 'demouser@test.com.testuser'];
        Account acc1= [SELECT id from Account where name='Parent Test Account' LIMIT 1];
        System.runAs(userRecord){
            result = PMC_DH_CaseListViewController.searchCaseRecords(null,acc1.Id);
        }
        Test.stopTest();
        //System.assertEquals(1, result.size(), 'Incorrect');
        System.assert(result!=null, 'Incorrect');
    }
}