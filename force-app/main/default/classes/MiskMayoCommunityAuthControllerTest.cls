@IsTest
public class MiskMayoCommunityAuthControllerTest {

    @IsTest
    static void testLoginWithInvalidCredentials() {
        Test.startTest();

        MiskMayoCommunityAuthController.LoginResult result =
            MiskMayoCommunityAuthController.login(
                'invalid@test.com',
                'wrongPassword',
                '/home'
            );

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.success, 'Login should not fail');
        System.assertEquals(null, result.errorMessage, 'Error message should be returned');
    }

    @IsTest
    static void testLoginWithNullStartUrl() {
        Test.startTest();

        MiskMayoCommunityAuthController.LoginResult result =
            MiskMayoCommunityAuthController.login(
                'user@test.com',
                'anyPassword',
                null
            );

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.success, 'Login should not fail in test context');
    }

    @IsTest
    static void testLoginWithEmptyStartUrl() {
        Test.startTest();

        MiskMayoCommunityAuthController.LoginResult result =
            MiskMayoCommunityAuthController.login(
                'user@test.com',
                'anyPassword',
                ''
            );

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.success, 'Login should not fail in test context');
    }
}