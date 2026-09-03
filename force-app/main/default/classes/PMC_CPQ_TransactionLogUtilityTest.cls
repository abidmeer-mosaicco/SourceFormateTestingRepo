/** @description This is the test class to test transaction logs
 *  @author Shefali Dsouza
 *  @storynumber GDASF-6864, GDASF-5842
 */

@isTest
public class PMC_CPQ_TransactionLogUtilityTest {
    public static List<PMC_CPQ_TransactionLog__c> lstTransactionLogs = new List<PMC_CPQ_TransactionLog__c>();
    
    /** 
     * @description Creates Transaction Logs for testing 
     */
    @isTest
	public static void createTransactionLog() { 
        
        List<String>lstPermissionNames = New List<String>{'PMC_SLS_Permission_Set_Group'};
        System.runAs(PMC_CPQ_CPIRemoteCalloutUtilityTest.createCPQTestUser('Sales User',lstPermissionNames)){
        String strTransactionLogStatus = 'Error';
        String strEndpoint = '/http/test';
        String strRequestBody = '{"Id":["a3CDT000001Sv2I2AS"]}';
        String strResponseBody = 'Internal Server Error';
        Map<String, String> mapTransactionLogFields = new Map<String,String>();
        
        mapTransactionLogFields.put('PMC_CPQ_IntegrationStatus__c',strTransactionLogStatus);
        mapTransactionLogFields.put('PMC_CPQ_InterfaceURL__c',strEndpoint);
        mapTransactionLogFields.put('PMC_CPQ_RequestBody__c',strRequestBody);
        mapTransactionLogFields.put('PMC_CPQ_ResponseBody__c',strResponseBody);
        
        Test.startTest();

        lstTransactionLogs = PMC_CPQ_TransactionLogUtilityClass.addTransactionLog(mapTransactionLogFields);
        PMC_CPQ_TransactionLogUtilityClass.insertTransactionLogs(lstTransactionLogs);
        
        Test.stopTest();
        
        System.assert(!lstTransactionLogs.isEmpty(), 'List should not be empty');
	}
	}
	
}