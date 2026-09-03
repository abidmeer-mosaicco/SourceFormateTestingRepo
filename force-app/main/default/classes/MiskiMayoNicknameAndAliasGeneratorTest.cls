@IsTest
private class MiskiMayoNicknameAndAliasGeneratorTest {

    @IsTest
    static void testNicknameGenerator_Length_And_Uniqueness_And_Collision() {
        // Create a user with a known CommunityNickname to force a collision
        String collisionValue = 'AbC123xYzKLMnOpQrStUvWxYz0123456789ABCDE';
        System.assertEquals(40, collisionValue.length(), 'Collision nickname must be 40 chars');

        User u = buildUser('nick.test', collisionValue);
        insert u;

        // Force the generator to try the collision value first, then it must retry
        MiskiMayoNIckNameGenerator.forcedCandidateOnce = collisionValue;

        Test.startTest();
        List<String> out = MiskiMayoNIckNameGenerator.generate();
        Test.stopTest();

        System.assertEquals(1, out.size());
        System.assertEquals(40, out[0].length());
        System.assertNotEquals(collisionValue, out[0], 'Should retry after collision');

        // Ensure returned value is not used
        System.assertEquals(
            0,
            [SELECT COUNT() FROM User WHERE CommunityNickname = :out[0]],
            'Generated nickname must be unique'
        );
    }

    @IsTest
    static void testAliasGenerator_Length_And_Uniqueness_And_Collision() {
        // Create a user with a known CommunityNickname to force a collision
        String collisionValue = 'Aa1Bb2Cc'; // 8 chars
        System.assertEquals(8, collisionValue.length(), 'Collision value must be 8 chars');

        User u = buildUser('alias.test', collisionValue);
        insert u;

        // Force the generator to try the collision value first, then it must retry
        MiskiMayoAliasGenerator.forcedCandidateOnce = collisionValue;

        Test.startTest();
        List<String> out = MiskiMayoAliasGenerator.generate();
        Test.stopTest();

        System.assertEquals(1, out.size());
        System.assertEquals(8, out[0].length());
        System.assertNotEquals(collisionValue, out[0], 'Should retry after collision');

        System.assertEquals(
            0,
            [SELECT COUNT() FROM User WHERE CommunityNickname = :out[0]],
            'Generated value must be unique vs CommunityNickname'
        );
    }

    // Helper to build a valid user in tests
    private static User buildUser(String prefix, String communityNickname) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        String unique = String.valueOf(DateTime.now().getTime());
        return new User(
            ProfileId = p.Id,
            Username = prefix + '.' + unique + '@example.com',
            Email = prefix + '.' + unique + '@example.com',
            LastName = 'Test',
            Alias = 'tstusr',
            TimeZoneSidKey = 'America/Sao_Paulo',
            LocaleSidKey = 'pt_BR',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'pt_BR',
            CommunityNickname = communityNickname
        );
    }
}