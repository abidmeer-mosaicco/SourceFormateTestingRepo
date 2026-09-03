/**
* @description       : Controller for fetching Case History
* @author            : @Lohitha sai
* Last modified by   : Sugunkar
* @group             : 
* @Created on        : 02-02-2024
**/
//public with sharing class PMC_DH_CaseListViewController {
public with sharing class PMC_DH_CaseListViewController {
    /**
* @description   : Search case records
* @return        : PMC_DH_CaseListWrapper
* @param           caseWrapper
* @param           effAccId
* @author        : @Lohitha Sai
* @date          : 06-28-2023
*/
    @AuraEnabled
    public static PMC_DH_CaseListWrapper searchCaseRecords(PMC_DH_CaseWrapper caseWrapper, Id effAccId){
        PMC_DH_CaseListWrapper caseListWrap = new PMC_DH_CaseListWrapper();
        String query = 'SELECT Id, CaseNumber, CreatedDate, Subject, LastModifiedDate, tolabel(PMC_SS_IssueReason__c), PMC_SS_CaseStatus__c FROM Case WHERE AccountId = :effAccId';
    try{
        if(caseWrapper!=null){
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
    if (String.isNotBlank(caseWrapper.strSearchTerm)) {
        String searchPattern = '\'%' + String.escapeSingleQuotes(caseWrapper.strSearchTerm) + '%\'';
        query += ' AND (CaseNumber LIKE ' + searchPattern;
        query += ' OR tolabel(PMC_SS_IssueReason__c) LIKE ' + searchPattern;
        query += ' OR Subject LIKE ' + searchPattern;
        query += ' OR PMC_SS_CaseStatus__c LIKE ' + searchPattern;
        query += ')';
    }

    if (caseWrapper.strFromDate != null && caseWrapper.strToDate != null) {
            query += ' AND';       
            query += ' (CreatedDate >= ' + caseWrapper.strFromDate + PMC_DH_ConstantClass.START_TIME;
            query += ' AND ';
            query += 'CreatedDate <= ' + caseWrapper.strToDate + PMC_DH_ConstantClass.END_TIME;
            query += ')';
    }
    }
        query += ' WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC LIMIT 1000';
        String queryRes = query.replace('\\', '');
        caseListWrap.lstCases = Database.query(queryRes);
        caseListWrap.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'CaseList');
    }catch(Exception ex){
        caseListWrap.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
        PMC_ErrorLogClass.processException(ex); // MDErrorLog
    }   
    return caseListWrap;
}
   
/**
@description Wrapper for searchCase params
**/
public class PMC_DH_CaseWrapper{
    /**
     * @description String to searchTerm
     * @return String
     */
    @AuraEnabled
    public String strSearchTerm{get;set;}
    /**
     * @description String to fromDate
     * @return String
     */
    @AuraEnabled
    public String strFromDate{get;set;}
    /**
     * @description String to toDate
     * @return String
     */
    @AuraEnabled
    public String strToDate{get;set;}
}

/**
@description Wrapper for cases list
**/
    // Main class is with sharing, wrapper is modified to sharing
public with sharing class PMC_DH_CaseListWrapper{
    /**
     * @description List of cases
     * @return List<PMC_DH_CaseWrapper>
     */
    @AuraEnabled
    public List<Case> lstCases{get;set;}
    
    /**
     * @description Status Code and message
     * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
     */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
}
}