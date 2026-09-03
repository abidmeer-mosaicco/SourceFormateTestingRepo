/** @description This class will be called from a PMC_CPQ_CadenceController apex
 *  @author Prakhar Srivastava
 *  @storynumber GDASF-9240, 9443
 */
public with sharing class PMC_CPQ_CadenceJSONCreation {
    
    static String strExceptionMsg = '';
    public static String strErrorMessage = '<br/>';
    static boolean flag = false;
    static List<Object> lstLookupQuoteLines = new List<Object>();
    
    static List<PMC_CPQ_IntegrationFieldMap__mdt> lstQuoteFieldMap = new List<PMC_CPQ_IntegrationFieldMap__mdt>();
    static List<PMC_CPQ_IntegrationFieldMap__mdt> lstQuoteLineFieldMap = new List<PMC_CPQ_IntegrationFieldMap__mdt>();
    static List<PMC_CPQ_IntegrationFieldMap__mdt> lstLookupQuoteMap = new List<PMC_CPQ_IntegrationFieldMap__mdt>();
    static List<PMC_CPQ_IntegrationFieldMap__mdt> lstLookupQuoteLineMap = new List<PMC_CPQ_IntegrationFieldMap__mdt>();
    static List<PMC_CPQ_IntegrationFieldMap__mdt> lstCadenceFieldMap = new List<PMC_CPQ_IntegrationFieldMap__mdt>(); // GDASF-9240 // GDASF-9443 commenting out

    /** 
     * @description Method to filter list for integration mapping.
     * @param strRegion - Region of Quotes
     */
    public static void filterMapValues(String strRegion){ // strRegion holds the developer name of Quote record
        // GDASF-9240: Added object PMC_CPQ_Cadence__c in filter.
        List<PMC_CPQ_IntegrationFieldMap__mdt> lstIntegration = [select MasterLabel,PMC_CPQ_ApexAPIName__c,PMC_CPQ_SFObject__c,PMC_CPQ_IsMandatory__c, PMC_CPQ_ErrorMessage__c, PMC_CPQ_AttributeKey__c, PMC_CPQ_DataType__c, PMC_CPQ_IsLookup__c from PMC_CPQ_IntegrationFieldMap__mdt where (PMC_CPQ_ApexAPIName__c != null AND PMC_CPQ_SFObject__c in ('SBQQ__Quote__c','SBQQ__QuoteLine__c','PMC_CPQ_Cadence__c') AND ((PMC_CPQ_DataType__c=null) OR (PMC_CPQ_DataType__c=:strRegion))) WITH SECURITY_ENFORCED order by MasterLabel ASC];

        for(PMC_CPQ_IntegrationFieldMap__mdt mapVal: lstIntegration){

            if(mapVal.PMC_CPQ_SFObject__c == 'SBQQ__Quote__c'){
                if(mapVal.PMC_CPQ_IsLookup__c == false){
                    lstQuoteFieldMap.add(mapVal);
                    continue;
                }
                lstLookupQuoteMap.add(mapVal);
            }
            // GDASF-9240 added below block for cadence.
            else if(mapVal.PMC_CPQ_SFObject__c == 'PMC_CPQ_Cadence__c'){
                lstCadenceFieldMap.add(mapVal);
                continue;
            }
            else{
                if(mapVal.PMC_CPQ_IsLookup__c == false){
                    lstQuoteLineFieldMap.add(mapVal);
                    continue;
                }
                lstLookupQuoteLineMap.add(mapVal);
            }
        }
    }

   /** 
     * @description This class will make a callout to CPI. and for testing cadence integration part
     * @param lstQuotes
     * @param strEndpoint
     */
    public static void makeCalloutRequestCadence(List<SBQQ__Quote__c> lstQuotes, String strEndpoint)
    {

        Map<String, String> mapQuoteLineDet = new Map<String, String>();
       	List<Map<String, String>> lstLineItem = new List<Map<String, String>>();
        String strQuoteId = lstQuotes[0].Id; // GDASF-9240
        Integer i = 0;
        List<Object> lstQuoteLines = new List<Object>();
        
        filterMapValues(lstQuotes[0].RecordType.DeveloperName);
        String queryParam = PMC_CPQ_GetPriceUtilityClass.getQueryParam(lstQuoteLineFieldMap, null) + ' ,SBQQ__Quote__c';
        String strLookupQueryParam = PMC_CPQ_GetPriceUtilityClass.getQueryParam(lstLookupQuoteLineMap, 'Lookup') + ' ,SBQQ__Quote__c';
        String strLookupGroupByQry = PMC_CPQ_GetPriceUtilityClass.getQueryParam(lstLookupQuoteLineMap, null) + ' ,SBQQ__Quote__c';
        strLookupQueryParam = strLookupQueryParam + '*' + strLookupGroupByQry;
        
        Map<String, List<Object>> bulkifiedQL = PMC_CPQ_CadenceUtility.getQuoteLines(lstQuotes[0].Id, queryParam);
        Map<String, List<Object>> bulkLookupQL = PMC_CPQ_CadenceUtility.getLookupQuoteLines(lstQuotes[0].Id, strLookupQueryParam);
        Map<String, List<Object>> bulkifiedCadence = new map<String,List<Object>>(); // GDASF-9240 // GDASF-9443 commenting out

        
        String quoteLookupQueryParam = PMC_CPQ_GetPriceUtilityClass.getQueryParam(lstLookupQuoteMap, 'Lookup');
        String quoteLookupGroupByQuery = PMC_CPQ_GetPriceUtilityClass.getQueryParam(lstLookupQuoteMap, null);
        quoteLookupQueryParam = quoteLookupQueryParam + '*' + quoteLookupGroupByQuery;
        Map<String,AggregateResult> quoteLookupTable = PMC_CPQ_CadenceUtility.getLookupQuotes(lstQuotes[0].Id, quoteLookupQueryParam);
        // GDASF-9240 query param for cadence
        
        	String strCadenceQueryParam = PMC_CPQ_GetPriceUtilityClass.getQueryParam(lstCadenceFieldMap, null);
            bulkifiedCadence = PMC_CPQ_CadenceUtility.getCadence(lstQuotes[0].Id, strCadenceQueryParam);
        
        try{
            JSONGenerator jsonReq = JSON.createGenerator(false);
            jsonReq.writeStartObject();
            SBQQ__Quote__c qt = lstQuotes[0];
                i = 0;
                AggregateResult lookupQuote = quoteLookupTable.get((String)qT.Id);
                lstQuoteLines = bulkifiedQL.get((String)qT.Id);
                lstLookupQuoteLines = bulkLookupQL.get((String)qT.Id);
                
                jsonReq = PMC_CPQ_CadenceUtility.quoteJsonGeneration(lstQuoteFieldMap, qT, jsonReq);
                jsonReq = PMC_CPQ_CadenceUtility.quoteLookupJsonGeneration(lstLookupQuoteMap, lookupQuote, jsonReq);
                
                for(Object quoteLine: lstQuoteLines){
                    List<Map<String,String>> lstMapCadence = new List<Map<String, String>>(); // GDASF-9240 to store cadence structure for request
                    mapQuoteLineDet = PMC_CPQ_CadenceUtility.quoteLineLookupJSONGen(lstLookupQuoteLineMap, i, mapQuoteLineDet);
                    mapQuoteLineDet = PMC_CPQ_CadenceUtility.quoteLineJSONGen(lstQuoteLineFieldMap, quoteLine, mapQuoteLineDet);
                    
                    i++;
                    // GDASF-9240 start create json for cadence
                   
                    String qliID = (String)(((SBQQ__QuoteLine__c)quoteLine).get('Id'));
                    List<PMC_CPQ_Cadence__c> lstQLICadence = new List<PMC_CPQ_Cadence__c>();
                    lstQLICadence = (List<PMC_CPQ_Cadence__c>)(bulkifiedCadence.get(qliID));
                    lstMapCadence = PMC_CPQ_CadenceUtility.cadenceJSONGen(lstCadenceFieldMap, lstQLICadence, lstMapCadence);
                    mapQuoteLineDet.put('CadenceList',JSON.serialize(lstMapCadence));
                    lstLineItem.add(mapQuoteLineDet);

                    mapQuoteLineDet = new Map<String, String>();
                }
                jsonReq.writeFieldName('LineItemList');
                jsonReq.writeObject(lstLineItem);
                jsonReq.writeEndObject(); 
                
            if(strErrorMessage == '<br/>'){
            	PMC_CPQ_CPIRemoteCalloutUtilityClass.sendCalloutRequestFuture('callout:PMC_CPQ_NamedCredential'+strEndpoint,PMC_CPQ_GetPriceUtilityClass.stringProcess(jsonReq.getAsString()), strQuoteId);
            }
          
        
        }
        catch(Exception e){
            PMC_ErrorLogClass.processException(e);
            strExceptionMsg = e.getMessage();
        }
        
    }//makeCalloutRequests

}