/**
* @description       : Controller Class for Footer Navigation Component
* @author            : @Krishan Jangir
* @group             : 
* @last modified on  : 02-27-2024
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
// added with sharing
public without sharing class PMC_DH_FooterController {
    public static final string USER_PROFILE_MENU='DH_Footer_Menus';
    public static final string PUBLISHED_STATE ='Live';
    public static boolean throwUsersTestException = false;
    public static final String TEST_EXCEPTION_MESSAGE = 'Test Error';
    
    
    /**
* @description   : fetches NavigationMenuItems for footer
* 
* @param menuName
* @param publishedState
* 
* @return        : PMC_DH_FooterDetailsWrapper
*
* @author        : @Krishan jangir
* @date          : 04-11-2023
*/
    @AuraEnabled(cacheable=true)
    public static PMC_DH_FooterDetailsWrapper getNavigationMenuItems(String menuName,String publishedState) {
        String strUserId=userInfo.getUserId();
        PMC_DH_FooterDetailsWrapper footerWrapper = new PMC_DH_FooterDetailsWrapper();
        PMC_DH_FooterDetailsWrapper.UserDetailsClass userData = new PMC_DH_FooterDetailsWrapper.UserDetailsClass();
        List<PMC_DH_FooterDetailsWrapper.MyAccountNavItemsClass> lstNavItems = new List<PMC_DH_FooterDetailsWrapper.MyAccountNavItemsClass>();
        List<ConnectApi.NavigationMenuItem> lstNavMenu=new List<ConnectApi.NavigationMenuItem>();
                try{
            getException();
            if (menuName!=null) {
                //method to fetch user details
                List<User> lstUser=PMC_DH_UserUtil.getUserData(strUserId);   
                if(!lstUser.isEmpty())
                {
                    userData.strUserLocation=lstUser[0].Country; 
                                    }
                //GDASF-19911
                if(!Test.isRunningTest())
                {
                //method to fetch navigationmenu through ConnectApi
                lstNavMenu=PMC_DH_HeaderDetails.getNavigationMenuItems(menuName);
                }
                else
                {   String strConnectLabelTestData='testLabel-ActionValue_String';
                    ConnectApi.NavigationMenuItemActionType conMenActionType;
                    ConnectApi.NavigationMenuItem navMenuItem=new ConnectApi.NavigationMenuItem();
                    navMenuItem.Label=strConnectLabelTestData;
                    navMenuItem.actionValue=strConnectLabelTestData;
                    navMenuItem.actionType=conMenActionType;
                    lstNavMenu.add(navMenuItem);
                }
//iterating over navigation menu list 
                for(ConnectApi.NavigationMenuItem navMenuItem : lstNavMenu){
                    PMC_DH_FooterDetailsWrapper.MyAccountNavItemsClass navObj = new PMC_DH_FooterDetailsWrapper.MyAccountNavItemsClass();
                    navObj.strLabel = navMenuItem.Label;
                    navObj.strTarget = navMenuItem.actionValue;
                    navObj.strType = String.valueOf(navMenuItem.actionType);
                    lstNavItems.add(navObj);
                }	
            }
//assigning the data in wrapper
            footerWrapper.userData = userData;
            footerWrapper.myAccountNavItems =lstNavItems;
            footerWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'FooterDetail');
        }
        catch(Exception ex){
            footerWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); 
             PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return footerWrapper;
    }
    private static void getException(){
        if (throwUsersTestException && Test.isRunningTest()) {
                throw new AuraHandledException(TEST_EXCEPTION_MESSAGE);
            }
    }
    
}