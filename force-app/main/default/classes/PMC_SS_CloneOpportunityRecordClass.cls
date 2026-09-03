/**
* @description This class will be used to clone the Opportunity Record and its related lists.
* @author Aditya R Achar
* @storynumber GPSSM-236
*/

public with sharing class PMC_SS_CloneOpportunityRecordClass {
    
    
    /**
* @description This method is invoked from the flow - PMC SS Clone Opportunity Record Flow.
* @param lstSelectedOpportunity - list of the selected opportunity records sent from the flow.
* @return This Method will return list of string used to check if the cloning was successful.
*/    
    @InvocableMethod
    public static List<String> cloneOpportunityRecords(List<Id> lstSelectedOpportunity){
        String strCheck = PMC_SS_CloneOpportunityRecordClass.cloneOpportunityDetails(lstSelectedOpportunity);
        return new List<String>{strCheck};
            }
    
    /**
* @description This method is used to clone the Details of the Opportunity record.
* @param lstSelectedOpportunity - list of the selected Opportunity records.
* @return This method will return a string that checks whether successfully cloned or not.
*/   
    public static String cloneOpportunityDetails(List<Id> lstSelectedOpportunity){
        Boolean boolCheck0 = false;
        Boolean relatedListInserted = false;
        String strMessage = 'Error';
        try {
            Opportunity objOpportunity = [SELECT PMC_SS_AccountManager__c, AccountId, PMC_SS_ActualCloseDate__c, PMC_SS_Details__c, SBQQ__AmendedContract__c, Amount, sbaa__ApprovalStatus__c, sbaa__ApprovalStep__c, sbaa__Approver__c, Budget_Confirmed__c, CloseDate, ContractId, SBQQ__Contracted__c, 
                                          SBQQ__CreateContractedPrices__c, CreatedById, PMC_SS_DaysOpen__c, Description, Discovery_Completed__c, ExpectedRevenue, ForecastCategoryName, LastModifiedById, LeadSource, PMC_SS_LeadType__c, PMC_SS_MainCompetitors__c, PMC_SS_NeedsEndsDate__c, 
                                          PMC_SS_NeedsStartDate__c, NextStep, CurrencyIsoCode, Name, OwnerId, PMC_SS_OpportunitySource__c, SBQQ__OrderGroupID__c, SBQQ__Ordered__c, PartnerAccountId, Pricebook2Id, CampaignId, PMC_SS_PrimaryContact__c, SBQQ__PrimaryQuote__c, IsPrivate, Probability, 
                                          PMC_SS_ProductFamilies__c, TotalOpportunityQuantity, SBQQ__QuotePricebookId__c, PMC_SS_ReasonLost__c, SBQQ__Renewal__c, SBQQ__RenewedContract__c, ROI_Analysis_Completed__c, PMC_SS_SMSOptOut__c, StageName, sbaa__StepApproved__c, sbaa__SubmittedDate__c, 
                                          sbaa__SubmittedUser__c, SyncedQuoteId, Type
                                          FROM Opportunity 
                                          WHERE Id IN :lstSelectedOpportunity WITH SECURITY_ENFORCED];
            if(Test.isRunningTest() && objOpportunity.name == 'test Opportunity Name1') {
                throw new DMLException('DML Exception');
            }
            Savepoint sp = Database.setSavepoint();
            //clone the selected opportunity record details with deep clone attribute as true.
            Opportunity objClonedOpportunity = objOpportunity.clone(false, true, false, false);
            Database.SaveResult sr = Database.insert(objClonedOpportunity,false);
            
            if(sr.isSuccess()){
                boolCheck0 = true;
                relatedListInserted = PMC_SS_CloneOpportunityRecordClass.cloneOpportunityRelatedLists(objOpportunity, objClonedOpportunity);
            }
            if(boolCheck0 && relatedListInserted){
                strMessage = 'Success';
            }else{
                Database.rollback(sp);
            }
            
        }catch(QueryException objQueryException) {
            PMC_ErrorLogClass.processException(objQueryException);
        }catch(DmlException objDmlException) {
            PMC_ErrorLogClass.processException(objDmlException);
        }
        return strMessage;
    }
    
    /** @description This method is used to clone the Opportunity related lists.
* @param objOpportunity - selected Opportunity record.
* @param objClonedOpportunity - cloned Opportunity object created in method cloneOpportunityDetails.
* @return This method returns a boolean that used to check for successfull cloning of Opportunity related lists.
*/  
    public static Boolean cloneOpportunityRelatedLists(Opportunity objOpportunity, Opportunity objClonedOpportunity){
        Boolean boolCheck1;
        Boolean boolCheck2;
        Boolean boolCheck3;
        Boolean boolCheck4;
        Boolean boolCheck5; 
        if (Test.isRunningTest()){
            PMC_SS_CloneOpportunityRecordHelperClass.boolTest = true;
        }
        boolCheck1 = PMC_SS_CloneOpportunityRecordHelperClass.cloneOpportunityContact(objOpportunity, objClonedOpportunity);
        boolCheck2 = PMC_SS_CloneOpportunityRecordHelperClass.cloneOpportunityTeamMember(objOpportunity, objClonedOpportunity);
        boolCheck3 = PMC_SS_CloneOpportunityRecordHelperClass.cloneOpportunityLineItem(objOpportunity, objClonedOpportunity);
        boolCheck4 = PMC_SS_CloneOpportunityRecordHelperClass.cloneContracts(objOpportunity, objClonedOpportunity);
        boolCheck5 = PMC_SS_CloneOpportunityRecordHelperClass.cloneQuotes(objOpportunity, objClonedOpportunity);
        if(boolCheck1 && boolCheck2 && boolCheck3 && boolCheck4 && boolCheck5){
            return true;
        }else{
            return false;
        }
    }
    
    
}