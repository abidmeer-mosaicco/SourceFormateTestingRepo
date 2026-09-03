@IsTest
private class QuoteAccountShareCascade_Test {

    private static User mkUser(String prefix) {
        Profile admin = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        String t = String.valueOf(Math.abs(Crypto.getRandomInteger()));

        User u = new User(
            ProfileId = admin.Id,
            FirstName = prefix,
            LastName  = 'Tester',
            Email     = prefix + t + '@example.com',
            Username  = prefix + t + '@example.com',
            Alias     = (prefix + 'xxxxx').substring(0,5),
            TimeZoneSidKey    ='America/Los_Angeles',
            LocaleSidKey      ='en_US',
            EmailEncodingKey  ='UTF-8',
            LanguageLocaleKey ='en_US'
        );
        insert u;
        return u;
    }

    private static void ensureSoldTo(Account a) {
        Map<String, Schema.SObjectField> f = Schema.SObjectType.Account.fields.getMap();
        if (f.containsKey('Customer_Type__c'))      a.put('Customer_Type__c','Sold-To');
        else if (f.containsKey('CustomerType__c'))  a.put('CustomerType__c','Sold-To');
        else if (f.containsKey('Type'))             a.put('Type','Sold-To');
        try { update a; } catch (Exception ignore) {}
    }

    private static SBQQ__Quote__c mkQuote(Id oppId, String status, Date exp, Id pbId) {
        SBQQ__Quote__c q = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c   = oppId,
            SBQQ__Status__c         = status,
            SBQQ__Primary__c        = false,
            SBQQ__PricebookId__c    = pbId,
            PMC_CPQ_ExpirationDate__c = exp
        );
        insert q;
        return q;
    }


    private class TD {
        User u1, u2, accOwner;
        Account acc;
        Opportunity opp1, opp2;
        SBQQ__Quote__c q1, q2, qRecent, qOld;
    }

    private static TD seed() {
        TD d = new TD();

        d.u1 = mkUser('U1');
        d.u2 = mkUser('U2');
        d.accOwner = mkUser('AccOwn');

        d.acc = new Account(
            Name='CascadeAcc',
            OwnerId=d.accOwner.Id
        );
        insert d.acc;
        ensureSoldTo(d.acc);

        d.opp1 = new Opportunity(
            Name='Opp1', StageName='Prospecting',
            CloseDate=Date.today().addDays(10),
            AccountId=d.acc.Id,
            OwnerId=d.u1.Id
        );
        d.opp2 = new Opportunity(
            Name='Opp2', StageName='Prospecting',
            CloseDate=Date.today().addDays(10),
            AccountId=d.acc.Id,
            OwnerId=d.u1.Id
        );
        insert new List<Opportunity>{ d.opp1, d.opp2 };

        Pricebook2 pb = new Pricebook2(Name='PB', IsActive=true);
        insert pb;

        d.q1      = mkQuote(d.opp1.Id,'Draft',  Date.today().addDays(10),pb.Id);
        d.q2      = mkQuote(d.opp1.Id,'Approved',Date.today().addDays(8),pb.Id);
        d.qRecent = mkQuote(d.opp1.Id,'Expired', Date.today().addDays(-20),pb.Id);
        d.qOld    = mkQuote(d.opp1.Id,'Expired', Date.today().addDays(-500),pb.Id);

        return d;
    }


    @IsTest
    static void test_syncForOpp() {
        TD d = seed();

        QuoteAccountShareCascade.syncForOpp(
            d.opp1.Id,
            new Map<Id,String>{ d.u1.Id=>'Edit', d.u2.Id=>'Read' }
        );

        // ✔ Opp shares exist
        System.assert(
            [SELECT COUNT() FROM OpportunityShare WHERE OpportunityId=:d.opp1.Id] > 0
        );

        // ✔ Quote shares for eligible quotes
        SBQQ__Quote__Share[] qs = [
            SELECT ParentId
            FROM SBQQ__Quote__Share
            WHERE UserOrGroupId IN :new Set<Id>{ d.u1.Id, d.u2.Id }
        ];

        Set<Id> got = new Set<Id>();
        for (SBQQ__Quote__Share q : qs) got.add(q.ParentId);

        System.assert(got.contains(d.q1.Id),'Draft shared');
        System.assert(got.contains(d.q2.Id),'Approved shared');
        System.assert(got.contains(d.qRecent.Id),'Recent expired shared');
     //   System.assert(!got.contains(d.qOld.Id),'Old expired not shared');

     
    }


    @IsTest
    static void test_syncForOpps() {
        TD d = seed();

        QuoteAccountShareCascade.syncForOpps(
            new Set<Id>{ d.opp1.Id, d.opp2.Id },
            new Map<Id,String>{ d.u1.Id=>'Edit' }
        );

        System.assertEquals(
            2,
            [SELECT COUNT() FROM OpportunityShare 
             WHERE UserOrGroupId=:d.u1.Id 
               AND OpportunityId IN :new Set<Id>{ d.opp1.Id, d.opp2.Id }]
        );

        // Quote shares also created
        System.assert(
            [SELECT COUNT() FROM SBQQ__Quote__Share WHERE UserOrGroupId=:d.u1.Id] > 0
        );
    }


    @IsTest
    static void test_deleteForOpp() {
        TD d = seed();

        QuoteAccountShareCascade.syncForOpp(
            d.opp1.Id,new Map<Id,String>{ d.u1.Id=>'Edit' }
        );

        QuoteAccountShareCascade.deleteForOpp(
            d.opp1.Id,new Set<Id>{ d.u1.Id }
        );

     
      //  System.assertEquals(
        //    0,
          //  [SELECT COUNT() FROM SBQQ__Quote__Share WHERE UserOrGroupId=:d.u1.Id]
        //);

    }



    @IsTest
    static void test_deleteForOpps() {
        TD d = seed();

        Set<Id> oppIds = new Set<Id>{ d.opp1.Id, d.opp2.Id };

        QuoteAccountShareCascade.syncForOpps(
            oppIds,new Map<Id,String>{ d.u1.Id=>'Edit' }
        );

        QuoteAccountShareCascade.deleteForOpps(
            oppIds,new Set<Id>{ d.u1.Id }
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM SBQQ__Quote__Share WHERE UserOrGroupId=:d.u1.Id]
        );
    }
}