/**
* @description This class will be used to handle to clear values of Contract mendment type and justification value.
* @author Swakeerth Gadda
* @storynumber GDASF-11118
*/

public with sharing class PMC_SS_ClearDependentFieldValues {
	/**
    * @description This method will be used to clear agreement type and justification values when case type is not transaction or issues reason is not amendment.
    * @param mapOldCases - Triggering case old version
	* @param lstNewCases - Triggering case records.
    */
    public static void clearDependentFieldValues(Map<Id, Case> mapOldCases, List<Case> lstNewCases){
        for(Case objCase : lstNewCases){
            if(
                (mapOldCases.get(objCase.Id).Type == PMC_SS_ConstantClass.CASE_TYPE_TRANSACTIONS && objCase.Type != PMC_SS_ConstantClass.CASE_TYPE_TRANSACTIONS) 
                || (mapOldCases.get(objCase.Id).PMC_SS_IssueReason__c == PMC_SS_ConstantClass.ISSUE_REASON_AMENDMENT && objCase.PMC_SS_IssueReason__c != PMC_SS_ConstantClass.ISSUE_REASON_AMENDMENT))
            	{
                objCase.PMC_SS_ContractAmendmentType__c	= null;
                objCase.PMC_SS_ContractAmendmentJustificationVal__c = null;
         	    }
            if(mapOldCases.get(objCase.Id).PMC_SS_IssueReason__c == PMC_SS_ConstantClass.ISSUE_REASON_ARTICLE_REQ && objCase.PMC_SS_IssueReason__c != mapOldCases.get(objCase.Id).PMC_SS_IssueReason__c) {
                objCase.PMC_SS_ArticleType__c = objCase.PMC_SS_IssueReason__c != PMC_SS_ConstantClass.ISSUE_REASON_ARTICLE_REQ ? '':objCase.PMC_SS_ArticleType__c;
            }
            clearCancellationSubReason(mapOldCases.get(objCase.Id),objCase);
            clearDependentFieldValues(mapOldCases.get(objCase.Id),objCase);
        }
    }
    /**
    * @description This method will be used to clear Contract Cancellation SubReason values.
    * @param objOldCase - Triggering case old version
	* @param objNewCase - Triggering case records.
    */
    private static void clearCancellationSubReason(Case objOldCase, Case objNewCase) {
        if(objOldCase.PMC_SS_ContractCancellation__c != objNewCase.PMC_SS_ContractCancellation__c && (objOldCase.PMC_SS_ContractCancellation__c == PMC_SS_ConstantClass.UNAPPROVED_CREDIT_LIMIT || objOldCase.PMC_SS_ContractCancellation__c == PMC_SS_ConstantClass.MOSAICS_FAILURE))
            {
                objNewCase.PMC_SS_ContractCancellationSubReason__c = objNewCase.PMC_SS_ContractCancellation__c != PMC_SS_ConstantClass.UNAPPROVED_CREDIT_LIMIT || objNewCase.PMC_SS_ContractCancellation__c != PMC_SS_ConstantClass.MOSAICS_FAILURE ? '':objNewCase.PMC_SS_ContractCancellationSubReason__c;
            }
    }
    /**
    * @description This method will be used to clear dependent field values.
    * @param objOldCase - Triggering case old version
	* @param objNewCase - Triggering case records.
    */
    Private static void clearDependentFieldValues(Case objOldCase, Case objNewCase){
            if(objNewCase.PMC_SS_IssueReason__c != objOldCase.PMC_SS_IssueReason__c || objNewCase.PMC_SS_MOT__c != objOldCase.PMC_SS_MOT__c  ) {
                objNewCase.PMC_SS_BadOrder__c =  objNewCase.PMC_SS_MOT__c != PMC_SS_ConstantClass.RAIL ? false:objNewCase.PMC_SS_BadOrder__c;
            }
        }   
}