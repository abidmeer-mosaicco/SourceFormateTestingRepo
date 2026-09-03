/**
 * @description This class provides utility methods for processing quote 
 * updates and generating contract JSON for callouts.
 * 
 * It includes methods to extract relevant information from 
 * MassUpdateExecutionLine__c records and to construct the necessary 
 * JSON structure for updating contracts based on quote changes.
 * 
 * The main method, createContractJson, takes an execution line ID, 
 * retrieves the associated record, and builds a JSON payload that can 
 * be sent to an external system (like SAP/CPI) via a callout.
 * 
 * @author Sergio Umlauf
 * @storynumber GCPM-2771
 */
public with sharing class QuoteUpdateUtils {
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public QuoteUpdateUtils() {
    }

    /**
     * @description Extracts the new sales office and account manager information from the MassUpdateExecutionLine__c record's NewValues__c field.
     * It deserializes the JSON string in NewValues__c, checks for the presence of the relevant fields, and populates an ExecutionLineDTO object
     * with the extracted information.
     * @param executionLine - The MassUpdateExecutionLine__c record containing the NewValues__c field with the updated values.
     * @return An ExecutionLineDTO object containing the extracted sales office and account manager information.
     * Note: The method includes error handling to catch any exceptions that may occur during JSON deserialization or data extraction, and it logs
     * the exception details for debugging purposes.
     * @throws Exception - If any exception occurs during JSON deserialization or data extraction, it is caught and logged, but the method continues
     * execution and returns an empty ExecutionLineDTO object.
     */
    public ExecutionLineDTO getExecutionLineDTO(MassUpdateExecutionLine__c executionLine) {
        ExecutionLineDTO result = new ExecutionLineDTO();

        try {
            Object newValues = JSON.deserializeUntyped(executionLine.NewValues__c);

            if (newValues instanceof Map<String, Object>) {
                Map<String, Object> jsonMap = (Map<String, Object>) newValues;

                if (jsonMap.containsKey('PMC_CPQ_SalesOffice__c')) {
                    String newSalesOffice = (String) jsonMap.get('PMC_CPQ_SalesOffice__c');
                    if (String.isNotBlank(newSalesOffice)) {
                        result.salesOffice = newSalesOffice;
                    }
                }

                if (jsonMap.containsKey('PMC_CPQ_AccountManager__c')) {
                    String newAccountManagerId = (String) jsonMap.get('PMC_CPQ_AccountManager__c');
                    if (String.isNotBlank(newAccountManagerId)) {
                        result.accountManagerId = newAccountManagerId;
                    }
                }
            }
        } catch (Exception ex) {
            System.debug(ex.getMessage() + '::: ' + ex.getStackTraceString());
        }

        System.debug('result ' + result);
        return result;
    }

    /**
     * @description This method generates a JSON string representing the contract update information based on the provided MassUpdateExecutionLine__c record ID.
     * It retrieves the MassUpdateExecutionLine__c record, extracts relevant information such as the associated contract, sales office, and account manager,
     * and constructs a JSON payload that can be used for updating contracts in an external system (like SAP/CPI). The method returns a ContractJsonResult
     * object containing the success status, any error messages, and the generated JSON string.
     * 
     * @param executionLineId - The ID of the MassUpdateExecutionLine__c record for which to generate the contract JSON.
     * @return A ContractJsonResult object containing the success status, error message (if any), and the generated JSON string for the contract update.
     * @throws Exception - If any exception occurs during the process of retrieving the execution line, extracting information, or generating the JSON,
     * it is caught and the success status is set to false with the error message populated accordingly.
     * Note: The method includes detailed error handling to ensure that any issues during the JSON generation process are captured and logged, allowing for
     * easier debugging and maintenance.
     * @see QuoteUpdateContractsQueueable for how the generated JSON is used in a Queueable context to perform callouts for contract updates.
     */
    public ContractJsonResult createContractJson(Id executionLineId) {
        ContractJsonResult res = new ContractJsonResult();

        if (executionLineId == null) {
            res.success = false;
            res.message = 'Execution Line ID is null';
            return res;
        }

        res.success = true;

        try {
            MassUpdateExecutionLine__c executionLine = [
                SELECT
                    Id,
                    CreatedQuote__c,
                    Status__c,
                    Step__c,
                    FinishedSteps__c,
                    Message__c,
                    CheckEligibilityStatus__c,
                    NewValues__c,
                    Contract__r.PMC_CPQ_SAPContractReference__c
                FROM MassUpdateExecutionLine__c
                WHERE Id = :executionLineId
                LIMIT 1
            ];

            ExecutionLineDTO executionLineDTO = getExecutionLineDTO(executionLine);

            if (executionLineDTO != null && executionLine != null && !String.isBlank(executionLine.Contract__r.PMC_CPQ_SAPContractReference__c)) {
                // Define the order by the sequence of 'put' calls
                Map<String, Object> contractDTOMap = new Map<String, Object>();

                // Account Manager.
                if (!String.isBlank(executionLineDTO.accountManagerId)) {
                    User user = [SELECT Id, PMC_CPQ_SAPExternalUserId__c FROM User WHERE Id = :executionLineDTO.accountManagerId LIMIT 1];
                    if (user != null) {
                        Map<String, Object> partnerDTOMap = new Map<String, Object>();
                        partnerDTOMap.put('to_SalesContract', executionLine.Contract__r.PMC_CPQ_SAPContractReference__c);
                        partnerDTOMap.put('Customer', user.PMC_CPQ_SAPExternalUserId__c);
                        partnerDTOMap.put('PartnerFunction', 'ZF');

                        // Add partner to contract header.
                        contractDTOMap.put('to_Partner', new List<Map<String, Object>>{ partnerDTOMap });

                        // Add partner to contract items.
                        List<SBQQ__QuoteLine__c> quoteLines = [
                            SELECT Id, SBQQ__Number__c, PMC_CLM_QuoteLineNumber__c
                            FROM SBQQ__QuoteLine__c
                            WHERE SBQQ__Quote__c = :executionLine.CreatedQuote__c
                            ORDER BY SBQQ__Number__c, PMC_CLM_QuoteLineNumber__c
                        ];

                        // System.debug('executionLine.CreatedQuote__c::: ' + executionLine.CreatedQuote__c);
                        // System.debug('quoteLines::: ' + quoteLines);

                        List<Map<String, Object>> itemsMapList = new List<Map<String, Object>>();
                        Map<String, Object> itemPartnerDTOMap = new Map<String, Object>();
                        Integer i = 1;
                        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
                            itemPartnerDTOMap.put('to_SalesContractItem', ((quoteLine.SBQQ__Number__c == null ? i : quoteLine.SBQQ__Number__c) * 10).toString());
                            itemPartnerDTOMap.put('to_SalesContract', executionLine.Contract__r.PMC_CPQ_SAPContractReference__c);
                            itemPartnerDTOMap.put('Customer', user.PMC_CPQ_SAPExternalUserId__c);
                            itemPartnerDTOMap.put('PartnerFunction', 'ZF');
                            Map<String, Object> contractItemDTOMap = new Map<String, Object>();
                            contractItemDTOMap.put('to_Partner', new List<Map<String, Object>>{ itemPartnerDTOMap });
                            contractItemDTOMap.put('SalesContractItem', ((quoteLine.SBQQ__Number__c == null ? i : quoteLine.SBQQ__Number__c) * 10).toString());
                            itemsMapList.add(contractItemDTOMap);
                            i++;
                        }
                        contractDTOMap.put('to_Item', itemsMapList);
                    } else {
                        res.success = false;
                        res.message = 'User not found for Account Manager Id: ' + executionLineDTO.accountManagerId;
                    }
                }

                contractDTOMap.put('SalesOffice', String.isBlank(executionLineDTO.salesOffice) ? '' : executionLineDTO.salesOffice);
                contractDTOMap.put('SalesContract', executionLine.Contract__r.PMC_CPQ_SAPContractReference__c);
                contractDTOMap.put('MassUpdateExecutionLine__c', executionLine.Id);

                res.json = JSON.serialize(contractDTOMap);
            } else {
                res.success = false;
                res.message =
                    'Execution Line not received or SAP Contract Number is blank. Execution Line DTO = ' +
                    executionLineDTO +
                    ', Execution Line = ' +
                    executionLine +
                    ', SAP Contract Number = ' +
                    (executionLine != null ? executionLine.Contract__r.PMC_CPQ_SAPContractReference__c : 'null');
            }
        } catch (Exception ex) {
            res.success = false;
            res.message = ex.getMessage();
        }
        return res;
    }

    // public Boolean checkSalesOfficeEligibility(Id quoteId, String newSalesOffice) {
    //     if (quoteId == null || newSalesOffice == null) {
    //         return false;
    //     }

    //     Map<String, List<String>> salesOfficesForSalesArea = SObjectUtils.getDependentPicklistValues('SBQQ__Quote__c', 'PMC_CPQ_SalesOffice__c');

    //     SBQQ__Quote__c quote = [
    //         SELECT Id, PMC_CPQ_SalesAreaCombination__c, PMC_CPQ_SalesOffice__c
    //         FROM SBQQ__Quote__c
    //         WHERE Id = :quoteId
    //         LIMIT 1
    //     ];

    //     if (quote.PMC_CPQ_SalesOffice__c == null || quote.PMC_CPQ_SalesAreaCombination__c == null) {
    //         return false;
    //     }

    //     List<Schema.PicklistEntry> pe = SObjectUtils.getPickListValues('SBQQ__Quote__c', 'PMC_CPQ_SalesAreaCombination__c');

    //     // SBQQ__Quote__c.PMC_CPQ_SalesAreaCombination__c holds the value of the picklist field
    //     // i.e. 'Mosaic Fertilizantes do B Domestic Common', while the dependent sales office values
    //     // (the key in salesOfficesForSalesArea) are grouped by the label of the sales area
    //     // i.e. 'Mosaic Fert Brasil Domestic Common'.
    //     //
    //     // salesAreas is a map of the picklist values and labels
    //     Map<String, String> salesAreas = new Map<String, String>();
    //     for (Schema.PicklistEntry p : pe) {
    //         if (!salesAreas.containsKey(p.getValue())) {
    //             salesAreas.put(p.getValue(), p.getLabel());
    //         }
    //     }

    //     // 1. Get the Sales Area's label for the given SBQQ__Quote__c.PMC_CPQ_SalesAreaCombination__c
    //     String salesArea = salesAreas.get(quote.PMC_CPQ_SalesAreaCombination__c);

    //     // 2. Get list of valid Sales Offices for the given Sales Area
    //     List<String> salesOffices = salesOfficesForSalesArea.get(salesArea);

    //     // 3. Check if the new Sales Office is valid
    //     return salesOffices.contains(newSalesOffice);
    // }

    // public Boolean checkAccountManagerEligibility(Id newAccountManagerId) {
    //     User user = [
    //         SELECT Id, Name, IsActive, PMC_CPQ_SAPExternalUserId__c
    //         FROM User
    //         WHERE PMC_SS_Profile_Name__c = 'Sales User' AND Id = :newAccountManagerId
    //         LIMIT 1
    //     ];
    //     return user?.IsActive && user?.PMC_CPQ_SAPExternalUserId__c != null;
    // }

    public class ExecutionDTO {
        @AuraEnabled
        public String feature;
        @AuraEnabled
        public MassUpdateExecution__c execution;
        @AuraEnabled
        public List<MassUpdateExecutionLine__c> lines;

        public ExecutionDTO(String feature, MassUpdateExecution__c exec, List<MassUpdateExecutionLine__c> lines) {
            this.feature = feature;
            this.execution = exec;
            this.lines = lines;
        }
    }

    public class ExecutionLineDTO {
        @AuraEnabled
        public Id contractId;
        @AuraEnabled
        public Id latestQuoteId;
        @AuraEnabled
        public String salesOffice;
        @AuraEnabled
        public Id accountManagerId;
        @AuraEnabled
        public String accountManagerName;
        @AuraEnabled
        public String oldSalesOffice;
        @AuraEnabled
        public Id oldAccountManagerId;
        @AuraEnabled
        public String oldAccountManagerName;

        @SuppressWarnings('PMD.EmptyStatementBlock')
        public ExecutionLineDTO() {
        }

        // @SuppressWarnings('PMD.ExcessiveParameterList')
        // public ExecutionLineDTO(
        //     Id contractId,
        //     Id latestQuoteId,
        //     String salesOffice,
        //     Id accountManagerId,
        //     String accountManagerName,
        //     String oldSalesOffice,
        //     Id oldAccountManagerId,
        //     String oldAccountManagerName
        // ) {
        //     this.contractId = contractId;
        //     this.latestQuoteId = latestQuoteId;
        //     this.salesOffice = salesOffice;
        //     this.accountManagerId = accountManagerId;
        //     this.accountManagerName = accountManagerName;
        //     this.oldSalesOffice = oldSalesOffice;
        //     this.oldAccountManagerId = oldAccountManagerId;
        //     this.oldAccountManagerName = oldAccountManagerName;
        // }
    }

    public class PicktListValueDTO {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;

        public PicktListValueDTO(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class SalesOfficeSalesAreaDTO {
        @AuraEnabled
        public Map<String, List<String>> salesOfficesForSalesAreas;
        @AuraEnabled
        public Map<String, String> salesAreas;

        @SuppressWarnings('PMD.EmptyStatementBlock')
        public SalesOfficeSalesAreaDTO() {
        }

        // public SalesOfficeSalesAreaDTO(Map<String, List<String>> salesOfficesForSalesAreas, Map<String, String> salesAreas) {
        //     this.salesOfficesForSalesAreas = salesOfficesForSalesAreas;
        //     this.salesAreas = salesAreas;
        // }
    }

    @SuppressWarnings('PMD.FieldNamingConventions')
    public virtual class PartnerDTO {
        public String PartnerFunction;
        public String Customer;
        public String to_SalesContract;
    }

    @SuppressWarnings('PMD.FieldNamingConventions')
    public class ItemPartnerDTO extends PartnerDTO {
        public String to_SalesContractItem;
    }

    @SuppressWarnings('PMD.FieldNamingConventions')
    public class ContractItemDTO {
        public String SalesContractItem;
        public List<ItemPartnerDTO> to_Partner;
    }

    @SuppressWarnings('PMD.FieldNamingConventions')
    public class ContractDTO {
        public String SalesContract;
        public String SalesOffice;
        public List<ContractItemDTO> to_Item;
        public List<PartnerDTO> to_Partner;
    }

    @SuppressWarnings('PMD.FieldNamingConventions')
    public class ContractJsonResult {
        public Boolean success;
        public String message;
        public String json;
    }

    public class QuoteUpdateException extends Exception {}
}