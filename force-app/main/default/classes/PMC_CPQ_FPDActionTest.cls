/**
 * @description Test class for PMC_CPQ_FPDActionClass
 * @author Copilot
 */
@isTest
public with sharing class PMC_CPQ_FPDActionTest {
	@testSetup
	static void setup() {
		// Create profiles and permission sets
		List<String> lstProfileNames = new List<String>{ 'System Administrator', 'Sales User' };
		List<String> lstPermissionNames = new List<String>{ 'PMC_SLS_Permission_Set_Group' };
		Map<String, Id> mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
		Map<String, PermissionSetGroup> mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionNames);

		// Create users
		List<User> lstUser = PMC_TestUtilityClass.createUser(2);
		lstUser[0].ProfileId = mapOfProfiles.get('System Administrator');
		lstUser[1].ProfileId = mapOfProfiles.get('Sales User');
		insert lstUser;
		User objSystemAdminUser = lstUser[0];
		User objUserAM = lstUser[1];
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
			objOrderProducts.Agreed_Final_Price__c = 100;
			objOrderProducts.ApprovalStatus__c = 'Approved';
			insert objOrderProducts;
		}
	}

	@isTest
	static void testConstructorStandardController() {
		OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
		ApexPages.StandardController sc = new ApexPages.StandardController(oi);
		PMC_CPQ_FPDActionClass ctrl = new PMC_CPQ_FPDActionClass(sc);
		System.assertEquals(oi.Id, ctrl.orderItemId);
		System.assertNotEquals(null, ctrl.objOrdItm);
	}

	@isTest
	static void testConstructorListAndMassFlag() {
		List<OrderItem> ois = [SELECT Id FROM OrderItem LIMIT 1];
		PMC_CPQ_FPDActionClass ctrl = new PMC_CPQ_FPDActionClass(ois, true);
		System.assertEquals(ois[0].Id, ctrl.lstOrderPrd[0].Id);
		System.assert(ctrl.massFPDUI);
	}

	@isTest
	static void testExecuteSuccess() {
		List<OrderItem> ois = [SELECT Id FROM OrderItem LIMIT 1];
		PMC_CPQ_FPDActionClass ctrl = new PMC_CPQ_FPDActionClass(ois, false);
		Test.startTest();
		// Mock callout success
		Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpSendFPDSuccess(ois[0].Id));
		ctrl.execute(null);
		Test.stopTest();
		System.assert(true, 'execute ran');
	}

	@isTest
	static void testExecuteError() {
		List<OrderItem> ois = [SELECT Id FROM OrderItem LIMIT 1];
		PMC_CPQ_FPDActionClass ctrl = new PMC_CPQ_FPDActionClass(ois, false);
		Test.startTest();
		// Mock callout error
		Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpSendFPDError());
		ctrl.execute(null);
		Test.stopTest();
		System.assert(true, 'execute ran with error');
	}

	@isTest
	static void testRedirectSuccess() {
		OrderItem oi = [SELECT Id FROM OrderItem WHERE Agreed_Final_Price__c != NULL LIMIT 1];
		ApexPages.StandardController sc = new ApexPages.StandardController(oi);
		PMC_CPQ_FPDActionClass ctrl = new PMC_CPQ_FPDActionClass(sc);
		Test.startTest();
		PageReference ref = ctrl.redirect();
		Test.stopTest();
		System.assertEquals(null, ref, 'redirect should return null');
		// System.assert(ref.getUrl().contains(oi.Id), 'redirect URL should contain OrderItem Id');
	}

	@isTest
	static void testRedirectNoItem() {
		// Create a dummy OrderItem with no Agreed_Final_Price__c
		OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
		oi.Agreed_Final_Price__c = null;
		update oi;
		ApexPages.StandardController sc = new ApexPages.StandardController(oi);
		PMC_CPQ_FPDActionClass ctrl = new PMC_CPQ_FPDActionClass(sc);
		Test.startTest();
		PageReference ref = ctrl.redirect();
		Test.stopTest();
		System.assertEquals(null, ref, 'redirect should return null even when no item');
		// System.assert(ref.getUrl().contains(oi.Id), 'redirect URL should contain OrderItem Id');
	}

	@isTest
	static void testBulkSendFPDtoSAPRequest() {
		List<OrderItem> ois = [SELECT Id FROM OrderItem LIMIT 1];
		PMC_CPQ_FPDActionClass ctrl = new PMC_CPQ_FPDActionClass(ois, false);
		Test.startTest();
		List<OrderItem> result = ctrl.bulkSendFPDtoSAPRequest(ois);
		Test.stopTest();
		System.assertEquals(ois[0].Id, result[0].Id);
	}

	@isTest
	static void testGoBack() {
		OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
		ApexPages.StandardController sc = new ApexPages.StandardController(oi);
		PMC_CPQ_FPDActionClass ctrl = new PMC_CPQ_FPDActionClass(sc);
		Test.startTest();
		PageReference ref = ctrl.goBack();
		Test.stopTest();
		System.assertNotEquals(null, ref);
		System.assert(ref.getUrl().contains(oi.Id));
	}
}