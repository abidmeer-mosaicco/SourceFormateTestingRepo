public without sharing class MosaicDirectOrderTableCtrl {
    @AuraEnabled(cacheable=false)
    public static OrderCartWrapper getOrderCart(String recordId) {
        OrderCartWrapper wrapper = new OrderCartWrapper();

        List<OrderCart__c> carts = [
            SELECT Id
            FROM OrderCart__c
            WHERE Contract__c = :String.escapeSingleQuotes(recordId) AND Status__c = 'Active'
        ];
        wrapper.orderCarts = carts;

        if (carts.isEmpty()) {
            wrapper.items = new List<OrderCartItemWrapper>();
            return wrapper;
        }

        Set<Id> cartIds = new Set<Id>();
        for (OrderCart__c c : carts) {
            cartIds.add(c.Id);
        }

        List<OrderCartItem__c> items = [
            SELECT Id,
                   SBQQ_Product__c,
                   OrderCart__c,
                   Origin__c,
                   OrderQty__c,
                   Ship_Method__c,
                   ReqShipmentDate__c,
                   OrderPoNumber__c,
                   Ship_To__c,
                   ShipToDisplay__c,
                   Subscription__c,
                   UOM__c
            FROM OrderCartItem__c
            WHERE OrderCart__c IN :cartIds
        ];

        Set<Id> productIds = new Set<Id>();
        for (OrderCartItem__c item : items) {
            if (item.SBQQ_Product__c != null) {
                productIds.add(item.SBQQ_Product__c);
            }
        }

        Map<Id, Product2> productMap = new Map<Id, Product2>(
            [SELECT Id, PMC_CPQ_SAPProductCode__c FROM Product2 WHERE Id IN :productIds]
        );

        List<OrderCartItemWrapper> wrappedItems = new List<OrderCartItemWrapper>();
        for (OrderCartItem__c item : items) {
            Product2 p = productMap.get(item.SBQQ_Product__c);
            OrderCartItemWrapper iw = new OrderCartItemWrapper();
            iw.Id = item.Id;
            iw.SBQQ_Product = item.SBQQ_Product__c;
            iw.OrderCart = item.OrderCart__c;
            iw.Origin = item.Origin__c;
            iw.OrderQty = item.OrderQty__c;
            iw.Ship_Method = item.Ship_Method__c;
            iw.ReqShipmentDate = item.ReqShipmentDate__c;
            iw.OrderPoNumber = item.OrderPoNumber__c;
            iw.Ship_To = item.Ship_To__c;
            iw.UOM = item.UOM__c;
            iw.ShipToDisplay = item.ShipToDisplay__c;
            iw.Subscription = item.Subscription__c;
            iw.PMC_CPQ_SAPProductCode = p != null ? p.PMC_CPQ_SAPProductCode__c : null;
            wrappedItems.add(iw);
        }

        wrapper.items = wrappedItems;
        return wrapper;
    }

    public class OrderCartWrapper {
        @AuraEnabled public List<OrderCart__c> orderCarts { get; set; }
        @AuraEnabled public List<OrderCartItemWrapper> items { get; set; }
    }

    public class OrderCartItemWrapper {
        @AuraEnabled public Id Id { get; set; }
        @AuraEnabled public Id SBQQ_Product { get; set; }
        @AuraEnabled public Id OrderCart { get; set; }
        @AuraEnabled public String Origin { get; set; }
        @AuraEnabled public Decimal OrderQty { get; set; }
        @AuraEnabled public String Ship_Method { get; set; }
        @AuraEnabled public Date ReqShipmentDate { get; set; }
        @AuraEnabled public String OrderPoNumber { get; set; }
        @AuraEnabled public String Ship_To { get; set; }
        @AuraEnabled public String ShipToDisplay { get; set; }
        @AuraEnabled public String Subscription { get; set; }
        @AuraEnabled public String UOM { get; set; }
        @AuraEnabled public String PMC_CPQ_SAPProductCode { get; set; } 
    }
}