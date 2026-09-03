@isTest
public class OrderLineCasesControllerTest {

    @isTest
    static void testGetRelatedCases() {
        // Create an Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create an Order with the correct Pricebook2Id
        Order ord = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            PMC_CPQ_SoldToAccount__c = acc.Id,
            PMC_CPQ_SAPOrderNumber__c = '6576512'
        );
        insert ord;
        
        // Create a Contact
        Contact cont = new Contact(
            LastName = 'Test Contact',
            AccountId = acc.Id
        );
        insert cont;
        
        // Create a Case
        Case cs = new Case(
            Subject = 'Test Case Subject',
            Status = 'New',
            Type = 'Inquiry',
            ContactId = cont.Id,
            PMC_SS_AtFaultParty__c = 'Carrier',
            PMC_SS_Order__c = ord.Id
        );
        insert cs;
        
        // Create a Product
        Product2 product = PMC_TestUtilityClass.createProduct(1, 'PMC_CPQ_NA')[0];
        
        PricebookEntry entry = new PricebookEntry();
        entry.Pricebook2Id = Test.getStandardPriceBookId();
        entry.Product2Id = product.Id;
        entry.UnitPrice = 100;
        insert entry;
        
        // Create and insert the OrderItem, which must reference the inserted PricebookEntry
        OrderItem ordItem = new OrderItem(
            OrderId = ord.Id,
            Product2Id = product.Id,
            Quantity = 1,
            ListPrice = 100,
            PMC_CPQ_ListPrice__c = 100,
            UnitPrice = 100,
            PMC_CPQ_ContractType__c = 'FPD'
        );
        insert ordItem;
        
        Test.startTest();
            // Execute the getRelatedCases method.
            List<Case> casesRetrieved = OrderLineCasesController.getRelatedCases(ordItem.Id);
            System.debug('Number of cases retrieved: ' + casesRetrieved.size());
        Test.stopTest();
    }

    @isTest
    static void testGetOrderDetails() {
        // Create an Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create an Order with the correct Pricebook2Id
        Order ord = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            PMC_CPQ_SoldToAccount__c = acc.Id,
            PMC_CPQ_SAPOrderNumber__c = '6576512'
        );
        insert ord;
        
        // Create a Contact
        Contact cont = new Contact(
            LastName = 'Test Contact',
            AccountId = acc.Id
        );
        insert cont;
        
        // Create a Case
        Case cs = new Case(
            Subject = 'Test Case Subject',
            Status = 'New',
            Type = 'Inquiry',
            ContactId = cont.Id,
            PMC_SS_AtFaultParty__c = 'Carrier',
            PMC_SS_Order__c = ord.Id
        );
        insert cs;
        
        // Create a Product
        Product2 product = PMC_TestUtilityClass.createProduct(1, 'PMC_CPQ_NA')[0];
        
        PricebookEntry entry = new PricebookEntry();
        entry.Pricebook2Id = Test.getStandardPriceBookId();
        entry.Product2Id = product.Id;
        entry.UnitPrice = 100;
        insert entry;
        
        // Create and insert the OrderItem, which must reference the inserted PricebookEntry
        OrderItem ordItem = new OrderItem(
            OrderId = ord.Id,
            Product2Id = product.Id,
            Quantity = 1,
            ListPrice = 100,
            PMC_CPQ_ListPrice__c = 100,
            UnitPrice = 100,
            PMC_CPQ_ContractType__c = 'FPD'
        );
        insert ordItem;
        
        Test.startTest();
            // Execute the getOrderDetails method.
            Map<String, Object> orderDetails = OrderLineCasesController.getOrderItemDetails(ordItem.Id);
            System.debug('Order Details Map: ' + orderDetails);
        Test.stopTest();
    }
}