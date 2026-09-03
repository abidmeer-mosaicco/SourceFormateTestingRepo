@IsTest
public class QuoteUpdateUtilsTest {
    @IsTest
    static void testCreateContractJson() {
        QuoteUpdateUtils utils = new QuoteUpdateUtils();
        Test.startTest();
        QuoteUpdateUtils.ContractJsonResult result = utils.createContractJson(null);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(false, result.success, 'Result should indicate failure when executionLineId is null');
        System.assertEquals('Execution Line ID is null', result.message, 'Result message should indicate null execution line ID');
    }
}