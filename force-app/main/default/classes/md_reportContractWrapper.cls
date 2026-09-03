public class md_reportContractWrapper {

    public class EnrichmentData {
        @AuraEnabled public Id quoteLineId;
        @AuraEnabled public Id originalQuoteId;
        @AuraEnabled public String contractNumber;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public Decimal contractQty;
        @AuraEnabled public Decimal openOrderQty;
        @AuraEnabled public Decimal shippedQty;
        @AuraEnabled public Decimal remainingQty;
        @AuraEnabled public String sapItemNumber;
        @AuraEnabled public String lineStatus;
        @AuraEnabled public String contractStatus;

        public EnrichmentData() {
            contractQty = 0;
            openOrderQty = 0;
            shippedQty = 0;
            remainingQty = 0;
        }
    }

    public class FilterOptions {
        @AuraEnabled public List<String> contractType;
        @AuraEnabled public List<String> product;
        @AuraEnabled public List<String> origin;
        @AuraEnabled public List<String> shipTo;

        public FilterOptions() {
            contractType = new List<String>();
            product = new List<String>();
            origin = new List<String>();
            shipTo = new List<String>();
        }
    }
}