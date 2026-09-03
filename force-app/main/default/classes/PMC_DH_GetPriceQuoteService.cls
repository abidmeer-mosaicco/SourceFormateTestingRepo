/**
* @description : class for Get Price SAP Integration
* @author      : Humera Rahath
* @params      : None
* @userStory   : GPDH-6862
* */
public without sharing class PMC_DH_GetPriceQuoteService {

    

    
    static List<PMC_CPQ_IntegrationFieldMap__mdt> lstCartFieldMap = new List<PMC_CPQ_IntegrationFieldMap__mdt>();
    static List<PMC_CPQ_IntegrationFieldMap__mdt> lstCartItemFieldMap = new List<PMC_CPQ_IntegrationFieldMap__mdt>();
    static List<PMC_CPQ_IntegrationFieldMap__mdt> lstLookupCartMap = new List<PMC_CPQ_IntegrationFieldMap__mdt>();
    static List<PMC_CPQ_IntegrationFieldMap__mdt> lstLookupCartItemMap = new List<PMC_CPQ_IntegrationFieldMap__mdt>();
    /** 
* @description Method to filter list for integration mapping.
*/
    public static void filterMapValues(){
        List<PMC_CPQ_IntegrationFieldMap__mdt> lstIntegration = [select MasterLabel,PMC_CPQ_ApexAPIName__c,PMC_CPQ_SFObject__c,PMC_CPQ_IsMandatory__c, PMC_CPQ_ErrorMessage__c, PMC_CPQ_AttributeKey__c, PMC_CPQ_IsLookup__c from PMC_CPQ_IntegrationFieldMap__mdt where (PMC_CPQ_ApexAPIName__c != null AND PMC_CPQ_SFObject__c in ('WebCart','CartItem')) WITH SECURITY_ENFORCED order by MasterLabel ASC];
        
        for(PMC_CPQ_IntegrationFieldMap__mdt mapVal: lstIntegration){
            
            if(mapVal.PMC_CPQ_SFObject__c == 'WebCart'){
                if(mapVal.PMC_CPQ_IsLookup__c == false){
                    lstCartFieldMap.add(mapVal);
                    continue;
                }
                lstLookupCartMap.add(mapVal);
            }
            else{
                if(mapVal.PMC_CPQ_IsLookup__c == false){
                    lstCartItemFieldMap.add(mapVal);
                    continue;
                }
                lstLookupCartItemMap.add(mapVal);
            }
        }
    }
    /** 
* @description This class will make a callout to CPI.
* @param lstCarts - List of quotes.
* @return response - HttpResponse Object returned from Endpoint.
*/

    public static HttpResponse makeCallOutRequest(List<WebCart> lstCarts){
        HttpResponse response;
        Map<String, String> mapCartItemDet = new Map<String, String>();
        List<Map<String, String>> lstCtItem = new List<Map<String, String>>();
        Set<String> setCartIds = new Set<String>();
        Integer i = 0;
        Integer j = 0;
        List<Object> lstCartItem = new List<Object>();
        List<Object> lstLookupCartItem = new List<Object>();
        
        filterMapValues();
        setCartIds.add(lstCarts[0].Id);
        String cId = (String)lstCarts[0].Id;
        String queryParam = getQueryParam(lstCartItemFieldMap, null) + ' ,CartId';
        String strLookupQueryParam = getQueryParam(lstLookupCartItemMap, 'Lookup') + ' ,CartId';
        String strLookupGroupByQry = getQueryParam(lstLookupCartItemMap, null) + ' ,CartId';
        strLookupQueryParam = strLookupQueryParam + '*' + strLookupGroupByQry;
        String strLocError = '';
        Map<String, List<Object>> bulkifiedCI = getCartItem(cId, queryParam);
        Map<String, List<Object>> bulkLookupCI = getLookupCartItem(cId, strLookupQueryParam);
        
        String quoteLookupQueryParam = getQueryParam(lstLookupCartMap, 'Lookup');
        String quoteLookupGroupByQuery = getQueryParam(lstLookupCartMap, null);
        quoteLookupQueryParam = quoteLookupQueryParam + '*' + quoteLookupGroupByQuery;
        Map<String,AggregateResult> cartLookupTable = getLookupCarts(cId, quoteLookupQueryParam);
        try{
            JSONGenerator jsonReq = JSON.createGenerator(false);
            jsonReq.writeStartObject();
            WebCart ct = [ 
                SELECT ID,
                PMC_DH_PaymentTerms__c,
                PMC_DH_ContractEndDate__c,
                PMC_DH_ContractStartDate__c,
                PMC_DH_Currency__c,
                PMC_DH_SalesAgreement__c,
                PMC_DH_SalesAgreementEndDate__c,
                PMC_DH_SalesAgreementStartDate__c,PMC_DH_B2B_B2C_INDICATOR__c,
                PMC_DH_SalesAgreement__r.PMC_SS_SalesAgreementExternalId__c,
                PMC_DH_Cart_Number__c,PMC_DH_SAP_CONSTANT__c,PMC_DH_SCHED_AGREEMENT__c,PMC_DH_EMPTYCONST__c,PMC_DH_PrimaryBusinessType__c,PMC_DH_PrepaymentDate__c
                FROM Webcart where Id=:lstCarts[0].Id WITH USER_MODE LIMIT 1];
            i = 0;
            AggregateResult lookupCart = cartLookupTable.get((String)ct.Id);
            lstCartItem = bulkifiedCI.get((String)ct.Id);
            lstLookupCartItem = bulkLookupCI.get((String)ct.Id);
            
            jsonReq = cartJsonGeneration(lstCartFieldMap, ct, jsonReq);
            jsonReq = cartLookupJsonGeneration(lstLookupCartMap, lookupCart, jsonReq);
            for(Object cartItem: lstCartItem){
                j = 0;
                strLocError = '';
                for(PMC_CPQ_IntegrationFieldMap__mdt value: lstLookupCartItemMap){
                    mapCartItemDet.put(value.PMC_CPQ_AttributeKey__c, ('' + ((((AggregateResult)lstLookupCartItem[i]).get(('Lookup'+j)) == null)?'':((AggregateResult)lstLookupCartItem[i]).get(('Lookup'+j)))));
                    
                    j++;
                }
                mapCartItemDet = cartItemJSONGen(lstCartItemFieldMap, cartItem, mapCartItemDet);
                i++;
                lstCtItem.add(mapCartItemDet);
                mapCartItemDet = new Map<String, String>();
            }
            jsonReq.writeFieldName('LineItemList');
            jsonReq.writeObject(lstCtItem);
            jsonReq.writeEndObject();  
            String strInterface = 'ProductsExternalPricing';
            PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(strInterface); 
            String strEndpoint = strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c;
           
            response = PMC_CPQ_CPIRemoteCalloutUtilityClass.sendCalloutRequest('GET', 'callout:PMC_CPQ_NamedCredential'+strEndpoint,stringProcess(jsonReq.getAsString()));
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        return response;
    }
    /** 
* @description Returns all the quotelines related to the Quote passed in the method
* @param queryCart - Quote for which quote lines has to be fetched
* @param queryParam - Contains part of the query on Quote Line object
* @return qtLines - Returns list of Quote Lines of the quote in argument
*/
    public static Map<String,List<Object>> getCartItem(String queryCart, String queryParam){
        String strCartSet = '(';
        strCartSet = strCartSet + '\'' + queryCart + '\'' + ')';
        Map<String, List<Object>> bulkifiedCI = new Map<String, List<Object>>();
        String cartItemQuery = 'Select ';
        cartItemQuery = cartItemQuery + String.escapeSingleQuotes(queryParam) + ' from CartItem where cartId  in '+ strCartSet ;//' WITH SECURITY_ENFORCED';
        List<CartItem> ciLines = Database.query(cartItemQuery);
        bulkifiedCI.put(queryCart, ciLines);
        return bulkifiedCI;
    }
    /** 
* @description Returns all the quotelines related to the Quote passed in the method
* @param queryCart - Quote for which quote lines has to be fetched
* @param queryParam - Contains part of the query on Quote Line object
* @return qtLines - Returns list of Quote Lines of the quote in argument
*/
    public static Map<String,List<Object>> getLookupCartItem(String queryCart, String queryParam){
        String strCartSet = '(';
        strCartSet = strCartSet + '\'' + queryCart + '\'' + ')';
        
        Map<String, List<Object>> bulkifiedCI = new Map<String, List<Object>>();
        String cartItemQuery = 'Select ';
        cartItemQuery = cartItemQuery + String.escapeSingleQuotes(queryParam.split('\\*')[0]) + ' from CartItem where cartId  in '+ strCartSet + ' group by ' + String.escapeSingleQuotes(queryParam.split('\\*')[1]);
        List<AggregateResult> ciLookupLines = Database.query(cartItemQuery);
        bulkifiedCI.put(queryCart, ciLookupLines);
        return bulkifiedCI;
    }
    /** 
* @description Returns unique set of id of Quote
* @param fieldMap - Fields fetched from External metadata.
* @param filterString - String value which will be added for aliasing. 
* @return queryParam - Returns String value which will be used to query the Database
*/
    public static String getQueryParam(List<PMC_CPQ_IntegrationFieldMap__mdt> fieldMap, String filterString){
        Set<String> cartItemFieldSet = new Set<String>();
        String queryParam = '';
        Integer i = 0;
        
        for(PMC_CPQ_IntegrationFieldMap__mdt keypair: fieldMap){
            cartItemFieldSet.add((String)keypair.PMC_CPQ_ApexAPIName__c);
        }
        for(String s: cartItemFieldSet){
            queryParam = queryParam + s + ((filterString!=null)?(' ' + filterString + i):'') + ',';
            i++;
        }
        queryParam = queryParam + 'Id';
        return queryParam;
    }
    /** 
* @description Returns unique set of id of Quote
* @param queryCart - Unique set of Quote IDS
* @param queryParam - String value for Query 
* @return lookupQuote - Returns String value which will be used to query the Database
*/
    public static Map<String,AggregateResult> getLookupCarts(String queryCart, String queryParam){
        String strCartSet = '(';
        Map<String, AggregateResult> lookupCart = new Map<String, AggregateResult>();
        String cartQuery = 'Select ';
        strCartSet = strCartSet + '\'' + queryCart + '\'' + ')';
        cartQuery = cartQuery + String.escapeSingleQuotes(queryParam.split('\\*')[0]) + ' from WebCart where Id  in '+ strCartSet + ' group by ' + String.escapeSingleQuotes(queryParam.split('\\*')[1]);
        List<AggregateResult> ctLookupLines = Database.query(cartQuery);
        
        for(AggregateResult line: ctLookupLines){
            lookupCart.put(queryCart, line);
        }
        return lookupCart;
    }
    /** 
* @description Returns the JSON Generator Object after adding fields based on if it is a lookup or not.
* @param lstCartFieldMap - Map for all the fields that have to be used in the JSON Request.
* @param cartObject - Argument of type Object that may be of type Quote or Aggregate result all similar to Quote.
* @param jsonReq - Reference of the jsonReq Object that is to have the additional fields that are in the Quote Field Map.
* @return qtLines - Returns list of Quote Lines of the quote in argument
*/
    public static JSONGenerator cartJsonGeneration(List<PMC_CPQ_IntegrationFieldMap__mdt> lstCartFieldMap, Object cartObject, JSONGenerator jsonReq){
        String strPlaceHolderValue = '';
        WebCart cT = (WebCart)cartObject;
        for (PMC_CPQ_IntegrationFieldMap__mdt value: lstCartFieldMap) { 
            jsonReq.writeFieldName(value.PMC_CPQ_AttributeKey__c);
            strPlaceHolderValue = (cT.get(value.PMC_CPQ_ApexAPIName__c) != null)?(''+cT.get(value.PMC_CPQ_ApexAPIName__c)):'';
            
            jsonReq.writeObject(strPlaceHolderValue);
        }
        return jsonReq;
    }
    /** 
* @description Returns the JSON Generator Object after adding fields based on if it is a lookup or not.
* @param lstCartFieldMap - Map for all the fields that have to be used in the JSON Request.
* @param cartObject - Argument of type Object that may be of type Quote or Aggregate result all similar to Quote.
* @param jsonReq - Reference of the jsonReq Object that is to have the additional fields that are in the Quote Field Map.
* @return qtLines - Returns list of Quote Lines of the quote in argument
*/
    public static JSONGenerator cartLookupJsonGeneration(List<PMC_CPQ_IntegrationFieldMap__mdt> lstCartFieldMap, Object cartObject, JSONGenerator jsonReq){
        String strPlaceHolderValue = '';
        Integer j = 0;
        AggregateResult lookupCart = (AggregateResult)cartObject;
        for (PMC_CPQ_IntegrationFieldMap__mdt value: lstCartFieldMap) {
            jsonReq.writeFieldName(value.PMC_CPQ_AttributeKey__c);
            strPlaceHolderValue = (lookupCart.get(('Lookup'+j)) != null)?(''+lookupCart.get(('Lookup'+j))):'';
            jsonReq.writeObject(strPlaceHolderValue);
            j++;
        }
        return jsonReq;
    }
    /** 
* @description Returns the map of quote line after adding fields.
* @param lstCartItemFieldMap - Map for all the fields that have to be used in the JSON Request.
* @param cartItem - Argument of type Object that may be of type Quote or Aggregate result all similar to Quote.
* @param mapCartItemDet - Reference of the jsonReq Object that is to have the additional fields that are in the Quote Field Map.
* @return mapCartItemDet - Returns map after adding values
*/
    public static Map<String, String> cartItemJSONGen(List<PMC_CPQ_IntegrationFieldMap__mdt> lstCartItemFieldMap, Object cartItem, Map<String, String> mapCartItemDet){
        for(PMC_CPQ_IntegrationFieldMap__mdt value: lstCartItemFieldMap){
            mapCartItemDet.put(value.PMC_CPQ_AttributeKey__c, ('' + ((((CartItem)cartItem).get(value.PMC_CPQ_ApexAPIName__c) == null)?'':((CartItem)cartItem).get(value.PMC_CPQ_ApexAPIName__c))));
        }
        return mapCartItemDet;
        
    }
    /** 
* @description Returns unique set of id of Quote
* @param strVal - Object to be converted to String and hit the end point.
* @return strProcessed - Returns String value which can be used to hit the end point.
*/
    public static String stringProcess(Object strVal){
        String strObject = JSON.serialize(strVal);
        String strProcessed = strObject.replace('\\\\','').substringAfter('"').substringBeforeLAst('"');
        strProcessed = strProcessed.replaceAll('\n','');
        strProcessed = strProcessed.replaceAll('\\\\','');
        return strProcessed;
    }


    

}