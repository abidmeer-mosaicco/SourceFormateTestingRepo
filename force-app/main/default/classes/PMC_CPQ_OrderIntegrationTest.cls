/** @description This is the test class to make callouts to the Quote and Contract Creation interface of CPI. 
 *  @author Shefali Dsouza
 *  @storynumber GDASF-6864, GDASF-5842
 */

@isTest
public class PMC_CPQ_OrderIntegrationTest {
    
    public static List <String> lstPayloadOrderIds = new List<String> ();
    public static List <String> lstPayloadOrderLineIds = new List<String> ();
    
     /** 
     * @description Used to create Orders 
     * @param numOrders - No of Orders to be created
     * @return lstOrders - return list of orders
     */
    public static List<Order> createOrders(Integer numOrders) {
        List<Account> lstAccount = new List<Account>(); 
        List<Order> lstOrders = new List<Order>();
        Account objAccount = PMC_TestUtilityClass.createAccount('The Mosaic Company1','PMC_SS_Prospect');
        lstAccount.add(objAccount);
        lstOrders = PMC_TestUtilityClass.createOrders(1, lstAccount);
        return lstOrders;
	}
    
   /** 
     * @description Used to create Order with Order Items
     * @param numOrders - No of Orders to be created
     * @return lstOrders - return list of orders
     */
    
    public static List<Order> createOrderswithLineItems(Integer numOrders) {
        List<Account> lstAccount = new List<Account>(); 
        List<Order> lstOrders = new List<Order>();
        Account objAccount = PMC_TestUtilityClass.createAccount('The Mosaic Company1','PMC_SS_Prospect');
        lstAccount.add(objAccount);
        lstOrders = PMC_TestUtilityClass.createOrders(1, lstAccount);
        PMC_TestUtilityClass.createOrderProducts(1, lstOrders);
        return lstOrders;
	}
    
    /** 
     * @description Used to invoke apex. Tests Order success scenario. 
     */
    @isTest
    public static void testInvocableOrdersCreateSuccess()
    {
       
        List<Order> lstOrders = PMC_CPQ_OrderIntegrationTest.createOrderswithLineItems(1);
		List<OrderItem> lstOrderLines = [SELECT Id FROM OrderItem Where OrderId IN : lstOrders ];
        
		for(Order objOrder : lstOrders)
        {
            lstPayloadOrderIds.add(objOrder.Id);
        }
        
        for(OrderItem objItem : lstOrderLines)
        {
            lstPayloadOrderLineIds.add(objItem.Id);
        }

        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpOrderCalloutMockSuccess());
        PMC_CPQ_OrderCreateActionClass.postInfoToCPI(lstOrders);
        Test.stopTest();
        
        System.assert(!lstOrders.isEmpty(), 'List should not be empty');
    } 
    
        
    /** 
     * @description Used to invoke apex. Test scenario where status = Sucess and Status = Failure
     */
    @isTest
    public static void testInvocableOrdersCreatePartialSuccess()
    {
        
         List<Order> lstOrders = PMC_CPQ_OrderIntegrationTest.createOrderswithLineItems(1);
		List<OrderItem> lstOrderLines = [SELECT Id FROM OrderItem Where OrderId IN : lstOrders ];
		for(Order objOrder : lstOrders)
        {
            lstPayloadOrderIds.add(objOrder.Id);
        }
        
        for(OrderItem objItem : lstOrderLines)
        {
            lstPayloadOrderLineIds.add(objItem.Id);
        }
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpOrderCalloutPartialSuccess());
        PMC_CPQ_OrderCreateActionClass.postInfoToCPI(lstOrders);
        Test.stopTest();
        
        System.assert(!lstOrders.isEmpty(), 'List should not be empty');
    }
    /** 
     * @description Used to invoke apex. Tests scenario where we cannot make an apex callout.
     */
    @isTest
    public static void testInvocableOrdersException()
    {
        List<Order> lstOrders = PMC_CPQ_OrderIntegrationTest.createOrders(1);
        
        Test.startTest();
        PMC_CPQ_OrderCreateActionClass.postInfoToCPI(lstOrders);
        PMC_CPQ_CPIRemoteCalloutUtilityClass.autoRetryQueueableApex(0,'Read Timed Out');
        Test.stopTest();
        
        System.assert(!lstOrders.isEmpty(), 'List should not be empty');
    }  

 	/** 
     * @description Used to invoke apex. Tests scenario where response code returned is not 200/201.
     */
    @isTest
    public static void testInvocableOrderStatusCodeFailure()
    {
        List<Order> lstOrders = PMC_CPQ_OrderIntegrationTest.createOrders(1);
        
        Test.startTest();
		Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpCalloutMockSCodeFailureTest());
		PMC_CPQ_OrderCreateActionClass.postInfoToCPI(lstOrders);
        Test.stopTest();
        
        System.assert(!lstOrders.isEmpty(), 'List should not be empty');
    }
    
    /** 
     * @description Used to invoke apex. Tests Parsing failure scenario where status code returned is 200/201. However, the response body format is not correct.
     */
    @isTest
    public static void testInvocableOrderParsingFailure()
    {
        List<Order> lstOrders = PMC_CPQ_OrderIntegrationTest.createOrders(1);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PMC_CPQ_HttpCalloutMockParseFailureTest());
        PMC_CPQ_OrderCreateActionClass.postInfoToCPI(lstOrders);
        Test.stopTest();

        System.assert(!lstOrders.isEmpty(), 'List should not be empty');
    }
}