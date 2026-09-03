/** @description This is the test class to make callouts to the Quote and Contract Creation interface of CPI. 
 *  @author Shefali Dsouza
 *  @storynumber GDASF-6864, GDASF-5842
 */

@isTest
public without sharing class PMC_CPQ_CPIRemoteCalloutUtilityTest {

    public static List <String> lstPayloadQuoteIds = new List<String> ();  
     
     /** 
     * @description Used to create CPQ Test User 
     * @param strUserProfile - Specifies the profile of requested user
     * @param lstPermissionNames - List of permission sets to be assigned
     * @return User - Returns the requested user
     */
    public static User createCPQTestUser(String strUserProfile, List<String>lstPermissionNames){ 
		List<String>lstProfileNames = New List<String>();
		lstProfileNames.add(strUserProfile);
        Map<String,Id>mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
        Map<String,PermissionSetGroup>mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionNames);
        List<User> lstUser = PMC_TestUtilityClass.createUser(1);
            for(User objUser : lstUser) {
                    objUser.LastName = strUserProfile+ ' Test';
                    objUser.ProfileId = mapOfProfiles.get(strUserProfile); 
                    objUser.FederationIdentifier = objUser.Username + strUserProfile;
                    objUser.Username = 'Integtestuser' + strUserProfile.split('', 1) + '@test.com'; //
                    objUser.isActive = true;                
                    objUser.MobilePhone = '1234567890';
                    objUser.UserPermissionsKnowledgeUser = true;
                    objUser.LanguageLocaleKey = 'en_US';  
            }      
            insert lstUser;
        for(String strPermissionName: lstPermissionNames)
        {
            PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{lstUser[0]}, mapOfPermissionGrp.get(strPermissionName));
        }   
        return lstUser[0];
    }
    /** 
     * @description Creates Quote data for testing 
     * @param numQuote - no of quotes to be created
     * @return lstQuotes - return list of quotes
     */
	public static List<SBQQ__Quote__c> createQuotes(Integer numQuote) {
        List<Opportunity> lstOpportunities;
        lstOpportunities = PMC_TestUtilityClass.createOpportunity(1,'Master');
        List<Contact> lstContacts;
        lstContacts = PMC_TestUtilityClass.createContact(1,'Master');
        List<SBQQ__Quote__c> lstQuotes;
        List<Account> lstAcct = [select Id,PMC_SS_AccountExternalID__c,PMC_SS_SAPCustomerNumber__c from Account where Id =: lstOpportunities[0].AccountId];

        String strSandboxName = UserInfo.getUserName().substringAfterLast('.');
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String email = 'admintestuser@mosaicco.com';
        UUID randomUuid = UUID.randomUUID();
        User adminUser = new User();
        adminUser.FirstName = 'Admin';
        adminUser.LastName = 'Test User';
        adminUser.Alias = 'admintst';
        adminUser.Email = email;
        adminUser.Username = email + '.' + strSandboxName + randomUuid.toString();
        adminUser.LanguageLocaleKey = 'pt_BR';
        adminUser.EmailEncodingKey = 'UTF-8';
        adminUser.LocaleSidKey = 'pt_BR';
        adminUser.TimeZoneSidKey = 'America/Sao_Paulo';
        adminUser.MobilePhone = '9999999999';
        adminUser.ProfileId = profiles[0].Id;
        adminUser.IsActive = true;
        insert adminUser;

        // Account's Type can only be edited by Master Data and a few other profiles, so we need to run this part as Master Data user.
        System.runAs(adminUser) {
            lstAcct[0].PMC_SS_AccountExternalID__c = '2378651345';
            lstAcct[0].PMC_SS_SAPCustomerNumber__c = '2378651345';
            lstAcct[0].Type = 'Sold-to';
            update lstAcct;
        }
        lstQuotes = PMC_TestUtilityClass.createCPQQuotes(numQuote,lstOpportunities,lstContacts);  
        return lstQuotes;
	}
	/**
     * @description Used to invoke apex 
     */
    @isTest
    public static void testInvocableQuoteContractCreateException()
    {
        List<String>lstPermissionNames = New List<String>{'PMC_SLS_Permission_Set_Group'};
        System.runAs(createCPQTestUser('Sales User',lstPermissionNames)){  
        List<SBQQ__Quote__c> lstQuotes = PMC_CPQ_CPIRemoteCalloutUtilityTest.createQuotes(1);
        Test.startTest();
        PMC_CPQ_QuoteContractCreateActionClass.postInfoToCPI(lstQuotes);
        PMC_CPQ_CPIRemoteCalloutUtilityClass.autoRetryQueueableApex(0,'Read Timed Out');
        Test.stopTest();
        System.assert(!lstQuotes.isEmpty(), 'List should not be empty');
    }  
    }  
	/** 
     * @description Used to invoke apex 
     */
    @isTest
    public static void testInvocableQuoteContractCreateSuccess()
    {
        List<String>lstPermissionNames = New List<String>{'PMC_SLS_Permission_Set_Group'};
        System.runAs(createCPQTestUser('Sales User',lstPermissionNames)){ 
        List<SBQQ__Quote__c> lstQuotes = PMC_CPQ_CPIRemoteCalloutUtilityTest.createQuotes(1);
		for(SBQQ__Quote__c objQuote : lstQuotes)
        {
            lstPayloadQuoteIds.add(objQuote.Id);
        }
        
        Test.startTest();
		Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpCalloutMockSuccessTest());
        PMC_CPQ_QuoteContractCreateActionClass.postInfoToCPI(lstQuotes);

        Test.stopTest();
        System.assert(!lstQuotes.isEmpty(), 'List should not be empty'); 
    } 
    } 
    
	/** 
     * @description Used to invoke apex 
     */
    @isTest
    public static void testInvocableContractUpdateSuccess()
    {
        List<String>lstPermissionNames = New List<String>{'PMC_SLS_Permission_Set_Group'};
        System.runAs(createCPQTestUser('Sales User',lstPermissionNames)){ 
        List<SBQQ__Quote__c> lstQuotes = PMC_CPQ_CPIRemoteCalloutUtilityTest.createQuotes(1);
		for(SBQQ__Quote__c curQuote : lstQuotes)
        {
            lstPayloadQuoteIds.add(curQuote.Id);
        }
		Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpCalloutMockSuccessTest());
        Test.startTest();
        PMC_CPQ_ContractUpdateActionClass.postInfoToCPI(lstQuotes);
		
		System.assert(!lstQuotes.isEmpty(), 'List should not be empty'); 
    } 
    } 
    
     /** 
     * @description Used to invoke apex 
     */
    @isTest
    public static void testInvocableContractUpdateException()
    {
        List<String>lstPermissionNames = New List<String>{'PMC_SLS_Permission_Set_Group'};
        System.runAs(createCPQTestUser('Sales User',lstPermissionNames)){ 
        Test.startTest();
        List<SBQQ__Quote__c> lstQuotes = PMC_CPQ_CPIRemoteCalloutUtilityTest.createQuotes(1);
        PMC_CPQ_ContractUpdateActionClass.postInfoToCPI(lstQuotes);
        PMC_CPQ_CPIRemoteCalloutUtilityClass.autoRetryQueueableApex(0,'Read Timed Out');
        Test.stopTest();
        System.assert(!lstQuotes.isEmpty(), 'List should not be empty');
    } 
    } 
    
 	/** 
     * @description Used to invoke apex 
     */
    @isTest
    public static void testInvocableQuoteContractStatusCodeFailure()
    {
        List<String>lstPermissionNames = New List<String>{'PMC_SLS_Permission_Set_Group'};
        System.runAs(createCPQTestUser('Sales User',lstPermissionNames)){  
        List<SBQQ__Quote__c> lstQuotes = PMC_CPQ_CPIRemoteCalloutUtilityTest.createQuotes(1);
		for(SBQQ__Quote__c curQuote : lstQuotes)
        {
            lstPayloadQuoteIds.add(curQuote.Id);
        }
        Test.startTest();
		Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpCalloutMockSCodeFailureTest());
		
        PMC_CPQ_QuoteContractCreateActionClass.postInfoToCPI(lstQuotes);
        
		System.assert(!lstQuotes.isEmpty(), 'List should not be empty'); 
    }
    }
    
    /** 
     * @description Used to invoke apex 
     */
    @isTest
    public static void testInvocableQuoteContractParsingFailure()
    {
        List<String>lstPermissionNames = New List<String>{'PMC_SLS_Permission_Set_Group'};
        System.runAs(createCPQTestUser('Sales User',lstPermissionNames)){  
        List<SBQQ__Quote__c> lstQuotes = PMC_CPQ_CPIRemoteCalloutUtilityTest.createQuotes(1);
		for(SBQQ__Quote__c curQuote : lstQuotes)
        {
            lstPayloadQuoteIds.add(curQuote.Id);
        }
        Test.startTest();
		Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpCalloutMockParseFailureTest());
		
        PMC_CPQ_QuoteContractCreateActionClass.postInfoToCPI(lstQuotes);
        
		System.assert(!lstQuotes.isEmpty(), 'List should not be empty'); 
    }
    }
    
    /** 
     * @description Used to invoke apex 
     */
    @isTest
    public static void testInvocableQuoteContractFailure()
    {
        List<String>lstPermissionNames = New List<String>{'PMC_SLS_Permission_Set_Group'};
        System.runAs(createCPQTestUser('Sales User',lstPermissionNames)){  
        List<SBQQ__Quote__c> lstQuotes = PMC_CPQ_CPIRemoteCalloutUtilityTest.createQuotes(1);
		for(SBQQ__Quote__c curQuote : lstQuotes)
        {
            lstPayloadQuoteIds.add(curQuote.Id);
        }
        Test.startTest();
		Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpCalloutMockFailureTest());
		
        PMC_CPQ_QuoteContractCreateActionClass.postInfoToCPI(lstQuotes);
        
		System.assert(!lstQuotes.isEmpty(), 'List should not be empty'); 
    }
    }
    
        /**
     * @description Test extractQuoteAndErrorMsg for JSON error response
     */
    @isTest
    private static void testExtractQuoteAndErrorMsg_JSON() {
        // Create a test Quote
        List<SBQQ__Quote__c> lstQuotes = createQuotes(1);
        SBQQ__Quote__c q = lstQuotes[0];

        // Mock JSON response with error TYPE = E
        String responseBody = '[{"TYPE":"E","MESSAGE":"Sample technical error","SFRecordId":"' + q.Id + '"}]';
        String requestBody = '{"Id":["' + q.Id + '"]}';

        Map<String, String> trxFields = new Map<String, String>();
        trxFields.put('PMC_CPQ_IntegrationStatus__c','Error');
        trxFields.put('PMC_CPQ_InterfaceURL__c','/http/QuoteandContractReplication');
        trxFields.put('PMC_CPQ_RequestBody__c',requestBody);
        trxFields.put('PMC_CPQ_ResponseBody__c',responseBody);

        Test.startTest();
        Map<String,String> updated = PMC_CPQ_TransactionLogUtilityClass.extractQuoteAndErrorMsg(responseBody, requestBody, trxFields);
        Test.stopTest();

        System.assert(updated.containsKey('PMC_CPQ_Error_Message__c'), 'Error message should be populated');
        System.assert(updated.containsKey('PMC_CPQ_Quote__c'), 'Quote Id should be populated');
        System.assertEquals(q.Id, updated.get('PMC_CPQ_Quote__c'), 'Quote Id should match the test quote');
    }

    /**
     * @description Test extractQuoteAndErrorMsg for non-JSON response (catch block)
     */
    @isTest
    private static void testExtractQuoteAndErrorMsg_NonJSON() {
        // Create a test Quote
        List<SBQQ__Quote__c> lstQuotes = createQuotes(1);
        SBQQ__Quote__c q = lstQuotes[0];

        // Non JSON response
        String responseBody = 'CPI Gateway Down';
        String requestBody = '{"Id":["' + q.Id + '"]}';

        Map<String, String> trxFields = new Map<String, String>();
        trxFields.put('PMC_CPQ_IntegrationStatus__c','Error');
        trxFields.put('PMC_CPQ_InterfaceURL__c','/http/QuoteandContractReplication');
        trxFields.put('PMC_CPQ_RequestBody__c',requestBody);
        trxFields.put('PMC_CPQ_ResponseBody__c',responseBody);

        Test.startTest();
        Map<String,String> updated = PMC_CPQ_TransactionLogUtilityClass.extractQuoteAndErrorMsg(responseBody, requestBody, trxFields);
        Test.stopTest();

        System.assert(updated.get('PMC_CPQ_Error_Message__c').contains('CPI Gateway Down'), 'Error message should contain raw response');
        System.assertEquals(q.Id, updated.get('PMC_CPQ_Quote__c'), 'Quote Id should be populated from request body');
    }
    
    
    /** 
     * @description Used to invoke apex 
     */
    @isTest
    public static void testInvocableContractUpdatePublishSuccess()
    {
        List<String>lstPermissionNames = New List<String>{'PMC_SLS_Permission_Set_Group'};
        System.runAs(createCPQTestUser('Sales User',lstPermissionNames)){ 
        List<SBQQ__Quote__c> lstQuotes = PMC_CPQ_CPIRemoteCalloutUtilityTest.createQuotes(1);
		for(SBQQ__Quote__c curQuote : lstQuotes)
        {
            lstPayloadQuoteIds.add(curQuote.Id);
        }
        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started');
        insert exec;
        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
            MassUpdateExecution__c = exec.Id,
            CreatedQuote__c = lstQuotes.get(0).Id,
            Feature__c = 'ContractDateUpdate',
            Status__c = 'Pending'
        );
        insert line;
		Test.setMock(HttpCalloutMock.class, new PMC_DH_ContractDocumentCalloutMock(204,'','Success'));
        Test.startTest();
        PMC_CPQ_ContractUpdatePublishClass.postInfoToCPI(lstQuotes);
		
		System.assert(!lstQuotes.isEmpty(), 'List should not be empty'); 
    } 
    } 
    
    /** 
     * @description Used to invoke apex 
     */
    @isTest
    public static void testInvocableContractUpdatePublishEmptySuccess()
    {
        List<String>lstPermissionNames = New List<String>{'PMC_SLS_Permission_Set_Group'};
        System.runAs(createCPQTestUser('Sales User',lstPermissionNames)){ 
        List<SBQQ__Quote__c> lstQuotes = PMC_CPQ_CPIRemoteCalloutUtilityTest.createQuotes(1);
		for(SBQQ__Quote__c curQuote : lstQuotes)
        {
            lstPayloadQuoteIds.add(curQuote.Id);
        }
        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started');
        insert exec;
        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
            MassUpdateExecution__c = exec.Id,
            CreatedQuote__c = lstQuotes.get(0).Id,
            Feature__c = 'ContractDateUpdate',
            Status__c = 'Pending'
        );
        insert line;
		Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpCalloutMockSuccessTest());
        Test.startTest();
        PMC_CPQ_ContractUpdatePublishClass.postInfoToCPI(lstQuotes);
		
		System.assert(!lstQuotes.isEmpty(), 'List should not be empty'); 
    } 
    } 
    
     /** 
     * @description Used to invoke apex 
     */
    @isTest
    public static void testInvocableContractUpdatePublishException()
    {
        List<String>lstPermissionNames = New List<String>{'PMC_SLS_Permission_Set_Group'};
        System.runAs(createCPQTestUser('Sales User',lstPermissionNames)){ 
        Test.startTest();
        List<SBQQ__Quote__c> lstQuotes = PMC_CPQ_CPIRemoteCalloutUtilityTest.createQuotes(1);
        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Started');
            insert exec;
            MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
                MassUpdateExecution__c = exec.Id,
                CreatedQuote__c = lstQuotes.get(0).Id,
                Feature__c = 'ContractDateUpdate',
                Status__c = 'Pending'
            );
            insert line;
        PMC_CPQ_ContractUpdatePublishClass.postInfoToCPI(lstQuotes);
        PMC_CPQ_CPIRemoteCalloutUtilityClass.autoRetryQueueableApex(0,'Read Timed Out');
        Test.stopTest();
        System.assert(!lstQuotes.isEmpty(), 'List should not be empty');
    } 
    }

}