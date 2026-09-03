/**
 * @description       : 
 * @author            : siddharth.pradhan@mosaicco.com | Digital Hub
 * @group             : 
 * @last modified on  : 06-18-2023
 * @last modified by  : siddharth.pradhan@mosaicco.com | Digital Hub
**/
@isTest
public class PMC_DH_ConstantClassTest {
  
    @isTest
    private static void testConstantVerification() {
        Test.startTest();
        PMC_DH_ConstantClass objContatnt = new PMC_DH_ConstantClass();
        Test.stopTest();        
        System.assertEquals(true, objContatnt.boolDHTestSetup, 'Contant Matched');
    }
        
}