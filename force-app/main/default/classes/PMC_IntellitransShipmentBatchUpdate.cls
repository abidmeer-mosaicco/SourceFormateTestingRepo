// GMDP-2612 - Added NOMOVEMENT/DaysNotMoved__c data into shipment
public class PMC_IntellitransShipmentBatchUpdate implements Database.Batchable<SObject>, Database.AllowsCallouts, Schedulable {

    private Set<Id> shipmentDataIds;

    public PMC_IntellitransShipmentBatchUpdate() {
        this.shipmentDataIds = new Set<Id>();
    }

    public PMC_IntellitransShipmentBatchUpdate(Set<Id> shipmentDataIds) {
        this.shipmentDataIds = shipmentDataIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, PMC_BOL__c, PMC_BOLNUMBER__c, PMC_COMMENTS__c, PMC_CPQ_CurrentCoordinates__c, ' +
                       'PMC_CPQ_CurrentCoordinates__Latitude__s, PMC_CPQ_CurrentCoordinates__Longitude__s, ' +
                       'PMC_CPQ_SAPDeliveryID__c, PMC_CPQ_Shipment_PO__c, PMC_CPQ_ShipmentNumber__c, ' +
                       'PMC_CURRENTCARRIER__c, DaysNotMoved__c, Intransit_Status__c, toLabel(Intransit_Status__c) statusCode, ' +
                       'PMC_CURRENTLOCATION__c, PMC_CUSTORDERNO__c, PMC_DELIVERYNUMBER__c, PMC_DESTINATIONCARRIER__c, ' +
                       'PMC_DESTINATIONMM__c, PMC_EQUIPMENTID__c, PMC_ETA__c, PMC_FLEETTOWNAME__c, ' +
                       'PMC_LATESTINTERNALCOMMENT__c, PMC_LATESTTRIPSIGHTINGID__c, PMC_PONUMBER__c, ' +
                       'PMC_SHIPMENTNUMBER_CNTORDER__c, PMC_SIGHTINGDESTINATION__c, PMC_SIGHTINGLOADOREMPTY__c, ' +
                       'PMC_Deliveries_Updated__c ' +
                       'FROM PMC_Shipment_Data__c ' +
                       'WHERE PMC_CUSTORDERNO__c != null AND PMC_EQUIPMENTID__c != null AND PMC_Deliveries_Updated__c = FALSE';

        if (this.shipmentDataIds != null && !this.shipmentDataIds.isEmpty()) {
            query += ' AND Id IN :shipmentDataIds';
        }

        return Database.getQueryLocator(query);
    }

    public void execute(SchedulableContext objSchedulableContext) {
        Database.executeBatch(new PMC_IntellitransShipmentBatchUpdate(), 200);
    }

    public void execute(Database.BatchableContext bc, List<PMC_Shipment_Data__c> scope) {
        // Maps to hold Intellitrans data
        Map<String, PMC_Shipment_Data__c> intellitransMapPO = new Map<String, PMC_Shipment_Data__c>();
        Map<String, PMC_Shipment_Data__c> intellitransMapVID = new Map<String, PMC_Shipment_Data__c>();
        Map<String, PMC_Shipment_Data__c> intellitransMapConcat = new Map<String, PMC_Shipment_Data__c>();

        // Populate the maps with IntelliTrans data
        for (PMC_Shipment_Data__c shipmentData : scope) {
            if (shipmentData.PMC_CUSTORDERNO__c != null) intellitransMapPO.put(shipmentData.PMC_CUSTORDERNO__c, shipmentData);
            if (shipmentData.PMC_EQUIPMENTID__c != null) intellitransMapVID.put(shipmentData.PMC_EQUIPMENTID__c, shipmentData);

            intellitransMapConcat.put(shipmentData.PMC_CUSTORDERNO__c + shipmentData.PMC_EQUIPMENTID__c, shipmentData);
        }

        List<Shipment> shipmentsToUpdate = [
            SELECT 
                Id,
                DaysNotMoved__c,
                Intransit_Status__c,
                PMC_CPQ_Order__r.PMC_CPQ_SAPOrderNumber__c,
                PMC_CPQ_SAPDeliveryID__c,
                PMC_CPQ_ETA__c,
                PMC_CPQ_PO__c,
                PMC_CPQ_VehicleID__c,
                PMC_CPQ_CurrentCarrier__c,
                PMC_CPQ_Carrier__c,
                PMC_CPQ_TowName__c,
                PMC_CPQ_CurrentLocation__c,
                PMC_CPQ_CurrentCoordinates__Latitude__s,
                PMC_CPQ_CurrentCoordinates__Longitude__s 
            FROM Shipment 
            WHERE PMC_CPQ_Order__r.PMC_CPQ_SAPOrderNumber__c IN :intellitransMapPO.keySet() 
               OR PMC_CPQ_VehicleID__c IN :intellitransMapVID.keySet()
        ];

        List<PMC_Shipment_Data__c> processedRecordsToUpdate = new List<PMC_Shipment_Data__c>();
        Map<Id, Shipment> shipmentsToUpdateMap = new Map<Id, Shipment>();

        for (Shipment ship : shipmentsToUpdate) {
            PMC_Shipment_Data__c matchedIntellitrans;
            String sapOrderNumber = ship.PMC_CPQ_Order__r.PMC_CPQ_SAPOrderNumber__c;

            if (sapOrderNumber != null) {
                sapOrderNumber = sapOrderNumber.removeStart('00');
            }

            if (sapOrderNumber != null && ship.PMC_CPQ_VehicleID__c != null) {
                String concatKey = sapOrderNumber + ship.PMC_CPQ_VehicleID__c;
                if (intellitransMapConcat.containsKey(concatKey)) {
                    matchedIntellitrans = intellitransMapConcat.get(concatKey);

                    PMC_Shipment_Data__c processedRecord = new PMC_Shipment_Data__c(
                        Id = matchedIntellitrans.Id, 
                        PMC_Deliveries_Updated__c = true
                    );

                    processedRecordsToUpdate.add(processedRecord);
                }
            }

            if (matchedIntellitrans != null) {
                // ship.Id = matchedIntellitrans.Id;
                // ship.PMC_CPQ_SAPDeliveryID__c = matchedIntellitrans.PMC_CPQ_SAPDeliveryID__c;

                if (matchedIntellitrans.PMC_ETA__c != null) {
                    Date currentDate = matchedIntellitrans.PMC_ETA__c.date();
                    ship.PMC_CPQ_ETA__c = Date.valueOf(currentDate);
                }

                // ship.Intransit_Status__c = matchedIntellitrans.Status__c;
                ship.Intransit_Status__c = matchedIntellitrans.Intransit_Status__c;
                String retrievedStatusCode = (String) matchedIntellitrans.get('statusCode');
                System.debug('>>> STATUS CODE: ' + retrievedStatusCode);

                if (retrievedStatusCode != null) {
                    ship.StatusCode__c = retrievedStatusCode;
                }

                // ship.PMC_CPQ_PO__c = matchedIntellitrans.PMC_CPQ_SAPDeliveryID__c;
                // ship.PMC_CPQ_VehicleID__c = matchedIntellitrans.PMC_CPQ_SAPDeliveryID__c;
                ship.PMC_CPQ_CurrentCarrier__c = matchedIntellitrans.PMC_CURRENTCARRIER__c;
                // ship.PMC_CPQ_Carrier__c = matchedIntellitrans.PMC_CPQ_SAPDeliveryID__c;

                ship.DaysNotMoved__c = matchedIntellitrans.DaysNotMoved__c;
                ship.PMC_CPQ_Comments__c = matchedIntellitrans.PMC_COMMENTS__c;
                ship.PMC_CPQ_TowName__c = matchedIntellitrans.PMC_FLEETTOWNAME__c;
                ship.PMC_CPQ_CurrentLocation__c = matchedIntellitrans.PMC_CURRENTLOCATION__c;
                ship.PMC_CPQ_Carrier__c = matchedIntellitrans.PMC_DESTINATIONCARRIER__c;
                ship.PMC_CPQ_CurrentCoordinates__Latitude__s = matchedIntellitrans.PMC_CPQ_CurrentCoordinates__Latitude__s;
                ship.PMC_CPQ_CurrentCoordinates__Longitude__s = matchedIntellitrans.PMC_CPQ_CurrentCoordinates__Longitude__s;

                shipmentsToUpdateMap.put(ship.Id, ship);
            }
        }

        // Perform the updates
        if (!shipmentsToUpdateMap.isEmpty()) {
            Database.SaveResult[] results = Database.update(shipmentsToUpdateMap.values(), false);
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug('>>> FALHA NO UPDATE DO SHIPMENT (' + sr.getId() + '). Campos: ' + err.getFields() + ' | Mensagem: ' + err.getMessage());
                    }
                }
            }
        }

        if (!processedRecordsToUpdate.isEmpty()) {
            Map<Id, PMC_Shipment_Data__c> uniqueProcessedRecordsMap = new Map<Id, PMC_Shipment_Data__c>();
            uniqueProcessedRecordsMap.putAll(processedRecordsToUpdate);
            Database.update(uniqueProcessedRecordsMap.values(), false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch processing finished.');
    }
}