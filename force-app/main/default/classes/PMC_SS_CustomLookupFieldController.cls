/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-20-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class PMC_SS_CustomLookupFieldController {

     /**
     * @description - Method used to fetch Orders
     * @param strSearchTerm - Search String i.e. OrderNumber
     * @param strObjectName - Object Name
     * @param strFilter - Filter
     * @return List<sObject> - Returns List of SObject
     */
    @AuraEnabled(cacheable=true)
    public static List<SObject> searchOrder(String strSearchTerm, string strObjectName, String strFilter) {
        String strQuery = null;
        if(strFilter != null && strFilter != ''){
            strQuery = 'Select Id, OrderNumber,PMC_CPQ_SAPOrderNumber__c,PMC_CPQ_PO__c,Status,PMC_CPQ_SAPContractReference__c from '+String.escapeSingleQuotes(strObjectName)+' Where AccountId = \'' + String.escapeSingleQuotes(strFilter) + '\'' +' LIMIT  49999';//GSMD-1467
        }
        else {
            if(strSearchTerm == null || strSearchTerm == ''){
                strQuery = 'Select Id, OrderNumber,PMC_CPQ_SAPOrderNumber__c,PMC_CPQ_PO__c,Status,PMC_CPQ_SAPContractReference__c from '+String.escapeSingleQuotes(strObjectName)+' Where LastViewedDate != NULL ORDER BY LastViewedDate DESC LIMIT  49999';//GSMD-1467
            }
            else {
                strQuery = 'Select Id, OrderNumber,PMC_CPQ_SAPOrderNumber__c,PMC_CPQ_PO__c,Status,PMC_CPQ_SAPContractReference__c from '+String.escapeSingleQuotes(strObjectName)+' Where OrderNumber Like  \'%' + String.escapeSingleQuotes(strSearchTerm) + '%\' LIMIT  49999';//GSMD-1467
            }
        }
        System.debug('strQuery1=> '+strQuery);
        System.debug('strQuery2=> '+strQuery);
        System.debug('strQuery3=> '+strQuery);

        List<sObject> lstLookUpList = database.query(strQuery);
        return lstLookUpList;
    }
}