/**
 * Queueable class to process MassUpdateExecutionLine__c records and call amendment logic.
 */
public with sharing class ContractDateAmendmentQueueable implements Queueable, Database.AllowsCallouts {
    private Id executionLineId;
    private Id executionId;

    public ContractDateAmendmentQueueable(Id executionLineId, Id executionId) {
        this.executionLineId = executionLineId;
        this.executionId = executionId;
    }

    public void execute(QueueableContext context) {
        if (executionLineId == null) {
            return;
        }

        MassUpdateExecutionLine__c line = [SELECT Id, Contract__c, NewValues__c, Status__c, Step__c, FinishedSteps__c FROM MassUpdateExecutionLine__c WHERE Id = :executionLineId LIMIT 1];

        try {
            PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest req = new PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest();
            req.uid = line.Contract__c;
            req.executionLineId = String.valueOf(executionLineId);
            PMC_CPQ_ContractDateAmenderFlowHandler.ContractDatesClass dates = new PMC_CPQ_ContractDateAmenderFlowHandler.ContractDatesClass();
            if (String.isNotBlank(line.NewValues__c)) {
                Map<String, Object> nv = (Map<String, Object>) JSON.deserializeUntyped(line.NewValues__c);
                String sStart = (String) nv.get('PMC_CPQ_ContractStart__c');
                String sEnd = (String) nv.get('PMC_CPQ_ContractEnd__c');
                Date sd = StringUtils.toDate(sStart);
                Date ed = StringUtils.toDate(sEnd);
                dates.PMC_CPQ_ContractStart = sd;
                dates.PMC_CPQ_ContractEnd = ed;
            }
            req.newDates = JSON.serialize(dates);
            List<PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest> singleReq = new List<PMC_CPQ_ContractDateAmenderFlowHandler.AmendContractRequest>{ req };
            PMC_CPQ_ContractDateAmenderFlowHandler.amendContract(singleReq);
            line = (MassUpdateExecutionLine__c) SObjectUtils.addPicklistValueToMultiSelect(line, 'FinishedSteps__c', 'Generate Amendments');
            line.Status__c = 'In Progress';
            line.Step__c = 'Check Eligibility';
            update line;
			System.enqueueJob(new ContractUpdateCheckEligibilityQueueable(line.Id, executionId));
        } catch (Exception ex) {
            update new MassUpdateExecutionLine__c(
                Id = line.Id,
                Message__c = ex.getMessage(),
                Status__c = 'Error',
                Step__c = 'Generate Amendments'
            );
        }
    }
}