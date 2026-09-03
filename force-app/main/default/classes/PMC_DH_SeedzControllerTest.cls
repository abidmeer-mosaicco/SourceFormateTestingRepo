/**
* @description : Test class for PMC_DH_SeedzController
* @author      : Humera Rahath
* @userStory   : GDASF-523
* @last modified by Humera
* @last modified on 08-30-2023
**/
@isTest
public with sharing class PMC_DH_SeedzControllerTest {
    public static final String RESPONSE_SUCCESS='{"token":"eyJhbGciOiJIUzI1NiIsInI","code":200,"message":"Sucesso"}';
    public static final String RESPONSE_ERROR='{"returnValue": ""{"code":401,"message":"Invalid access data. Try again."}"" }';
    public static final String RESPONSE_INVALID_REQUEST='{"Message": "The request is invalid."}';
    public static final String RESPONSE_POINTS_SUCCESS='{"code":200,"message":"Sucesso.","balance":12356}';
    public static final String RESPONSE_POINTS_ERROR='{"code":400,"message":"User has no association with the partner."}';
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
* @description Test Method for getSeedzPoints
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/
    @isTest
    public static void getSeedzPointsTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Test.setMock(HttpCalloutMock.class, new PMC_DH_SeedzCalloutMock(200,RESPONSE_SUCCESS,'Success'));
           PMC_DH_SeedzController.PMC_DH_GetSeedzWrapper result = PMC_DH_SeedzController.getSeedzPoints();
             system.Assert(result!=null, 'Success');
    }
        Test.StopTest();
    }
    
     /**
* @description Test Method for getSeedzPoints method
* @param: none
* @return: void
* @author Humera
* 
*/
    @isTest
    public static void getSeedzExceptionTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        
        system.runAs(user){
            Test.setMock(HttpCalloutMock.class, new PMC_DH_SeedzCalloutMock(401,RESPONSE_ERROR,'Error'));
            
            Boolean isException = false;
            try{
                PMC_DH_SeedzController.getSeedzPoints();
            }catch(Exception ex){
                isException = true;
            }
            System.assert(!isException,'Success');
        }
        Test.stopTest();
    }
/**
* @description Test Method for cache helper method
* @param: none
* @return: void
* @author Humera
* 
*/
    @isTest
    public static void getSeedzCacheHelperTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        
        system.runAs(user){
            Test.setMock(HttpCalloutMock.class, new PMC_DH_SeedzCalloutMock(200,RESPONSE_SUCCESS,'Success'));
            
            PMC_DH_CacheHelper.setCachePartitionCache('CPFNUMBER',12356);
            Boolean isException = false;
            PMC_DH_SeedzController.PMC_DH_GetSeedzWrapper result;
            try{
                result=PMC_DH_SeedzController.getSeedzPoints();
            }catch(Exception ex){
                isException = true;
            }
            system.Assert(result!=null, 'success');
        }
        Test.stopTest();
    } 
    /**
* @description Test Method for Exception handling 
* @param: none
* @return: void
* @author Humera
* 
*/
    @isTest
    public static void getSeedzExceptionTest1(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        
        system.runAs(user){
            Test.setMock(HttpCalloutMock.class, new PMC_DH_SeedzCalloutMock(400,RESPONSE_POINTS_ERROR,'Error'));
            Boolean isException = false;
            PMC_DH_SeedzController.PMC_DH_GetSeedzWrapper result;
            try{
                result=PMC_DH_SeedzController.getSeedzPoints();
                PMC_DH_Validation dhValidation = new PMC_DH_Validation();
                System.assertEquals(true, dhValidation.boolDHTestSetup, 'Validation Matched');
            }catch(Exception ex){
                isException = true;
            }
            system.Assert(result!=null, 'Exception');
        }
        Test.stopTest();
    } 
    
    /**
* @description Test Method for Exception handling 
* @param: none
* @return: void
* @author Hemant
* 
*/
@isTest
public static void getSeedzPointsCalloutException(){
    Test.startTest();
    User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
    
    system.runAs(user){
        Test.setMock(HttpCalloutMock.class, new PMC_DH_SeedzCalloutMock(400,RESPONSE_POINTS_ERROR,'Error'));
        Boolean isException = false;
        PMC_DH_SeedzController.PMC_DH_GetSeedzWrapper result;
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestException=TRUE;
            result=PMC_DH_SeedzController.getSeedzPoints();
            
            }catch(Exception ex){
                isException = true;
            }
            system.Assert(result!=null, 'Exception');
        }
        Test.stopTest();
    }    

}