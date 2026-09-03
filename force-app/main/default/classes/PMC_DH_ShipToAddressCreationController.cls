/**
* 
* @description Add new ship to 
* @author @Krishan
* @last modified on 05-11-2023
* @last modified by @Krishan
* 
**/
public without sharing class PMC_DH_ShipToAddressCreationController {
    public static boolean throwUsersTestException = false;
    public static final String TEST_EXCEPTION_MESSAGE = 'Test Error';
    public static final String ACCOUNT_CREATION_MODULE = 'ShipToAccountCreation';
    public static final String DO_NOT_USE = 'DO NOT USE';
    public static final String PMC_ADDADDRESS_HEADER='pmc_addNewAddress_';
    public static final String RECORD_TYPE='Ship-to Customer';
    /**
* @description 
* @author @Krishan | 05-19-2023 
* @param strEffectiveAccountId 
* @param addressDetailsJSON 
* @return PMC_DH_CreateShipToAddressWrapper 
**/
    //changes as part of GDASF-19642
    @AuraEnabled
    public static PMC_DH_CreateShipToAddressWrapper createShipToAddress(String strEffectiveAccountId, String addressDetailsJSON){
        User loggedInUser = [SELECT Id,Name,ContactId, Country from User Where Id=:Userinfo.getUserId() WITH SECURITY_ENFORCED];
        Account objAcc = [SELECT Id,CurrencyIsoCode,RecordTypeId from Account Where  Id=:strEffectiveAccountId WITH SECURITY_ENFORCED];
        RecordType RecType = [SELECT Id,Name from RecordType Where  Name=:RECORD_TYPE WITH SECURITY_ENFORCED];
        
        Account objAccount = new Account();
        PMC_DH_CreateShipToAddressWrapper wrpShipToAddress = new PMC_DH_CreateShipToAddressWrapper();
        try{
            getException();
            AddressDetails addressDetailsWrapper = (AddressDetails)JSON.deserialize(addressDetailsJSON, AddressDetails.Class);
            objAccount.Name = addressDetailsWrapper.strAddressName;
            objAccount.Type = PMC_DH_ConstantClass.ACCOUNT_TYPE;
            objAccount.PMC_SS_SoldToAccount__c=strEffectiveAccountId;
            objAccount.Partner_Status__c='Active';
            objAccount.ShippingCountryCode= addressDetailsWrapper.strcountry;
            objAccount.BillingCountryCode = addressDetailsWrapper.strcountry;
            objAccount.ShippingStreet = addressDetailsWrapper.strAddress;
            objAccount.BillingStreet = addressDetailsWrapper.strAddress;
            objAccount.PMC_DH_StreetNumber__c =  addressDetailsWrapper.strNumber;
            objAccount.ShippingCity =  addressDetailsWrapper.strCity;
            objAccount.BillingCity =  addressDetailsWrapper.strCity;
            objAccount.ShippingPostalCode =  addressDetailsWrapper.strZipcode;
            objAccount.BillingPostalCode =  addressDetailsWrapper.strZipcode;
            objAccount.ShippingStateCode =  addressDetailsWrapper.strState;
            objAccount.BillingStateCode =  addressDetailsWrapper.strState;
            objAccount.Phone=addressDetailsWrapper.strcontactPhone;
            objAccount.PMC_DH_Email__c=addressDetailsWrapper.strcontactEmail;
            objAccount.PMC_SS_AddressDistrict__c=addressDetailsWrapper.strDistrict;
            objAccount.PMC_SS_AddressNumber__c=addressDetailsWrapper.straddressNumber;
            objAccount.PMC_SS_Property_farm_name__c=addressDetailsWrapper.strPropertyFarmName;
            if(addressDetailsWrapper.strPersonOrOrganization=='Person')
            {
                objAccount.PMC_SS_CustomerType__c='B2C';
            }
            if(addressDetailsWrapper.strPersonOrOrganization=='Organization')
            {
                objAccount.PMC_SS_CustomerType__c='B2B';
            }
            
            objAccount.PMC_SS_StateTaxNumber__c=addressDetailsWrapper.strStateSubscription; // addition to GDASDF-19874
            if(String.isNoTBlank(addressDetailsWrapper.strCPF)  )
            {
                objAccount.PMC_SS_CPF__c=addressDetailsWrapper.strCPF; // addition to GDASDF-19874
            }
            objAccount.PMC_SS_MDMVerified__c = False;
            objAccount.RecordTypeId=RecType.Id;
            
            if(addressDetailsWrapper.strPersonOrOrganization=='Person')   {//GSMD-2027
                if(String.isNoTBlank(addressDetailsWrapper.strCPF)  ){
                    objAccount.PMC_SS_CPF__c=addressDetailsWrapper.strCPF; // addition to GDASDF-19874
                    objAccount.PMC_SS_TaxIDOrCNPJOrCPF__c='';
                }
            }  if(addressDetailsWrapper.strPersonOrOrganization=='Organization'){//GSMD-2027
                if(String.isNoTBlank(addressDetailsWrapper.strCnpj)){
                    objAccount.PMC_SS_TaxIDOrCNPJOrCPF__c= addressDetailsWrapper.strCnpj;
                    objAccount.PMC_SS_CPF__c='';
                }
            }
            
           
            if(String.isNoTBlank(addressDetailsWrapper.strDeliveryInstructions)){
                objAccount.PMC_DH_Delivery_Instruction__c = addressDetailsWrapper.strDeliveryInstructions;
            }
            if(Schema.sObjectType.Account.isCreateable()){
                Database.SaveResult sr = Database.insert(objAccount,false);
                system.debug('result:'+sr);
                Account existingShiptoAccount=new Account();
                wrpShipToAddress.statusCodeMessage = PMC_DH_Acccount_Utils.setDuplicateAccountErrCode(sr);
                //If there is no error during Account insert
                if(wrpShipToAddress.statusCodeMessage.strStatusCode==null) {
                    createTasks(strEffectiveAccountId, objAccount, objAcc);
                    wrpShipToAddress.objAccount = objAccount; //changes as part of GDASF-19642
                    wrpShipToAddress.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, ACCOUNT_CREATION_MODULE); //changes as part of GDASF-19642   
                }
                else
                {
                    
                    for(Database.Error duplicateError : sr.getErrors()){
                        Datacloud.DuplicateResult dupeResult =((Database.DuplicateError)duplicateError).getDuplicateResult();
                        for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                            for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                                System.debug('Duplicate Record: ' + matchRecord.getRecord());
                                existingShiptoAccount=(Account)matchRecord.getRecord();
                            }
                        }
                        
                    }
                    
                    Database.SaveResult result= createSoldToShipToRelation(strEffectiveAccountId, existingShiptoAccount.Id, objAcc.CurrencyIsoCode, objAccount);//GSMD-1486
                    if(!result.isSuccess())
                    {
                        
                        wrpShipToAddress.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.ERROR_STATUS_CODE, PMC_DH_ConstantClass.DUPLICATE_ACCOUNT_MODULE);
                        
                    }
                    else {
                        wrpShipToAddress.objAccount = existingShiptoAccount;
                        wrpShipToAddress.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, ACCOUNT_CREATION_MODULE); //changes as part of GDASF-19642   
                    }
                    
                }
            }
        }Catch(Exception ex){
            PMC_ErrorLogClass.processException(ex);
            wrpShipToAddress.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL); //changes as part of GDASF-19642
        }
        return wrpShipToAddress; //changes as part of GDASF-19642
    }
    
    /**
* @description Create SoldToShipToRelation and task for Sales team
* @author Manisha Singh
* @param effAccId
* @param nwAcc
* @param exstAcc
*/
    private static void createTasks(String effAccId, Account nwAcc, Account exstAcc) {
        Database.SaveResult result;
        if(!String.isBlank(nwAcc.Id)){
            // to identify sold-to changes 
            // Below ACR creation code is commented as required for GPT-31150
            //createAccountContactRelation(objAccount.Id, strEffectiveAccountId);
            result=createSoldToShipToRelation(effAccId,nwAcc.Id,exstAcc.CurrencyIsoCode,nwAcc);//GSMD-1486 
            createTaskForSalesTeam(effAccId);
        }
    }
    
    /**
* @description get PersonOrOrganization
* @author @Shubhada | 12-24-2024 
* @return List<PMC_DH_ShipToAddressCreationWrapper.PersonOrOrganization> 
*/
    @TestVisible
    public static List<PMC_DH_ShipToAddressCreationWrapper.PersonOrOrganization> getPersonOrOrganization() {
        
        List<PMC_DH_ShipToAddressCreationWrapper.PersonOrOrganization> lstAddType = new List<PMC_DH_ShipToAddressCreationWrapper.PersonOrOrganization>();
        PMC_DH_ShipToAddressCreationWrapper.PersonOrOrganization addType = new PMC_DH_ShipToAddressCreationWrapper.PersonOrOrganization();
        PMC_DH_ShipToAddressCreationWrapper.PersonOrOrganization addType1 = new PMC_DH_ShipToAddressCreationWrapper.PersonOrOrganization();
        
        
        String strTemp ='person';
        addType.strLabel=System.label.get(null,PMC_ADDADDRESS_HEADER+strTemp,userinfo.getLocale());
        addType.strValue = 'Person';
        lstAddType.add(addType);
        String strTemp1 ='organization';
        addType1.strLabel=System.label.get(null,PMC_ADDADDRESS_HEADER+strTemp1,userinfo.getLocale());
        
        addType1.strValue = 'Organization';
        lstAddType.add(addType1);
        return lstAddType;
    }
    
    /**
* @description get address type 
* @author @Krishan | 05-19-2023 
* @param sfValue 
* @return List<PMC_DH_ShipToAddressCreationWrapper.AddressType> 
**/
    @TestVisible
    public static List<PMC_DH_ShipToAddressCreationWrapper.AddressType> getAddressType(String sfValue) {
        Map<String,String> mapSfValuesToDHValues = new Map<String,String>();        
        List<PMC_DH_ShipToAddressCreationWrapper.AddressType> lstAddType = new List<PMC_DH_ShipToAddressCreationWrapper.AddressType>();
        PMC_DH_ShipToAddressCreationWrapper.AddressType addType = new PMC_DH_ShipToAddressCreationWrapper.AddressType();
        PMC_Data_Conversion_SF_DH__mdt[] pmcSFtoDHRecords = PMC_Data_Conversion_SF_DH__mdt.getAll().values();
        for(PMC_Data_Conversion_SF_DH__mdt recPMC : pmcSFtoDHRecords){
            if(sfValue==recPMC.PMC_SF_Value__c){
                mapSfValuesToDHValues.put(sfValue,recPMC.PMC_DH_Value__c);                       
            }
        }
        String strTemp;
        strTemp= mapSfValuesToDHValues.get(sfValue).replace(' ','');
        addType.strLabel =System.label.get(null,PMC_DH_ConstantClass.LABEL_HEADER+strtemp,userinfo.getLocale());
        addType.strValue = mapSfValuesToDHValues.get(sfValue);
        System.debug('addType=='+addType);
        lstAddType.add(addType);
        return lstAddType;
    }
    /*************************************************************************
* Method Name: getNewAddressStateDetails
* Description: get new address state list
* Return Type: string
*****************************************************************************/
    
    
    
    /**
* @description get new address state list
* @author @Krishan | 05-19-2023 
* @return string 
**/
    @AuraEnabled(cacheable=true)
    public static string getNewAddressStateDetails(){
        PMC_DH_ShipToAddressCreationWrapper creationWrapper = new PMC_DH_ShipToAddressCreationWrapper(); 
        try{
            getException();
            User objUser = [SELECT Id, Name, City, Country FROM User where Id=:UserInfo.getUserId() WITH SECURITY_ENFORCED];
            List<PMC_DH_ShipToAddressCreationWrapper.LstState> lstofStates = new List<PMC_DH_ShipToAddressCreationWrapper.LstState>();
            
            for(PMC_Country__mdt recPMC : PMC_Country__mdt.getAll().values()){
                if(objUser.Country==recPMC.Country_Name__c){
                    PMC_DH_ShipToAddressCreationWrapper.LstState objState = new PMC_DH_ShipToAddressCreationWrapper.LstState();
                    objState.strLabel = recPMC.State__c;
                    objState.strValue = recPMC.State__c;
                    lstofStates.add(objState);
                    
                }
                
            }
            creationWrapper.lstAddressType = getAddressType(PMC_DH_ConstantClass.ACCOUNT_TYPE);
            creationWrapper.lstPersonOrOrganization=getPersonOrOrganization();
            creationWrapper.lstState = lstofStates;
            creationWrapper.lstcountries =PMC_DH_AddressesDetailController.getNewAddressCountryDetails();
            creationWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'AddressDetail');   
        }
        catch(Exception ex){
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
            creationWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
        }
        return JSON.serialize(creationWrapper);
    }
    /**
* @description Get Exception 
* @author @Krishan
**/
    @TestVisible
    private static void getException(){
        if (throwUsersTestException && Test.isRunningTest()) {
            throw new AuraHandledException(TEST_EXCEPTION_MESSAGE);
        }
    }
    
    /**
* @description create task for sales team
* @param strShipToAccId 
* @param strEffectiveAccountId 
* @author @Krishan
**/
    // Below ACR creation code is commented as required for GPT-31150
    /*@TestVisible
private static void createAccountContactRelation(Id strShipToAccId, Id strEffectiveAccountId) { 

List<AccountContactRelation> lstAccConRelation = new List<AccountContactRelation>();
for(Contact objContact : [SELECT Id, AccountId FROM Contact WHERE AccountId =:strEffectiveAccountId WITH SECURITY_ENFORCED]){
AccountContactRelation objAccountContactRelation = new AccountContactRelation();
objAccountContactRelation.ContactId = objContact.Id;
objAccountContactRelation.AccountId = strShipToAccId;
lstAccConRelation.add(objAccountContactRelation);
}
if(Schema.sObjectType.AccountContactRelation.isCreateable()){
Database.insert(lstAccConRelation, false);
}

}*/
    
    
    
    /**
* @description create task for sales team
* @param selectedAccountId 
* @author @Krishan
**/
    @TestVisible
    private static void createTaskForSalesTeam(Id selectedAccountId) {   
        Task tsk = new Task();
        tsk.Subject = PMC_DH_ConstantClass.TASK_SUBJECT;
        tsk.Status = PMC_DH_ConstantClass.OPEN;
        tsk.Priority = PMC_DH_ConstantClass.TASK_PRIOROTY;
        tsk.WhatId = selectedAccountId;
        tsk.ActivityDate=System.today();
        if(Schema.sObjectType.Task.isCreateable()){
            insert tsk;
        }
        
    }
    /**
* @description create sold to ship relation
* @param selectedAccountId
* @param newShippingAccountd
* @param currencyIsoCode  
* @author @Krishan
**/
    
    
    
    @TestVisible//GSMD-1486
    private static Database.SaveResult createSoldToShipToRelation(Id selectedAccountId,Id newShippingAccountd,String currencyIsoCode,Account objAccount ) {   
        PMC_SS_AccountPartnerRelationships__c soldToShipToAccount = new PMC_SS_AccountPartnerRelationships__c();
        soldToShipToAccount.Name = objAccount.Name;//GSMD-1486
        soldToShipToAccount.PMC_SS_Account__c=selectedAccountId;
        soldToShipToAccount.PMC_SS_RelatedAccount__c=newShippingAccountd;
        soldToShipToAccount.CurrencyIsoCode=currencyIsoCode;
        soldToShipToAccount.PMC_SS_Type__c = PMC_DH_ConstantClass.ACCOUNT_TYPE;
        Database.SaveResult sr;
        if(Schema.sObjectType.PMC_SS_AccountPartnerRelationships__c.isCreateable()){
            
            sr = Database.insert(soldToShipToAccount,false);
            system.debug('result:'+sr);
        }
        return sr;
        
    }
    
    /**
* @description weapper fo address details
* @author @Krishan | 05-19-2023 
* @return string 
**/
    public with sharing class AddressDetails{
        /**
* @description 
* @author @shubhada | 12-23-2024 
* @return string 
**/
        @AuraEnabled
        public string strPersonOrOrganization{get;set;}
        
        /**
* @description 
* @author @shubhada | 12-23-2024 
* @return string 
**/
        @AuraEnabled
        public string strcontactPhone{get;set;}
        /**
* @description 
* @author @shubhada | 12-23-2024 
* @return string 
**/
        @AuraEnabled
        public string straddressNumber{get;set;} 
        /**
* @description 
* @author @shubhada | 12-23-2024 
* @return string 
**/
        @AuraEnabled
        public string strDistrict{get;set;}
        
        /**
* @description 
* @author @shubhada | 12-23-2024 
* @return string 
**/
        @AuraEnabled
        public string strPropertyFarmName{get;set;}
        /**
* @description 
* @author @shubhada | 12-23-2024 
* @return string 
**/
        
        @AuraEnabled
        public string strcontactEmail{get;set;}
        /**
* @description 
* @author @krishan | 05-19-2023 
* @return string 
**/
        @AuraEnabled
        public string strNumber{get;set;}
        /**
* @description 
* @author @krishan | 05-19-2023 
* @return string 
**/
        @AuraEnabled
        public string strAddressName{get;set;}
        /**
* @description 
* @author @krishan | 05-19-2023 
* @return string 
**/
        @AuraEnabled
        public String strCnpj{get;set;}
        /**
* @description 
* @author @krishan | 05-19-2023 
* @return string 
**/
        @AuraEnabled
        public string strAddress{get;set;}
        /**
* @description 
* @author @krishan | 05-19-2023 
* @return string 
**/
        @AuraEnabled
        public string strCity{get;set;}
        /**
* @description 
* @author @krishan | 05-19-2023 
* @return string 
**/
        @AuraEnabled
        public string strState{get;set;}
        /**
* @description 
* @author @krishan | 05-19-2023 
* @return string 
**/
        @AuraEnabled
        public string strZipcode{get;set;}
        /**
* @description
* @return string 
**/
        @AuraEnabled
        public string strcountry{get;set;}
        /**
* @description 
* @author @krishan | 05-19-2023 
* @return string 
**/
        @AuraEnabled
        public string strDeliveryInstructions{get;set;}
        
        /**
*  @description State Subscription
* @return String // added as a part of GDASF-19874
*/
        @AuraEnabled
        public String strStateSubscription{get;set;}
        
        /**
*  @description CPF
* @return String // added as a part of GDASF-19874
*/
        @AuraEnabled
        public String strCPF{get;set;}
    }
    
    /**
* @description Wrapper for createShipToAddress (as part of GDASF-19642)
* @author Nikhilesh
* @since 01-10-2024
*/
    public class PMC_DH_CreateShipToAddressWrapper{
        /**
* @description Account
* @author Nikhilesh
* @return  Account
*/
        @AuraEnabled
        public Account objAccount{get;set;}
        /**
* @description Status Code and message
* @author Nikhilesh
* @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
*/
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    }
}