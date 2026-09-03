/** @description This class will be used to fetch list price from Pricefx for FPD.
 *  @author Shefali Dsouza
 *  @storynumber GDASF-9360
 */

public without sharing class PMC_CPQ_GetFPDController implements Queueable, Database.AllowsCallouts {
	public Id orderItemId;
	public OrderItem objOrderItem = new OrderItem();
	public List<OrderItem> lstOrderItems = new List<OrderItem>();
	public boolean massFPDUI = false;

	/** @description Constructor of the class which is used to intialize variables using parameter.
	 *  @param controller : Standard Controller Object
	 */
	public PMC_CPQ_GetFPDController(ApexPages.StandardController controller) {
		orderItemId = controller.getId();
		objOrderItem = (OrderItem) controller.getRecord();
	}

	/** @description Constructor of the class which is used to intialize variables using parameter.
	 *  @param lstOrderItems - List of Order line items
	 *  @param massFPD - variable to identify if callout is from order detail page/mass fpd UI
	 */
	public PMC_CPQ_GetFPDController(List<OrderItem> lstOrderItems, Boolean massFPD) {
		this.lstOrderItems = lstOrderItems;
		this.massFPDUI = massFPD;
	}

	/** @description Constructor of the class which is used to intialize variables using parameter. This is for anync call.
	 *  @param context : Context of the queueable job.
	 */
	public void execute(QueueableContext context) {
		final String strInterface = 'ToPriceFxFPD';
		final String strNamedCredentials = 'callout:PMC_CPQ_NamedCredential';
		final String strMethod = 'POST';

		List<Id> lstIds = new List<Id>();

		for (OrderItem objCur : lstOrderItems) {
			lstIds.add(objCur.Id);
		}

		PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(strInterface);
		String strEndpoint = strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c;
		String strCalloutEndpoint = strNamedCredentials + strEndpoint;

		String strSerializedBody = PMC_CPQ_CPIRemoteCalloutUtilityClass.createMinimalPayload(lstIds);
		HttpResponse response = PMC_CPQ_CPIRemoteCalloutUtilityClass.sendCalloutRequest(strMethod, strCalloutEndpoint, strSerializedBody);

		if (response == null) {
			Boolean boolRetry = PMC_CPQ_CPIRemoteCalloutUtilityClass.autoRetryQueueableApex(
				AsyncInfo.getCurrentQueueableStackDepth(),
				PMC_CPQ_GetFPDOrderLineResParsingClass.strExceptionMsg
			);
			PMC_CPQ_GetFPDOrderLineResParsingClass.updateOrderLineErrorExceptionStatusMsg(
				lstOrderItems,
				PMC_CPQ_CPIRemoteCalloutUtilityClass.strExceptionMsg
			);
			if (massFPDUI && !boolRetry) {
				PMC_CPQ_SendPriceFPDResponseParsing.publishToFPDPlatformEvent(lstOrderItems, 'Error', strEndpoint);
			}
			if (boolRetry) {
				System.enqueueJob(new PMC_CPQ_GetFPDController(lstOrderItems, massFPDUI), 1);
			}
		} else {
			PMC_CPQ_GetFPDOrderLineResParsingClass.parseJSONOrderLineInterface(lstOrderItems, response, massFPDUI);
		}
	}

	/** @description Method that returns to the Order detail Page
	 *  @return PageReference of the Order Page
	 */
	public PageReference redirect() {
        /** start -> GCPM-5209*/
        OrderItem currentItem = [SELECT Id, PMC_CPQ_ReasonOfRejectionOfItem__c FROM OrderItem WHERE Id = :orderItemId LIMIT 1];
        if (String.isNotBlank(currentItem.PMC_CPQ_ReasonOfRejectionOfItem__c)) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                'This order line is rejected. If you wish to price this line, you need to remove the rejection in SAP and allow the integration to update this record before proceeding'
            ));
            // Return null to stay on the same page and display the error message
            return null;
        }
        /** End -> GCPM-5209*/
        
		lstOrderItems.add(objOrderItem);
		System.enqueueJob(new PMC_CPQ_GetFPDController(lstOrderItems, massFPDUI));

		return new PageReference('/' + orderItemId);
	}

	/** @description Method that fetches FPD info from Pricefx in bulk.
	 *  @param lstOrderItems : List of Order Lines.
	 *  @return null
	 */
	public List<OrderItem> bulkGetFPDRequest(List<OrderItem> lstOrderItems) {
		this.lstOrderItems = lstOrderItems;
		massFPDUI = true;
		System.enqueueJob(new PMC_CPQ_GetFPDController(lstOrderItems, massFPDUI));
		return lstOrderItems;
	}
}