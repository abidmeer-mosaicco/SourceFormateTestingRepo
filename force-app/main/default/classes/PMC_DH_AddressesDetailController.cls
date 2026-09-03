/**
* @description       : Controller for fetching address deatil
* @author            : @Krishan Jangir
* @group             : 
* @last modified on  : 01-02-2025
* @last modified by  : Shubhada Kurumkar | shubhada.kurumkar@mosaico.com
**/
public without sharing  class PMC_DH_AddressesDetailController {
    // added comments
	public static Boolean boolThrowException=false;
    public static final String MOSAIC_DIRECT='Mosaic Direct';
         public static final String PMC_ADDADDRESS_HEADER='pmc_addNewAddress_';

    /** 
* @description   : fetches get Address Details
* 
* @return        : PMC_DH_AddressDetailWrapper
* @param   strAccountId
* @author        : @Krishan jangir
* @date          : 2023-05-02
*/
    @AuraEnabled
    public static PMC_DH_AddressDetailWrapper getAddressDetails(String strAccountId){  
        PMC_DH_AddressDetailWrapper addressWrapper = new PMC_DH_AddressDetailWrapper();
        addressWrapper.lstPickList=getAddrListTypes();
        List<PMC_DH_AddressDetailWrapper.AddressDetails> lstAddressWrapper = new List<PMC_DH_AddressDetailWrapper.AddressDetails>();
        try{
            throwNewExceptionForTest();
            List<PMC_SS_AccountPartnerRelationships__c> lstSoldtoShipto = [SELECT Name,Id, PMC_SS_Account__c, PMC_SS_Account__r.Name, PMC_SS_Account__r.AccountNumber,
            PMC_SS_RelatedAccount__r.PMC_SS_StateTaxNumber__c,PMC_SS_RelatedAccount__r.PMC_SS_CPF__c,PMC_SS_RelatedAccount__r.PMC_SS_SAPCustomerNumber__c,
            PMC_SS_RelatedAccount__c, PMC_SS_RelatedAccount__r.Name, PMC_SS_RelatedAccount__r.AccountNumber,PMC_SS_RelatedAccount__r.PMC_DH_StreetNumber__c, PMC_SS_RelatedAccount__r.Type,
            PMC_SS_RelatedAccount__r.ShippingStreet, PMC_SS_RelatedAccount__r.ShippingCity, PMC_SS_RelatedAccount__r.ShippingPostalCode, PMC_SS_RelatedAccount__r.ShippingState,
            PMC_SS_RelatedAccount__r.PMC_SS_TaxIDOrCNPJOrCPF__c, PMC_SS_RelatedAccount__r.PMC_SS_MDMVerified__c ,PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c
            FROM PMC_SS_AccountPartnerRelationships__c 
            WHERE PMC_SS_Account__c =:strAccountId AND  PMC_SS_Type__c=:PMC_DH_ConstantClass.ACCOUNT_TYPE AND PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c!=:PMC_DH_ConstantClass.ACCOUNT_INACTIVE_STATUS
            WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC];
            List<PMC_SS_AccountPartnerRelationships__c> lstSoldtoShiptoProcessed = PMC_DH_QuoteManagementHelper.removeDuplicateRelatedAccountsFromList(lstSoldtoShipto);
        for(PMC_SS_AccountPartnerRelationships__c objSoldtoship : lstSoldtoShiptoProcessed)
            {
                PMC_DH_AddressDetailWrapper.AddressDetails addDetailwrapper = new PMC_DH_AddressDetailWrapper.AddressDetails();
                PMC_DH_AddressDetailWrapper.parentDetails parenetDetails = new PMC_DH_AddressDetailWrapper.parentDetails();

                parenetDetails.strId=objSoldtoship.PMC_SS_Account__c;
                parenetDetails.strName=  objSoldtoship.PMC_SS_Account__r.Name;
                parenetDetails.strAccountNumber=  objSoldtoship.PMC_SS_Account__r.AccountNumber;
                
                addDetailwrapper.strJunctionRecId =objSoldtoship.Id;
                addDetailwrapper.strShipToAccountNumber=objSoldtoship.PMC_SS_RelatedAccount__r.AccountNumber;
                addDetailwrapper.strRecId = objSoldtoship.PMC_SS_RelatedAccount__c;
                addDetailwrapper.strNumber=objSoldtoship.PMC_SS_RelatedAccount__r.PMC_DH_StreetNumber__c ;
                addDetailwrapper.strAddressName = objSoldtoship.PMC_SS_RelatedAccount__r.Name;
                addDetailwrapper.strAddressType = getDigitalHubAddressPageValues(objSoldtoship.PMC_SS_RelatedAccount__r.Type);
                addDetailwrapper.strAddress = objSoldtoship.PMC_SS_RelatedAccount__r.ShippingStreet;
                addDetailwrapper.strCity = objSoldtoship.PMC_SS_RelatedAccount__r.ShippingCity;
                addDetailwrapper.strState = objSoldtoship.PMC_SS_RelatedAccount__r.ShippingState;
                addDetailwrapper.strZipcode = objSoldtoship.PMC_SS_RelatedAccount__r.ShippingPostalCode;
                addDetailwrapper.strCNPJ = objSoldtoship.PMC_SS_RelatedAccount__r.PMC_SS_TaxIDOrCNPJOrCPF__c;
                addDetailwrapper.strCPF=objSoldtoship.PMC_SS_RelatedAccount__r.PMC_SS_CPF__c;
                addDetailwrapper.strStateSubscription=objSoldtoship.PMC_SS_RelatedAccount__r.PMC_SS_StateTaxNumber__c;
        addDetailwrapper.strStatus = PMC_DH_Acccount_Utils.getStatusValue(objSoldtoship.PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c,objSoldtoship.PMC_SS_RelatedAccount__r.PMC_SS_SAPCustomerNumber__c);
                String statusOnAccountRecord =getLocalizedAddressStatus(objSoldtoship.PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c);

                if(addDetailwrapper.strStatus==System.Label.pmc_addressDetails_inAnalysis && statusOnAccountRecord == System.Label.pmc_addressDetails_in){
                    addDetailwrapper.strStatus =System.Label.pmc_addressDetails_in;
                } 
              
                String searchResult = addDetailwrapper.strAddressName + addDetailwrapper.strAddressType + addDetailwrapper.strAddress + addDetailwrapper.strCNPJ + addDetailwrapper.strZipcode + addDetailwrapper.strCity + addDetailwrapper.strState;
                addDetailwrapper.strSearchString = searchResult.replace('null','');
                addDetailwrapper.parent=parenetDetails;
                lstAddressWrapper.add(addDetailwrapper);
            }
            
            addressWrapper.addressData = lstAddressWrapper;
            return addressWrapper;
        }
        
        catch(Exception ex){
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /**
* @description   : Get DH values
* @return        : String
* @param    sfValue
* @author        : @Krishan jangir
* @date          : 2023-05-02
*/
    private static String getDigitalHubAddressPageValues(String sfValue) {
        String result = '';
        Map<String, String> mapSfValuesToDHValues = new Map<String, String>();
        PMC_Data_Conversion_SF_DH__mdt[] pmcSFtoDHRecords = PMC_Data_Conversion_SF_DH__mdt.getAll().values();
        for(PMC_Data_Conversion_SF_DH__mdt recPMC : pmcSFtoDHRecords){
            if(sfValue==recPMC.PMC_SF_Value__c){
                mapSfValuesToDHValues.put(sfValue,recPMC.PMC_DH_Value__c);                       
            }
        }
        if(mapSfValuesToDHValues.get(sfValue)!=null) {
            String strTemp= mapSfValuesToDHValues.get(sfValue).replace(' ','');
            result =System.label.get(null,PMC_DH_ConstantClass.LABEL_HEADER+strTemp,userinfo.getLocale());
        }
        return result;
    }

    public static String getLocalizedAddressStatus(String accountStatus) {
        if (accountStatus == 'Invalid') {
            return System.Label.pmc_addressDetails_in;
        }
        // Return the original accountStatus if it's not 'invalid'
        return accountStatus;
    }
    
    /**
* @description   : fetches get Address Detail wrt Account number
* @param strJunctionId
* @return        : PMC_DH_AddressWrapper
* @author        : @Krishan jangir
* @date          : 2023-06-01
*/
    @AuraEnabled
    public static PMC_DH_AddressWrapper viewAddressDetails(String strJunctionId){ 
        PMC_DH_AddressWrapper addressWrapper = new PMC_DH_AddressWrapper();
        PMC_SS_AccountPartnerRelationships__c objSoldToShip = new PMC_SS_AccountPartnerRelationships__c();
        try{
            throwNewExceptionForTest();
            List<PMC_DH_PicklistWrapper> lstStatesWrap = getNewAddressStateDetails();
           List<PMC_DH_PicklistWrapper> lstCountryWrap =getNewAddressCountryDetails();
            List<PMC_DH_PicklistWrapper> lstAddTypeWrap = getAddressType(PMC_DH_ConstantClass.ACCOUNT_TYPE);
            List<PMC_DH_PicklistWrapper> lstSoldToAcc = soldToAccount();
            
            objSoldToShip = [SELECT Id, Name, PMC_SS_Account__c,PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c, PMC_SS_Account__r.Name,PMC_SS_RelatedAccount__r.PMC_SS_CPF__c,PMC_SS_RelatedAccount__r.PMC_SS_StateTaxNumber__c,PMC_SS_RelatedAccount__r.PMC_SS_CustomerType__c,PMC_SS_RelatedAccount__r.PMC_SS_Property_farm_name__c,
                                                            PMC_SS_RelatedAccount__c,PMC_SS_RelatedAccount__r.PMC_SS_SAPCustomerNumber__c, PMC_SS_RelatedAccount__r.Name,PMC_SS_RelatedAccount__r.PMC_DH_StreetNumber__c, PMC_SS_RelatedAccount__r.Type,
                                                            PMC_SS_RelatedAccount__r.ShippingStreet,PMC_SS_RelatedAccount__r.Phone,PMC_SS_RelatedAccount__r.PMC_DH_Email__c, PMC_SS_RelatedAccount__r.ShippingCity, PMC_SS_RelatedAccount__r.ShippingPostalCode, PMC_SS_RelatedAccount__r.ShippingStateCode,
                                                            PMC_SS_RelatedAccount__r.PMC_SS_AddressNumber__c,PMC_SS_RelatedAccount__r.PMC_SS_TaxIDOrCNPJOrCPF__c,PMC_SS_RelatedAccount__r.PMC_SS_AddressDistrict__c,PMC_SS_RelatedAccount__r.ParentId,PMC_SS_RelatedAccount__r.shippingcountryCode,PMC_SS_RelatedAccount__r.PMC_DH_Delivery_Instruction__c, PMC_SS_RelatedAccount__r.PMC_SS_MDMVerified__c  
                                                            FROM PMC_SS_AccountPartnerRelationships__c WHERE ID=:strJunctionId AND  PMC_SS_Type__c=:PMC_DH_ConstantClass.ACCOUNT_TYPE AND PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c!=:PMC_DH_ConstantClass.ACCOUNT_INACTIVE_STATUS
                                                            WITH  SECURITY_ENFORCED 
                                                            LIMIT 1];
       List<PMC_DH_PicklistWrapper> lstPersonOrOrganizationWrap =getPersonOrOrganization(objSoldToShip.PMC_SS_RelatedAccount__r.PMC_SS_CustomerType__c);
        //  to identify sold-to changes
            
            // Account objSoldToShip=[select id,PMC_DH_StreetNumber__c,name,type,ShippingStreet,ShippingState,
            //                     PMC_SS_TaxIDOrCNPJOrCPF__c,PMC_DH_Delivery_Instruction__c 
            //                     from account where id=: strJunctionId WITH  SECURITY_ENFORCED LIMIT 1] ;
            PMC_DH_AddressWrapper.AddressViewDetails addDetailwrapper = new PMC_DH_AddressWrapper.AddressViewDetails(); 
            addDetailwrapper.strJunctionAccountId =objSoldToShip.Id;
            addDetailwrapper.strAccountId = objSoldToShip.PMC_SS_RelatedAccount__r.Id;
            addDetailwrapper.strNumber = objSoldToShip.PMC_SS_RelatedAccount__r.PMC_DH_StreetNumber__c;
            addDetailwrapper.strAddressName = objSoldToShip.PMC_SS_RelatedAccount__r.Name;
            addDetailwrapper.strAddressType = objSoldToShip.PMC_SS_RelatedAccount__r.Type;
            addDetailwrapper.strAddress = objSoldToShip.PMC_SS_RelatedAccount__r.ShippingStreet;
            addDetailwrapper.strCity = objSoldToShip.PMC_SS_RelatedAccount__r.ShippingCity; 
            addDetailwrapper.strDistrict= objSoldToShip.PMC_SS_RelatedAccount__r.PMC_SS_AddressDistrict__c; 
            addDetailwrapper.strState = objSoldToShip.PMC_SS_RelatedAccount__r.ShippingStateCode;
            addDetailwrapper.strZipcode = objSoldToShip.PMC_SS_RelatedAccount__r.ShippingPostalCode;
            addDetailwrapper.strCnpj = objSoldToShip.PMC_SS_RelatedAccount__r.PMC_SS_TaxIDOrCNPJOrCPF__c; // addition to GDASDF-19874
            addDetailwrapper.strStateSubscription=objSoldToShip.PMC_SS_RelatedAccount__r.PMC_SS_StateTaxNumber__c ; // addition to GDASDF-19874
            addDetailwrapper.strCPF=objSoldToShip.PMC_SS_RelatedAccount__r.PMC_SS_CPF__c; // addition to GDASDF-19874
            addDetailwrapper.strSoldToAcc = objSoldToShip.PMC_SS_Account__c;
            addDetailwrapper.strCountry = objSoldToShip.PMC_SS_RelatedAccount__r.shippingcountryCode; 
         addDetailwrapper.strPropertyFarmName=objSoldtoship.PMC_SS_RelatedAccount__r.PMC_SS_Property_farm_name__c;
          addDetailwrapper.straddressNumber=objSoldtoship.PMC_SS_RelatedAccount__r.PMC_SS_AddressNumber__c;
           addDetailwrapper.strcontactPhone=objSoldtoship.PMC_SS_RelatedAccount__r.phone;
            addDetailwrapper.strcontactEmail=objSoldtoship.PMC_SS_RelatedAccount__r.PMC_DH_Email__c;
          addDetailwrapper.strStatus = PMC_DH_Acccount_Utils.getStatusValue(objSoldtoship.PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c,objSoldtoship.PMC_SS_RelatedAccount__r.PMC_SS_SAPCustomerNumber__c);
            String statusOnAccountRecord1 =getLocalizedAddressStatus(objSoldtoship.PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c);
            if(addDetailwrapper.strStatus==System.Label.pmc_addressDetails_inAnalysis && statusOnAccountRecord1 == System.Label.pmc_addressDetails_in){
                addDetailwrapper.strStatus =System.Label.pmc_addressDetails_in;
            } 
                   
            addDetailwrapper.strDeliveryInstructions = objSoldToShip.PMC_SS_RelatedAccount__r.PMC_DH_Delivery_Instruction__c;
            addressWrapper.addressData = addDetailwrapper;
            addressWrapper.lststates = lstStatesWrap;
            addressWrapper.lstcountries = lstCountryWrap;
            addressWrapper.lstPersonOrOrganizationWrap=lstPersonOrOrganizationWrap;
            
            addressWrapper.lstAddType = lstAddTypeWrap;
            addressWrapper.lstSoldToAcc = lstSoldToAcc;
             if(objSoldToShip.PMC_SS_RelatedAccount__r.PMC_SS_CustomerType__c=='B2C')
            {
              addDetailwrapper.strPersonOrOrganization='Person';
            }
          if(objSoldToShip.PMC_SS_RelatedAccount__r.PMC_SS_CustomerType__c=='B2B')
            {
               addDetailwrapper.strPersonOrOrganization='Organization';
            }
           
            return addressWrapper;
        }
        
        catch(Exception ex){
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
           // system.debug('Exception:'+ex.getLineNumber());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    private static List<PMC_DH_PicklistWrapper>  getNewAddressStateDetails(){
        try{
             Schema.DescribeFieldResult fieldResult = User.StateCode.getDescribe();
                 List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                  List<PMC_DH_PicklistWrapper> lstofStates = new List<PMC_DH_PicklistWrapper>();
                  for( Schema.PicklistEntry f : ple){
                     PMC_DH_PicklistWrapper  objPickWrap = new PMC_DH_PicklistWrapper();
                    objPickWrap.label = f.getLabel();
                    objPickWrap.value =f.getLabel();
                    lstofStates.add(objPickWrap);
                      
                               }
            // User objUser = [SELECT Id, Name, City, Country FROM User where Id=:UserInfo.getUserId() WITH SECURITY_ENFORCED];
            // List<PMC_DH_PicklistWrapper> lstofStates = new List<PMC_DH_PicklistWrapper>();
            // for(PMC_Country__mdt recPMC : PMC_Country__mdt.getAll().values()){
            //     if(objUser.Country==recPMC.Country_Name__c){
            //         PMC_DH_PicklistWrapper  objPickWrap = new PMC_DH_PicklistWrapper();
            //         objPickWrap.label = recPMC.State__c;
            //         objPickWrap.value = recPMC.State__c;
            //         lstofStates.add(objPickWrap);
            //     }
            // }
            return lstofStates;
            
        }
        catch(Exception ex){
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
            throw new AuraHandledException(ex.getMessage());
        }
    }
  public static List<PMC_DH_PicklistWrapper>  getNewAddressCountryDetails(){
        try{
                Schema.DescribeFieldResult fieldResult = User.Countrycode.getDescribe();
                 List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                  List<PMC_DH_PicklistWrapper> lstofCountries = new List<PMC_DH_PicklistWrapper>();
                  for( Schema.PicklistEntry f : ple){
                     PMC_DH_PicklistWrapper  objPickWrap = new PMC_DH_PicklistWrapper();
                    objPickWrap.label = f.getLabel();
                    objPickWrap.value =f.getLabel();
                    lstofCountries.add(objPickWrap);
                      
                               }
                                return lstofCountries;
              }
        catch(Exception ex){
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
            throw new AuraHandledException(ex.getMessage());
        }
   }
   private static List<PMC_DH_PicklistWrapper> getPersonOrOrganization(String sfValue)
    {
 List<PMC_DH_PicklistWrapper> lstAddType = new List<PMC_DH_PicklistWrapper>();
        PMC_DH_PicklistWrapper addType = new PMC_DH_PicklistWrapper();
          if(sfValue=='B2C')
            {
                String strTemp ='person';
               addType.label=System.label.get(null,PMC_ADDADDRESS_HEADER+strTemp,userinfo.getLocale());
                addType.value = 'Person';
            }
          if(sfValue=='B2B')
            {
             String strTemp1 ='organization';
               addType.label=System.label.get(null,PMC_ADDADDRESS_HEADER+strTemp1,userinfo.getLocale());

                 addType.value = 'Organization';
            }
      
        lstAddType.add(addType);
       
        return lstAddType;
    }
    private static List<PMC_DH_PicklistWrapper> getAddressType(String sfValue) {
        Map<String,String> mapSfValuesToDHValues = new Map<String,String>();        
        List<PMC_DH_PicklistWrapper> lstAddType = new List<PMC_DH_PicklistWrapper>();
        PMC_DH_PicklistWrapper addType = new PMC_DH_PicklistWrapper();
        PMC_Data_Conversion_SF_DH__mdt[] pmcSFtoDHRecords = PMC_Data_Conversion_SF_DH__mdt.getAll().values();
        for(PMC_Data_Conversion_SF_DH__mdt recPMC : pmcSFtoDHRecords){
            if(sfValue==recPMC.PMC_SF_Value__c){
                mapSfValuesToDHValues.put(sfValue,recPMC.PMC_DH_Value__c);                       
            }
        }
        String strTemp;
        strTemp= mapSfValuesToDHValues.get(sfValue).replace(' ','');
        addType.label =System.label.get(null,PMC_DH_ConstantClass.LABEL_HEADER+strtemp,userinfo.getLocale());
        addType.value = sfValue;
        lstAddType.add(addType);
        return lstAddType;
    }
    
    /**
    * @description   : update Address Details
    * @param objAddressWrapper
    * @param strOldSoldToAcc
    * @return        : PMC_DH_StatusCodeMessageWrapper
    * @author        : @Rohan Undale
    * @date          : 2023-06-01
    */
    @AuraEnabled public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper updateAddressDetails(PMC_DH_AddressWrapper.AddressViewDetails objAddressWrapper, String strOldSoldToAcc) {
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result=new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        PMC_DH_AddressWrapper.AddressViewDetails addDetailwrapper=objAddressWrapper;
        // PMC_DH_ShipToAddressCreationController.PMC_DH_CreateShipToAddressWrapper wrpShipToAddress = new PMC_DH_ShipToAddressCreationController.PMC_DH_CreateShipToAddressWrapper();
        try {
            throwNewExceptionForTest();
            Boolean boolHasPermission=FeatureManagement.checkPermission(PMC_DH_ConstantClass.EDIT_ADDRESS_PERMISSION);
            if(boolHasPermission) {
                if(addDetailwrapper.strSoldToAcc !=strOldSoldToAcc) {
                    result = PMC_DH_Acccount_Utils.updateSoldToAcc(addDetailwrapper);
                }
                else {
                    result = PMC_DH_Acccount_Utils.updateShipToAccount(addDetailwrapper);
                }
            }
            else {
                result=PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.FAILURE_STATUS_CODE, PMC_DH_ConstantClass.ADDRESS_DETAIL);
            }
        }
        catch (Exception ex) {
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
            result=PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
        }
        return result;
    }

    // private static 
    // if(wrpShipToAddress.statusCodeMessage!=null && (wrpShipToAddress.statusCodeMessage.strStatusCode == PMC_DH_ConstantClass.ERROR_STATUS_CODE || wrpShipToAddress.statusCodeMessage.strStatusCode == PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE)) {
    //     result = wrpShipToAddress.statusCodeMessage;
    // }
    // else {
    //     result=PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, PMC_DH_ConstantClass.ADDRESS_DETAIL);
    // }

    private static List<PMC_DH_PicklistWrapper> soldToAccount(){
        PMC_DH_PicklistWrapper wrpAccount;
        List<PMC_DH_PicklistWrapper> lstAccountWrapper=new List<PMC_DH_PicklistWrapper>();
        String strComm=[SELECT Id,Name FROM Network WHERE Name=:MOSAIC_DIRECT WITH SECURITY_ENFORCED LIMIT 1].Id;
        
        String strWebStoreId = PMC_DH_DigitalHubB2BUtils.getWebStoreId(strComm);
        List<ConnectApi.ExternalManagedAccountOutput> lstExternalManagedAccounts=new List<ConnectApi.ExternalManagedAccountOutput>();
        if(!Test.isRunningTest()){
        ConnectApi.ExternalManagedAccountCollectionOutput conManagedAccounts = ConnectApi.ExternalManagedAccount.getExternalManagedAccounts(strWebStoreId,true);   
        lstExternalManagedAccounts= conManagedAccounts.externalManagedAccounts;
    }else{
			lstExternalManagedAccounts=new List<ConnectApi.ExternalManagedAccountOutput>();
          ConnectApi.ExternalManagedAccountOutput conAccParent=new  ConnectApi.ExternalManagedAccountOutput();
          lstExternalManagedAccounts.add(conAccParent);
          ConnectApi.ExternalManagedAccountOutput conAccChild=new  ConnectApi.ExternalManagedAccountOutput();
        conAccChild.accountId=[Select ID,NAME from Account where name='Test Account' WITH SECURITY_ENFORCED LIMIT 1].Id;
			
          lstExternalManagedAccounts.add(conAccChild);            
        }
        Set<Id> setBuyerAccs=new Set<Id>();
        for(ConnectApi.ExternalManagedAccountOutput conAccounts:lstExternalManagedAccounts)
        {   setBuyerAccs.add(conAccounts.accountId);      
        }  
        if(Schema.sObjectType.Account.isAccessible()){
            List<Account> lstAccount=[Select Id,Name from Account where Id IN:setBuyerAccs WITH SECURITY_ENFORCED];   
            for (Account acc : lstAccount) {
                wrpAccount=new PMC_DH_PicklistWrapper();
                wrpAccount.label=acc.Name;
                wrpAccount.value=acc.Id;
                lstAccountWrapper.add(wrpAccount);
            }
            
        }
        return lstAccountWrapper;   
    }

       /**
    * @description   : to get address status piclist
    * @return        : pickListWrap
    * @author        : @Lohitha sai
    * @Date          : 2023-06-05
    */
    public static List<PMC_DH_PicklistWrapper> getAddrListTypes() {
         List<PMC_DH_PicklistWrapper> pickListWrap=new List<PMC_DH_PicklistWrapper>();
           User objUser = [SELECT Id, Name, City, Country FROM User where Id=:UserInfo.getUserId() WITH SECURITY_ENFORCED];
            List<PMC_DH_PicklistWrapper> lstofStates = new List<PMC_DH_PicklistWrapper>();
            
            for(PMC_Country__mdt recPMC : PMC_Country__mdt.getAll().values()){
                if(objUser.Country==recPMC.Country_Name__c){
            PMC_DH_PicklistWrapper wrapper = new PMC_DH_PicklistWrapper();
                    wrapper.label = recPMC.State__c;
                    wrapper.value = recPMC.State__c;
                    lstofStates.add(wrapper);
                    
                }
                
            }
       
       /** PMC_DH_AddressStatusFilter__mdt[] metadataRecords = PMC_DH_AddressStatusFilter__mdt.getAll().values();

        for (PMC_DH_AddressStatusFilter__mdt metadataRecord : metadataRecords) {
            PMC_DH_PicklistWrapper wrapper = new PMC_DH_PicklistWrapper();
            String strTrsnStatus=PMC_DH_OrderUtilHelper.getStatusOrdLine(metadataRecord.PMC_DH_Status__c);
            wrapper.label =strTrsnStatus; //system.label.get(null,metadataRecord.PMC_DH_Status__c,UserInfo.getlocale());//metadataRecord.PMC_DH_Status__c;
            wrapper.value =strTrsnStatus; //system.label.get(null,metadataRecord.PMC_DH_Status__c,UserInfo.getlocale());//metadataRecord.PMC_DH_Status__c;
           if(metadataRecord.PMC_SS_Status__c!=PMC_DH_ConstantClass.STATUS_FAILURE){
            pickListWrap.add(wrapper);
          }
        }*/
        return pickListWrap;
    }
    /**
    * @description   : to throw exception to cover main class logic
    * @author        : @Lohitha sai
    * @Date          : 2023-06-05
    */
    public static void throwNewExceptionForTest(){
        if(boolThrowException && Test.isRunningTest())
        {
            throw new AuraHandledException(PMC_DH_ConstantClass.EXCEPTION_TEST); 
        }
    }

    /**
    * @description   : Delete the addresses 
    * @author        : @Lohitha sai
    * @param         shipTo
    * @return        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    * @Date          : 2023-06-15
    */
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper deleteAddresses(String shipTo){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();

        try{
            
            Account updateShipToAcc = [SELECT Id,PMC_DH_Account_Status__c from Account where Id=:shipTo];
            updateShipToAcc.PMC_DH_Account_Status__c = PMC_DH_ConstantClass.ACCOUNT_INACTIVE_STATUS;
            if(Schema.sObjectType.Account.isUpdateable()){
                update updateShipToAcc;
            }            
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, PMC_DH_ConstantClass.ADDRESS_DELETE);
            
        }Catch(Exception ex){
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
            throw new AuraHandledException(ex.getMessage());
        }
       return result;
    }
    
}