@IsTest
private class MosaicDirectOrderTableCtrlTest {
    @IsTest
    static void test_getOrderCart_withData(){

        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;

        Contract cont = new Contract(
            AccountId = acc.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 12
        );
        insert cont;

        Product2 product = new Product2(
            Name = 'Test Product',
            Family = 'Test',
            PMC_CPQ_SAPProductCode__c = 'SAP123'
        );
        insert product;

        OrderCart__c cart = new OrderCart__c(
            Contract__c = cont.Id, 
            Status__c = 'Active'
        );
        insert cart;

        OrderCartItem__c item = new OrderCartItem__c(
            OrderCart__c = cart.Id,
            SBQQ_Product__c = product.Id,
            Origin__c = 'Web',
            OrderQty__c = 10,
            Ship_Method__c = 'Ground',
            ReqShipmentDate__c = Date.today().addDays(5),
            OrderPoNumber__c = '12345', 
            Ship_To__c = 'Warehouse A', 
            ShipToDisplay__c = 'Warehouse A'
        );
        insert item;

        Test.startTest();
        MosaicDirectOrderTableCtrl.OrderCartWrapper result = MosaicDirectOrderTableCtrl.getOrderCart(cont.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Wrapper should not be null');
        System.assertEquals(1, result.orderCarts.size(), 'Should return one cart');
        System.assertEquals(1, result.items.size(), 'Should return one item');

        MosaicDirectOrderTableCtrl.OrderCartItemWrapper returnedItem = result.items[0];

        System.assertEquals(item.Id, returnedItem.Id, 'IDs should match');
        System.assertEquals('SAP123', returnedItem.PMC_CPQ_SAPProductCode, 'SAP code should map');
    }

    @IsTest
    static void test_getOrderCart_noData() {
        Account acc = new Account(
            Name = 'Empty Account'
        );
        insert acc;

        Contract cont = new Contract(
            AccountId = acc.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 6
        );
        insert cont;

        Test.startTest();
        MosaicDirectOrderTableCtrl.OrderCartWrapper result = MosaicDirectOrderTableCtrl.getOrderCart(cont.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Wrapper should not be null');
        System.assertEquals(0, result.orderCarts.size(), 'Should return no carts');
        System.assertEquals(0, result.items.size(), 'Should return empty item list');
    }

}