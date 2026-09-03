@IsTest
private class md_reportDocumentDownloadControllerTest {

    private class DocumentHttpMock implements HttpCalloutMock {
        private final Integer statusCode;
        private final String  body;

        DocumentHttpMock() {
            this(200, buildSapSuccessBody('FAKEPDFBASE64DATA=='));
        }

        DocumentHttpMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body       = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    private static String buildSapSuccessBody(String pdfData) {
        return JSON.serialize(new Map<String, Object>{
            'objData' => new Map<String, Object>{
                'strStatusCode' => 'S',
                'strMessage'    => 'OK',
                'strData'       => pdfData,
                'strKey'        => '0001234567'
            }
        });
    }

    private static String buildSapErrorBody(String sapMessage) {
        return JSON.serialize(new Map<String, Object>{
            'objData' => new Map<String, Object>{
                'strStatusCode' => 'E',
                'strMessage'    => sapMessage,
                'strData'       => null
            }
        });
    }

    private static PMC_CPQ_Invoice__c createInvoice(String invoiceNumber, String notaFiscalNumber) {
        PMC_CPQ_Invoice__c inv = new PMC_CPQ_Invoice__c(
            PMC_CPQ_InvoiceNumber__c = invoiceNumber,
            Nota_Fiscal_Number__c    = notaFiscalNumber,
            PMC_CPQ_Cancelled__c     = false
        );
        insert inv;
        return inv;
    }

    private static PMC_CPQ_Invoice__c createInvoiceWithAccessKey(String invoiceNumber, String notaFiscalNumber, String accessKey) {
        PMC_CPQ_Invoice__c inv = new PMC_CPQ_Invoice__c(
            PMC_CPQ_InvoiceNumber__c = invoiceNumber,
            Nota_Fiscal_Number__c    = notaFiscalNumber,
            PMC_CPQ_NFAccessKey__c   = accessKey,
            PMC_CPQ_Cancelled__c     = false
        );
        insert inv;
        return inv;
    }

    private static String buildNfeXmlErrorBody(String message) {
        return JSON.serialize(new Map<String, Object>{
            'timestamp' => 1783949104709L,
            'status'    => 400,
            'error'     => 'Bad Request',
            'exception' => 'InvalidNfeKeyException',
            'message'   => message,
            'path'      => '/storage'
        });
    }

    private static ShipmentItem createShipmentItem(String deliveryItemId) {
        Shipment shipment = new Shipment(
            ShipToName = 'Test Ship To',
            PMC_CPQ_DeliveryItemID__c = deliveryItemId
        );
        insert shipment;

        ShipmentItem item = new ShipmentItem(
            ShipmentId = shipment.Id,
            PMC_CPQ_DeliveryItemID__c = deliveryItemId,
            Quantity = 1
        );
        insert item;
        return item;
    }

    private static PMC_CPQ_InvoiceItem__c createInvoiceItem(Id invoiceId, String sapDeliveryId, String sapDeliveryLineId) {
        ShipmentItem shipItem = createShipmentItem(sapDeliveryId + '_' + sapDeliveryLineId);
        PMC_CPQ_InvoiceItem__c item = new PMC_CPQ_InvoiceItem__c(
            PMC_CPQ_Invoice__c             = invoiceId,
            PMC_CPQ_DeliveryItem__c        = shipItem.Id
        );
        insert item;
        return item;
    }

    // ─────────────────────────────────────────────────────────────────
    // DAO
    // ─────────────────────────────────────────────────────────────────

    @IsTest
    static void dao_getInvoiceById_returnsRecord() {
        PMC_CPQ_Invoice__c inv = createInvoice('9000001234', '9000001234');

        Test.startTest();
        PMC_CPQ_Invoice__c result = md_reportDocumentDownloadDAO.getInvoiceById(inv.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(inv.Id, result.Id);
        System.assertEquals('9000001234', result.PMC_CPQ_InvoiceNumber__c);
    }

    @IsTest
    static void dao_getInvoiceById_notFound_returnsNull() {
        PMC_CPQ_Invoice__c inv = createInvoice('1234', null);
        Id deletedId = inv.Id;
        delete inv;

        Test.startTest();
        PMC_CPQ_Invoice__c result = md_reportDocumentDownloadDAO.getInvoiceById(deletedId);
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @IsTest
    static void dao_getFirstInvoiceItemByInvoiceId_returnsRecord() {
        PMC_CPQ_Invoice__c inv = createInvoice('9000001234', null);
        createInvoiceItem(inv.Id, '4500001234', '000010');

        Test.startTest();
        PMC_CPQ_InvoiceItem__c result = md_reportDocumentDownloadDAO.getFirstInvoiceItemByInvoiceId(inv.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('4500001234_000010', result.PMC_CPQ_DeliveryItem__r.PMC_CPQ_DeliveryItemID__c);
    }

    // ─────────────────────────────────────────────────────────────────
    // getDocumentInfo
    // ─────────────────────────────────────────────────────────────────

    @IsTest
    static void getDocumentInfo_blankId_returnsFailure() {
        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.getDocumentInfo(null);
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assertEquals('ID da fatura é obrigatório', result.get('message'));
    }

    @IsTest
    static void getDocumentInfo_noInvoiceItem_returnsFailure() {
        PMC_CPQ_Invoice__c inv = createInvoice('9000001234', null);

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.getDocumentInfo(inv.Id);
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assert(((String) result.get('message')).contains('não encontrado'), 'Message should indicate delivery ID not found');
    }

    @IsTest
    static void getDocumentInfo_validInvoice_returnsDeliveryNumbers() {
        PMC_CPQ_Invoice__c inv = createInvoice('9000001234', null);
        createInvoiceItem(inv.Id, '4500001234', '000010');

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.getDocumentInfo(inv.Id);
        Test.stopTest();

        System.assertEquals(true, result.get('success'));
        System.assertEquals('4500001234', result.get('deliveryNumber'));
        System.assertEquals('000010',     result.get('itemNumber'));
        System.assertEquals('9000001234', result.get('invoiceNumber'));
    }

    @IsTest
    static void dao_getInvoiceItemsByInvoiceId_returnsRecords() {
        PMC_CPQ_Invoice__c inv = createInvoice('9000001234', null);
        createInvoiceItem(inv.Id, '4500001234', '000010');

        Test.startTest();
        List<PMC_CPQ_InvoiceItem__c> results = md_reportDocumentDownloadDAO.getInvoiceItemsByInvoiceId(inv.Id);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('4500001234_000010', results[0].PMC_CPQ_DeliveryItem__r.PMC_CPQ_DeliveryItemID__c);
    }

    // ─────────────────────────────────────────────────────────────────
    // downloadNFE
    // ─────────────────────────────────────────────────────────────────

    @IsTest
    static void downloadNFE_blankId_returnsFailure() {
        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadNFE(null);
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assertEquals('ID da fatura é obrigatório', result.get('message'));
    }

    @IsTest
    static void downloadNFE_invoiceNotFound_returnsFailure() {
        PMC_CPQ_Invoice__c inv = createInvoice('12345', null);
        Id deletedId = inv.Id;
        delete inv;

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadNFE(deletedId);
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assertEquals('Fatura não encontrada', result.get('message'));
    }

    @IsTest
    static void downloadNFE_blankInvoiceNumber_returnsFailure() {
        PMC_CPQ_Invoice__c inv = createInvoice('', null);

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadNFE(inv.Id);
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assert(((String) result.get('message')).contains('Número da nota fiscal'), 'Message should mention Invoice Number');
    }

    @IsTest
    static void downloadNFE_sapSuccess_returnsPdfAndInvoiceNumber() {
        PMC_CPQ_Invoice__c inv = createInvoice('9000001234', '9000001234');
        Test.setMock(HttpCalloutMock.class, new DocumentHttpMock());

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadNFE(inv.Id);
        Test.stopTest();

        System.assertEquals(true,                  result.get('success'));
        System.assertEquals('FAKEPDFBASE64DATA==',  result.get('pdfData'));
        System.assertNotEquals(null, result.get('invoiceNumber'));
        System.assert(((String) result.get('message')).contains('NFE'));
    }

    @IsTest
    static void downloadNFE_sapErrorStatus_returnsFailure() {
        PMC_CPQ_Invoice__c inv = createInvoice('9000001234', null);
        Test.setMock(HttpCalloutMock.class, new DocumentHttpMock(200, buildSapErrorBody('Document not found')));

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadNFE(inv.Id);
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assert(((String) result.get('message')).startsWith('Erro SAP:'));
    }

    @IsTest
    static void downloadNFE_httpError_returnsFailure() {
        PMC_CPQ_Invoice__c inv = createInvoice('9000001234', null);
        Test.setMock(HttpCalloutMock.class, new DocumentHttpMock(500, 'Internal Server Error'));

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadNFE(inv.Id);
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assert(((String) result.get('message')).contains('Erro HTTP: 500'));
    }

    @IsTest
    static void downloadNFE_sapEmptyPdf_returnsNotFound() {
        PMC_CPQ_Invoice__c inv = createInvoice('9000001234', null);
        Test.setMock(HttpCalloutMock.class, new DocumentHttpMock(200, buildSapSuccessBody('')));

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadNFE(inv.Id);
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assert(((String) result.get('message')).contains('não encontrado'));
    }

    // ─────────────────────────────────────────────────────────────────
    // downloadZBQI
    // ─────────────────────────────────────────────────────────────────

    @IsTest
    static void downloadZBQI_blankBillingDoc_returnsFailure() {
        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadZBQI(null, '000010');
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assertEquals('Número do documento de faturamento é obrigatório', result.get('message'));
    }

    @IsTest
    static void downloadZBQI_blankItemNumber_succeeds() {
        Test.setMock(HttpCalloutMock.class, new DocumentHttpMock());

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadZBQI('4500001234', null);
        Test.stopTest();

        System.assertEquals(true, result.get('success'));
    }

    @IsTest
    static void downloadZBQI_sapSuccess_returnsPdf() {
        Test.setMock(HttpCalloutMock.class, new DocumentHttpMock());

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadZBQI('4500001234', '000010');
        Test.stopTest();

        System.assertEquals(true,                  result.get('success'));
        System.assertEquals('FAKEPDFBASE64DATA==',  result.get('pdfData'));
        System.assert(((String) result.get('message')).contains('ZBQI'));
    }

    @IsTest
    static void downloadZBQI_sapErrorStatus_returnsFailure() {
        Test.setMock(HttpCalloutMock.class, new DocumentHttpMock(200, buildSapErrorBody('No ZBQI document')));

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadZBQI('4500001234', '000010');
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assert(((String) result.get('message')).startsWith('Erro SAP:'));
    }

    @IsTest
    static void downloadZBQI_httpError_returnsFailure() {
        Test.setMock(HttpCalloutMock.class, new DocumentHttpMock(503, 'Unavailable'));

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadZBQI('4500001234', '000010');
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assert(((String) result.get('message')).contains('Erro HTTP: 503'));
    }

    @IsTest
    static void downloadZBQI_sapEmptyPdf_returnsNotFound() {
        Test.setMock(HttpCalloutMock.class, new DocumentHttpMock(200, buildSapSuccessBody('')));

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadZBQI('4500001234', '000010');
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assert(((String) result.get('message')).contains('não encontrado'));
    }

    // ─────────────────────────────────────────────────────────────────
    // downloadNfeXml
    // ─────────────────────────────────────────────────────────────────

    @IsTest
    static void downloadNfeXml_blankId_returnsFailure() {
        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadNfeXml(null);
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assertEquals('ID da fatura é obrigatório', result.get('message'));
    }

    @IsTest
    static void downloadNfeXml_invoiceNotFound_returnsFailure() {
        PMC_CPQ_Invoice__c inv = createInvoice('12345', null);
        Id deletedId = inv.Id;
        delete inv;

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadNfeXml(deletedId);
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assertEquals('Fatura não encontrada', result.get('message'));
    }

    @IsTest
    static void downloadNfeXml_blankAccessKey_returnsFailure() {
        PMC_CPQ_Invoice__c inv = createInvoice('9000001234', '9000001234');

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadNfeXml(inv.Id);
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assert(((String) result.get('message')).contains('Chave de acesso'), 'Message should mention access key');
    }

    @IsTest
    static void downloadNfeXml_success_returnsXmlAndInvoiceNumber() {
        PMC_CPQ_Invoice__c inv = createInvoiceWithAccessKey('9000001234', '9000001234', '31260733931486001455550020016225561851746813');
        Test.setMock(HttpCalloutMock.class, new DocumentHttpMock(200, '<?xml version="1.0" encoding="UTF-8"?><nfeProc></nfeProc>'));

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadNfeXml(inv.Id);
        Test.stopTest();

        System.assertEquals(true, result.get('success'));
        System.assertEquals('<?xml version="1.0" encoding="UTF-8"?><nfeProc></nfeProc>', result.get('xmlData'));
        System.assertEquals('9000001234', result.get('invoiceNumber'));
    }

    @IsTest
    static void downloadNfeXml_emptyXmlBody_returnsNotFound() {
        PMC_CPQ_Invoice__c inv = createInvoiceWithAccessKey('9000001234', null, '31260733931486001455550020016225561851746813');
        Test.setMock(HttpCalloutMock.class, new DocumentHttpMock(200, ''));

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadNfeXml(inv.Id);
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assert(((String) result.get('message')).contains('não encontrado'));
    }

    @IsTest
    static void downloadNfeXml_structuredHttpError_returnsCpiMessage() {
        PMC_CPQ_Invoice__c inv = createInvoiceWithAccessKey('9000001234', null, '3126073393148600145555002001622556185174681');
        Test.setMock(HttpCalloutMock.class, new DocumentHttpMock(400, buildNfeXmlErrorBody('The NF-e key is invalid: 3126073393148600145555002001622556185174681')));

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadNfeXml(inv.Id);
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assertEquals('The NF-e key is invalid: 3126073393148600145555002001622556185174681', result.get('message'));
    }

    @IsTest
    static void downloadNfeXml_unparseableHttpError_returnsGenericMessage() {
        PMC_CPQ_Invoice__c inv = createInvoiceWithAccessKey('9000001234', null, '31260733931486001455550020016225561851746813');
        Test.setMock(HttpCalloutMock.class, new DocumentHttpMock(500, 'Internal Server Error'));

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadNfeXml(inv.Id);
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assert(((String) result.get('message')).contains('Erro HTTP: 500'));
    }

    @IsTest
    static void downloadNfeXml_serviceThrows_rethrowsAura() {
        md_reportDocumentDownloadService.throwForTest = true;
        Boolean threw = false;
        try {
            Test.startTest();
            md_reportDocumentDownloadController.downloadNfeXml('someId');
            Test.stopTest();
        } catch (AuraHandledException e) {
            threw = true;
        } finally {
            md_reportDocumentDownloadService.throwForTest = false;
        }
        System.assertEquals(true, threw, 'Expected AuraHandledException');
    }

    // ─────────────────────────────────────────────────────────────────
    // downloadAllDocuments
    // ─────────────────────────────────────────────────────────────────

    @IsTest
    static void downloadAllDocuments_blankId_returnsFailure() {
        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadAllDocuments(null);
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assertEquals(0, result.get('successfulDownloads'));
    }

    @IsTest
    static void downloadAllDocuments_bothSucceed_counts2of2() {
        PMC_CPQ_Invoice__c inv = createInvoice('9000001234', '9000001234');
        createInvoiceItem(inv.Id, '4500001234', '000010');
        Test.setMock(HttpCalloutMock.class, new DocumentHttpMock());

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadAllDocuments(inv.Id);
        Test.stopTest();

        System.assertEquals(true, result.get('success'));
        System.assertEquals(2,    result.get('successfulDownloads'));
        System.assert(((String) result.get('message')).contains('2 de 2'));
    }

    @IsTest
    static void downloadAllDocuments_bothSapError_returnsOverallFailure() {
        PMC_CPQ_Invoice__c inv = createInvoice('9000001234', null);
        createInvoiceItem(inv.Id, '4500001234', '000010');
        Test.setMock(HttpCalloutMock.class, new DocumentHttpMock(200, buildSapErrorBody('SAP unavailable')));

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadAllDocuments(inv.Id);
        Test.stopTest();

        System.assertEquals(false, result.get('success'));
        System.assertEquals(0,     result.get('successfulDownloads'));
    }

    @IsTest
    static void downloadAllDocuments_nfeFailsZbqiSucceeds_counts1of2() {
        PMC_CPQ_Invoice__c inv = createInvoice('', null);
        createInvoiceItem(inv.Id, '4500001234', '000010');
        Test.setMock(HttpCalloutMock.class, new DocumentHttpMock());

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadAllDocuments(inv.Id);
        Test.stopTest();

        System.assertEquals(true, result.get('success'));
        System.assertEquals(1,    result.get('successfulDownloads'));

        md_reportDocumentDownloadWrapper.DocumentDownloadResult nfe  = (md_reportDocumentDownloadWrapper.DocumentDownloadResult) result.get('nfeResult');
        md_reportDocumentDownloadWrapper.DocumentDownloadResult zbqi = (md_reportDocumentDownloadWrapper.DocumentDownloadResult) result.get('zbqiResult');
        System.assertEquals(false, nfe.success,  'NFE should fail — no invoice number');
        System.assertEquals(true,  zbqi.success, 'ZBQI should succeed');
    }

    @IsTest
    static void downloadAllDocuments_nfeSucceedsZbqiFails_counts1of2() {
        PMC_CPQ_Invoice__c inv = createInvoice('9000001234', null);
        Test.setMock(HttpCalloutMock.class, new DocumentHttpMock());

        Test.startTest();
        Map<String, Object> result = md_reportDocumentDownloadController.downloadAllDocuments(inv.Id);
        Test.stopTest();

        System.assertEquals(true, result.get('success'));
        System.assertEquals(1,    result.get('successfulDownloads'));

        md_reportDocumentDownloadWrapper.DocumentDownloadResult nfe  = (md_reportDocumentDownloadWrapper.DocumentDownloadResult) result.get('nfeResult');
        md_reportDocumentDownloadWrapper.DocumentDownloadResult zbqi = (md_reportDocumentDownloadWrapper.DocumentDownloadResult) result.get('zbqiResult');
        System.assertEquals(true,  nfe.success,  'NFE should succeed');
        System.assertEquals(false, zbqi.success, 'ZBQI should fail — no delivery item');
    }

    // ─────────────────────────────────────────────────────────────────
    // Controller exception paths (covers catch branches)
    // ─────────────────────────────────────────────────────────────────

    @IsTest
    static void getDocumentInfo_serviceThrows_rethrowsAura() {
        md_reportDocumentDownloadService.throwForTest = true;
        Boolean threw = false;
        try {
            Test.startTest();
            md_reportDocumentDownloadController.getDocumentInfo('someId');
            Test.stopTest();
        } catch (AuraHandledException e) {
            threw = true;
        } finally {
            md_reportDocumentDownloadService.throwForTest = false;
        }
        System.assertEquals(true, threw, 'Expected AuraHandledException');
    }

    @IsTest
    static void downloadNFE_serviceThrows_rethrowsAura() {
        md_reportDocumentDownloadService.throwForTest = true;
        Boolean threw = false;
        try {
            Test.startTest();
            md_reportDocumentDownloadController.downloadNFE('someId');
            Test.stopTest();
        } catch (AuraHandledException e) {
            threw = true;
        } finally {
            md_reportDocumentDownloadService.throwForTest = false;
        }
        System.assertEquals(true, threw, 'Expected AuraHandledException');
    }

    @IsTest
    static void downloadZBQI_serviceThrows_rethrowsAura() {
        md_reportDocumentDownloadService.throwForTest = true;
        Boolean threw = false;
        try {
            Test.startTest();
            md_reportDocumentDownloadController.downloadZBQI('4500001234', '000010');
            Test.stopTest();
        } catch (AuraHandledException e) {
            threw = true;
        } finally {
            md_reportDocumentDownloadService.throwForTest = false;
        }
        System.assertEquals(true, threw, 'Expected AuraHandledException');
    }

    @IsTest
    static void downloadAllDocuments_serviceThrows_rethrowsAura() {
        md_reportDocumentDownloadService.throwForTest = true;
        Boolean threw = false;
        try {
            Test.startTest();
            md_reportDocumentDownloadController.downloadAllDocuments('someId');
            Test.stopTest();
        } catch (AuraHandledException e) {
            threw = true;
        } finally {
            md_reportDocumentDownloadService.throwForTest = false;
        }
        System.assertEquals(true, threw, 'Expected AuraHandledException');
    }

    @IsTest
    static void getZbqiAvailability_validInvoiceApproved_returnsInvoiceId() {
        PMC_CPQ_Invoice__c inv = createInvoice('9000001234', null);
        PMC_CPQ_InvoiceItem__c invItem = createInvoiceItem(inv.Id, '4500001234', '000010');
        
        ShipmentItem shipItem = [SELECT ShipmentId FROM ShipmentItem WHERE Id = :invItem.PMC_CPQ_DeliveryItem__c];
        Shipment sh = new Shipment(Id = shipItem.ShipmentId, Insp_Lot_Usage_Decision__c = 'Approved');
        update sh;

        Test.startTest();
        List<String> result = md_reportDocumentDownloadController.getZbqiAvailability(new List<String>{ String.valueOf(inv.Id) });
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(String.valueOf(inv.Id), result[0]);
    }

    @IsTest
    static void getZbqiAvailability_validInvoiceNotApproved_returnsEmpty() {
        PMC_CPQ_Invoice__c inv = createInvoice('9000001234', null);
        PMC_CPQ_InvoiceItem__c invItem = createInvoiceItem(inv.Id, '4500001234', '000010');
        
        ShipmentItem shipItem = [SELECT ShipmentId FROM ShipmentItem WHERE Id = :invItem.PMC_CPQ_DeliveryItem__c];
        Shipment sh = new Shipment(Id = shipItem.ShipmentId, Insp_Lot_Usage_Decision__c = 'Rejected');
        update sh;

        Test.startTest();
        List<String> result = md_reportDocumentDownloadController.getZbqiAvailability(new List<String>{ String.valueOf(inv.Id) });
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @IsTest
    static void getZbqiAvailability_exceptionThrown_rethrowsAura() {
        Boolean threw = false;
        try {
            Test.startTest();
            md_reportDocumentDownloadController.getZbqiAvailability(new List<String>{ 'invalid_id' });
            Test.stopTest();
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assertEquals(true, threw);
    }
}