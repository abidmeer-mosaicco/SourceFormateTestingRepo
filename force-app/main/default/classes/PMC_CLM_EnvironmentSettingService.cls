/**
 * @description Resolves environment-specific DocuSign CLM settings from PMC_CLM_Environment_Setting__mdt,
 *              keyed by the current sandbox name (or Production). There is intentionally NO fallback:
 *              an environment without a matching record throws EnvironmentSettingException so that a
 *              misconfigured sandbox fails fast instead of silently pointing to the Production CLM account.
 * @author Raphael Soares
 * @storynumber GCPM-5347
 * @changelog
 *   GCPM-5347 (2026-07-14): Class created
 */
public with sharing class PMC_CLM_EnvironmentSettingService {

    private static final String PRODUCTION_ENVIRONMENT_NAME = 'Production';

    @TestVisible
    private static String environmentNameOverride;

    @TestVisible
    private static Map<String, PMC_CLM_Environment_Setting__mdt> settingsOverride;

    /**
     * @description Thrown when no PMC_CLM_Environment_Setting__mdt record exists (or is incomplete)
     *              for the current environment.
     */
    public class EnvironmentSettingException extends Exception {
    }

    /**
     * @description Returns the CLM settings record for the current environment.
     * @return PMC_CLM_Environment_Setting__mdt record whose DeveloperName matches the current environment.
     */
    public static PMC_CLM_Environment_Setting__mdt getSetting() {
        String strEnvironmentName = getEnvironmentName();
        Map<String, PMC_CLM_Environment_Setting__mdt> mapSettingsByName = getSettingsByName();
        PMC_CLM_Environment_Setting__mdt objSetting = mapSettingsByName.get(strEnvironmentName.toLowerCase());
        if (objSetting == null || String.isBlank(objSetting.PMC_CLM_AccountId__c) || String.isBlank(objSetting.PMC_CLM_BaseUrl__c)) {
            throw new EnvironmentSettingException(
                String.format(System.Label.PMC_CLM_EnvironmentSettingMissing, new List<String>{ strEnvironmentName })
            );
        }
        return objSetting;
    }

    /**
     * @description Builds the DocuSign CLM OneClick document generation URL for the given quote,
     *              using the account id and base URL configured for the current environment.
     * @param objQuote Quote with Id, Name and PMC_CPQ_ContractLanguage__c populated.
     * @return DocuSign CLM doc launcher URL.
     */
    public static String getContractUrl(SBQQ__Quote__c objQuote) {
        PMC_CLM_Environment_Setting__mdt objSetting = getSetting();
        return String.format(
            '{0}/atlas/doclauncher/OneClickDocGen?' +
                'aid={1}&config=Brazil Contrato {2}&eos[0].Id={3}&eos[0].System=Salesforce' +
                '&eos[0].Type=SBQQ__Quote__c&eos[0].Name={4}&eos[0].ScmPath=/Salesforce/Quote/',
            new List<String>{
                objSetting.PMC_CLM_BaseUrl__c,
                objSetting.PMC_CLM_AccountId__c,
                objQuote.PMC_CPQ_ContractLanguage__c,
                objQuote.Id,
                EncodingUtil.urlEncode(objQuote.Name, 'UTF-8')
            }
        );
    }

    /**
     * @description Returns the current environment name: the sandbox name (lowercase) or Production.
     * @return Sandbox name in lowercase, or Production when the org is not a sandbox.
     */
    public static String getEnvironmentName() {
        if (environmentNameOverride != null) {
            return environmentNameOverride;
        }
        String strSandboxName = System.DomainParser.parse(Url.getOrgDomainUrl()).getSandboxName();
        return String.isBlank(strSandboxName) ? PRODUCTION_ENVIRONMENT_NAME : strSandboxName.toLowerCase();
    }

    /**
     * @description Loads all PMC_CLM_Environment_Setting__mdt records keyed by lowercase DeveloperName.
     * @return Map of environment name (lowercase) to its settings record.
     */
    private static Map<String, PMC_CLM_Environment_Setting__mdt> getSettingsByName() {
        Map<String, PMC_CLM_Environment_Setting__mdt> mapSource = settingsOverride != null
            ? settingsOverride
            : PMC_CLM_Environment_Setting__mdt.getAll();
        Map<String, PMC_CLM_Environment_Setting__mdt> mapSettingsByName = new Map<String, PMC_CLM_Environment_Setting__mdt>();
        for (String strDeveloperName : mapSource.keySet()) {
            mapSettingsByName.put(strDeveloperName.toLowerCase(), mapSource.get(strDeveloperName));
        }
        return mapSettingsByName;
    }
}