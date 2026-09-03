public without sharing class md_reportDocumentDownloadDAO {

    public static PMC_CPQ_Invoice__c getInvoiceById(Id invoiceId) {
        List<PMC_CPQ_Invoice__c> results = [
            SELECT Id, Nota_Fiscal_Number__c, PMC_CPQ_InvoiceNumber__c, PMC_CPQ_NFAccessKey__c
            FROM PMC_CPQ_Invoice__c
            WHERE Id = :invoiceId
            LIMIT 1
        ];
        return results.isEmpty() ? null : results[0];
    }

    public static PMC_CPQ_InvoiceItem__c getFirstInvoiceItemByInvoiceId(Id invoiceId) {
        List<PMC_CPQ_InvoiceItem__c> results = [
            SELECT Id, PMC_CPQ_SAPDeliveryID__c, PMC_CPQ_SAPDeliveryLineID__c,
                   PMC_CPQ_DeliveryItem__r.PMC_CPQ_DeliveryItemID__c
            FROM PMC_CPQ_InvoiceItem__c
            WHERE PMC_CPQ_Invoice__c = :invoiceId
            LIMIT 1
        ];
        return results.isEmpty() ? null : results[0];
    }

    public static List<PMC_CPQ_InvoiceItem__c> getInvoiceItemsByInvoiceId(Id invoiceId) {
        return [
            SELECT Id, PMC_CPQ_SAPDeliveryID__c, PMC_CPQ_SAPDeliveryLineID__c,
                   PMC_CPQ_DeliveryItem__r.PMC_CPQ_DeliveryItemID__c
            FROM PMC_CPQ_InvoiceItem__c
            WHERE PMC_CPQ_Invoice__c = :invoiceId
        ];
    }

    public static Set<Id> getZbqiApprovedInvoiceIds(Set<Id> invoiceIds) {
        Set<Id> approved = new Set<Id>();
        for (PMC_CPQ_InvoiceItem__c item : [
            SELECT PMC_CPQ_Invoice__c,
                   PMC_CPQ_DeliveryItem__r.Shipment.Insp_Lot_Usage_Decision__c
            FROM PMC_CPQ_InvoiceItem__c
            WHERE PMC_CPQ_Invoice__c IN :invoiceIds
              AND PMC_CPQ_DeliveryItem__r.Shipment.Insp_Lot_Usage_Decision__c = 'Approved'
        ]) {
            approved.add(item.PMC_CPQ_Invoice__c);
        }
        return approved;
    }
}