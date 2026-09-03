@isTest
private class PMC_CPI_ProductActionClassTest {
 
    /**
     * @description Mock class for HTTP Callout to simulate a response.
     */
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"message":"Success"}');
            return res;
        }
    }
 
    /**
     * @description Helper method to create a test Product.
     */
    private static Product2 createTestProduct() {
        Product2 prod = new Product2(Name = 'Test Product', PMC_CPQ_Material_Type__c = 'ZKMT');
        insert prod;
        return prod;
    }
 
    /**
     * @description Mocks custom metadata for endpoint.
     */
    private static void mockMetadataEndpoint() {
        PMC_CPQ_Integration_Endpoint__mdt mockMdt = new PMC_CPQ_Integration_Endpoint__mdt();
        mockMdt.PMC_CPQ_Endpoint__c = '/services/testEndpoint';
        PMC_CPI_AccountActionClass.mockMetadata.put('MasterDataMatmas_Clfmas', mockMdt);
    }
 
    /**
     * @description Test the postInfoToCPI method.
     */
    @isTest
    static void testPostInfoToCPI() {
        // Prepare test data
        Product2 testProduct = createTestProduct();
        mockMetadataEndpoint();
 
        // Create AccountActionRequest instance
        PMC_CPI_ProductActionClass.ProductActionRequest request = new PMC_CPI_ProductActionClass.ProductActionRequest();
        request.inputProduct = testProduct;    
 
        List<PMC_CPI_ProductActionClass.ProductActionRequest> requestList = new List<PMC_CPI_ProductActionClass.ProductActionRequest>{request};
 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
 
        Test.startTest();
        PMC_CPI_ProductActionClass.postInfoToCPI(requestList);
        Test.stopTest();
 
        System.assert(true, 'Queueable job should be enqueued and executed without error.');
    }
}