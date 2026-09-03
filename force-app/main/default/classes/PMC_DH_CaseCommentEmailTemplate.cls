/**
* @description Controller to customize Lightning Email Template 
* @author Lohitha
* @userStory   : GDASF-13391
* Created On       :2023-September-25
**/

public without sharing class PMC_DH_CaseCommentEmailTemplate {
    
    private final static String CONTACT_POINT_TYPE_EMAIL = 'Email';
    private final static String CONSENT_STATUS_OPTIN = 'OptIn';
    private final static String LEGAL_BASIS_CASES = 'Cases';
    private final static String DATA_USE_PURPOSE_CASE_COMMENTS= 'New Comments';
    
    /****************************************************************************
    * @method Name  : getContactEmailIds
    * @description  : Method to get the required email IDs of contacts
    * @param     caseRecord
    * @return    Set<String>
    *****************************************************************************/
    private static Set<String> getContactEmailIds(Case caseRecord){
        Set<String> setContactEmailIds = new Set<String>();
        // Query on AccountContactRelation and fetch all the required Contact Email IDs 
        Set<Id> setuserIdCaseAccess = new Set<Id>();
        for(CaseShare cs : [SELECT Id,UserOrGroupId FROM CaseShare Where CaseId=:caseRecord.Id WITH SYSTEM_MODE]){
            setuserIdCaseAccess.add(cs.UserOrGroupId);
        }
        List<String> lstPersonaApplicable=PMC_DH_CommonSystemUtils.getListStoreConfigbyFeature(PMC_DH_ConstantClass.CASE_COMMENT_PROFILES); 
        List<User> lstUsers = new List<User>();
        List<AccountContactRelation> lstACR = [SELECT ContactId from AccountContactRelation WHERE AccountId =: caseRecord.AccountId AND Contact.PMC_SS_Status__c =: PMC_DH_ConstantClass.ACTIVE_STATUS WITH SECURITY_ENFORCED];
        List<Id> lstContactIds = new List<Id>();
        for(AccountContactRelation acr: lstACR){
            lstContactIds.add(acr.ContactId);
        }
        //if(Test.isRunningTest()){
           
            lstUsers = [SELECT Id, ContactId, Contact.Email, Email, Contact.IndividualId, IsActive, Profile.Name FROM User 
                                   WHERE ContactId IN : lstContactIds
                                   AND Profile.Name IN:lstPersonaApplicable AND Id IN : setuserIdCaseAccess
                                   AND IsActive = true 
                                   WITH SYSTEM_MODE]; 
        //}        
        List<String> lstIndividualIds = new List<String>();
        Map<String, String> mapIdWithEmail = new Map<String, String>();
        for(User u : lstUsers){
            if(u.Contact.IndividualId != null){
                lstIndividualIds.add(u.Contact.IndividualId);
                mapIdWithEmail.put(u.Contact.IndividualId, u.Contact.Email);  
            }
        }
        // Get list of individual Ids of recipients
        List<String> lstRecipientIds = getIndividualIds(lstIndividualIds, DATA_USE_PURPOSE_CASE_COMMENTS, LEGAL_BASIS_CASES);
        
        // Get list of email Ids of recipients
        //Set<String> lstContactEmailIds = new Set<String>();
        if(!lstRecipientIds.isEmpty()){
            for(String str : lstRecipientIds){
                setContactEmailIds.add(mapIdWithEmail.get(str));
            }
        }
        return setContactEmailIds;
    }
    
    /*************************************************************************
* @method Name  : getIndividualIds
* @description  : Method to get the list of IDs of individuals
* @param		  lstIndividualIds
* @param          strDataUsePurpose
* @param		  strLegalBasis
* @return       : List<String>
*****************************************************************************/
    // This can be a common utility method for different contact point types (Email, Phone etc) and legal bases (Quotes, Contracts etc)
    private static List<String> getIndividualIds(List<String> lstIndividualIds, String strDataUsePurpose, String strLegalBasis){
        List<String> lstRecipientIds = new List<String>();
        List<ContactPointTypeConsent> lstConPointTypeConsent = [SELECT ContactPointType, PrivacyConsentStatus, PartyId, DataUsePurpose.Name, DataUsePurpose.LegalBasis.Name from ContactPointTypeConsent 
                                                                WHERE ContactPointType =: CONTACT_POINT_TYPE_EMAIL AND PrivacyConsentStatus =: CONSENT_STATUS_OPTIN 
                                                                AND PartyId IN: (lstIndividualIds)
                                                                AND DataUsePurpose.Name =: strDataUsePurpose AND DataUsePurpose.LegalBasis.Name =: strLegalBasis
                                                                WITH SYSTEM_MODE];
        
        if(!lstConPointTypeConsent.isEmpty()){
            for(ContactPointTypeConsent cptc : lstConPointTypeConsent){
                lstRecipientIds.add(cptc.PartyId);
            }
        }
        return lstRecipientIds;
    }

    /****************************************************************************
    * @method Name  : sendEmailWithTemplate
    * @description  : Method to send email to the respective contacts
    * @param          lstCaseId
    * @return       : List<Boolean>
    *****************************************************************************/
    @InvocableMethod(label='New case comment Email')
    public static List<Boolean> sendEmailWithTemplate(List<Id> lstCaseId) {

        Id caseId = lstCaseId[0];
        Case caseRecord = [SELECT Id, OwnerId, CreatedById, CreatedBy.Email, Owner.Email,AccountId FROM Case Where Id =: caseId WITH SECURITY_ENFORCED];
        User loggedInUser = [SELECT Id,ContactId,Contact.EMail FROM User Where Id=:caseRecord.CreatedById WITH SECURITY_ENFORCED];
        // Fetch the list of recipient email IDs
        Set<String> setContactEmailIds = getContactEmailIds(caseRecord);
        // Create a new Email Template object and specify the template ID
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        EmailTemplate emailTemplate = [Select Id, Name, Subject, HtmlValue from EmailTemplate WHERE Name = 'PMC_DH_YourCaseHasBeenUpdated' WITH SYSTEM_MODE];
        email.setTemplateId(emailTemplate.Id);
        if(setContactEmailIds.contains(loggedInUser.Contact.Email)){
            email.setTargetObjectId(loggedInUser.ContactId);
        }else{
            email.setTargetObjectId(NULL);
        }
        email.setWhatId(caseId);
        email.setSubject(emailTemplate.Subject);
        email.setSaveAsActivity(false); // Set to true if you want to log the email as an activity
        email.setBccAddresses(new List<String>(setContactEmailIds));
        String htmlTextBody = labelMappingToTemplate(emailTemplate.HtmlValue);
        //email.setHtmlBody(htmlTextBody);

        List<Messaging.RenderEmailTemplateBodyResult> renderResults = Messaging.renderEmailTemplate(loggedInUser.ContactId, caseId, new List<String>{htmlTextBody});
        String mergedBody = renderResults[0].getMergedBody();
        email.setHtmlBody(mergedBody);
        // Send the email
        Messaging.SendEmailResult[] result ;
         List<Boolean> lstBool = new List<Boolean>();
        if(!setContactEmailIds.isEmpty()){
            result = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            lstBool.add(result[0].isSuccess());
        }
       
       
       
        return lstBool;
    }

    // to pass the label mapping 
    private static string labelMappingToTemplate(String htmlTextBody){
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_caseUpdated}', Label.pmc_emailTemplate_caseUpdated);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_caseNumber}', Label.pmc_emailTemplate_caseNumber);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_caseInquiryType}', Label.pmc_emailTemplate_caseInquiryType);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_caseTopic}', Label.pmc_emailTemplate_caseTopic);
        
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_caseViewBtn}', Label.pmc_emailTemplate_caseViewBtn);
        
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_copyPasteLink1}', Label.pmc_emailTemplate_copyPasteLink1);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_copyPasteLink2}', Label.pmc_emailTemplate_copyPasteLink2);
        
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_caseViewLink}', Label.pmc_emailTemplate_caseViewLink);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_caseNumberLink}', Label.pmc_emailTemplate_caseNumberLink);
        
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_customerService1}', Label.pmc_emailTemplate_customerService1);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_customerService2}', Label.pmc_emailTemplate_customerService2);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_customerService3}', Label.pmc_emailTemplate_customerService3);
        
      
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_contactUsLink}', Label.pmc_emailTemplate_contactUsLink);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_contactUs}', Label.pmc_emailTemplate_contactUs);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_copyright}', Label.pmc_emailTemplate_copyright);
        
        //added by Nikhilesh as part of GPT-17240
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_basePath}', Label.pmc_emailTemplate_basePath);
        return htmlTextBody;

    }
}