public class PMC_CPQ_InvoiceTriggerHandler {

    private static final Boolean BOOL_BYPASS_AFTER_UPDATE;

    @TestVisible
    public static Boolean boolBypassTriggerLogic = false;

    static {
        Boolean bypassUpdate = false;
        PMC_TriggerSwitches__mdt switches = PMC_TriggerSwitches__mdt.getInstance('PMC_CPQ_Invoice');
        if (switches != null) {
            bypassUpdate = switches.PMC_AfterUpdate__c;
        }
        BOOL_BYPASS_AFTER_UPDATE = bypassUpdate;
    }

    public static void afterUpdate(List<PMC_CPQ_Invoice__c> newList, Map<Id, PMC_CPQ_Invoice__c> oldMap) {
        if (BOOL_BYPASS_AFTER_UPDATE || boolBypassTriggerLogic) return;

        Set<Id> cancelledInvoiceIds = new Set<Id>();
        for (PMC_CPQ_Invoice__c inv : newList) {
            PMC_CPQ_Invoice__c old = oldMap.get(inv.Id);
            if (inv.PMC_CPQ_Cancelled__c == true && old.PMC_CPQ_Cancelled__c != true) {
                cancelledInvoiceIds.add(inv.Id);
            }
        }

        if (cancelledInvoiceIds.isEmpty()) return;

        Set<Id> oiIds = new Set<Id>();
        for (PMC_CPQ_InvoiceItem__c ii : [
            SELECT PMC_CPQ_OrderProduct__c
            FROM PMC_CPQ_InvoiceItem__c
            WHERE PMC_CPQ_Invoice__c IN :cancelledInvoiceIds
            AND PMC_CPQ_OrderProduct__c != null
        ]) {
            oiIds.add(ii.PMC_CPQ_OrderProduct__c);
        }

        PMC_CPQ_InvoiceItemTriggerHandler.enqueueIfNeeded(oiIds);
    }
}