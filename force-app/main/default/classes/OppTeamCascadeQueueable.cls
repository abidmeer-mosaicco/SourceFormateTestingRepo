public class OppTeamCascadeQueueable implements Queueable {

    private Set<Id> oppIds;
    private Map<Id, String> userToLevel;

    public OppTeamCascadeQueueable(Set<Id> oppIds, Map<Id, String> userToLevel) {
        this.oppIds = oppIds;
        this.userToLevel = userToLevel;
    }

    /*public void execute(QueueableContext qc) {

       
        SBQQ__Quote__c.SObjectType.getDescribe();
        SBQQ__Quote__Share.SObjectType.getDescribe();

      
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity o : [
            SELECT AccountId
            FROM Opportunity
            WHERE Id IN :oppIds AND AccountId != null
        ]) {
            accountIds.add(o.AccountId);
        }

      
        Map<Id, List<SBQQ__Quote__c>> oppToQuotes = new Map<Id, List<SBQQ__Quote__c>>();

        for (SBQQ__Quote__c q : [
            SELECT Id, SBQQ__Opportunity2__c
            FROM SBQQ__Quote__c
            WHERE SBQQ__Opportunity2__c IN :oppIds
        ]) {
            Id oppId = q.SBQQ__Opportunity2__c;

            // FIXED: Apex does NOT have putIfAbsent
            if (!oppToQuotes.containsKey(oppId)) {
                oppToQuotes.put(oppId, new List<SBQQ__Quote__c>());
            }

            oppToQuotes.get(oppId).add(q);
        }

        // Loop by user
        for (Id userId : userToLevel.keySet()) {

            String lvl = userToLevel.get(userId);

            // 1) OTM
          //  OppTeamReplicationService.upsertOppTeam(oppIds, userId, lvl);
           
            // 2) OpportunityShare
          //  OppTeamReplicationService.deleteOppManualShare(oppIds, userId);
           // OppTeamReplicationService.upsertOppManualShare(oppIds, userId, lvl);

            // 3) CPQ-compliant Quote Shares
         
            

            // 4) Account Shares
            if (!accountIds.isEmpty()) {
                OppTeamReplicationService.deleteAccountShare(accountIds, userId);
                OppTeamReplicationService.upsertAccountShare(accountIds, userId, lvl);
            }
        }
    }*/
    public void execute(QueueableContext qc) {

    SBQQ__Quote__c.SObjectType.getDescribe();
    SBQQ__Quote__Share.SObjectType.getDescribe();

    Set<Id> accountIds = new Set<Id>();
    for (Opportunity o : [
        SELECT AccountId
        FROM Opportunity
        WHERE Id IN :oppIds AND AccountId != null
    ]) {
        accountIds.add(o.AccountId);
    }

    // 1️⃣ Opportunity Team (ONLY source of opp access)
    for (Id userId : userToLevel.keySet()) {
        OppTeamReplicationService.upsertOppTeam(
            oppIds,
            userId,
            userToLevel.get(userId)
        );
    }

    // 2️⃣ 💥 KILL duplicate OpportunityShares
    OppTeamReplicationService.deleteManualOppShareForTeamUsers(
        oppIds,
        userToLevel.keySet()
    );

    // 3️⃣ Account shares (bulk, once)
    if (!accountIds.isEmpty()) {
        OppTeamReplicationService.bulkUpsertAccountShare(
            accountIds,
            userToLevel
        );
    }

    
for (Id oppId : oppIds) {
    OppTeamReplicationService.topUpEligibleQuoteSharesForAnchor(oppId);
}

}
}