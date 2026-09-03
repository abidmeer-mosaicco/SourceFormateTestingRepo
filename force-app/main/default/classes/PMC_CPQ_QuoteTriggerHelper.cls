/**
 * @description This class will be used to handle all triggers on Quote (SBQQ__Quote__c) object.
 * @author Lalit Sharma
 * @storynumber : GDASF-8944
 */
public without sharing class PMC_CPQ_QuoteTriggerHelper {
    //This takes all available Quote fields from the required object.
    private static Map<String, Schema.SObjectField> schemaFieldMap = Schema.SObjectType.SBQQ__Quote__c.fields.getMap();
    //This hold the profile Name of the current context user
    private static String profileName;
    //This hold boolean to cover exception from test class
    @TestVisible
    private static Boolean testException = false;
    /**
     * @description This method will be used to validate during primmary field updation of Expired Quote records.
     * @param lstTriggeringNewQuotes - List of Quotes that trigger the validation method.
     * @param mapTriggeringOldQuote - Map datatype of list of Quotes that triggered the validation method's old value.
     */
    public static void validateQuoteExpiration(List<SBQQ__Quote__c> lstTriggeringNewQuotes, Map<Id, SBQQ__Quote__c> mapTriggeringOldQuote) {
        try {
            String currentUserName = UserInfo.getName();
            if (currentUserName.contains('Platform Integration User')) {
                return;
            }
            exceptionCheckvalidateQuoteExpiration();
            //Get the logged in user profile Name
            Id profileId = userinfo.getProfileId();
            profileName = [SELECT Id, Name FROM Profile WHERE Id = :profileId].Name;
            //Get the Quote fields to bypass below error message logic
            Map<String, String> mapBypassFieldForExpirationValidation = new Map<String, String>();
            for (String str : System.Label.PMC_CPQ_BypassFieldForQuoteExpirationValidation.split(';')) {
                mapBypassFieldForExpirationValidation.put(str, str);
            }

            for (SBQQ__Quote__c objQuote : lstTriggeringNewQuotes) {
                validateQuoteValuesChange(objQuote, mapTriggeringOldQuote, mapBypassFieldForExpirationValidation);
            }
        } catch (QueryException objQueryException) {
            PMC_ErrorLogClass.processException(objQueryException);
        }
    }
    /**
     * @description This method is used to check Exception triggered from test class to cover Query Exception on method validateQuoteExpiration
     */
    private static void exceptionCheckvalidateQuoteExpiration() {
        if (testException) {
            throw new QueryException();
        }
    }
    /**
    * @description This method is used to Validate the expired quote value change conditions.
    @param objQuote - current quote object of iteration to compare values.
    @param mapTriggeringOldQuote - Map list of old values of quotes.
    @param mapBypassFieldForExpirationValidation - Map list of fields should be bypassed for validation error.
    */
    private static void validateQuoteValuesChange(
        SBQQ__Quote__c objQuote,
        Map<Id, SBQQ__Quote__c> mapTriggeringOldQuote,
        Map<String, String> mapBypassFieldForExpirationValidation
    ) {
        if (mapTriggeringOldQuote.get(objQuote.Id).get('PMC_CPQ_FlowVRByPassToggle__c') != objQuote.get('PMC_CPQ_FlowVRByPassToggle__c')) {
            return;
        }
        if (mapTriggeringOldQuote.get(objQuote.Id).get('SBQQ__Status__c') == 'Expired') {
            for (String str : schemaFieldMap.keyset()) {
                //Condition to check profile and dymanic Quote fields to throw the exception
                if (
                    profileName != 'System Administrator' &&
                    str != mapBypassFieldForExpirationValidation.get(str) &&
                    objQuote.get(str) != mapTriggeringOldQuote.get(objQuote.Id).get(str)
                ) {
                    //Throw exception to user about Expiration validation Message
                    objQuote.addError(System.Label.PMC_CPQ_QuoteExpirationValidationMessage);
                }
            }
        }
    }

    @Future
    public static void deleteZeroQuantityLinesAfterApproval(Set<Id> approvedQuotes) {
        if (approvedQuotes.isEmpty()) {
            return;
        }
        Set<Id> quotesWithToDelete = ExecutionController.bulkExecuteOnce('deleteZeroQuantityLinesAfterApproval', approvedQuotes);
        if (quotesWithToDelete.isEmpty()) {
            return;
        }

        PMC_ProcessSwitches__c processSwitch = null;
        Boolean originalBypassFlowValue = null;
        Boolean originalBypassVRValue = null;
        try {
            List<SBQQ__QuoteLine__c> qLines = [
                SELECT Id
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c IN :quotesWithToDelete AND (SBQQ__Quantity__c = 0 OR SBQQ__Quantity__c = NULL)
            ];
            if (!qLines.isEmpty()) {
                PMC_CPQ_QuoteLineTriggerHandler.boolBypassTriggerLogic = true;
                PMC_CPQ_QuoteTriggerHandler.boolBypassTriggerLogic = true;
                // Set custom setting to bypass the flow
                processSwitch = PMC_ProcessSwitches__c.getOrgDefaults();
                originalBypassFlowValue = processSwitch.PMC_BypassFlow__c;
                originalBypassVRValue = processSwitch.PMC_BypassValidationRule__c;
                processSwitch.PMC_BypassFlow__c = true;
                processSwitch.PMC_BypassValidationRule__c = true;
                upsert processSwitch;
                SBQQ.TriggerControl.disable();
                delete qLines;
                SBQQ.TriggerControl.enable();
            }
        } catch (Exception ex) {
            PMC_ErrorLog__c objErrorLog = new PMC_ErrorLog__c();
            objErrorLog.PMC_Message__c = ex.getMessage();
            objErrorLog.PMC_MethodName__c = 'deleteZeroQuantityLinesAfterApproval';
            objErrorLog.PMC_ClassName__c = 'PMC_CPQ_QuoteTriggerHelper';
            Database.insert(objErrorLog, false);
        } finally {
            // Reset the bypass flags
            PMC_CPQ_QuoteLineTriggerHandler.boolBypassTriggerLogic = false;
            PMC_CPQ_QuoteTriggerHandler.boolBypassTriggerLogic = false;
            // Only reset process switch if it was initialized
            if (processSwitch != null && originalBypassFlowValue != null && originalBypassVRValue != null) {
                processSwitch.PMC_BypassFlow__c = originalBypassFlowValue;
                processSwitch.PMC_BypassValidationRule__c = originalBypassVRValue;
                upsert processSwitch;
            }
        }
    }

    public static void validateProductsEntitlementPoliciesAfterAccepted(Id quoteId) {
        if (quoteId == null) {
            return;
        }

        Set<Product2> quoteProducts = new Set<Product2>();
        Set<Product2> entitlementProducts = new Set<Product2>();
        Set<Product2> productsWithoutEntitlementPolicy = new Set<Product2>();

        try {
            SBQQ__Quote__c quote = [
                SELECT Id, SBQQ__Account__r.PMC_SS_SAPCustomerNumber__c
                FROM SBQQ__Quote__c
                WHERE Id = :quoteId
                LIMIT 1
            ];
            List<SBQQ__QuoteLine__c> quoteLines = [SELECT SBQQ__Product__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quoteId];
            for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
                quoteProducts.add(new Product2(Id = quoteLine.SBQQ__Product__c));
            }

            String accountSapNumber = quote.SBQQ__Account__r.PMC_SS_SAPCustomerNumber__c;
            CommerceEntitlementPolicy entitlementPolicy = [
                SELECT Id
                FROM CommerceEntitlementPolicy
                WHERE PMC_DH_SAPCustomerNumber__c = :accountSapNumber
                LIMIT 1
            ];
            List<Product2> productList = [
                SELECT Id
                FROM Product2
                WHERE Id IN (SELECT ProductId FROM CommerceEntitlementProduct WHERE PolicyId = :entitlementPolicy.Id)
            ];
            entitlementProducts.addAll(productList);

            for (Product2 prod : quoteProducts) {
                if (!entitlementProducts.contains(prod)) {
                    productsWithoutEntitlementPolicy.add(prod);
                }
            }

            List<CommerceEntitlementProduct> entitlementRelationships = new List<CommerceEntitlementProduct>();
            for (Product2 prod : productsWithoutEntitlementPolicy) {
                entitlementRelationships.add(new CommerceEntitlementProduct(ProductId = prod.Id, PolicyId = entitlementPolicy.Id));
            }

            if (!entitlementRelationships.isEmpty()) {
                insert entitlementRelationships;
            }
        } catch (QueryException objQueryException) {
            PMC_ErrorLogClass.processException(objQueryException);
        }
    }

    /**
     * Update Quote Line Items based on Quote PMC_CPQ_VCOQuotation__c value.
     * @param quoteIds Set of Quote IDs to process.
     * @param quotes List of Quote records with current values.
     */
    public static void updateQuoteItemsVCO(Set<Id> quoteIds, List<SBQQ__Quote__c> newQuotes) {
        // Create a map for easy lookup of Quote values
        Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>();
        for (SBQQ__Quote__c quote : newQuotes) {
            if (quoteIds.contains(quote.Id)) {
                quoteMap.put(quote.Id, quote);
            }
        }

        List<SBQQ__QuoteLine__c> lineItemsToUpdate = new List<SBQQ__QuoteLine__c>();

        // Get all Quote Line Items for the affected quotes.
        List<SBQQ__QuoteLine__c> lineItems = [
            SELECT Id, SBQQ__Quote__c, PMC_CPQ_VCOQuotation__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c IN :quoteIds
            WITH SECURITY_ENFORCED
        ];

        // Update each line item based on its parent Quote's checkbox.
        for (SBQQ__QuoteLine__c quoteLine : lineItems) {
            SBQQ__Quote__c parentQuote = quoteMap.get(quoteLine.SBQQ__Quote__c);
            if (parentQuote != null) {
                quoteLine.PMC_CPQ_VCOQuotation__c = parentQuote.PMC_CPQ_VCOQuotation__c == null
                    ? false
                    : parentQuote.PMC_CPQ_VCOQuotation__c;
                lineItemsToUpdate.add(quoteLine);
            }
        }

        // Perform the update if we have records to update.
        if (!lineItemsToUpdate.isEmpty()) {
            try {
                update lineItemsToUpdate;
            } catch (Exception ex) {
                PMC_ErrorLogClass.processException(ex);
            }
        }
    }

	@Future
	public static void setMassContractUpdateApprovalFinishedStep(Set<Id> approvedQuoteIds) {
		if (approvedQuoteIds == null || approvedQuoteIds.isEmpty()) {
			return;
		}
		List<MassUpdateExecutionLine__c> linesToUpdate = [
			SELECT Id, CreatedById, CreatedQuote__c, FinishedSteps__c, Status__c, Step__c
			FROM MassUpdateExecutionLine__c
			WHERE CreatedQuote__c IN :approvedQuoteIds
		];
		for (MassUpdateExecutionLine__c line : linesToUpdate) {
			String currentStep = line.Step__c;
			line.Step__c = 'Generate Contracts';
			line.Status__c = 'Pending';
			line.FinishedSteps__c = StringUtils.addPicklistValueToMultiSelect(line.FinishedSteps__c, currentStep);
            if(linesToUpdate.size() <= 10) {
			    line.Status__c = 'In Progress';
				System.enqueueJob(new ContractUpdateGenContrsQueueable(line.Id, line.CreatedQuote__c, line.CreatedById));
            }
		}
		if (!linesToUpdate.isEmpty()) {
			update linesToUpdate;
		}
	}

	@Future
	public static void setMassContractUpdateGenDocumentStatus(Set<Id> quoteIds) {
		if (quoteIds == null || quoteIds.isEmpty()) {
			return;
		}
		List<MassUpdateExecutionLine__c> linesToUpdate = [
			SELECT Id, CreatedQuote__c, CreatedQuote__r.PMC_CPQ_ContractStageName__c, FinishedSteps__c, Status__c, Step__c
			FROM MassUpdateExecutionLine__c
			WHERE CreatedQuote__c IN :quoteIds
		];
		List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
		for (MassUpdateExecutionLine__c line : linesToUpdate) {
            String currentStep = line.Step__c;
			line.Step__c = 'Generate Contracts';
			quotesToUpdate.add(new SBQQ__Quote__c(
				Id = line.CreatedQuote__c,
				SBQQ__Status__c = 'Accepted'
			));
            if(line.CreatedQuote__r?.PMC_CPQ_ContractStageName__c == 'Pending Signature'){
				line.Status__c = 'Success';
				line.FinishedSteps__c = StringUtils.addPicklistValueToMultiSelect(line.FinishedSteps__c, currentStep);
			}
		}
		if (!linesToUpdate.isEmpty()) {
			update linesToUpdate;
			update quotesToUpdate;
		}
	}
}