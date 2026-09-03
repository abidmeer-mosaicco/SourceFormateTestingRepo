/**
* @description       : Util method for Account Operations
* @author            : @Sugunakar Routhu
* @group             : 
* @last modified on  : 02-19-2024
* @last modified by  : Lohitha| nlohithasai@deloitte.com
**/
public without sharing class PMC_DH_Acccount_Utils {

    /**
    * @description   : Update the ShipTo Account Information
    * @author        : @Suguankar Routhu
    * @param addDetailwrapper
    * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    * @Date          : 2023-06-05
    */

    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper updateShipToAccount(PMC_DH_AddressWrapper.AddressViewDetails addDetailwrapper){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result=new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        Account objAcc=new Account();
        objAcc.Id=addDetailwrapper.strAccountId;
        objAcc.Name=addDetailwrapper.strAddressName;
        objAcc.Type=addDetailwrapper.strAddressType;
        objAcc.ShippingCountryCode=addDetailwrapper.strCountry;
        objAcc.BillingCountryCode=addDetailwrapper.strCountry;
        objAcc.ShippingStreet=addDetailwrapper.strAddress;
        objAcc.BillingStreet=addDetailwrapper.strAddress;
        objAcc.PMC_DH_StreetNumber__c=addDetailwrapper.strNumber;
        objAcc.ShippingCity=addDetailwrapper.strCity;
        objAcc.BillingCity=addDetailwrapper.strCity;
        objAcc.ShippingStateCode=addDetailwrapper.strState;
        objAcc.Phone=addDetailwrapper.strcontactPhone;
        objAcc.BillingStateCode=addDetailwrapper.strState;
        objAcc.PMC_SS_StateTaxNumber__c =addDetailwrapper.strStateSubscription; // addition to GDASDF-19874
        objAcc.ShippingPostalCode=addDetailwrapper.strZipcode;
        objAcc.BillingPostalCode=addDetailwrapper.strZipcode;
        if(addDetailwrapper.boolMandatoryChanged){
        objAcc.PMC_SS_MDMVerified__c = False;
        }
        if(String.isNotBlank(addDetailwrapper.strCnpj)) {
            objAcc.PMC_SS_TaxIDOrCNPJOrCPF__c=addDetailwrapper.strCnpj;
        }
        if(String.isNotBlank(addDetailwrapper.strCPF)) {
            objAcc.PMC_SS_CPF__c=addDetailwrapper.strCPF;  // addition to GDASDF-19874
        }
        if(String.isNotBlank(addDetailwrapper.strDeliveryInstructions)) {
            objAcc.PMC_DH_Delivery_Instruction__c=addDetailwrapper.strDeliveryInstructions;
        }
        if(Schema.sObjectType.Account.isUpdateable()) {
            update objAcc;
            result=PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, PMC_DH_ConstantClass.ADDRESS_DETAIL);
        }
        return result;
    }

    /**
    * @description   : Update the associted Sold in the Information
    * @author        : @Suguankar Routhu
    * @param addDetailwrapper
    * @return PMC_DH_CreateShipToAddressWrapper
    * @Date          : 2023-06-05
    */
    
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper updateSoldToAcc(PMC_DH_AddressWrapper.AddressViewDetails addDetailwrapper){
       
        Account objAcc = [SELECT Id,PMC_DH_Account_Status__c,PMC_DH_StreetNumber__c from Account where Id=:addDetailwrapper.strAccountId WITH SECURITY_ENFORCED];
        objAcc.PMC_DH_Account_Status__c=PMC_DH_ConstantClass.ACCOUNT_INACTIVE_STATUS;
        update objAcc;
        PMC_DH_ShipToAddressCreationController.AddressDetails addressDetailsWrapper = new PMC_DH_ShipToAddressCreationController.AddressDetails();
        addressDetailsWrapper.strNumber = addDetailwrapper.strNumber;
        addressDetailsWrapper.strAddressName = addDetailwrapper.strAddressName;
        addressDetailsWrapper.strAddress = addDetailwrapper.strAddress;
        addressDetailsWrapper.strCity = addDetailwrapper.strCity;
        addressDetailsWrapper.strZipcode = addDetailwrapper.strZipcode;
        addressDetailsWrapper.strState = addDetailwrapper.strState;
        addressDetailsWrapper.strStateSubscription=addDetailwrapper.strStateSubscription;  // addition to GDASDF-19874
          if(String.isNoTBlank(addDetailwrapper.strCnpj)){
                addressDetailsWrapper.strCnpj = addDetailwrapper.strCnpj;
           }
        if(String.isNoTBlank(addDetailwrapper.strCPF))
        {
            addressDetailsWrapper.strCPF = addDetailwrapper.strCPF;    // addition to GDASDF-19874
        }
           if(String.isNoTBlank(addDetailwrapper.strDeliveryInstructions)){
                addressDetailsWrapper.strDeliveryInstructions = addDetailwrapper.strDeliveryInstructions;
            }
        PMC_DH_ShipToAddressCreationController.PMC_DH_CreateShipToAddressWrapper wrpShipToAddress = PMC_DH_ShipToAddressCreationController.createShipToAddress(addDetailwrapper.strSoldToAcc,JSON.serialize(addressDetailsWrapper));
        return wrpShipToAddress.statusCodeMessage;
    } 
    
    /**
    * @description   : get Status Value
    * @author        : @Suguankar Routhu
    * @param isVarified
    * @return String
    * @Date          : 2023-06-05
    */
    
   public static String getStatusValue(String status,String sapNumber){
        String result;
       
        if(status=='Active' && sapNumber!=null )
        {
            result =System.Label.pmc_addressDetails_validated;
        }
        else
        {
         result =System.Label.pmc_addressDetails_inAnalysis;
        }
        
        return result;
    }
    
    /**
    * @description Handle Duplicate account insert/update
    * @author Manisha Singh
    * @param dbSaveResult
    * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    */
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper setDuplicateAccountErrCode(Database.SaveResult dbSaveResult) {
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        if (!dbSaveResult.isSuccess()) {
            Datacloud.DuplicateResult duplicateResult;
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
            // Insertion failed due to duplicate detected
            for(Database.Error duplicateError : dbSaveResult.getErrors()){
                duplicateResult = ((Database.DuplicateError)duplicateError).getDuplicateResult();
            }
            if(duplicateResult!=NULL) {
                result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.ERROR_STATUS_CODE, PMC_DH_ConstantClass.DUPLICATE_ACCOUNT_MODULE);
            }
        }
        return result;
    }
    
}