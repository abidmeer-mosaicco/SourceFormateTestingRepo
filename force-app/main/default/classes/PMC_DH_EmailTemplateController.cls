/** 
* @description Controller to customize Lightning Email Template 
* @author Nikhilesh
* @last modified on 2023-September-13
* @last modified by Nikhilesh
* Created On       :2023-August-29
**/
public with sharing class PMC_DH_EmailTemplateController {
    
    /*************************************************************************
* @method Name  : getContractTypeValues
* @description  : Method to get the required contract type values
* @param          contractId
* @return       : String
*****************************************************************************/
    public static String getContractTypeValues(Id contractId) {
        String contractTypes = '';
        // Query Quote and related fields
        SBQQ__Quote__c contractRecord = [SELECT Id, 
                                         (SELECT Id, PMC_CPQ_ContractType__c 
                                          FROM SBQQ__LineItems__r)
                                         FROM SBQQ__Quote__c
                                         WHERE Id = :contractId WITH SECURITY_ENFORCED];
        
        // Check if the Contract record is not null
        if (contractRecord.SBQQ__LineItems__r != null) {
            Set<String> setContractTypes = new Set<String>();
            for(SBQQ__QuoteLine__c qli : contractRecord.SBQQ__LineItems__r){
                if(!setContractTypes.contains(qli.PMC_CPQ_ContractType__c)){
                    setContractTypes.add(qli.PMC_CPQ_ContractType__c);
                    contractTypes += qli.PMC_CPQ_ContractType__c + ', ';
                }
            }
            contractTypes = contractTypes.removeEnd(', ');
        }
        return contractTypes;
    }
    
    /*************************************************************************
* @method Name  : getContactEmailIds
* @description  : Method to get the required email IDs of contacts
* @param          effAccId
* @return       : List<String>
*****************************************************************************/
    public static List<String> getContactEmailIds(Id effAccId){
        List<String> lstPersonaApplicable=PMC_DH_CommonSystemUtils.getListStoreConfigbyFeature(PMC_DH_ConstantClass.ACTION_PENDING_CONTRACT_PROFILES); 
        // Query on AccountContactRelation and fetch all the required Contact Email IDs        
        List<User> lstUsers = [SELECT Id, ContactId, Contact.Email, Email, IsActive FROM User 
                               WHERE ContactId IN (SELECT ContactId from AccountContactRelation WHERE AccountId =: effAccId 
                                                   AND Contact.PMC_SS_Status__c =: PMC_DH_ConstantClass.ACTIVE_STATUS) 
                               AND Profile.Name IN:lstPersonaApplicable 
                               AND IsActive = true 
                               WITH SYSTEM_MODE]; 
        List<String> lstContactEmailIds = new List<String>();
        for(User u : lstUsers){
            lstContactEmailIds.add(u.Contact.Email);
        }
        return lstContactEmailIds;
    }
        /*************************************************************************
* @method Name  : getHtmlTextBody
* @description  : Method to replace custom labels with their values in email HTML body
* @param          htmlTextBody
* @param		  contractTypeValues
* @param	  	  contractId
* @author		: Nikhilesh Mohanty
* @return       : String
*****************************************************************************/
    private static String getHtmlTextBody(String htmlTextBody, String contractTypeValues, Id contractId){
        htmlTextBody = htmlTextBody.replace('{{{SBQQ__Quote__c.PMC_CPQ_ContractType__c}}}', contractTypeValues);
        
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_contractReadyTitle}', Label.pmc_emailTemplate_contractReadyTitle);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_contractNumber}', Label.pmc_emailTemplate_contractNumber);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_contractType}', Label.pmc_emailTemplate_contractType);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_companyName}', Label.pmc_emailTemplate_companyName);
        
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_viewContract}', Label.pmc_emailTemplate_viewContract);
        
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_copyPasteLink1}', Label.pmc_emailTemplate_copyPasteLink1);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_copyPasteLink2}', Label.pmc_emailTemplate_copyPasteLink2);
        
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_customerService1}', Label.pmc_emailTemplate_customerService1);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_customerService2}', Label.pmc_emailTemplate_customerService2);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_customerService3}', Label.pmc_emailTemplate_customerService3);
        
        
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_contactUsLink}', Label.pmc_emailTemplate_contactUsLink);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_contactUs}', Label.pmc_emailTemplate_contactUs);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_copyright}', Label.pmc_emailTemplate_copyright);
        
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_contractReadyLink}', Label.pmc_emailTemplate_contractReadyLink);
        htmlTextBody = htmlTextBody.replace('{{{SBQQ__Quote__c.Id}}}', contractId);
        //added as part of GPT-17240
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_basePath}', Label.pmc_emailTemplate_basePath);

        return htmlTextBody;
    }
    /*************************************************************************
* @method Name  : sendEmailWithTemplate
* @description  : Method to send email to the respective contacts
* @param          lstContractId
* @return       : List<Boolean>
*****************************************************************************/
    @InvocableMethod(label='Contract Review Email')
    public static List<Boolean> sendEmailWithTemplate(List<Id> lstContractId) {
        Id contractId = lstContractId[0];
        String contractTypeValues = getContractTypeValues(contractId);
        SBQQ__Quote__c quoteRecord = [SELECT SBQQ__Account__c, PMC_CPQ_PrimaryContact__c from SBQQ__Quote__c where Id =: contractId WITH SECURITY_ENFORCED];
        // Fetch the list of recipient email IDs
        List<String> lstContactEmailIds = getContactEmailIds(quoteRecord.SBQQ__Account__c);
        
        // Create a new Email Template object and specify the template ID
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); 
        EmailTemplate emailTemplate = [Select Id, Name, Subject, HtmlValue from EmailTemplate WHERE Name = 'Your contract is ready for review' WITH SYSTEM_MODE];
        email.setTemplateId(emailTemplate.Id);
        email.setTargetObjectId(quoteRecord.PMC_CPQ_PrimaryContact__c);
        email.setWhatId(contractId);
        email.setSubject(emailTemplate.Subject);
        email.setSaveAsActivity(false); // Set to true if you want to log the email as an activity
        email.setBccAddresses(lstContactEmailIds);
        //get the org wide email address to use in the email method
        List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply.testmosaiccs@mosaicco.com' WITH SYSTEM_MODE]; //GPT-27258
        if(owea.size() > 0) {
            email.setOrgWideEmailAddressId(owea[0].Id); //GPT-27258
        }
        
        String htmlTextBody = emailTemplate.HtmlValue;
        htmlTextBody = getHtmlTextBody(htmlTextBody, contractTypeValues, contractId); //to remove NCSS line count SCA
        
        List<Messaging.RenderEmailTemplateBodyResult> renderResults = Messaging.renderEmailTemplate(quoteRecord.PMC_CPQ_PrimaryContact__c, contractId, new List<String>{htmlTextBody});
        String mergedBody = renderResults[0].getMergedBody();
        email.setHtmlBody(mergedBody);
        // Send the email
        Messaging.SendEmailResult[] result = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
        List<Boolean> lstBool = new List<Boolean>();
        lstBool.add(result[0].isSuccess());
        return lstBool;
    }
}