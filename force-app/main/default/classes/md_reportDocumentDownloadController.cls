global without sharing class md_reportDocumentDownloadController {
    @AuraEnabled
    global static Map<String, Object> getDocumentInfo(String shipmentItemId) {
        try {
            return md_reportDocumentDownloadService.getDocumentInfo(shipmentItemId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    global static Map<String, Object> downloadNFE(String shipmentItemId) {
        try {
            return md_reportDocumentDownloadService.downloadNFE(shipmentItemId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    global static Map<String, Object> downloadZBQI(String strBillingDocNumber, String strItemNumber) {
        try {
            return md_reportDocumentDownloadService.downloadZBQI(strBillingDocNumber, strItemNumber);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    global static Map<String, Object> downloadNfeXml(String shipmentItemId) {
        try {
            return md_reportDocumentDownloadService.downloadNfeXml(shipmentItemId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    global static Map<String, Object> downloadAllDocuments(String invoiceId) {
        try {
            return md_reportDocumentDownloadService.downloadAllDocuments(invoiceId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    global static List<String> getZbqiAvailability(List<String> invoiceIds) {
        try {
            Set<Id> idSet = new Set<Id>();
            for (String id : invoiceIds) {
                if (String.isNotBlank(id)) idSet.add((Id) id);
            }
            Set<Id> approved = md_reportDocumentDownloadDAO.getZbqiApprovedInvoiceIds(idSet);
            List<String> result = new List<String>();
            for (Id id : approved) {
                result.add(String.valueOf(id));
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}