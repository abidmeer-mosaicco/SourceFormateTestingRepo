/**
 * @description This trigger is created on PMC_SS_AccountSalesAreaRelationship__c object.
 * @author Megha Sunhare
 * @storynumber GDASF-1065
 */

trigger PMC_AccountSalesAreaRelationshipTrigger on PMC_SS_AccountSalesAreaRelationship__c (before insert,
                                                before update, before delete, after insert, after update, 
                                                after delete, after undelete) {
    // Checking if the trigger operation is bypassed                                                
    new PMC_AccountSalesAreaRelTriggerHandler().run();
}