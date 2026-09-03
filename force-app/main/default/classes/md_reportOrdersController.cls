public with sharing class md_reportOrdersController {
    @AuraEnabled(cacheable=false)
    public static List<md_reportOrdersWrapper.ShipmentSummary> getDataForOrderItems(List<Id> orderItemIds) {
        try {return md_reportOrdersService.getDataForOrderItems(orderItemIds);} catch (Exception e) {throw new AuraHandledException(e.getMessage());}
    }

    @AuraEnabled(cacheable=false)
    public static md_reportOrdersWrapper.FilterOptions getOrderFilterOptions(
        String baseWhereClause,
        String orderNumber,
        String poNumber,
        String dataInicio,
        String dataFim,
        List<String> appliedOrderStatus,
        List<String> appliedProduct,
        List<String> appliedOrigin,
        List<String> appliedShipTo
    ) {
        try {
            return md_reportOrdersService.getOrderFilterOptions(
                baseWhereClause,
                orderNumber,
                poNumber,
                dataInicio,
                dataFim,
                appliedOrderStatus,
                appliedProduct,
                appliedOrigin,
                appliedShipTo
            );
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}