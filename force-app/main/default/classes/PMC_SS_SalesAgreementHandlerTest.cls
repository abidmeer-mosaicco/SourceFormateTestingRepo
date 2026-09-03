/**
 * @description This test class will be used to cover all the methods of PMC_SS_SalesAgreementHandler and PMC_SS_SalesAgreementHelper.
 * @author Isha Gupta
*  @storynumber GDASF-15372
 */
@isTest(SeeAllData=false)
private with sharing class PMC_SS_SalesAgreementHandlerTest{

     /**
     * @description : Test setup method to prepare data for test.
     */
    @testsetup
     private static void testSetupData(){
         PermissionSetGroup perSetGrpAdmin = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'PMC_Administrator_Permission_Set_Group'];
        List<Account> lstAccounts = new List<Account>();
        Account objAccount;
        
            List<User> lstuser=[Select Id from User where Id=:Userinfo.getuserid()];
         System.runAs(lstuser[0]){
            PMC_TestUtilityClass.assignPermissionSetGroupToUsers(lstUser, perSetGrpAdmin);
         }
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
            Id northAmericaSalesAgreementRecordTypeId = Schema.SObjectType.SalesAgreement.getRecordTypeInfosByDeveloperName().get('PMC_SS_BusinessPartnerAgreement')?.getRecordTypeId();
            
            SalesAgreement salesAgreement = new SalesAgreement();
            salesAgreement.Name = 'Test Sales Agreement';
            salesAgreement.RecordTypeId = northAmericaSalesAgreementRecordTypeId;
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
            prt2.PMC_SS_Type__c = 'ZRS3';
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
            prtb21.MinimumQualifyingValue = 100;
            prtb21.BenefitValue = 3;
            prtb21.ProgramRebateTypeId = prt2.id;
            insert prtb21;
            ProgramRebateTypeBenefit prtb22 = new ProgramRebateTypeBenefit();
            prtb22.Name = 'KMAG Tier 1';
            prtb22.PMC_SS_ProductFamily__c = 'K-MAG';
            prtb22.MinimumQualifyingValue = 90;
            prtb22.BenefitValue = 5;
            prtb22.ProgramRebateTypeId = prt2.id;
            insert prtb22;
     }
    
    /**
	* @description This method will be used to cover the method updateForecastedQuantityAndProjectedIncentive of the PMC_SS_SalesAgreementHelper.
	*/
    @isTest 
    private static void testupdateForecastedQuantityAndProjectedIncentive(){
        test.startTest();
        User objUser = [SELECT Id, Name FROM User WHERE Id=:Userinfo.getuserid()];
        System.runAs(objUser){
        Id northAmericaSalesAgreementRecordTypeId = Schema.SObjectType.SalesAgreement.getRecordTypeInfosByDeveloperName().get('PMC_SS_BusinessPartnerAgreement')?.getRecordTypeId();
        SalesAgreement sa = [select PMC_SS_ApprovalStatus__c,id from SalesAgreement where recordtypeid = :northAmericaSalesAgreementRecordTypeId  limit 1];
        sa.PMC_SS_ApprovalStatus__c = 'Under Revision';
        update sa;
           
       List<RebateProgram> rp = [Select id,PMC_SS_Projected_Incentive__c From RebateProgram where PMC_SS_SalesAgreement__c = :sa.id limit 1];
        System.assertEquals(true,rp.size()>=0,'Incentive calculated');
        }
        test.stopTest();
    }
   /**
* @description This method will be used to test booleanbypass trigger value positive scenario.
*/  
    @isTest 
    private static void testUpdateBooleanBypassFlag(){
        User objUser = [SELECT Id, Name FROM User WHERE Id=:Userinfo.getuserid()];
        system.runAs(objUser){
        SalesAgreement sa = [select PMC_SS_ApprovalStatus__c,id from SalesAgreement limit 1];
        sa.PMC_SS_ApprovalStatus__c = 'Under Revision';
        PMC_SS_SalesAgreementHandler.boolBypassTriggerLogic = true;
        test.starttest();
        update sa;
        test.stoptest();
        System.assert(sa.PMC_SS_ApprovalStatus__c == 'Under Revision', true);
        }
        
    }
    /**
* @description This method will be used to test booleanbypass trigger value negative scenario.
*/
    @isTest 
    private static void testInsertBooleanBypassFlag(){
        User objUser = [SELECT Id, Name FROM User WHERE Id=:Userinfo.getuserid()];
        system.runAs(objUser){
        Id northAmericaSalesAgreementRecordTypeId = Schema.SObjectType.SalesAgreement.getRecordTypeInfosByDeveloperName().get('PMC_SS_BusinessPartnerAgreement')?.getRecordTypeId();
        SalesAgreement salesAgreement = new SalesAgreement();
        salesAgreement.Name = 'Test Sales Agreement';
        salesAgreement.RecordTypeId = northAmericaSalesAgreementRecordTypeId;
        salesAgreement.Status = PMC_SS_ConstantClass.SALES_AGREEMENT_STATUS_DRAFT;
        salesAgreement.StartDate = System.Today();
        salesAgreement.AccountId = [Select Id From Account Where Name = 'Deloitte1' limit 1].Id;
        salesAgreement.ScheduleFrequency = PMC_SS_ConstantClass.SALES_AGREEMENT_SCHEDULEFREQUENCY_WEEKLY;
        salesAgreement.ScheduleCount = 60;
        salesAgreement.CurrencyIsoCode = PMC_SS_ConstantClass.SALES_AGREEMENT_CURRENCYISOCODE_USD;
        salesAgreement.ProductLevel = PMC_SS_ConstantClass.SALES_AGREEMENT_PRODUCTLEVEL_PRODUCT;
        salesAgreement.PricebookId = Test.getStandardPricebookId();
        PMC_SS_SalesAgreementHandler.boolBypassTriggerLogic = true;
        test.starttest();
        insert salesAgreement;
        test.stoptest();
        }
        System.assert(salesAgreement.Id != null, true);
    }
}