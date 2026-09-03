/**
* @description This test class will be used to cover all the methods of PMC_DM_SubscriptionCreateBatchTest
* @author Preethi J
*/
@isTest
public class PMC_DM_SubscriptionCreateBatchTest {
    public Static List<Id> lstQuoteId = new List<Id>();
    public Static List<Opportunity> lstOpty = new List<Opportunity>();
    public Static List<Contact> lstContact = new List<Contact>();
    public static Id userId;
    public static List<SBQQ__Quote__c> lstQuotes;
    public static Account objAccount;
    public static Account objAccount1;
    public static List<Account> lstAccount = new List<Account>();
    public static List<SBQQ__QuoteLine__c> lstQLs;
    public static List<Product2> lstProduct;
    public static List<Contract> lstCon;
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
        objAccount = PMC_TestUtilityClass.createAccount('Test Account 01', 'PMC_SS_Prospect');
        objAccount1 = PMC_TestUtilityClass.createAccount('Test Account 02', 'PMC_SS_Prospect');
        lstAccount.add(objAccount);
        lstAccount.add(objAccount1);
        lstOpty = PMC_TestUtilityClass.createOpportunity(1,'Master');
        lstContact = PMC_TestUtilityClass.createContact(1,'Master');
        lstQuotes = PMC_TestUtilityClass.createCPQQuotes(1,lstOpty , lstContact);
        lstProduct = PMC_TestUtilityClass.createProduct(1,'PMC_CPQ_NA');
        lstCon = PMC_TestUtilityClass.createContract(lstAccount,lstOpty);
        lstCon[0].SBQQ__Quote__c = lstQuotes[0].Id;
        update lstCon;
        lstQuotes[0].PMC_CLM_ContractCreated__c = true;   
        update lstQuotes;
            SBQQ__QuoteLine__c objQLs = new SBQQ__QuoteLine__c();
            objQLs.SBQQ__Quote__c = lstQuotes[0].Id;
            objQLs.SBQQ__Product__c = lstProduct[0].Id;
            objQLs.CurrencyIsoCode ='USD';
            objQLs.PMC_CPQ_PercentageOfQuantity__c =0;
            objQLs.PMC_CPQ_PriceGuidanceCeiling__c =0;
            objQLs.PMC_CPQ_Commission__c =0;
            objQLs.PMC_CPQ_CommissionCurrency__c =0;
            objQLs.PMC_CPQ_CostAdjustment__c =0;
            objQLs.PMC_CPQ_CropType__c ='Corn Safrinha';
            objQLs.PMC_CPQ_CustomerOfferedPrice__c = false;
            objQLs.PMC_CPQ_ExspaceIndicator__c =True;
            objQLs.PMC_CPQ_FinalPricePerTon__c =0;
            objQLs.PMC_CPQ_Incoterms1__c ='CIF';
            objQLs.SBQQ__Quantity__c =120;
            objQLs.PMC_CPQ_UnitofMeasure__c ='MTN';
            objQLs.PMC_CPQ_ModeofTransportation__c ='Truck';
            /*objQLs.PMC_CPQ_ProductLocation__c = */
            objQLs.PMC_CPQ_PriceDueDate__c =Date.newInstance(2024, 05, 25);
            //objQLs.PMC_CPQ_ShipTo__c = obj.SBQQ__Opportunity2__r.AccountId;
            objQLs.PMC_CPQ_QuoteRecordSubType__c = 'B2C - Fertilizer';
            objQLs.PMC_CPQ_QuoteRecordType__c ='Domestic SA';
            objQLs.PMC_CPQ_PaymentTerms__c = 'Fixed Date';
            objQLs.SBQQ__SubscriptionPricing__c ='Fixed Price';          
           	//lstQLs.add(objQLs);
        	insert objQLs;
    }
    }
    /*
     * @description This method will run the Execute method by passing only user id
*/
    @isTest
    public static void testBatchExecution(){
        List<User> lstUser = [SELECT Id FROM User WHERE LastName ='Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(lstUser.get(0)){
       List<SBQQ__Quote__c> lstQuote = [select OwnerId,SBQQ__Opportunity2__r.AccountId,PMC_CPQ_AccountManager__c,CurrencyIsoCode,SBQQ__PriceBook__c,SBQQ__PaymentTerms__c,SBQQ__Account__c,PMC_CLM_ContractCreated__c, Id from SBQQ__Quote__c LIMIT 5];
        userId = lstQuote[0].OwnerId;
        List<SBQQ__QuoteLine__c> lstQLS = [select id from SBQQ__QuoteLine__c];
        Test.startTest();
        PMC_DM_SubscriptionCreateBatch batch4 = new PMC_DM_SubscriptionCreateBatch(userId);
        Database.executeBatch(batch4);
        
        Test.stopTest();
        List<SBQQ__Subscription__c> lstSub = [select id from SBQQ__Subscription__c where SBQQ__QuoteLine__c =: lstQLS[0].Id];
        System.assert(!lstSub.isEmpty(), 'List should not be empty');
        }
    }
    /*
     * @description This method will run the Execute method by passing both user id and list of quote ids
*/
     @isTest
    public static void testBatchExecution2(){
        List<User> lstUser = [SELECT Id FROM User WHERE LastName ='Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(lstUser.get(0)){
       List<SBQQ__Quote__c> lstQuote = [select OwnerId,SBQQ__Opportunity2__r.AccountId,PMC_CPQ_AccountManager__c,CurrencyIsoCode,SBQQ__PriceBook__c,SBQQ__PaymentTerms__c,SBQQ__Account__c,PMC_CLM_ContractCreated__c, Id from SBQQ__Quote__c LIMIT 5];
        userId = lstQuote[0].OwnerId;
        List<Id> lstQLId = new List<Id>();
        List<SBQQ__QuoteLine__c> lstQLS = [select id from SBQQ__QuoteLine__c];
        for(SBQQ__QuoteLine__c objQl:[select id from SBQQ__QuoteLine__c]){
            lstQLId.add(objQl.Id);
        }
        Test.startTest();
        PMC_DM_SubscriptionCreateBatch batch4 = new PMC_DM_SubscriptionCreateBatch(userId, lstQLId);
        Database.executeBatch(batch4);
        
        Test.stopTest();
        List<SBQQ__Subscription__c> lstSub = [select id from SBQQ__Subscription__c where SBQQ__QuoteLine__c =: lstQLS[0].Id];
        System.assert(!lstSub.isEmpty(), 'List should not be empty');
        }
    }
}