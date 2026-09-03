/** 
* @description Controller for Seedz Response
* @author Humera Rahath
* @last modified on 08-29-2023
* @last modified by Humera Rahath
* Created On       :2023-Aug- 29
**/
public with sharing class PMC_DH_SeedzController {
	private static final String SEEDZ_SESSIONCACHE='CPFNUMBER';
    private static final String SEEDZ_ERRORMESSAGE='PMC_DH_SeedzErrorMessage';
/*************************************************************************
* @method Name  : getSeedzPoints
* @description  : Method to assign the Seedz Points in Wrapper class
* @return       : PMC_DH_GetSeedzWrapper
*****************************************************************************/
    @AuraEnabled
    Public static PMC_DH_GetSeedzWrapper getSeedzPoints(){
        PMC_DH_GetSeedzWrapper getSeedzWrapper = new PMC_DH_GetSeedzWrapper();
        Map<String,Object> mapResponsePoints;
        //fetch CPF number on contact
        String strUserId=userInfo.getUserId();
        String strConCPF=[select Contact.PMC_SS_CPF__c from user where id =:strUserId WITH SYSTEM_MODE][0].Contact.PMC_SS_CPF__c;
        HttpResponse response;

        //
        Map<String,PMC_DH_Store_Configuration__mdt> mcs = PMC_DH_Store_Configuration__mdt.getAll();
        PMC_DH_Store_Configuration__mdt configure = mcs.get('SeedzUrl');
        getSeedzWrapper.strCTALink=configure.PMC_DH_PageUrl__c;
        try{
            //make callout if CPF number is present
        if(strConCPF!=null ){
            if(PMC_DH_CacheHelper.isSessionKeyAvailable(SEEDZ_SESSIONCACHE))
            {
                getSeedzWrapper.boolIsSeedzEnrolled=true;
                getSeedzWrapper.decSeedzPoints=(Decimal)PMC_DH_CacheHelper.getSessionPartitionCachebyKey(SEEDZ_SESSIONCACHE);
            }
            else{
            response=PMC_DH_SeedzServiceClass.getSeedzPointsCallout(strConCPF);
                    
            //if response is success , send seedz points
            if(response.getStatusCode() == 200)
            {
                getSeedzWrapper.boolIsSeedzEnrolled=true;
                mapResponsePoints=(Map<String,Object>)JSON.deserializeUntyped(response.getBody());
                getSeedzWrapper.decSeedzPoints=(Decimal)mapResponsePoints.GET('balance');
                PMC_DH_CacheHelper.setCachePartitionCache(SEEDZ_SESSIONCACHE,getSeedzWrapper.decSeedzPoints);
                        getSeedzWrapper.boolHasError=false;
                        getSeedzWrapper.strErrorMessage = '';
            }
            //if response failed , send error message
           else
            {
                        getSeedzWrapper.boolHasError=true;
            getSeedzWrapper.strErrorMessage=System.Label.get(null,SEEDZ_ERRORMESSAGE, userinfo.getLocale());
			}
        }
            }
            getSeedzWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'UserModalDetails');
        }
        
        catch (Exception ex) {
            getSeedzWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); 
            //throw  new AuraHandledException(ex.getMessage());
            
        }
        return getSeedzWrapper;
    }
    
 /*************************************************************************
* @method Name  : PMC_DH_GetSeedzWrapper
* @description  : Wrapper class for Seedz Response 
*****************************************************************************/   
    public class PMC_DH_GetSeedzWrapper{
        /**
* @description Check for Seedz Enrollment
* @return  Boolean 
*/
        @AuraEnabled
        public Boolean boolIsSeedzEnrolled{get;set;}
        /**
* @description Seedz Points
* @return  Decimal 
*/
        @AuraEnabled
        public Decimal decSeedzPoints{get;set;}
        /**
* @description Seedz Redirection Link
* @return  String 
*/
        @AuraEnabled
        public String strCTALink{get;set;}
        /**
* @description Check for Error
* @return  Boolean 
*/
        @AuraEnabled
        public Boolean boolHasError{get;set;}
        /**
* @description Error Message
* @return  String 
*/
        @AuraEnabled
        public String strErrorMessage{get;set;}
    /**
    * @description Status Code and message
    * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}  
    }
}