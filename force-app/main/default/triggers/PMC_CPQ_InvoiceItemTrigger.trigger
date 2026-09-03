trigger PMC_CPQ_InvoiceItemTrigger on PMC_CPQ_InvoiceItem__c (after insert, after update) {
    //if (Trigger.isBefore){}
    
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            PMC_CPQ_InvoiceItemTriggerHandler.afterInsert(Trigger.new);
        }
        
        if(Trigger.isUpdate) {
            PMC_CPQ_InvoiceItemTriggerHandler.afterUpdate(Trigger.new,Trigger.oldMap);
        }
    }
    
}