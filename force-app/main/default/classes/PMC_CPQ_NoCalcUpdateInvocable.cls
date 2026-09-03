/**
 * @description Invocable Apex called from the flow PMC_CPQ_FetchLatestPriceBeforeSubmittingforApproval
 *              to execute DML on Quote/QuoteLines with the CPQ Quote Calculator
 *              SUPPRESSED via SBQQ.TriggerControl.disable() in a try/finally.
 *              Replaces the flow's recordUpdates elements (Update_Quote_Lines,
 *              UpdateApprovedQuote, UpdateTriggeredQuote) that previously enqueued
 *              stale QueueableCalculatorService jobs, causing SBQQ__Status__c to
 *              revert from 'Approved' to 'Draft'.
 *              'without sharing' is justified: runs under the flow's SystemModeWithoutSharing.
 * @author Raphael Soares
 * @storynumber back-to-draft-fix
 */
public without sharing class PMC_CPQ_NoCalcUpdateInvocable {

    /**
     * @description Input wrapper for the invocable. Accepts a list of quote lines
     *              and/or a single quote.
     */
    public class Request {
        @InvocableVariable(label='Quote Lines' description='Quote lines to update (optional)' required=false)
        public List<SBQQ__QuoteLine__c> quoteLines;

        @InvocableVariable(label='Quote' description='Single quote to update (optional)' required=false)
        public SBQQ__Quote__c quote;
    }

    /**
     * @description Executes DML on Quote/QuoteLines with SBQQ.TriggerControl.disable()
     *              in a try/finally. Prevents the QueueableCalculatorService from
     *              being enqueued with a stale snapshot that would revert the status.
     * @param lstRequests Requests coming from the flow.
     */
    @InvocableMethod(
        label='Update Quote/QuoteLines without triggering CPQ Calculator'
        description='DML on Quote/QuoteLines with SBQQ.TriggerControl.disable() in a try/finally'
        category='SBQQ__Quote__c'
    )
    public static void updateWithoutCalc(List<Request> lstRequests) {
        if (lstRequests == null || lstRequests.isEmpty()) {
            return;
        }

        List<SBQQ__QuoteLine__c> lstLinesToUpdate = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__Quote__c> lstQuotesToUpdate = new List<SBQQ__Quote__c>();

        for (Request req : lstRequests) {
            if (req.quoteLines != null && !req.quoteLines.isEmpty()) {
                lstLinesToUpdate.addAll(req.quoteLines);
            }
            if (req.quote != null) {
                lstQuotesToUpdate.add(req.quote);
            }
        }

        if (lstLinesToUpdate.isEmpty() && lstQuotesToUpdate.isEmpty()) {
            return;
        }

        SBQQ.TriggerControl.disable();
        try {
            if (!lstLinesToUpdate.isEmpty()) {
                Database.update(lstLinesToUpdate, false);
            }
            if (!lstQuotesToUpdate.isEmpty()) {
                Database.update(lstQuotesToUpdate, false);
            }
        } catch (Exception e) {
            PMC_ErrorLogClass.processException(e);
            throw e;
        } finally {
            SBQQ.TriggerControl.enable();
        }
    }
}