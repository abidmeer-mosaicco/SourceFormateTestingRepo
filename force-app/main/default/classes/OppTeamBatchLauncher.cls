public class OppTeamBatchLauncher implements Queueable {

    private Id ownerId;

    public OppTeamBatchLauncher(Id ownerId) {
        this.ownerId = ownerId;
    }

    public void execute(QueueableContext qc) {

        Integer running = [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND Status IN ('Processing','Preparing')
        ];

        if (running > 0) {
            return;
        }

        if (ownerId == null) {
            return;
        }

        Database.executeBatch(
            new OppTeamFinalBackfillBatch(new Set<Id>{ ownerId }),
            20
        );
    }
}