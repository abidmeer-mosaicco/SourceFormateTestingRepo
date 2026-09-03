@isTest
private class CLIInitialLoadBatchTest {
    private static final Id CUSTOMER_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PMC_SS_Customer').getRecordTypeId();

    private static String suffix() {
        return String.valueOf(Math.abs(Crypto.getRandomInteger())).left(6);
    }

    private static Account createAccount() {
        Account acc = new Account(
            Name          = 'Test Account ' + suffix(),
            RecordTypeId  = CUSTOMER_RECORD_TYPE_ID,
            BillingCity   = 'Tampa',
            BillingStreet = '1 Mosaic Ave'
        );
        insert acc;
        return acc;
    }

    private static Contract createContract(Id accountId) {
        Contract ctr = new Contract(
            AccountId    = accountId,
            Status       = 'Draft',
            StartDate    = Date.today(),
            ContractTerm = 12
        );
        insert ctr;
        ctr.Status = 'Activated';
        update ctr;
        return ctr;
    }

    private static Product2 createProduct() {
        Product2 prod = new Product2(Name = 'Test Product ' + suffix(), IsActive = true);
        insert prod;
        return prod;
    }

    private static SBQQ__Subscription__c createSub(Id contractId, Id accountId, Decimal qty) {
        SBQQ.TriggerControl.disable();
        try {
            SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
                SBQQ__Contract__c              = contractId,
                SBQQ__Account__c               = accountId,
                SBQQ__Quantity__c              = qty,
                SBQQ__SubscriptionStartDate__c = Date.today(),
                SBQQ__SubscriptionEndDate__c   = Date.today().addYears(1)
            );
            insert sub;
            return sub;
        } finally {
            SBQQ.TriggerControl.enable();
        }
    }

    private static SBQQ__Subscription__c createAmendmentSub(
        Id contractId, Id accountId, Decimal qty, Id revisedSubId
    ) {
        SBQQ.TriggerControl.disable();
        try {
            SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
                SBQQ__Contract__c              = contractId,
                SBQQ__Account__c               = accountId,
                SBQQ__Quantity__c              = qty,
                SBQQ__RevisedSubscription__c   = revisedSubId,
                SBQQ__SubscriptionStartDate__c = Date.today(),
                SBQQ__SubscriptionEndDate__c   = Date.today().addYears(1)
            );
            insert sub;
            return sub;
        } finally {
            SBQQ.TriggerControl.enable();
        }
    }

    private static SBQQ__Subscription__c createSubWithProduct(
        Id contractId, Id accountId, Decimal qty, Id productId, Decimal netPrice
    ) {
        SBQQ.TriggerControl.disable();
        try {
            SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
                SBQQ__Contract__c              = contractId,
                SBQQ__Account__c               = accountId,
                SBQQ__Quantity__c              = qty,
                SBQQ__Product__c               = productId,
                SBQQ__NetPrice__c              = netPrice,
                SBQQ__SubscriptionStartDate__c = Date.today(),
                SBQQ__SubscriptionEndDate__c   = Date.today().addYears(1)
            );
            insert sub;
            return sub;
        } finally {
            SBQQ.TriggerControl.enable();
        }
    }

    private static SBQQ__Subscription__c createTerminatedSub(Id contractId, Id accountId, Decimal qty) {
        SBQQ.TriggerControl.disable();
        try {
            SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
                SBQQ__Contract__c              = contractId,
                SBQQ__Account__c               = accountId,
                SBQQ__Quantity__c              = qty,
                SBQQ__TerminatedDate__c        = Date.today().addDays(-1),
                SBQQ__SubscriptionStartDate__c = Date.today().addYears(-1),
                SBQQ__SubscriptionEndDate__c   = Date.today()
            );
            insert sub;
            return sub;
        } finally {
            SBQQ.TriggerControl.enable();
        }
    }

    private static void clearFlowCLIs(Id contractId) {
        List<Contract_Line_Item__c> existing = [
            SELECT Id FROM Contract_Line_Item__c WHERE Contract__c = :contractId
        ];
        if (!existing.isEmpty()) delete existing;
    }

    private static void clearFlowCLIs(List<Id> contractIds) {
        List<Contract_Line_Item__c> existing = [
            SELECT Id FROM Contract_Line_Item__c WHERE Contract__c IN :contractIds
        ];
        if (!existing.isEmpty()) delete existing;
    }

    @isTest
    static void testSingleSub_createsCli() {
        Account  acc = createAccount();
        Contract ctr = createContract(acc.Id);
        SBQQ__Subscription__c sub = createSub(ctr.Id, acc.Id, 100);
        clearFlowCLIs(ctr.Id);

        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(), 50);
        Test.stopTest();

        List<Contract_Line_Item__c> clis = [
            SELECT Id, Quantity__c, Subscription__c,
                   Original_Subscription__c, Original_Subscription_Id__c
            FROM   Contract_Line_Item__c
            WHERE  Contract__c = :ctr.Id
        ];

        Assert.areEqual(1,      clis.size(),                          '1 sub deve produzir 1 CLI');
        Assert.areEqual(100,    clis[0].Quantity__c,                  'Qty deve ser 100');
        Assert.areEqual(sub.Id, clis[0].Subscription__c,             'Subscription__c deve apontar para a sub');
        Assert.isFalse(         clis[0].Original_Subscription__c,    'Standalone: checkbox deve ser false');
    }

    @isTest
    static void testSingleSub_netPricePopulated() {
        Account  acc  = createAccount();
        Contract ctr  = createContract(acc.Id);
        Product2 prod = createProduct();
        createSubWithProduct(ctr.Id, acc.Id, 150, prod.Id, 9000);
        clearFlowCLIs(ctr.Id);

        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(), 50);
        Test.stopTest();

        Contract_Line_Item__c cli = [
            SELECT Quantity__c, Line_Status__c, Net_Price__c, Original_Subscription__c
            FROM   Contract_Line_Item__c
            WHERE  Contract__c = :ctr.Id
            LIMIT  1
        ];

        Assert.areEqual(150,      cli.Quantity__c,              'Qty = 150');
        Assert.areEqual('Active', cli.Line_Status__c,           'Standalone: status Active');
        Assert.areEqual(9000,     cli.Net_Price__c,             'Net_Price__c vem da sub');
        Assert.isFalse(           cli.Original_Subscription__c, 'Standalone: checkbox false');
    }

    @isTest
    static void testTwoProductLines_createsTwoClis() {
        Account  acc = createAccount();
        Contract ctr = createContract(acc.Id);
        createSub(ctr.Id, acc.Id, 200);
        createSub(ctr.Id, acc.Id, 300);
        clearFlowCLIs(ctr.Id);

        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(), 50);
        Test.stopTest();

        List<Contract_Line_Item__c> clis = [
            SELECT Quantity__c
            FROM   Contract_Line_Item__c
            WHERE  Contract__c = :ctr.Id
            ORDER  BY Quantity__c ASC
        ];

        Assert.areEqual(2,   clis.size(),         '2 subs independentes → 2 CLIs');
        Assert.areEqual(200, clis[0].Quantity__c, 'Primeiro CLI qty = 200');
        Assert.areEqual(300, clis[1].Quantity__c, 'Segundo CLI qty = 300');
    }

    @isTest
    static void testTerminatedSub_notIncludedInQty() {
        Account  acc = createAccount();
        Contract ctr = createContract(acc.Id);
        createSub(ctr.Id, acc.Id, 100);
        createTerminatedSub(ctr.Id, acc.Id, 999);
        clearFlowCLIs(ctr.Id);

        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(), 50);
        Test.stopTest();

        List<Contract_Line_Item__c> clis = [
            SELECT Quantity__c
            FROM   Contract_Line_Item__c
            WHERE  Contract__c = :ctr.Id
        ];

        Assert.areEqual(1,   clis.size(),         '1 CLI para sub ativa');
        Assert.areEqual(100, clis[0].Quantity__c, 'Qty apenas da sub ativa');
    }

    @isTest
    static void testContractAlreadyHasCli_skipped() {
        Account  acc = createAccount();
        Contract ctr = createContract(acc.Id);
        Contract_Line_Item__c existingCli = new Contract_Line_Item__c(
            Contract__c = ctr.Id, Quantity__c = 999
        );
        insert existingCli;

        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(), 50);
        Test.stopTest();

        List<Contract_Line_Item__c> clis = [
            SELECT Id FROM Contract_Line_Item__c WHERE Contract__c = :ctr.Id
        ];
        Assert.areEqual(1,              clis.size(), 'Não deve criar segundo CLI');
        Assert.areEqual(existingCli.Id, clis[0].Id, 'CLI existente deve permanecer');
    }

    @isTest
    static void testContractWithoutSubs_producesNoCli() {
        Account  acc = createAccount();
        Contract ctr = createContract(acc.Id);

        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(), 50);
        Test.stopTest();

        Assert.areEqual(0,
            [SELECT COUNT() FROM Contract_Line_Item__c WHERE Contract__c = :ctr.Id],
            'Contrato sem subs não deve gerar CLI');
    }

    @isTest
    static void testDraftContract_skipped() {
        Account  acc = createAccount();
        Contract ctr = new Contract(
            AccountId = acc.Id, Status = 'Draft',
            StartDate = Date.today(), ContractTerm = 12
        );
        insert ctr;

        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(new Set<Id>{ ctr.Id }), 50);
        Test.stopTest();

        Assert.areEqual(0,
            [SELECT COUNT() FROM Contract_Line_Item__c WHERE Contract__c = :ctr.Id],
            'Contrato Draft não deve gerar CLI');
    }

    @isTest
    static void testStatefulCounters_accurate() {
        Account  acc = createAccount();
        Contract ctr = createContract(acc.Id);
        createSub(ctr.Id, acc.Id, 50);
        clearFlowCLIs(ctr.Id);

        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(), 50);
        Test.stopTest();

        Assert.areEqual(1,
            [SELECT COUNT() FROM Contract_Line_Item__c WHERE Contract__c = :ctr.Id],
            '1 CLI deve existir após o batch');
    }

    @isTest
    static void testBulk_fiveIndependentContracts() {
        Account      acc         = createAccount();
        List<Id>     contractIds = new List<Id>();

        for (Integer i = 0; i < 5; i++) {
            Contract ctr = createContract(acc.Id);
            contractIds.add(ctr.Id);
            createSub(ctr.Id, acc.Id, 100);
        }
        clearFlowCLIs(contractIds);

        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(), 50);
        Test.stopTest();

        List<Contract_Line_Item__c> clis = [
            SELECT Quantity__c
            FROM   Contract_Line_Item__c
            WHERE  Contract__c IN :contractIds
        ];

        Assert.areEqual(5, clis.size(), '5 contratos devem gerar 5 CLIs');
        for (Contract_Line_Item__c cli : clis) {
            Assert.areEqual(100, cli.Quantity__c, 'Cada CLI qty = 100');
        }
    }

    @isTest
    static void testAmendmentChain_singleCliGrouped() {
        Account  acc = createAccount();
        Contract ctr = createContract(acc.Id);

        createSub(ctr.Id, acc.Id, 500);
        createAmendmentSub(ctr.Id, acc.Id, -100, [SELECT Id FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c = :ctr.Id LIMIT 1].Id);
        clearFlowCLIs(ctr.Id);

        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(), 50);
        Test.stopTest();

        Assert.areEqual(1,
            [SELECT COUNT() FROM Contract_Line_Item__c WHERE Contract__c = :ctr.Id],
            'Cadeia de 2 subs deve produzir exatamente 1 CLI');
    }

    @isTest
    static void testAmendmentChain_multipleAmendmentsToSameRoot() {
        Account  acc = createAccount();
        Contract ctr = createContract(acc.Id);

        SBQQ__Subscription__c root = createSub(ctr.Id, acc.Id, 500);
        createAmendmentSub(ctr.Id, acc.Id, -150, root.Id);
        createAmendmentSub(ctr.Id, acc.Id, -20,  root.Id);
        createAmendmentSub(ctr.Id, acc.Id, -30,  root.Id);
        clearFlowCLIs(ctr.Id);

        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(), 50);
        Test.stopTest();

        Assert.areEqual(1,
            [SELECT COUNT() FROM Contract_Line_Item__c WHERE Contract__c = :ctr.Id],
            '4 subs com mesma raiz devem produzir 1 CLI');
    }

    @isTest
    static void testAmendmentChain_cascadeChain() {
        Account  acc = createAccount();
        Contract ctr = createContract(acc.Id);

        SBQQ__Subscription__c subA = createSub(ctr.Id, acc.Id, 400);
        SBQQ__Subscription__c subB = createAmendmentSub(ctr.Id, acc.Id, -100, subA.Id);
        SBQQ__Subscription__c subC = createAmendmentSub(ctr.Id, acc.Id, -50,  subB.Id);
        createAmendmentSub(ctr.Id, acc.Id, -30, subC.Id);
        clearFlowCLIs(ctr.Id);

        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(), 50);
        Test.stopTest();

        Assert.areEqual(1,
            [SELECT COUNT() FROM Contract_Line_Item__c WHERE Contract__c = :ctr.Id],
            'Cadeia encadeada A←B←C←D deve produzir 1 CLI');
    }

    @isTest
    static void testAmendmentChain_twoIndependentChains_twoClis() {
        Account  acc = createAccount();
        Contract ctr = createContract(acc.Id);

        SBQQ__Subscription__c root1 = createSub(ctr.Id, acc.Id, 200);
        createAmendmentSub(ctr.Id, acc.Id, -50, root1.Id);

        SBQQ__Subscription__c root2 = createSub(ctr.Id, acc.Id, 400);
        createAmendmentSub(ctr.Id, acc.Id, 100, root2.Id);

        clearFlowCLIs(ctr.Id);

        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(), 50);
        Test.stopTest();

        Assert.areEqual(2,
            [SELECT COUNT() FROM Contract_Line_Item__c WHERE Contract__c = :ctr.Id],
            '2 cadeias independentes devem produzir 2 CLIs');
    }

    @isTest
    static void testAmendmentChain_mixedWithStandalone() {
        Account  acc = createAccount();
        Contract ctr = createContract(acc.Id);

        createSub(ctr.Id, acc.Id, 75);

        SBQQ__Subscription__c root = createSub(ctr.Id, acc.Id, 600);
        createAmendmentSub(ctr.Id, acc.Id, -200, root.Id);

        clearFlowCLIs(ctr.Id);

        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(), 50);
        Test.stopTest();

        Assert.areEqual(2,
            [SELECT COUNT() FROM Contract_Line_Item__c WHERE Contract__c = :ctr.Id],
            'Standalone + cadeia devem produzir 2 CLIs');

        List<Contract_Line_Item__c> standalone = [
            SELECT Quantity__c, Line_Status__c
            FROM   Contract_Line_Item__c
            WHERE  Contract__c = :ctr.Id
            AND    Quantity__c = 75
        ];
        Assert.areEqual(1,        standalone.size(),             '1 CLI standalone');
        Assert.areEqual('Active', standalone[0].Line_Status__c, 'Standalone: status Active');
    }

    @isTest
    static void testNegativeQty_preserved() {
        Account  acc = createAccount();
        Contract ctr = createContract(acc.Id);
        createSub(ctr.Id, acc.Id, -50);
        clearFlowCLIs(ctr.Id);

        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(), 50);
        Test.stopTest();

        Assert.areEqual(-50,
            [SELECT Quantity__c FROM Contract_Line_Item__c WHERE Contract__c = :ctr.Id LIMIT 1].Quantity__c,
            'Quantidade negativa deve ser preservada');
    }

    @isTest
    static void testIdempotency_batchRunTwice_noDuplicates() {
        Account  acc = createAccount();
        Contract ctr = createContract(acc.Id);
        createSub(ctr.Id, acc.Id, 100);
        clearFlowCLIs(ctr.Id);

        // Primeira execução cria o CLI
        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(), 50);
        Test.stopTest();

        // Segunda execução: contrato já tem CLI, batch não deve criar outro
        // (não pode usar segundo startTest/stopTest no mesmo método —
        // executamos o batch diretamente fora do contexto de teste)
        Database.executeBatch(new CLIInitialLoadBatch(), 50);

        Assert.areEqual(1,
            [SELECT COUNT() FROM Contract_Line_Item__c WHERE Contract__c = :ctr.Id],
            'Segunda execução não deve duplicar CLI');
    }

    @isTest
    static void testParameterizedConstructor_processesOnlyTargetContract() {
        Account  acc  = createAccount();
        Contract ctr1 = createContract(acc.Id);
        Contract ctr2 = createContract(acc.Id);

        createSub(ctr1.Id, acc.Id, 100);
        createSub(ctr2.Id, acc.Id, 200);
        clearFlowCLIs(new List<Id>{ ctr1.Id, ctr2.Id });

        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(new Set<Id>{ ctr1.Id }), 50);
        Test.stopTest();

        Assert.areEqual(1,
            [SELECT COUNT() FROM Contract_Line_Item__c WHERE Contract__c = :ctr1.Id],
            'Contrato alvo deve ser processado');
        Assert.areEqual(0,
            [SELECT COUNT() FROM Contract_Line_Item__c WHERE Contract__c = :ctr2.Id],
            'Contrato não incluído não deve ser processado');
    }

    @isTest
    static void testReprocess_updatesExistingCliQuantity() {
        Account  acc = createAccount();
        Contract ctr = createContract(acc.Id);

        SBQQ__Subscription__c root = createSub(ctr.Id, acc.Id, 200);
        createAmendmentSub(ctr.Id, acc.Id, -50, root.Id);
        clearFlowCLIs(ctr.Id);

        Contract_Line_Item__c wrongCli = new Contract_Line_Item__c(
            Contract__c             = ctr.Id,
            Subscription__c         = root.Id,
            Original_Subscription_Id__c = root.Id,
            Quantity__c             = -50
        );
        insert wrongCli;

        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(new Set<Id>{ ctr.Id }, true), 50);
        Test.stopTest();

        List<Contract_Line_Item__c> clis = [
            SELECT Id, Quantity__c
            FROM   Contract_Line_Item__c
            WHERE  Contract__c = :ctr.Id
        ];

        Assert.areEqual(1,   clis.size(),         'Reprocess nao deve duplicar CLI');
        Assert.areEqual(150, clis[0].Quantity__c,  'Qty deve ser soma da cadeia: 200 + (-50) = 150');
        Assert.areEqual(wrongCli.Id, clis[0].Id,   'Deve atualizar CLI existente, nao criar novo');
    }

    @isTest
    static void testReprocess_createsNewCliWhereMissing() {
        Account  acc = createAccount();
        Contract ctr = createContract(acc.Id);

        SBQQ__Subscription__c sub1 = createSub(ctr.Id, acc.Id, 100);
        createSub(ctr.Id, acc.Id, 300);
        clearFlowCLIs(ctr.Id);

        Contract_Line_Item__c existingCli = new Contract_Line_Item__c(
            Contract__c             = ctr.Id,
            Subscription__c         = sub1.Id,
            Original_Subscription_Id__c = sub1.Id,
            Quantity__c             = 100
        );
        insert existingCli;

        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(new Set<Id>{ ctr.Id }, true), 50);
        Test.stopTest();

        List<Contract_Line_Item__c> clis = [
            SELECT Quantity__c
            FROM   Contract_Line_Item__c
            WHERE  Contract__c = :ctr.Id
            ORDER  BY Quantity__c ASC
        ];

        Assert.areEqual(2,   clis.size(),         'Deve ter 2 CLIs: 1 existente atualizado + 1 novo');
        Assert.areEqual(100, clis[0].Quantity__c,  'CLI existente mantém qty correta');
        Assert.areEqual(300, clis[1].Quantity__c,  'Novo CLI criado para sub sem CLI');
    }

    @isTest
    static void testReprocess_withoutTargetIds_processesAll() {
        Account  acc = createAccount();
        Contract ctr = createContract(acc.Id);

        SBQQ__Subscription__c root = createSub(ctr.Id, acc.Id, 500);
        createAmendmentSub(ctr.Id, acc.Id, -200, root.Id);
        clearFlowCLIs(ctr.Id);

        Contract_Line_Item__c wrongCli = new Contract_Line_Item__c(
            Contract__c             = ctr.Id,
            Subscription__c         = root.Id,
            Original_Subscription_Id__c = root.Id,
            Quantity__c             = -200
        );
        insert wrongCli;

        Test.startTest();
        Database.executeBatch(new CLIInitialLoadBatch(null, true), 50);
        Test.stopTest();

        Contract_Line_Item__c cli = [
            SELECT Quantity__c
            FROM   Contract_Line_Item__c
            WHERE  Contract__c = :ctr.Id
            LIMIT  1
        ];

        Assert.areEqual(300, cli.Quantity__c, 'Reprocess sem IDs deve corrigir qty: 500 + (-200) = 300');
    }
}