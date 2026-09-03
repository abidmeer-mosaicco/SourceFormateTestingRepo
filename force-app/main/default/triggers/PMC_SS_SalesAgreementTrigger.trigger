/**
 * @description This trigger is created on sales agreement object.
 * @author Swakeerth Gadda
 * @storynumber GDASF-7712
 */
 
trigger PMC_SS_SalesAgreementTrigger on SalesAgreement (before insert, before update) {
    new PMC_SS_SalesAgreementHandler().run();
}