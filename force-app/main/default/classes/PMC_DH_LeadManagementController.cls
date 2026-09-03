/**
 * 
 * @author hemant giri
 * @since  08-25-2023
 * @description controller class for lead management
 */
public with sharing class PMC_DH_LeadManagementController {
    
    /**
     * @author hemant giri goswami
     * @since 08-25-2023
     * @description method to get the record
     * @param strAccountid 
     * @param strTabType   
     * @return PMC_DH_LeadMgmtWrapper`
     */
    @AuraEnabled
    public static PMC_DH_LeadMgmtWrapper getRecord(String strAccountid,String strTabType ){
        PMC_DH_LeadMgmtWrapper leadsWrapper=new PMC_DH_LeadMgmtWrapper();
        List<PMC_DH_LeadMgmtWrapper.LeadInfoWrapper> lstRecordsData=new List<PMC_DH_LeadMgmtWrapper.LeadInfoWrapper>();
        try{
        if(strTabType == PMC_DH_ConstantClass.NEW_LEAD){
          lstRecordsData = getNewLeadsData();
        }
        else{
         lstRecordsData = getAcceptedLeadsData();
        }
        leadsWrapper.lstRecordsData=lstRecordsData;
         leadsWrapper.lstRejectionResons=getRejectionReason();
        leadsWrapper.lstStage = getStagesForOppty();
        leadsWrapper.lstContactMethods = getContactMethod();
        leadsWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'LeadManagement');
        }
        catch(Exception ex){
            leadsWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
            //throw new AuraHandledException(ex.getMessage());
			}
        return leadsWrapper;
    }

    private static String assignProductFam(PMC_DH_LeadMgmtWrapper.LeadInfoWrapper wrpLead, String strValue )
    {	
        String strProdSearch='';
        if(strValue!=null)
        {
            //wrpLead.strProductFamily=getProductFamily(strValue);
            wrpLead.lstProductFamiles=strValue.split(';');
            strProdSearch=String.join(wrpLead.lstProductFamiles, ',');
        }
        return strProdSearch;
        
        
}
    
    
    private static String assignCropType(PMC_DH_LeadMgmtWrapper.LeadInfoWrapper wrpLead, String strValue)
        {
            String strCropSearch='';
            if(strValue!=null)
        {
            //wrpLead.strCrop=getCrop(strValue);
            wrpLead.lstCrops=strValue.split(';');
            strCropSearch=String.join(wrpLead.lstCrops, ',');
        }
        return strCropSearch;
        
        }
    
    
    /*************************************************************************
* @method Name  : getStagesForOppty
* @description  : Method to get Stages information in wrapper form
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/
    private static List<PMC_DH_PicklistWrapper> getStagesForOppty()
    {
        List<PMC_DH_PicklistWrapper> lstStage = getModalReasons('StageName');
        return lstStage;
    }




    private static List<PMC_DH_PicklistWrapper> getRejectionReason()
    {	
     	List<PMC_DH_PicklistWrapper> lstRejectReason =getModalReasons(PMC_DH_ConstantClass.LEAD_REJECT);
         return lstRejectReason;

    }
    
     /**
     * @description Method to get the modal values after setting stage as Lost
     * @since 09-20-2023
     * @author Hemant Giri Goswami
     * @return List<PMC_DH_PicklistWrapper> 
     * 
     */
    @AuraEnabled
    public static List<PMC_DH_PicklistWrapper> getLostOpportunityModal()
    {
        List<PMC_DH_PicklistWrapper> lstRejectReason =getModalReasons(PMC_DH_ConstantClass.OPPORTUNITY_LOST);
         return lstRejectReason;
       
    }

  
    
    private static List<PMC_DH_PicklistWrapper> getModalReasons(String strModalType){
        List<PMC_DH_PicklistWrapper> lstPicklistValues=new List<PMC_DH_PicklistWrapper>();
        try{
            List<PMC_DH_ModalReasonList__mdt> lstMetaData=[SELECT id,PMC_DH_Type__c, PMC_DH_Position__c, Label, PMC_DH_Value__c,PMC_DH_Custom_Label__c from PMC_DH_ModalReasonList__mdt 
                                                           WHERE PMC_DH_Type__c=:strModalType  WITH SECURITY_ENFORCED order by PMC_DH_Position__c ASC];
            
            for(PMC_DH_ModalReasonList__mdt data:lstMetaData){
                PMC_DH_PicklistWrapper objData=new PMC_DH_PicklistWrapper();

                objData.label=System.Label.get(null, data.PMC_DH_Custom_Label__c, userinfo.getLocale());
                objData.value=data.PMC_DH_Value__c;
                lstPicklistValues.add(objData);

            }
        }Catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        return  lstPicklistValues;

    }
    
    
    
    
    /*************************************************************************
* @method Name  : getContactMethod
* @description  : Method to get contact method in wrapper form
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/
    private static List<PMC_DH_PicklistWrapper> getContactMethod()
    {
        Schema.DescribeFieldResult fieldResult = Opportunity.PMC_DH_ContactMethod__c.getDescribe();
        List<PMC_DH_PicklistWrapper> lstContactMethod = PMC_DH_DigitalHubB2BUtils.getPicklistFromSchema(fieldResult);
        return lstContactMethod;
    }
    


    
    private static Map<String,String> getComment(List<Lead> lstLead)
    {
        Set<Id> opptyIds = new Set<Id>();
        //Set<Id> contenDocIds = new Set<Id>();
        Map<String,String> mapofOpptyAndNote = new Map<String,String>();
        for(Lead objLd : lstLead){
            ///if(objLd.ConvertedOpportunityId!=null){
                opptyIds.add(objLd.ConvertedOpportunityId);
          // }
            
            }
      
                if(!opptyIds.isEmpty()){
                for(ContentDocumentLink objCD : [SELECT ContentDocumentId,LinkedEntityId,
                ContentDocument.LatestPublishedVersion.TextPreview  FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :opptyIds AND ContentDocument.FileType='SNOTE' WITH SECURITY_ENFORCED]){
                        mapofOpptyAndNote.put(objCD.LinkedEntityId,(objCD.ContentDocument.LatestPublishedVersion.TextPreview ));
            }
        
        }
        
        return mapofOpptyAndNote;
    }

    /**
     * @description method to edit opportunity record
     * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
     * @param strOpporId
     * @param wrpUpdate
     * @author hemant giri goswami
     * @since 29-08-2023
     */

    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper updateAcceptedLeads( String strOpporId,PMC_DH_LeadMgmtWrapper.LeadInfoWrapper wrpUpdate)
    {
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        
        try{
            List<Lead> lstLeadRrd=[SELECT id,ConvertedOpportunityid FROM LEAD WHERE ConvertedOpportunityid=:strOpporId AND ConvertedOpportunityid!=NULL WITH SECURITY_ENFORCED];
            map<String,String> mapGetCmmt=getComment(lstLeadRrd);
            Opportunity objOpptRecord= new Opportunity(Id=strOpporId);
            objOpptRecord.StageName= PMC_DH_LeadManagementUtil.getStage(objOpptRecord,wrpUpdate);
            objOpptRecord.PMC_DH_LastContactedDate__c= wrpUpdate.datContactedDate ;
            if( mapGetCmmt.containsKey(strOpporId))
            {

                updateContentNote( strOpporId, wrpUpdate.strComments);
            }
            else if(!String.isBlank(wrpUpdate.strComments))
            {
                createContentNote(strOpporId, wrpUpdate.strComments);
            }
            
            objOpptRecord.PMC_DH_ContactMethod__c=  wrpUpdate.strContactMethod ;
            if(Schema.sObjectType.Opportunity.isUpdateable() )
            {
                Update objOpptRecord;
                result=PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000','OpportunityUpdate');
                
            }
            
        }
        catch(Exception ex)
        {
            result=PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100','All');
        }
        return result;
    }

    private static void createContentNote(String strOppId,String strComment )
    {
        
        ContentNote noteRecord = new ContentNote();
        noteRecord.Title   = 'Note for Opportunity';
        String body        = strComment;
        noteRecord.Content = Blob.valueOf(body.escapeHTML4());
        if(Schema.sObjectType.ContentNote.isCreateable()){
        insert  noteRecord;
        }
        ContentDocumentLink link = new ContentDocumentLink();
        link.ContentDocumentId   = noteRecord.id;
        link.LinkedEntityId      =strOppId ;
        link.ShareType           = 'V';
        link.Visibility          = 'AllUsers';
        if(Schema.sObjectType.ContentDocumentLink.isCreateable()){
        insert  link;
        }
    }

    private static void updateContentNote(String strOppId,String strComment)
    {
        //SELECT Id, ContentDocument.FileType, ContentDocument.Id,LinkedEntityId  from ContentDocumentLink  Where LinkedEntityId IN ('006DT00000Tg8kjYAB','006DT00000TgAvwYAF') Order by ContentDocument.CreatedDate DESC
        ContentDocumentLink csl=[SELECT ID FROM ContentDocumentLink WHERE LinkedEntityId=:strOppId 
                                AND ContentDocument.FILETYPE='SNOTE'
                                WITH SYSTEM_MODE
                                 ORDER BY ContentDocument.CreatedDate DESC LIMIT 1];
        if(Schema.sObjectType.ContentDocumentLink.isDeletable()){                   
        delete csl;
        }
        createContentNote(strOppId,strComment);

    }




    /**
     * @description method to reject a lead
     * @since 08-29-2023
     * @param strLeadId 
     * @param stRejectionReason    
     * @return          `PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper`
     */
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper  rejectLead(String strLeadId, String stRejectionReason )
    {
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        
        try{
            Lead objLeadRecord = new Lead(Id=strLeadId); 
            objLeadRecord.Status = PMC_DH_ConstantClass.LEAD_LOST;
            objLeadRecord.PMC_SS_RejectionReason__c = stRejectionReason;
            objLeadRecord.PMC_SS_AcceptedByRetailer__c=PMC_DH_ConstantClass.REJECTED;
            if(Schema.sObjectType.Lead.isUpdateable()){
                Update objLeadRecord;
                result=PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE,'LeadRejected');
            }
        }
        catch(Exception ex)
        {
            result=PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE,PMC_DH_ConstantClass.ALL);
        }
        
        return result;
    }
    
    private static List<PMC_DH_LeadMgmtWrapper.LeadInfoWrapper> getNewLeadsData(){
        List<PMC_DH_LeadMgmtWrapper.LeadInfoWrapper> lstNewLeadsData = new List<PMC_DH_LeadMgmtWrapper.LeadInfoWrapper>();
        List<Lead> lstLead = [SELECT Id, FirstName, LastName, Email, Phone, City, State, Country, CreatedDate, PMC_DH_FarmSize__c,
                             PMC_SS_ProductFamilyCategoryInterests__c, PMC_SS_Crops__c,  PMC_DH_DealOwner__c,PartnerAccountId, 
                             PMC_DH_DealOwner__r.Name,PMC_SS_ProductInterestVolumeEstimate__c FROM Lead 
                            WHERE  Status=:PMC_DH_ConstantClass.SALES_QUALIFIED WITH SECURITY_ENFORCED
                            Order By CreatedDate Desc LIMIT 1001];
        
        for(Lead objLead : lstLead){  
           
            PMC_DH_LeadMgmtWrapper.LeadInfoWrapper leadWrp=new PMC_DH_LeadMgmtWrapper.LeadInfoWrapper();
            leadWrp.strRecordId=objLead.Id;//assignment for all the attributes\
            leadWrp.strLastName=objLead.Lastname;
            leadWrp.strFirstName=objLead.Firstname;
            leadWrp.strEmail =objLead.Email;
            leadWrp.strPhone =objLead.Phone;
            leadWrp.strRegion =objLead.Country;
            leadWrp.datCreatedDate =Date.valueof(objLead.CreatedDate);
            leadWrp.strCity =objLead.City;
            leadWrp.strState =objLead.State; 
            leadWrp.strProductFamily= PMC_DH_LeadManagementUtil.getProductFamilyData(objLead.PMC_SS_ProductFamilyCategoryInterests__c);
            leadWrp.strCrop = PMC_DH_LeadManagementUtil.getCropFamilyData(objLead.PMC_SS_Crops__c);
            String strProdSearch= assignProductFam(leadWrp,objLead.PMC_SS_ProductFamilyCategoryInterests__c );
            String strCropSearch=assignCropType(leadWrp,objLead.PMC_SS_Crops__c);
            leadWrp.strQty =objLead.PMC_SS_ProductInterestVolumeEstimate__c; //will discuss
            leadWrp.strDealOwner =objLead.PMC_DH_DealOwner__r.name;
            leadWrp.strFarmSize =objLead.PMC_DH_FarmSize__c;
            leadWrp.strSearchdata=leadWrp.strFirstName+' '+leadWrp.strLastName+' '+leadWrp.strEmail+' '+leadWrp.strPhone+' '+leadWrp.strState+' '+leadWrp.strRegion+' '+leadWrp.strState+'-> '+strProdSearch+' '+strCropSearch;
            lstNewLeadsData.add(leadWrp);
       
        }
        return lstNewLeadsData;
    }
    
    private static List<PMC_DH_LeadMgmtWrapper.LeadInfoWrapper> getAcceptedLeadsData(){
        
        List<Lead> lstAcceptedLeads =new List<Lead>();
        lstAcceptedLeads= [SELECT Id, ConvertedContact.FirstName, ConvertedContact.LastName, ConvertedContact.Email, ConvertedContact.Phone, ConvertedOpportunity.StageName,
                                       ConvertedContact.MailingCity, ConvertedContact.MailingState,ConvertedContact.MailingCountry, ConvertedOpportunity.CreatedDate,ConvertedAccountId,
                                       PMC_DH_DealOwner__c,  PMC_DH_DealOwner__r.Name,  PMC_DH_FarmSize__c, 
                                       ConvertedOpportunity.PMC_SS_ProductFamilies__c, ConvertedOpportunity.PMC_SS_Crops__c,PMC_SS_ProductInterestVolumeEstimate__c,
                                       ConvertedOpportunity.PMC_DH_ContactPreference__c, ConvertedOpportunity.PMC_DH_LastContactedDate__c, ConvertedOpportunity.PMC_DH_ContactMethod__c 
                                       FROM Lead WHERE  IsConverted=TRUE  AND ConvertedOpportunityId!=NULL AND ConvertedOpportunity.StageName!=:PMC_DH_ConstantClass.CLOSED_LOST
                                    WITH SECURITY_ENFORCED Order by ConvertedOpportunity.CreatedDate DESC LIMIT 1001];
        
        List<PMC_DH_LeadMgmtWrapper.LeadInfoWrapper> lstAccptedLeadsData = new List<PMC_DH_LeadMgmtWrapper.LeadInfoWrapper>();
        
       map<String,String> mapComment=getComment(lstAcceptedLeads);
                
        for(Lead objLead : lstAcceptedLeads){ 
            
            PMC_DH_LeadMgmtWrapper.LeadInfoWrapper leadWrp=new PMC_DH_LeadMgmtWrapper.LeadInfoWrapper();
            leadWrp.strRecordId=objLead.ConvertedOpportunityId;//assignment for all the attributes\
            leadWrp.strLastName=objLead.ConvertedContact.Lastname ;
            leadWrp.strFirstName=objLead.ConvertedContact.Firstname ;
            leadWrp.strEmail =objLead.ConvertedContact.Email ;
            leadWrp.strPhone =objLead.ConvertedContact.Phone ;
            leadWrp.strRegion =objLead.ConvertedContact.MailingCountry ;
            leadWrp.datCreatedDate =Date.valueof(objLead.ConvertedOpportunity.CreatedDate);
            leadWrp.strCity =objLead.ConvertedContact.MailingCity;
            leadWrp.strState =objLead.ConvertedContact.MailingState; 
            String strProdSearch=assignProductFam(leadWrp,objLead.ConvertedOpportunity.PMC_SS_ProductFamilies__c );
            String strCropSearch=assignCropType(leadWrp,objLead.ConvertedOpportunity.PMC_SS_Crops__c);
            leadWrp.strProductFamily= PMC_DH_LeadManagementUtil.getProductFamilyData(objLead.ConvertedOpportunity.PMC_SS_ProductFamilies__c);
            leadWrp.strCrop = PMC_DH_LeadManagementUtil.getCropFamilyData(objLead.ConvertedOpportunity.PMC_SS_Crops__c);
            leadWrp.strQty =objLead.PMC_SS_ProductInterestVolumeEstimate__c ;
            leadWrp.strDealOwner =objLead.PMC_DH_DealOwner__r.name;
            leadWrp.strFarmSize =objLead.PMC_DH_FarmSize__c;
              leadWrp.strStage =objLead.ConvertedOpportunity.stagename;
             leadWrp.strContactPreferences =objLead.ConvertedOpportunity.PMC_DH_ContactPreference__c;
             leadWrp.datContactedDate =objLead.ConvertedOpportunity.PMC_DH_LastContactedDate__c;
             leadWrp.strContactMethod =objLead.ConvertedOpportunity.PMC_DH_ContactMethod__c;
            leadWrp.strComments =mapComment.get(objLead.ConvertedOpportunityID);
            leadWrp.strSearchdata=leadWrp.strFirstName+' '+leadWrp.strLastName+' '+leadWrp.strEmail+' '+leadWrp.strPhone+' '+leadWrp.strState+' '+leadWrp.strRegion+' '+leadWrp.strState+' '+strProdSearch+' '+strCropSearch;
            lstAccptedLeadsData.add(leadWrp);
       
        }
        return lstAccptedLeadsData;
        
    }
    
/**
     * @description method to convert a lead
     * @param strRecordId
     * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
     * @since 11-02-2023
     * GDASF-16399
     */
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper leadConversion(String strRecordId){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        try{
            Database.LeadConvert lc = new database.LeadConvert();
            lc.setLeadId(strRecordId);
            lc.setDoNotCreateOpportunity(false);
            lc.setConvertedStatus('Converted');
            Database.convertLead(lc, true, AccessLevel.SYSTEM_MODE);
            result=PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000','LeadAccepted');
        } catch (Exception ex) {
            result=PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
        }
        return result;
    }
}