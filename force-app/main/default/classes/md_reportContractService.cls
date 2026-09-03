public without sharing class md_reportContractService {

    @TestVisible
    private static Exception serviceException = null;

    public static List<Id> getLatestQuoteIdsForAccounts(List<Id> accountIds) {
        if (serviceException != null) throw serviceException;
        if (accountIds == null || accountIds.isEmpty()) return new List<Id>();
        return new List<Id>(md_reportContractDAO.queryLatestQuoteIdsByAccounts(new Set<Id>(accountIds)));
    }

    public static String getWhereClauseExcludingRejected(List<Id> quoteIds) {
        if (serviceException != null) throw serviceException;
        if (quoteIds == null || quoteIds.isEmpty()) return '';

        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id, PMC_CLM_QuoteLineNumber__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c IN :quoteIds
        ];

        if (quoteLines.isEmpty()) return '';

        Map<String, Id> displayedQuoteLineIdByItemNumber = new Map<String, Id>();
        for (SBQQ__QuoteLine__c ql : quoteLines) {
            if (String.isNotBlank(ql.PMC_CLM_QuoteLineNumber__c)) {
                displayedQuoteLineIdByItemNumber.put(ql.PMC_CLM_QuoteLineNumber__c, ql.Id);
            }
        }

        List<Contract_Line_Item__c> rejectedItems =
            md_reportContractDAO.queryRejectedContractLineItems(displayedQuoteLineIdByItemNumber.keySet());

        if (rejectedItems.isEmpty()) return '';

        Set<Id> rejectedDisplayedQuoteLineIds = new Set<Id>();
        for (Contract_Line_Item__c cli : rejectedItems) {
            if (!String.isNotBlank(cli.Original_Subscription_Ref__r?.PMC_CPQ_RejectionReason__c)) continue;

            String itemNumber = cli.Latest_Quote_Line__r?.PMC_CLM_QuoteLineNumber__c;
            if (itemNumber == null || !displayedQuoteLineIdByItemNumber.containsKey(itemNumber)) {
                itemNumber = cli.Original_Quote_Line__r?.PMC_CLM_QuoteLineNumber__c;
            }

            Id displayedQuoteLineId = displayedQuoteLineIdByItemNumber.get(itemNumber);
            if (displayedQuoteLineId != null) {
                rejectedDisplayedQuoteLineIds.add(displayedQuoteLineId);
            }
        }

        if (rejectedDisplayedQuoteLineIds.isEmpty()) return '';

        List<String> excluded = new List<String>();
        for (Id qlId : rejectedDisplayedQuoteLineIds) {
            excluded.add('\'' + qlId + '\'');
        }

        return 'Id NOT IN (' + String.join(excluded, ',') + ')';
    }

    public static List<md_reportContractWrapper.EnrichmentData> getContractEnrichmentData(List<Id> quoteIds) {
        if (serviceException != null) throw serviceException;
        if (quoteIds == null || quoteIds.isEmpty()) return new List<md_reportContractWrapper.EnrichmentData>();

        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id, PMC_CLM_QuoteLineNumber__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c IN :quoteIds
        ];

        if (quoteLines.isEmpty()) return new List<md_reportContractWrapper.EnrichmentData>();

        Map<String, Id> displayedQuoteLineIdByItemNumber = new Map<String, Id>();
        for (SBQQ__QuoteLine__c ql : quoteLines) {
            if (String.isNotBlank(ql.PMC_CLM_QuoteLineNumber__c)) {
                displayedQuoteLineIdByItemNumber.put(ql.PMC_CLM_QuoteLineNumber__c, ql.Id);
            }
        }

        List<Contract_Line_Item__c> lineItems =
            md_reportContractDAO.queryContractLineItemsByLatestQuoteLines(displayedQuoteLineIdByItemNumber.keySet());

        Map<Id, md_reportContractWrapper.EnrichmentData> enrichmentMap = new Map<Id, md_reportContractWrapper.EnrichmentData>();

        for (Contract_Line_Item__c cli : lineItems) {
            Id key = displayedQuoteLineIdByItemNumber.get(cli.Latest_Quote_Line__r?.PMC_CLM_QuoteLineNumber__c);
            if (key != null) {
                enrichmentMap.put(key, buildEnrichmentData(cli, key));
            }
        }
        for (Contract_Line_Item__c cli : lineItems) {
            Id key = displayedQuoteLineIdByItemNumber.get(cli.Original_Quote_Line__r?.PMC_CLM_QuoteLineNumber__c);
            if (key != null && !enrichmentMap.containsKey(key)) {
                enrichmentMap.put(key, buildEnrichmentData(cli, key));
            }
        }
        for (Contract_Line_Item__c cli : lineItems) {
            Id key = displayedQuoteLineIdByItemNumber.get(cli.Quote_Line__r?.PMC_CLM_QuoteLineNumber__c);
            if (key != null && !enrichmentMap.containsKey(key)) {
                enrichmentMap.put(key, buildEnrichmentData(cli, key));
            }
        }

        return enrichmentMap.values();
    }

    private static md_reportContractWrapper.EnrichmentData buildEnrichmentData(Contract_Line_Item__c cli, Id resolvedQuoteLineId) {
        md_reportContractWrapper.EnrichmentData data = new md_reportContractWrapper.EnrichmentData();
        data.quoteLineId = resolvedQuoteLineId;
        data.originalQuoteId = cli.Contract__r?.SBQQ__Quote__c;
        data.contractNumber = cli.Latest_Quote_Line__r?.SBQQ__Quote__r?.PMC_CLM_DocumentNumber__c;
        data.sapItemNumber = cli.Latest_Subscription__r?.MD_SAPItemNumber__c
            ?? cli.Original_Subscription_Ref__r?.MD_SAPItemNumber__c
            ?? cli.Subscription__r?.MD_SAPItemNumber__c;
        data.startDate = cli.Contract__r.StartDate;
        data.endDate = cli.Contract__r.EndDate;
        data.contractQty = cli.Quantity__c ?? 0;
        data.openOrderQty = cli.Invoiced_Quantity__c ?? 0;
        data.shippedQty = cli.Total_Consumed_Quantity__c ?? 0;
        data.remainingQty = cli.Total_Available_Quantity__c ?? 0;
        data.lineStatus = cli.Line_Status__c;
        data.contractStatus = computeContractStatus(cli.Contract__r.StartDate, cli.Contract__r.EndDate, cli.Total_Available_Quantity__c);
        Set<String> autoClosedValues = new Set<String>{ 'Y1', 'Y2' };
        if (autoClosedValues.contains(cli.Original_Subscription_Ref__r?.AutoClosedInfo__c) ||
            autoClosedValues.contains(cli.Latest_Subscription__r?.AutoClosedInfo__c)) {
            data.contractStatus = 'Completed';
        }
        return data;
    }

    public static md_reportContractWrapper.FilterOptions getContractFilterOptions(
        String baseWhereClause,
        List<Id> quoteIds,
        List<String> appliedContractType,
        List<String> appliedProduct,
        List<String> appliedOrigin,
        List<String> appliedShipTo
    ) {
        md_reportContractWrapper.FilterOptions options = new md_reportContractWrapper.FilterOptions();

        String whereClause = buildFilterOptionsWhereClause(
            baseWhereClause, quoteIds,
            appliedContractType, appliedProduct, appliedOrigin, appliedShipTo
        );

        Set<String> contractTypes = new Set<String>();
        Set<String> products = new Set<String>();
        Set<String> origins = new Set<String>();
        Set<String> shipTos = new Set<String>();

        for (SBQQ__QuoteLine__c ql : md_reportContractDAO.queryFilterOptionsQuoteLines(whereClause)) {
            if (ql.SBQQ__Quote__r?.PMC_CPQ_ContractType__c != null) contractTypes.add(ql.SBQQ__Quote__r.PMC_CPQ_ContractType__c);
            if (ql.SBQQ__ProductName__c != null) products.add(ql.SBQQ__ProductName__c);
            if (ql.PMC_CPQ_ProductLocation__r?.Name != null) origins.add(ql.PMC_CPQ_ProductLocation__r.Name);
            if (ql.PMC_CPQ_ShipTo__r?.ShipToFormula__c != null) shipTos.add(ql.PMC_CPQ_ShipTo__r.ShipToFormula__c);
        }

        options.contractType = new List<String>(contractTypes);
        options.product = new List<String>(products);
        options.origin = new List<String>(origins);
        options.shipTo = new List<String>(shipTos);

        options.contractType.sort();
        options.product.sort();
        options.origin.sort();
        options.shipTo.sort();

        return options;
    }

    public static Map<Id, Map<String, Object>> getQuotesWithContractFile(List<Id> quoteIds) {
        if (serviceException != null) throw serviceException;
        Map<Id, Map<String, Object>> result = new Map<Id, Map<String, Object>>();
        if (quoteIds == null || quoteIds.isEmpty()) return result;

        Set<Id> uniqueIds = new Set<Id>(quoteIds);
        uniqueIds.remove(null);
        for (Id qid : uniqueIds) {
            result.put(qid, new Map<String, Object>{ 'hasFile' => false });
        }

        Map<Id, ContentDocumentLink> latestByQuote = md_reportContractDAO.queryLatestContractLinksByQuotes(uniqueIds);

        for (Id qid : latestByQuote.keySet()) {
            ContentDocumentLink cdl = latestByQuote.get(qid);
            Id cvId = cdl.ContentDocument.LatestPublishedVersionId;
            if (cvId == null) continue;
            result.put(qid, new Map<String, Object>{
                'hasFile'     => true,
                'downloadUrl' => '/sfc/servlet.shepherd/version/download/' + cvId,
                'fileName'    => cdl.ContentDocument.Title
            });
        }

        return result;
    }

    public static Map<String, Object> downloadContractFile(Id contentVersionId) {
        if (serviceException != null) throw serviceException;
        if (contentVersionId == null) {
            throw new AuraHandledException('contentVersionId is required.');
        }
        List<ContentVersion> cvs = md_reportContractDAO.queryContentVersion(contentVersionId);
        if (cvs.isEmpty()) {
            throw new AuraHandledException('File not found.');
        }
        ContentVersion cv = cvs[0];
        return new Map<String, Object>{
            'fileName' => cv.Title + (String.isNotBlank(cv.FileExtension) ? '.' + cv.FileExtension : ''),
            'mimeType' => 'application/pdf',
            'base64'   => EncodingUtil.base64Encode(cv.VersionData)
        };
    }

    public static Map<String, Object> getQuoteContractDownloadUrl(Id quoteId) {
        if (serviceException != null) throw serviceException;
        Map<String, Object> result = new Map<String, Object>();
        if (quoteId == null) {
            result.put('success', false);
            result.put('message', 'There is no Sales Contract PDF file available for download.');
            return result;
        }

        List<ContentDocumentLink> links = md_reportContractDAO.queryLatestContractLinkByQuote(quoteId);

        if (links.isEmpty() || links[0].ContentDocument.LatestPublishedVersionId == null) {
            result.put('success', false);
            result.put('message', 'There is no Sales Contract PDF file available for download.');
            return result;
        }

        String versionId = String.valueOf(links[0].ContentDocument.LatestPublishedVersionId);
        result.put('success', true);
        result.put('downloadUrl', '/sfc/servlet.shepherd/version/download/' + versionId);
        result.put('fileName', links[0].ContentDocument.Title);
        return result;
    }

    public static String computeContractStatus(Date startDate, Date endDate, Decimal availableQty) {
        if (availableQty != null && availableQty <= 0) return 'Completed';
        if (endDate != null && Date.today() > endDate) return 'Expired';
        return 'Open';
    }

    private static String buildFilterOptionsWhereClause(
        String baseWhereClause,
        List<Id> quoteIds,
        List<String> appliedContractType,
        List<String> appliedProduct,
        List<String> appliedOrigin,
        List<String> appliedShipTo
    ) {
        List<String> parts = new List<String>();

        if (String.isNotBlank(baseWhereClause)) parts.add('(' + baseWhereClause + ')');

        if (quoteIds != null && !quoteIds.isEmpty()) {
            List<String> quoted = new List<String>();
            for (Id qId : quoteIds) quoted.add('\'' + qId + '\'');
            parts.add('SBQQ__Quote__c IN (' + String.join(quoted, ',') + ')');
        }

        if (appliedContractType != null && !appliedContractType.isEmpty()) {
            parts.add('SBQQ__Quote__r.PMC_CPQ_ContractType__c IN (' + toSoqlList(appliedContractType) + ')');
        }

        if (appliedProduct != null && !appliedProduct.isEmpty()) {
            parts.add('SBQQ__ProductName__c IN (' + toSoqlList(appliedProduct) + ')');
        }

        if (appliedOrigin != null && !appliedOrigin.isEmpty()) {
            parts.add('PMC_CPQ_ProductLocation__r.Name IN (' + toSoqlList(appliedOrigin) + ')');
        }

        if (appliedShipTo != null && !appliedShipTo.isEmpty()) {
            parts.add('PMC_CPQ_ShipTo__r.ShipToFormula__c IN (' + toSoqlList(appliedShipTo) + ')');
        }

        return String.join(parts, ' AND ');
    }

    private static String toSoqlList(List<String> values) {
        List<String> escaped = new List<String>();
        for (String v : values) escaped.add('\'' + String.escapeSingleQuotes(v) + '\'');
        return String.join(escaped, ',');
    }
}