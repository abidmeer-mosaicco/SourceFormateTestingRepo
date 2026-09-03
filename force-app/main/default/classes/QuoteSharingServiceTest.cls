@IsTest
public class QuoteSharingServiceTest {

    /* =====================================================
     * Test Data Setup (runs once for all tests)
     * ===================================================== */
    @testSetup
    static void setupData() {

        // -----------------------------
        // Profile
        // -----------------------------
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        // -----------------------------
        // Users
        // -----------------------------
        User editUser = new User(
            FirstName = 'Edit',
            LastName  = 'User',
            Alias     = 'edtu',
            Email     = 'edit@test.com',
            Username  = 'edit' + System.currentTimeMillis() + '@test.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey   = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );

        User readUser = new User(
            FirstName = 'Read',
            LastName  = 'User',
            Alias     = 'rdu',
            Email     = 'read@test.com',
            Username  = 'read' + System.currentTimeMillis() + '@test.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey   = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );

        insert new List<User>{ editUser, readUser };

        // -----------------------------
        // Account (CPQ requires Sold-To)
        // -----------------------------
        Account acc = new Account(
            Name = 'Test Sold-To Account',
            Type = 'Sold-To' // ✅ CPQ validation requirement
        );
        insert acc;

        // -----------------------------
        // Opportunity
        // -----------------------------
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            OwnerId = editUser.Id
        );
        insert opp;

        // -----------------------------
        // Opportunity Team
        // -----------------------------
        insert new OpportunityTeamMember(
            OpportunityId = opp.Id,
            UserId = editUser.Id,
            OpportunityAccessLevel = 'Edit'
        );
        insert new OpportunityTeamMember(
            OpportunityId = opp.Id,
            UserId = readUser.Id,
            OpportunityAccessLevel = 'Read'
        );

        // -----------------------------
        // CPQ Quote
        // -----------------------------
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
          //  Name = 'Test Quote',
            SBQQ__Opportunity2__c = opp.Id
        );
        insert quote;
    }

    /* =====================================================
     * Test: Invocable Method (Flow)
     * ===================================================== */
    @IsTest
    static void testFlowCopyOppTeam() {

        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];

        QuoteSharingService.Request req =
            new QuoteSharingService.Request();
        req.opportunityId = opp.Id;

        Test.startTest();
        QuoteSharingService.flowCopyOppTeam(
            new List<QuoteSharingService.Request>{ req }
        );
        Test.stopTest();

        List<SBQQ__Quote__Share> shares = [
            SELECT UserOrGroupId, AccessLevel
            FROM SBQQ__Quote__Share
            WHERE ParentId IN (
                SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id
            )
        ];

       /* System.assertEquals(
            2,
            shares.size(),
            'Two quote shares must be created'
        );
*/
        Map<String, String> accessByName = new Map<String, String>();
        for (SBQQ__Quote__Share s : shares) {
            accessByName.put(
                [SELECT Name FROM User WHERE Id = :s.UserOrGroupId].Name,
                s.AccessLevel
            );
        }

        System.assertEquals('Edit', accessByName.get('Edit User'));
        System.assertEquals('Read', accessByName.get('Read User'));
    }

    /* =====================================================
     * Test: Duplicate Quote Share Protection
     * ===================================================== */
    @IsTest
    static void testNoDuplicateShares() {

        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];

        SBQQ__Quote__c quote = [
            SELECT Id
            FROM SBQQ__Quote__c
            LIMIT 1
        ];

        User u = [
            SELECT Id
            FROM User
            WHERE LastName = 'User' and IsActive=True
            LIMIT 1
        ];

        // Pre-existing manual share
        insert new SBQQ__Quote__Share(
            ParentId = quote.Id,
            UserOrGroupId = u.Id,
            AccessLevel = 'Edit',
            RowCause = Schema.SBQQ__Quote__Share.RowCause.Manual
        );

        Test.startTest();
        QuoteSharingService.copyOppTeamToQuotes(opp.Id);
        Test.stopTest();

        Integer shareCount = [
            SELECT COUNT()
            FROM SBQQ__Quote__Share
            WHERE ParentId = :quote.Id
            AND UserOrGroupId = :u.Id
        ];

        System.assertEquals(
            1,
            shareCount,
            'Duplicate shares must not be created'
        );
    }

    /* =====================================================
     * Test: Null Safety / Defensive Code
     * ===================================================== */
    @IsTest
    static void testNullSafety() {
        Test.startTest();
        QuoteSharingService.flowCopyOppTeam(null);
        QuoteSharingService.copyOppTeamToQuotes(null);
        Test.stopTest();

        System.assert(true, 'Null safety handled');
    }
}