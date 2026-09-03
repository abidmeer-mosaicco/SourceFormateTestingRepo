/**
* @description : Controller class for notification preference
* @author      : Ajeet
* @userStory   : GDASF-11860
* @last modified on 
* @last modified by 
**/
public without sharing class PMC_DH_NotificationPreferenceController {
/**
* @description create contact point type consent record for notification preferences
* @param userId
*/
    public static String individualId = '';
    public static void createNotificationPref(String userId){
        User usr = [SELECT Id, ContactId,Contact.IndividualId,Contact.FirstName,Contact.LastName, Profile.Name FROM User WHERE Id =: userId WITH SYSTEM_MODE];
        String profileName = '%'+usr.Profile.Name +'%';
        Contact con = new Contact(Id=usr.ContactId);
        if(usr.Contact.IndividualId==null){
            Individual ind = new Individual();
            ind.FirstName = usr.Contact.FirstName;
            ind.LastName = usr.Contact.LastName;
            if(Schema.sObjectType.Individual.isCreateable()){
                insert ind;
            }
            con.IndividualId = ind.Id;
            individualId = con.IndividualId;
        }else{
        individualId = usr.Contact.IndividualId;
        }
        con.HasOptedOutOfEmail = false;
        con.PMC_SS_SMSOptOut__c = false;
        con.PMC_SS_WhatsappOptOut__c = false;
        if(Schema.sObjectType.Contact.isUpdateable()){
            //Added a Recursion Check - Prashanth Kamma - 08/05/2025
            PMC_SS_TriggerRecursionGuard.markProcessed('Contact_afterUpdate');
            update con;
        }
        Map<String, DataUsePurpose> dataUseMap = new Map<String, DataUsePurpose>();
        List<DataUsePurpose> lstDataUse = [SELECT Id, Name, LegalBasis.Name FROM DataUsePurpose WITH SYSTEM_MODE];
        for(DataUsePurpose dataUse: lstDataUse){
            String mapKey = dataUse.Name + dataUse.LegalBasis.Name;
            dataUseMap.put(mapKey,dataUse);
        }
        List<PMC_DH_Preference_Notification__mdt> lstPrefNotification = [SELECT PMC_DH_Default_Opt_In__c, PMC_DH_Notification_Type__c, PMC_DH_Notification_Sub_Type__c, PMC_DH_Profile__c, PMC_DH_Preferences__c, PMC_DH_Sequence__c FROM PMC_DH_Preference_Notification__mdt WHERE PMC_DH_Profile__c LIKE : profileName WITH SECURITY_ENFORCED];
        List<ContactPointTypeConsent> lstCPTConsent = new List<ContactPointTypeConsent>();
        for(PMC_DH_Preference_Notification__mdt prefNotif:lstPrefNotification){
            if(prefNotif.PMC_DH_Preferences__c.contains('Email')){
                ContactPointTypeConsent cptConsent = buildConsentRecord(prefNotif,dataUseMap,'Email');
                lstCPTConsent.add(cptConsent);
            }
        }
        if(Schema.sObjectType.ContactPointTypeConsent.isCreateable()){
            insert lstCPTConsent;
        }
    }

    /**
    * @description create contact point type consent record for notification preferences
    * @param prefNot
    * @param dataUseMap
    * @param notType
    * @return ContactPointTypeConsent
    */
       private static ContactPointTypeConsent buildConsentRecord(PMC_DH_Preference_Notification__mdt prefNot, Map<String, DataUsePurpose> dataUseMap, String notType){
        ContactPointTypeConsent cptConsent = new ContactPointTypeConsent();
        cptConsent.Name = prefNot.PMC_DH_Notification_Sub_Type__c;
        cptConsent.PartyId = individualId;
        cptConsent.PrivacyConsentStatus = 'OptIn';
        cptConsent.ContactPointType = notType;
        String mapKey = prefNot.PMC_DH_Notification_Sub_Type__c + prefNot.PMC_DH_Notification_Type__c;
        if (dataUseMap.containsKey(mapKey)){
            cptConsent.DataUsePurposeId = dataUseMap.get(mapKey).Id;
        }
        return cptConsent;
    }
}