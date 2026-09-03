/**
 * @description       : 
 * @author            : nokrause@valgroupco.com.gaugedev
 * @group             : 
 * @last modified on  : 25-06-2025
 * @last modified by  : nokrause@valgroupco.com.gaugedev
**/
public without sharing class PMC_EmailValidityBatch implements Database.Batchable<SObject>, Database.Stateful {

    private String objectName;
    private static final String EMAIL_FIELD = 'Email';
    private static final String VALID_FIELD = 'PMC_SS_EmailValid__c';

    // Fase 1: Lead, Fase 2: Contact
    public PMC_EmailValidityBatch(String objName) {
        this.objectName = objName;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        if(objectName == 'Lead') {
            return Database.getQueryLocator(
                'SELECT Id, Email FROM Lead WHERE Email != NULL'
            );
        } else {
            return Database.getQueryLocator(
                'SELECT Id, Email FROM Contact WHERE Email != NULL'
            );
        }
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<SObject> toUpdate = new List<SObject>();
        for (SObject record : scope) {
            String email = (String) record.get(EMAIL_FIELD);
            Boolean isValid = PMC_EmailValidationService.isValid(email);
            record.put(VALID_FIELD, isValid);
            toUpdate.add(record);
        }
        if(!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    public void finish(Database.BatchableContext BC) {
        // Segunda fase: dispara batch para Contact, se Lead acabou
        if(objectName == 'Lead') {
            Database.executeBatch(new PMC_EmailValidityBatch('Contact'), 200);
        }
    }
}