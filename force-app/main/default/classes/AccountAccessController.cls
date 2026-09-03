public without sharing class AccountAccessController {
  @TestVisible
  public static List<AccountAccessDTO> testAccessibleAccounts;
  public class AccountAccessDTO {
    @AuraEnabled
    public Id accountId;
    @AuraEnabled
    public String accountName;
    @AuraEnabled
    public Boolean hasAccess;
    @AuraEnabled
    public String sapCustomerNumber;
    @AuraEnabled
    public String shippingAddress;

    public AccountAccessDTO() {
    }

    public AccountAccessDTO(Id id, String name, Boolean hasAccess, String sapCustomerNumber, String shippingAddress) {
      this.accountId = id;
      this.accountName = name;
      this.hasAccess = hasAccess;
      this.sapCustomerNumber = sapCustomerNumber;
      this.shippingAddress = shippingAddress;
    }
  }

  @AuraEnabled(cacheable=false)
  public static List<AccountAccessDTO> getAccessibleAccountsForUser() {
    Id uid = UserInfo.getUserId();
    Id contactId = [SELECT ContactId FROM User WHERE Id = :uid].ContactId;

    Set<Id> accountIds = new Set<Id>();
    if (contactId != null) {
      Date today = Date.today();

      for (AccountContactRelation acr : [
        SELECT AccountId, StartDate, EndDate, IsActive
        FROM AccountContactRelation
        WHERE ContactId = :contactId
      ]) {
        if (acr.StartDate != null && acr.StartDate > today)
          continue;
        if (acr.EndDate != null && acr.EndDate < today)
          continue;
        accountIds.add(acr.AccountId);
      }

      Contact c = [SELECT AccountId FROM Contact WHERE Id = :contactId];
      if (c.AccountId != null)
        accountIds.add(c.AccountId);
    }

    if (accountIds.isEmpty())
      return new List<AccountAccessDTO>();

    List<AccountAccessDTO> outp = new List<AccountAccessDTO>();
    for (Account a : [
      SELECT Id, Name, PMC_SS_SAPCustomerNumber__c, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
      FROM Account
      WHERE Id IN :accountIds
      ORDER BY Name
    ]) {
      String shippingAddr = '';
      System.debug(
        'Shipping Address: ' +
          a.ShippingStreet +
          ', ' +
          a.ShippingCity +
          ', ' +
          a.ShippingState +
          ', ' +
          a.ShippingPostalCode +
          ', ' +
          a.ShippingCountry
      );

      if (a.ShippingStreet != null)
        shippingAddr += a.ShippingStreet + ', ';
      if (a.ShippingCity != null)
        shippingAddr += a.ShippingCity + ', ';
      if (a.ShippingState != null)
        shippingAddr += a.ShippingState + ', ';
      if (a.ShippingPostalCode != null)
        shippingAddr += a.ShippingPostalCode + ', ';
      if (a.ShippingCountry != null)
        shippingAddr += a.ShippingCountry;
      shippingAddr = shippingAddr.trim().replaceAll(', $', '');

      outp.add(new AccountAccessDTO(a.Id, a.Name, true, a.PMC_SS_SAPCustomerNumber__c, shippingAddr));
      System.debug('Adding AccountAccessDTO: ' + a.Id + ', ' + a.Name + ', ' + a.PMC_SS_SAPCustomerNumber__c + ', ' + shippingAddr);
    }
    return outp;
  }

  @AuraEnabled(cacheable=true)
  public static Boolean canPlaceOrder() {
    Profile p = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
    return p.Name == 'Mosaic Direct Partner Community';
  }
}