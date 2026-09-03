/**
* @description       : Class to make callout for Documents(I196)
* @author            : Humera Rahath 
* @User Story		  : GDASF-463
* @last modified on  : 10-27-2023
* @last modified by  : Humera Rahath
**/
public with sharing class PMC_DH_DocumentFetchService {
    
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
            if(String.isNotEmpty(objData.strDeliveryNumber) || String.isNotEmpty(objData.strItemNumber) ||String.isNotEmpty(objData.strBillingDocNumber)){
                switch on (objData.strDocumentCode) {
                 
                    when  'ZBQI'  {
                        objReqData.strDeliveryNumber=objData.strDeliveryNumber;
                        
                        objReqData.strItemNumber=objData.strItemNumber;
                        objReqData.strDocLanguage=objData.strDocLanguage;
                       
                    }
                       when  'COA'  {
                        objReqData.strDeliveryNumber=objData.strDeliveryNumber;
                        List<String> lstItemNum = new List<String>();
                        lstItemNum=objData.strItemNumber.split('_');
                        objReqData.strItemNumber=lstItemNum[1];
                      

                       
                    }
                    
                    when 'BOL' {
                        objReqData.strDeliveryNumber=objData.strDeliveryNumber;
                        

                    }


                    when 'INV','CDM','DBM','NFE'{
                        objReqData.strBillingDocNumber=objData.strBillingDocNumber;
                        

                    }
                }
                data.objData=objReqData;
            }
            if(data!=null)
            {
                //api callout 
                response = PMC_CPQ_CPIRemoteCalloutUtilityClass.sendCalloutRequest(STRING_METHOD, strCalloutEndpoint, Json.serialize(data,TRUE));
                //Insert transaction logs
                String  responseBody = (String)response.getBody();
                PMC_DH_DocumentResponseWrapper resWrapper=(PMC_DH_DocumentResponseWrapper)JSON.deserialize(responseBody,PMC_DH_DocumentResponseWrapper.class);
                
                Map<String,String> mapStatus=new  Map<String,String>();
                mapStatus.put('S','Success');
                mapStatus.put('E','Error');
                
                mapTransactionLogFields.put('PMC_CPQ_InterfaceURL__c',strSAPDocEndpoint);
                mapTransactionLogFields.put('PMC_CPQ_RequestBody__c',PMC_CPQ_CPIRemoteCalloutUtilityClass.request.getBody());
                
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
            PMC_ErrorLogClass.processException(objException);
        }
        return response;
        
    }
    
    
}