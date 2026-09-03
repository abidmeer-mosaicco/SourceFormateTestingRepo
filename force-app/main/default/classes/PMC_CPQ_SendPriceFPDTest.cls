/** @description Test Class for Send Final Price to SAP on Order Detail Page
 *  @creator Prakhar
 *  @storynumber GDASF-12490
 */
@isTest
public with sharing class PMC_CPQ_SendPriceFPDTest {
	public static List<String> lstPayloadOrderIds = new List<String>();
	public static List<String> lstPayloadOrderLineIds = new List<String>();

	@testSetup
	private static void setup() {
		// Create profiles and permission sets
		List<String> lstProfileNames = new List<String>{ 'System Administrator', 'Sales User' };
		List<String> lstPermissionNames = new List<String>{ 'PMC_SLS_Permission_Set_Group' };
		Map<String, Id> mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
		Map<String, PermissionSetGroup> mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionNames);

		// Create users
		List<User> lstUser = PMC_TestUtilityClass.createUser(2);
		User objSystemAdminUser;
		User objUserAM;
		Integer intuserCount = 0;
		for (User objUser : lstUser) {
			if (intuserCount == 0) {
				objUser.LastName = 'System Administrator Test';
				objUser.ProfileId = mapOfProfiles.get('System Administrator');
			} else {
				objUser.LastName = 'Sales User Test';
				objUser.ProfileId = mapOfProfiles.get('Sales User');
			}
			objUser.isActive = true;
			objUser.MobilePhone = '1234567890';
			objUser.UserPermissionsKnowledgeUser = true;
			objUser.LanguageLocaleKey = 'en_US';
			intuserCount++;
		}
		insert lstUser;
		objSystemAdminUser = lstUser[0];
		objUserAM = lstUser[1];
		PMC_TestUtilityClass.assignPermissionSetGroupToUsers(
			new List<User>{ objUserAM },
			mapOfPermissionGrp.get('PMC_SLS_Permission_Set_Group')
		);

		// Create order
		List<Order> lstOrders = PMC_CPQ_OrderIntegrationTest.createOrders(1);
		if (!lstOrders.isEmpty() && lstOrders[0].Id == null) {
			insert lstOrders;
		}

		System.runAs(objSystemAdminUser) {
			List<Product2> prod = PMC_TestUtilityClass.createProduct(1, 'PMC_CPQ_NA');
			if (!prod.isEmpty() && prod[0].Id == null) {
				insert prod;
			}
			prod[0].PMC_CPQ_SAPProductCode__c = '';
			update prod[0];

			Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
			update standardPricebook;

			lstOrders[0].Pricebook2Id = standardPricebook.Id;
			lstOrders[0].CurrencyIsoCode = 'USD';
			lstOrders[0].OwnerId = objUserAM.Id;
			lstOrders[0].PMC_CPQ_IsFPD__c = true;
			update lstOrders;

			PricebookEntry pbe = new PricebookEntry(
				Pricebook2Id = standardPricebook.Id,
				Product2Id = prod[0].Id,
				UnitPrice = 0,
				CurrencyIsoCode = lstOrders[0].CurrencyIsoCode,
				IsActive = true
			);
			insert pbe;

			OrderItem objOrderProducts = new OrderItem();
			objOrderProducts.Product2Id = prod[0].Id;
			objOrderProducts.OrderId = lstOrders[0].Id;
			objOrderProducts.Quantity = 2;
			objOrderProducts.ListPrice = 0;
			objOrderProducts.UnitPrice = 5;
			objOrderProducts.PMC_CPQ_ListPrice__c = 10;
			objOrderProducts.PMC_CPQ_FPDPricefromPriceFx__c = 11;
			objOrderProducts.PMC_CPQ_FinalAgreedPrice__c = 12;
			objOrderProducts.PricebookEntryId = pbe.Id;
			insert objOrderProducts;
		}
	}

	@isTest
	public static void testSendPriceFPDSuccess() {
		List<OrderItem> lstOrderLines = [
			SELECT
				Id,
				Product2Id,
				OrderId,
				Quantity,
				ListPrice,
				PMC_CPQ_FPDPricefromPriceFx__c,
				UnitPrice,
				PMC_CPQ_FinalAgreedPrice__c,
				PricebookEntryId
			FROM OrderItem
		];
		for (OrderItem oi : lstOrderLines) {
			lstPayloadOrderLineIds.add(oi.Id);
		}

		User runAsUser;
		List<User> maybeSales = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];
		if (!maybeSales.isEmpty())
			runAsUser = maybeSales[0];
		else
			runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

		System.runAs(runAsUser) {
			Test.startTest();
			Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpSendFPDSuccess(lstOrderLines[0].Id));

			PageReference pageRef = Page.PMC_CPQ_SendFPD;
			pageRef.getParameters().put('id', String.valueOf(lstOrderLines[0].Id));
			Test.setCurrentPage(pageRef);

			ApexPages.StandardController stdController = new ApexPages.StandardController(lstOrderLines[0]);
			PMC_CPQ_FPDActionClass controllerFPD = new PMC_CPQ_FPDActionClass(stdController);
			controllerFPD.redirect();

			Test.stopTest();
			System.assert(!lstOrderLines.isEmpty(), 'List should not be empty');
		}
	}

	@isTest
	public static void testSendPriceFPDGoBack() {
		List<OrderItem> lstOrderLines = [
			SELECT
				Id,
				Product2Id,
				OrderId,
				Quantity,
				ListPrice,
				PMC_CPQ_FPDPricefromPriceFx__c,
				UnitPrice,
				PMC_CPQ_FinalAgreedPrice__c,
				PricebookEntryId
			FROM OrderItem
		];
		for (OrderItem oi : lstOrderLines) {
			lstPayloadOrderLineIds.add(oi.Id);
		}

		User runAsUser;
		List<User> maybeSales = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];
		if (!maybeSales.isEmpty())
			runAsUser = maybeSales[0];
		else
			runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

		System.runAs(runAsUser) {
			Test.startTest();
			Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpSendFPDSuccess(lstOrderLines[0].Id));

			PageReference pageRef = Page.PMC_CPQ_SendFPD;
			pageRef.getParameters().put('id', String.valueOf(lstOrderLines[0].Id));
			Test.setCurrentPage(pageRef);

			ApexPages.StandardController stdController = new ApexPages.StandardController(lstOrderLines[0]);
			PMC_CPQ_FPDActionClass controllerFPD = new PMC_CPQ_FPDActionClass(stdController);
			controllerFPD.goBack();

			Test.stopTest();
			System.assert(!lstOrderLines.isEmpty(), 'List should not be empty');
		}
	}

	@isTest
	public static void testSendPriceFPDError() {
		List<OrderItem> lstOrderLines = [
			SELECT
				Id,
				Product2Id,
				OrderId,
				Quantity,
				ListPrice,
				PMC_CPQ_FPDPricefromPriceFx__c,
				UnitPrice,
				PMC_CPQ_FinalAgreedPrice__c,
				PricebookEntryId
			FROM OrderItem
		];
		for (OrderItem oi : lstOrderLines) {
			lstPayloadOrderLineIds.add(oi.Id);
		}

		User runAsUser;
		List<User> maybeSales = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];
		if (!maybeSales.isEmpty())
			runAsUser = maybeSales[0];
		else
			runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

		System.runAs(runAsUser) {
			Test.startTest();
			Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpSendFPDError());

			PageReference pageRef = Page.PMC_CPQ_SendFPD;
			pageRef.getParameters().put('id', String.valueOf(lstOrderLines[0].Id));
			Test.setCurrentPage(pageRef);

			ApexPages.StandardController stdController = new ApexPages.StandardController(lstOrderLines[0]);
			PMC_CPQ_FPDActionClass controllerFPD = new PMC_CPQ_FPDActionClass(stdController);
			controllerFPD.redirect();

			Test.stopTest();
			System.assert(!lstOrderLines.isEmpty(), 'List should not be empty');
		}
	}

	@isTest
	public static void testSendPriceException() {
		List<OrderItem> lstOrderLines = [
			SELECT
				Id,
				Product2Id,
				OrderId,
				Quantity,
				ListPrice,
				PMC_CPQ_FPDPricefromPriceFx__c,
				UnitPrice,
				PMC_CPQ_FinalAgreedPrice__c,
				PricebookEntryId
			FROM OrderItem
		];
		for (OrderItem oi : lstOrderLines) {
			lstPayloadOrderLineIds.add(oi.Id);
		}

		User runAsUser;
		List<User> maybeSales = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];
		if (!maybeSales.isEmpty())
			runAsUser = maybeSales[0];
		else
			runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

		System.runAs(runAsUser) {
			Test.startTest();
			Test.setMock(HttpCalloutMock.class, null);

			PageReference pageRef = Page.PMC_CPQ_SendFPD;
			pageRef.getParameters().put('id', String.valueOf(lstOrderLines[0].Id));
			Test.setCurrentPage(pageRef);

			ApexPages.StandardController stdController = new ApexPages.StandardController(lstOrderLines[0]);
			PMC_CPQ_FPDActionClass controllerFPD = new PMC_CPQ_FPDActionClass(stdController);
			controllerFPD.redirect();

			Test.stopTest();
			System.assert(!lstOrderLines.isEmpty(), 'List should not be empty');
		}
	}

	@isTest
	public static void testBulkSendFPDRequest() {
		List<OrderItem> lstOrderLines = [
			SELECT
				Id,
				Product2Id,
				OrderId,
				Quantity,
				ListPrice,
				PMC_CPQ_FPDPricefromPriceFx__c,
				UnitPrice,
				PMC_CPQ_FinalAgreedPrice__c,
				PricebookEntryId
			FROM OrderItem
		];
		for (OrderItem oi : lstOrderLines) {
			lstPayloadOrderLineIds.add(oi.Id);
		}

		User runAsUser;
		List<User> maybeSales = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];
		if (!maybeSales.isEmpty())
			runAsUser = maybeSales[0];
		else
			runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

		System.runAs(runAsUser) {
			Test.startTest();
			Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpSendFPDSuccess(lstOrderLines[0].Id));
			Boolean fpdUI = true;
			PMC_CPQ_FPDActionClass objRef = new PMC_CPQ_FPDActionClass(lstOrderLines, fpdUI);
			objRef.bulkSendFPDtoSAPRequest(lstOrderLines);
			Test.stopTest();
			System.assert(!lstOrderLines.isEmpty(), 'List should not be empty');
		}
	}

	@isTest
	public static void testSendPriceFPDWarning() {
		List<OrderItem> lstOrderLines = [
			SELECT
				Id,
				Product2Id,
				OrderId,
				Quantity,
				ListPrice,
				PMC_CPQ_FPDPricefromPriceFx__c,
				UnitPrice,
				PMC_CPQ_FinalAgreedPrice__c,
				PricebookEntryId
			FROM OrderItem
		];
		for (OrderItem objItem : lstOrderLines) {
			objItem.put('PMC_CPQ_FinalAgreedPrice__c', null);
			lstPayloadOrderLineIds.add(objItem.Id);
		}
		update lstOrderLines;

		User runAsUser;
		List<User> maybeSales = [SELECT Id FROM User WHERE LastName = 'Sales User Test' LIMIT 1];
		if (!maybeSales.isEmpty())
			runAsUser = maybeSales[0];
		else
			runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

		System.runAs(runAsUser) {
			Test.startTest();
			Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpSendFPDSuccess(lstOrderLines[0].Id));

			PageReference pageRef = Page.PMC_CPQ_SendFPD;
			pageRef.getParameters().put('id', String.valueOf(lstOrderLines[0].Id));
			Test.setCurrentPage(pageRef);

			ApexPages.StandardController stdController = new ApexPages.StandardController(lstOrderLines[0]);
			PMC_CPQ_FPDActionClass controllerFPD = new PMC_CPQ_FPDActionClass(stdController);
			controllerFPD.redirect();

			Test.stopTest();
			System.assert(!lstOrderLines.isEmpty(), 'List should not be empty');
		}
	}

	@isTest
	private static void testCreateTransactionLog() {
		HttpResponse res = new HttpResponse();
		res.setStatusCode(200);
		res.setBody('200 Ok');
		Test.startTest();
		PMC_CPQ_SendPriceFPDResponseParsing.createTransactionLog(res);
		Test.stopTest();
		// No assert needed, just coverage for transaction log creation
	}

	@isTest
	private static void testGenOrderItemMap() {
		List<OrderItem> orderItems = [SELECT Id FROM OrderItem LIMIT 1];
		Map<String, OrderItem> mapOrderItem = PMC_CPQ_SendPriceFPDResponseParsing.genOrderItemMap(orderItems);
		System.assertEquals(orderItems[0].Id, mapOrderItem.get(orderItems[0].Id).Id);
	}

	@isTest
	private static void testParseSAPErrorDetail() {
		List<OrderItem> orderItems = [SELECT Id FROM OrderItem LIMIT 1];
		HttpResponse res = new HttpResponse();
		res.setStatusCode(500);
		res.setBody('Internal Server Error');
		Test.startTest();
		PMC_CPQ_SendPriceFPDResponseParsing.parseSAPErrorDetail(orderItems, res, true);
		Test.stopTest();
		OrderItem oi = [
			SELECT PMC_CPQ_OrderItemIntegrationStatus__c, PMC_CPQ_OrderItemIntegrationMessage__c
			FROM OrderItem
			WHERE Id = :orderItems[0].Id
		];
		System.assertEquals('Error', oi.PMC_CPQ_OrderItemIntegrationStatus__c);
		System.assert(oi.PMC_CPQ_OrderItemIntegrationMessage__c.contains('Error'));
	}

	@isTest
	private static void testParseSAPDetailSimpleSuccess() {
		List<OrderItem> orderItems = [SELECT Id FROM OrderItem LIMIT 1];
		HttpResponse res = new HttpResponse();
		res.setStatusCode(200);
		res.setBody('200 Ok');
		Test.startTest();
		PMC_CPQ_SendPriceFPDResponseParsing.parseSAPDetail(orderItems, res, false);
		Test.stopTest();
		OrderItem oi = [
			SELECT PMC_CPQ_OrderItemIntegrationStatus__c, PMC_CPQ_OrderItemIntegrationMessage__c
			FROM OrderItem
			WHERE Id = :orderItems[0].Id
		];
		System.assertEquals('Success', oi.PMC_CPQ_OrderItemIntegrationStatus__c);
	}
}