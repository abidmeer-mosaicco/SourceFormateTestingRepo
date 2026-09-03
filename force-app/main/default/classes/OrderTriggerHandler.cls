public with sharing class OrderTriggerHandler {

    private static final Boolean BOOL_BYPASS_BEFORE_UPDATE;
    private static final Boolean BOOL_BYPASS_AFTER_UPDATE;
    private static Boolean HAS_RUN_CLI_BALANCE = false;
    
    @testVisible
    public static Boolean boolBypassTriggerLogic = false;

    static{
        
        PMC_TriggerSwitches__mdt operationSwitches = PMC_TriggerSwitches__mdt.getInstance('Order');
        BOOL_BYPASS_AFTER_UPDATE = operationSwitches.PMC_AfterUpdate__c;
        BOOL_BYPASS_BEFORE_UPDATE = operationSwitches.PMC_BeforeUpdate__c;
    }


    private static final String STATUS_CANCELLED = 'Cancelled';

    public static void cancellationResource(List<Order> lstOrders, Map<Id,Order> oldMapOrder) {
        if(BOOL_BYPASS_AFTER_UPDATE  || boolBypassTriggerLogic){
            return;
        }

        Set<Id> orderIds = new Set<Id>();
        for (Order order : lstOrders) {
            Order oldOrder = oldMapOrder.get(order.Id);
            if (order.Status == STATUS_CANCELLED && oldOrder.Status != STATUS_CANCELLED) {
                orderIds.add(order.Id);
            }
        }

        if (orderIds.isEmpty()) return;

        Set<Id> cliIds = new Set<Id>();
        for (Order order : [
            SELECT Id, (SELECT Id, SBQQ__Subscription__r.Contract_Line_Item__c FROM OrderItems)
            FROM Order
            WHERE Id IN :orderIds
        ]) {
            for (OrderItem oi : order.OrderItems) {
                if (oi.SBQQ__Subscription__r.Contract_Line_Item__c != null) {
                    cliIds.add(oi.SBQQ__Subscription__r.Contract_Line_Item__c);
                }
            }
        }

        if (!cliIds.isEmpty() || !HAS_RUN_CLI_BALANCE) {
            HAS_RUN_CLI_BALANCE = true;
            new CLIBalanceCalculator(cliIds).execute();
        }
    }

    public static void calculator(List<Order> lstOrders, Map<Id,Order> oldMapOrder){
        if(BOOL_BYPASS_AFTER_UPDATE  || boolBypassTriggerLogic){
        return;
        }


        Set<Id> orderIds = new Set<Id>();
        for (Order order : lstOrders) {
            Order oldOrder = oldMapOrder.get(order.Id);
            if (order.PMC_DH_OrderTypeCode__c != null && order.PMC_DH_OrderTypeCode__c != oldOrder.PMC_DH_OrderTypeCode__c) {
                orderIds.add(order.Id);
            }
        }

        if (orderIds.isEmpty()) return;

        Set<Id> cliIds = new Set<Id>();
        for (Order order : [
            SELECT Id, (SELECT Id, SBQQ__Subscription__r.Contract_Line_Item__c FROM OrderItems)
            FROM Order
            WHERE Id IN :orderIds
        ]) {
            for (OrderItem oi : order.OrderItems) {
                if (oi.SBQQ__Subscription__r.Contract_Line_Item__c != null) {
                    cliIds.add(oi.SBQQ__Subscription__r.Contract_Line_Item__c);
                }
            }
        }

        if (!cliIds.isEmpty() || !HAS_RUN_CLI_BALANCE){
            HAS_RUN_CLI_BALANCE = true;
            new CLIBalanceCalculator(cliIds).execute();
        }
    }

}