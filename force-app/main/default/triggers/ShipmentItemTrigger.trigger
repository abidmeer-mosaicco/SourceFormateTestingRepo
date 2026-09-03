trigger ShipmentItemTrigger on ShipmentItem (after insert, after update, after delete, after undelete) {
    if (Trigger.isAfter && Trigger.isInsert) {
        ShipmentItemTriggerHandler.updateVisibilityOnCreate(Trigger.new);
    }

    ShipmentItemTriggerHandler.rollupActualShippedQuantity(
        Trigger.new,
        (Map<Id, ShipmentItem>) Trigger.oldMap
    );
}