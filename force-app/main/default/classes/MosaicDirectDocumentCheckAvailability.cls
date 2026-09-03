public without sharing class MosaicDirectDocumentCheckAvailability {
    @AuraEnabled
    public static String checkDocumentButtons(String rawShipmentItems) {
        try {
            List<Object> rawItems = (List<Object>) JSON.deserializeUntyped(rawShipmentItems);
            List<Map<String, Object>> shipmentItems = new List<Map<String, Object>>();

            for (Object item : rawItems) {
                if (item instanceof Map<String, Object>) {
                    shipmentItems.add((Map<String, Object>) item);
                } else {
                    System.debug('Item inválido encontrado: ' + item);
                }
            }

            if (shipmentItems.isEmpty()) {
                throw new AuraHandledException('Nenhum item válido encontrado no JSON.');
            }

            Set<Id> orderIds = new Set<Id>();
            for (Map<String, Object> ship : shipmentItems) {
                Object orderProduct = ship.get('PMC_CPQ_OrderProduct__c');
                if (orderProduct != null) {
                    orderIds.add(String.valueOf(orderProduct));
                }
            }

            Map<Id, PMC_CPQ_InvoiceItem__c> orderInvoiceItems = new Map<Id, PMC_CPQ_InvoiceItem__c>();
            Map<Id, ShipmentItem> bolItems = new Map<Id, ShipmentItem>();
            Map<Id, ShipmentItem> coaItems = new Map<Id, ShipmentItem>();

            if (!orderIds.isEmpty()) {
                for (PMC_CPQ_InvoiceItem__c invoiceItem : [
                    SELECT Id, PMC_CPQ_OrderProduct__c 
                    FROM PMC_CPQ_InvoiceItem__c 
                    WHERE PMC_CPQ_OrderProduct__c IN :orderIds
                ]) {
                    orderInvoiceItems.put(invoiceItem.PMC_CPQ_OrderProduct__c, invoiceItem);
                }

                for (ShipmentItem shipmentItem : [
                    SELECT Id, PMC_CPQ_ModeofTransportation__c, PMC_CPQ_OrderProduct__c, Shipment.Insp_Lot_Usage_Decision__c
                    FROM ShipmentItem 
                    WHERE PMC_CPQ_OrderProduct__c IN :orderIds AND Shipment.Status != 'Delivery Deleted' AND Shipment.PMC_CPQ_DeliveryStatus__c = 'Completely Shipped'
                ]) {
                    if (shipmentItem.PMC_CPQ_ModeofTransportation__c == 'Barge') continue; // GMDP-2127

                    bolItems.put(shipmentItem.PMC_CPQ_OrderProduct__c, shipmentItem);
                    if (shipmentItem.Shipment.Insp_Lot_Usage_Decision__c == 'Approved') coaItems.put(shipmentItem.PMC_CPQ_OrderProduct__c, shipmentItem);
                }
            }

            for (Map<String, Object> ship : shipmentItems) {
                Object orderProduct = ship.get('PMC_CPQ_OrderProduct__c');
                String orderItemId = orderProduct != null ? String.valueOf(orderProduct) : null;

                ship.put('invoiceFounded', orderInvoiceItems.get(orderItemId) != null);
                ship.put('bolFounded', bolItems.get(orderItemId) != null);
                ship.put('coaFounded', coaItems.get(orderItemId) != null);
            }

            return JSON.serialize(shipmentItems);
        } catch (Exception e) {
            throw new AuraHandledException('Erro ao processar documentos: ' + e.getMessage());
        }
    }
}