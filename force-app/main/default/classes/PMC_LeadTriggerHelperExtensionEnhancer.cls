/**
* @description This class is an enahncer to PMC_LeadTriggerHelperExtension class to avoid complexity
* @author Kailas Shimpi
* @TestClass PMC_LeadTriggerHelperTest
*/
public without sharing class PMC_LeadTriggerHelperExtensionEnhancer {
	/**
     * @description This method is used to send notifications when a Lead owner is changed.
     * @author Nandini Dey
     * @param lstUpdatedLeads List of newly updated Leads
     * @param mapOldLeads Map of old values of Leads before updation
     */
    public static void notifyNewLeadOwner(List<Lead> lstUpdatedLeads, Map<Id, Lead> mapOldLeads){
        
        //Call Custom Notification created in Org
        CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'PMC_SS_CustomPushNotification' WITH SYSTEM_MODE];
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        String newOwnerId;
        String strLeadFirstName;
        Map<ID, String> mapNewOwnerIdProfileName = new Map<ID, String>();
        
        //Getting OwnerId of the Triggering Leads.
        for(Lead objLead: lstUpdatedLeads) {
            mapNewOwnerIdProfileName.put(objLead.OwnerId,'');
        }
        
        try {
            Map<ID, User> mapIdVsUser = new Map<ID, User>([Select Id, Profile.Name from User where Id In :mapNewOwnerIdProfileName.keySet()]);
            
            for(Lead updatedLead : lstUpdatedLeads){
                newOwnerId = String.valueof(updatedLead.OwnerId);
                strLeadFirstName = updatedLead.FirstName != NULL ? updatedLead.FirstName : ''; 
                //Condition to check if Lead Owner was updated
                if(updatedLead.OwnerId != mapOldLeads.get(updatedLead.Id).OwnerId && newOwnerId.startsWith(PMC_SS_ConstantClass.USER_ID_CODE) && !(mapIdVsUser.get(updatedLead.OwnerId).Profile.Name.contains(PMC_SS_ConstantClass.PORTAL_USER_PROFILE))){
                    //Configure notification to be sent to new Lead Owner                   
                    notification.setTitle( PMC_SS_ConstantClass.NEW_LEAD + ', ' + strLeadFirstName + ' ' + updatedLead.LastName + ' ' + PMC_SS_ConstantClass.ASSIGNED_TO);
                    notification.setBody(PMC_SS_ConstantClass.NEW_LEAD + ', ' + strLeadFirstName + ' ' + updatedLead.LastName + ' ' + PMC_SS_ConstantClass.ASSIGNED_TO + PMC_SS_ConstantClass.TAKE_ACTION);
                    notification.setNotificationTypeId(notificationType.id);
                    notification.setTargetId(updatedLead.Id);
                    //Send notification to new Lead Owner
                    notification.send(new Set<String> {updatedLead.OwnerId});
                }
            }
        } catch (Exception objException) {
            PMC_ErrorLogClass.processException(objException);
        }
    }

    /**
     * @description This method is used to capture deal owner when SDR assign lead to retailer.
     * @author Megha Sunhare
     * @param lstLeads List of newly updated Leads
     * @param mapOldLeads Map of old values of Leads before updation
     */
    public static void assignDealOwnerForRetailerLeads(List<Lead> lstLeads, Map<Id, Lead> mapOldLeads){
        
        Set<Id> setOwnerIds = new Set<Id>();
        Map<Id, User> mapUserIdAndUser = new Map<Id, User>();
        //Loop though the lead list to get all owner ids
        for(Lead objLead : lstLeads){
            setOwnerIds.add(objLead.OwnerId);
        }
        
        try{   
            //Create user id vs profile name map
            mapUserIdAndUser = new Map<Id, User>([SELECT Id, Profile.Name, IsPortalEnabled FROM User WHERE Id IN :setOwnerIds]);
            
            for(Lead objLead : lstLeads){  
                //check if lead owner is changed and it is changed to retailer user and if the deal owner is not equal to null
                if(mapUserIdAndUser!=null){
                    PMC_LeadTriggerHelperExtensionEnhancer.checkLeadOwnerChangeAndDealOwnerAssignment(objLead, mapOldLeads, mapUserIdAndUser.get(objLead.OwnerId));
                }
                
            }
            
        }catch (Exception objException){
            PMC_ErrorLogClass.processException(objException);
        }
    }
    
    /**
     * @description This method is to check if lead owner is change and if deal owner is present.
     * @author Megha Sunhare
     * @param objLead newly updated lead object
     * @param mapOldLeads Map of old values of Leads before updation
     * @param objLeadOwnerUser current lead owner's user record
     */
    public static void checkLeadOwnerChangeAndDealOwnerAssignment(Lead objLead, Map<Id, Lead> mapOldLeads, User objLeadOwnerUser){
        
        if(objLead.OwnerId != mapOldLeads.get(objLead.Id).OwnerId && (objLeadOwnerUser.Profile.Name == PMC_SS_ConstantClass.DH_BUYER_PROFILE_NAME || 
               objLeadOwnerUser.Profile.Name == PMC_SS_ConstantClass.DH_SUPER_BUYER_PROFILE_NAME) && String.isBlank(objLead.PMC_DH_DealOwner__c)){
            //Assign old owner id to deal owner owner id
            objLead.PMC_DH_DealOwner__c = mapOldLeads.get(objLead.Id).OwnerId;
        }
        if( objLead.OwnerId != mapOldLeads.get(objLead.Id).OwnerId && !objLeadOwnerUser.IsPortalEnabled && String.isNotBlank(objLead.PMC_DH_DealOwner__c)){
            //Set Deal owner to null when lead owner is reassigned to internal salesforce user
            objLead.PMC_DH_DealOwner__c = NULL;
        }
    }
    
    /**
     * @description This method is used to add SDR User to account & opportunity teams after lead conversion.
     * @author Kailas Shimpi
     * @param lstUpdatedLeads List of newly updated Leads
     * @param mapOldLeads Map of old values of Leads before updation
     */
    public static void addSDRToAccAndOppTeamsAfterLeadConversion(List<Lead> lstUpdatedLeads, Map<Id,Lead> mapOldLeads) {
        Map<ID,String> mapOwnerIDs = new Map<ID,String>();
        Map<ID,String> mapDealOwnerIDs = new Map<ID,String>();
        
        Map<ID,User> mapOwnerIDsWithProfileName;
        Map<ID,User> mapOwnerIDsWithRoleName;
        
        Map<Id,Id> mapConvertedAccIdWithDealOwner = new Map<Id,Id>();
        Map<Id,Id> mapConvertedOppIdWithDealOwner = new Map<Id,Id>();
        
        for(Lead objLead: lstUpdatedLeads) {
            mapOwnerIDs.put(objLead.OwnerId,'');
            mapDealOwnerIDs.put(objLead.PMC_DH_DealOwner__c,'');
        }
        
        mapOwnerIDsWithProfileName = new Map<ID,User>([SELECT Id,Profile.Name FROM User WHERE Id IN : mapOwnerIDs.keySet() WITH SYSTEM_MODE]);
        mapOwnerIDsWithRoleName = new Map<ID,User>([SELECT Id,UserRole.Name FROM User WHERE Id IN : mapDealOwnerIDs.keySet() WITH SYSTEM_MODE]);
        
        
        for(Lead objLead : lstUpdatedLeads) {
            if(objLead.isConverted && String.isNotBlank(objLead.PMC_DH_DealOwner__c) &&
               checkLeadOwnerDHBuyerOrDHSuperBuyer(objLead,mapOwnerIDsWithProfileName) &&
               checkDealOwnerRoleName(objLead,mapOwnerIDsWithRoleName)) {
                   mapConvertedAccIdWithDealOwner.put(objLead.ConvertedAccountId,objLead.PMC_DH_DealOwner__c);
                   mapConvertedOppIdWithDealOwner.put(objLead.ConvertedOpportunityId,objLead.PMC_DH_DealOwner__c);
               }
        }
        if(!mapConvertedAccIdWithDealOwner.isEmpty()) {
            PMC_SS_CreateTeamMemberController.createAccountTeamMember(mapConvertedAccIdWithDealOwner);
        }
        if(!mapConvertedOppIdWithDealOwner.isEmpty()) {
            PMC_SS_CreateTeamMemberController.createOpportunityTeamMember(mapConvertedOppIdWithDealOwner);
        }
    }
    
    /**
     * @description This method is used to check if Lead's Owner is DH Buyer or DH Super Buyer user.
     * @author Kailas Shimpi
     * @param objLead Lead Record
     * @param mapOwnerIDsWithProfileName Map of owner id with profile name
     * @return boolIsLeadOwnerDHBuyerOrDHSuperBuyer Returns true if Lead's Owner is DH Buyer or DH Super Buyer user.
     */
    public static Boolean checkLeadOwnerDHBuyerOrDHSuperBuyer(Lead objLead, Map<ID,User> mapOwnerIDsWithProfileName) {
        Boolean boolIsLeadOwnerDHBuyerOrDHSuperBuyer = false;
        
        if((mapOwnerIDsWithProfileName.get(objLead.OwnerId).Profile.Name == PMC_SS_ConstantClass.DH_BUYER_PROFILE_NAME || mapOwnerIDsWithProfileName.get(objLead.OwnerId).Profile.Name == PMC_SS_ConstantClass.DH_SUPER_BUYER_PROFILE_NAME)) {
            boolIsLeadOwnerDHBuyerOrDHSuperBuyer = true;
        }
        return boolIsLeadOwnerDHBuyerOrDHSuperBuyer;
    }
    
    /**
     * @description This method is used to check if Lead's Deal Owner is SDR user or not.
     * @author Kailas Shimpi
     * @param objLead Lead Record
     * @param mapOwnerIDsWithRoleName Map of owner id with user role name
     * @return boolIsDealOwnerSDRUser Returns true if Lead's Deal Owner is SDR user.
     */
    public static Boolean checkDealOwnerRoleName(Lead objLead, Map<ID,User> mapOwnerIDsWithRoleName) {
        Boolean boolIsDealOwnerSDRUser = false;
        
        if((mapOwnerIDsWithRoleName.get(objLead.PMC_DH_DealOwner__c).UserRole.Name == PMC_SS_ConstantClass.SDR_NA_SALES_TEAM_ROLE || mapOwnerIDsWithRoleName.get(objLead.PMC_DH_DealOwner__c).UserRole.Name == PMC_SS_ConstantClass.SDR_SA_B2B_SALES_TEAM_ROLE || mapOwnerIDsWithRoleName.get(objLead.PMC_DH_DealOwner__c).UserRole.Name == PMC_SS_ConstantClass.SDR_SA_B2C_SALES_TEAM_ROLE)) {
            boolIsDealOwnerSDRUser = true;
        }
        return boolIsDealOwnerSDRUser;
    }
}