@IsTest
private class OppTeamCascadeQueueable_Test {

  
    private static User mkUser(String prefix){
        Profile p = [SELECT Id FROM Profile LIMIT 1];
        String key = prefix + '_' + Crypto.getRandomLong() + '_' + DateTime.now().getTime();

        User u = new User(
            ProfileId = p.Id,
            FirstName = prefix,
            LastName  = 'Tester',
            Email     = key + '@test.com',
            Username  = key + '@test.com',
            Alias     = prefix.left(5),
            TimeZoneSidKey='America/Los_Angeles',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US'
        );
        insert u;
        return u;
    }

    private static Account mkAccount() {
        Account a = new Account(
            Name = 'Acc_' + Crypto.getRandomLong(),
            BillingStreet = '123 Test Street',
            BillingCity = 'San Francisco',
            BillingStateCode = 'CA',
            BillingPostalCode = '94105',
            BillingCountryCode = 'US',
            Type='Sold-to'
        );
        insert a;
        return a;
    }

    private static Opportunity mkOpp(Account acc, User owner) {
        Opportunity o = new Opportunity(
            Name = 'Opp_' + Crypto.getRandomLong(),
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            OwnerId   = owner.Id
        );
        insert o;
        return o;
    }

 
    private static SBQQ__Quote__c mkQuote(Opportunity opp) {
        SBQQ__Quote__c q = new SBQQ__Quote__c(
          //  Name = 'Quote_' + Crypto.getRandomLong(),
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Status__c = 'Draft'
        );
        insert q;
        return q;
    }

 
    @IsTest
    static void test_OppTeamCascadeQueueable_executes() {

        // --- Users ---
        User owner  = mkUser('owner');
        User member = mkUser('member');

        System.runAs(owner) {

            // --- Data ---
            Account acc = mkAccount();
            Opportunity opp = mkOpp(acc, owner);

          
            SBQQ__Quote__c quote = mkQuote(opp);

        
            Set<Id> oppIds = new Set<Id>{ opp.Id };
            Map<Id, String> userToLevel = new Map<Id, String>{
                member.Id => 'Edit'
            };

            
            Test.startTest();
            System.enqueueJob(
                new OppTeamCascadeQueueable(oppIds, userToLevel)
            );
            Test.stopTest();

          
            Integer otmCount = [
                SELECT COUNT()
                FROM OpportunityTeamMember
                WHERE OpportunityId = :opp.Id
                AND UserId = :member.Id
            ];
            System.assert(
                otmCount >= 1,
                'OpportunityTeamMember should exist after cascade'
            );
        }
    }
}