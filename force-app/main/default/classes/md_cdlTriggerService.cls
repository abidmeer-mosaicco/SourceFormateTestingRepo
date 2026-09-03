public without sharing class md_cdlTriggerService {

    private static final String VISIBILITY_ALL_USERS = 'AllUsers';

    public static void fixQuoteFileVisibility(List<ContentDocumentLink> records) {
        for (ContentDocumentLink cdl : records) {
            if (cdl.LinkedEntityId == null) continue;
            if (cdl.LinkedEntityId.getSObjectType() != SBQQ__Quote__c.SObjectType) continue;
            if (cdl.Visibility == VISIBILITY_ALL_USERS) continue;

            cdl.Visibility = VISIBILITY_ALL_USERS;
        }
    }
}