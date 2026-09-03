/**
* @description This test class will be used to cover all the methods of PMC_SS_CreateOpportunityLineItems.
* @author Chetna Nihalani
* @storynumber GDASF-10431
*/

@isTest(seeAllData = false)
public with sharing class PMC_SS_CreateOpportunityLineItemsTest {
	/**
    * @description This Method will be used to setup the data for the test class execution.
    */
    @TestSetup
    public static void setup() {
        
        List<String> lstPermissionNames = New List<String>{'PMC_Administrator_Permission_Set_Group','PMC_SLS_Permission_Set_Group'};
        Map<String,PermissionSetGroup> mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionNames);
        
        Integer intuserCount =0;
        User objSystemAdminUser;  
        User objServiceUser;
        Profile objUserAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        List<User> lstUser = PMC_TestUtilityClass.createUser(2);
            for(User objUser : lstUser) {
                If(intuserCount==0){
                   objUser.LastName = 'Admin User Test';
                   //objUser.ProfileId = mapOfProfiles.get('System Administrator');
                    objUser.ProfileId=objUserAdminProfile.Id;
                   objUser.FederationIdentifier = objUser.Username + 'Admin';
                }else if(intuserCount==1){
                    objUser.LastName = 'Service User Test';
                    //objUser.ProfileId = mapOfProfiles.get('Service User'); 
                    objUser.ProfileId=objUserAdminProfile.Id;
                   objUser.FederationIdentifier = objUser.Username + 'Service';
                }
                objUser.isActive = true;                
                objUser.MobilePhone = '1234567890';
                intuserCount = intuserCount + 1;
            } 
            insert lstUser;
            objSystemAdminUser = lstUser[0];
            objServiceUser = lstUser[1];
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSystemAdminUser}, mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group'));
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSystemAdminUser}, mapOfPermissionGrp.get('PMC_SLS_Permission_Set_Group'));
        System.runAs(objSystemAdminUser){
        List<SalesAgreementProduct> lstSalesAgreementProductToUpdate = new List<SalesAgreementProduct>();
        
            List<Opportunity> lstOpportunities = PMC_TestUtilityClass.createOpportunity(1,'Master');
            List<Opportunity> lstOpportunitiesNew = PMC_TestUtilityClass.createOpportunity(1,'Master');
            
            List<Product2> lstProducts = PMC_TestUtilityClass.createProduct(3,'PMC_CPQ_NA');
            
            Id idPriceBook = Test.getStandardPricebookId();
            List<PricebookEntry> lstPriceBookEntry = PMC_TestUtilityClass.createPriceBookEntry(lstProducts,idPriceBook);
           
            
            List<OpportunityLineItem> lstOpportunityLineItem = PMC_TestUtilityClass.createOpportunityLineItem(lstPriceBookEntry,lstOpportunities);
            List<OpportunityLineItem> lstOpportunityLineItemNew = PMC_TestUtilityClass.createOpportunityLineItem(lstPriceBookEntry,lstOpportunitiesNew);
            lstOpportunityLineItem.addall(lstOpportunityLineItemNew);
            
            List<SalesAgreement> lstSalesAgreements = PMC_TestUtilityClass.createSalesAgreement(1,'Master');
            List<SalesAgreementProduct> lstSalesAgreementProducts = PMC_TestUtilityClass.createSalesAgreementProduct(1,lstSalesAgreements);
            
            for(SalesAgreementProduct objSalesAgreementProduct : lstSalesAgreementProducts) {
                objSalesAgreementProduct.InitialPlannedQuantity = 20;
                lstSalesAgreementProductToUpdate.add(objSalesAgreementProduct);
            }
            Update lstSalesAgreementProductToUpdate;
        }  
    }
    
    /**
	* @description This method will be used to cover the createMap Invocable method of the PMC_SS_CreateFlowMap.
	*/
    @isTest 
    private static void testCreateMap() {
        test.startTest();
        User objUser = [SELECT Id, Name FROM User WHERE Lastname = 'Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser){
        Account objAccount = [SELECT Id,Name FROM Account LIMIT 1];
        List<Id> lstSalesAgreementProductIds = new List<Id>();
        
        Opportunity objOpportunity = new Opportunity();
        objOpportunity.Name = 'test Opportunity 1';
        objOpportunity.AccountId = objAccount.Id;
        objOpportunity.CloseDate = System.today();
        objOpportunity.StageName = PMC_SS_ConstantClass.OPPORTUNITY_PROSPECTING_STAGE;
        objOpportunity.ForecastCategoryName = PMC_SS_ConstantClass.OPPORTUNITY_FORECAST_CATEGORY_PIPELINE;
        insert objOpportunity;
        
        List<OpportunityLineItem> lstOpportunityLineItem = [SELECT Id,Product2Id,OpportunityId,PricebookEntryId,Quantity,TotalPrice FROM OpportunityLineItem];
        
        List<SalesAgreement> lstSalesAgreements = [SELECT Id,Name,AccountId,Status,StartDate,EndDate,ScheduleCount,ScheduleFrequency,CurrencyIsoCode,ProductLevel,ActualsCalculationMode,PricebookId FROM SalesAgreement];
         
             
        List<ProcessInstanceWorkitem> workItems = [SELECT Id,ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: lstSalesAgreements[0].Id];
        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
        for(ProcessInstanceWorkitem workItem : workItems){
            Approval.ProcessWorkitemRequest approvalProcessReq = new Approval.ProcessWorkitemRequest();
            approvalProcessReq.setWorkitemId(workItem.Id);
            //Valid values are: Approve, Reject, or Removed. 
            //Only system administrators can specify Removed.
            approvalProcessReq.setAction('Approve');
            approvalProcessReq.setComments('Test Sales Agreement is approved.');
            requests.add(approvalProcessReq);
        }
        
        List<SalesAgreementProduct> lstSalesAgreementProducts = [SELECT Id, Name, SalesAgreementId,ProductId,SalesPrice,PricebookEntryId FROM SalesAgreementProduct WHERE SalesAgreementId =: lstSalesAgreements[0].Id];
        
        for(SalesAgreementProduct objSalesAgreementProduct : lstSalesAgreementProducts) {
            lstSalesAgreementProductIds.add(objSalesAgreementProduct.Id);
        }
        
        List<SalesAgreementProductSchedule> lstSalesAgreementProductSchedule = [SELECT Id, Name,PlannedQuantity,SalesAgreementProductId FROM SalesAgreementProductSchedule WHERE SalesAgreementProductId IN: lstSalesAgreementProductIds];
        
        List<PMC_SS_CreateOpportunityLineItems.CreateMapInputs> lstCreateFlowMap = new List<PMC_SS_CreateOpportunityLineItems.CreateMapInputs>();
        PMC_SS_CreateOpportunityLineItems.CreateMapInputs createFlowMap = new PMC_SS_CreateOpportunityLineItems.CreateMapInputs();
        createFlowMap.idOpportunity = objOpportunity.Id;
        createFlowMap.lstOpportunityLineItem = lstOpportunityLineItem;
        createFlowMap.lstSalesAgreementProducts = lstSalesAgreementProducts;
        createFlowMap.lstSalesAgreementProductSchedules = lstSalesAgreementProductSchedule;
        lstCreateFlowMap.add(createFlowMap);
        PMC_SS_CreateOpportunityLineItems.CreateMapInputs.createMap(lstCreateFlowMap);
        System.assertEquals(1,lstCreateFlowMap.size(),'List size matches');
        }
        test.stopTest();
    }
    
    /**
	* @description This method will be used to cover the createMap Invocable Method of the PMC_SS_CreateFlowMap when 
		no OpportunityLineItems are passed to Invocable Method.
	*/
    @isTest 
    private static void testCreateMapNullOpportunityLineItem() {
        test.startTest();
        User objUser = [SELECT Id, Name FROM User WHERE Lastname = 'Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser){
        Account objAccount = [SELECT Id,Name FROM Account LIMIT 1];
        List<Id> lstSalesAgreementProductIds = new List<Id>();
        
        Opportunity objOpportunity = new Opportunity();
        objOpportunity.Name = 'test Opportunity 1';
        objOpportunity.AccountId = objAccount.Id;
        objOpportunity.CloseDate = System.today();
        objOpportunity.StageName = PMC_SS_ConstantClass.OPPORTUNITY_PROSPECTING_STAGE;
        objOpportunity.ForecastCategoryName = PMC_SS_ConstantClass.OPPORTUNITY_FORECAST_CATEGORY_PIPELINE;
        insert objOpportunity;
        
        List<SalesAgreement> lstSalesAgreements = [SELECT Id,Name,AccountId,Status,StartDate,EndDate,ScheduleCount,ScheduleFrequency,CurrencyIsoCode,ProductLevel,ActualsCalculationMode,PricebookId FROM SalesAgreement];
        
        List<ProcessInstanceWorkitem> workItems = [SELECT Id,ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: lstSalesAgreements[0].Id];
        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
        for(ProcessInstanceWorkitem workItem : workItems){
            Approval.ProcessWorkitemRequest approvalProcessReq = new Approval.ProcessWorkitemRequest();
            approvalProcessReq.setWorkitemId(workItem.Id);
            approvalProcessReq.setAction('Approve');
            approvalProcessReq.setComments('Test Sales Agreement is approved.');
            requests.add(approvalProcessReq);
        }
        
        
        List<SalesAgreementProduct> lstSalesAgreementProduct = [SELECT Id, Name, SalesAgreementId,ProductId,SalesPrice,PricebookEntryId FROM SalesAgreementProduct WHERE SalesAgreementId =: lstSalesAgreements[0].Id];
        for(SalesAgreementProduct objSalesAgreementProduct : lstSalesAgreementProduct) {
            lstSalesAgreementProductIds.add(objSalesAgreementProduct.Id);
        }
        
        List<SalesAgreementProductSchedule> lstSalesAgreementProductSchedule = [SELECT Id, Name,PlannedQuantity,SalesAgreementProductId FROM SalesAgreementProductSchedule WHERE SalesAgreementProductId IN: lstSalesAgreementProductIds];
        
        List<PMC_SS_CreateOpportunityLineItems.CreateMapInputs> lstCreateFlowMap = new List<PMC_SS_CreateOpportunityLineItems.CreateMapInputs>();
        PMC_SS_CreateOpportunityLineItems.CreateMapInputs createFlowMap = new PMC_SS_CreateOpportunityLineItems.CreateMapInputs();
        createFlowMap.idOpportunity = objOpportunity.Id;
        createFlowMap.lstOpportunityLineItem = null;
        createFlowMap.lstSalesAgreementProducts = lstSalesAgreementProduct;
        createFlowMap.lstSalesAgreementProductSchedules = lstSalesAgreementProductSchedule;
        lstCreateFlowMap.add(createFlowMap);
        PMC_SS_CreateOpportunityLineItems.CreateMapInputs.createMap(lstCreateFlowMap);
        System.assertEquals(1,lstCreateFlowMap.size(),'List size matches');
        }
        test.stopTest();
    }
}