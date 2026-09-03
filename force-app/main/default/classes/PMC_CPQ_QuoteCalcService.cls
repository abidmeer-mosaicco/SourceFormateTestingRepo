/**
 * @description Service responsible for invoking the CPQ Calculate Quote API with
 *              callbackClass = PMC_CPQ_QuoteCalcCallback. Single entry point for
 *              controlled calculation: the calculation runs async and the callback
 *              persists + publishes Get_Price_Response__e when it completes. Used by
 *              SetPriceResource after consolidating SAP prices on the quote.
 * @author Raphael Soares
 * @storynumber back-to-draft-fix
 */
public with sharing class PMC_CPQ_QuoteCalcService {

    @TestVisible
    static final String CALLBACK_CLASS = 'PMC_CPQ_QuoteCalcCallback';
    @TestVisible
    static final String QUOTE_READER = 'SBQQ.QuoteAPI.QuoteReader';
    @TestVisible
    static final String QUOTE_CALCULATOR = 'SBQQ.QuoteAPI.QuoteCalculator';

    /**
     * @description Reads the QuoteModel via QuoteReader and triggers the async
     *              calculation passing the callbackClass. The callback receives the
     *              calculated model, persists it via QuoteSaver, and publishes the
     *              Get_Price_Response__e platform event.
     * @param quoteId Quote to recalculate.
     */
    public static void recalculate(Id quoteId) {
        if (quoteId == null) {
            throw new IllegalArgumentException('quoteId is required');
        }
        try {
            String strQuoteModelJson = (String) SBQQ.ServiceRouter.read(QUOTE_READER, quoteId);
            String strContext = buildCalculatorContext(strQuoteModelJson, CALLBACK_CLASS);
            SBQQ.ServiceRouter.load(QUOTE_CALCULATOR, null, strContext);
        } catch (Exception e) {
            PMC_ErrorLogClass.processException(e);
            throw e;
        }
    }

    /**
     * @description Builds the context JSON for the QuoteCalculator with the QuoteModel
     *              and the callback class name. Expected SBQQ shape:
     *              {"quote": <quoteModel>, "callbackClass": "<className>"}
     * @param strQuoteModelJson QuoteModel already serialized as JSON.
     * @param strCallbackClassName Qualified name of the class implementing SBQQ.CalculateCallback.
     * @return Context JSON ready for ServiceRouter.load.
     */
    @TestVisible
    private static String buildCalculatorContext(String strQuoteModelJson, String strCallbackClassName) {
        return '{"quote":' + strQuoteModelJson + ',"callbackClass":"' + strCallbackClassName + '"}';
    }
}