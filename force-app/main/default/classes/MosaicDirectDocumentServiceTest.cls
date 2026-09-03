/**
 *  Test class for MosaicDirectDocumentService
 */
@isTest
private class MosaicDirectDocumentServiceTest {
    
    /**
     *  Mock HTTP Response for testing
     */
    public class MockHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String body;
        
        public void setStatusCode(Integer code) {
            this.statusCode = code;
        }
        
        public void setBody(String responseBody) {
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
     *  Test getInvoiceNumber with valid ShipmentItem ID
     */
    @isTest
    static void testGetInvoiceNumber_Success() {
        // Arrange - Create test data directly
        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Customer'
        );
        insert testAccount;
        
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            PMC_CPQ_SAPOrderNumber__c = 'SAP123456'
        );
        insert testOrder;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;
        
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testOrderItem;
        
        Shipment testShipment = new Shipment(
            ShipToName = 'Test Ship To'
        );
        insert testShipment;
        
        ShipmentItem testShipmentItem = new ShipmentItem(
            ShipmentId = testShipment.Id,
            PMC_CPQ_OrderProduct__c = testOrderItem.Id,
            Quantity = 1
        );
        insert testShipmentItem;
        
        PMC_CPQ_Invoice__c testInvoice = new PMC_CPQ_Invoice__c(
            PMC_CPQ_InvoiceNumber__c = 'INV123456'
        );
        insert testInvoice;
        
        PMC_CPQ_InvoiceItem__c testInvoiceItem = new PMC_CPQ_InvoiceItem__c(
            PMC_CPQ_Invoice__c = testInvoice.Id,
            PMC_CPQ_DeliveryItem__c = testShipmentItem.Id
        );
        insert testInvoiceItem;
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.getInvoiceNumber(testShipmentItem.Id);
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result.get('success'), 'Should return success');
        System.assertEquals('INV123456', result.get('invoiceNumber'), 'Should return correct invoice number');
        System.assertEquals('SAP123456', result.get('orderNumber'), 'Should return correct order number');
        System.assertEquals(testOrder.Id, result.get('orderId'), 'Should return correct order ID');
    }
    
    /**
     *  Test getInvoiceNumber with blank ShipmentItem ID
     */
    @isTest
    static void testGetInvoiceNumber_BlankShipmentItemId() {
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.getInvoiceNumber('');
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('success'), 'Should return failure');
        System.assertEquals('Shipment ID is required', result.get('message'), 'Should return correct error message');
    }
    
    /**
     *  Test getInvoiceNumber with non-existent ShipmentItem ID
     */
    @isTest
    static void testGetInvoiceNumber_ShipmentItemNotFound() {
        // Arrange
        String fakeShipmentItemId = 'a0D000000000000'; // Fake but valid ID format
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.getInvoiceNumber(fakeShipmentItemId);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('success'), 'Should return failure');
        System.assertEquals(null, result.get('message'), 'Should return no error message');
    }
    
    /**
     *  Test getInvoiceNumber when no invoice exists for shipment item
     */
    @isTest
    static void testGetInvoiceNumber_NoInvoiceFound() {
        // Arrange - Create test data directly
        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Customer'
        );
        insert testAccount;

        Order orderWithoutInvoice = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            PMC_CPQ_SAPOrderNumber__c = 'SAP999999'
        );
        insert orderWithoutInvoice;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;
        
        OrderItem testOrderItem = new OrderItem(
            OrderId = orderWithoutInvoice.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testOrderItem;
        
        Shipment testShipment = new Shipment(
            ShipToName = 'Test Ship To'
        );
        insert testShipment;
        
        ShipmentItem testShipmentItem = new ShipmentItem(
            ShipmentId = testShipment.Id,
            PMC_CPQ_OrderProduct__c = testOrderItem.Id,
            Quantity = 1
        );
        insert testShipmentItem;
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.getInvoiceNumber(testShipmentItem.Id);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('success'), 'Should return failure');
        System.assertEquals('No Invoice found for this Order Item', result.get('message'), 'Should return correct error message');
    }
    
    /**
     *  Test getInvoiceNumber when invoice number is blank
     */
    @isTest
    static void testGetInvoiceNumber_BlankInvoiceNumber() {
        // Arrange - Create test data with blank invoice number
        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Customer'
        );
        insert testAccount;
        
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            PMC_CPQ_SAPOrderNumber__c = 'SAP123456'
        );
        insert testOrder;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;
        
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testOrderItem;
        
        Shipment testShipment = new Shipment(
            ShipToName = 'Test Ship To'
        );
        insert testShipment;
        
        ShipmentItem testShipmentItem = new ShipmentItem(
            ShipmentId = testShipment.Id,
            PMC_CPQ_OrderProduct__c = testOrderItem.Id,
            Quantity = 1
        );
        insert testShipmentItem;
        
        PMC_CPQ_Invoice__c testInvoiceBlank = new PMC_CPQ_Invoice__c(
            PMC_CPQ_InvoiceNumber__c = '' // Blank invoice number
        );
        insert testInvoiceBlank;
        
        PMC_CPQ_InvoiceItem__c testInvoiceItem = new PMC_CPQ_InvoiceItem__c(
            PMC_CPQ_Invoice__c = testInvoiceBlank.Id,
            PMC_CPQ_DeliveryItem__c = testShipmentItem.Id
        );
        insert testInvoiceItem;
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.getInvoiceNumber(testShipmentItem.Id);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('success'), 'Should return failure');
        System.assertEquals('Invoice Number is not populated', result.get('message'), 'Should return correct error message');
    }
    
    /**
     *  Test getOrderIdFromOrderItem with valid OrderItem ID
     */
    // @isTest(SeeAllData=true)
    // static void testGetOrderIdFromOrderItem_Success() {
    //     // Find an existing OrderItem in the org
    //     OrderItem existingOrderItem = [SELECT Id, OrderId FROM OrderItem LIMIT 1];

    //     // Act
    //     Test.startTest();
    //     String result = MosaicDirectDocumentService.getOrderIdFromOrderItem(existingOrderItem.Id);
    //     Test.stopTest();

    //     // Assert
    //     System.assertEquals(existingOrderItem.OrderId, result, 'Should return correct Order ID');
    // }
    
    /**
     *  Test getOrderIdFromOrderItem with ShipmentItem ID
     */
    // @isTest(SeeAllData=true)
    // static void testGetOrderIdFromOrderItem_WithShipmentItem() {
    //     // Find an existing ShipmentItem with OrderProduct in the org
    //     ShipmentItem existingShipmentItem = [
    //         SELECT Id, PMC_CPQ_OrderProduct__c, PMC_CPQ_OrderProduct__r.OrderId
    //         FROM ShipmentItem
    //         WHERE PMC_CPQ_OrderProduct__c != null
    //         LIMIT 1
    //     ];
        
    //     // Act
    //     Test.startTest();
    //     String result = MosaicDirectDocumentService.getOrderIdFromOrderItem(existingShipmentItem.Id);
    //     Test.stopTest();
        
    //     // Assert
    //     System.assertEquals(existingShipmentItem.PMC_CPQ_OrderProduct__r.OrderId, result, 'Should return correct Order ID from ShipmentItem');
    // }
    
    /**
     *  Test getOrderIdFromOrderItem with blank OrderItem ID
     */
    @isTest
    static void testGetOrderIdFromOrderItem_BlankId() {
        // Act
        Test.startTest();
        String result = MosaicDirectDocumentService.getOrderIdFromOrderItem('');
        Test.stopTest();
        
        // Assert
        System.assertEquals(null, result, 'Should return null for blank ID');
    }
    
    /**
     *  Test getOrderIdFromOrderItem with non-existent OrderItem ID
     */
    @isTest
    static void testGetOrderIdFromOrderItem_NotFound() {
        // Arrange
        String fakeOrderItemId = '802000000000000'; // Fake but valid ID format
        
        // Act
        Test.startTest();
        String result = MosaicDirectDocumentService.getOrderIdFromOrderItem(fakeOrderItemId);
        Test.stopTest();
        
        // Assert
        System.assertEquals(null, result, 'Should return null for non-existent ID');
    }
    
    /**
     *  Test downloadInvoice with mock HTTP response
     */
    @isTest
    static void testDownloadInvoice_Success() {
        // Arrange
        MockHttpResponse mockResponse = new MockHttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"objData":{"strStatusCode":"S","strMessage":"Success","strData":"JVBERi0xLjQK"}}');
        Test.setMock(HttpCalloutMock.class, mockResponse);
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.downloadInvoice('INV123456');
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result.get('success'), 'Should return success');
        System.assertEquals('JVBERi0xLjQK', result.get('pdfData'), 'Should return PDF data');
    }
    
    /**
     *  Test downloadInvoice with SAP error response
     */
    @isTest
    static void testDownloadInvoice_SapError() {
        // Arrange
        MockHttpResponse mockResponse = new MockHttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"objData":{"strStatusCode":"E","strMessage":"Document not found","strData":""}}');
        Test.setMock(HttpCalloutMock.class, mockResponse);
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.downloadInvoice('INV123456');
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('success'), 'Should return failure');
        System.assertEquals('SAP Error: Document not found', result.get('message'), 'Should return SAP error message');
    }
    
    /**
     *  Test downloadInvoice with HTTP error
     */
    @isTest
    static void testDownloadInvoice_HttpError() {
        // Arrange
        MockHttpResponse mockResponse = new MockHttpResponse();
        mockResponse.setStatusCode(500);
        mockResponse.setBody('Internal Server Error');
        Test.setMock(HttpCalloutMock.class, mockResponse);

        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.downloadInvoice('INV123456');
        Test.stopTest();

        // Assert
        System.assertEquals(false, result.get('success'), 'Should return failure');
        // The message should contain Exception during Invoice download (JSON parsing error)
        String message = (String) result.get('message');
        System.assert(message != null, 'Message should not be null');
        System.assert(message.contains('Exception during Invoice download'), 'Should return exception message: ' + message);
        System.assert(message.contains('Unexpected character'), 'Should contain JSON parsing error: ' + message);
    }
    
    /**
     *  Test downloadInvoice with empty PDF data
     */
    @isTest
    static void testDownloadInvoice_EmptyPdfData() {
        // Arrange
        MockHttpResponse mockResponse = new MockHttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"objData":{"strStatusCode":"S","strMessage":"Success","strData":""}}');
        Test.setMock(HttpCalloutMock.class, mockResponse);
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.downloadInvoice('INV123456');
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('success'), 'Should return failure');
        System.assertEquals('Documento não encontrado', result.get('message'), 'Should return empty document message');
    }
    
    /**
     *  Test downloadInvoice with blank billing document number
     */
    @isTest
    static void testDownloadInvoice_BlankBillingDoc() {
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.downloadInvoice('');
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('success'), 'Should return failure');
        System.assertEquals('Billing Document Number is required', result.get('message'), 'Should return correct error message');
    }
    
    /**
     *  Test getInvoiceNumbersBulk with multiple shipment items
     */
    @isTest
    static void testGetInvoiceNumbersBulk_Success() {
        // Arrange - Create test data directly
        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Customer'
        );
        insert testAccount;

        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            PMC_CPQ_SAPOrderNumber__c = 'SAP123456'
        );
        insert testOrder;

        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;
        
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testOrderItem;
        
        Shipment testShipment = new Shipment(
            ShipToName = 'Test Ship To'
        );
        insert testShipment;
        
        ShipmentItem testShipmentItem = new ShipmentItem(
            ShipmentId = testShipment.Id,
            PMC_CPQ_OrderProduct__c = testOrderItem.Id,
            Quantity = 1
        );
        insert testShipmentItem;

        PMC_CPQ_Invoice__c testInvoice = new PMC_CPQ_Invoice__c(
            PMC_CPQ_InvoiceNumber__c = 'INV123456',
            PMC_CPQ_Order__c = testOrder.Id
        );
        insert testInvoice;

        PMC_CPQ_InvoiceItem__c testInvoiceItem = new PMC_CPQ_InvoiceItem__c(
            PMC_CPQ_Invoice__c = testInvoice.Id,
            PMC_CPQ_DeliveryItem__c = testShipmentItem.Id
        );
        insert testInvoiceItem;

        // List<String> shipmentItemIds = new List<String>{ testShipmentItem.Id }; // AJUSTAR POSTERIORMENTE PARA USAR SHIPMENT ITEM ID
        List<String> shipmentItemIds = new List<String>{ testOrder.Id };
        
        // Act
        Test.startTest();
        List<MosaicDirectDocumentService.InvoiceResult> results = 
            MosaicDirectDocumentService.getInvoiceNumbersBulk(shipmentItemIds);
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, results.size(), 'Should return result for each shipment item');
        System.assertEquals(true, results[0].success, 'Should return success for valid shipment items');
        System.assertEquals('INV123456', results[0].invoiceNumber, 'Should return correct invoice number');
        System.assertEquals('SAP123456', results[0].orderNumber, 'Should return correct order number');
    }
    
    /**
     *  Test getInvoiceNumbersBulk with empty list
     */
    @isTest
    static void testGetInvoiceNumbersBulk_EmptyList() {
        // Act
        Test.startTest();
        List<MosaicDirectDocumentService.InvoiceResult> results = 
            MosaicDirectDocumentService.getInvoiceNumbersBulk(new List<String>());
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, results.size(), 'Should return empty list for empty input');
    }
    
    /**
     *  Test getInvoiceNumbersBulk with null input
     */
    @isTest
    static void testGetInvoiceNumbersBulk_NullInput() {
        // Act
        Test.startTest();
        List<MosaicDirectDocumentService.InvoiceResult> results = 
            MosaicDirectDocumentService.getInvoiceNumbersBulk(null);
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, results.size(), 'Should return empty list for null input');
    }
    
    /**
     *  Test getDocumentInfo with valid ShipmentItem ID
     */
    @isTest
    static void testGetDocumentInfo_Success() {
        String FPDrecordTypeId = Schema.SObjectType.Shipment
            .getRecordTypeInfosByName()
            .get('FPD Delivery')
            .getRecordTypeId();

        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Customer'
        );
        insert testAccount;
        
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert testOrder;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product - A1',
            IsActive = true
        );
        insert testProduct;
        
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testOrderItem;

        Shipment testShipment = new Shipment(
            ShipToName = 'Test Ship To',
            RecordTypeId = FPDrecordTypeId,
            PMC_CPQ_Order__c = testOrder.Id,
            Status = 'Completed',
            PMC_CPQ_DeliveryStatus__c = 'Completely Shipped'
        );
        insert testShipment;

        ShipmentItem testShipmentItem = new ShipmentItem(
            ShipmentId = testShipment.Id,
            PMC_CPQ_OrderProduct__c = testOrderItem.Id,
            Quantity = 1,
            PMC_CPQ_DeliveryItemID__c = '123_ABC'
        );
        insert testShipmentItem;

        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.getDocumentInfo(testShipmentItem.Id);
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result.get('success'), 'Should return success');
        // Extract delivery number from DeliveryItemID (part before underscore) as done in the service method
        String expectedDeliveryNumber = '123_ABC'.contains('_') ?
            '123_ABC'.substringBefore('_') : '123_ABC';
        System.assertEquals(expectedDeliveryNumber, result.get('deliveryNumber'), 'Should return correct delivery number');
        System.assertEquals('123_ABC', result.get('itemNumber'), 'Should return correct item number');
    }
    
    /**
     *  Test getDocumentInfo with blank ShipmentItem ID
     */
    @isTest
    static void testGetDocumentInfo_BlankId() {
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.getDocumentInfo('');
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('success'), 'Should return failure');
        System.assertEquals('ShipmentItem ID is required', result.get('message'), 'Should return correct error message');
    }
    
    /**
     *  Test getDocumentInfo with non-existent ShipmentItem ID
     */
    @isTest
    static void testGetDocumentInfo_NotFound() {
        // Arrange
        String fakeShipmentItemId = '0ob000000000000'; // Fake but valid ID format
        Account a1 = new Account(Name = 'Acme One');
        Account a2 = new Account(Name = 'Acme Two');
        insert new List<Account>{ a1, a2 };

        Contact con = new Contact(LastName = 'Portal Contact', AccountId = a1.Id);
        insert con;

        Id shareableProfileId = getShareableCommunityProfileId();
        User extUser = createCommunityUser(con, shareableProfileId);

        Boolean secondRelationOk = true;
        try {
        insert new AccountContactRelation(AccountId = a2.Id, ContactId = con.Id);
        } catch (Exception e) {
        secondRelationOk = false; // org pode não ter CTMA habilitado
        }

        // Act
        Test.startTest();
        System.runAs(extUser) {
            Map<String, Object> result = MosaicDirectDocumentService.getDocumentInfo(fakeShipmentItemId);
             // Assert
            System.assertEquals(false, result.get('success'), 'Should return failure');
            System.assertEquals('ShipmentItem not found', result.get('message'), 'Should return correct error message');
        }
        Test.stopTest();
    }

    /**
     *  Test getDocumentInfo when SAP Delivery ID is missing
     */
    @isTest
    static void testGetDocumentInfo_MissingSAPDeliveryID() {
        String FPDrecordTypeId = Schema.SObjectType.Shipment
            .getRecordTypeInfosByName()
            .get('FPD Delivery')
            .getRecordTypeId();

        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Customer'
        );
        insert testAccount;
        
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert testOrder;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product - A1',
            IsActive = true
        );
        insert testProduct;
        
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testOrderItem;

        Shipment testShipment = new Shipment(
            ShipToName = 'Test Ship To',
            RecordTypeId = FPDrecordTypeId,
            PMC_CPQ_Order__c = testOrder.Id,
            Status = 'Completed',
            PMC_CPQ_DeliveryStatus__c = 'Completely Shipped'
        );
        insert testShipment;

        ShipmentItem testShipmentItem = new ShipmentItem(
            ShipmentId = testShipment.Id,
            PMC_CPQ_OrderProduct__c = testOrderItem.Id,
            Quantity = 1
        );
        insert testShipmentItem;
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.getDocumentInfo(testShipmentItem.Id);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('success'), 'Should return failure');
        System.assertEquals('Delivery Item ID (PMC_CPQ_DeliveryItemID__c) is not populated', result.get('message'), 'Should return correct error message');
    }
    
    /**
     *  Test downloadBOL with mock HTTP response
     */
    @isTest
    static void testDownloadBOL_Success() {
        // Arrange
        MockHttpResponse mockResponse = new MockHttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"objData":{"strStatusCode":"S","strMessage":"Success","strData":"JVBERi0xLjQK"}}');
        Test.setMock(HttpCalloutMock.class, mockResponse);
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.downloadBOL('DEL123456');
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result.get('success'), 'Should return success');
        System.assertEquals('JVBERi0xLjQK', result.get('pdfData'), 'Should return PDF data');
        System.assertEquals('BOL downloaded successfully', result.get('message'), 'Should return success message');
    }
    
    /**
     *  Test downloadBOL with SAP error response
     */
    @isTest
    static void testDownloadBOL_SapError() {
        // Arrange
        MockHttpResponse mockResponse = new MockHttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"objData":{"strStatusCode":"E","strMessage":"BOL not found","strData":""}}');
        Test.setMock(HttpCalloutMock.class, mockResponse);
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.downloadBOL('DEL123456');
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('success'), 'Should return failure');
        System.assertEquals('SAP Error: BOL not found', result.get('message'), 'Should return SAP error message');
    }
    
    /**
     *  Test downloadBOL with blank billing document number
     */
    @isTest
    static void testDownloadBOL_BlankBillingDoc() {
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.downloadBOL('');
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('success'), 'Should return failure');
        System.assertEquals('Billing Document Number (Delivery Number) is required', result.get('message'), 'Should return correct error message');
    }
    
    /**
     *  Test downloadBOL with HTTP error
     */
    @isTest
    static void testDownloadBOL_HttpError() {
        // Arrange
        MockHttpResponse mockResponse = new MockHttpResponse();
        mockResponse.setStatusCode(500);
        mockResponse.setBody('Internal Server Error');
        Test.setMock(HttpCalloutMock.class, mockResponse);
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.downloadBOL('DEL123456');
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('success'), 'Should return failure');
        String message = (String) result.get('message');
        System.assert(message.contains('Exception during BOL download'), 'Should return exception message: ' + message);
    }
    
    /**
     *  Test downloadBOL with invalid response format
     */
    @isTest
    static void testDownloadBOL_InvalidResponse() {
        // Arrange
        MockHttpResponse mockResponse = new MockHttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"objData":null}'); // null objData
        Test.setMock(HttpCalloutMock.class, mockResponse);
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.downloadBOL('DEL123456');
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('success'), 'Should return failure');
        // The null objData will cause a null pointer exception, which gets caught as Exception
        String message = (String) result.get('message');
        System.assert(message.contains('Exception during BOL download'), 'Should return exception message: ' + message);
    }
    
    /**
     *  Test downloadBOL with empty PDF data
     */
    @isTest
    static void testDownloadBOL_EmptyPdfData() {
        // Arrange
        MockHttpResponse mockResponse = new MockHttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"objData":{"strStatusCode":"S","strMessage":"Success","strData":""}}');
        Test.setMock(HttpCalloutMock.class, mockResponse);
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.downloadBOL('DEL123456');
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('success'), 'Should return failure');
        System.assertEquals('BOL documento não encontrado', result.get('message'), 'Should return empty document message');
    }
    
    /**
     *  Test downloadCOA with mock HTTP response
     */
    @isTest
    static void testDownloadCOA_Success() {
        // Arrange
        MockHttpResponse mockResponse = new MockHttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"objData":{"strStatusCode":"S","strMessage":"Success","strData":"JVBERi0xLjQK"}}');
        Test.setMock(HttpCalloutMock.class, mockResponse);
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.downloadCOA('DEL123456', 'ITEM001');
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result.get('success'), 'Should return success');
        System.assertEquals('JVBERi0xLjQK', result.get('pdfData'), 'Should return PDF data');
        System.assertEquals('COA downloaded successfully', result.get('message'), 'Should return success message');
    }
    
    /**
     *  Test downloadCOA with blank parameters
     */
    @isTest
    static void testDownloadCOA_BlankParams() {
        // Act - Test both scenarios within a single Test.startTest/stopTest block
        Test.startTest();
        Map<String, Object> result1 = MosaicDirectDocumentService.downloadCOA('', 'ITEM001');
        Map<String, Object> result2 = MosaicDirectDocumentService.downloadCOA('DEL123456', '');
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result1.get('success'), 'Should return failure for blank billing doc');
        System.assertEquals('Billing Document Number (Delivery Number) is required', result1.get('message'), 'Should return correct error message');
        
        System.assertEquals(false, result2.get('success'), 'Should return failure for blank item number');
        System.assertEquals('Item Number is required', result2.get('message'), 'Should return correct error message');
    }
    
    /**
     *  Test downloadCOA with HTTP error
     */
    @isTest
    static void testDownloadCOA_HttpError() {
        // Arrange
        MockHttpResponse mockResponse = new MockHttpResponse();
        mockResponse.setStatusCode(500);
        mockResponse.setBody('Internal Server Error');
        Test.setMock(HttpCalloutMock.class, mockResponse);
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.downloadCOA('DEL123456', 'ITEM001');
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('success'), 'Should return failure');
        String message = (String) result.get('message');
        System.assert(message.contains('Exception during COA download'), 'Should return exception message: ' + message);
    }
    
    /**
     *  Test downloadCOA with SAP error response
     */
    @isTest
    static void testDownloadCOA_SapError() {
        // Arrange
        MockHttpResponse mockResponse = new MockHttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"objData":{"strStatusCode":"E","strMessage":"COA not found","strData":""}}');
        Test.setMock(HttpCalloutMock.class, mockResponse);
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.downloadCOA('DEL123456', 'ITEM001');
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('success'), 'Should return failure');
        System.assertEquals('SAP Error: COA not found', result.get('message'), 'Should return SAP error message');
    }
    
    /**
     *  Test downloadCOA with empty PDF data
     */
    @isTest
    static void testDownloadCOA_EmptyPdfData() {
        // Arrange
        MockHttpResponse mockResponse = new MockHttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"objData":{"strStatusCode":"S","strMessage":"Success","strData":""}}');
        Test.setMock(HttpCalloutMock.class, mockResponse);
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.downloadCOA('DEL123456', 'ITEM001');
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('success'), 'Should return failure');
        System.assertEquals('COA documento não encontrado', result.get('message'), 'Should return empty document message');
    }

    /**
     *  Test downloadCOA with item number processing (underscore extraction)
     */
    @isTest
    static void testDownloadCOA_ItemNumberProcessing() {
        // Arrange
        MockHttpResponse mockResponse = new MockHttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"objData":{"strStatusCode":"S","strMessage":"Success","strData":"JVBERi0xLjQK"}}');
        Test.setMock(HttpCalloutMock.class, mockResponse);

        // Act
        Test.startTest();
        // Test with underscore in item number - should extract only the part after underscore
        Map<String, Object> result = MosaicDirectDocumentService.downloadCOA('DEL123456', '85594085_000001');
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.get('success'), 'Should return success');
        System.assertEquals('JVBERi0xLjQK', result.get('pdfData'), 'Should return PDF data');
        System.assertEquals('COA downloaded successfully', result.get('message'), 'Should return success message');
    }

    /**
     * Test downloadBOL error scenarios: invalid response format and HTTP error without JSON parsing
    */
    @isTest
    static void testDownloadErrors() {
        MockHttpResponse mockInvalidFormat = new MockHttpResponse();
        mockInvalidFormat.setStatusCode(500);
        mockInvalidFormat.setBody('{"objData": null}');
        Test.setMock(HttpCalloutMock.class, mockInvalidFormat);

        Test.startTest();
        Map<String, Object> resultInvalid = MosaicDirectDocumentService.downloadBOL('DEL123456');

        System.assertEquals(false, resultInvalid.get('success'), 'Should return failure for invalid format');

        MockHttpResponse mockHttpError = new MockHttpResponse();
        mockHttpError.setStatusCode(404);
        mockHttpError.setBody('Not Found');
        Test.setMock(HttpCalloutMock.class, mockHttpError);

        Map<String, Object> resultHttpError1 = MosaicDirectDocumentService.downloadBOL('DEL123456');
        System.assertEquals(false, resultHttpError1.get('success'), 'Should return failure for HTTP error');

        MockHttpResponse mockHttpError2 = new MockHttpResponse();
        mockHttpError2.setStatusCode(404);
        Test.setMock(HttpCalloutMock.class, mockHttpError2);

        Map<String, Object> resultHttpError2 = MosaicDirectDocumentService.downloadCOA('DEL123456', 'DEL123456');
        System.assertEquals(false, resultHttpError2.get('success'), 'Should return failure for HTTP error');

        Map<String, Object> resultHttpError3 = MosaicDirectDocumentService.downloadInvoice('DEL123456');
        System.assertEquals(false, resultHttpError3.get('success'), 'Should return failure for HTTP error');

        Test.stopTest();
    }

    /**
     *  Test item number processing functionality
     */
    @isTest
    static void testProcessItemNumber() {
        // Test with underscore - should extract part after last underscore
        String result1 = MosaicDirectDocumentService.processItemNumber('85594085_000001');
        System.assertEquals('000001', result1, 'Should extract part after underscore');

        // Test with multiple underscores - should extract after last one
        String result2 = MosaicDirectDocumentService.processItemNumber('123_456_789');
        System.assertEquals('789', result2, 'Should extract part after last underscore');

        // Test without underscore - should return original
        String result3 = MosaicDirectDocumentService.processItemNumber('ITEM001');
        System.assertEquals('ITEM001', result3, 'Should return original if no underscore');

        // Test empty/null - should return original
        String result4 = MosaicDirectDocumentService.processItemNumber('');
        System.assertEquals('', result4, 'Should return empty string');
    }

    /**
     *  Test downloadAllDocuments with mock responses
     */
    @isTest
    static void testDownloadAllDocuments_Success() {
        // Arrange - Create test data
        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Customer'
        );
        insert testAccount;
        
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            PMC_CPQ_SAPOrderNumber__c = 'SAP123456'
        );
        insert testOrder;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;
        
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testOrderItem;
        
        Shipment testShipment = new Shipment(
            ShipToName = 'Test Ship To'
        );
        insert testShipment;
        
        ShipmentItem testShipmentItem = new ShipmentItem(
            ShipmentId = testShipment.Id,
            PMC_CPQ_OrderProduct__c = testOrderItem.Id,
            Quantity = 1
        );
        insert testShipmentItem;
        
        PMC_CPQ_Invoice__c testInvoice = new PMC_CPQ_Invoice__c(
            PMC_CPQ_InvoiceNumber__c = 'INV123456'
        );
        insert testInvoice;
        
        PMC_CPQ_InvoiceItem__c testInvoiceItem = new PMC_CPQ_InvoiceItem__c(
            PMC_CPQ_Invoice__c = testInvoice.Id,
            PMC_CPQ_DeliveryItem__c = testShipmentItem.Id
        );
        insert testInvoiceItem;
        
        // Mock successful HTTP response
        MockHttpResponse mockResponse = new MockHttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"objData":{"strStatusCode":"S","strMessage":"Success","strData":"JVBERi0xLjQK"}}');
        Test.setMock(HttpCalloutMock.class, mockResponse);
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.downloadAllDocuments(null, testShipmentItem.Id);
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result.get('success'), 'Should return overall success');
        System.assertEquals(3, result.get('totalDocuments'), 'Should track total documents');
        System.assertEquals(1, result.get('successfulDownloads'), 'Should track successful downloads');
        
        // Check invoice result
        Map<String, Object> invoiceResult = (Map<String, Object>) result.get('invoiceResult');
        System.assertEquals(true, invoiceResult.get('success'), 'Invoice should succeed');
    }
    
    /**
     *  Test downloadAllDocuments with blank ShipmentItem ID
     */
    @isTest
    static void testDownloadAllDocuments_BlankShipmentItemId() {
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.downloadAllDocuments('', null);
        Test.stopTest();

        // Assert
        System.assertEquals(false, result.get('success'), 'Should return failure');
        System.assertEquals(0, result.get('successfulDownloads'), 'Should have no successful downloads');

        Map<String, Object> invoiceResult = (Map<String, Object>) result.get('invoiceResult');
        System.assertEquals(false, invoiceResult.get('success'), 'Invoice should fail');
        System.assertEquals('Shipment Item ID not provided', invoiceResult.get('message'), 'Should return correct error message');
    }
    
    /**
     *  Test checkCOARestriction with Sulfuric Acid + Rail
     */
    @isTest
    static void testCheckCOARestriction_Restricted() {
        // Arrange - Create test data with Sulfuric Acid + Rail
        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Customer'
        );
        insert testAccount;
        
        Product2 sulfuricAcidProduct = new Product2(
            Name = 'Sulfuric Acid',
            PMC_CPQ_SAPProductCode__c = '2000002',
            IsActive = true
        );
        insert sulfuricAcidProduct;
        
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert testOrder;
        
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = sulfuricAcidProduct.Id,
            Quantity = 1,
            UnitPrice = 100,
            PMC_CPQ_ModeofTransportation__c = 'Rail'
        );
        insert testOrderItem;
        
        Shipment testShipment = new Shipment(
            ShipToName = 'Test Ship To'
        );
        insert testShipment;
        
        ShipmentItem testShipmentItem = new ShipmentItem(
            ShipmentId = testShipment.Id,
            PMC_CPQ_OrderProduct__c = testOrderItem.Id,
            Quantity = 1
        );
        insert testShipmentItem;
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.checkCOARestriction(testShipmentItem.Id);
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result.get('isRestricted'), 'Should be restricted for Sulfuric Acid + Rail');
        String message = (String) result.get('message');
        System.assert(message.contains('Sulfuric Acid'), 'Message should mention Sulfuric Acid');
        System.assert(message.contains('Rail'), 'Message should mention Rail');
        System.assert(message.contains('CoA is not available'), 'Message should mention CoA restriction');
    }
    
    /**
     *  Test checkCOARestriction with non-restricted product
     */
    @isTest
    static void testCheckCOARestriction_NotRestricted() {
        // Arrange - Create test data with different product
        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Customer'
        );
        insert testAccount;
        
        Product2 otherProduct = new Product2(
            Name = 'Other Product',
            PMC_CPQ_SAPProductCode__c = '1000001',
            IsActive = true
        );
        insert otherProduct;
        
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert testOrder;
        
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = otherProduct.Id,
            Quantity = 1,
            UnitPrice = 100,
            PMC_CPQ_ModeofTransportation__c = 'Rail'
        );
        insert testOrderItem;
        
        Shipment testShipment = new Shipment(
            ShipToName = 'Test Ship To'
        );
        insert testShipment;
        
        ShipmentItem testShipmentItem = new ShipmentItem(
            ShipmentId = testShipment.Id,
            PMC_CPQ_OrderProduct__c = testOrderItem.Id,
            Quantity = 1
        );
        insert testShipmentItem;
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.checkCOARestriction(testShipmentItem.Id);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('isRestricted'), 'Should not be restricted for other products');
        System.assertEquals('', result.get('message'), 'Message should be empty for non-restricted');
    }
    
    /**
     *  Test checkCOARestriction with blank ShipmentItem ID
     */
    @isTest
    static void testCheckCOARestriction_BlankId() {
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.checkCOARestriction('');
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('isRestricted'), 'Should not be restricted for blank ID');
        System.assertEquals('', result.get('message'), 'Message should be empty');
    }
    
    /**
     *  Test checkCOARestriction with non-existent ShipmentItem ID
     */
    @isTest
    static void testCheckCOARestriction_NotFound() {
        // Arrange
        String fakeShipmentItemId = '0ob000000000000'; // Fake but valid ID format
        
        // Act
        Test.startTest();
        Map<String, Object> result = MosaicDirectDocumentService.checkCOARestriction(fakeShipmentItemId);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.get('isRestricted'), 'Should not be restricted for non-existent ID (fail open)');
        System.assertEquals('', result.get('message'), 'Message should be empty');
    }
    
    /**
     *  Test wrapper classes constructors
     */
    @isTest
    static void testWrapperClasses() {
        // Test InvoiceResult constructors
        MosaicDirectDocumentService.InvoiceResult invoiceResult1 = 
            new MosaicDirectDocumentService.InvoiceResult();
        System.assertEquals(false, invoiceResult1.success, 'Default constructor should set success to false');
        
        MosaicDirectDocumentService.InvoiceResult invoiceResult2 = 
            new MosaicDirectDocumentService.InvoiceResult(true, 'Test message');
        System.assertEquals(true, invoiceResult2.success, 'Should set success to true');
        System.assertEquals('Test message', invoiceResult2.message, 'Should set message');
        
        // Test DocumentDownloadResult constructors
        MosaicDirectDocumentService.DocumentDownloadResult downloadResult1 = 
            new MosaicDirectDocumentService.DocumentDownloadResult();
        System.assertEquals(false, downloadResult1.success, 'Default constructor should set success to false');
        
        MosaicDirectDocumentService.DocumentDownloadResult downloadResult2 = 
            new MosaicDirectDocumentService.DocumentDownloadResult(true, 'Test message');
        System.assertEquals(true, downloadResult2.success, 'Should set success to true');
        System.assertEquals('Test message', downloadResult2.message, 'Should set message');
        
        // Test DocumentInfo constructor
        MosaicDirectDocumentService.DocumentInfo docInfo1 = 
            new MosaicDirectDocumentService.DocumentInfo();
        System.assertEquals(false, docInfo1.success, 'Default constructor should set success to false');
        
        MosaicDirectDocumentService.DocumentInfo docInfo2 = 
            new MosaicDirectDocumentService.DocumentInfo(true, 'Test message');
        System.assertEquals(true, docInfo2.success, 'Should set success to true');
        System.assertEquals('Test message', docInfo2.message, 'Should set message');
        
        // Test DownloadAllResult constructor
        MosaicDirectDocumentService.DownloadAllResult downloadAllResult = 
            new MosaicDirectDocumentService.DownloadAllResult();
        System.assertEquals(false, downloadAllResult.success, 'Default constructor should set success to false');
        System.assertEquals(0, downloadAllResult.totalDocuments, 'Should initialize totalDocuments to 0');
        System.assertEquals(0, downloadAllResult.successfulDownloads, 'Should initialize successfulDownloads to 0');
    }

    private static Id getShareableCommunityProfileId() {
        // Prefer Customer Community Plus or Partner Community
        List<Profile> p = [
        SELECT Id, Name, UserLicense.Name
        FROM Profile
        WHERE UserLicense.Name IN ('Partner Community')
        ORDER BY Name
        LIMIT 1
        ];
        if (!p.isEmpty())
        return p[0].Id;
        return null; // fallback path if org doesn't have shareable licenses
    }
    private static Id getAnyCommunityProfileId() {
        List<Profile> p = [
        SELECT Id, Name, UserLicense.Name
        FROM Profile
        WHERE Name LIKE '%Community%' OR Name LIKE '%Portal%' OR Name LIKE '%Partner%'
        ORDER BY Name
        LIMIT 1
        ];
        System.assert(!p.isEmpty(), 'No community/portal profile found. Add one or adjust this query for your org.');
        return p[0].Id;
    }
    private static User createCommunityUser(Contact c, Id preferredProfileId) {
        Id profileIdToUse = preferredProfileId != null ? preferredProfileId : getAnyCommunityProfileId();
        User u = new User(
            ProfileId         = profileIdToUse,
            Username          = 'ext_'+System.now().getTime()+'@example.com',
            Email             = 'ext_'+System.now().getTime()+'@example.com',
            Alias             = 'extusr',
            TimeZoneSidKey    = 'America/Sao_Paulo',
            LocaleSidKey      = 'pt_BR',
            EmailEncodingKey  = 'UTF-8',
            LanguageLocaleKey = 'pt_BR',
            LastName          = 'Portal',
            CommunityNickname = 'nick' + String.valueOf(Crypto.getRandomInteger()),
            ContactId         = c.Id
        );
        insert u;
        return u;
    }
}