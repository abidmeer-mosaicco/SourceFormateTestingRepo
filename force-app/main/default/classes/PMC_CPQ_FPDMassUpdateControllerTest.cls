/**
 * @description Test class for PMC_CPQ_FPDMassUpdateController
 * Covers filtering logic, numeric sorting by SAP Line ID, and dynamic SOQL generation.
 */
@IsTest
private class PMC_CPQ_FPDMassUpdateControllerTest {

    // --- Data Factory Helpers ---

    private static Pricebook2 ensureStandardPricebookActive() {
        Id stdPbId = Test.getStandardPricebookId();
        Pricebook2 pb = new Pricebook2(Id = stdPbId, IsActive = true);
        try { 
            update pb; 
        } catch (Exception e) {}
        return pb;
    }

    private static PricebookEntry createPbe(Id pbId, Id prodId) {
        List<PricebookEntry> existing = [
            SELECT Id, Product2Id, UnitPrice 
            FROM PricebookEntry 
            WHERE Pricebook2Id = :pbId 
            AND Product2Id = :prodId 
            AND CurrencyIsoCode = 'USD'
            LIMIT 1
        ];

        if (!existing.isEmpty()) {
            return existing[0];
        }

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pbId,
            Product2Id = prodId,
            UnitPrice = 100.00,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert pbe;
        
        return [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Id = :pbe.Id];
    }

    // --- Test Setup ---

    @TestSetup
    static void setupData() {
        String ts = String.valueOf(System.currentTimeMillis());
        
        Account acc = new Account(Name = 'Mass Update Account ' + ts);
        insert acc;

        Pricebook2 pb = ensureStandardPricebookActive();
        
        Product2 prod = new Product2(
            Name = 'FPD Product ' + ts, 
            IsActive = true, 
            PMC_CPQ_MaterialGroup__c = 'Potash',
            ProductCode = 'CODE-' + ts
        );
        insert prod;
        
        PricebookEntry pbe = createPbe(pb.Id, prod.Id);

        // Parent Order defines the currency for all child items
        Order ord = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = pb.Id,
            PMC_CPQ_SAPOrderNumber__c = '9000123',
            OwnerId = UserInfo.getUserId(),
            CurrencyIsoCode = 'USD'
        );
        insert ord;

        List<OrderItem> items = new List<OrderItem>();
        
        items.add(new OrderItem(
            OrderId = ord.Id,
            PricebookEntryId = pbe.Id,
            Product2Id = pbe.Product2Id,
            Quantity = 1,
            UnitPrice = 100,
            ListPrice = 100, // Integrity match
            PMC_CPQ_ContractType__c = 'FPD',
            PMC_CPQ_SAPOrderLineID__c = '100_10',
            PMC_CPQ_OrderItemIntegrationStatus__c = 'Error'
        ));

        items.add(new OrderItem(
            OrderId = ord.Id,
            PricebookEntryId = pbe.Id,
            Product2Id = pbe.Product2Id,
            Quantity = 1,
            UnitPrice = 100,
            ListPrice = 100,
            PMC_CPQ_ContractType__c = 'FPD',
            PMC_CPQ_SAPOrderLineID__c = '100_05',
            PMC_CPQ_FinalAgreedPrice__c = 0
        ));

        insert items;
    }

    // --- Test Methods ---

    @IsTest
    static void testGetOPDetailsSortingAndFilters() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Order ord = [SELECT Id FROM Order LIMIT 1];

        PMC_CPQ_FPDMassUpdateController.GetOPDetailsParams params = new PMC_CPQ_FPDMassUpdateController.GetOPDetailsParams();
        params.acctId = acc.Id;
        params.prodId = prod.Id;
        params.ordId = ord.Id; 

        Test.startTest();
        String jsonRes = PMC_CPQ_FPDMassUpdateController.getOPDetails(JSON.serialize(params));
        Test.stopTest();

        List<Object> results = (List<Object>) JSON.deserializeUntyped(jsonRes);
        System.assertNotEquals(0, results.size());
        
        Map<String, Object> firstItem = (Map<String, Object>) results[0];
        System.assertEquals('100_05', (String)firstItem.get('sapOrderLineID'), 'Should sort 10005 before 10010');
    }

    @IsTest
    static void testGetDefaultOrderLines() {
        Test.startTest();
        String jsonRes = PMC_CPQ_FPDMassUpdateController.getDefaultOrderLines();
        Test.stopTest();

        List<Object> results = (List<Object>) JSON.deserializeUntyped(jsonRes);
        System.assert(results.size() > 0);
    }

    @IsTest
    static void testFilteringBySapOrderNumberLogic() {
        Order ord = [SELECT Id, PMC_CPQ_SAPOrderNumber__c FROM Order LIMIT 1];

        PMC_CPQ_FPDMassUpdateController.GetOPDetailsParams params = new PMC_CPQ_FPDMassUpdateController.GetOPDetailsParams();
        params.ordId = ord.Id;

        Test.startTest();
        String jsonRes = PMC_CPQ_FPDMassUpdateController.getOPDetails(JSON.serialize(params));
        Test.stopTest();

        System.assert(jsonRes.contains('9000123'), 'Result should include the SAP number from the related Order');
    }
    
    @IsTest
    static void testNullSapIdHandling() {
        // 1. Get the Order and explicitly check its Currency
        Order ord = [SELECT Id, CurrencyIsoCode FROM Order LIMIT 1];
        
        // 2. Get a PricebookEntry that MATCHES the Order's currency
        // This prevents the FIELD_INTEGRITY_EXCEPTION
        PricebookEntry pbe = [
            SELECT Id, Product2Id, UnitPrice 
            FROM PricebookEntry 
            WHERE CurrencyIsoCode = :ord.CurrencyIsoCode 
            AND IsActive = true 
            LIMIT 1
        ];
        
        // 3. Insert the Item (CurrencyIsoCode is inherited from 'ord')
        insert new OrderItem(
            OrderId = ord.Id,
            PricebookEntryId = pbe.Id,
            Product2Id = pbe.Product2Id,
            Quantity = 5,
            UnitPrice = pbe.UnitPrice,
            ListPrice = pbe.UnitPrice, // Integrity match
            PMC_CPQ_ContractType__c = 'FPD',
            PMC_CPQ_SAPOrderLineID__c = null,
            PMC_CPQ_FinalAgreedPrice__c = null
        );

        PMC_CPQ_FPDMassUpdateController.GetOPDetailsParams params = new PMC_CPQ_FPDMassUpdateController.GetOPDetailsParams();
        
        Test.startTest();
        String jsonRes = PMC_CPQ_FPDMassUpdateController.getOPDetails(JSON.serialize(params));
        Test.stopTest();

        System.assert(jsonRes.contains('null'), 'The result should contain the item with a null SAP ID');
    }
}