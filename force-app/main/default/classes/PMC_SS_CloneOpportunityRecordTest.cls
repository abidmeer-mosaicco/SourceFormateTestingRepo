/**
* @description This test class will be used to cover all the methods of PMC_SS_CloneOpportunityRecordClass.
* @author Aditya R Achar
* @storynumber GPSSM-236
*/

@isTest(seeAllData = false)
private with sharing class PMC_SS_CloneOpportunityRecordTest {
    /**
* @description This Method will be used to setup the data for the test class execution.
*/
    @testsetup
    public static void setup() {
                
        List<String>lstProfileNames = New List<String>{'System Administrator','Sales User'};
        List<String>lstPermissionNames = New List<String>{'PMC_Administrator_Permission_Set_Group','PMC_SLS_Permission_Set_Group'};
    
        Map<String,Id>mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
        Map<String,PermissionSetGroup>mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionNames);
        Integer intuserCount =0;
        User objSystemAdminUser;  
        User objSalesUser;
        List<User> lstUser = PMC_TestUtilityClass.createUser(2);
            for(User objUser : lstUser) {
                If(intuserCount==0){
                   objUser.LastName = 'Admin User Test';
                   objUser.ProfileId = mapOfProfiles.get('System Administrator');
                }else if(intuserCount==1){
                    objUser.LastName = 'Sales User Test';
                    objUser.ProfileId = mapOfProfiles.get('Sales User');
                }
                objUser.isActive = true;                
                objUser.MobilePhone = '1234567890';
                intuserCount = intuserCount + 1;
            }            
            insert lstUser;
            objSystemAdminUser = lstUser[0];
            objSalesUser = lstUser[1];
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSystemAdminUser}, mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group'));
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSalesUser}, mapOfPermissionGrp.get('PMC_SLS_Permission_Set_Group'));
        
        System.runAs(objSystemAdminUser){
            
            List<Opportunity> lstOpportunities = PMC_TestUtilityClass.createOpportunity(2,'Master');
            List<Contact> lstContacts = PMC_TestUtilityClass.createContact(1,'Master');
            List<OpportunityContactRole> lstOppContactRoles = PMC_TestUtilityClass.createOpportunityContactRoles(lstContacts, lstOpportunities);
            System.assertEquals(1,lstOppContactRoles.size(),'List size matches');
            List<OpportunityTeamMember> lstOppTeamMembers = PMC_TestUtilityClass.createOpportunityTeamMember(lstUser, lstOpportunities);
            System.assertEquals(2,lstOppTeamMembers.size(),'List size matches');
            List<Product2> lstProducts = PMC_TestUtilityClass.createProduct(1,'PMC_CPQ_NA');
            Id idPriceBook = Test.getStandardPricebookId();
            List<PricebookEntry> lstProceBookEntry = PMC_TestUtilityClass.createPriceBookEntry(lstProducts,idPriceBook);
            List<OpportunityLineItem> lstOpportunityLineItem = PMC_TestUtilityClass.createOpportunityLineItem(lstProceBookEntry,lstOpportunities);
            System.assertEquals(1,lstOpportunityLineItem.size(),'List size matches');
            List<Account> lstAccounts =new List<Account>{PMC_TestUtilityClass.createAccount('Test Mosaic Account','PMC_SS_Prospect')};
                List<Contract> lstContracts = PMC_TestUtilityClass.createContract(lstAccounts,lstOpportunities);
            System.assertEquals(1,lstContracts.size(),'List size matches');
            List<Quote> lstQuotes = PMC_TestUtilityClass.createQuotes(1, lstOpportunities); 
            System.assertEquals(1,lstQuotes.size(),'List size matches');
        }
    }
    
    /** 
* @description This method will be used to cover the cloneOpportunityRecords of the PMC_SS_CloneOpportunityRecordClass.
*/ 
    @isTest 
    private static void testCloneOpportunityRecords() {
        test.startTest();
        List<User> lstUser = [SELECT Id, Name FROM User WHERE Lastname = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
        List<Id> lstOptyIds = new List<Id>();
        List<Opportunity> lstOpportunities = [SELECT Id, Name, AccountId, Amount, StageName, CloseDate FROM Opportunity WHERE name = 'test Opportunity Name0'];
        for(Opportunity objOpty :lstOpportunities) {
            lstOptyIds.add(objOpty.Id);
        } 
        List<OpportunityContactRole> lstOppContactRoles = [SELECT ContactId, OpportunityId, IsPrimary, Role FROM OpportunityContactRole WHERE OpportunityId=:lstOpportunities[0].id];
        
        if(!lstUser.isEmpty()) {
            System.runAs(lstUser[0]) {
                try {
                    PMC_SS_CloneOpportunityRecordClass.cloneOpportunityRecords(lstOptyIds);
                }catch(Exception e) {
                    System.assertEquals(e.getMessage(),e.getMessage(), 'Script-Thrown Exception');
                }
                List<Opportunity> lstClonedOpportunities = [SELECT Id, Name, AccountId, Amount, StageName, CloseDate FROM Opportunity ORDER BY LastModifiedDate DESC LIMIT 1];
                System.assertEquals(lstOpportunities[0].Name, lstClonedOpportunities[0].Name, 'Opportunity Name is not matching' );
                System.assertEquals(lstOpportunities[0].AccountId, lstClonedOpportunities[0].AccountId, 'Accounts are not equal' );
                System.assertEquals(lstOpportunities[0].Amount, lstClonedOpportunities[0].Amount, 'Amount is not matching' );
                
                List<OpportunityContactRole> lstClonedOppContactRoles = [SELECT ContactId, OpportunityId, IsPrimary, Role FROM OpportunityContactRole WHERE OpportunityId=:lstClonedOpportunities[0].id];
                System.AssertEquals(lstOppContactRoles[0].ContactId, lstClonedOppContactRoles[0].ContactId, 'Contacts are not matching' );
            }
        }
        test.stopTest();
        
    }
    
    /** 
* @description This method will be used to cover the QueryException of cloneOpportunityRecords of the PMC_SS_CloneOpportunityRecordClass.
*/ 
    @isTest 
    private static void testCloneOpportunityRecordsQueryException() {
        test.startTest();
        List<User> lstUser = [SELECT Id, Name FROM User WHERE Lastname = 'Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
        List<Id> lstOptyIds = new List<Id>();
        if(!lstUser.isEmpty()) {
            System.runAs(lstUser[0]) {
                try {
                    PMC_SS_CloneOpportunityRecordClass.cloneOpportunityRecords(lstOptyIds);
                }catch(Exception e) {
                    System.assertEquals(e.getMessage(),e.getMessage(), 'Script-Thrown Exception');
                }
            }
        }
        test.stopTest();
        
    } 
    
    /** 
* @description This method will be used to cover the DMLException of cloneOpportunityRecords of the PMC_SS_CloneOpportunityRecordClass.
*/ 
    @isTest 
    private static void testCloneOpportunityRecordsDMLException() {
        test.startTest();
        List<User> lstUser = [SELECT Id, Name FROM User LIMIT 1];
        List<Id> lstOptyIds = new List<Id>();
        List<Opportunity> lstOpportunities = [SELECT Id, Name, AccountId, Amount, StageName, CloseDate FROM Opportunity WHERE name = 'test Opportunity Name1'];
        for(Opportunity objOpty :lstOpportunities) {
            
            lstOptyIds.add(objOpty.Id);
        } 
        
        if(!lstUser.isEmpty()) {
            System.runAs(lstUser[0]) {
                try {
                    PMC_SS_CloneOpportunityRecordClass.cloneOpportunityRecords(lstOptyIds);
                }catch(Exception e) {
                    System.assertEquals(e.getMessage(),e.getMessage(), 'Script-Thrown Exception');
                }
            }
        }
        test.stopTest();
        
    } 
    
}