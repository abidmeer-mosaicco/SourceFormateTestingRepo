/** @description This is class to convert Error Messages to User Friendly Error Messages.
 *  @author Shefali Dsouza
 *  @storynumber GDASF-18246
 */

public with sharing class PMC_CPQ_ConvertErrorMessageClass {
    /** 
     * @description Converts Integration Error Messages to User Friendly Messages
     * @param lstErrorMsg - List of Error Messages
     * @return strReturnList - List of User Friendly Message
     */
	public static List<String> convertToUserFriendlyMsg(List<String> lstErrorMsg){
        List<PMC_CPQ_ErrorMessageSettings__mdt> lstErrorMsgDetails = PMC_CPQ_ErrorMessageSettings__mdt.getAll().values();
        List<String> strReturnList = new List<String>();
        Pattern strPattern;
        Matcher strMatcher;
        
        for(String strErrorMsg : lstErrorMsg )
        {
			for(PMC_CPQ_ErrorMessageSettings__mdt objErrorMsgSetting : lstErrorMsgDetails)
            {
                strPattern = Pattern.compile(objErrorMsgSetting.PMC_CPQ_RegexExpression__c);
                strMatcher = strPattern.matcher(strErrorMsg);
                if(strMatcher.matches())//match found
                {
                    strReturnList.add(objErrorMsgSetting.PMC_CPQ_ConvertedErrorMessage__c);
                    break;
                }
            }
            strReturnList.add(strErrorMsg);// no match found
        }
        return strReturnList;
    }
}