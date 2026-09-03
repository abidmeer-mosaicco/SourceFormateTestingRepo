@isTest
public class PMC_CPQ_QLApprovalReqEmailTempTest {

    @testSetup  
    static void setup(){
        List<Order> lstOrders = PMC_CPQ_OrderIntegrationTest.createOrders(1);
        if (!lstOrders.isEmpty() && lstOrders[0].Id == null) {
            insert lstOrders; 
        }

        User objUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        System.runAs(objUser){  
            List<Product2> prod = PMC_TestUtilityClass.createProduct(1,'PMC_CPQ_NA');
            if (!prod.isEmpty() && prod[0].Id == null) {
                insert prod;
            }
            prod[0].PMC_CPQ_SAPProductCode__c = '';
            update prod[0];

            Pricebook2 standardPricebook = new Pricebook2(
                Id = Test.getStandardPricebookId(),
                IsActive = true
            );
            update standardPricebook;

            lstOrders[0].Pricebook2Id    = standardPricebook.Id;
            lstOrders[0].CurrencyIsoCode = 'USD';
            update lstOrders;

            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id    = standardPricebook.Id,
                Product2Id      = prod[0].Id,
                UnitPrice       = 0,
                CurrencyIsoCode = lstOrders[0].CurrencyIsoCode,
                IsActive        = true
            );
            insert pbe;

            OrderItem objOrderProducts = new OrderItem();
            objOrderProducts.Product2Id                 = prod[0].Id;
            objOrderProducts.OrderId                    = lstOrders[0].Id;
            objOrderProducts.Quantity                   = 2;
            objOrderProducts.UnitPrice                  = 0;
            objOrderProducts.ListPrice                  = 0;
            objOrderProducts.PMC_CPQ_FinalAgreedPrice__c = 1;
            objOrderProducts.PricebookEntryId           = pbe.Id;
            insert objOrderProducts;
        }
    }
    
    @isTest
    static void testGetOLines() {
        OrderItem testOrderItem = [SELECT Id FROM OrderItem LIMIT 1];

        PMC_CPQ_QLApprovalReqEmailTempClass emailTempClass = new PMC_CPQ_QLApprovalReqEmailTempClass();
        emailTempClass.orderItemId = testOrderItem.Id;

        List<OrderItem> oLines = emailTempClass.oLines;

        System.assertNotEquals(null, oLines, 'oLines should not be null');
        System.assertEquals(1, oLines.size(), 'oLines should contain one OrderItem');
        System.assertEquals(testOrderItem.Id, oLines[0].Id, 'The OrderItem Id should match the one created in setup');
    }

    @isTest
    static void testGetOLinesWithNullOrderItemId() {
        PMC_CPQ_QLApprovalReqEmailTempClass emailTempClass = new PMC_CPQ_QLApprovalReqEmailTempClass();

        List<OrderItem> oLines = emailTempClass.oLines;

        System.assertEquals(null, oLines, 'oLines should be null when orderItemId is not set');
    }
}