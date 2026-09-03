/**
* @File Name : InvoiceCasesController.cls
* @Description :GSMD-1449-Create Case from Invoice Record
* @Author :Azaam Ali
* @Last Modified By :Azaam Ali
* @Last Modified On : May 7, 2025
* @Modification Log :
*==============================================================================
* Ver | Date 		| Author 	| Modification
*==============================================================================
* 1.0 | May 7, 2025 |  Azaamali | Initial Version
* 2.0 | Aug 12, 2025 |  Nithin M | GSMD-2754: Auto Populate Case Fields When Opening Case from Invoice Object
**/

public class InvoiceCasesController {
    @AuraEnabled(cacheable=true)
    public static List<Case> getRelatedCases(Id invoiceId) {
        System.debug('In apex class!');
        List<Case> casesRetreived = [SELECT Id, CaseNumber, Status, Type, Contact.Name, PMC_SS_AtFaultParty__c, CreatedDate 
                FROM Case WHERE PMC_SS_Invoice__c = :invoiceId ORDER BY CreatedDate DESC];
        System.debug('casesRetreived-->' + casesRetreived);
        return casesRetreived;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getInvoiceDetails(Id invoiceId) {
        PMC_CPQ_Invoice__c inv = [SELECT Id,Name, PMC_CPQ_Order__r.AccountId, PMC_CPQ_Order__r.BillToContactId, PMC_CPQ_Order__c,PMC_CPQ_Order__r.PMC_CPQ_SAPOrderNumber__c,
                                  PMC_CPQ_SoldToAccount__c, PMC_CPQ_InvoiceNumber__c,PMC_CPQ_CustomerPONumber__c,PMC_CPQ_TotalInvoiceValue__c,PMC_CPQ_Delivery__r.PMC_CPQ_VehicleID__c,PMC_CPQ_BillingDate__c 
                                  FROM PMC_CPQ_Invoice__c
                                  WHERE Id = :invoiceId];

        Map<String, Object> result = new Map<String, Object>();
        result.put('AccountId', inv.PMC_CPQ_Order__r.AccountId);
        result.put('ContactId', inv.PMC_CPQ_Order__r.BillToContactId);
		result.put('PMC_SS_Order__c',inv.PMC_CPQ_Order__c);
		result.put('PMC_SS_SAPOrderNumber__c', inv.PMC_CPQ_Order__r.PMC_CPQ_SAPOrderNumber__c);
        result.put('PMC_SS_SoldToAccount__c', inv.PMC_CPQ_Order__r.AccountId);
		result.put('PMC_SS_SAPInvoiceNumber__c',inv.PMC_CPQ_InvoiceNumber__c);
        result.put('PMC_SS_Invoice__c',inv.Id);
       	result.put('Customer_Purchase_Order__c',inv.PMC_CPQ_CustomerPONumber__c);
        result.put('PMC_SS_OriginalInvoiceAmount__c',inv.PMC_CPQ_TotalInvoiceValue__c);
        result.put('PMC_SS_VehicleID__c',inv.PMC_CPQ_Delivery__r.PMC_CPQ_VehicleID__c);
        result.put('PMC_CPQ_BillingDate__c',inv.PMC_CPQ_BillingDate__c);

        return result;
    }
}