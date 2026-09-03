/**
 * @description This class, QuoteUpdateContractsService, is responsible for handling the communication 
 * with an external system (like SAP/CPI) to update contract information based on quote updates in Salesforce. 
 * 
 * It defines a method sendContracts that takes a JSON string as input, which contains the contract update information. 
 * 
 * The method constructs an HTTP request to the specified endpoint using named credentials, sends the request, 
 * and processes the response. The response is encapsulated in a CPIResponse object that indicates whether the 
 * call was successful and includes any relevant messages or data from the response.
 * 
 * @author Sergio Umlauf
 * @storynumber GCPM-2771
 */
public with sharing class QuoteUpdateContractsService {
    // Constants
    static final String CPI_INTERFACE = 'SalesContractMassUpdate';
    static final String CPI_NAMED_CREDENTIALS = 'callout:PMC_CPQ_NamedCredential';
    static final String CPI_METHOD = 'POST';
    static final String CPI_CONTENT_TYPE = 'application/json;charset=UTF-8';

    public static CPIResponse sendContracts(String jsonBody) {
        PMC_CPQ_Integration_Endpoint__mdt integrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(CPI_INTERFACE);
        String endpoint = integrationEndpointRecord.PMC_CPQ_Endpoint__c;
        String calloutEndpoint = CPI_NAMED_CREDENTIALS + endpoint;
        Integer intTimeoutValue = Integer.valueOf(
            PMC_CPQ_IntegrationSettings__mdt.getInstance('PMC_CPQ_IntegrationAutoRetrySettings').PMC_CPQ_SettingTwoValueNumber_c__c
        );

        Http http = new Http();
        HttpRequest req = new HttpRequest();

        try {
            req.setMethod(CPI_METHOD);
            req.setHeader('Content-Type', CPI_CONTENT_TYPE);
            req.setEndpoint(calloutEndpoint);
            req.setBody(jsonBody);
            req.setTimeout(intTimeoutValue);
            HttpResponse response = http.send(req);
            String responseBody = response.getBody();

            if (response.getStatusCode() != 200) {
                System.debug('CPI callout failed with status code ' + response.getStatusCode() + ' and body: ' + responseBody);
                return new CPIResponse(false, 'CPI callout failed with status code ' + response.getStatusCode());
            } else {
                System.debug('CPI callout succeeded with status code ' + response.getStatusCode() + ' and body: ' + responseBody);
            }
            return new CPIResponse(true, responseBody);
        } catch (Exception ex) {
            PMC_ErrorLogClass.processException(ex);
            System.debug('CPI callout error::: ' + ex.getMessage());
            return new CPIResponse(false, 'Error during CPI callout: ' + ex.getMessage());
        }
    }

    public class CPIResponse {
        public Boolean isSuccess;
        public String message;

        public CPIResponse() {
            // No-argument constructor
        }

        public CPIResponse(Boolean isSuccess, String message) {
            this.isSuccess = isSuccess;
            this.message = message;
        }
    }
}