/** @description This is a utility class for external callouts.
 *  @author Shefali Dsouza
 *  @storynumber GDASF-2983
 *  @storynumber GDASF-9240
 */
public without sharing class PMC_CPQ_CPIRemoteCalloutUtilityClass  implements Database.AllowsCallouts {
    
    public static String strExceptionMsg; 
    public static HttpRequest request = new HttpRequest();
    /** 
     * @description This method will make a callout to CPI.
     * @param strMethod - Method for external callout. eg. GET, POST, PATCH
     * @param strCalloutEndpoint - Concatenation of named credential and specific endpoint
     * @param strSerializedBody - List of quotes.
     * @return response - Http Response.
     * @return null - If no response is returned.
     */
    public static HttpResponse sendCalloutRequest(String strMethod, String strCalloutEndpoint, String strSerializedBody)
    {
        String strIntegrationSettingsRecord = 'PMC_CPQ_IntegrationAutoRetrySettings';
        Integer intTimeoutValue = Integer.valueOf(PMC_CPQ_IntegrationSettings__mdt.getInstance(strIntegrationSettingsRecord).PMC_CPQ_SettingTwoValueNumber_c__c);
        request = new HttpRequest();
        HttpResponse response;
        Http http = new Http();
        String strContentType = 'Content-Type';
        String strContentTypeValue = 'application/json;charset=UTF-8';
        try
        {          
            request.setMethod(strMethod);
            request.setHeader(strContentType,strContentTypeValue);
            request.setEndpoint(strCalloutEndpoint);
            request.setBody(strSerializedBody);
            request.setTimeout(intTimeoutValue);
            response = http.send(request); 
            return response;
        }
        catch(Exception objException)
        {
            PMC_ErrorLogClass.processException(objException);
            strExceptionMsg = objException.getMessage();
            return null;
        }
    }
    
     /** 
     * @description This method will create a minimal payload.
     * @param lstIds - List of ids.
     * @return strSerializedBody - Serialized Http Request Body.
     */
    public static String createMinimalPayload(List<Id> lstIds)
    {   
        Map<String, List<String>> mapJSONbody = new Map<String, List<String>>();
        List<String> lstJSONBodyValue= new List<String>();
        String strSerializedBody;
        String  strID = 'Id';
        
        for(Id curId : lstIds){ 
             lstJSONBodyValue.add(curId);
        }
          
        mapJSONbody.put(strID,lstJSONBodyValue);
        strSerializedBody = JSON.serialize(mapJSONbody);
        return strSerializedBody;
    } 
    
     /** 
     * @description This method will determine if auto retrigger is needed for queueable apex.
     * @param intStackDepth - Stack depth of queueable apex.
     * @param strErrorMsg - Error Message
     * @return true - If Auto-Retrigger is needed.
     * @return false - If Auto-Retrigger is not needed.
     */
    public static Boolean autoRetryQueueableApex(Integer intStackDepth, String strErrorMsg)
    {
        String strIntegrationAutoRetrySettingsLabel = 'PMC_CPQ_IntegrationAutoRetrySettings';
        PMC_CPQ_IntegrationSettings__mdt strIntegrationAutoRetrySettings = PMC_CPQ_IntegrationSettings__mdt.getInstance(strIntegrationAutoRetrySettingsLabel);
        String strIntegrationMsgCSV = strIntegrationAutoRetrySettings.PMC_CPQ_SettingValueLongTextArea__c;
        
        Integer intIntegrationRetryCount = Integer.valueOf(strIntegrationAutoRetrySettings.PMC_CPQ_SettingValueNumber__c);
        List<String> lstStringErrorMessages = strIntegrationMsgCSV.split('&');
        
        if(intStackDepth <= intIntegrationRetryCount && lstStringErrorMessages.contains(strErrorMsg))
        {
            return true;  
        }
        
        return false;
    }

    /** 
     * @description This method will make a callout to CPI GDASF-9240.
     * @param strCalloutEndpoint - Concatenation of named credential and specific endpoint
     * @param strSerializedBody - List of quotes.
     * @param strQuoteId - quote id
     */
    @future (callout=true)
    public static void sendCalloutRequestFuture(String strCalloutEndpoint, String strSerializedBody, String strQuoteId)
    {
        String strMethod = 'GET';
        String strIntegrationSettingsRecord = 'PMC_CPQ_IntegrationAutoRetrySettings';
        Integer intTimeoutValue = Integer.valueOf(PMC_CPQ_IntegrationSettings__mdt.getInstance(strIntegrationSettingsRecord).PMC_CPQ_SettingTwoValueNumber_c__c);
        request = new HttpRequest();
        HttpResponse response;
        Http http = new Http();
        String strContentType = 'Content-Type';
        String strContentTypeValue = 'application/json;charset=UTF-8';
        String reqBody = strSerializedBody.replace('"[','[');
        String finalReqBody = reqBody.replace(']"',']');
        try
        {          
            request.setMethod(strMethod);
            request.setHeader(strContentType,strContentTypeValue);
            request.setEndpoint(strCalloutEndpoint);
            request.setBody(finalReqBody);
            request.setTimeout(intTimeoutValue);
            response = http.send(request); 
            if(response!=null){
                PMC_CPQ_CadenceResponseParsing.parseJSONCadenceInterface(strQuoteId,response,strCalloutEndpoint);
            }
        }
        catch(Exception objException)
        {
            PMC_ErrorLogClass.processException(objException);
            strExceptionMsg = objException.getMessage();
        }
    }
}