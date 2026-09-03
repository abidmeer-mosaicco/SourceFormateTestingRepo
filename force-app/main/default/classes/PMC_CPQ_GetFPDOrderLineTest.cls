/** @description This is the test class for Get FPD Order Line Interface 
*  @author Shefali Dsouza (Integration Team)
*  @storynumber GDASF-9359
*/
@isTest
public class PMC_CPQ_GetFPDOrderLineTest {
    private static Id orderItemId;
    
	@TestSetup
	public static void setup() {
		List<String> lstProfileNames = new List<String>{ 'System Administrator', 'Sales User' };
		List<userRole> userRoleName = [SELECT Id FROM userRole WHERE DeveloperName = 'PMC_SS_NASalesServiceAnalystSSA'];
		List<String> lstPermissionSetGroupNames = new List<String>{ 'PMC_Administrator_Permission_Set_Group', 'PMC_SLS_Permission_Set_Group' };
		Map<String, Id> mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
		Map<String, PermissionSetGroup> mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionSetGroupNames);
		Integer intuserCount = 0;
		User objSystemAdminUser;
		User objSalesUser;
		List<User> lstUser = PMC_TestUtilityClass.createUser(2);
		for (User objUser : lstUser) {
			if (intuserCount == 0) {
				objUser.LastName = 'Admin User Test';
				objUser.ProfileId = mapOfProfiles.get('System Administrator');
				objUser.FederationIdentifier = objUser.Username + 'Admin';
			} else if (intuserCount == 1) {
				objUser.LastName = 'Sales User Test';
				objUser.ProfileId = mapOfProfiles.get('Sales User');
				objUser.FederationIdentifier = objUser.Username + 'Sales';
				objUser.UserRoleId = userRoleName[0].Id;
			}
			objUser.isActive = true;
			objUser.MobilePhone = '1234567890';
			objUser.UserPermissionsKnowledgeUser = true;
			objUser.LanguageLocaleKey = 'en_US';
			objUser.PMC_CPQ_SalesRegion__c = 'North America';
			objUser.PMC_CPQ_PrimaryBusinessType__c = 'Feed';
			objUser.PMC_CPQ_SalesArea__c = 'Mosaic Global Sales LLC Domestic Common';
			intuserCount = intuserCount + 1;
		}
		insert lstUser;
		objSystemAdminUser = lstUser[0];
		objSalesUser = lstUser[1];
		PMC_TestUtilityClass.assignPermissionSetGroupToUsers(
			new List<User>{ objSystemAdminUser },
			mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group')
		);
		PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{ objSalesUser }, mapOfPermissionGrp.get('PMC_SLS_Permission_Set_Group'));

		System.runAs(objSystemAdminUser) {
			SBQQ.TriggerControl.disable();
			//Create Sales area
			List<PMC_SS_SalesArea__c> lstSalesArea = PMC_TestUtilityClass.createSalesArea(1, 'Master');
			lstSalesArea[0].PMC_SS_SalesOrganization__c = 'Mosaic Global Sales LLC';
			lstSalesArea[0].PMC_CPQ_SAPSalesOrganization__c = '10020010';
			lstSalesArea[0].PMC_SS_DistributionChannel__c = 'Common';
			lstSalesArea[0].PMC_SS_Division__c = '10';
			update lstSalesArea;
		}
	}

	private class MockSuccess implements HttpCalloutMock {
		private Id targetOrderItemId;

		public MockSuccess(Id orderItemId) {
			this.targetOrderItemId = orderItemId;
		}

		public HTTPResponse respond(HTTPRequest req) {
			HttpResponse res = new HttpResponse();
			res.setStatusCode(200);
			Id useId = this.targetOrderItemId;
			if (useId == null) {
				List<OrderItem> tmp = [SELECT Id FROM OrderItem LIMIT 1];
				if (!tmp.isEmpty()) useId = tmp[0].Id;
			}
			String body = '[{"OrderItemId":"' + String.escapeSingleQuotes(String.valueOf(useId)) + '","ListPrice":15.0,"FloorPrice":5.0,"CeilingPrice":100.0,"Status":"Success","ErrorMessage":""}]';
			res.setBody(body);
			return res;
		}
	}

	private class MockBadJSON implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest req) {
			HttpResponse res = new HttpResponse();
			res.setStatusCode(200);
			res.setBody('INVALID_JSON');
			return res;
		}
	}

	private static Id createTestOrderItem() {
        // Create test data without using SBQQ.TriggerControl.disable()
        User adminUser = [SELECT Id FROM User WHERE LastName = 'Admin User Test' LIMIT 1];
        
        System.runAs(adminUser) {
            // First, ensure we're not in a trigger disabled state
            SBQQ.TriggerControl.enable();
            
            // Bypass flows that might change PricebookEntry
            PMC_ProcessSwitches__c bypassSetting = PMC_ProcessSwitches__c.getOrgDefaults();
            if (bypassSetting.Id == null) {
                bypassSetting = new PMC_ProcessSwitches__c();
            }
            bypassSetting.PMC_BypassFlow__c = true;
            upsert bypassSetting;
            
            // Create Account
            Account testAccount = new Account(
                Name = 'Test Account for FPD',
                CurrencyIsoCode = 'USD'
            );
            insert testAccount;
            
            // Create Product
            Product2 testProduct = new Product2(
                Name = 'Test Product for FPD',
                IsActive = true,
                CurrencyIsoCode = 'USD',
                PMC_CPQ_SAPProductCode__c = 'TEST_FPD_123'
            );
            insert testProduct;
            
            // Get Standard Pricebook
            Id standardPricebookId = Test.getStandardPricebookId();
            
			// Create PricebookEntry
			PricebookEntry testPricebookEntry = new PricebookEntry(
				Pricebook2Id = standardPricebookId,
				Product2Id = testProduct.Id,
				UnitPrice = 100.00,
				IsActive = true,
				CurrencyIsoCode = 'USD'
			);
			insert testPricebookEntry;

			// Verify the Product SAP code is set (PricebookEntry SKU may be a derived/read-only field).
			Product2 prodCheck = [SELECT Id, PMC_CPQ_SAPProductCode__c FROM Product2 WHERE Id = :testProduct.Id];
			System.assertEquals('TEST_FPD_123', prodCheck.PMC_CPQ_SAPProductCode__c, 'Product SAP code should be set');
            
            // Create Order
            Order testOrder = new Order(
                AccountId = testAccount.Id,
                EffectiveDate = Date.today(),
                Status = 'Draft',
                Pricebook2Id = standardPricebookId,
                CurrencyIsoCode = 'USD'
            );
            insert testOrder;
            
            // Create OrderItem - ensure ListPrice matches UnitPrice
            OrderItem testOrderItem = new OrderItem(
                OrderId = testOrder.Id,
                Product2Id = testProduct.Id,
                Quantity = 1,
                PricebookEntryId = testPricebookEntry.Id,
                UnitPrice = testPricebookEntry.UnitPrice,
                ListPrice = testPricebookEntry.UnitPrice, // Critical: must match PricebookEntry UnitPrice
                PMC_CPQ_ListPrice__c = testPricebookEntry.UnitPrice,
                PMC_CPQ_FinalAgreedPrice__c = 10,
                PMC_CPQ_PriceGuidanceCeiling__c = 100,
                PMC_CPQ_EstFreightPrice__c = 1,
                PMC_CPQ_OrderItemIntegrationStatus__c = 'Pending'
            );
            insert testOrderItem;
            
            // Verify OrderItem was created correctly with matching PricebookEntry
            OrderItem createdItem = [SELECT Id, ListPrice, PricebookEntryId, PricebookEntry.UnitPrice 
                                     FROM OrderItem WHERE Id = :testOrderItem.Id];
            System.assertEquals(createdItem.ListPrice, createdItem.PricebookEntry.UnitPrice, 
                               'ListPrice must match PricebookEntry UnitPrice');
            
            // Cleanup: Reset bypass setting
            bypassSetting.PMC_BypassFlow__c = false;
            upsert bypassSetting;
            
            return testOrderItem.Id;
        }
        return null;
	}

	@isTest
	static void testBulkGetFPDRequestEnqueues() {
		Id oiId = createTestOrderItem();
        System.assertNotEquals(null, oiId, 'OrderItem Id should not be null');
		List<OrderItem> lst = [SELECT Id, ListPrice, PricebookEntry.UnitPrice FROM OrderItem WHERE Id = :oiId];
		System.assertEquals(lst[0].ListPrice, lst[0].PricebookEntry.UnitPrice, 'ListPrice should match PricebookEntry UnitPrice');
		Test.startTest();
		List<OrderItem> returned = (new PMC_CPQ_GetFPDController(new List<OrderItem>{ lst[0] }, true)).bulkGetFPDRequest(new List<OrderItem>{ lst[0] });
		Test.stopTest();
		System.assertEquals(1, returned.size(), 'Should return the same list');
	}

	@isTest
	static void testRedirectEnqueues() {
		Id oiId = createTestOrderItem();
        System.assertNotEquals(null, oiId, 'OrderItem Id should not be null');
		OrderItem oi = [SELECT Id FROM OrderItem WHERE Id = :oiId];
		ApexPages.StandardController sc = new ApexPages.StandardController(oi);
		Test.startTest();
		PMC_CPQ_GetFPDController ctrl = new PMC_CPQ_GetFPDController(sc);
		PageReference pr = ctrl.redirect();
		Test.stopTest();
		System.assertEquals('/' + oi.Id, pr.getUrl(), 'Redirect should point to the order item page');
	}

	@isTest
	static void testExecuteSuccessParsesAndUpdates() {
		Id oiId = createTestOrderItem();
        System.assertNotEquals(null, oiId, 'OrderItem Id should not be null');
		Test.setMock(HttpCalloutMock.class, new MockSuccess(oiId));
		List<OrderItem> lst = [SELECT Id, PMC_CPQ_OrderItemIntegrationStatus__c, PMC_CPQ_FPDPricefromPriceFx__c FROM OrderItem WHERE Id = :oiId];

		Test.startTest();
		System.enqueueJob(new PMC_CPQ_GetFPDController(lst, true));
		Test.stopTest();

		OrderItem refreshed = [SELECT Id, PMC_CPQ_OrderItemIntegrationStatus__c, PMC_CPQ_FPDPricefromPriceFx__c FROM OrderItem WHERE Id = :oiId];
		System.assertEquals('Success', refreshed.PMC_CPQ_OrderItemIntegrationStatus__c, 'Integration status should be Success');
		System.assertEquals(15.0, refreshed.PMC_CPQ_FPDPricefromPriceFx__c, 'FPD price should be set from response');
	}

	@isTest
	static void testExecuteParseExceptionSetsError() {
		Id oiId = createTestOrderItem();
        System.assertNotEquals(null, oiId, 'OrderItem Id should not be null');
		Test.setMock(HttpCalloutMock.class, new MockBadJSON());
		List<OrderItem> lst = [SELECT Id, PMC_CPQ_OrderItemIntegrationStatus__c, PMC_CPQ_OrderItemIntegrationMessage__c FROM OrderItem WHERE Id = :oiId];

		Test.startTest();
		System.enqueueJob(new PMC_CPQ_GetFPDController(lst, true));
		Test.stopTest();

		OrderItem refreshed = [SELECT Id, PMC_CPQ_OrderItemIntegrationStatus__c, PMC_CPQ_OrderItemIntegrationMessage__c FROM OrderItem WHERE Id = :oiId];
		System.assertEquals('Error', refreshed.PMC_CPQ_OrderItemIntegrationStatus__c, 'Integration status should be Error on parse exception');
		System.assert(refreshed.PMC_CPQ_OrderItemIntegrationMessage__c.contains('Get FPD Price'), 'Integration message should be set');
	}
}