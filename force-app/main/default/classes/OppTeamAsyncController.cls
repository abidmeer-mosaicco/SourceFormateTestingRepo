public without sharing class OppTeamAsyncController {
    
   @TestVisible
private static Map<Id,String> testUserToLevel;

@AuraEnabled
public static Id runAsyncTeamSync(
    Id anchorOppId,
    Id ownerUserId,
    Map<Id, String> userToLevel
) {
    if (userToLevel == null || userToLevel.isEmpty()) {
        throw new AuraHandledException('Missing userToLevel');
    }

    if (ownerUserId == null) {
        throw new AuraHandledException('Missing ownerUserId');
    }

    OppTeamReplicationService.Targets t =
        OppTeamReplicationService.findTargetsForOwner(ownerUserId);

    if (t.opportunityIds.isEmpty()) {
        System.debug('No opps for owner → nothing to do');
        return null;
    }

    List<OppTeamReplicationService.Change> changes =
        new List<OppTeamReplicationService.Change>();

    for (Id oppId : t.opportunityIds) {

        for (Id uid : userToLevel.keySet()) {

            changes.add(
                new OppTeamReplicationService.Change(
                    oppId,
                    uid,
                    userToLevel.get(uid),
                    'UPSERT'
                )
            );
        }
    }

    return System.enqueueJob(
        new OppTeamReplicationJob(changes)
    );
}
    @AuraEnabled
public static Id runAsyncTeamSyncForOwnerChange(
    Id anchorOppId,
    Id ownerUserId,
    Map<Id,String> userToLevel
) {

    if (userToLevel == null || userToLevel.isEmpty()) {
        throw new AuraHandledException('Missing userToLevel');
    }

    if (ownerUserId == null) {
        throw new AuraHandledException('Missing ownerUserId');
    }

    OppTeamReplicationService.Targets t =
        OppTeamReplicationService.findAnchorOnlyTargets(anchorOppId);

    if (t.opportunityIds.isEmpty()) {
        return null;
    }

    List<OppTeamReplicationService.Change> changes =
        new List<OppTeamReplicationService.Change>();

    for (Id oppId : t.opportunityIds) {

        for (Id uid : userToLevel.keySet()) {

           OppTeamReplicationService.Change c =
    new OppTeamReplicationService.Change(
        oppId,
        uid,
        userToLevel.get(uid),
        'UPSERT'
    );

c.isOwnerChange = true;

changes.add(c);
        }
    }

    return System.enqueueJob(
        new OppTeamReplicationJob(changes)
    );
}
 /* @InvocableMethod(label='Run Opp Team Sync From Owner')
public static void runFromOwner(List<Id> ownerIds) {

    if (ownerIds == null || ownerIds.isEmpty()) return;

    for (Id ownerId : ownerIds) {

        if (ownerId == null) continue;

        Map<Id, String> userToLevel = new Map<Id, String>();

        for (UserTeamMember utm : [
            SELECT UserId, OpportunityAccessLevel
            FROM UserTeamMember
            WHERE OwnerId = :ownerId
        ]) {
            userToLevel.put(utm.UserId, utm.OpportunityAccessLevel);
        }

        if (userToLevel.isEmpty()) continue;

        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            WHERE OwnerId = :ownerId
            LIMIT 1
        ];

        if (opp == null) continue;

        runAsyncTeamSync(opp.Id, ownerId, userToLevel);
    }
}
*/
 @InvocableMethod(label='Run Opp Team Sync')
public static void runFromOpportunity(List<Id> opportunityIds) {

    if (opportunityIds == null || opportunityIds.isEmpty()) return;

    for (Id oppId : opportunityIds) {

        Opportunity opp = [
            SELECT Id, OwnerId
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];

      /*  Map<Id, String> userToLevel = new Map<Id, String>();

        for (UserTeamMember utm : [
            SELECT UserId, OpportunityAccessLevel
            FROM UserTeamMember
            WHERE OwnerId = :opp.OwnerId
        ]) {
            userToLevel.put(
                utm.UserId,
                utm.OpportunityAccessLevel
            );
        }*/
        Map<Id, String> userToLevel = new Map<Id, String>();

if(Test.isRunningTest() &&
   testUserToLevel != null) {

    userToLevel.putAll(testUserToLevel);

} else {

    for (UserTeamMember utm : [
        SELECT UserId, OpportunityAccessLevel
        FROM UserTeamMember
        WHERE OwnerId = :opp.OwnerId
    ]) {
        userToLevel.put(
            utm.UserId,
            utm.OpportunityAccessLevel
        );
    }
}

        if (userToLevel.isEmpty()) continue;

       runAsyncTeamSyncForOwnerChange(
    opp.Id,
    opp.OwnerId,
    userToLevel
);
    }
}
}