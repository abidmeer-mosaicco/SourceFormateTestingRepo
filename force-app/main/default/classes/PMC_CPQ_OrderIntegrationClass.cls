/** @description This an Order Response parsing class
 *  @author Shefali Dsouza
 *  @storynumber GDASF-8818
 */
public with sharing class PMC_CPQ_OrderIntegrationClass implements Database.AllowsCallouts {
    static HttpRequest request = new HttpRequest();
    static HttpResponse response;
    
    static Boolean boolTransLogSuccess = false;
    static Boolean boolTransLogError = false;
    static String strTransactionLogStatus;
    
    static final String STRING_INTEGRATIONSTATUSERROR = 'Error'; 
    static final String STRING_INTEGRATIONSTATUSSUCCESS = 'Success';
    
    static final String STRING_SAP_ORDERNO = 'OBJ_NUM';
    static final String STRING_SAP_ORDERITEMNO = 'OBJ_ITEM';
    static final String STRING_SF_ORDERID = 'SFOrderId';
    static final String STRING_SF_ORDERLINEID = 'SF_ORDERITEM_ID';
    static final string STRING_STATUSCODE = 'statusCode';
    static final string STRING_RESPONSEMESSAGE = 'responsetext';
    
    static final Integer INT_STATUSCODE200 = 200;
    static final Integer INT_STATUSCODE201 = 201;

    static final List<Integer> LISTINT_SUCCESSCODES = new List<Integer>{INT_STATUSCODE200,INT_STATUSCODE201};
    static List<PMC_CPQ_TransactionLog__c> lstTransactionLogs;
  
    static List<Object> lstFilteredOrderLine = new List<Object>();
    static List<Object> lstFilteredOrder = new List<Object>();
    static List<Object> lstFilteredTransactionStatus = new List<Object>();
    static List<OrderItem> lstOrderLines = new List<OrderItem>();
    
    /** 
     * @description Filters out the duplicate records in response payload to set 3 lists - Order list, Order Line List, Transaction Status List. 
     * @param lstObjContainer - Entire response payload
     */
    public static void setFilteredListOrderOrderLine(List<Object> lstObjContainer)
    {
        Set<Object> setFilteredOrderLine = new Set<Object>();
        Set<Object> setFilteredOrder = new Set<Object>();
        Set<Object> setFilteredTransactionStatus = new Set<Object>();
        
        for(Object objContainer: lstObjContainer)//remove records with duplicate values and keep only values required for further processing.
        { 
            Map<String,Object> mapCurRecord = (Map<String,Object>) objContainer;
            Map<String,Object> mapOrderLineRecord = new Map<String,Object>();
            Map<String,Object> mapOrderRecord = new Map<String,Object>();
            
            //Creating Orderline Record
            mapOrderLineRecord.put(STRING_SAP_ORDERNO,mapCurRecord.get(STRING_SAP_ORDERNO));
            mapOrderLineRecord.put(STRING_SF_ORDERID,mapCurRecord.get(STRING_SF_ORDERID));
            mapOrderLineRecord.put(STRING_SAP_ORDERITEMNO,mapCurRecord.get(STRING_SAP_ORDERITEMNO));
            mapOrderLineRecord.put(STRING_SF_ORDERLINEID,mapCurRecord.get(STRING_SF_ORDERLINEID));
            mapOrderLineRecord.put(STRING_STATUSCODE,mapCurRecord.get(STRING_STATUSCODE));
            mapOrderLineRecord.put(STRING_RESPONSEMESSAGE,mapCurRecord.get(STRING_RESPONSEMESSAGE));
            
            //Creating Order Record
            mapOrderRecord.put(STRING_SF_ORDERID,mapCurRecord.get(STRING_SF_ORDERID));
            mapOrderRecord.put(STRING_SAP_ORDERNO,mapCurRecord.get(STRING_SAP_ORDERNO));
            mapOrderRecord.put(STRING_STATUSCODE,mapCurRecord.get(STRING_STATUSCODE));
            mapOrderRecord.put(STRING_RESPONSEMESSAGE,mapCurRecord.get(STRING_RESPONSEMESSAGE));
            
            setFilteredOrderLine.add(mapOrderLineRecord);
            setFilteredOrder.add(mapOrderRecord);
            setFilteredTransactionStatus.add(mapCurRecord.get(STRING_STATUSCODE));
        }
        lstFilteredOrder.addAll(setFilteredOrder);
        lstFilteredOrderLine.addAll(setFilteredOrderLine);
        lstFilteredTransactionStatus.addAll(setFilteredTransactionStatus);
    }
    
     /** 
     * @description Parses through the filtered order list and sets values on the order record.
     * @param lstOrders - List of Orders
     */
    public static void parseOrderFilteredList(List<Order> lstOrders)
    {
        for(Order objOrder: lstOrders)//parse through orders
        { 
            for(Object objCurrent: lstFilteredOrder)//parse through filtered list order list
            {
                Map<String,Object> mapRecord = (Map<String,Object>)objCurrent;
                Boolean boolIsCurrentOrder = (String)mapRecord.get(STRING_SF_ORDERID) == objOrder.Id;
                if(boolIsCurrentOrder)
                {
                    objOrder.PMC_CPQ_OrderIntegrationMessage__c = (String) mapRecord.get(STRING_RESPONSEMESSAGE);
                    if(String.isBlank((String) mapRecord.get(STRING_SAP_ORDERNO)) == false)
                    {
                        objOrder.PMC_CPQ_OrderIntegrationStatus__c = STRING_INTEGRATIONSTATUSSUCCESS;
                        objOrder.PMC_CPQ_SAPOrderNumber__c = (String) mapRecord.get(STRING_SAP_ORDERNO);                       
                    }
                    else
                    {
                         objOrder.PMC_CPQ_OrderIntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;                      
                    }
                 }
            }
        }
     }
    
    /** 
     * @description Parses through the filtered order line list and sets values on the order line record.
     * @param lstOrderLines - List of Order Lines
     */
    public static void parseOrderLineFilteredList(List<OrderItem> lstOrderLines)
    {   
        for(OrderItem objOrderLine: lstOrderLines)//parse through order lines
        {
            for(Object objCurrent: lstFilteredOrderLine)//parse through filtered order line list 
            {
                Map<String,Object> mapRecord = (Map<String,Object>)objCurrent;
                Boolean boolIsCurrentOrderLine = String.valueOf(mapRecord.get(STRING_SF_ORDERLINEID)) == String.valueOf(objOrderLine.Id);
                if(boolIsCurrentOrderLine)
                {
                    objOrderLine.PMC_CPQ_OrderItemIntegrationMessage__c = (String) mapRecord.get(STRING_RESPONSEMESSAGE);
                    if(String.isBlank((String) mapRecord.get(STRING_SAP_ORDERNO)) == false)
                    {
                        objOrderLine.PMC_CPQ_OrderItemIntegrationStatus__c = STRING_INTEGRATIONSTATUSSUCCESS;
                        objOrderLine.PMC_CPQ_SAPOrderLineID__c = (String) mapRecord.get(STRING_SAP_ORDERNO)+'_'+String.valueOf(mapRecord.get(STRING_SAP_ORDERITEMNO));
                    }
                    else
                    {
                        objOrderLine.PMC_CPQ_OrderItemIntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR; 
                    }
                }
            }
        }
        
    }
  
    /** 
     * @description Parses through the response and takes appropriate actions based on the response status. 
     * @param lstOrders - List of orders.
     * @param response - Response received from the endpoint.
     * @param lstIds - List of order ids.
     */
    public static void parseJSONOrderInterface(List<Order> lstOrders, HttpResponse response, List<Id> lstIds)
    {    
        List<Object> lstObjContainer= new List<Object>();
        String strJSONResponseBody = response.getBody();
		List<OrderItem> lstOrderLines = new List<OrderItem>();
        if(Schema.sObjectType.OrderItem.isAccessible())
        {
			 lstOrderLines = [select Id from OrderItem where OrderId in :lstIds];
        }
        
        String strInterface = 'SAPSalesOrderCreate';
        PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(strInterface); 
        String strOrderReplicationEndpoint = strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c;
        
        if(LISTINT_SUCCESSCODES.contains(response.getStatusCode()))//status code returned is 200
        {   
            try
            {
                lstObjContainer = (List<Object>) JSON.deserializeUntyped(response.getBody());
                setFilteredListOrderOrderLine(lstObjContainer);
                parseOrderFilteredList(lstOrders);
                parseOrderLineFilteredList(lstOrderLines);
                
                if(lstFilteredTransactionStatus.size() == 1 && LISTINT_SUCCESSCODES.contains(Integer.valueOf(lstFilteredTransactionStatus[0])))
                {
					strTransactionLogStatus = STRING_INTEGRATIONSTATUSSUCCESS;                    
                }
                else
                {
                    strTransactionLogStatus = STRING_INTEGRATIONSTATUSERROR; 
                }
            }
            catch(Exception e)//Exception caused due to inablitiy to parse through response.
            {
                strTransactionLogStatus = STRING_INTEGRATIONSTATUSERROR;
                updateOrderandOrderLineErrorExceptionStatusMsg(lstOrders,lstIds,e.getMessage()); 
            }
        }
        else //status code returned is not 200
        {
            strTransactionLogStatus = STRING_INTEGRATIONSTATUSERROR;
            updateOrderandOrderLineErrorExceptionStatusMsg(lstOrders,lstIds,response.getBody()); 
        }
        
        SObjectAccessDecision securityDecisionOrder = Security.stripInaccessible(AccessType.UPDATABLE, lstOrders);
    	Database.update(securityDecisionOrder.getRecords(),false);
        
        SObjectAccessDecision securityDecisionOrderItem = Security.stripInaccessible(AccessType.UPDATABLE, lstOrderLines);
    	Database.update(securityDecisionOrderItem.getRecords(),false);
        
        Map<String, String> mapTransactionLogFields = new Map<String,String>();
        mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',strTransactionLogStatus);
        mapTransactionLogFields.put('PMC_CPQ_InterfaceURL__c',strOrderReplicationEndpoint);
        mapTransactionLogFields.put('PMC_CPQ_RequestBody__c',PMC_CPQ_CPIRemoteCalloutUtilityClass.request.getBody());
        mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c',strJSONResponseBody);

        lstTransactionLogs = PMC_CPQ_TransactionLogUtilityClass.addTransactionLog(mapTransactionLogFields);
        PMC_CPQ_TransactionLogUtilityClass.insertTransactionLogs(lstTransactionLogs);
    }
    
    /** 
     * @description Updates the status and message for orders and order lines.
     * @param lstOrders - List of orders.
     * @param lstIds - List of order ids.
     * @param strMessage - Error or Exception Message.
     */
    public static void updateOrderandOrderLineErrorExceptionStatusMsg(List<Order> lstOrders, List<Id> lstIds, String strMessage)
    {
        List<OrderItem> lstOrderLines = new List<OrderItem>();
        if(Schema.sObjectType.OrderItem.isAccessible())
        {
			 lstOrderLines = [select Id from OrderItem where OrderId in :lstIds];
        }
        for(Order objOrder: lstOrders)
        {
            objOrder.PMC_CPQ_OrderIntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
            objOrder.PMC_CPQ_OrderIntegrationMessage__c = strMessage;
        }
        for(OrderItem objOrderLine: lstOrderLines)
        {
            objOrderLine.PMC_CPQ_OrderItemIntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
            objOrderLine.PMC_CPQ_OrderItemIntegrationMessage__c = strMessage;
        }

        SObjectAccessDecision securityDecisionOrder = Security.stripInaccessible(AccessType.UPDATABLE, lstOrders);
        Database.update(securityDecisionOrder.getRecords(),false);
        
        SObjectAccessDecision securityDecisionOrderItem = Security.stripInaccessible(AccessType.UPDATABLE, lstOrderLines);
    	Database.update(securityDecisionOrderItem.getRecords(),false);
    }
    
}