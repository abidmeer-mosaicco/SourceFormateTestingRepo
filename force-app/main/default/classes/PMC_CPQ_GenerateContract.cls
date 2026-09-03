/**
* @description Generates the DocuSign CLM contract document URL for Brazil-region quotes.
*              Validates that quotes with CIF lines have Shipping Instructions and that the quote
*              region is Brazil before building the CLM doc launcher URL.
* @author Raphael Soares
* @storynumber GCPM-5347
* @changelog
*   GCPM-5347 (2026-07-14): Externalized DocuSign CLM Account ID and Base URL to PMC_CLM_Environment_Setting__mdt, resolved by PMC_CLM_EnvironmentSettingService — fail fast when the environment is not configured
**/
public without sharing class PMC_CPQ_GenerateContract {
	@AuraEnabled(cacheable=true)
	public static String generateContract(String quoteId) {
		System.debug('Received Quote ID : ' + quoteId);
		// Query Quote and related Quote Lines with Incoterms
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
		System.debug('Queries Executed : ' + quotes.size());

		if (quotes.isEmpty()) {
			throw buildException('Quote not found or access denied.');
		}
		SBQQ__Quote__c quote = quotes[0];

		// Check 1: Validate CIF lines and Shipping Instructions
		if (!quote.SBQQ__LineItems__r.isEmpty() && String.isBlank(quote.PMC_CPQ_ContractShippingInstructions__c)) {
			throw buildException(System.Label.pmc_shipping_ins);
		}
		// Check 2: Region and Language validation
		if (quote.PMC_CLM_Region__c?.toLowerCase() != 'brazil') {
			throw buildException('Contract generation is only available for Brazil region.');
		}
		return getContractUrl(quote);
	}

	// ======    START    ======      GCPM-5347
	// Helper method to build URL — environment-specific values come from PMC_CLM_Environment_Setting__mdt
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