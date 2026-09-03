@IsTest
private class md_reportOrdersControllerTest {

    @IsTest
    static void testGetDataForOrderItems() {
        Id fakeOrderItemId = '802000000000001AAA';

        ShipmentItem shipment = new ShipmentItem(
            PMC_CPQ_OrderProduct__c = fakeOrderItemId,
            Shipment = new Shipment(
                PMC_CPQ_VehicleID__c = 'TRUCK-001',
                PMC_CPQ_ShippedDate__c = Date.today()
            ),
            isFPD__c = true
        );

        md_reportOrdersDAO.testInjectedRecords =
            new List<ShipmentItem>{ shipment };

        Test.startTest();

        List<md_reportOrdersWrapper.ShipmentSummary> result =
            md_reportOrdersController.getDataForOrderItems(
                new List<Id>{ fakeOrderItemId }
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());

        System.assertEquals(
            String.valueOf(fakeOrderItemId),
            result[0].orderItemId
        );

        System.assertEquals(
            'TRUCK-001',
            result[0].vehicleID
        );

        System.assertEquals(
            String.valueOf(Date.today()),
            result[0].ShippedDate
        );
    }

    @IsTest
    static void testGetDataForOrderItemsEmptyResult() {

        md_reportOrdersDAO.testInjectedRecords =
            new List<ShipmentItem>();

        Test.startTest();

        List<md_reportOrdersWrapper.ShipmentSummary> result =
            md_reportOrdersController.getDataForOrderItems(
                new List<Id>{ '802000000000001AAA' }
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(0, result.size());
    }

    @IsTest
    static void testMapShipmentsPrefersFPD() {

        Id fakeOrderItemId = '802000000000001AAA';

        ShipmentItem normalShipment = new ShipmentItem(
            PMC_CPQ_OrderProduct__c = fakeOrderItemId,
            Shipment = new Shipment(
                PMC_CPQ_VehicleID__c = 'NORMAL',
                PMC_CPQ_ShippedDate__c = Date.today().addDays(-1)
            ),
            isFPD__c = false
        );

        ShipmentItem fpdShipment = new ShipmentItem(
            PMC_CPQ_OrderProduct__c = fakeOrderItemId,
            Shipment = new Shipment(
                PMC_CPQ_VehicleID__c = 'FPD',
                PMC_CPQ_ShippedDate__c = Date.today()
            ),
            isFPD__c = true
        );

        md_reportOrdersDAO.testInjectedRecords =
            new List<ShipmentItem>{
                normalShipment,
                fpdShipment
            };

        Test.startTest();

        List<md_reportOrdersWrapper.ShipmentSummary> result =
            md_reportOrdersController.getDataForOrderItems(
                new List<Id>{ fakeOrderItemId }
            );

        Test.stopTest();

        System.assertEquals(1, result.size());

        System.assertEquals(
            'FPD',
            result[0].vehicleID
        );
    }

    @IsTest
    static void testGetOrderFilterOptions_ReturnsFilterOptions() {
        md_reportOrdersDAO.testInjectedFieldValues = new Map<String, List<String>>{
            'PMC_CPQ_OrderLineStatus__c' => new List<String>{ 'Open', 'Shipped' },
            'Product2.Name' => new List<String>{ 'Product A', 'Product B' },
            'PMC_CPQ_ProductLocation__r.Name' => new List<String>{ 'FL, Riverview', 'MN, Rosemount' }
        };

        Test.startTest();

        md_reportOrdersWrapper.FilterOptions result =
            md_reportOrdersController.getOrderFilterOptions(
                null, null, null, null, null, null, null, null, null
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(2, result.orderStatus.size());
        System.assertEquals(2, result.product.size());
        System.assertEquals(2, result.origin.size());
        System.assertNotEquals(null, result.shipTo);
    }

    @IsTest
    static void testGetOrderFilterOptions_SortedAlphabetically() {
        md_reportOrdersDAO.testInjectedFieldValues = new Map<String, List<String>>{
            'PMC_CPQ_OrderLineStatus__c' => new List<String>{ 'Open', 'Shipped', 'Draft' },
            'Product2.Name' => new List<String>{ 'Zinc', 'Ammonia', 'Potash' },
            'PMC_CPQ_ProductLocation__r.Name' => new List<String>{ 'FL, Riverview', 'MN, Rosemount', 'TX, Houston' }
        };

        Test.startTest();

        md_reportOrdersWrapper.FilterOptions result =
            md_reportOrdersController.getOrderFilterOptions(
                null, null, null, null, null, null, null, null, null
            );

        Test.stopTest();

        System.assertEquals('Draft', result.orderStatus[0]);
        System.assertEquals('Shipped', result.orderStatus[2]);
        System.assertEquals('Ammonia', result.product[0]);
        System.assertEquals('Zinc', result.product[2]);
    }

    @IsTest
    static void testGetOrderFilterOptions_WithAppliedFilters() {
        md_reportOrdersDAO.testInjectedFieldValues = new Map<String, List<String>>{
            'PMC_CPQ_OrderLineStatus__c' => new List<String>{ 'Open' },
            'Product2.Name' => new List<String>{ 'Product A' },
            'PMC_CPQ_ProductLocation__r.Name' => new List<String>{ 'FL, Riverview' }
        };

        Test.startTest();

        md_reportOrdersWrapper.FilterOptions result =
            md_reportOrdersController.getOrderFilterOptions(
                null,
                null,
                null,
                null,
                null,
                new List<String>{ 'Open' },
                null,
                null,
                null
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(1, result.orderStatus.size());
        System.assertEquals('Open', result.orderStatus[0]);
    }

    @IsTest
    static void testGetOrderFilterOptions_EmptyResult() {
        md_reportOrdersDAO.testInjectedFieldValues = new Map<String, List<String>>();

        Test.startTest();

        md_reportOrdersWrapper.FilterOptions result =
            md_reportOrdersController.getOrderFilterOptions(
                null, null, null, null, null, null, null, null, null
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(0, result.orderStatus.size());
        System.assertEquals(0, result.product.size());
        System.assertEquals(0, result.origin.size());
        System.assertNotEquals(null, result.shipTo);
    }

    @IsTest
    static void testGetOrderFilterOptions_InvalidSoqlClause_ThrowsAuraHandledException() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            md_reportOrdersController.getOrderFilterOptions(
                'INVALID SOQL %%%', null, null, null, null, null, null, null, null
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();

        System.assert(exceptionThrown);
    }

    @IsTest
    static void testGetOrderFilterOptions_ResolvesShipToNames() {
        Id fakeShipToId = '001000000000001AAA';

        md_reportOrdersDAO.testInjectedFieldValues = new Map<String, List<String>>{
            'PMC_CPQ_ShipTo__c' => new List<String>{ String.valueOf(fakeShipToId) }
        };
        md_reportOrdersDAO.testInjectedShipToAccounts = new List<Account>{
            (Account) JSON.deserialize(
                '{"Id":"' + fakeShipToId + '","ShipToFormula__c":"Rondonopolis - MT"}',
                Account.class
            )
        };

        Test.startTest();

        md_reportOrdersWrapper.FilterOptions result =
            md_reportOrdersController.getOrderFilterOptions(
                null, null, null, null, null, null, null, null, null
            );

        Test.stopTest();

        System.assertEquals(1, result.shipTo.size());
        System.assertEquals('Rondonopolis - MT', result.shipTo[0]);
    }

    @IsTest
    static void testGetOrderFilterOptions_AllFiltersApplied() {
        md_reportOrdersDAO.testInjectedFieldValues = new Map<String, List<String>>{
            'PMC_CPQ_OrderLineStatus__c' => new List<String>{ 'Shipped' },
            'Product2.Name' => new List<String>{ 'Product A' },
            'PMC_CPQ_ProductLocation__r.Name' => new List<String>{ 'FL, Riverview' }
        };

        Test.startTest();

        md_reportOrdersWrapper.FilterOptions result =
            md_reportOrdersController.getOrderFilterOptions(
                'PMC_CPQ_ReasonOfRejectionOfItem__c = null',
                '4500123456',
                'PO-987',
                '2026-01-01',
                '2026-03-31',
                new List<String>{ 'Open', 'Shipped' },
                new List<String>{ 'Product A' },
                new List<String>{ 'FL, Riverview' },
                new List<String>{ 'Rondonopolis - MT' }
            );

        Test.stopTest();

        System.assertEquals(1, result.orderStatus.size());
        System.assertEquals('Shipped', result.orderStatus[0]);
        System.assertEquals(1, result.product.size());
        System.assertEquals(1, result.origin.size());
    }

    @IsTest
    static void testGetOrderFilterOptions_ShippedOnlyFilter() {
        md_reportOrdersDAO.testInjectedFieldValues = new Map<String, List<String>>{
            'Product2.Name' => new List<String>{ 'Product A' }
        };

        Test.startTest();

        md_reportOrdersWrapper.FilterOptions result =
            md_reportOrdersController.getOrderFilterOptions(
                null, null, null, '2026-01-01', null,
                new List<String>{ 'Shipped' }, null, null, null
            );

        Test.stopTest();

        System.assertEquals(1, result.product.size());
        System.assertEquals(0, result.shipTo.size());
    }

    @IsTest
    static void testDaoQueriesWithoutInjection() {
        Test.startTest();

        List<ShipmentItem> shipments =
            md_reportOrdersDAO.queryShipmentItemByOrderItemIds(new List<Id>{ '802000000000001AAA' });
        List<String> values =
            md_reportOrdersDAO.queryDistinctOrderItemValues('Product2.Name', 'Quantity > 0');
        List<String> valuesWithoutWhere =
            md_reportOrdersDAO.queryDistinctOrderItemValues('PMC_CPQ_OrderLineStatus__c', null);
        List<Account> shipToAccounts =
            md_reportOrdersDAO.queryShipToAccountsByIds(new Set<Id>());

        Test.stopTest();

        System.assertNotEquals(null, shipments);
        System.assertNotEquals(null, values);
        System.assertNotEquals(null, valuesWithoutWhere);
        System.assertEquals(0, shipToAccounts.size());
    }

    @IsTest
    static void testGetDataForOrderItems_EmptyInput() {
        Test.startTest();

        List<md_reportOrdersWrapper.ShipmentSummary> result =
            md_reportOrdersController.getDataForOrderItems(new List<Id>());

        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @IsTest
    static void testGetDataForOrderItems_ServiceException() {
        md_reportOrdersService.forceException = true;
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            md_reportOrdersController.getDataForOrderItems(new List<Id>{ '802000000000001AAA' });
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        md_reportOrdersService.forceException = false;
        System.assert(exceptionThrown);
    }

    @IsTest
    static void testFilterOptions_Defaults() {
        md_reportOrdersWrapper.FilterOptions opts = new md_reportOrdersWrapper.FilterOptions();

        System.assertNotEquals(null, opts.orderStatus);
        System.assertNotEquals(null, opts.product);
        System.assertNotEquals(null, opts.origin);
        System.assertNotEquals(null, opts.shipTo);

        System.assertEquals(0, opts.orderStatus.size());
        System.assertEquals(0, opts.product.size());
        System.assertEquals(0, opts.origin.size());
        System.assertEquals(0, opts.shipTo.size());
    }
}