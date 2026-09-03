@isTest
private class md_cdlTriggerTest {

    private static final String HANDLER_NAME = 'md_cdlTriggerHandler';

    private static Account makeAccount() {
        Account a = new Account(Name = 'Test Account');
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        Database.insert(a, dml);
        return a;
    }

    private static SBQQ__Quote__c makeQuote(Id accountId) {
        SBQQ__Quote__c q = new SBQQ__Quote__c(
            SBQQ__Account__c = accountId,
            SBQQ__Primary__c = true
        );
        SBQQ.TriggerControl.disable();
        insert q;
        SBQQ.TriggerControl.enable();
        return q;
    }

    private static ContentDocumentLink attachFile(Id linkedEntityId, String visibility) {
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('SAMPLE-PDF-CONTENT')
        );
        insert cv;
        Id contentDocumentId = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = linkedEntityId,
            ContentDocumentId = contentDocumentId,
            ShareType = 'V',
            Visibility = visibility
        );
        insert cdl;
        return cdl;
    }

    @isTest
    static void testTrigger_QuoteLink_InternalUsers_FlippedToAllUsers() {
        Account acc = makeAccount();
        SBQQ__Quote__c q = makeQuote(acc.Id);

        Test.startTest();
        ContentDocumentLink cdl = attachFile(q.Id, 'InternalUsers');
        Test.stopTest();

        ContentDocumentLink result = [SELECT Visibility FROM ContentDocumentLink WHERE Id = :cdl.Id];
        System.assertEquals('AllUsers', result.Visibility,
            'CDL linked to a Quote should be flipped to AllUsers');
    }

    @isTest
    static void testTrigger_QuoteLink_AlreadyAllUsers_NoOp() {
        Account acc = makeAccount();
        SBQQ__Quote__c q = makeQuote(acc.Id);

        Test.startTest();
        ContentDocumentLink cdl = attachFile(q.Id, 'AllUsers');
        Test.stopTest();

        ContentDocumentLink result = [SELECT Visibility FROM ContentDocumentLink WHERE Id = :cdl.Id];
        System.assertEquals('AllUsers', result.Visibility,
            'CDL already AllUsers should remain unchanged');
    }

    @isTest
    static void testTrigger_NonQuoteLink_VisibilityUnchanged() {
        Account acc = makeAccount();

        Test.startTest();
        ContentDocumentLink cdl = attachFile(acc.Id, 'InternalUsers');
        Test.stopTest();

        ContentDocumentLink result = [SELECT Visibility FROM ContentDocumentLink WHERE Id = :cdl.Id];
        System.assertEquals('InternalUsers', result.Visibility,
            'CDL linked to a non-Quote record should keep its original Visibility');
    }

    @isTest
    static void testHandler_Bypass_SkipsTriggerLogic() {
        Account acc = makeAccount();
        SBQQ__Quote__c q = makeQuote(acc.Id);

        PMC_TriggerHandler.bypass(HANDLER_NAME);

        Test.startTest();
        ContentDocumentLink cdl = attachFile(q.Id, 'InternalUsers');
        Test.stopTest();

        PMC_TriggerHandler.clearBypass(HANDLER_NAME);

        ContentDocumentLink result = [SELECT Visibility FROM ContentDocumentLink WHERE Id = :cdl.Id];
        System.assertEquals('InternalUsers', result.Visibility,
            'Bypassed handler should not change Visibility');
    }
}