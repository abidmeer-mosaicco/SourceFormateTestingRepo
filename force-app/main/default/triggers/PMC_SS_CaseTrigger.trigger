/**
 * @description This trigger is created on Case object.
 * @author Sayali Shinde
 * @storynumber GDASF-1941
 */

trigger PMC_SS_CaseTrigger on Case (before insert, before update) {
    new PMC_CaseTriggerHandler().run();
}