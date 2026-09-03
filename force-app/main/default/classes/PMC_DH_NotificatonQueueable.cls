/**
* @description : queueable class for notification preference
* @author      : Sugunakar
* @userStory   : GDASF-11860
* @last modified on 
* @last modified by 
**/
public without sharing class PMC_DH_NotificatonQueueable implements Queueable {  
/**
* @description NotificatonQueueable
* @param lstUserIds
*/    
    public List<String> lstUserIds;
    public PMC_DH_NotificatonQueueable(List<String> lstUserIds){
        this.lstUserIds=lstUserIds;
    }
/**
* @description execute method
* @param qc
*/
    /*public void execute(QueueableContext qc){ 
        for(String userRecordId : lstUserIds){
            PMC_DH_NotificationPreferenceController.createNotificationPref(userRecordId);
        }
    }*/

/**
* @description Added for the recursion check - Prashanth Kamma - 08/05/2025
*/
    public void execute(QueueableContext qc){ 
    	PMC_SS_TriggerRecursionGuard.markProcessed('Contact_afterUpdate'); // 🛑 Defensive protection
    	for(String userRecordId : lstUserIds){
        	PMC_DH_NotificationPreferenceController.createNotificationPref(userRecordId);
        }
    }
}