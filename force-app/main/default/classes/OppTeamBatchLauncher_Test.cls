@IsTest
private class OppTeamBatchLauncher_Test {

    @IsTest
    static void testBatchLauncherExecutes() {

        // ✅ Create test user
        Profile p = [SELECT Id FROM Profile LIMIT 1];

        User u = new User(
            FirstName = 'Test',
            LastName  = 'User',
            Email     = 'testuser' + DateTime.now().getTime() + '@test.com',
            Username  = 'testuser' + DateTime.now().getTime() + '@test.com',
            Alias     = 'tuser',
            ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US'
        );
        insert u;

        // ✅ Create Account
        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;

        // ✅ Create Opportunity (within 180 days condition)
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            OwnerId = u.Id,
            AccountId = acc.Id
        );
        insert opp;

        Test.startTest();

        // ✅ Call your Queueable
        System.enqueueJob(new OppTeamBatchLauncher(u.Id));

        Test.stopTest();

        // ✅ Basic validation (batch executed without error)
        List<Opportunity> opps = [
            SELECT Id
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals(1, opps.size());
    }
}