/**
 * @description This trigger is to Create Preferece Records for the User
 * @author Sugunakar Routhu
 * @storynumber 
 */
public with sharing class PMC_DH_UserTriggerHandler extends PMC_TriggerHandler {
    
     public final static List<String> DIGITAL_HUB_PROFILES=new List<String>{'Digital Hub Super Buyer','Digital Hub Buyer','Digital Hub Contract Manager','Digital Hub Finance Manager','Digital Hub Logistics Manager','Digital Hub Knowledge Only User'};
     private final static string NOTIFICATIOIN_PREFERENCE_BATCH_SIZE='Notification_Preference_Batch_Size';
    /**
     * These boolean variables are used to bypass the trigger operations
     */
    private static final Boolean BOOL_BYPASS_BEFORE_INSERT;
    private static final Boolean BOOL_BYPASS_BEFORE_UPDATE;
    private static final Boolean BOOL_BYPASS_BEFORE_DELETE;
    private static final Boolean BOOL_BYPASS_AFTER_INSERT;
    private static final Boolean BOOL_BYPASS_AFTER_UPDATE;
    private static final Boolean BOOL_BYPASS_AFTER_DELETE;
    private static final Boolean BOOL_BYPASS_AFTER_UNDELETE;
    
    
    /**
    * These boolean variables are used to bypass the trigger operations
    */
    @testVisible
    public static Boolean boolBypassTriggerLogic = false;
    
    /**
     * These variables will hold the copy of trigger variables
     */
    private List<User> lstNewUsers;
    private Map<Id,User> mapNewUsers;
    private List<User> lstOldUsers;
    private Map<Id,User> mapOldUsers;
    
    /**
     * @description This static block initializes the trigger switches when the class is invoked
     */
    static{
        
        PMC_TriggerSwitches__mdt operationSwitches = PMC_TriggerSwitches__mdt.getInstance('User');
        
        BOOL_BYPASS_BEFORE_INSERT = operationSwitches.PMC_BeforeInsert__c;
        BOOL_BYPASS_BEFORE_UPDATE = operationSwitches.PMC_BeforeUpdate__c;
        BOOL_BYPASS_BEFORE_DELETE = operationSwitches.PMC_BeforeDelete__c;
        BOOL_BYPASS_AFTER_INSERT = operationSwitches.PMC_AfterInsert__c;
        BOOL_BYPASS_AFTER_UPDATE = operationSwitches.PMC_AfterUpdate__c;
        BOOL_BYPASS_AFTER_DELETE = operationSwitches.PMC_AfterDelete__c;
        BOOL_BYPASS_AFTER_UNDELETE = operationSwitches.PMC_AfterUndelete__c;

    }
    
    /**
    * @description This constructor will initiate data when the class is invoked
    */
    public PMC_DH_UserTriggerHandler() {
        //Instantiating local class variables from trigger variables
        this.lstNewUsers = Trigger.new;
        this.mapNewUsers = (Map<Id,User>) Trigger.newMap;
        this.lstOldUsers = Trigger.old;
        this.mapOldUsers = (Map<Id, User>) Trigger.oldMap;
        //Set the maximum calls allowed for the class
        this.setMaxLoopCount(16);
    }
    /**
     * @description This method will perform the operation for after insert trigger
     */
    public override void afterInsert(){
        if( BOOL_BYPASS_AFTER_INSERT && boolBypassTriggerLogic){
            return;
        }
        
        List<String> lstUserIds = new List<String>();
        Map<Id,String> mapUserIdProfileName = new Map<Id,String>();
        for(User objUser : [SELECT Id,Name,Profile.Name FROM User Where Id IN : lstNewUsers AND ContactId!=NULL AND Profile.Name IN : DIGITAL_HUB_PROFILES WITH SYSTEM_MODE]){
            lstUserIds.add(objUser.Id);
            mapUserIdProfileName.put(objUser.Id,objUser.Profile.Name);
        }
        if(!lstUserIds.isEmpty()){
            PMC_DH_Store_Configuration__mdt config = PMC_DH_Store_Configuration__mdt.getInstance(NOTIFICATIOIN_PREFERENCE_BATCH_SIZE);
            
            if(!Test.isRunningTest()){
                assignPermissionsToUser(lstUserIds, mapUserIdProfileName);
            }
            if(lstUserIds.size() <= config.PMC_DH_Batch_Size__c){
               System.enqueueJob(new PMC_DH_NotificatonQueueable(lstUserIds));
            }
            if(!System.isFuture()){
                 Database.executeBatch(new PMC_DH_DelegatedAccountAccessBatch());
            }
        }
    }

/*************************************************************************
* @method Name   : assignPermissionsToUser
* @description   : to Assign the Permission Set the User and Create Notification Data
* @param       lstUserIds
* @param       mapUserIdProfileName 
*****************************************************************************/
    
    @Future
    public static void assignPermissionsToUser(List<String> lstUserIds, Map<Id,String> mapUserIdProfileName){
        
        Map<String, String> mapProfilePermissionGroupDeveloperName = new Map<String, String> ();
        Map<String, Id> mapPermissionSetGroupDevelopNameId = new Map<String, Id>();
        PMC_DH_PersonaPermissionSetGroup__mdt[] lstPersonaPermissionSetGroup = PMC_DH_PersonaPermissionSetGroup__mdt.getAll().values();
        for(PMC_DH_PersonaPermissionSetGroup__mdt objPersonaPermissionSetGroup : lstPersonaPermissionSetGroup){
            mapProfilePermissionGroupDeveloperName.put(objPersonaPermissionSetGroup.strProfile__c,objPersonaPermissionSetGroup.strPermissionSetGroup__c);
        }
        
        for (PermissionSetGroup permsGrp :  [SELECT Id, Status, DeveloperName FROM PermissionSetGroup WHERE DeveloperName IN : mapProfilePermissionGroupDeveloperName.values() WITH SYSTEM_MODE]){
            
            if(permsGrp.Status!=PMC_DH_ConstantClass.UPDATED)
            {
                Test.calculatePermissionSetGroup(permsGrp.Id);
            }
            mapPermissionSetGroupDevelopNameId.put(permsGrp.DeveloperName, permsGrp.Id);
        }
        
        List<PermissionSetAssignment> lstPermissionSet= new List<PermissionSetAssignment>();
             for(Id userId : mapUserIdProfileName.KeySet()){
                 String userProfileName = mapUserIdProfileName.get(userId);
                 if(mapProfilePermissionGroupDeveloperName.ContainsKey(userProfileName)){
                     String permissionSetdeveloperName = mapProfilePermissionGroupDeveloperName.get(userProfileName);
                     if(mapPermissionSetGroupDevelopNameId.ContainsKey(permissionSetdeveloperName)){
                         PermissionSetAssignment objPermissionSetAss = new PermissionSetAssignment(  PermissionSetGroupId = mapPermissionSetGroupDevelopNameId.get(permissionSetdeveloperName), AssigneeId = userId);
                         lstPermissionSet.add(objPermissionSetAss);
                     }
                 }
                 
             }
        if(!lstPermissionSet.isEmpty()){
            insert as system lstPermissionSet;
        }
    }
    
    
}