/**
 * @description       : 
 * @author            : @siddharth.pradhan
 * @group             : 
 * @last modified on  : 05-18-2023
 * @last modified by  : @siddharth.pradhan
**/
public without sharing class PMC_DH_AccessReviewController {
    
    public static final String PAGE_NAME ='my-accounts';
    public static final String EMAIL ='?email=';
    public static final String ACTIVE_TAB='&activeTab=user-management';
    public static final String SITE_NAME= 'Mosaic_Direct1'; //'Digital_Hub1';
    public static final String CONTACTUS ='contactus';

   /**
     * @description contact id from email template
     * @return string contId
     */
    public string contId{get;set;}
    
    /**
     * @description contact id from contact
     * @return contact contact
     */
    public contact contact {
        get{
            Contact c;
            if (Schema.sObjectType.Contact.isAccessible()) {
                c= [SELECT ID,FirstName,LastName,Email,toLabel(PMC_DH_Preferences__c) from Contact where Id=:contId ];
            }
            String desiredActivites=c.PMC_DH_Preferences__c;
            c.PMC_DH_Preferences__c=desiredActivites.replace(';', ', '); // comma separated 
            return c;
        } set;
    }
    
     /**
     * @description approval link
     * @return String approvallink
     */
    public String approvalLink{
        get{
                Site mySite = [select Id from Site where Name =:SITE_NAME ];
                SiteDetail mySiteDetail = [select SecureURL from SiteDetail where DurableId = :mySite.Id ];
                return mySiteDetail.SecureURL+PAGE_NAME+EMAIL+contact.Email+ACTIVE_TAB;
    }
    set;
}
        /**
     * @description contact us
     * @return String contactUsLink
     */
public String contactUsLink{
    get{
            Site mySite = [select Id from Site where Name =:SITE_NAME ];
            SiteDetail mySiteDetail = [select SecureURL from SiteDetail where DurableId = :mySite.Id ];
            return mySiteDetail.SecureURL+CONTACTUS;
}
set;
}
}