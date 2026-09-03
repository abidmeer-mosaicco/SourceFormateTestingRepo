public without sharing class md_reportContractController {

    @AuraEnabled(cacheable=false)
    public static List<Id> getLatestQuoteIdsForAccounts(List<Id> accountIds) {
        try {
            return md_reportContractService.getLatestQuoteIdsForAccounts(accountIds);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static String getWhereClauseExcludingRejected(List<Id> quoteIds) {
        try {
            return md_reportContractService.getWhereClauseExcludingRejected(quoteIds);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<md_reportContractWrapper.EnrichmentData> getContractEnrichmentData(List<Id> quoteIds) {
        try {
            return md_reportContractService.getContractEnrichmentData(quoteIds);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static md_reportContractWrapper.FilterOptions getContractFilterOptions(
        String baseWhereClause,
        List<Id> quoteIds,
        List<String> appliedContractType,
        List<String> appliedProduct,
        List<String> appliedOrigin,
        List<String> appliedShipTo
    ) {
        try {
            return md_reportContractService.getContractFilterOptions(
                baseWhereClause, quoteIds,
                appliedContractType, appliedProduct, appliedOrigin, appliedShipTo
            );
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Bulk pre-check used by the Contract Report to figure out which Quote Lines have a Sales
     * Contract PDF available for download. Receives the list of ORIGINAL Quote Ids (Contract.SBQQ__Quote__c,
     * NOT the latest one) and returns a map keyed by quote Id. Each entry exposes whether a file
     * exists, a ready-to-use download URL and the file name.
     */
    @AuraEnabled(cacheable=false)
    public static Map<Id, Map<String, Object>> getQuotesWithContractFile(List<Id> quoteIds) {
        try {
            return md_reportContractService.getQuotesWithContractFile(quoteIds);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> downloadContractFile(Id contentVersionId) {
        try {
            return md_reportContractService.downloadContractFile(contentVersionId);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getQuoteContractDownloadUrl(Id quoteId) {
        try {
            return md_reportContractService.getQuoteContractDownloadUrl(quoteId);
        } catch (Exception e) {
            Map<String, Object> result = new Map<String, Object>();
            result.put('success', false);
            result.put('message', e.getMessage());
            return result;
        }
    }
}