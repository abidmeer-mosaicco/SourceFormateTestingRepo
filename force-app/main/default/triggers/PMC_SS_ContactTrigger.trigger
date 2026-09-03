trigger PMC_SS_ContactTrigger on Contact (before insert, before update, after update, after insert) {
    new PMC_ContactTriggerHandler().run();
}