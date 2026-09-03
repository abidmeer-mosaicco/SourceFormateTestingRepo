public with sharing class md_reportDocumentDownloadService {

    @TestVisible
    static Boolean throwForTest = false;

    private static Map<String, Object> failResult(String message) {
        return new Map<String, Object>{ 'success' => false, 'message' => message };
    }

    private static Map<String, Object> extractPdfFromResponse(HttpResponse response, String docLabel, String notFoundMsg) {
        if (response == null || response.getStatusCode() != 200) {
            return failResult('Erro HTTP: ' + (response != null ? String.valueOf(response.getStatusCode()) : 'sem resposta'));
        }

        md_reportDocumentDownloadWrapper.PMC_DH_DocumentResponseWrapper resWrapper =
            (md_reportDocumentDownloadWrapper.PMC_DH_DocumentResponseWrapper) JSON.deserialize(
                response.getBody(), md_reportDocumentDownloadWrapper.PMC_DH_DocumentResponseWrapper.class
            );

        if (resWrapper == null || resWrapper.objData == null) return failResult('Formato de resposta inválido do SAP');
        if (resWrapper.objData.strStatusCode != 'S') return failResult('Erro SAP: ' + resWrapper.objData.strMessage);

        String pdfData = resWrapper.objData.strData;
        if (String.isBlank(pdfData)) return failResult(notFoundMsg);

        return new Map<String, Object>{
            'success' => true,
            'pdfData' => pdfData,
            'strKey'  => resWrapper.objData.strKey,
            'message' => docLabel + ' obtido com sucesso'
        };
    }

    private static md_reportDocumentDownloadWrapper.DocumentDownloadResult toDownloadResult(Map<String, Object> raw) {
        md_reportDocumentDownloadWrapper.DocumentDownloadResult r = new md_reportDocumentDownloadWrapper.DocumentDownloadResult();
        r.success = (Boolean) raw.get('success');
        r.message = (String)  raw.get('message');
        r.pdfData = (String)  raw.get('pdfData');
        return r;
    }

    public static Map<String, Object> getDocumentInfo(String invoiceId) {
        if (throwForTest) throw new IllegalArgumentException('Test exception');
        try {
            if (String.isBlank(invoiceId)) return failResult('ID da fatura é obrigatório');

            PMC_CPQ_InvoiceItem__c item = md_reportDocumentDownloadDAO.getFirstInvoiceItemByInvoiceId((Id) invoiceId);
            if (item == null || String.isBlank(item.PMC_CPQ_DeliveryItem__r.PMC_CPQ_DeliveryItemID__c)) {
                return failResult('ID de entrega SAP não encontrado para esta fatura');
            }

            List<String> deliveryInfo = item.PMC_CPQ_DeliveryItem__r.PMC_CPQ_DeliveryItemID__c.split('_');
            String deliveryNumber = deliveryInfo[0];
            String itemNumber = deliveryInfo[1];

            PMC_CPQ_Invoice__c invoice = md_reportDocumentDownloadDAO.getInvoiceById((Id) invoiceId);
            String invoiceNumber = '';
            if (invoice != null) {
                invoiceNumber = String.isNotBlank(invoice.Nota_Fiscal_Number__c)
                    ? invoice.Nota_Fiscal_Number__c
                    : invoice.PMC_CPQ_InvoiceNumber__c;
            }

            return new Map<String, Object>{
                'success'        => true,
                'deliveryNumber' => deliveryNumber,
                'itemNumber'     => itemNumber,
                'invoiceNumber'  => invoiceNumber,
                'shipmentItemId' => invoiceId,
                'message'        => 'Informações do documento obtidas com sucesso'
            };
        } catch (Exception e) {
            return failResult('Erro ao buscar informações do documento: ' + e.getMessage());
        }
    }

    public static Map<String, Object> downloadNFE(String invoiceId) {
        if (throwForTest) throw new IllegalArgumentException('Test exception');
        try {
            if (String.isBlank(invoiceId)) return failResult('ID da fatura é obrigatório');

            PMC_CPQ_Invoice__c invoice = md_reportDocumentDownloadDAO.getInvoiceById((Id) invoiceId);
            if (invoice == null) return failResult('Fatura não encontrada');

            String billingDocNumber = invoice.PMC_CPQ_InvoiceNumber__c;
            if (String.isBlank(billingDocNumber)) return failResult('Número da nota fiscal (PMC_CPQ_InvoiceNumber__c) não está preenchido');

            Map<String, Object> result = extractPdfFromResponse(
                md_reportDocumentApiService.getDoc('NFE', billingDocNumber, null),
                'NFE',
                'Documento NF de Venda não encontrado'
            );
            if ((Boolean) result.get('success')) {
                result.put('invoiceNumber', String.isNotBlank(invoice.Nota_Fiscal_Number__c)
                    ? invoice.Nota_Fiscal_Number__c
                    : billingDocNumber
                );
            }
            return result;
        } catch (Exception e) {
            return failResult('Erro ao obter NF de Venda: ' + e.getMessage());
        }
    }

    public static Map<String, Object> downloadZBQI(String strBillingDocNumber, String strItemNumber) {
        if (throwForTest) throw new IllegalArgumentException('Test exception');
        try {
            if (String.isBlank(strBillingDocNumber)) return failResult('Número do documento de faturamento é obrigatório');
            // if (String.isBlank(strItemNumber))       return failResult('Número do item é obrigatório');

            return extractPdfFromResponse(
                md_reportDocumentApiService.getDoc('ZBQI', strBillingDocNumber, strItemNumber),
                'ZBQI',
                'Laudo de Qualidade não encontrado'
            );
        } catch (Exception e) {
            return failResult('Erro ao obter Laudo de Qualidade: ' + e.getMessage());
        }
    }

    public static Map<String, Object> downloadNfeXml(String invoiceId) {
        if (throwForTest) throw new IllegalArgumentException('Test exception');
        try {
            if (String.isBlank(invoiceId)) return failResult('ID da fatura é obrigatório');

            PMC_CPQ_Invoice__c invoice = md_reportDocumentDownloadDAO.getInvoiceById((Id) invoiceId);
            if (invoice == null) return failResult('Fatura não encontrada');

            String accessKey = invoice.PMC_CPQ_NFAccessKey__c;
            if (String.isBlank(accessKey)) return failResult('Chave de acesso da NF-e (PMC_CPQ_NFAccessKey__c) não está preenchida');

            HttpResponse response = md_reportDocumentApiService.getNfeXmlDoc(accessKey);
            if (response == null) return failResult('Erro ao conectar com o serviço de XML da NF-e');

            if (response.getStatusCode() == 200) {
                String xmlData = response.getBody();
                if (String.isBlank(xmlData)) return failResult('XML da NF-e não encontrado');

                return new Map<String, Object>{
                    'success'       => true,
                    'xmlData'       => xmlData,
                    'invoiceNumber' => String.isNotBlank(invoice.Nota_Fiscal_Number__c) ? invoice.Nota_Fiscal_Number__c : invoice.PMC_CPQ_InvoiceNumber__c,
                    'message'       => 'XML da NF-e obtido com sucesso'
                };
            }

            return failResult(extractNfeXmlErrorMessage(response));
        } catch (Exception e) {
            return failResult('Erro ao obter XML da NF-e: ' + e.getMessage());
        }
    }

    private static String extractNfeXmlErrorMessage(HttpResponse response) {
        String defaultMessage = 'Erro HTTP: ' + response.getStatusCode();
        try {
            md_reportDocumentDownloadWrapper.NfeXmlErrorResponse errWrapper =
                (md_reportDocumentDownloadWrapper.NfeXmlErrorResponse) JSON.deserialize(
                    response.getBody(), md_reportDocumentDownloadWrapper.NfeXmlErrorResponse.class
                );
            return errWrapper != null && String.isNotBlank(errWrapper.message) ? errWrapper.message : defaultMessage;
        } catch (Exception parseEx) {
            return defaultMessage;
        }
    }

    public static Map<String, Object> downloadAllDocuments(String invoiceId) {
        if (throwForTest) throw new IllegalArgumentException('Test exception');
        Map<String, Object> result = new Map<String, Object>{
            'totalDocuments'      => 2,
            'successfulDownloads' => 0
        };
        try {
            if (String.isBlank(invoiceId)) {
                result.put('success', false);
                result.put('message', 'ID da fatura é obrigatório');
                return result;
            }

            Integer successfulDownloads = 0;

            md_reportDocumentDownloadWrapper.DocumentDownloadResult nfeResult = toDownloadResult(downloadNFE(invoiceId));
            result.put('nfeResult', nfeResult);
            if (nfeResult.success) successfulDownloads++;

            Map<String, Object> docInfo = getDocumentInfo(invoiceId);
            md_reportDocumentDownloadWrapper.DocumentDownloadResult zbqiResult;

            if ((Boolean) docInfo.get('success')) {
                zbqiResult = toDownloadResult(
                    downloadZBQI((String) docInfo.get('deliveryNumber'), (String) docInfo.get('itemNumber'))
                );
            } else {
                zbqiResult = toDownloadResult(failResult('Failed to get document info: ' + (String) docInfo.get('message')));
            }
            result.put('zbqiResult', zbqiResult);
            if (zbqiResult.success) successfulDownloads++;

            result.put('successfulDownloads', successfulDownloads);
            Boolean overallSuccess = successfulDownloads > 0;
            result.put('success', overallSuccess);
            result.put('message', overallSuccess
                ? String.format('Download concluído: {0} de {1} documentos obtidos com sucesso', new List<Object>{ successfulDownloads, 2 })
                : 'Não foi possível obter nenhum documento'
            );
        } catch (Exception e) {
            result.put('success', false);
            result.put('message', 'Erro ao realizar download: ' + e.getMessage());
        }
        return result;
    }
}