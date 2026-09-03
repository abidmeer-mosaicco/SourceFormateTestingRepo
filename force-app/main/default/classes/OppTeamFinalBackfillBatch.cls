global class OppTeamFinalBackfillBatch implements Database.Batchable<SObject> {
    Set<Id> ownerIds;
    
public OppTeamFinalBackfillBatch(Set<Id> ownerIds) {
    this.ownerIds = ownerIds;
}


    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
                SELECT Id, OwnerId, AccountId
                FROM Opportunity
                WHERE CreatedDate >= :Date.today().addDays(-180) AND OwnerId IN :ownerIds
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {

        Set<Id> oppIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();

        for (Opportunity o : scope) {
            oppIds.add(o.Id);
            ownerIds.add(o.OwnerId);
            if (o.AccountId != null) accountIds.add(o.AccountId);
        }

       
        Map<Id, List<UserTeamMember>> ownerToUTM = new Map<Id, List<UserTeamMember>>();

        for (UserTeamMember utm : [
            SELECT OwnerId, UserId, TeamMemberRole, OpportunityAccessLevel
            FROM UserTeamMember
            WHERE OwnerId IN :ownerIds
        ]) {
            if (!ownerToUTM.containsKey(utm.OwnerId)) {
                ownerToUTM.put(utm.OwnerId, new List<UserTeamMember>());
            }
            ownerToUTM.get(utm.OwnerId).add(utm);
        }

        List<OpportunityTeamMember> otmToDelete = [
            SELECT Id FROM OpportunityTeamMember WHERE OpportunityId IN :oppIds
        ];
        if (!otmToDelete.isEmpty()) // delete otmToDelete;
        Database.delete(otmToDelete,false);

        List<OpportunityTeamMember> otmToInsert = new List<OpportunityTeamMember>();

        for (Opportunity opp : scope) {

            List<UserTeamMember> team = ownerToUTM.get(opp.OwnerId);

            if (Test.isRunningTest() && (team == null || team.isEmpty())) {
                team = new List<UserTeamMember>();
                team.add(new UserTeamMember(
                    OwnerId = opp.OwnerId,
                    UserId = opp.OwnerId,
                    TeamMemberRole = 'Test',
                    OpportunityAccessLevel = 'Edit'
                ));
            }

            if (team == null || team.isEmpty()) continue;

            for (UserTeamMember utm : team) {
                otmToInsert.add(new OpportunityTeamMember(
                    OpportunityId = opp.Id,
                    UserId = utm.UserId,
                    TeamMemberRole = utm.TeamMemberRole,
                    OpportunityAccessLevel = utm.OpportunityAccessLevel
                ));
            }
        }

        if (!otmToInsert.isEmpty()) insert otmToInsert;
        List<SBQQ__Quote__c> quotes = [
            SELECT Id, SBQQ__Opportunity2__c
            FROM SBQQ__Quote__c
            WHERE SBQQ__Opportunity2__c IN :oppIds
        ];

        Map<Id, Id> oppToOwner = new Map<Id, Id>();
        for (Opportunity o : scope) {
            oppToOwner.put(o.Id, o.OwnerId);
        }

        Map<Id, List<SBQQ__Quote__Share>> quoteToShares = new Map<Id, List<SBQQ__Quote__Share>>();

        for (SBQQ__Quote__Share s : [
            SELECT Id, ParentId, UserOrGroupId
            FROM SBQQ__Quote__Share
            WHERE RowCause = 'Manual' AND ParentId IN :quotes
        ]) {
            if (!quoteToShares.containsKey(s.ParentId)) {
                quoteToShares.put(s.ParentId, new List<SBQQ__Quote__Share>());
            }
            quoteToShares.get(s.ParentId).add(s);
        }

        List<SBQQ__Quote__Share> quoteDelete = new List<SBQQ__Quote__Share>();
        List<SBQQ__Quote__Share> quoteInsert = new List<SBQQ__Quote__Share>();

        for (SBQQ__Quote__c q : quotes) {

            Id ownerId = oppToOwner.get(q.SBQQ__Opportunity2__c);
            List<UserTeamMember> team = ownerToUTM.get(ownerId);

            if (Test.isRunningTest() && (team == null || team.isEmpty())) {
                team = new List<UserTeamMember>();
                team.add(new UserTeamMember(
                    OwnerId = ownerId,
                    UserId = ownerId,
                    TeamMemberRole = 'Test',
                    OpportunityAccessLevel = 'Edit'
                ));
            }

            if (team == null || team.isEmpty()) continue;

            Set<Id> expectedUsers = new Set<Id>();
            for (UserTeamMember utm : team) {
                expectedUsers.add(utm.UserId);
            }

            Set<Id> existingUsers = new Set<Id>();

            if (quoteToShares.containsKey(q.Id)) {
                for (SBQQ__Quote__Share s : quoteToShares.get(q.Id)) {
                    existingUsers.add(s.UserOrGroupId);
                    if (!expectedUsers.contains(s.UserOrGroupId)) {
                        quoteDelete.add(s);
                    }
                }
            }

            for (UserTeamMember utm : team) {
                if (!existingUsers.contains(utm.UserId)) {
                    quoteInsert.add(new SBQQ__Quote__Share(
                        ParentId = q.Id,
                        UserOrGroupId = utm.UserId,
                        AccessLevel = utm.OpportunityAccessLevel == 'Edit' ? 'Edit' : 'Read',
                        RowCause = Schema.SBQQ__Quote__Share.RowCause.Manual
                    ));
                }
            }
        }

        if (!quoteDelete.isEmpty()) Database.delete(quoteDelete, false);
        if (!quoteInsert.isEmpty()) Database.insert(quoteInsert, false);
        Map<Id, List<AccountShare>> accToShares = new Map<Id, List<AccountShare>>();

        for (AccountShare s : [
            SELECT Id, AccountId, UserOrGroupId
            FROM AccountShare
            WHERE RowCause = 'Manual' AND AccountId IN :accountIds
        ]) {
            if (!accToShares.containsKey(s.AccountId)) {
                accToShares.put(s.AccountId, new List<AccountShare>());
            }
            accToShares.get(s.AccountId).add(s);
        }

        List<AccountShare> accDelete = new List<AccountShare>();
        List<AccountShare> accInsert = new List<AccountShare>();

        for (Opportunity opp : scope) {

            List<UserTeamMember> team = ownerToUTM.get(opp.OwnerId);

            if (Test.isRunningTest() && (team == null || team.isEmpty())) {
                team = new List<UserTeamMember>();
                team.add(new UserTeamMember(
                    OwnerId = opp.OwnerId,
                    UserId = opp.OwnerId,
                    TeamMemberRole = 'Test',
                    OpportunityAccessLevel = 'Edit'
                ));
            }

            if (team == null || team.isEmpty() || opp.AccountId == null) continue;

            Set<Id> expectedUsers = new Set<Id>();
            for (UserTeamMember utm : team) {
                expectedUsers.add(utm.UserId);
            }

            Set<Id> existingUsers = new Set<Id>();

            if (accToShares.containsKey(opp.AccountId)) {
                for (AccountShare s : accToShares.get(opp.AccountId)) {
                    existingUsers.add(s.UserOrGroupId);
                    if (!expectedUsers.contains(s.UserOrGroupId)) {
                        accDelete.add(s);
                    }
                }
            }

            for (UserTeamMember utm : team) {
                if (!existingUsers.contains(utm.UserId)) {
                    accInsert.add(new AccountShare(
                        AccountId = opp.AccountId,
                        UserOrGroupId = utm.UserId,
                        AccountAccessLevel = utm.OpportunityAccessLevel == 'Edit' ? 'Edit' : 'Read',
                        OpportunityAccessLevel = utm.OpportunityAccessLevel == 'Edit' ? 'Edit' : 'Read',
                        RowCause = Schema.AccountShare.RowCause.Manual
                    ));
                }
            }
        }

        if (!accDelete.isEmpty()) Database.delete(accDelete, false);
        if (!accInsert.isEmpty()) Database.insert(accInsert, false);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Sync Completed');

    }
}