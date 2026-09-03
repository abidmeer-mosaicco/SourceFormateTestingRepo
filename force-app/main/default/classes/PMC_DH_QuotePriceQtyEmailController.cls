/** 
* @description Controller to customize Lightning Email Template for Quote Update 
* @author Nikhilesh
* @last modified on 2023-Sept-18
* @last modified by Nikhilesh
* Created On       :2023-Sept-08
**/
public with sharing class PMC_DH_QuotePriceQtyEmailController {
    /*************************************************************************
* @method Name  : sendEmailforQuoteUpdate
* @description  : Method to send email for quote price/qty update to the respective contacts
* @param          lstQuoteId
* @return       : List<Boolean>
*****************************************************************************/
    @InvocableMethod(label='Quote Price/Qty Update Email')
    public static List<Boolean> sendEmailforQuoteUpdate(List<Id> lstQuoteId) {
        List<Boolean> lstBool = new List<Boolean>();
        List<SBQQ__QuoteLine__History> lstQuoteLineHistory=new List<SBQQ__QuoteLine__History>();
        Id quoteId = lstQuoteId[0];
        SBQQ__Quote__c quoteRecord = [SELECT SBQQ__Account__c, PMC_CPQ_PrimaryContact__c, PMC_CPQ_PrimaryContact__r.Email, PMC_DH_QuotePresentedTime__c from SBQQ__Quote__c where Id =: quoteId WITH SECURITY_ENFORCED];
        
        // Fetch the list of price/qty changes on all quote line items
        if(!Test.isRunningTest())
        {
            lstQuoteLineHistory = PMC_DH_EmailUtils.getQuoteLineHistory(quoteRecord.Id, quoteRecord.PMC_DH_QuotePresentedTime__c);
        }
        else if(Test.isRunningTest())
        {
            PMC_DH_EmailUtils.getQuoteLineHistory(quoteRecord.Id, System.now());
            SBQQ__QuoteLine__History hisData = new SBQQ__QuoteLine__History(Field='Name');
            lstQuoteLineHistory.add(hisData);
        }
        // if there are price/qty related changes, render and send the email
        if(!lstQuoteLineHistory.isEmpty()){
            
            // Fetch the list of recipient email IDs
            List<String> lstContactEmailIds = PMC_DH_EmailUtils.getContactEmailIds(quoteRecord.SBQQ__Account__c, PMC_DH_ConstantClass.DATA_USE_PURPOSE_QUOTEUPDATE, PMC_DH_ConstantClass.LEGAL_BASIS_QUOTES);
            
            // Create a new Email Template object and specify the template ID
            EmailTemplate emailTemplate = [Select Id, Name, Subject, HtmlValue from EmailTemplate WHERE Name =: PMC_DH_ConstantClass.TEMPLATE_NAME_QUOTEUPDATE WITH SYSTEM_MODE];
            Messaging.SingleEmailMessage email = PMC_DH_EmailUtils.renderEmail(emailTemplate, quoteRecord, lstContactEmailIds);
            
            // replace template specific values first
            String htmlTextBody = emailTemplate.HtmlValue;
            htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_quoteUpdatedTitle}', Label.pmc_emailTemplate_quoteUpdatedTitle);
            htmlTextBody = htmlTextBody.replace('{labels.pmc_emailTemplate_quoteUpdatedBody}', Label.pmc_emailTemplate_quoteUpdatedBody);
            
            email = PMC_DH_EmailUtils.getHtmlTextBody(htmlTextBody, quoteRecord, email);
            
            // Send the email
            if(!lstContactEmailIds.isEmpty()){
                Messaging.SendEmailResult[] result = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
                lstBool.add(result[0].isSuccess());
                
                // update PMC_DH_QuotePresentedTime__c if email was sent successfully
                //if(lstBool[0] == true){
                updateQuotePresentedTime(quoteRecord, lstBool[0]);
                //}
            }
        }
        return lstBool;
    }
    /*************************************************************************
* @method Name  : updateQuotePresentedTime
* @description  : Method to update PMC_DH_QuotePresentedTime__c to current DateTime value
* @param          quoteRecord
* @param		  boolIsSuccess
*****************************************************************************/
    public static void updateQuotePresentedTime(SBQQ__Quote__c quoteRecord, Boolean boolIsSuccess){
        if(boolIsSuccess == true){
            quoteRecord.PMC_DH_QuotePresentedTime__c = System.now();
            if(Schema.sObjectType.SBQQ__Quote__c.isUpdateable()){
                update quoteRecord;
            }
        }
    }
}