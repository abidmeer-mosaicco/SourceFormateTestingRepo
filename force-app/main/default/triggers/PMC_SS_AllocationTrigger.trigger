/**
 * @description This trigger is created on PMC_SS_Allocation__c object.
 * @author Aravind Chaganti
 * @storynumber GDASF-17000
 */

trigger PMC_SS_AllocationTrigger on PMC_SS_Allocation__c (before insert,
                                                before update, before delete, after insert, after update, 
                                                after delete, after undelete) {                                             
    new PMC_SS_AllocationTriggerHandler().run();
}