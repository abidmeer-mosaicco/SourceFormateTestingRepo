/**
 * @description This trigger is created on Lead object.
 * @author Megha Sunhare
 * @storynumber GDASF-6734
 */
trigger PMC_LeadTrigger on Lead (before insert, before update, before delete,
                                after insert, after update, after delete, after undelete) {
    new PMC_LeadTriggerHandler().run();
}