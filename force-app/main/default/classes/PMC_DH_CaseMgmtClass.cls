/**
* @description       : Class for Case Management
* @author            : @Ajeet
* @group             : 
* @last modified on  : 02-16-2024
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
public with sharing class PMC_DH_CaseMgmtClass {
    private static final String CASE_INQUIRY_TYPE = 'Case Inquiry Type';
    private static final String CASE_INQUIRY_SUB_TYPE = 'Case Inquiry Sub Type';

        /**
@description Wrapper for file saveFiles
**/
public class PMC_DH_CaseDataWrapper{
    /**
    * @description Holds details of new case created
    * @return Case
    */
    @AuraEnabled
    public Case objCaseDetail{get;set;}
    /**
     * @description Status Code and message
     * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
     */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
}
    
    /**
* @description method to return timeline of 48hr
* @author hemant.girigoswami
* @since 06-14-2023
* @param strCaseId
* @return Boolean
*/
    @AuraEnabled 
    public static Boolean getTimeline(String strCaseId)
    {   
    Boolean boolIsCaseElgToReopen=false;    
    Case caseObjRecord=[SELECT CASENUMBER,BUSINESSHOURSID,CLOSEDDATE, PMC_SS_CaseStatus__c
                        FROM CASE WHERE Id=:strCaseId WITH SECURITY_ENFORCED ];
    Id idBusinessHrs;
    if(caseObjRecord.ClosedDate != NULL && caseObjRecord.PMC_SS_CaseStatus__c==PMC_DH_ConstantClass.CLOSED ){
        if(String.isNotBlank(caseObjRecord.BusinessHoursId))
        {   
            idBusinessHrs=caseObjRecord.BusinessHoursId;
        }
        else
        {
           BusinessHours objBusinessHrs = [Select Id, Name From BusinessHours Where isDefault = TRUE AND IsActive = True With Security_Enforced LIMIT 1];
           idBusinessHrs=objBusinessHrs.Id;
        }
        Long longMilliSec = Long.ValueOf(String.valueOf(Integer.valueOf(Label.PMC_DH_CaseExpireDays) * Integer.valueOf(Label.PMC_DH_DayBusinessHours) * 3600000));
        DateTime dateTimeExpectedReOpenDate = BusinessHours.addGmt(idBusinessHrs, caseObjRecord.ClosedDate, longMilliSec);
        if(System.now() <= dateTimeExpectedReOpenDate) 
        {
            boolIsCaseElgToReopen=true;
        }
    }
    return boolIsCaseElgToReopen;     
    }
    
    
    /*************************************************************************
* @method Name  : getTypeForCase
* @description  : Method to get 'Type' information in wrapper form
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/
    @AuraEnabled
    public static List<PMC_DH_PicklistWrapper> getTypeForCase(){
        Schema.DescribeFieldResult fieldResult = Case.Type.getDescribe();
        List<PMC_DH_PicklistWrapper> lstTypeAll = PMC_DH_DigitalHubB2BUtils.getPicklistFromSchema(fieldResult);
        List<PMC_DH_PicklistWrapper> lstType = new List<PMC_DH_PicklistWrapper>();
        
        Set<String> valuesToShow = new Set<String>();
        List<PMC_DH_Digital_Hub_Restriction_Setting__mdt> lstRules= [SELECT PMC_DH_Category__c, PMC_DH_Type__c, PMC_DH_Restricted_Value__c  FROM PMC_DH_Digital_Hub_Restriction_Setting__mdt  WHERE PMC_DH_Category__c =: CASE_INQUIRY_TYPE WITH SECURITY_ENFORCED ];
        for (PMC_DH_Digital_Hub_Restriction_Setting__mdt record : lstRules) {
            valuesToShow.add(record.PMC_DH_Restricted_Value__c);
        } 
        
        for (PMC_DH_PicklistWrapper pw : lstTypeAll) {
            if (valuesToShow.contains(pw.value)) {
                lstType.add(pw);
            }
        }
       /* for (Integer i= 0;i<lstTypeAll.size(); i++) {
            PMC_DH_PicklistWrapper pw = lstTypeAll[i];
            if (valuesToShow.contains(pw.value)) {
                lstType.add(lstTypeAll[i]);
            }
        }*/
        return lstType;

    }
    
    /*************************************************************************
* @method Name  : getIssueReasonForCase
* @description  : Method to get 'Issue Reason' information in wrapper form
* @return       : List<PMC_DH_PicklistWrapper>
*****************************************************************************/
    @AuraEnabled
    public static Map<String,List<PMC_DH_PicklistWrapper>> getIssueReasonForCase(){
        Map<String,List<Schema.PicklistEntry>> mapOfAllIssueReason = PMC_DH_CaseUtil.getDependentPicklistValues(Case.PMC_SS_IssueReason__c);
        Set<String> valuesToShow = new Set<String>();
        List<PMC_DH_Digital_Hub_Restriction_Setting__mdt> lstRules= [SELECT PMC_DH_Category__c, PMC_DH_Type__c, PMC_DH_Restricted_Value__c  FROM PMC_DH_Digital_Hub_Restriction_Setting__mdt WHERE PMC_DH_Category__c =: CASE_INQUIRY_SUB_TYPE WITH SECURITY_ENFORCED ];
        for (PMC_DH_Digital_Hub_Restriction_Setting__mdt record : lstRules) {
            valuesToShow.add(record.PMC_DH_Restricted_Value__c);
        } 
        Map<String,List<PMC_DH_PicklistWrapper>> mapOfIssueReason = new Map<String,List<PMC_DH_PicklistWrapper>>();
        for(String key: mapOfAllIssueReason.keySet()){
            //List<String> lstIssueReason = mapOfAllIssueReason.get(key);
            //system.debug(lstIssueReason);//showing depency values each like internal=(Article Request, Credit Request, Data Entry, Financial Solution, MDM Verification, Planning, Stock Out / Plant Outage),
            List<PMC_DH_PicklistWrapper> lstReason = new List<PMC_DH_PicklistWrapper>();
            for (Schema.PicklistEntry entry : mapOfAllIssueReason.get(key)) {
                if (valuesToShow.contains(entry.getValue())) {
                    PMC_DH_PicklistWrapper picklistWrapper = new PMC_DH_PicklistWrapper();
                    picklistWrapper.label = entry.getLabel();
                    picklistWrapper.value = entry.getValue();
                    lstReason.add(picklistWrapper);
                }
            }
            mapOfIssueReason.put(key, lstReason);
        }
        return mapOfIssueReason;
    }
    
    
    /*************************************************************************
* @method Name  : createNewCase
* @description  : Method to create New Case
* @param         caseCreation
* @param        lstFileWrapper
* @param        effAccountId
* @return       : PMC_DH_CaseDataWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_CaseDataWrapper createNewCase(PMC_DH_CaseCreationWrapper caseCreation, List<PMC_DH_FileWrapper> lstFileWrapper, Id effAccountId){
        PMC_DH_CaseDataWrapper result = new PMC_DH_CaseDataWrapper();
        Case createCase;
        try{
            createCase = new Case();
            createCase.Type = caseCreation.strType;
            createCase.PMC_SS_IssueReason__c = caseCreation.strIssueReason;
            createCase.Subject = caseCreation.strSubject;
            createCase.Description = caseCreation.strDescription;
            //createCase.PMC_SS_CustomerStatus__c = PMC_DH_ConstantClass.CUSTOMER_STATUS;
            createCase.Origin = PMC_DH_ConstantClass.CASE_ORIGIN;
            User usr = [Select Id, ContactId, AccountId FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED];
            createCase.ContactId = usr.ContactId;
            createCase.AccountId = effAccountId;
            if(Schema.sObjectType.Case.isCreateable()){
                insert createCase;
                
            }
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.useDefaultRule = true;
            dmlOpts.EmailHeader.TriggerUserEmail = true;
            createCase.SetOptions(dmlOpts);
            if(Schema.sObjectType.Case.isUpdateable()){
                Database.update(createCase, dmlOpts);
            }
            
            for (Integer i = 0; i < lstFileWrapper.size(); i++) {
                lstFileWrapper[i].parentId = createCase.Id;
            }
            saveTheChunkFile(lstFileWrapper);
            if(Schema.sObjectType.Case.isAccessible()){
                result.objCaseDetail = [SELECT Id, Type, PMC_SS_IssueReason__c,Subject,Description,CaseNumber FROM Case Where Id = :createCase.Id WITH SECURITY_ENFORCED];
            }
            result.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'CaseCreation'); 
        }catch(Exception e){
            PMC_ErrorLogClass.processException(e); // MDErrorLog
            result.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); 
        }
        return result;
    }
    
    
    /****************************************************************************************
* @Method Name : saveTheChunkFile
* @description : Recieves input from LWC to store Files
* @param      lstFileWrapper
* @return  PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
****************************************************************************************/
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper saveTheChunkFile(List<PMC_DH_FileWrapper> lstFileWrapper){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        try{
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            Map<Integer,Id> integerQuoteIdMap= new Map<Integer,Id>();
            for (Integer i = 0; i < lstFileWrapper.size(); i++) {
                ContentVersion contentToInsert =new ContentVersion();
                contentToInsert.Title = lstFileWrapper[i].strFileName;
                contentToInsert.VersionData=EncodingUtil.base64Decode(lstFileWrapper[i].strBase64Data);
                contentToInsert.PathOnClient='/' + lstFileWrapper[i].strFileName ;
                contentToInsert.IsMajorVersion = false;
                contentVersions.add(contentToInsert);
                integerQuoteIdMap.put(i, lstFileWrapper[i].parentId);
            }
            if(Schema.sObjectType.ContentVersion.isCreateable()){
                insert contentVersions;
            }
            
            List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
            List<ContentVersion> contentToInsertNew = [Select Id, ContentDocumentId from ContentVersion WHERE Id IN : contentVersions WITH SECURITY_ENFORCED];
            
            for (Integer i = 0; i < contentToInsertNew.size(); i++) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = contentToInsertNew[i].ContentDocumentId;
                cdl.LinkedEntityId = integerQuoteIdMap.get(i);
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                
                
                contentDocumentLinks.add(cdl);
                
            }
            if(Schema.sObjectType.ContentDocumentLink.isCreateable()){
                insert contentDocumentLinks;
            }
        
            List<ContentDistribution> lstCd = new List<ContentDistribution>();
            for (Integer i = 0; i < contentVersions.size(); i++) {
                ContentDistribution cDis = new ContentDistribution();
                cDis.Name =lstFileWrapper[i].strFileName;
                cDis.ContentVersionId = contentVersions[i].id;
                cDis.PreferencesAllowViewInBrowser= true;
                cDis.PreferencesLinkLatestVersion=true;
                cDis.PreferencesNotifyOnVisit=false;
                cDis.PreferencesPasswordRequired=false;
                cDis.PreferencesAllowOriginalDownload= true;
                lstCd.add(cDis);
            }
            if(Schema.sObjectType.ContentDistribution.isCreateable()){
                insert lstCd;
            }
            
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'FileUpload');
        }catch (Exception e) {
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); 
            PMC_ErrorLogClass.processException(e);
        }
        return result;
    }
    /**
@description Wrapper for file saveFiles
**/
    public class PMC_DH_FileWrapper{
        /**
* @description String to parentId(caseid)
* @return Id
*/
        @AuraEnabled
        public Id parentId{get;set;}
        /**
* @description String to store File Name
* @return String
*/
        @AuraEnabled
        public String strFileName{get;set;}
        /**
* @description String to store base64Data
* @return String
*/
        @AuraEnabled
        public String strBase64Data{get;set;}
    }
    
    /**
* @description Wrapper to use as a parameter for case creation
*/
    
    public class PMC_DH_CaseCreationWrapper{
        /**
* @description String to store Type
* @return String
*/
        @AuraEnabled
        public String strType{get;set;}
        /**
* @description String to store Issue reason
* @return String
*/
        @AuraEnabled
        public String strIssueReason{get;set;}
        /**
* @description String to store Subject
* @return String
*/
        @AuraEnabled
        public String strSubject{get;set;}
        /**
* @description String to store Description
* @return String
*/
        @AuraEnabled
        public String strDescription{get;set;}
    }
    /****************************************************************************************
* @Method Name : getCaseDocumentAndCommentRecords
* @description : Fetch case document and comments records
* @param      caseId
* @return  List<CaseDocumentCommentWrapper>
****************************************************************************************/
    @AuraEnabled
    public static CaseDocumentCommentWrapper getCaseDocumentAndCommentRecords(String caseId){
        CaseDocumentCommentWrapper caseDocCommentWrapper = new CaseDocumentCommentWrapper();
        List<PMC_DH_CaseDocumentWrapper> lstCaseDocWrapper = new List<PMC_DH_CaseDocumentWrapper>();
        try{
            Case caseRecord = [SELECT Id, CaseNumber,(SELECT CommentBody, CreatedBy.Profile.Name from CaseComments ORDER BY CreatedDate ASC) FROM Case WHERE Id=: caseId WITH SYSTEM_MODE];
            List<ContentDocumentLink> lstCDLink = new List<ContentDocumentLink>();
            lstCDLink=[SELECT Id,ContentDocument.LatestPublishedVersionId, ContentDocument.FileExtension, ContentDocumentId, ContentDocument.Title,ContentDocument.createdDate
                                                FROM ContentDocumentLink WHERE LinkedEntityId=:caseId AND ContentDocument.FileType!='SNOTE'];
            if(!lstCDLink.isEmpty())
            {
                for(ContentDocumentLink cdLink: lstCDLink){
                PMC_DH_CaseDocumentWrapper cseDocWrapper = new PMC_DH_CaseDocumentWrapper();
                cseDocWrapper.strCaseNumber = caseRecord.CaseNumber;
                cseDocWrapper.strDocumentName = cdLink.ContentDocument.Title;
                // + '.' + cdLink.ContentDocument.FileExtension;
                cseDocWrapper.strDateAdded = cdLink.ContentDocument.createdDate;
                cseDocWrapper.strDocDownloadUrl = System.Label.PMC_DH_CaseDocUrl + cdLink.ContentDocumentId;
                //cseDocWrapper.strDocDownloadUrl = URL.getSalesforceBaseUrl().toExternalForm() + PMC_DH_ConstantClass.RELATIVE_URL + cdLink.ContentDocument.LatestPublishedVersionId;
                
                lstCaseDocWrapper.add(cseDocWrapper);
            }
        }
            caseDocCommentWrapper.boolEligibleToAddDocAndComments = PMC_DH_CaseUtil.isEligibleToUploadDoc(caseId);
            caseDocCommentWrapper.caseDocList = lstCaseDocWrapper;
            List<PMC_DH_CaseCommentWrapper> lstCaseCommentWrapper = new List<PMC_DH_CaseCommentWrapper>();
            Set<String> customerProfile = new Set<String>{PMC_DH_ConstantClass.PROFILE_NAME,PMC_DH_ConstantClass.BUYER_PERSONA,PMC_DH_ConstantClass.LOGISTIC_MANAGER,PMC_DH_ConstantClass.FINANCE_MANAGER,PMC_DH_ConstantClass.CONTRACT_MANAGER};
            for(CaseComment caseComment: caseRecord.CaseComments){
                    PMC_DH_CaseCommentWrapper cseCommentWrapper = new PMC_DH_CaseCommentWrapper();
                    cseCommentWrapper.strCaseComment = caseComment.CommentBody;
                    if(customerProfile.contains(caseComment.CreatedBy.Profile.Name)){
                        cseCommentWrapper.boolIsCustomerCreated = true;
                    }else{
                        cseCommentWrapper.boolIsCustomerCreated = false;
                    }
                    lstCaseCommentWrapper.add(cseCommentWrapper);
                }
            caseDocCommentWrapper.caseCommentList = lstCaseCommentWrapper;
            caseDocCommentWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'CaseDocAndComment');
        }catch(Exception e){
            caseDocCommentWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL); 
            PMC_ErrorLogClass.processException(e); // MDErrorLog
        }
        return caseDocCommentWrapper;
    }
    /**
* @description Wrapper for case document and comment
*/
    public class CaseDocumentCommentWrapper{
        /**
* @description Boolean to check customer eligible to add comment and document
* @return Boolean
*/
        @AuraEnabled
        public Boolean boolEligibleToAddDocAndComments{get;set;}
        /**
* @description List of Document wrapper
* @return List<PMC_DH_CaseDocumentWrapper>
*/
        @AuraEnabled
        public List<PMC_DH_CaseDocumentWrapper> caseDocList{get;set;}
        /**
* @description List of Comment Wrapper
* @return List<PMC_DH_CommentWrapper>
*/
        @AuraEnabled
        public List<PMC_DH_CaseCommentWrapper> caseCommentList{get;set;}
        /**
        * @description Status Code and message
        * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
        */
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    } 
    /**
* @description Wrapper to case document records
*/
    public with sharing class PMC_DH_CaseDocumentWrapper{
        /**
* @description String to store case number
* @return String
*/
        @AuraEnabled
        public String strCaseNumber{get;set;}
        /**
* @description String to store document name
* @return String
*/
        @AuraEnabled
        public String strDocumentName{get;set;}
        /**
* @description String to store date added
* @return String
*/
        @AuraEnabled
        public DateTime strDateAdded{get;set;}
        /**
* @description String to store download url
* @return String
*/
        @AuraEnabled
        public String strDocDownloadUrl{get;set;}
    }
    /**
* @description Wrapper to case comment
*/
    public with sharing class PMC_DH_CaseCommentWrapper{
        /**
* @description String to store case number
* @return String
*/
        @AuraEnabled
        public String strCaseComment{get;set;}
        /**
* @description String to store document name
* @return Boolean
*/
        @AuraEnabled
        public Boolean boolIsCustomerCreated{get;set;}
    } 
    /****************************************************************************************
* @Method Name : createComment
* @description : Method to add comment by customer
* @param      caseId
* @param   strComment
* @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
****************************************************************************************/
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper createComment(String caseId, String strComment){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        try{
            CaseComment comment = new CaseComment();
            comment.ParentId = caseId;
            comment.CommentBody = strComment;
            if(Schema.sObjectType.CaseComment.isCreateable()){
                insert comment;
            }
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'CaseCommentCreation');
        }catch (Exception e) { 
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');  
            PMC_ErrorLogClass.processException(e);
        }
        return result;
    }
}