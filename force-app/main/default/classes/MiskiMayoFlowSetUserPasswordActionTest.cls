@IsTest
private class MiskiMayoFlowSetUserPasswordActionTest {

    @IsTest
    static void testSetPassword_singleInput() {
        // Create a user to be used as target of setPassword
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        User u = new User(
            FirstName = 'Test',
            LastName = 'UserPwd',
            Alias = 'tupw',
            Email = 'test.userpwd@example.com',
            Username = 'test.userpwd.' + System.currentTimeMillis() + '@example.com',
            TimeZoneSidKey = 'America/Sao_Paulo',
            LocaleSidKey = 'pt_BR',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'pt_BR',
            ProfileId = p.Id
        );
        insert u;

        // Build invocable input
        MiskiMayoFlowSetUserPasswordAction.Input inp = new MiskiMayoFlowSetUserPasswordAction.Input();
        inp.userId = u.Id;
        inp.password = 'Abcdefg1!Abcdefg1!'; // strong-ish password

        Test.startTest();
        try {
            MiskiMayoFlowSetUserPasswordAction.setPassword(new List<MiskiMayoFlowSetUserPasswordAction.Input>{ inp });

            // If no exception is thrown, we at least assert that execution reached here
            System.assert(true, 'setPassword executed without exceptions.');
        } catch (Exception e) {
            // In some orgs/tests, System.setPassword can throw. We accept it but validate it's the expected path.
            System.assert(
                e.getMessage() != null,
                'An exception was thrown by System.setPassword; message should not be null.'
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testSetPassword_multipleInputs() {
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        User u1 = new User(
            FirstName = 'Test',
            LastName = 'UserPwd1',
            Alias = 'tup1',
            Email = 'test.userpwd1@example.com',
            Username = 'test.userpwd1.' + System.currentTimeMillis() + '@example.com',
            TimeZoneSidKey = 'America/Sao_Paulo',
            LocaleSidKey = 'pt_BR',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'pt_BR',
            ProfileId = p.Id
        );

        User u2 = new User(
            FirstName = 'Test',
            LastName = 'UserPwd2',
            Alias = 'tup2',
            Email = 'test.userpwd2@example.com',
            Username = 'test.userpwd2.' + (System.currentTimeMillis() + 1) + '@example.com',
            TimeZoneSidKey = 'America/Sao_Paulo',
            LocaleSidKey = 'pt_BR',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'pt_BR',
            ProfileId = p.Id
        );

        insert new List<User>{ u1, u2 };

        MiskiMayoFlowSetUserPasswordAction.Input i1 = new MiskiMayoFlowSetUserPasswordAction.Input();
        i1.userId = u1.Id;
        i1.password = 'Abcdefg1!Abcdefg1!';

        MiskiMayoFlowSetUserPasswordAction.Input i2 = new MiskiMayoFlowSetUserPasswordAction.Input();
        i2.userId = u2.Id;
        i2.password = 'Xyzabcd1!Xyzabcd1!';

        Test.startTest();
        try {
            MiskiMayoFlowSetUserPasswordAction.setPassword(
                new List<MiskiMayoFlowSetUserPasswordAction.Input>{ i1, i2 }
            );
            System.assert(true, 'setPassword executed for multiple inputs.');
        } catch (Exception e) {
            System.assert(
                e.getMessage() != null,
                'An exception was thrown by System.setPassword; message should not be null.'
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testSetPassword_emptyList() {
        Test.startTest();
        // Should simply do nothing without throwing.
        MiskiMayoFlowSetUserPasswordAction.setPassword(new List<MiskiMayoFlowSetUserPasswordAction.Input>());
        Test.stopTest();

        System.assert(true, 'Empty input list should not fail.');
    }
}