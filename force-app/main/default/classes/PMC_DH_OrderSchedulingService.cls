/**
 * @description       : Service Class for SAP Scheduling Services 
 * @author            : Dev | Digital Hub
 * @group             : Mosaic Direct 
 * @last modified on  : 03-01-2024
 * @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
public without sharing class PMC_DH_OrderSchedulingService {
    static final String STRING_NAMEDCREDENTIALS = 'callout:PMC_CPQ_NamedCredential';
    static final String STRING_METHOD = 'POST';
    static List<PMC_CPQ_TransactionLog__c> lstTransactionLogs;

  
    /**
    * @description 
    * @author siddharth.pradhan@mosaicco.com | Digital Hub | 10-07-2023 
    * @param strCartId 
    * @return HttpResponse 
    **/
    public static HttpResponse submitOrUpdateSchedulingRequest(String strCartId) {
        String strInterface = 'SAPSchedulingRequest';
        PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(strInterface); 
        String strSchedulingEndpoint = strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c;
        
        String strCalloutEndpoint = STRING_NAMEDCREDENTIALS+strSchedulingEndpoint;
        
        String strSerializedBody = PMC_DH_CreateOrderRequestAPIUtility.createOrderRequestForAPI(strCartId);
        HttpResponse response = PMC_CPQ_CPIRemoteCalloutUtilityClass.sendCalloutRequest(STRING_METHOD, strCalloutEndpoint, strSerializedBody);
        Map<String, String> mapTransactionLogFields = new Map<String,String>();
        mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',String.valueOf(response.getStatusCode()));
        mapTransactionLogFields.put('PMC_CPQ_InterfaceURL__c',strSchedulingEndpoint);
        mapTransactionLogFields.put('PMC_CPQ_RequestBody__c',PMC_CPQ_CPIRemoteCalloutUtilityClass.request.getBody());
        mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c',String.valueOf(response.getBody()));
        lstTransactionLogs = PMC_CPQ_TransactionLogUtilityClass.addTransactionLog(mapTransactionLogFields);
        PMC_CPQ_TransactionLogUtilityClass.insertTransactionLogs(lstTransactionLogs);
        return response;
    }
   
   /**
    * @description 
    * @author  Mosaic Direct Dev 
    * @param strEffectiveAccountId 
    * @return HttpResponse 
    **/ 
    public static HttpResponse fetchOrderHistoryFromSAP(String strEffectiveAccountId) {
        String strInterface = 'SAPSchedulingStatus';
        PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(strInterface); 
        String strSchedulingStatusEndpoint = strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c;
        String strCalloutEndpoint = STRING_NAMEDCREDENTIALS+strSchedulingStatusEndpoint;
        
        String strSerializedBody = PMC_DH_CreateOrderRequestAPIUtility.createRequestForOrderRequestStatus(strEffectiveAccountId);
        HttpResponse response = PMC_CPQ_CPIRemoteCalloutUtilityClass.sendCalloutRequest(STRING_METHOD, strCalloutEndpoint, strSerializedBody);
        Map<String, String> mapTransactionLogFields = new Map<String,String>();
        mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',String.valueOf(response.getStatusCode()));
        mapTransactionLogFields.put('PMC_CPQ_InterfaceURL__c',strSchedulingStatusEndpoint);
        mapTransactionLogFields.put('PMC_CPQ_RequestBody__c',PMC_CPQ_CPIRemoteCalloutUtilityClass.request.getBody());
        mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c',String.valueOf(response.getBody()));
        lstTransactionLogs = PMC_CPQ_TransactionLogUtilityClass.addTransactionLog(mapTransactionLogFields);
        PMC_CPQ_TransactionLogUtilityClass.insertTransactionLogs(lstTransactionLogs);
        return response;
        
    }
	
    	/**
    * @description 
    * @author Mosaic Direct Dev 
    * @param editWrapper 
    * @return HttpResponse 
    **/
    public static HttpResponse updateSchedulingRequest(PMC_DH_RequestedOrderEditController.editRequestWrapper editWrapper) {
        String strInterface = 'SAPSchedulingRequest';
        PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(strInterface); 
        String strSchedulingEndpoint = strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c;
        
        String strCalloutEndpoint = STRING_NAMEDCREDENTIALS+strSchedulingEndpoint;
        
        String strSerializedBody = PMC_DH_CreateOrderRequestAPIUtility.createOrderRequestForEdit(editWrapper);
        HttpResponse response = PMC_CPQ_CPIRemoteCalloutUtilityClass.sendCalloutRequest(STRING_METHOD, strCalloutEndpoint, strSerializedBody);
        Map<String, String> mapTransactionLogFields = new Map<String,String>();
        mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',String.valueOf(response.getStatusCode()));
        mapTransactionLogFields.put('PMC_CPQ_InterfaceURL__c',strSchedulingEndpoint);
        mapTransactionLogFields.put('PMC_CPQ_RequestBody__c',PMC_CPQ_CPIRemoteCalloutUtilityClass.request.getBody());
        mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c',String.valueOf(response.getBody()));
        lstTransactionLogs = PMC_CPQ_TransactionLogUtilityClass.addTransactionLog(mapTransactionLogFields);
        PMC_CPQ_TransactionLogUtilityClass.insertTransactionLogs(lstTransactionLogs);
        return response;
    }
}