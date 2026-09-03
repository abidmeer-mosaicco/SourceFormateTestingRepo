public without sharing class PMC_CPQ_SAPOrderIntegrationEmailCtrl {
	public String orderId { get; set; }

	public class OrderWrapper {
		public String accountName { get; set; }
		public String orderNumber { get; set; }
		public String sapOrderNumber { get; set; }
		public String contractEndDate { get; set; }
	}

	public class OrderItemWrapper {
		public String id { get; set; }
		public String currencyCode { get; set; }
		public String orderItemNumber { get; set; }
		public String shipToName { get; set; }
		public String accountName { get; set; }
		public String productName { get; set; }
		public Decimal quantity { get; set; }
		public String pricingDate { get; set; }
		public String listPrice { get; set; }
		public String finalAgreedPrice { get; set; }
		public String orderLineStatus { get; set; }
		public String orderLineUrl { get; set; }
		public String sapOrderNumber { get; set; }
		public String sapOrderLineId { get; set; }
		public String lastModifiedBy { get; set; }
		public String integrationMessage { get; set; }
		public String integrationStatus { get; set; }
	}

	public String baseUrl {
		get {
			return URL.getOrgDomainUrl().toExternalForm();
		}
	}

	public String orderUrl {
		get {
			return baseUrl + '/lightning/r/Order/' + orderId + '/view';
		}
	}

	private OrderWrapper orderWrapper;
	private List<OrderItemWrapper> orderItemWrappers;

	public OrderWrapper getOrderRecord() {
		if (orderWrapper == null && orderId != null) {
			Order ord = [
				SELECT Account.Name, OrderNumber, PMC_CPQ_SAPOrderNumber__c, SBQQ__Quote__r.PMC_CPQ_ContractEnd__c
				FROM Order
				WHERE Id = :orderId
				LIMIT 1
			];

			orderWrapper = new OrderWrapper();
			orderWrapper.accountName = ord.Account?.Name;
			orderWrapper.orderNumber = ord.OrderNumber;
			orderWrapper.sapOrderNumber = ord.PMC_CPQ_SAPOrderNumber__c;
			orderWrapper.contractEndDate = formatDate(ord.SBQQ__Quote__r?.PMC_CPQ_ContractEnd__c);
		}
		return orderWrapper;
	}

	public List<OrderItemWrapper> getFilteredOrderItemWrappers() {
		if (orderItemWrappers == null && orderId != null) {
			orderItemWrappers = new List<OrderItemWrapper>();
			List<OrderItem> orderItems = [
				SELECT
					Id,
					CurrencyIsoCode,
					OrderItemNumber,
					PMC_CPQ_ShipTo__r.Name,
					Order.Account.Name,
					Product2.Name,
					Quantity,
					PMC_CPQ_PricingDate__c,
					PMC_CPQ_FPDPricefromPriceFx__c,
					PMC_CPQ_FinalAgreedPrice__c,
					PMC_CPQ_OrderLineStatus__c,
					PMC_CPQ_SAPOrderLineID__c,
					PMC_CPQ_OrderItemIntegrationMessage__c,
					PMC_CPQ_OrderItemIntegrationStatus__c,
					Order.PMC_CPQ_SAPOrderNumber__c,
					LastModifiedBy.Name
				FROM OrderItem
				WHERE OrderId = :orderId AND SendIntegrationResultEmail__c = TRUE
				ORDER BY LastModifiedDate DESC
			];
			for (OrderItem item : orderItems) {
				OrderItemWrapper wrapper = new OrderItemWrapper();
				wrapper.id = item.Id;
				wrapper.currencyCode = item.CurrencyIsoCode;
				wrapper.orderItemNumber = item.OrderItemNumber;
				wrapper.shipToName = item.PMC_CPQ_ShipTo__r?.Name;
				wrapper.accountName = item.Order?.Account?.Name;
				wrapper.productName = item.Product2?.Name;
				wrapper.quantity = item.Quantity;
				wrapper.pricingDate = formatDate(item.PMC_CPQ_PricingDate__c);
				wrapper.listPrice = formatCurrency(item.PMC_CPQ_FPDPricefromPriceFx__c);
				wrapper.finalAgreedPrice = formatCurrency(item.PMC_CPQ_FinalAgreedPrice__c);
				wrapper.orderLineStatus = item.PMC_CPQ_OrderLineStatus__c;
				wrapper.orderLineUrl = baseUrl + '/' + item.Id;
				wrapper.sapOrderLineId = item.PMC_CPQ_SAPOrderLineID__c;
				wrapper.integrationMessage = item.PMC_CPQ_OrderItemIntegrationMessage__c;
				wrapper.integrationStatus = getStatusIcon(item.PMC_CPQ_OrderItemIntegrationStatus__c);
				wrapper.sapOrderNumber = item.Order.PMC_CPQ_SAPOrderNumber__c;
				wrapper.lastModifiedBy = item.LastModifiedBy.Name;
				orderItemWrappers.add(wrapper);
			}
		}
		return orderItemWrappers;
	}

	@TestVisible
	private String formatDate(Date d) {
		return d != null ? DateTime.newInstance(d.year(), d.month(), d.day()).format('MM/dd/yyyy') : '';
	}

	@TestVisible
	private String formatCurrency(Decimal value) {
		return value == null ? '0.00' : String.valueOf(value.setScale(2, System.RoundingMode.HALF_UP));
	}

	@TestVisible
	private String getStatusIcon(String status) {
		switch on status {
			when 'Success' {
				return '✅';
			}
			when 'Error' {
				return '❌';
			}
			when 'Pending' {
				return '⏳';
			}
			when else {
				return status;
			}
		}
	}
}