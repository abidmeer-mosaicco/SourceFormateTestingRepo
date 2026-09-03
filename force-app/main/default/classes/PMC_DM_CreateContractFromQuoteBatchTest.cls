/**
* @description This test class will be used to cover all the methods of PMC_DM_CreateContractFromQuoteBatchTest
* @author Preethi J
*/
@isTest
public class PMC_DM_CreateContractFromQuoteBatchTest {
    public Static List<Id> lstQuoteId = new List<Id>();
    public Static List<Opportunity> lstOpty = new List<Opportunity>();
    public Static List<Contact> lstContact = new List<Contact>();
    public static Id userId;
    public static List<SBQQ__Quote__c> lstQuotes;
    public static Account objAccount;
    
    /*
     * @description This is the test setup method which creates the data required
*/
    @TestSetup
    private static void testSetup(){
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
                objUser.FederationIdentifier = objUser.Username + 'Admin';
            }else if(intuserCount==1){
                objUser.LastName = 'Sales User Test';
                objUser.ProfileId = mapOfProfiles.get('Sales User'); 
                objUser.FederationIdentifier = objUser.Username + 'Sales';
            }
            objUser.isActive = true;                
            objUser.MobilePhone = '1234567890';
            objUser.UserPermissionsKnowledgeUser =true;
            objUser.LanguageLocaleKey = 'en_US';
            intuserCount = intuserCount + 1;
        }            
        insert lstUser;
        objSystemAdminUser = lstUser[0];
        objSalesUser =lstUser[1];
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSystemAdminUser}, mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group'));
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSalesUser}, mapOfPermissionGrp.get('PMC_SLS_Permission_Set_Group'));
        System.runas(objSystemAdminUser){
            lstOpty = PMC_TestUtilityClass.createOpportunity(3,'Master');
            lstContact = PMC_TestUtilityClass.createContact(3,'Master');
            lstQuotes = PMC_TestUtilityClass.createCPQQuotes(3,lstOpty , lstContact);
            for(Integer i=0; i<lstQuotes.size();i++){
                lstQuoteId.add(lstQuotes[i].Id);
            }
        }
    }
    /*
     * @description This method will run the Execute method for Months between less than 1
*/
    @isTest
    public static void testBatchExecution(){
        List<User> lstUser = [SELECT Id FROM User WHERE LastName ='Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(lstUser.get(0)){
        List<SBQQ__Quote__c> lstQuote = [select OwnerId,SBQQ__Opportunity2__r.AccountId,PMC_CPQ_AccountManager__c,CurrencyIsoCode,SBQQ__PriceBook__c,SBQQ__PaymentTerms__c,SBQQ__Account__c,PMC_CLM_ContractCreated__c,PMC_CPQ_ContractStart__c,PMC_CPQ_ContractEnd__c, Id from SBQQ__Quote__c LIMIT 3];
        for(SBQQ__Quote__c obj : lstQuote){
            lstQuoteId.add(obj.Id);
            obj.CurrencyIsoCode = 'USD';
            obj.SBQQ__PriceBook__c = Test.getStandardPricebookId();
            obj.SBQQ__PaymentTerms__c = 'Fixed Date';
            obj.SBQQ__Account__c = obj.SBQQ__Opportunity2__r.AccountId;
            obj.PMC_CLM_ContractCreated__c = false;
            obj.PMC_CPQ_ContractEnd__c = obj.PMC_CPQ_ContractStart__c.addDays(2);
        }
        update lstQuote;
        userId = lstQuote[0].OwnerId;
        Test.startTest();
        PMC_DM_CreateContractFromQuoteBatch batch = new PMC_DM_CreateContractFromQuoteBatch(userId);
        Database.executeBatch(batch);
        Test.stopTest();
        List<SBQQ__Quote__c> updatedQuotes = [SELECT Id, PMC_CLM_ContractCreated__c FROM SBQQ__Quote__c WHERE PMC_CLM_ContractCreated__c =: true];
        System.assertEquals(3, updatedQuotes.size(),'Contract not created');
        }
    }
    /*
     * @description This method will run the Execute method for Months between greater than 1
*/
    @isTest
    public static void testBatchExecution1(){
        List<User> lstUser = [SELECT Id FROM User WHERE LastName ='Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(lstUser.get(0)){
        List<SBQQ__Quote__c> lstQuote = [select OwnerId,SBQQ__Opportunity2__r.AccountId,PMC_CPQ_AccountManager__c,CurrencyIsoCode,SBQQ__PriceBook__c,SBQQ__PaymentTerms__c,SBQQ__Account__c,PMC_CLM_ContractCreated__c,PMC_CPQ_ContractStart__c,PMC_CPQ_ContractEnd__c, Id from SBQQ__Quote__c LIMIT 3];
        for(SBQQ__Quote__c obj : lstQuote){
            lstQuoteId.add(obj.Id);
            obj.CurrencyIsoCode = 'USD';
            obj.SBQQ__PriceBook__c = Test.getStandardPricebookId();
            obj.SBQQ__PaymentTerms__c = 'Fixed Date';
            obj.SBQQ__Account__c = obj.SBQQ__Opportunity2__r.AccountId;
            obj.PMC_CLM_ContractCreated__c = false;
            obj.PMC_CPQ_ContractEnd__c = obj.PMC_CPQ_ContractStart__c.addDays(50);
        }
        update lstQuote;
        userId = lstQuote[0].OwnerId;
        Test.startTest();
        PMC_DM_CreateContractFromQuoteBatch batch1 = new PMC_DM_CreateContractFromQuoteBatch(userId,lstQuoteId);
        Database.executeBatch(batch1);
        Test.stopTest();
        List<SBQQ__Quote__c> updatedQuotes = [SELECT Id, PMC_CLM_ContractCreated__c FROM SBQQ__Quote__c WHERE PMC_CLM_ContractCreated__c =: true];
        System.assertEquals(3, updatedQuotes.size(),'Contract not created');
        }
    }
}