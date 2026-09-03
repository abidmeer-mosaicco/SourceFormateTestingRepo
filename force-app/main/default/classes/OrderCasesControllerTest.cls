@isTest
private class OrderCasesControllerTest {

    @isTest
    static void testGetRelatedCases() {
        // Create an Account to support Order & Contact records.
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create an Order record. Order requires an EffectiveDate and Status.
        Order ord = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            PMC_CPQ_SoldToAccount__c = acc.Id,
            PMC_CPQ_SAPOrderNumber__c = '6576512'
        );
        insert ord;
        
        // Create a Contact record.
        Contact cont = new Contact(
            LastName = 'Test Contact',
            AccountId = acc.Id
        );
        insert cont;
        //added for GSMD- 1534
        SObject loc = new Schema.Location(Name = 'Test');
        insert loc;
        
        // Create a Case record related to the Order.
        Case cs = new Case(
            Subject = 'Test Case Subject',
            Status = 'New',
            Type = 'Inquiry',
            ContactId = cont.Id,
            PMC_SS_AtFaultParty__c = 'Warehouse',
            PMC_SS_Location__c= loc.Id,
            PMC_SS_Order__c = ord.Id
        );
        insert cs;
        
        Test.startTest();
            // Execute the getRelatedCases method.
            List<Case> casesRetrieved = OrderCasesController.getRelatedCases(ord.Id);
            System.debug('Number of cases retrieved: ' + casesRetrieved.size());
        Test.stopTest();
    }

    @isTest
    static void testGetOrderDetails() {
        // Create an Account record.
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create a Contact record to use with the Contract.
        Contact cont = new Contact(
            LastName = 'Test Contact',
            AccountId = acc.Id
        );
        insert cont;
        
        // Create a Contract record.
        Contract con = new Contract(
            AccountId = acc.Id,
            Status = 'Draft',
            StartDate = Date.today()
        );
        // Assuming 'CustomerSignedId' accepts a Contact Id.
        con.CustomerSignedId = cont.Id;
        insert con;
        
        // Create an Order record related to the Contract.
        Order ord = new Order(
            AccountId = acc.Id,
            ContractId = con.Id,
            Status = 'Draft',
            PMC_CPQ_SoldToAccount__c = acc.Id,
            PMC_CPQ_SAPOrderNumber__c = '6576512'
        );
        insert ord;
        
        Test.startTest();
            // Execute the getOrderDetails method.
            Map<String, Object> orderDetails = OrderCasesController.getOrderDetails(ord.Id);
            System.debug('Order Details Map: ' + orderDetails);
        Test.stopTest();
    }
}