public without sharing class TrackTraceController {

    @AuraEnabled(cacheable=true)
    public static Datetime getLastIntegrationUpdate() {

        AsyncApexJob job = [
            SELECT CompletedDate
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'PMC_IntellitransShipmentBatchUpdate'
            AND Status = 'Completed'
            AND CompletedDate != null
            ORDER BY CompletedDate DESC
            LIMIT 1
        ] ?? null;

        return job != null ? job.CompletedDate : null;
    }
}