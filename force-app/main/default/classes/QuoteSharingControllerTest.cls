@isTest
private class QuoteSharingControllerTest {
    
    @testSetup
    static void setupData() {
        // Create a test user to act as shared user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User sharedUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@test.mosaicco.com',
            Alias = 'tuser',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert sharedUser;

        // Create a test Quote
       SBQQ__Quote__c quote = new SBQQ__Quote__c();
insert quote;

        // Create initial share record
        SBQQ__Quote__Share share = new SBQQ__Quote__Share(
            ParentId = quote.Id,
            UserOrGroupId = sharedUser.Id,
            AccessLevel = 'Read',
           // RowCause = Schema.SBQQ__Quote__Share.RowCause.Manual
           RowCause ='Manual'
        );
        insert share;
    }

    @isTest
    static void testGetQuoteShares() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Test.startTest();
        List<QuoteSharingController.QuoteShareWrapper> shares = QuoteSharingController.getQuoteShares(quote.Id);
        Test.stopTest();
        System.assertEquals(1, shares.size());
        System.assertEquals('Read', shares[0].accessLevel);
    }

    @isTest
    static void testShareQuote() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        User user = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];

        Test.startTest();
        // Call again with same user - should not create a duplicate
        QuoteSharingController.shareQuote(quote.Id, user.Id, 'Read');
        Test.stopTest();

        List<SBQQ__Quote__Share> shares = [SELECT Id FROM SBQQ__Quote__Share WHERE ParentId = :quote.Id AND UserOrGroupId = :user.Id];
        System.assertEquals(1, shares.size()); // still 1, no duplicate
    }

    @isTest
    static void testRemoveQuoteShare() {
        SBQQ__Quote__Share share = [SELECT Id FROM SBQQ__Quote__Share where UserOrGroup.Type='User' LIMIT 1];
        Test.startTest();
        QuoteSharingController.removeQuoteShare(share.Id);
        Test.stopTest();

        List<SBQQ__Quote__Share> remaining = [SELECT Id FROM SBQQ__Quote__Share WHERE Id = :share.Id];
        System.assertEquals(0, remaining.size());
    }

    @isTest
    static void testRemoveShare() {
        // Create a new share to delete
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        User user = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        SBQQ__Quote__Share share = new SBQQ__Quote__Share(
            ParentId = quote.Id,
            UserOrGroupId = user.Id,
            AccessLevel = 'Read',
            RowCause = Schema.SBQQ__Quote__Share.RowCause.Manual
        );
        insert share;

        Test.startTest();
        QuoteSharingController.removeShare(share.Id);
        Test.stopTest();

        List<SBQQ__Quote__Share> remaining = [SELECT Id FROM SBQQ__Quote__Share WHERE Id = :share.Id];
        System.assertEquals(0, remaining.size());
    }

    @isTest
    static void testUpdateAccessLevels() {
        SBQQ__Quote__Share share = [SELECT Id, AccessLevel FROM SBQQ__Quote__Share WHERE RowCause != 'Owner' LIMIT 1];

        QuoteSharingController.QuoteShareWrapper wrapper = new QuoteSharingController.QuoteShareWrapper();
        wrapper.id = share.Id;
        wrapper.accessLevel = 'Edit';

        Test.startTest();
        QuoteSharingController.updateAccessLevels(new List<QuoteSharingController.QuoteShareWrapper>{ wrapper });
        Test.stopTest();

        SBQQ__Quote__Share updated = [SELECT Id, AccessLevel FROM SBQQ__Quote__Share WHERE Id = :share.Id];
        System.assertEquals('Edit', updated.AccessLevel);
    }
}