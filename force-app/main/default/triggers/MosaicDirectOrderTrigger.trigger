trigger MosaicDirectOrderTrigger on Order (after update, after insert) {
    if (!Trigger.isAfter || !Trigger.isUpdate) return;

    List<Order> ordersToProcess = new List<Order>();

    for (Order newOrder : Trigger.new) {
        Order oldOrder = Trigger.oldMap.get(newOrder.Id);

        // SUCCESS PATH => PMC_CPQ_SAPOrderNumber__c
        if (String.isBlank(oldOrder.PMC_CPQ_SAPOrderNumber__c) && !String.isBlank(newOrder.PMC_CPQ_SAPOrderNumber__c) && newOrder.IsMosaicDirect__c) {
            ordersToProcess.add(newOrder);
        }

        // ERROR PATH => PMC_CPQ_OrderIntegrationStatus__c
        if (String.isBlank(oldOrder.PMC_CPQ_OrderIntegrationStatus__c) && !String.isBlank(newOrder.PMC_CPQ_OrderIntegrationStatus__c) && newOrder.IsMosaicDirect__c) {
            if (newOrder.PMC_CPQ_OrderIntegrationStatus__c == 'Error') ordersToProcess.add(newOrder);
        }

        // WARNING PATH => PMC_CPQ_OrderIntegrationStatus__c
        if (!String.isBlank(oldOrder.PMC_CPQ_OrderIntegrationStatus__c) && !String.isBlank(newOrder.PMC_CPQ_OrderIntegrationStatus__c) && newOrder.IsMosaicDirect__c) {
            if (oldOrder.PMC_CPQ_OrderIntegrationStatus__c == 'Warning' && newOrder.PMC_CPQ_OrderIntegrationStatus__c == 'Error') ordersToProcess.add(newOrder);
        }
    }

    if (!ordersToProcess.isEmpty()) {
        MosaicDirectOrderEmailSender.handleOrderSubmission(JSON.serialize(ordersToProcess));
    }

    if(Trigger.isAfter){
        if(Trigger.isInsert || Trigger.isUpdate){
            OrderTriggerHandler.cancellationResource(Trigger.new, Trigger.oldMap);
            OrderTriggerHandler.calculator(Trigger.new, Trigger.oldMap);
        }
    }

}