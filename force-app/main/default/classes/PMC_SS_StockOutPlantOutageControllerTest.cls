/**
* @description This test class is used to cover PMC_SS_StockOutPlantOutageController Apex
* @author Urvashi Chauhan
* @storynumber GDASF-15351
*/

@isTest(seeAllData = false)
public with sharing class PMC_SS_StockOutPlantOutageControllerTest {
    
    /**
    * @description This method is used to setup the test data for the test class execution
    */
    
    @testsetup
    private static void setup() {
        List<String>lstProfileNames = New List<String>{'System Administrator','Service User'};
        List<String>lstPermissionNames = New List<String>{'PMC_Administrator_Permission_Set_Group','PMC_SRV_Permission_Set_Group'};
        Map<String,Id>mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
        Map<String,PermissionSetGroup>mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionNames);
        Integer intuserCount =0;
        User objSystemAdminUser;  
        User objServiceUser;
        List<User> lstUser = PMC_TestUtilityClass.createUser(2);
            for(User objUser : lstUser) {
                If(intuserCount==0){
                   objUser.LastName = 'Admin User Test';
                   objUser.ProfileId = mapOfProfiles.get('System Administrator'); 
                   objUser.FederationIdentifier = objUser.Username + 'Admin';
                }else if(intuserCount==1){
                    objUser.LastName = 'Service User Test';
                    objUser.ProfileId = mapOfProfiles.get('Service User'); 
                   objUser.FederationIdentifier = objUser.Username + 'Service';
                }
                objUser.isActive = true;                
                objUser.MobilePhone = '1234567890';
                objUser.UserPermissionsKnowledgeUser =true;
                objUser.LanguageLocaleKey = 'en_US';
                intuserCount = intuserCount + 1;
            }            
            insert lstUser;
            objSystemAdminUser = lstUser[0];
            objServiceUser = lstUser[1];
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSystemAdminUser}, mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group'));
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objServiceUser}, mapOfPermissionGrp.get('PMC_SRV_Permission_Set_Group'));
        BusinessHours objBusinessHrs = [SELECT Id, Name FROM BusinessHours 
                                        WHERE isDefault = True AND IsActive = True
                                   WITH SECURITY_ENFORCED LIMIT 1];
        Account objAccount;
        Account objAccountCont;
        List<Account> lstAccount = new List<Account>();
        Opportunity objOpportunity;
        List<Contract> lstContractsRec = new List<Contract>();
            
        System.runAs(objServiceUser){
        objAccount = PMC_TestUtilityClass.createAccount('Test Account 01', 'PMC_SS_Prospect');
        objAccountCont = PMC_TestUtilityClass.createAccount('Test Account 02', 'PMC_SS_Prospect');        
        lstAccount.add(objAccount);
        lstAccount.add(objAccountCont);
        
        objOpportunity = PMC_TestUtilityClass.createOpportunity(1, '')[0];
        }        
        
        Schema.Location objLocation;
        List<Product2> lstProduct =new List<Product2>();  
        List<Order> lstOrdersRec;
        
        System.runAs(objSystemAdminUser){
        PMC_TestUtilityClass.createContract(lstAccount, new List<Opportunity>{objOpportunity});
        PMC_TestUtilityClass.createContract(new List<Account>{objAccount}, new List<Opportunity>{objOpportunity});
        
        lstContractsRec = [SELECT Id, ContractNumber 
                                          FROM Contract WHERE SBQQ__Opportunity__c = :objOpportunity.Id 
                                          WITH SECURITY_ENFORCED LIMIT 3];    
        objLocation = PMC_TestUtilityClass.createLocation('Test Schema.Location');
        
        PMC_TestUtilityClass.createProduct(1,'PMC_CPQ_NA');
        
        lstProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product0'
                                     WITH SECURITY_ENFORCED LIMIT 1];
        
        PMC_TestUtilityClass.createOrders(2, new List<Account>{objAccount});
        lstOrdersRec = [SELECT Id, OrderNumber, ContractId 
                                    FROM Order WHERE AccountId = :objAccount.Id 
                                    WITH SECURITY_ENFORCED LIMIT 2];
        }

            
        System.runAs(objServiceUser){
        List<Case> lstCases = new List<Case>();
        Case objCaseOrder = PMC_TestUtilityClass.createCase(objBusinessHrs.Id, objAccount.Id, objServiceUser.Id, objLocation.Id);
        objCaseOrder.Subject = 'Test stock outage orders';
        objCaseOrder.PMC_SS_StockOutPlantOutageStartDate__c = Date.TODAY();
        objCaseOrder.PMC_SS_StockOutPlantOutageEndDate__c = Date.TODAY() + 30;
        objCaseOrder.PMC_SS_StockOutPlantOutageOrders__c = lstOrdersRec[0].OrderNumber+ ';' +lstOrdersRec[1].OrderNumber;
        objCaseOrder.Type = 'Internal';
        objCaseOrder.PMC_SS_IssueReason__c = 'Stock Out / Plant Outage';
        objCaseOrder.ProductId = lstProduct[0].Id;
        objCaseOrder.PMC_SS_Location__c = objLocation.Id;
        lstCases.add(objCaseOrder);
        
        Case objCaseContract = PMC_TestUtilityClass.createCase(objBusinessHrs.Id, objAccount.Id, objServiceUser.Id,objLocation.Id);
        objCaseContract.Subject = 'Test stock outage contracts';
        objCaseContract.PMC_SS_StockOutPlantOutageStartDate__c = Date.TODAY();
        objCaseContract.PMC_SS_StockOutPlantOutageEndDate__c = Date.TODAY() + 40;
        objCaseContract.PMC_SS_StockOutPlantOutageContracts__c = lstContractsRec[0].ContractNumber+ ';' +lstContractsRec[1].ContractNumber+ ';' +lstContractsRec[2].ContractNumber;
        objCaseContract.Type = 'Internal';
        objCaseContract.PMC_SS_IssueReason__c = 'Stock Out / Plant Outage';
        objCaseContract.ProductId = lstProduct[0].Id;
        objCaseContract.PMC_SS_Location__c = objLocation.Id;
        lstCases.add(objCaseContract);
        
        insert lstCases;
    }
    }
    
    /**
    * @description This method is used to cover createChildStockOutageChildCases from PMC_SS_StockOutPlantOutageController for Orders
    */
    
    @isTest
    private static void testCreateChildCasesForOrders() {
        
        Test.startTest();
        
        User objUser = [SELECT Id, Name FROM User WHERE LastName = 'Service User Test'
                        WITH SECURITY_ENFORCED LIMIT 1];
        Case objCase;
        System.runAs(objUser){
        Account objAccount = [SELECT Id FROM Account WHERE Name = 'Test Account 01' 
                              WITH SECURITY_ENFORCED LIMIT 1];
        List<Order> lstOrders = [SELECT Id, OrderNumber FROM Order WHERE AccountId = :objAccount.Id 
                                 WITH SECURITY_ENFORCED LIMIT 2];
        objCase = [SELECT Id, CaseNumber, Status, Type, BusinessHoursId, AccountId, Origin,
                        Priority, Subject, Description, CurrencyIsoCode, ProductId, PMC_SS_Location__c,
                        PMC_SS_IssueReason__c, PMC_SS_Plant__c, PMC_SS_StockOutPlantOutageStartDate__c, 
                        PMC_SS_StockOutPlantOutageEndDate__c, PMC_SS_StockOutPlantOutageContracts__c, 
                        PMC_SS_StockOutPlantOutageOrders__c FROM Case 
                        WHERE Subject = 'Test stock outage orders'
                        WITH SECURITY_ENFORCED];
        
        if(objUser != null && !lstOrders.isEmpty()) {
            //System.runAs(objUser) {
                PMC_SS_StockOutPlantOutageController.PMC_SS_StockOutageRequest objStockOutagReq = new PMC_SS_StockOutPlantOutageController.PMC_SS_StockOutageRequest();
                objStockOutagReq.strOrders = lstOrders[0].OrderNumber+ ';' +lstOrders[1].OrderNumber;
                objStockOutagReq.objParentCase = objCase;
                
                List<PMC_SS_StockOutPlantOutageController.PMC_SS_StockOutageRequest> lstStockOutagReq = new List<PMC_SS_StockOutPlantOutageController.PMC_SS_StockOutageRequest>();
                lstStockOutagReq.add(objStockOutagReq);
                
                PMC_SS_StockOutPlantOutageController.createChildStockOutageChildCases(lstStockOutagReq);
            //}
        }
          List<Case> lstChildCases = [SELECT Id FROM Case WHERE ParentId = :objCase.Id
                                    WITH SECURITY_ENFORCED];
          System.assertEquals(lstChildCases.size(), 1, 'Child case created for orders');  
        }
        Test.stopTest();
    }
    
    /**
    * @description This Method will be used to cover createChildCasesForStockOutageOrders from PMC_SS_StockOutPlantOutageController for null Orders
    */
    
    @isTest
    private static void testCreateChildCasesForNullOrders() {
        
        Test.startTest();
        
        User objUser = [SELECT Id, Name FROM User WHERE LastName = 'Service User Test'
                        WITH SECURITY_ENFORCED LIMIT 1];
        Map<Id,Case> mapAccIdWithCase = new Map<Id,Case>();
         if(objUser != null) {
        System.runAs(objUser){
        Case objCase = [SELECT Id, CaseNumber, Status, Type, BusinessHoursId, AccountId, Origin,
                        Priority, Subject, Description, CurrencyIsoCode, ProductId, PMC_SS_Location__c,
                        PMC_SS_IssueReason__c, PMC_SS_Plant__c, PMC_SS_StockOutPlantOutageStartDate__c, 
                        PMC_SS_StockOutPlantOutageEndDate__c, PMC_SS_StockOutPlantOutageContracts__c, 
                        PMC_SS_StockOutPlantOutageOrders__c FROM Case 
                        WHERE Subject = 'Test stock outage orders'
                        WITH SECURITY_ENFORCED];
                mapAccIdWithCase = PMC_SS_StockOutPlantOutageController.createChildCasesForStockOutageOrders(new List<String>(),objCase);
              System.assertEquals(mapAccIdWithCase, null, 'No child cases created');  
         
        }
        }
        Test.stopTest();        
          
    }
    
    /**
    * @description This Method will be used to cover createChildStockOutageChildCases from PMC_SS_StockOutPlantOutageController for Contracts
    */
    
    @isTest
    private static void testCreateChildCasesForContracts() {
        
        Test.startTest();
        Case objCase;
        User objUser = [SELECT Id, Name FROM User WHERE LastName = 'Service User Test'
                        WITH SECURITY_ENFORCED LIMIT 1];
        if(objUser != null){
        System.runAs(objUser){
        Opportunity objOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'test Opportunity Name0'
                                      WITH SECURITY_ENFORCED LIMIT 1];
        List<Contract> lstContracts = [SELECT Id, ContractNumber FROM Contract 
                                       WHERE SBQQ__Opportunity__c = :objOpportunity.Id 
                                       WITH SECURITY_ENFORCED LIMIT 3];
        objCase = [SELECT Id, CaseNumber, Status, Type, BusinessHoursId, AccountId, Origin,
                        Priority, Subject, Description, CurrencyIsoCode, ProductId, PMC_SS_Location__c,
                        PMC_SS_IssueReason__c, PMC_SS_Plant__c, PMC_SS_StockOutPlantOutageStartDate__c, 
                        PMC_SS_StockOutPlantOutageEndDate__c, PMC_SS_StockOutPlantOutageContracts__c, 
                        PMC_SS_StockOutPlantOutageOrders__c FROM Case 
                        WHERE Subject = 'Test stock outage contracts'
                        WITH SECURITY_ENFORCED];
        
        if(!lstContracts.isEmpty()) {
           
                PMC_SS_StockOutPlantOutageController.PMC_SS_StockOutageRequest objStockOutagReq = new PMC_SS_StockOutPlantOutageController.PMC_SS_StockOutageRequest();
                objStockOutagReq.strContracts = lstContracts[0].ContractNumber+ ';' +lstContracts[1].ContractNumber+ ';' +lstContracts[2].ContractNumber;
                objStockOutagReq.objParentCase = objCase;
                
                List<PMC_SS_StockOutPlantOutageController.PMC_SS_StockOutageRequest> lstStockOutagReq = new List<PMC_SS_StockOutPlantOutageController.PMC_SS_StockOutageRequest>();
                lstStockOutagReq.add(objStockOutagReq);
                
                PMC_SS_StockOutPlantOutageController.createChildStockOutageChildCases(lstStockOutagReq);
           
        }
          List<Case> lstChildCases = [SELECT Id FROM Case WHERE ParentId = :objCase.Id
                                    WITH SECURITY_ENFORCED];
          System.assertEquals(lstChildCases.size(), 2, 'Child cases created for contracts');
            }
        }
        
        Test.stopTest();
        
        
    }
    
    /**
    * @description This Method will be used to cover createChildCasesForStockOutageContracts from PMC_SS_StockOutPlantOutageController for null Contracts
    */
    
    @isTest
    private static void testCreateChildCasesForNullContracts() {
        
        Test.startTest();
        Map<Id,Case> mapAccIdWithCase = new Map<Id,Case>();
        User objUser = [SELECT Id, Name FROM User WHERE LastName = 'Service User Test'
                        WITH SECURITY_ENFORCED LIMIT 1];
        if(objUser != null) {
        System.runAs(objUser){
        Case objCase = [SELECT Id, CaseNumber, Status, Type, BusinessHoursId, AccountId, Origin,
                        Priority, Subject, Description, CurrencyIsoCode, ProductId, PMC_SS_Location__c,
                        PMC_SS_IssueReason__c, PMC_SS_Plant__c, PMC_SS_StockOutPlantOutageStartDate__c, 
                        PMC_SS_StockOutPlantOutageEndDate__c, PMC_SS_StockOutPlantOutageContracts__c, 
                        PMC_SS_StockOutPlantOutageOrders__c FROM Case 
                        WHERE Subject = 'Test stock outage contracts'
                        WITH SECURITY_ENFORCED];
        
        
         mapAccIdWithCase = PMC_SS_StockOutPlantOutageController.createChildCasesForStockOutageContracts(new List<String>(),objCase);
         System.assertEquals(mapAccIdWithCase, null, 'No child case created'); 
   
            }
        }
        
        Test.stopTest();
        
    }
    
}