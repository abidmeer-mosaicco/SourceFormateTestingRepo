public class PMC_CPQ_InvoiceItemTriggerHandler {
    private static final Boolean BOOL_BYPASS_AFTER_INSERT;
    private static final Boolean BOOL_BYPASS_AFTER_UPDATE;
    
    @TestVisible
    public static Boolean boolBypassTriggerLogic = false;
    
    private static Boolean HAS_RUN = false;
    
    static {
        Boolean bypassInsert = false;
        Boolean bypassUpdate = false;
        PMC_TriggerSwitches__mdt switches =
            PMC_TriggerSwitches__mdt.getInstance('Invoice_Line_Item');
        if (switches != null) {
            bypassInsert = switches.PMC_AfterInsert__c;
            bypassUpdate = switches.PMC_AfterUpdate__c;
        }
        BOOL_BYPASS_AFTER_INSERT = bypassInsert;
        BOOL_BYPASS_AFTER_UPDATE = bypassUpdate;
    }
    
    public static void afterInsert(List<PMC_CPQ_InvoiceItem__c> newList) {
        if (BOOL_BYPASS_AFTER_INSERT || boolBypassTriggerLogic)
            return;
        
        Set<Id> oiIds = collectOrderItemIds(newList, null);
        enqueueIfNeeded(oiIds);
    }
    
    public static void afterUpdate(List<PMC_CPQ_InvoiceItem__c> newList, Map<Id, PMC_CPQ_InvoiceItem__c> oldMap) {
        if (BOOL_BYPASS_AFTER_UPDATE || boolBypassTriggerLogic)
            return;
        
        Set<Id> oiIds = collectOrderItemIds(newList, oldMap);
        
        enqueueIfNeeded(oiIds);
    }
    
    @TestVisible
    private static Set<Id> collectOrderItemIds(List<PMC_CPQ_InvoiceItem__c> newList, Map<Id, PMC_CPQ_InvoiceItem__c> oldMap) {
        Set<Id> oiIds = new Set<Id>();
        
        for (PMC_CPQ_InvoiceItem__c ii : newList) {
            
            if (ii.PMC_CPQ_OrderProduct__c == null)
                continue;
            
            if (oldMap == null) {
                oiIds.add(ii.PMC_CPQ_OrderProduct__c);
                continue;
            }
            
            PMC_CPQ_InvoiceItem__c old = oldMap.get(ii.Id);
            if (hasRelevantChange(ii, old)) {
                oiIds.add(ii.PMC_CPQ_OrderProduct__c);
            }
        }
        
        return oiIds;
    }
    
    @TestVisible
    private static Boolean hasRelevantChange(PMC_CPQ_InvoiceItem__c newRec, PMC_CPQ_InvoiceItem__c oldRec) {
        return newRec.PMC_CPQ_NetInvoicedQuantity__c != oldRec.PMC_CPQ_NetInvoicedQuantity__c || newRec.PMC_CPQ_Invoice__c != oldRec.PMC_CPQ_Invoice__c;
    }
    
    // Changed to public methods as it's called in 2 different classes
    // which was shown during PMC_CPQ_GetPriceActionClassTest
    public static void enqueueIfNeeded(Set<Id> oiIds) {
        if (oiIds.isEmpty() || HAS_RUN) return;
        
        Set<Id> subIds = getSubscriptionIds(oiIds);
        if (subIds.isEmpty()) return;
        
        Set<Id> cliIds = getCLIIds(subIds);
        if (cliIds.isEmpty()) return;
        
        HAS_RUN = true;
        new CLIBalanceCalculator(cliIds).execute();
    }
    
    @TestVisible
    private static Set<Id> getSubscriptionIds(Set<Id> oiIds) {
        Set<Id> subIds = new Set<Id>();
        for (OrderItem oi : [
            SELECT SBQQ__Subscription__c
            FROM OrderItem
            WHERE Id IN :oiIds
            AND SBQQ__Subscription__c != null
            WITH SYSTEM_MODE
        ]) {
            subIds.add(oi.SBQQ__Subscription__c);
        }
        return subIds;
    }
    
    @TestVisible
    private static Set<Id> getCLIIds(Set<Id> subIds) {
        Set<Id> cliIds = new Set<Id>();
        for (SBQQ__Subscription__c sub : [
            SELECT Contract_Line_Item__c
            FROM SBQQ__Subscription__c
            WHERE Id IN :subIds
            AND Contract_Line_Item__c != null
            WITH SYSTEM_MODE
        ]) {
            cliIds.add(sub.Contract_Line_Item__c);
        }
        return cliIds;
    }
}