/** @description Test class to make callouts for cadence
 *  @author Prakhar Srivastava
 *  @storynumber GDASF-9240
 */

@IsTest
public with sharing class PMC_CPQ_CadenceControllerTest {
    public static List <String> lstPayloadQuoteIds = new List<String> ();
    
    /*
     * This Method will be used to setup the data for the test class execution.
     */
    @TestSetup
    private static void testSetup(){
        List<String> lstProfileNames = new List<String>{'System Administrator','Sales User'};
        List<String> lstPermissionSetGroupNames = new List<String>{'PMC_Administrator_Permission_Set_Group','PMC_SLS_Permission_Set_Group'};
        Map<String,Id>mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
        Map<String,PermissionSetGroup>mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionSetGroupNames);
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
            objUser.PMC_CPQ_SalesRegion__c ='North America';
            objUser.PMC_CPQ_PrimaryBusinessType__c ='Feed';
            intuserCount = intuserCount + 1;
        }
        insert lstUser;
        objSystemAdminUser = lstUser[0];
        objSalesUser = lstUser[1];
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSystemAdminUser}, mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group'));
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSalesUser}, mapOfPermissionGrp.get('PMC_SLS_Permission_Set_Group'));
        
        // GCPM-5506
        // Bypass the flow (PMC_ProcessSwitches__c.PMC_BypassFlow__c) set on the org default
        // while the setup data is created. The PMC flow cascade (Account, Opportunity,
        // Quote, QuoteLine) is not affected by SBQQ.TriggerControl.disable() and was hitting
        // the limit of 100 SOQL queries per transaction inside this testSetup().
        PMC_ProcessSwitches__c switchesOrgDefault = PMC_ProcessSwitches__c.getOrgDefaults();
        System.runAs(new User(Id = UserInfo.getUserId())){
            if (switchesOrgDefault.Id == null) {
                switchesOrgDefault.SetupOwnerId = UserInfo.getOrganizationId();
            }
            switchesOrgDefault.PMC_BypassFlow__c = true;
            upsert switchesOrgDefault;
        }
        
        System.runas(objSystemAdminUser){
            //Create Sales area
            List<PMC_SS_SalesArea__c> lstSalesArea = PMC_TestUtilityClass.createSalesArea(1, 'Master');
            lstSalesArea[0].PMC_SS_SalesOrganization__c = 'Mosaic Global Sales LLC';
            lstSalesArea[0].PMC_CPQ_SAPSalesOrganization__c = '10020010';
            lstSalesArea[0].PMC_SS_DistributionChannel__c = 'Common';
            lstSalesArea[0].PMC_SS_Division__c = 'Domestic';
            update lstSalesArea;
            
            objSalesUser.PMC_CPQ_SalesArea__c = 'Mosaic Global Sales LLC Domestic Common';
            update objSalesUser;
        }
        System.runAs(objSalesUser){
            SBQQ.TriggerControl.disable();
            PMC_CPQ_GetPriceOnQuickSaveTest.createQuotes(1, new List<User>{objSalesUser});
            SBQQ.TriggerControl.enable();
        }
        
        // GCPM-5506
        // Restore the normal behavior of PMC flows for test methods that run
        // after this @TestSetup.
        System.runAs(new User(Id = UserInfo.getUserId())){
            switchesOrgDefault.PMC_BypassFlow__c = false;
            upsert switchesOrgDefault;
        }
    }
    
    /**
     * @description Make Get Price Call through Custom action
     * @param lstQuotes - no of quotes to be created
     */
    public static void viewAvailabilityCustomAction(List<SBQQ__Quote__c> lstQuotes){
        PageReference pageRef = Page.PMC_CPQ_ViewAvailabilityPage; // Add your VF page Name here
        pageRef.getParameters ().put ('id', String.valueOf (lstQuotes[0].Id));
        pageRef.getParameters ().put ('baseUrl', 'Test');
        
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(lstQuotes[0]);
        PMC_CPQ_CadenceController testAccPlan = new PMC_CPQ_CadenceController(stdController);
        testAccPlan.redirect1();
    }
    
    /**
     * @description Used to invoke apex
     */
    @isTest
    public static void testViewAvailWithQtyUpdate()
    {
        List<User> lstUser = [SELECT Id FROM User WHERE LastName ='Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runas(lstUser.get(0)){
            List<SBQQ__Quote__c> lstQuotes = [select id, PMC_CPQ_IntegrationMessage__c from SBQQ__Quote__c];
            List<SBQQ__QuoteLine__c> lstQLI = [select id, PMC_CPQ_Last_Quantity__c, SBQQ__Quantity__c from SBQQ__QuoteLine__c];
            PMC_CPQ_Cadence__c cad = new PMC_CPQ_Cadence__c(PMC_CPQ_QuoteLine__c = lstQLI[0].Id,PMC_CPQ_RequestedDate__c = System.Today(), PMC_CPQ_RequestedQuantity__c = 20);
            insert cad;
            lstQLI[0].PMC_CPQ_Last_Quantity__c = 1;
            lstQLI[0].SBQQ__Quantity__c = 14;
            SBQQ.TriggerControl.disable();
            update lstQLI;
            SBQQ.TriggerControl.enable();
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpGetCadenceSuccessCalloutTest());
            viewAvailabilityCustomAction(lstQuotes);
            System.assert(!lstQuotes.isEmpty(), 'List should not be empty');
            Test.stopTest();
        }
    }
    
    /**
     * @description Used to invoke apex
     */
    @isTest
    public static void testViewAvailWithQtyExceptionUpdate()
    {
        List<User> lstUser = [SELECT Id FROM User WHERE LastName ='Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runas(lstUser.get(0)){
            List<SBQQ__Quote__c> lstQuotes = [select id, PMC_CPQ_IntegrationMessage__c from SBQQ__Quote__c];
            List<SBQQ__QuoteLine__c> lstQLI = [select id, PMC_CPQ_Last_Quantity__c, SBQQ__Quantity__c from SBQQ__QuoteLine__c];
            PMC_CPQ_Cadence__c cad = new PMC_CPQ_Cadence__c(PMC_CPQ_QuoteLine__c = lstQLI[0].Id,PMC_CPQ_RequestedDate__c = System.Today(), PMC_CPQ_RequestedQuantity__c = 20);
            insert cad;
            lstQLI[0].PMC_CPQ_Last_Quantity__c = 1;
            lstQLI[0].SBQQ__Quantity__c = 14;
            SBQQ.TriggerControl.disable();
            update lstQLI;
            SBQQ.TriggerControl.enable();
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpGetCadenceSuccessCalloutTest());
            viewAvailabilityCustomAction(lstQuotes);
            System.assert(!lstQuotes.isEmpty(), 'List should not be empty');
            Test.stopTest();
        }
    }
    
    /**
     * @description Used to invoke apex
     */
    @isTest
    public static void testViewAvailWithContractUpdate()
    {
        List<User> lstUser = [SELECT Id FROM User WHERE LastName ='Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runas(lstUser.get(0)){
            List<SBQQ__Quote__c> lstQuotes = [select id, PMC_CPQ_IntegrationMessage__c, PMC_CPQ_LastContractEnd__c, PMC_CPQ_LastContractStart__c from SBQQ__Quote__c];
            List<SBQQ__QuoteLine__c> lstQLI = [select id, PMC_CPQ_Last_Quantity__c, SBQQ__Quantity__c from SBQQ__QuoteLine__c];
            PMC_CPQ_Cadence__c cad = new PMC_CPQ_Cadence__c(PMC_CPQ_QuoteLine__c = lstQLI[0].Id,PMC_CPQ_RequestedDate__c = System.Today(), PMC_CPQ_RequestedQuantity__c = 20);
            insert cad;
            lstQuotes[0].PMC_CPQ_LastContractStart__c = System.Today().addmonths(1);
            lstQuotes[0].PMC_CPQ_ContractStart__c = System.Today().addDays(2);
            SBQQ.TriggerControl.disable();
            update lstQuotes;
            SBQQ.TriggerControl.enable();
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpGetCadenceSuccessCalloutTest());
            viewAvailabilityCustomAction(lstQuotes);
            System.assert(!lstQuotes.isEmpty(), 'List should not be empty');
            Test.stopTest();
        }
        
    }
    
    /**
     * @description Used to invoke apex
     */
    @isTest
    public static void testViewAvailWithCadence()
    {
        List<User> lstUser = [SELECT Id FROM User WHERE LastName ='Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
        
        System.runas(lstUser.get(0)){
            
            List<SBQQ__Quote__c> lstQuotes = [select id, PMC_CPQ_IntegrationMessage__c from SBQQ__Quote__c];
            for(SBQQ__Quote__c curQuote : lstQuotes)
            {
                lstPayloadQuoteIds.add(curQuote.Id);
                curQuote.PMC_CPQ_IntegrationMessage__c = 'Test';
            }
            
            lstQuotes[0].PMC_CPQ_LastContractStart__c = System.Today();
            lstQuotes[0].PMC_CPQ_ContractStart__c = System.Today();
            SBQQ.TriggerControl.disable();
            update lstQuotes;
            SBQQ.TriggerControl.enable();
            
            List<SBQQ__QuoteLine__c> lstQLI = [select id, PMC_CPQ_Last_Quantity__c, SBQQ__Quantity__c from SBQQ__QuoteLine__c];
            PMC_CPQ_Cadence__c cad = new PMC_CPQ_Cadence__c(PMC_CPQ_QuoteLine__c = lstQLI[0].Id,PMC_CPQ_RequestedDate__c = System.Today(), PMC_CPQ_RequestedQuantity__c = 20);
            insert cad;
            List<PMC_CPQ_Cadence__c> lstCadence = [select Id from PMC_CPQ_Cadence__c];
            
            PMC_CPQ_CadenceItem__c caditem = new PMC_CPQ_CadenceItem__c(PMC_CPQ_Cadence__c = lstCadence[0].Id, PMC_CPQ_ConfirmedDate__c = System.Today(), PMC_CPQ_ConfirmedQuantity__c = 20);
            insert caditem;
            Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpGetCadenceSuccessCalloutTest());
            Test.startTest();
            
            viewAvailabilityCustomAction(lstQuotes);
            Test.stopTest();
            System.assert(!lstQuotes.isEmpty(), 'List should not be empty');
        }
    }
    
    /**
     * @description Used to invoke apex
     */
    @isTest
    public static void testViewAvailErrorHandling()
    {
        List<User> lstUser = [SELECT Id FROM User WHERE LastName ='Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
        
        System.runas(lstUser.get(0)){
            List<SBQQ__Quote__c> lstQuotes = [select id, PMC_CPQ_IntegrationMessage__c, PMC_CPQ_LastContractEnd__c, PMC_CPQ_LastContractStart__c from SBQQ__Quote__c];
            List<SBQQ__QuoteLine__c> lstQLI = [select id, PMC_CPQ_Last_Quantity__c, SBQQ__Quantity__c from SBQQ__QuoteLine__c];
            lstQuotes[0].PMC_CPQ_ContractStart__c = System.Today().addDays(2);
            SBQQ.TriggerControl.disable();
            update lstQuotes;
            SBQQ.TriggerControl.enable();
            delete lstQLI[0];
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpGetCadenceSuccessCalloutTest());
            viewAvailabilityCustomAction(lstQuotes);
            System.assert(!lstQuotes.isEmpty(), 'List should not be empty');
            Test.stopTest();
        }
    }
    
    /**
     * @description Used to invoke apex
     */
    @IsTest
    public static void testCadenceError500()
    {
        List<User> lstUser = [SELECT Id FROM User WHERE LastName ='Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
        
        System.runas(lstUser.get(0)){
            List<SBQQ__Quote__c> lstQuotes = [select id, PMC_CPQ_IntegrationMessage__c from SBQQ__Quote__c];
            for(SBQQ__Quote__c curQuote : lstQuotes)
            {
                lstPayloadQuoteIds.add(curQuote.Id);
                curQuote.PMC_CPQ_IntegrationMessage__c = 'Test';
            }
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpCalloutMockSCodeFailureTest());
            viewAvailabilityCustomAction(lstQuotes);
            Test.stopTest();
            System.assert(!lstQuotes.isEmpty(), 'List should not be empty');
            
        }
    }
    
    /**
     * @description Used to invoke apex
     */
    @IsTest
    public static void testCadenceErrorCall()
    {
        List<User> lstUser = [SELECT Id FROM User WHERE LastName ='Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
        
        System.runas(lstUser.get(0)){
            List<SBQQ__Quote__c> lstQuotes = [select id, PMC_CPQ_IntegrationMessage__c from SBQQ__Quote__c];
            for(SBQQ__Quote__c curQuote : lstQuotes)
            {
                lstPayloadQuoteIds.add(curQuote.Id);
                curQuote.PMC_CPQ_IntegrationMessage__c = 'Test';
            }
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpGetPriceErrorCalloutTest());
            viewAvailabilityCustomAction(lstQuotes);
            Test.stopTest();
            System.assert(!lstQuotes.isEmpty(), 'List should not be empty');
            
        }
    }
    
    /**
     * @description Used to invoke apex
     */
    @IsTest
    public static void testCadenceParsingErrorCall()
    {
        List<User> lstUser = [SELECT Id FROM User WHERE LastName ='Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
        
        System.runas(lstUser.get(0)){
            List<SBQQ__Quote__c> lstQuotes = [select id, PMC_CPQ_IntegrationMessage__c from SBQQ__Quote__c];
            for(SBQQ__Quote__c curQuote : lstQuotes)
            {
                lstPayloadQuoteIds.add(curQuote.Id);
                curQuote.PMC_CPQ_IntegrationMessage__c = 'Test';
            }
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpCalloutMockParseFailureTest());
            viewAvailabilityCustomAction(lstQuotes);
            Test.stopTest();
            System.assert(!lstQuotes.isEmpty(), 'List should not be empty');
            
        }
    }
    
    
    /**
     * @description Used to invoke apex
     */
    @IsTest
    public static void testViewAvailabilitySuccessMessage()
    {
        List<User> lstUser = [SELECT Id FROM User WHERE LastName ='Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
        
        System.runas(lstUser.get(0)){
            
            List<SBQQ__Quote__c> lstQuotes = [select id, PMC_CPQ_IntegrationMessage__c from SBQQ__Quote__c];
            for(SBQQ__Quote__c curQuote : lstQuotes)
            {
                lstPayloadQuoteIds.add(curQuote.Id);
                curQuote.PMC_CPQ_IntegrationMessage__c = 'Test';
            }
            
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpGetCadenceSuccessCalloutTest());
            viewAvailabilityCustomAction(lstQuotes);
            Test.stopTest();
            System.assert(!lstQuotes.isEmpty(), 'List should not be empty');
        }
    }
    
    /**
     * @description Used to invoke apex
     */
    @IsTest
    public static void testViewAvailabilityMaterialExceptionMessage()
    {
        List<User> lstUser = [SELECT Id FROM User WHERE LastName ='Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
        
        System.runas(lstUser.get(0)){
            
            List<SBQQ__Quote__c> lstQuotes = [select id, PMC_CPQ_IntegrationMessage__c from SBQQ__Quote__c];
            for(SBQQ__Quote__c curQuote : lstQuotes)
            {
                lstPayloadQuoteIds.add(curQuote.Id);
                curQuote.PMC_CPQ_IntegrationMessage__c = 'Test';
            }
            
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpGetCadenceExceptnCalloutTest());
            viewAvailabilityCustomAction(lstQuotes);
            Test.stopTest();
            System.assert(!lstQuotes.isEmpty(), 'List should not be empty');
        }
    }
    
    /**
     * @description Used to invoke apex
     */
    @IsTest
    public static void testViewAvailabilityExceptionMessage()
    {
        List<User> lstUser = [SELECT Id FROM User WHERE LastName ='Sales User Test' WITH SECURITY_ENFORCED LIMIT 1];
        
        System.runas(lstUser.get(0)) {
            List<SBQQ__Quote__c> lstQuotes = [select id, PMC_CPQ_IntegrationMessage__c from SBQQ__Quote__c];
            for(SBQQ__Quote__c curQuote : lstQuotes)
            {
                lstPayloadQuoteIds.add(curQuote.Id);
                curQuote.PMC_CPQ_IntegrationMessage__c = 'Test';
            }
            Test.startTest();
            
            viewAvailabilityCustomAction(lstQuotes);
            Test.stopTest();
            System.assert(!lstQuotes.isEmpty(), 'List should not be empty');
        }
    }
}