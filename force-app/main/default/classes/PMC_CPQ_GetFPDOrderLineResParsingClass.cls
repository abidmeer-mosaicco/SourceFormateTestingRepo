/** @description OrderLine Response parsing class for Get FPD Price from Pricefx.
 *  @author Shefali Dsouza
 *  @storynumber GDASF-9360
 */

public without sharing class PMC_CPQ_GetFPDOrderLineResParsingClass {
	static HttpRequest request = new HttpRequest();
	static HttpResponse response;
	public static String strTransactionLogStatus;

	static final String STRING_INTEGRATIONSTATUSSUCCESS = 'Success';
	static final String STRING_INTEGRATIONSTATUSERROR = 'Error';
	static final String STRING_INTEGRATIONSTATUSPARTIALSUCCESS = 'Partial Success';

	static final String STRING_SF_ORDERLINEID = 'OrderItemId';
	static final string STRING_STATUSCODE = 'statusCode';
	static final string STRING_RESPONSEMESSAGE = 'ErrorMessage';
	static final string STRING_PRICEFXCOST = 'ListPrice';
	static final string STRING_FLOOR_PRICE = 'FloorPrice';
	static final string STRING_CEILING_PRICE = 'CeilingPrice';
	static final string STRING_INTEGRATIONSTATUS = 'Status';
	static final string STRING_INTEGRATIONMSGPREFIX = 'Get FPD Price: ';

	static final Integer INT_STATUSCODE200 = 200;
	static final Integer INT_STATUSCODE201 = 201;

	static final List<Integer> LISTINT_SUCCESSCODES = new List<Integer>{ INT_STATUSCODE200, INT_STATUSCODE201 };
	static List<PMC_CPQ_TransactionLog__c> lstTransactionLogs;

	static List<Object> lstFilteredOrderLine = new List<Object>();
	static List<Object> lstFilteredOrder = new List<Object>();
	static List<Object> lstFilteredTransactionStatus = new List<Object>();
	static List<OrderItem> lstOrderLines = new List<OrderItem>();

	public static String strExceptionMsg;

	/**
	 * @description Filters out the duplicate records in response payload to set 2 lists - Order Line List, Transaction Status List.
	 * @param lstObjContainer - Entire response payload
	 */
	public static void setFilteredListOrderLine(List<Object> lstObjContainer) {
		Set<Object> setFilteredOrderLine = new Set<Object>();
		Set<Object> setFilteredTransactionStatus = new Set<Object>();

		for (Object objContainer : lstObjContainer) {
			//remove records with duplicate values and keep only values required for further processing.
			Map<String, Object> mapCurRecord = (Map<String, Object>) objContainer;
			Map<String, Object> mapOrderLineRecord = new Map<String, Object>();

			//Creating Orderline Record
			mapOrderLineRecord.put(STRING_SF_ORDERLINEID, mapCurRecord.get(STRING_SF_ORDERLINEID));
			mapOrderLineRecord.put(STRING_PRICEFXCOST, mapCurRecord.get(STRING_PRICEFXCOST));
			mapOrderLineRecord.put(STRING_FLOOR_PRICE, mapCurRecord.get(STRING_FLOOR_PRICE));
			mapOrderLineRecord.put(STRING_CEILING_PRICE, mapCurRecord.get(STRING_CEILING_PRICE));
			mapOrderLineRecord.put(STRING_INTEGRATIONSTATUS, mapCurRecord.get(STRING_INTEGRATIONSTATUS));
			mapOrderLineRecord.put(STRING_RESPONSEMESSAGE, mapCurRecord.get(STRING_RESPONSEMESSAGE));

			setFilteredOrderLine.add(mapOrderLineRecord);
			setFilteredTransactionStatus.add(mapCurRecord.get(STRING_INTEGRATIONSTATUS));
		}
		lstFilteredOrderLine.addAll(setFilteredOrderLine);
		lstFilteredTransactionStatus.addAll(setFilteredTransactionStatus);
	}
	/**
	 * @description Parses through the filtered order line list and sets values on the order line record.
	 * @param lstOrderLines - List of Order Lines
	 * @return i - the counter variable of the number of success lines in the response
	 */
	public static Integer parseOrderLineFilteredList(List<OrderItem> lstOrderLines) {
		Integer i = 0;
		for (OrderItem objOrderLine : lstOrderLines) {
			//parse through order lines
			for (Object objCurrent : lstFilteredOrderLine) {
				//parse through filtered order line list
				Map<String, Object> mapRecord = (Map<String, Object>) objCurrent;
				Boolean boolIsCurrentOrderLine = String.valueOf(mapRecord.get(STRING_SF_ORDERLINEID)) == String.valueOf(objOrderLine.Id);
				if (boolIsCurrentOrderLine) {
					objOrderLine.PMC_CPQ_OrderItemIntegrationMessage__c =
						STRING_INTEGRATIONMSGPREFIX + (String) mapRecord.get(STRING_RESPONSEMESSAGE);
					if ((String) mapRecord.get(STRING_INTEGRATIONSTATUS) == STRING_INTEGRATIONSTATUSSUCCESS) {
						objOrderLine.PMC_CPQ_OrderItemIntegrationMessage__c = STRING_INTEGRATIONMSGPREFIX + STRING_INTEGRATIONSTATUSSUCCESS;
						objOrderLine.PMC_CPQ_OrderItemIntegrationStatus__c = STRING_INTEGRATIONSTATUSSUCCESS;
						i++;
					} else {
						objOrderLine.PMC_CPQ_OrderItemIntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
					}
					//objOrderLine.PMC_CPQ_OrderItemIntegrationStatus__c = (String) mapRecord.get(STRING_INTEGRATIONSTATUS);
					//Commenting the below line as part of GDASF-16764 - 31-Oct
					//objOrderLine.PMC_CPQ_FinalAgreedPrice__c = (Double) mapRecord.get(STRING_PRICEFXCOST);
					objOrderLine.PMC_CPQ_FPDPricefromPriceFx__c = (Double) mapRecord.get(STRING_PRICEFXCOST);
					objOrderLine.PMC_CPQ_Floorprice__c = (Double) mapRecord.get(STRING_FLOOR_PRICE);
					objOrderLine.PMC_CPQ_PriceGuidanceCeiling__c = (Double) mapRecord.get(STRING_CEILING_PRICE);
				}
			}
		}
		return i;
	}

	/**
	 * @description Parses through the response and takes appropriate actions based on the response status.
	 * @param lstOrderLines - List of orders lines
	 * @param response - Response received from the endpoint.
	 * @param fromMassFPDUI - boolean variable to check if called from detail page/massfpdUI
	 */
	public static void parseJSONOrderLineInterface(List<OrderItem> lstOrderLines, HttpResponse response, Boolean fromMassFPDUI) {
		List<Object> lstObjContainer = new List<Object>();
		String strJSONResponseBody = response.getBody();

		String strInterface = 'ToPriceFxFPD';
		PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(strInterface);
		String strOrderReplicationEndpoint = strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c;

		if (LISTINT_SUCCESSCODES.contains(response.getStatusCode())) {
			//status code returned is 200
			try {
				lstObjContainer = (List<Object>) JSON.deserializeUntyped(response.getBody());
				setFilteredListOrderLine(lstObjContainer);
				Integer i = parseOrderLineFilteredList(lstOrderLines);
				strTransactionLogStatus = ((i < lstObjContainer.size())
					? ((i == 0) ? STRING_INTEGRATIONSTATUSERROR : STRING_INTEGRATIONSTATUSPARTIALSUCCESS)
					: STRING_INTEGRATIONSTATUSSUCCESS);
			} catch (Exception e) {
				//Exception caused due to inablitiy to parse through response.
				strTransactionLogStatus = STRING_INTEGRATIONSTATUSERROR;
				strExceptionMsg = e.getMessage();
				updateOrderLineErrorExceptionStatusMsg(lstOrderLines, e.getMessage());
			}
		} else {
			//status code returned is not 200
			strTransactionLogStatus = STRING_INTEGRATIONSTATUSERROR;
			updateOrderLineErrorExceptionStatusMsg(lstOrderLines, response.getBody());
		}

		//SObjectAccessDecision securityDecisionOrderItem = Security.stripInaccessible(AccessType.UPDATABLE, lstOrderLines);
		List<Database.SaveResult> srList = Database.update(lstOrderLines, false);
		for (Database.SaveResult sr : srList) {
			if (!sr.isSuccess()) {
				// Operation failed, get all errors
				for (Database.Error err : sr.getErrors()) {
					System.debug('Error: ' + err.getStatusCode() + ' - ' + err.getMessage());
					System.debug('Fields affected: ' + err.getFields());
				}
			}
		}

		Map<String, String> mapTransactionLogFields = new Map<String, String>();
		mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c', strTransactionLogStatus);
		mapTransactionLogFields.put('PMC_CPQ_InterfaceURL__c', strOrderReplicationEndpoint);
		mapTransactionLogFields.put('PMC_CPQ_RequestBody__c', PMC_CPQ_CPIRemoteCalloutUtilityClass.request.getBody());
		mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c', strJSONResponseBody.abbreviate(131060));

		lstTransactionLogs = PMC_CPQ_TransactionLogUtilityClass.addTransactionLog(mapTransactionLogFields);
		PMC_CPQ_TransactionLogUtilityClass.insertTransactionLogs(lstTransactionLogs);
		if (fromMassFPDUI) {
			//Call this method to publish the platform event with the FPD Price and Integration Status
			PMC_CPQ_SendPriceFPDResponseParsing.publishToFPDPlatformEvent(lstOrderLines, strTransactionLogStatus, strOrderReplicationEndpoint);
		}
	}

	/**
	 * @description Updates the status and message for order lines.
	 * @param lstOrderLines - List of order lines.
	 * @param strMessage - Error or Exception Message.
	 */
	public static void updateOrderLineErrorExceptionStatusMsg(List<OrderItem> lstOrderLines, String strMessage) {
		for (OrderItem objOrderLine : lstOrderLines) {
			objOrderLine.PMC_CPQ_OrderItemIntegrationStatus__c = STRING_INTEGRATIONSTATUSERROR;
			objOrderLine.PMC_CPQ_OrderItemIntegrationMessage__c = STRING_INTEGRATIONMSGPREFIX + strMessage;
		}
		if (strMessage == PMC_CPQ_CPIRemoteCalloutUtilityClass.strExceptionMsg) {
			SObjectAccessDecision securityDecisionOrderItem = Security.stripInaccessible(AccessType.UPDATABLE, lstOrderLines);
			Database.update(securityDecisionOrderItem.getRecords(), false);
		}
	}
}