/**
 * @description This class is called from batch class to make service callout
* Created By : Megha Sunhare
*/
public without sharing class PMC_SS_SalesAgreementCalloutActionClass {
    
    // Http integartion objects
    private static Http http;
    private static HttpRequest request;
    private static HttpResponse response;
    
    //static final variables to hold the constants
    private static final String STRING_INTEGRATION_STATUS_ERROR = 'Error'; 
    private static final String STRING_INTEGRATION_STATUS_SUCCESS = 'Success';
    private static final String STRING_INTERFACE_NAME = 'SAPCreateUpdateRebateContracts';
    private static final Integer INT_STATUSCODE200 = 200;
    private static final Integer INT_STATUSCODE201 = 201;
    
    /** 
* @description This is the apex action that will be invoked from the batch.
* @param lstSalesAgreements - list of sales agreement sent from the batch.
*/
    
    public static void invokeCPICallout(List<SalesAgreement> lstSalesAgreements) {
        
        PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(STRING_INTERFACE_NAME); 
        String strEndpoint = strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c;
        makeCPICallout(lstSalesAgreements,strEndpoint);
    }
    
    /** 
* @description This is the apex method that will be invoked from the invokeCPICallout method.
* @param lstSalesAgreements - list of sales agreement sent from the method.
* @param strEndpoint - endpoint of the service
*/
    private static void makeCPICallout(List<SalesAgreement> lstSalesAgreements, String strEndpoint){
        http = new Http();
        Map<String,List<Map<String,String>>> mapJSONbody = new Map<String,List<Map<String,String>>>();
        List<Map<String,String>> lstJsonBodyValues = new List<Map<String,String>>();
        Map<String,String> mapSAIdAndAccid;
        String strIdAPIName = 'SAid';
        String strAccIdAPIName = 'AccId';
        try{    
            request = new HttpRequest();
            response = new HttpResponse();
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            request.setEndpoint('callout:PMC_CPQ_NamedCredential'+strEndpoint);
            request.setTimeout(120000);
            for(SalesAgreement objSalesAgreement : lstSalesAgreements){	
                mapSAIdAndAccid = new Map<String,String>();
                mapSAIdAndAccid.put(strIdAPIName,objSalesAgreement.Id);
                mapSAIdAndAccid.put(strAccIdAPIName,objSalesAgreement.AccountId);
                lstJsonBodyValues.add(mapSAIdAndAccid);
            } 
            mapJSONbody.put('Ids',lstJsonBodyValues);
            String strJSONRequest = JSON.serialize(mapJSONbody);
            request.setBody(strJSONRequest);
            response = http.send(request); 
            if(response.getStatusCode() == INT_STATUSCODE200 ){
                createTransactionLogRecord(lstSalesAgreements.get(0), STRING_INTEGRATION_STATUS_SUCCESS);
            }else{
                createTransactionLogRecord(lstSalesAgreements.get(0), STRING_INTEGRATION_STATUS_ERROR);
            }
            
        }catch(Exception objException){
            PMC_ErrorLogClass.processException(objException);
            createTransactionLogRecord(lstSalesAgreements.get(0), STRING_INTEGRATION_STATUS_ERROR);
        }
        
    }
    
    /** 
* @description This is to create PMC_CPQ_TransactionLog__c record.
* @param objSalesAgreement - sales agreement object.
* @param strStatus - status of service response
*/
    private static void createTransactionLogRecord(SalesAgreement objSalesAgreement, String strStatus){
        PMC_CPQ_TransactionLog__c objTransactionLog = new PMC_CPQ_TransactionLog__c();
        objTransactionLog.PMC_CPQ_IntegrationStatus__c = strStatus;
        objTransactionLog.PMC_CPQ_RequestBody__c = request.getBody();
        objTransactionLog.PMC_CPQ_ResponseBody__c = response.getBody();
        objTransactionLog.PMC_CPQ_InterfaceURL__c = STRING_INTERFACE_NAME;
        try{
            if(Schema.sObjectType.PMC_CPQ_TransactionLog__c.isCreateable()){
                Database.insert(objTransactionLog, true);
            }
            
        }catch(Exception objException){
            PMC_ErrorLogClass.processException(objException);
        }
    }
}