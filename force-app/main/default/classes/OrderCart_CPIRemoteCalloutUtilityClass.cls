/** @description Utility class para callouts específicos do fluxo OrderCart -> SAP
 */
public without sharing class OrderCart_CPIRemoteCalloutUtilityClass implements Database.AllowsCallouts {
    public static String strExceptionMsg;
    public static HttpRequest request = new HttpRequest();

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

    // Overload to include a weight value in the payload. Weight can be used by the receiving
    // integration to prioritize or sequence processing of Orders (1 = highest priority).
    public static String createMinimalPayload(List<Id> lstIds, Integer weight)
    {
        Map<String, Object> mapJSONbody = new Map<String, Object>();
        List<String> lstJSONBodyValue= new List<String>();
        String strSerializedBody;
        String  strID = 'Id';

        for(Id curId : lstIds){
             lstJSONBodyValue.add(String.valueOf(curId));
        }

        mapJSONbody.put(strID,lstJSONBodyValue);
        if (weight != null) {
            mapJSONbody.put('weight', weight);
        }
        strSerializedBody = JSON.serialize(mapJSONbody);
        return strSerializedBody;
    }

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

    @future (callout=true)
    public static void sendCalloutRequestFuture(String strCalloutEndpoint, String strSerializedBody, String strOrderId)
    {
        String strMethod = 'GET';
        String strIntegrationSettingsRecord = 'PMC_CPQ_IntegrationAutoRetrySettings';
        Integer intTimeoutValue = Integer.valueOf(PMC_CPQ_IntegrationSettings__mdt.getInstance(strIntegrationSettingsRecord).PMC_CPQ_SettingTwoValueNumber_c__c);
        request = new HttpRequest();
        HttpResponse response;
        Http http = new Http();
        String strContentType = 'Content-Type';
        String strContentTypeValue = 'application/json;charset=UTF-8';
        String reqBody = strSerializedBody.replace('\"[','[');
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
                // construir lista com Order baseado no Id único passado
                List<Order> lst = new List<Order>();
                try {
                    if (!String.isBlank(strOrderId)) {
                        Order o = new Order(Id = Id.valueOf(strOrderId));
                        lst.add(o);
                    }
                } catch (Exception ex) { }
                // reuse parse logic da nova classe
                if (!lst.isEmpty()) OrderCart_OrderIntegrationClass.parseJSONOrderInterface(lst,response,new List<Id>{ Id.valueOf(strOrderId) });
            }
        }
        catch(Exception objException)
        {
            PMC_ErrorLogClass.processException(objException);
            strExceptionMsg = objException.getMessage();
        }
    }
}