@isTest
public class OppTeamFinalBackfillBatchTest {

    @isTest
    static void testBatchExecution() {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@test.com',
            Username = 'test' + DateTime.now().getTime() + '@test.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;

    
        Account acc = new Account(Name = 'Test Account');
        insert acc;

 
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            OwnerId = u.Id,
            AccountId = acc.Id
        );
        insert opp;

        
        SBQQ__Quote__c q = new SBQQ__Quote__c(
           // Name = 'Test Quote',
            SBQQ__Opportunity2__c = opp.Id
        );
        insert q;

        Test.startTest();

       // Database.executeBatch(new OppTeamFinalBackfillBatch(), 1);
        Database.executeBatch(
    new OppTeamFinalBackfillBatch(new Set<Id>{ u.Id }),
    1
);

        Test.stopTest();

       
        List<OpportunityTeamMember> otm = [
            SELECT Id FROM OpportunityTeamMember WHERE OpportunityId = :opp.Id
        ];
       // System.assertNotEquals(0, otm.size());
        System.assertNotEquals(0, otm.size());
    }
}