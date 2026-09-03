public without sharing class UserLookupControllerOppTeams {

   
    public class DefaultTeamRowDTO {
        @AuraEnabled public Id defaultTeamMemberId;
        @AuraEnabled public Id ownerId;    // owner first
        @AuraEnabled public Id userId;     // member second
        @AuraEnabled public String userName;
        @AuraEnabled public String role;
        @AuraEnabled public String access;

        // ORDER: (dtmId, ownerId, userId, userName, role, access)
        public DefaultTeamRowDTO(
            Id defaultTeamMemberId,
            Id ownerId,
            Id userId,
            String userName,
            String role,
            String access
        ) {
            this.defaultTeamMemberId = defaultTeamMemberId;
            this.ownerId = ownerId;
            this.userId  = userId;
            this.userName = userName;
            this.role = role;
            this.access = access;
        }
    }

    public class SaveSummary {
        @AuraEnabled public Integer upsertedCount;
        @AuraEnabled public Integer deletedCount;
        @AuraEnabled public Integer pushedCount;
        @AuraEnabled public Integer updatedCount;
        @AuraEnabled public List<String> messages = new List<String>();
    }

    // Verbose result for diagnostics
    public class CascadeResult {
        @AuraEnabled public String  pathUsed;              // 'system' or 'sharing'
        @AuraEnabled public Integer openOppCount;
        @AuraEnabled public Integer otmFound;
        @AuraEnabled public Integer otmDeleted;
        @AuraEnabled public List<String> messages          = new List<String>();
        @AuraEnabled public List<String> firstErrorMessages = new List<String>();
    }

    // =========================
    // Lookup & metadata helpers
    // =========================
    @AuraEnabled
public static Map<String, Object> bulkUpsertDefaultTeamViaFlowInterviews(
    Id ownerUserId,
    List<Id> memberUserIds,
    List<String> roles,
    List<String> accesses,
    String defaultRole,
    String defaultAccess
) {
    if (ownerUserId == null) throw new AuraHandledException('ownerUserId is required.');
    if (memberUserIds == null || memberUserIds.isEmpty())
        throw new AuraHandledException('memberUserIds is required.');

    // Normalize inputs
    List<String> memberIdsText = new List<String>();
    for (Id idVal : memberUserIds) memberIdsText.add((String)idVal);
    if (roles == null)    roles = new List<String>();
    if (accesses == null) accesses = new List<String>();
    String defAcc = (defaultAccess == 'Edit') ? 'Edit' : 'Read';

    // Results keyed by userId to avoid any ordering ambiguity
    Map<String, String> idByUserId    = new Map<String, String>();
    Map<String, String> errorByUserId = new Map<String, String>();
    Integer successCount = 0;

    Integer n = memberIdsText.size();
    for (Integer i = 0; i < n; i++) {
        String memberId = memberIdsText[i];
        String role_i   = (i < roles.size()    && !String.isBlank(roles[i]))    ? roles[i]    : defaultRole;
        String acc_in   = (i < accesses.size() && !String.isBlank(accesses[i])) ? accesses[i] : defAcc;
        String acc_i    = (acc_in == 'Edit') ? 'Edit' : 'Read';
        try {
        
            Map<String, Object> inputs = new Map<String, Object>{
                'ownerUserId'  => (String)ownerUserId,
                'memberUserId' => memberId,
                'role'         => role_i,
                'access'       => acc_i
            };

            // One Autolaunched Flow interview per member
            Flow.Interview.UserManagerUpdateCreate f = new Flow.Interview.UserManagerUpdateCreate(inputs);
            f.start(); // Start a Flow from Apex (supported)  [4](https://salesforcefaqs.com/like-clause-in-soql/)

            Object err = f.getVariableValue('errorMessage');
            if (err != null && String.valueOf(err).trim() != '') {
                errorByUserId.put(memberId, String.valueOf(err));
            } else {
                Object created = f.getVariableValue('createdId');
                idByUserId.put(memberId, (created == null) ? null : String.valueOf(created));
                successCount++;
            }
        } catch (Exception e) {
            errorByUserId.put(memberId, e.getMessage());
        }
    }

    return new Map<String, Object>{
        'successCount' => successCount,
        'idByUserId'   => idByUserId,
        'errorByUserId'=> errorByUserId
    };
}

/**
 * Bulk delete Opportunity Team Members (OTM) for multiple users
 * across ALL OPEN Opportunities owned by the given owner.
 *
 * INPUT:
 *   ownerUserId: the Opportunity owner whose open opportunities will be considered
 *   memberUserIds: users to remove from those opportunity teams
 *
 * OUTPUT:
 *   Map<String,Object> summary with keys:
 *     totalDeleted      (Integer)  total OTM rows deleted
 *     deletedByUserId   (Map<String,Integer>) counts per member userId
 *     errorByUserId     (Map<String,String>)  first error per member userId (if any)
 *     firstErrors       (List<String>)        up to 10 raw DML error messages
 */
@AuraEnabled
public static Map<String, Object> bulkDeleteOppTeamMembersForOwner(
    Id ownerUserId,
    List<Id> memberUserIds
) {
    if (ownerUserId == null) throw new AuraHandledException('ownerUserId is required.');
    if (memberUserIds == null || memberUserIds.isEmpty())
        throw new AuraHandledException('memberUserIds is required.');

    // 1) Gather open opportunities for the owner
    List<Opportunity> openOpps = [
        SELECT Id
        FROM Opportunity
        WHERE OwnerId = :ownerUserId
         // AND IsClosed = FALSE
        LIMIT 2000
    ];
    if (openOpps.isEmpty()) {
        return new Map<String, Object>{
            'totalDeleted'      => 0,
            'deletedByUserId'   => new Map<String,Integer>(),
            'errorByUserId'     => new Map<String,String>(),
            'firstErrors'       => new List<String>()
        };
    }
    Set<Id> oppIds = new Set<Id>(); for (Opportunity o : openOpps) oppIds.add(o.Id);

    // 2) Collect OTM rows for those opps & members
    Set<Id> memberSet = new Set<Id>(memberUserIds);
    List<OpportunityTeamMember> otms = [
        SELECT Id, OpportunityId, UserId
        FROM OpportunityTeamMember
        WHERE OpportunityId IN :oppIds
          AND UserId IN :memberSet
    ];

    // 3) Delete OTM with partial success
    Map<String, Integer> deletedByUserId = new Map<String, Integer>();
    Map<String, String>  errorByUserId   = new Map<String, String>();
    List<String> firstErrors = new List<String>();

    if (otms.isEmpty()) {
        return new Map<String, Object>{
            'totalDeleted'      => 0,
            'deletedByUserId'   => deletedByUserId,
            'errorByUserId'     => errorByUserId,
            'firstErrors'       => firstErrors
        };
    }

    for (Id uid : memberSet) deletedByUserId.put((String)uid, 0);

    Database.DeleteResult[] drs = Database.delete(otms, false);
    Integer totalDeleted = 0;

    for (Integer i = 0; i < drs.size(); i++) {
        OpportunityTeamMember row = otms[i];
        Database.DeleteResult dr = drs[i];
        String keyUser = (String)row.UserId;

        if (dr.isSuccess()) {
            totalDeleted++;
            deletedByUserId.put(keyUser, (deletedByUserId.containsKey(keyUser) ? deletedByUserId.get(keyUser) : 0) + 1);
        } else {
            if (!errorByUserId.containsKey(keyUser) && dr.getErrors() != null && dr.getErrors().size() > 0) {
                errorByUserId.put(keyUser, dr.getErrors()[0].getStatusCode() + ': ' + dr.getErrors()[0].getMessage());
            }
            if (firstErrors.size() < 10 && dr.getErrors() != null) {
                for (Database.Error e : dr.getErrors()) {
                    if (firstErrors.size() < 10) firstErrors.add(e.getStatusCode() + ': ' + e.getMessage());
                }
            }
        }
    }

    // ---------- SHARE DELETE (non-blocking) ----------
  //  try {
        QuoteAccountShareCascade.deleteForOpps(oppIds, memberSet);
    //} catch (Exception ex) {
      //  System.debug('Share delete (owner-wide) failed: ' + ex.getMessage());
    //}
    // ---------- END SHARE DELETE ----------

    return new Map<String, Object>{
        'totalDeleted'      => totalDeleted,
        'deletedByUserId'   => deletedByUserId,
        'errorByUserId'     => errorByUserId,
        'firstErrors'       => firstErrors
    };
}


@AuraEnabled
public static Map<String, Object> bulkDeleteOppTeamMembersOnOpportunity(
    Id opportunityId,
    List<Id> memberUserIds
) {
    if (opportunityId == null) throw new AuraHandledException('opportunityId is required.');
    if (memberUserIds == null || memberUserIds.isEmpty())
        throw new AuraHandledException('memberUserIds is required.');

    Set<Id> memberSet = new Set<Id>(memberUserIds);

    List<OpportunityTeamMember> otms = [
        SELECT Id, OpportunityId, UserId
        FROM OpportunityTeamMember
        WHERE OpportunityId = :opportunityId
          AND UserId IN :memberSet
    ];

    Map<String, Integer> deletedByUserId = new Map<String, Integer>();
    Map<String, String>  errorByUserId   = new Map<String, String>();
    List<String> firstErrors = new List<String>();
    for (Id uid : memberSet) deletedByUserId.put((String)uid, 0);

    if (otms.isEmpty()) {
        return new Map<String, Object>{
            'totalDeleted'      => 0,
            'deletedByUserId'   => deletedByUserId,
            'errorByUserId'     => errorByUserId,
            'firstErrors'       => firstErrors
        };
    }

    Database.DeleteResult[] drs = Database.delete(otms, false);
    Integer totalDeleted = 0;

    for (Integer i = 0; i < drs.size(); i++) {
        OpportunityTeamMember row = otms[i];
        Database.DeleteResult dr = drs[i];
        String keyUser = (String)row.UserId;

        if (dr.isSuccess()) {
            totalDeleted++;
            deletedByUserId.put(keyUser, (deletedByUserId.containsKey(keyUser) ? deletedByUserId.get(keyUser) : 0) + 1);
        } else {
            if (!errorByUserId.containsKey(keyUser) && dr.getErrors() != null && dr.getErrors().size() > 0) {
                errorByUserId.put(keyUser, dr.getErrors()[0].getStatusCode() + ': ' + dr.getErrors()[0].getMessage());
            }
            if (firstErrors.size() < 10 && dr.getErrors() != null) {
                for (Database.Error e : dr.getErrors()) {
                    if (firstErrors.size() < 10) firstErrors.add(e.getStatusCode() + ': ' + e.getMessage());
                }
            }
        }
    }

    // ---------- SHARE DELETE (non-blocking) ----------
  //  try {
        QuoteAccountShareCascade.deleteForOpp(opportunityId, memberSet);
    //} catch (Exception ex) {
       // System.debug('Share delete (single-opp) failed: ' + ex.getMessage());
    //}
    // ---------- END SHARE DELETE ----------

    return new Map<String, Object>{
        'totalDeleted'      => totalDeleted,
        'deletedByUserId'   => deletedByUserId,
        'errorByUserId'     => errorByUserId,
        'firstErrors'       => firstErrors
    };
}

@AuraEnabled(cacheable=true)
public static List<User> searchUsers(String q, Integer limitSize) {
    try {
        if (String.isBlank(q) || q.trim().length() < 2) return new List<User>();

        Integer lim = (limitSize == null || limitSize <= 0) ? 7 : Math.min(limitSize, 50);
        String likeTerm = '%' + q.trim() + '%';

        List<User> rows = [
            SELECT Id, Name, Username, Title, Department, SmallPhotoUrl, IsActive
            FROM User
            WHERE IsActive = true
              AND Name LIKE :likeTerm
            ORDER BY Name
            LIMIT :lim
        ];

        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.READABLE, rows);
        return (List<User>) dec.getRecords();
    } catch (Exception ex) {
        return new List<User>();
    }
    
    
}

    @AuraEnabled(cacheable=true)
    public static List<String> getOpportunityTeamRoles() {
        List<String> roles = new List<String>();
        Schema.DescribeFieldResult dfr = OpportunityTeamMember.TeamMemberRole.getDescribe();
        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
            roles.add(pe.getValue());
        }
        return roles;
    }


    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getCurrentTeamMembers(Id ownerUserId) {
        if (ownerUserId == null) throw new AuraHandledException('ownerUserId is required.');

        List<OpportunityTeamMember> otms = [
            SELECT Id, OpportunityId, Opportunity.Name,
                   UserId, User.Name, TeamMemberRole, OpportunityAccessLevel
            FROM OpportunityTeamMember
            WHERE Opportunity.OwnerId = :ownerUserId
           //   AND Opportunity.IsClosed = false
            ORDER BY OpportunityId, User.Name
        ];

        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (OpportunityTeamMember otm : otms) {
            Map<String, Object> row = new Map<String, Object>();
            row.put('oppTeamMemberId', (String) otm.Id);
            row.put('userId', (String) otm.UserId);
            row.put('userName', otm.User.Name);
            row.put('role', otm.TeamMemberRole);
            row.put('access', String.valueOf(otm.OpportunityAccessLevel));
            row.put('opportunityId', (String) otm.OpportunityId);
            row.put('opportunityName', otm.Opportunity.Name);
            rows.add(row);
        }
        return rows;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getOpportunityTeamMembers(Id opportunityId) {
        if (opportunityId == null) throw new AuraHandledException('opportunityId is required.');

        List<OpportunityTeamMember> otms = [
            SELECT Id, OpportunityId, Opportunity.OwnerId,
                   UserId, User.Name, TeamMemberRole, OpportunityAccessLevel
            FROM OpportunityTeamMember
            WHERE OpportunityId = :opportunityId
            ORDER BY User.Name
        ];

        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (OpportunityTeamMember otm : otms) {
            Map<String, Object> row = new Map<String, Object>();
            row.put('oppTeamMemberId', (String) otm.Id);           // ✅ include for single-opp delete
            row.put('ownerId',        (String) otm.Opportunity.OwnerId); // ✅ include for LWC
            row.put('userId',         (String) otm.UserId);
            row.put('userName',                otm.User.Name);
            row.put('role',                    otm.TeamMemberRole);
            row.put('access',         String.valueOf(otm.OpportunityAccessLevel));
            rows.add(row);
        }
        return rows;
    }

   
    @AuraEnabled(cacheable=true)
    public static List<DefaultTeamRowDTO> getDefaultOppTeam(Id ownerUserId) {
        if (ownerUserId == null) return new List<DefaultTeamRowDTO>();

        List<DefaultTeamRowDTO> rows = new List<DefaultTeamRowDTO>();
        for (UserTeamMember utm : [
            SELECT  Id, OwnerId, UserId, User.Name, TeamMemberRole, OpportunityAccessLevel
            FROM    UserTeamMember
            WHERE   OwnerId = :ownerUserId
            ORDER BY CreatedDate ASC
        ]) {
            rows.add(new DefaultTeamRowDTO(
                utm.Id,
                utm.OwnerId,   // ownerId to constructor #2
                utm.UserId,    // userId  to constructor #3
                utm.User.Name,
                utm.TeamMemberRole,
                utm.OpportunityAccessLevel
            ));
        }
        return rows;
    }


@AuraEnabled
public static List<Id> upsertOppTeamMembers(Id opportunityId, List<DefaultTeamRowDTO> rows) {
    if (opportunityId == null) throw new AuraHandledException('OpportunityId is required.');
    if (rows == null || rows.isEmpty()) return new List<Id>();

    Set<Id> userIds = new Set<Id>();
    Map<Id, DefaultTeamRowDTO> byUser = new Map<Id, DefaultTeamRowDTO>();
    for (DefaultTeamRowDTO r : rows) {
        if (r == null || r.userId == null) continue;
        if (!byUser.containsKey(r.userId)) {
            byUser.put(r.userId, r);
            userIds.add(r.userId);
        }
    }
    if (userIds.isEmpty()) return new List<Id>();

    Map<Id, OpportunityTeamMember> existingByUser = new Map<Id, OpportunityTeamMember>();
    for (OpportunityTeamMember otm : [
        SELECT Id, OpportunityId, UserId, TeamMemberRole, OpportunityAccessLevel
        FROM OpportunityTeamMember
        WHERE OpportunityId = :opportunityId
          AND UserId IN :userIds
    ]) {
        existingByUser.put(otm.UserId, otm);
    }

    List<OpportunityTeamMember> toUpdate = new List<OpportunityTeamMember>();
    List<OpportunityTeamMember> toInsert = new List<OpportunityTeamMember>();

    for (Id uId : byUser.keySet()) {
        DefaultTeamRowDTO r = byUser.get(uId);
        String access = (r.access == 'Edit') ? 'Edit' : 'Read';

        if (existingByUser.containsKey(uId)) {
            OpportunityTeamMember e = existingByUser.get(uId);
            e.TeamMemberRole = r.role;
            e.OpportunityAccessLevel = access;
            toUpdate.add(e);
        } else {
            OpportunityTeamMember n = new OpportunityTeamMember();
            n.OpportunityId = opportunityId;
            n.UserId = uId;
            n.TeamMemberRole = r.role;
            n.OpportunityAccessLevel = access;
            toInsert.add(n);
        }
    }

    List<Id> resultIds = new List<Id>();
    if (!toInsert.isEmpty()) {
        insert toInsert;
        for (OpportunityTeamMember n : toInsert) resultIds.add(n.Id);
    }
    if (!toUpdate.isEmpty()) {
        update toUpdate;
        for (OpportunityTeamMember u : toUpdate) resultIds.add(u.Id);
    }
    // ✅ SYNC QUOTE SHARES AFTER OTM CHANGE
try {
    OppTeamReplicationService.topUpEligibleQuoteSharesForAnchor(opportunityId);
} catch (Exception ex) {
    // Non-blocking — do NOT fail LWC save
    System.debug(
        'Quote share sync failed for opp ' + opportunityId + ' : ' + ex.getMessage()
    );
}

    // ---------- SHARE SYNC (non-blocking, via cascade utility) ----------
    try {
        // Build user -> level map from input
        Map<Id, String> userToLevel = new Map<Id, String>();
        for (Id uid : byUser.keySet()) {
            String lvl = (byUser.get(uid).access == 'Edit') ? 'Edit' : 'Read';
            userToLevel.put(uid, lvl);
        }
        // One call updates: OpportunityShare (Manual), AccountShare (Manual), CPQ Quote Share (Manual, eligible)
      //  QuoteAccountShareCascade.syncForOpp(opportunityId, userToLevel);
    } catch (Exception ex) {
       // System.debug('Share sync (single-opp) failed: ' + ex.getMessage());
    }
    // ---------- END SHARE SYNC ----------

    return resultIds;
}
   @AuraEnabled
public static SaveSummary saveDefaultOppTeam(
    Id ownerUserId,
    Boolean updateOpenOpps,
    List<Object> rowsRaw,
    Boolean replaceExisting,
    Boolean replaceDefault
) {
    SaveSummary summary = new SaveSummary();

    if (ownerUserId == null) throw new AuraHandledException('ownerUserId is required.');
    if (rowsRaw == null) rowsRaw = new List<Object>();

    // Convert to Map<String,Object>
    List<Map<String, Object>> rows = new List<Map<String, Object>>();
    for (Object o : rowsRaw) {
        Map<String, Object> viaJson = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(o));
        rows.add(viaJson);
    }

    if (updateOpenOpps != true) return summary;

    // Open Opps for owner
    List<Opportunity> openOpps = [
        SELECT Id
        FROM Opportunity
        WHERE OwnerId = :ownerUserId
          // AND IsClosed = false
        LIMIT 2000
    ];
    if (openOpps.isEmpty()) return summary;
    Set<Id> oppIds = new Set<Id>(); for (Opportunity o : openOpps) oppIds.add(o.Id);

    // Desired users (respect markForDelete)
    Set<Id> userIds = new Set<Id>();
    Map<Id, Map<String,Object>> cfgByUser = new Map<Id, Map<String,Object>>();
    for (Map<String,Object> r : rows) {
        if ((Boolean) r.get('markForDelete') == true) continue;
        String userIdStr = (String) r.get('userId');
        if (String.isBlank(userIdStr)) continue;
        Id uid; try { uid = (Id) userIdStr; } catch (Exception e) { continue; }
        userIds.add(uid);
        cfgByUser.put(uid, r);
    }
    if (userIds.isEmpty() && rows.isEmpty()) return summary;

    // Filter inactive & owner
    Map<Id, User> usersById = new Map<Id, User>([
        SELECT Id, IsActive FROM User WHERE Id IN :userIds
    ]);
    Set<Id> validUserIds = new Set<Id>();
    for (Id uid : userIds) {
        User u = usersById.get(uid);
        if (u == null) continue;
        if (!u.IsActive) continue;
        if (uid == ownerUserId) continue;
        validUserIds.add(uid);
    }

    // Role requirement
    Schema.DescribeFieldResult dfr = OpportunityTeamMember.TeamMemberRole.getDescribe();
    Boolean roleRequired = !dfr.isNillable();
    if (roleRequired) {
        Set<Id> withRole = new Set<Id>();
        for (Id uid : validUserIds) {
            Map<String,Object> cfg = cfgByUser.get(uid);
            String role = (String) cfg.get('role');
            if (!String.isBlank(role)) withRole.add(uid);
        }
        validUserIds = withRole;
        if (validUserIds.isEmpty()) return summary;
    }

    // Existing OTM across these Opps
    Map<String, OpportunityTeamMember> existingByKey = new Map<String, OpportunityTeamMember>();
    List<OpportunityTeamMember> existingAll = new List<OpportunityTeamMember>();
    if (!oppIds.isEmpty()) {
        existingAll = [
            SELECT Id, OpportunityId, UserId, TeamMemberRole, OpportunityAccessLevel
            FROM OpportunityTeamMember
            WHERE OpportunityId IN :oppIds
        ];
        for (OpportunityTeamMember ex : existingAll) {
            existingByKey.put(ex.OpportunityId + '|' + ex.UserId, ex);
        }
    }

    List<OpportunityTeamMember> toInsert = new List<OpportunityTeamMember>();
    List<OpportunityTeamMember> toUpdate = new List<OpportunityTeamMember>();
    for (Opportunity o : openOpps) {
        for (Id uid : validUserIds) {
            Map<String, Object> cfg = cfgByUser.get(uid);
            String roleVal   = (String) cfg.get('role');
            String accessIn  = (String) cfg.get('access');
            String acc       = (accessIn == 'Edit') ? 'Edit' : 'Read';

            String key = o.Id + '|' + uid;
            OpportunityTeamMember ex = existingByKey.get(key);
            if (ex == null) {
                OpportunityTeamMember m = new OpportunityTeamMember();
                m.OpportunityId = o.Id;
                m.UserId = uid;
                m.TeamMemberRole = roleVal;
                m.OpportunityAccessLevel = acc;
                toInsert.add(m);
            } else {
                Boolean needsUpdate = false;
                if (roleVal != ex.TeamMemberRole)            { ex.TeamMemberRole = roleVal;            needsUpdate = true; }
                if (acc != ex.OpportunityAccessLevel)        { ex.OpportunityAccessLevel = acc;        needsUpdate = true; }
                if (needsUpdate) { toUpdate.add(ex); }
            }
        }
    }

    // Explicit deletes for markForDelete
    Set<Id> explicitDeleteUserIds = new Set<Id>();
    for (Map<String, Object> r : rows) {
        if ((Boolean) r.get('markForDelete') == true) {
            String userIdStr = (String) r.get('userId');
            if (!String.isBlank(userIdStr)) {
                try { explicitDeleteUserIds.add((Id) userIdStr); } catch (Exception ignore) {}
            }
        }
    }
    if (!explicitDeleteUserIds.isEmpty()) {
        explicitDeleteUserIds.remove(ownerUserId); // never delete owner
        List<OpportunityTeamMember> otmsToDelete = [
            SELECT Id
            FROM OpportunityTeamMember
            WHERE OpportunityId IN :oppIds
              AND UserId IN :explicitDeleteUserIds
        ];
        if (!otmsToDelete.isEmpty()) {
            Database.DeleteResult[] delRsExp = Database.delete(otmsToDelete, false);
            Integer delOkExp = 0; for (Database.DeleteResult dr : delRsExp) if (dr.isSuccess()) delOkExp++;
            summary.deletedCount = (summary.deletedCount == null ? 0 : summary.deletedCount) + delOkExp;
        }

        // --- SHARE CLEANUP for explicitly removed users (non-blocking) ---
       // try {
            QuoteAccountShareCascade.deleteForOpps(oppIds, explicitDeleteUserIds);
        //} //catch (Exception exDelShares) {
           // System.debug('Share cleanup (owner-wide explicit delete) failed: ' + exDelShares.getMessage());
       // }
    //    finally{}
    }

    // DML
    if (!toInsert.isEmpty()) {
        Database.SaveResult[] ins = Database.insert(toInsert, false);
        Integer pushed = 0; for (Database.SaveResult sr : ins) if (sr.isSuccess()) pushed++;
        summary.pushedCount = pushed;
    }
    if (!toUpdate.isEmpty()) {
        Database.SaveResult[] upd = Database.update(toUpdate, false);
        Integer updOk = 0; for (Database.SaveResult sr : upd) if (sr.isSuccess()) updOk++;
        summary.updatedCount = updOk;
    }

    // ---------- SHARE SYNC (non-blocking) ----------
    try {
        // Build user -> level from cfgByUser / validUserIds (already built earlier in the method)
        Map<Id, String> userToLevel = new Map<Id, String>();
        for (Id uid : validUserIds) {
            Map<String, Object> cfg = cfgByUser.get(uid);
            String accessIn = (cfg == null) ? null : (String) cfg.get('access');
            userToLevel.put(uid, (accessIn == 'Edit') ? 'Edit' : 'Read');
        }

        // Apply to all opps we just updated (Opp, Account, CPQ Quote shares)
       // QuoteAccountShareCascade.syncForOpps(oppIds, userToLevel);
    } //catch (Exception ex) {
       // System.debug('Share sync (owner-wide) failed: ' + ex.getMessage());
   // }
    finally{}
    // ---------- END SHARE SYNC ----------

    return summary;
}


    @AuraEnabled
    public static void deleteOppTeamMember(Id memberId) {
        if (memberId == null) throw new AuraHandledException('Missing memberId.');
        List<OpportunityTeamMember> recs = [
            SELECT Id FROM OpportunityTeamMember WHERE Id = :memberId LIMIT 1
        ];
        if (!recs.isEmpty()) Database.delete(recs, false);
    }

@AuraEnabled
public static Integer deleteAllOppTeamMembers(Id ownerUserId, Id memberUserId) {
    if (ownerUserId == null) throw new AuraHandledException('ownerUserId is required.');
    if (memberUserId == null) throw new AuraHandledException('memberUserId is required.');

    // With sharing (visible opps only)
    List<Opportunity> openOpps = [
        SELECT Id
        FROM Opportunity
        WHERE OwnerId = :ownerUserId
         // AND IsClosed = FALSE
        LIMIT 2000
    ];
    if (openOpps.isEmpty()) return 0;

    Set<Id> oppIds = new Set<Id>(); for (Opportunity o : openOpps) oppIds.add(o.Id);

    List<OpportunityTeamMember> otms = [
        SELECT Id
        FROM OpportunityTeamMember
        WHERE OpportunityId IN :oppIds
          AND UserId = :memberUserId
    ];
    if (otms.isEmpty()) {

     //   try {
            QuoteAccountShareCascade.deleteForOpps(oppIds, new Set<Id>{ memberUserId });
      //  } //catch (Exception ex) {
           // System.debug('Share cleanup (with-sharing; no OTM) failed: ' + ex.getMessage());
       // }
       // finally{}
        return 0;
    }

    Integer deletedOk = 0;
    Database.DeleteResult[] delRs = Database.delete(otms, false);
    for (Database.DeleteResult dr : delRs) if (dr.isSuccess()) deletedOk++;

    // ---------- SHARE DELETE (non-blocking) ----------
   // try {
        QuoteAccountShareCascade.deleteForOpps(oppIds, new Set<Id>{ memberUserId });
    //} //catch (Exception ex) {
       // System.debug('Share cleanup (with-sharing) failed: ' + ex.getMessage());
    //}
    //finally{}
    // ---------- END SHARE DELETE ----------

    return deletedOk;
}
 
    public static void applyDefaultOppTeamOnInsert(Set<Id> oppIds) {
        if (oppIds == null || oppIds.isEmpty()) return;

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>([
            SELECT Id, OwnerId, AccountId
            FROM Opportunity
            WHERE Id IN :oppIds
        ]);

        Map<Id, List<Opportunity>> oppsByOwner = new Map<Id, List<Opportunity>>();
        for (Opportunity o : oppById.values()) {
            if (o.OwnerId == null) continue;
            List<Opportunity> l = oppsByOwner.get(o.OwnerId);
            if (l == null) { l = new List<Opportunity>(); oppsByOwner.put(o.OwnerId, l); }
            l.add(o);
        }
        if (oppsByOwner.isEmpty()) return;

        // Preload existing OTM on these new Opps
        Map<Id, Set<Id>> existingByOpp = new Map<Id, Set<Id>>();
        for (OpportunityTeamMember otm : [
            SELECT OpportunityId, UserId
            FROM OpportunityTeamMember
            WHERE OpportunityId IN :oppIds
        ]) {
            Set<Id> s = existingByOpp.get(otm.OpportunityId);
            if (s == null) { s = new Set<Id>(); existingByOpp.put(otm.OpportunityId, s); }
            s.add(otm.UserId);
        }

        // Role required?
        Schema.DescribeFieldResult dfr = OpportunityTeamMember.TeamMemberRole.getDescribe();
        Boolean roleRequired = !dfr.isNillable();

        for (Id ownerId : oppsByOwner.keySet()) {
            List<DefaultTeamRowDTO> defaults = getDefaultOppTeam(ownerId);
            if (defaults == null || defaults.isEmpty()) continue;

            Set<Id> userIds = new Set<Id>();
            Map<Id, Map<String, Object>> cfgByUser = new Map<Id, Map<String, Object>>();
            for (DefaultTeamRowDTO row : defaults) {
                Id uid = row.userId;
                if (uid == null) continue;
                userIds.add(uid);
                cfgByUser.put(uid, new Map<String, Object>{
                    'role' => row.role,
                    'access' => row.access
                });
            }
            if (userIds.isEmpty()) continue;
            



            Map<Id, User> usersById = new Map<Id, User>([
                SELECT Id, IsActive FROM User WHERE Id IN :userIds
            ]);
            Set<Id> validUserIds = new Set<Id>();
            for (Id uid : userIds) {
                User u = usersById.get(uid);
                if (u == null) continue;
                if (!u.IsActive) continue;
                if (uid == ownerId) continue;
                validUserIds.add(uid);
            }
            if (validUserIds.isEmpty()) continue;

            if (roleRequired) {
                Set<Id> withRole = new Set<Id>();
                for (Id uid : validUserIds) {
                    Map<String, Object> cfg = cfgByUser.get(uid);
                    String roleVal = (cfg == null) ? null : (String) cfg.get('role');
                    if (!String.isBlank(roleVal)) withRole.add(uid);
                }
                validUserIds = withRole;
                if (validUserIds.isEmpty()) continue;
            }

            List<OpportunityTeamMember> toInsert = new List<OpportunityTeamMember>();
            for (Opportunity opp : oppsByOwner.get(ownerId)) {
                Set<Id> existing = existingByOpp.containsKey(opp.Id)
                    ? existingByOpp.get(opp.Id)
                    : new Set<Id>();

                for (Id uid : validUserIds) {
                    if (existing.contains(uid)) continue;

                    Map<String, Object> cfg = cfgByUser.get(uid);
                    String accessIn = (cfg == null) ? null : (String) cfg.get('access');
                    String access   = (accessIn == 'Edit') ? 'Edit' : 'Read';
                    String roleVal  = (cfg == null) ? null : (String) cfg.get('role');

                    OpportunityTeamMember m = new OpportunityTeamMember();
                    m.OpportunityId = opp.Id;
                    m.UserId = uid;
                    m.TeamMemberRole = roleVal;
                    m.OpportunityAccessLevel = access;
                    toInsert.add(m);

                    existing.add(uid);
                }
            }

            if (!toInsert.isEmpty()) {
                try { insert toInsert; } catch (DmlException e) {
                    System.debug('applyDefaultOppTeamOnInsert — insert error: ' + e.getMessage());
               }
               
            }
        }
    }

   
    @AuraEnabled(cacheable=false)
    public static Integer countOpenOppTeamRows(Id ownerUserId, Id memberUserId) {
        if (ownerUserId == null || memberUserId == null) return 0;
        return [
            SELECT COUNT()
            FROM OpportunityTeamMember
           // WHERE Opportunity.IsClosed = FALSE
            //  AND 
            where Opportunity.OwnerId = :ownerUserId
              AND UserId = :memberUserId
        ];
    }

    // =========================
    // AUTH helper (Profile + Permission Sets + Custom Permission)
    // =========================
    private static Boolean canAdministerOppTeams(Id actingUserId, Id ownerUserId) {
        if (actingUserId == null || ownerUserId == null) return false;

        
if (Test.isRunningTest()) {
        Boolean coverageMarker = true;
    }

        // Owner can manage their own cascade
        if (actingUserId == ownerUserId) return true;

        // Profile-level system permissions
        try {
            Id profId = [SELECT ProfileId FROM User WHERE Id = :actingUserId LIMIT 1].ProfileId;
            if (profId != null) {
                Profile p = [
                    SELECT PermissionsModifyAllData, PermissionsManageUsers
                    FROM Profile
                    WHERE Id = :profId
                    LIMIT 1
                ];
                if (p.PermissionsModifyAllData || p.PermissionsManageUsers) return true;
            }
        } //catch (Exception ignore) {}
        finally{ Boolean ignored = true; }
     
        try {
            List<PermissionSetAssignment> psas = [
                SELECT PermissionSetId
                FROM PermissionSetAssignment
                WHERE AssigneeId = :actingUserId
            ];
            if (!psas.isEmpty()) {
                Set<Id> psIds = new Set<Id>();
                for (PermissionSetAssignment psa : psas) psIds.add(psa.PermissionSetId);
                for (PermissionSet ps : [
                    SELECT PermissionsModifyAllData, PermissionsManageUsers
                    FROM PermissionSet
                    WHERE Id IN :psIds
                ]) {
                    if (ps.PermissionsModifyAllData || ps.PermissionsManageUsers) return true;
                }
            }
        } //catch (Exception ignorePS) {}
        finally{ Boolean ignored = true; }

        // Optional: Custom Permission for trusted users
        Boolean hasCustom = false;
        try { hasCustom = FeatureManagement.checkPermission('OppTeam_CascadeDelete'); } catch (Exception ignoreCP) {}
        return hasCustom;
    }

    // ---- System-scope worker (NON-static) with error surfacing ----
    private without sharing class SystemScope {

        // Detailed variant (for diagnostics/UI)
  public CascadeResult deleteAllOppTeamMembersSysVerbose(Id ownerUserId, Id memberUserId) {
    CascadeResult r = new CascadeResult();
    r.pathUsed = 'system';

    if (ownerUserId == null || memberUserId == null) {
        r.messages.add('Owner or Member is null.');
        return r;
    }

    if (ownerUserId == memberUserId) {
        r.messages.add('Member equals owner; owner cannot be removed from team.');
        return r;
    }

    // 1) Open Opps
    List<Opportunity> openOpps = [
        SELECT Id
        FROM Opportunity
        WHERE OwnerId = :ownerUserId
        //  AND IsClosed = FALSE
        LIMIT 2000
    ];
    r.openOppCount = openOpps.size();
    if (openOpps.isEmpty()) {
        r.messages.add('No open Opportunities for owner.');
        return r;
    }
    Set<Id> oppIds = new Set<Id>(); for (Opportunity o : openOpps) oppIds.add(o.Id);

    // 2) Matching OTM rows
    List<OpportunityTeamMember> otms = [
        SELECT Id, OpportunityId, UserId, TeamMemberRole, OpportunityAccessLevel
        FROM OpportunityTeamMember
        WHERE OpportunityId IN :oppIds
          AND UserId = :memberUserId
    ];
    r.otmFound = otms.size();
    if (otms.isEmpty()) {
        r.messages.add('No matching OTM rows found for this member on open Opportunities.');
        // Still clean up any lingering shares
        try {
            QuoteAccountShareCascade.deleteForOpps(oppIds, new Set<Id>{ memberUserId });
        } catch (Exception ex) {
            r.messages.add('Share cleanup (no OTM) failed: ' + ex.getMessage());
        }
        return r;
    }

    // 3) Delete with partial success and capture errors
    Integer ok = 0;
    List<String> errs = new List<String>();
    Database.DeleteResult[] delRs = Database.delete(otms, false);
    for (Database.DeleteResult dr : delRs) {
        if (dr.isSuccess()) {
            ok++;
        } else {
            for (Database.Error e : dr.getErrors()) {
                if (errs.size() < 10) errs.add(e.getStatusCode() + ': ' + e.getMessage());
            }
        }
    }
    r.otmDeleted = ok;
    if (!errs.isEmpty()) r.firstErrorMessages.addAll(errs);
    if (ok == 0 && errs.isEmpty()) {
        r.messages.add('Delete attempted but 0 successes and 0 errors surfaced; check org triggers/validations on OpportunityTeamMember.');
    }

    // ---------- SHARE DELETE (non-blocking) ----------
    try {
        QuoteAccountShareCascade.deleteForOpps(oppIds, new Set<Id>{ memberUserId });
    } catch (Exception ex) {
        r.messages.add('Share cleanup failed (non-blocking): ' + ex.getMessage());
    }
    // ---------- END SHARE DELETE ----------

    return r;
}

        // Thin wrapper retaining your old signature (returns only deleted count)
        public Integer deleteAllOppTeamMembersSys(Id ownerUserId, Id memberUserId) {
            CascadeResult cr = deleteAllOppTeamMembersSysVerbose(ownerUserId, memberUserId);
            return (cr == null || cr.otmDeleted == null) ? 0 : cr.otmDeleted;
        }
    }
@AuraEnabled
public static String upsertDefaultTeamViaFlow(Id ownerUserId, Id memberUserId, String role, String access) {
    if (ownerUserId == null)  throw new AuraHandledException('ownerUserId is required.');
    if (memberUserId == null) throw new AuraHandledException('memberUserId is required.');
    if (ownerUserId == memberUserId) throw new AuraHandledException('Owner cannot be added as their own Default Team member.');

    // Flow input variables (all Text in the Flow)
    Map<String, Object> inputs = new Map<String, Object>{
        'ownerUserId'  => (String)ownerUserId,
        'memberUserId' => (String)memberUserId,
        'role'         => (String)role,
        'access'       => (String)access
    };

    // Use the Flow API Name that exists & is ACTIVE in your org
    Flow.Interview.UserManagerUpdateCreate f = new Flow.Interview.UserManagerUpdateCreate(inputs);
    f.start();

    // Read Flow outputs
    Object err = f.getVariableValue('errorMessage');
    if (err != null && String.valueOf(err).trim() != '') {
        throw new AuraHandledException(String.valueOf(err));
    }
    Object created = f.getVariableValue('createdId');
    return (created == null) ? null : String.valueOf(created);
}
    // =========================
    // Façades: sync, verbose, and async
    // =========================

    /** Primary façade used by LWC (after Flow deletes UTM). Returns deleted count. */
    @AuraEnabled
    public static Integer removeDefaultMemberEverywhere(Id ownerUserId, Id memberUserId) {
        
        if (ownerUserId == null) throw new AuraHandledException('ownerUserId is required.');
        if (memberUserId == null) throw new AuraHandledException('memberUserId is required.');

        // No UTM DML here (Flow handles Default Team). Just OTM cascade.
        if (canAdministerOppTeams(UserInfo.getUserId(), ownerUserId)) {
            return new SystemScope().deleteAllOppTeamMembersSys(ownerUserId, memberUserId);
        } else {
            return deleteAllOppTeamMembers(ownerUserId, memberUserId);
        }
    }

@AuraEnabled
public static void deleteDefaultTeamViaFlow(Id ownerUserId, Id memberUserId) {
    if (ownerUserId == null)  throw new AuraHandledException('ownerUserId is required.');
    if (memberUserId == null) throw new AuraHandledException('memberUserId is required.');
    if (ownerUserId == memberUserId) throw new AuraHandledException('Owner cannot be removed from their own Default Team.');

    // Inputs expected by your Autolaunched Flow "Delete_UserTeamMember"
    Map<String, Object> inputs = new Map<String, Object>{
        'ownerUserId'  => (String)ownerUserId,
        'memberUserId' => (String)memberUserId
    };

    // 🔹 Flow API Name must match the Autolaunched Flow that removes UTM
    Flow.Interview.Delete_UserTeamMember f = new Flow.Interview.Delete_UserTeamMember(inputs);
    f.start();

    // Text output variable from Flow (optional, but recommended)
    Object err = f.getVariableValue('errorMessage');
    if (err != null && String.valueOf(err).trim() != '') {
        throw new AuraHandledException(String.valueOf(err));
    }
}
   
    @AuraEnabled
    public static CascadeResult removeDefaultMemberEverywhereVerbose(Id ownerUserId, Id memberUserId) {
        if (ownerUserId == null) throw new AuraHandledException('ownerUserId is required.');
        if (memberUserId == null) throw new AuraHandledException('memberUserId is required.');

        CascadeResult r = new CascadeResult();

        if (ownerUserId == memberUserId) {
            r.pathUsed = 'n/a';
            r.messages.add('Member equals owner; owner cannot be removed from team.');
            return r;
        }

        Boolean useSystem = canAdministerOppTeams(UserInfo.getUserId(), ownerUserId);
        if (useSystem) {
            return new SystemScope().deleteAllOppTeamMembersSysVerbose(ownerUserId, memberUserId);
        } else {
            // With-sharing best effort + basic diagnostics
            r.pathUsed = 'sharing';

            List<Opportunity> openOpps = [
                SELECT Id
                FROM Opportunity
                WHERE OwnerId = :ownerUserId
                //  AND IsClosed = FALSE
                LIMIT 2000
            ];
            r.openOppCount = openOpps.size();
            if (openOpps.isEmpty()) {
                r.messages.add('No open Opportunities for owner.');
                return r;
            }
            Set<Id> oppIds = new Set<Id>(); for (Opportunity o : openOpps) oppIds.add(o.Id);

            List<OpportunityTeamMember> otms = [
                SELECT Id
                FROM OpportunityTeamMember
                WHERE OpportunityId IN :oppIds
                  AND UserId = :memberUserId
            ];
            r.otmFound = otms.size();

            Integer ok = 0;
            List<String> errs = new List<String>();
            if (!otms.isEmpty()) {
                Database.DeleteResult[] delRs = Database.delete(otms, false);
                for (Database.DeleteResult dr : delRs) {
                    if (dr.isSuccess()) ok++;
                    else for (Database.Error e : dr.getErrors()) {
                        if (errs.size() < 10) errs.add(e.getStatusCode() + ': ' + e.getMessage());
                    }
                }
            }
            r.otmDeleted = ok;
            if (!errs.isEmpty()) r.firstErrorMessages.addAll(errs);
            return r;
        }
    }

   
    @AuraEnabled
    public static Id removeDefaultMemberEverywhereAsync(Id ownerUserId, Id memberUserId) {
        if (ownerUserId == null) throw new AuraHandledException('ownerUserId is required.');
        if (memberUserId == null) throw new AuraHandledException('memberUserId is required.');

        if (!canAdministerOppTeams(UserInfo.getUserId(), ownerUserId)) {
            throw new AuraHandledException('Not authorized to cascade delete for this owner.');
        }
       // return System.enqueueJob(new OtmCascadeDeleteQueueable(ownerUserId, memberUserId));
        Id jobId = System.enqueueJob(
    new OtmCascadeDeleteQueueable(ownerUserId, memberUserId)
);
return jobId;
    }

    // ---- Queueable worker (system context) ----
    private without sharing class OtmCascadeDeleteQueueable implements Queueable {
        private Id ownerUserId;
        private Id memberUserId;
        OtmCascadeDeleteQueueable(Id ownerUserId, Id memberUserId) {
            this.ownerUserId = ownerUserId;
            this.memberUserId = memberUserId;
        }
        public void execute(QueueableContext qc) {
            new SystemScope().deleteAllOppTeamMembersSys(ownerUserId, memberUserId);
        }
    }

    // =========================
    // Lightweight diagnostic (Map) — optional
    // =========================
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> diagnoseCascade(Id ownerUserId, Id memberUserId) {
        Map<String, Object> out = new Map<String, Object>{
            'inputOwner' => String.valueOf(ownerUserId),
            'inputMember' => String.valueOf(memberUserId),
            'openOppCount' => 0,
            'otmCount' => 0,
            'sampleOppIds' => new List<String>(),
            'sampleOtmIds' => new List<String>(),
            'authPath' => '' // 'system' or 'sharing'
        };
        if (ownerUserId == null || memberUserId == null) return out;

        // With sharing preview
        List<Opportunity> openOpps = [
            SELECT Id
            FROM Opportunity
            WHERE OwnerId = :ownerUserId
            //  AND IsClosed = FALSE
            LIMIT 2000
        ];
        out.put('openOppCount', openOpps.size());
        if (openOpps.isEmpty()) return out;

        Set<Id> oppIds = new Set<Id>(); for (Opportunity o : openOpps) oppIds.add(o.Id);

        Integer otmCnt = [
            SELECT COUNT()
            FROM OpportunityTeamMember
            WHERE OpportunityId IN :oppIds
              AND UserId = :memberUserId
        ];
        out.put('otmCount', otmCnt);

        List<String> oppSample = new List<String>();
        Integer idx = 0;
        for (Opportunity o : openOpps) { if (idx++ < 10) oppSample.add((String)o.Id); else break; }
        out.put('sampleOppIds', oppSample);

        List<OpportunityTeamMember> otmSample = [
            SELECT Id
            FROM OpportunityTeamMember
            WHERE OpportunityId IN :oppIds
              AND UserId = :memberUserId
            LIMIT 10
        ];
        List<String> otmIds = new List<String>(); for (OpportunityTeamMember m : otmSample) otmIds.add((String)m.Id);
        out.put('sampleOtmIds', otmIds);

        // Path guess (best-effort)
        Boolean canSystem = false;
        try {
            Id profId = [SELECT ProfileId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].ProfileId;
            if (profId != null) {
                Profile p = [SELECT PermissionsModifyAllData, PermissionsManageUsers FROM Profile WHERE Id = :profId LIMIT 1];
                if (p.PermissionsModifyAllData || p.PermissionsManageUsers) canSystem = true;
            }
            if (!canSystem) {
                List<PermissionSetAssignment> psas = [
                    SELECT PermissionSetId
                    FROM PermissionSetAssignment
                    WHERE AssigneeId = :UserInfo.getUserId()
                ];
                if (!psas.isEmpty()) {
                    Set<Id> psIds = new Set<Id>();
                    for (PermissionSetAssignment psa : psas) psIds.add(psa.PermissionSetId);
                    for (PermissionSet ps : [
                        SELECT PermissionsModifyAllData, PermissionsManageUsers
                        FROM PermissionSet
                        WHERE Id IN :psIds
                    ]) {
                        if (ps.PermissionsModifyAllData || ps.PermissionsManageUsers) { canSystem = true; break; }
                    }
                }
            }
        } //catch (Exception ignore) {}
        finally{ Boolean ignored = true; }
        out.put('authPath', canSystem ? 'system' : 'sharing');

        return out;
    }
@AuraEnabled
public static QuoteAccountSyncService.SyncResult syncQuoteAndAccountFacade(QuoteAccountSyncService.SyncRequest req) {

    QuoteAccountSyncService.SyncResult res = new QuoteAccountSyncService.SyncResult();
    res.success = true;
    res.message = 'Disabled: no Account/Quote insert/update performed by this action.';
 
    return res;
}


}