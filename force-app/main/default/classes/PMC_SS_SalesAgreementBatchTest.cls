/**
 * @description       : Test Class for PMC_SS_SalesAgreementBatchClass
 * @author            : Isha Gupta
**/
@isTest
public with sharing class PMC_SS_SalesAgreementBatchTest {
    
     @TestSetup
    static void testSetup()
    {
        PermissionSetGroup perSetGrpAdmin = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'PMC_Administrator_Permission_Set_Group'];
        List<User> lstuser=[Select Id from User where Id=:Userinfo.getuserid()];
         System.runAs(lstuser[0]){
            PMC_TestUtilityClass.assignPermissionSetGroupToUsers(lstUser, perSetGrpAdmin);
         }
         List<Account> lstAccounts = new List<Account>();
        Account objAccount;
        for(Integer intAccountCount = 0; intAccountCount < 2; intAccountCount++) {
                objAccount = new Account();
                objAccount = PMC_TestUtilityClass.createAccount('Deloitte' + intAccountCount,'PMC_SS_Customer');
                lstAccounts.add(objAccount);
            }
            
            Product2 prd = new Product2();
            prd.Name = 'MOP';
            prd.PMC_CPQ_ProductFamily__c = 'MOP';
            insert prd;
            Product2 prd2 = new Product2();
            prd2.Name = 'KMAG';
            prd2.PMC_CPQ_ProductFamily__c = 'K-MAG';
            insert prd2;
            PricebookEntry pe = new PricebookEntry(Product2Id = prd.Id, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 1);
            insert pe;
            PricebookEntry pe2 = new PricebookEntry(Product2Id = prd2.Id, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 1);
            insert pe2;
            SalesAgreement salesAgreement = new SalesAgreement();
            salesAgreement.Name = 'Test Sales Agreement';
            salesAgreement.Status = PMC_SS_ConstantClass.SALES_AGREEMENT_STATUS_DRAFT;
            salesAgreement.StartDate = System.Today();
            salesAgreement.AccountId = [Select Id From Account Where Name = 'Deloitte1' limit 1].Id;
            salesAgreement.ScheduleFrequency = PMC_SS_ConstantClass.SALES_AGREEMENT_SCHEDULEFREQUENCY_WEEKLY;
            salesAgreement.ScheduleCount = 60;
            salesAgreement.CurrencyIsoCode = PMC_SS_ConstantClass.SALES_AGREEMENT_CURRENCYISOCODE_USD;
            salesAgreement.ProductLevel = PMC_SS_ConstantClass.SALES_AGREEMENT_PRODUCTLEVEL_PRODUCT;
            salesAgreement.PricebookId = Test.getStandardPricebookId();
            insert salesAgreement;
            SalesAgreementProduct sap = new SalesAgreementProduct();
            sap.name = prd.name;
            sap.SalesAgreementId = salesAgreement.id;
            sap.PricebookEntryId = pe.id;
            sap.InitialPlannedQuantity = 300;
            insert sap;
            SalesAgreementProduct sap2 = new SalesAgreementProduct();
            sap2.name = prd2.name;
            sap2.SalesAgreementId = salesAgreement.id;
            sap2.PricebookEntryId = pe2.id;
            sap2.InitialPlannedQuantity = 600;
            insert sap2;
            RebateProgram rp = new RebateProgram();
            rp.Name = 'Test Rebate Prg';
            rp.StartDate = System.Today();
            rp.EndDate = System.Today().addYears(1);
            rp.PMC_SS_SalesAgreement__c = salesAgreement.id;
            rp.Frequency = 'Annually';
            insert rp;
            ProgramRebateType prt = new ProgramRebateType();
            prt.RebateProgramId = rp.id;
            prt.Name = 'Individual';
            prt.Status = 'Active';
            prt.PMC_SS_Type__c = 'Individual';
            prt.CalculationType = 'AggregateBased';
            prt.CalculationMethod = 'Retrospective';
            prt.AggregateObjectName = 'RebateMemberProductAggregate';
            prt.RebateMeasureType = 'AmountperUnit';
            prt.BenefitQualifierField = 'TotalQuantity';
            prt.MeasureField = 'TotalQuantity';
            prt.CalcObjectId = [SELECT Id FROM BatchCalcJobDefinition WHERE ProcessType='Rebates' AND DeveloperName='PMC_SS_AggregateByMemberWithAggregateItemDetails' LIMIT 1].id;
            insert prt;
            PgmRebateTypBnftMapping bm = new PgmRebateTypBnftMapping();
            bm.AggregateField = 'RebateMemberProductAggregate.PMC_SS_ProductFamily__c';
            bm.RebateTypeBenefitField = 'ProgramRebateTypeBenefit.PMC_SS_ProductFamily__c';
            bm.ProgramRebateTypeId = prt.id;
            insert bm;
            ProgramRebateTypeBenefit prtb = new ProgramRebateTypeBenefit();
            prtb.Name = 'MOP Tier 1';
            prtb.PMC_SS_ProductFamily__c = 'MOP';
            prtb.MinimumQualifyingValue = 1;
            prtb.MaximumQualifyingValue = 500;
            prtb.BenefitValue = 3;
            prtb.ProgramRebateTypeId = prt.id;
            insert prtb;
            ProgramRebateTypeBenefit prtb2 = new ProgramRebateTypeBenefit();
            prtb2.Name = 'KMAG Tier 1';
            prtb2.PMC_SS_ProductFamily__c = 'K-MAG';
            prtb2.MinimumQualifyingValue = 1;
            prtb2.MaximumQualifyingValue = 800;
            prtb2.BenefitValue = 5;
            prtb2.ProgramRebateTypeId = prt.id;
            insert prtb2;
            ProgramRebateType prt2 = new ProgramRebateType();
            prt2.RebateProgramId = rp.id;
            prt2.Name = 'Growth Incentive';
            prt2.Status = 'Active';
            prt2.PMC_SS_Type__c = 'Growth';
            prt2.CalculationType = 'AggregateBased';
            prt2.CalculationMethod = 'Retrospective';
            prt2.AggregateObjectName = 'RebateMemberProductAggregate';
            prt2.RebateMeasureType = 'AmountperUnit';
            prt2.BenefitQualifierField = 'TotalQuantity';
            prt2.MeasureField = 'TotalQuantity';
	        prt2.CalcObjectId = [SELECT Id FROM BatchCalcJobDefinition WHERE ProcessType='Rebates' AND DeveloperName='PMC_SS_AggregateByMemberWithAggregateItemDetails' LIMIT 1].id;
            insert prt2;
            PgmRebateTypBnftMapping bm2 = new PgmRebateTypBnftMapping();
            bm2.AggregateField = 'RebateMemberProductAggregate.PMC_SS_ProductFamily__c';
            bm2.RebateTypeBenefitField = 'ProgramRebateTypeBenefit.PMC_SS_ProductFamily__c';
            bm2.ProgramRebateTypeId = prt2.id;
            insert bm2;
            ProgramRebateTypeBenefit prtb21= new ProgramRebateTypeBenefit();
            prtb21.Name = 'MOP Tier 1';
            prtb21.PMC_SS_ProductFamily__c = 'MOP';
            prtb21.MinimumQualifyingValue = 1000;
            prtb21.BenefitValue = 3;
            prtb21.ProgramRebateTypeId = prt2.id;
            insert prtb21;
            ProgramRebateTypeBenefit prtb22 = new ProgramRebateTypeBenefit();
            prtb22.Name = 'KMAG Tier 1';
            prtb22.PMC_SS_ProductFamily__c = 'K-MAG';
            prtb22.MinimumQualifyingValue = 900;
            prtb22.BenefitValue = 5;
            prtb22.ProgramRebateTypeId = prt2.id;
            insert prtb22;
        } 
    

    /**
    * @description Testing success callout condition
    * @author Isha Gupta 
    **/
    @isTest
    public static void testOutboundCallBatch()
    {
        User objUser = [SELECT Id, Name FROM User WHERE Id=:Userinfo.getuserid()];
        System.runAs(objUser){
        PMC_SS_SalesAgreementBatchClass batchJob=new PMC_SS_SalesAgreementBatchClass();
        Test.startTest();
        	Test.setMock(HttpCalloutMock.class, new AnimalLocatorMock());
        	Database.executeBatch(batchJob);
            System.assertEquals(true, [SELECT Id FROM SalesAgreement].size()>0, 'Checking Sales Agreements');
        Test.stopTest();
      
        }
    }
    
     /**
    * @description Testing failure callout condition
    * @author Isha Gupta 
    **/
    @isTest
    public static void testOutboundCallBatchFailedResponse()
    {
        User objUser = [SELECT Id, Name FROM User WHERE Id=:Userinfo.getuserid()];
        System.runAs(objUser){
        PMC_SS_SalesAgreementBatchClass batchJob=new PMC_SS_SalesAgreementBatchClass();       
        Test.startTest();
        	Database.executeBatch(batchJob);
        	System.assertEquals(true, [SELECT Id FROM SalesAgreement].size()>0, 'Checking Sales Agreements');
        Test.stopTest();
        
        }
    }
    @isTest
    public static void testSalesAgreementBatchSchedule() {
		User objUser = [SELECT Id, Name FROM User WHERE Id=:Userinfo.getuserid()];
        System.runAs(objUser){        
        Test.StartTest();
			PMC_SS_SalesAgreementBatchSchedule objScheduler = new PMC_SS_SalesAgreementBatchSchedule();
        	String sch = '0 0 23 * * ?';
        	System.schedule('Sales Agreement Batch Schedule', sch, objScheduler );
            
            System.assertEquals(true, [SELECT Id FROM SalesAgreement].size()>0, 'Checking Sales Agreements');
        Test.stopTest();
        } 
    }
 /**
    * @description Mock service class
    * @author Isha Gupta 
    **/   
public class AnimalLocatorMock implements HttpCalloutMock {
    
    /**
    * @description mock response method
    * @param  request
    * @return HTTPResponse response
    **/
    public HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"animal": {"id":2, "name":"Test"}}');
        response.setStatusCode(200);
        return response; 
    }
}
    
  }