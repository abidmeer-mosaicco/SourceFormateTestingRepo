public without sharing class OppTeamOwnerCleanup {

    @TestVisible
    private static Map<Id, Set<Id>> testOwnerTeams;

    public class Request {

        @InvocableVariable(required=true)
        public Id opportunityId;

        @InvocableVariable(required=true)
        public Id oldOwnerId;

        @InvocableVariable(required=true)
        public Id newOwnerId;
    }

    @InvocableMethod(label='Cleanup Old Owner Team')
    public static void cleanup(List<Request> requests) {

        if (requests == null || requests.isEmpty()) {
            return;
        }

        List<OpportunityTeamMember> otmsToDelete =
            new List<OpportunityTeamMember>();

        List<SBQQ__Quote__Share> quoteSharesToDelete =
            new List<SBQQ__Quote__Share>();

        for (Request req : requests) {

            if (req == null ||
                req.opportunityId == null ||
                req.oldOwnerId == null ||
                req.newOwnerId == null) {
                continue;
            }

            Set<Id> oldOwnerUsers = new Set<Id>();
            Set<Id> newOwnerUsers = new Set<Id>();

            // Include owners themselves
            oldOwnerUsers.add(req.oldOwnerId);
            newOwnerUsers.add(req.newOwnerId);

            // Old Owner Team
            if (Test.isRunningTest() && testOwnerTeams != null) {

                if (testOwnerTeams.containsKey(req.oldOwnerId)) {
                    oldOwnerUsers.addAll(
                        testOwnerTeams.get(req.oldOwnerId)
                    );
                }

            } else {

                for (UserTeamMember utm : [
                    SELECT UserId
                    FROM UserTeamMember
                    WHERE OwnerId = :req.oldOwnerId
                ]) {
                    oldOwnerUsers.add(utm.UserId);
                }
            }

            // New Owner Team
            if (Test.isRunningTest() && testOwnerTeams != null) {

                if (testOwnerTeams.containsKey(req.newOwnerId)) {
                    newOwnerUsers.addAll(
                        testOwnerTeams.get(req.newOwnerId)
                    );
                }

            } else {

                for (UserTeamMember utm : [
                    SELECT UserId
                    FROM UserTeamMember
                    WHERE OwnerId = :req.newOwnerId
                ]) {
                    newOwnerUsers.add(utm.UserId);
                }
            }

            // Users in old team but not in new team
            Set<Id> usersToDelete = oldOwnerUsers.clone();
            usersToDelete.removeAll(newOwnerUsers);

            if (usersToDelete.isEmpty()) {
                continue;
            }

            // Delete Opportunity Team Members
            otmsToDelete.addAll([
                SELECT Id
                FROM OpportunityTeamMember
                WHERE OpportunityId = :req.opportunityId
                AND UserId IN :usersToDelete
            ]);

            // Current Opportunity Team Users
            Set<Id> currentOppTeamUsers = new Set<Id>();

            for (OpportunityTeamMember otm : [
                SELECT UserId
                FROM OpportunityTeamMember
                WHERE OpportunityId = :req.opportunityId
            ]) {
                currentOppTeamUsers.add(otm.UserId);
            }

            // Don't delete Quote Shares for users still on team
            Set<Id> quoteUsersToDelete = usersToDelete.clone();
            quoteUsersToDelete.removeAll(currentOppTeamUsers);

            if (quoteUsersToDelete.isEmpty()) {
                continue;
            }

            // Get all Quotes related to Opportunity
            Set<Id> quoteIds = new Set<Id>();

            for (SBQQ__Quote__c quoteRec : [
                SELECT Id
                FROM SBQQ__Quote__c
                WHERE SBQQ__Opportunity2__c = :req.opportunityId
            ]) {
                quoteIds.add(quoteRec.Id);
            }

            if (!quoteIds.isEmpty()) {

                quoteSharesToDelete.addAll([
                    SELECT Id
                    FROM SBQQ__Quote__Share
                    WHERE ParentId IN :quoteIds
                    AND UserOrGroupId IN :quoteUsersToDelete
                    AND RowCause = 'Manual'
                ]);
            }
        }

        if (!otmsToDelete.isEmpty()) {
            Database.delete(otmsToDelete, false);
        }

        if (!quoteSharesToDelete.isEmpty()) {
            Database.delete(quoteSharesToDelete, false);
        }
    }
}