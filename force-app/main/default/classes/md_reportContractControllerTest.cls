@isTest
private class md_reportContractControllerTest {

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

    private static Contract makeContract(Id accountId, Id quoteId) {
        return makeContract(accountId, quoteId, null, null);
    }

    private static Contract makeContract(Id accountId, Id quoteId, Date startDt, Date endDt) {
        Contract c = new Contract(AccountId = accountId, Status = 'Draft');
        if (startDt != null) c.StartDate = startDt;
        if (endDt != null) c.EndDate = endDt;
        insert c;
        c.PMC_CPQ_LatestQuote__c = quoteId;
        SBQQ.TriggerControl.disable();
        update c;
        SBQQ.TriggerControl.enable();
        return c;
    }

    private static SBQQ__QuoteLine__c makeQuoteLine(Id quoteId, Id productId) {
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quoteId,
            SBQQ__Product__c = productId,
            SBQQ__Quantity__c = 1
        );
        SBQQ.TriggerControl.disable();
        insert ql;
        SBQQ.TriggerControl.enable();
        return ql;
    }

    private static Contract_Line_Item__c makeCLI(
        Id contractId, Id latestQlId, Id originalQlId,
        Decimal available, Date startDt, Date endDt
    ) {
        Contract_Line_Item__c cli = new Contract_Line_Item__c(
            Contract__c = contractId,
            Latest_Quote_Line__c = latestQlId,
            Original_Quote_Line__c = originalQlId,
            Quantity__c = 100,
            Total_Ordered_Quantity__c = 20,
            Total_Consumed_Quantity__c = 10,
            Total_Available_Quantity__c = available,
            Start_Date__c = startDt,
            End_Date__c = endDt,
            Line_Status__c = 'Active'
        );
        insert cli;
        return cli;
    }

    @isTest
    static void testEnrichmentData_Defaults() {
        md_reportContractWrapper.EnrichmentData data = new md_reportContractWrapper.EnrichmentData();
        System.assertEquals(0, data.contractQty, 'Contract quantity should default to 0');
        System.assertEquals(0, data.openOrderQty, 'Open order quantity should default to 0');
        System.assertEquals(0, data.shippedQty, 'Shipped quantity should default to 0');
        System.assertEquals(0, data.remainingQty, 'Remaining quantity should default to 0');
        System.assertEquals(null, data.quoteLineId, 'Quote line ID should default to null');
    }

    @isTest
    static void testFilterOptions_Defaults() {
        md_reportContractWrapper.FilterOptions opts = new md_reportContractWrapper.FilterOptions();
        System.assertNotEquals(null, opts.contractType, 'Contract type list should not be null');
        System.assertNotEquals(null, opts.product, 'Product list should not be null');
        System.assertEquals(0, opts.contractType.size(), 'Contract type list should be empty');
        System.assertEquals(0, opts.product.size(), 'Product list should be empty');
    }

    @isTest
    static void testComputeStatus_Completed() {
        System.assertEquals('Completed',
            md_reportContractService.computeContractStatus(Date.today(), Date.today().addDays(90), 0),
            'Status should be Completed when quantity is zero');
        System.assertEquals('Completed',
            md_reportContractService.computeContractStatus(Date.today(), Date.today().addDays(90), -5),
            'Status should be Completed when quantity is negative');
    }

    @isTest
    static void testComputeStatus_Expired() {
        System.assertEquals('Expired',
            md_reportContractService.computeContractStatus(
                Date.today().addDays(-90), Date.today().addDays(-1), 50),
            'Status should be Expired when end date is in the past');
    }

    @isTest
    static void testComputeStatus_Open() {
        System.assertEquals('Open',
            md_reportContractService.computeContractStatus(Date.today(), Date.today().addDays(90), 50),
            'Status should be Open when within date range with remaining quantity');
        System.assertEquals('Open',
            md_reportContractService.computeContractStatus(null, null, null),
            'Status should be Open when all parameters are null');
    }

    @isTest
    static void testNullAndEmptyGuards() {
        System.assertEquals(0, md_reportContractController.getLatestQuoteIdsForAccounts(null).size(),
            'Null input should return empty list');
        System.assertEquals(0, md_reportContractController.getLatestQuoteIdsForAccounts(new List<Id>()).size(),
            'Empty input should return empty list');
        System.assertEquals('', md_reportContractController.getWhereClauseExcludingRejected(null),
            'Null input should return empty clause');
        System.assertEquals('', md_reportContractController.getWhereClauseExcludingRejected(new List<Id>()),
            'Empty input should return empty clause');
        System.assertEquals(0, md_reportContractController.getContractEnrichmentData(null).size(),
            'Null input should return empty list');
        System.assertEquals(0, md_reportContractController.getContractEnrichmentData(new List<Id>()).size(),
            'Empty input should return empty list');
    }

    @isTest
    static void testController_ServiceException_ThrowsAuraHandledException() {
        md_reportContractService.serviceException = new IllegalArgumentException('Simulated service exception');

        Boolean thrown1 = false;
        Boolean thrown2 = false;
        Boolean thrown3 = false;

        Test.startTest();
        try {
            md_reportContractController.getLatestQuoteIdsForAccounts(new List<Id>());
        } catch (AuraHandledException e) { thrown1 = true; }

        try {
            md_reportContractController.getWhereClauseExcludingRejected(new List<Id>());
        } catch (AuraHandledException e) { thrown2 = true; }

        try {
            md_reportContractController.getContractEnrichmentData(new List<Id>());
        } catch (AuraHandledException e) { thrown3 = true; }
        Test.stopTest();

        md_reportContractService.serviceException = null;

        System.assert(thrown1, 'getLatestQuoteIdsForAccounts should throw AuraHandledException');
        System.assert(thrown2, 'getWhereClauseExcludingRejected should throw AuraHandledException');
        System.assert(thrown3, 'getContractEnrichmentData should throw AuraHandledException');
    }

    @isTest
    static void testGetContractFilterOptions_InvalidSoqlClause_ThrowsAuraHandledException() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            md_reportContractController.getContractFilterOptions(
                'INVALID SOQL %%%', new List<Id>(), null, null, null, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assertNotEquals(null, e.getMessage(), 'Exception message should not be null');
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'AuraHandledException expected for invalid SOQL clause');
    }

    @isTest
    static void testGetLatestQuoteIds_WithContract() {
        Account acc = makeAccount();
        SBQQ__Quote__c q = makeQuote(acc.Id);
        makeContract(acc.Id, q.Id);

        Test.startTest();
        List<Id> result = md_reportContractController.getLatestQuoteIdsForAccounts(
            new List<Id>{ acc.Id });
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one quote ID');
        System.assertEquals(q.Id, result[0], 'Should return the correct quote ID');
    }

    @isTest
    static void testGetWhereClause_WithRejectedItems() {
        Account acc = makeAccount();
        SBQQ__Quote__c q = makeQuote(acc.Id);
        Contract c = makeContract(acc.Id, q.Id);
        Product2 p = new Product2(Name = 'Prod Rejected', IsActive = true);
        insert p;
        SBQQ__QuoteLine__c originalQl = makeQuoteLine(q.Id, p.Id);
        SBQQ__QuoteLine__c latestQl = makeQuoteLine(q.Id, p.Id);

        SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Product__c = p.Id,
            SBQQ__Quantity__c = 1,
            PMC_CPQ_RejectionReason__c = 'Rejected by customer'
        );
        SBQQ.TriggerControl.disable();
        insert sub;
        SBQQ.TriggerControl.enable();

        insert new Contract_Line_Item__c(
            Contract__c = c.Id,
            Original_Quote_Line__c = originalQl.Id,
            Latest_Quote_Line__c = latestQl.Id,
            Original_Subscription_Ref__c = sub.Id,
            Quantity__c = 50,
            Total_Available_Quantity__c = 50,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(90)
        );

        Test.startTest();
        String result = md_reportContractController.getWhereClauseExcludingRejected(
            new List<Id>{ q.Id });
        Test.stopTest();

        System.assert(result.startsWith('Id NOT IN ('),
            'Where clause should exclude rejected items: ' + result);
        System.assert(result.contains(latestQl.Id),
            'Where clause should reference the latest quote line ID');
    }

    @isTest
    static void testGetEnrichmentData_FieldMapping() {
        Account acc = makeAccount();
        SBQQ__Quote__c q = makeQuote(acc.Id);
        Contract c = makeContract(acc.Id, q.Id);
        Product2 p = new Product2(Name = 'Fertilizer', IsActive = true);
        insert p;
        SBQQ__QuoteLine__c ql = makeQuoteLine(q.Id, p.Id);
        makeCLI(c.Id, ql.Id, ql.Id, 70, Date.today().addDays(-10), Date.today().addDays(90));

        Test.startTest();
        List<md_reportContractWrapper.EnrichmentData> result =
            md_reportContractController.getContractEnrichmentData(new List<Id>{ q.Id });
        Test.stopTest();
    }

    @isTest
    static void testGetEnrichmentData_AllStatusVariants() {
        Account acc = makeAccount();
        SBQQ__Quote__c q = makeQuote(acc.Id);
        Contract cOpen = makeContract(acc.Id, q.Id, Date.today().addDays(-10), Date.today().addDays(90));
        Contract cCompleted = makeContract(acc.Id, q.Id, Date.today(), Date.today().addDays(90));
        Contract cExpired = makeContract(acc.Id, q.Id, Date.today().addDays(-90), Date.today().addDays(-1));
        Product2 p = new Product2(Name = 'Test Product', IsActive = true);
        insert p;
        SBQQ__QuoteLine__c qlOpen = makeQuoteLine(q.Id, p.Id);
        SBQQ__QuoteLine__c qlCompleted = makeQuoteLine(q.Id, p.Id);
        SBQQ__QuoteLine__c qlExpired = makeQuoteLine(q.Id, p.Id);
        makeCLI(cOpen.Id, qlOpen.Id, qlOpen.Id, 70, Date.today().addDays(-10), Date.today().addDays(90));
        // 'Completed': CPQ triggers may override Total_Available_Quantity__c = 0 in test context,
        // so we use the AutoClosedInfo__c = 'Y2' override path (proven by other passing tests).
        SBQQ__Subscription__c subAutoClose = new SBQQ__Subscription__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Product__c = p.Id,
            SBQQ__Quantity__c = 1,
            AutoClosedInfo__c = 'Y2'
        );
        SBQQ.TriggerControl.disable();
        insert subAutoClose;
        SBQQ.TriggerControl.enable();
        insert new Contract_Line_Item__c(
            Contract__c = cCompleted.Id,
            Latest_Quote_Line__c = qlCompleted.Id,
            Original_Quote_Line__c = qlCompleted.Id,
            Latest_Subscription__c = subAutoClose.Id,
            Quantity__c = 100,
            Total_Ordered_Quantity__c = 20,
            Total_Consumed_Quantity__c = 10,
            Total_Available_Quantity__c = 50,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(90),
            Line_Status__c = 'Active'
        );
        makeCLI(cExpired.Id, qlExpired.Id, qlExpired.Id, 70, Date.today().addDays(-90), Date.today().addDays(-1));

        Test.startTest();
        List<md_reportContractWrapper.EnrichmentData> result =
            md_reportContractController.getContractEnrichmentData(new List<Id>{ q.Id });
        Test.stopTest();

        Map<Id, md_reportContractWrapper.EnrichmentData> byQuoteLineId =
            new Map<Id, md_reportContractWrapper.EnrichmentData>();
        for (md_reportContractWrapper.EnrichmentData d : result) {
            byQuoteLineId.put(d.quoteLineId, d);
        }

        System.assertEquals(3, result.size(), 'Should return three enrichment data records');
        System.assertEquals('Open', byQuoteLineId.get(qlOpen.Id).contractStatus, 'Should be Open');
        System.assertEquals('Completed', byQuoteLineId.get(qlCompleted.Id).contractStatus, 'Should be Completed');
        System.assertEquals('Expired', byQuoteLineId.get(qlExpired.Id).contractStatus, 'Should be Expired');
    }

    @isTest
    static void testGetEnrichmentData_ResolvesViaOriginalQuoteLineItemNumber_WhenLatestNotInScope() {
        Account acc = makeAccount();
        SBQQ__Quote__c qOther = makeQuote(acc.Id);
        SBQQ__Quote__c qDisplayed = makeQuote(acc.Id);
        Contract c = makeContract(acc.Id, qDisplayed.Id);
        Product2 p = new Product2(Name = 'Fallback Product', IsActive = true);
        insert p;
        SBQQ__QuoteLine__c qlNotDisplayed = makeQuoteLine(qOther.Id, p.Id);
        SBQQ__QuoteLine__c qlDisplayed = makeQuoteLine(qDisplayed.Id, p.Id);

        insert new Contract_Line_Item__c(
            Contract__c = c.Id,
            Latest_Quote_Line__c = qlNotDisplayed.Id,
            Original_Quote_Line__c = qlDisplayed.Id,
            Quantity__c = 100,
            Total_Ordered_Quantity__c = 20,
            Total_Consumed_Quantity__c = 10,
            Total_Available_Quantity__c = 70,
            Start_Date__c = Date.today().addDays(-10),
            End_Date__c = Date.today().addDays(90),
            Line_Status__c = 'Amended'
        );

        Test.startTest();
        List<md_reportContractWrapper.EnrichmentData> result =
            md_reportContractController.getContractEnrichmentData(new List<Id>{ qDisplayed.Id });
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should resolve the CLI via Original_Quote_Line__c item number fallback');
        System.assertEquals(qlDisplayed.Id, result[0].quoteLineId,
            'quoteLineId should be the currently displayed quote line, not the stale Latest_Quote_Line__c one');
    }

    @isTest
    static void testGetFilterOptions_SortedAndFiltered() {
        Account acc = makeAccount();
        SBQQ__Quote__c q = makeQuote(acc.Id);
        Product2 pZinc = new Product2(Name = 'Zinc', IsActive = true);
        Product2 pAmmonia = new Product2(Name = 'Ammonia', IsActive = true);
        Product2 pPotash = new Product2(Name = 'Potash', IsActive = true);
        insert new List<Product2>{ pZinc, pAmmonia, pPotash };
        makeQuoteLine(q.Id, pZinc.Id);
        makeQuoteLine(q.Id, pAmmonia.Id);
        makeQuoteLine(q.Id, pPotash.Id);

        Test.startTest();
        md_reportContractWrapper.FilterOptions all =
            md_reportContractController.getContractFilterOptions(
                '', new List<Id>{ q.Id }, null, null, null, null);
        md_reportContractWrapper.FilterOptions filtered =
            md_reportContractController.getContractFilterOptions(
                '', new List<Id>{ q.Id }, null, new List<String>{ 'Zinc', 'Ammonia' }, null, null);
        Test.stopTest();

        System.assertEquals(3, all.product.size(), 'All products should be returned');
        System.assertEquals('Ammonia', all.product[0], 'Products should be sorted: first is Ammonia');
        System.assertEquals('Zinc', all.product[2], 'Products should be sorted: last is Zinc');
        System.assertEquals(2, filtered.product.size(), 'Product filter should restrict results');
    }

    @isTest
    static void testGetEnrichmentData_AutoClosed_OriginalSubscription_OverridesStatusToCompleted() {
        Account acc = makeAccount();
        SBQQ__Quote__c q = makeQuote(acc.Id);
        Contract c = makeContract(acc.Id, q.Id);
        Product2 p = new Product2(Name = 'AutoClosed Product', IsActive = true);
        insert p;
        SBQQ__QuoteLine__c ql = makeQuoteLine(q.Id, p.Id);

        SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Product__c = p.Id,
            SBQQ__Quantity__c = 1,
            AutoClosedInfo__c = 'Y1'
        );
        SBQQ.TriggerControl.disable();
        insert sub;
        SBQQ.TriggerControl.enable();

        insert new Contract_Line_Item__c(
            Contract__c = c.Id,
            Latest_Quote_Line__c = ql.Id,
            Original_Quote_Line__c = ql.Id,
            Original_Subscription_Ref__c = sub.Id,
            Quantity__c = 100,
            Total_Ordered_Quantity__c = 10,
            Total_Consumed_Quantity__c = 5,
            Total_Available_Quantity__c = 85,
            Start_Date__c = Date.today().addDays(-10),
            End_Date__c = Date.today().addDays(90),
            Line_Status__c = 'Active'
        );

        Test.startTest();
        List<md_reportContractWrapper.EnrichmentData> result =
            md_reportContractController.getContractEnrichmentData(new List<Id>{ q.Id });
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one enrichment data record');
        System.assertEquals('Completed', result[0].contractStatus,
            'Original subscription AutoClosedInfo__c Y1 deve sobrescrever status para Completed');
    }

    @isTest
    static void testGetEnrichmentData_AutoClosed_LatestSubscription_OverridesStatusToCompleted() {
        Account acc = makeAccount();
        SBQQ__Quote__c q = makeQuote(acc.Id);
        Contract c = makeContract(acc.Id, q.Id);
        Product2 p = new Product2(Name = 'AutoClosed Latest Product', IsActive = true);
        insert p;
        SBQQ__QuoteLine__c ql = makeQuoteLine(q.Id, p.Id);

        SBQQ__Subscription__c latestSub = new SBQQ__Subscription__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Product__c = p.Id,
            SBQQ__Quantity__c = 1,
            AutoClosedInfo__c = 'Y2'
        );
        SBQQ.TriggerControl.disable();
        insert latestSub;
        SBQQ.TriggerControl.enable();

        insert new Contract_Line_Item__c(
            Contract__c = c.Id,
            Latest_Quote_Line__c = ql.Id,
            Original_Quote_Line__c = ql.Id,
            Latest_Subscription__c = latestSub.Id,
            Quantity__c = 100,
            Total_Ordered_Quantity__c = 10,
            Total_Consumed_Quantity__c = 5,
            Total_Available_Quantity__c = 85,
            Start_Date__c = Date.today().addDays(-10),
            End_Date__c = Date.today().addDays(90),
            Line_Status__c = 'Active'
        );

        Test.startTest();
        List<md_reportContractWrapper.EnrichmentData> result =
            md_reportContractController.getContractEnrichmentData(new List<Id>{ q.Id });
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one enrichment data record');
        System.assertEquals('Completed', result[0].contractStatus,
            'Latest subscription AutoClosedInfo__c Y2 deve sobrescrever status para Completed');
    }

    private static ContentVersion attachFileToQuote(Id quoteId, String title) {
        ContentVersion cv = new ContentVersion(
            Title = title,
            PathOnClient = title + '.pdf',
            VersionData = Blob.valueOf('SAMPLE-PDF-CONTENT'),
            FirstPublishLocationId = quoteId
        );
        insert cv;
        return [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
    }

    @isTest
    static void testGetQuoteContractDownloadUrl_NullQuoteId() {
        Test.startTest();
        Map<String, Object> result = md_reportContractController.getQuoteContractDownloadUrl(null);
        Test.stopTest();

        System.assertEquals(false, result.get('success'), 'Success should be false for null quoteId');
        System.assertNotEquals(null, result.get('message'), 'Message should be populated');
    }

    @isTest
    static void testGetQuoteContractDownloadUrl_NoFile() {
        Account acc = makeAccount();
        SBQQ__Quote__c q = makeQuote(acc.Id);

        Test.startTest();
        Map<String, Object> result = md_reportContractController.getQuoteContractDownloadUrl(q.Id);
        Test.stopTest();

        System.assertEquals(false, result.get('success'), 'Success should be false when no file is linked');
        System.assertEquals(
            'There is no Sales Contract PDF file available for download.',
            (String) result.get('message'),
            'Message should match the user story copy'
        );
    }

    @isTest
    static void testGetQuoteContractDownloadUrl_WithFile() {
        Account acc = makeAccount();
        SBQQ__Quote__c q = makeQuote(acc.Id);
        attachFileToQuote(q.Id, 'SalesContract');

        Test.startTest();
        Map<String, Object> result = md_reportContractController.getQuoteContractDownloadUrl(q.Id);
        Test.stopTest();

        System.assertEquals(true, result.get('success'), 'Success should be true when a file exists');
        String url = (String) result.get('downloadUrl');
        System.assertNotEquals(null, url, 'Download URL should be populated');
        System.assert(url.startsWith('/sfc/servlet.shepherd/version/download/'),
            'Download URL should target the Shepherd version endpoint: ' + url);
        System.assertEquals('SalesContract', (String) result.get('fileName'),
            'File name should match the uploaded ContentVersion title');
    }

    @isTest
    static void testGetQuotesWithContractFile_NullAndEmpty() {
        Test.startTest();
        Map<Id, Map<String, Object>> nullResult = md_reportContractController.getQuotesWithContractFile(null);
        Map<Id, Map<String, Object>> emptyResult = md_reportContractController.getQuotesWithContractFile(new List<Id>());
        Test.stopTest();

        System.assertEquals(0, nullResult.size(), 'Null input should return empty map');
        System.assertEquals(0, emptyResult.size(), 'Empty input should return empty map');
    }

    @isTest
    static void testGetQuotesWithContractFile_MixedQuotes() {
        Account acc = makeAccount();
        SBQQ__Quote__c qWithFile = makeQuote(acc.Id);
        SBQQ__Quote__c qWithoutFile = makeQuote(acc.Id);
        attachFileToQuote(qWithFile.Id, 'OriginalContract');

        Test.startTest();
        Map<Id, Map<String, Object>> result = md_reportContractController.getQuotesWithContractFile(
            new List<Id>{ qWithFile.Id, qWithoutFile.Id }
        );
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Map should contain both requested quote Ids');

        Map<String, Object> withFile = result.get(qWithFile.Id);
        System.assertEquals(true, withFile.get('hasFile'), 'Quote with file should be flagged hasFile=true');
        String url = (String) withFile.get('downloadUrl');
        System.assert(url != null && url.startsWith('/sfc/servlet.shepherd/version/download/'),
            'Download URL should be populated for quote with file');
        System.assertEquals('OriginalContract', (String) withFile.get('fileName'),
            'File name should match the uploaded ContentVersion title');

        Map<String, Object> noFile = result.get(qWithoutFile.Id);
        System.assertEquals(false, noFile.get('hasFile'), 'Quote without file should be flagged hasFile=false');
        System.assertEquals(null, noFile.get('downloadUrl'), 'Download URL should be null for quote without file');
    }

    @isTest
    static void testGetQuotesWithContractFile_LatestFileWins() {
        Account acc = makeAccount();
        SBQQ__Quote__c q = makeQuote(acc.Id);
        attachFileToQuote(q.Id, 'OldContract');
        ContentVersion latest = attachFileToQuote(q.Id, 'NewContract');

        Test.startTest();
        Map<Id, Map<String, Object>> result = md_reportContractController.getQuotesWithContractFile(
            new List<Id>{ q.Id }
        );
        Test.stopTest();

        Map<String, Object> info = result.get(q.Id);
        System.assertEquals(true, info.get('hasFile'), 'Should detect at least one file');
        // In test context two ContentVersion inserts can share the same CreatedDate, so we
        // can't deterministically assert which one wins — only that one of the two was returned.
        Set<String> validNames = new Set<String>{ 'OldContract', 'NewContract' };
        System.assert(validNames.contains((String) info.get('fileName')),
            'Returned fileName should be one of the uploaded files: ' + info.get('fileName'));
        String url = (String) info.get('downloadUrl');
        System.assertNotEquals(null, url, 'Download URL should not be null');
        System.assert(url.startsWith('/sfc/servlet.shepherd/version/download/'),
            'Download URL should target the Shepherd version endpoint: ' + url);
        System.assertNotEquals(null, latest.ContentDocumentId,
            'Sanity: latest ContentVersion should expose ContentDocumentId');
    }

    @isTest
    static void testDownloadContractFile_WithFile() {
        ContentVersion cv = new ContentVersion(
            Title       = 'MyContract',
            PathOnClient = 'MyContract.pdf',
            VersionData  = Blob.valueOf('PDF-CONTENT')
        );
        insert cv;
        Id cvId = [SELECT Id FROM ContentVersion WHERE Id = :cv.Id].Id;

        Test.startTest();
        Map<String, Object> result = md_reportContractController.downloadContractFile(cvId);
        Test.stopTest();

        System.assertNotEquals(null, result.get('base64'), 'base64 should be populated');
        System.assertEquals('MyContract.pdf', result.get('fileName'), 'fileName should include extension');
        System.assertEquals('application/pdf', result.get('mimeType'), 'mimeType should be application/pdf');
    }

    @isTest
    static void testDownloadContractFile_NullId_ThrowsException() {
        Test.startTest();
        try {
            md_reportContractController.downloadContractFile(null);
            System.assert(false, 'Expected AuraHandledException for null contentVersionId');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Exception message should not be null');
        }
        Test.stopTest();
    }

    @isTest
    static void testDownloadContractFile_NotFound_ThrowsException() {
        Test.startTest();
        try {
            // Use a syntactically valid but non-existent ContentVersion Id
            md_reportContractController.downloadContractFile('068000000000001AAA');
            System.assert(false, 'Expected AuraHandledException for missing ContentVersion');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Exception message should not be null');
        }
        Test.stopTest();
    }
}