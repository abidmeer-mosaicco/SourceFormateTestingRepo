@IsTest
public class PMC_DH_DocumentListViewHelperTest {
    
    @TestSetup
    static void setupTestData() {
        
        
        // Create test invoice
        PMC_CPQ_Invoice__c invoice = new PMC_CPQ_Invoice__c(
            PMC_DH_SAPInvoiceCreatedDate__c = Date.today().addDays(-30)
        );
        insert invoice;
        
        // Create test invoice item
        PMC_CPQ_InvoiceItem__c invoiceItem = new PMC_CPQ_InvoiceItem__c(
            PMC_CPQ_Invoice__c = invoice.Id
        );
        insert invoiceItem;
        
        // Create test shipment
        Shipment shipment = new Shipment(
            PMC_DH_SAPDeliveryCreatedDate__c = Date.today().addDays(-15),
            ShipToName = 'Test Ship To Name'
        );
        insert shipment;
        
        // Create test shipment item
        ShipmentItem shipmentItem = new ShipmentItem(
            ShipmentId = shipment.Id,
            Quantity = 10
        );
        insert shipmentItem;
    }
    
    
    @IsTest
    static void testGetDocumentSearchQuery() {
        PMC_DH_DocumentListViewHelper.PMC_DH_DocumentSearchParameterWrapper searchParams =
            new PMC_DH_DocumentListViewHelper.PMC_DH_DocumentSearchParameterWrapper();
        searchParams.strSearchTerm = 'INV-12345';
        searchParams.strSearchTerm = 'INV-12345 INV-54321';
        searchParams.datFromDate = Date.today().addMonths(-2);
        searchParams.datToDate = Date.today();
        
        Test.startTest();
         List<OrderItem> lstDocument = PMC_DH_DocumentListViewHelper.getDocumentSearchQuery(searchParams, '001XXXXXXXXXXXX'); // Mock Account Id
        Test.stopTest();
        
      //  System.assertNotEquals(null, query, 'The query should not be null.');
       // System.assert(query.contains('Invoice'), 'The query should include the Invoice filter.');
    }
    
    @IsTest
    static void testGetMapOfAllDocTypes() {
        // Create mock metadata
        Map<String, PMC_DH_DocumentType__mdt> mockMetadata = new Map<String, PMC_DH_DocumentType__mdt>();
        
        PMC_DH_DocumentType__mdt docType = (PMC_DH_DocumentType__mdt)JSON.deserialize(
            JSON.serialize(new Map<String, Object>{
                'DeveloperName' => 'Invoice',
                    'Label' => 'Invoice',
                    'PMC_DH_Identifier__c' => 'InvoiceNumber',
                    'PMC_DH_DocumentCode__c' => 'INV'
                    }), PMC_DH_DocumentType__mdt.class
        );
        mockMetadata.put('Invoice', docType);
        
        Test.startTest();
        Map<String, String> mapDocTypes = PMC_DH_DocumentListViewHelper.getMapOfAllDocTypes(mockMetadata);
        Test.stopTest();
        
        System.assertEquals('Invoice', mapDocTypes.get('Invoice'), 'The map should contain the Invoice document type.');
    }
    
    @IsTest
    static void testGetDateFilters() {
        PMC_DH_DocumentListViewHelper.PMC_DH_DocumentSearchParameterWrapper searchParams =
            new PMC_DH_DocumentListViewHelper.PMC_DH_DocumentSearchParameterWrapper();
        searchParams.datFromDate = Date.today().addMonths(-3);
        searchParams.datToDate = Date.today();
        
        Test.startTest();
        Map<String, Date> dateFilters = PMC_DH_DocumentListViewHelper.getDateFilters(searchParams);
        Test.stopTest();
        
        System.assertEquals(searchParams.datFromDate, dateFilters.get('datFromDate'), 'From date should match.');
        System.assertEquals(searchParams.datToDate, dateFilters.get('datToDate'), 'To date should match.');
    }
    
    @IsTest
    static void testGetDocumentsByDocType() {
        List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper> docList = new List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper>();
        PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper docWrapper = new PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper();
        docWrapper.strDocumentType = 'Invoice';
        docList.add(docWrapper);
        
        PMC_DH_DocumentListViewHelper.PMC_DH_DocumentSearchParameterWrapper searchParams =
            new PMC_DH_DocumentListViewHelper.PMC_DH_DocumentSearchParameterWrapper();
        searchParams.strSearchTerm = 'Invoice';
        
        Test.startTest();
        List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper> filteredDocs =
            PMC_DH_DocumentListViewHelper.getDocumentsbyDocType(docList, searchParams);
        Test.stopTest();
        
        System.assertEquals(1, filteredDocs.size(), 'There should be one filtered document.');
    }
    
    @IsTest
    static void testGetDocTypeInfoWithInvoiceItem() {
        // Create mock metadata
        PMC_DH_DocumentType__mdt metadata = (PMC_DH_DocumentType__mdt)JSON.deserialize(
            JSON.serialize(new Map<String, Object>{
                'DeveloperName' => 'Invoice',
                    'Label' => 'Invoice',
                    'PMC_DH_Identifier__c' => 'InvoiceNumber',
                    'PMC_DH_DocumentCode__c' => 'INV'
                    }), PMC_DH_DocumentType__mdt.class
        );
        
        // Create and insert a test invoice
        PMC_CPQ_Invoice__c invoice = new PMC_CPQ_Invoice__c(
            PMC_DH_SAPInvoiceCreatedDate__c = Date.today().addDays(-30),
            PMC_CPQ_InvoiceNumber__c = 'INV-12345'
        );
        insert invoice;
        
     
          // Create test shipment
        Shipment shipment = new Shipment(
            PMC_DH_SAPDeliveryCreatedDate__c = Date.today().addDays(-15),
            ShipToName = 'Test Ship To Name',
            Insp_Lot_Usage_Decision__c='Approved'
        );
        insert shipment;
        
        // Create test shipment item
        ShipmentItem shipmentItem = new ShipmentItem(
            ShipmentId = shipment.Id,
            Quantity = 10
        );
        insert shipmentItem;
        // Create and insert a test invoice item linked to the invoice
        PMC_CPQ_InvoiceItem__c invoiceItem = new PMC_CPQ_InvoiceItem__c(
            PMC_CPQ_Invoice__c = invoice.Id, // Link invoice item to the invoice
            PMC_CPQ_DeliveryItem__c =shipmentItem.id
        );
        insert invoiceItem;
        // Query the invoice item to populate relationships
        invoiceItem = [SELECT Id, PMC_CPQ_Invoice__r.PMC_DH_SAPInvoiceCreatedDate__c, PMC_CPQ_DeliveryItem__r.Shipment.Insp_Lot_Usage_Decision__c,
                       PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c,PMC_CPQ_Invoice__r.Nota_Fiscal_Number__c ,PMC_CPQ_DeliveryItem__r.Shipment.PMC_CPQ_SAPDeliveryID__c,PMC_CPQ_DeliveryItem__r.PMC_CPQ_DeliveryItemID__c
                       FROM PMC_CPQ_InvoiceItem__c 
                       WHERE Id = :invoiceItem.Id];
        
        // Test the method
        Test.startTest();
        PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper result =
            PMC_DH_DocumentListViewHelper.getDocTypeInfo(metadata, invoiceItem);
        Test.stopTest();
        
     
    }
    
    @IsTest
    static void testGetDocTypeInfoWithShipmentItem() {
        // Mock metadata
        PMC_DH_DocumentType__mdt metadata = (PMC_DH_DocumentType__mdt)JSON.deserialize(
            JSON.serialize(new Map<String, Object>{
                'DeveloperName' => 'Shipment',
                    'Label' => 'Shipment',
                    'PMC_DH_Identifier__c' => 'DeliveryNumber;DeliveryItemNumber',
                    'PMC_DH_DocumentCode__c' => 'BOL'
                    }), PMC_DH_DocumentType__mdt.class
        );
        
        // Create and insert a test shipment with required fields
        Shipment shipment = new Shipment(
            PMC_CPQ_SAPDeliveryID__c = 'DEL-12345',
            PMC_DH_SAPDeliveryCreatedDate__c = Date.today().addDays(-15),
            ShipToName = 'Test Ship To Name' // Required field
        );
        insert shipment;
        
        // Create and insert a test shipment item linked to the shipment with required Quantity field
        ShipmentItem shipmentItem = new ShipmentItem(
            ShipmentId = shipment.Id,
            PMC_CPQ_DeliveryItemID__c = 'ITEM-56789',
            Quantity = 10 // Required field
        );
        insert shipmentItem;
        
        // Query the shipment item and include necessary related fields
        shipmentItem = [SELECT Id, 
                        PMC_CPQ_DeliveryItemID__c, 
                        Shipment.PMC_CPQ_SAPDeliveryID__c, 
                        Shipment.Insp_Lot_Usage_Decision__c,
                        Shipment.PMC_DH_SAPDeliveryCreatedDate__c, 
                        Shipment.ShipToName 
                        FROM ShipmentItem 
                        WHERE Id = :shipmentItem.Id];
        
        // Test the method
        Test.startTest();
        PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper result =
            PMC_DH_DocumentListViewHelper.getDocTypeInfo(metadata, shipmentItem);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'The DocIdentifierWrapper should not be null.');
        // System.assertEquals('DEL-12345', result.mapIdentifier.get('DeliveryNumber'), 
        //              'The delivery number should match.');
        // System.assertEquals('ITEM-56789', result.mapIdentifier.get('DeliveryItemNumber'), 
        // 'The delivery item number should match.');
    }
    
    @IsTest
    static void testgetIdentifierToDocTypeMap() {
        // Mock metadata
        PMC_DH_DocumentType__mdt metadata = (PMC_DH_DocumentType__mdt)JSON.deserialize(
            JSON.serialize(new Map<String, Object>{
                'DeveloperName' => 'Shipment',
                    'Label' => 'Shipment',
                    'PMC_DH_Identifier__c' => 'DeliveryNumber;DeliveryItemNumber',
                    'PMC_DH_DocumentCode__c' => 'COA'
                    }), PMC_DH_DocumentType__mdt.class
        );
        List<PMC_DH_DocumentType__mdt> mtd=new List<PMC_DH_DocumentType__mdt>();
        mtd.add(metadata);
       Map<String, List<String>> result= PMC_DH_DocumentListViewHelper.getIdentifierToDocTypeMap(mtd);
        
    }
    @IsTest
    static void testGetDocTypeInfoWithShipmentItem1() {
        // Mock metadata
        PMC_DH_DocumentType__mdt metadata = (PMC_DH_DocumentType__mdt)JSON.deserialize(
            JSON.serialize(new Map<String, Object>{
                'DeveloperName' => 'Shipment',
                    'Label' => 'Shipment',
                    'PMC_DH_Identifier__c' => 'DeliveryNumber;DeliveryItemNumber',
                    'PMC_DH_DocumentCode__c' => 'COA'
                    }), PMC_DH_DocumentType__mdt.class
        );
        
        // Create and insert a test shipment with required fields
        Shipment shipment = new Shipment(
            PMC_CPQ_SAPDeliveryID__c = 'DEL-12345',
            PMC_DH_SAPDeliveryCreatedDate__c = Date.today().addDays(-15),
            ShipToName = 'Test Ship To Name' // Required field
        );
        insert shipment;
        
        // Create and insert a test shipment item linked to the shipment with required Quantity field
        ShipmentItem shipmentItem = new ShipmentItem(
            ShipmentId = shipment.Id,
            PMC_CPQ_DeliveryItemID__c = 'ITEM-56789',
            Quantity = 10 // Required field
        );
        insert shipmentItem;
        
        // Query the shipment item and include necessary related fields
        shipmentItem = [SELECT Id, 
                        PMC_CPQ_DeliveryItemID__c, 
                        Shipment.PMC_CPQ_SAPDeliveryID__c, 
                        Shipment.Insp_Lot_Usage_Decision__c,
                        Shipment.PMC_DH_SAPDeliveryCreatedDate__c, 
                        Shipment.ShipToName 
                        FROM ShipmentItem 
                        WHERE Id = :shipmentItem.Id];
        
        // Test the method
        Test.startTest();
        PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper result =
            PMC_DH_DocumentListViewHelper.getDocTypeInfo(metadata, shipmentItem);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'The DocIdentifierWrapper should not be null.');
        // System.assertEquals('DEL-12345', result.mapIdentifier.get('DeliveryNumber'), 
        //              'The delivery number should match.');
        // System.assertEquals('ITEM-56789', result.mapIdentifier.get('DeliveryItemNumber'), 
        // 'The delivery item number should match.');
    }
    
    
    @IsTest
    static void testGetDocTypesWithSearchTerm() {
        // Arrange
        List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper> lstDocumentWrapper = new List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper>();
        
        PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper docType1 = new PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper();
        docType1.strDocumentType = 'Invoice';
        lstDocumentWrapper.add(docType1);
        
        PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper docType2 = new PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper();
        docType2.strDocumentType = 'BillOfLading';
        lstDocumentWrapper.add(docType2);
        
        PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper docType3 = new PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper();
        docType3.strDocumentType = 'CreditMemo';
        lstDocumentWrapper.add(docType3);
        
        PMC_DH_DocumentListViewHelper.PMC_DH_DocumentSearchParameterWrapper searchParams = 
            new PMC_DH_DocumentListViewHelper.PMC_DH_DocumentSearchParameterWrapper();
        searchParams.strSearchTerm = 'Invoice';
        
        // Act
        List<PMC_DH_PicklistWrapper> result = PMC_DH_DocumentListViewHelper.getDocTypes(lstDocumentWrapper, searchParams);
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(1, result.size(), 'Only one document type should match.');
        System.assertEquals('Invoice', result[0].label, 'The label of the result should match the search term.');
    }
    
    @IsTest
    static void testGetDocTypesWithoutSearchTerm() {
        // Arrange
        List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper> lstDocumentWrapper = new List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper>();
        
        PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper docType1 = new PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper();
        docType1.strDocumentType = 'Invoice';
        lstDocumentWrapper.add(docType1);
        
        PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper docType2 = new PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper();
        docType2.strDocumentType = 'BillOfLading';
        lstDocumentWrapper.add(docType2);
        
        PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper docType3 = new PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper();
        docType3.strDocumentType = 'CreditMemo';
        lstDocumentWrapper.add(docType3);
        
        PMC_DH_DocumentListViewHelper.PMC_DH_DocumentSearchParameterWrapper searchParams = 
            new PMC_DH_DocumentListViewHelper.PMC_DH_DocumentSearchParameterWrapper();
        searchParams.strSearchTerm = null;
        
        // Act
        List<PMC_DH_PicklistWrapper> result = PMC_DH_DocumentListViewHelper.getDocTypes(lstDocumentWrapper, searchParams);
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(3, result.size(), 'All document types should be returned when no search term is provided.');
    }
    
    @IsTest
    static void testGetDocTypesWithNonMatchingSearchTerm() {
        // Arrange
        List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper> lstDocumentWrapper = new List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper>();
        
        PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper docType1 = new PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper();
        docType1.strDocumentType = 'Invoice';
        lstDocumentWrapper.add(docType1);
        
        PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper docType2 = new PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper();
        docType2.strDocumentType = 'BillOfLading';
        lstDocumentWrapper.add(docType2);
        
        PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper docType3 = new PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper();
        docType3.strDocumentType = 'CreditMemo';
        lstDocumentWrapper.add(docType3);
        
        PMC_DH_DocumentListViewHelper.PMC_DH_DocumentSearchParameterWrapper searchParams = 
            new PMC_DH_DocumentListViewHelper.PMC_DH_DocumentSearchParameterWrapper();
        searchParams.strSearchTerm = 'NonExistentType';
        
        // Act
        List<PMC_DH_PicklistWrapper> result = PMC_DH_DocumentListViewHelper.getDocTypes(lstDocumentWrapper, searchParams);
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(3, result.size(), 'All document types should be returned when no match is found.');
    }
    @IsTest
    static void testGetMiddleMap() {
        Map<String, Map<String, List<PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper>>> mapIdentifierToInnerMap = new Map<String, Map<String, List<PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper>>>();
        Map<String, List<PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper>> mapIdentifierToList = new Map<String, List<PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper>>();
        
        PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper docWrapper = new PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper();
        docWrapper.strIdentifierType = 'IdentifierType';
        docWrapper.mapIdentifier = new Map<String, String>{'IdentifierType' => 'IdentifierValue'};
            
            Test.startTest();
        mapIdentifierToInnerMap = PMC_DH_DocumentListViewHelper.getMiddleMap(mapIdentifierToInnerMap, mapIdentifierToList, docWrapper);
        Test.stopTest();
        
        System.assertNotEquals(null, mapIdentifierToInnerMap, 'The mapIdentifierToInnerMap should not be null.');
        System.assertNotEquals(0, mapIdentifierToInnerMap.size(), 'The mapIdentifierToInnerMap should not be empty.');
    }
}