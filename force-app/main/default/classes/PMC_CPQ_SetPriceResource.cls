@RestResource(urlMapping='/quote/setprices')
global without sharing class PMC_CPQ_SetPriceResource {
	static final String STRING_INTEGRATIONSTATUSERROR = 'Error';
	static final String STRING_INTEGRATIONSTATUSSUCCESS = 'Success';
	static final String STRING_GETPRICEPREFIX = 'Get Price: ';
	static String errorMsg = '';

	@HttpPost
	global static void savePrice() {
		Boolean isSuccess = false;
		RestRequest req = RestContext.request;
		RestResponse res = RestContext.response;
		SBQQ__Quote__c quoteRecord;
		String quoteNumber;
		Map<String, Object> jsonResponse;
		String reqBody = req.requestBody.toString();
		String resBody = '';
		PMC_CPQ_TransactionLog__c transactionLog = new PMC_CPQ_TransactionLog__c();
		transactionLog.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
		transactionLog.PMC_CPQ_InterfaceURL__c = '/services/apexrest/quote/setprices';

		try {
			Map<String, Object> untypedResponse = (Map<String, Object>) JSON.deserializeUntyped(reqBody);
			Integer reqBodyMaxLength = PMC_CPQ_TransactionLog__c.PMC_CPQ_RequestBody__c.getDescribe().getLength();
			transactionLog.PMC_CPQ_RequestBody__c = reqBody.length() > reqBodyMaxLength ? reqBody.substring(0, reqBodyMaxLength) : reqBody;
			errorMsg = untypedResponse.get('error') != null ? (String) untypedResponse.get('error') : '';

			if (String.isNotBlank(errorMsg)) {
				String quoteName = 'Q-' + (String) untypedResponse.get('Ztransid');
				List<SBQQ__Quote__c> quotes = [
					SELECT Id, Get_Prices_Status__c, PMC_CPQ_IntegrationStatus__c, PMC_CPQ_IntegrationMessage__c, PMC_CPQ_GetPriceCallComplete__c
					FROM SBQQ__Quote__c
					WHERE Name = :quoteName
					LIMIT 1
				];
				if (quotes.isEmpty()) {
					throw new CustomException('Quote not found!');
				}                
				quoteRecord = quotes[0];
				Integer errorMsgMaxLength = SBQQ__Quote__c.PMC_CPQ_IntegrationMessage__c.getDescribe().getLength();
				quoteRecord.PMC_CPQ_IntegrationMessage__c = errorMsg.length() > errorMsgMaxLength
					? errorMsg.substring(0, errorMsgMaxLength)
					: errorMsg;
				quoteRecord.Get_Prices_Status__c = 'Failed';
				quoteRecord.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
				quoteRecord.PMC_CPQ_GetPriceCallComplete__c = ((quoteRecord.PMC_CPQ_GetPriceCallComplete__c != true) ? false : true);
				res.statusCode = 200;
				resBody = '{"error":"Price fetch failed","details":"' + errorMsg + '","quoteId":"' + quoteRecord.Id + '"}';
				fireGetPriceResponseEvent(quoteRecord.Id, 400, resBody);
                String convErrMsg;
                Boolean matchFound=false;
                List<String> errMsgs = errorMsg.split('\\|',-2);
                transactionLog.PMC_CPQ_Quote__c = quotes[0].Id;
                for(PMC_CPQ_ErrorMessageSettings__mdt objErrorMsg: PMC_CPQ_ErrorMessageSettings__mdt.getAll().values()){
                    if(errMsgs[0].contains(objErrorMsg.PMC_CPQ_RegexExpression__c)){
                        convErrMsg = objErrorMsg.PMC_CPQ_ConvertedErrorMessage__c;
            			matchFound=true;
            			break;
        			}
    			}
                if(!matchFound){                    
                    convErrMsg = errMsgs[0];
                }
                Integer tlerrorMsgMaxLength = PMC_CPQ_TransactionLog__c.PMC_CPQ_Error_Message__c.getDescribe().getLength();
                transactionLog.PMC_CPQ_Error_Message__c = convErrMsg.length() > tlerrorMsgMaxLength ? convErrMsg.substring(0, tlerrorMsgMaxLength): convErrMsg;
			} else {
				System.Debug('Payload:'+untypedResponse);
				jsonResponse = (Map<String, Object>) ((Map<String, Object>) (untypedResponse).get('HeaderSet')).get('Header');

				List<Object> priceCondSet = (List<Object>) jsonResponse.get('Price_CondSet');
				if (!priceCondSet.isEmpty()) {
					Map<String, Object> firstCondSet = (Map<String, Object>) priceCondSet[0];
					List<Object> priceCond = (List<Object>) firstCondSet.get('Price_Cond');

					if (!priceCond.isEmpty()) {
						Map<String, Object> firstCond = (Map<String, Object>) priceCond[0];
						quoteNumber = (String) firstCond.get('Ztransid');
					}
					System.debug('quoteNumber: ' + quoteNumber);
					if (String.isNotBlank(quoteNumber)) {
						quoteNumber = 'Q-' + quoteNumber;
						List<SBQQ__QuoteLine__c> lstQuoteLines = [
							SELECT
								Id,
								Name,
								SBQQ__ListPrice__c,
								PMC_CPQ_FinalPricePerTon__c,
								PMC_CPQ_FinalPricePerTonne__c,
								SBQQ__Number__c,
								SBQQ__Quote__c,
								PMC_CPQ_LastPricedDate__c,
								SBQQ__UpgradedSubscription__c,
								SBQQ__Quote__r.SBQQ__Type__c,
								SBQQ__Quote__r.PMC_CPQ_Region__c,
								SBQQ__Quote__r.PMC_CPQ_GetPriceCallComplete__c
							FROM SBQQ__QuoteLine__c
							WHERE SBQQ__Quote__r.Name = :quoteNumber
						];

						quoteRecord = new SBQQ__Quote__c(
							Id = lstQuoteLines[0].SBQQ__Quote__c,
							PMC_CPQ_GetPriceCallComplete__c = lstQuoteLines[0].SBQQ__Quote__r.PMC_CPQ_GetPriceCallComplete__c
						);
						PMC_CPQ_GetPriceResponseParsing.responseProcess(quoteRecord, untypedResponse);

						quoteRecord.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSSUCCESS;
						quoteRecord.PMC_CPQ_IntegrationMessage__c = STRING_GETPRICEPREFIX + STRING_INTEGRATIONSTATUSSUCCESS;
						quoteRecord.PMC_CPQ_GetPriceCallComplete__c = true;
						res.statusCode = 200;
						resBody = '{"message":"Success!","quoteId":"' + quoteRecord.Id + '"}';
						transactionLog.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSSUCCESS;

						List<SBQQ__QuoteLine__c> linesToUpdate = [
							SELECT Id, 
								PMC_CPQ_FinalPricePerTon__c,
								PMC_CPQ_FinalPricePerTonne__c
							FROM SBQQ__QuoteLine__c
							WHERE SBQQ__Quote__r.Name = :quoteNumber AND SBQQ__Quote__r.Get_Prices_Status__c != 'Approval In Progress'
						];
						if(!linesToUpdate.isEmpty()){
							for (SBQQ__QuoteLine__c quoteLine : linesToUpdate) {
								quoteLine.PMC_CPQ_FinalPricePerTon__c = quoteLine.PMC_CPQ_FinalPricePerTonne__c;
							}
							SBQQ.TriggerControl.disable();
							try {
								Database.update(linesToUpdate, false);
							} finally {
								SBQQ.TriggerControl.enable();
							}
						}

						quoteRecord.Get_Prices_Status__c = 'Completed';
						isSuccess = true;
					} else {
						res.statusCode = 500;
						quoteRecord.Get_Prices_Status__c = 'Failed';
						resBody = '{"error":"Invalid JSON, Ztransid (quoteNumber) not found."}';
					}
				} else {
					quoteRecord.Get_Prices_Status__c = 'Failed';
					res.statusCode = 500;
					resBody = '{"error":"Invalid JSON, Ztransid (quoteNumber) not found."}';
				}
				// On SUCCESS, the event is published by PMC_CPQ_QuoteCalcCallback after
				// the Calculate Quote API finishes (see block after the quoteRecord update).
				// Only fire the event here for parsing/payload failure paths.
				if (!isSuccess) {
					fireGetPriceResponseEvent(quoteRecord.Id, res.statusCode, resBody);
				}
			}
		} catch (CustomException ex) {
			System.debug(ex.getMessage());
			res.statusCode = 500;
			if (quoteRecord != null) {
				quoteRecord.Get_Prices_Status__c = 'Failed';
				quoteRecord.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
				quoteRecord.PMC_CPQ_IntegrationMessage__c = ex.getMessage();
				quoteRecord.PMC_CPQ_GetPriceCallComplete__c = ((quoteRecord.PMC_CPQ_GetPriceCallComplete__c != true) ? false : true);
				resBody = '{"error":"Internal Server Error","details":"' + ex.getMessage() + '","quoteId":"' + quoteRecord.Id + '"}';
				fireGetPriceResponseEvent(quoteRecord.Id, res.statusCode, resBody);
				// Fire Platform Event for exception case
			} else {
				resBody = '{"error":"Internal Server Error","details":"' + ex.getMessage() + '","quoteId":""}';
			}
		}
		if (quoteRecord != null) {
			try {
				SBQQ.TriggerControl.disable();
				try {
					update quoteRecord;
				} finally {
					SBQQ.TriggerControl.enable();
				}

				if (isSuccess) {
					// Trigger the single calculation via the CPQ Calculate Quote API.
					// The callback (PMC_CPQ_QuoteCalcCallback) persists the calculated
					// model and publishes Get_Price_Response__e, guaranteeing that
					// subscribers only receive the signal AFTER the calculation completes.
					PMC_CPQ_QuoteCalcService.recalculate(quoteRecord.Id);
				} else {
					updateExecutionLinesAsync(String.valueOf(quoteRecord.Id));
				}
			} catch (Exception ex) {
				System.Debug('exception::'+ex.getMessage());
				res.statusCode = 500;
				resBody = '{"error":"Internal Server Error","details":"' + ex.getMessage() + '","quoteId":"' + quoteRecord.Id + '"}';
				fireGetPriceResponseEvent(quoteRecord.Id, res.statusCode, resBody);
			}
		}
		res.responseBody = Blob.valueOf(resBody);
		transactionLog.PMC_CPQ_ResponseBody__c = resBody;
		insert transactionLog;
	}

	@future(callout=false)
	private static void updateExecutionLinesAsync(String quoteRecordId) {
		List<MassUpdateExecutionLine__c> execLines = [
			SELECT Id, Status__c, CheckEligibilityStatus__c, Message__c
			FROM MassUpdateExecutionLine__c
			WHERE CreatedQuote__c = :quoteRecordId
		];
		if (execLines.isEmpty()) {
			return;
		}
		for (MassUpdateExecutionLine__c line : execLines) {
			line.Status__c = 'Error';
			line.CheckEligibilityStatus__c = 'Error';
			line.Message__c = String.isNotBlank(errorMsg) ? errorMsg : line.Message__c;
		}
		update execLines;
	}

	private static void fireGetPriceResponseEvent(String quoteId, Decimal statusCode, String message) {
		Get_Price_Response__e event = new Get_Price_Response__e(Quote__c = quoteId, StatusCode__c = statusCode, Message__c = message);

		// Publish the event
		Database.SaveResult sr = EventBus.publish(event);
		if (!sr.isSuccess()) {
			for (Database.Error err : sr.getErrors()) {
				System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
			}
		}
	}
}