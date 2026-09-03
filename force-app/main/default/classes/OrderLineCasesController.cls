public with sharing class OrderLineCasesController {

    @AuraEnabled(cacheable=true)
    public static List<Case> getRelatedCases(Id orderItemId) {
        return [SELECT Id, CaseNumber, Status, Type, Contact.Name, PMC_SS_AtFaultParty__c, CreatedDate FROM Case WHERE PMC_SS_OrderProduct__c = :orderItemId ORDER BY CreatedDate DESC];
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getOrderItemDetails(Id orderItemId) {
        OrderItem ord = [SELECT Id,PMC_CPQ_ModeofTransportation__c,PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__c, OrderId,PMC_CPQ_UnitOfMeasure__c, PMC_CPQ_SoldtoAccount__c, Order.Contract.PMC_CPQ_PrimaryContact__c, Order.PMC_CPQ_SAPOrderNumber__c, PMC_CPQ_ShipTo__c, Quantity,PMC_CPQ_LinePONumber__c, PMC_CPQ_RequestedShipDate__c FROM OrderItem WHERE Id = :orderItemId];

        Map<String, Object> result = new Map<String, Object>();
        result.put('AccountId', ord.PMC_CPQ_SoldtoAccount__c);
        result.put('ContactId', ord.Order.Contract.PMC_CPQ_PrimaryContact__c);
        result.put('PMC_SS_Order__c', ord.OrderId);
        result.put('PMC_SS_SAPOrderNumber__c', ord.Order.PMC_CPQ_SAPOrderNumber__c);
        result.put('PMC_SS_SoldToAccount__c', ord.PMC_CPQ_SoldtoAccount__c);
        result.put('PMC_SS_ShipToAccount__c', ord.PMC_CPQ_ShipTo__c);
        result.put('OrderQuantity__c', ord.Quantity);
        result.put('Customer_Purchase_Order__c',ord.PMC_CPQ_LinePONumber__c); // added for GSMD- 1534
        result.put('PMC_SS_ShipmentDate__c', ord.PMC_CPQ_RequestedShipDate__c);
        result.put('PMC_SS_Location__c',ord.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__c); // GSMD-1500
       	result.put('PMC_SS_MOT__c',ord.PMC_CPQ_ModeofTransportation__c); //GSMD-3235
        result.put('PMC_SS_UOM__c',ord.PMC_CPQ_UnitOfMeasure__c); //GSMD-3235

        return result;
    }
}