/**
 * @description This is the controller class for Advanced Approvals on Case
 */
public with sharing class CaseExtController {
  private Id caseId;
     /**
     * @description This is the constructor of the class
     * @param stdController - The instance of the standard controller
     */
      public CaseExtController(ApexPages.StandardController stdController) {
        caseId = stdController.getId();
      }
     /**
     * @description Method that executes when quote is submitted for approval
     * @return The page reference to the quote
     */
      public PageReference onSubmit() {
        if (caseId != null) {
          SBAA.ApprovalAPI.submit(caseId, SBAA__Approval__c.Case__c);
        }
        return new PageReference('/' + caseId);
      }
     /**
     * @description Method that executes when approval is recalled
     * @return The page reference to the quote
     */
      public PageReference onRecall() {
        if (caseId != null) {
          SBAA.ApprovalAPI.recall(caseId, SBAA__Approval__c.Case__c);
        }
        return new PageReference('/' + caseId);
      }
    
    @InvocableMethod(label='Invoke Submit for Approval Action')
    public static void invokeURLAction(List<String> recordIds) {
        System.Debug('Record ID Outside: '+recordIds);
        for (String recordId : recordIds) {
            System.Debug('Record ID Inside: '+recordId);
            if (recordId != null) {
          		SBAA.ApprovalAPI.submit(recordId, SBAA__Approval__c.Case__c);
        	}
        }
    }
}