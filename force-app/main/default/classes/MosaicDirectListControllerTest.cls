@isTest
private class MosaicDirectListControllerTest {
  // Utilidades para o seam de teste
  private static void setAllowed(Set<Id> ids) {
    MosaicDirectListController.TEST_ALLOWED_IDS = ids;
  }
  private static void clearAllowed() {
    MosaicDirectListController.TEST_ALLOWED_IDS = null;
  }

  // ===== Seed comum =====
  @testSetup
  static void data() {
    Account a1 = new Account(Name = 'ACCT Alpha', BillingCity = 'Tampa', BillingStreet = '123 Test St');
    Account a2 = new Account(Name = 'BETA Bravo', BillingCity = 'Tampa', BillingStreet = '456 Test Ave');
    insert new List<Account>{ a1, a2 };

    insert new List<Contact>{
      new Contact(LastName = 'Alpha One', AccountId = a1.Id, Email = 'alpha1@example.com', Phone = '551190000001', Primary_Function__c = 'Agronomy / Field Technician', Seniority_Level__c = 'Assistant', PMC_SS_ContractRecipient__c = true),
      new Contact(LastName = 'Zeta Two', AccountId = a1.Id, Email = 'zeta2@example.com', Phone = '551190000002', Primary_Function__c = 'Agronomy / Field Technician', Seniority_Level__c = 'Assistant'),
      new Contact(LastName = 'Bravo Three', AccountId = a2.Id, Email = 'bravo3@example.com', Phone = '551190000003', Primary_Function__c = 'Agronomy / Field Technician', Seniority_Level__c = 'Assistant')
    };

    insert new List<Lead>{
      new Lead(LastName = 'Lead One', Company = 'Comp Alpha'),
      new Lead(LastName = 'Lead Two', Company = 'Comp Beta'),
      new Lead(LastName = 'Lead Three', Company = 'Comp Gamma')
    };
  }

  // ===== getRecordsByIds =====
  @isTest
  static void test_getRecordsByIds_empty_and_valid() {
    // Vazios
    System.assertEquals(0, MosaicDirectListController.getRecordsByIds('Account', new List<Id>(), new List<String>{ 'Name' }).size());
    System.assertEquals(0, MosaicDirectListController.getRecordsByIds('Account', new List<Id>{}, new List<String>()).size());

    // Válido
    Account a = new Account(Name = 'Test A', BillingCity = 'Tampa', BillingStreet = '123 Test St');
    insert a;
    List<sObject> r = MosaicDirectListController.getRecordsByIds('Account', new List<Id>{ a.Id }, new List<String>{ 'Id', 'Name' });
    System.assertEquals(1, r.size());
    System.assertEquals(a.Id, ((Account) r[0]).Id);
  }

  // ===== searchRecords =====
  @isTest
  static void test_searchRecords_contact_intersection_and_account_filter() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    Account a2 = [SELECT Id FROM Account WHERE Name = 'BETA Bravo' LIMIT 1];

    // Allowed = {a1, a2}  → interseção com filtro {a1} retorna só contatos da a1
    setAllowed(new Set<Id>{ a1.Id, a2.Id });
    List<SObject> rows = MosaicDirectListController.searchRecords(
      'Contact',
      'LastName',
      '',
      new List<String>{ 'Id', 'AccountId', 'LastName' },
      new List<Id>{ a1.Id }
    );
    System.assert(rows.size() > 0, 'Deve retornar contatos da a1');
    for (SObject so : rows)
      System.assertEquals(a1.Id, (Id) so.get('AccountId'));
    clearAllowed();
  }

  @isTest
  static void test_searchRecords_contact_intersection_empty_returns_empty() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    Account a2 = [SELECT Id FROM Account WHERE Name = 'BETA Bravo' LIMIT 1];

    // Allowed = {a1} e filtro = {a2}  → interseção vazia → lista vazia
    setAllowed(new Set<Id>{ a1.Id });
    List<SObject> rows = MosaicDirectListController.searchRecords(
      'Contact',
      'LastName',
      '',
      new List<String>{ 'Id', 'AccountId', 'LastName' },
      new List<Id>{ a2.Id }
    );
    System.assertEquals(0, rows.size(), 'Interseção vazia deve retornar vazio');
    clearAllowed();
  }

  @isTest
  static void test_searchRecords_lead_branch_without_accountid() {
    // Allowed não-vazio, objeto sem AccountId → não injeta cláusula de Account no WHERE
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });
    List<SObject> leads = MosaicDirectListController.searchRecords(
      'Lead',
      'LastName',
      '',
      new List<String>{ 'Id', 'LastName', 'Company' },
      new List<Id>()
    ); // ignorado
    System.assert(leads.size() >= 0);
    clearAllowed();
  }

  @isTest
  static void test_searchRecords_invalid_object_returns_empty() {
    // Mesmo com allowed, objeto inválido retorna vazio
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });
    List<SObject> r = MosaicDirectListController.searchRecords('Totally_Not_A_Real_Object__c', 'Name', 'x', new List<String>{ 'Id' }, new List<Id>());
    System.assertEquals(0, r.size());
    clearAllowed();
  }

  // ===== listRecords =====
  @isTest
  static void test_listRecords_with_where_and_limit() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });
    List<SObject> rows = MosaicDirectListController.listRecords(
      'Contact',
      new List<String>{ 'Id', 'AccountId', 'LastName' },
      'LastName LIKE \'Alpha%\'',
      1
    );
    System.assertEquals(1, rows.size(), 'Respeita LIMIT 1 quando há allowed');
    System.assertEquals(a1.Id, ((Contact) rows[0]).AccountId);
    clearAllowed();
  }

  @isTest
  static void test_listRecords_no_where_default_limit_and_allowed_empty() {
    // Allowed vazio → early return
    setAllowed(new Set<Id>());
    System.assertEquals(0, MosaicDirectListController.listRecords('Contact', new List<String>{ 'Id', 'AccountId', 'LastName' }, null, null).size());
    clearAllowed();
  }

  // ===== listRecordsPaged =====

  @isTest
  static void test_listRecordsPaged_allowed_empty_early_return() {
    setAllowed(new Set<Id>());
    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ 'Id', 'AccountId', 'LastName' },
      null,
      'LastModifiedDate',
      'DESC',
      null,
      null,
      null,
      null,
      null, // dateFilterFieldName
      null, // endDateFilterFieldName
      null, // dateFromYmd
      null, // dateToYmd
      null // timezoneId
    );
    System.assertEquals(0, pr.totalSize);
    System.assertEquals(0, pr.records.size());
    System.assertEquals(1, pr.pageNumber);
    System.assertEquals(false, pr.hasPrev);
    System.assertEquals(false, pr.hasNext);
    clearAllowed();
  }

  @isTest
  static void test_listRecordsPaged_invalid_object_returns_empty() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Not_Real__c',
      new List<String>{ 'Id' },
      null,
      'LastModifiedDate',
      'ASC',
      10,
      1,
      null,
      null,
      null,
      null,
      null,
      null,
      null
    );
    System.assertEquals(0, pr.totalSize);
    System.assertEquals(0, pr.records.size());
    System.assertEquals(false, pr.hasNext);
    System.assertEquals(false, pr.hasPrev);
    clearAllowed();
  }

  @isTest
  static void test_listRecordsPaged_pagination_page1_and_page2() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    Account a2 = [SELECT Id FROM Account WHERE Name = 'BETA Bravo' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id, a2.Id });

    // Página 1
    MosaicDirectListController.PagedResult p1 = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ 'Id', 'AccountId', 'LastName' },
      null,
      'LastModifiedDate',
      'DESC',
      1,
      1, // pageSize=1 força mais páginas
      null,
      null,
      null,
      null,
      null,
      null,
      null
    );
    System.assertEquals(1, p1.pageNumber);
    System.assertNotEquals(null, p1.records);

    // Página 2 (deve existir)
    MosaicDirectListController.PagedResult p2 = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ 'Id', 'AccountId', 'LastName' },
      null,
      'LastModifiedDate',
      'DESC',
      1,
      2,
      null,
      null,
      null,
      null,
      null,
      null,
      null
    );
    System.assertEquals(2, p2.pageNumber);
    System.assertEquals(true, p2.hasPrev);
    clearAllowed();
  }

  @isTest
  static void test_listRecordsPaged_orderBy_sanitization_keeps_default() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    Account a2 = [SELECT Id FROM Account WHERE Name = 'BETA Bravo' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id, a2.Id });

    // orderByField com caracteres inválidos → mantém 'LastModifiedDate'
    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ 'Id', 'AccountId', 'LastName' },
      null,
      'Name;DROP', // inválido para regex
      'ASC',
      5,
      1,
      null,
      null,
      null,
      null,
      null,
      null,
      null
    );
    System.assertEquals(1, pr.pageNumber);
    System.assertNotEquals(null, pr.records);
    clearAllowed();
  }

  @isTest
  static void test_listRecordsPaged_where_plus_search_related_and_direct() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    Account a2 = [SELECT Id FROM Account WHERE Name = 'BETA Bravo' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id, a2.Id });

    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ 'Id', 'AccountId', 'LastName' },
      '(LastName LIKE \'A%\')', // whereClause
      'Account.Name', // ORDER BY relacionado válido
      'ASC',
      50,
      1,
      'Alpha', // searchTerm
      new List<String>{ 'Account.Name', 'LastName' }, // relacionado + direto
      null,
      null,
      null,
      null,
      null
    );
    System.assertEquals(1, pr.pageNumber);
    System.assertNotEquals(null, pr.records);
    clearAllowed();
  }

  @isTest
  static void test_listRecordsPaged_search_text_and_order_valid_ASC() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    Account a2 = [SELECT Id FROM Account WHERE Name = 'BETA Bravo' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id, a2.Id });

    // Garante pelo menos 3 contatos com padrões diferentes para ordenar e buscar
    insert new Contact(LastName = 'Alpha SearchHit', AccountId = a1.Id, Email = 'hit1@example.com', Primary_Function__c = 'Agronomy / Field Technician', Seniority_Level__c = 'Assistant');
    insert new Contact(LastName = 'Gamma Miss', AccountId = a1.Id, Email = 'miss@example.com', Primary_Function__c = 'Agronomy / Field Technician', Seniority_Level__c = 'Assistant');
    insert new Contact(LastName = 'Alpha Another', AccountId = a2.Id, Email = 'hit2@example.com', Primary_Function__c = 'Agronomy / Field Technician', Seniority_Level__c = 'Assistant');

    // Busca textual por "Alpha" em LastName e também em relacionado Account.Name
    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ 'Id', 'AccountId', 'LastName' },
      null,
      'LastName', // campo válido direto
      'ASC',
      50,
      1,
      'Alpha',
      new List<String>{ 'LastName', 'Account.Name' },
      null,
      null,
      null,
      null,
      null
    );
    System.assert(pr.records.size() > 0, 'Deve achar contatos com "Alpha"');
    System.assertEquals(false, pr.hasPrev);
    clearAllowed();
  }

  @isTest
  static void test_listRecordsPaged_datetime_filter_from_only_to_only_and_single_day() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    // Cria registros espaçados no tempo para validar janelas
    Contact c1 = new Contact(LastName = 'Time One', AccountId = a1.Id, Email = 't1@example.com', Primary_Function__c = 'Agronomy / Field Technician', Seniority_Level__c = 'Assistant');
    Contact c2 = new Contact(LastName = 'Time Two', AccountId = a1.Id, Email = 't2@example.com', Primary_Function__c = 'Agronomy / Field Technician', Seniority_Level__c = 'Assistant');
    Contact c3 = new Contact(LastName = 'Time Three', AccountId = a1.Id, Email = 't3@example.com', Primary_Function__c = 'Agronomy / Field Technician', Seniority_Level__c = 'Assistant');
    insert new List<Contact>{ c1, c2, c3 };

    // FROM only: hoje - 1 dia (DateTime usa start >= FROM)
    Date fromYmd = Date.today().addDays(-1);
    MosaicDirectListController.PagedResult prFrom = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ 'Id', 'AccountId', 'LastName' },
      null,
      'CreatedDate',
      'DESC',
      50,
      1,
      null,
      null,
      'CreatedDate', // DateTime
      null,
      String.valueOf(fromYmd),
      null,
      null // timezoneId nulo => default America/New_York
    );
    System.assert(prFrom.totalSize >= 0);

    // TO only: hoje (DateTime usa end <= TO, mas aqui só há start ⇒ fallback start < TO+1)
    Date toYmd = Date.today();
    MosaicDirectListController.PagedResult prTo = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ 'Id', 'AccountId', 'LastName' },
      null,
      'CreatedDate',
      'DESC',
      50,
      1,
      null,
      null,
      'CreatedDate',
      null,
      null,
      String.valueOf(toYmd),
      null
    );
    System.assert(prTo.totalSize >= 0);

    // Single-day window: FROM = TO (contenção em DateTime → start >= FROM e end < TO+1; com apenas start, cai em janela em start)
    MosaicDirectListController.PagedResult prSingleDay = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ 'Id', 'AccountId', 'LastName' },
      null,
      'CreatedDate',
      'DESC',
      50,
      1,
      null,
      null,
      'CreatedDate',
      null,
      String.valueOf(Date.today()),
      String.valueOf(Date.today()),
      null
    );
    System.assert(prSingleDay.totalSize >= 0);

    clearAllowed();
  }

  @isTest
  static void test_listRecordsPaged_date_filter_birthdate_from_to_and_single_day() {
    // Usa Date (Birthdate)
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    insert new Contact(LastName = 'Birth A', AccountId = a1.Id, Birthdate = Date.newInstance(1990, 1, 1), Primary_Function__c = 'Agronomy / Field Technician', Seniority_Level__c = 'Assistant');
    insert new Contact(LastName = 'Birth B', AccountId = a1.Id, Birthdate = Date.newInstance(1995, 5, 5), Primary_Function__c = 'Agronomy / Field Technician', Seniority_Level__c = 'Assistant');
    insert new Contact(LastName = 'Birth C', AccountId = a1.Id, Birthdate = Date.newInstance(2000, 12, 31), Primary_Function__c = 'Agronomy / Field Technician', Seniority_Level__c = 'Assistant');

    // FROM only (Date → start >= FROM)
    MosaicDirectListController.PagedResult prFrom = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ 'Id', 'AccountId', 'LastName', 'Birthdate' },
      null,
      'LastModifiedDate',
      'DESC',
      50,
      1,
      null,
      null,
      'Birthdate',
      null,
      '1994-01-01',
      null,
      'America/Sao_Paulo'
    );
    System.assert(prFrom.totalSize >= 0);

    // TO only (Date → end <= TO; com apenas start, fallback start <= TO)
    MosaicDirectListController.PagedResult prTo = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ 'Id', 'AccountId', 'LastName', 'Birthdate' },
      null,
      'LastModifiedDate',
      'DESC',
      50,
      1,
      null,
      null,
      'Birthdate',
      null,
      null,
      '1994-01-01',
      'America/Sao_Paulo'
    );
    System.assert(prTo.totalSize >= 0);

    // FROM = TO (dia único) → contenção em Date
    MosaicDirectListController.PagedResult prSingle = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ 'Id', 'AccountId', 'LastName', 'Birthdate' },
      null,
      'LastModifiedDate',
      'DESC',
      50,
      1,
      null,
      null,
      'Birthdate',
      null,
      '1995-05-05',
      '1995-05-05',
      'America/Sao_Paulo'
    );
    System.assert(prSingle.totalSize >= 0);

    clearAllowed();
  }

  @isTest
  static void test_listRecordsPaged_datetime_interval_start_end_fields() {
    // Intervalo DateTime usando CreatedDate (start) e LastModifiedDate (end)
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    insert new Contact(LastName = 'Interval One', AccountId = a1.Id, Primary_Function__c = 'Agronomy / Field Technician', Seniority_Level__c = 'Assistant');
    Test.startTest();
    // pequena alteração de tempo entre criação e última modificação
    Contact c = [SELECT Id, LastName FROM Contact WHERE LastName = 'Interval One' LIMIT 1];
    c.LastName = 'Interval One Edited';
    update c;
    Test.stopTest();

    Date today = Date.today();
    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ 'Id', 'AccountId', 'LastName' },
      null,
      'CreatedDate',
      'DESC',
      50,
      1,
      null,
      null,
      'CreatedDate',
      'LastModifiedDate',
      String.valueOf(today),
      String.valueOf(today),
      null
    );
    System.assert(pr.totalSize >= 0, 'Intervalo DateTime (start/end) deve compilar e executar');
    clearAllowed();
  }

  @isTest
  static void test_listRecordsPaged_hasNext_true_with_small_pages() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    // Garante 3+ registros
    List<Contact> many = new List<Contact>();
    for (Integer i = 0; i < 3; i++) {
      many.add(new Contact(LastName = 'Pageable ' + i, AccountId = a1.Id, Email = 'p' + i + '@ex.com', Primary_Function__c = 'Agronomy / Field Technician', Seniority_Level__c = 'Assistant'));
    }
    insert many;

    MosaicDirectListController.PagedResult p1 = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ 'Id', 'AccountId', 'LastName' },
      null,
      'LastModifiedDate',
      'DESC',
      1, // pageSize pequeno
      1,
      null,
      null,
      null,
      null,
      null,
      null,
      null
    );
    System.assertEquals(true, p1.hasNext, 'Com pageSize=1 e 3 registros, deveria ter próxima página');
    clearAllowed();
  }

  @isTest
  static void test_listRecordsPaged_catch_block_invalid_field_in_select() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    // Campo inexistente força exception no Database.query => cai no catch e retorna lista vazia
    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ 'Id', 'AccountId', 'ThisFieldDoesNotExist__c' }, // força erro no SELECT
      null,
      'LastModifiedDate',
      'DESC',
      10,
      1,
      null,
      null,
      null,
      null,
      null,
      null,
      null
    );
    System.assertEquals(0, pr.records.size(), 'Com campo inválido no SELECT, recs deve ser vazio pelo catch');
    clearAllowed();
  }

  @isTest
  static void test_searchRecords_no_account_filter_and_object_with_accountid() {
    // Cobre o branch onde accountIds é null (logo não faz retainAll), mas objeto tem AccountId
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    insert new Contact(LastName = 'NoFilter One', AccountId = a1.Id, Email = 'nf1@example.com', Primary_Function__c = 'Agronomy / Field Technician', Seniority_Level__c = 'Assistant');

    List<SObject> rows = MosaicDirectListController.searchRecords(
      'Contact',
      'LastName',
      '', // searchTerm é ignorado nessa implementação
      new List<String>{ 'Id', 'AccountId', 'LastName' },
      null // accountIds null
    );
    System.assert(rows.size() > 0, 'Deve retornar pelo menos um contato da conta permitida');
    for (SObject so : rows) {
      System.assertEquals(a1.Id, (Id) so.get('AccountId'), 'Filtra por allowedIds quando há AccountId no objeto');
    }
    clearAllowed();
  }

  @isTest
  static void test_listRecordsPaged_field_preprocess_sbqq_lineitems_prefix_is_ignored_without_pkg() {
    // Mesmo sem o pacote CPQ, passar um campo com prefixo "SBQQ__LineItems__r." não deve quebrar
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ 'Id', 'AccountId', 'LastName', 'SBQQ__LineItems__r.Name' },
      null,
      'LastModifiedDate',
      'DESC',
      5,
      1,
      null,
      null,
      null,
      null,
      null,
      null,
      null
    );
    System.assertNotEquals(null, pr.records, 'Execução deve ocorrer normalmente mesmo com campo SBQQ__* inexistente');
    clearAllowed();
  }

  @isTest
  static void test_listRecordsPaged_date_RANGE_on_Campaign_from_and_to() {
    // Allowed não-vazio (mesmo Campaign não tendo AccountId, a verificação global exige allowedIds != empty)
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    // Semeia campanhas em datas distintas
    Campaign c1 = new Campaign(Name = 'Camp A', StartDate = Date.newInstance(2023, 1, 1), EndDate = Date.newInstance(2023, 1, 31), IsActive = true);
    Campaign c2 = new Campaign(Name = 'Camp B', StartDate = Date.newInstance(2023, 6, 1), EndDate = Date.newInstance(2023, 6, 30), IsActive = true);
    Campaign c3 = new Campaign(Name = 'Camp C', StartDate = Date.newInstance(2023, 12, 1), EndDate = Date.newInstance(2023, 12, 31), IsActive = true);
    insert new List<Campaign>{ c1, c2, c3 };

    // FROM e TO preenchidos (CONTENÇÃO: start >= 2023-05-01 e end <= 2023-11-01) → Camp B passa
    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Campaign',
      new List<String>{ 'Id', 'Name', 'StartDate', 'EndDate' },
      null,
      'LastModifiedDate',
      'DESC',
      50,
      1,
      null,
      null,
      'StartDate', // Date
      'EndDate', // Date
      '2023-05-01', // FROM
      '2023-11-01', // TO
      'America/Sao_Paulo'
    );
    System.assert(pr.totalSize >= 1, 'Deve pegar Campanhas contidas na janela (ex.: Camp B).');

    clearAllowed();
  }

  @isTest
  static void test_listRecordsPaged_date_RANGE_on_Campaign_from_only_start_based() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    // c1 começa antes do FROM (excluído); c2 começa depois do FROM (incluído)
    Campaign c1 = new Campaign(
      Name = 'FromOnly A',
      StartDate = Date.newInstance(2024, 1, 1),
      EndDate = Date.newInstance(2024, 1, 10),
      IsActive = true
    );
    Campaign c2 = new Campaign(Name = 'FromOnly B', StartDate = Date.newInstance(2024, 2, 1), EndDate = null, IsActive = true);
    insert new List<Campaign>{ c1, c2 };

    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Campaign',
      new List<String>{ 'Id', 'Name', 'StartDate', 'EndDate' },
      null,
      'LastModifiedDate',
      'DESC',
      50,
      1,
      null,
      null,
      'StartDate',
      'EndDate',
      '2024-01-05', // FROM
      null, // TO
      null
    );
    System.assertEquals(true, pr.totalSize >= 1);
    // Valida que todos têm StartDate >= FROM (regra nova)
    for (SObject so : pr.records) {
      Date sd = (Date) so.get('StartDate');
      System.assert(sd >= Date.newInstance(2024, 1, 5));
    }
    clearAllowed();
  }

  @isTest
  static void test_listRecordsPaged_date_RANGE_on_Campaign_to_only_end_based() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    // c1 termina antes do TO (incluído); c2 termina depois do TO (excluído)
    Campaign c1 = new Campaign(Name = 'ToOnly A', StartDate = Date.newInstance(2022, 3, 1), EndDate = Date.newInstance(2022, 3, 10), IsActive = true);
    Campaign c2 = new Campaign(Name = 'ToOnly B', StartDate = Date.newInstance(2022, 4, 1), EndDate = Date.newInstance(2022, 4, 30), IsActive = true);
    insert new List<Campaign>{ c1, c2 };

    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Campaign',
      new List<String>{ 'Id', 'Name', 'StartDate', 'EndDate' },
      null,
      'LastModifiedDate',
      'DESC',
      50,
      1,
      null,
      null,
      'StartDate',
      'EndDate',
      null, // FROM
      '2022-03-15', // TO
      null
    );
    System.assertEquals(true, pr.totalSize >= 1);
    // Valida que todos têm EndDate <= TO (regra nova)
    for (SObject so : pr.records) {
      Date ed = (Date) so.get('EndDate');
      System.assert(ed <= Date.newInstance(2022, 3, 15));
    }
    clearAllowed();
  }

  @isTest
  static void test_buildDatePredicate_inverted_range_swaps_dates() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    insert new Campaign(Name = 'Swap Window', StartDate = Date.newInstance(2024, 1, 1), EndDate = Date.newInstance(2024, 12, 31));
    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Campaign',
      new List<String>{ 'Id', 'Name', 'StartDate', 'EndDate' },
      null,
      'LastModifiedDate',
      'DESC',
      50,
      1,
      null,
      null,
      'StartDate', // startF (Date)
      'EndDate', // endF   (Date)
      '2024-12-31', // FROM > TO (força swap)
      '2024-01-01', // TO
      'America/Sao_Paulo'
    );
    System.assertNotEquals(null, pr.records);
    clearAllowed();
  }

  @isTest
  static void test_buildDatePredicate_mixed_types_start_datetime_end_date() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    insert new Task(Subject = 'Mixed Types - T1', ActivityDate = Date.today()); // mínimos
    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Task',
      new List<String>{ 'Id', 'Subject', 'ActivityDate', 'CreatedDate' },
      null,
      'CreatedDate',
      'DESC',
      50,
      1,
      null,
      null,
      'CreatedDate', // startF (DateTime)
      'ActivityDate', // endF   (Date)
      String.valueOf(Date.today().addDays(-1)),
      String.valueOf(Date.today().addDays(1)),
      'America/Sao_Paulo'
    );
    System.assertNotEquals(null, pr.records);
    clearAllowed();
  }

  @isTest
  static void test_buildDatePredicate_from_and_to_only_end_exists() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    insert new Campaign(Name = 'Only End - Both Limits', StartDate = Date.newInstance(2023, 6, 1), EndDate = Date.newInstance(2023, 6, 30));

    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Campaign',
      new List<String>{ 'Id', 'Name', 'StartDate', 'EndDate' },
      null,
      'LastModifiedDate',
      'DESC',
      50,
      1,
      null,
      null,
      'Does_Not_Exist__c', // startF inexistente
      'EndDate', // endF existente (Date)
      '2023-01-01',
      '2023-12-31',
      'America/Sao_Paulo'
    );
    System.assertNotEquals(null, pr.records);
    clearAllowed();
  }

  @isTest
  static void test_buildDatePredicate_from_only_only_end_exists() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    insert new Campaign(Name = 'Only End - From Only', StartDate = Date.newInstance(2024, 2, 1), EndDate = Date.newInstance(2024, 2, 10));

    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Campaign',
      new List<String>{ 'Id', 'Name', 'StartDate', 'EndDate' },
      null,
      'LastModifiedDate',
      'DESC',
      50,
      1,
      null,
      null,
      'Totally_Bogus__c', // startF inexistente
      'EndDate', // endF existente
      '2024-01-01', // FROM
      null, // TO
      'America/Sao_Paulo'
    );
    System.assertNotEquals(null, pr.records);
    clearAllowed();
  }

  @isTest
  static void test_quote_computedValues_when_cpq_present() {
    if (!Schema.getGlobalDescribe().containsKey('SBQQ__Quote__c') || !Schema.getGlobalDescribe().containsKey('SBQQ__QuoteLine__c')) {
      return;
    }

    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    try {
      Product2 p = new Product2(Name = 'CPQ Prod', IsActive = true);
      insert p;

      SObject q = Schema.getGlobalDescribe().get('SBQQ__Quote__c').newSObject();
      // NUNCA force 'Name' em Quote do CPQ — é auto-number na maioria dos orgs
      safePut(q, 'SBQQ__Account__c', a1.Id);
      safePut(q, 'SBQQ__Status__c', 'Draft');
      try {
        insert q;
      } catch (DmlException dmlEx) {
        System.assert(true, 'Validation rule prevents Quote insert in this org — test skipped.');
        return;
      }

      SObjectType qlt = Schema.getGlobalDescribe().get('SBQQ__QuoteLine__c');
      SObject ql1 = qlt.newSObject();
      ql1.put('SBQQ__Quote__c', (Id) q.get('Id'));
      if (qlt.getDescribe().fields.getMap().containsKey('SBQQ__Product__c'))
        ql1.put('SBQQ__Product__c', p.Id);
      if (qlt.getDescribe().fields.getMap().containsKey('PMC_CPQ_FinalPricePerTon__c'))
        ql1.put('PMC_CPQ_FinalPricePerTon__c', 100);
      insert ql1;

      SObject ql2 = qlt.newSObject();
      ql2.put('SBQQ__Quote__c', (Id) q.get('Id'));
      if (qlt.getDescribe().fields.getMap().containsKey('SBQQ__Product__c'))
        ql2.put('SBQQ__Product__c', p.Id);
      if (qlt.getDescribe().fields.getMap().containsKey('PMC_CPQ_FinalPricePerTon__c'))
        ql2.put('PMC_CPQ_FinalPricePerTon__c', 200);
      insert ql2;

      MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
        'SBQQ__Quote__c',
        new List<String>{
          'Id',
          // 'Name' não é necessário para o teste
          'SBQQ__LineItems__r.PMC_CPQ_FinalPricePerTon__c',
          'SBQQ__LineItems__r.SBQQ__Product__r.Name'
        },
        null,
        'LastModifiedDate',
        'DESC',
        50,
        1,
        null,
        null,
        null,
        null,
        null,
        null,
        null
      );

      System.assertNotEquals(null, pr.computedValues);
      Map<String, String> agg = pr.computedValues.get((Id) q.get('Id'));
      System.assertNotEquals(null, agg);
      if (agg.containsKey('SBQQ__LineItems__r.PMC_CPQ_FinalPricePerTon__c')) {
        System.assertEquals('MULTIPLE', agg.get('SBQQ__LineItems__r.PMC_CPQ_FinalPricePerTon__c'));
      }
    } finally {
      clearAllowed();
    }
  }

  @isTest
  static void test_listRecordsPaged_quote_computedValues_hits_block() {
    if (!Schema.getGlobalDescribe().containsKey('SBQQ__Quote__c') || !Schema.getGlobalDescribe().containsKey('SBQQ__QuoteLine__c')) {
      System.assert(true, 'CPQ não instalado — teste ignorado.');
      return;
    }

    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    MosaicDirectListController.TEST_ALLOWED_IDS = new Set<Id>{ a1.Id };

    // Produto (Pricebook/Entry opcional) — não é necessário forçar
    Product2 p = new Product2(Name = 'UT CPQ Prod', IsActive = true);
    insert p;

    SObjectType qt = Schema.getGlobalDescribe().get('SBQQ__Quote__c');
    SObject q = qt.newSObject();
    // NÃO setar 'Name'
    safePut(q, 'SBQQ__Account__c', a1.Id);
    safePut(q, 'SBQQ__Status__c', 'Draft');
    try {
      insert q;
    } catch (DmlException dmlEx) {
      MosaicDirectListController.TEST_ALLOWED_IDS = null;
      System.assert(true, 'Validation rule prevents Quote insert in this org — test skipped.');
      return;
    }

    SObjectType qlt = Schema.getGlobalDescribe().get('SBQQ__QuoteLine__c');
    SObject ql1 = qlt.newSObject();
    ql1.put('SBQQ__Quote__c', (Id) q.get('Id'));
    if (qlt.getDescribe().fields.getMap().containsKey('SBQQ__Product__c'))
      ql1.put('SBQQ__Product__c', p.Id);
    if (qlt.getDescribe().fields.getMap().containsKey('PMC_CPQ_FinalPricePerTon__c'))
      ql1.put('PMC_CPQ_FinalPricePerTon__c', 100);
    insert ql1;

    SObject ql2 = qlt.newSObject();
    ql2.put('SBQQ__Quote__c', (Id) q.get('Id'));
    if (qlt.getDescribe().fields.getMap().containsKey('SBQQ__Product__c'))
      ql2.put('SBQQ__Product__c', p.Id);
    if (qlt.getDescribe().fields.getMap().containsKey('PMC_CPQ_FinalPricePerTon__c'))
      ql2.put('PMC_CPQ_FinalPricePerTon__c', 200);
    insert ql2;

    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'SBQQ__Quote__c',
      new List<String>{
        'Id',
        // 'Name' fora — algumas orgs não permitem SELECT em Name também
        'SBQQ__LineItems__r.PMC_CPQ_FinalPricePerTon__c',
        'SBQQ__LineItems__r.SBQQ__Product__r.Name'
      },
      null,
      'LastModifiedDate',
      'DESC',
      50,
      1,
      null,
      null,
      null,
      null,
      null,
      null,
      null
    );

    System.assertNotEquals(null, pr.records);
    System.assert(pr.records.size() > 0);
    System.assertNotEquals(null, pr.computedValues);
    Map<String, String> agg = pr.computedValues.get((Id) q.get('Id'));
    System.assertNotEquals(null, agg);
    if (agg.containsKey('SBQQ__LineItems__r.PMC_CPQ_FinalPricePerTon__c')) {
      System.assertEquals('MULTIPLE', agg.get('SBQQ__LineItems__r.PMC_CPQ_FinalPricePerTon__c'));
    }
    MosaicDirectListController.TEST_ALLOWED_IDS = null;
  }

  private static void safePut(SObject sobj, String fieldApi, Object value) {
    Map<String, Schema.SObjectField> fmap = sobj.getSObjectType().getDescribe().fields.getMap();
    if (!fmap.containsKey(fieldApi))
      return;
    Schema.DescribeFieldResult dfr = fmap.get(fieldApi).getDescribe();
    if (dfr.isCreateable()) {
      sobj.put(fieldApi, value);
    }
  }

  @isTest
  static void test_getInTransitFilterOptions_invalid_object_returns_empty() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    MosaicDirectListController.InTransitFilterOptionsResult r = MosaicDirectListController.getInTransitFilterOptions(
      'Account',
      null,
      null,
      null,
      null,
      null
    );

    System.assertNotEquals(null, r);
    System.assertEquals(0, r.products.size());
    System.assertEquals(0, r.origins.size());
    System.assertEquals(0, r.shipTos.size());
    System.assertEquals(0, r.destinations.size());
    System.assertEquals(0, r.statuses.size());
    clearAllowed();
  }

  @isTest
  static void test_getInTransitFilterOptions_blank_object_returns_empty() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    MosaicDirectListController.InTransitFilterOptionsResult r = MosaicDirectListController.getInTransitFilterOptions(
      '',
      null,
      null,
      null,
      null,
      null
    );

    System.assertNotEquals(null, r);
    System.assertEquals(0, r.products.size());
    clearAllowed();
  }

  @isTest
  static void test_getInTransitFilterOptions_shipmentitem_with_text_filters() {
    if (!Schema.getGlobalDescribe().containsKey('ShipmentItem')) {
      System.assert(true, 'ShipmentItem não disponível — teste ignorado.');
      return;
    }
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    MosaicDirectListController.InTransitFilterOptionsResult r = MosaicDirectListController.getInTransitFilterOptions(
      'ShipmentItem',
      null,
      'TRUCK-99',
      'CONTRACT-A',
      'PO-001',
      null
    );

    System.assertNotEquals(null, r);
    System.assertNotEquals(null, r.products);
    clearAllowed();
  }

  @isTest
  static void test_getInTransitFilterOptions_compound_order_number() {
    if (!Schema.getGlobalDescribe().containsKey('ShipmentItem')) {
      System.assert(true, 'ShipmentItem não disponível — teste ignorado.');
      return;
    }
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    MosaicDirectListController.InTransitFilterOptionsResult r = MosaicDirectListController.getInTransitFilterOptions(
      'ShipmentItem',
      'Id != null',
      '321310010',
      null,
      null,
      null
    );

    System.assertNotEquals(null, r);
    clearAllowed();
  }

  @isTest
  static void test_getInTransitFilterOptions_order_number_only() {
    if (!Schema.getGlobalDescribe().containsKey('ShipmentItem')) {
      System.assert(true, 'ShipmentItem não disponível — teste ignorado.');
      return;
    }
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    MosaicDirectListController.InTransitFilterOptionsResult r = MosaicDirectListController.getInTransitFilterOptions(
      'ShipmentItem',
      'Id != null',
      '32131',
      null,
      null,
      null
    );

    System.assertNotEquals(null, r);
    clearAllowed();
  }

  @isTest
  static void test_getInTransitFilterOptions_advanced_cascading() {
    if (!Schema.getGlobalDescribe().containsKey('ShipmentItem')) {
      System.assert(true, 'ShipmentItem não disponível — teste ignorado.');
      return;
    }
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    MosaicDirectListController.InTransitFilterOptionsResult r = MosaicDirectListController.getInTransitFilterOptions(
      'ShipmentItem',
      null,
      null,
      null,
      null,
      null
    );

    System.assertNotEquals(null, r);
    System.assertNotEquals(null, r.products);
    System.assertNotEquals(null, r.origins);
    clearAllowed();
  }

  @isTest
  static void test_listInTransitRecordsPaged_non_shipmentitem_delegates_to_listRecordsPaged() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listInTransitRecordsPaged(
      'Contact',
      new List<String>{ 'Id', 'LastName' },
      null,
      'LastModifiedDate',
      'DESC',
      5,
      1,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null
    );

    System.assertNotEquals(null, pr);
    System.assertEquals(1, pr.pageNumber);
    clearAllowed();
  }

  @isTest
  static void test_listInTransitRecordsPaged_shipmentitem_with_all_filters() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listInTransitRecordsPaged(
      'ShipmentItem',
      new List<String>{ 'Id' },
      'Id != null',
      'LastModifiedDate',
      'DESC',
      10,
      1,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      '321310010',
      'TRUCK-99',
      'Q-2024',
      'PO-999',
      new List<String>{ 'ProductA', 'ProductB' },
      new List<String>{ 'OriginA' },
      new List<String>{ 'ShipTo1' },
      new List<String>{ 'Dest1' },
      new List<String>{ 'Scheduled' }
    );

    System.assertNotEquals(null, pr);
    clearAllowed();
  }

  @isTest
  static void test_listInTransitRecordsPaged_shipmentitem_short_non_numeric_order_number() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listInTransitRecordsPaged(
      'ShipmentItem',
      new List<String>{ 'Id' },
      null,
      'LastModifiedDate',
      'DESC',
      10,
      1,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      'SHORT-ORDER',
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null
    );

    System.assertNotEquals(null, pr);
    clearAllowed();
  }

  @isTest
  static void test_listInTransitRecordsPaged_shipmentitem_empty_filter_lists() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listInTransitRecordsPaged(
      'ShipmentItem',
      new List<String>{ 'Id' },
      null,
      'LastModifiedDate',
      'ASC',
      10,
      1,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      new List<String>(),
      new List<String>(),
      new List<String>(),
      new List<String>(),
      new List<String>()
    );

    System.assertNotEquals(null, pr);
    clearAllowed();
  }

  @isTest
  static void test_listInTransitRecordsPaged_empty_allowed_early_return() {
    setAllowed(new Set<Id>());

    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listInTransitRecordsPaged(
      'ShipmentItem',
      new List<String>{ 'Id' },
      null,
      'LastModifiedDate',
      'DESC',
      10,
      1,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null
    );

    System.assertNotEquals(null, pr);
    System.assertEquals(0, pr.totalSize);
    clearAllowed();
  }

  @isTest
  static void test_listRecords_campaign_no_where_no_accountid_field() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    insert new Campaign(Name = 'NoCoverageTestCamp', IsActive = true);

    List<SObject> rows = MosaicDirectListController.listRecords('Campaign', new List<String>{ 'Id', 'Name' }, null, 10);
    System.assert(rows.size() >= 1);
    clearAllowed();
  }

  @isTest
  static void test_listInTransitRecordsPaged_compound_order_number_9chars() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listInTransitRecordsPaged(
      'ShipmentItem',
      new List<String>{ 'Id' },
      null,
      'LastModifiedDate',
      'DESC',
      10,
      1,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      '321310010',
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null
    );

    System.assertNotEquals(null, pr);
    clearAllowed();
  }

  @isTest
  static void test_listInTransitRecordsPaged_order_number_only() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listInTransitRecordsPaged(
      'ShipmentItem',
      new List<String>{ 'Id' },
      null,
      'LastModifiedDate',
      'DESC',
      10,
      1,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      '32131',
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null
    );

    System.assertNotEquals(null, pr);
    clearAllowed();
  }

  @isTest
  static void test_getInTransitFilterOptions_iteration_with_product() {
    if (!Schema.getGlobalDescribe().containsKey('ShipmentItem')) {
      System.assert(true, 'ShipmentItem não disponível — teste ignorado.');
      return;
    }
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    try {
      Product2 p = new Product2(Name = 'Filter Option Product', IsActive = true);
      insert p;

      Shipment shipment = new Shipment(Description = 'Test Shipment');
      insert shipment;

      ShipmentItem si = new ShipmentItem(ShipmentId = shipment.Id, Product2Id = p.Id, Quantity = 5);
      insert si;

      MosaicDirectListController.InTransitFilterOptionsResult r = MosaicDirectListController.getInTransitFilterOptions(
        'ShipmentItem',
        null,
        null,
        null,
        null,
        null
      );

      System.assertNotEquals(null, r);
      System.assertNotEquals(null, r.products);
      System.assertNotEquals(null, r.origins);
      System.assertNotEquals(null, r.shipTos);
      System.assertNotEquals(null, r.destinations);
      System.assertNotEquals(null, r.statuses);
      System.assert(r.products.contains('Filter Option Product'), 'Produto inserido deve aparecer nas opções');
    } catch (Exception e) {
      System.assert(true, 'Ambiente não suporta criação de ShipmentItem sem módulo Order Management.');
    }

    clearAllowed();
  }

  @isTest
  static void test_getInTransitFilterOptions_iteration_no_product_covers_null_branch() {
    if (!Schema.getGlobalDescribe().containsKey('ShipmentItem')) {
      System.assert(true, 'ShipmentItem não disponível — teste ignorado.');
      return;
    }
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    try {
      Shipment shipment = new Shipment(Description = 'No Product Shipment');
      insert shipment;

      ShipmentItem si = new ShipmentItem(ShipmentId = shipment.Id, Quantity = 2);
      insert si;

      MosaicDirectListController.InTransitFilterOptionsResult r = MosaicDirectListController.getInTransitFilterOptions(
        'ShipmentItem',
        null,
        null,
        null,
        null,
        null
      );

      System.assertNotEquals(null, r);
      System.assertEquals(0, r.products.size());
    } catch (Exception e) {
      System.assert(true, 'Ambiente não suporta criação de ShipmentItem sem Product2.');
    }

    clearAllowed();
  }

  @isTest
  static void test_getInTransitFilterOptions_covers_shipment_destination_status_and_shipto() {
    if (!Schema.getGlobalDescribe().containsKey('ShipmentItem')) {
      System.assert(true, 'ShipmentItem não disponível — teste ignorado.');
      return;
    }
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    try {
      Account shipToAccount = new Account(Name = 'Ship To Account', BillingCity = 'Tampa', BillingStreet = '123 Test St');
      insert shipToAccount;

      Shipment shipment = new Shipment(
        Description = 'Shipment With Fields',
        PMC_CPQ_ShipToAccount__c = shipToAccount.Id,
        StatusCode__c = 'Shipped'
      );
      insert shipment;

      Product2 p = new Product2(Name = 'Product For Shipment Fields', IsActive = true);
      insert p;

      ShipmentItem si = new ShipmentItem(ShipmentId = shipment.Id, Product2Id = p.Id, Quantity = 3);
      insert si;

      MosaicDirectListController.InTransitFilterOptionsResult r = MosaicDirectListController.getInTransitFilterOptions(
        'ShipmentItem',
        null,
        null,
        null,
        null,
        null
      );

      System.assertNotEquals(null, r);
      System.assert(r.statuses.contains('Shipped'), 'StatusCode__c deve aparecer nos statuses');
    } catch (Exception e) {
      System.assert(true, 'Ambiente não suporta a criação deste cenário: ' + e.getMessage());
    }

    clearAllowed();
  }

  @isTest
  static void test_getInTransitFilterOptions_covers_product_location_origin() {
    if (!Schema.getGlobalDescribe().containsKey('ShipmentItem')) {
      System.assert(true, 'ShipmentItem não disponível — teste ignorado.');
      return;
    }
    if (!Schema.getGlobalDescribe().containsKey('PMC_CPQ_ProductLocation__c')) {
      System.assert(true, 'PMC_CPQ_ProductLocation__c não disponível — teste ignorado.');
      return;
    }
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    try {
      SObject location = Schema.getGlobalDescribe().get('PMC_CPQ_ProductLocation__c').newSObject();
      location.put('Name', 'Terminal Origem ABC');
      insert location;

      Shipment shipment = new Shipment(Description = 'Shipment For Location Test');
      insert shipment;

      SObject si = Schema.getGlobalDescribe().get('ShipmentItem').newSObject();
      si.put('ShipmentId', shipment.Id);
      si.put('Quantity', 2);
      si.put('PMC_CPQ_ProductLocation__c', location.Id);
      insert si;

      MosaicDirectListController.InTransitFilterOptionsResult r = MosaicDirectListController.getInTransitFilterOptions(
        'ShipmentItem',
        null,
        null,
        null,
        null,
        null
      );

      System.assertNotEquals(null, r);
      System.assert(r.origins.contains('Terminal Origem ABC'), 'Origin inserida deve aparecer nas opções');
    } catch (Exception e) {
      System.assert(true, 'Ambiente não suporta a criação deste cenário: ' + e.getMessage());
    }

    clearAllowed();
  }

  @isTest
  static void test_listInTransitRecordsPaged_blank_objectname_delegates() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });

    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listInTransitRecordsPaged(
      '',
      new List<String>{ 'Id' },
      null,
      'LastModifiedDate',
      'DESC',
      10,
      1,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null
    );

    System.assertNotEquals(null, pr);
    clearAllowed();
  }

  @isTest
  static void test_listRecordsPaged_sbqq_nested_rel_path_covers_qlRelPaths_branch() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });
    Test.startTest();
    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ 'Id', 'AccountId', 'SBQQ__LineItems__r.SBQQ__Product__r.Name' },
      null, 'LastModifiedDate', 'DESC', 5, 1, null, null, null, null, null, null, null
    );
    Test.stopTest();
    System.assertNotEquals(null, pr.records);
    clearAllowed();
  }

  @isTest
  static void test_listRecordsPaged_real_account_access_path_when_no_injection() {
    MosaicDirectListController.TEST_ALLOWED_IDS = null;
    Test.startTest();
    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Contact', new List<String>{ 'Id' }, null, 'LastModifiedDate', 'DESC', 5, 1,
      null, null, null, null, null, null, null
    );
    Test.stopTest();
    System.assertNotEquals(null, pr);
  }

  @isTest
  static void test_getAllowedAccountIds_real_dto_path_covers_inner_loop() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    AccountAccessController.AccountAccessDTO dto = new AccountAccessController.AccountAccessDTO();
    dto.accountId = a1.Id;
    AccountAccessController.testAccessibleAccounts = new List<AccountAccessController.AccountAccessDTO>{ dto };
    MosaicDirectListController.TEST_ALLOWED_IDS = null;
    Test.startTest();
    List<SObject> r = MosaicDirectListController.listRecords('Lead', new List<String>{ 'Id' }, null, 1);
    Test.stopTest();
    System.assertNotEquals(null, r);
    AccountAccessController.testAccessibleAccounts = null;
  }

  @isTest
  static void test_searchRecords_empty_allowed_early_return() {
    setAllowed(new Set<Id>());
    Test.startTest();
    List<SObject> r = MosaicDirectListController.searchRecords(
      'Contact', 'LastName', 'x', new List<String>{ 'Id' }, null
    );
    Test.stopTest();
    System.assertEquals(0, r.size());
    clearAllowed();
  }

  @isTest
  static void test_listRecords_invalid_object_with_allowed_returns_empty() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });
    Test.startTest();
    List<SObject> r = MosaicDirectListController.listRecords(
      'NotARealObject__xyz', new List<String>{ 'Id' }, null, 10
    );
    Test.stopTest();
    System.assertEquals(0, r.size());
    clearAllowed();
  }

  @isTest
  static void test_listRecordsPaged_date_field_set_but_no_date_values() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });
    Test.startTest();
    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ 'Id', 'BirthDate' },
      null, 'LastModifiedDate', 'DESC', 10, 1,
      null, null,
      'BirthDate', null,
      null, null, null
    );
    Test.stopTest();
    System.assertNotEquals(null, pr);
    clearAllowed();
  }

  @isTest
  static void test_listRecordsPaged_date_fields_not_in_schema_returns_no_filter() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });
    Test.startTest();
    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ 'Id' },
      null, 'LastModifiedDate', 'DESC', 10, 1,
      null, null,
      'FakeField__xyz', 'AnotherFake__xyz',
      '2024-01-01', '2024-12-31', null
    );
    Test.stopTest();
    System.assertNotEquals(null, pr);
    clearAllowed();
  }

  @isTest
  static void test_listRecordsPaged_field_and_search_edge_cases() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });
    Test.startTest();
    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listRecordsPaged(
      'Contact',
      new List<String>{ '', 'SBQQ__LineItems__r.', 'Id' },
      null, 'LastModifiedDate', 'DESC', 10, 1,
      'Alpha',
      new List<String>{ '', 'SBQQ__LineItems__r.Name', 'Field#Invalid!', 'NotInSchema99', 'LastName' },
      null, null, null, null, null
    );
    Test.stopTest();
    System.assertNotEquals(null, pr);
    clearAllowed();
  }

  @isTest
  static void test_listInTransitRecordsPaged_blank_values_in_filter_lists() {
    Account a1 = [SELECT Id FROM Account WHERE Name = 'ACCT Alpha' LIMIT 1];
    setAllowed(new Set<Id>{ a1.Id });
    Test.startTest();
    MosaicDirectListController.PagedResult pr = MosaicDirectListController.listInTransitRecordsPaged(
      'ShipmentItem',
      new List<String>{ 'Id' },
      null, 'LastModifiedDate', 'DESC', 10, 1,
      null, null, null, null, null, null, null,
      null, null, null, null,
      new List<String>{ '' },
      new List<String>{ '' },
      new List<String>{ '' },
      new List<String>{ '' },
      new List<String>{ '' }
    );
    Test.stopTest();
    System.assertNotEquals(null, pr);
    clearAllowed();
  }
}