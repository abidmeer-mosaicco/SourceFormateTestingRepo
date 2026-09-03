public class md_reportOrdersWrapper {
    public class ShipmentSummary {
        @AuraEnabled public String orderItemId;
        @AuraEnabled public String vehicleID;
        @AuraEnabled public String ShippedDate;
    }

    public class FilterOptions {
        @AuraEnabled public List<String> orderStatus;
        @AuraEnabled public List<String> product;
        @AuraEnabled public List<String> origin;
        @AuraEnabled public List<String> shipTo;

        public FilterOptions() {
            orderStatus = new List<String>();
            product = new List<String>();
            origin = new List<String>();
            shipTo = new List<String>();
        }
    }
}