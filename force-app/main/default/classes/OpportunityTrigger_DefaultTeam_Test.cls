@IsTest(SeeAllData=true)
private class OpportunityTrigger_DefaultTeam_Test {

    @IsTest
    static void testDefaultOppTeamAppliedOnInsert() {

        // 1️⃣ Find a user who already has a Default Opportunity Team
        User owner = [
            SELECT Id
            FROM User
            WHERE Id IN (
                SELECT OwnerId
                FROM UserTeamMember
            )
            AND IsActive = true
            LIMIT 1
        ];

        System.assertNotEquals(
            null,
            owner,
            'Test requires at least one user with a Default Opportunity Team'
        );

        // 2️⃣ Create Opportunity owned by that user
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            OwnerId = owner.Id
        );

        Test.startTest();
        insert opp;   // 🔥 fires Opportunity after-insert trigger
        Test.stopTest();

        // 3️⃣ Assert team members were applied
        Integer teamCount = [
            SELECT COUNT()
            FROM OpportunityTeamMember
            WHERE OpportunityId = :opp.Id
        ];

        System.assert(
            teamCount > 0,
            'Opportunity Team should be created from User Default Team'
        );
    }
}