public without sharing class PMC_CPQ_OrderApprovalEmailCtrl {
	// Attributes
	public string orderId { get; set; }
	public string materialGroup { get; set; }
	public string approvalStatus { get; set; }

	// Wrapper classes
	public class OrderWrapper {
		public String accountName { get; set; }
		public String orderNumber { get; set; }
		public String sapOrderNumber { get; set; }
		public String contractEndDate { get; set; }
		// Add all other Order fields needed in the template
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
		public String floorPlusFreight { get; set; }
		public String finalAgreedPrice { get; set; }
		public String listPrice { get; set; }
		public String ceilingPrice { get; set; }
		public Decimal freight { get; set; }
		public String finalAgreedPriceBeforeFreight { get; set; }		
		public String orderLineStatus { get; set; }
		public String orderLineUrl { get; set; }
		// Add all other OrderItem fields needed
	}

	// Base URL properties
	public String baseUrl {
		get {
			String url = URL.getOrgDomainUrl()?.toExternalForm();
			return url != null ? url : '';
		}
	}

	public String orderUrl {
		get {
			return baseUrl + '/lightning/r/Order/' + orderId + '/view';
		}
	}

	public String listViewUrl {
		get {
			String redirectUrl = baseUrl + '/lightning/o/sbaa__Approval__c/list?filterName=';
			if (materialGroup == 'Potash') {
				return redirectUrl + 'Potash_FPD_Approval_Requests';
			} else if (materialGroup == 'Phosphate') {
				return redirectUrl + 'Phosphate_FPD_Approval_Requests';
			}
			return redirectUrl + 'FPD_Approval_Requests';
		}
	}

	// Wrapped data properties
	private OrderWrapper orderWrapper;
	private List<OrderItemWrapper> orderItemWrappers;

	public OrderWrapper getOrderRecord() {
		if (orderWrapper == null && orderId != null) {
			Order ord = [
				SELECT Account.Name, OrderNumber, PMC_CPQ_SAPOrderNumber__c, SBQQ__Quote__r.PMC_CPQ_ContractEnd__c, SBQQ__Quote__r.CurrencyIsoCode
				FROM Order
				WHERE Id = :orderId
			];

			orderWrapper = new OrderWrapper();
			orderWrapper.accountName = ord.Account?.Name;
			orderWrapper.orderNumber = ord.OrderNumber;
			orderWrapper.sapOrderNumber = ord.PMC_CPQ_SAPOrderNumber__c;
			orderWrapper.contractEndDate = formatDate(ord.SBQQ__Quote__r?.PMC_CPQ_ContractEnd__c);
		}
		return orderWrapper;
	}

	public List<OrderItemWrapper> getOrderItemWrappers() {
		if (orderItemWrappers == null && orderId != null) {
			orderItemWrappers = new List<OrderItemWrapper>();

			for (OrderItem item : [
				SELECT
					Id,
					CurrencyIsoCode,
					OrderItemNumber,
					PMC_CPQ_ShipTo__r.Name,
					Order.Account.Name,
					Product2.Name,
					Product2.PMC_CPQ_MaterialGroup__c,
					Quantity,
					PMC_CPQ_PricingDate__c,
					PMC_CPQ_Floorplusfreight__c,
					PMC_CPQ_FPDPricefromPriceFx__c,
					PMC_CPQ_FinalAgreedPrice__c,
					PMC_CPQ_PriceGuidanceCeiling__c,
					PMC_CPQ_EstFreightPrice__c,
					PMC_CPQ_OrderLineStatus__c
				FROM OrderItem
				WHERE
					OrderId = :orderId
					AND Id IN (
						SELECT OrderItem__c
						FROM sbaa__Approval__c
						WHERE
							sbaa__Status__c = :approvalStatus
							AND PMC_CPQ_SendEmail__c = TRUE
							AND OrderItem__r.OrderId = :orderId
							AND LastModifiedDate >= LAST_N_DAYS:0
					)
			]) {
				OrderItemWrapper wrapper = new OrderItemWrapper();
				wrapper.id = item.Id;
				wrapper.currencyCode = item.CurrencyIsoCode;
				wrapper.orderItemNumber = item.OrderItemNumber;
				wrapper.shipToName = item.PMC_CPQ_ShipTo__r?.Name;
				wrapper.accountName = item.Order?.Account?.Name;
				wrapper.productName = item.Product2?.Name;
				wrapper.quantity = item.Quantity;
				wrapper.pricingDate = formatDate(item.PMC_CPQ_PricingDate__c);
				wrapper.floorPlusFreight = formatCurrency(item.PMC_CPQ_Floorplusfreight__c);
				wrapper.listPrice = formatCurrency(item.PMC_CPQ_FPDPricefromPriceFx__c);
				wrapper.finalAgreedPrice = formatCurrency(item.PMC_CPQ_FinalAgreedPrice__c);
				wrapper.ceilingPrice = formatCurrency(item.PMC_CPQ_PriceGuidanceCeiling__c);
				wrapper.freight = item.PMC_CPQ_EstFreightPrice__c ?? 0;
				wrapper.finalAgreedPriceBeforeFreight = (item.PMC_CPQ_EstFreightPrice__c != null && item.PMC_CPQ_FinalAgreedPrice__c != null) ? formatCurrency(item.PMC_CPQ_FinalAgreedPrice__c - wrapper.freight) : '';
				wrapper.orderLineStatus = item.PMC_CPQ_OrderLineStatus__c;
				wrapper.orderLineUrl = baseUrl + '/' + item.Id;

				orderItemWrappers.add(wrapper);

				// Set material group from first item
				if (materialGroup == null && item.Product2 != null) {
					materialGroup = item.Product2.PMC_CPQ_MaterialGroup__c;
				}
			}
		}
		return orderItemWrappers;
	}

	// Helper methods
	@TestVisible
	private String formatDate(Date d) {
		return d != null ? DateTime.newInstance(d.year(), d.month(), d.day()).format('MM/dd/yyyy') : '';
	}

	@TestVisible
	private String formatCurrency(Decimal value) {
		if (value == null)
			return '';
		return String.valueOf(value.setScale(2, System.RoundingMode.HALF_UP));
	}
}