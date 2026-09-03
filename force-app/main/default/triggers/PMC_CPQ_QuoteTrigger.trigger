/**
 * @description This trigger is created on Quote (SBQQ__Quote__c) object.
 * @author Lalit Sharma
 * @storynumber GDASF-2588
 */
trigger PMC_CPQ_QuoteTrigger on SBQQ__Quote__c (before insert, before update, before delete,
                                                after insert, after update, after delete, after undelete) {
  new PMC_CPQ_QuoteTriggerHandler().run();
}