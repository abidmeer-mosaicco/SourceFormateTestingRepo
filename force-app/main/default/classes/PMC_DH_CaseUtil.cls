/**
 * @author @hemant.giri
 * @description utility class for Case
 * @since 06-14-2023
 */
// added with sharing 
public without sharing class PMC_DH_CaseUtil {
    public static final String BASE64MAP = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
	private static final String CASE_REOPEN = 'CaseReopen';
    public static boolean boolThrow=false;

    /**
     * @description method to reopen a closed case
     * @param cseWrapper 
     * @return  PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
     * @author Hemant giri goswami
     * @since 06-15-2023
     */
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper reopenCase(CaseWrapper cseWrapper)
    {   
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage= new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        Case cse=[Select id,status,PMC_SS_ReOpenReason__c,PMC_SS_OtherReOpenReason__c from Case where id=:cseWrapper.strCaseId WITH SECURITY_ENFORCED];
        
        try 
        {
            if(cse.status==PMC_DH_ConstantClass.CLOSED && PMC_DH_CaseMgmtClass.getTimeline(cseWrapper.strCaseId)){   
                cse.Status=PMC_DH_ConstantClass.CASE_REOPEN_STATUS;
                cse.PMC_SS_ReOpenReason__c=cseWrapper.strReason;
                cse.PMC_SS_OtherReOpenReason__c=cseWrapper.strOthersComment;
                if(Schema.sObjectType.Case.isUpdateable()){
                update  cse ;
                statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, CASE_REOPEN); 
                }
            }
            else if(Test.isRunningTest()&&boolThrow){
                throw new AuraHandledException('Mock Exception');
            }
            else{ 
                statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.FAILURE_STATUS_CODE, CASE_REOPEN); 
            }
    } 
    catch (Exception ex) {
        statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL); 
        PMC_ErrorLogClass.processException(ex);        // added to handle-track Error logs             
        }
        return statusCodeMessage;
    }

    /**
     * @description method to fetch reasons list
     * @return List<PMC_DH_PicklistWrapper> 
     * @author Hemant.girigoswami
     */
@AuraEnabled
   public static List<PMC_DH_PicklistWrapper> getReopenReasonList()
   {
       Schema.DescribeFieldResult fieldResult = Case.PMC_SS_ReOpenReason__c.getDescribe();
       List<PMC_DH_PicklistWrapper> lstReason = PMC_DH_DigitalHubB2BUtils.getPicklistFromSchema(fieldResult);
       return lstReason;
   }

/**
* @description method to fetch reasons list
* @return Map<String,List<String>>
* @param dependentField
*/
    public static Map<String,List<Schema.PicklistEntry>> getDependentPicklistValues(Schema.sObjectField dependentField){
        Map<String,List<Schema.PicklistEntry>> dependentPicklistValues = new Map<String,List<Schema.PicklistEntry>>();
        //Schema.DescribeFieldResult dependentFieldResult = Case.PMC_SS_IssueReason__c.getDescribe();
        Schema.DescribeFieldResult dependentFieldResult = dependentField.getDescribe();
        Schema.sObjectField controllerField = dependentFieldResult.getController();
        if(controllerField == null){
            return null;
        } 
        Schema.DescribeFieldResult controllerFieldResult = controllerField.getDescribe();
        List<Schema.PicklistEntry> controllerValues = (controllerFieldResult.getType() == Schema.DisplayType.Boolean ? null : controllerFieldResult.getPicklistValues());
        
        for (Schema.PicklistEntry entry : dependentFieldResult.getPicklistValues()){
            if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))){
                getPicklistValues(controllerValues,dependentPicklistValues,entry);
            }
        }
        
        return dependentPicklistValues;
    }
/**
* @description method to fetch reasons list
* @return Map<String,List<String>>
* @param controllerValues
* @param dependentPicklistValues
* @param entry
*/
    private static Map<String,List<Schema.PicklistEntry>> getPicklistValues(List<Schema.PicklistEntry> controllerValues,Map<String,List<Schema.PicklistEntry>> dependentPicklistValues,Schema.PicklistEntry entry){
        //Map<String,List<String>> dependentPicklistValues = new Map<String,List<String>>();
        List<String> base64chars = String.valueOf(((Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
            for (Integer i = 0; i < controllerValues.size(); i++) {
                Object controllerValue = (controllerValues == null ? (Object) (i == 1) : (Object) (controllerValues.get(i).isActive() ? controllerValues.get(i).getValue() : null));
                Integer bitIndex = i / 6;
                Integer bitShift = 5 - Math.mod(i, 6);
    
                if (controllerValue == null || (BASE64MAP.indexOf(base64chars.get(bitIndex)) & (1 << bitShift)) == 0) {
                    continue;
                }
    
                String controllerValueString = String.valueOf(controllerValue);
    
                if (!dependentPicklistValues.containsKey(controllerValueString)) {
                    dependentPicklistValues.put(controllerValueString, new List<Schema.PicklistEntry>());
                }
                
                dependentPicklistValues.get(controllerValueString).add(entry);
            }
            return dependentPicklistValues;
        }

    /**
     * @description wrapper for case
     * @author hemant.girigoswami
     * @since 06-14-2023
     */
    // added with sharing 

    public with sharing class CaseWrapper{
        /**
         * @description string to store case id
         * @return String
         */
        @AuraEnabled
        public String strCaseId{get;set;}
        /**
         * @description  string to store reason for reopening the case
         * @return String
         */
        @AuraEnabled
        public String strReason{get;set;}
        /**
         * @description String to store other text field
         * @return String
         */
        @AuraEnabled
        public String strOthersComment{get;set;}
    }
    /**
* @description Method to check if user is eligible to upload document
* @return Boolean
* @param caseId
*/
    @AuraEnabled
    public static Boolean isEligibleToUploadDoc(String caseId){
    Boolean boolIsEligible = false;
    String strStatus = [SELECT Id, PMC_SS_CaseStatus__c FROM Case WHERE Id=:caseId WITH SECURITY_ENFORCED].PMC_SS_CaseStatus__c;
    List<UserRecordAccess> lstUsrRecAccess = new  List<UserRecordAccess>();
    lstUsrRecAccess=[SELECT RecordId, HasReadAccess, HasEditAccess from UserRecordAccess where RecordId =:caseId and UserId =:UserInfo.getUserId() WITH USER_MODE];
    if(!lstUsrRecAccess.isEmpty()&&( lstUsrRecAccess[0].HasEditAccess == true && (strStatus == 'Open' || strStatus == 'In Progress')) ){
        boolIsEligible = true;
    }
    return boolIsEligible;
    }
}