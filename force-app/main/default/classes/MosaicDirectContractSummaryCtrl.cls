public without sharing class MosaicDirectContractSummaryCtrl {

    public class ContractItemDTO {
        @AuraEnabled public Id subscriptionId;
        @AuraEnabled public Id contractId;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String salesOffice;
        @AuraEnabled public String salesChannel;
        @AuraEnabled public Decimal qtyAvailable;
        @AuraEnabled public Id quoteLineId;
        @AuraEnabled public Id quoteId;
        @AuraEnabled public String productCode;
        @AuraEnabled public String productName;
        @AuraEnabled public String uom;
        @AuraEnabled public String mot;
        @AuraEnabled public String shippingType;
        @AuraEnabled public String incoterm;
        @AuraEnabled public String incoterm2;
        @AuraEnabled public Decimal exchangeRate;
        @AuraEnabled public Id productLocationId;
        @AuraEnabled public String productLocationName;
        @AuraEnabled public Id shipToId;
        @AuraEnabled public String shipToName;
        @AuraEnabled public Boolean advanceBilling;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public Date contractEndDate;
        @AuraEnabled public String paymentTerms;
        @AuraEnabled public Id opportunityId;
    }

    @AuraEnabled(cacheable=true)
    public static List<ContractItemDTO> getContractItems(String quoteName) {
        if (String.isBlank(quoteName)) return new List<ContractItemDTO>();

        Contract contrato = [
            SELECT Id, PMC_CPQ_LatestQuote__c, Latest_Amendment_Created__c
            FROM Contract
            WHERE SBQQ__Quote__c = :quoteName OR PMC_CPQ_LatestQuote__c = :quoteName OR Latest_Amendment_Created__c = :quoteName
            LIMIT 1
        ] ?? null;

        if (contrato == null) return new List<ContractItemDTO>();

        Id effectiveQuoteId = contrato.Latest_Amendment_Created__c != null
            ? contrato.Latest_Amendment_Created__c
            : contrato.PMC_CPQ_LatestQuote__c;

        if (effectiveQuoteId == null) return new List<ContractItemDTO>();

        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id,
                PMC_CLM_QuoteLineNumber__c,
                SBQQ__Quote__c,
                SBQQ__Product__r.PMC_CPQ_SAPProductCode__c,
                SBQQ__Product__r.Name,
                PMC_CPQ_UnitofMeasure__c,
                PMC_CPQ_ModeofTransportation__c,
                PMC_CPQ_ShippingType__c,
                PMC_CPQ_Incoterms1__c,
                PMC_CPQ_Incoterm2__c,
                PMC_CPQ_ExchangeRate__c,
                PMC_CPQ_ProductLocation__c,
                PMC_CPQ_ProductLocation__r.Name,
                PMC_CPQ_ShipTo__c,
                PMC_CPQ_ShipTo__r.Name,
                PMC_CPQ_ShipTo__r.BillingCity,
                PMC_CPQ_ShipTo__r.BillingStateCode,
                PMC_CPQ_ShipTo__r.BillingStreet,
                PMC_CPQ_ShipTo__r.BillingPostalCode,
                PMC_CPQ_AdvanceBilling__c,
                SBQQ__Quote__r.SBQQ__StartDate__c,
                SBQQ__Quote__r.SBQQ__EndDate__c,
                SBQQ__Quote__r.PMC_CPQ_ContractEnd__c,
                SBQQ__Quote__r.SBQQ__PaymentTerms__c,
                SBQQ__Quote__r.SBQQ__Opportunity2__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :effectiveQuoteId
        ];

        if (quoteLines.isEmpty()) return new List<ContractItemDTO>();

        Map<String, SBQQ__QuoteLine__c> qlByItemNumber = new Map<String, SBQQ__QuoteLine__c>();
        for (SBQQ__QuoteLine__c ql : quoteLines) {
            if (ql.PMC_CLM_QuoteLineNumber__c != null) {
                qlByItemNumber.put(String.valueOf(ql.PMC_CLM_QuoteLineNumber__c), ql);
            }
        }

        List<SBQQ__Subscription__c> allSubs = [
            SELECT Id,
                PMC_CPQ_TotalAvailableQuantity__c,
                SBQQ__Contract__c,
                SBQQ__Account__c,
                SBQQ__Account__r.Name,
                toLabel(SBQQ__Account__r.PMC_SS_SalesOffice__c),
                SBQQ__Account__r.PMC_SS_Channel__c,
                SBQQ__QuoteLine__r.PMC_CLM_QuoteLineNumber__c
            FROM SBQQ__Subscription__c
            WHERE SBQQ__Contract__c = :contrato.Id
            ORDER BY CreatedDate DESC
        ];

        Map<String, SBQQ__Subscription__c> latestByItemNumber = new Map<String, SBQQ__Subscription__c>();
        for (SBQQ__Subscription__c sub : allSubs) {
            String itemNumber = String.valueOf(sub.SBQQ__QuoteLine__r?.PMC_CLM_QuoteLineNumber__c);
            if (!latestByItemNumber.containsKey(itemNumber)) {
                latestByItemNumber.put(itemNumber, sub);
            }
        }

        List<ContractItemDTO> result = new List<ContractItemDTO>();
        for (String itemNumber : qlByItemNumber.keySet()) {
            SBQQ__Subscription__c sub = latestByItemNumber.get(itemNumber);
            if (sub == null) continue;

            SBQQ__QuoteLine__c ql = qlByItemNumber.get(itemNumber);

            ContractItemDTO dto = new ContractItemDTO();
            dto.subscriptionId = sub.Id;
            dto.contractId = sub.SBQQ__Contract__c;
            dto.accountId = sub.SBQQ__Account__c;
            dto.accountName = sub.SBQQ__Account__r?.Name;
            dto.salesOffice = sub.SBQQ__Account__r?.PMC_SS_SalesOffice__c;
            dto.salesChannel = sub.SBQQ__Account__r?.PMC_SS_Channel__c;
            dto.qtyAvailable = sub.PMC_CPQ_TotalAvailableQuantity__c;
            dto.quoteLineId = ql.Id;
            dto.quoteId = ql.SBQQ__Quote__c;
            dto.productCode = ql.SBQQ__Product__r?.PMC_CPQ_SAPProductCode__c;
            dto.productName = ql.SBQQ__Product__r?.Name;
            dto.uom = ql.PMC_CPQ_UnitofMeasure__c;
            dto.mot = ql.PMC_CPQ_ModeofTransportation__c;
            dto.shippingType = ql.PMC_CPQ_ShippingType__c;
            dto.incoterm = ql.PMC_CPQ_Incoterms1__c;
            dto.incoterm2 = ql.PMC_CPQ_Incoterm2__c;
            dto.exchangeRate = ql.PMC_CPQ_ExchangeRate__c;
            dto.productLocationId = ql.PMC_CPQ_ProductLocation__c;
            dto.productLocationName = ql.PMC_CPQ_ProductLocation__r?.Name;
            dto.shipToId = ql.PMC_CPQ_ShipTo__c;
            dto.advanceBilling = ql.PMC_CPQ_AdvanceBilling__c;
            dto.startDate = ql.SBQQ__Quote__r?.SBQQ__StartDate__c;
            dto.endDate = ql.SBQQ__Quote__r?.SBQQ__EndDate__c;
            dto.contractEndDate = ql.SBQQ__Quote__r?.PMC_CPQ_ContractEnd__c;
            dto.paymentTerms = ql.SBQQ__Quote__r?.SBQQ__PaymentTerms__c;
            dto.opportunityId = ql.SBQQ__Quote__r?.SBQQ__Opportunity2__c;

            if (ql.PMC_CPQ_ShipTo__r != null) {
                List<String> parts = new List<String>();
                if (!String.isBlank(ql.PMC_CPQ_ShipTo__r.Name)) parts.add(ql.PMC_CPQ_ShipTo__r.Name);
                if (!String.isBlank(ql.PMC_CPQ_ShipTo__r.BillingCity)) parts.add(ql.PMC_CPQ_ShipTo__r.BillingCity);
                if (!String.isBlank(ql.PMC_CPQ_ShipTo__r.BillingStateCode)) parts.add(ql.PMC_CPQ_ShipTo__r.BillingStateCode);
                if (!String.isBlank(ql.PMC_CPQ_ShipTo__r.BillingStreet)) parts.add(ql.PMC_CPQ_ShipTo__r.BillingStreet);
                if (!String.isBlank(ql.PMC_CPQ_ShipTo__r.BillingPostalCode)) parts.add(ql.PMC_CPQ_ShipTo__r.BillingPostalCode);
                dto.shipToName = String.join(parts, ', ');
            }

            result.add(dto);
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<ShipToOption> getShipToOptions(String quoteId) {
        if (String.isBlank(quoteId)) {
            return new List<ShipToOption>();
        }
        
        SBQQ__Quote__c quote = [
            SELECT Id,
                PMC_CPQ_SoldToShipToJunction__r.PMC_SS_RelatedAccount__c,
                PMC_CPQ_SoldToShipToJunction__r.PMC_SS_Account__c,
                SBQQ__Account__c
            FROM SBQQ__Quote__c
            WHERE Id = :quoteId
            LIMIT 1
        ];

        Id soldToId = quote.SBQQ__Account__c;
        if (soldToId == null) { return new List<ShipToOption>(); }

        List<PMC_SS_AccountPartnerRelationships__c> rels = [
            SELECT 
                Name, 
                PMC_SS_Account__c, 
                PMC_SS_RelatedAccount__c, 
                PMC_SS_RelatedAccount__r.Name, 
                PMC_SS_RelatedAccount__r.BillingCity, 
                PMC_SS_RelatedAccount__r.BillingStateCode,
                PMC_SS_RelatedAccount__r.BillingCountryCode, 
                PMC_SS_RelatedAccount__r.BillingStreet, 
                PMC_SS_RelatedAccount__r.BillingPostalCode, 
                PMC_CPQ_SAPCustomerNumber__c 
            FROM PMC_SS_AccountPartnerRelationships__c 
            WHERE PMC_SS_Account__c = :soldToId 
            AND PMC_SS_Type__c = 'Ship-to' 
            AND PMC_SS_IsActive__c = true
        ];

        List<ShipToOption> options = new List<ShipToOption>();

        for (PMC_SS_AccountPartnerRelationships__c rel : rels) {
            if (rel.PMC_SS_RelatedAccount__c == null) continue;

            String name = rel.PMC_SS_RelatedAccount__r.Name;
            String city = rel.PMC_SS_RelatedAccount__r.BillingCity;
            String state = rel.PMC_SS_RelatedAccount__r.BillingStateCode;
            String street = rel.PMC_SS_RelatedAccount__r.BillingStreet;
            String postal = rel.PMC_SS_RelatedAccount__r.BillingPostalCode;

            List<String> parts = new List<String>();
            if (!String.isBlank(name)) parts.add(name);
            if (!String.isBlank(city)) parts.add(city);
            if (!String.isBlank(state)) parts.add(state);
            if (!String.isBlank(street)) parts.add(street);
            if (!String.isBlank(postal)) parts.add(postal);

            String label = String.join(parts, ', ');

            options.add(new ShipToOption(label, rel.PMC_SS_RelatedAccount__c));
        }

        return options;
    }

    public class ShipToOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public ShipToOption(String l, String v) {
            label = l; 
            value = v;
        }
    }
}