/**
* @description : Test class for PMC_DH_QuoteManagementController
* @author      : Humera Rahath
* @userStory   : GDASF-121
* @last modified by Hemant Giri Goswami
* @last modified on 06-07-2023
**/
@isTest
public with sharing class PMC_DH_QuoteMgmtRelatedItemsClassTest {
    
    /**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* 
* @param: none
* 
* @return: void
*
* @author Hemant
* 
*/
    @testSetup  
    static void setup()
    {
        Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();        
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
        
        
        User userR=[SELECT id FROM User WHERE Email = 'demouser@test.com' limit 1];
        String strContactId=[SELECT contactId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1][0].contactId;
        Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(userR.Id,lstPermSet2);
        Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(userR.Id,lstPermSet);
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(userR.Id,lstPermSet1);
        Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(userR.Id,lstPermSet3);
        WebStore webStore=PMC_DH_TestDataFactoryClass.createTestWebStore();
        System.runAs(userR)
        {
    		WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
            insert cartObj;
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            insert prod;
            PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            test.startTest();
            SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,new Opportunity());
            SBQQ__QuoteLine__c testQuoteLine=PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,prod);
            Contract testContract=PMC_DH_TestDataFactoryClass.createContract(testQuote.id,acc.id);
            testContract.Status='Activated';
            testContract.ContractTerm=1;
            update testContract;
            CartDeliveryGroup testCartDeliveryGroup=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj.id);
            insert testCartDeliveryGroup;
            
            Account shipToAcc=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
            Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
            
            PMC_CPQ_ProductLocation__c prodLocation = PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
            PMC_DH_TestDataFactoryClass.CartItemObject objCartItem=new PMC_DH_TestDataFactoryClass.CartItemObject();
            objCartItem.strCartId=cartObj.id;
            objCartItem.strProductId=prod.id;
            objCartItem.strDeliveryGroupId=testCartDeliveryGroup.id;
            objCartItem.strShipToAccId=shipToAcc.id;
            objCartItem.strQuoteLineId =testQuoteLine.id;
            objCartItem.strShipFromId=prodLocation.id;
            objCartItem.strContractId = testContract.Id;
            SBQQ__Subscription__c subsc=PMC_DH_TestDataFactoryClass.createSubscription(objCartItem);
            CartItem cartItem1=PMC_DH_TestDataFactoryClass.buildCartItem1(objCartItem);
            cartItem1.PMC_DH_Source__c='RFQ';
            cartItem1.PMC_DH_Subscription__c=subsc.id;
            cartItem1.PMC_DH_Contract__c=testContract.Id;
            cartItem1.PMC_DH_DeliveryMode__c='barge';
            upsert cartItem1;
        }    
    } 
    
    
    
/**
* @description Test Method for getConversationHistory  method
* 
* @param: none
* 
* @return: void
*
* @author Hemant
* 
*/
    
    @isTest
    public static void getConversationHistoryTest(){
        
        User userOR=[SELECT id,name,profile.name FROM User WHERE Email = 'demouser@test.com' limit 1];
        Test.startTest();
        System.runAs(userOR)
        {
        SBQQ__Quote__c objQuote=[SELECT ID,PMC_DH_PaymentMethod__c,PMC_CPQ_ContractStart__c,PMC_CPQ_ContractEnd__c,SBQQ__PaymentTerms__c,
                                CurrencyIsoCode FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote' LIMIT 1];
            List<SBQQ__Quote__History> histList=new List<SBQQ__Quote__History>();
            List<SBQQ__QuoteLine__History> histQList=new List<SBQQ__QuoteLine__History>();
            
            SBQQ__Quote__History hist=new SBQQ__Quote__History(Field='Name');
            histList.add(hist);
            SBQQ__QuoteLine__History histql=new SBQQ__QuoteLine__History(Field='Incoterms');
            histQList.add(histql);
            //added as part of GDASF-19642
            PMC_DH_QuoteMgmtRelatedItemsClass.processConvo(histList,histQList); //added as part of GDASF-19642
    
            //added as part of GDASF-19642
            PMC_DH_QuoteMgmtRelatedItemsClass.PMC_DH_ConversationHistoryWrapper wrpResult = PMC_DH_QuoteMgmtRelatedItemsClass.getConversationHistory(objQuote.id);
            System.assert(wrpResult.lstQtHistory != null,'Success');
        }
        Test.stopTest();
        
    }
    
    
    @isTest
    public static void getExceptiongetShipTos()
    {
        User userOR=[SELECT id,name FROM User WHERE Email = 'demouser@test.com' limit 1];
        Test.startTest();
        System.runAs(userOR)
        {
            PMC_DH_DigitalHubB2BUtils.throwTestException=true;
            map<String,String> strResult=new map<String,String>() ;
            String strIns='';
            try{
                List<SBQQ__QuoteLine__History> lstMock=new List<SBQQ__QuoteLine__History>();
            strResult=PMC_DH_QuoteMgmtRelatedItemsClass.getShipTos(lstMock);
            }
            catch(Exception e){
                strIns='Exception';
            }
            System.assertEquals('Exception',strIns,'Passed');

        }   
        Test.stopTest();
    }
    
    
    @isTest
    public static void getExceptiongetAccountList(){
        User userOR=[SELECT id,name FROM User WHERE Email = 'demouser@test.com' limit 1];
        Test.startTest();
        System.runAs(userOR)
        {
            PMC_DH_DigitalHubB2BUtils.throwTestException=true;
            map<String,String> strResult=new map<String,String>() ;
            String strIns='';
            try{
                set<Id> setId=new set<Id>();
            strResult=PMC_DH_QuoteMgmtRelatedItemsClass.getAccountList(setId);
            }
            catch(Exception e){
                strIns='Exception';
            }
            System.assert(strIns.equals('Exception'),'Passed');

        }
        Test.stopTest();
    }
    
    @isTest
    public static void lstQuoteLineDatabaseException(){
        User userOR=[SELECT id,name FROM User WHERE Email = 'demouser@test.com' limit 1];
        Test.startTest();
        System.runAs(userOR)
        {
            PMC_DH_DigitalHubB2BUtils.throwTestException=true;
            List<SBQQ__QuoteLine__History> lstResult=new List<SBQQ__QuoteLine__History>();
            String strIns='';
            try{
            List<String> lstFL=new List<String>();
            lstResult=PMC_DH_QuoteMgmtRelatedItemsClass.lstQuoteLineDatabase('',lstFL);
            }
            catch(Exception e){
                strIns='Exception';
            }
            System.assert(strIns.equals('Exception'),'Passed');
        }
    Test.stopTest();

    }
    
    @isTest
    public static void lstQuoteDatabaseException(){
        User userOR=[SELECT id,name FROM User WHERE Email = 'demouser@test.com' limit 1];
        Test.startTest();
        System.runAs(userOR)
        {
            PMC_DH_DigitalHubB2BUtils.throwTestException=true;
            List<SBQQ__Quote__History> lstResult=new List<SBQQ__Quote__History>();
            String strIns='';
            try{
                
            lstResult=PMC_DH_QuoteMgmtRelatedItemsClass.lstQuoteDatabase('');
            }
            catch(Exception e){
                strIns='Exception';
            }
            System.assert(strIns.equals('Exception'),'Passed');
        }
    Test.stopTest();

    }
    
    
    @isTest
    public static void processConvoException(){
        User userOR=[SELECT id,name FROM User WHERE Email = 'demouser@test.com' limit 1];
        Test.startTest();
        System.runAs(userOR)
        {
            PMC_DH_DigitalHubB2BUtils.throwTestException=true;
            PMC_DH_QuoteMgmtRelatedItemsClass.PMC_DH_ConversationHistoryWrapper wrpConvHistory = new PMC_DH_QuoteMgmtRelatedItemsClass.PMC_DH_ConversationHistoryWrapper(); 
                List<SBQQ__Quote__History> lstQHis=new List<SBQQ__Quote__History>();
                List<SBQQ__QuoteLine__History> lstQLineHis= new List<SBQQ__QuoteLine__History>();
                wrpConvHistory=PMC_DH_QuoteMgmtRelatedItemsClass.processConvo(lstQHis,lstQLineHis); //added as part of GDASF-19642
            
            System.assert(wrpConvHistory.statusCodeMessage.strStatusCode!='000','Failed due to wrong status code');
        }
    Test.stopTest();

    }
        /**
* @description Test Method for getConversationHistory Exception  method
* 
* @param: none
* 
* @return: void
*
* @author Hemant
* 
*/        
    @isTest
        public static void getConversationHistoryException()
        {
            User userOR=[SELECT id,name FROM User WHERE Email = 'demouser@test.com' limit 1];
        Test.startTest();
        System.runAs(userOR)
        {
            String lstResult;
            lstResult=PMC_DH_QuoteMgmtRelatedItemsClass.getUserPersona('System Admin','efg');
            PMC_DH_QuoteMgmtRelatedItemsClass.getUserPersona(PMC_DH_ConstantClass.PMC_DH_APPNAME,'Sham Zack');
        System.assert(lstResult.equals('Mosaic'),'Success');
            PMC_DH_DigitalHubB2BUtils.throwTestException=true;
            try{
            lstResult=PMC_DH_QuoteMgmtRelatedItemsClass.getUserPersona('digital hub',userOR.name);
            }
            catch(Exception e){
                lstResult='Exception';
            }
            System.assert(lstResult.equals('Exception'),'Passed');
            
        }
            Test.stopTest();
            
        }
    
    
    /**
* @description Test Method for Exception  method
* 
* @param: none
* 
* @return: void
*
* @author Hemant
* 
*/        
    @isTest
        public static void exceptionTest()
        {
            User userOR=[SELECT id FROM User WHERE Email = 'demouser@test.com' limit 1];
        Test.startTest();
        System.runAs(userOR)
        {
            List<PMC_DH_QuoteDetailsWrapper.QuoteHistoryWrapper> lstResult=new List<PMC_DH_QuoteDetailsWrapper.QuoteHistoryWrapper>();
            PMC_DH_DigitalHubB2BUtils.throwTestException=true;
            
            try{
            PMC_DH_QuoteMgmtRelatedItemsClass.getConversationHistory('QId'); //added as part of GDASF-19642
            }
            catch(Exception e){
                lstResult=null;
            }
            System.assert(lstResult==null,'Passed');
        }
        Test.stopTest();  
        }
    
    @isTest
    public static void getConversationHistoryExceptionTest()
    {
        User userOR=[SELECT id FROM User WHERE Email = 'demouser@test.com' limit 1];
        Test.startTest();
        System.runAs(userOR)
        {
            List<PMC_DH_QuoteDetailsWrapper.QuoteHistoryWrapper> lstResult=new List<PMC_DH_QuoteDetailsWrapper.QuoteHistoryWrapper>();
            PMC_DH_DigitalHubB2BUtils.throwTestException=true;
            
            try{
                PMC_DH_QuoteMgmtRelatedItemsClass.getConversationHistory('QId'); //added as part of GDASF-19642
            }
            catch(Exception e){
                lstResult=null;
            }
            System.assert(lstResult==null,'Passed');
        }
        Test.stopTest();  
    }
    
    @istest
    public static void getContractsTest() // GDASF-19663 test class fix
    {
	User userOR=[SELECT id FROM User WHERE Email = 'demouser@test.com' limit 1];
    Test.startTest();
        System.runAs(userOR)
        {	SBQQ__Quote__c objQuote=[SELECT ID,PMC_DH_PaymentMethod__c,PMC_CPQ_ContractStart__c,PMC_CPQ_ContractEnd__c,SBQQ__PaymentTerms__c,
                                CurrencyIsoCode FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote' LIMIT 1];
         String strQuoteId=objQuote.id;
         PMC_DH_QuoteMgmtRelatedItemsClass.PMC_DH_ContractListWrapper conWrr=new PMC_DH_QuoteMgmtRelatedItemsClass.PMC_DH_ContractListWrapper();
         conWrr=PMC_DH_QuoteMgmtRelatedItemsClass.getContracts(strQuoteId);
         System.assert(conWrr!=null,'Passed');
        }
       Test.stopTest();  
    }     
}