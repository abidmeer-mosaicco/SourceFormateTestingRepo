public without sharing class md_reportOrdersDAO {
    private static final Integer FILTER_OPTIONS_LIMIT = 2000;

    @TestVisible private static List<ShipmentItem> testInjectedRecords;
    @TestVisible private static Map<String, List<String>> testInjectedFieldValues;
    @TestVisible private static List<Account> testInjectedShipToAccounts;

    public static List<ShipmentItem> queryShipmentItemByOrderItemIds(List<Id> orderItemIds) {
        if (Test.isRunningTest() && testInjectedRecords != null) return testInjectedRecords;else return [
        SELECT
            Id,
            PMC_CPQ_OrderProduct__c,
            Shipment.PMC_CPQ_VehicleID__c,
            Shipment.PMC_CPQ_ShippedDate__c,
            PMC_CPQ_OrderProduct__r.Order.PMC_DH_SAPOrderCreatedDate__c,
            isFPD__c
        FROM
            ShipmentItem
        WHERE
            PMC_CPQ_OrderProduct__c
        IN:orderItemIds
        ORDER BY
            PMC_CPQ_OrderProduct__c,
            PMC_CPQ_OrderProduct__r.Order.PMC_DH_SAPOrderCreatedDate__c
        DESC
        ];
    }

    public static List<String> queryDistinctOrderItemValues(String fieldPath, String whereClause) {
        if (Test.isRunningTest() && testInjectedFieldValues != null) {
            List<String> injectedValues = testInjectedFieldValues.get(fieldPath);
            return injectedValues != null ? injectedValues : new List<String>();
        }

        String soql =
            'SELECT ' + fieldPath + ' groupedValue' +
            ' FROM OrderItem' +
            (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '') +
            ' GROUP BY ' + fieldPath +
            ' LIMIT ' + FILTER_OPTIONS_LIMIT;

        List<String> values = new List<String>();
        for (AggregateResult groupedRow : (List<AggregateResult>) Database.query(soql)) {
            Object groupedValue = groupedRow.get('groupedValue');
            if (groupedValue != null) values.add(String.valueOf(groupedValue));
        }
        return values;
    }

    public static List<Account> queryShipToAccountsByIds(Set<Id> shipToIds) {
        if (Test.isRunningTest() && testInjectedShipToAccounts != null) return testInjectedShipToAccounts;
        return [SELECT Id, ShipToFormula__c FROM Account WHERE Id IN :shipToIds];
    }
}