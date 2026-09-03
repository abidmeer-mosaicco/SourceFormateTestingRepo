public without sharing class QuoteAccountShareCascade {
   
    public static void syncForOpp(Id opportunityId, Map<Id, String> userToLevel) {
        if (opportunityId == null || userToLevel == null || userToLevel.isEmpty()) return;

        // Opp & Account
        Id acctId = [
            SELECT AccountId
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ].AccountId;

        Set<Id> oppSet  = new Set<Id>{ opportunityId };
        Set<Id> acctSet = (acctId != null) ? new Set<Id>{ acctId } : new Set<Id>();

        // Apply per user
        for (Id uid : userToLevel.keySet()) {
            String lvl = normalize(userToLevel.get(uid));
            // Opportunity manual share
            OppTeamReplicationService.upsertOppManualShare(oppSet, uid, lvl);
            // Eligible CPQ quotes under this opportunity
            OppTeamReplicationService.upsertEligibleQuoteSharesForOpp(opportunityId, uid, lvl);
            // Account manual share
            if (!acctSet.isEmpty()) {
                OppTeamReplicationService.upsertAccountShare(acctSet, uid, lvl);
            }
        }
    }


    public static void syncForOpps(Set<Id> oppIds, Map<Id, String> userToLevel) {
        if (oppIds == null || oppIds.isEmpty() || userToLevel == null || userToLevel.isEmpty()) return;

        // 1) Accounts for these opps
        Map<Id, Id> oppToAcct = new Map<Id, Id>();
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity o : [
            SELECT Id, AccountId
            FROM Opportunity
            WHERE Id IN :oppIds
        ]) {
            oppToAcct.put(o.Id, o.AccountId);
            if (o.AccountId != null) accountIds.add(o.AccountId);
        }

        // 2) Quotes under these opps (we’ll still rely on OppTeamReplicationService to filter ineligible by PMC)
        Set<Id> quoteIds = new Set<Id>();
        for (SBQQ__Quote__c q : [
            SELECT Id, SBQQ__Opportunity2__c
            FROM SBQQ__Quote__c
            WHERE SBQQ__Opportunity2__c IN :oppIds
        ]) {
            quoteIds.add(q.Id);
        }

        // 3) Normalize user levels up-front
        Map<Id, String> normalized = new Map<Id, String>();
        for (Id uid : userToLevel.keySet()) normalized.put(uid, normalize(userToLevel.get(uid)));

        // 4) Apply
        for (Id uid : normalized.keySet()) {
            String lvl = normalized.get(uid);

            // Opp shares (Manual) across all opps
            OppTeamReplicationService.upsertOppManualShare(oppIds, uid, lvl);

            // Account shares (Manual)
            if (!accountIds.isEmpty()) {
                OppTeamReplicationService.upsertAccountShare(accountIds, uid, lvl);
            }

            // Quote shares (Manual) across all quotes
            if (!quoteIds.isEmpty()) {
                OppTeamReplicationService.upsertQuoteShare(quoteIds, uid, lvl);
            }
        }
    }

    public static void deleteForOpp(Id opportunityId, Set<Id> memberUserIds) {
        if (opportunityId == null || memberUserIds == null || memberUserIds.isEmpty()) return;

        // Account for this opp
        Id acctId = [
            SELECT AccountId
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ].AccountId;

        Set<Id> acctSet = (acctId != null) ? new Set<Id>{ acctId } : new Set<Id>();

        // Quotes under this opp
        Set<Id> quoteIds = new Set<Id>();
        for (SBQQ__Quote__c q : [
            SELECT Id
            FROM SBQQ__Quote__c
            WHERE SBQQ__Opportunity2__c = :opportunityId
        ]) {
            quoteIds.add(q.Id);
        }

        // Delete for each user
        for (Id uid : memberUserIds) {
            if (!quoteIds.isEmpty()) OppTeamReplicationService.deleteQuoteShare(quoteIds, uid);
            if (!acctSet.isEmpty())  OppTeamReplicationService.deleteAccountShare(acctSet, uid);
        }
    }


    public static void deleteForOpps(Set<Id> oppIds, Set<Id> memberUserIds) {
        if (oppIds == null || oppIds.isEmpty() || memberUserIds == null || memberUserIds.isEmpty()) return;

        // Accounts for these opps
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity o : [
            SELECT Id, AccountId
            FROM Opportunity
            WHERE Id IN :oppIds
        ]) {
            if (o.AccountId != null) accountIds.add(o.AccountId);
        }


        Set<Id> quoteIds = new Set<Id>();
        for (SBQQ__Quote__c q : [
            SELECT Id
            FROM SBQQ__Quote__c
            WHERE SBQQ__Opportunity2__c IN :oppIds
        ]) {
            quoteIds.add(q.Id);
        }

        for (Id uid : memberUserIds) {
            if (!quoteIds.isEmpty()) OppTeamReplicationService.deleteQuoteShare(quoteIds, uid);
            if (!accountIds.isEmpty()) OppTeamReplicationService.deleteAccountShare(accountIds, uid);
        }
    }

  
    private static String normalize(String v) {
        if (String.isBlank(v)) return 'Read';
        String s = v.trim();
        if (s == 'Edit' || s == 'Read/Write') return 'Edit';
        return 'Read';
    }
}