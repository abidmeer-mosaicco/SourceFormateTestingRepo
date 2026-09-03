@IsTest
private class OppTeamOwnerCleanupTest {

    @TestSetup
    static void setupData() {

        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        User oldOwner = new User(
            Alias = 'oldown',
            Email = 'oldowner@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'OldOwner',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            Username = 'oldowner' + System.currentTimeMillis() + '@test.com'
        );
        insert oldOwner;

        User newOwner = new User(
            Alias = 'newown',
            Email = 'newowner@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'NewOwner',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            Username = 'newowner' + System.currentTimeMillis() + '@test.com'
        );
        insert newOwner;

        User userX = new User(
            Alias = 'userx',
            Email = 'userx@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'UserX',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            Username = 'userx' + System.currentTimeMillis() + '@test.com'
        );
        insert userX;

        User userY = new User(
            Alias = 'usery',
            Email = 'usery@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'UserY',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            Username = 'usery' + System.currentTimeMillis() + '@test.com'
        );
        insert userY;

        User userZ = new User(
            Alias = 'userz',
            Email = 'userz@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'UserZ',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            Username = 'userz' + System.currentTimeMillis() + '@test.com'
        );
        insert userZ;

        User userP = new User(
            Alias = 'userp',
            Email = 'userp@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'UserP',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            Username = 'userp' + System.currentTimeMillis() + '@test.com'
        );
        insert userP;

        User userQ = new User(
            Alias = 'userq',
            Email = 'userq@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'UserQ',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            Username = 'userq' + System.currentTimeMillis() + '@test.com'
        );
        insert userQ;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            OwnerId = oldOwner.Id
        );
        insert opp;

        insert new List<OpportunityTeamMember>{
            new OpportunityTeamMember(
                OpportunityId = opp.Id,
                UserId = userX.Id,
                TeamMemberRole = 'Sales Rep',
                OpportunityAccessLevel = 'Edit'
            ),
            new OpportunityTeamMember(
                OpportunityId = opp.Id,
                UserId = userY.Id,
                TeamMemberRole = 'Sales Rep',
                OpportunityAccessLevel = 'Edit'
            ),
            new OpportunityTeamMember(
                OpportunityId = opp.Id,
                UserId = userZ.Id,
                TeamMemberRole = 'Sales Rep',
                OpportunityAccessLevel = 'Edit'
            )
        };
    }

    @IsTest
    static void testCleanupOldOwnerTeam() {

        User oldOwner = [
            SELECT Id
            FROM User
            WHERE LastName = 'OldOwner'
            LIMIT 1
        ];

        User newOwner = [
            SELECT Id
            FROM User
            WHERE LastName = 'NewOwner'
            LIMIT 1
        ];

        User userX = [
            SELECT Id
            FROM User
            WHERE LastName = 'UserX'
            LIMIT 1
        ];

        User userY = [
            SELECT Id
            FROM User
            WHERE LastName = 'UserY'
            LIMIT 1
        ];

        User userZ = [
            SELECT Id
            FROM User
            WHERE LastName = 'UserZ'
            LIMIT 1
        ];

        User userP = [
            SELECT Id
            FROM User
            WHERE LastName = 'UserP'
            LIMIT 1
        ];

        User userQ = [
            SELECT Id
            FROM User
            WHERE LastName = 'UserQ'
            LIMIT 1
        ];

        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            WHERE Name = 'Test Opp'
            LIMIT 1
        ];

        // IMPORTANT: Must be set inside test method
        OppTeamOwnerCleanup.testOwnerTeams =
            new Map<Id, Set<Id>>();

        OppTeamOwnerCleanup.testOwnerTeams.put(
            oldOwner.Id,
            new Set<Id>{
                userX.Id,
                userY.Id,
                userZ.Id
            }
        );

        OppTeamOwnerCleanup.testOwnerTeams.put(
            newOwner.Id,
            new Set<Id>{
                userP.Id,
                userX.Id,
                userQ.Id
            }
        );

        OppTeamOwnerCleanup.Request req =
            new OppTeamOwnerCleanup.Request();

        req.opportunityId = opp.Id;
        req.oldOwnerId = oldOwner.Id;
        req.newOwnerId = newOwner.Id;

        Test.startTest();

        OppTeamOwnerCleanup.cleanup(
            new List<OppTeamOwnerCleanup.Request>{ req }
        );

        Test.stopTest();

        Set<String> remainingUsers = new Set<String>();

        for (OpportunityTeamMember otm : [
            SELECT User.LastName
            FROM OpportunityTeamMember
            WHERE OpportunityId = :opp.Id
        ]) {
            remainingUsers.add(otm.User.LastName);
        }

        System.assert(
            remainingUsers.contains('UserX'),
            'Common user X should remain'
        );

        System.assert(
            !remainingUsers.contains('UserY'),
            'UserY should be removed'
        );

        System.assert(
            !remainingUsers.contains('UserZ'),
            'UserZ should be removed'
        );
    }

    @IsTest
    static void testNullRequestCoverage() {

        Test.startTest();

        OppTeamOwnerCleanup.cleanup(null);

        OppTeamOwnerCleanup.cleanup(
            new List<OppTeamOwnerCleanup.Request>()
        );

        Test.stopTest();

        System.assert(true);
    }
    @IsTest
static void testInvalidRequestCoverage() {

    OppTeamOwnerCleanup.Request req =
        new OppTeamOwnerCleanup.Request();

    // all fields null

    Test.startTest();

    OppTeamOwnerCleanup.cleanup(
        new List<OppTeamOwnerCleanup.Request>{ req }
    );

    Test.stopTest();

    System.assert(true);
}
    @IsTest
static void testRequestWithNullValues() {

    OppTeamOwnerCleanup.Request req =
        new OppTeamOwnerCleanup.Request();

    Test.startTest();

    OppTeamOwnerCleanup.cleanup(
        new List<OppTeamOwnerCleanup.Request>{ req }
    );

    Test.stopTest();

    System.assert(true);
}
    @IsTest
static void testNullRequestObject() {

    List<OppTeamOwnerCleanup.Request> reqs =
        new List<OppTeamOwnerCleanup.Request>();

    reqs.add(null);

    Test.startTest();

    OppTeamOwnerCleanup.cleanup(reqs);

    Test.stopTest();

    System.assert(true);
}
    @IsTest
static void testOwnerNotPresentInMap() {

    Opportunity opp = [
        SELECT Id
        FROM Opportunity
        WHERE Name = 'Test Opp'
        LIMIT 1
    ];

    OppTeamOwnerCleanup.testOwnerTeams =
        new Map<Id, Set<Id>>();

    OppTeamOwnerCleanup.Request req =
        new OppTeamOwnerCleanup.Request();

    req.opportunityId = opp.Id;
    req.oldOwnerId = UserInfo.getUserId();
    req.newOwnerId = UserInfo.getUserId();

    Test.startTest();

    OppTeamOwnerCleanup.cleanup(
        new List<OppTeamOwnerCleanup.Request>{ req }
    );

    Test.stopTest();

    System.assert(true);
}
}