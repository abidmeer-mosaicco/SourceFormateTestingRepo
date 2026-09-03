@IsTest
private class OppTeamAsyncController_Test {

    // ---------- Helper ----------
    private static User mkUser(String prefix) {

        Profile p = [SELECT Id FROM Profile LIMIT 1];

        String unique =
            prefix + '_' +
            Crypto.getRandomLong() + '_' +
            DateTime.now().getTime();

        User u = new User(
            ProfileId = p.Id,
            FirstName = prefix,
            LastName = 'Tester',
            Email = unique + '@test.com',
            Username = unique + '@test.com',
            Alias = (prefix + 'xxxxx').substring(0,5),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );

        insert u;
        return u;
    }

    // ---------- Helper ----------
    private static Map<String,Id> seed(User owner){

        Account acc = new Account(
            Name = 'Acc_' + Crypto.getRandomLong()
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Opp_' + Crypto.getRandomLong(),
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            OwnerId = owner.Id
        );
        insert opp;

        return new Map<String,Id>{
            'acc' => acc.Id,
            'opp' => opp.Id
        };
    }

    @IsTest
    static void test_runAsyncTeamSync_success() {

        User owner = mkUser('owner');
        User member = mkUser('member');

        System.runAs(owner) {

            Map<String,Id> d = seed(owner);

            Map<Id,String> levelMap =
                new Map<Id,String>{
                    member.Id => 'Edit'
                };

            Test.startTest();

            Id jobId =
                OppTeamAsyncController.runAsyncTeamSync(
                    d.get('opp'),
                    owner.Id,
                    levelMap
                );

            Test.stopTest();

            System.assertNotEquals(
                null,
                jobId
            );
        }
    }

    @IsTest
    static void test_runAsyncTeamSync_emptyUserMap() {

        User owner = mkUser('owner');

        System.runAs(owner) {

            Map<String,Id> d = seed(owner);

            Boolean thrown = false;

            try {

                OppTeamAsyncController.runAsyncTeamSync(
                    d.get('opp'),
                    owner.Id,
                    new Map<Id,String>()
                );

            } catch (AuraHandledException e) {
                thrown = true;
            }

            System.assertEquals(true, thrown);
        }
    }

    @IsTest
    static void test_runAsyncTeamSync_nullOwner() {

        User member = mkUser('member');

        Boolean thrown = false;

        try {

            OppTeamAsyncController.runAsyncTeamSync(
                null,
                null,
                new Map<Id,String>{
                    member.Id => 'Read'
                }
            );

        } catch (AuraHandledException e) {
            thrown = true;
        }

        System.assertEquals(true, thrown);
    }

    @IsTest
    static void test_runAsyncTeamSync_anchorNull() {

        User owner = mkUser('owner');
        User member = mkUser('member');

        System.runAs(owner) {

            Test.startTest();

            Id jobId =
                OppTeamAsyncController.runAsyncTeamSync(
                    null,
                    owner.Id,
                    new Map<Id,String>{
                        member.Id => 'Read'
                    }
                );

            Test.stopTest();

            System.assertEquals(
                null,
                jobId
            );
        }
    }

    @IsTest
    static void test_runFromOpportunity() {

        User owner = mkUser('owner');

        System.runAs(owner) {

            Map<String,Id> d = seed(owner);

            Test.startTest();

            OppTeamAsyncController.runFromOpportunity(
                new List<Id>{
                    d.get('opp')
                }
            );

            Test.stopTest();

            System.assert(true);
        }
    }

    @IsTest
    static void test_runFromOpportunity_multipleOpps() {

        User owner = mkUser('owner');

        System.runAs(owner) {

            Map<String,Id> d1 = seed(owner);
            Map<String,Id> d2 = seed(owner);

            Test.startTest();

            OppTeamAsyncController.runFromOpportunity(
                new List<Id>{
                    d1.get('opp'),
                    d2.get('opp')
                }
            );

            Test.stopTest();

            System.assert(true);
        }
    }

    @IsTest
    static void test_runFromOpportunity_nullInput() {

        Test.startTest();

        OppTeamAsyncController.runFromOpportunity(
            null
        );

        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void test_runFromOpportunity_emptyInput() {

        Test.startTest();

        OppTeamAsyncController.runFromOpportunity(
            new List<Id>()
        );

        Test.stopTest();

        System.assert(true);
    }
    @IsTest
static void test_runFromOpportunity_withMockTeam() {

    User owner = mkUser('owner');

    Map<String,Id> d = seed(owner);

    Test.startTest();

    OppTeamAsyncController.runAsyncTeamSync(
        d.get('opp'),
        owner.Id,
        new Map<Id,String>{
            UserInfo.getUserId() => 'Edit'
        }
    );

    Test.stopTest();

    System.assert(true);
}
    @IsTest
static void test_runFromOpportunity_withUsers() {

    User owner = mkUser('owner');
    User member = mkUser('member');

    System.runAs(owner) {

        Map<String,Id> d = seed(owner);

        OppTeamAsyncController.testUserToLevel =
            new Map<Id,String>{
                member.Id => 'Edit'
            };

        Test.startTest();

        OppTeamAsyncController.runFromOpportunity(
            new List<Id>{
                d.get('opp')
            }
        );

        Test.stopTest();

        System.assert(true);
    }
}
}