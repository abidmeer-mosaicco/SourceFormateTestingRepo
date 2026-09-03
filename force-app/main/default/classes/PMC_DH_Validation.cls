/** 
* @description Validation class for Quote/Contract/Order Details page 
* @author Krishan
* @last modified on 2023-August-22
* @last modified by Krishan
* Created On       :2023-August-22
**/
public class PMC_DH_Validation {
		/*************************************************************************
	@description Class for custom exception 
	* @author Krishan
	*****************************************************************************/
    @testVisible
    private Boolean boolDHTestSetup = false;
public class CustomException extends Exception{}
		/*************************************************************************
	* @method Name  : throwException
	* @description  : Method to throw custom exception
	*****************************************************************************/
	/*public static void throwException()
	{
		throw new CustomException(PMC_DH_ConstantClass.ACCESS_DENIED);
	} comment due to no usage*/
    
    
    public PMC_DH_Validation()
    {
        if(Test.isRunningTest())
        {
            boolDHTestSetup =true;
        }
    } 
}