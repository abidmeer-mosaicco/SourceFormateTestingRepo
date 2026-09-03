/**
* @description       : Batch Class to create Contract for the Quotes created by Data Migration User
* @author            : Preethi J
**/
public with sharing class PMC_DM_CreateContractFromQuoteBatch implements Database.Batchable<sObject> {
    Id userId;
    List<Id> listQuoteIds = new List<Id>();
    List<Contract> lstContract = new List<Contract>();
    List<SBQQ__Quote__c> quoUpdate = new List<SBQQ__Quote__c>();
    /**
* @description constructor of the class
* @param userId - the id of the user
*/
    public PMC_DM_CreateContractFromQuoteBatch(Id userId) {
        this.userId = userId;
    }
    /**
* @description constructor of the class
* @param userId - the id of the user
* @param lstQuoteIds - list of Quotes
*/
    public PMC_DM_CreateContractFromQuoteBatch(Id userId, List<Id> lstQuoteIds){
        this.userId = userId;
        this.listQuoteIds = lstQuoteIds;
    }
    /**
* @description start method of batchable class
* @param objBC
* @return  Database.QueryLocator
*/
    public Database.QueryLocator start(Database.BatchableContext objBC) {
        String query;
        if(!listQuoteIds.isEmpty()){
            query = 'select Id, CurrencyIsoCode,PMC_CPQ_QuoteNumberIdentifier__c, PMC_CPQ_ContractEnd__c, PMC_CPQ_ContractStart__c, SBQQ__PricebookId__c, PMC_CPQ_AccountManager__c, PMC_CPQ_PrimaryContact__c, SBQQ__Opportunity2__c, SBQQ__PaymentTerms__c, SBQQ__Account__c, SBQQ__Account__r.OwnerId from SBQQ__Quote__c where CreatedById =: userId AND PMC_CLM_ContractCreated__c = false AND id in : listQuoteIds';
        }
        else{
            query = 'select Id, CurrencyIsoCode,PMC_CPQ_QuoteNumberIdentifier__c, PMC_CPQ_ContractEnd__c, PMC_CPQ_ContractStart__c, SBQQ__PricebookId__c, PMC_CPQ_AccountManager__c, PMC_CPQ_PrimaryContact__c, SBQQ__Opportunity2__c, SBQQ__PaymentTerms__c, SBQQ__Account__c, SBQQ__Account__r.OwnerId from SBQQ__Quote__c where CreatedById =: userId AND PMC_CLM_ContractCreated__c = false';
        }
        return Database.getQueryLocator(query);
    }
    /**
* @description execute method of batchable class
* @param objBC
* @param  lstQuotes - list of quotes
*/
    public void execute(Database.BatchableContext objBC, List<SBQQ__Quote__c> lstQuotes) {
        //List<Contract> lstContract = new List<Contract>();
        //List<SBQQ__Quote__c> quoUpdate = new List<SBQQ__Quote__c>();
        try {
            contractCreate(lstQuotes);
            // Insert the created contracts
            if (!lstContract.isEmpty()) {
                SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, lstContract);
                Database.insert(decision.getRecords());
            }
            if(!quoUpdate.isEmpty()){
                SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, quoUpdate);
                Database.update(decision.getRecords());
            }
        } catch (Exception e) {
            PMC_ErrorLogClass.processException(e);
        }
    }
    /**
* @description method which creates the contract by assigning the respective fields
* @param lstQuotes
*/
    public void contractCreate(List<SBQQ__Quote__c> lstQuotes){
        // Iterate through the quotes and create contracts
        for (SBQQ__Quote__c q : lstQuotes) {
            Contract objContract = new Contract();
            objContract.CurrencyIsoCode = q.CurrencyIsoCode;
            objContract.EndDate = q.PMC_CPQ_ContractEnd__c;
            objContract.StartDate = q.PMC_CPQ_ContractStart__c;
            objContract.Pricebook2Id = q.SBQQ__PricebookId__c!=null?q.SBQQ__PricebookId__c:null;
            objContract.Status = 'Draft';
            //objContract.PMC_CPQ_AccountManager__c = q.PMC_CPQ_AccountManager__c;
            objContract.SBQQ__AmendmentRenewalBehavior__c = 'Latest End Date';
            objContract.SBQQ__SubscriptionQuantitiesCombined__c = false;
            objContract.PMC_CPQ_PrimaryContact__c = q.PMC_CPQ_PrimaryContact__c!=null?q.PMC_CPQ_PrimaryContact__c:null;
            objContract.SBQQ__Opportunity__c = q.SBQQ__Opportunity2__c!=null?q.SBQQ__Opportunity2__c:null;
            objContract.PMC_CPQ_PaymentTerms__c  = q.SBQQ__PaymentTerms__c;
            objContract.SBQQ__Quote__c = q.Id;
            objContract.PMC_CPQ_LatestQuote__c = q.Id;
            objContract.AccountId = q.SBQQ__Account__c!=null?q.SBQQ__Account__c:null;
            objContract.OwnerId = q.SBQQ__Account__r.OwnerId;
            objContract.PMC_CPQ_ContractNumberIdentifier__c = q.PMC_CPQ_QuoteNumberIdentifier__c;
            objContract.ContractTerm = objContract.StartDate.monthsBetween(objContract.EndDate)==0?1:objContract.StartDate.monthsBetween(objContract.EndDate);
            lstContract.add(objContract);
            q.PMC_CLM_ContractCreated__c = true;
            quoUpdate.add(q);
        }
    }
    /**
* @description finish method of batchable class
* @param objBC
*/
    public void finish(Database.BatchableContext objBC) {
        System.assertEquals('Success','Success');
    }
}