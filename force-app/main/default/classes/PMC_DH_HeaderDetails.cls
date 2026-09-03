/**
* @description : class for Navigation menu in Header
* @author      : Humera Rahath
* @userStory   : GPDH-299 & GPDH - 185 & GPDH - 296
* @last modified on  : 03-01-2024
* @last modified by  : Humera Rahath
* */
public without sharing class PMC_DH_HeaderDetails {
    
    
    /*************************************************************************
* @method Name  : getHeaderDetails
* @description  : Method to assign the navigation menu details in wrapper class
* @param       strEffectiveAccountId
* @return       : PMC_DH_HeaderDetailsWrapper
*****************************************************************************/
    @AuraEnabled(cacheable=true)
    public static PMC_DH_HeaderDetailsWrapper getHeaderDetails(String strEffectiveAccountId){
        String strUserId=userInfo.getUserId();
        Boolean boolHasPermission;
        PMC_DH_HeaderDetailsWrapper headerWrapper = new PMC_DH_HeaderDetailsWrapper();
        
        List<PMC_DH_HeaderDetailsWrapper.MyAccountNavItemsClass> lstAccNav =new List<PMC_DH_HeaderDetailsWrapper.MyAccountNavItemsClass>();
        List<PMC_DH_HeaderDetailsWrapper.NavigationMenuItemsClass> lstNavMenu=new List<PMC_DH_HeaderDetailsWrapper.navigationMenuItemsClass>();
        List<PMC_DH_FeatureVisibility__mdt> lstNavData=new List<PMC_DH_FeatureVisibility__mdt>();
        PMC_DH_HeaderDetailsWrapper.MyAccountNavItemsClass accNav;
        
        try{
            
            PMC_DH_HeaderDetailsWrapper.UserDetailsClass userData=getUserDetail(strUserId);
            lstNavData =PMC_DH_PermissionsFrameworkUtilClass.callFeatureMdt(PMC_DH_ConstantClass.NAVIGATION_TYPE);
            //fetching the list of custom permissions concerned to the user of type Navigation
            List<String> lstCustomPermission=PMC_DH_PermissionsFrameworkUtilClass.getFeatureVisibilityNavigationData(PMC_DH_ConstantClass.NAVIGATION_TYPE,lstNavData);
            //to fetch custom permission for Cart
            boolHasPermission = FeatureManagement.checkPermission(PMC_DH_ConstantClass.CART_CUSTOM_PERMISSION);
            //fetch the navigation menu through ConnectApi
            List<ConnectApi.NavigationMenuItem> navMenu = getNavigationMenuItems(PMC_DH_ConstantClass.NAVIGATION);
            //Iterating over navigation menu items

            String userProfileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;

            for(ConnectApi.NavigationMenuItem navMenuItem : navMenu){
                //check for Business icon
                if(navMenuItem.label==PMC_DH_ConstantClass.ACC_TAB){
                    List<ConnectApi.NavigationMenuItem> navSubMenu=navMenuItem.subMenu;
                    for(ConnectApi.NavigationMenuItem navSub:navSubMenu){
                        accNav = new PMC_DH_HeaderDetailsWrapper.MyAccountNavItemsClass();
                        accNav.strLabel=navSub.Label;
                        accNav.strTarget= navSub.actionValue;
                        accNav.strType=String.valueOf(navSub.actionType);
                        lstAccNav.add(accNav); 
                    }
                }
                //method for Navigation menu in header
                else {
                    List<PMC_DH_HeaderDetailsWrapper.NavigationMenuItemsClass> lstNavMenus = getNavDetails(navMenuItem, lstCustomPermission);

                    if (userProfileName == 'Digital Hub Logistics Manager') { //GSMD-2167
                        for (PMC_DH_HeaderDetailsWrapper.NavigationMenuItemsClass items : lstNavMenus) {
                            if (items.strLabel == 'Home' || items.strLabel == 'Documents' || items.strLabel == 'Documentos') {
                                lstNavMenu.addAll(lstNavMenus);
                            }
                        }
                    } else {
                        lstNavMenu.addAll(lstNavMenus);
                    }

                }
            }
            //assigning data in wrapper
            headerWrapper.userData=userData;
            headerWrapper.myAccountNavItems =lstAccNav;
            headerWrapper.navigationMenuItems=lstNavMenu;
            headerWrapper.langPrefeWrapper=PMC_DH_LanguagePreferenceController.getLanguagePreferences();
            headerWrapper.boolIsCart=boolHasPermission;
            headerWrapper.boolIsSeedZAccess= seedzEligibilityCheck(strEffectiveAccountId,userData.strUserLocation);
            //Cart Testing
            if(boolHasPermission){ //GDASF-21258
                List<WebCart> activeCart=[select id,CurrencyIsoCode,PMC_DH_Account__r.CurrencyIsoCode,LastModifiedDate,CreatedById from webcart where Status=:PMC_DH_ConstantClass.ACTIVE_STATUS and accountId=:strEffectiveAccountId and createdbyId=:UserInfo.getUserId() WITH USER_MODE  LIMIT 1];
                if(!activeCart.isEmpty())
                {
                    /*if(activeCart[0].CurrencyIsoCode!=activeCart[0].PMC_DH_Account__r.CurrencyIsoCode)
                    {
                        //async process to correct the currency of the cart 
                        processCartCurrency(activeCart[0].Id);
                    }*/
                    currencyMisMatchCheck(activeCart);
                }
            }
            headerWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'HeaderDetails'); 
        }
        catch(Exception ex){
            headerWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return headerWrapper;
    }    
    @future
    private static void processCartCurrency(Id webCartId) {
        List<WebCart> wc=[select id,CurrencyIsoCode,PMC_DH_Account__r.CurrencyIsoCode,LastModifiedDate,CreatedById from webcart where Id=:webCartId WITH USER_MODE];
        WebCart objWebCart=new WebCart();
        objWebCart.Id=webCartId;
        objWebCart.CurrencyIsoCode=wc[0].PMC_DH_Account__r.CurrencyIsoCode;
        update as user objWebCart;
        List<CartItem> lstcartItem=new List<CartItem>();
        for (CartItem cartItem :[select id from cartitem where cartid=:webCartId WITH USER_MODE]) {
            CartItem newCartItem=new CartItem();
            newCartItem.Id=cartItem.Id;
            newCartItem.CurrencyIsoCode=wc[0].PMC_DH_Account__r.CurrencyIsoCode;
            lstcartItem.add(newCartItem);
        }
        update as user lstcartItem;
    }
    
    /*************************************************************************
* @method Name  : getNavigationMenuItems
* @description  : Method to fetch NavigationMenuItems using ConnectApi
* @author        Humera
* @param         strNavDevName
* @return       : List<ConnectApi.NavigationMenuItem>
*****************************************************************************/
    public static  List<ConnectApi.NavigationMenuItem> getNavigationMenuItems(String strNavDevName){
        //method to get NetworkId of the logged-in user
        String strNetworkId= Network.getNetworkId();
        List<ConnectApi.NavigationMenuItem> navMenu;
        ConnectApi.PublishStatus publishStatus =ConnectApi.PublishStatus.LIVE;
        ConnectApi.NavigationMenuItemCollection navDetails;
        try{
            if(!Test.isRunningTest()){
                navDetails=ConnectApi.NavigationMenu.getCommunityNavigationMenu(strNetworkId,null,strNavDevName,publishStatus,false, false,null);
            }
            else{
                navDetails=new ConnectApi.NavigationMenuItemCollection();
                String strConnectLabelTestData='testLabel-ActionValue_String';
                ConnectApi.NavigationMenuItemActionType conMenActionType=ConnectApi.NavigationMenuItemActionType.Event;
                List<ConnectApi.NavigationMenuItem> menuItems=new List<ConnectApi.NavigationMenuItem>();
                ConnectApi.NavigationMenuItem navMenuItem=new ConnectApi.NavigationMenuItem();
                ConnectApi.NavigationMenuItem navMenuItem2=new ConnectApi.NavigationMenuItem();
                ConnectApi.NavigationMenuItem navMenuItem3=new ConnectApi.NavigationMenuItem();
                navMenuItem.Label=PMC_DH_ConstantClass.STOREFRONT_CATEGORIES_MENUNAME;
                navMenuItem.actionValue='/category/products/test';
                navMenuItem.actionType=conMenActionType;
                menuItems.add(navMenuItem);
                navMenuItem2.Label=PMC_DH_ConstantClass.ACC_TAB;
                navMenuItem2.actionValue=PMC_DH_ConstantClass.ACC_TAB;
                navMenuItem2.actionType=conMenActionType;
                List<ConnectApi.NavigationMenuItem> lstSubMenu=new List<ConnectApi.NavigationMenuItem>();
                navMenuItem3.Label=PMC_DH_ConstantClass.STOREFRONT_CATEGORIES_MENUNAME;
                navMenuItem3.actionValue=strConnectLabelTestData;
                navMenuItem3.actionType=conMenActionType;
                lstSubMenu.add(navMenuItem3);
                navMenuItem2.subMenu=lstSubMenu;
                menuItems.add(navMenuItem2);
                navDetails.menuItems=menuItems;
                
            }
            navMenu =navDetails.menuItems;
        }
        catch(Exception ex){
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return navMenu;
    }
    
    /*************************************************************************
* @method Name  : getUserDetail
* @description  : Method to fetch the user Details
* @param       strUserId
* @return       : PMC_DH_HeaderDetailsWrapper.UserDetailsClass
*****************************************************************************/
    private static PMC_DH_HeaderDetailsWrapper.UserDetailsClass getUserDetail(String strUserId){
        PMC_DH_HeaderDetailsWrapper.UserDetailsClass userData=new PMC_DH_HeaderDetailsWrapper.UserDetailsClass();
        //Fetching user Details with respect to on logged-in User Id
        List<User> lstUser=PMC_DH_UserUtil.getUserData(strUserId);
        if(!lstUser.isEmpty())
        {
            userData.strUserName=lstUser[0].name;
            userData.strUserLocation=lstUser[0].Country;
        }
        return userData;
    }
    
    /*************************************************************************
* @method Name  : getNavDetails
* @description  : Method to group the navigation menu details in  Map
* @author         Humera
* @param         navMenuItem 
* @param         lstCustomPermission
* @return       :List<PMC_DH_HeaderDetailsWrapper.NavigationMenuItemsClass>
*****************************************************************************/ 
    public static List<PMC_DH_HeaderDetailsWrapper.NavigationMenuItemsClass>  getNavDetails(ConnectApi.NavigationMenuItem navMenuItem,List<String> lstCustomPermission)
    {
        List<PMC_DH_HeaderDetailsWrapper.NavigationMenuItemsClass> lstNavMenu=new List<PMC_DH_HeaderDetailsWrapper.navigationMenuItemsClass>();
        PMC_DH_HeaderDetailsWrapper.navigationMenuItemsClass navItems=new PMC_DH_HeaderDetailsWrapper.navigationMenuItemsClass();
        Map<String,String> getProductsMap=getProductsMap();
        //check if custom permissions matches navigation menu item label
        if(lstCustomPermission.contains(navMenuItem.Label)){
            //For products navigationmenu item
            if((navMenuItem.Label==PMC_DH_ConstantClass.STOREFRONT_CATEGORIES_MENUNAME)||(navMenuItem.Label==PMC_DH_ConstantClass.PRODUCTS_ES)||(navMenuItem.Label==PMC_DH_ConstantClass.PRODUCTS_PT_BR))
            {   
                navItems.strLabel=getProductsMap.get(navMenuItem.Label);    
                String strNavTar=navMenuItem.actionValue;
                List<String> lstCategory =strNavTar.split('/');
                Integer lastIndex = lstCategory.size() - 1;
                /*if (lastIndex >= 0) {
                    lstCategory[lastIndex] =getParentCategoryId() ;
                    navItems.strTarget= String.join(lstCategory, '/');
                }*/
                lastIndexCheck(lastIndex, lstCategory, navItems);
                navItems.strType=String.valueOf(navMenuItem.actionType);
            }
            else{
                navItems.strLabel=navMenuItem.Label;
                navItems.strTarget= navMenuItem.actionValue;
                navItems.strType=String.valueOf(navMenuItem.actionType);
            }
            lstNavMenu.add(navItems);
        }
        return lstNavMenu;
    }
    
    /*************************************************************************
* @method Name  : seedzEligibilityCheck
* @description  : Method to assign the Seedz Points in Wrapper class
* @param     strEffectiveAccountId
* @param     strCountry
* @return    Boolean
*****************************************************************************/
    private static Boolean seedzEligibilityCheck(String strEffectiveAccountId,String strCountry){
        Boolean isSeedzEligibilityCheck = FALSE;
        List<Account> accList = [SELECT Id, PMC_SS_Channel__c FROM Account  Where Id=:strEffectiveAccountId WITH USER_MODE LIMIT 1];
        String  strChannelType  =  (!accList.isEmpty()) ?  accList[0].PMC_SS_Channel__c : '';
        if(strChannelType == PMC_DH_ConstantClass.END_USR && strCountry == PMC_DH_ConstantClass.BRAZIL){
            isSeedzEligibilityCheck = TRUE;
        }
        return isSeedzEligibilityCheck;
        
    }
    
    /*************************************************************************
* @method Name  : getParentCategoryId
* @description  : Method to fetch Parent category ID
* @author       Humera
* @return    String
*****************************************************************************/ 
    private static String getParentCategoryId(){
        
        List<ProductCategory> lstProCategory = [SELECT Id from ProductCategory where Catalog.name=:PMC_DH_ConstantClass.CATALOG_NAME
                                                AND PMC_DH_Category_ID__c =:PMC_DH_ConstantClass.PRODUCTS_MENUNAME WITH SYSTEM_MODE LIMIT 1];
        
        String strParentCategoryId= (!lstProCategory.isEmpty()) ? lstProCategory[0].Id:'';
        return strParentCategoryId;
    }
    
    /*************************************************************************
* @method Name  : getProductsMap
* @description  : Method to create map for products label translation
* @author       Humera
* @return    Map<String,String>
*****************************************************************************/ 
    private static Map<String,String> getProductsMap(){
        Map<String,String> mapProducts=new Map<String,String>();
        mapProducts.put(PMC_DH_ConstantClass.STOREFRONT_CATEGORIES_MENUNAME,PMC_DH_ConstantClass.PRODUCTS_MENUNAME);
        mapProducts.put(PMC_DH_ConstantClass.PRODUCTS_ES,PMC_DH_ConstantClass.PRODUCTS_ES);
        mapProducts.put(PMC_DH_ConstantClass.PRODUCTS_PT_BR,PMC_DH_ConstantClass.PRODUCTS_PT_BR);
        return mapProducts ;
    }

    /*************************************************************************
* @method Name  : currencyMisMatchCheck
* @description  : to call the future method when curency mismatch b/w account and webcart
* @author       Sugunakar Routhu
* @param     activeCart
*/

    private static void currencyMisMatchCheck(List<WebCart> activeCart){
        if(activeCart[0].CurrencyIsoCode!=activeCart[0].PMC_DH_Account__r.CurrencyIsoCode){
            //async process to correct the currency of the cart 
            processCartCurrency(activeCart[0].Id);
        }
    }

    /*************************************************************************
* @method Name  : lastIndexCheck
* @description  : to check the latIndex check
* @author       Sugunakar Routhu
* @param     lastIndex
* @param     lstCategory
* @param     navItems
*/

    private static void lastIndexCheck(Integer lastIndex, List<String> lstCategory, PMC_DH_HeaderDetailsWrapper.navigationMenuItemsClass navItems){
        if (lastIndex >= 0) {
            lstCategory[lastIndex] =getParentCategoryId() ;
            navItems.strTarget= String.join(lstCategory, '/');
        }
    }
}