/**
* @description       : Class to make callout for Documents(I196)
* @author            : Romulo Coimbra 
* @User Story		 : GMDP-21
* @last modified on  : 08-29-2025
* @last modified by  : Romulo Coimbra
**/
public with sharing class MosaicDirectDocumentApiService {

        static final String STRING_NAMEDCREDENTIALS = 'callout:PMC_CPQ_NamedCredential';
        static final String STRING_METHOD = 'POST';
        static List<PMC_CPQ_TransactionLog__c> lstTransactionLogs;
    
    
    
        /*************************************************************************
    * @method Name  : getDoc
    * @description  : Method to make callOut for Document
    * @param       	  objData
    * @return       : HttpResponse
    *****************************************************************************/
        public static HttpResponse getDoc(PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper objData){
            String strInterface = 'SAPDocuments';
            PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(strInterface);
            String strSAPDocEndpoint = strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c;
            String strCalloutEndpoint = STRING_NAMEDCREDENTIALS+strSAPDocEndpoint;
    
            HttpResponse response;
            Map<String, String> mapTransactionLogFields = new Map<String,String>();
            PMC_DH_DocumentWrapper data=new PMC_DH_DocumentWrapper();
    
            PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper objReqData=new PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper();
            try{
                objReqData.strDocumentCode=objData.strDocumentCode;
    
                // LOG DOS DADOS RECEBIDOS
                System.debug('=== REQUEST DATA ANALYSIS ===');
                System.debug('Input objData: ' + JSON.serialize(objData));
                System.debug('strDocumentCode: ' + objData.strDocumentCode);
                System.debug('strBillingDocNumber: ' + objData.strBillingDocNumber);
                System.debug('strDeliveryNumber: ' + objData.strDeliveryNumber);
                System.debug('strItemNumber: ' + objData.strItemNumber);
    
                if(String.isNotEmpty(objData.strDeliveryNumber) || String.isNotEmpty(objData.strItemNumber) ||String.isNotEmpty(objData.strBillingDocNumber)){
                    switch on (objData.strDocumentCode) {
                        when  'COA'  {
                            objReqData.strBillingDocNumber=objData.strBillingDocNumber;
                            objReqData.strItemNumber=objData.strItemNumber;
    
                        }
                        when  'ZBQI'  {
                            objReqData.strDeliveryNumber=objData.strDeliveryNumber;
    
                            objReqData.strItemNumber=objData.strItemNumber;
    
                        }
                        when 'BOL' {
                            objReqData.strBillingDocNumber=objData.strBillingDocNumber;
                        }
                        when 'INV','CDM','DBM','NFE'{
                            objReqData.strBillingDocNumber=objData.strBillingDocNumber;
                            System.debug('=== NFE/INV DOCUMENT PROCESSING ===');
                            System.debug('Document Code: ' + objData.strDocumentCode);
                            System.debug('Billing Doc Number: ' + objData.strBillingDocNumber);
                        }
                    }
                    data.objData=objReqData;
                }
    
                // LOG DO CORPO DA REQUISIÇÃO ANTES DE ENVIAR
                String requestBody = Json.serialize(data,TRUE);
                System.debug('=== REQUEST BODY TO SAP ===');
                System.debug('Endpoint: ' + strCalloutEndpoint);
                System.debug('Method: ' + STRING_METHOD);
                System.debug('Request Body: ' + requestBody);
                System.debug('Request Body Pretty: ' + JSON.serializePretty(data));
    
                if(data!=null)
                {
                    //api callout
                    response = PMC_CPQ_CPIRemoteCalloutUtilityClass.sendCalloutRequest(STRING_METHOD, strCalloutEndpoint, requestBody);
    
                    // LOG DA RESPOSTA
                    System.debug('=== SAP RESPONSE ===');
                    System.debug('HTTP Status Code: ' + response.getStatusCode());
                    System.debug('Response Headers: ' + response.getHeaderKeys());
    
                    //Insert transaction logs
                    String  responseBody = (String)response.getBody();
                    System.debug('Response Body: ' + responseBody);
    
                    PMC_DH_DocumentResponseWrapper resWrapper=(PMC_DH_DocumentResponseWrapper)JSON.deserialize(responseBody,PMC_DH_DocumentResponseWrapper.class);
    
                    Map<String,String> mapStatus=new  Map<String,String>();
                    mapStatus.put('S','Success');
                    mapStatus.put('E','Error');
    
                    mapTransactionLogFields.put('PMC_CPQ_InterfaceURL__c',strSAPDocEndpoint);
                    mapTransactionLogFields.put('PMC_CPQ_RequestBody__c',requestBody); // Agora usa a variável local
    
                    if(response.getStatusCode()==200){
                        mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',mapStatus.get(resWrapper.objData.strStatusCode));
                        mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c',resWrapper.objData.strMessage);
                    }
                    else{
                        mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',mapStatus.get('E'));
                        mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c',String.valueOf(response.getBody()));
                    }
                    lstTransactionLogs = PMC_CPQ_TransactionLogUtilityClass.addTransactionLog(mapTransactionLogFields);
                    PMC_CPQ_TransactionLogUtilityClass.insertTransactionLogs(lstTransactionLogs);
                }
    
            }
            catch(System.CalloutException objException)
            {
                System.debug('=== CALLOUT EXCEPTION ===');
                System.debug('Exception Message: ' + objException.getMessage());
                System.debug('Exception Type: ' + objException.getTypeName());
                PMC_ErrorLogClass.processException(objException);
            }
            return response;
    
            }

    /**
     * @description Convenience method for Invoice document download
     * @param strBillingDocNumber The billing document number
     * @return HttpResponse from SAP
     */
    public static HttpResponse getInvoiceDoc(String strBillingDocNumber) {
        PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper requestData = new PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper();
        requestData.strDocumentCode = 'INV';
        requestData.strBillingDocNumber = strBillingDocNumber;
        return getDoc(requestData);
    }

    /**
     * @description Convenience method for COA document download  
     * @param strBillingDocNumber The billing document number (delivery number)
     * @param strItemNumber The item number
     * @return HttpResponse from SAP
     */
    public static HttpResponse getCOADoc(String strBillingDocNumber, String strItemNumber) {
        PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper requestData = new PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper();
        requestData.strDocumentCode = 'COA';
        requestData.strBillingDocNumber = strBillingDocNumber;
        requestData.strItemNumber = strItemNumber;
        return getDoc(requestData);
    }

    /**
     * @description Convenience method for BOL document download
     * @param strBillingDocNumber The billing document number (delivery number)
     * @return HttpResponse from SAP
     */
    public static HttpResponse getBOLDoc(String strBillingDocNumber) {
        PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper requestData = new PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper();
        requestData.strDocumentCode = 'BOL';
        requestData.strBillingDocNumber = strBillingDocNumber;
        return getDoc(requestData);
    }


    }