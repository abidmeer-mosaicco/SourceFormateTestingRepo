/**
 * @description This test class will be used to cover all the methods of PMC_SS_SalesAgreeSalesAreaRelHandler and PMC_SS_SalesAgreeSalesAreaRelHelper.
 * @author Swakeerth Gadda
 */
@isTest
private with sharing class PMC_SS_SalesAgreeSalesAreaRelHandlerTest{

    /**
    * @description This Method will be used to setup the test data for the test class execution.
    */
    
    @testsetup
    private static void setup() {
        
        List<Profile> lstUserProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
        List<Account> lstAccounts = new List<Account>();
        Account objAccount;
        
        if(lstUserProfile != null && !lstUserProfile.isEmpty()) {
            
            List<User> lstUser = PMC_TestUtilityClass.createUser(2);
            if(lstUser != null && !lstUser.isEmpty()) {
                for(User objUser : lstUser) {
                    objUser.ProfileId = lstUserProfile[0].Id;
                }
            }
            insert lstUser;
            
            for(Integer intAccountCount = 0; intAccountCount < 2; intAccountCount++) {
                objAccount = new Account();
                objAccount = PMC_TestUtilityClass.createAccount('Deloitte' + intAccountCount,'PMC_SS_Customer');
                lstAccounts.add(objAccount);
            }
                  
            List<PMC_SS_SalesArea__c> listSalesArea = PMC_TestUtilityClass.createSalesArea(4, null);
            PMC_TestUtilityClass.createAccountSalesAreaRelationship(lstAccounts, new List<PMC_SS_SalesArea__c>{listSalesArea[0],listSalesArea[1]});
			PMC_TestUtilityClass.createAccountSalesAreaRelationship(lstAccounts, new List<PMC_SS_SalesArea__c>{listSalesArea[2],listSalesArea[3]});
			Pricebook2 priceBook = new Pricebook2();
            priceBook.Name = 'Test';
            priceBook.IsActive = true;
            priceBook.Description = 'Test1';
            insert priceBook;
            SalesAgreement salesAgreement = new SalesAgreement();
            salesAgreement.Name = 'Test Sales Agreement';
            salesAgreement.Status = PMC_SS_ConstantClass.SALES_AGREEMENT_STATUS_DRAFT;
            salesAgreement.StartDate = System.Today();
            salesAgreement.AccountId = [Select Id From Account Where Name = 'Deloitte1' limit 1].Id;
            salesAgreement.ScheduleFrequency = PMC_SS_ConstantClass.SALES_AGREEMENT_SCHEDULEFREQUENCY_WEEKLY;
            salesAgreement.ScheduleCount = 24;
            salesAgreement.CurrencyIsoCode = PMC_SS_ConstantClass.SALES_AGREEMENT_CURRENCYISOCODE_USD;
            salesAgreement.ProductLevel = PMC_SS_ConstantClass.SALES_AGREEMENT_PRODUCTLEVEL_PRODUCT;
            salesAgreement.PricebookId = [Select Id From Pricebook2 Where Name = 'Test' limit 1].Id;
            insert salesAgreement;
        }
    }
    @isTest
    static void validateSalesAgreementSalesAreaInsertTest(){
        string hasErrorMessage;
        PMC_SalesAgreementSalesAreaRelation__c salesAgreeSalesAreaRel = new PMC_SalesAgreementSalesAreaRelation__c();
        salesAgreeSalesAreaRel.PMC_SS_SalesAgreement__c = [Select Id From SalesAgreement Where name = 'Test Sales Agreement'].Id;
        salesAgreeSalesAreaRel.PMC_SS_SalesArea__c = [Select Id From PMC_SS_SalesArea__c Where name = 'test Sales Area Name0'].Id;
        try{
			insert salesAgreeSalesAreaRel;
        }
        catch(exception ex){
            hasErrorMessage = ex.getMessage();
        }
        system.assertEquals(true, hasErrorMessage.contains(Label.PMC_SS_SalesAgreementtoSalesAreaValidationMessage), 'Has validation message for salesarea');
    }
    @isTest
    static void validateSalesAgreementSalesAreaUpdateTest(){
        string hasErrorMessage = '';
        PMC_SalesAgreementSalesAreaRelation__c salesAgreeSalesAreaRel = new PMC_SalesAgreementSalesAreaRelation__c();
        salesAgreeSalesAreaRel.PMC_SS_SalesAgreement__c = [Select Id From SalesAgreement Where name = 'Test Sales Agreement'].Id;
        salesAgreeSalesAreaRel.PMC_SS_SalesArea__c = [Select Id From PMC_SS_SalesArea__c Where name = 'test Sales Area Name1'].Id;
		insert salesAgreeSalesAreaRel;
        try{
			salesAgreeSalesAreaRel.PMC_SS_SalesArea__c = [Select Id From PMC_SS_SalesArea__c Where Name = 'test Sales Area Name0'].Id;
            update salesAgreeSalesAreaRel;
        }
        catch(exception ex){
            hasErrorMessage = ex.getMessage();
        }
        system.assertEquals(true, hasErrorMessage.contains(Label.PMC_SS_SalesAgreementtoSalesAreaValidationMessage), 'Has validation message for salesarea');
    }
    @isTest
    static void validateSalesAgreementSalesAreaBypassInsertTest(){
        string hasErrorMessage = '';
        PMC_SalesAgreementSalesAreaRelation__c salesAgreeSalesAreaRel = new PMC_SalesAgreementSalesAreaRelation__c();
        salesAgreeSalesAreaRel.PMC_SS_SalesAgreement__c = [Select Id From SalesAgreement Where name = 'Test Sales Agreement'].Id;
        salesAgreeSalesAreaRel.PMC_SS_SalesArea__c = [Select Id From PMC_SS_SalesArea__c Where name = 'test Sales Area Name0'].Id;
        try{
            PMC_SS_SalesAgreeSalesAreaRelHandler.boolBypassTriggerLogic = true;
            insert salesAgreeSalesAreaRel;
        }
        catch(exception ex){
            hasErrorMessage = ex.getMessage();
        }
		system.assertEquals(false, hasErrorMessage.contains(Label.PMC_SS_SalesAgreementtoSalesAreaValidationMessage), 'Has no validation message for salesarea');
    }
    @isTest
    static void validateSalesAgreementSalesAreaBypassUpdateTest(){
        string hasErrorMessage = '';
        PMC_SalesAgreementSalesAreaRelation__c salesAgreeSalesAreaRel = new PMC_SalesAgreementSalesAreaRelation__c();
        salesAgreeSalesAreaRel.PMC_SS_SalesAgreement__c = [Select Id From SalesAgreement Where name = 'Test Sales Agreement'].Id;
        salesAgreeSalesAreaRel.PMC_SS_SalesArea__c = [Select Id From PMC_SS_SalesArea__c Where name = 'test Sales Area Name1'].Id;
		insert salesAgreeSalesAreaRel;
        try{
			PMC_SS_SalesAgreeSalesAreaRelHandler.boolBypassTriggerLogic = true;
            update salesAgreeSalesAreaRel;
        }
        catch(exception ex){
            hasErrorMessage = ex.getMessage();
        }
		system.assertEquals(false, hasErrorMessage.contains(Label.PMC_SS_SalesAgreementtoSalesAreaValidationMessage), 'Has no validation message for salesarea');
    }
    @isTest
    static void validateSalesAgreementSalesAreaDeleteTest(){
        string hasErrorMessage = '';
        PMC_SalesAgreementSalesAreaRelation__c salesAgreeSalesAreaRel = new PMC_SalesAgreementSalesAreaRelation__c();
        salesAgreeSalesAreaRel.PMC_SS_SalesAgreement__c = [Select Id From SalesAgreement Where name = 'Test Sales Agreement'].Id;
        salesAgreeSalesAreaRel.PMC_SS_SalesArea__c = [Select Id From PMC_SS_SalesArea__c Where name = 'test Sales Area Name1'].Id;
		insert salesAgreeSalesAreaRel;
        try{
			PMC_SS_SalesAgreeSalesAreaRelHandler.boolBypassTriggerLogic = true;
            delete salesAgreeSalesAreaRel;
        }
        catch(exception ex){
            hasErrorMessage = ex.getMessage();
        }
		system.assertEquals(false, hasErrorMessage.contains(Label.PMC_SS_SalesAgreementtoSalesAreaValidationMessage), 'Has no validation message for salesarea');
    }
    @isTest
    static void validateSalesAgreementSalesAreaUndeleteTest(){
        string hasErrorMessage = '';
        PMC_SalesAgreementSalesAreaRelation__c salesAgreeSalesAreaRel = new PMC_SalesAgreementSalesAreaRelation__c();
        salesAgreeSalesAreaRel.PMC_SS_SalesAgreement__c = [Select Id From SalesAgreement Where name = 'Test Sales Agreement'].Id;
        salesAgreeSalesAreaRel.PMC_SS_SalesArea__c = [Select Id From PMC_SS_SalesArea__c Where name = 'test Sales Area Name1'].Id;
		insert salesAgreeSalesAreaRel;
        delete salesAgreeSalesAreaRel;
        try{
			PMC_SS_SalesAgreeSalesAreaRelHandler.boolBypassTriggerLogic = true;
            undelete salesAgreeSalesAreaRel;
        }
        catch(exception ex){
            hasErrorMessage = ex.getMessage();
        }
		system.assertEquals(false, hasErrorMessage.contains(Label.PMC_SS_SalesAgreementtoSalesAreaValidationMessage), 'Has no validation message for salesarea');
    }
}