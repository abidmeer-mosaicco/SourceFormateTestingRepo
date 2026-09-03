trigger OpportunityTrigger on Opportunity (after insert) {

    if (Trigger.isAfter && Trigger.isInsert) {
        UserLookupControllerOppTeams.applyDefaultOppTeamOnInsert(
            Trigger.newMap.keySet()
        );
    }
}