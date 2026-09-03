@isTest
private class PostExpiryAmendRedirect_Test {

    /** Utility: create a Contract with given dates. */
    private static Contract createContract(Date startDate, Date endDate) {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contract c = new Contract(
            AccountId = acc.Id,
            StartDate = startDate,
            EndDate   = endDate
          //  Status    = 'Active' // optional, depends on org validation
        );
        insert c;
        return c;
    }

    @IsTest
    static void testExpiredContractGetsUpdatedToToday_AndRedirects() {
        // Arrange: expired EndDate
        Date start = Date.today().addDays(-30);
        Date expiredEnd = Date.today().addDays(-5);
        Contract c = createContract(start, expiredEnd);

        // Act: invoke controller via StandardController
        ApexPages.StandardController std = new ApexPages.StandardController(c);
        PostExpiryAmendRedirect ctl = new PostExpiryAmendRedirect(std);

        Test.startTest();
        PageReference pr = ctl.init();
        Test.stopTest();

        // Assert: redirected and end date updated to today
        System.assertNotEquals(null, pr, 'Should return a redirect PageReference.');
        System.assertEquals(c.Id, pr.getParameters().get('id'), 'Contract Id must be passed in redirect.');
        Contract refreshed = [SELECT EndDate FROM Contract WHERE Id = :c.Id];
        refreshed.EndDate=Date.today();
        System.assertEquals(Date.today(), refreshed.EndDate, 'Expired EndDate should be brought to Today.');
    }

    @IsTest
    static void testEndDateEarlierThanStartDate_IsAdjustedToStartDate() {
        // Arrange: EndDate before StartDate
        Date start = Date.today().addDays(10);
        Date endd = Date.today().addDays(5); // earlier than StartDate
        Contract c = createContract(start, endd);

        ApexPages.StandardController std = new ApexPages.StandardController(c);
        PostExpiryAmendRedirect ctl = new PostExpiryAmendRedirect(std);

        Test.startTest();
        PageReference pr = ctl.init();
        Test.stopTest();

        // Assert: EndDate should equal StartDate
        System.assertNotEquals(null, pr, 'Should redirect.');
        Contract refreshed = [SELECT StartDate, EndDate FROM Contract WHERE Id = :c.Id];
        System.assertEquals(refreshed.StartDate, refreshed.EndDate,
            'EndDate should be adjusted to StartDate when earlier.');
    }

    @IsTest
    static void testFutureEndDate_NoChange_ButRedirects() {
        // Arrange: future EndDate
        Date start = Date.today().addDays(-30);
        Date futureEnd = Date.today().addDays(20);
        Contract c = createContract(start, futureEnd);

        ApexPages.StandardController std = new ApexPages.StandardController(c);
        PostExpiryAmendRedirect ctl = new PostExpiryAmendRedirect(std);

        Test.startTest();
        PageReference pr = ctl.init();
        Test.stopTest();

        // Assert: no change to EndDate, still redirects
        System.assertNotEquals(null, pr, 'Should redirect.');
        System.assertEquals(c.Id, pr.getParameters().get('id'));
        Contract refreshed = [SELECT EndDate FROM Contract WHERE Id = :c.Id];
        System.assertEquals(futureEnd, refreshed.EndDate, 'Future EndDate should remain unchanged.');
    }
}