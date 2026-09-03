/**
 * @description Test class for PMC_CPQ_QuoteCalcService.
 * @author Raphael Soares
 * @storynumber back-to-draft-fix
 */
@isTest(seeAllData = false)
private with sharing class PMC_CPQ_QuoteCalcServiceTest {

    @isTest
    static void recalculate_throwsWhenQuoteIdIsNull() {
        Test.startTest();
        Boolean boolCaught = false;
        try {
            PMC_CPQ_QuoteCalcService.recalculate(null);
        } catch (IllegalArgumentException e) {
            boolCaught = true;
        }
        Test.stopTest();

        System.assert(boolCaught, 'Should throw IllegalArgumentException when quoteId is null');
    }

    @isTest
    static void buildCalculatorContext_producesExpectedJsonShape() {
        String strQuoteModel = '{"record":{"Id":"0Q0000000000001AAA"}}';
        String strCallback = 'PMC_CPQ_QuoteCalcCallback';

        Test.startTest();
        String strContext = PMC_CPQ_QuoteCalcService.buildCalculatorContext(strQuoteModel, strCallback);
        Test.stopTest();

        System.assert(
            strContext.contains('"quote":' + strQuoteModel),
            'Context must embed the QuoteModel under the "quote" key'
        );
        System.assert(
            strContext.contains('"callbackClass":"' + strCallback + '"'),
            'Context must include callbackClass with the class name'
        );
        // Ensure the result is valid JSON
        try {
            JSON.deserializeUntyped(strContext);
        } catch (Exception e) {
            System.assert(false, 'Context must be valid JSON: ' + e.getMessage());
        }
    }

    @isTest
    static void constants_pointToExpectedSBQQServices() {
        System.assertEquals('PMC_CPQ_QuoteCalcCallback', PMC_CPQ_QuoteCalcService.CALLBACK_CLASS);
        System.assertEquals('SBQQ.QuoteAPI.QuoteReader', PMC_CPQ_QuoteCalcService.QUOTE_READER);
        System.assertEquals('SBQQ.QuoteAPI.QuoteCalculator', PMC_CPQ_QuoteCalcService.QUOTE_CALCULATOR);
    }
}