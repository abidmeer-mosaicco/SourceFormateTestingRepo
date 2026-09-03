/**
 * @description This class will be used as a controller for fpdMassUpdate lightning web component.
 * @author Ridhu Varshini M
 * @storynumber GDASF-12110
 */
public with sharing class PMC_CPQ_FPDMassUpdateController {
	/**
	 * @description This method is to send the list of order products based on the account id or user id received from lWC component
	 * @param paramsVar - Wrapper class containing parameters (acctId, userId, prodId, shipId)
	 * @return jsonString - the list of order product details contained in the wrapper class
	 */
	@AuraEnabled(cacheable=false)
	public static String getOPDetails(String paramsVar) {
		GetOPDetailsParams params = (GetOPDetailsParams) JSON.deserialize(paramsVar, GetOPDetailsParams.class);
		Id acctId = params.acctId;
		Id userId = params.userId;
		Id prodId = params.prodId;
		Id shipId = params.shipId;
		Id ordId = params.ordId;
		String approvedStr = 'Approved'; //For US GCPM - 2396
		List<OrderItem> lstFPD = [
			SELECT Id
			FROM OrderItem
			WHERE
				SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c IN ('FPD', 'FPD Ex-Space')
				OR PMC_CPQ_ContractType__c IN ('FPD', 'FPD Ex-Space')
			WITH SECURITY_ENFORCED
		];
		List<OrderItem> lstOP = new List<OrderItem>();
		String igStatus;
		igStatus = 'Error';
		if (!lstFPD.isEmpty()) {
			// String query = 'SELECT Id, OrderItemNumber, PMC_CPQ_SAPOrderLineID__c, Order.OrderNumber, SBQQ__Contract__r.PMC_CPQ_ContractNumberIdentifier__c, PMC_CPQ_LinePONumber__c, PMC_CPQ_ShipTo__r.Name, Order.Account.Name, Product2.Name, Quantity, PMC_CPQ_PricingDate__c, PMC_CPQ_FPDPricefromPriceFx__c, PMC_CPQ_FinalAgreedPrice__c, PMC_CPQ_OrderLineStatus__c, PMC_CPQ_OrderItemIntegrationStatus__c,PMC_CPQ_OrderItemIntegrationMessage__c,Order.PMC_CPQ_SAPOrderNumber__c FROM OrderItem WHERE Id IN: lstFPD AND  (PMC_CPQ_FinalAgreedPrice__c = Null OR PMC_CPQ_FinalAgreedPrice__c = 0 OR PMC_CPQ_OrderItemIntegrationStatus__c =: igStatus )';
			String query = 'SELECT Id, OrderItemNumber, PMC_CPQ_ReasonOfRejectionOfItem__c, ApprovalStatus__c, PMC_CPQ_SAPOrderLineID__c, Order.OrderNumber, SBQQ__Contract__r.PMC_CPQ_ContractNumberIdentifier__c, PMC_CPQ_LinePONumber__c, PMC_CPQ_ShipTo__r.Name, Order.Account.Name, Product2.Name, Quantity, PMC_CPQ_PricingDate__c, PMC_CPQ_FPDPricefromPriceFx__c, PMC_CPQ_FinalAgreedPrice__c, PMC_CPQ_OrderLineStatus__c, PMC_CPQ_OrderItemIntegrationStatus__c,PMC_CPQ_OrderItemIntegrationMessage__c,Order.PMC_CPQ_SAPOrderNumber__c, PMC_CPQ_EstFreightPrice__c FROM OrderItem WHERE Id IN: lstFPD AND  ((PMC_CPQ_FinalAgreedPrice__c > 0 AND ApprovalStatus__c != : approvedStr) OR PMC_CPQ_FinalAgreedPrice__c = Null OR PMC_CPQ_FinalAgreedPrice__c = 0 OR PMC_CPQ_OrderItemIntegrationStatus__c =: igStatus )';
			if (acctId != null) {
				query += ' AND Order.AccountId = :acctId';
			}
			if (userId != null) {
				query += ' AND Order.OwnerId = :userId';
			}
			if (prodId != null) {
				query += ' AND Product2Id = :prodId';
			}
			if (shipId != null) {
				query += ' AND PMC_CPQ_ShipTo__c = :shipId';
			}
			if (ordId != null) {
				query += ' AND (OrderId = : ordId OR Order.PMC_CPQ_SAPOrderNumber__c =: ordId) ';
			}
			lstOP = Database.query(String.escapeSingleQuotes(query));
			lstOP = Database.query(String.escapeSingleQuotes(query));

			// Newly Added here .
			Map<long, OrderItem> OrderItemMap = new Map<long, OrderItem>();
			List<long> numericValues = new List<long>();

			for (OrderItem ordItem : lstOP) {
				if (ordItem.PMC_CPQ_SAPOrderLineID__c != null) {
					System.debug(ordItem.PMC_CPQ_SAPOrderLineID__c);
					String data = ordItem.PMC_CPQ_SAPOrderLineID__c;
					String[] parts = data.split('_'); // Split the string by the underscore
					String result = parts[0] + parts[1]; // Concatenate the parts
					System.debug(result); // Outputs '3000022552014'
					Long numericVal = Long.valueof(result);
					System.debug(numericVal);

					OrderItemMap.put(numericVal, ordItem);
					numericValues.add(numericVal); // 12345_222 ==> 12345222
				}
			}
			System.debug('OrderItemMap::  ' + OrderItemMap);
			System.debug(lstOP.size());
			// Sort the numeric values
			numericValues.sort();
			System.debug(numericValues);
			List<OrderItem> sortedOrderItem = new List<OrderItem>();
			for (long value : numericValues) {
				sortedOrderItem.add(OrderItemMap.get(value));
			}
			System.debug('Sorted sortedOrderItem: ' + sortedOrderItem);
			// For showing Null values
			for (OrderItem ordItem : lstOP) {
				if (ordItem.PMC_CPQ_SAPOrderLineID__c == null) {
					sortedOrderItem.add(ordItem);
				}
			}
			lstOP = sortedOrderItem;
			System.debug(lstOP.size());
			// Newly code ended here.
		}
		List<PMC_CPQ_OrderProductDetailsWrapperClass> opDetailsWrapperList = new List<PMC_CPQ_OrderProductDetailsWrapperClass>();
		for (OrderItem cObj : lstOP) {
			PMC_CPQ_OrderProductDetailsWrapperClass opWrapper = new PMC_CPQ_OrderProductDetailsWrapperClass();
			opWrapper.customId = cObj.Id;
			opWrapper.orderLine = cObj.OrderItemNumber;
			opWrapper.accountName = cObj.Order.Account.Name;
			opWrapper.productName = cObj.Product2.Name;
			opWrapper.quantity = cObj.Quantity;
			opWrapper.priceByDate = cObj.PMC_CPQ_PricingDate__c;
			opWrapper.freight = cObj.PMC_CPQ_EstFreightPrice__c;
			opWrapper.fpdPrice = cObj.PMC_CPQ_FPDPricefromPriceFx__c;
			opWrapper.finalAgreedPrice = cObj.PMC_CPQ_FinalAgreedPrice__c;
			opWrapper.status = cObj.PMC_CPQ_OrderLineStatus__c;
			opWrapper.orderNum = cObj.Order.OrderNumber;
			opWrapper.contractNum = cObj.SBQQ__Contract__r.PMC_CPQ_ContractNumberIdentifier__c;
			opWrapper.po = cObj.PMC_CPQ_LinePONumber__c;
			opWrapper.shipTo = cObj.PMC_CPQ_ShipTo__r.Name;
			opWrapper.integrationMessage = cObj.PMC_CPQ_OrderItemIntegrationMessage__c;
			opWrapper.sapOrderNumber = cObj.Order.PMC_CPQ_SAPOrderNumber__c;
			//For US GCPM - 2121,Added  sapOrderLineID for SAP Order Line ID as API Name
			opWrapper.sapOrderLineID = cObj.PMC_CPQ_SAPOrderLineID__c;
			opWrapper.approvalStatus = cobj.ApprovalStatus__c; //For US GCPM - 2396
			opWrapper.integrationStatus = cObj.PMC_CPQ_OrderItemIntegrationStatus__c; //For US GCPM-3644
            opWrapper.rejectedReason = cobj.PMC_CPQ_ReasonOfRejectionOfItem__c; // GCPM-5209
			opDetailsWrapperList.add(opWrapper);
		}

		String jsonString = JSON.serialize(opDetailsWrapperList);
		return jsonString;
	}

	/**
	 * @description This method is to send the list of order products whose quote is owned by the logged in user
	 * @return jsonString - the list of order product details contained in the wrapper class
	 */
	@AuraEnabled
	public static String getDefaultOrderLines() {
		Id currentUserId = UserInfo.getUserId();
		List<OrderItem> lstOP = new List<OrderItem>();
		List<OrderItem> lstFPD = [
			SELECT Id, Order.SBQQ__Quote__r.OwnerId
			FROM OrderItem
			WHERE
				SBQQ__Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c IN ('FPD', 'FPD Ex-Space')
				OR PMC_CPQ_ContractType__c IN ('FPD', 'FPD Ex-Space')
			WITH SECURITY_ENFORCED
		];
		lstOP = [
			SELECT
				Id,
				OrderItemNumber,
				ApprovalStatus__c,
            	PMC_CPQ_ReasonOfRejectionOfItem__c,
				Order.OrderNumber,
				SBQQ__Contract__r.PMC_CPQ_ContractNumberIdentifier__c,
				PMC_CPQ_LinePONumber__c,
				PMC_CPQ_ShipTo__r.Name,
				Order.Account.Name,
				Product2.Name,
				Quantity,
				PMC_CPQ_PricingDate__c,
				PMC_CPQ_EstFreightPrice__c,
				PMC_CPQ_FPDPricefromPriceFx__c,
				PMC_CPQ_FinalAgreedPrice__c,
				PMC_CPQ_OrderLineStatus__c,
				PMC_CPQ_OrderItemIntegrationStatus__c,
				PMC_CPQ_OrderItemIntegrationMessage__c,
				Order.PMC_CPQ_SAPOrderNumber__c
			FROM OrderItem
			WHERE
				Id IN :lstFPD
				AND Order.OwnerId = :currentUserId
				AND (PMC_CPQ_FinalAgreedPrice__c = NULL
				OR PMC_CPQ_FinalAgreedPrice__c = 0
				OR PMC_CPQ_OrderItemIntegrationStatus__c != 'Success'
				OR (PMC_CPQ_FinalAgreedPrice__c > 0
				AND ApprovalStatus__c != 'Approved'))
			WITH SECURITY_ENFORCED
		]; //For US GCPM - 2396
		List<PMC_CPQ_OrderProductDetailsWrapperClass> opDetailsWrapperList = new List<PMC_CPQ_OrderProductDetailsWrapperClass>();
		for (OrderItem cObj : lstOP) {
			PMC_CPQ_OrderProductDetailsWrapperClass opWrapper = new PMC_CPQ_OrderProductDetailsWrapperClass();
			opWrapper.customId = cObj.Id;
			opWrapper.orderLine = cObj.OrderItemNumber;
			opWrapper.accountName = cObj.Order.Account.Name;
			opWrapper.productName = cObj.Product2.Name;
			opWrapper.quantity = cObj.Quantity;
			opWrapper.priceByDate = cObj.PMC_CPQ_PricingDate__c;
			opWrapper.freight = cObj.PMC_CPQ_EstFreightPrice__c;
			opWrapper.fpdPrice = cObj.PMC_CPQ_FPDPricefromPriceFx__c;
			opWrapper.finalAgreedPrice = cObj.PMC_CPQ_FinalAgreedPrice__c;
			opWrapper.status = cObj.PMC_CPQ_OrderLineStatus__c;
			opWrapper.orderNum = cObj.Order.OrderNumber;
			opWrapper.contractNum = cObj.SBQQ__Contract__r.PMC_CPQ_ContractNumberIdentifier__c;
			opWrapper.po = cObj.PMC_CPQ_LinePONumber__c;
			opWrapper.shipTo = cObj.PMC_CPQ_ShipTo__r.Name;
			opWrapper.integrationMessage = cObj.PMC_CPQ_OrderItemIntegrationMessage__c;
			opWrapper.sapOrderNumber = cObj.Order.PMC_CPQ_SAPOrderNumber__c;
			opWrapper.approvalStatus = cobj.ApprovalStatus__c; //For US GCPM - 2396
			opWrapper.integrationStatus = cObj.PMC_CPQ_OrderItemIntegrationStatus__c; //For US GCPM-3644
            opWrapper.rejectedReason = cobj.PMC_CPQ_ReasonOfRejectionOfItem__c; // GCPM-5209

			opDetailsWrapperList.add(opWrapper);
		}
		String jsonString = JSON.serialize(opDetailsWrapperList);
		return jsonString;
	}

	/**
	 * @description Wrapper class for parameters of getOPDetails method
	 */
	public class GetOPDetailsParams {
		/**
		 * @description acctId - the account id sent from LWC
		 */
		@AuraEnabled
		public Id acctId { get; set; }
		/**
		 * @description userId - the user/quote owner id sent from LWC
		 */
		@AuraEnabled
		public Id userId { get; set; }
		/**
		 * @description prodId - the product id sent from LWC
		 */
		@AuraEnabled
		public Id prodId { get; set; }
		/**
		 * @description shipId - the ship to acct id sent from LWC
		 */
		@AuraEnabled
		public Id shipId { get; set; }

		/**
		 * @description OrderId - the order id sent from LWC
		 */
		@AuraEnabled
		public Id ordId { get; set; }

		@AuraEnabled
		public String integrationStatus { get; set; }
	}
}