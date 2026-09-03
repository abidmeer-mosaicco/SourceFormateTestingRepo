/**
* @description This test class will be used to cover all the methods of PMC_SS_PopulateInvoiceQtyOnBenefitsBatch.
* @author Nandini Dey
*/

@isTest(seeAllData = false)
public with sharing class PMC_SS_PopulateInvoiceQtyOnBenefitsTest {
    
    /**
    * @description This Method will be used to setup the data for the test class execution.
    */
    @TestSetup
    static void testPopulateInvoiceQtyDataSetup() {
        //Get Admin Permission Set Group
        PermissionSetGroup perSetGrpAdmin = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'PMC_Administrator_Permission_Set_Group'];
        //Get current user
        List<User> lstuser=[Select Id from User where Id=:Userinfo.getuserid()];
        //System.debug(lstuser[0].id);
        String strSandboxName = UserInfo.getUserName().substringAfterLast('.');
        List<String>lstProfileNames = New List<String>{'System Administrator'};
        Map<String,Id>mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
        List<User> lstUser1 = PMC_TestUtilityClass.createUser(1);
        lstUser1[0].LastName = 'Admin User Test 1';
        lstUser1[0].Username = lstUser1[0].Email+'1.'+strSandboxName;
        lstUser1[0].ProfileId = mapOfProfiles.get('System Administrator'); 
        lstUser1[0].FederationIdentifier = lstUser1[0].Username + 'Admin1';
        lstUser1[0].isActive = true;                
        lstUser1[0].MobilePhone = '1234567891';
        lstUser1[0].LanguageLocaleKey = 'en_US';
        insert lstUser1;
        //Assign Admin Permission Set Group to Current User
        System.runAs(lstuser[0]){
            PMC_TestUtilityClass.assignPermissionSetGroupToUsers(lstUser, perSetGrpAdmin);
            PMC_TestUtilityClass.assignPermissionSetGroupToUsers(lstUser1, perSetGrpAdmin);
        }
        lstUser[0].ManagerId = lstUser1[0].Id;
        lstUser[0].MobilePhone = '1234567893';
        lstUser[0].FederationIdentifier ='1234567893';
        lstUser[0].PMC_CPQ_SalesRegion__c ='North America';
        update lstUser;
        //Create Process Switches Instance to bypass validation rule
        
        PMC_ProcessSwitches__c objProcessSwitch = new PMC_ProcessSwitches__c();
        objProcessSwitch.SetupOwnerId = UserInfo.getUserId();
        objProcessSwitch.PMC_BypassValidationRule__c = true;
        insert objProcessSwitch;
        
        //Create Accounts Test Data
        List<Account> lstAccounts = new List<Account>();
        Account objAccount;
        for(Integer intAccountCount = 0; intAccountCount < 2; intAccountCount++) {
            objAccount = new Account();
            objAccount = PMC_TestUtilityClass.createAccount('Deloitte' + intAccountCount,'PMC_SS_Customer');
            objAccount.Type='Sold-to';
            lstAccounts.add(objAccount);
        }
        //Create Products Test Data
        Product2 objProduct = new Product2();
        objProduct.Name = 'MOP';
        objProduct.PMC_CPQ_ProductFamily__c = 'MOP';
        insert objProduct;
        Product2 objProduct2 = new Product2();
        objProduct2.Name = 'KMAG';
        objProduct2.PMC_CPQ_ProductFamily__c = 'K-MAG';
        insert objProduct2;
        //Create Pricebook Entry Test Data
        PricebookEntry objPBEntry = new PricebookEntry(Product2Id = objProduct.Id, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 1);
        insert objPBEntry;
        PricebookEntry objPBEntry2 = new PricebookEntry(Product2Id = objProduct2.Id, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 1);
        insert objPBEntry2;
        //Create Sales Agreement Test Data
        Id northAmericaSalesAgreementRecordTypeId = Schema.SObjectType.SalesAgreement.getRecordTypeInfosByDeveloperName().get('PMC_SS_BusinessPartnerAgreement')?.getRecordTypeId();
        SalesAgreement objSalesAgreement = new SalesAgreement();
        objSalesAgreement.Name = 'Test Sales Agreement';
        objSalesAgreement.RecordTypeId = northAmericaSalesAgreementRecordTypeId;
        objSalesAgreement.Status = PMC_SS_ConstantClass.SALES_AGREEMENT_STATUS_DRAFT;
        objSalesAgreement.StartDate = Date.today();  
        objSalesAgreement.EndDate =   Date.today() + 364;
        objSalesAgreement.AccountId = [Select Id From Account Where Name = 'Deloitte1' limit 1].Id;
        objSalesAgreement.ScheduleFrequency ='Monthly';
        objSalesAgreement.ScheduleCount = 12;
        objSalesAgreement.CurrencyIsoCode = PMC_SS_ConstantClass.SALES_AGREEMENT_CURRENCYISOCODE_USD;
        objSalesAgreement.ProductLevel = PMC_SS_ConstantClass.SALES_AGREEMENT_PRODUCTLEVEL_PRODUCT;
        objSalesAgreement.PricebookId = Test.getStandardPricebookId();
        objSalesAgreement.ActualsCalculationMode ='Manual';
        insert objSalesAgreement;
        //Create Sales Agreement Products Test Data
        SalesAgreementProduct objSAProduct = new SalesAgreementProduct();
        objSAProduct.name = objProduct.name;
        objSAProduct.SalesAgreementId = objSalesAgreement.id;
        objSAProduct.PricebookEntryId = objPBEntry.id;
        objSAProduct.InitialPlannedQuantity = 300;
        insert objSAProduct;
        SalesAgreementProduct objSAProduct2 = new SalesAgreementProduct();
        objSAProduct2.name = objProduct2.name;
        objSAProduct2.SalesAgreementId = objSalesAgreement.id;
        objSAProduct2.PricebookEntryId = objPBEntry2.id;
        objSAProduct2.InitialPlannedQuantity = 600;
        insert objSAProduct2;
           //Submit Sales Agreement for Approval
        Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
        approvalRequest.setComments('Submitting Test Sales Agreement for approval.');
        approvalRequest.setObjectId(objSalesAgreement.Id);
        Approval.ProcessResult result = Approval.process(approvalRequest);
        //Approve Sales Agreement
        List<Id> newWorkItemIds = result.getNewWorkitemIds();
        Approval.ProcessWorkitemRequest approvalWorkItem = new Approval.ProcessWorkitemRequest();
        approvalWorkItem.setComments('Approving Test Sales Agreement.');
        approvalWorkItem.setAction('Approve');
        approvalWorkItem.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        approvalWorkItem.setWorkitemId(newWorkItemIds.get(0));
        Approval.process(approvalWorkItem);

        SalesAgreement objSAToBeActivated = [SELECT Id,Enddate,ActualsCalculationMode,OwnerId,Owner.LastName,PMC_CLM_AgreementDocumentStatus__c, Status FROM SalesAgreement WHERE Id = :objSalesAgreement.Id];
        User u=[SELECT id,Name,LastName from user where Id=:objSAToBeActivated.OwnerId];
        system.runAs(u){
            objSAToBeActivated.PMC_CLM_AgreementDocumentStatus__c='Accepted';
            update objSAToBeActivated;
        }

        //Create Rebate Program Test Data
        RebateProgram objRebateProgram = new RebateProgram();
        objRebateProgram.Name = 'Test Rebate Program';
        objRebateProgram.StartDate = System.Today();
        objRebateProgram.EndDate = System.Today().addDays(280);
        objRebateProgram.PMC_SS_SalesAgreement__c = objSalesAgreement.id;
        objRebateProgram.Frequency = 'Annually';
        objRebateProgram.Status='Active';
        insert objRebateProgram;
        //Create Program Rebate Type Test Data
        ProgramRebateType objProgRebType = new ProgramRebateType();
        objProgRebType.RebateProgramId = objRebateProgram.id;
        objProgRebType.Name = 'Individual';
        objProgRebType.Status = 'Active';
        objProgRebType.PMC_SS_Type__c = 'Individual';
        objProgRebType.CalculationType = 'AggregateBased';
        objProgRebType.CalculationMethod = 'Retrospective';
        objProgRebType.AggregateObjectName = 'RebateMemberProductAggregate';
        objProgRebType.RebateMeasureType = 'AmountperUnit';
        objProgRebType.BenefitQualifierField = 'TotalQuantity';
        objProgRebType.MeasureField = 'TotalQuantity';
        objProgRebType.CalcObjectId = [select id from BatchCalcJobDefinition WHERE ProcessType='Rebates' AND DeveloperName='PMC_SS_AggregateByMemberWithAggregateItemDetails' limit 1].id;
        insert objProgRebType;
        ProgramRebateType objProgRebType2 = new ProgramRebateType();
        objProgRebType2.RebateProgramId = objRebateProgram.id;
        objProgRebType2.Name = 'Growth Incentive';
        objProgRebType2.Status = 'Active';
        objProgRebType2.PMC_SS_Type__c = 'ZRS3';
        objProgRebType2.CalculationType = 'AggregateBased';
        objProgRebType2.CalculationMethod = 'Retrospective';
        objProgRebType2.AggregateObjectName = 'RebateMemberProductAggregate';
        objProgRebType2.RebateMeasureType = 'AmountperUnit';
        objProgRebType2.BenefitQualifierField = 'TotalQuantity';
        objProgRebType2.MeasureField = 'TotalQuantity';
        objProgRebType2.CalcObjectId = [select id from BatchCalcJobDefinition WHERE ProcessType='Rebates' AND DeveloperName='PMC_SS_AggregateByMemberWithAggregateItemDetails' limit 1].id;
        insert objProgRebType2;
        //Create Program Rebate Type Benefit Mapping Test Data
        PgmRebateTypBnftMapping objPrgRebTypeBnftMapping = new PgmRebateTypBnftMapping();
        objPrgRebTypeBnftMapping.AggregateField = 'RebateMemberProductAggregate.PMC_SS_ProductFamily__c';
        objPrgRebTypeBnftMapping.RebateTypeBenefitField = 'ProgramRebateTypeBenefit.PMC_SS_ProductFamily__c';
        objPrgRebTypeBnftMapping.ProgramRebateTypeId = objProgRebType.id;
        insert objPrgRebTypeBnftMapping;
        PgmRebateTypBnftMapping objPrgRebTypeBnftMapping2 = new PgmRebateTypBnftMapping();
        objPrgRebTypeBnftMapping2.AggregateField = 'RebateMemberProductAggregate.PMC_SS_ProductFamily__c';
        objPrgRebTypeBnftMapping2.RebateTypeBenefitField = 'ProgramRebateTypeBenefit.PMC_SS_ProductFamily__c';
        objPrgRebTypeBnftMapping2.ProgramRebateTypeId = objProgRebType2.id;
        insert objPrgRebTypeBnftMapping2;
        //Create Program Rebate Type Benefit Test Data
        ProgramRebateTypeBenefit objProgRebTypeBenefit = new ProgramRebateTypeBenefit();
        objProgRebTypeBenefit.Name = 'MOP Tier 1';
        objProgRebTypeBenefit.PMC_SS_ProductFamily__c = 'MOP';
        objProgRebTypeBenefit.MinimumQualifyingValue = 1;
        objProgRebTypeBenefit.MaximumQualifyingValue = 500;
        objProgRebTypeBenefit.BenefitValue = 3;
        objProgRebTypeBenefit.ProgramRebateTypeId = objProgRebType.id;
        insert objProgRebTypeBenefit;
        ProgramRebateTypeBenefit objProgRebTypeBenefit2 = new ProgramRebateTypeBenefit();
        objProgRebTypeBenefit2.Name = 'KMAG Tier 1';
        objProgRebTypeBenefit2.PMC_SS_ProductFamily__c = 'K-MAG';
        objProgRebTypeBenefit2.MinimumQualifyingValue = 1;
        objProgRebTypeBenefit2.MaximumQualifyingValue = 800;
        objProgRebTypeBenefit2.BenefitValue = 5;
        objProgRebTypeBenefit2.ProgramRebateTypeId = objProgRebType.id;
        insert objProgRebTypeBenefit2;
        ProgramRebateTypeBenefit objProgRebTypeBenefit3 = new ProgramRebateTypeBenefit();
        objProgRebTypeBenefit3.Name = 'MOP Tier 1';
        objProgRebTypeBenefit3.PMC_SS_ProductFamily__c = 'MOP';
        objProgRebTypeBenefit3.MinimumQualifyingValue = 100;
        objProgRebTypeBenefit3.BenefitValue = 3;
        objProgRebTypeBenefit3.ProgramRebateTypeId = objProgRebType2.id;
        insert objProgRebTypeBenefit3;
        ProgramRebateTypeBenefit objProgRebTypeBenefit4 = new ProgramRebateTypeBenefit();
        objProgRebTypeBenefit4.Name = 'KMAG Tier 1';
        objProgRebTypeBenefit4.PMC_SS_ProductFamily__c = 'K-MAG';
        objProgRebTypeBenefit4.MinimumQualifyingValue = 90;
        objProgRebTypeBenefit4.BenefitValue = 5;
        objProgRebTypeBenefit4.ProgramRebateTypeId = objProgRebType2.id;
        insert objProgRebTypeBenefit4;
        
        //Update Sales Agreement Product Schedules with Actual Quantity
        List<SalesAgreementProductSchedule> lstUpdatesProductSchedules=new List<SalesAgreementProductSchedule>();
        List<SalesAgreementProductSchedule> lstSalesAgreementProductSchedules = [SELECT SalesAgreementProductId, ActualQuantity, SalesAgreementProduct.Product.PMC_CPQ_ProductFamily__c 
                                                                                 FROM SalesAgreementProductSchedule 
                                                                                 WHERE SalesAgreementProduct.SalesAgreementId = :objSalesAgreement.Id AND SalesAgreementProduct.SalesAgreement.Status='Activated' AND StartDate=THIS_MONTH];
        for(SalesAgreementProductSchedule objSAProdSchedule : lstSalesAgreementProductSchedules) {
            objSAProdSchedule.ActualQuantity = 100;
            lstUpdatesProductSchedules.add(objSAProdSchedule);
        }
        update lstUpdatesProductSchedules;
    }
    
    @isTest
    private static void testPopulateInvoiceQtyOnBenefitsBatchSchedule() {
        User objUser = [SELECT Id, Name FROM User WHERE isActive =true AND Id=:UserInfo.getUserId()];
        System.runAs(objUser){        
        Test.StartTest();
            PMC_SS_InvQtyOnBenefitsBatchSchedule objScheduler = new PMC_SS_InvQtyOnBenefitsBatchSchedule();
            String sch = '0 0 23 * * ?';
            System.schedule('Populate Invoice Qty on Benefits Batch Schedule', sch, objScheduler );
            List<ProgramRebateTypeBenefit> lstProgramRebateTypeBenefits=[SELECT ID,PMC_SS_InvoiceQuantity__c,PMC_SS_ActualIncentives__c FROM ProgramRebateTypeBenefit WHERE PMC_SS_InvoiceQuantity__c!=0];
            System.assertEquals(true, lstProgramRebateTypeBenefits.size()>0, 'Invoice Quantity Populated on Rebate Program Benefits');
        Test.stopTest();
        }
    }
    
}