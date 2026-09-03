@isTest
private class CLIQuantityRecalculatorTest {

    private static final Id CUSTOMER_RECORD_TYPE_ID = Schema.SObjectType.Account
        .getRecordTypeInfosByDeveloperName()
        .get('PMC_SS_Customer')
        .getRecordTypeId();

    @isTest
    static void testFirstAmendment_rootPlusDelta() {
        Id contractId = createContract();
        Contract_Line_Item__c cli = createCli(contractId, 1000);
        SBQQ__Subscription__c root = createSubscription(contractId, 1000, null, null);
        SBQQ__Subscription__c amendment = createSubscription(contractId, -500, root.Id, null);

        CLIQuantityRecalculator.Request req = new CLIQuantityRecalculator.Request();
        req.cliId              = cli.Id;
        req.rootSubscriptionId = root.Id;
        req.currentDelta       = -500;
        req.subscriptionId     = amendment.Id;

        Test.startTest();
        List<CLIQuantityRecalculator.Response> responses =
            CLIQuantityRecalculator.recalculate(new List<CLIQuantityRecalculator.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Deve retornar uma resposta por request');
        Assert.areEqual(500, responses[0].calculatedQuantity,
            'Primeira amendment: 1000 (raiz) + (-500) (delta atual) = 500');
    }

    /**
     * Cenário do bug corrigido: uma 2ª amendment sobre a mesma linha precisa
     * somar o delta atual em cima da raiz + da revisão anterior já aplicada
     * a este CLI, e não confiar no Quantity__c armazenado no CLI.
     */
    @isTest
    static void testSecondAmendment_accumulatesPriorRevisionAppliedToSameCli() {
        Id contractId = createContract();
        Contract_Line_Item__c cli = createCli(contractId, 3000);
        SBQQ__Subscription__c root = createSubscription(contractId, 3000, null, null);

        // 1ª amendment já aplicada a este CLI (delta -1000)
        createSubscription(contractId, -1000, root.Id, cli.Id);

        // 2ª amendment: subscription DIFERENTE da 1ª, ainda não linkada ao CLI
        SBQQ__Subscription__c secondAmendment = createSubscription(contractId, -1000, root.Id, null);

        CLIQuantityRecalculator.Request req = new CLIQuantityRecalculator.Request();
        req.cliId              = cli.Id;
        req.rootSubscriptionId = root.Id;
        req.currentDelta       = -1000; // 2ª amendment
        req.subscriptionId     = secondAmendment.Id;

        Test.startTest();
        List<CLIQuantityRecalculator.Response> responses =
            CLIQuantityRecalculator.recalculate(new List<CLIQuantityRecalculator.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1000, responses[0].calculatedQuantity,
            '3000 (raiz) + (-1000) (1a amendment) + (-1000) (2a amendment) = 1000');
    }

    /**
     * Uma revisão da mesma raiz que foi "split" pra um CLI diferente não pode
     * entrar na soma deste CLI, senão o cálculo fica negativo/errado.
     */
    @isTest
    static void testSplitOffRevision_isExcludedFromOtherCli() {
        Id contractId = createContract();
        Contract_Line_Item__c cli      = createCli(contractId, 3000);
        Contract_Line_Item__c splitCli = createCli(contractId, 0);
        SBQQ__Subscription__c root = createSubscription(contractId, 3000, null, null);

        // Revisão que foi "splitada" para um CLI diferente — não deve contar aqui
        createSubscription(contractId, -1000, root.Id, splitCli.Id);

        SBQQ__Subscription__c current = createSubscription(contractId, -1000, root.Id, null);

        CLIQuantityRecalculator.Request req = new CLIQuantityRecalculator.Request();
        req.cliId              = cli.Id;
        req.rootSubscriptionId = root.Id;
        req.currentDelta       = -1000;
        req.subscriptionId     = current.Id;

        Test.startTest();
        List<CLIQuantityRecalculator.Response> responses =
            CLIQuantityRecalculator.recalculate(new List<CLIQuantityRecalculator.Request>{ req });
        Test.stopTest();

        Assert.areEqual(2000, responses[0].calculatedQuantity,
            '3000 (raiz) + 0 (revisao splitada para outro CLI, excluida) + (-1000) (delta atual) = 2000');
    }

    @isTest
    static void testNoPriorRevisions_onlyRootAndDelta() {
        Id contractId = createContract();
        Contract_Line_Item__c cli = createCli(contractId, 100);
        SBQQ__Subscription__c root = createSubscription(contractId, 100, null, null);
        SBQQ__Subscription__c current = createSubscription(contractId, 0, root.Id, null);

        CLIQuantityRecalculator.Request req = new CLIQuantityRecalculator.Request();
        req.cliId              = cli.Id;
        req.rootSubscriptionId = root.Id;
        req.currentDelta       = null;
        req.subscriptionId     = current.Id;

        Test.startTest();
        List<CLIQuantityRecalculator.Response> responses =
            CLIQuantityRecalculator.recalculate(new List<CLIQuantityRecalculator.Request>{ req });
        Test.stopTest();

        Assert.areEqual(100, responses[0].calculatedQuantity,
            'currentDelta nulo deve ser tratado como 0: 100 + 0 + 0 = 100');
    }

    @isTest
    static void testBulk_multipleRootsDoNotCrossContaminate() {
        Id contractId = createContract();

        Contract_Line_Item__c cliA = createCli(contractId, 1000);
        SBQQ__Subscription__c rootA = createSubscription(contractId, 1000, null, null);
        createSubscription(contractId, -300, rootA.Id, cliA.Id);
        SBQQ__Subscription__c currentA = createSubscription(contractId, -200, rootA.Id, null);

        Contract_Line_Item__c cliB = createCli(contractId, 5000);
        SBQQ__Subscription__c rootB = createSubscription(contractId, 5000, null, null);
        createSubscription(contractId, -2000, rootB.Id, cliB.Id);
        SBQQ__Subscription__c currentB = createSubscription(contractId, -500, rootB.Id, null);

        CLIQuantityRecalculator.Request reqA = new CLIQuantityRecalculator.Request();
        reqA.cliId              = cliA.Id;
        reqA.rootSubscriptionId = rootA.Id;
        reqA.currentDelta       = -200;
        reqA.subscriptionId     = currentA.Id;

        CLIQuantityRecalculator.Request reqB = new CLIQuantityRecalculator.Request();
        reqB.cliId              = cliB.Id;
        reqB.rootSubscriptionId = rootB.Id;
        reqB.currentDelta       = -500;
        reqB.subscriptionId     = currentB.Id;

        Test.startTest();
        List<CLIQuantityRecalculator.Response> responses = CLIQuantityRecalculator.recalculate(
            new List<CLIQuantityRecalculator.Request>{ reqA, reqB }
        );
        Test.stopTest();

        Assert.areEqual(2, responses.size(), 'Deve retornar uma resposta por request, na mesma ordem');
        Assert.areEqual(500, responses[0].calculatedQuantity,  'Linha A: 1000 - 300 - 200 = 500');
        Assert.areEqual(2500, responses[1].calculatedQuantity, 'Linha B: 5000 - 2000 - 500 = 2500');
    }

    /**
     * Bug real observado em QA2: re-rodar o cálculo para a MESMA subscription
     * que já está linkada ao CLI (retry, re-debug, reprocessamento) contava o
     * delta dela duas vezes — uma via appliedSum (porque já estava linkada) e
     * outra via currentDelta. subscriptionId precisa excluir a própria
     * subscription da soma de "já aplicadas".
     */
    @isTest
    static void testRerunSameSubscription_doesNotDoubleCountOwnDelta() {
        Id contractId = createContract();
        Contract_Line_Item__c cli = createCli(contractId, 40);
        SBQQ__Subscription__c root = createSubscription(contractId, 60, null, null);

        // Já linkada a este CLI por uma execução anterior (é isso que causava o bug)
        SBQQ__Subscription__c amendment = createSubscription(contractId, -10, root.Id, cli.Id);

        CLIQuantityRecalculator.Request req = new CLIQuantityRecalculator.Request();
        req.cliId              = cli.Id;
        req.rootSubscriptionId = root.Id;
        req.currentDelta       = -10;
        req.subscriptionId     = amendment.Id;

        Test.startTest();
        List<CLIQuantityRecalculator.Response> responses =
            CLIQuantityRecalculator.recalculate(new List<CLIQuantityRecalculator.Request>{ req });
        Test.stopTest();

        Assert.areEqual(50, responses[0].calculatedQuantity,
            '60 (raiz) + (-10) (delta atual, contado uma unica vez) = 50, nao 40');
    }

    private static Id createContract() {
        Account acc = new Account(
            Name          = generateRandomizedName('ACCOUNT'),
            RecordTypeId  = CUSTOMER_RECORD_TYPE_ID,
            BillingCity   = 'Tampa',
            BillingStreet = '1 Mosaic Ave'
        );
        insert acc;

        Contract ctr = new Contract(
            AccountId    = acc.Id,
            Status       = 'Draft',
            StartDate    = Date.today(),
            ContractTerm = 12
        );
        insert ctr;

        return ctr.Id;
    }

    private static Contract_Line_Item__c createCli(Id contractId, Decimal quantity) {
        Contract_Line_Item__c cli = new Contract_Line_Item__c(
            Contract__c = contractId,
            Quantity__c = quantity
        );
        insert cli;
        return cli;
    }

    private static SBQQ__Subscription__c createSubscription(Id contractId, Decimal quantity,
                                                             Id revisedSubscriptionId, Id cliId) {
        Id accountId = [SELECT AccountId FROM Contract WHERE Id = :contractId].AccountId;

        SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
            SBQQ__Account__c               = accountId,
            SBQQ__Contract__c              = contractId,
            SBQQ__Quantity__c              = quantity,
            SBQQ__RevisedSubscription__c   = revisedSubscriptionId,
            SBQQ__SubscriptionStartDate__c = Date.today(),
            SBQQ__SubscriptionEndDate__c   = Date.today().addYears(1)
        );
        insert sub;

        if (cliId != null) {
            Database.update(new SBQQ__Subscription__c(Id = sub.Id, Contract_Line_Item__c = cliId), false);
        }

        return sub;
    }

    private static String generateRandomizedName(String baseName) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        String randomSuffix = '';
        while (randomSuffix.length() < 3) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randomSuffix += chars.substring(idx, idx + 1);
        }
        return baseName + '-' + randomSuffix;
    }
}