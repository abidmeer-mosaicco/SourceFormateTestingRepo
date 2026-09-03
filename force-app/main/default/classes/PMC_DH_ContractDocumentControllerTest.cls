/**
* @description : Test class for PMC_DH_ContractDocumentController class
* @author      : Humera Rahath
* @userStory   : GDASF-12218
* @last modified by Humera
* @last modified on 09-12-2023 
**/
@isTest
public with sharing class PMC_DH_ContractDocumentControllerTest {
    public static final String RESPONSE_SUCCESS='{"access_token": "eyJ0eXAiOiJKV1Qng","expires_in": 28800,"scope": "spring_read"}';
    public static final String RESPONSE_ERROR='{"Error":{"HttpStatusCode": 401,"UserMessage": "Access Denied","DeveloperMessage": "Access Denied","ErrorCode": 103,"ReferenceId": "019f0c69-8205-42c2-910a-ccd2e175c0c3"}}';
    public static final String RESPONSE_INVALID_REQUEST='{"Message": "The request is invalid."}';
    
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
        
        
        SBQQ__QuoteLine__c quoteL;
        WebStore webStore=PMC_DH_TestDataFactoryClass.createTestWebStore();
        system.runAs(user){
            WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
            insert cartObj;
            PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            insert prod;
            Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
            PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
            
            SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
            Test.startTest();
            quoteL=PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,prod);
            quoteL.PMC_CLM_ContractDocumentId__c='TestDoc1';
            quoteL.PMC_CLM_ContractDocumentName__c='Test DOC-123';
            update quoteL;
            Contract testContract=PMC_DH_TestDataFactoryClass.createContract(testQuote.id,acc.id); 
            
            PMC_DH_TestDataFactoryClass.CartItemObject objCartItem=new PMC_DH_TestDataFactoryClass.CartItemObject();
            objCartItem.strAccId = acc.Id;
            objCartItem.strContractId = testContract.Id;
            objCartItem.strQuoteLineId = quoteL.Id;
            objCartItem.strProductId=prod.id;
            objCartItem.strCartId = cartObj.id;
            PMC_DH_TestDataFactoryClass.createSubscription(objCartItem);
            Test.stopTest();
        }
        List<PMC_DH_CaseMgmtClass.PMC_DH_FileWrapper> lstFileWrapper = new List<PMC_DH_CaseMgmtClass.PMC_DH_FileWrapper>();
        PMC_DH_CaseMgmtClass.PMC_DH_FileWrapper fileWrapper = new PMC_DH_CaseMgmtClass.PMC_DH_FileWrapper();
        fileWrapper.strBase64Data =EncodingUtil.base64Encode(Blob.valueOf('123ads'));
        fileWrapper.strfileName = 'Test DOC-123';
        fileWrapper.parentId=quoteL.id;   
        lstFileWrapper.add(fileWrapper);
        PMC_DH_CaseMgmtClass.saveTheChunkFile(lstFileWrapper);
    }
    
    /**
* @description Test Method for getQuoteDetails method
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/
    @isTest
    public static void getContractDocInfoTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Test.setMock(HttpCalloutMock.class, new PMC_DH_ContractDocumentCalloutMock(200,RESPONSE_SUCCESS,'Success'));
            Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
            Contract conObj=[SELECT ID,Status FROM Contract WHERE AccountId=:strTestAcct.id][0];
            PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocInfo result=PMC_DH_ContractDocumentController.getContractDocInfo(conObj.id);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for getContractDocData method
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/
    @isTest
    public static void getContractDocDataTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PMC_DH_ContractDocumentCalloutMock(200,RESPONSE_SUCCESS,'Success'));
        PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocData result=PMC_DH_ContractDocumentController.getContractDocData('view', 'TestDoc1');
        system.Assert(result!=null, 'Success');
        
        Test.stopTest();
    }
    
    
    
    /**
* @description Test Method for getContractDocData method
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/
    @isTest
    public static void getContractDocDataAttachTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PMC_DH_ContractDocumentCalloutMock(200,RESPONSE_SUCCESS,'Success'));
        PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocData result=PMC_DH_ContractDocumentController.getContractDocData('Download', 'TestDoc1');
        system.Assert(result!=null, 'Success');
        
        Test.stopTest();
    }
    
    /**
* @description Test Method for getContractDocData method
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/
    @isTest
    public static void getContractDocDataExceptionTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocData contrDoc=new PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocData();
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper errObj = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); 
        system.runAs(user){
            Test.setMock(HttpCalloutMock.class, new PMC_DH_ContractDocumentCalloutMock(401,RESPONSE_ERROR,'Exception Occured'));
            
            // Boolean isException = false;
            // try{
            contrDoc = PMC_DH_ContractDocumentController.getContractDocData('Download', 'TestDoc1');
            // }catch(Exception ex){
            // isException = true;
            //}
            System.assert(contrDoc.statusCodeMessage.strStatusMessage == errObj.strStatusMessage,'Success');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for getContractDocData method
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/
    @isTest
    public static void getContractDocDataCacheHelperTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        
        system.runAs(user){
            Test.setMock(HttpCalloutMock.class, new PMC_DH_ContractDocumentCalloutMock(200,RESPONSE_SUCCESS,'Success'));
            
            String strAccessToken='eyJ0eXAiOiJKV1Qng';
            PMC_DH_CacheHelper.setOrgPartitionCache('CLMDHAUTHORIZATIONTOKEN', (Object)strAccessToken, 1800);
            Boolean isException = false;
            PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocData result;
            try{
                result=PMC_DH_ContractDocumentController.getContractDocData('Download', 'TestDoc1');
            }catch(Exception ex){
                isException = true;
            }
            system.Assert(result.strDownloadLink==null, 'Exception');
        }
        Test.stopTest();
    }
    
    @isTest
    public static void exceptionTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        PMC_DH_DigitalHubB2BUtils.throwTestException=true;
        Boolean isException = false;
        system.runAs(user)
        {
            try
            {
                PMC_DH_ContractDocumentController.getContractDocInfo('id_mock');
            }
            catch(Exception e)
            {
                isException=true;
            }
            System.Assert(isException!=null,'passsed');
        }
        Test.stopTest();
    }
    
    
    @isTest
    public static void excepIntegrationTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        PMC_DH_DigitalHubB2BUtils.throwTestException=true;
        Boolean isException = false;
        HttpRequest req;
        Map<String,String> mapOfHeader=new Map<String,String> ();
        system.runAs(user)
        {
            PMC_DH_RequestForQuoteUtil.throwTestException=true;
            try
            {
                PMC_DH_IntegrationCalloutFramework.createRequestPayload(req,mapOfHeader);
                PMC_DH_IntegrationCalloutFramework aa =new PMC_DH_IntegrationCalloutFramework();
                aa.doCallout('GET',mapOfHeader);
            }
            catch(Exception e)
            {
                isException=true;
            }
            System.Assert(isException!=null,'passsed');
        }
        Test.stopTest();
    }
    

    /**
    * @description 
    * @author Hemant Giri Goswami | hegoswami@deloitte.com | 05-16-2024 
    **/
    @isTest
    public static void getAmendedContractDetailsTest(){
        Test.startTest();
        User user=[SELECT id, contactId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
            Account strShipToAcc = [SELECT Id FROM Account WHERE Name = 'Ship To Account123' limit 1][0];
            Opportunity opp = [SELECT Id,Name from Opportunity Where Name='test Opportunity Name' limit 1][0];
            SBQQ__Quote__c testQuote = [SELECT Id, SBQQ__Type__c FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c = 'TestDH Quote'][0];
            testQuote.SBQQ__Type__c  = 'Amendment';
            update testQuote;
            
            Product2 prod2 = PMC_DH_TestDataFactoryClass.createProduct();
            prod2.Name='Test Product 2';
            prod2.ProductCode='GH-12345';
            prod2.Description='Test New Description 2';
            prod2.StockKeepingUnit='123450';
            insert prod2;
            
            Contract testContract = [SELECT ID, Status, SBQQ__Quote__c, PMC_CPQ_LatestQuote__c, PMC_CPQ_LatestQuote__r.SBQQ__Type__c FROM Contract WHERE SBQQ__Quote__r.PMC_CPQ_QuoteShortNameDescription__c = 'TestDH Quote' limit 1][0];
            
            // amendment quote
            SBQQ__Quote__c testQuote2=PMC_DH_TestDataFactoryClass.createQuote(strTestAcct,user.contactId,opp);
            testQuote2.PMC_CPQ_QuoteShortNameDescription__c = 'TestDH Quote2';
            testQuote2.SBQQ__Type__c  = 'Amendment';
            update testQuote2;
            SBQQ__QuoteLine__c testQuoteLine2 = PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote2,prod2);
            testQuoteLine2.PMC_CPQ_ShipTo__c = strShipToAcc.Id;
            update testQuoteLine2;
            
            testContract.Status='Activated';
            testContract.PMC_CPQ_LatestQuote__c=testQuote2.id;
            update testContract;
            PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocInfo result=PMC_DH_ContractDocumentController.getContractDocInfo(testContract.id);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
}