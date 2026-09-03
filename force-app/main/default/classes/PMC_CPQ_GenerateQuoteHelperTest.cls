/**
* @description Test class for PMC_CPQ_GenerateQuoteHelper.
* @author Raphael Soares
* @storynumber GCPM-5347
* @changelog
*   GCPM-5347 (2026-07-14): Replaced EnvironmentChecker-based expected values with PMC_CLM_EnvironmentSettingService test overrides; added testMissingEnvironmentSetting
**/
@IsTest
private class PMC_CPQ_GenerateQuoteHelperTest {
    @TestSetup
    static void setup() {
        List<String> lstProfileNames = new List<String>{'System Administrator','Sales User'};
        List<UserRole> userRoleName = [SELECT Id FROM UserRole WHERE Name = 'Service Director'];
        List<String> lstPermissionNames = new List<String>{'PMC_Administrator_Permission_Set_Group','PMC_SLS_Permission_Set_Group'};
        Map<String,Id> mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
        Map<String,PermissionSetGroup> mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionNames);
        Integer intuserCount = 0;
        User objSystemAdminUser;  
        User objSalesUser;
        List<User> lstUser = PMC_TestUtilityClass.createUser(2);
        for(User objUser : lstUser) {
            if(intuserCount == 0){
                objUser.LastName = 'Admin User Test';
                objUser.ProfileId = mapOfProfiles.get('System Administrator'); 
                objUser.FederationIdentifier = objUser.Username + 'Admin';
                objUser.UserRoleId = userRoleName[0].id;
            }else if(intuserCount == 1){
                objUser.LastName = 'Sales User Test PMC_CPQ_GenerateQuoteHelperTest';
                objUser.ProfileId = mapOfProfiles.get('Sales User'); 
                objUser.FederationIdentifier = objUser.Username + 'Sales';
            }
            objUser.PMC_CPQ_SalesArea__c = 'Mosaic Global Sales LLC Export Common';
            objUser.PMC_CPQ_SalesRegion__c = 'Brazil';
            objUser.isActive = true;                
            objUser.MobilePhone = '1234567890';
            objUser.UserPermissionsKnowledgeUser = true;
            objUser.LanguageLocaleKey = 'en_US';
            intuserCount = intuserCount + 1;
        }            
        insert lstUser;
        objSystemAdminUser = lstUser[0];
        objSalesUser = lstUser[1];
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(
            new List<User>{objSystemAdminUser}, 
            mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group')
        );
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(
            new List<User>{objSalesUser}, 
            mapOfPermissionGrp.get('PMC_SLS_Permission_Set_Group')
        );
        
        System.runAs(objSystemAdminUser) {
            PMC_ProcessSwitches__c bypassSetting = PMC_ProcessSwitches__c.getOrgDefaults();
            bypassSetting.PMC_BypassValidationRule__c = true;
            upsert bypassSetting;
            
            Account acc = new Account(Name = 'Test Account', BillingCity = 'toronto', BillingStreet = 'tor');
            insert acc;
            
            PMC_SS_SalesArea__c salesArea = new PMC_SS_SalesArea__c(
                Name = 'Brazil Area',
                PMC_CPQ_SAPSalesOrganization__c = '40000010',
                PMC_SS_SalesOrganization__c = 'Mosaic Global Sales LLC',
                PMC_SS_DistributionChannel__c = '0',
                PMC_SS_Division__c = '20'
            );
            insert salesArea;
            
            PMC_SS_AccountSalesAreaRelationship__c salesAreaAssignment = new PMC_SS_AccountSalesAreaRelationship__c(
                Name = 'Test Sales Area Assignment',
                PMC_SS_Account__c = acc.Id, 
                PMC_SS_SalesArea__c = salesArea.Id
            );
            insert salesAreaAssignment;
            
            Product2 product = new Product2(
                Name = 'Test Product',
                IsActive = true
            );
            insert product;
            
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = product.Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false
            );
            insert pbe;
            
            SBQQ__Quote__c validQuote = new SBQQ__Quote__c(
                SBQQ__Account__c = acc.Id,
                SBQQ__PriceBook__c = Test.getStandardPricebookId(),
                SBQQ__Primary__c = true,
                PMC_CPQ_SalesArea__c = salesAreaAssignment.Id,
                PMC_CPQ_Region__c = 'Brazil',
                PMC_CPQ_ContractLanguage__c = 'Portuguese',
                PMC_CPQ_ContractShippingInstructions__c = 'Test Shipping Instructions',
                PMC_CPQ_AccountManager__c = objSalesUser.Id
            );
            insert validQuote;
            
            SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = validQuote.Id,
                SBQQ__Product__c = product.Id,
                SBQQ__PricebookEntryId__c = pbe.Id,
                SBQQ__Quantity__c = 1,
                SBQQ__NetPrice__c = 100,
                PMC_CPQ_EstFreightPrice__c = 10,
                PMC_CPQ_QuoteRecordType__c = 'Domestic SA',
                PMC_CPQ_QuoteRecordSubType__c = 'B2C - Fertilizer',
                PMC_CPQ_Incoterms1__c = 'CIF'
            );
            insert quoteLine;
        }
    }
    
    @isTest
    static void testValidSpanishContract() {
        User testUser = [SELECT Id, Name FROM User WHERE LastName='Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id, Name, PMC_CLM_Region__c, PMC_CPQ_ContractLanguage__c FROM SBQQ__Quote__c LIMIT 1];
        System.runAs(testUser) {
            // ======    START    ======      GCPM-5347
            PMC_CLM_EnvironmentSettingService.environmentNameOverride = 'unittest';
            PMC_CLM_EnvironmentSettingService.settingsOverride = new Map<String, PMC_CLM_Environment_Setting__mdt>{
                'unittest' => new PMC_CLM_Environment_Setting__mdt(
                    DeveloperName = 'unittest',
                    PMC_CLM_AccountId__c = '98018',
                    PMC_CLM_BaseUrl__c = 'https://uatna11.springcm.com'
                )
            };
            String expectedParam = 'aid=98018';
            // ======      END      ======      GCPM-5347
            quote.PMC_CPQ_Region__c = 'Brazil';
            quote.PMC_CPQ_ContractLanguage__c = 'Spanish';
            update quote;
            Test.startTest();
            String result = PMC_CPQ_GenerateQuoteHelper.generateContract(quote.Id);
            Test.stopTest();
            System.assert(result.contains(expectedParam), 'Should generate Spanish contract URL' + expectedParam + '\nActual result:' + result);
        }
    }
    
    @isTest
    static void testMissingShippingInstructions() {
        SBQQ__Quote__c quote = [SELECT Id, PMC_CPQ_ContractShippingInstructions__c FROM SBQQ__Quote__c LIMIT 1];
        quote.PMC_CPQ_ContractShippingInstructions__c = null;
        update quote;
        
        Test.startTest();
        try {
            PMC_CPQ_GenerateQuoteHelper.generateContract(quote.Id);
            System.assert(false, 'Expected exception not thrown');
        } catch (CustomException e) {
            System.assertEquals('Shipping Instructions field is empty. Please fill it before generating the contract.', e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testInvalidRegion() {
        PMC_SS_SalesArea__c salesArea = [SELECT Id, PMC_SS_Division__c, PMC_SS_SalesOrganization__c, PMC_CPQ_SAPSalesOrganization__c FROM PMC_SS_SalesArea__c LIMIT 1];
        salesArea.PMC_CPQ_SAPSalesOrganization__c = '123';
        salesArea.PMC_SS_SalesOrganization__c = 'Mosaic Global Sales LLC';
        salesArea.PMC_SS_Division__c = '20';
        update salesArea;
        
        Test.startTest();
        try {
            PMC_CPQ_GenerateQuoteHelper.generateContract([SELECT Id FROM SBQQ__Quote__c LIMIT 1].Id);
            System.assert(false, 'Expected exception not thrown');
        } catch (CustomException e) {
            System.assertEquals('Contract generation is only available for Brazil region.', e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testInvalidLanguage() {
        SBQQ__Quote__c quote = [SELECT Id, Name, PMC_CPQ_Region__c, PMC_CPQ_ContractLanguage__c FROM SBQQ__Quote__c LIMIT 1];
        quote.PMC_CPQ_Region__c = 'Brazil';
        quote.PMC_CPQ_ContractLanguage__c = 'English';
        
        Test.startTest();
        try {
            update quote;
            PMC_CPQ_GenerateQuoteHelper.generateContract(quote.Id);
            System.assert(false, 'Expected exception not thrown');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST, bad value for restricted picklist field: English: [PMC_CPQ_ContractLanguage__c]'));
        }
        Test.stopTest();
    }
    
    @isTest
    static void testQuoteNotFound() {
        try {
            Test.startTest();
            PMC_CPQ_GenerateQuoteHelper.generateContract('invalidId');
            Test.stopTest();
            System.assert(false, 'Expected exception not thrown');
        } catch (CustomException e) {
            System.assertEquals('Quote not found or access denied.', e.getMessage());
        }
    }

    // ======    START    ======      GCPM-5347
    // Test environment without a PMC_CLM_Environment_Setting__mdt record — must fail fast, no fallback
    @isTest
    static void testMissingEnvironmentSetting() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        PMC_CLM_EnvironmentSettingService.environmentNameOverride = 'newsandbox';
        PMC_CLM_EnvironmentSettingService.settingsOverride = new Map<String, PMC_CLM_Environment_Setting__mdt>();
        String expectedMessage = String.format(System.Label.PMC_CLM_EnvironmentSettingMissing, new List<String>{ 'newsandbox' });

        Test.startTest();
        try {
            PMC_CPQ_GenerateQuoteHelper.generateContract(quote.Id);
            System.assert(false, 'Expected exception not thrown');
        } catch (CustomException e) {
            System.assertEquals(expectedMessage, e.getMessage());
        }
        Test.stopTest();
    }
    // ======      END      ======      GCPM-5347

    @IsTest
    static void testGetQuotePrimaryContact() {
        SBQQ__Quote__c quoteRecord = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Test.startTest();
        Map<String, String> result = PMC_CPQ_GenerateQuoteHelper.getQuotePrimaryContact(quoteRecord.Id);
        Test.stopTest();
        System.assertNotEquals(null, result.get('primaryContactName'));
        System.assertNotEquals(null, result.get('quoteName'));
    }

    @IsTest
    static void testUpdateDocusignPicklist() {
        SBQQ__Quote__c quoteRecord = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Test.startTest();
        PMC_CPQ_GenerateQuoteHelper.updateDocusignPicklist(quoteRecord.Id, 'Yes');
        Test.stopTest();
        SBQQ__Quote__c updated = [
            SELECT Id, PMC_CPQ_Docusign__c 
            FROM SBQQ__Quote__c 
            WHERE Id = :quoteRecord.Id
        ];
        System.assertEquals('Yes', updated.PMC_CPQ_Docusign__c);
    }
}