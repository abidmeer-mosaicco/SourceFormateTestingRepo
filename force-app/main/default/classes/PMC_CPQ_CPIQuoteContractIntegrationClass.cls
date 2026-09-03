/** @description This is a utility class for external callouts.
 *  @author Shefali Dsouza
 *  @storynumber GDASF-2983
 */
public without sharing class PMC_CPQ_CPIQuoteContractIntegrationClass implements Database.AllowsCallouts {
    static HttpRequest request = new HttpRequest();
    static HttpResponse response;
    static Boolean boolTransLogSuccess = false;
    static Boolean boolTransLogError = false;
    static String strTransactionLogStatus;
    static final String STRING_INTEGRATIONSTATUSERROR = 'Error'; 
    static final String STRING_INTEGRATIONSTATUSSUCCESS = 'Success';
    static final String STRING_INTEGRATIONSTATUSPARTIALSUCCESS = 'Partial Success';
    static final string STRING_OBJECTNUMBER = 'OBJECT_NUMBER';
    static final string STRING_SFRECORDID = 'SFRecordId';
    static final string STRING_OBJECTNAME = 'ObjectName';
    static final string STRING_STATUSCODE = 'statusCode';
    static final string STRING_RESPONSEMESSAGE = 'responsetext';
    static final string STRING_OBJECTNAMEQUOTE = 'Quote';
    static final string STRING_OBJECTNAMECONTRACT = 'Contract';
    static final string STRING_OBJECT_CREATE = 'Creation';
    static final string STRING_OBJECT_UPDATE = 'Update';
    static final Integer INT_STATUSCODE200 = 200;
    static final Integer INT_STATUSCODE201 = 201;
    static Exception objException;
    static final List<Integer> LISTINT_SUCCESSCODES = new List<Integer>{INT_STATUSCODE200,INT_STATUSCODE201};
    static List<PMC_CPQ_TransactionLog__c> lstTransactionLogs;

    /** 
     * @description Returns a filtered list of values by parsing through the payload received
     * @param lstObjContainer - Entire payload
     * @return lstFilteredList - Filtered payload
     */
    public static List<Object> getFilteredList(List<Object> lstObjContainer)
    {
        List<Object> lstFilteredList = new List<Object>();
        Set<Object> setFilteredSet = new Set<Object>();

        for(Object objContainer: lstObjContainer)//remove records with duplicate values and keep only values required for futher processing.
        { 
            Map<String,Object> mapCurRecord = (Map<String,Object>) objContainer;
            Map<String,Object> mapNewRecord = new Map<String,Object>();
            mapNewRecord.put(STRING_OBJECTNUMBER,mapCurRecord.get(STRING_OBJECTNUMBER));
            mapNewRecord.put(STRING_SFRECORDID,mapCurRecord.get(STRING_SFRECORDID));
            mapNewRecord.put(STRING_OBJECTNAME,mapCurRecord.get(STRING_OBJECTNAME));
            mapNewRecord.put(STRING_STATUSCODE,mapCurRecord.get(STRING_STATUSCODE));
            mapNewRecord.put(STRING_RESPONSEMESSAGE,mapCurRecord.get(STRING_RESPONSEMESSAGE));
            setFilteredSet.add(mapNewRecord);
        }
        lstFilteredList.addAll(setFilteredSet);
        return lstFilteredList;
    }
    
    public static void getFilteredErrorList(List<Object> lstObjContainer,List<SBQQ__Quote__c> lstQuotes,list<SBQQ__QuoteLine__c> QuoteItemUpdate,String strEndpoint)
    {
        Map<String,String> lstFilteredList = new Map<String,String>();
        Set<Object> setFilteredSet = new Set<Object>();
        Map<String,String> QuoteErrorList = new Map<String,String>();
        Map<String,String> QuoteItemErrorList = new Map<String,String>();
        Set<Id> LstQuoteId = new Set<Id>();
        List<SBQQ__QuoteLine__c> QuoteItemList= new List<SBQQ__QuoteLine__c>();
        
        for(Object objContainer: lstObjContainer)
        { 
            Map<String,Object> mapCurRecord = (Map<String,Object>) objContainer;
            String sfdcitem = (String)mapCurRecord.get('SFDC_ITEM'); 
            String sfrecordid = (String)mapCurRecord.get(STRING_SFRECORDID); 

            if(mapCurRecord.get('TYPE') == 'E'){
                Boolean containsQuote = QuoteErrorList.containsKey(sfrecordid);
                if(!containsQuote){
                    QuoteErrorList.put(sfrecordid,(String)mapCurRecord.get('MESSAGE'));
                }
                LstQuoteId.add(sfrecordid);
                
                // GCPM-5353: Checking if sfdcitem is not null or blank; this can happen when SFDC_ITEM element is not present in the error response from CPI.
                if(!String.isBlank(sfdcitem)) {
                    if(!QuoteItemErrorList.containsKey(sfdcitem)){                    
                        QuoteItemErrorList.put(sfdcitem,(String)mapCurRecord.get('MESSAGE'));
                    }
                }
            }
        }

        If(!QuoteErrorList.isEmpty()){
            for(SBQQ__Quote__c objQuote: lstQuotes){
                // objQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
                // GCPM-5353: Checking if QuoteErrorList contains the quote Id before trying to get the error message to avoid null pointer exception.
                if (QuoteErrorList.containsKey(objQuote.Id)) {
                    objQuote.PMC_CPQ_IntegrationMessage__c = getPrefix(strEndpoint) + QuoteErrorList.get(objQuote.Id).abbreviate(225);
                }
            }
        }
    }
    
    /** 
     * @description Parses through the quote and payload.
     * @param lstQuotes - list of quotes
     * @param lstFilteredList - Filtered payload
     * @param strEndpoint - Interface Endpoint
     */
    public static void parseQuoteContractFilteredList(List<SBQQ__Quote__c> lstQuotes, List<Object> lstFilteredList, String strEndpoint)
    {
        for(SBQQ__Quote__c curQuote: lstQuotes)//parse through filtered list
        {
            Integer intResponseCode;
            String strSAPRefId;
            Integer intCountResponseCodes;
            Set<Integer> setResponseCodes = new Set<Integer>();
            Set<String> setSAPContracts = new Set<String>();
            
            for(Object curObjContainer: lstFilteredList)//parse through filtered list 
            {
                Map<String,Object> mapRecord = (Map<String,Object>)curObjContainer;
                Boolean boolIsCurrentQuote = mapRecord.get(STRING_OBJECTNAME) == STRING_OBJECTNAMEQUOTE && mapRecord.get(STRING_SFRECORDID) == curQuote.Id;
                Boolean boolIsCurrentContract = mapRecord.get(STRING_OBJECTNAME) == STRING_OBJECTNAMECONTRACT && mapRecord.get(STRING_SFRECORDID) == curQuote.Id;
                if(boolIsCurrentQuote)
                {
                    intResponseCode = (Integer) mapRecord.get(STRING_STATUSCODE);
                    setResponseCodes.add(intResponseCode); 
                }
                else if(boolIsCurrentContract)
                {
                    intResponseCode = (Integer) mapRecord.get(STRING_STATUSCODE);
                    setResponseCodes.add(intResponseCode);
                    strSAPRefId = (String) mapRecord.get(STRING_OBJECTNUMBER);
                    setSAPContracts.add(strSAPRefId);   
                } 
            }

            setSAPContracts.remove('');
            String strSAPContracts = string.join(setSAPContracts,',');
            curQuote.PMC_CPQ_SAPContractReference__c = strSAPContracts;
            intCountResponseCodes = setResponseCodes.size();
            setResponseCodes.removeAll(LISTINT_SUCCESSCODES);
            if(setResponseCodes.isEmpty()) //Success Scenario
            {
                curQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSSUCCESS;
                curQuote.PMC_CPQ_IntegrationMessage__c = getPrefix(strEndpoint)+STRING_INTEGRATIONSTATUSSUCCESS;
            }
            else //Error Scenario
            {
                boolTransLogError = true;
                curQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
                curQuote.PMC_CPQ_IntegrationMessage__c = getPrefix(strEndpoint) + getQuoteErrorStatus(intCountResponseCodes,setResponseCodes.size());
            }
        }
    }

    /** 
     * @description Parses through the quote and payload.
     * @param lstQuotes - list of quotes
     * @param lstFilteredList - Filtered payload
     * @param strEndpoint - Interface Endpoint
     */
    public static void parseQuoteContractFilteredList(List<SBQQ__Quote__c> lstQuotes, List<Object> lstFilteredList, String strEndpoint, List<Object> lstObjContainer)
    {
        for(SBQQ__Quote__c curQuote: lstQuotes)//parse through filtered list
        {
            Integer intResponseCode;
            String strSAPRefId;
            Integer intCountResponseCodes;
            Set<Integer> setResponseCodes = new Set<Integer>();
            Set<String> setSAPContracts = new Set<String>();
            Map<String,String> quoteErrorList = new Map<String,String>();
            
            for(Object curObjContainer: lstFilteredList)//parse through filtered list 
            {
                Map<String,Object> mapRecord = (Map<String,Object>)curObjContainer;
                Boolean boolIsCurrentQuote = mapRecord.get(STRING_OBJECTNAME) == STRING_OBJECTNAMEQUOTE && mapRecord.get(STRING_SFRECORDID) == curQuote.Id;
                Boolean boolIsCurrentContract = mapRecord.get(STRING_OBJECTNAME) == STRING_OBJECTNAMECONTRACT && mapRecord.get(STRING_SFRECORDID) == curQuote.Id;
                if(boolIsCurrentQuote)
                {
                    intResponseCode = (Integer) mapRecord.get(STRING_STATUSCODE);
                    setResponseCodes.add(intResponseCode); 
                }
                else if(boolIsCurrentContract)
                {
                    intResponseCode = (Integer) mapRecord.get(STRING_STATUSCODE);
                    setResponseCodes.add(intResponseCode);
                    strSAPRefId = (String) mapRecord.get(STRING_OBJECTNUMBER);
                    setSAPContracts.add(strSAPRefId);   
                } 
            }

            setSAPContracts.remove('');
            String strSAPContracts = string.join(setSAPContracts,',');

            for(Object objContainer: lstObjContainer)
            { 
                Map<String,Object> mapCurRecord = (Map<String,Object>) objContainer;
                String sfdcitem = (String)mapCurRecord.get('SFDC_ITEM'); 
                String sfrecordid = (String)mapCurRecord.get(STRING_SFRECORDID); 

                if(mapCurRecord.get('TYPE') == 'E') {
                    Boolean containsQuote = quoteErrorList.containsKey(sfrecordid);
                    if(!containsQuote){
                        quoteErrorList.put(sfrecordid,(String)mapCurRecord.get('MESSAGE'));
                    }
                }
            }

            if (quoteErrorList.isEmpty() || !quoteErrorList.containsKey(curQuote.Id)) {
                curQuote.PMC_CPQ_SAPContractReference__c = strSAPContracts;
            }

            intCountResponseCodes = setResponseCodes.size();
            setResponseCodes.removeAll(LISTINT_SUCCESSCODES);
            if(setResponseCodes.isEmpty()) //Success Scenario
            {
                curQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSSUCCESS;
                curQuote.PMC_CPQ_IntegrationMessage__c = getPrefix(strEndpoint)+STRING_INTEGRATIONSTATUSSUCCESS;
            }
            else //Error Scenario
            {
                boolTransLogError = true;
                curQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
                curQuote.PMC_CPQ_IntegrationMessage__c = getPrefix(strEndpoint) + getQuoteErrorStatus(intCountResponseCodes,setResponseCodes.size());
            }
        }
    }

    /** 
     * @description Returns whether the quote is Partial Success or Error
     * @param intCountResponseCodes - Count of Response Codes
     * @param intCurCountResponseCodes - Count of Response Codes after removing successful response codes
     * @return STRING_INTEGRATIONSTATUSPARTIALSUCCESS = Partial Success
     * @return STRING_INTEGRATIONSTATUSERROR = Error
     */
    public static String getQuoteErrorStatus(Integer intCountResponseCodes, Integer intCurCountResponseCodes)
    {
        if(intCountResponseCodes != intCurCountResponseCodes)
        {
            return STRING_INTEGRATIONSTATUSPARTIALSUCCESS;
        }
        return STRING_INTEGRATIONSTATUSERROR;
    }
 

     /**
     * @description Returns overall order status
     * @return strIntegrationStatusError - Status = Error
     * @return strIntegrationStatusWarning - Status = Warning
     * @return strIntegrationStatusSuccess - Status = Success 
     */
    public static String getOverallTransactionStatus()
    {
        if(boolTransLogError)
        {
            return (STRING_INTEGRATIONSTATUSERROR);
        }
        return (STRING_INTEGRATIONSTATUSSUCCESS);
    }
    
    /** 
     * @description It returns the prefix for integration message.
     * @param strEndpoint - Integration Endpoint.
     * @return strPrefix - Prefix of Integration Message.
     */
    public Static String getPrefix(String strEndpoint)
    {
        String strPrefix;
        String strInterface = 'SAPQuoteandContractCreate';
        PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(strInterface); 
        String strQuoteAndContractReplicationEndpoint = strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c;
        
        if(strEndpoint == strQuoteAndContractReplicationEndpoint)
        {
            strPrefix = 'Quote/Contract Creation: ';
        }
        else
        {
            strPrefix = 'Contract Update: ';
        }
        return strPrefix;
    }
    
    /** 
     * @description Parses through the response body and populates Integration fields on the quote.
     * @param lstQuotes - List of quotes.
     * @param response - Response received from the endpoint.
     * @param strEndpoint - Endpoint that the HttpRequest will hit.
     */
    public static void parseJSONQuoteContractInterface(List<SBQQ__Quote__c> lstQuotes, HttpResponse response, String strEndpoint)
    {    
        List<Object> lstFilteredList = new List<Object>();
        List<Object> lstObjContainer= new List<Object>();
        String strJSONResponseBody = response.getBody();
        list<SBQQ__QuoteLine__c> QuoteItemUpdate=new list<SBQQ__QuoteLine__c>();
        
        if(LISTINT_SUCCESSCODES.contains(response.getStatusCode()))//status code returned is 200
        {   
            try
            {
                lstObjContainer= (List<Object>) JSON.deserializeUntyped(response.getBody());
                lstFilteredList = getFilteredList(lstObjContainer);//removes duplicate records and non essential values
                parseQuoteContractFilteredList(lstQuotes, lstFilteredList, strEndpoint);
                strTransactionLogStatus = getOverallTransactionStatus();
                if(boolTransLogError){
                       getFilteredErrorList(lstObjContainer,lstQuotes,QuoteItemUpdate,strEndpoint);
                    
                }
            }
            catch(Exception e)//Exception caused due to inablitiy to parse through response.
            {
                strTransactionLogStatus = STRING_INTEGRATIONSTATUSERROR;
                for(SBQQ__Quote__c objQuote: lstQuotes)
                {
                    objQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
                    objQuote.PMC_CPQ_IntegrationMessage__c = getPrefix(strEndpoint)+e.getMessage().abbreviate(225);
                }
            }
        }
        else //status code returned is not 200
        {

            strTransactionLogStatus = STRING_INTEGRATIONSTATUSERROR;
            for(SBQQ__Quote__c objQuote: lstQuotes)
            {
                objQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
                objQuote.PMC_CPQ_IntegrationMessage__c = getPrefix(strEndpoint)+response.getBody().abbreviate(225);
            }
        }
        
        SObjectAccessDecision securityDecisionQuote = Security.stripInaccessible(AccessType.UPDATABLE, lstQuotes);
        Database.update(securityDecisionQuote.getRecords(),false);

       // parseAndUpdateQuoteLineFields(lstObjContainer);


        Map<String, String> mapTransactionLogFields = new Map<String,String>();
        mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',strTransactionLogStatus);
        mapTransactionLogFields.put('PMC_CPQ_InterfaceURL__c',strEndpoint);
        mapTransactionLogFields.put('PMC_CPQ_RequestBody__c',PMC_CPQ_CPIRemoteCalloutUtilityClass.request.getBody());
        mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c',strJSONResponseBody);
        
        if (strTransactionLogStatus == STRING_INTEGRATIONSTATUSERROR) {
        	mapTransactionLogFields = PMC_CPQ_TransactionLogUtilityClass.extractQuoteAndErrorMsg(strJSONResponseBody,
                                                                                            PMC_CPQ_CPIRemoteCalloutUtilityClass.request.getBody(),
                                                                                            mapTransactionLogFields );
        }
        
        lstTransactionLogs = PMC_CPQ_TransactionLogUtilityClass.addTransactionLog(mapTransactionLogFields);
        PMC_CPQ_TransactionLogUtilityClass.insertTransactionLogs(lstTransactionLogs);
    
    }
    /** 
     * @description Updates the status and message for quotes 
     * @param lstQuotes - List of quotes.
     * @param strEndpoint - Integration Endpoint.
     */
    public static void updateQuoteExceptionStatusMsg(List<SBQQ__Quote__c> lstQuotes, String strEndpoint)
    {
        for(SBQQ__Quote__c objQuote: lstQuotes)
        {
            objQuote.PMC_CPQ_IntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
            objQuote.PMC_CPQ_IntegrationMessage__c = getPrefix(strEndpoint)+PMC_CPQ_CPIRemoteCalloutUtilityClass.strExceptionMsg.abbreviate(225);
        }
        SObjectAccessDecision securityDecisionQuote = Security.stripInaccessible(AccessType.UPDATABLE, lstQuotes);
        Database.update(securityDecisionQuote.getRecords(),false);
    }
}