public without sharing class QuoteSharingController {

    @AuraEnabled(cacheable=true)
    public static List<QuoteShareWrapper> getQuoteShares(Id quoteId) {
        List<SBQQ__Quote__Share> shares = [
            SELECT Id, UserOrGroupId, AccessLevel,
                   UserOrGroup.Name, UserOrGroup.Type
            FROM SBQQ__Quote__Share
            WHERE ParentId = :quoteId
        ];

        List<QuoteShareWrapper> results = new List<QuoteShareWrapper>();
        for (SBQQ__Quote__Share s : shares) {
            if (s.UserOrGroup != null && s.UserOrGroup.Type == 'User') {
            QuoteShareWrapper wrapper = new QuoteShareWrapper();
            wrapper.id = s.Id;
            wrapper.name = s.UserOrGroup.Name;
            wrapper.type = s.UserOrGroup.Type;
            wrapper.accessLevel = s.AccessLevel;
            results.add(wrapper);
        }
        }
        return results;
    }

    @AuraEnabled
    public static void removeQuoteShare(Id shareId) {
        delete [SELECT Id FROM SBQQ__Quote__Share WHERE Id = :shareId];
    }

    @AuraEnabled
    public static void shareQuote(Id quoteId, Id userOrGroupId, String accessLevel) {
        List<SBQQ__Quote__Share> existing = [
            SELECT Id FROM SBQQ__Quote__Share
            WHERE ParentId = :quoteId AND UserOrGroupId = :userOrGroupId
        ];
        if (existing.isEmpty()) {
            SBQQ__Quote__Share share = new SBQQ__Quote__Share();
            share.ParentId = quoteId;
            share.UserOrGroupId = userOrGroupId;
            share.AccessLevel= accessLevel;
            share.RowCause = Schema.SBQQ__Quote__Share.RowCause.Manual;
            insert share;
        }
    }

    @AuraEnabled
    public static void updateAccessLevels(List<QuoteShareWrapper> updates) {
        List<SBQQ__Quote__Share> recordsToUpdate = new List<SBQQ__Quote__Share>();
        for (QuoteShareWrapper wrap : updates) {
            if (String.isNotBlank(wrap.id)) {
                recordsToUpdate.add(new SBQQ__Quote__Share(
                    Id = wrap.id,
                    AccessLevel = wrap.accessLevel
                ));
            }
        }
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }
    

    @AuraEnabled
    public static void removeShare(Id shareId) {
        delete [SELECT Id FROM SBQQ__Quote__Share WHERE Id = :shareId];
    }

    public class QuoteShareWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String type;
        @AuraEnabled public String accessLevel;
    }
}