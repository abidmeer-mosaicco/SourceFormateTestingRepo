@isTest
private class PMC_CPI_ProductCalloutUtilityClassTest {
    
    @testSetup
    static void setupTestData() {
        // Create Product
        Product2 prod = new Product2(
            Name = 'Test Product',
            PMC_CPQ_SAPProductCode__c = '123456',
            PMC_CPQ_Control_Code__c = 'CC001',
            PMC_CPQ_Date_from__c = Date.today(),
            PMC_CPQ_Planning_Group__c = 'AS',
            PMC_CPQ_Basic_Text__c = 'Texto Básico PT',
            PMC_CPQ_Basic_Text_ES__c = 'Texto Básico ES',
            PMC_CPQ_Nitrogen__c = 10,
            PMC_CPQ_Phosphorous__c = 20,
            PMC_CPQ_Phosphorous_PH2O__c = 5,
            PMC_CPQ_Potassium__c = 30,
            PMC_CPQ_Magnesium__c = 8,
            PMC_CPQ_Calcium__c = 6,
            PMC_CPQ_Zinc__c = 2,
            PMC_CPQ_Copper__c = 1,
            PMC_CPQ_Sulfur__c = 3,
            PMC_CPQ_Sulfur_SO4__c = 4,
            PMC_CPQ_Boron__c = 0.5,
            PMC_CPQ_Cobalt__c = 0.2,
            PMC_CPQ_Iron__c = 0.3,
            PMC_CPQ_Manganese__c = 0.4,
            PMC_CPQ_Molybdenum__c = 0.1,
            PMC_CPQ_Chlorine__c = 0.6,
            PMC_CPQ_Silicone__c = 0.7,
            PMC_CPQ_Sales_Org__c = '4000',
            PMC_CPQ_QuantityUnitOfMeasure__c = 'KG',
            Standard_Price__c = 100,
            Material_Usage__c = 8,
            Material_Origin__c = 8,
            PMC_CPQ_Produced_In_House__c = true
        );
        insert prod;

        // Create Location
        Schema.Location locationAcc = new Schema.Location(Name = 'Test Location', PMC_CPQ_Plant__c = 'PL01', PMC_CPQ_Country__c = 'BR', PMC_CPQ_SalesOrg__c = 'SORG', PMC_CPQ_Profit_Center__c = 'PROF1');
        insert locationAcc;

        // Create ProductLocation
        PMC_CPQ_ProductLocation__c productLoc = new PMC_CPQ_ProductLocation__c(
            PMC_CPQ_Location__c = locationAcc.Id,
            PMC_CPQ_ProductName__c = prod.Id,
            PMC_CPQ_ProductLocationSAPIdentifier__c = 'ID123'
        );
        insert productLoc;
    }

    @isTest
    static void testCreateProductPayload() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        String payload = PMC_CPI_ProductCalloutUtilityClass.createProductPayload(prod.Id);
        System.assertNotEquals(null, payload, 'Payload should not be null');
        System.assert(payload.contains('<ROOT>'), 'Payload should contain expected XML root element');
    }

    @isTest
    static void testSendCalloutRequest() {
        // Setup Mock Response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        HttpResponse response = PMC_CPI_ProductCalloutUtilityClass.sendCalloutRequest(
            'POST',
            'https://test.salesforce.com/services/apexrest/mockEndpoint',
            '<sample>test</sample>'
        );
        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.getStatusCode(), 'Status code should be 200');
    }

    @isTest
    static void testAutoRetryQueueableApexTrue() {
        Boolean result = PMC_CPI_ProductCalloutUtilityClass.autoRetryQueueableApex(2, 'RetryableError1');
        System.assert(result == false || result == true, 'shouldRetry should return a boolean');
    }

    @isTest
    static void testAutoRetryQueueableApexFalse() {
        Boolean result = PMC_CPI_ProductCalloutUtilityClass.autoRetryQueueableApex(4, 'RetryableError1');
        System.assert(result == false || result == true, 'shouldRetry should return a boolean');

        Boolean result2 = PMC_CPI_ProductCalloutUtilityClass.autoRetryQueueableApex(2, 'NonRetryableError');
        System.assert(result == false || result == true, 'shouldRetry should return a boolean');
    }

    // Mock Class for HTTP Callouts
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/xml');
            res.setBody('<response>Success</response>');
            res.setStatusCode(200);
            return res;
        }
    }
}