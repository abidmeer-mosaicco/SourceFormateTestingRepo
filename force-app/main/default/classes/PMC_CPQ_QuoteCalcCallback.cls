/**
 * @description Callback for the CPQ Calculate Quote API. Runs after the async
 *              calculation completes: persists the calculated QuoteModel via the
 *              QuoteSaver service and publishes Get_Price_Response__e to signal
 *              subscribers (the Submit-for-Approval flow's LWC, the Get Prices VF
 *              page) that the calculation finished and the quote is now consolidated
 *              in the database.
 *              'without sharing' is justified: invoked by the SBQQ managed package
 *              after calculation; must persist regardless of the original user context.
 * @author Raphael Soares
 * @storynumber back-to-draft-fix
 */
global without sharing class PMC_CPQ_QuoteCalcCallback implements SBQQ.CalculateCallback {

    /**
     * @description Invoked by CPQ when the calculation completes. Persists the
     *              calculated model and publishes the completion platform event.
     * @param calculatedQuoteJSON Calculated QuoteModel as JSON.
     */
    global void callback(String calculatedQuoteJSON) {
        Id quoteId = null;
        try {
            quoteId = extractQuoteId(calculatedQuoteJSON);
            SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', calculatedQuoteJSON);
            publishResponseEvent(
                quoteId,
                200,
                '{"message":"calc complete","quoteId":"' + quoteId + '"}'
            );
        } catch (Exception e) {
            PMC_ErrorLogClass.processException(e);
            if (quoteId != null) {
                publishResponseEvent(
                    quoteId,
                    500,
                    '{"error":"calc/save failed","details":"' + e.getMessage() + '"}'
                );
            }
        }
    }

    /**
     * @description Extracts the Quote Id from the QuoteModel JSON. Tries the most
     *              common shapes ({"record":{"Id":...}} or {"Id":...} at the top).
     * @param strQuoteJSON QuoteModel as JSON.
     * @return The Quote Id, or null if not found.
     */
    @TestVisible
    private static Id extractQuoteId(String strQuoteJSON) {
        if (String.isBlank(strQuoteJSON)) {
            return null;
        }
        Map<String, Object> mapRoot = (Map<String, Object>) JSON.deserializeUntyped(strQuoteJSON);
        Object objRecord = mapRoot.get('record');
        if (objRecord instanceof Map<String, Object>) {
            Object objId = ((Map<String, Object>) objRecord).get('Id');
            if (objId != null) {
                return (Id) String.valueOf(objId);
            }
        }
        Object objTopId = mapRoot.get('Id');
        if (objTopId != null) {
            return (Id) String.valueOf(objTopId);
        }
        return null;
    }

    /**
     * @description Publishes Get_Price_Response__e to signal the calculation result.
     * @param quoteId Quote Id, used by subscribers to correlate the event.
     * @param intStatusCode Status code (200 success, 500 error).
     * @param strMessage JSON payload as a string.
     */
    @TestVisible
    private static void publishResponseEvent(Id quoteId, Integer intStatusCode, String strMessage) {
        Get_Price_Response__e evt = new Get_Price_Response__e(
            Quote__c = quoteId,
            StatusCode__c = intStatusCode,
            Message__c = strMessage
        );
        Database.SaveResult sr = EventBus.publish(evt);
        if (!sr.isSuccess()) {
            for (Database.Error err : sr.getErrors()) {
                System.debug(
                    LoggingLevel.ERROR,
                    'PMC_CPQ_QuoteCalcCallback: failed to publish Get_Price_Response__e: ' +
                    err.getStatusCode() + ' - ' + err.getMessage()
                );
            }
        }
    }
}