@isTest
public class PMC_CPQ_FetchAndStoreDataTest {
    @testSetup
    static void setup() {
        // Set up any required data or configurations before tests
        // Create a mock Integration Settings record
        PMC_DH_IntegrationSettings__mdt intSettingsToken = new PMC_DH_IntegrationSettings__mdt(
            DeveloperName = 'IntelliTransGetToken',
            PMC_DH_EndpointURL__c = 'https://test.com/token',
            PMC_DH_ClientId__c = 'testClientId',
            PMC_DH_ClientSecret__c = 'testClientSecret',
            PMC_DH_CalloutMethod__c = 'POST'
        );
        //insert intSettingsToken;
        
        PMC_DH_IntegrationSettings__mdt intSettingsShipment = new PMC_DH_IntegrationSettings__mdt(
            DeveloperName = 'IntelliTransGetShipmentData',
            PMC_DH_EndpointURL__c = 'https://test.com/shipment',
            PMC_DH_ContentType__c = 'application/json',
            PMC_DH_CalloutMethod__c = 'POST'
        );
        
        //insert intSettingsShipment;
        List<PMC_Shipment_Data__c> shipmentDataList = new List<PMC_Shipment_Data__c>();
        for (Integer i = 0; i < 5; i++) {
            shipmentDataList.add(new PMC_Shipment_Data__c(
                PMC_PONUMBER__c = 'PO' + i,
                PMC_EQUIPMENTID__c = 'EQUIP' + i,
                PMC_CUSTORDERNO__c = 'PO' + i,
                	
                PMC_ETA__c = Date.today().addDays(i),
                PMC_Deliveries_Updated__c = false
            ));
        }
        insert shipmentDataList;
        
        // Create test records for shipment
        List<shipment> shipmentList = new List<shipment>();
        Account accobj = new Account(Name = 'TestAccount');
Insert accobj;
Date today = Date.today();
Order ordrobj = new Order(PMC_CPQ_SAPOrderNumber__c ='123456', AccountId = accobj.id, 	EffectiveDate = today,Status = 'Draft' );

insert ordrobj;
        
        for (Integer i = 0; i < 5; i++) {
            shipmentList.add(new shipment(
                PMC_CPQ_PO__c = 'PO' + i,
                PMC_CPQ_VehicleID__c = '789' + i,
                PMC_CPQ_ETA__c = Date.today().addDays(i + 1), // different dates to verify update
                PMC_CPQ_CurrentCarrier__c = 'OldCarrier' + i,
                PMC_CPQ_TowName__c = 'OldTowName' + i,
                PMC_CPQ_CurrentLocation__c = 'OldLocation' + i,
                PMC_CPQ_Carrier__c = 'OldCarrierDest' + i,
                PMC_CPQ_CurrentCoordinates__Latitude__s = 0,
                PMC_CPQ_CurrentCoordinates__Longitude__s = 0,
                PMC_CPQ_Order__c  = ordrobj.Id,
                ShipToName = 'Test'
            ));
        }
        insert shipmentList;
        
    }

    
    @isTest
    static void testFetchAndInsertData() {
        // Set up a mock callout response
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Call the method
        PMC_CPQ_FetchAndStoreData.fetchAndInsertData();
        Database.executeBatch(new PMC_IntellitransShipmentBatchUpdate(), 200);
        Test.stopTest();

        // Validate that records were inserted
        List<PMC_Shipment_Data__c> insertedRecords = [SELECT Id FROM PMC_Shipment_Data__c];
        System.assertEquals(6, insertedRecords.size()); // Adjust this depending on your mock data
    }

    // Mock class to simulate the HTTP callout
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if (req.getEndpoint().contains('Token')) {
                res.setBody('"mockToken"');
            } else if (req.getEndpoint().contains('Shipment')) {
                res.setBody('[{"DELIVERYNUMBER": "123456", "EQUIPMENTID": "7890", "ETA": "2022-03-15T00:00:00Z", "BOL": "BOL123", "BOLNUMBER": "BOL789", "CUSTORDERNO": "123456", "SHIPMENTNUMBER_CNTORDER": "SHIP001", "PONUMBER": "PO123", "CURRENTCARRIER": "Carrier1", "DESTINATIONCARRIER": "Carrier2", "FLEETTOWNAME": "FleetName", "COMMENTS": "Some comment", "SIGHTINGLOADOREMPTY": "Load", "CURRENTLOCATION": "Location1", "DESTINATIONMM": "DestinationMM1", "LATESTTRIPSIGHTINGID": "SIGHT123", "LATESTINTERNALCOMMENT": "Internal comment", "SIGHTINGDESTINATION": "Destination1", "LATITUDE": 12.34, "LONGITUDE": 56.78}]');
            }
            res.setStatusCode(200);
            return res;
        }
    }
}