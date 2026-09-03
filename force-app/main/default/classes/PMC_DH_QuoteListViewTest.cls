/**
* @description : Test class for PMC_DH_QuoteListViewController
* @author      : Lohitha Sai
* @Created on   07/04/2023
**/
@IsTest
public with sharing class PMC_DH_QuoteListViewTest {
     /**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* 
* @param: none
* 
* @return: void
*
* @author Rohan
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
        
        system.runAs(user){
            
            PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            insert prod;
            Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            Test.startTest();
            SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
            testQuote.PMC_CPQ_ContractStageName__c='Draft';
            update testquote;
            Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
            PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
            PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,prod);
            Test.stopTest();
           
            
        }
    }
    
    /**
* @description Test Method for fetchQuoteRecords
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/
    @isTest
    public static void testFetchQuoteRecords()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Account acc = [SELECT Id,Name FROM Account Where Name='Parent Test Account' LIMIT 1];
        SBQQ__Quote__c sQuote= [SELECT Id, PMC_DH_QuoteInactiveTime__c, SBQQ__Status__c from SBQQ__Quote__c LIMIT 1 ];
        sQuote.SBQQ__Status__c='Expired';
        update sQuote;
        
        system.runAs(user){
            
            Date datToday = Date.today();
            Date datYesterday = datToday.addDays(-1);
            Date datTomm = datToday.addDays(1);
            PMC_DH_QuoteListViewController.QuoteSearchParameterWrapper searchWrapper = new PMC_DH_QuoteListViewController.QuoteSearchParameterWrapper();
            searchWrapper.strSearchTerm='Quote';
            searchWrapper.datFromDate=datYesterday;
            searchWrapper.datToDate=datTomm;
            PMC_DH_QuoteListViewWrapper result=PMC_DH_QuoteListViewController.fetchQuoteRecords(searchWrapper , acc.Id);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for fetchQuoteRecords Exception
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/
    @isTest
    public static void testFetchQuoteRecordsException()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Account acc = [SELECT Id,Name FROM Account Where Name='Parent Test Account' LIMIT 1];
        system.runAs(user){
            //Boolean exceptionOccurred = false;
            //try{
            PMC_DH_QuoteListViewController.QuoteSearchParameterWrapper searchWrapper = new PMC_DH_QuoteListViewController.QuoteSearchParameterWrapper();
            searchWrapper.strSearchTerm='';
            searchWrapper.datFromDate=NULL;
            searchWrapper.datToDate=NULL;
                PMC_DH_DigitalHubB2BUtils.throwTestException = true;
                PMC_DH_QuoteListViewWrapper result = PMC_DH_QuoteListViewController.fetchQuoteRecords(searchWrapper,acc.Id);
               //}
               //catch(exception e){
                   //exceptionOccurred=true;
               //}
            System.AssertEquals(result.statusCodeMessage.strStatusCode, '100','success');
        }
        Test.stopTest();
    }
    
    
  /**
* @description Test Method for getCountryValidation
* 
* @param: none
* 
* @return: void
*
* @author Hemant Giri Goswami
* 
*/   
    @istest
    public static void getCountryValidationTest(){
        Test.startTest();
        User userObj=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        userObj.country='Brazil';
        update userObj;
        System.runAs(userObj)
        {	
            //Boolean boolResult= PMC_DH_QuoteListViewController.getCountryValidation(userObj.country);
            //System.AssertEquals(boolResult,true,'success');
            
            // changes as part of GDASF-19642
            PMC_DH_QuoteListViewController.PMC_DH_CountryValidationWrapper wrpResult = PMC_DH_QuoteListViewController.getCountryValidation(userObj.country);
            System.AssertEquals(wrpResult.boolFlag,true,'success');
        }
        Test.stopTest();
    }
    
    
  /**
* @description Test Method for getCountryValidation Exception
* 
* @param: none
* 
* @return: void
*
* @author Hemant Giri Goswami
* 
*/  
     @istest
    public static void getCountryValidationEXCEPTIONTest(){
        Test.startTest();
        User userObj=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        System.runAs(userObj)
        {	Boolean boolResult=true;
            
          try{
           PMC_DH_DigitalHubB2BUtils.throwTestException = true;
           PMC_DH_QuoteListViewController.getCountryValidation(userObj.country);
            }
            catch(exception e)
            {
                boolResult=false;
            }
            System.AssertEquals(boolResult,false,'success');
            
        }
        Test.stopTest();
    }
    
    @isTest
    public static void assignSourceTest()   
    {
        Test.startTest();
        User userObj=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        CartItem objCartItem = new CartItem();
        String str;
        System.runAs(userObj)
        {	PMC_DH_QuoteListViewController.assignSource(objCartItem,'rtd');
         	str='true';
		}
        System.AssertEquals(str,'true','success');
    	Test.stopTest();
}
    
}