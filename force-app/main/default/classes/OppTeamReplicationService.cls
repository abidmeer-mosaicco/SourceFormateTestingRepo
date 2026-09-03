public without sharing class OppTeamReplicationService {


    public static Boolean isReplicating = false;

    public class Change {
        public Id anchorOpportunityId;
        public Id memberUserId;
        public String accessLevel; // 'Read' | 'Edit'
        public String action;      // 'UPSERT' | 'DELETE'
        public Boolean isOwnerChange = false;

        
        public Change(Id oppId, Id userId, String level, String action) {
            this.anchorOpportunityId = oppId;
            this.memberUserId = userId;
            this.accessLevel = OppTeamReplicationGate.normalizeAccess(level);
            this.action = (action == null ? null : action.trim().toUpperCase());
        }
    }

    public class Targets {
        public Set<Id> opportunityIds = new Set<Id>();
        public Set<Id> accountIds     = new Set<Id>();
        public Set<Id> quoteIds       = new Set<Id>();
    }

    // ------------ Helpers ------------
public static String normalizeLevel(String level) {

    
    if (String.isBlank(level)) return 'Read';

    // Try Gate normalization safely
    String lvl;
    try {
        lvl = OppTeamReplicationGate.normalizeAccess(level);
    } catch (Exception e) {
        lvl = null;
    }

    if (String.isBlank(lvl)) return 'Read';

    if (lvl == 'Edit') return 'Edit';

    return 'Read';
}
  
    private static Set<Id> filterOutIneligibleExpiredByPMC(Set<Id> quoteIds) {
        if (quoteIds == null || quoteIds.isEmpty()) return new Set<Id>();
        final Date cutoff = Date.today().addDays(-180);

        Set<Id> allowed = new Set<Id>(quoteIds);

        for (SBQQ__Quote__c q : [
            SELECT Id
            FROM SBQQ__Quote__c
            WHERE Id IN :quoteIds
              AND SBQQ__Status__c = 'Expired'
              AND (PMC_CPQ_ExpirationDate__c = null OR PMC_CPQ_ExpirationDate__c < :cutoff)
        ]) {
            allowed.remove(q.Id);
        }
        return allowed;
    }

public static Targets findTargets(Id anchorOppId) {
    Targets t = new Targets();
    if (anchorOppId == null) return t;

    Opportunity anchor = [
        SELECT Id, OwnerId, AccountId
        FROM Opportunity
        WHERE Id = :anchorOppId
        LIMIT 1
    ];

    // ONLY SYNC THIS OPPORTUNITY
    t.opportunityIds.add(anchorOppId);

    // Add anchor’s account only
    if (anchor.AccountId != null) {
        t.accountIds.add(anchor.AccountId);
    }

    // Quotes for ONLY this Opportunity
    for (SBQQ__Quote__c q : [
        SELECT Id
        FROM SBQQ__Quote__c
        WHERE SBQQ__Opportunity2__c = :anchorOppId
    ]) {
        t.quoteIds.add(q.Id);
    }

    return t;
}

   
    public static Targets findAnchorOnlyTargets(Id anchorOppId) {
        Targets t = new Targets();
        if (anchorOppId == null) return t;

        Opportunity o = [
            SELECT Id, AccountId
            FROM Opportunity
            WHERE Id = :anchorOppId
            LIMIT 1
        ];
        t.opportunityIds.add(o.Id);
        if (o.AccountId != null) t.accountIds.add(o.AccountId);

        for (SBQQ__Quote__c q : [
            SELECT Id
            FROM SBQQ__Quote__c
            WHERE SBQQ__Opportunity2__c = :anchorOppId
        ]) {
            t.quoteIds.add(q.Id);
        }
        return t;
    }

    // ------------ Delete wrappers (anchor-only vs same-owner) ------------
  
public static void deleteForAnchorOnly(Id anchorOppId, Id userId) {
    Targets t = findAnchorOnlyTargets(anchorOppId);

    // NEW: remove Manual Opp share(s) first
    deleteOppManualShare(t.opportunityIds, userId);

    deleteOppTeam(t.opportunityIds, userId);
    deleteQuoteShare(t.quoteIds, userId);
    deleteAccountShare(t.accountIds, userId);
}

public static Targets findTargetsForOwner(Id ownerId) {
    Targets t = new Targets();
    if (ownerId == null) return t;

    List<Opportunity> opps = [
        SELECT Id, AccountId
        FROM Opportunity
        WHERE OwnerId = :ownerId AND CreatedDate >= :Date.today().addDays(-180)
    ];
    for (Opportunity o : opps) {
        t.opportunityIds.add(o.Id);
        if (o.AccountId != null) t.accountIds.add(o.AccountId);
    }

    // 1 SOQL — ALL quotes
    if (!t.opportunityIds.isEmpty()) {
        for (SBQQ__Quote__c q : [
            SELECT Id
            FROM SBQQ__Quote__c
            WHERE SBQQ__Opportunity2__c IN :t.opportunityIds
        ]) {
            t.quoteIds.add(q.Id);
        }
    }

    return t;
}
  
public static void deleteForSameOwner(Id anchorOppId, Id userId) {
    Targets t = findTargets(anchorOppId);

    // NEW: remove Manual Opp share(s) first
    deleteOppManualShare(t.opportunityIds, userId);

    deleteOppTeam(t.opportunityIds, userId);
    deleteQuoteShare(t.quoteIds, userId);
    deleteAccountShare(t.accountIds, userId);
}

public static void bootstrapOppTeamFromNewOwner(Set<Id> oppIds) {
    if (oppIds == null || oppIds.isEmpty()) return;

    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
        SELECT Id, OwnerId, AccountId
        FROM Opportunity
        WHERE Id IN :oppIds
    ]);
    if (oppMap.isEmpty()) return;

    // collect owners
    Set<Id> ownerIds = new Set<Id>();
    for (Opportunity o : oppMap.values()) {
        if (o.OwnerId != null) ownerIds.add(o.OwnerId);
    }
    if (ownerIds.isEmpty()) return;

    // derive "default team" from any other opp (same owner)
    List<OpportunityTeamMember> seeds = [
        SELECT Id, OpportunityId, UserId, OpportunityAccessLevel, Opportunity.OwnerId
        FROM OpportunityTeamMember
        WHERE Opportunity.OwnerId IN :ownerIds
        AND OpportunityId NOT IN :oppIds
    ];

    Map<Id, Map<Id, String>> ownerToDefaultTeam = new Map<Id, Map<Id, String>>();

    for (OpportunityTeamMember m : seeds) {
        Id ownerId = m.Opportunity.OwnerId;

        if (!ownerToDefaultTeam.containsKey(ownerId)) {
            ownerToDefaultTeam.put(ownerId, new Map<Id, String>());
        }

        Map<Id, String> mapUserToLevel = ownerToDefaultTeam.get(ownerId);

        String lvl = normalizeLevel(m.OpportunityAccessLevel);
        if (String.isBlank(lvl)) lvl = 'Read';


        if (!mapUserToLevel.containsKey(m.UserId) || 'Edit'.equals(lvl)) {
            mapUserToLevel.put(m.UserId, lvl);
        }
    }

    // collect quotes under each opp
    Map<Id, List<Id>> oppToQuoteIds = new Map<Id, List<Id>>();
    for (SBQQ__Quote__c q : [
        SELECT Id, SBQQ__Opportunity2__c
        FROM SBQQ__Quote__c
        WHERE SBQQ__Opportunity2__c IN :oppIds
    ]) {
        List<Id> lst = oppToQuoteIds.get(q.SBQQ__Opportunity2__c);
        if (lst == null) lst = new List<Id>();
        lst.add(q.Id);
        oppToQuoteIds.put(q.SBQQ__Opportunity2__c, lst);
    }

    // apply to each opp
    for (Id oppId : oppIds) {

        Opportunity opp = oppMap.get(oppId);
        if (opp == null) continue;

        Map<Id, String> defaultTeam = ownerToDefaultTeam.get(opp.OwnerId);
        if (defaultTeam == null || defaultTeam.isEmpty()) continue;

        isReplicating = true;
        try {
            // existing team
            Map<Id, OpportunityTeamMember> existing = new Map<Id, OpportunityTeamMember>();
            for (OpportunityTeamMember ex : [
                SELECT Id, UserId, OpportunityAccessLevel
                FROM OpportunityTeamMember
                WHERE OpportunityId = :oppId
            ]) {
                existing.put(ex.UserId, ex);
            }

            List<OpportunityTeamMember> toInsert = new List<OpportunityTeamMember>();
            List<OpportunityTeamMember> toUpdate = new List<OpportunityTeamMember>();

            for (Id userId : defaultTeam.keySet()) {

            
                String lvl = normalizeLevel(defaultTeam.get(userId));
                if (String.isBlank(lvl)) lvl = 'Read';

                OpportunityTeamMember ex = existing.get(userId);

                if (ex == null) {
                    toInsert.add(new OpportunityTeamMember(
                        OpportunityId = oppId,
                        UserId = userId,
                        OpportunityAccessLevel = lvl
                    ));
                } else if (ex.OpportunityAccessLevel != lvl) {
                    ex.OpportunityAccessLevel = lvl;
                    toUpdate.add(ex);
                }
            }

if (!toInsert.isEmpty()) {
    Database.SaveResult[] res = Database.insert(toInsert, false);
    logErrors('Bootstrap OTM insert', res, toInsert);
}

if (!toUpdate.isEmpty()) {
    Database.SaveResult[] res2 = Database.update(toUpdate, false);
    logErrors('Bootstrap OTM update', res2, toUpdate);
}


        } finally {
            isReplicating = false;
        }

        // quotes for this opp
        List<Id> qList = oppToQuoteIds.get(oppId);
        if (qList == null) qList = new List<Id>();

        if (!qList.isEmpty()) {
            Set<Id> qSet = new Set<Id>(qList);

          
            for (Id userId : defaultTeam.keySet()) {
                String lvl = normalizeLevel(defaultTeam.get(userId));
                if (String.isBlank(lvl)) lvl = 'Read';

                upsertQuoteShare(qSet, userId, lvl);
            }
        }

        // accounts for this opp
        if (opp.AccountId != null) {
            Set<Id> acctSet = new Set<Id>{ opp.AccountId };

            for (Id userId : defaultTeam.keySet()) {
                String lvl = normalizeLevel(defaultTeam.get(userId));
                if (String.isBlank(lvl)) lvl = 'Read';

            }
        }
    }
}

    // ------------ OTM operations ------------
    public static void upsertOppTeam(Set<Id> oppIds, Id userId, String level) {
        if (oppIds == null || oppIds.isEmpty() || userId == null) return;

        Map<Id, OpportunityTeamMember> existingByOpp = new Map<Id, OpportunityTeamMember>();
        for (OpportunityTeamMember m : [
            SELECT Id, OpportunityId, UserId, OpportunityAccessLevel
            FROM OpportunityTeamMember
            WHERE OpportunityId IN :oppIds AND UserId = :userId
        ]) {
            existingByOpp.put(m.OpportunityId, m);
        }

        List<OpportunityTeamMember> toInsert = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> toUpdate = new List<OpportunityTeamMember>();

        String lvl = normalizeLevel(level);
        for (Id oppId : oppIds) {
            OpportunityTeamMember ex = existingByOpp.get(oppId);
            if (ex == null) {
                toInsert.add(new OpportunityTeamMember(
                    OpportunityId = oppId,
                    UserId = userId,
                    OpportunityAccessLevel = lvl
                ));
            } else if (ex.OpportunityAccessLevel != lvl) {
                ex.OpportunityAccessLevel = lvl;
                toUpdate.add(ex);
            }
        }

        isReplicating = true;
        try {
           // if (!toInsert.isEmpty()) insert toInsert;
            //if (!toUpdate.isEmpty()) update toUpdate;
            if (!toInsert.isEmpty()) {
    Database.SaveResult[] res = Database.insert(toInsert, false);
    logErrors('OTM insert', res, toInsert);
}

if (!toUpdate.isEmpty()) {
    Database.SaveResult[] res2 = Database.update(toUpdate, false);
    logErrors('OTM update', res2, toUpdate);
}

        } finally {
            isReplicating = false;
        }
    }

public static void bulkUpsertOppManualShare(
    Set<Id> oppIds,
    Map<Id,String> userToLevel
) {
    if (oppIds.isEmpty() || userToLevel.isEmpty()) return;

    Set<String> teamKeys =
        buildTeamKeys(oppIds, userToLevel.keySet());

    Map<String, OpportunityShare> existing = new Map<String, OpportunityShare>();
    for (OpportunityShare s : [
        SELECT Id, OpportunityId, UserOrGroupId, OpportunityAccessLevel
        FROM OpportunityShare
        WHERE OpportunityId IN :oppIds
        AND UserOrGroupId IN :userToLevel.keySet()
        AND RowCause = :Schema.OpportunityShare.RowCause.Manual
    ]) {
        existing.put(s.OpportunityId + '|' + s.UserOrGroupId, s);
    }

    List<OpportunityShare> toInsert = new List<OpportunityShare>();
    List<OpportunityShare> toUpdate = new List<OpportunityShare>();

    for (Id oppId : oppIds) {
        for (Id userId : userToLevel.keySet()) {

            String key = oppId + '|' + userId;

            // ✅ HARD BLOCK: no Manual share for Team users
            if (teamKeys.contains(key)) {
                continue;
            }

            String lvl = normalizeLevel(userToLevel.get(userId));
            OpportunityShare ex = existing.get(key);

            if (ex == null) {
                toInsert.add(new OpportunityShare(
                    OpportunityId          = oppId,
                    UserOrGroupId          = userId,
                    OpportunityAccessLevel = lvl,
                    RowCause               = Schema.OpportunityShare.RowCause.Manual
                ));
            } else if (ex.OpportunityAccessLevel != lvl) {
                ex.OpportunityAccessLevel = lvl;
                toUpdate.add(ex);
            }
        }
    }
if (!toInsert.isEmpty()) {
    Database.insert(toInsert, false);
}
if (!toUpdate.isEmpty()) {
    Database.update(toUpdate, false);
}

}



public static void bulkDeleteOppTeam(Set<Id> oppIds, Set<Id> userIds) {
    if (oppIds == null || oppIds.isEmpty()) return;
    if (userIds == null || userIds.isEmpty()) return;

    List<OpportunityTeamMember> toDelete = [
        SELECT Id
        FROM OpportunityTeamMember
        WHERE OpportunityId IN :oppIds
        AND UserId IN :userIds
    ];

    if (!toDelete.isEmpty()) delete toDelete;
}


public static void bulkUpsertAccountShare(Set<Id> accountIds, Map<Id,String> userToLevel) {
    if (accountIds.isEmpty() || userToLevel.isEmpty()) return;

    Map<String, AccountShare> existing = new Map<String, AccountShare>();
    for (AccountShare s : [
        SELECT Id, AccountId, UserOrGroupId
        FROM AccountShare
        WHERE AccountId IN :accountIds
        AND UserOrGroupId IN :userToLevel.keySet()
        AND RowCause = :Schema.AccountShare.RowCause.Manual
    ]) {
        existing.put(s.AccountId + '|' + s.UserOrGroupId, s);
    }

    List<AccountShare> toDelete = new List<AccountShare>();
    List<AccountShare> toInsert = new List<AccountShare>();

    for (Id acctId : accountIds) {
        for (Id userId : userToLevel.keySet()) {

            String key = acctId + '|' + userId;
            String lvl = normalizeLevel(userToLevel.get(userId));

            if (existing.containsKey(key)) {
                toDelete.add(existing.get(key));
            }

            toInsert.add(new AccountShare(
                AccountId              = acctId,
                UserOrGroupId          = userId,
                AccountAccessLevel     = lvl,
                OpportunityAccessLevel = lvl,
                RowCause               = Schema.AccountShare.RowCause.Manual
            ));
        }
    }

    if (!toDelete.isEmpty()) delete toDelete;
  //  if (!toInsert.isEmpty()) insert toInsert;
  if (!toInsert.isEmpty()) {
    Database.insert(toInsert, false);
}
}

    public static void deleteOppTeam(Set<Id> oppIds, Id userId) {
        if (oppIds == null || oppIds.isEmpty() || userId == null) return;

        List<OpportunityTeamMember> toDelete = [
            SELECT Id
            FROM OpportunityTeamMember
            WHERE OpportunityId IN :oppIds AND UserId = :userId
        ];
        if (!toDelete.isEmpty()) {
            isReplicating = true;
            try { delete toDelete; } finally { isReplicating = false; }
        }
    }
public static void bulkDeleteAccountShare(Set<Id> accountIds, Set<Id> userIds) {
    System.debug('account share delete called');
    System.debug('account id ...'+accountIds);
    if (accountIds.isEmpty() || userIds.isEmpty()) return;

    List<AccountShare> toDelete = [
        SELECT Id, RowCause
        FROM AccountShare
        WHERE AccountId IN :accountIds
        AND UserOrGroupId IN :userIds
    ];

    if (!toDelete.isEmpty()) delete toDelete;
}
    // ------------ Quote Share (CPQ) ------------
    public static void upsertQuoteShare(Set<Id> quoteIds, Id userId, String level) {
        if (quoteIds == null || quoteIds.isEmpty() || userId == null) return;
        if (!OppTeamReplicationGate.isQuoteManualSharingEnabled()) return;

        quoteIds = filterOutIneligibleExpiredByPMC(quoteIds);
        if (quoteIds.isEmpty()) return;

        Map<Id, SBQQ__Quote__Share> existingByQuote = new Map<Id, SBQQ__Quote__Share>();
        for (SBQQ__Quote__Share s : [
            SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause
            FROM SBQQ__Quote__Share
            WHERE ParentId IN :quoteIds
              AND UserOrGroupId = :userId
              AND RowCause = :Schema.SBQQ__Quote__Share.RowCause.Manual
        ]) {
            existingByQuote.put(s.ParentId, s);
        }

        List<SBQQ__Quote__Share> toInsert = new List<SBQQ__Quote__Share>();
        List<SBQQ__Quote__Share> toUpdate = new List<SBQQ__Quote__Share>();
        String lvl = normalizeLevel(level);

        for (Id qId : quoteIds) {
            SBQQ__Quote__Share ex = existingByQuote.get(qId);
            if (ex == null) {
                toInsert.add(new SBQQ__Quote__Share(
                    ParentId      = qId,
                    UserOrGroupId = userId,
                    AccessLevel   = lvl,
                    RowCause      = Schema.SBQQ__Quote__Share.RowCause.Manual
                ));
            } else if (ex.AccessLevel != lvl) {
                ex.AccessLevel = lvl;
                toUpdate.add(ex);
            }
        }
    System.debug('RUNNING USER = ' + UserInfo.getUserId());

System.debug('User can update Quote? ' +
    SBQQ__Quote__c.SObjectType.getDescribe().isUpdateable()
);


System.debug('Can Create QuoteShare? ' +
    SBQQ__Quote__Share.SObjectType.getDescribe().isCreateable()
);
try{
        if (!toInsert.isEmpty()) {
            Database.SaveResult[] ins = Database.insert(toInsert, false);
            logErrors('SBQQ__Quote__Share insert', ins, toInsert);
        }
}
catch(Exception e) {
    System.debug('QuoteShare insert failed but ignored: ' + e.getMessage());
}

        if (!toUpdate.isEmpty()) {
            Database.SaveResult[] upd = Database.update(toUpdate, false);
            logErrors('SBQQ__Quote__Share update', upd, toUpdate);
        }
    }

    public static void deleteQuoteShare(Set<Id> quoteIds, Id userId) {
        if (quoteIds == null || quoteIds.isEmpty() || userId == null) return;
        if (!OppTeamReplicationGate.isQuoteManualSharingEnabled()) return;

        quoteIds = filterOutIneligibleExpiredByPMC(quoteIds);
        if (quoteIds.isEmpty()) return;

        List<SBQQ__Quote__Share> toDelete = [
            SELECT Id
            FROM SBQQ__Quote__Share
            WHERE ParentId IN :quoteIds
              AND UserOrGroupId = :userId
              AND RowCause = :Schema.SBQQ__Quote__Share.RowCause.Manual
        ];
        if (!toDelete.isEmpty()) Database.delete(toDelete, false);
    }

public static void upsertAccountShare(Set<Id> accountIds, Id userId, String level) {
    if (accountIds == null || accountIds.isEmpty() || userId == null) return;

    String lvl = normalizeLevel(level);  // "Read" or "Edit"

    // Delete old shares
    List<AccountShare> oldShares = [
        SELECT Id
        FROM AccountShare
        WHERE AccountId IN :accountIds
          AND UserOrGroupId = :userId
          AND RowCause = :Schema.AccountShare.RowCause.Manual
    ];
    if (!oldShares.isEmpty()) delete oldShares;

    // Insert new shares — REQUIRED FIX: include OpportunityAccessLevel
    List<AccountShare> inserts = new List<AccountShare>();
    for (Id acctId : accountIds) {
        inserts.add(new AccountShare(
            AccountId              = acctId,
            UserOrGroupId          = userId,
            AccountAccessLevel     = lvl,
            OpportunityAccessLevel = 'Read',    
            RowCause               = Schema.AccountShare.RowCause.Manual
        ));
    }

   // insert inserts;
   if (!inserts.isEmpty()) {
    Database.insert(inserts, false);
}
}
public static void deleteAccountShare(Set<Id> accountIds, Id userId) {
    if (accountIds == null || accountIds.isEmpty() || userId == null) return;

    List<AccountShare> toDelete = [
        SELECT Id, RowCause
        FROM AccountShare
        WHERE AccountId IN :accountIds
        AND UserOrGroupId = :userId
        AND RowCause NOT IN (
            'Owner',
            'ImplicitChild',
            'ImplicitParent',
            'Territory',
            'Rule'
        )
    ];

    if (!toDelete.isEmpty()) delete toDelete;
}


    // ------------ Anchor Opp + eligible quotes ------------
    public static void upsertOppManualShare(Set<Id> oppIds, Id userId, String level) {
        if (oppIds == null || oppIds.isEmpty() || userId == null) return;
        
Integer teamCount = [
        SELECT COUNT()
        FROM OpportunityTeamMember
        WHERE OpportunityId IN :oppIds
        AND UserId = :userId
    ];
    if (teamCount > 0) {
        return; 
    }


        Map<Id, OpportunityShare> existingByOpp = new Map<Id, OpportunityShare>();
        for (OpportunityShare s : [
            SELECT Id, OpportunityId, UserOrGroupId, OpportunityAccessLevel, RowCause
            FROM OpportunityShare
            WHERE OpportunityId IN :oppIds
              AND UserOrGroupId = :userId
              AND RowCause = :Schema.OpportunityShare.RowCause.Manual
        ]) {
            existingByOpp.put(s.OpportunityId, s);
        }

        String access = normalizeLevel(level);
        List<OpportunityShare> toInsert = new List<OpportunityShare>();
        List<OpportunityShare> toUpdate = new List<OpportunityShare>();

        for (Id oppId : oppIds) {
            OpportunityShare ex = existingByOpp.get(oppId);
            if (ex == null) {
                toInsert.add(new OpportunityShare(
                    OpportunityId          = oppId,
                    UserOrGroupId          = userId,
                    OpportunityAccessLevel = access,
                    RowCause               = Schema.OpportunityShare.RowCause.Manual
                ));
            } else if (ex.OpportunityAccessLevel != access) {
                ex.OpportunityAccessLevel = access;
                toUpdate.add(ex);
            }
        }

        if (!toInsert.isEmpty()) {
            Database.SaveResult[] ins = Database.insert(toInsert, false);
            logErrors('OpportunityShare insert', ins, toInsert);
        }
        if (!toUpdate.isEmpty()) {
            Database.SaveResult[] upd = Database.update(toUpdate, false);
            logErrors('OpportunityShare update', upd, toUpdate);
        }
    }
public static void upsertEligibleQuoteSharesForOpp(Id opportunityId, Id userId, String level) {

    if (opportunityId == null || userId == null) return;
    if (!OppTeamReplicationGate.isQuoteManualSharingEnabled()) return;

    List<String> eligibleStatuses = new List<String>{
        'Request','Draft','Approved','Presented','Accepted','Rejected','Expired'
    };

    // Fetch ALL eligible quotes under THIS Opportunity
    List<SBQQ__Quote__c> eligibleQuotes = [
        SELECT Id
        FROM SBQQ__Quote__c
        WHERE (SBQQ__Opportunity2__c = :opportunityId 
            OR  SBQQ__Opportunity2__c  = :opportunityId)
          AND SBQQ__Status__c IN :eligibleStatuses
    ];

    if (eligibleQuotes.isEmpty()) return;

    Set<Id> quoteIds = new Set<Id>();
    for (SBQQ__Quote__c q : eligibleQuotes) quoteIds.add(q.Id);

    Map<Id, SBQQ__Quote__Share> existingByQuote = new Map<Id, SBQQ__Quote__Share>();
    for (SBQQ__Quote__Share s : [
        SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause
        FROM SBQQ__Quote__Share
        WHERE ParentId IN :quoteIds
          AND UserOrGroupId = :userId
          AND RowCause = :Schema.SBQQ__Quote__Share.RowCause.Manual
    ]) {
        existingByQuote.put(s.ParentId, s);
    }

    String lvl = normalizeLevel(level);
    List<SBQQ__Quote__Share> toInsert = new List<SBQQ__Quote__Share>();
    List<SBQQ__Quote__Share> toUpdate = new List<SBQQ__Quote__Share>();

    for (Id qId : quoteIds) {
        SBQQ__Quote__Share ex = existingByQuote.get(qId);
        if (ex == null) {
            toInsert.add(new SBQQ__Quote__Share(
                ParentId      = qId,
                UserOrGroupId = userId,
                AccessLevel   = lvl,
                RowCause      = Schema.SBQQ__Quote__Share.RowCause.Manual
            ));
        } else if (ex.AccessLevel != lvl) {
            ex.AccessLevel = lvl;
            toUpdate.add(ex);
        }
    }

    if (!toInsert.isEmpty()) {
        Database.SaveResult[] ins = Database.insert(toInsert, false);
        logErrors('Eligible QuoteShare insert', ins, toInsert);
    }
    if (!toUpdate.isEmpty()) {
        Database.SaveResult[] upd = Database.update(toUpdate, false);
        logErrors('Eligible QuoteShare update', upd, toUpdate);
    }
}

    public static void deleteIneligibleExpiredQuoteSharesForOpp(Id anchorOppId, Id userId) {
        if (anchorOppId == null || userId == null) return;
        if (!OppTeamReplicationGate.isQuoteManualSharingEnabled()) return;

        final Date cutoff = Date.today().addDays(-180);

        List<SBQQ__Quote__c> oldExpired = [
            SELECT Id
            FROM SBQQ__Quote__c
            WHERE SBQQ__Opportunity2__c = :anchorOppId
              AND SBQQ__Status__c = 'Expired'
              AND PMC_CPQ_ExpirationDate__c != null
              AND PMC_CPQ_ExpirationDate__c < :cutoff
        ];
        if (oldExpired.isEmpty()) return;

        Set<Id> oldIds = new Set<Id>();
        for (SBQQ__Quote__c q : oldExpired) oldIds.add(q.Id);

        List<SBQQ__Quote__Share> toDelete = [
            SELECT Id
            FROM SBQQ__Quote__Share
            WHERE ParentId IN :oldIds
              AND UserOrGroupId = :userId
              AND RowCause = :Schema.SBQQ__Quote__Share.RowCause.Manual
        ];
        if (!toDelete.isEmpty()) Database.delete(toDelete, false);
    }

    public static void grantAnchorOppAndEligibleQuotesAccess(
        Id anchorOppId, Id userId, String level, Boolean cleanupOldExpired
    ) {
        if (anchorOppId == null || userId == null) return;
        upsertOppManualShare(new Set<Id>{ anchorOppId }, userId, level);
        upsertEligibleQuoteSharesForOpp(anchorOppId, userId, level);
        if (cleanupOldExpired == true) deleteIneligibleExpiredQuoteSharesForOpp(anchorOppId, userId);
    }

    public static void topUpEligibleQuoteSharesForAnchor(Id anchorOppId) {
        if (anchorOppId == null) return;
        if (!OppTeamReplicationGate.isQuoteManualSharingEnabled()) return;

        final Date cutoff = Date.today().addDays(-180);

       
        Map<Id, String> userToLevel = new Map<Id, String>();
        for (OpportunityTeamMember t : [
            SELECT UserId, OpportunityAccessLevel
            FROM OpportunityTeamMember
            WHERE OpportunityId = :anchorOppId
        ]) {
            String lvl = normalizeLevel(t.OpportunityAccessLevel);
            String curr = userToLevel.get(t.UserId);
            if (curr == null || 'Edit'.equals(lvl)) userToLevel.put(t.UserId, lvl);
        }
        if (userToLevel.isEmpty()) return;

        // 2) ELIGIBLE quotes on the anchor
        List<SBQQ__Quote__c> eligibleQuotes = [
            SELECT Id
            FROM SBQQ__Quote__c
            WHERE SBQQ__Opportunity2__c = :anchorOppId
              AND (
                    SBQQ__Status__c IN ('Request','Draft','Approved','Presented','Accepted','Rejected')
                    OR (SBQQ__Status__c = 'Expired'
                        AND PMC_CPQ_ExpirationDate__c != null
                        AND PMC_CPQ_ExpirationDate__c >= :cutoff)
                  )
                //  WITH SYSTEM_MODE
        ];
        if (eligibleQuotes.isEmpty()) return;

        Set<Id> qIds = new Set<Id>();
        for (SBQQ__Quote__c q : eligibleQuotes) qIds.add(q.Id);

        // 3) Existing MANUAL shares for these users on eligible quotes
        Map<String, Boolean> hasShare = new Map<String, Boolean>(); // key = quoteId|userId
        for (SBQQ__Quote__Share s : [
            SELECT ParentId, UserOrGroupId
            FROM SBQQ__Quote__Share
            WHERE ParentId IN :qIds
              AND UserOrGroupId IN :userToLevel.keySet()
              AND RowCause = :Schema.SBQQ__Quote__Share.RowCause.Manual
        ]) {
            hasShare.put(s.ParentId + '|' + s.UserOrGroupId, true);
        }

        // 4) Insert only MISSING shares
        List<SBQQ__Quote__Share> toInsert = new List<SBQQ__Quote__Share>();
        for (Id qId : qIds) {
            for (Id uId : userToLevel.keySet()) {
                String key = qId + '|' + uId;
                if (!hasShare.containsKey(key)) {
                    toInsert.add(new SBQQ__Quote__Share(
                        ParentId      = qId,
                        UserOrGroupId = uId,
                        AccessLevel   = userToLevel.get(uId),
                        RowCause      = Schema.SBQQ__Quote__Share.RowCause.Manual
                    ));
                }
            }
        }
        try{
        if (!toInsert.isEmpty()) {
            Database.SaveResult[] ins = Database.insert(toInsert, false);
            logErrors('TopUp QuoteShare insert', ins, toInsert);
        }
        }
        
catch (Exception e) {
    System.debug('TopUp QuoteShare failed but ignored: ' + e.getMessage());
}

    }

    // --- helper: per-row error logging for partial DML ---
    private static void logErrors(String op, Database.SaveResult[] results, List<SObject> records) {
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error e : results[i].getErrors()) {
                    System.debug(LoggingLevel.WARN,
                        op + ' failed: ' + e.getStatusCode() + ' - ' + e.getMessage()
                        + ' rec=' + String.valueOf(records[i]));
                }
            }
        }
    }
    public static void deleteOppManualShare(Set<Id> oppIds, Id userId) {
    if (oppIds == null || oppIds.isEmpty() || userId == null) return;

    List<OpportunityShare> toDelete = [
        SELECT Id
        FROM OpportunityShare
        WHERE OpportunityId IN :oppIds
          AND UserOrGroupId = :userId
          AND RowCause = :Schema.OpportunityShare.RowCause.Manual
    ];
    if (!toDelete.isEmpty()) Database.delete(toDelete, false);
}

public static void bulkUpsertQuoteShares(Set<Id> oppIds, Map<Id,String> userToLevel) {

    if (oppIds == null || oppIds.isEmpty()) return;
    if (userToLevel == null || userToLevel.isEmpty()) return;
    if (!OppTeamReplicationGate.isQuoteManualSharingEnabled()) return;

    // -----------------------------
    // 1) Fetch ALL eligible quotes
    // -----------------------------
    List<String> eligibleStatuses = new List<String>{
        'Request','Draft','Approved','Presented','Accepted','Rejected','Expired'
    };

    List<SBQQ__Quote__c> allQuotes = [
        SELECT Id, SBQQ__Opportunity2__c, SBQQ__Status__c
        FROM SBQQ__Quote__c
        WHERE SBQQ__Opportunity2__c IN :oppIds
          AND SBQQ__Status__c IN :eligibleStatuses
          //WITH SYSTEM_MODE
    ];

    if (allQuotes.isEmpty()) return;

    Set<Id> allQuoteIds = new Set<Id>();
    for (SBQQ__Quote__c q : allQuotes) allQuoteIds.add(q.Id);

    Map<String, SBQQ__Quote__Share> existing = new Map<String, SBQQ__Quote__Share>();
    // key = quoteId + '|' + userId

    List<SBQQ__Quote__Share> oldShares = [
        SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause
        FROM SBQQ__Quote__Share
        WHERE ParentId IN :allQuoteIds
          AND UserOrGroupId IN :userToLevel.keySet()
          AND RowCause = :Schema.SBQQ__Quote__Share.RowCause.Manual
    ];

    for (SBQQ__Quote__Share s : oldShares) {
        existing.put(s.ParentId + '|' + s.UserOrGroupId, s);
    }

    // -----------------------------
    // 3) Build bulk INSERT + UPDATE
    // -----------------------------
    List<SBQQ__Quote__Share> toInsert = new List<SBQQ__Quote__Share>();
    List<SBQQ__Quote__Share> toUpdate = new List<SBQQ__Quote__Share>();

    for (SBQQ__Quote__c q : allQuotes) {
        for (Id userId : userToLevel.keySet()) {
            String key = q.Id + '|' + userId;
            String lvl = normalizeLevel(userToLevel.get(userId));

            if (!existing.containsKey(key)) {
                // INSERT
                toInsert.add(new SBQQ__Quote__Share(
                    ParentId      = q.Id,
                    UserOrGroupId = userId,
                    AccessLevel   = lvl,
                    RowCause      = Schema.SBQQ__Quote__Share.RowCause.Manual
                ));
            } else {
                // UPDATE if needed
                SBQQ__Quote__Share ex = existing.get(key);
                if (ex.AccessLevel != lvl) {
                    ex.AccessLevel = lvl;
                    toUpdate.add(ex);
                }
            }
        }
    }

    // -----------------------------
    // 4) DML (bulk-safe)
    // -----------------------------
    try {

    if (!toInsert.isEmpty()) {
        Database.SaveResult[] ins = Database.insert(toInsert, false);
        logErrors('Bulk QuoteShare INSERT', ins, toInsert);
    }}
   
catch (Exception e) {
    System.debug('QuoteShare INSERT failed but ignored: ' + e.getMessage());
}


    if (!toUpdate.isEmpty()) {
        Database.SaveResult[] upd = Database.update(toUpdate, false);
        logErrors('Bulk QuoteShare UPDATE', upd, toUpdate);
    }
}
public static void bulkDeleteOppManualShare(Set<Id> oppIds, Set<Id> userIds) {
    if (oppIds == null || oppIds.isEmpty()) return;
    if (userIds == null || userIds.isEmpty()) return;

    List<OpportunityShare> toDelete = [
        SELECT Id
        FROM OpportunityShare
        WHERE OpportunityId IN :oppIds
        AND UserOrGroupId IN :userIds
        AND RowCause = :Schema.OpportunityShare.RowCause.Manual
    ];

    if (!toDelete.isEmpty()) {
        Database.delete(toDelete, false);
    }
}

public static void restoreLostOTM(
    Set<Id> oppIds,
    Set<Id> userIds,
    Map<Id, String> userToLevel
) {
    if (oppIds == null || oppIds.isEmpty()) return;
    if (userIds == null || userIds.isEmpty()) return;

    Map<String, OpportunityTeamMember> existing = new Map<String, OpportunityTeamMember>();

    for (OpportunityTeamMember otm : [
        SELECT Id, OpportunityId, UserId, OpportunityAccessLevel
        FROM OpportunityTeamMember
        WHERE OpportunityId IN :oppIds
          AND UserId IN :userIds
    ]) {
        existing.put(otm.OpportunityId + '|' + otm.UserId, otm);
    }

    List<OpportunityTeamMember> toInsert = new List<OpportunityTeamMember>();
    List<OpportunityTeamMember> toUpdate = new List<OpportunityTeamMember>();

    for (Id oppId : oppIds) {
        for (Id userId : userIds) {

            String key = oppId + '|' + userId;
            String lvl = normalizeLevel(userToLevel.get(userId));

            if (!existing.containsKey(key)) {
                // ✅ INSERT ONLY IF MISSING
                toInsert.add(new OpportunityTeamMember(
                    OpportunityId = oppId,
                    UserId        = userId,
                    OpportunityAccessLevel = lvl
                ));
            } else {
                // ✅ UPDATE ONLY IF LEVEL CHANGED
                OpportunityTeamMember ex = existing.get(key);
                if (ex.OpportunityAccessLevel != lvl) {
                    ex.OpportunityAccessLevel = lvl;
                    toUpdate.add(ex);
                }
            }
        }
    }

    isReplicating = true;
    try {
        if (!toInsert.isEmpty()) insert toInsert;
        if (!toUpdate.isEmpty()) update toUpdate;
    } finally {
        isReplicating = false;
    }
}
public static void deleteManualOppShareForTeamUsers(
    Set<Id> oppIds,
    Set<Id> userIds
) {
    if (oppIds.isEmpty()) return;

    List<OpportunityShare> manualShares = [
        SELECT Id
        FROM OpportunityShare
        WHERE OpportunityId IN :oppIds
        AND RowCause = :Schema.OpportunityShare.RowCause.Manual
    ];

    if (!manualShares.isEmpty()) {
        Database.delete(manualShares, false);
    }
}
private static Set<String> buildTeamKeys(Set<Id> oppIds, Set<Id> userIds) {

    Set<String> teamKeys = new Set<String>();

    for (OpportunityTeamMember otm : [
        SELECT OpportunityId, UserId
        FROM OpportunityTeamMember
        WHERE OpportunityId IN :oppIds
        AND UserId IN :userIds
    ]) {
        teamKeys.add(otm.OpportunityId + '|' + otm.UserId);
    }

    return teamKeys;
}
}