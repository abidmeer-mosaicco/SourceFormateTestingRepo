/**
* @description Apex controller for the generateContractScreen LWC: returns quote primary contact
*              details, updates the DocuSign picklist and generates the DocuSign CLM contract
*              document URL for Brazil-region quotes.
* @author Raphael Soares
* @storynumber GCPM-5347
* @changelog
*   GCPM-5347 (2026-07-14): Externalized DocuSign CLM Account ID and Base URL to PMC_CLM_Environment_Setting__mdt, resolved by PMC_CLM_EnvironmentSettingService — fail fast when the environment is not configured
**/
public with sharing class PMC_CPQ_GenerateQuoteHelper {

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getQuotePrimaryContact(Id quoteId) {
        
        // Query the quote and its primary contact
        SBQQ__Quote__c q = [
            SELECT Name, PMC_CPQ_PrimaryContact__r.Name, PMC_CPQ_PrimaryContact__r.Email
            FROM SBQQ__Quote__c
            WHERE Id = :quoteId
            LIMIT 1
        ];

        Map<String, String> result = new Map<String, String>();

        //logic for primary contact
        if (q.PMC_CPQ_PrimaryContact__r != null) {
            result.put('primaryContactName', q.PMC_CPQ_PrimaryContact__r.Name);
            result.put('primaryContactEmail', q.PMC_CPQ_PrimaryContact__r.Email);
        } else {
            result.put('primaryContactName', 'No Primary Contact');
            result.put('primaryContactEmail', '');
        }

        result.put('quoteName', q.Name);

        return result;
    }

    @AuraEnabled
    public static void updateDocusignPicklist(Id quoteId, String picklistValue) {
     
        try {
      
            SBQQ__Quote__c quoteToUpdate = new SBQQ__Quote__c(
                Id = quoteId,
                PMC_CPQ_Docusign__c = picklistValue
            );

        // Use Database.update with allOrNone=false to bypass validation rule errors
        Database.SaveResult sr = Database.update(quoteToUpdate, false);

        if (!sr.isSuccess()) {
            // Log the validation rule error, but do not throw an exception
            System.debug('Validation rules prevented update: ' + sr.getErrors()[0].getMessage());
            // Optional: show a toast in LWC if you want
            // this.showToast('Warning', 'Some rules prevented the picklist update.', 'warning');
        }

        } catch (Exception e) {
        // Catch unexpected errors and show a toast
            throw new AuraHandledException('Error updating DocuSign picklist: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String generateContract(String quoteId) {
        List<SBQQ__Quote__c> quotes = [
            SELECT
                Id,
                Name,
                PMC_CPQ_ContractShippingInstructions__c,
                PMC_CLM_Region__c,
                PMC_CPQ_ContractLanguage__c,
                (
                    SELECT Id, PMC_CPQ_Incoterms1__c
                    FROM SBQQ__LineItems__r
                    WHERE PMC_CPQ_Incoterms1__c = 'CIF'
                    LIMIT 1
                )
            FROM SBQQ__Quote__c
            WHERE Id = :quoteId
            LIMIT 1
        ];
        if (quotes.isEmpty()) {
            throw buildException('Quote not found or access denied.');
        }
        SBQQ__Quote__c quote = quotes[0];

        if (!quote.SBQQ__LineItems__r.isEmpty() && String.isBlank(quote.PMC_CPQ_ContractShippingInstructions__c)) {
            throw buildException(System.Label.pmc_shipping_ins);
        }

        if (quote.PMC_CLM_Region__c?.toLowerCase() != 'brazil') {
            throw buildException('Contract generation is only available for Brazil region.');
        }

        return getContractUrl(quote);
    }

    // ======    START    ======      GCPM-5347
    // Environment-specific values come from PMC_CLM_Environment_Setting__mdt
    private static String getContractUrl(SBQQ__Quote__c quote) {
        try {
            return PMC_CLM_EnvironmentSettingService.getContractUrl(quote);
        } catch (PMC_CLM_EnvironmentSettingService.EnvironmentSettingException e) {
            PMC_ErrorLogClass.processException(e);
            throw buildException(e.getMessage());
        }
    }
    // ======      END      ======      GCPM-5347

    private static Exception buildException(String msg) {
        if (Test.isRunningTest()) {
            return new CustomException(msg);
        } else {
            return new AuraHandledException(msg);
        }
    }
}