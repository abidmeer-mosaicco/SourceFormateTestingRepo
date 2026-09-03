trigger MassUpdateExecutionLineTrigger on MassUpdateExecutionLine__c (after update) {
    if(Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert)) {
        List<MassUpdateEvent__e> events = new List<MassUpdateEvent__e>();
        for (MassUpdateExecutionLine__c line : Trigger.new) {
            events.add(new MassUpdateEvent__e(
                ExecutionId__c = line.MassUpdateExecution__c,
                LineId__c = line.Id,
                Status__c = line.Status__c,
                Step__c = line.Step__c,
                Message__c = line.Message__c
            ));
            // MassUpdateExecutionLineTriggerHelper.updateExecutionStatus(line.MassUpdateExecution__c);
        }
        EventBus.publish(events);
    }
}