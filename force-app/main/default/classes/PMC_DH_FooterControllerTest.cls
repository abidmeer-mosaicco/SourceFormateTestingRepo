/* Class Name      :PMC_DH_FooterControllerTest
* Description      :Test Class for PMC_DH_FooterController
* Created By       :Krishan
* Created On       :2023-April-13 
*/
@IsTest
public with sharing class PMC_DH_FooterControllerTest { 

    @isTest
    public static void getFooterTest(){
        test.startTest();
        PMC_DH_FooterDetailsWrapper result = PMC_DH_FooterController.getNavigationMenuItems(PMC_DH_FooterController.USER_PROFILE_MENU,PMC_DH_FooterController.PUBLISHED_STATE); 
        System.Assert(result!=null, 'Success');
        test.stopTest();
    }
    @isTest
    public static void getFooterTest1(){
        Test.startTest();
        PMC_DH_FooterDetailsWrapper footerWrapper = new PMC_DH_FooterDetailsWrapper();
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper errObj = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); 
        Boolean exceptionOccurred;
            try{
                PMC_DH_FooterController.throwUsersTestException = true;
                footerWrapper = PMC_DH_FooterController.getNavigationMenuItems(PMC_DH_FooterController.USER_PROFILE_MENU,PMC_DH_FooterController.PUBLISHED_STATE);
            }catch(exception e){
                exceptionOccurred=true;
            }
            System.assert(footerWrapper.statusCodeMessage.strStatusMessage == errObj.strStatusMessage, 'An Exception was not thrown');
        
        test.stopTest();
    }    
   
}