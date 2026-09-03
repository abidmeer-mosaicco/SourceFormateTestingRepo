trigger MD_ContentDocumentLinkTrigger on ContentDocumentLink (before insert) {
    new md_cdlTriggerHandler().run();
}