public without sharing class md_cdlTriggerHandler extends PMC_TriggerHandler {

    private final List<ContentDocumentLink> newRecords;

    public md_cdlTriggerHandler() {
        this.newRecords = (List<ContentDocumentLink>) Trigger.new;
    }

    protected override void beforeInsert() {
        md_cdlTriggerService.fixQuoteFileVisibility(this.newRecords);
    }
}