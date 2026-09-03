public with sharing class DocusignWorkflowService {

    // Constants
    private static final String ENDPOINT = 'callout:DocuSignWorkflow/v2/' + Label.PMC_CLM_DocuSign_Account_ID_UUID + '/workflows';

    private static final String WORKFLOW_NAME = 'PMC CLM Mass Amendment Staging';
    private static final String OBJECT_TYPE = 'SBQQ__Quote__c';
    private static final String SCM_PATH = '/Salesforce/Quote/';

    /**
     * Build the XML body for the given Quote Id and User Id, then perform the callout.
     * @param quoteId Id of SBQQ__Quote__c to include in the payload
     * @param userId Id of the executing User to include in the payload
     */
    public static void triggerWorkflow(Id quoteId, Id userId) {
        SBQQ__Quote__c quote;
        try {
            quote = [SELECT Id, Name, SBQQ__Type__c, PMC_CPQ_QuoteRecordSubType__c, PMC_CPQ_Region__c, PMC_CPQ_ContractLanguage__c, PMC_CPQ_PrimaryContact__c, PMC_CPQ_PrimaryContact__r.Email, PMC_CPQ_PrimaryContact__r.Name FROM SBQQ__Quote__c WHERE Id = :quoteId LIMIT 1];
        } catch (Exception ex) {
            System.debug('Failed to query Quote for id ' + quoteId + ': ' + ex.getMessage());
            return;
        }

        List<MassUpdateExecutionLine__c> lines = [SELECT Id, Contract__r.PMC_CPQ_LatestQuote__c FROM MassUpdateExecutionLine__c WHERE CreatedQuote__c = :quoteId ORDER BY CreatedDate ASC LIMIT 1];
        

        User sfUser = [SELECT Id, Name, Email, Alias FROM User WHERE Id = :userId LIMIT 1];
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        String requestBody = '{"Name": "' + WORKFLOW_NAME + '", "Params": ' + JSON.serialize(buildXmlBody(quote, sfUser, lines.isEmpty() ? null : lines[0])) + '}';

        System.debug('Request Body: ' + requestBody);
        req.setBody(requestBody);

        Http http = new Http();
        HTTPResponse res = http.send(req);

        System.debug('Status: ' + res.getStatus());
        System.debug('Code: ' + res.getStatusCode());
        System.debug('Response: ' + res.getBody());
    }

    /**
     * Builds the XML body for the DocuSign workflow trigger using XmlUtils.
     * @param quote The SBQQ__Quote__c record
     * @param sfUser The User record for SFUser block
     * @return The generated XML string
     */
    private static String buildXmlBody(SBQQ__Quote__c quote, User sfUser, MassUpdateExecutionLine__c line) {
        return XmlUtils.mapToXml(new Map<String,Object> {
            'Params' => new Map<String,Object> {
                'TemplateFieldData' => new Map<String, Object>{
                    'Id' => String.valueOf(quote.Id),
                    'System' => 'Salesforce',
                    'Type' => OBJECT_TYPE,
                    'Quote_Type'=> quote.SBQQ__Type__c,
                    'BusinessType' => quote.PMC_CPQ_QuoteRecordSubType__c,
                    'Region' => quote.PMC_CPQ_Region__c,
                    'Language' => quote.PMC_CPQ_ContractLanguage__c,
                    'Name' => quote.Name,
                    'ScmPath' => SCM_PATH,
                    'PrimaryContact' => new Map<String, Object>{
                        'Id' => quote.PMC_CPQ_PrimaryContact__c,
                        'Name' => quote.PMC_CPQ_PrimaryContact__r.Name,
                        'Email' => quote.PMC_CPQ_PrimaryContact__r.Email
                    },
                    'SFUser' => new Map<String, Object>{
                        'Id' => String.valueOf(sfUser.Id),
                        'Name' => sfUser.Name,
                        'Email' => sfUser.Email,
                        'Alias' => sfUser.Alias
                    },
                    'PreviousQuote' => new Map<String,Object> {
                        'Id' => line != null && line.Contract__r != null ? String.valueOf(line.Contract__r.PMC_CPQ_LatestQuote__c) : ''
                    }
                }
            }
        });
    }
}