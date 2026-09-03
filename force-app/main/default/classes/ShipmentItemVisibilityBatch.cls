public class ShipmentItemVisibilityBatch implements Database.Batchable<SObject> {

    private Integer batchSize;

    public ShipmentItemVisibilityBatch() {
        this(200);
    }

    public ShipmentItemVisibilityBatch(Integer batchSize) {
        this.batchSize = batchSize;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, PMC_CPQ_OrderProduct__c, isVisible__c, isFPD__c, CreatedDate
            FROM ShipmentItem
            WHERE PMC_CPQ_OrderProduct__c != null
            ORDER BY PMC_CPQ_OrderProduct__c, CreatedDate DESC
        ]);
    }

    public void execute(Database.BatchableContext bc, List<ShipmentItem> scope) {
        try {
            ShipmentItemTriggerHandler.updateVisibilityOnCreate(scope);

            Set<Id> orderItemIds = new Set<Id>();
            for (ShipmentItem item : scope) {
                if (item.PMC_CPQ_OrderProduct__c != null) {
                    orderItemIds.add(item.PMC_CPQ_OrderProduct__c);
                }
            }
            ShipmentItemTriggerHandler.recalculateActualShippedQuantity(orderItemIds);
        } catch (Exception e) {
            System.debug('Error processing batch: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }

    public void finish(Database.BatchableContext bc) {
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                   TotalJobItems, CreatedDate, CompletedDate
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()
        ];

        System.debug('Batch Job Completed');
        System.debug('Status: ' + job.Status);
        System.debug('Total Batches: ' + job.TotalJobItems);
        System.debug('Batches Processed: ' + job.JobItemsProcessed);
        System.debug('Errors: ' + job.NumberOfErrors);
    }

    public static Id executeBatch() {
        return executeBatch(200);
    }

    public static Id executeBatch(Integer batchSize) {
        ShipmentItemVisibilityBatch batch = new ShipmentItemVisibilityBatch(batchSize);
        return Database.executeBatch(batch, batchSize);
    }
}