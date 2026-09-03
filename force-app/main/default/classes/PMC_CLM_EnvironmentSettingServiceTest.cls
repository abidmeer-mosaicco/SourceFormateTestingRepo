/**
 * @description Test class for PMC_CLM_EnvironmentSettingService.
 * @author Raphael Soares
 * @storynumber GCPM-5347
 * @changelog
 *   GCPM-5347 (2026-07-14): Class created
 */
@isTest(seeAllData=false)
private with sharing class PMC_CLM_EnvironmentSettingServiceTest {

    private static PMC_CLM_Environment_Setting__mdt buildSetting(String strDeveloperName, String strAccountId, String strBaseUrl) {
        return new PMC_CLM_Environment_Setting__mdt(
            DeveloperName = strDeveloperName,
            PMC_CLM_AccountId__c = strAccountId,
            PMC_CLM_BaseUrl__c = strBaseUrl
        );
    }

    private static SBQQ__Quote__c buildQuote() {
        Id objFakeQuoteId = Id.valueOf(SBQQ__Quote__c.SObjectType.getDescribe().getKeyPrefix() + '000000000001');
        return (SBQQ__Quote__c) JSON.deserialize(
            '{"Id":"' + objFakeQuoteId + '","Name":"Q-00001","PMC_CPQ_ContractLanguage__c":"Portuguese"}',
            SBQQ__Quote__c.class
        );
    }

    @isTest
    static void testGetSettingForSandbox() {
        PMC_CLM_EnvironmentSettingService.environmentNameOverride = 'qa2';
        PMC_CLM_EnvironmentSettingService.settingsOverride = new Map<String, PMC_CLM_Environment_Setting__mdt>{
            'qa2' => buildSetting('qa2', '102552', 'https://uatna11.springcm.com')
        };

        Test.startTest();
        PMC_CLM_Environment_Setting__mdt objSetting = PMC_CLM_EnvironmentSettingService.getSetting();
        Test.stopTest();

        System.assertEquals('102552', objSetting.PMC_CLM_AccountId__c, 'Should resolve the qa2 sandbox account id');
        System.assertEquals('https://uatna11.springcm.com', objSetting.PMC_CLM_BaseUrl__c, 'Should resolve the qa2 sandbox base URL');
    }

    @isTest
    static void testGetSettingForProductionNormalizesCase() {
        PMC_CLM_EnvironmentSettingService.environmentNameOverride = 'Production';
        PMC_CLM_EnvironmentSettingService.settingsOverride = new Map<String, PMC_CLM_Environment_Setting__mdt>{
            'Production' => buildSetting('Production', '31298', 'https://na11.springcm.com')
        };

        Test.startTest();
        PMC_CLM_Environment_Setting__mdt objSetting = PMC_CLM_EnvironmentSettingService.getSetting();
        Test.stopTest();

        System.assertEquals('31298', objSetting.PMC_CLM_AccountId__c, 'Should resolve the Production account id regardless of key case');
    }

    @isTest
    static void testGetSettingMissingEnvironmentThrows() {
        PMC_CLM_EnvironmentSettingService.environmentNameOverride = 'newsandbox';
        PMC_CLM_EnvironmentSettingService.settingsOverride = new Map<String, PMC_CLM_Environment_Setting__mdt>();
        String strExpectedMessage = String.format(System.Label.PMC_CLM_EnvironmentSettingMissing, new List<String>{ 'newsandbox' });

        Test.startTest();
        try {
            PMC_CLM_EnvironmentSettingService.getSetting();
            System.assert(false, 'Expected EnvironmentSettingException not thrown');
        } catch (PMC_CLM_EnvironmentSettingService.EnvironmentSettingException e) {
            System.assertEquals(strExpectedMessage, e.getMessage(), 'Exception message should name the unconfigured environment');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetSettingIncompleteRecordThrows() {
        PMC_CLM_EnvironmentSettingService.environmentNameOverride = 'qa2';
        PMC_CLM_EnvironmentSettingService.settingsOverride = new Map<String, PMC_CLM_Environment_Setting__mdt>{
            'qa2' => buildSetting('qa2', null, 'https://uatna11.springcm.com')
        };

        Test.startTest();
        try {
            PMC_CLM_EnvironmentSettingService.getSetting();
            System.assert(false, 'Expected EnvironmentSettingException not thrown');
        } catch (PMC_CLM_EnvironmentSettingService.EnvironmentSettingException e) {
            System.assert(e.getMessage().contains('qa2'), 'Exception message should name the incomplete environment');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetContractUrl() {
        PMC_CLM_EnvironmentSettingService.environmentNameOverride = 'unittest';
        PMC_CLM_EnvironmentSettingService.settingsOverride = new Map<String, PMC_CLM_Environment_Setting__mdt>{
            'unittest' => buildSetting('unittest', '98018', 'https://uatna11.springcm.com')
        };
        SBQQ__Quote__c objQuote = buildQuote();

        Test.startTest();
        String strUrl = PMC_CLM_EnvironmentSettingService.getContractUrl(objQuote);
        Test.stopTest();

        System.assert(strUrl.startsWith('https://uatna11.springcm.com/atlas/doclauncher/OneClickDocGen?'), 'URL should use the configured base URL. Actual: ' + strUrl);
        System.assert(strUrl.contains('aid=98018'), 'URL should use the configured account id. Actual: ' + strUrl);
        System.assert(strUrl.contains('config=Brazil Contrato Portuguese'), 'URL should include the contract language. Actual: ' + strUrl);
        System.assert(strUrl.contains('eos[0].Id=' + objQuote.Id), 'URL should include the quote id. Actual: ' + strUrl);
        System.assert(strUrl.contains('eos[0].Name=Q-00001'), 'URL should include the quote name. Actual: ' + strUrl);
    }

    @isTest
    static void testGetEnvironmentNameRealDetection() {
        Test.startTest();
        String strEnvironmentName = PMC_CLM_EnvironmentSettingService.getEnvironmentName();
        Test.stopTest();

        System.assert(String.isNotBlank(strEnvironmentName), 'Environment name should never be blank');
    }
}