/** @description This is a utility class for callout response parsing
 *  @author Prakhar Srivastava
 *  @storynumber GDASF-9240, 9443
 */
public with sharing class PMC_CPQ_CadenceResponseParsing {

    static final String STRING_INTEGRATIONSTATUSERROR = 'Error'; 
    static final String STRING_INTEGRATIONSTATUSSUCCESS = 'Success';
    static final Integer INT_STATUSCODE200 = 200;
    static final Integer INT_STATUSCODE201 = 201;
    static Exception objException;
    static final List<Integer> LISTINT_SUCCESSCODES = new List<Integer>{INT_STATUSCODE200,INT_STATUSCODE201};
    static HttpRequest request = new HttpRequest();
    static HttpResponse response;
    static List<PMC_CPQ_IntegrationFieldMap__mdt> lstPriceCondMap = new List<PMC_CPQ_IntegrationFieldMap__mdt>();
    static List<PMC_CPQ_IntegrationFieldMap__mdt> lstMaterial = new List<PMC_CPQ_IntegrationFieldMap__mdt>(); // GDASF-9443 this will hold integration field metadata record for MaterialSet
    static List<PMC_CPQ_IntegrationFieldMap__mdt> lstSchedule = new List<PMC_CPQ_IntegrationFieldMap__mdt>(); // GDASF-9240 this will hold integration field metadata record for ScheduleSet
    static Map<String, String> mapSchedule = new Map<String, String>();//map of Key and Apex API name
    static Map<String, String> mapMaterialAvailable =  new Map<String, String>();//map of Key and Apex API name for material set
    static Map<String, PMC_CPQ_CadenceItem__c> mapCadenceItem = new Map<String,PMC_CPQ_CadenceItem__c>(); // GDASF-9443 map of key(Linenumber+ConfirmaDt) and Cadence item record
    static Map<String, Id> mapCadencetoMonth = new Map<String, Id>(); // GDASF-9443 for assgning cadence item to respective cadence this map will be used
    static Map<String, PMC_CPQ_Cadence__c> mapCadencetoLineNum = new Map<String, PMC_CPQ_Cadence__c>(); // 9443 map of QL line num and cadence record

    /** 
     * @description prepare the list and map of Integration Field metadata records.
     * @param lstMapping - list of integration field map
     */
    public static void prepareIntegrationFieldData(List<PMC_CPQ_IntegrationFieldMap__mdt> lstMapping){
        Map<String,List<PMC_CPQ_IntegrationFieldMap__mdt>> mapObjectToResponseRecord = new Map<String, List<PMC_CPQ_IntegrationFieldMap__mdt>>();        
        Map<String,Map<String,String>> mapOfTargetFields = new Map<String,Map<String,String>>(); // map which will hold target fields for ScheduleSet and Material Available

        mapObjectToResponseRecord = PMC_CPQ_ProductAvailableUtility.filterResponseMap(lstMapping);
        lstSchedule = mapObjectToResponseRecord.get('Schedule');
        lstMaterial = mapObjectToResponseRecord.get('MaterialSet');
        mapOfTargetFields = PMC_CPQ_ProductAvailableUtility.createMapOfTargetField(lstMapping);
        mapSchedule = mapOfTargetFields.get('Schedule');
        mapMaterialAvailable = mapOfTargetFields.get('MaterialSet');
    }    
    /** 
     * @description Parses through the response body and populates Integration fields on the cadence GDASF-9240.
     * @param strQuoteId - quote id
     * @param response - response received from the endpoint.
     * @param strEndpoint - Endpoint that the HttpRequest will hit.
     */
    public static void parseJSONCadenceInterface(String strQuoteId, HttpResponse response, String strEndpoint)
    {    
        String strJSONResponseBody = response.getBody();
        Map<String, Schema.SObjectField> fieldMap = SBQQ__Quote__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
        // Get all of the fields on the object
        Set<String> setFieldNames = fieldMap.keySet();
        list<String> lstFieldNames = new List<String>(setFieldNames);
                
        // Dynamic Query String.
        List<SBQQ__Quote__c> lstQuotes = Database.query('SELECT ' + String.escapeSingleQuotes(String.join(lstFieldNames, ',')) + ', RecordType.DeveloperName FROM SBQQ__Quote__c where Id  = \''+ String.escapeSingleQuotes(strQuoteId) + '\'');// WITH SECURITY_ENFORCED');
		SBQQ__Quote__c objQuote = lstQuotes[0];
        List<SBQQ__QuoteLine__c> lstQuoteLines = [Select id, SBQQ__Number__c,SBQQ__Quote__c, SBQQ__Quantity__c, PMC_CPQ_Last_Quantity__c from SBQQ__QuoteLine__c where SBQQ__Quote__c = :(lstQuotes[0].Id) WITH SECURITY_ENFORCED];
                List<PMC_CPQ_Cadence__c> lstCadence = [select id, PMC_CPQ_ConfirmedDate__c, PMC_CPQ_ConfirmedQuantity__c, PMC_CPQ_QuoteLine__c, PMC_CPQ_RequestedDate__c, PMC_CPQ_QuoteLine__r.SBQQ__Number__c  
                                                        from PMC_CPQ_Cadence__c where PMC_CPQ_QuoteLine__r.SBQQ__Quote__c =: objQuote.Id WITH SECURITY_ENFORCED order by PMC_CPQ_RequestedDate__c ASC];
        // GDASF-9443 query cadence item and put in map to refer while upserting data
        List<PMC_CPQ_CadenceItem__c> lstCadItem = [select id,PMC_CPQ_ConfirmedQuantity__c, PMC_CPQ_ConfirmedDate__c, PMC_CPQ_Cadence__r.PMC_CPQ_QuoteLine__r.SBQQ__Number__c, PMC_CPQ_Cadence__r.PMC_CPQ_QuoteLine__r.SBQQ__Quote__c 
                                                    from PMC_CPQ_CadenceItem__c  where PMC_CPQ_Cadence__r.PMC_CPQ_QuoteLine__r.SBQQ__Quote__c =: objQuote.Id WITH SECURITY_ENFORCED];
        // GDASF-9443 query Integration Mapping metadata for ScheduleSet and Material Availability
        List<PMC_CPQ_IntegrationFieldMap__mdt> lstMapping = [select MasterLabel,PMC_CPQ_ApexAPIName__c,PMC_CPQ_DataType__c,PMC_CPQ_SFObject__c,  PMC_CPQ_AttributeKey__c from PMC_CPQ_IntegrationFieldMap__mdt 
                                                                where (PMC_CPQ_SFObject__c in ('Schedule','MaterialSet') AND PMC_CPQ_IsLookup__c = false AND PMC_CPQ_AttributeKey__c != null AND PMC_CPQ_ApexAPIName__c != null) WITH SECURITY_ENFORCED order by MasterLabel ASC];
                                                
        Map<String, String> mapTransactionLogFields = new Map<String,String>();
        mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',STRING_INTEGRATIONSTATUSERROR);
        mapTransactionLogFields.put('PMC_CPQ_InterfaceURL__c',strEndpoint);
        mapTransactionLogFields.put('PMC_CPQ_RequestBody__c',PMC_CPQ_CPIRemoteCalloutUtilityClass.request.getBody());
        mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c',strJSONResponseBody);

        if(LISTINT_SUCCESSCODES.contains(response.getStatusCode()))//status code returned is 200
        {   
            try
            {
                
                Map<String, PMC_CPQ_Cadence__c> mapIndividualQLICadence = new Map<String, PMC_CPQ_Cadence__c>(); // map of concat of item number_Requestdate and cadence record
                for(SBQQ__QuoteLine__c qtline: lstQuoteLines){
                    qtLine.put('PMC_CPQ_Last_Quantity__c',qtLine.SBQQ__Quantity__c);
                }
               // GDASF-9443 prepare map of cadence with QL line num which will be used to parse cadence and cadence item and its association. 
               if(!lstCadence.isEmpty()){
                mapIndividualQLICadence = prepareMapLineNumberCadence(lstCadence);
                mapCadenceItem = prepareMapCadenceItemtoLineNum(lstCadItem);
                }
                
                Map<String,Object> jsonResponse = (Map<String, Object>)((Map<String, Object>)((Map<String, Object>)JSON.deserializeUntyped(response.getBody())).get('HeaderSet')).get('Header');
                List<Object> lstItemR = (List<Object>)((Map<String,Object>)jsonResponse.get('Item_RSet')).get('Item_R');
                List<Object> lstMaterialAvailable = (List<Object>)((Map<String,Object>)jsonResponse.get('Material_AvailabilitySet')).get('Material_Availability'); // GDASF-9443
                prepareIntegrationFieldData(lstMapping);
                for(Object o: lstItemR){
                    Map<String,Object> mapItemRParse = (Map<String,Object>)o;
                    List<Object> lstScheduleResponse = (List<Object>)((Map<String,Object>)mapItemRParse.get('ScheduleSet')).get('Schedule');
                    parseScheduleCadence(lstScheduleResponse, mapIndividualQLICadence); // GDASF-9443 added lstMaterialAvailable
                }
                // GDASF-9443 parse material availability response and store it as cadence tiem
                parseMaterialAvailable(lstMaterialAvailable);
                
                    objQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSSUCCESS;
                    objQuote.PMC_CPQ_IntegrationMessage__c = STRING_INTEGRATIONSTATUSSUCCESS;
                    objQuote.put('PMC_CPQ_LastContractStart__c', objQuote.PMC_CPQ_ContractStart__c); 
                    objQuote.put('PMC_CPQ_LastContractEnd__c', objQuote.PMC_CPQ_ContractEnd__c);

                mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',STRING_INTEGRATIONSTATUSSUCCESS);
            }
            catch(Exception e)//Exception caused due to inablitiy to parse through response.
            {
                    objQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
                    objQuote.PMC_CPQ_IntegrationMessage__c = e.getMessage();
                
            }
        }
        else if(response.getStatusCode() != 500) //status code returned is not 200
        {
                objQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
                
                //Check for null response under Error Details json node.
                String checkForNullResponseFromSAP;
                checkForNullResponseFromSAP = ('' + ((Map<String, Object>)((Map<String, Object>)((Map<String, Object>)JSON.deserializeUntyped(response.getBody())).get('error')).get('innererror')).get('errordetails'));
                objQuote.PMC_CPQ_IntegrationMessage__c = ((checkForNullResponseFromSAP != '')?(String)((Map<String, Object>)((List<Object>)((Map<String, Object>)((Map<String, Object>)((Map<String, Object>)((Map<String, Object>)JSON.deserializeUntyped(response.getBody())).get('error')).get('innererror')).get('errordetails')).get('errordetail'))[0]).get('message'):System.Label.PMC_CPQ_GetPriceCalloutFailedNoResponse);              
                
        }else{
                objQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
                objQuote.PMC_CPQ_IntegrationMessage__c = STRING_INTEGRATIONSTATUSERROR;
                
        }
        
        PMC_CPQ_ProductAvailableUtility.updateQuoteNQLI(lstQuotes,lstQuoteLines, mapTransactionLogFields);
        }

    /** 
     * @description Parses through the response body and populates Integration fields on the cadence GDASF-9240.
     * @param lstScheduleResponse - response line from EndPoint
     * @param mapIndividualQLICadence - map of QLI and related Cadence
     */
    public static void parseScheduleCadence(List<Object> lstScheduleResponse, Map<String, PMC_CPQ_Cadence__c> mapIndividualQLICadence){
        PMC_CPQ_Cadence__c cadRecord = new PMC_CPQ_Cadence__c();
        List<PMC_CPQ_Cadence__c> lstCadUpdate = new List<PMC_CPQ_Cadence__c>();
        Map<String, Object> mapResponseLine = new Map<String, Object>();
        for(Object responseKey: lstScheduleResponse){
                mapResponseLine = (Map<String, Object>)responseKey;
                cadRecord = PMC_CPQ_ProductAvailableUtility.getTargetFieldValueMapped(mapResponseLine, mapIndividualQLICadence);
                if(cadRecord!=null){
                    lstCadUpdate.add(cadRecord);
                }
                
        }
        try {
            SBQQ.TriggerControl.disable();
            if(!lstCadUpdate.isEmpty()){
                SObjectAccessDecision securityDecisionCadence = Security.stripInaccessible(AccessType.UPDATABLE, lstCadUpdate);
                Database.update(securityDecisionCadence.getRecords(), false); // GDASF-9443 changed from update to upsert
            }
        } 
        catch(Exception e) {
            PMC_ErrorLogClass.processException(e);
        }
        finally{
             SBQQ.TriggerControl.enable();
        }
    }

    /** 
     * @description Parses through the response body and populates Integration fields on the cadence GDASF-9240.
     * @param lstMaterialAvailable - response line from EndPoint
     */
    public static void parseMaterialAvailable(List<Object> lstMaterialAvailable){
        Map<String, Object> mapMaterialResponseLine = new Map<String, Object>();
        List<PMC_CPQ_CadenceItem__c> lstCadItemUpdate = new List<PMC_CPQ_CadenceItem__c>();
        PMC_CPQ_CadenceItem__c cadItemRec = new PMC_CPQ_CadenceItem__c();
            try{
                for(Object materialRespKey: lstMaterialAvailable){
                    mapMaterialResponseLine = (Map<String, Object>)materialRespKey;
                    cadItemRec = mapMaterialAvailableResponse(mapMaterialResponseLine);
                    lstCadItemUpdate.add(cadItemRec);
                }
                SBQQ.TriggerControl.disable();
                if(!lstCadItemUpdate.isEmpty()){
                    SObjectAccessDecision securityDecisionCadItem = Security.stripInaccessible(AccessType.CREATABLE, lstCadItemUpdate);
                    Database.upsert(securityDecisionCadItem.getRecords(), false); // GDASF-9443 changed from update to upsert
                }
            }
            catch(Exception e) {
                PMC_ErrorLogClass.processException(e);
            }
            finally{
                 SBQQ.TriggerControl.enable();
            }
    }

    /** 
     * @description Parses through the response body and populates Integration fields on the cadence GDASF-9240.
     * @param lstCadence - response line from EndPoint
     * @return mapIndividualQLICadence
     */
    public static Map<String, PMC_CPQ_Cadence__c> prepareMapLineNumberCadence(List<PMC_CPQ_Cadence__c> lstCadence){
        Map<String,PMC_CPQ_Cadence__c> mapIndividualQLICadence = new Map<String,PMC_CPQ_Cadence__c>();
        for(PMC_CPQ_Cadence__c cad: lstCadence){
            Date d = cad.PMC_CPQ_RequestedDate__c;
            String month = d.month()<10?'0'+d.month():String.valueOf(d.month());
            String day = d.day()<10?'0'+d.day():String.valueOf(d.day());
            mapIndividualQLICadence.put(cad.PMC_CPQ_QuoteLine__r.SBQQ__Number__c+'_'+d.year()+'-'+month+'-'+day, cad);
            mapCadencetoLineNum.put(String.valueOf(cad.PMC_CPQ_QuoteLine__r.SBQQ__Number__c),cad);
            mapCadencetoMonth.put(cad.PMC_CPQ_QuoteLine__r.SBQQ__Number__c+'_'+d.year()+'-'+month, cad.Id);
        }
        return mapIndividualQLICadence;
    }

    /** 
     * @description Parses through the response body and populates Integration fields on the cadence GDASF-9240.
     * @param lstCadItem - response line from EndPoint
     * @return mapCadItemtoLineNum
     */
    public static Map<String, PMC_CPQ_CadenceItem__c> prepareMapCadenceItemtoLineNum(List<PMC_CPQ_CadenceItem__c> lstCadItem){
        Map<String,PMC_CPQ_CadenceItem__c> mapCadItemtoLineNum = new Map<String,PMC_CPQ_CadenceItem__c>();
        for(PMC_CPQ_CadenceItem__c cadItem: lstCadItem){
            Date d = cadItem.PMC_CPQ_ConfirmedDate__c;
            String month = d.month()<10?'0'+d.month():String.valueOf(d.month());
            String day = d.day()<10?'0'+d.day():String.valueOf(d.day());
            mapCadItemtoLineNum.put(cadItem.PMC_CPQ_Cadence__r.PMC_CPQ_QuoteLine__r.SBQQ__Number__c+'_'+d.year()+'-'+month+'-'+day, cadItem);
        }
        return mapCadItemtoLineNum;
    }

    /** 
     * @description Parses through the response body and create Cadence Item/update Integration fields on the cadence items GDASF-9443.
     * @param mapMaterialResponseLine - response line from EndPoint
     * @return cadRecord
     */
    public static PMC_CPQ_CadenceItem__c mapMaterialAvailableResponse(Map<String, Object> mapMaterialResponseLine){
        PMC_CPQ_CadenceItem__c cadItemRec = new PMC_CPQ_CadenceItem__c();
        
        for(PMC_CPQ_IntegrationFieldMap__mdt add: lstMaterial){
            Date forecastDate = Date.valueOf((String)mapMaterialResponseLine.get('ComDate'));
            String month = forecastDate.month()<10?'0'+forecastDate.month():String.valueOf(forecastDate.month());
            Integer year = forecastDate.year(); 
            // if first time 14-week data is recieved or if some specific week response is not prsent in SF then create the record
            if(mapCadenceItem.isEmpty() || !mapCadenceItem.containskey(mapMaterialResponseLine.get('ItmNumber')+'_'+mapMaterialResponseLine.get('ComDate'))){
                
                cadItemRec.PMC_CPQ_Cadence__c = Date.valueOf((String)mapMaterialResponseLine.get('ComDate')) > (mapCadencetoLineNum.get((String)mapMaterialResponseLine.get('ItmNumber'))).PMC_CPQ_RequestedDate__c ? (mapCadencetoLineNum.get((String)mapMaterialResponseLine.get('ItmNumber'))).Id : mapCadencetoMonth.get(mapMaterialResponseLine.get('ItmNumber')+'_'+year+'-'+month);
                mapValueToCadItemRec(cadItemRec,add,mapMaterialResponseLine); // this will map value to target field of cadence item
            }
            // if cadence item record already exists then update the same record with latest value.
            else{
                cadItemRec = mapCadenceItem.get(mapMaterialResponseLine.get('ItmNumber')+'_'+mapMaterialResponseLine.get('ComDate'));
                mapValueToCadItemRec(cadItemRec,add,mapMaterialResponseLine); // this will map value to target field of cadence item
            }
        }
        return cadItemRec;
    }

    /** 
     * @description Map value to target fields of cadence item GDASF-9443.
     * @param cadItemRec - Cadence Item Record
     * @param add - integration field metadata records
     * @param mapMaterialResponseLine - response line from EndPoint
     */
    public static void mapValueToCadItemRec(PMC_CPQ_CadenceItem__c cadItemRec, PMC_CPQ_IntegrationFieldMap__mdt add, Map<String, Object> mapMaterialResponseLine){
        String strAPIName = mapMaterialAvailable.get((String)add.get('PMC_CPQ_AttributeKey__c'));
        if(cadItemRec != null && add.PMC_CPQ_DataType__c == 'Date'){
            cadItemRec.put(strAPIName,Date.valueOf((String)mapMaterialResponseLine.get((String)add.get('PMC_CPQ_AttributeKey__c'))));
        }
        else{
            cadItemRec.put(strAPIName,Decimal.valueOf((String)mapMaterialResponseLine.get((String)add.get('PMC_CPQ_AttributeKey__c'))));
        }
    }
}