@isTest
private class md_reportController_Test {

    private static void setAllowed(Set<Id> ids) {
        md_reportController.TEST_ALLOWED_IDS = ids;
    }

    private static void clearAllowed() {
        md_reportController.TEST_ALLOWED_IDS = null;
    }

    private static md_reportController.PagedResult callPaged(
        String objectApiName,
        List<String> fields,
        String whereClause,
        String orderByField,
        String orderDir,
        Integer pageSize,
        Integer pageNumber,
        String cursor
    ) {
        return md_reportController.listRecordsPaged(
            objectApiName, fields, whereClause,
            orderByField, orderDir, pageSize, pageNumber,
            null, new List<String>{ 'LastName' },
            null, null, null, null,
            'America/New_York',
            cursor
        );
    }

    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account RC');
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        Database.insert(acc, dml);

        insert new List<Contact>{
            new Contact(LastName = 'Alpha', AccountId = acc.Id, Email = 'alpha@rc.test'),
            new Contact(LastName = 'Beta',  AccountId = acc.Id, Email = 'beta@rc.test'),
            new Contact(LastName = 'Gamma', AccountId = acc.Id, Email = 'gamma@rc.test')
        };
    }

    @isTest
    static void testEmptyAllowed_ReturnsEmpty() {
        setAllowed(new Set<Id>());
        md_reportController.PagedResult res = callPaged(
            'Contact', new List<String>{ 'Id', 'LastName' },
            null, 'LastModifiedDate', 'DESC', 10, 1, null
        );
        System.assertEquals(0, res.totalSize, 'Empty allowed should return 0 total');
        System.assertEquals(0, res.records.size(), 'Empty allowed should return 0 records');
        System.assertEquals(false, res.hasNext, 'hasNext should be false');
        System.assertEquals(false, res.hasPrev, 'hasPrev should be false');
        System.assertEquals(null, res.nextCursor, 'nextCursor should be null');
        clearAllowed();
    }

    @isTest
    static void testInvalidObject_ReturnsEmpty() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });
        md_reportController.PagedResult res = callPaged(
            'NotReal__c', new List<String>{ 'Id' },
            null, 'LastModifiedDate', 'DESC', 10, 1, null
        );
        System.assertEquals(0, res.totalSize, 'Invalid object should return 0 total');
        System.assertEquals(0, res.records.size(), 'Invalid object should return 0 records');
        clearAllowed();
    }

    @isTest
    static void testGetRecordsByIds_EmptyInputs() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        System.assertEquals(0,
            md_reportController.getRecordsByIds('Account', new List<Id>(), new List<String>{ 'Name' }).size(),
            'Empty ids should return empty list');
        System.assertEquals(0,
            md_reportController.getRecordsByIds('Account', null, new List<String>{ 'Name' }).size(),
            'Null ids should return empty list');
        System.assertEquals(0,
            md_reportController.getRecordsByIds('Account', new List<Id>{ acc.Id }, new List<String>()).size(),
            'Empty fields should return empty list');
    }

    @isTest
    static void testGetRecordsByIds_ValidQuery_ReturnsRecord() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        List<SObject> result = md_reportController.getRecordsByIds(
            'Account', new List<Id>{ acc.Id }, new List<String>{ 'Id', 'Name' }
        );
        System.assertEquals(1, result.size(), 'Should return 1 record');
        System.assertEquals(acc.Id, (Id) result[0].get('Id'), 'ID should match');
    }

    @isTest
    static void testPagination_Page1_ReturnsCorrectMetadata() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        md_reportController.PagedResult res = callPaged(
            'Contact', new List<String>{ 'Id', 'AccountId', 'LastName' },
            null, 'LastModifiedDate', 'DESC', 2, 1, null
        );
        System.assertEquals(1, res.pageNumber, 'Page number should be 1');
        System.assertEquals(2, res.pageSize, 'Page size should be 2');
        System.assertEquals(2, res.records.size(), 'Should return 2 records on page 1');
        System.assertEquals(3, res.totalSize, 'Total should be 3');
        System.assertEquals(false, res.hasPrev, 'Page 1 should not have prev');
        System.assertEquals(true, res.hasNext, 'Page 1 should have next');
        System.assertNotEquals(null, res.nextCursor, 'nextCursor should be set');
        clearAllowed();
    }

    @isTest
    static void testPagination_Page2_HasPrevAndNoNext() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        md_reportController.PagedResult res = callPaged(
            'Contact', new List<String>{ 'Id', 'AccountId', 'LastName' },
            null, 'LastModifiedDate', 'DESC', 2, 2, null
        );
        System.assertEquals(2, res.pageNumber, 'Page number should be 2');
        System.assertEquals(true, res.hasPrev, 'Page 2 should have prev');
        System.assertEquals(false, res.hasNext, 'Page 2 should not have next');
        clearAllowed();
    }

    @isTest
    static void testNullPageSizeAndNumber_DefaultTo50And1() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        md_reportController.PagedResult res = callPaged(
            'Contact', new List<String>{ 'Id', 'LastName' },
            null, null, null, null, null, null
        );
        System.assertEquals(50, res.pageSize, 'Default page size should be 50');
        System.assertEquals(1, res.pageNumber, 'Default page number should be 1');
        clearAllowed();
    }

    @isTest
    static void testSearchTerm_DirectField_FiltersResults() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        md_reportController.PagedResult res = md_reportController.listRecordsPaged(
            'Contact', new List<String>{ 'Id', 'AccountId', 'LastName' }, null,
            'LastModifiedDate', 'DESC', 10, 1,
            'Alpha', new List<String>{ 'LastName' },
            null, null, null, null, 'America/New_York',
            null
        );
        System.assertEquals(1, res.records.size(), 'Search for Alpha should return 1 result');
        System.assertEquals('Alpha', (String) res.records[0].get('LastName'), 'Result should be Alpha');
        clearAllowed();
    }

    @isTest
    static void testSearchTerm_RelatedField_NoError() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        md_reportController.PagedResult res = md_reportController.listRecordsPaged(
            'Contact', new List<String>{ 'Id', 'AccountId', 'LastName' }, null,
            'LastModifiedDate', 'DESC', 10, 1,
            'Test', new List<String>{ 'Account.Name', 'LastName' },
            null, null, null, null, 'America/New_York',
            null
        );
        System.assert(res.records.size() >= 0, 'Related field search should not error');
        clearAllowed();
    }

    @isTest
    static void testWhereClause_FiltersToSingleRecord() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        md_reportController.PagedResult res = callPaged(
            'Contact', new List<String>{ 'Id', 'LastName' },
            'LastName = \'Beta\'',
            'LastModifiedDate', 'DESC', 10, 1, null
        );
        System.assertEquals(1, res.records.size(), 'WHERE clause should filter to 1 record');
        System.assertEquals('Beta', (String) res.records[0].get('LastName'), 'Should return Beta');
        clearAllowed();
    }

    @isTest
    static void testDateFilter_DateTime_FromAndTo_IncludesRecords() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        md_reportController.PagedResult res = md_reportController.listRecordsPaged(
            'Contact', new List<String>{ 'Id', 'AccountId', 'LastName' }, null,
            'CreatedDate', 'DESC', 50, 1,
            null, null,
            'CreatedDate', null,
            String.valueOf(Date.today().addDays(-1)),
            String.valueOf(Date.today().addDays(1)),
            'America/New_York',
            null
        );
        System.assertEquals(3, res.totalSize, 'Date range should include today records');
        clearAllowed();
    }

    @isTest
    static void testDateFilter_DateTime_FromOnly_NoError() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        md_reportController.PagedResult res = md_reportController.listRecordsPaged(
            'Contact', new List<String>{ 'Id', 'AccountId', 'LastName' }, null,
            'CreatedDate', 'DESC', 50, 1,
            null, null,
            'CreatedDate', null,
            String.valueOf(Date.today().addDays(-1)), null,
            'America/New_York',
            null
        );
        System.assert(res.totalSize >= 0, 'fromOnly datetime filter should not error');
        clearAllowed();
    }

    @isTest
    static void testDateFilter_DateTime_ToOnly_NoError() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        md_reportController.PagedResult res = md_reportController.listRecordsPaged(
            'Contact', new List<String>{ 'Id', 'AccountId', 'LastName' }, null,
            'CreatedDate', 'DESC', 50, 1,
            null, null,
            null, 'CreatedDate',
            null, String.valueOf(Date.today().addDays(1)),
            'America/New_York',
            null
        );
        System.assert(res.totalSize >= 0, 'toOnly datetime filter should not error');
        clearAllowed();
    }

    @isTest
    static void testDateFilter_DateField_Birthdate_FiltersCorrectly() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });
        insert new Contact(LastName = 'Dated', AccountId = acc.Id, Birthdate = Date.newInstance(1990, 6, 15));

        md_reportController.PagedResult res = md_reportController.listRecordsPaged(
            'Contact', new List<String>{ 'Id', 'AccountId', 'LastName', 'Birthdate' }, null,
            'LastModifiedDate', 'DESC', 50, 1,
            null, null,
            'Birthdate', null,
            '1985-01-01', '2000-01-01', 'America/New_York',
            null
        );
        System.assert(res.totalSize >= 1, 'Should find contact with Birthdate in range');
        clearAllowed();
    }

    @isTest
    static void testDateFilter_TwoFields_OverlapBranch_NoError() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });
        insert new Contact(LastName = 'TwoFields', AccountId = acc.Id, Birthdate = Date.newInstance(1990, 1, 1));

        md_reportController.PagedResult res = md_reportController.listRecordsPaged(
            'Contact', new List<String>{ 'Id', 'AccountId', 'LastName', 'Birthdate' }, null,
            'LastModifiedDate', 'DESC', 50, 1,
            null, null,
            'Birthdate', 'LastActivityDate',
            '1985-01-01', String.valueOf(Date.today().addDays(1)),
            'America/New_York',
            null
        );
        System.assert(res.totalSize >= 0, 'Two-field date filter should not error');
        clearAllowed();
    }

    @isTest
    static void testOrderField_InvalidChars_FallsBackToDefault() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        md_reportController.PagedResult res = callPaged(
            'Contact', new List<String>{ 'Id', 'LastName' },
            null, 'Name; DROP TABLE', 'DESC', 10, 1, null
        );
        System.assert(res.records.size() >= 0, 'Invalid order field should fall back to default');
        clearAllowed();
    }

    @isTest
    static void testOrderAscAndDesc_ReturnDifferentFirstRecords() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        md_reportController.PagedResult ascResult = md_reportController.listRecordsPaged(
            'Contact', new List<String>{ 'Id', 'AccountId', 'LastName' }, null,
            'LastName', 'ASC', 1, 1,
            null, null, null, null, null, null, null,
            null
        );
        md_reportController.PagedResult descResult = md_reportController.listRecordsPaged(
            'Contact', new List<String>{ 'Id', 'AccountId', 'LastName' }, null,
            'LastName', 'DESC', 1, 1,
            null, null, null, null, null, null, null,
            null
        );
        System.assertEquals(1, ascResult.records.size(), 'ASC page 1 should return 1 record');
        System.assertEquals(1, descResult.records.size(), 'DESC page 1 should return 1 record');
        System.assertNotEquals(
            (String) ascResult.records[0].get('LastName'),
            (String) descResult.records[0].get('LastName'),
            'ASC and DESC first records should differ'
        );
        clearAllowed();
    }

    @isTest
    static void testNextCursor_ReturnedOnPage1() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        md_reportController.PagedResult res = callPaged(
            'Contact', new List<String>{ 'Id', 'LastName' },
            null, 'LastModifiedDate', 'DESC', 1, 1, null
        );
        System.assertEquals(1, res.records.size(), 'Page 1 should return 1 record');
        System.assertNotEquals(null, res.nextCursor, 'Page 1 should return a cursor');
        clearAllowed();
    }

    @isTest
    static void testKeyset_Page2_ReturnsDifferentRecord() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        md_reportController.PagedResult p1 = callPaged(
            'Contact', new List<String>{ 'Id', 'LastName' },
            null, 'LastModifiedDate', 'DESC', 1, 1, null
        );
        System.assertNotEquals(null, p1.nextCursor, 'Cursor from page 1 should not be null');

        md_reportController.PagedResult p2 = callPaged(
            'Contact', new List<String>{ 'Id', 'LastName' },
            null, 'LastModifiedDate', 'DESC', 1, 2, p1.nextCursor
        );
        System.assertEquals(1, p2.records.size(), 'Page 2 should return 1 record via keyset');
        System.assertNotEquals(p1.records[0].Id, p2.records[0].Id, 'Page 2 should return different record');
        clearAllowed();
    }

    @isTest
    static void testKeyset_FullTraversal_ExhaustsAllRecords() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        md_reportController.PagedResult p1 = callPaged(
            'Contact', new List<String>{ 'Id', 'LastName' },
            null, 'LastModifiedDate', 'DESC', 1, 1, null
        );
        Id id1 = p1.records[0].Id;

        md_reportController.PagedResult p2 = callPaged(
            'Contact', new List<String>{ 'Id', 'LastName' },
            null, 'LastModifiedDate', 'DESC', 1, 2, p1.nextCursor
        );
        Id id2 = p2.records[0].Id;
        System.assertNotEquals(id1, id2, 'Page 2 should differ from page 1');

        md_reportController.PagedResult p3 = callPaged(
            'Contact', new List<String>{ 'Id', 'LastName' },
            null, 'LastModifiedDate', 'DESC', 1, 3, p2.nextCursor
        );
        Id id3 = p3.records[0].Id;
        System.assertNotEquals(id1, id3, 'Page 3 should differ from page 1');
        System.assertNotEquals(id2, id3, 'Page 3 should differ from page 2');

        md_reportController.PagedResult p4 = callPaged(
            'Contact', new List<String>{ 'Id', 'LastName' },
            null, 'LastModifiedDate', 'DESC', 1, 4, p3.nextCursor
        );
        System.assertEquals(0, p4.records.size(), 'Page 4 should be empty after exhausting all 3 records');
        System.assertEquals(false, p4.hasNext, 'Page 4 hasNext should be false');
        clearAllowed();
    }

    @isTest
    static void testKeyset_DirectionMismatch_FallsBackToOffset() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        md_reportController.PagedResult p1 = callPaged(
            'Contact', new List<String>{ 'Id', 'LastName' },
            null, 'LastModifiedDate', 'DESC', 1, 1, null
        );

        md_reportController.PagedResult p2 = md_reportController.listRecordsPaged(
            'Contact', new List<String>{ 'Id', 'LastName' }, null,
            'LastModifiedDate', 'ASC', 1, 2,
            null, null, null, null, null, null, null,
            p1.nextCursor
        );
        System.assertEquals(1, p2.records.size(), 'Should fallback to OFFSET on direction mismatch');
        System.assertEquals(2, p2.pageNumber, 'Page number should still be 2');
        clearAllowed();
    }

    @isTest
    static void testKeyset_FieldMismatch_FallsBackToOffset() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        md_reportController.PagedResult p1 = callPaged(
            'Contact', new List<String>{ 'Id', 'LastName' },
            null, 'LastModifiedDate', 'DESC', 1, 1, null
        );

        md_reportController.PagedResult p2 = md_reportController.listRecordsPaged(
            'Contact', new List<String>{ 'Id', 'LastName' }, null,
            'CreatedDate', 'DESC', 1, 2,
            null, null, null, null, null, null, null,
            p1.nextCursor
        );
        System.assertEquals(1, p2.records.size(), 'Should fallback to OFFSET on field mismatch');
        clearAllowed();
    }

    @isTest
    static void testKeyset_InvalidCursorJson_FallsBackToOffset() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        md_reportController.PagedResult res = callPaged(
            'Contact', new List<String>{ 'Id', 'LastName' },
            null, 'LastModifiedDate', 'DESC', 10, 1, 'not-valid-json{{{'
        );
        System.assertEquals(3, res.totalSize, 'Invalid cursor should fallback to OFFSET');
        System.assertEquals(3, res.records.size(), 'Should return all 3 records');
        clearAllowed();
    }

    @isTest
    static void testKeyset_ReportedTotal_IsFullCount() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        md_reportController.PagedResult p1 = callPaged(
            'Contact', new List<String>{ 'Id', 'LastName' },
            null, 'LastModifiedDate', 'DESC', 1, 1, null
        );
        md_reportController.PagedResult p2 = callPaged(
            'Contact', new List<String>{ 'Id', 'LastName' },
            null, 'LastModifiedDate', 'DESC', 1, 2, p1.nextCursor
        );
        System.assertEquals(3, p2.totalSize, 'Keyset mode should report full totalSize');
        clearAllowed();
    }

    @isTest
    static void testNoAccountField_ObjectWithoutAccountId_NoError() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        md_reportController.PagedResult res = md_reportController.listRecordsPaged(
            'Lead', new List<String>{ 'Id', 'LastName' }, null,
            'LastModifiedDate', 'DESC', 10, 1,
            null, null, null, null, null, null, null,
            null
        );
        System.assert(res.records.size() >= 0, 'Object without AccountId field should not error');
        clearAllowed();
    }

    @isTest
    static void testComputedValues_SbqqQuote_AggregatesLineItems() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account RC' LIMIT 1];
        setAllowed(new Set<Id>{ acc.Id });

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Primary__c = true
        );
        Product2 prod = new Product2(Name = 'RC Test Product', IsActive = true);
        SBQQ__QuoteLine__c ql;

        SBQQ.TriggerControl.disable();
        insert quote;
        insert prod;
        ql = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = prod.Id,
            SBQQ__Quantity__c = 5
        );
        insert ql;
        SBQQ.TriggerControl.enable();

        Test.startTest();
        md_reportController.PagedResult res = md_reportController.listRecordsPaged(
            'SBQQ__Quote__c',
            new List<String>{
                'Id',
                'SBQQ__Account__c',
                'SBQQ__LineItems__r.SBQQ__Quantity__c',
                'SBQQ__LineItems__r.SBQQ__Product__r.Name'
            },
            null,
            'LastModifiedDate', 'DESC', 10, 1,
            null, null, null, null, null, null, null,
            null
        );
        Test.stopTest();

        System.assertEquals(1, res.records.size(), 'Should return the quote');
        System.assertNotEquals(null, res.computedValues, 'computedValues should be populated for SBQQ__Quote__c');
        System.assertNotEquals(null,
            res.computedValues.get(quote.Id)?.get('SBQQ__LineItems__r.SBQQ__Quantity__c'),
            'Quantity should be aggregated from QuoteLine');
        System.assertNotEquals(null,
            res.computedValues.get(quote.Id)?.get('SBQQ__LineItems__r.SBQQ__Product__r.Name'),
            'Product name should be aggregated via related path');
        clearAllowed();
    }
}