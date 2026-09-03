/**
* @description Controller Class for language preferences
* @author Hemant Giri  Goswami/ Nikhilesh Mohanty
* @since  09-22-2023
* 
*/
public without sharing class PMC_DH_LanguagePreferenceController {
    
    /**
* @description Method to get the user's language and preferred language list
* @since 09-22-2023
* @return LanguagePreferenceWrapper
*/
    @AuraEnabled
    public static LanguagePreferenceWrapper getLanguagePreferences(){
        String strLanguage;
        LanguagePreferenceWrapper langPrefeWrapper=new LanguagePreferenceWrapper();
        List<PMC_DH_LangData> lstPrefe=new  List<PMC_DH_LangData>();
        List<String> lstUrl=new List<String>();
        Map<String,String> mapLanguageKeys=new Map<String,String>();
        List<PMC_DH_Store_Language__mdt> lstMdtLanguage=[Select label,DeveloperName,Language_Prefix__c,User_Locale__c,PMC_DH_UrlPrefix__c,PMC_DH_PicklistOrder__c
                                                         FROM PMC_DH_Store_Language__mdt 
                                                         WITH SECURITY_ENFORCED ORDER BY PMC_DH_PicklistOrder__c  ];
        try {
            for(PMC_DH_Store_Language__mdt  inst:lstMdtLanguage)
            {
                
                PMC_DH_LangData picklistIns=new PMC_DH_LangData();
                picklistIns.label=inst.DeveloperName;
                picklistIns.value=inst.Language_Prefix__c;
                picklistIns.key=inst.PMC_DH_UrlPrefix__c;
                picklistIns.transLabel=inst.Label;
                lstUrl.add(inst.PMC_DH_UrlPrefix__c);
                mapLanguageKeys.put(inst.User_Locale__c,inst.Language_Prefix__c);
                lstPrefe.add(picklistIns);
            }
            if (Auth.CommunitiesUtil.isGuestUser()){
                langPrefeWrapper.strUserLanguage='EN';
            }else{
                strLanguage = userinfo.getLanguage();
                String strLanguageFinal =mapLanguageKeys.get(strLanguage) ; // logic to extract only the head part of the value i.e EN,SP,PT
                langPrefeWrapper.strUserLanguage=strLanguageFinal.toUpperCase();
            }
            langPrefeWrapper.lstPreferences=lstPrefe;
            langPrefeWrapper.lstUrlLanguage=lstUrl;
            langPrefeWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'LangugaePreference');
        } catch (Exception e) {
            langPrefeWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
            //throw new AuraHandledException(e.getMessage());
        }
        return langPrefeWrapper;
    }
    
    /*************************************************************************
* @method Name  : updateUserLocale
* @description  : Method to update the logged in user's locale based on language selected
* @author       : Nikhilesh
* @param          strLanguage
* @return       : PMC_DH_UpdateUserLocaleWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_UpdateUserLocaleWrapper updateUserLocale(String strLanguage){ //changes as part of GDASF-19642
        String strResultUrl='';
        PMC_DH_UpdateUserLocaleWrapper wrpUpdateUserLocale = new PMC_DH_UpdateUserLocaleWrapper(); //changes as part of GDASF-19642
        try{
            String strUserId=userInfo.getUserId();
            User userObjRecord = [SELECT Id, ContactId, LanguageLocaleKey FROM User WHERE Id =: strUserId WITH SYSTEM_MODE LIMIT 1];
            PMC_DH_Store_Language__mdt config = PMC_DH_Store_Language__mdt.getInstance(strLanguage); // English / Portuguese / Spanish
            Contact conRecord = new Contact(Id=userObjRecord.ContactId);
            conRecord.PMC_DH_Language__c=strLanguage;
            if(Schema.sObjectType.Contact.isUpdateable()){
                update conRecord;
            }
            //userObjRecord.LanguageLocaleKey = config.Label; // en_US / pt_BR / esp_PG
            userObjRecord.LanguageLocaleKey=config.User_Locale__c;
            userObjRecord.LocaleSidKey=config.User_Locale__c;
            if(Schema.sObjectType.User.isUpdateable()){
                update as System userObjRecord;
                wrpUpdateUserLocale.strResultUrl=config.PMC_DH_UrlPrefix__c; //changes as part of GDASF-19642
                wrpUpdateUserLocale.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'UserLocaleUpdate'); //changes as part of GDASF-19642
            }
        }
        catch (Exception e) {
			wrpUpdateUserLocale.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); //changes as part of GDASF-19642
            throw new  AuraHandledException(e.getMessage());
        }
        return wrpUpdateUserLocale; //changes as part of GDASF-19642
    }
    
    /**
* @description wrapper for getLanguagePreferences
* @since 09-22-2023
*/
    public class LanguagePreferenceWrapper{
        /**
* @description User Current Language
* @return  String
*/
        @AuraEnabled
        public  String strUserLanguage{get;set;}
        /**
* @description List of Preferred Language
* @return List<PMC_DH_PicklistWrapper>
*/
        @AuraEnabled
        public  List<PMC_DH_LangData> lstPreferences{get;set;}
        
        @AuraEnabled
        public List<String> lstUrlLanguage{get;set;}
        /**
* @description Status Code and message
* @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*/
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    }
    
    public class PMC_DH_LangData{
        /**
* @description Label
* @return Label value
*/
        @AuraEnabled
        public String label{get;set;}
        /**
* @description value
* @return value
*/
        @AuraEnabled
        public String value{get;set;}
        /**
* @description value
* @return value
*/
        @AuraEnabled
        public String key{get;set;}
        /**
* @description Translated label
* @return String
*/
        @AuraEnabled
        public String transLabel{get;set;}
        
    }
    
    /**
* @description Wrapper for updateUserLocale (as part of GDASF-19642)
* @author Nikhilesh
* @since 01-10-2024
*/
    public class PMC_DH_UpdateUserLocaleWrapper{
        /**
* @description Result URL
* @author Nikhilesh
* @return  String
*/
        @AuraEnabled
        public String strResultUrl{get;set;}
        /**
* @description Status Code and message
* @author Nikhilesh
* @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*/
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    }
    
    
}