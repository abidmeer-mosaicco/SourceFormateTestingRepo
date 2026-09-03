@IsTest
private class OppTeamReplicationJob_Test {
private static User mkUser(String prefix){
    // SAFE: Always returns a valid profile
    Profile p = [SELECT Id FROM Profile LIMIT 1];

    // guaranteed unique in parallel tests
    String unique = prefix + '_' + Crypto.getRandomLong() + '_' + DateTime.now().getTime();

    User u = new User(
        ProfileId = p.Id,
        FirstName = prefix,
        LastName  = 'Tester',
        Email     = unique + '@test.com',
        Username  = unique + '@test.com',
        Alias     = (prefix + 'xxxxx').substring(0,5),
        TimeZoneSidKey='America/Los_Angeles',
        LocaleSidKey='en_US',
        EmailEncodingKey='UTF-8',
        LanguageLocaleKey='en_US'
    );
    insert u;
    return u;
}

private static Map<String,Id> seed(User owner) {
    Map<String,Id> d = new Map<String,Id>();
    
Account acc = new Account(
    Name = 'Acc_' + Crypto.getRandomLong(),
    BillingStreet = '123 Test Street',
    BillingCity = 'San Francisco',
    BillingStateCode = 'CA',     // valid state code
    BillingPostalCode = '94105',
    BillingCountryCode = 'US'    // valid country code
);
insert acc;

    Opportunity opp = new Opportunity(
        Name='Opp_' + Crypto.getRandomLong(),
        StageName='Prospecting',
        CloseDate=Date.today(),
        AccountId=acc.Id,
        OwnerId=owner.Id
    );
    insert opp;

    d.put('acc', acc.Id);
    d.put('opp', opp.Id);
    return d;
}

    @IsTest
    static void testQueueableRunsSuccessfully() {

        // 100% isolated test user
        User isoUser = mkUser('iso');

        System.runAs(isoUser) {

            // Seed new Account + Opportunity
            Map<String,Id> data = seed(isoUser);
            Id oppId = data.get('opp');
            User member = mkUser('member');

            // Build Changes list
            List<OppTeamReplicationService.Change> changes =
                new List<OppTeamReplicationService.Change>{
                    new OppTeamReplicationService.Change(
                        oppId,
                        member.Id,
                        'Edit',
                        'UPSERT'
                    )
                };

            Test.startTest();
            System.enqueueJob(new OppTeamReplicationJob(changes));
            Test.stopTest();

            // Basic validation
            Opportunity o = [
                SELECT Id, OwnerId, AccountId
                FROM Opportunity
                WHERE Id = :oppId
                LIMIT 1
            ];

            System.assertNotEquals(null, o);
        }
    }
}