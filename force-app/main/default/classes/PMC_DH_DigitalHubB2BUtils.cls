/**
* @description : class for the methods that will be used across in the site
* @author      : Humera Rahath
* @last modified on  : 05-17-2023
* @last modified by  : Humera Rahath
**/
public without sharing class PMC_DH_DigitalHubB2BUtils  
{
    public static boolean throwTestException = false;
/*************************************************************************
* @method Name  : getCountryCodePhoneFormat
* @description  : Method to assign the Phone Format Metadata in wrapper class
* @param       	: None
* @return       : PhoneFormatWrapper
*****************************************************************************/
    public static PhoneFormatWrapper getCountryCodePhoneFormat()
    {
        PhoneFormatWrapper phnFormat=new PhoneFormatWrapper();
        List<PMC_DH_PicklistWrapper> lstCountryCode=new List<PMC_DH_PicklistWrapper>();
        PMC_DH_PicklistWrapper countryCode;
        Map<String,String> mapPhoneFrmt=new Map<String,String>();
        try{
            List<PMC_DH_Phone_Number_Format__mdt> lstPhoneMetadata= PMC_DH_Phone_Number_Format__mdt.getAll().values();
            if(!lstPhoneMetadata.isEmpty())
            {
                for(PMC_DH_Phone_Number_Format__mdt phoneFormat:lstPhoneMetadata)
                {
                    String strCountryCode=phoneFormat.PMC_DH_Country__c+' '+phoneFormat.PMC_DH_Country_Code__c;
                    countryCode=new PMC_DH_PicklistWrapper();
                    countryCode.label=strCountryCode;
                    countryCode.value=strCountryCode;
                    lstCountryCode.add(countryCode);
                    if(!mapPhoneFrmt.containsKey(strCountryCode))
                    {
                        mapPhoneFrmt.put(strCountryCode,phoneFormat.PMC_DH_Format__c);
                    }
                }
                phnFormat.lstCountryCode =lstCountryCode;
                phnFormat.mapCountryPhoneFormatting=mapPhoneFrmt;
            }
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        return  phnFormat;
    }
    
    /*************************************************************************
* @description  : Wrapper class for Phone Format and Country Code
* @author       : Humera Rahath
* @last modified on 05-17-2023
* @last modified by @humerarahath
*****************************************************************************/
    
    public with sharing class PhoneFormatWrapper
    {
        /**
* @description List for value label picklist
* @return 		List<PMC_DH_PicklistWrapper>
*/
        public List<PMC_DH_PicklistWrapper> lstCountryCode {get;set;}
        /**
* @description Map for CountryPhoneFormat
* @return 		Map<String,String>
*/
        public Map<String,String> mapCountryPhoneFormatting{get;set;}
    }

/*************************************************************************
* @method Name getMatchingContacts
* @description Method to Check if contact is present in system
* @param emailId - email id of contact
* @param strLastName - Last name
* @param strPhone - Phone number
* @return PMC_DH_ContactEmailWrapper
* @UserStory GDASF-5085
*****************************************************************************/

    public static List<Contact> getMatchingContacts(String emailId, String strLastName, String strPhone){
        try{
        //String strEmailId = emailId.toLowerCase();
        User objUser = [Select Id, ContactId from User Where Id =: UserInfo.getUserId() WITH SYSTEM_MODE];
       String strContactId = objUser.ContactId;
        
        String strQuery = 'SELECT Id, Email, LastName, Phone FROM Contact';
        strQuery += ' WHERE ((Email = :emailId) OR (Phone = :strPhone AND LastName = :strLastName))';
        if(strContactId != null){
            strQuery += ' AND Id != :strContactId';
        }
        strQuery += ' WITH SECURITY_ENFORCED';
        
        List<Contact> lstContact = Database.query(String.escapeSingleQuotes(strQuery));
        //System.debug('Contact List : '+lstContact);
        return lstContact;
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
/*************************************************************************
    * @method Name getMatchingContactsForUsrCreation
    * @description Method to Check if contact is present in system even including the loggedIn User
    * @param emailId - email id of contact
    * @param strLastName - Last name
    * @param strPhone - Phone number
    * @return PMC_DH_ContactEmailWrapper
    *****************************************************************************/
    public static List<Contact> getMatchingContactsForUsrCreation(String emailId, String strLastName, String strPhone){
        List<Contact> lstContact = new List<Contact>();  
        try{  
            lstContact = [SELECT Id, Email, LastName, Phone FROM Contact WHERE ((Email = :emailId) OR (Phone = :strPhone AND LastName = :strLastName)) WITH SECURITY_ENFORCED];
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        return lstContact;
    }
    
/*************************************************************************
* @description  : Wrapper class for Status code message
* @author       : Rohan Undale
* @last modified on 06-02-2023
* @last modified by @Nikhilesh
*****************************************************************************/
public with sharing class PMC_DH_StatusCodeMessageWrapper{
/**
* @description Status code
* @return String
*/	@Auraenabled
    public String strStatusCode{get;set;}
/**
* @description Status Message
* @return String
*/
    @Auraenabled
    public String strStatusMessage{get;set;}
/**
* @description Module from which method is called
* @return String
*/
    @Auraenabled
    public String strModule{get;set;}
/**
* @description Attribute to send data for any method return
* @return String
*/
    @AuraEnabled
    public string strData{get;set;}
}

/*************************************************************************
* @method Name getMessageForStatusCode
* @description Method to Get message wrt status code and module
* @param strStatusCode - Status code
* @param strModule - Module
* @return PMC_DH_StatusCodeMessageWrapper
*****************************************************************************/
    public static PMC_DH_StatusCodeMessageWrapper getMessageForStatusCode(String strStatusCode, String strModule){
        try{
            PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_StatusCodeMessageWrapper();
            PMC_DH_StatusCodeMessageMapping__mdt[] lstStatusCodeMessageMapping = PMC_DH_StatusCodeMessageMapping__mdt.getAll().values();
            for(PMC_DH_StatusCodeMessageMapping__mdt mapping : lstStatusCodeMessageMapping){
                if(mapping.strModule__c == strModule && mapping.strStatusCode__c == strStatusCode){
                    result.strStatusCode = strStatusCode;
                    result.strStatusMessage = mapping.strMessageCustomLabelApiName__c;
                    result.strModule = strModule;                        
                }else if(strStatusCode == '100' && mapping.strStatusCode__c == strStatusCode){
                    result.strStatusCode = strStatusCode;
                    result.strStatusMessage = mapping.strMessageCustomLabelApiName__c;
                    result.strModule = strModule;
                }
            }
            return result;
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /*************************************************************************
* @method Name  : getWebStoreId
* @description  : Method to get the Store Id
* @param communityId - community Id
* @return       : String
*****************************************************************************/
    public static String getWebStoreId(String communityId){
        string strWebStoreId;
        if(Schema.sObjectType.WebStoreNetwork.isAccessible()){
            List<WebStoreNetwork> lstwebNetwork=  [SELECT WebStoreId FROM WebStoreNetwork WHERE NetworkId=:communityId LIMIT 1];
            if(!lstwebNetwork.isEmpty()){        
                strWebStoreId= lstwebNetwork[0].WebStoreId;   
            }
        }
        return strWebStoreId;
    }

        /*************************************************************************
* @method Name  : checkQuantity
* @description  : Method to check quantity
* @param param Integer
* @return       : String
*****************************************************************************/

    public static Double checkQuantity(CartItem param) { 
       // String strParam;
       Double strParam=0;
        strParam = PMC_DH_QuoteUtils.checkForQuantity(param)?PMC_DH_ConstantClass.PRODUCT_QUANTITY:param.Quantity;
        return strParam;
    }
       /**
* @description throw aura handled exception for test class
* @author Nikhilesh
* @date 2023-05-24
*/
    public static void throwTestExceptionForTest(){
        if (throwTestException && Test.isRunningTest()) {
            throw new AuraHandledException(PMC_DH_ConstantClass.TEST_EXCEPTION_MESSAGE);
        }
    }

/*************************************************************************
* @method Name getFormattedPhone
* @description Method to Get formatted phone
* @param strCountryCode 
* @param strPhone
* @return String
* @author Ajeet
* @date 2023-06-01
*****************************************************************************/
    public static String getFormattedPhone(String strCountryCode, String strPhone){
        List<String> phoneCode = strCountryCode.split(' ');
        String strPhoneNumber = phoneCode[1] + ' ' + strPhone;
        return strPhoneNumber;
    }

/*************************************************************************
* @method Name getPicklistFromSchema
* @description Method to Get Picklist from Schema
* @param fieldResult Schema.DescribeFieldResult
* @return String
* @author Humera Rahath
* @date 2023-06-01
*****************************************************************************/
public static List<PMC_DH_PicklistWrapper> getPicklistFromSchema(Schema.DescribeFieldResult fieldResult){
    List<PMC_DH_PicklistWrapper> lstPickList = new List<PMC_DH_PicklistWrapper>();
    PMC_DH_PicklistWrapper picklist;
    try{
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        if(!ple.isEmpty()){
            for(Schema.PicklistEntry pickListVal : ple){
                picklist = new PMC_DH_PicklistWrapper();
                picklist.label = pickListVal.getLabel();
                picklist.value = pickListVal.getValue();
                lstPickList.add(picklist);
            } 
        } 
    }
    catch(Exception ex){
        throw new AuraHandledException(ex.getMessage());
    }
    return lstPickList;

}

/*************************************************************************
* @method Name  : getPaymentInfoForCart
* @param strCountry : Country name
* @description  : Method to get the payment information of Quote Checkout in wrapper class
* @return       : PaymentInfoWrapper
*****************************************************************************/
    public static PMC_DH_RequestForQuoteController.PaymentInfoWrapper getPicklistValuesForPayment(String strCountry)
    {
      Set<String> lstModule = new Set<String>{'PaymentMethod', 'CurrencyCode', 'PaymentTerm'};
        List<PMC_DH_PicklistWrapper> lstCurrencyIsoCode = new List<PMC_DH_PicklistWrapper>();
        List<PMC_DH_PicklistWrapper> lstPaymentMethods = new List<PMC_DH_PicklistWrapper>();
        List<PMC_DH_PicklistWrapper> lstPaymentTerms = new List<PMC_DH_PicklistWrapper>();
        Map<String,String> mapTranslatedPaymentTerms = PMC_DH_QuoteManagementHelper.createPaymentTermsMapFrTranslations(SBQQ__Quote__c.SBQQ__PaymentTerms__c.getDescribe());
        List<PMC_DH_CheckoutConfig__mdt> lstCheckoutConfig = PMC_DH_QuoteUtils.getCheckoutConfigs(lstModule, strCountry, 'RequestForQuote');
        for(PMC_DH_CheckoutConfig__mdt objCheckoutConfig : lstCheckoutConfig){
            switch on objCheckoutConfig.Module__c {
                when 'PaymentMethod' {		// when block 1
                    PMC_DH_PicklistWrapper pickList = new PMC_DH_PicklistWrapper();
                    pickList.label = objCheckoutConfig.MasterLabel;
                    pickList.value = objCheckoutConfig.PicklistAPI_Name__c;
                    lstPaymentMethods.add(pickList);
                }	
                when 'CurrencyCode' {		// when block 2
                    PMC_DH_PicklistWrapper pickList = new PMC_DH_PicklistWrapper();
                    pickList.label = objCheckoutConfig.PicklistAPI_Name__c;
                    pickList.value = objCheckoutConfig.PicklistAPI_Name__c;
                    lstCurrencyIsoCode.add(pickList);
                }
                when 'PaymentTerm' {		// when block 3
                    if(mapTranslatedPaymentTerms.containsKey(objCheckoutConfig.PicklistAPI_Name__c)){
                    PMC_DH_PicklistWrapper pickList = new PMC_DH_PicklistWrapper();
                    pickList.label = mapTranslatedPaymentTerms.get(objCheckoutConfig.PicklistAPI_Name__c);
                    pickList.value = objCheckoutConfig.PicklistAPI_Name__c;
                    lstPaymentTerms.add(pickList);
                }
            }
        }
        }
  		PMC_DH_RequestForQuoteController.PaymentInfoWrapper objPaymentInfoWrapper = new PMC_DH_RequestForQuoteController.PaymentInfoWrapper();
        objPaymentInfoWrapper.lstCurrencyIsoCode = lstCurrencyIsoCode;
        objPaymentInfoWrapper.lstPaymentMethods = lstPaymentMethods;
        objPaymentInfoWrapper.lstPaymentTerms = lstPaymentTerms;
        return objPaymentInfoWrapper;
    }
	

}