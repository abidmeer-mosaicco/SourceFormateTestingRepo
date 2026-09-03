trigger CLIBalanceTrigger on Contract_Line_Item__c (after insert, before update, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isUpdate) CLIBalanceTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) CLIBalanceTriggerHandler.afterInsert(Trigger.new);
        if (Trigger.isUpdate) CLIBalanceTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}