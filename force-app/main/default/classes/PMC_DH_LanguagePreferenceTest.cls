/**
 * @description Test Class for PMC_DH_LanguagePreferenceController
 * @author Hemant giri goswami
 * @since 09-25-2023
 * */

@isTest
public with sharing class PMC_DH_LanguagePreferenceTest {
/**
 * @description test data setup
 * @author Hemant
 * */
    @testSetup 
     static void testSetup(){
           Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
          Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);       
        
    }
    
    
    @isTest
    public static void getLanguagePreferencesTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        System.runAs(user)
        {
        PMC_DH_LanguagePreferenceController.LanguagePreferenceWrapper result=new PMC_DH_LanguagePreferenceController.LanguagePreferenceWrapper();
        result=PMC_DH_LanguagePreferenceController.getLanguagePreferences();
        System.assertEquals(result!=null,true,'Success');
        }
        Test.stopTest();
    }
    
    @isTest
    public static void updateUserLocaleTest()
    {	//String strResult;
     Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        System.runAs(user)
        {
            //strResult=PMC_DH_LanguagePreferenceController.updateUserLocale('Portuguese');
            //System.assertEquals(strResult!=null,true,'Success');
            //changes as part of GDASF-19642
            PMC_DH_LanguagePreferenceController.PMC_DH_UpdateUserLocaleWrapper wrpResult = PMC_DH_LanguagePreferenceController.updateUserLocale('Portuguese');
            System.assertEquals(wrpResult.strResultUrl != null,true,'Success');
            //end of changes as part of GDASF-19642
        }
     Test.stopTest();
        
    }
    
     @isTest
    public static void updateUserLocaleExceptionTest()
    {	
        String strResult;
        PMC_DH_LanguagePreferenceController.PMC_DH_UpdateUserLocaleWrapper wrpResult; //changes as part of GDASF-19642
     Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        System.runAs(user)
        {
            try{
                //strResult=PMC_DH_LanguagePreferenceController.updateUserLocale('Hindi');
                wrpResult = PMC_DH_LanguagePreferenceController.updateUserLocale('Hindi'); //changes as part of GDASF-19642
            }
            catch(Exception ex){
                strResult='fail';
            }
            System.assertEquals(strResult=='fail',true,'Success');
        }
     Test.stopTest();
        
    }
}