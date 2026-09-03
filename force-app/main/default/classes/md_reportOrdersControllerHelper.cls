public class md_reportOrdersControllerHelper {

    public static List<md_reportOrdersWrapper.ShipmentSummary> mapShipmentsToSummaries(
        List<ShipmentItem> shipments
    ) {

        Map<Id, ShipmentItem> selectedShipmentByOrderItem = new Map<Id, ShipmentItem>();

        for (ShipmentItem shipm : shipments) {

            if (shipm.PMC_CPQ_OrderProduct__c == null) continue;

            Id orderItemId = shipm.PMC_CPQ_OrderProduct__c;
            if (!selectedShipmentByOrderItem.containsKey(orderItemId)) {
                selectedShipmentByOrderItem.put(orderItemId, shipm);
                continue;
            }

            ShipmentItem currentSelected = selectedShipmentByOrderItem.get(orderItemId);

            if (shipm.isFPD__c == true && currentSelected.isFPD__c != true) {
                selectedShipmentByOrderItem.put(orderItemId, shipm);
            }
        }

        List<md_reportOrdersWrapper.ShipmentSummary> result =
            new List<md_reportOrdersWrapper.ShipmentSummary>();

        for (ShipmentItem shipm : selectedShipmentByOrderItem.values()) {

            md_reportOrdersWrapper.ShipmentSummary summary = new md_reportOrdersWrapper.ShipmentSummary();
            summary.orderItemId = String.valueOf(shipm.PMC_CPQ_OrderProduct__c);
            summary.vehicleID = shipm.Shipment.PMC_CPQ_VehicleID__c;
            summary.ShippedDate = shipm.Shipment.PMC_CPQ_ShippedDate__c != null ? String.valueOf(shipm.Shipment.PMC_CPQ_ShippedDate__c) : null;

            result.add(summary);
        }

        return result;
    }
}