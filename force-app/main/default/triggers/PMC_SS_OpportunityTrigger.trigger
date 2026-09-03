/**
 * @description This trigger is created on Opportunity object.
 * @author Nandini Dey
 * @storynumber GDASF-2588
 */
trigger PMC_SS_OpportunityTrigger on Opportunity (before insert, before update, before delete,
                                                after insert, after update, after delete, after undelete) {
	new PMC_OpportunityTriggerHandler().run();
}