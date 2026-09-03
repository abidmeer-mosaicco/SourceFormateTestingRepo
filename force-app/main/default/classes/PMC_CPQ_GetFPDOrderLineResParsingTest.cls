/**
 * @description Test class for PMC_CPQ_GetFPDOrderLineResParsingClass.
 * Covers success, partial success, HTTP error and malformed JSON scenarios.
 * NOTE: Per instructions, no Custom Metadata Type records are inserted/created here.
 *       The test assumes the required custom metadata (Integration Endpoint) exists in the org.
 * @author Copilot
 */
@isTest
public without sharing class PMC_CPQ_GetFPDOrderLineResParsingTest {
	@testSetup
	static void setup() {
		List<Order> lstOrders = PMC_CPQ_OrderIntegrationTest.createOrders(1);
		User objUser = [SELECT Id FROM User WHERE LastName = 'System Administrator Test' LIMIT 1];

		System.runAs(objUser) {
			List<Product2> prod = PMC_TestUtilityClass.createProduct(1, 'PMC_CPQ_NA');
			prod[0].PMC_CPQ_SAPProductCode__c = '';
			update prod[0];

			Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
			update standardPricebook;

			lstOrders[0].Pricebook2Id = standardPricebook.Id;
			lstOrders[0].CurrencyIsoCode = 'USD';
			update lstOrders;

			PricebookEntry pbe = new PricebookEntry(
				Pricebook2Id = standardPricebook.Id,
				Product2Id = prod[0].Id,
				UnitPrice = 0,
				CurrencyIsoCode = lstOrders[0].CurrencyIsoCode,
				IsActive = true
			);
			insert pbe;

			OrderItem orderItemRecord = new OrderItem();
			orderItemRecord.Product2Id = prod[0].Id;
			orderItemRecord.OrderId = lstOrders[0].Id;
			orderItemRecord.Quantity = 2;
			orderItemRecord.PMC_CPQ_ListPrice__c = 180;
			orderItemRecord.UnitPrice = 0;
			orderItemRecord.ListPrice = 0;
			orderItemRecord.PMC_CPQ_FinalAgreedPrice__c = 1;
			orderItemRecord.PricebookEntryId = pbe.Id;
			orderItemRecord.SendIntegrationResultEmail__c = true;
			orderItemRecord.PMC_CPQ_OrderItemIntegrationMessage__c = 'Save and Send to SAP: Order Updated Successfully';
			orderItemRecord.ApprovalStatus__c = 'Approved';
			insert orderItemRecord;

			// Insert a second OrderItem so tests referencing index 1 don't throw List index errors
			OrderItem orderItemRecord2 = new OrderItem();
			orderItemRecord2.Product2Id = prod[0].Id; // reuse same product / PBE for simplicity
			orderItemRecord2.OrderId = lstOrders[0].Id;
			orderItemRecord2.Quantity = 3;
			orderItemRecord2.PMC_CPQ_ListPrice__c = 185;
			orderItemRecord2.UnitPrice = 0;
			orderItemRecord2.ListPrice = 0;
			orderItemRecord2.PMC_CPQ_FinalAgreedPrice__c = 1;
			orderItemRecord2.PricebookEntryId = pbe.Id;
			orderItemRecord2.SendIntegrationResultEmail__c = true;
			orderItemRecord2.PMC_CPQ_OrderItemIntegrationMessage__c = 'Save and Send to SAP: Order Updated Successfully';
			orderItemRecord2.ApprovalStatus__c = 'Approved';
			insert orderItemRecord2;
		}
	}

	/**
	 * @description Utility: fetch test order items.
	 */
	private static List<OrderItem> fetchOrderItems() {
		return [
			SELECT
				Id,
				PMC_CPQ_OrderItemIntegrationStatus__c,
				PMC_CPQ_OrderItemIntegrationMessage__c,
				PMC_CPQ_FPDPricefromPriceFx__c,
				PMC_CPQ_Floorprice__c,
				PMC_CPQ_PriceGuidanceCeiling__c
			FROM OrderItem
			ORDER BY CreatedDate ASC
			LIMIT 2
		];
	}

	/**
	 * @description Test full success scenario (all lines Success -> transaction status Success).
	 */
	@isTest
	private static void testParseSuccessAllLines() {
		List<OrderItem> items = fetchOrderItems();
		System.assertEquals(2, items.size(), 'Two order items expected from setup');

		String body =
			'[{' +
			'"OrderItemId":"' +
			items[0].Id +
			'","ListPrice":100,"FloorPrice":90,"CeilingPrice":120,' +
			'"Status":"Success","ErrorMessage":""},{' +
			'"OrderItemId":"' +
			items[1].Id +
			'","ListPrice":200,"FloorPrice":150,"CeilingPrice":250,' +
			'"Status":"Success","ErrorMessage":""}]';

		HttpResponse resp = new HttpResponse();
		resp.setStatusCode(200);
		resp.setBody(body);

		// Mock static request reference used for logging
		PMC_CPQ_CPIRemoteCalloutUtilityClass.request = new HttpRequest();
		PMC_CPQ_CPIRemoteCalloutUtilityClass.request.setBody('{"mock":"request"}');

		Test.startTest();
		PMC_CPQ_GetFPDOrderLineResParsingClass.parseJSONOrderLineInterface(items, resp, false);
		Test.stopTest();

		List<OrderItem> updated = [
			SELECT
				Id,
				PMC_CPQ_OrderItemIntegrationStatus__c,
				PMC_CPQ_OrderItemIntegrationMessage__c,
				PMC_CPQ_FPDPricefromPriceFx__c,
				PMC_CPQ_Floorprice__c,
				PMC_CPQ_PriceGuidanceCeiling__c
			FROM OrderItem
			WHERE Id IN :new List<Id>{ items[0].Id, items[1].Id }
		];
		for (OrderItem oi : updated) {
			System.assertEquals('Success', oi.PMC_CPQ_OrderItemIntegrationStatus__c, 'Status should be Success');
			System.assert(oi.PMC_CPQ_OrderItemIntegrationMessage__c.contains('Get FPD Price: Success'), 'Message should reflect success');
		}
		System.assertEquals(100, updated[0].PMC_CPQ_FPDPricefromPriceFx__c, 'First line price mismatch');
		System.assertEquals(200, updated[1].PMC_CPQ_FPDPricefromPriceFx__c, 'Second line price mismatch');
		System.assertEquals(120, updated[0].PMC_CPQ_PriceGuidanceCeiling__c, 'Ceiling not set first line');
		System.assertEquals(250, updated[1].PMC_CPQ_PriceGuidanceCeiling__c, 'Ceiling not set second line');
	}

	/**
	 * @description Test partial success (one Success, one Error -> transaction status Partial Success).
	 */
	@isTest
	private static void testParsePartialSuccess() {
		List<OrderItem> items = fetchOrderItems();
		System.assertEquals(2, items.size(), 'Two order items expected from setup');
		String body =
			'[{' +
			'"OrderItemId":"' +
			items[0].Id +
			'","ListPrice":110,"FloorPrice":95,"CeilingPrice":130,' +
			'"Status":"Success","ErrorMessage":""},{' +
			'"OrderItemId":"' +
			items[1].Id +
			'","ListPrice":210,"FloorPrice":160,"CeilingPrice":260,' +
			'"Status":"Error","ErrorMessage":"Price derivation failed"}]';

		HttpResponse resp = new HttpResponse();
		resp.setStatusCode(200);
		resp.setBody(body);

		PMC_CPQ_CPIRemoteCalloutUtilityClass.request = new HttpRequest();
		PMC_CPQ_CPIRemoteCalloutUtilityClass.request.setBody('{"mock":"request"}');

		Test.startTest();
		PMC_CPQ_GetFPDOrderLineResParsingClass.parseJSONOrderLineInterface(items, resp, false);
		Test.stopTest();

		List<OrderItem> updated = [
			SELECT
				Id,
				PMC_CPQ_OrderItemIntegrationStatus__c,
				PMC_CPQ_OrderItemIntegrationMessage__c,
				PMC_CPQ_FPDPricefromPriceFx__c,
				PMC_CPQ_PriceGuidanceCeiling__c
			FROM OrderItem
			WHERE Id IN :new List<Id>{ items[0].Id, items[1].Id }
		];
		// First line success
		System.assertEquals('Success', updated[0].PMC_CPQ_OrderItemIntegrationStatus__c, 'First line should be Success');
		System.assert(updated[0].PMC_CPQ_OrderItemIntegrationMessage__c.contains('Success'), 'First line message should indicate success');
		// Second line error
		System.assertEquals('Error', updated[1].PMC_CPQ_OrderItemIntegrationStatus__c, 'Second line should be Error');
		System.assert(
			updated[1].PMC_CPQ_OrderItemIntegrationMessage__c.contains('Price derivation failed'),
			'Second line should carry error message'
		);

		// Transaction Log status check (latest log)
		PMC_CPQ_TransactionLog__c log = [
			SELECT Id, PMC_CPQ_IntegrationStatus__c
			FROM PMC_CPQ_TransactionLog__c
			ORDER BY CreatedDate DESC
			LIMIT 1
		];
		System.assertEquals('Partial Success', log.PMC_CPQ_IntegrationStatus__c, 'Transaction log should record Partial Success');
	}

	/**
	 * @description Test HTTP error status (non-200) leading to Error for all lines.
	 */
	@isTest
	private static void testParseHttpError() {
		List<OrderItem> items = fetchOrderItems();
		System.assertEquals(2, items.size(), 'Two order items expected from setup');
		HttpResponse resp = new HttpResponse();
		resp.setStatusCode(500);
		resp.setBody('Server Internal Error');

		PMC_CPQ_CPIRemoteCalloutUtilityClass.request = new HttpRequest();
		PMC_CPQ_CPIRemoteCalloutUtilityClass.request.setBody('{"mock":"request"}');

		Test.startTest();
		PMC_CPQ_GetFPDOrderLineResParsingClass.parseJSONOrderLineInterface(items, resp, false);
		Test.stopTest();

		List<OrderItem> updated = [
			SELECT Id, PMC_CPQ_OrderItemIntegrationStatus__c, PMC_CPQ_OrderItemIntegrationMessage__c
			FROM OrderItem
			WHERE Id IN :new List<Id>{ items[0].Id, items[1].Id }
		];
		for (OrderItem oi : updated) {
			System.assertEquals('Error', oi.PMC_CPQ_OrderItemIntegrationStatus__c, 'All lines should be Error on HTTP failure');
			System.assert(oi.PMC_CPQ_OrderItemIntegrationMessage__c.contains('Get FPD Price:'), 'Message should have prefix');
		}
		PMC_CPQ_TransactionLog__c log = [
			SELECT Id, PMC_CPQ_IntegrationStatus__c
			FROM PMC_CPQ_TransactionLog__c
			ORDER BY CreatedDate DESC
			LIMIT 1
		];
		System.assertEquals('Error', log.PMC_CPQ_IntegrationStatus__c, 'Transaction log should record Error');
	}

	/**
	 * @description Test malformed JSON body causing exception path (status code success but parse failure).
	 */
	@isTest
	private static void testParseMalformedJson() {
		List<OrderItem> items = fetchOrderItems();
		System.assertEquals(2, items.size(), 'Two order items expected from setup');
		HttpResponse resp = new HttpResponse();
		resp.setStatusCode(200);
		resp.setBody('[{"badJson": '); // intentionally malformed

		PMC_CPQ_CPIRemoteCalloutUtilityClass.request = new HttpRequest();
		PMC_CPQ_CPIRemoteCalloutUtilityClass.request.setBody('{"mock":"request"}');

		Test.startTest();
		PMC_CPQ_GetFPDOrderLineResParsingClass.parseJSONOrderLineInterface(items, resp, false);
		Test.stopTest();

		List<OrderItem> updated = [
			SELECT Id, PMC_CPQ_OrderItemIntegrationStatus__c, PMC_CPQ_OrderItemIntegrationMessage__c
			FROM OrderItem
			WHERE Id IN :new List<Id>{ items[0].Id, items[1].Id }
		];
		for (OrderItem oi : updated) {
			System.assertEquals('Error', oi.PMC_CPQ_OrderItemIntegrationStatus__c, 'Lines should be Error on JSON parse failure');
			System.assert(
				oi.PMC_CPQ_OrderItemIntegrationMessage__c.startsWith('Get FPD Price:'),
				'Message should contain prefix and exception text'
			);
		}
		PMC_CPQ_TransactionLog__c log = [
			SELECT Id, PMC_CPQ_IntegrationStatus__c
			FROM PMC_CPQ_TransactionLog__c
			ORDER BY CreatedDate DESC
			LIMIT 1
		];
		System.assertEquals('Error', log.PMC_CPQ_IntegrationStatus__c, 'Transaction log should record Error for malformed JSON');
	}
}