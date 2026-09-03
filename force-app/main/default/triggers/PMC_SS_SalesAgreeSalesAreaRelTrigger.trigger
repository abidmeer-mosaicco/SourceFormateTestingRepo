trigger PMC_SS_SalesAgreeSalesAreaRelTrigger on PMC_SalesAgreementSalesAreaRelation__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    new PMC_SS_SalesAgreeSalesAreaRelHandler().run();
}