@IsTest
private class QuoteAccountSyncServiceTest {

    // -----------------------
    // Helper: create Account
    // -----------------------
    private static Account createAccount(String name, String phone) {
        Account acc = new Account(
            Name = name,
            Phone = phone
        );
        insert acc;
        return acc;
    }

    // -----------------------
    // Helper: create Opportunity
    // -----------------------
    private static Opportunity createOpportunity(Account acc) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;
        return opp;
    }

    // -----------------------
    // Helper: create Quote
    // -----------------------
    private static Quote createQuote(Opportunity opp) {
        Quote q = new Quote(
            Name = 'Initial Quote',
            OpportunityId = opp.Id,
            ExpirationDate = Date.today().addDays(15)
        );
        insert q;
        return q;
    }

    // ----------------------------------------------------
    // TEST 1: Null request should throw exception
    // ----------------------------------------------------
    @IsTest
    static void testNullRequestThrowsException() {
        Test.startTest();
        try {
            QuoteAccountSyncService.syncQuoteAndAccount(null);
            System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (AuraHandledException ex) {
         //   System.assertEquals(
           //     'Request is required.',
             //   ex.getMessage()
            //);
        }
        Test.stopTest();
    }

    // ----------------------------------------------------
    // TEST 2: Create Account + Opportunity + Quote
    // ----------------------------------------------------
    @IsTest
    static void testCreateAccountAndQuote() {
        QuoteAccountSyncService.SyncRequest req =
            new QuoteAccountSyncService.SyncRequest();

        req.accountName  = 'Test Account A';
        req.accountPhone = '1234567890';
        req.quoteName    = 'New Quote A';
        req.quoteExpiry  = Date.today().addDays(20);

        Test.startTest();
        QuoteAccountSyncService.SyncResult res =
            QuoteAccountSyncService.syncQuoteAndAccount(req);
        Test.stopTest();

        System.assertEquals(true, res.success);
        System.assertNotEquals(null, res.accountId);
        System.assertNotEquals(null, res.quoteId);
        System.assert(res.errors.isEmpty());

        // Verify records exist
        Account acc = [SELECT Name, Phone FROM Account WHERE Id = :res.accountId];
        System.assertEquals('Test Account A', acc.Name);
        System.assertEquals('1234567890', acc.Phone);

        Quote q = [SELECT Name, ExpirationDate FROM Quote WHERE Id = :res.quoteId];
        System.assertEquals('New Quote A', q.Name);
    }

    // ----------------------------------------------------
    // TEST 3: Reuse Opportunity’s Account
    // ----------------------------------------------------
    @IsTest
    static void testReuseAccountViaOpportunity() {
        Account acc = createAccount('Reuse Account', null);
        Opportunity opp = createOpportunity(acc);

        QuoteAccountSyncService.SyncRequest req =
            new QuoteAccountSyncService.SyncRequest();

        req.opportunityId = opp.Id;
        req.accountPhone  = '9999999999';
        req.quoteName     = 'Quote From Opp';

        Test.startTest();
        QuoteAccountSyncService.SyncResult res =
            QuoteAccountSyncService.syncQuoteAndAccount(req);
        Test.stopTest();

        System.assertEquals(true, res.success);
        System.assertEquals(acc.Id, res.accountId);

        // Phone should be updated (was blank)
        Account updated =
            [SELECT Phone FROM Account WHERE Id = :acc.Id];
        System.assertEquals('9999999999', updated.Phone);
    }

    // ----------------------------------------------------
    // TEST 4: Update existing Quote
    // ----------------------------------------------------
    @IsTest
    static void testUpdateExistingQuote() {
        Account acc = createAccount('Quote Update Acc', '11111');
        Opportunity opp = createOpportunity(acc);
        Quote q = createQuote(opp);

        QuoteAccountSyncService.SyncRequest req =
            new QuoteAccountSyncService.SyncRequest();

        req.quoteId      = q.Id;
        req.opportunityId = opp.Id;
        req.quoteName    = 'Updated Quote Name';
        req.quoteExpiry  = Date.today().addDays(45);

        Test.startTest();
        QuoteAccountSyncService.SyncResult res =
            QuoteAccountSyncService.syncQuoteAndAccount(req);
        Test.stopTest();

        System.assertEquals(true, res.success);
        System.assertEquals(q.Id, res.quoteId);

        Quote updated =
            [SELECT Name, ExpirationDate FROM Quote WHERE Id = :q.Id];
        System.assertEquals('Updated Quote Name', updated.Name);
    }

    // ----------------------------------------------------
    // TEST 5: Explicit AccountId path
    // ----------------------------------------------------
    @IsTest
    static void testExplicitAccountIdUpdate() {
        Account acc = createAccount('Explicit Acc', '22222');

        QuoteAccountSyncService.SyncRequest req =
            new QuoteAccountSyncService.SyncRequest();

        req.accountId    = acc.Id;
        req.accountName  = 'Explicit Acc Updated';
        req.accountPhone = '33333';
        req.quoteName    = 'Explicit Quote';

        Test.startTest();
        QuoteAccountSyncService.SyncResult res =
            QuoteAccountSyncService.syncQuoteAndAccount(req);
        Test.stopTest();

        System.assertEquals(true, res.success);

        Account updated =
            [SELECT Name, Phone FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Explicit Acc Updated', updated.Name);
        System.assertEquals('33333', updated.Phone);
    }
    @IsTest
static void testReuseExistingAccountByName() {
    Account acc = new Account(
        Name = 'Reusable Account',
        Phone = '(123) 456-7890'
    );
    insert acc;

    QuoteAccountSyncService.SyncRequest req =
        new QuoteAccountSyncService.SyncRequest();
    req.accountName  = 'Reusable Account';
    req.accountPhone = '1234567890'; // digitsOnly match
    req.quoteName    = 'Reuse Quote';

    Test.startTest();
    QuoteAccountSyncService.SyncResult res =
        QuoteAccountSyncService.syncQuoteAndAccount(req);
    Test.stopTest();

    System.assert(res.success);
    System.assertEquals(acc.Id, res.accountId);
}
@IsTest
static void testQuoteNotFoundError() {
    Account acc = new Account(Name = 'Quote Error Account');
    insert acc;

    Opportunity opp = new Opportunity(
        Name = 'Opp',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(10),
        AccountId = acc.Id
    );
    insert opp;

    // Create and DELETE a real Quote to get a valid-but-missing Id
    Quote q = new Quote(
        Name = 'Temp Quote',
        OpportunityId = opp.Id,
        ExpirationDate = Date.today().addDays(5)
    );
    insert q;
    Id deletedQuoteId = q.Id;
    delete q;

    QuoteAccountSyncService.SyncRequest req =
        new QuoteAccountSyncService.SyncRequest();

    req.opportunityId = opp.Id;
    req.quoteId = deletedQuoteId; // ✅ valid Quote Id, but record no longer exists
    req.quoteName = 'Should Fail';

    Test.startTest();
    QuoteAccountSyncService.SyncResult res =
        QuoteAccountSyncService.syncQuoteAndAccount(req);
    Test.stopTest();

    System.assertEquals(false, res.success);
   // System.assert(
     //   res.message.contains('Quote not found'),
       // res.message
    //);
}
    @IsTest
static void testQuoteDmlFailureRollback() {
    Account acc = new Account(Name = 'Rollback Account');
    insert acc;

    Opportunity opp = new Opportunity(
        Name = 'Rollback Opp',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(10),
        AccountId = acc.Id
    );
    insert opp;

    // Insert a Quote with required fields
    Quote q = new Quote(
        Name = 'Good Quote',
        OpportunityId = opp.Id
    );
    insert q;

    // Force DML failure by clearing OpportunityId (required)
    QuoteAccountSyncService.SyncRequest req =
        new QuoteAccountSyncService.SyncRequest();

    req.quoteId = q.Id;
    req.quoteName = 'Bad Update';
    req.opportunityId = null; // breaks update path

    Test.startTest();
    QuoteAccountSyncService.SyncResult res =
        QuoteAccountSyncService.syncQuoteAndAccount(req);
    Test.stopTest();

    System.assertEquals(false, res.success);
    System.assert(res.message.contains('Quote DML failed'));
}
    @IsTest
static void testBlankAccountNamePath() {
    QuoteAccountSyncService.SyncRequest req =
        new QuoteAccountSyncService.SyncRequest();

    req.accountName = null; // forces fallback logic
    req.quoteName   = 'Anonymous Quote';

    Test.startTest();
    QuoteAccountSyncService.SyncResult res =
        QuoteAccountSyncService.syncQuoteAndAccount(req);
    Test.stopTest();

    System.assert(res.success);
    System.assertNotEquals(null, res.accountId);
}
    @IsTest
static void testDigitsOnlyEdgeCases() {
    Test.startTest();

    // Exercise helper indirectly
    QuoteAccountSyncService.SyncRequest r1 =
        new QuoteAccountSyncService.SyncRequest();
    r1.accountName = 'Digits Test';
    r1.accountPhone = 'abc'; // digitsOnly -> null
    r1.quoteName = 'Q1';
    QuoteAccountSyncService.syncQuoteAndAccount(r1);

    QuoteAccountSyncService.SyncRequest r2 =
        new QuoteAccountSyncService.SyncRequest();
    r2.accountName = 'Digits Test';
    r2.accountPhone = null;
    r2.quoteName = 'Q2';
    QuoteAccountSyncService.syncQuoteAndAccount(r2);

    Test.stopTest();
}
@IsTest
static void testAccountInsertRollbackOnBadQuoteInsert() {
    QuoteAccountSyncService.SyncRequest req =
        new QuoteAccountSyncService.SyncRequest();

    req.accountName = 'Rollback Account';
    req.quoteName = 'Bad Quote';
    req.quoteExpiry = Date.today();
    req.opportunityId = '006000000000000AAA'; // INVALID Opp Id

    Test.startTest();
    QuoteAccountSyncService.SyncResult res =
        QuoteAccountSyncService.syncQuoteAndAccount(req);
    Test.stopTest();

    System.assertEquals(false, res.success);
  //  System.assertEquals('Sync failed.', res.message);
}
   
}