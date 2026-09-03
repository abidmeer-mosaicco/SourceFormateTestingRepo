/**
 * @description This test class will be used to cover all the methods of PMC_SS_ConstantClass
 * @author Sayali Shinde
 */

 @isTest(seeAllData = false)
 private class PMC_SS_ConstantClassTest {
 
     /**
     * @description This Method will be used to check contants.
     */
     
    @isTest
    private static void testConstantVerification() {
        Test.startTest();
        PMC_SS_ConstantClass objContatnt = new PMC_SS_ConstantClass();
        Test.stopTest();        
        System.assertEquals(true, objContatnt.boolTestSetup, 'Contant Matched');
    }
 }