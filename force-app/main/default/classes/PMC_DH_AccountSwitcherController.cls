/**
 * @description       : Account Switcher
 * @author            : @hemant.girigoswami
 * @group             : Digital Hub
   * @last modified on  : 06-07-2024
   * @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
// added with sharing 

public with sharing class PMC_DH_AccountSwitcherController {
    
    
  public static Boolean boolthrowTestException = false;
 

  
  /**
* @description Wrapper class for Account Modal
* @author @hemant.girigoswami 
* 
**/
// added with sharing
  public with sharing class PMC_DH_AccountModalWrapper{
      /**
   * @description  Id of Account 
   * @return String
   */
      @AuraEnabled
      public String strAccountId {get;set;}
      /**
   * @description  Name of Account 
   * @return String
   */
      @AuraEnabled
      public String strAccountName {get;set;} 
      /**
   * @description  Street of Account 
   * @return String
   */
      @AuraEnabled
      public String strStreet{get;set;}
      /**
   * @description  City of Account 
   * @return String
   */
      @AuraEnabled
      public String strCity {get;set;}
      /**
   * @description  State of Account 
   * @return String
   */
      @AuraEnabled
      public String strState {get;set;}
      /**
   * @description  ZipCode of Account 
   * @return String
   */
      @AuraEnabled
      public String strZip {get;set;}
      /**
   * @description  country of Account 
   * @return String
   */
      @AuraEnabled
      public String strCountry {get;set;}
      /**
   * @description  Wrapper for Parent Info 
   * @author @hemant.girigoswami
   */
      @AuraEnabled
      public ParentWrapper parent {get;set;}
  }
  
  /**
   * @description  Wrapper Class for parent Info
   * @author @hemant.girigoswami
   */
  // added with sharing
  public with sharing class ParentWrapper{ 
      /**
   * @description  name of Parent Account 
   * @return String
   */
      @AuraEnabled
      public String strName {get;set;}
      /**
   * @description  Account Number of Parent Account 
   * @return String
   */
      @AuraEnabled
      public String strAccountNumber {get;set;}         
  }


  
  /**
  * @description 
  * @author @hemant.girigoswami | 05-09-2023 
  * @param strEffectiveAccountId 
  * @param strCommunityId 
  * @return PMC_DH_AccountSwitcherModalWrapper 
  **/
  @AuraEnabled(cacheable=true)
  public static PMC_DH_AccountSwitcherModalWrapper getAccountForModal(String strEffectiveAccountId,String strCommunityId ) {
    PMC_DH_AccountSwitcherModalWrapper accSwitcherWrapper = new PMC_DH_AccountSwitcherModalWrapper();
    try{              
          List<PMC_DH_AccountModalWrapper> lstAccountWrapper= new List<PMC_DH_AccountModalWrapper>();

          String strWebStoreId = PMC_DH_DigitalHubB2BUtils.getWebStoreId(strCommunityId);
          Boolean boolIncludeMyAccount = true;
        List<ConnectApi.ExternalManagedAccountOutput>  lstExternalManagedAccounts=new List<ConnectApi.ExternalManagedAccountOutput>();
       
        if(Test.isRunningTest())
       {  lstExternalManagedAccounts=new List<ConnectApi.ExternalManagedAccountOutput>();
        ConnectApi.ExternalManagedAccountOutput conAccParent=new  ConnectApi.ExternalManagedAccountOutput();
        conAccParent.accountId=[Select ID,NAME from Account where name='TestAccount' WITH SECURITY_ENFORCED LIMIT 1].Id;
        lstExternalManagedAccounts.add(conAccParent);
        ConnectApi.ExternalManagedAccountOutput conAccChild=new  ConnectApi.ExternalManagedAccountOutput();
        conAccChild.accountId=[Select ID,NAME from Account where name='Parent Test Account' WITH SECURITY_ENFORCED LIMIT 1].Id;
    
        lstExternalManagedAccounts.add(conAccChild);
     
       }
        else if(!Test.isRunningTest()) {
          ConnectApi.ExternalManagedAccountCollectionOutput conManagedAccounts = ConnectApi.ExternalManagedAccount.getExternalManagedAccounts(strWebStoreId, boolIncludeMyAccount);
           lstExternalManagedAccounts= conManagedAccounts.externalManagedAccounts;
        }
       
        
          Set<Id> setBuyerAccs=new Set<Id>();
          for(ConnectApi.ExternalManagedAccountOutput conAccounts:lstExternalManagedAccounts)
          {   setBuyerAccs.add(conAccounts.accountId);      
          }  
        
          if(Schema.sObjectType.Account.isAccessible()) {

         List<Account> lstAccount  =[SELECT Id, Name, ShippingCity, ShippingState, ShippingCountry, ShippingStreet, ShippingPostalCode, Parent.Name, Parent.AccountNumber, PMC_SS_SAPCustomerNumber__c FROM Account WHERE Id IN:setBuyerAccs WITH SECURITY_ENFORCED ORDER BY Name ASC];   
         for (Account acc : lstAccount) {
            PMC_DH_AccountModalWrapper accWrapper= new PMC_DH_AccountModalWrapper();   
            ParentWrapper parentwrap=new ParentWrapper();      
            accWrapper.strAccountId=acc.Id;
            accWrapper.strAccountName= acc.Name + ' - ' +  acc.PMC_SS_SAPCustomerNumber__c;
              if(acc.ShippingCity!=null){accWrapper.strCity= acc.ShippingCity;
              }
              if(acc.ShippingState!=null){  accWrapper.strState= acc.ShippingState;
              }
              if(acc.ShippingPostalCode!=null){ accWrapper.strZip= acc.ShippingPostalCode;
              }
              if(acc.ShippingCountry!=null){  accWrapper.strCountry= acc.ShippingCountry;
              }
              if(acc.ShippingStreet!=null){ accWrapper.strStreet= acc.ShippingStreet;
              }
              // ADDED REVERTED changes
              parentwrap.strName=  acc.Parent.Name;
              parentwrap.strAccountNumber=acc.Parent.AccountNumber;
              accWrapper.parent=parentwrap;
              lstAccountWrapper.add(accWrapper);
              
          }      
      }       
      accSwitcherWrapper.strAccountData = JSON.serialize(lstAccountWrapper);
      accSwitcherWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'EffectiveAccount');
    }    
    catch(Exception ex){  
       accSwitcherWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');  
       PMC_ErrorLogClass.processException(ex); // MDErrorLog
    }
    return accSwitcherWrapper;
  }
 





  /**
* @description   : get effective account Id
* 
* 
* @return        : PMC_DH_EffectiveAccountDetails
*
* @author        : @hemant.girigoswami
* @date          : 05-09-2023 
*/
  @AuraEnabled
  public static PMC_DH_EffectiveAccountDetails  getEffectiveAccountDetails()
   {  
      PMC_DH_EffectiveAccountDetails effAcc=new PMC_DH_EffectiveAccountDetails();
      try{
       if(Schema.sObjectType.User.isAccessible() && Schema.sObjectType.Account.isAccessible())
        {
       User usr=[SELECT id, AccountId from User WHERE Id = : userInfo.getUserId() WITH SECURITY_ENFORCED];
       Account acc=[SELECT ID,Name from Account where Id=:usr.AccountId WITH SECURITY_ENFORCED];
       effAcc.strAccountId=acc.Id;
       effAcc.strAccountName=acc.Name;
       effAcc.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'EffectiveAccount'); 
       }
    }
    catch(Exception ex){
       effAcc.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); 
       PMC_ErrorLogClass.processException(ex); // MDErrorLog
    }
      return effAcc;
   
  }
  
  /**
* @description Wrapper class for Effective Account Id
* @author @hemant.girigoswami 
* 
**/
// added with sharing
  public with sharing class PMC_DH_EffectiveAccountDetails{
    /**
   * @description  Id of Account 
   * @return String
   */
      @AuraEnabled
      public String strAccountId{get;set;}
      /**
   * @description  Name of Account 
   * @return String
   */
      @AuraEnabled
      public String strAccountName{get;set;}
      /**
   * @description Status Code and message
   * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
   */
  @AuraEnabled
  public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
}

/**
* @description Wrapper class for Effective Account Id
* @author @manishasingh9
* 
**/
// added with sharing
public with sharing class PMC_DH_AccountSwitcherModalWrapper{
 /**
 * @description list of Account Details string
 * @return String
 */
 @AuraEnabled
 public String strAccountData{get;set;}

 /**
 * @description Status Code and message
 * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
 */
 @AuraEnabled
 public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
}
}