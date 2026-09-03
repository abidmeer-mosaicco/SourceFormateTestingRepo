@isTest
public class UserLookupControllerTest {

    @testSetup
    static void setup() {
        // Create test users
        List<User> testUsers = new List<User>();

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        testUsers.add(new User(
            FirstName = 'John',
            LastName = 'Doe',
            Alias = 'jdoe',
            Email = 'jdoe@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@test.mosaicco.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        ));

        testUsers.add(new User(
            FirstName = 'Jane',
            LastName = 'Smith',
            Alias = 'jsmith',
            Email = 'jsmith@example.com',
            Username = 'jsmith1@example.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        ));

        insert testUsers;
    }

    @isTest
    static void testSearchUsersWithValidKey() {
        Test.startTest();
        List<User> result = UserLookupController.searchUsers('John');
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Should return at least one user');
        System.assert(result[0].Name.contains('John'), 'User name should contain the search key');
    }

    @isTest
    static void testSearchUsersWithEmptyKey() {
        Test.startTest();
        List<User> result = UserLookupController.searchUsers('');
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty list for empty search key');
    }

    @isTest
    static void testSearchUsersWithNoMatch() {
        Test.startTest();
        List<User> result = UserLookupController.searchUsers('DoesNotExist');
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return no users for unmatched search key');
    }

    @isTest
    static void testSearchUsersWithSpecialCharacters() {
        Test.startTest();
        List<User> result = UserLookupController.searchUsers('Jo\'hn');
        Test.stopTest();

        System.assert(result != null, 'Method should not throw an exception for special characters');
    }
}