@isTest
private class AccountNameResolverTest {
    @isTest static void testResolveAccountNamesToIds_basic() {
        // Cria contas de teste básicas
        Account a1 = new Account(Name = 'Test Account A');
        Account a2 = new Account(Name = 'Test Account B');
        insert new List<Account>{a1, a2};

        Test.startTest();
        Map<String, List<Id>> mapResult = AccountNameResolver.resolveAccountNamesToIds(new List<String>{'Test Account A','Test Account B','Nonexistent'});
        Test.stopTest();

        System.assertEquals(2, mapResult.size(), 'Deve retornar dois mapeamentos válidos');
        System.assert(mapResult.containsKey('Test Account A'));
        System.assert(mapResult.containsKey('Test Account B'));
        System.assertNotEquals(null, mapResult.get('Test Account A'));
        System.assert(mapResult.get('Test Account A').size() == 1, 'Esperado uma lista de ids para o nome');
    }

    @isTest static void testResolveAccountNamesToIds_duplicatesAndTrim() {
        // Cria contas com nomes duplicados para garantir que a lista de Ids contenha múltiplos elementos
        Account d1 = new Account(Name = 'Duplicate');
        Account d2 = new Account(Name = 'Duplicate');
        Account u1 = new Account(Name = ' Unique '); // com espaços para testar trim
        insert new List<Account>{d1, d2, u1};

        // Passa entradas duplicadas e com espaços
        List<String> inputs = new List<String>{'Duplicate', '  Duplicate  ', 'Unique', ' Nonexistent ', null, '   '};

        Test.startTest();
        Map<String, List<Id>> mapResult = AccountNameResolver.resolveAccountNamesToIds(inputs);
        Test.stopTest();

        // Esperamos dois nomes válidos: 'Duplicate' e 'Unique' (trim aplicado)
        System.assertEquals(2, mapResult.size(), 'Deve retornar somente os nomes encontrados');
        System.assert(mapResult.containsKey('Duplicate'));
        System.assertEquals(2, mapResult.get('Duplicate').size(), 'Duplicate deve mapear para duas accounts');

        // Note: o Account foi criado com Name = ' Unique ' (com espaços), mas o resolver faz trim antes de buscar
        System.assert(mapResult.containsKey('Unique'));
        System.assertEquals(1, mapResult.get('Unique').size(), 'Unique deve mapear para uma account');
        System.assert(!mapResult.containsKey('Nonexistent'));
    }

    @isTest static void testResolveAccountNamesToIds_nullAndEmpty() {
        // Testa comportamento com null e listas vazias
        Test.startTest();
        Map<String, List<Id>> nullResult = AccountNameResolver.resolveAccountNamesToIds(null);
        Map<String, List<Id>> emptyResult = AccountNameResolver.resolveAccountNamesToIds(new List<String>());
        Map<String, List<Id>> whitesResult = AccountNameResolver.resolveAccountNamesToIds(new List<String>{null, '   '});
        Test.stopTest();

        System.assertNotEquals(null, nullResult, 'Deve retornar mapa (vazio) mesmo para null');
        System.assertEquals(0, nullResult.size(), 'Mapa deve estar vazio quando input for null');

        System.assertNotEquals(null, emptyResult);
        System.assertEquals(0, emptyResult.size(), 'Mapa deve estar vazio quando input for lista vazia');

        System.assertNotEquals(null, whitesResult);
        System.assertEquals(0, whitesResult.size(), 'Mapa deve estar vazio quando input contem apenas nulos/espacos');
    }
}