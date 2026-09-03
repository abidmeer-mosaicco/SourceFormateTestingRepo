public without sharing class QuoteSharingService {

    /**
     * Copy Opportunity Team Members to Quote Share
     */
	 
public class Request {
        @InvocableVariable(required=true)
        public Id opportunityId;
    }

    @InvocableMethod(
        label='Copy Opportunity Team to Quotes'
        description='Copies OpportunityTeamMember to Quote Share'
    )
    public static void flowCopyOppTeam(List<Request> requests) {
        if (requests == null) return;
        for (Request r : requests) {
            if (r == null || r.opportunityId == null) continue;
            copyOppTeamToQuotes(r.opportunityId);
        }
    }

    public static void copyOppTeamToQuotes(Id opportunityId) {
        if (opportunityId == null) return;

        // 1) Read full Opportunity Team
        Map<Id, String> userToAccess = new Map<Id, String>();
        for (OpportunityTeamMember otm : [
            SELECT UserId, OpportunityAccessLevel,user.isactive
            FROM OpportunityTeamMember
            WHERE OpportunityId = :opportunityId and user.isactive=true
        ]) {
            String lvl = otm.OpportunityAccessLevel == 'Edit' ? 'Edit' : 'Read';
            
            if (!userToAccess.containsKey(otm.UserId) || lvl == 'Edit') {
                userToAccess.put(otm.UserId, lvl);
            }
        }
        if (userToAccess.isEmpty()) return;

        // 2) Fetch Quotes for this Opportunity
        List<SBQQ__Quote__c> quotes = [
            SELECT Id
            FROM SBQQ__Quote__c
            WHERE SBQQ__Opportunity2__c = :opportunityId
        ];
        if (quotes.isEmpty()) return;

        Set<Id> quoteIds = new Set<Id>();
        for (SBQQ__Quote__c q : quotes) quoteIds.add(q.Id);

        // 3) Existing Quote Shares (avoid duplicates)
        Set<String> existingKeys = new Set<String>();
        for (SBQQ__Quote__Share s : [
            SELECT ParentId, UserOrGroupId
            FROM SBQQ__Quote__Share
            WHERE ParentId IN :quoteIds
            AND UserOrGroupId IN :userToAccess.keySet()
        ]) {
            existingKeys.add(s.ParentId + '|' + s.UserOrGroupId);
        }

        // 4) Insert missing shares
        List<SBQQ__Quote__Share> toInsert = new List<SBQQ__Quote__Share>();
        for (Id qId : quoteIds) {
            for (Id userId : userToAccess.keySet()) {
                String key = qId + '|' + userId;
                if (!existingKeys.contains(key)) {
                    toInsert.add(new SBQQ__Quote__Share(
                        ParentId      = qId,
                        UserOrGroupId = userId,
                        AccessLevel   = userToAccess.get(userId),
                        RowCause      = Schema.SBQQ__Quote__Share.RowCause.Manual
                    ));
                }
            }
        }

       // if (!toInsert.isEmpty()) insert toInsert;
       if (!toInsert.isEmpty()) {
    Database.SaveResult[] results = Database.insert(toInsert, false);

    for (Integer i = 0; i < results.size(); i++) {
        if (!results[i].isSuccess()) {
            for (Database.Error err : results[i].getErrors()) {
                System.debug(
                    LoggingLevel.ERROR,
                    'Failed to create Quote Share for Quote ' +
                    toInsert[i].ParentId +
                    ', User ' +
                    toInsert[i].UserOrGroupId +
                    '. Error: ' + err.getMessage()
                );
            }
        }
    }
}
    }
}