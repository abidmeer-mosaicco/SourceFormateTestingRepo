public without sharing class OppTeamReplicationJob implements Queueable {

    private List<OppTeamReplicationService.Change> changes;

    public OppTeamReplicationJob(List<OppTeamReplicationService.Change> changes) {
        this.changes = changes;
    }

    public void execute(QueueableContext qc) {

        if (changes == null || changes.isEmpty()) return;

        Map<String, OppTeamReplicationService.Change> uniq = new Map<String, OppTeamReplicationService.Change>();
        for (OppTeamReplicationService.Change c : changes) {
            if (c == null) continue;
            String key = String.valueOf(c.anchorOpportunityId) + '|' + String.valueOf(c.memberUserId);
            uniq.put(key, c);
        }

 
        Set<Id> anchorOppIds = new Set<Id>();
        for (OppTeamReplicationService.Change c : uniq.values()) {
            if (c.anchorOpportunityId != null) anchorOppIds.add(c.anchorOpportunityId);
        }
        if (anchorOppIds.isEmpty()) return;

        // Resolve owner for replication scope
     /*  Id sampleOpp = anchorOppIds.iterator().next();
        Id ownerId = [
            SELECT OwnerId
            FROM Opportunity
            WHERE Id = :sampleOpp
            LIMIT 1
        ].OwnerId;

     
        OppTeamReplicationService.Targets t =
            OppTeamReplicationService.findTargetsForOwner(ownerId);

            System.debug('ANCHOR OPP IDS = ' + anchorOppIds);

System.debug('OWNER ID = ' + ownerId);

System.debug('ALL OPP IDS = ' + t.opportunityIds);

        Set<Id> allOppIds  = t.opportunityIds;
        Set<Id> allAcctIds = t.accountIds;*/
        Id sampleOpp = anchorOppIds.iterator().next();

Id ownerId = [
    SELECT OwnerId
    FROM Opportunity
    WHERE Id = :sampleOpp
    LIMIT 1
].OwnerId;

// OWNER CHANGE = USE ONLY ANCHOR OPP
Set<Id> allOppIds = new Set<Id>(anchorOppIds);

Set<Id> allAcctIds = new Set<Id>();

for (Opportunity opp : [
    SELECT Id, AccountId
    FROM Opportunity
    WHERE Id IN :allOppIds
]) {
    if (opp.AccountId != null) {
        allAcctIds.add(opp.AccountId);
    }
}

        // ---------------------------------------------------------
        // 4. Build user -> level map (UPSERT only)
        // ---------------------------------------------------------
        Map<Id, String> allUsersToLevels = new Map<Id, String>();
        for (OppTeamReplicationService.Change c : uniq.values()) {
            if (c == null) continue;
            if (String.isNotBlank(c.accessLevel)) {
                allUsersToLevels.put(c.memberUserId, c.accessLevel);
            }
        }

   
        Set<Id> usersToDelete = new Set<Id>(); // must always remain empty

     

        // --- AccountShare (Manual) ---
        OppTeamReplicationService.bulkUpsertAccountShare(
            allAcctIds,
            allUsersToLevels
        );
        // Remove users that are not part of the current owner's team

Boolean ownerChange = false;
for (OppTeamReplicationService.Change c : uniq.values()) {
    if (c != null && c.isOwnerChange == true) {
        ownerChange = true;
        break;
    }
}

// ONLY FOR OWNER CHANGE
if (ownerChange) {

    List<OpportunityTeamMember> existingOtms = [
        SELECT Id
        FROM OpportunityTeamMember
        WHERE OpportunityId IN :allOppIds
    ];

    if (!existingOtms.isEmpty()) {
        Database.delete(existingOtms, false);
    }
}
// Rebuild expected team
OppTeamReplicationService.restoreLostOTM(
    allOppIds,
    allUsersToLevels.keySet(),
    allUsersToLevels
);
     //   OppTeamReplicationService.restoreLostOTM(allOppIds, allUsersToLevels.keySet(), allUsersToLevels);
      OppTeamReplicationService.deleteManualOppShareForTeamUsers(
    allOppIds,
    allUsersToLevels.keySet()
);
OppTeamReplicationService.bulkUpsertQuoteShares(
    allOppIds,
    allUsersToLevels
);
  /* 
if (!Test.isRunningTest() && !System.isBatch()) {

    System.enqueueJob(new OppTeamBatchLauncher(ownerId));

}*/


if (!ownerChange &&
    !Test.isRunningTest() &&
    !System.isBatch()) {

    System.enqueueJob(new OppTeamBatchLauncher(ownerId));

}

}
}