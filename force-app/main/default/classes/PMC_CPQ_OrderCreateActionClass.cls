/** @description This class will be used to make callouts to the Order Creation interface of CPI. Orders will be pushed from SF to SAP. 
 *  @author Shefali Dsouza
 *  @storynumber GDASF-8818
 */
public class PMC_CPQ_OrderCreateActionClass implements Queueable, Database.AllowsCallouts{   
	public List<Order> lstOrders;
    public List<Id> lstIds;
    
    static final String STRING_INTERFACE = 'SAPSalesOrderCreate';
    static final String STRING_NAMEDCREDENTIALS = 'callout:PMC_CPQ_NamedCredential';
    static final String STRING_METHOD = 'POST';
    
     /** 
     * @description Constructor of the class. 
     * @param lstOrders - List of orders sent from the flow.
     * @param lstIds - List of order ids.
     */
    public PMC_CPQ_OrderCreateActionClass(List<Order> lstOrders, List<Id> lstIds)
    {
        this.lstOrders = lstOrders; 
        this.lstIds = lstIds;
    }
    
    /** 
     * @description This is the apex action that will be invoked from the flow.
     * @param lstOrders - List of orders sent from the flow.
     */
	@InvocableMethod(label='Order Create Remote Action' description='Triggers the CPI Interface to create order and order line records in SAP' category='Order')
  	public static void postInfoToCPI(List<Order> lstOrders){
   		List<Id> lstIds = new List<Id>();
        
        for(Order objOrder: lstOrders)
        {
            lstIds.add(objOrder.Id);
        }
       System.enqueueJob(new PMC_CPQ_OrderCreateActionClass(lstOrders,lstIds));
    }
    
    /** 
     * @description Governs the overall flow of the Order Request, Response, Transaction and Error Log Generation.
     * @param context - Receives the context of the flow. In this case it is the list of orders.
     */
    public void execute(QueueableContext context)
    {
		PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(STRING_INTERFACE); 
        String strEndpoint = strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c;
        String strCalloutEndpoint = STRING_NAMEDCREDENTIALS+strEndpoint;
        
        String strSerializedBody = PMC_CPQ_CPIRemoteCalloutUtilityClass.createMinimalPayload(lstIds);
        HttpResponse response = PMC_CPQ_CPIRemoteCalloutUtilityClass.sendCalloutRequest(STRING_METHOD, strCalloutEndpoint, strSerializedBody);
        
        if(response != null)
        {
            PMC_CPQ_OrderIntegrationClass.parseJSONOrderInterface(lstOrders,response,lstIds);
        }
        else
        {
            Boolean boolRetry = PMC_CPQ_CPIRemoteCalloutUtilityClass.autoRetryQueueableApex(AsyncInfo.getCurrentQueueableStackDepth(),PMC_CPQ_CPIRemoteCalloutUtilityClass.strExceptionMsg);
            PMC_CPQ_OrderIntegrationClass.updateOrderandOrderLineErrorExceptionStatusMsg(lstOrders,lstIds,PMC_CPQ_CPIRemoteCalloutUtilityClass.strExceptionMsg); 
            
            if(boolRetry)
            {
                System.enqueueJob(new PMC_CPQ_OrderCreateActionClass(lstOrders,lstIds), 1);
            } 
        }
    }
}