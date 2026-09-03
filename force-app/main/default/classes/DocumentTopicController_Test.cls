/**
* @File Name : DocumentTopicController_Test.cls
* @Description : Unit tests for DocumentTopicController (topics + articles assembly and filters)
* @Author :
* @Last Modified By :
* @Last Modified On : August 28, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 28, 2025 |   | Initial Version
**/

/**
 * @file DocumentTopicController_Test.cls
 * @description Unit tests for DocumentTopicController (topics + articles assembly and filters)
 */
@IsTest
private class DocumentTopicController_Test {

    @TestSetup
    static void setupData() {
        // Get two valid picklist values (restricted-safe) for data creation
        List<String> types = getTwoTypeValues();
        String typeA = types[0];
        String typeB = types[1];

        // ----- Insert Topics -----
        Doc_Topic__c t1 = new Doc_Topic__c(
            Name               = 'T1 - ' + typeA,
            Type_of_Doc__c     = typeA,
            Doc_Description__c = 'Description T1',
            Doc_Order__c       = 1,
            Active__c          = true
        );
        Doc_Topic__c t2 = new Doc_Topic__c(
            Name               = 'T2 - ' + typeA,
            Type_of_Doc__c     = typeA,
            Doc_Description__c = 'Description T2',
            Doc_Order__c       = 2,
            Active__c          = true
        );
        Doc_Topic__c t3 = new Doc_Topic__c(
            Name               = 'T3 - Inactive',
            Type_of_Doc__c     = typeB, // valid value; topic inactive
            Doc_Description__c = 'Description T3',
            Doc_Order__c       = 3,
            Active__c          = false
        );
        insert new List<Doc_Topic__c>{ t1, t2, t3 };

        // ----- Insert Articles using inserted IDs -----
        insert new List<Doc_Article__c>{
            // T1: 2 active (orders 1,3) + 1 inactive (order 2)
            new Doc_Article__c(
                Doc_Topic__c = t1.Id, Doc_Article_Body__c = '<p>A1 Body</p>',
                Doc_Article_order__c = 1, Active__c = true
            ),
            new Doc_Article__c(
                Doc_Topic__c = t1.Id, Doc_Article_Body__c = '<p>A2 Body</p>',
                Doc_Article_order__c = 2, Active__c = false
            ),
            new Doc_Article__c(
                Doc_Topic__c = t1.Id, Doc_Article_Body__c = '<p>A3 Body</p>',
                Doc_Article_order__c = 3, Active__c = true
            ),
            // T2: 1 active
            new Doc_Article__c(
                Doc_Topic__c = t2.Id, Doc_Article_Body__c = '<p>A4 Body</p>',
                Doc_Article_order__c = 1, Active__c = true
            ),
            // T3: topic inactive; won’t show up regardless
            new Doc_Article__c(
                Doc_Topic__c = t3.Id, Doc_Article_Body__c = '<p>A5 Body</p>',
                Doc_Article_order__c = 1, Active__c = true
            )
        };
    }

    // ---------- getTopicsBySectionValue ----------

    @IsTest
    static void test_getTopicsBySectionValue_blank_returnsEmpty() {
        Test.startTest();
        List<DocumentTopicController.TopicDto> out =
            DocumentTopicController.getTopicsBySectionValue(null);
        Test.stopTest();
        System.assertEquals(0, out.size(), 'Blank sectionValue should return empty list.');
    }

    @IsTest
    static void test_getTopicsBySectionValue_filters_active_only_and_orders() {
        String typeA = getTwoTypeValues()[0];

        Test.startTest();
        List<DocumentTopicController.TopicDto> out =
            DocumentTopicController.getTopicsBySectionValue(typeA);
        Test.stopTest();

        System.assertEquals(2, out.size(), 'Only the two active topics of typeA should be returned.');
        System.assertEquals('T1 - ' + typeA, out[0].name, 'Order should be by Doc_Order__c (1 first).');
        System.assertEquals('T2 - ' + typeA, out[1].name, 'Then Doc_Order__c (2 second).');

        DocumentTopicController.TopicDto t1Dto = getByName(out, 'T1 - ' + typeA);
        System.assertNotEquals(null, t1Dto, 'T1 must exist.');
        System.assertEquals(2, t1Dto.articles.size(), 'T1 should have only active articles.');
        System.assertEquals(1, t1Dto.articles[0].orderNo, 'First T1 article order should be 1.');
        System.assertEquals(3, t1Dto.articles[1].orderNo, 'Second T1 article order should be 3.');

        DocumentTopicController.TopicDto t2Dto = getByName(out, 'T2 - ' + typeA);
        System.assertNotEquals(null, t2Dto, 'T2 must exist.');
        System.assertEquals(1, t2Dto.articles.size(), 'T2 should have one active article.');
        System.assertEquals(1, t2Dto.articles[0].orderNo, 'T2 article order should be 1.');
    }

    // ---------- getTopicsBySection (legacy) ----------

    @IsTest
    static void test_getTopicsBySection_blank_returnsEmpty() {
        Test.startTest();
        List<DocumentTopicController.TopicDto> out =
            DocumentTopicController.getTopicsBySection('');
        Test.stopTest();
        System.assertEquals(0, out.size(), 'Blank sectionKey should return empty list.');
    }

    @IsTest
    static void test_getTopicsBySection_returns_active_and_orders() {
        String typeA = getTwoTypeValues()[0];

        // Current impl returns all active topics ignoring the key
        Test.startTest();
        List<DocumentTopicController.TopicDto> out =
            DocumentTopicController.getTopicsBySection('anything');
        Test.stopTest();

        System.assertEquals(2, out.size(), 'Should return only active topics.');
        System.assertEquals('T1 - ' + typeA, out[0].name, 'Expected T1 first.');
        System.assertEquals('T2 - ' + typeA, out[1].name, 'Expected T2 second.');
        System.assertEquals(null, getByName(out, 'T3 - Inactive'),
            'Inactive topic should not be included.');
    }

    // ---------- Helpers ----------

    // Always fetch fresh picklist values in each method (statics are reset between tests)
    private static List<String> getTwoTypeValues() {
        List<Schema.PicklistEntry> entries =
            Doc_Topic__c.Type_of_Doc__c.getDescribe().getPicklistValues();
        System.assert(entries.size() > 0,
            'Type_of_Doc__c must have at least one picklist value.');
        List<String> out = new List<String>();
        for (Schema.PicklistEntry e : entries) {
            out.add(e.getValue());
            if (out.size() == 2) break;
        }
        if (out.size() == 1) {
            // If org only has one value, duplicate it to keep tests simple
            out.add(out[0]);
        }
        return out;
    }

    private static DocumentTopicController.TopicDto getByName(
        List<DocumentTopicController.TopicDto> listIn, String nameIn
    ) {
        for (DocumentTopicController.TopicDto t : listIn) {
            if (t != null && t.name == nameIn) return t;
        }
        return null;
    }
}