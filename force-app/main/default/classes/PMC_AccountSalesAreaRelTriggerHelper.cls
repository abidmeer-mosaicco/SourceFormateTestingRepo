/**
* @description This class will be used to handle all trigger operations on AccountSalesAreaRelationship
* @author Megha Sunhare
* @storynumber GDASF-1065
* Test Class: PMC_AccountSalesAreaRelTriggerHelperTest
*/
public with sharing class PMC_AccountSalesAreaRelTriggerHelper {
    
    //Variable to cover the exception part
    @testVisible
    private static Boolean boolThrowException = false;
    
    /**
     * @description This method restrics one sales area per agent account
     * @param lstAccountSalesAreaRels List of AccountSalesAreaRelationship records
     */
    public static void validateSalesAreaForAgentAccount(List<PMC_SS_AccountSalesAreaRelationship__c> lstAccountSalesAreaRels){
        // Set variable to store the IDs of associated account records
        try{
            Set<Id> setAccountIds = new Set<Id>();
            // Set variable to store the IDs of accounts that are of type Agent
            Set<Id> setAgentAccountIds = new Set<Id>();
            
            for(PMC_SS_AccountSalesAreaRelationship__c objAccSalesAreaRel : lstAccountSalesAreaRels){
                setAccountIds.add(objAccSalesAreaRel.PMC_SS_Account__c);
            }

            for(PMC_SS_AccountSalesAreaRelationship__c objAccSalesAreaRel : [SELECT Id, PMC_SS_Account__c, PMC_SS_Account__r.Type FROM 
                                                                            PMC_SS_AccountSalesAreaRelationship__c WHERE 
                                                                            PMC_SS_Account__c IN :setAccountIds AND PMC_SS_Account__r.RecordType.DeveloperName = :PMC_SS_ConstantClass.STRING_AGENT_ACCOUNT_RECORDTYPE_NAME
                                                                            WITH SECURITY_ENFORCED]){
                setAgentAccountIds.add(objAccSalesAreaRel.PMC_SS_Account__c);
            }

            for(PMC_SS_AccountSalesAreaRelationship__c objAccSARel : lstAccountSalesAreaRels){
                //Check if the related agent account is already linked to a sales area record
                if(setAgentAccountIds.contains(objAccSARel.PMC_SS_Account__c)){
                    objAccSARel.PMC_SS_Account__c.addError(Label.PMC_SS_AccountSalesAreaRelationshipErrorMessage);
                }
            }
            
            if(boolThrowException){
                throw new QueryException();
            }
        }catch (QueryException objQueryException) {
            PMC_ErrorLogClass.processException(objQueryException);
        }
    }
}