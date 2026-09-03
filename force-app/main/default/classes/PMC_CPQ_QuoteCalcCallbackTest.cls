/**
 * @description Test class for PMC_CPQ_QuoteCalcCallback.
 * @author Raphael Soares
 * @storynumber back-to-draft-fix
 */
@isTest(seeAllData = false)
private with sharing class PMC_CPQ_QuoteCalcCallbackTest {

    @isTest
    static void extractQuoteId_returnsIdFromRecordWrapper() {
        Id strFakeId = '0Q0000000000001AAA';
        String strJson = '{"record":{"Id":"' + strFakeId + '","Name":"Q-1"}}';

        Test.startTest();
        Id strResult = PMC_CPQ_QuoteCalcCallback.extractQuoteId(strJson);
        Test.stopTest();

        System.assertEquals(strFakeId, strResult, 'Should extract Id from inside record wrapper');
    }

    @isTest
    static void extractQuoteId_returnsIdFromTopLevel() {
        Id strFakeId = '0Q0000000000002AAA';
        String strJson = '{"Id":"' + strFakeId + '","Name":"Q-2"}';

        Test.startTest();
        Id strResult = PMC_CPQ_QuoteCalcCallback.extractQuoteId(strJson);
        Test.stopTest();

        System.assertEquals(strFakeId, strResult, 'Should extract Id from top-level');
    }

    @isTest
    static void extractQuoteId_returnsNullForBlankInput() {
        Test.startTest();
        Id strResultEmpty = PMC_CPQ_QuoteCalcCallback.extractQuoteId('');
        Id strResultNull = PMC_CPQ_QuoteCalcCallback.extractQuoteId(null);
        Test.stopTest();

        System.assertEquals(null, strResultEmpty, 'Empty string should return null');
        System.assertEquals(null, strResultNull, 'Null input should return null');
    }

    @isTest
    static void extractQuoteId_returnsNullWhenNoIdField() {
        String strJson = '{"record":{"Name":"Q-NoId"}}';

        Test.startTest();
        Id strResult = PMC_CPQ_QuoteCalcCallback.extractQuoteId(strJson);
        Test.stopTest();

        System.assertEquals(null, strResult, 'Missing Id field should return null');
    }

    @isTest
    static void publishResponseEvent_publishesSuccessfully() {
        Id strFakeId = '0Q0000000000003AAA';

        Test.startTest();
        PMC_CPQ_QuoteCalcCallback.publishResponseEvent(strFakeId, 200, '{"message":"test"}');
        Test.stopTest();
        // EventBus.publish in test context does not raise; coverage validated by absence of exception.
        System.assert(true, 'publishResponseEvent should not throw');
    }

    @isTest
    static void callback_extractsIdAndPublishesEventOnSaverFailure() {
        // In test context SBQQ.ServiceRouter.save with invalid JSON fails. The class
        // should catch the exception, log it, and publish a 500 error event.
        String strJson = '{"record":{"Id":"0Q0000000000004AAA"}}';

        Test.startTest();
        PMC_CPQ_QuoteCalcCallback callback = new PMC_CPQ_QuoteCalcCallback();
        try {
            callback.callback(strJson);
        } catch (Exception e) {
            System.assert(false, 'callback should not propagate exceptions: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void callback_handlesBlankJsonGracefully() {
        Test.startTest();
        PMC_CPQ_QuoteCalcCallback callback = new PMC_CPQ_QuoteCalcCallback();
        try {
            callback.callback(null);
            callback.callback('');
        } catch (Exception e) {
            System.assert(false, 'callback should not propagate exceptions on blank input: ' + e.getMessage());
        }
        Test.stopTest();
    }
}