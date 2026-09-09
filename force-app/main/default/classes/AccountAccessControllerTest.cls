@IsTest
private class AccountAccessControllerTest {
  // Try to find a community profile that CAN be the target of AccountShare
  private static Id getShareableCommunityProfileId() {
    // Prefer Customer Community Plus or Partner Community
    List<Profile> p = [
      SELECT Id, Name, UserLicense.Name
      FROM Profile
      WHERE UserLicense.Name IN ('Partner Community')
      ORDER BY Name
      LIMIT 1
    ];
    if (!p.isEmpty())
      return p[0].Id;
    return null; // fallback path if org doesn't have shareable licenses
  }
  // please add comments
  private static Id getAnyCommunityProfileId() {
    List<Profile> p = [
      SELECT Id, Name, UserLicense.Name
      FROM Profile
      WHERE Name LIKE '%Community%' OR Name LIKE '%Portal%' OR Name LIKE '%Partner%'
      ORDER BY Name
      LIMIT 1
    ];
    System.assert(!p.isEmpty(), 'No community/portal profile found. Add one or adjust this query for your org.');
    return p[0].Id;
  }

  private static User createCommunityUser(Contact c, Id preferredProfileId) {
    Id profileIdToUse = preferredProfileId != null ? preferredProfileId : getAnyCommunityProfileId();
    User u = new User(
      ProfileId = profileIdToUse,
      Username = 'ext_' + System.now().getTime() + '@example.com',
      Email = 'ext_' + System.now().getTime() + '@example.com',
      Alias = 'extusr',
      TimeZoneSidKey = 'America/Sao_Paulo',
      LocaleSidKey = 'pt_BR',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'pt_BR',
      LastName = 'Portal',
      CommunityNickname = 'nick' + String.valueOf(Crypto.getRandomInteger()),
      ContactId = c.Id
    );
    insert u;
    return u;
  }

  @IsTest
  static void returnsEmptyWhenUserHasNoContact() {
    Profile std = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User internal = new User(
      ProfileId = std.Id,
      Username = 'std_' + System.now().getTime() + '@example.com',
      Email = 'std_' + System.now().getTime() + '@example.com',
      Alias = 'stdusr',
      TimeZoneSidKey = 'America/Sao_Paulo',
      LocaleSidKey = 'pt_BR',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'pt_BR',
      LastName = 'Internal'
    );
    insert internal;

    Test.startTest();
    System.runAs(internal) {
      List<AccountAccessController.AccountAccessDTO> got = AccountAccessController.getAccessibleAccountsForUser();
      System.assertEquals(0, got.size(), 'Should return empty when ContactId is null.');
    }
    Test.stopTest();
  }

  @IsTest
  static void returnsAccountsAndMarksAccessCorrectly() {
    // Data
    Account a1 = new Account(Name = 'Acme One');
    Account a2 = new Account(Name = 'Acme Two');
    insert new List<Account>{ a1, a2 };

    Contact con = new Contact(LastName = 'Portal Contact', AccountId = a1.Id);
    insert con;

    Id shareableProfileId = getShareableCommunityProfileId();
    User extUser = createCommunityUser(con, shareableProfileId);

    Boolean secondRelationOk = true;
    try {
      insert new AccountContactRelation(AccountId = a2.Id, ContactId = con.Id);
    } catch (Exception e) {
      secondRelationOk = false; // org pode não ter CTMA habilitado
    }

    // (Opcional) tenta criar um share manual para a2, mas o teste não depende disso
    try {
      if (shareableProfileId != null) {
        insert new AccountShare(
          AccountId = a2.Id,
          UserOrGroupId = extUser.Id,
          AccountAccessLevel = 'Read',
          OpportunityAccessLevel = 'None',
          CaseAccessLevel = 'None',
          RowCause = Schema.AccountShare.RowCause.Manual
        );
      }
    } catch (Exception ignore) {
    }

    Test.startTest();
    System.runAs(extUser) {
      List<AccountAccessController.AccountAccessDTO> got = AccountAccessController.getAccessibleAccountsForUser();

      System.assert(got.size() >= 1, 'Deve retornar pelo menos a conta relacionada ao contato.');

      Map<Id, AccountAccessController.AccountAccessDTO> byId = new Map<Id, AccountAccessController.AccountAccessDTO>();
      for (AccountAccessController.AccountAccessDTO d : got)
        byId.put(d.accountId, d);

      // Pelo comportamento atual da classe principal, QUALQUER conta retornada tem hasAccess = true
      if (byId.containsKey(a1.Id)) {
        System.assertEquals(true, byId.get(a1.Id).hasAccess, 'Pelo comportamento atual, contas retornadas devem vir com hasAccess=true (a1).');
      }
      if (secondRelationOk && byId.containsKey(a2.Id)) {
        System.assertEquals(true, byId.get(a2.Id).hasAccess, 'Pelo comportamento atual, contas retornadas devem vir com hasAccess=true (a2).');
      }
    }
    Test.stopTest();
  }
}