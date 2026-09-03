/**
* @description This class will be used to make callouts to the Product Creation/Update/Extension interface of CPI
* @author Gideoni Silva
*/
public class PMC_CPI_ProductActionClass implements Queueable, Database.AllowsCallouts {
	
    public Product2 EffectiveProduct;
    public List<Id> lstIds;
    public List<Object> ProductParameters;
    public ID strProductId;
    static final String STRING_INTERFACE = 'MasterDataMatmas_Clfmas';
    static final String STRING_INTEGRATIONSTATUSERROR = 'Error';
    static final String STRING_NAMEDCREDENTIALS = 'callout:PMC_CPQ_NamedCredential';
    static final String STRING_METHOD = 'POST';
    static List<PMC_CPQ_TransactionLog__c> lstTransactionLogs = new List<PMC_CPQ_TransactionLog__c>();
    
    /** 
     * @description Constructor of the class. 
     * @param strProductId - id of product sent from the flow.
     */
    public PMC_CPI_ProductActionClass(Product2 EffectiveProduct, List<Id> lstIds) {
            this.EffectiveProduct = EffectiveProduct; 
            this.lstIds = lstIds;
    }
    
    /** 
     * @description This is the apex action that will be invoked from the flow.
     * @param lstIds - list of IDs sent from the flow.
     */
    @InvocableMethod(label='CPI Material Creation/Extension Remote Action' description='Triggers the CPI Interface to create Material records in SAP' category='Product2')
    public static void postInfoToCPI(List<ProductActionRequest> ProductParameters) {
        Product2 EffectiveProduct = ProductParameters[0].inputProduct;
		system.debug(EffectiveProduct.id);                
        List<Id> lstIds = new List<Id>();
        lstIds.add(EffectiveProduct.Id);

       	System.enqueueJob(new PMC_CPI_ProductActionClass(EffectiveProduct, lstIds));
    }

    /** 
     * @description Makes a request to callout class.
     * @param context - Receives the context of the flow. In this case it is the list of accounts.
     */
    public void execute(QueueableContext context) {		
        PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(STRING_INTERFACE); 
        String strEndpoint = strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c;
        String strCalloutEndpoint = STRING_NAMEDCREDENTIALS+strEndpoint;
        String strSerializedBody;

        strSerializedBody = PMC_CPI_ProductCalloutUtilityClass.createProductPayload(EffectiveProduct.Id);
        system.debug(strSerializedBody);
        
        HttpResponse response = PMC_CPI_ProductCalloutUtilityClass.sendCalloutRequest(STRING_METHOD, strCalloutEndpoint, strSerializedBody);
		system.debug(response.getBody());
        if(response != null)
        {
            PMC_CPI_ProductIntegrationClass.parseXMLProductInterface(EffectiveProduct, response, strEndpoint);
        }
        else
        {   
            Boolean boolRetry = PMC_CPI_ProductCalloutUtilityClass.autoRetryQueueableApex(AsyncInfo.getCurrentQueueableStackDepth(),PMC_CPI_ProductCalloutUtilityClass.strExceptionMsg);
            PMC_CPI_ProductIntegrationClass.updateProductExceptionStatusMsg(EffectiveProduct, strEndpoint); 
            
            if(boolRetry)
            {
                System.enqueueJob(new PMC_CPI_ProductActionClass(EffectiveProduct, lstIds));
            } 
        }
    }

    public class ProductActionRequest {
        @InvocableVariable(required=true)
        public Product2 inputProduct;
    	}
}