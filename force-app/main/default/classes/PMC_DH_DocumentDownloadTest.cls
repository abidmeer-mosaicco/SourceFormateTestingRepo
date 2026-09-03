/**
* @description : Test class for PMC_DH_DocumentListViewController
* @author      : Humera Rahath
* @userStory   : GDASF-463
* @last modified by Lohitha
* @last modified on 01-25-2024
**/
@isTest
public with sharing class PMC_DH_DocumentDownloadTest {
    public static final String RESPONSE_SUCCESS='{"objData":{"strStatusCode":"S","strData":"JVBERi0xLjYNJeLjz9MNCjIwIDAgb2JqC","strKey":"0085001395000001","strMessage":"Base64 string generated sucessfully"}}';
    public static final String RESPONSE_ERROR='{"objData":{"strStatusCode":"E","strData":"","strKey":"","strMessage":"Error while processing"}}';
    
    /**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* @param: none
* @return: void
* @author Humera 
*/
    @testSetup  
    static void setup()
    {
        Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
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
        Id lstPermSet4=[select id from PermissionSet where Name ='PMC_DH_CR_TransactionLogs'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet4);
    }
    /**
* @description Test Method for getDocDownload
* @param: none
* @return: void
* @author Humera
* 
*/
    @isTest
    public static void getDocDownloadTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Test.setMock(HttpCalloutMock.class, new PMC_DH_DocumentMock(200,RESPONSE_SUCCESS,'Success'));
            PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper objData=new PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper();
            objData.strDocumentCode='COA';
            objData.strDeliveryNumber='85001752';
            objData.strItemNumber='85001752_000001';
            PMC_DH_DocumentResponseWrapper result = PMC_DH_DocumentDownloadController.getDocDownload(objData);
            PMC_DH_DocumentResponseWrapper res=new PMC_DH_DocumentResponseWrapper();
            res.objData=result.objData;
            res.objData.strStatusCode=result.objData.strStatusCode;
            res.objData.strData=result.objData.strData;
            res.objData.strMessage=result.objData.strData;
            system.Assert(result!=null, 'Success');
        }
        Test.StopTest();
    }
    /**
* @description Test Method for getDocDownload
* @param: none
* @return: void
* @author Humera
* 
*/
    @isTest
    public static void getDocDownloadTestBOL()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Test.setMock(HttpCalloutMock.class, new PMC_DH_DocumentMock(200,RESPONSE_SUCCESS,'Success'));
            PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper objData=new PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper();
            objData.strDocumentCode='BOL';
            objData.strDeliveryNumber='85001752';
            PMC_DH_DocumentResponseWrapper result = PMC_DH_DocumentDownloadController.getDocDownload(objData);
            system.Assert(result!=null, 'Success');
        }
        Test.StopTest();
    }

    /**
* @description Test Method for getDocDownload
* @param: none
* @return: void
* @author Humera
* 
*/
    @isTest
    public static void getDocDownloadTestINV()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Test.setMock(HttpCalloutMock.class, new PMC_DH_DocumentMock(200,RESPONSE_SUCCESS,'Success'));
            PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper objData=new PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper();
            objData.strDocumentCode='INV';
            objData.strBillingDocNumber='85001752';
            PMC_DH_DocumentResponseWrapper result = PMC_DH_DocumentDownloadController.getDocDownload(objData);
            system.Assert(result!=null, 'Success');
        }
        Test.StopTest();
    }

    /**
* @description Test Method for getDocDownload
* @param: none
* @return: void
* @author Humera
* 
*/
    @isTest
    public static void getDocDownloadTestException()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Boolean isException=false;
            PMC_DH_DocumentResponseWrapper result;
            try{
            PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper objData=new PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper();
            objData.strDocumentCode='INV';
             result = PMC_DH_DocumentDownloadController.getDocDownload(objData);
            }
            catch(Exception ex){
               isException=true; 
            }
            //System.debug('Result: ' + result);
            system.Assert(result!=null, 'Success');
        }
        Test.StopTest();
    }
    /**
* @description Test Method for getDocDownload
* @param: none
* @return: void
* @author Lohitha
* 
*/
        @isTest
    public static void getDocDownloadTestStatusCode201() {
        Test.startTest();
        User user = [SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' LIMIT 1];
        system.runAs(user) {
            Test.setMock(HttpCalloutMock.class, new PMC_DH_DocumentMock(201, RESPONSE_SUCCESS, 'Success'));
            PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper objData = new PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper();
            objData.strDocumentCode = 'COA';
            objData.strDeliveryNumber = '85001752';
            objData.strItemNumber = '85001752_000001';
            PMC_DH_DocumentResponseWrapper result = PMC_DH_DocumentDownloadController.getDocDownload(objData);
            system.assert(result != null, 'Success');
        }
        Test.stopTest();
    }
    
        /**
* @description Test Method for getDocDownload
* @param: none
* @return: void
* @author Lohitha
* 
*/
            @isTest
    public static void getDocDownloadTestStatusCode202() {
        Test.startTest();
        User user = [SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' LIMIT 1];
        system.runAs(user) {
            Test.setMock(HttpCalloutMock.class, new PMC_DH_DocumentMock(202, RESPONSE_SUCCESS, 'Success'));
            PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper objData = new PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper();
            objData.strDocumentCode = 'COA';
            objData.strDeliveryNumber = '85001752';
            objData.strItemNumber = '85001752_000001';
            PMC_DH_DocumentResponseWrapper result = PMC_DH_DocumentDownloadController.getDocDownload(objData);
            system.assert(result != null, 'Success');
        }
        Test.stopTest();
    }
}