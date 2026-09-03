/** 
* @description Controller to send email for quote in review 
* @author Hemant Giri Goswami
* @since 09-07-2023
**/

public with sharing class PMC_DH_QuoteReviewEmailController {
    /*************************************************************************
* @method Name  : sendEmailforQuoteReview
* @description  : Method to send email when quote is in review'
* @author		: Hemant Giri Goswami
* @param          lstQuoteId
* @return       : List<Boolean>
*****************************************************************************/
    @InvocableMethod(label='Quote Review Email')
    public static List<Boolean> sendEmailforQuoteReview(List<Id> lstQuoteId)
    {
        List<Boolean> lstBool=new List<Boolean>();
        Id quoteId = lstQuoteId[0];
        SBQQ__Quote__c quoteRecord = [SELECT SBQQ__Account__c, PMC_CPQ_PrimaryContact__c, PMC_CPQ_PrimaryContact__r.Email from SBQQ__Quote__c where Id =: quoteId WITH SECURITY_ENFORCED];
        
        // Fetch the list of recipient email IDs
        List<String> lstContactEmailIds = PMC_DH_EmailUtils.getContactEmailIds(quoteRecord.SBQQ__Account__c, PMC_DH_ConstantClass.DATA_USE_PURPOSE_QUOTEREVIEW, PMC_DH_ConstantClass.LEGAL_BASIS_QUOTES);
        
        // Create a new Email Template object and specify the template ID
        EmailTemplate emailTemplate = [Select Id, Name, Subject, HtmlValue from EmailTemplate WHERE Name =: PMC_DH_ConstantClass.TEMPLATE_NAME_QUOTEREVIEW WITH SYSTEM_MODE];
        Messaging.SingleEmailMessage email = PMC_DH_EmailUtils.renderEmail(emailTemplate, quoteRecord, lstContactEmailIds);
        
        // replace template specific values first
        String htmlTextBody = emailTemplate.HtmlValue;
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_quoteInReviewTitle}', Label.pmc_emailTemplate_quoteInReviewTitle);
        htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_quoteInReviewBody}', Label.pmc_emailTemplate_quoteInReviewBody);
        
        email = PMC_DH_EmailUtils.getHtmlTextBody(htmlTextBody, quoteRecord, email);
        
        // Send the email
        if(!lstContactEmailIds.isEmpty()){
            Messaging.SendEmailResult[] result = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            lstBool.add(result[0].isSuccess());
        }
        return lstBool;
    }
}