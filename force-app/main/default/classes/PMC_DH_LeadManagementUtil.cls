/**
 * 
 * @author Krishan Jangir
 * @since  09-01-2023
 * @description controller class for lead management
 */
public with sharing class PMC_DH_LeadManagementUtil {
    public final static String CLOSE_LOST = 'Closed Lost';
    public final static String INACTIVE_STATUS = 'Inactive';
    public final static String OTHER = 'Other';
    /**
     * @description method to get Opportunity Stage
     * @return String
     * @param objOpty
     * @param wrapLead
     * @author Krishan Jangir
     * @since 09-01-2023
     */
    public static String getStage(Opportunity objOpty,PMC_DH_LeadMgmtWrapper.LeadInfoWrapper wrapLead)
    {   
        if(wrapLead.strStage == CLOSE_LOST){
            objOpty.StageName = CLOSE_LOST;
            objOpty.PMC_SS_ReasonLost__c = OTHER;
        }else{
            objOpty.StageName = wrapLead.strStage;
        }
        return objOpty.StageName;
    }
    /**
     * @description method to get product family
     * @return String
     * @param strCropProductFam
     * @author Krishan Jangir
     * @since 09-04-2023
     */
    public static String getProductFamilyData(String strCropProductFam){   
        String strReturn;
        if(strCropProductFam!=null ){
            List<String> lstCropProductFam = strCropProductFam.split(';');
            if(lstCropProductFam.size()>1){
                strReturn= System.label.pmc_requestToDeliverShippingInformation_multiple;
            }else {
                strReturn=lstCropProductFam[0];
            }
        }
        return strReturn;
        
        
    }
    /**
     * @description method to get Crop family
     * @return String
     * @param strCropFam
     * @author Krishan Jangir
     * @since 09-04-2023
     */
    public static String getCropFamilyData(String strCropFam){   
        String strReturn;
        if(strCropFam!=null ){
            List<String> lstCropFam = strCropFam.split(';');
            if(lstCropFam.size()>1){
                strReturn= System.label.pmc_requestToDeliverShippingInformation_multiple;
            }else {
                strReturn=lstCropFam[0];
            }
        }
        return strReturn;
        
        
    }

    /**
     * @description Method to Lost the Accepted Leads
     * @param strOpportunityId
     * @param strLostReason
     * @param strComment
     * @author Hemant Giri Goswami
     * @since 09-21-2023
     * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
     * 
     */
    @AuraEnabled
     public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper updateOpportunitytoLost(String strOpportunityId, String strLostReason, String strComment)
     {
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper status =new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();             
    try{
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        Opportunity opporObjRecord=[SELECT StageName  ,PMC_SS_ReasonLost__c 
                                    FROM Opportunity WHERE Id=:strOpportunityId WITH SECURITY_ENFORCED];
        opporObjRecord.StageName  =PMC_DH_ConstantClass.CLOSED_LOST;
        opporObjRecord.PMC_SS_ReasonLost__c=strLostReason;
        opporObjRecord.PMC_DH_LostOtherReason__c=strComment;
        if(Schema.sObjectType.Opportunity.isUpdateable()){
        update opporObjRecord;
        status=PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE,'OpportunityUpdate');
        
    }
    }
    catch(Exception ex)
    {
        PMC_ErrorLogClass.processException(ex);
        status=PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE,PMC_DH_ConstantClass.ALL);
    }
    return status;

     }


   



}