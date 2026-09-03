@IsTest
private class TrackTraceControllerTest {

    @IsTest
    static void testGetLastIntegrationUpdate() {

        PMC_Shipment_Data__c shipmentData = new PMC_Shipment_Data__c(
            Name = 'Test',
            PMC_CUSTORDERNO__c = 'ORDER123',
            PMC_EQUIPMENTID__c = 'VEH123',
            PMC_Deliveries_Updated__c = false
        );
        insert shipmentData;

        Test.startTest();

            Database.executeBatch(new PMC_IntellitransShipmentBatchUpdate(), 1);
        
        Test.stopTest(); 

        Datetime result = TrackTraceController.getLastIntegrationUpdate();

        System.assertNotEquals(null, result, 
            'Expected a CompletedDate from AsyncApexJob');
    }

}