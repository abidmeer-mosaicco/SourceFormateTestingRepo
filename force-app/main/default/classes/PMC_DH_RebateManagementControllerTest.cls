/**
* @description : Test class for PMC_DH_RebateManagementController
* @author      : Rohan Undale
* @last modified on 
* @last modified by 
**/
@isTest
public without sharing class PMC_DH_RebateManagementControllerTest { //without added
    @testSetup
    static void setup()
    {
        Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
        
        /* User adminUser = [SELECT Id,Name from User Where Profile.Name='System Administrator' AND isActive= TRUE Order by CreatedDate ASC LIMIT 1];

Id lstPermSetReb=[select id from PermissionSet where Name ='PMC_VRebate'][0].id;
PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(adminUser.Id,lstPermSetReb);

Id lstPermSetReb1=[select id from PermissionSet where Name ='PMC_VSalesAgreement'][0].id;
PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(adminUser.Id,lstPermSetReb1);

Id lstPermSetReb2=[select id from PermissionSet where Name ='PMC_SS_RRebateEarnings'][0].id;
PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(adminUser.Id,lstPermSetReb2);

Id lstPermSetReb3=[select id from PermissionSet where Name ='PMC_REEvent'][0].id;
PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(adminUser.Id,lstPermSetReb3);

Id lstPermSetReb4=[select id from PermissionSet where Name ='PMC_RETask'][0].id;
PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(adminUser.Id,lstPermSetReb4);

Id lstPermSetReb5=[select id from PermissionSet where Name ='PMC_SS_ERebate'][0].id;
PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(adminUser.Id,lstPermSetReb5);*/
        
        
        
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        
        Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet2);
        Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet);
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet1);
        Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet3);
        Id lstPermSet4=[select id from PermissionSet where Name ='PMC_DH_R_Manufacturing'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet4);
        Id lstPermSet5=[select id from PermissionSet where Name ='PMC_DH_R_Manufacturing_ExperienceCloud'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet5);   
        Id lstPermSet6=[select id from PermissionSet where Name ='PMC_DH_R_Sales_Agreement'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet6); 
        // added as part of GDASF-19642
        //Id lstPermSet7=[select id from PermissionSet where Name ='PMC_CRERebate'][0].id;
        //PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet7);
        
        Product2 prd = new Product2();
        prd.Name = 'MOP';
        prd.PMC_CPQ_ProductFamily__c = 'MOP';
        prd.PMC_CPQ_QuantityUnitOfMeasure__c = 'STN';
        insert prd;
        Product2 prd2 = new Product2();
        prd2.Name = 'KMAG';
        prd2.PMC_CPQ_ProductFamily__c = 'K-MAG';
        prd2.PMC_CPQ_QuantityUnitOfMeasure__c = 'MTN';
        insert prd2;
        PricebookEntry pe = new PricebookEntry(Product2Id = prd.Id, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 1);
        insert pe;
        PricebookEntry pe2 = new PricebookEntry(Product2Id = prd2.Id, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 1);
        insert pe2;
        
        SalesAgreement salesAgreement = new SalesAgreement();
        salesAgreement.Name = 'Test Sales Agreement';
        salesAgreement.Status = PMC_SS_ConstantClass.SALES_AGREEMENT_STATUS_DRAFT;
        salesAgreement.StartDate = System.Today();
        salesAgreement.AccountId = acc.Id;
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
        prt.PMC_SS_Type__c = 'ZRS1';
        prt.CalculationType = 'AggregateBased';
        prt.CalculationMethod = 'Retrospective';
        prt.AggregateObjectName = 'RebateMemberProductAggregate';
        prt.RebateMeasureType = 'AmountperUnit';
        prt.BenefitQualifierField = 'TotalQuantity';
        prt.MeasureField = 'TotalQuantity';
        prt.CalcObjectId = [select id from BatchCalcJobDefinition WHERE ProcessType='Rebates' AND DeveloperName='PMC_SS_AggregateByMemberWithAggregateItemDetails' limit 1].id;  //[select id from BatchCalcJobDefinition  where BatchJobDefinition.Status ='Active' limit 1].id; //[SELECT Id  FROM BatchCalcJobDefinition WHERE DeveloperName = 'PMC_SS_AggregateByMemberWithAggregateItemDetails' LIMIT 1].Id;
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
        prt2.CalcObjectId = [select id from BatchCalcJobDefinition WHERE ProcessType='Rebates' AND DeveloperName='PMC_SS_AggregateByMemberWithAggregateItemDetails' limit 1].id; 
        insert prt2;
        PgmRebateTypBnftMapping bm2 = new PgmRebateTypBnftMapping();
        bm2.AggregateField = 'RebateMemberProductAggregate.PMC_SS_ProductFamily__c';
        bm2.RebateTypeBenefitField = 'ProgramRebateTypeBenefit.PMC_SS_ProductFamily__c';
        bm2.ProgramRebateTypeId = prt2.id;
        insert bm2;
        ProgramRebateTypeBenefit prtb21= new ProgramRebateTypeBenefit();
        prtb21.Name = 'MOP Tier 1';
        prtb21.PMC_SS_ProductFamily__c = 'MOP';
        prtb21.MinimumQualifyingValue = 10;
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
* @description Test Method for getListOfRebateProgramOptions
* @param: none
* @return: void
* @author Rohan
*/  
    @isTest
    public static void getListOfRebateProgramOptionsTest()
    {
        Account acc = [Select Id From Account limit 1];
        //List<PMC_DH_PicklistWrapper> lstResult = PMC_DH_RebateManagementController.getListOfRebateProgramOptions(acc.Id);
        //System.Assert(lstResult != null, 'Success');
        
        // added as part of GDASF-19642
        PMC_DH_RebateManagementController.PMC_DH_RebateProgramWrapper wrpResult = PMC_DH_RebateManagementController.getListOfRebateProgramOptions(acc.Id);
        System.Assert(wrpResult.lstRebateProgramOptions != null, 'Success');
    }
    
    /**
* @description Test Method for getRebateDetails
* @param: none
* @return: void
* @author Rohan
*/  
    @isTest
    public static void getRebateDetailsTest()
    {
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        RebateProgram objRebateProgram = [Select Id, PMC_SS_SalesAgreement__r.AccountId From RebateProgram Where Name = 'Test Rebate Prg' limit 1];
        System.runAs(user){
            PMC_DH_RebateManagementWrapper result = PMC_DH_RebateManagementController.getRebateDetails(objRebateProgram.Id,  objRebateProgram.PMC_SS_SalesAgreement__r.AccountId);
            System.Assert(result != null, 'Success');
        }
    }
    
    /**
* @description Test Method for getRebateDetails
* @param: none
* @return: void
* @author Rohan
*/  
    @isTest
    public static void getRebateDetailsExceptionTest()
    {
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        RebateProgram objRebateProgram = [Select Id, PMC_SS_SalesAgreement__r.AccountId From RebateProgram Where Name = 'Test Rebate Prg' limit 1];
        System.runAs(user){
            PMC_DH_DigitalHubB2BUtils.throwTestException = true;
            PMC_DH_RebateManagementWrapper result = PMC_DH_RebateManagementController.getRebateDetails(objRebateProgram.Id,  objRebateProgram.PMC_SS_SalesAgreement__r.AccountId);
            System.Assert(result != null, 'Success');
        }
    }
    
    @isTest
    public static void demoForBrazilTest()
    {
        PMC_DH_RebateManagementWrapper objRebateManagementWrapper = new PMC_DH_RebateManagementWrapper();
        objRebateManagementWrapper.lstCultivar = new List<PMC_DH_RebateManagementWrapper.RebateData>();
        objRebateManagementWrapper.lstRawMaterials = new List<PMC_DH_RebateManagementWrapper.RebateData>();
        objRebateManagementWrapper.lstBlendedProducts = new List<PMC_DH_RebateManagementWrapper.RebateData>();
        System.Assert(objRebateManagementWrapper != null, 'Success');
    }
}