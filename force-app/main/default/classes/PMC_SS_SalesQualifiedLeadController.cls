/**
* @description Controller used to fetch lead info & send email to Retailer.
* @author Kailas Shimpi
* @storynumber GDASF-2092
**/

public with sharing class PMC_SS_SalesQualifiedLeadController {
    /**
	* @description Method to send email to Retailer to review the Lead
	* @param lstLead - Lead Record from where the quick action was fired to send out an email
	*/
    @InvocableMethod(label='Retailer Lead Email')
    public static void sendEmailforRetailerLeadReview(List<Lead> lstLead) {
        try {
            EmailTemplate objRetailerLeadEmailTemplate = new EmailTemplate();
            Messaging.SingleEmailMessage objRetailerLeadSingleEmailMsg = new Messaging.SingleEmailMessage();
            Lead objLead;
            
            if(!lstLead.isEmpty()){
                objLead = lstLead[0];
            }
            //Query Retailer Lead's Email Template with the help of template name
            objRetailerLeadEmailTemplate = [SELECT Id,Name,Subject,HtmlValue FROM EmailTemplate WHERE Name =: PMC_SS_ConstantClass.TEMPLATE_NAME_LEAD_REVIEW WITH SECURITY_ENFORCED];
            
            //Method call to set the parameters to send email
            objRetailerLeadSingleEmailMsg = assignRetailerLeadMailParams(objRetailerLeadEmailTemplate, objLead);
            
            //Pass Single Email Message object instance to send the email
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{objRetailerLeadSingleEmailMsg});
        } catch(Exception objException) {
            objException.setMessage(PMC_SS_ConstantClass.EMAIL_EXCEPTION_MESSAGE);
            PMC_ErrorLogClass.processException(objException);
        }
    }
    
    /**
	* @description Method to set the parameters to send email
	* @param objRetailerLeadEmailTemplate - EmailTemplate record to get the values from it
    * @param objLead - Lead object to get the lead values from it
	* @return Messaging.SingleEmailMessage - Returns Single Email Message object instance after setting up the values
	*/
    public static Messaging.SingleEmailMessage assignRetailerLeadMailParams(EmailTemplate objRetailerLeadEmailTemplate, Lead objLead) {
        Messaging.SingleEmailMessage objRetailerLeadSingleEmailMsg = new Messaging.SingleEmailMessage();
        List<String> lstEmailIds = new List<String>();
        
        //Add lead owner's email ID
        lstEmailIds.add(objLead.OwnerId);

        objRetailerLeadSingleEmailMsg.setTemplateId(objRetailerLeadEmailTemplate.Id);
        objRetailerLeadSingleEmailMsg.setSubject(objRetailerLeadEmailTemplate.Subject);
        objRetailerLeadSingleEmailMsg.setTreatBodiesAsTemplate(true);
        objRetailerLeadSingleEmailMsg.setTreatTargetObjectAsRecipient(false);
        objRetailerLeadSingleEmailMsg.setTargetObjectId(objLead.Id);
        objRetailerLeadSingleEmailMsg.setToAddresses(lstEmailIds);
        objRetailerLeadSingleEmailMsg.setHtmlBody(replaceLeadMailBodyWithCustomLabels(objRetailerLeadEmailTemplate.HtmlValue));
        
        return objRetailerLeadSingleEmailMsg;
    }
    
    /**
    * @description - Method to replace hard coded values with custom label values in email HTML body
    * @param strRetailerLeadEmailBody - Html values from lightning email template
    * @return String - Returns String after replacing hard coded values with custom label values
    */
    public static String replaceLeadMailBodyWithCustomLabels(String strRetailerLeadEmailBody) {
        
        //Replace hard coded values from email template body with custom label values in email body
        strRetailerLeadEmailBody = strRetailerLeadEmailBody.replace('{Label.PMC_SS_RetailerLeadEmailTemplate_HelloText}', Label.PMC_SS_RetailerLeadEmailTemplate_HelloText);
        strRetailerLeadEmailBody = strRetailerLeadEmailBody.replace('{Label.PMC_SS_RetailerLeadEmailTemplate_LeadInformation}', Label.PMC_SS_RetailerLeadEmailTemplate_LeadInformation);
        strRetailerLeadEmailBody = strRetailerLeadEmailBody.replace('{Label.PMC_SS_RetailerLeadEmailTemplate_LeadName}', Label.PMC_SS_RetailerLeadEmailTemplate_LeadName);
        strRetailerLeadEmailBody = strRetailerLeadEmailBody.replace('{Label.PMC_SS_RetailerLeadEmailTemplate_LeadProdInterest}', Label.PMC_SS_RetailerLeadEmailTemplate_LeadProdInterest);
        strRetailerLeadEmailBody = strRetailerLeadEmailBody.replace('{Label.PMC_SS_RetailerLeadEmailTemplate_LeadReviewText}', Label.PMC_SS_RetailerLeadEmailTemplate_LeadReviewText);
        strRetailerLeadEmailBody = strRetailerLeadEmailBody.replace('{Label.PMC_SS_MosaicDirect_SiteBaseURL}', Label.PMC_SS_MosaicDirect_SiteBaseURL);
        strRetailerLeadEmailBody = strRetailerLeadEmailBody.replace('{Label.PMC_SS_MosaicDirect_SiteURLPath}', Label.PMC_SS_MosaicDirect_SiteURLPath);
        strRetailerLeadEmailBody = strRetailerLeadEmailBody.replace('{Label.PMC_SS_MosaicDirect_SiteName}', Label.PMC_SS_MosaicDirect_SiteName);
        strRetailerLeadEmailBody = strRetailerLeadEmailBody.replace('{Label.PMC_SS_RetailerLeadEmailTemplate_ThankYouText}', Label.PMC_SS_RetailerLeadEmailTemplate_ThankYouText);
        strRetailerLeadEmailBody = strRetailerLeadEmailBody.replace('{Label.PMC_SS_RetailerLeadEmailTemplate_SalesforceTeamText}', Label.PMC_SS_RetailerLeadEmailTemplate_SalesforceTeamText);
		
        return strRetailerLeadEmailBody;
    }
}