public with sharing class CLIQuantityRecalculator {

    public class Request {
        @InvocableVariable(required=true)
        public Id cliId;
        @InvocableVariable(required=true)
        public Id rootSubscriptionId;
        @InvocableVariable(required=true)
        public Decimal currentDelta;
        @InvocableVariable(required=true)
        public Id subscriptionId;
    }

    public class Response {
        @InvocableVariable
        public Decimal calculatedQuantity;
    }

    @InvocableMethod(label='Recalculate CLI Quantity From Subscriptions' description='Computes Quantity__c for a Contract_Line_Item__c from its root Subscription quantity plus every OTHER revision of that root already linked to this same CLI, plus the new delta being applied by the current amendment. The subscription being processed is excluded from that "already applied" sum, so re-running the calculation for the same subscription (retry, re-debug, reprocess) never double-counts its own delta. Never trusts the currently stored Quantity__c as a starting point.')
    public static List<Response> recalculate(List<Request> requests) {
        Set<Id> rootIds = new Set<Id>();
        Set<Id> currentSubscriptionIds = new Set<Id>();
        for (Request req : requests) {
            rootIds.add(req.rootSubscriptionId);
            if (req.subscriptionId != null) {
                currentSubscriptionIds.add(req.subscriptionId);
            }
        }

        Map<Id, SBQQ__Subscription__c> rootMap = new Map<Id, SBQQ__Subscription__c>([
            SELECT Id, SBQQ__Quantity__c
            FROM SBQQ__Subscription__c
            WHERE Id IN :rootIds
        ]);

        Map<String, Decimal> appliedDeltaSumByRootAndCli = new Map<String, Decimal>();
        for (AggregateResult ar : [
            SELECT SBQQ__RevisedSubscription__c revSub, Contract_Line_Item__c cli, SUM(SBQQ__Quantity__c) totalDelta
            FROM SBQQ__Subscription__c
            WHERE SBQQ__RevisedSubscription__c IN :rootIds
              AND Contract_Line_Item__c != null
              AND Id NOT IN :currentSubscriptionIds
            GROUP BY SBQQ__RevisedSubscription__c, Contract_Line_Item__c
        ]) {
            Id revSub = (Id) ar.get('revSub');
            Id cli = (Id) ar.get('cli');
            Decimal total = (Decimal) ar.get('totalDelta');
            appliedDeltaSumByRootAndCli.put(revSub + ':' + cli, total);
        }

        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            SBQQ__Subscription__c root = rootMap.get(req.rootSubscriptionId);
            Decimal rootQty = (root != null && root.SBQQ__Quantity__c != null) ? root.SBQQ__Quantity__c : 0;

            String key = req.rootSubscriptionId + ':' + req.cliId;
            Decimal appliedSum = appliedDeltaSumByRootAndCli.containsKey(key) ? appliedDeltaSumByRootAndCli.get(key) : 0;

            Decimal delta = req.currentDelta == null ? 0 : req.currentDelta;

            Response res = new Response();
            res.calculatedQuantity = rootQty + appliedSum + delta;
            responses.add(res);
        }

        return responses;
    }
}