/** @description Controller Class for Send Final Price to SAP on Order Detail Page
 *  @creator Prakhar
 *  @storynumber GDASF-12488
 */

public with sharing class PMC_CPQ_FPDActionClass implements Queueable, Database.AllowsCallouts {
	public Id orderItemId;
	public OrderItem objOrdItm = new OrderItem();
	public List<OrderItem> lstOrderPrd;
	static String strInterface = 'SendFPD';
	static final Integer INT_STATUSCODE200 = 200;
	static final Integer INT_STATUSCODE201 = 201;
	static final List<Integer> LISTINT_SUCCESSCODES = new List<Integer>{ INT_STATUSCODE200, INT_STATUSCODE201 };
	public boolean massFPDUI = false;

	/** @description Constructor of the class which is used to intialize variables using parameter.
	 *  @param controller : Standard Controller Object
	 */
	public PMC_CPQ_FPDActionClass(ApexPages.StandardController controller) {
		orderItemId = controller.getId();
		objOrdItm = (OrderItem) controller.getRecord();
	}
	/** @description Constructor of the class which is used to intialize variables using parameter.
	 *  @param lstOrderItmm - List of Orderitem records
	 *  @param massFPD - variable to identify if callout is from order detail page/mass fpd UI
	 */
	public PMC_CPQ_FPDActionClass(List<OrderItem> lstOrderItmm, Boolean massFPD) {
		this.lstOrderPrd = lstOrderItmm;
		this.massFPDUI = massFPD;
	}

	/** @description Constructor of the class which is used to intialize variables using parameter.
	 *  @param context : Queueable job
	 */
	public void execute(QueueableContext context) {
		// Make Request for FPD Interface
		try {
			PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(strInterface);
			String strEndpoint = strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c;

			List<Id> lstIds = new List<Id>();
			for (OrderItem objCur : lstOrderPrd) {
				lstIds.add(objCur.Id);
			}
			String request = PMC_CPQ_CPIRemoteCalloutUtilityClass.createMinimalPayload(lstIds);

			// Response from the FPD Interface
			HttpResponse response = PMC_CPQ_CPIRemoteCalloutUtilityClass.sendCalloutRequest(
				'POST',
				'callout:PMC_CPQ_NamedCredential' + strEndpoint,
				request
			);
			// Response parsing
			if (response != null) {
				if (LISTINT_SUCCESSCODES.contains(response.getStatusCode())) {
					PMC_CPQ_SendPriceFPDResponseParsing.parseSAPDetail(lstOrderPrd, response, massFPDUI);
				} else {
					PMC_CPQ_SendPriceFPDResponseParsing.parseSAPErrorDetail(lstOrderPrd, response, massFPDUI);
				}
			} else {
				Boolean boolRetry = PMC_CPQ_CPIRemoteCalloutUtilityClass.autoRetryQueueableApex(
					AsyncInfo.getCurrentQueueableStackDepth(),
					PMC_CPQ_CPIRemoteCalloutUtilityClass.strExceptionMsg
				);
				PMC_CPQ_SendPriceFPDResponseParsing.updateLinesOnException(lstOrderPrd);
				if (massFPDUI && !boolRetry) {
					PMC_CPQ_SendPriceFPDResponseParsing.publishToFPDPlatformEvent(lstOrderPrd, 'Error', strEndpoint);
				}
				if (boolRetry) {
					System.enqueueJob(new PMC_CPQ_FPDActionClass(lstOrderPrd, massFPDUI), 1);
				}
			}
		} catch (Exception e) {
			PMC_ErrorLogClass.processException(e);
		}
	}

	/** @description Method that returns to the Order detail Page
	 *  @return PageReference of the Order Page
	 */
	public PageReference redirect() {
		try {
			// Query the OrderItem with a more specific filter
			List<OrderItem> orderItems = [
				SELECT Id, OrderId, PMC_CPQ_FinalAgreedPrice__c, Agreed_Final_Price__c, ApprovalStatus__c,PMC_CPQ_ReasonOfRejectionOfItem__c
				FROM OrderItem
				WHERE Id = :objOrdItm.Id AND Agreed_Final_Price__c != NULL
				LIMIT 1
			];

			// Check if order item exists with required price
			if (orderItems.isEmpty()) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.PMC_CPQ_FPDtoSAP_Error_Message));
				return null;
			}

			OrderItem targetItem = orderItems[0];
            
            /*Start GCPM-5209*/
            if (String.isNotBlank(targetItem.PMC_CPQ_ReasonOfRejectionOfItem__c)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This order line is rejected. If you wish to price this line, you need to remove the rejection in SAP and allow the integration to update this record before proceeding'));
                return null;
            }
            /*End GCPM-5209*/

			// Prepare and send data to SAP
			PMC_CPQ_OrderProductDetailsWrapperClass wrapper = new PMC_CPQ_OrderProductDetailsWrapperClass();
			wrapper.customId = objOrdItm.Id;
			wrapper.finalAgreedPrice = targetItem.Agreed_Final_Price__c;

			String message = PMC_CPQ_sendFPDOrderProductsSAPClass.saveOPFromUI(
				JSON.serialize(new List<PMC_CPQ_OrderProductDetailsWrapperClass>{ wrapper }),
				'Send Final Price to SAP: RecordPage button click.'
			);

			if (String.isBlank(message)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'The Order Line record has been auto approved.'));
				ApexPages.addMessage(
					new ApexPages.Message(
						ApexPages.Severity.CONFIRM,
						'The integration with SAP is Running, it may take up to 5 minutes, the record integration status will be updated.'
					)
				);
			} else if (message.startsWith('Error')) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
			} else {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, message));
			}
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An unexpected error occurred: ' + e.getMessage()));
		}
		return null;
	}

	/** @description Method that sends FPD updates to SAP in bulk.
	 * @param lstOrderIt : List of Order Lines.
	 * @return null
	 */
	public List<OrderItem> bulkSendFPDtoSAPRequest(List<OrderItem> lstOrderIt) {
		massFPDUI = true;
		System.enqueueJob(new PMC_CPQ_FPDActionClass(lstOrderIt, massFPDUI));
		return lstOrderIt;
	}
	/** @description Method that returns to the Order detail Page
	 *  @return PageReference of the Order Page
	 */
	public PageReference goBack() {
		return new PageReference('/' + orderItemId);
	}
}