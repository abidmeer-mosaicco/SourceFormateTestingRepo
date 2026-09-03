/**
 * @description       : 
 * @author            : @siddharth.pradhan
 * @group             : 
 * @last modified on  : 05-20-2023
 * @last modified by  : @siddharth.pradhan
**/
public with sharing class PMC_DH_HubAccessReviewUtils {
    
    public final static string EMAIL_TEMPLATENAME='PMC_DH_AccessReviewRequest';

    /**
    * @description 
    * @author @siddharth.pradhan | 05-20-2023 
    * @param lstContacts 
    **/
    @InvocableMethod(label='Access Review to Super Buyer' description='Email Triggered to Super Buyer once contact is created by registration')
    public static void sendEmail(List<Contact> lstContacts) {
        List<String> lstRecipientEmailList = new List<String>();
        if(!lstContacts.isEmpty()){
            String strSuperBuyerEmail=getSuperBuyerEmailId(lstContacts[0].ID);
       
            if(!String.isBlank(strSuperBuyerEmail))
            {
                EmailTemplateWrapper emailwrp=new EmailTemplateWrapper();
                lstRecipientEmailList.add(strSuperBuyerEmail);
                emailwrp.strtemplateName=EMAIL_TEMPLATENAME;
                emailwrp.lstRecipientEmailList=lstRecipientEmailList;
                emailwrp.strWhatId=lstContacts[0].ID;
                renderAndSendEmail(emailwrp);
            }
           
        }
     
}


    /**
    * @description fetch the super buyer for the account and send email
    * @author @siddharth.pradhan | 05-06-2023 
    * @param strConId 
    * @return String 
    **/
    private static String getSuperBuyerEmailId(String strConId) {
        String strSuperBuyerEmailId='';
        List<Contact> lstCon=[Select Id,Email,AccountId from Contact where id=:strConId WITH SECURITY_ENFORCED];
        if(!lstCon.isEmpty())
        {
            Set<String> setConEmails = new Set<String>();
            for (AccountContactRelation acr :[Select Id,Contact.Email from AccountContactRelation where AccountId=:lstCon[0].AccountId WITH SECURITY_ENFORCED]) {
                setConEmails.add(acr.Contact.Email);
            }
            List<User> usr=[Select Id,Email,Profile.Name from user where Profile.Name=:PMC_DH_ConstantClass.USER_PROFILE_DH_SUPER_BUYER WITH SECURITY_ENFORCED];
            strSuperBuyerEmailId=String.valueOf(usr[0].Email);
            
        } 
        return strSuperBuyerEmailId;
    }

  
  
    /**
    * @description 
    * @author @siddharth.pradhan | 05-06-2023 
    * @param emailwrp 
    **/
    private static void renderAndSendEmail(EmailTemplateWrapper emailwrp) {
       
        EmailTemplate emailTemplate = [SELECT Id,Subject  FROM EmailTemplate WHERE Name =:emailwrp.strtemplateName WITH SECURITY_ENFORCED];
        
        // Set the recipients of the email
        
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplate.Id, null, emailwrp.strWhatId);

        mail.setToAddresses(emailwrp.lstRecipientEmailList);
        mail.setSubject(emailTemplate.Subject);
        mail.sethtmlBody(mail.gethtmlBody());
        mail.saveAsActivity = false;
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
        }

    /**
    * @description recipients
    **/
        public class EmailTemplateWrapper 
{
        /**
        * @description email template name
        * @return String 
        **/
        public String strtemplateName{get;set;}
        
        /**
        * @description recipients
        * @return List<String> 
        **/
        public List<String> lstRecipientEmailList{get;set;} 
        /**
        * @description related to object id
        * @return List<String> 
        **/
        public String strWhatId{get;set;}

    }

        
    }