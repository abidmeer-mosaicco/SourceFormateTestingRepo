/**
* @description : Test class for PMC_DH_ProductSuggestionsClass
* @author      : Humera Rahath
* @userStory   : GDASF-659
**/
@isTest
public with sharing class PMC_DH_ProductSuggestionsClassTest {
    @testSetup  static void setup()
    {
        Account acc=PMC_DH_TestDataFactoryClass.createTestAccount();
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Digital Hub Super Buyer' LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
        
    }
    
    @isTest
    public static void getProductSuggestionsExceptionTest(){
        test.startTest();
        Boolean exceptionOccurred;
        try
        {
            PMC_DH_ProductSuggestionsClass.boolHandleException=true;
            User user=[SELECT id from User WHERE Username = 'demouser@test.com.testuser'];
            system.runAs(user)
            {
                String strTestAcct=[SELECT id FROM Account WHERE Name='Test Account'][0].Id;
                PMC_DH_ProductSuggestionsClass.getProductSuggestions(PMC_DH_ConstantClass.PRODUCT_SUGGESTION_VALUE, strTestAcct);
            }
        }
        catch(Exception ex)
        {
            exceptionOccurred=true;
        }
        System.assert(exceptionOccurred, 'An Exception was not thrown');
        test.stopTest();
    }
    @isTest
    public static void getProductSuggestionsSuccessTest(){
        test.startTest();
        try{
            PMC_DH_ProductSuggestionsClass.boolHandleException=false;
            User user=[SELECT id from User WHERE Username = 'demouser@test.com.testuser'];
            system.runAs(user)
            {
                String strTestAcct=[SELECT id FROM Account WHERE Name='Test Account'][0].Id;
                //List<PMC_DH_ProductSuggestionsClass.ProductSuggestionWrapper> lstResult=PMC_DH_ProductSuggestionsClass.getProductSuggestions(PMC_DH_ConstantClass.PRODUCT_SUGGESTION_VALUE, strTestAcct);
                //System.Assert(lstResult!=null, 'Success');
                
                // added as part of GDASF-19642
                PMC_DH_ProductSuggestionsClass.PMC_DH_ProductSuggestionListWrapper wrpResult=PMC_DH_ProductSuggestionsClass.getProductSuggestions(PMC_DH_ConstantClass.PRODUCT_SUGGESTION_VALUE, strTestAcct);
                System.Assert(wrpResult.lstProdSuggestions != null, 'Success');
            }
        }
        catch(Exception ex)
        {
            throw new AuraHandledException(ex.getMessage());
        }
        test.stopTest();
    }
}