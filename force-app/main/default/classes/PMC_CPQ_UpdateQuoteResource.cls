/**
 * @description REST resource class for handling quote update requests from CPI.
 * It processes the incoming request, updates the relevant quote records in Salesforce, and logs the transaction details.
 * The class also fires a platform event to notify other systems of the update result.
 *
 * Successful Request Body Example:
 *
 * {
 *      "MassUpdateExecutionLine__c" : "a76RT000000AWBWYA4",
 *      "SalesContract" : "0020061890",
 *      "SAPReponseStatus" : "10 - 204 No Content ;20 - 204 No Content ;30 - 204 No Content ;40 - 204 No Content ;",
 *      "Status" : "S",
 *      "result" : "SalesContractItems Updated"
 * }
 *
 * Error Request Body Example:
 *
 * The Item property will be populated in error scenarios where the contract update fails for specific items,
 * allowing for partial success handling on the CPI side.
 *
 * In this example, the contract update was successul for item 10 and failed for item 20.
 * Any subsequent items (30, 40) were not processed due to the failure at item 20.
 *
 * {
 *      "MassUpdateExecutionLine__c" : "a76RT000000AUmPYAW",
 *      "SalesContract" : "0020060611",
 *      "Item" : "20",
 *      "SAPResponseStatus" : "",
 *      "Status" : "E",
 *      "result" : "com.sap.gateway.core.ip.component.odata.exception.OsciException: Bad Request : 400 : HTTP/1.1 "
 * }
 *
 * @author Sergio Umlauf
 * @storynumber GCPM-2771
 */

@RestResource(urlMapping='/quote/update')
global without sharing class PMC_CPQ_UpdateQuoteResource {
    static final String STRING_INTEGRATIONSTATUSERROR = 'Error';
    static final String STRING_INTEGRATIONSTATUSSUCCESS = 'Success';

    /**
     * @description Handles quote update requests from CPI and updates the related quote and execution records.
     */
    @HttpPost
    global static void updateQuote() {
        Boolean isSuccess = false;
        RestRequest req = RestContext.request;
        String reqBody = req.requestBody.toString();
        String resBody = '';
        Id executionLineId;
        MassUpdateExecutionLine__c executionLineRecord;
        PMC_CPQ_TransactionLog__c transactionLog = initializeTransactionLog(reqBody);
        Integer tlErrorMsgMaxLength = PMC_CPQ_TransactionLog__c.PMC_CPQ_Error_Message__c.getDescribe().getLength();
        String eventStatus = '';
        String eventMessage = '';

        System.debug('reqBody::: ' + reqBody);

        try {
            Map<String, Object> untypedResponse = deserializeRequestBody(reqBody);
            System.debug('CPI response::: ' + untypedResponse);

            if (Test.isRunningTest() && isForcedCustomException(untypedResponse)) {
                throw new CustomException('Simulated custom exception for test');
            }

            QuoteProcessingResult processingResult = processQuoteUpdate(untypedResponse, transactionLog, tlErrorMsgMaxLength);
            executionLineId = processingResult.executionLineId;
            executionLineRecord = processingResult.executionLineRecord;
            eventStatus = processingResult.eventStatus;
            eventMessage = processingResult.eventMessage;
            isSuccess = processingResult.isSuccess;
            resBody = processingResult.responseBody;
        } catch (CustomException ex) {
            System.debug('Exception in PMC_CPQ_UpdateQuoteResource.updateQuote::: ' + ex.getMessage());
            if (executionLineRecord != null) {
                resBody = '{"error": "Internal Server Error","details": "' + ex.getMessage() + '","quoteId": "' + executionLineRecord.CreatedQuote__c + '"}';
            } else {
                resBody = '{"error": "Internal Server Error","details": "' + ex.getMessage() + '","quoteId": ""}';
            }
            eventMessage = 'Exception in PMC_CPQ_UpdateQuoteResource.updateQuote: ' + ex.getMessage();
            transactionLog.PMC_CPQ_Error_Message__c = truncTransactionLogErrorMessage(resBody, tlErrorMsgMaxLength);
            isSuccess = false;
        }

        updateExecutionLines(executionLineId, eventStatus, eventMessage);
        fireUpdateQuoteResponseEvent(executionLineRecord, eventMessage, eventStatus);
        transactionLog.PMC_CPQ_ResponseBody__c = resBody;
        insert transactionLog;
    }

    private static PMC_CPQ_TransactionLog__c initializeTransactionLog(String reqBody) {
        PMC_CPQ_TransactionLog__c transactionLog = new PMC_CPQ_TransactionLog__c();
        transactionLog.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
        transactionLog.PMC_CPQ_InterfaceURL__c = '/services/apexrest/quote/update';
        Integer reqBodyMaxLength = PMC_CPQ_TransactionLog__c.PMC_CPQ_RequestBody__c.getDescribe().getLength();
        transactionLog.PMC_CPQ_RequestBody__c = reqBody.length() > reqBodyMaxLength ? reqBody.substring(0, reqBodyMaxLength) : reqBody;
        return transactionLog;
    }

    private static Map<String, Object> deserializeRequestBody(String reqBody) {
        return (Map<String, Object>) JSON.deserializeUntyped(reqBody);
    }

    private static QuoteProcessingResult processQuoteUpdate(Map<String, Object> untypedResponse, PMC_CPQ_TransactionLog__c transactionLog, Integer tlErrorMsgMaxLength) {
        QuoteProcessingResult result = new QuoteProcessingResult();
        Id executionLineId = getExecutionLineId(untypedResponse);

        if (executionLineId == null) {
            result.eventStatus = 'Error';
            result.eventMessage = 'No Execution Line Id found in request body.';
            result.responseBody = '{"error": "Internal Server Error", "details": "' + result.eventMessage + '", "SAP Contract Number": ""}';
            transactionLog.PMC_CPQ_Error_Message__c = truncTransactionLogErrorMessage(result.responseBody, tlErrorMsgMaxLength);
            return result;
        }

        String cpiStatus = getStringValue(untypedResponse, 'Status');
        String cpiContractItem = getStringValue(untypedResponse, 'Item');
        String cpiSAPContractNumber = getStringValue(untypedResponse, 'SalesContract');

        if (cpiStatus == 'E') {
            String cpiResult = getStringValue(untypedResponse, 'result');
            result.eventStatus = String.isBlank(cpiContractItem) ? 'Error' : 'Partial Success';
            result.eventMessage = String.isBlank(cpiResult) ? 'No message found in request body.' : cpiResult;
            result.isSuccess = false;
            result.responseBody =
                '{"error": "Internal Server Error", "details": "' +
                result.eventMessage +
                '", "Execution Line Id": "' +
                executionLineId +
                '", "SAP Contract Number": "' +
                cpiSAPContractNumber +
                '", "Item": "' +
                cpiContractItem +
                '"}';
            transactionLog.PMC_CPQ_Error_Message__c = truncTransactionLogErrorMessage(result.responseBody, tlErrorMsgMaxLength);
            return result;
        }

        result.executionLineId = executionLineId;
        result.executionLineRecord = getExecutionLineRecord(executionLineId);
        if (result.executionLineRecord == null) {
            result.eventStatus = 'Error';
            result.eventMessage = 'No Execution Line record found for Execution Line Id ' + executionLineId;
            result.responseBody = '{"error": "Internal Server Error",' + '"details": "' + result.eventMessage + '", "SAP Contract Number": "' + cpiSAPContractNumber + '"}';
            transactionLog.PMC_CPQ_Error_Message__c = truncTransactionLogErrorMessage(result.responseBody, tlErrorMsgMaxLength);
            return result;
        }

        SBQQ__Quote__c quoteRecord = getQuoteRecord(executionLineId);
        if (quoteRecord == null) {
            result.eventStatus = 'Error';
            result.eventMessage = 'No Quote record found for Execution Line Id ' + executionLineId;
            result.responseBody = '{"error": "Internal Server Error",' + '"details": "' + result.eventMessage + '", "quoteId": "' + result.executionLineRecord.CreatedQuote__c + '"}';
            transactionLog.PMC_CPQ_Error_Message__c = truncTransactionLogErrorMessage(result.responseBody, tlErrorMsgMaxLength);
            return result;
        }

        transactionLog.PMC_CPQ_Quote__c = quoteRecord.Id;
        QuoteUpdateOutcome outcome = applyQuoteUpdates(result.executionLineRecord, quoteRecord);
        result.eventStatus = outcome.status;
        result.eventMessage = outcome.message;
        result.isSuccess = outcome.isSuccess;
        result.responseBody = outcome.responseBody;
        transactionLog.PMC_CPQ_IntegrationStatus__c = result.isSuccess ? STRING_INTEGRATIONSTATUSSUCCESS : STRING_INTEGRATIONSTATUSERROR;
        if (!String.isBlank(outcome.errorMessage)) {
            transactionLog.PMC_CPQ_Error_Message__c = truncTransactionLogErrorMessage(outcome.errorMessage, tlErrorMsgMaxLength);
        }
        return result;
    }

    private static Boolean isForcedCustomException(Map<String, Object> response) {
        return response.containsKey('ForceCustomException') && (Boolean) response.get('ForceCustomException') == true;
    }

    private static Id getExecutionLineId(Map<String, Object> untypedResponse) {
        return untypedResponse.get('MassUpdateExecutionLine__c') != null ? Id.valueOf((String) untypedResponse.get('MassUpdateExecutionLine__c')) : null;
    }

    private static String getStringValue(Map<String, Object> response, String key) {
        return response.get(key) != null ? (String) response.get(key) : '';
    }

    private static MassUpdateExecutionLine__c getExecutionLineRecord(Id executionLineId) {
        List<MassUpdateExecutionLine__c> execLineResults = [
            SELECT
                Id,
                MassUpdateExecution__c,
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
        return execLineResults.isEmpty() ? null : execLineResults[0];
    }

    private static SBQQ__Quote__c getQuoteRecord(Id executionLineId) {
        List<SBQQ__Quote__c> quoteResults = [
            SELECT Id, SBQQ__Status__c, PMC_CPQ_SalesOffice__c, PMC_CPQ_AccountManager__c
            FROM SBQQ__Quote__c
            WHERE Id IN (SELECT CreatedQuote__c FROM MassUpdateExecutionLine__c WHERE Id = :executionLineId)
            LIMIT 1
        ];
        return quoteResults.isEmpty() ? null : quoteResults[0];
    }

    private static QuoteUpdateOutcome applyQuoteUpdates(MassUpdateExecutionLine__c executionLineRecord, SBQQ__Quote__c quoteRecord) {
        QuoteUpdateOutcome outcome = new QuoteUpdateOutcome();

        try {
            if (executionLineRecord == null || quoteRecord == null) {
                outcome.status = 'Error';
                outcome.message = 'No execution line or quote record available for update.';
                outcome.isSuccess = false;
                outcome.responseBody = '{"error": "Internal Server Error", "details": "' + outcome.message + '", "quoteId": ""}';
                outcome.errorMessage = outcome.responseBody;
                return outcome;
            }

            Boolean hasSalesOfficeUpdate = false;
            Boolean hasAccountManagerUpdate = false;
            Boolean salesOfficeUpdated = true;
            Boolean accountManagerUpdated = true;
            QuoteUpdateUtils.ExecutionLineDTO executionLineDTO = new QuoteUpdateUtils().getExecutionLineDTO(executionLineRecord);

            FieldUpdateResult accountManagerResult = new FieldUpdateResult();
            if (!String.isBlank(executionLineDTO.accountManagerId)) {
                accountManagerResult = attemptQuoteFieldUpdate(quoteRecord, executionLineDTO.accountManagerId, 'PMC_CPQ_AccountManager__c');
                hasAccountManagerUpdate = accountManagerResult.wasAttempted;
                accountManagerUpdated = accountManagerResult.wasUpdated;
                if (!String.isBlank(accountManagerResult.errorMessage)) {
                    outcome.errorMessage = accountManagerResult.errorMessage;
                    outcome.responseBody = accountManagerResult.errorMessage;
                }
            }

            FieldUpdateResult salesOfficeResult = new FieldUpdateResult();
            if (!String.isBlank(executionLineDTO.salesOffice)) {
                salesOfficeResult = attemptQuoteFieldUpdate(quoteRecord, executionLineDTO.salesOffice, 'PMC_CPQ_SalesOffice__c');
                hasSalesOfficeUpdate = salesOfficeResult.wasAttempted;
                salesOfficeUpdated = salesOfficeResult.wasUpdated;
                if (!String.isBlank(salesOfficeResult.errorMessage)) {
                    outcome.errorMessage = salesOfficeResult.errorMessage;
                    outcome.responseBody = salesOfficeResult.errorMessage;
                }
            }

            Boolean hasAnyUpdateAttempt = hasSalesOfficeUpdate || hasAccountManagerUpdate;
            if (!hasAnyUpdateAttempt) {
                outcome.status = 'Success';
                outcome.message = 'No update to Sales Office or Account Manager was attempted.';
                outcome.isSuccess = true;
                outcome.responseBody = '{"message": "Success!", "quoteId": "' + quoteRecord.Id + '"}';
            } else if (
                ((hasSalesOfficeUpdate && salesOfficeUpdated) && (hasAccountManagerUpdate && accountManagerUpdated)) ||
                (!hasSalesOfficeUpdate && (hasAccountManagerUpdate && accountManagerUpdated)) ||
                (!hasAccountManagerUpdate && (hasSalesOfficeUpdate && salesOfficeUpdated))
            ) {
                outcome.status = 'Success';
                outcome.message = 'Quote record updated successfully.';
                outcome.isSuccess = true;
                outcome.responseBody = '{"message": "Success", "quoteId": "' + quoteRecord.Id + '"}';
            } else if ((hasSalesOfficeUpdate && salesOfficeUpdated) && (hasAccountManagerUpdate && !accountManagerUpdated)) {
                outcome.status = 'Partial Success';
                outcome.message = 'Quote record updated with Sales Office only.';
                outcome.isSuccess = false;
                outcome.responseBody = '{"message": "Partial Success", "quoteId": "' + quoteRecord.Id + '"}';
            } else if ((hasSalesOfficeUpdate && !salesOfficeUpdated) && (hasAccountManagerUpdate && accountManagerUpdated)) {
                outcome.status = 'Partial Success';
                outcome.message = 'Quote record updated with Account Manager only.';
                outcome.isSuccess = false;
                outcome.responseBody = '{"message": "Partial Success", "quoteId": "' + quoteRecord.Id + '"}';
            } else {
                outcome.status = 'Error';
                outcome.message = 'No fields were updated in the Quote record.';
                outcome.isSuccess = false;
                outcome.responseBody = '{"message": "Error", "quoteId": "' + quoteRecord.Id + '"}';
            }

            return outcome;
        } catch (Exception ex) {
            outcome.status = 'Error';
            outcome.message = 'Error updating Quote in Salesforce: ' + ex.getMessage();
            outcome.isSuccess = false;
            outcome.responseBody = '{"error": "Internal Server Error", "details": "' + outcome.message + '", "quoteId": "' + (quoteRecord != null ? quoteRecord.Id : '') + '"}';
            outcome.errorMessage = outcome.responseBody;
            return outcome;
        }
    }

    private static FieldUpdateResult attemptQuoteFieldUpdate(SBQQ__Quote__c quoteRecord, String fieldValue, String fieldApiName) {
        FieldUpdateResult result = new FieldUpdateResult();
        if (String.isBlank(fieldValue)) {
            return result;
        }

        result.wasAttempted = true;
        if (fieldApiName == 'PMC_CPQ_AccountManager__c') {
            quoteRecord.PMC_CPQ_AccountManager__c = fieldValue;
        } else {
            quoteRecord.PMC_CPQ_SalesOffice__c = fieldValue;
        }

        try {
            if (Test.isRunningTest() && (fieldValue == 'FORCE_FAIL_ACCOUNT' || fieldValue == 'FORCE_RETHROW_ACCOUNT' || fieldValue == 'FORCE_FAIL_SALESOFFICE' || fieldValue == 'FORCE_RETHROW_SALESOFFICE')) {
                throw new QuoteUpdateUtils.QuoteUpdateException('Simulated ' + fieldApiName + ' update failure for test');
            }
            SBQQ.TriggerControl.disable();
            update quoteRecord;
            SBQQ.TriggerControl.enable();
            result.wasUpdated = true;
        } catch (Exception ex) {
            System.Debug('Exception when updating ' + fieldApiName + ' in quote::: ' + ex.getMessage());
            result.errorMessage = '{"error": "Internal Server Error", "details": "' + ex.getMessage() + '", "quoteId": "' + quoteRecord.Id + '"}';
            result.wasUpdated = false;
            if (Test.isRunningTest() && (fieldValue == 'FORCE_RETHROW_ACCOUNT' || fieldValue == 'FORCE_RETHROW_SALESOFFICE')) {
                throw ex;
            }
        }
        return result;
    }

    // @future(callout=false)
    private static void updateExecutionLines(Id executionLineId, String status, String message) {
        if (executionLineId == null) {
            return;
        }

        try {
            MassUpdateExecutionLine__c lineToUpdate = [
                SELECT Id, Status__c, Message__c, FinishedSteps__c, MassUpdateExecution__c
                FROM MassUpdateExecutionLine__c
                WHERE Id = :executionLineId
                LIMIT 1
            ];
            if (lineToUpdate != null) {
                lineToUpdate.Status__c = status;
                lineToUpdate.Message__c = message;
                if (status == 'Success') {
                    lineToUpdate.FinishedSteps__c = StringUtils.addPicklistValueToMultiSelect(lineToUpdate.FinishedSteps__c, 'Update Quotes');
                }
                update lineToUpdate;

                MassUpdateExecution__c exec = [
                    SELECT Id, Status__c
                    FROM MassUpdateExecution__c
                    WHERE Id = :lineToUpdate.MassUpdateExecution__c
                    LIMIT 1
                ];
                if (exec != null) {
                    exec.Status__c = (status == 'Success' ? 'Completed' : 'Failed');
                    update exec;
                }
            }
        } catch (Exception ex) {
            System.debug('Failed to update execution line or execution record: ' + ex.getMessage());
        }
    }

    private static void fireUpdateQuoteResponseEvent(MassUpdateExecutionLine__c executionLineRecord, String message, String status) {
        if (executionLineRecord == null) {
            return;
        }

        MassUpdateEvent__e event = new MassUpdateEvent__e(
            ExecutionId__c = executionLineRecord.MassUpdateExecution__c,
            LineId__c = executionLineRecord.Id,
            Message__c = message,
            Status__c = status,
            Step__c = executionLineRecord.Step__c
        );

        Database.SaveResult sr = EventBus.publish(event);
        if (!sr.isSuccess()) {
            for (Database.Error err : sr.getErrors()) {
                System.debug('Error returned::: ' + err.getStatusCode() + ' - ' + err.getMessage());
            }
        }
    }

    private static String truncTransactionLogErrorMessage(String message, Integer maxLength) {
        if (message.length() > maxLength) {
            return message.substring(0, maxLength);
        }
        return message;
    }

    private class QuoteProcessingResult {
        public Boolean isSuccess;
        public String eventStatus;
        public String eventMessage;
        public String responseBody;
        public Id executionLineId;
        public MassUpdateExecutionLine__c executionLineRecord;
    }

    private class QuoteUpdateOutcome {
        public Boolean isSuccess;
        public String status;
        public String message;
        public String responseBody;
        public String errorMessage;
    }

    private class FieldUpdateResult {
        public Boolean wasAttempted;
        public Boolean wasUpdated;
        public String errorMessage;
    }
}