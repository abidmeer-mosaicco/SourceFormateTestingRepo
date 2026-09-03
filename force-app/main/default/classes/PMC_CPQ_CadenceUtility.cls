/** @description This class will house utility functions for Cadence
 *  @author Prakhar Srivastava
 *  @storynumber GDASF-9240
 */
public with sharing class PMC_CPQ_CadenceUtility {
    
    static boolean flag = false;
    public static String strErrorMessage = '<br/>';
    static List<Object> lstLookupQuoteLines = new List<Object>();
    static Id quoteId;
    static Map<String, List<Object>> bulkLookupQL = new Map<String, List<Object>>();
    /** 
     * @description Returns all the quotelines related to the Quote passed in the method
     * @param queryQuote - Quote for which quote lines has to be fetched
     * @param queryParam - Contains part of the query on Quote Line object
     * @return qtLines - Returns list of Quote Lines of the quote in argument
     */
    public static Map<String,List<Object>> getQuoteLines(Id queryQuote, String queryParam){
            quoteId = queryQuote;
            Map<String, List<Object>> bulkifiedQL = new Map<String, List<Object>>();
            String quoteLineQuery = 'Select ' + String.escapeSingleQuotes(queryParam) + ' from SBQQ__QuoteLine__c where SBQQ__Quote__c  = \''+ queryQuote + '\' WITH SECURITY_ENFORCED';
            List<SBQQ__QuoteLine__c> qtLines = Database.query(quoteLineQuery);
            bulkifiedQL.put(queryQuote, qtLines);
            return bulkifiedQL;
    }
    
    /** 
     * @description Returns all the quotelines related to the Quote passed in the method
     * @param queryQuote - Quote for which quote lines has to be fetched
     * @param queryParam - Contains part of the query on Quote Line object
     * @return qtLines - Returns list of Quote Lines of the quote in argument
     */
    public static Map<String,List<Object>> getLookupQuoteLines(Id queryQuote, String queryParam){

        String quoteLineQuery = 'Select ' + String.escapeSingleQuotes(queryParam.split('\\*')[0]) + ' from SBQQ__QuoteLine__c where SBQQ__Quote__c = \''+ queryQuote + '\' group by ' + String.escapeSingleQuotes(queryParam.split('\\*')[1]);
        List<AggregateResult> qtLookupLines = Database.query(quoteLineQuery);
        bulkLookupQL.put(queryQuote, qtLookupLines);
            return bulkLookupQL;
    }

    /** 
     * @description Returns unique set of id of Quote
     * @param queryQuote - Unique set of Quote IDS
     * @param queryParam - String value for Query 
     * @return lookupQuote - Returns String value which will be used to query the Database
     */
    public static Map<String,AggregateResult> getLookupQuotes(Id queryQuote, String queryParam){

        Map<String, AggregateResult> lookupQuote = new Map<String, AggregateResult>();

            String quoteLineQuery = 'Select ' + String.escapeSingleQuotes(queryParam.split('\\*')[0]) + ' from SBQQ__Quote__c where Id  = \''+ queryQuote + '\' group by ' + String.escapeSingleQuotes(queryParam.split('\\*')[1]);
            List<AggregateResult> qtLookupLines = Database.query(quoteLineQuery);
            
                for(AggregateResult line: qtLookupLines){
                    lookupQuote.put(queryQuote, line);
                }
        return lookupQuote;
    }

    /** 
     * @description Returns all the cadence related to the Quote passed in the method
     * @param queryQuote - Quote for which cadence has to be fetched
     * @param strCadenceQueryParam - Contains part of the query on Cadence object
     * @return lstCadence - Returns list of Cadence of the quote in argument
     */
    public static Map<String,List<Object>> getCadence(Id queryQuote, String strCadenceQueryParam){
        Map<String, List<Object>> bulkifiedCadence = new Map<String, List<PMC_CPQ_Cadence__c>>();
        String cadenceQuery = 'Select ' + String.escapeSingleQuotes(strCadenceQueryParam) + ', PMC_CPQ_QuoteLine__c from PMC_CPQ_Cadence__c where PMC_CPQ_QuoteLine__r.SBQQ__Quote__c  = \''+ queryQuote + '\' WITH SECURITY_ENFORCED';
        List<PMC_CPQ_Cadence__c> lstCadence = Database.query(cadenceQuery);
        if(!lstCadence.isEmpty()){
            for(PMC_CPQ_Cadence__c cad: lstCadence){
                List<PMC_CPQ_Cadence__c> lstQLICad = new List<PMC_CPQ_Cadence__c>();
                if(bulkifiedCadence.containsKey(cad.PMC_CPQ_QuoteLine__c)){
                    lstQLICad = (List<PMC_CPQ_Cadence__c>)bulkifiedCadence.get(cad.PMC_CPQ_QuoteLine__c);
                }
                lstQLICad.add(cad);
                bulkifiedCadence.put(cad.PMC_CPQ_QuoteLine__c,lstQLICad);
            }
         }
        return bulkifiedCadence;
    }

    /** 
     * @description Returns the JSON Generator Object after adding fields based on if it is a lookup or not.
     * @param lstQuoteFieldMap - Map for all the fields that have to be used in the JSON Request.
     * @param quoteObject - Argument of type Object that may be of type Quote or Aggregate result all similar to Quote.
     * @param jsonReq - Reference of the jsonReq Object that is to have the additional fields that are in the Quote Field Map.
     * @return qtLines - Returns list of Quote Lines of the quote in argument
     */
    public static JSONGenerator quoteJsonGeneration(List<PMC_CPQ_IntegrationFieldMap__mdt> lstQuoteFieldMap, Object quoteObject, JSONGenerator jsonReq){
        String strPlaceHolderValue = '';
        SBQQ__Quote__c qT = (SBQQ__Quote__c)quoteObject;
        for (PMC_CPQ_IntegrationFieldMap__mdt value: lstQuoteFieldMap) { 
                jsonReq.writeFieldName(value.PMC_CPQ_AttributeKey__c);
                strPlaceHolderValue = (qT.get(value.PMC_CPQ_ApexAPIName__c) != null)?(''+qT.get(value.PMC_CPQ_ApexAPIName__c)):'';
                strErrorMessage = strErrorMessage + (((strPlaceHolderValue=='')&&(value.PMC_CPQ_IsMandatory__c))?(value.PMC_CPQ_ErrorMessage__c + '<br/>'):'');
                jsonReq.writeObject(strPlaceHolderValue);
            }
         return jsonReq;
    }

    /** 
     * @description Returns the JSON Generator Object after adding fields based on if it is a lookup or not.
     * @param lstQuoteFieldMap - Map for all the fields that have to be used in the JSON Request.
     * @param quoteObject - Argument of type Object that may be of type Quote or Aggregate result all similar to Quote.
     * @param jsonReq - Reference of the jsonReq Object that is to have the additional fields that are in the Quote Field Map.
     * @return qtLines - Returns list of Quote Lines of the quote in argument
     */
    public static JSONGenerator quoteLookupJsonGeneration(List<PMC_CPQ_IntegrationFieldMap__mdt> lstQuoteFieldMap, Object quoteObject, JSONGenerator jsonReq){
        String strPlaceHolderValue = '';
        Integer j = 0;
            AggregateResult lookupQuote = (AggregateResult)quoteObject;
            for (PMC_CPQ_IntegrationFieldMap__mdt value: lstQuoteFieldMap) { 
                jsonReq.writeFieldName(value.PMC_CPQ_AttributeKey__c);
                strPlaceHolderValue = (lookupQuote.get(('Lookup'+j)) != null)?(''+lookupQuote.get(('Lookup'+j))):'';
                strErrorMessage = strErrorMessage + (((strPlaceHolderValue=='')&&(value.PMC_CPQ_IsMandatory__c))?(value.PMC_CPQ_ErrorMessage__c+ '<br/>'):'');
                jsonReq.writeObject(strPlaceHolderValue);
                j++;
            }
        return jsonReq;
    }

    /** 
     * @description Returns the map of quote line after adding fields.
     * @param lstLookupQuoteLineMap - Map for all the fields that have to be used in the JSON Request.
     * @param i - integer reference to QuoteLine num
     * @param mapQuoteLineDet - Reference of the jsonReq Object that is to have the additional fields that are in the Quote Field Map.
     * @return mapQuoteLineDet - Returns map after adding values
     */
    public static Map<String, String> quoteLineLookupJSONGen(List<PMC_CPQ_IntegrationFieldMap__mdt> lstLookupQuoteLineMap, Integer i, Map<String, String> mapQuoteLineDet){
    	lstLookupQuoteLines = bulkLookupQL.get((String)quoteId);
        flag = false;
		Integer j = 0;
		String strLocError = '';
		for(PMC_CPQ_IntegrationFieldMap__mdt value: lstLookupQuoteLineMap){
			mapQuoteLineDet.put(value.PMC_CPQ_AttributeKey__c, ('' + ((((AggregateResult)lstLookupQuoteLines[i]).get(('Lookup'+j)) == null)?'':((AggregateResult)lstLookupQuoteLines[i]).get(('Lookup'+j)))));
			strLocError = strLocError + (((((AggregateResult)lstLookupQuoteLines[i]).get(('Lookup'+j)) == null)&&(value.PMC_CPQ_IsMandatory__c))?('-'+ value.PMC_CPQ_ErrorMessage__c + '<br/>'):'');
			j++;
		}
		strErrorMessage = ((strLocError != '')?(strErrorMessage + '<br/>QuoteLine ' + (i + 1) + ' :<br/>' + strLocError):strErrorMessage);
		flag = ((strLocError != '')?True:False);
        
        return mapQuoteLineDet;
        
    }

    /** 
     * @description Returns the map of quote line after adding fields.
     * @param lstQuoteLineFieldMap - Map for all the fields that have to be used in the JSON Request.
     * @param quoteLine - Argument of type Object that may be of type Quote or Aggregate result all similar to Quote.
     * @param mapQuoteLineDet - Reference of the jsonReq Object that is to have the additional fields that are in the Quote Field Map.
     * @return mapQuoteLineDet - Returns map after adding values
     */
    public static Map<String, String> quoteLineJSONGen(List<PMC_CPQ_IntegrationFieldMap__mdt> lstQuoteLineFieldMap, Object quoteLine, Map<String, String> mapQuoteLineDet){
        String strLocError = '';
        for(PMC_CPQ_IntegrationFieldMap__mdt value: lstQuoteLineFieldMap){
         mapQuoteLineDet.put(value.PMC_CPQ_AttributeKey__c, ('' + ((((SBQQ__QuoteLine__c)quoteLine).get(value.PMC_CPQ_ApexAPIName__c) == null)?'':((SBQQ__QuoteLine__c)quoteLine).get(value.PMC_CPQ_ApexAPIName__c))));
         strLocError = strLocError + (((((SBQQ__QuoteLine__c)quoteLine).get(value.PMC_CPQ_ApexAPIName__c) == null)&&(value.PMC_CPQ_IsMandatory__c))?('-'+ value.PMC_CPQ_ErrorMessage__c + '<br/>'):'');
         }
                     
         strErrorMessage = ((strLocError != '')?(strErrorMessage + ((flag)?'':('<br/>QuoteLine ' + (((SBQQ__QuoteLine__c)quoteLine).get('SBQQ__Number__c'))+ ' :<br/>'))  + strLocError):strErrorMessage);
         
         return mapQuoteLineDet;
                      
     }

     /** 
     * @description Returns the map of cadence after adding fields.
     * @param lstCadenceFieldMap - Map for all the fields that have to be used in the JSON Request.
     * @param lstQLICandence - List of QLI
     * @param lstMapCadence - store output json in this map
     * @return lstMapCadence - Returns map after adding values
     */
    public static List<Map<String,String>> cadenceJSONGen(List<PMC_CPQ_IntegrationFieldMap__mdt> lstCadenceFieldMap, List<PMC_CPQ_Cadence__c> lstQLICandence, List<Map<String,String>> lstMapCadence){
        String strLocError = '';
        
        for(PMC_CPQ_Cadence__c cadValue: lstQLICandence){
            Map<String,String> mapCadenceValue = new Map<String,String>();
            for(PMC_CPQ_IntegrationFieldMap__mdt value: lstCadenceFieldMap){
                String fieldAPIName = value.PMC_CPQ_ApexAPIName__c;
                mapCadenceValue.put(value.PMC_CPQ_AttributeKey__c, (''+(cadValue.get(fieldAPIName) == null?'':(cadValue.get(fieldAPIName)))));
                strLocError = strLocError + (((cadValue.get(fieldAPIName) == null) &&(value.PMC_CPQ_IsMandatory__c))?('-'+ value.PMC_CPQ_ErrorMessage__c + '<br/>'):'');
            }
           
            lstMapCadence.add(mapCadenceValue);
        }            
         //strErrorMessage = ((strLocError != '')?(strErrorMessage + ((flag)?'':('<br/>QuoteLine ' + (((SBQQ__QuoteLine__c)quoteLine).get('SBQQ__Number__c'))+ ' :<br/>'))  + strLocError):strErrorMessage);
         
         return lstMapCadence;
                      
     }
}