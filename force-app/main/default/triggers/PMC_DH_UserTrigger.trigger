/**
 * @description This trigger is to Create Preferece Records for the User
 * @author Sugunakar Routhu
 * @storynumber 
 */
trigger PMC_DH_UserTrigger on User (After Insert) {
  new PMC_DH_UserTriggerHandler().run();
}