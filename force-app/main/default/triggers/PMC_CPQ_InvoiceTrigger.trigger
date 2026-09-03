trigger PMC_CPQ_InvoiceTrigger on PMC_CPQ_Invoice__c (after update) {
    if (Trigger.isAfter) {
        if (Trigger.isUpdate)
            PMC_CPQ_InvoiceTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}