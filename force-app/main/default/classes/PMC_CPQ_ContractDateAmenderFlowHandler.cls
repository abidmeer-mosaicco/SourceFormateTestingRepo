public without sharing class PMC_CPQ_ContractDateAmenderFlowHandler {
	@InvocableMethod(label='Amendment Quote Creation Background Process' description='Amendment Quote Creation Background Process')
	public static List<AmendContractResponse> amendContract(List<AmendContractRequest> requestList) {
		List<AmendContractResponse> responseList = new List<AmendContractResponse>();
		List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
		List<MassUpdateExecutionLine__c> executionLinesToUpdate = new List<MassUpdateExecutionLine__c>();
		Map<Id, Id> mapReqAmendId = new Map<Id, Id>();

		for (AmendContractRequest request : requestList) {
			String contractId = request.uid;
			// Load the contract and perform amendments
			QuoteModel quote = LoadContract(request.uid);
			mapReqAmendId.put(request.uid, quote?.record?.id);
		}
		Map<Id, SBQQ__Quote__c> mapAmendQuotes = new Map<Id, SBQQ__Quote__c>(
			[SELECT Id, PMC_CPQ_ContractStart__c, PMC_CPQ_ContractEnd__c FROM SBQQ__Quote__c WHERE Id IN :mapReqAmendId.values()]
		);
		for (AmendContractRequest request : requestList) {
			String contractId = request.uid;
			String quoteId = mapReqAmendId.get(contractId);
			SBQQ__Quote__c amendQuote = mapAmendQuotes.get(quoteId);
			String contractDates = request.newDates;

			if (amendQuote != null && !String.isBlank(contractDates)) {
				ContractDatesClass newDates = (ContractDatesClass) JSON.deserialize(contractDates, ContractDatesClass.class);
				amendQuote.PMC_CPQ_ContractStart__c = newDates.PMC_CPQ_ContractStart != null
					? newDates.PMC_CPQ_ContractStart
					: amendQuote.PMC_CPQ_ContractStart__c;
				amendQuote.PMC_CPQ_ContractEnd__c = newDates.PMC_CPQ_ContractEnd != null
					? newDates.PMC_CPQ_ContractEnd
					: amendQuote.PMC_CPQ_ContractEnd__c;
				quotesToUpdate.add(amendQuote);
				executionLinesToUpdate.add(new MassUpdateExecutionLine__c(
					Id = request.executionLineId,
					Status__c = 'Success',
					CreatedQuote__c = quoteId,
					Message__c = null
				));
			}

			AmendContractResponse response = new AmendContractResponse();
			response.QuoteId = mapReqAmendId.get(contractId);
			responseList.add(response);
		}
		try {
			if (!quotesToUpdate.isEmpty()) {
				SBQQ.TriggerControl.disable();
				update quotesToUpdate;
				SBQQ.TriggerControl.enable();
			}
			if (!executionLinesToUpdate.isEmpty()) {
				update executionLinesToUpdate;
			}
		} catch (Exception ex) {
			PMC_ErrorLogClass.processException(ex);
		}
		return responseList;
	}

	public static QuoteModel LoadContract(String contractId) {
		String quoteJSON = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractAmender', contractId, null);
		return (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
	}

	public class AmendContractRequest {
		@InvocableVariable(label='Contract ID' description='The Salesforce Contract ID to amend')
		public String uid;
		@InvocableVariable(label='New Date Values' description='The new contract start date & end date')
		public String newDates;
		@InvocableVariable(label='Execution Line ID' description='The ID of the execution line context')
		public String executionLineId;
	}

	public class AmendContractResponse {
		@InvocableVariable(label='Amended Quote' description='The amended quote data')
		//public QuoteModel quote;
		public ID QuoteId;
	}

	public class ContractDatesClass {
		public Date PMC_CPQ_ContractStart;
		public Date PMC_CPQ_ContractEnd;
	}

}