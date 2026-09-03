/**
* @description : Test class for PMC_DH_GuestLandingPageController
* @author      : Ajeet
* @last modified by 
* @last modified on 
**/
@IsTest
public class PMC_DH_GuestLandingPageTest {
    /**
* @description Test Method for getLandingPageData
* @param: none
* @return: void
*/
    @isTest
    public static void getLandingPageDataTestEN(){
        Test.startTest();
            PMC_DH_GuestLandingPageController.LandingPageWrapper result = PMC_DH_GuestLandingPageController.getLandingPageData('English');
            system.Assert(result!=null, 'Success');
        Test.stopTest();
    }   
    
    @isTest
    public static void getLandingPageDataTestSP(){
        Test.startTest();
            PMC_DH_GuestLandingPageController.LandingPageWrapper result = PMC_DH_GuestLandingPageController.getLandingPageData('Spanish');
            system.Assert(result!=null, 'Success');
        Test.stopTest();
    }
    
    @isTest
    public static void getLandingPageDataTestPO(){
        Test.startTest();
            PMC_DH_GuestLandingPageController.LandingPageWrapper result = PMC_DH_GuestLandingPageController.getLandingPageData('Portuguese');
            system.Assert(result!=null, 'Success');
        Test.stopTest();
    }
    
    @isTest
    public static void getLandingPageDataExceptionTest(){
        Test.startTest();
        	PMC_DH_DigitalHubB2BUtils.throwTestException = true;
            PMC_DH_GuestLandingPageController.LandingPageWrapper result = PMC_DH_GuestLandingPageController.getLandingPageData('Portuguese');
            system.Assert(result!=null, 'Success');
        Test.stopTest();
    }
}