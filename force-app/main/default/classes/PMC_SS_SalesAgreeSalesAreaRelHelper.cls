/**
* @description This class will be used to handle all triggers on Sales Agreement Sales Area Relation object.
* @author Swakeerth Gadda
* @storynumber GDASF-9729
*/

public with sharing class PMC_SS_SalesAgreeSalesAreaRelHelper {
    /**
    * @description This method will be used to validate if sales area matches on sales agreement sales area relation object from account sales area junction.
    * @param listSalesAgreeSalesAreaRel - Triggering sales agreement sales area relation records.
    */
    public static void salesAgreementToSalesAreaValidation(List<PMC_SalesAgreementSalesAreaRelation__c> listSalesAgreeSalesAreaRel){
		Map<Id, Id> mapSalesAgreementAccountId = new Map<Id, Id>();
		Set<Id> setSalesAgreementId = new Set<Id>();
		Map<Id, Set<Id>> mapAccountSalesArea = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> mapSalesAgreementSalesArea = new Map<Id, Set<Id>>();
        list<PMC_SalesAgreementSalesAreaRelation__c> listNewSalesAgreeSalesAreaRel = new list<PMC_SalesAgreementSalesAreaRelation__c>();
        for(PMC_SalesAgreementSalesAreaRelation__c salesAgreeSalesAreaRel : listSalesAgreeSalesAreaRel){
            If(salesAgreeSalesAreaRel.PMC_SS_SalesArea__c != null && salesAgreeSalesAreaRel.PMC_SS_SalesAgreement__c != null){
                //Get Sales Agreement ID's for relevant Sales Agreement Sales Area Relation Junction
                setSalesAgreementId.add(salesAgreeSalesAreaRel.PMC_SS_SalesAgreement__c);
                //Get relavent Sales Agreement Sales Area Relation to loop and add validation if necessary
                listNewSalesAgreeSalesAreaRel.add(salesAgreeSalesAreaRel);
            }
        }
        mapSalesAgreementAccountId = createSalesAgreementAccountIdMap(setSalesAgreementId);
        mapAccountSalesArea = createAccountIdAccountSalesAreaRelationshipMap(mapSalesAgreementAccountId);
        mapSalesAgreementSalesArea = createSalesAgreeIdSalesAreaRelMap(mapSalesAgreementAccountId, mapAccountSalesArea);
		//Loop to check Account - Sales Area relations for all relavent sales agreement sales area relationship
        for(PMC_SalesAgreementSalesAreaRelation__c salesAgreeSalesAreaRel : listNewSalesAgreeSalesAreaRel){
            If(!mapSalesAgreementSalesArea.containsKey(salesAgreeSalesAreaRel.PMC_SS_SalesAgreement__c) || (mapSalesAgreementSalesArea.containsKey(salesAgreeSalesAreaRel.PMC_SS_SalesAgreement__c) && !mapSalesAgreementSalesArea.get(salesAgreeSalesAreaRel.PMC_SS_SalesAgreement__c).contains(salesAgreeSalesAreaRel.PMC_SS_SalesArea__c))){
                salesAgreeSalesAreaRel.addError(Label.PMC_SS_SalesAgreementtoSalesAreaValidationMessage);
            }
        }
    }
    /**
     * @description this method is used to create a map of account id vs set of related sales area ids
     * @param mapSalesAgreementAccountId map of accountIds linked to Sales Agreement
     * @return Map<Id, Set<Id>> map of <accId, Set<SalesAreaId>>
     */
	private static Map<Id, Set<Id>> createAccountIdAccountSalesAreaRelationshipMap(Map<Id, Id> mapSalesAgreementAccountId){
		Map<Id, Set<Id>> mapAccountSalesArea = new Map<Id, Set<Id>>();
        If(mapSalesAgreementAccountId.KeySet().size() > 0 && PMC_SS_AccountSalesAreaRelationship__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible() && Schema.sObjectType.PMC_SS_AccountSalesAreaRelationship__c.fields.PMC_SS_Account__c.isAccessible() && Schema.sObjectType.PMC_SS_AccountSalesAreaRelationship__c.fields.PMC_SS_SalesArea__c.isAccessible()){
		//Loop to map Account - Sales Area relations for all related Accounts      
        for(PMC_SS_AccountSalesAreaRelationship__c accountSalesArea : [Select PMC_SS_Account__c, PMC_SS_SalesArea__c From PMC_SS_AccountSalesAreaRelationship__c Where PMC_SS_Account__c In : mapSalesAgreementAccountId.values()]){
            If(!mapAccountSalesArea.containsKey(accountSalesArea.PMC_SS_Account__c)){
                mapAccountSalesArea.put(accountSalesArea.PMC_SS_Account__c, new Set<Id>{accountSalesArea.PMC_SS_SalesArea__c});
            }
            else{
                Set<Id> existingSalesAreaSet = mapAccountSalesArea.get(accountSalesArea.PMC_SS_Account__c);
                existingSalesAreaSet.add(accountSalesArea.PMC_SS_SalesArea__c);
                mapAccountSalesArea.put(accountSalesArea.PMC_SS_Account__c, existingSalesAreaSet);
            }
        }
        }
        return mapAccountSalesArea;
    }
    
    /**
     * @description this method is used to create a map of sales agreement ids vs sales area ids
     * @param setSalesAgreementId set of Sales Agreement Ids
     * @return Map<Id, Id> map of <salesAgreementId, accountId>
     */
    private static Map<Id, Id> createSalesAgreementAccountIdMap(Set<Id> setSalesAgreementId){
        Map<Id, Id> mapSalesAgreementAccountId = new Map<Id, Id>();
        If(setSalesAgreementId.size() > 0 && SalesAgreement.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible() && Schema.sObjectType.SalesAgreement.fields.AccountId.isAccessible()){
            for(SalesAgreement salesAgreement : [Select Id, AccountId from SalesAgreement Where Id IN: setSalesAgreementId]){
                mapSalesAgreementAccountId.put(salesAgreement.Id, salesAgreement.AccountId);           
            }
        }
        return mapSalesAgreementAccountId;
    }
    
    /**
     * @description this method is used to create a map of sales agreement id vs set of related sales area ids
     * @param mapSalesAgreementAccountId map of accountIds linked to Sales Agreement
     * @param mapAccountSalesArea map of sales area ids linked to account Ids
     * @return Map<Id, Set<Id>> map of <salesAgreementId, Set<SalesAreaId>>
     */
    private static Map<Id, Set<Id>> createSalesAgreeIdSalesAreaRelMap(Map<Id, Id> mapSalesAgreementAccountId, Map<Id, Set<Id>> mapAccountSalesArea){
		Map<Id, Set<Id>> mapSalesAgreementSalesArea = new Map<Id, Set<Id>>();
        for(Id salesAgreementId: mapSalesAgreementAccountId.KeySet()){
            Id accountId = mapSalesAgreementAccountId.get(salesAgreementId);
            if(mapAccountSalesArea.containsKey(accountId) && mapAccountSalesArea.get(accountId).size() > 0){
                mapSalesAgreementSalesArea.put(salesAgreementId, mapAccountSalesArea.get(accountId));
            }
        }
		return mapSalesAgreementSalesArea;
    }
}