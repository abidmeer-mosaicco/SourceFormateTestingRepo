/**
* @description : Test class for PMC_DH_RequestForQuoteUtil
* @author      : Rohan Undale
* @userStory   : GDASF-20218
* @last modified by Rohan Undale
* @last modified on 03-04-2024
**/
@isTest
public with sharing class PMC_DH_RequestForQuoteUtilTest {
    /**
    * @description Test Method for getQuoteDetails method
    * @param: none
    * @return: void
    * @author Rohan
    */
    @isTest
    public static void throwTestIntegrationExceptionForTest(){
        Test.startTest();
        //User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        //system.runAs(user){
        Boolean exceptionOccurred = false;
        try{
            PMC_DH_RequestForQuoteUtil.throwTestException = true;
            PMC_DH_RequestForQuoteUtil.throwTestIntegrationExceptionForTest();
        }catch(Exception ex){
            exceptionOccurred = true;
        }
        System.assert(exceptionOccurred, 'An Exception was not thrown');
        //}
        Test.stopTest();
    }
     /**
    * @description Test Method for insertOpportunityShare method
    * @param: none
    * @return: void
    * @author Lakshmi
    */
     @isTest
    public static void throwTestIntegrationExceptionForTest2(){
        Test.startTest();
        //User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        //system.runAs(user){
        
            PMC_DH_RequestForQuoteUtil.throwTestException = true;
            
            OpportunityShare objOppShare = new OpportunityShare();
            objOppShare.OpportunityId = NULL;
            objOppShare.UserOrGroupId = UserInfo.getUserId();
            objOppShare.OpportunityAccessLevel = PMC_DH_ConstantClass.EDIT;
            objOppShare.RowCause = Schema.OpportunityShare.RowCause.Manual;
            Boolean boolIsShared = PMC_DH_RequestForQuoteUtil.insertOpportunityShare(objOppShare);
        
        
        	System.assert(boolIsShared==False,'An Exception was not thrown');
        //}
        Test.stopTest();
    }
}