/** @description This is the test class to Test ConvertErrorMessageClass
 *  @author Shefali Dsouza
 *  @storynumber GDASF-18246
 */

@isTest
public class PMC_CPQ_ConvertErrorMessageTest {
  @isTest
    public static void testconvertToUserFriendlyMsg()
    { 
        List<String>lstPermissionNames = New List<String>{'PMC_SLS_Permission_Set_Group'};
        System.runAs(PMC_CPQ_CPIRemoteCalloutUtilityTest.createCPQTestUser('Sales User',lstPermissionNames)){
        List<String> lstExactMatch = New List<String>();
        lstExactMatch.add('Match Not Found');
        lstExactMatch.add('Internal Server Error');
        lstExactMatch.add('Unexpected character');
        String strMatchNotFound = PMC_CPQ_ConvertErrorMessageClass.convertToUserFriendlyMsg(lstExactMatch)[0];
        String strEqualsMatchFound = PMC_CPQ_ConvertErrorMessageClass.convertToUserFriendlyMsg(lstExactMatch)[1];
        String strContainsMatchFound = PMC_CPQ_ConvertErrorMessageClass.convertToUserFriendlyMsg(lstExactMatch)[2];
        
        System.assertEquals(strMatchNotFound,'Match Not Found','No transformation is applied');
        System.assertNotEquals(strEqualsMatchFound,'Internal Server Error','Transformation applied');
        System.assertNotEquals(strContainsMatchFound,'Unexpected character','Transformation applied');
        }
    }  
}