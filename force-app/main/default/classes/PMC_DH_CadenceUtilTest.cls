/**
* @description : Test class for PMC_DH_CadenceUtil
* @author      : Ajeet
* @last modified on 
* @last modified by 
**/
@isTest
public class PMC_DH_CadenceUtilTest {
    /**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* @param: none
* @return: void
*/
    @testSetup  static void setup()
    {
        Account acc;
        User user;
        String strContactId;
        User userAdmin=PMC_DH_TestDataFactoryClass.createAdminUser();
        System.runAs(userAdmin){
        acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
        user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
         strContactId=[SELECT contactId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1][0].contactId;
        Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet2);
        Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet);
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet1);
        Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet3);
        }
        system.runAs(user){            
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            insert prod;
            Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
            testQuote.PMC_CPQ_QuoteOrigin__c = 'DH Request';
            update testQuote;
            SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,prod);
            Test.startTest();
            Contract testContract=PMC_DH_TestDataFactoryClass.createContract(testQuote.id,acc.id); 
            testContract.Status='Activated';
            update testContract;
            PMC_CPQ_Cadence__c testCadence = new PMC_CPQ_Cadence__c();
            testCadence.PMC_CPQ_QuoteLine__c = testQuoteLine.Id;
            testCadence.PMC_CPQ_RequestedDate__c = System.today();
            testCadence.PMC_CPQ_RequestedQuantity__c = 25;
            insert testCadence;
            //PMC_DH_TestDataFactoryClass.createCadence(testQuoteLine);
            Test.stopTest();
        }
    } 


    @isTest
    public static void deleteAndCreateCadenceTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strQuoteId = [SELECT Id FROM SBQQ__Quote__c WHERE PMC_DH_QuoteFriendlyName__c = 'Test Quote' LIMIT 1].id;
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result;
        System.runAs(user){
            result = PMC_DH_CadenceUtil.createCadence(strQuoteId, true);        
        }
        System.assert(result!=null, 'Success');
        Test.stopTest();
    }
    
    @isTest
    public static void createCadenceTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strQuoteId = [SELECT Id FROM SBQQ__Quote__c WHERE PMC_DH_QuoteFriendlyName__c = 'Test Quote' LIMIT 1].id;
        List<PMC_CPQ_Cadence__c> lstCadence = [select id from PMC_CPQ_Cadence__c where PMC_CPQ_QuoteLine__r.SBQQ__Quote__c =: strQuoteId];
        delete lstCadence;
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result;
        System.runAs(user){
            result = PMC_DH_CadenceUtil.createCadence(strQuoteId, true);        
        }
        System.assert(result!=null, 'Success');
        Test.stopTest();
    }

    @isTest
    public static void getCadenceRecordsTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strQuoteId = [SELECT Id FROM SBQQ__Quote__c WHERE PMC_DH_QuoteFriendlyName__c = 'Test Quote' LIMIT 1].id;
        PMC_DH_CadenceUtil.PMC_DH_QuoteAndCadenceLstResponseWrapper result;
        System.runAs(user){
            result = PMC_DH_CadenceUtil.getCadenceRecords(strQuoteId);        
        }
        System.assert(result!=null, 'Success');
        Test.stopTest();
    }

    @isTest
    public static void updateCadenceTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        PMC_CPQ_Cadence__c cadence = [SELECT Id FROM PMC_CPQ_Cadence__c LIMIT 1];
        List<PMC_DH_CadenceUtil.PMC_DH_CadenceWrapper> lstCadenceWrapper = new List<PMC_DH_CadenceUtil.PMC_DH_CadenceWrapper>();
        PMC_DH_CadenceUtil.PMC_DH_CadenceWrapper cadencewrp1 = new PMC_DH_CadenceUtil.PMC_DH_CadenceWrapper();
        cadencewrp1.strCadenceId = cadence.Id;
        cadencewrp1.strMonth =  String.valueOf(System.today());
        cadencewrp1.intQuantity = 30;
        lstCadenceWrapper.add(cadencewrp1);
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result;
        System.runAs(user){
            result = PMC_DH_CadenceUtil.updateCadence(lstCadenceWrapper);        
        }
        System.assertEquals('000', result.strStatusCode, 'Success');
        Test.stopTest();
    }

    @isTest
    public static void testExceptionCall()
    {
        Boolean boolExc=False;
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        System.runAs(user){
            PMC_DH_DigitalHubB2BUtils.throwTestException = true;
            PMC_DH_CadenceUtil.PMC_DH_QuoteAndCadenceLstResponseWrapper quoteCadenceRecordsWrapper =new PMC_DH_CadenceUtil.PMC_DH_QuoteAndCadenceLstResponseWrapper();
            quoteCadenceRecordsWrapper=PMC_DH_CadenceUtil.getCadenceRecords(''); 
            if(quoteCadenceRecordsWrapper.statusCodeMessage.strStatusCode!='000')
            {
             boolExc=True;   
            } 
            System.assertEquals(True,boolExc, 'Exception not Handled');
            Test.stopTest();  
        }
	
    }
}