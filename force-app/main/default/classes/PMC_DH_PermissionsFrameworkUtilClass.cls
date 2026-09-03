/**
* @description : class for Feature Visibility
* @author      : Humera Rahath
* @userStory   : GPDH - 296 & GPDH- 163 & GPDH - 157 
* @last modified on 05-26-2023
* @last modified by Ajeet
* */
public without sharing class PMC_DH_PermissionsFrameworkUtilClass {
    private static final string REBATES_LABEL = 'PMC_DH_Rebates';
    private static final string LANG_EN = 'en_US';
    
    /**
* @description 
* @author Hemant Giri Goswami | hegoswami@deloitte.com | 02-28-2024 
* @param strType 
* @param lstNavData 
* @return List<String> 
**/
    public static List<String> getFeatureVisibilityNavigationData(String strType,List<PMC_DH_FeatureVisibility__mdt> lstNavData )
    {
        List<String> lstMetaData=new  List<String>();
        Map<String,List<String>> mapCustPer=new  Map<String,List<String>>();
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            for(PMC_DH_FeatureVisibility__mdt feature:lstNavData){
                List<String> lstValues=feature.PMC_DH_Value__c.split(',');
                if(!mapCustPer.containsKey(feature.DeveloperName)){ 
                    mapCustPer.put(feature.DeveloperName,new List<String>());
                }
                
                mapCustPer.get(feature.DeveloperName).addAll(lstValues);
            }
            lstMetaData=getlstData(mapCustPer);
        }
        catch(Exception ex)
        {
            PMC_ErrorLogClass.processException(ex);
            throw new AuraHandledException(ex.getMessage());
        }
        return lstMetaData;
    }
    
    /**
* @description 
* @author Hemant Giri Goswami | hegoswami@deloitte.com | 02-28-2024 
* @param mapNavData 
* @return List<String> 
**/
    public static List<String> getlstData(Map<String,List<String>> mapNavData){
        List<String> lstDataValues=new List<String>();
        Boolean boolHasPermission;
        if(mapNavData!=null)
        {
            for(String cust:mapNavData.keyset())
            {
                List<String> lstData=new  List<String>();
                boolHasPermission = FeatureManagement.checkPermission(cust);
                if(boolHasPermission)
                {
                    lstData=mapNavData.get(cust);
                }
                lstDataValues.addAll(lstData);
            } 
        }
        return lstDataValues;
    }
    
    private static  void  getMapofPermissionTabValue(Map<String,String> mapCustomPermissionTabValue,List<PMC_DH_FeatureVisibility__mdt> lstNavData)
    {   
        List<String> lstVal;
        for(PMC_DH_FeatureVisibility__mdt mdtInstance:lstNavData)
        {  
            lstVal=mdtInstance.PMC_DH_Value__c.split(',');
            for(String strInstance:lstVal)
            {
                mapCustomPermissionTabValue.put(strInstance,mdtInstance.PMC_DH_CommercePermission__c) ;
            }
        }
    }
    /**
* @description 
* @author Hemant Giri Goswami | hegoswami@deloitte.com | 02-28-2024 
* @param strEffAccountId 
* @return PMC_DH_FeatureVisibilityWrapper 
**/
    @AuraEnabled(cacheable=true)
    public static PMC_DH_FeatureVisibilityWrapper getFeatureVisibilityMyAccountData(String strEffAccountId) //added as part of GDASF-19642
    {
        PMC_DH_FeatureVisibilityWrapper wrpFeatureVisibilityList = new PMC_DH_FeatureVisibilityWrapper(); //added as part of GDASF-19642
        List<String> lstAcctCustomPermission=new List<String> () ; 
        List<AccountSubHeadersData> lstAccDetail=new List<AccountSubHeadersData>();
        AccountSubHeadersData accDetail;
        String strResult;
        List<ConnectApi.NavigationMenuItem> lstNavSubTab=new List<ConnectApi.NavigationMenuItem>();
        Map<String,String> mapCustomPermissionTabValue=new Map<String,String>();
        try
        {
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            Account accRec = [SELECT RecordType.Name, PMC_SS_Channel__c FROM Account WHERE id=:strEffAccountId WITH SECURITY_ENFORCED LIMIT 1];
            List<PMC_DH_FeatureVisibility__mdt> lstNavData =callFeatureMdt(PMC_DH_ConstantClass.ACCOUNT_SUBMENU);
            
            String strNavDev=PMC_DH_ConstantClass.ACCOUNT_SUBMENUS;
            if(!Test.isRunningTest())
            {
                lstNavSubTab=PMC_DH_HeaderDetails.getNavigationMenuItems(strNavDev);//fetching the list of custom permissions concerned to the user of type Account Sub Menu
                
            }
            else
            {
                String strConnectLabelTestData='Account Details';
                ConnectApi.NavigationMenuItemActionType conMenActionType;
                ConnectApi.NavigationMenuItem navMenuItem=new ConnectApi.NavigationMenuItem();
                navMenuItem.Label=strConnectLabelTestData;
                navMenuItem.actionValue=strConnectLabelTestData;
                navMenuItem.actionType=conMenActionType;
                lstNavSubTab.add(navMenuItem);
                
            }
            lstAcctCustomPermission=getFeatureVisibilityNavigationData(PMC_DH_ConstantClass.ACCOUNT_SUBMENU,lstNavData);
            getMapofPermissionTabValue(mapCustomPermissionTabValue,lstNavData);
            
            String strCountry = ([SELECT Id,Country FROM User WHERE Id =: UserInfo.getUserId() WITH SYSTEM_MODE].Country); //GDASF-21410
            for(ConnectApi.NavigationMenuItem navMenuItem:lstNavSubTab){
                accDetail=new AccountSubHeadersData();
                if(checkLeadMgmtCond(navMenuItem,  lstAcctCustomPermission, accRec)
                   || (checkRebatesCond(navMenuItem, lstAcctCustomPermission, strCountry))
                   || (lstAcctCustomPermission.contains(navMenuItem.label) && (navMenuItem.Label != System.label.PMC_DH_LeadManagement && navMenuItem.Label != System.label.PMC_DH_Rebates))
                  ) // checkRebatesCond method added as part of GDASF-21410
                { 
                    accDetail.strTabLabel=navMenuItem.Label;
                    accDetail.strTabValue=mapCustomPermissionTabValue.get(navMenuItem.Label).replace(' ','');
                    lstAccDetail.add(accDetail);
                }
                
            }
            
            strResult=json.serialize(lstAccDetail);
            wrpFeatureVisibilityList.strResult = strResult; //added as part of GDASF-19642
            wrpFeatureVisibilityList.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'FeatureVisibility'); //added as part of GDASF-19642
        }
        catch(Exception ex)
        {
            PMC_ErrorLogClass.processException(ex);
            wrpFeatureVisibilityList.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); //added as part of GDASF-19642
        }
        return wrpFeatureVisibilityList; //added as part of GDASF-19642
    }
    
    //GDASF-21410
    private static Boolean checkRebatesCond(ConnectApi.NavigationMenuItem navMenuItem, List<String> lstAcctCustomPermission, String strCountry){
        Boolean boolIsActive; 
        String strRegion = PMC_DH_CommonSystemUtils.getUserRegion(strCountry); // possible values - NA/BR
        String strDeveloperName = System.Label.get(null, REBATES_LABEL, LANG_EN)+ '_' + strRegion; // Rebates_NA or Rebates_BR  //System.label.PMC_DH_Rebates 
        PMC_DH_Store_Configuration__mdt mdtRebates = PMC_DH_Store_Configuration__mdt.getInstance(strDeveloperName);
        boolIsActive = ((lstAcctCustomPermission.contains(navMenuItem.label) && navMenuItem.Label == System.label.PMC_DH_Rebates) && mdtRebates.PMC_DH_isActive__c);
        return boolIsActive;
    }
    
    private static boolean checkLeadMgmtCond(ConnectApi.NavigationMenuItem navMenuItem, List<String> lstAcctCustomPermission,Account accRec)
    {
        Boolean boolResult=False;
        boolResult=((lstAcctCustomPermission.contains(navMenuItem.label) && navMenuItem.Label == System.label.PMC_DH_LeadManagement) && 
                    ( accRec.RecordType.Name == PMC_DH_ConstantClass.RETAILER || accRec.PMC_SS_Channel__c == PMC_DH_ConstantClass.RETAILERS_CHNL));
        return boolResult;
    } // this method is added as a part of COMPLEXITY HANDLING 
    
    /**
* @description 
* @author Hemant Giri Goswami | hegoswami@deloitte.com | 02-28-2024 
* @param strType 
* @return List<PMC_DH_FeatureVisibility__mdt> 
**/
    public static List<PMC_DH_FeatureVisibility__mdt> callFeatureMdt(String strType)
    {    
        
        List<PMC_DH_FeatureVisibility__mdt> lstMdt=[SELECT id,PMC_DH_Tab_Order__c,PMC_DH_CommercePermission__c,DeveloperName,PMC_DH_Value__c from PMC_DH_FeatureVisibility__mdt  
                                                    where PMC_DH_Type__c =:strType
                                                    WITH SYSTEM_MODE ORDER BY PMC_DH_Tab_Order__c ASC];
        return lstMdt;
    }
    /*************************************************************************
* @method Name : AccountSubHeadersData
* @description : Wrapper for Account Subheaders
*****************************************************************************/    
    public with sharing class AccountSubHeadersData
    {
        /**
* @description  Target of Navigation Menu
* @return String
*/
        @AuraEnabled
        public string strTabLabel{get;set;}
        /**
* @description  Target of Navigation Menu
* @return String
*/
        @AuraEnabled
        public string strTabValue{get;set;}
    }
    
    // added as part of GDASF-19642
    /**
* @description : Wrapper for List of custom permissions and metadata
* @author      : Nikhilesh Mohanty
* @last modified on 2024-01-10
**/ 
    public with sharing class PMC_DH_FeatureVisibilityWrapper
    {
        /**
* @description Serialized string of custom permissions and metadata
* @author Nikhilesh
* @return String
**/ 
        @AuraEnabled
        public String strResult{get;set;}
        
        /**
* @description Status Code and message
* @author Nikhilesh
* @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*/
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    }
    
    
}