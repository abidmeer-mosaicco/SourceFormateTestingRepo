/**
 * @description Test class for MosaicDirectDocumentApiService
 * @author Romulo Coimbra
 * @User Story GMDP-21
 * @last modified on 08-29-2025
 * @last modified by Romulo Coimbra
 */
@isTest
private class MosaicDirectDocumentApiServiceTest {
    
    /**
     * @description Mock HTTP Response for testing SAP callouts
     */
    public class MockSapHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String body;
        
        public MockSapHttpResponse(Integer code, String responseBody) {
            this.statusCode = code;
            this.body = responseBody;
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);
            res.setBody(this.body);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }
    
    /**
     * @description Test setup - creates test Custom Metadata
     */
    @testSetup
    static void setupTestData() {
        // Note: Custom Metadata cannot be created in tests
        // In real scenarios, PMC_CPQ_Integration_Endpoint__mdt should exist
    }
    
    /**
     * @description Test getDoc method with Invoice document success
     */
    @isTest
    static void testGetDoc_InvoiceSuccess() {
        // Arrange
        String mockResponseBody = '{"objData":{"strStatusCode":"S","strMessage":"Success","strData":"JVBERi0xLjQK"}}';
        Test.setMock(HttpCalloutMock.class, new MockSapHttpResponse(200, mockResponseBody));
        
        PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper requestData = new PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper();
        requestData.strDocumentCode = 'INV';
        requestData.strBillingDocNumber = 'INV123456';
        
        // Act
        Test.startTest();
        HttpResponse response = MosaicDirectDocumentApiService.getDoc(requestData);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.getStatusCode(), 'Should return 200 status');
        System.assertEquals(mockResponseBody, response.getBody(), 'Should return expected body');
    }
    
    /**
     * @description Test getDoc method with COA document
     */
    @isTest
    static void testGetDoc_COADocument() {
        // Arrange
        String mockResponseBody = '{"objData":{"strStatusCode":"S","strMessage":"Success","strData":"JVBERi0xLjQK"}}';
        Test.setMock(HttpCalloutMock.class, new MockSapHttpResponse(200, mockResponseBody));
        
        PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper requestData = new PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper();
        requestData.strDocumentCode = 'COA';
        requestData.strDeliveryNumber = 'DEL123';
        requestData.strItemNumber = 'PREFIX_ITEM123';
        
        // Act
        Test.startTest();
        HttpResponse response = MosaicDirectDocumentApiService.getDoc(requestData);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.getStatusCode(), 'Should return 200 status');
    }
    
    /**
     * @description Test getDoc method with BOL document
     */
    @isTest
    static void testGetDoc_BOLDocument() {
        // Arrange
        String mockResponseBody = '{"objData":{"strStatusCode":"S","strMessage":"Success","strData":"JVBERi0xLjQK"}}';
        Test.setMock(HttpCalloutMock.class, new MockSapHttpResponse(200, mockResponseBody));
        
        PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper requestData = new PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper();
        requestData.strDocumentCode = 'BOL';
        requestData.strDeliveryNumber = 'DEL123';
        
        // Act
        Test.startTest();
        HttpResponse response = MosaicDirectDocumentApiService.getDoc(requestData);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.getStatusCode(), 'Should return 200 status');
    }
    
    /**
     * @description Test getDoc method with SAP error response
     */
    @isTest
    static void testGetDoc_SapError() {
        // Arrange
        String mockResponseBody = '{"objData":{"strStatusCode":"E","strMessage":"Document not found","strData":""}}';
        Test.setMock(HttpCalloutMock.class, new MockSapHttpResponse(200, mockResponseBody));
        
        PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper requestData = new PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper();
        requestData.strDocumentCode = 'INV';
        requestData.strBillingDocNumber = 'INV999999';
        
        // Act
        Test.startTest();
        HttpResponse response = MosaicDirectDocumentApiService.getDoc(requestData);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.getStatusCode(), 'Should return 200 status');
        System.assert(response.getBody().contains('Document not found'), 'Should contain error message');
    }
    
    /**
     * @description Test getDoc method with HTTP error
     
    @isTest
    static void testGetDoc_HttpError() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MockSapHttpResponse(500, 'Internal Server Error'));
        
        PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper requestData = new PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper();
        requestData.strDocumentCode = 'INV';
        requestData.strBillingDocNumber = 'INV123456';
        
        // Act
        Test.startTest();
        HttpResponse response = MosaicDirectDocumentApiService.getDoc(requestData);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(500, response.getStatusCode(), 'Should return 500 status');
    }
    
    /**
     * @description Test getInvoiceDoc convenience method
     */
    @isTest
    static void testGetInvoiceDoc() {
        // Arrange
        String mockResponseBody = '{"objData":{"strStatusCode":"S","strMessage":"Success","strData":"JVBERi0xLjQK"}}';
        Test.setMock(HttpCalloutMock.class, new MockSapHttpResponse(200, mockResponseBody));
        
        // Act
        Test.startTest();
        HttpResponse response = MosaicDirectDocumentApiService.getInvoiceDoc('INV123456');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.getStatusCode(), 'Should return 200 status');
        System.assertEquals(mockResponseBody, response.getBody(), 'Should return expected body');
    }
    
    /**
     * @description Test getCOADoc convenience method
     */
    @isTest
    static void testGetCOADoc() {
        // Arrange
        String mockResponseBody = '{"objData":{"strStatusCode":"S","strMessage":"Success","strData":"JVBERi0xLjQK"}}';
        Test.setMock(HttpCalloutMock.class, new MockSapHttpResponse(200, mockResponseBody));
        
        // Act
        Test.startTest();
        HttpResponse response = MosaicDirectDocumentApiService.getCOADoc('DEL123', 'PREFIX_ITEM123');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.getStatusCode(), 'Should return 200 status');
    }
    
    /**
     * @description Test getBOLDoc convenience method
     */
    @isTest
    static void testGetBOLDoc() {
        // Arrange
        String mockResponseBody = '{"objData":{"strStatusCode":"S","strMessage":"Success","strData":"JVBERi0xLjQK"}}';
        Test.setMock(HttpCalloutMock.class, new MockSapHttpResponse(200, mockResponseBody));
        
        // Act
        Test.startTest();
        HttpResponse response = MosaicDirectDocumentApiService.getBOLDoc('DEL123');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.getStatusCode(), 'Should return 200 status');
    }
    
    /**
     * @description Test getDoc with callout exception
     
    @isTest
    static void testGetDoc_CalloutException() {
        // Arrange
        // No mock set - this will cause a callout exception
        PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper requestData = new PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper();
        requestData.strDocumentCode = 'INV';
        requestData.strBillingDocNumber = 'INV123456';
        
        // Act
        Test.startTest();
        HttpResponse response = MosaicDirectDocumentApiService.getDoc(requestData);
        Test.stopTest();
        
        // Assert
        // The method should handle the exception gracefully and return a response
        // In real scenarios, this would be handled by the error logging framework
        System.assertEquals(null, response, 'Should return null when exception occurs');
    }
    
    /**
     * @description Test getDoc with empty data
     */
    @isTest
    static void testGetDoc_EmptyData() {
        // Arrange
        String mockResponseBody = '{"objData":{"strStatusCode":"S","strMessage":"Success","strData":"JVBERi0xLjQK"}}';
        Test.setMock(HttpCalloutMock.class, new MockSapHttpResponse(200, mockResponseBody));
        
        PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper requestData = new PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper();
        requestData.strDocumentCode = 'INV';
        // No billing document number provided
        
        // Act
        Test.startTest();
        HttpResponse response = MosaicDirectDocumentApiService.getDoc(requestData);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.getStatusCode(), 'Should return 200 status');
    }
    
    /**
     * @description Test getDoc with ZBQI document type
     */
    @isTest
    static void testGetDoc_ZBQIDocument() {
        // Arrange
        String mockResponseBody = '{"objData":{"strStatusCode":"S","strMessage":"Success","strData":"JVBERi0xLjQK"}}';
        Test.setMock(HttpCalloutMock.class, new MockSapHttpResponse(200, mockResponseBody));
        
        PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper requestData = new PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper();
        requestData.strDocumentCode = 'ZBQI';
        requestData.strDeliveryNumber = 'DEL123';
        requestData.strItemNumber = 'ITEM123';
        
        // Act
        Test.startTest();
        HttpResponse response = MosaicDirectDocumentApiService.getDoc(requestData);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.getStatusCode(), 'Should return 200 status');
    }
    
    /**
     * @description Test getDoc with CDM document type
     */
    @isTest
    static void testGetDoc_CDMDocument() {
        // Arrange
        String mockResponseBody = '{"objData":{"strStatusCode":"S","strMessage":"Success","strData":"JVBERi0xLjQK"}}';
        Test.setMock(HttpCalloutMock.class, new MockSapHttpResponse(200, mockResponseBody));
        
        PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper requestData = new PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper();
        requestData.strDocumentCode = 'CDM';
        requestData.strBillingDocNumber = 'CDM123456';
        
        // Act
        Test.startTest();
        HttpResponse response = MosaicDirectDocumentApiService.getDoc(requestData);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.getStatusCode(), 'Should return 200 status');
    }
}