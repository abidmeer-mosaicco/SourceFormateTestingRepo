public with sharing class ShipmentItemTriggerHandler {

    public static void updateVisibilityOnCreate(List<ShipmentItem> newShipmentItems) {
        // Step 1: Collect OrderItemIds
        Set<Id> orderItemIds = new Set<Id>();
        for (ShipmentItem newItem : newShipmentItems) {
            if (newItem.PMC_CPQ_OrderProduct__c != null) {
                orderItemIds.add(newItem.PMC_CPQ_OrderProduct__c);
            }
        }

        if (orderItemIds.isEmpty()) {
            return;
        }

        // Step 2: Check which OrderItems have Invoices
        Map<Id, Boolean> orderItemHasInvoiceMap = new Map<Id, Boolean>();
        for (Id orderItemId : orderItemIds) {
            orderItemHasInvoiceMap.put(orderItemId, false);
        }

        for (PMC_CPQ_Invoice__c invoice : [
            SELECT Id, PMC_CPQ_OrderProduct__c
            FROM PMC_CPQ_Invoice__c 
            WHERE PMC_CPQ_OrderProduct__c IN :orderItemIds
        ]) {
            if (invoice.PMC_CPQ_OrderProduct__c != null) {
                orderItemHasInvoiceMap.put(invoice.PMC_CPQ_OrderProduct__c, true);
            }
        }

        // Step 3: Get ALL ShipmentItems for these OrderItems, ordered by CreatedDate DESC
        List<ShipmentItem> allRelatedItems = [
            SELECT Id, isVisible__c, isTTVisible__c, isFPD__c, PMC_CPQ_OrderProduct__c, CreatedDate
            FROM ShipmentItem
            WHERE PMC_CPQ_OrderProduct__c IN :orderItemIds
            ORDER BY CreatedDate DESC
        ];

        // Merge new items not yet committed to the database
        Set<Id> existingIds = new Set<Id>();
        for (ShipmentItem item : allRelatedItems) {
            existingIds.add(item.Id);
        }
        for (ShipmentItem newItem : newShipmentItems) {
            if (!existingIds.contains(newItem.Id)) {
                allRelatedItems.add(newItem);
            }
        }

        // Step 4: Group ShipmentItems by OrderItem
        Map<Id, List<ShipmentItem>> orderItemToShipmentItemsMap = new Map<Id, List<ShipmentItem>>();
        for (ShipmentItem item : allRelatedItems) {
            if (!orderItemToShipmentItemsMap.containsKey(item.PMC_CPQ_OrderProduct__c)) {
                orderItemToShipmentItemsMap.put(item.PMC_CPQ_OrderProduct__c, new List<ShipmentItem>());
            }
            orderItemToShipmentItemsMap.get(item.PMC_CPQ_OrderProduct__c).add(item);
        }

        // Step 5: Apply visibility logic for each OrderItem
        List<ShipmentItem> itemsToUpdate = new List<ShipmentItem>();

        for (Id orderItemId : orderItemToShipmentItemsMap.keySet()) {
            List<ShipmentItem> items = orderItemToShipmentItemsMap.get(orderItemId);
            Boolean hasInvoice = orderItemHasInvoiceMap.get(orderItemId) == true;

            // Find the most recent item with isFPD = false
            ShipmentItem mostRecentNonFpd = null;
            for (ShipmentItem item : items) {
                if (item.isFPD__c == false) {
                    mostRecentNonFpd = item;
                    break;
                }
            }

            // Find the most recent item with isFPD = true
            ShipmentItem mostRecentFpd = null;
            for (ShipmentItem item : items) {
                if (item.isFPD__c == true) {
                    mostRecentFpd = item;
                    break;
                }
            }

            // Determine which item should be visible
            ShipmentItem visibleItem = null;

            if (mostRecentNonFpd != null) {
                // Priority 1: Most recent non-FPD item
                visibleItem = mostRecentNonFpd;
            } else if (mostRecentFpd != null && !hasInvoice) {
                // Priority 2: Most recent FPD item, but only if no invoice
                visibleItem = mostRecentFpd;
            }

            // GMDP-2985 - For FPD Orders, In Transit tab should only display the STO deliveries
            ShipmentItem ttVisibleItem = null;

            // Priority 1: isFPD__c = true AND isVisible__c = true
            if (ttVisibleItem == null && mostRecentFpd != null && mostRecentFpd.Id == visibleItem?.Id) {
                ttVisibleItem = mostRecentFpd;
            }

            // Priority 2: isFPD__c = true AND isVisible__c = false
            if (ttVisibleItem == null && mostRecentFpd != null) {
                ttVisibleItem = mostRecentFpd;
            }

            // Priority 3: isFPD__c = false AND isVisible__c = true
            if (ttVisibleItem == null && visibleItem != null && visibleItem.isFPD__c == false) {
                ttVisibleItem = visibleItem;
            }
            // END GMDP-2985

            for (ShipmentItem item : items) {
                Boolean shouldBeVisible = (item.Id == visibleItem?.Id);
                Boolean shouldBeTTVisible = (item.Id == ttVisibleItem?.Id);
                Boolean isChanged = false;

                if (item.isVisible__c != shouldBeVisible) {
                    item.isVisible__c = shouldBeVisible;
                    isChanged = true;
                }

                // GMDP-2985
                if (item.isTTVisible__c != shouldBeTTVisible) {
                    item.isTTVisible__c = shouldBeTTVisible;
                    isChanged = true;
                }
                // END GMDP-2985

                if (isChanged) itemsToUpdate.add(item);
            }
        }

        if (!itemsToUpdate.isEmpty()) {
            update itemsToUpdate;
        }
    }

    public static void rollupActualShippedQuantity(List<ShipmentItem> newList, Map<Id, ShipmentItem> oldMap) {
        Set<Id> orderItemIds = new Set<Id>();

        if (newList != null) {
            for (ShipmentItem si : newList) {
                if (si.PMC_CPQ_OrderProduct__c != null) {
                    orderItemIds.add(si.PMC_CPQ_OrderProduct__c);
                }
                if (oldMap != null) {
                    ShipmentItem oldItem = oldMap.get(si.Id);
                    if (oldItem != null
                        && oldItem.PMC_CPQ_OrderProduct__c != null
                        && oldItem.PMC_CPQ_OrderProduct__c != si.PMC_CPQ_OrderProduct__c) {
                        orderItemIds.add(oldItem.PMC_CPQ_OrderProduct__c);
                    }
                }
            }
        } else if (oldMap != null) {
            for (ShipmentItem si : oldMap.values()) {
                if (si.PMC_CPQ_OrderProduct__c != null) {
                    orderItemIds.add(si.PMC_CPQ_OrderProduct__c);
                }
            }
        }

        recalculateActualShippedQuantity(orderItemIds);
    }

    public static void recalculateActualShippedQuantity(Set<Id> orderItemIds) {
        if (orderItemIds == null || orderItemIds.isEmpty()) {
            return;
        }

        Map<Id, Decimal> totalsByOrderItem = new Map<Id, Decimal>();
        for (Id orderItemId : orderItemIds) {
            totalsByOrderItem.put(orderItemId, 0);
        }

        for (AggregateResult ar : [
            SELECT PMC_CPQ_OrderProduct__c orderItemId, SUM(PMC_CPQ_DeliveryQuantity__c) totalQuantity
            FROM ShipmentItem
            WHERE PMC_CPQ_OrderProduct__c IN :orderItemIds
                AND isTTVisible__c = TRUE
                AND Shipment.Status != 'Delivery Deleted'
            GROUP BY PMC_CPQ_OrderProduct__c
        ]) {
            totalsByOrderItem.put(
                (Id) ar.get('orderItemId'),
                (Decimal) ar.get('totalQuantity')
            );
        }

        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        for (OrderItem oi : [
            SELECT Id, ActualShippedQuantity__c
            FROM OrderItem
            WHERE Id IN :orderItemIds
        ]) {
            Decimal newTotal = totalsByOrderItem.get(oi.Id);
            if (oi.ActualShippedQuantity__c != newTotal) {
                orderItemsToUpdate.add(new OrderItem(
                    Id = oi.Id,
                    ActualShippedQuantity__c = newTotal
                ));
            }
        }

        if (!orderItemsToUpdate.isEmpty()) {
            update orderItemsToUpdate;
        }
    }

}