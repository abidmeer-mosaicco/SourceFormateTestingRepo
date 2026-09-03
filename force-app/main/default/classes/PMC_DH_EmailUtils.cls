/** 
* @description Utility class for Lightning Email Template controller classes
* @author Nikhilesh
* @last modified on 2023-Sept-12
* @last modified by Nikhilesh
* Created On       :2023-Sept-12
**/
public without sharing class PMC_DH_EmailUtils {
    private static final String CONTACT_POINT_TYPE_EMAIL = 'Email';
    private static final String CONSENT_STATUS_OPTIN = 'OptIn';
    /*************************************************************************
* @method Name  : getQuoteLineHistory
* @description  : Method to get the list of quote line history values
* @param          strParentId
* @param		  datTquotePresented
* @return       : List<SBQQ__QuoteLine__History>
*****************************************************************************/
    public static List<SBQQ__QuoteLine__History> getQuoteLineHistory(String strParentId, DateTime datTquotePresented)
    {
        List<String> lstFieldAPINames=PMC_DH_CommonSystemUtils.getListStoreConfigbyFeature(PMC_DH_ConstantClass.QUOTE_LINE_HISTORY_FIELDS); 
        //PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        List<SBQQ__QuoteLine__History> lstQLH =  [SELECT CreatedDate, toLabel(Field), NewValue, OldValue, Parent.SBQQ__Quote__c
                                                  FROM SBQQ__QuoteLine__History 
                                                  WHERE Parent.SBQQ__Quote__c=:strParentId  
                                                  AND toLabel(Field) IN:lstFieldAPINames
                                                  AND CreatedDate >=: datTquotePresented
                                                  WITH SYSTEM_MODE]; // querying on QL history, hence using SYSTEM_MODE
        return lstQLH;
    }

    /*************************************************************************
* @method Name  : getContactEmailIds
* @description  : Method to get the required email IDs of contacts
* @param          effAccId
* @param		  strDataUsePurpose
* @param		  strLegalBasis
* @author		: Nikhilesh Mohanty
* @return       : List<String>
*****************************************************************************/
    public static List<String> getContactEmailIds(Id effAccId, String strDataUsePurpose, String strLegalBasis){
        
        List<String> lstPersonaApplicable=PMC_DH_CommonSystemUtils.getListStoreConfigbyFeature(PMC_DH_ConstantClass.QUOTE_PROFILES); 
        // Query on AccountContactRelation and fetch all the required Individual IDs        
        List<User> lstUsers = [SELECT ContactId, Contact.Email, Contact.FirstName, Contact.LastName, Contact.IndividualId FROM User 
                               WHERE ContactId IN (SELECT ContactId from AccountContactRelation WHERE AccountId =: effAccId 
                                                   AND Contact.PMC_SS_Status__c =: PMC_DH_ConstantClass.ACTIVE_STATUS)            
                               AND Profile.Name IN:lstPersonaApplicable
                               AND IsActive = true
                               WITH SYSTEM_MODE]; // querying on User, hence using SYSTEM_MODE
        
        List<String> lstIndividualIds = new List<String>();
        Map<String, String> mapIdWithEmail = new Map<String, String>();
        if(!lstUsers.isEmpty()){
            for(User u : lstUsers){
                if(u.Contact.IndividualId != null){
                    lstIndividualIds.add(u.Contact.IndividualId);
                    mapIdWithEmail.put(u.Contact.IndividualId, u.Contact.Email);  
                }
            }
        }
        // Get list of individual Ids of recipients
        List<String> lstRecipientIds = getIndividualIds(lstIndividualIds, strDataUsePurpose, strLegalBasis);
        
        // Get list of email Ids of recipients
        List<String> lstContactEmailIds = new List<String>();
        //Set<String> setContactEmailIds = new Set<String>();
        if(!lstRecipientIds.isEmpty()){
            for(String str : lstRecipientIds){
                lstContactEmailIds.add(mapIdWithEmail.get(str));
                //setContactEmailIds.add(mapIdWithEmail.get(str));
            }
        }
        return lstContactEmailIds;
        //return setContactEmailIds;
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
    /*************************************************************************
* @method Name  : renderEmail
* @description  : Method to render the email using the template
* @param          emailTemplate
* @param		  quoteRecord
* @param		  lstContactEmailIds
* @author		: Nikhilesh Mohanty
* @return       : Messaging.SingleEmailMessage
*****************************************************************************/
    public static Messaging.SingleEmailMessage renderEmail(EmailTemplate emailTemplate, SBQQ__Quote__c quoteRecord, List<String> lstContactEmailIds){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTemplateId(emailTemplate.Id);
        if(lstContactEmailIds.contains(quoteRecord.PMC_CPQ_PrimaryContact__r.Email)){
            email.setTargetObjectId(quoteRecord.PMC_CPQ_PrimaryContact__c);
        }
        else{
            email.setTargetObjectId(null);
        }
        email.setWhatId(quoteRecord.Id);
        email.setSubject(emailTemplate.Subject);
        email.setSaveAsActivity(false); // Set to true if you want to log the email as an activity
        email.setBccAddresses(lstContactEmailIds);
        //get the org wide email address to use in the email method
        List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply.testmosaiccs@mosaicco.com' WITH SYSTEM_MODE]; //GPT-27258
        if(owea.size() > 0) {
            email.setOrgWideEmailAddressId(owea[0].Id); //GPT-27258
        }
        return email;
    }
    /*************************************************************************
* @method Name  : getHtmlTextBody
* @description  : Method to replace custom labels with their values in email HTML body
* @param          htmlTextBody
* @param		  quoteRecord
* @param	  	  email
* @author		: Nikhilesh Mohanty
* @return       : Messaging.SingleEmailMessage
*****************************************************************************/
    public static Messaging.SingleEmailMessage getHtmlTextBody(String htmlTextBody, SBQQ__Quote__c quoteRecord, Messaging.SingleEmailMessage email){
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_quoteRequestNumber}', Label.pmc_emailTemplate_quoteRequestNumber);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_quoteId}', Label.pmc_emailTemplate_quoteId);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_companyName}', Label.pmc_emailTemplate_companyName);
        
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_viewQuote}', Label.pmc_emailTemplate_viewQuote);
        
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_copyPasteLink1}', Label.pmc_emailTemplate_copyPasteLink1);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_copyPasteLink2}', Label.pmc_emailTemplate_copyPasteLink2);
        
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_customerService1}', Label.pmc_emailTemplate_customerService1);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_customerService2}', Label.pmc_emailTemplate_customerService2);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_customerService3}', Label.pmc_emailTemplate_customerService3);
        
        
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_contactUsLink}', Label.pmc_emailTemplate_contactUsLink);
        
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_contactUs}', Label.pmc_emailTemplate_contactUs);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_copyright}', Label.pmc_emailTemplate_copyright);
        
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_quoteNumber}', Label.pmc_emailTemplate_quoteNumber);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_quoteIdUrl}', Label.pmc_emailTemplate_quoteIdUrl);
        
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_quoteNavigationLink}', Label.pmc_emailTemplate_quoteNavigationLink);

        //added as part of GPT-17240
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_basePath}', Label.pmc_emailTemplate_basePath);
        
        List<Messaging.RenderEmailTemplateBodyResult> renderResults = Messaging.renderEmailTemplate(quoteRecord.PMC_CPQ_PrimaryContact__c, quoteRecord.Id, new List<String>{htmlTextBody});
        String mergedBody = renderResults[0].getMergedBody();
        email.setHtmlBody(mergedBody);
        
        return email;
    }
}