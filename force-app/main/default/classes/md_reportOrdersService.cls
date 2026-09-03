public without sharing class md_reportOrdersService {
    private static final String ORDER_STATUS_FIELD = 'PMC_CPQ_OrderLineStatus__c';
    private static final String PRODUCT_FIELD = 'Product2.Name';
    private static final String ORIGIN_FIELD = 'PMC_CPQ_ProductLocation__r.Name';
    private static final String SHIP_TO_FIELD = 'PMC_CPQ_ShipTo__c';

    @TestVisible private static Boolean forceException = false;

    public static List<md_reportOrdersWrapper.ShipmentSummary> getDataForOrderItems(List<Id> orderItemIds) {
        if (forceException) throw new IllegalArgumentException('Forced test exception');
        if (orderItemIds == null || orderItemIds.isEmpty()) {return new List<md_reportOrdersWrapper.ShipmentSummary>();}
        List<ShipmentItem> shipmentItems = md_reportOrdersDAO.queryShipmentItemByOrderItemIds(orderItemIds);
        System.debug('shipmentItems >>> ' + shipmentItems);
        return md_reportOrdersControllerHelper.mapShipmentsToSummaries(shipmentItems);
    }

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
        md_reportOrdersWrapper.FilterOptions options = new md_reportOrdersWrapper.FilterOptions();

        options.orderStatus = queryDistinctValues(
            ORDER_STATUS_FIELD,
            buildFilterOptionsWhereClause(
                baseWhereClause, orderNumber, poNumber, dataInicio, dataFim,
                null, appliedProduct, appliedOrigin, appliedShipTo
            )
        );

        options.product = queryDistinctValues(
            PRODUCT_FIELD,
            buildFilterOptionsWhereClause(
                baseWhereClause, orderNumber, poNumber, dataInicio, dataFim,
                appliedOrderStatus, null, appliedOrigin, appliedShipTo
            )
        );

        options.origin = queryDistinctValues(
            ORIGIN_FIELD,
            buildFilterOptionsWhereClause(
                baseWhereClause, orderNumber, poNumber, dataInicio, dataFim,
                appliedOrderStatus, appliedProduct, null, appliedShipTo
            )
        );

        options.shipTo = queryShipToValues(
            buildFilterOptionsWhereClause(
                baseWhereClause, orderNumber, poNumber, dataInicio, dataFim,
                appliedOrderStatus, appliedProduct, appliedOrigin, null
            )
        );

        return options;
    }

    private static List<String> queryDistinctValues(String fieldPath, String whereClause) {
        return sortedDistinct(md_reportOrdersDAO.queryDistinctOrderItemValues(fieldPath, whereClause));
    }

    private static List<String> queryShipToValues(String whereClause) {
        Set<Id> shipToIds = new Set<Id>();
        for (String shipToId : md_reportOrdersDAO.queryDistinctOrderItemValues(SHIP_TO_FIELD, whereClause)) {
            if (String.isNotBlank(shipToId)) shipToIds.add((Id) shipToId);
        }

        if (shipToIds.isEmpty()) return new List<String>();

        List<String> shipToFormulas = new List<String>();
        for (Account shipTo : md_reportOrdersDAO.queryShipToAccountsByIds(shipToIds)) {
            shipToFormulas.add(shipTo.ShipToFormula__c);
        }
        return sortedDistinct(shipToFormulas);
    }

    private static List<String> sortedDistinct(List<String> values) {
        Set<String> uniqueValues = new Set<String>();
        for (String value : values) {
            if (String.isNotBlank(value)) uniqueValues.add(value);
        }
        List<String> result = new List<String>(uniqueValues);
        result.sort();
        return result;
    }

    private static String buildFilterOptionsWhereClause(
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
        List<String> parts = new List<String>();

        if (String.isNotBlank(baseWhereClause)) {
            parts.add('(' + baseWhereClause + ')');
        }

        if (String.isNotBlank(orderNumber)) {
            parts.add('PMC_CPQ_SAPOrderLineID__c LIKE \'%' + String.escapeSingleQuotes(orderNumber) + '%\'');
        }

        if (String.isNotBlank(poNumber)) {
            parts.add('PMC_CPQ_LinePONumber__c LIKE \'%' + String.escapeSingleQuotes(poNumber) + '%\'');
        }

        if (String.isNotBlank(dataInicio) || String.isNotBlank(dataFim)) {
            List<String> dateConds = new List<String>();
            if (String.isNotBlank(dataInicio)) dateConds.add('Order.PMC_DH_SAPOrderCreatedDate__c >= ' + dataInicio);
            if (String.isNotBlank(dataFim))    dateConds.add('Order.PMC_DH_SAPOrderCreatedDate__c <= ' + dataFim);
            parts.add('(' + String.join(dateConds, ' AND ') + ')');
        }

        if (appliedOrderStatus != null && !appliedOrderStatus.isEmpty()) {
            Boolean hasOpen = appliedOrderStatus.contains('Open');
            Boolean hasShipped = appliedOrderStatus.contains('Shipped');
            if (hasOpen && !hasShipped) {
                parts.add('PMC_CPQ_OrderLineStatus__c != \'Shipped\'');
            } else if (!hasOpen && hasShipped) {
                parts.add('PMC_CPQ_OrderLineStatus__c = \'Shipped\'');
            }
        }

        if (appliedProduct != null && !appliedProduct.isEmpty()) {
            List<String> escaped = new List<String>();
            for (String s : appliedProduct) escaped.add('\'' + String.escapeSingleQuotes(s) + '\'');
            parts.add('Product2.Name IN (' + String.join(escaped, ',') + ')');
        }

        if (appliedOrigin != null && !appliedOrigin.isEmpty()) {
            List<String> escaped = new List<String>();
            for (String s : appliedOrigin) escaped.add('\'' + String.escapeSingleQuotes(s) + '\'');
            parts.add('PMC_CPQ_ProductLocation__r.Name IN (' + String.join(escaped, ',') + ')');
        }

        if (appliedShipTo != null && !appliedShipTo.isEmpty()) {
            List<String> escaped = new List<String>();
            for (String s : appliedShipTo) escaped.add('\'' + String.escapeSingleQuotes(s) + '\'');
            parts.add('PMC_CPQ_ShipTo__r.ShipToFormula__c IN (' + String.join(escaped, ',') + ')');
        }

        return parts.isEmpty() ? '' : String.join(parts, ' AND ');
    }
}