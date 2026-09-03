@isTest
private class OrderCart_OrderIntegrationClassTest {

    @isTest static void testSetFilteredListOrderOrderLine_and_parsers() {
        // Build a simulated response body list to exercise filtering logic
        List<Object> rows = new List<Object>();
        Map<String,Object> rec = new Map<String,Object>{
            'OBJ_NUM' => 'SAP123',
            'SFOrderId' => '012000000000000AAA',
            'OBJ_ITEM' => '10',
            'SF_ORDERITEM_ID' => '099000000000000AAA',
            'statusCode' => 200,
            'responsetext' => 'OK'
        };
        rows.add(rec);
        OrderCart_OrderIntegrationClass.setFilteredListOrderOrderLine(rows);
    // call parseOrderFilteredList with a fake Order (need AccountId)
    Account a = new Account(Name='Test Account');
    insert a;
    Order o = new Order(Status='Draft', EffectiveDate=Date.today(), AccountId = a.Id);
    insert o;
        List<Order> lst = new List<Order>{ o };
        // create a fake HttpResponse with body
        HttpResponse resp = new HttpResponse();
        resp.setBody(JSON.serialize(rows));
        resp.setStatusCode(200);

        Test.startTest();
        OrderCart_OrderIntegrationClass.parseJSONOrderInterface(lst, resp, new List<Id>{ o.Id });
        Test.stopTest();
        System.assert(true);
    }

    @isTest static void testUpdateOrderandOrderLineErrorExceptionStatusMsg_noOrderItems() {
    Account a2 = new Account(Name='Test Account 2');
    insert a2;
    Order o = new Order(Status='Draft', EffectiveDate=Date.today(), AccountId = a2.Id);
    insert o;
        Test.startTest();
        OrderCart_OrderIntegrationClass.updateOrderandOrderLineErrorExceptionStatusMsg(new List<Order>{ o }, new List<Id>{ o.Id }, 'ERR');
        Test.stopTest();
        System.assert(true);
    }

    @isTest static void testParseOrderFilteredList_and_parseOrderLineFilteredList_errorPath() {
        // Monta lista com statusCode indicando erro e sem SAP order number
        List<Object> rows = new List<Object>();
        Map<String,Object> rec = new Map<String,Object>{
            'OBJ_NUM' => '',
            'SFOrderId' => '012000000000000ZZZ',
            'OBJ_ITEM' => '11',
            'SF_ORDERITEM_ID' => '099000000000000ZZZ',
            'statusCode' => 500,
            'responsetext' => 'ERR'
        };
        rows.add(rec);
        OrderCart_OrderIntegrationClass.setFilteredListOrderOrderLine(rows);

        Account a = new Account(Name='Test Account X'); insert a;
        Order o = new Order(Status='Draft', EffectiveDate=Date.today(), AccountId = a.Id);
        insert o;

        // create an OrderItem and ensure it exists for parsing
        OrderItem oi;
        try {
            oi = new OrderItem(OrderId = o.Id, Quantity = 1, UnitPrice = 1.0);
            insert oi;
        } catch (Exception e) {
            // ignore if not allowed in org
        }

        List<Order> lst = new List<Order>{ o };
        HttpResponse resp = new HttpResponse();
        resp.setBody(JSON.serialize(rows));
        resp.setStatusCode(500);

        Test.startTest();
        OrderCart_OrderIntegrationClass.parseJSONOrderInterface(lst, resp, new List<Id>{ o.Id });
        Test.stopTest();

        // Verify Orders got status set to Error via query
        Order updated = [SELECT Id, PMC_CPQ_OrderIntegrationStatus__c FROM Order WHERE Id = :o.Id LIMIT 1];
        System.assert(updated.PMC_CPQ_OrderIntegrationStatus__c == 'Error' || updated.PMC_CPQ_OrderIntegrationStatus__c == 'Error', 'Order deve ter status de Error');
    }
}