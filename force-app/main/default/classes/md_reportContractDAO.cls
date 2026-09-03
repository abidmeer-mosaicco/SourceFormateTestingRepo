public without sharing class md_reportContractDAO {

    public static Set<Id> queryLatestQuoteIdsByAccounts(Set<Id> accountIds) {
        Set<Id> quoteIds = new Set<Id>();
        for (Contract c : [
            SELECT PMC_CPQ_LatestQuote__c
            FROM Contract
            WHERE AccountId IN :accountIds
            AND PMC_CPQ_LatestQuote__c != null
        ]) {
            quoteIds.add(c.PMC_CPQ_LatestQuote__c);
        }
        return quoteIds;
    }

    public static List<Contract_Line_Item__c> queryContractLineItemsByLatestQuoteLines(Set<String> itemNumbers) {
        return [
            SELECT Id,
                Latest_Quote_Line__c,
                Latest_Quote_Line__r.PMC_CLM_QuoteLineNumber__c,
                Original_Quote_Line__c,
                Original_Quote_Line__r.PMC_CLM_QuoteLineNumber__c,
                Quote_Line__c,
                Quote_Line__r.PMC_CLM_QuoteLineNumber__c,
                Contract__c,
                Contract__r.SBQQ__Quote__c,
                Latest_Quote_Line__r.SBQQ__Quote__r.PMC_CLM_DocumentNumber__c,
                Contract__r.StartDate,
                Contract__r.EndDate,
                Quantity__c,
                Invoiced_Quantity__c,
                Total_Ordered_Quantity__c,
                Total_Consumed_Quantity__c,
                Total_Available_Quantity__c,
                Line_Status__c,
                Original_Subscription_Ref__r.AutoClosedInfo__c,
                Original_Subscription_Ref__r.MD_SAPItemNumber__c,
                Latest_Subscription__r.AutoClosedInfo__c,
                Latest_Subscription__r.MD_SAPItemNumber__c,
                Subscription__r.MD_SAPItemNumber__c
            FROM Contract_Line_Item__c
            WHERE Latest_Quote_Line__r.PMC_CLM_QuoteLineNumber__c IN :itemNumbers
               OR Original_Quote_Line__r.PMC_CLM_QuoteLineNumber__c IN :itemNumbers
               OR Quote_Line__r.PMC_CLM_QuoteLineNumber__c IN :itemNumbers
        ];
    }

    public static List<Contract_Line_Item__c> queryRejectedContractLineItems(Set<String> itemNumbers) {
        return [
            SELECT Id,
                Original_Quote_Line__c,
                Original_Quote_Line__r.PMC_CLM_QuoteLineNumber__c,
                Latest_Quote_Line__c,
                Latest_Quote_Line__r.PMC_CLM_QuoteLineNumber__c,
                Original_Subscription_Ref__r.PMC_CPQ_RejectionReason__c,
                Original_Subscription_Ref__r.AutoClosedInfo__c,
                Latest_Subscription__r.AutoClosedInfo__c
            FROM Contract_Line_Item__c
            WHERE (Latest_Quote_Line__r.PMC_CLM_QuoteLineNumber__c IN :itemNumbers
                OR Original_Quote_Line__r.PMC_CLM_QuoteLineNumber__c IN :itemNumbers)
            AND Original_Subscription_Ref__c != null
        ];
    }

    public static List<SBQQ__QuoteLine__c> queryFilterOptionsQuoteLines(String whereClause) {
        String soql =
            'SELECT Id,' +
            ' SBQQ__ProductName__c,' +
            ' PMC_CPQ_ProductLocation__r.Name,' +
            ' PMC_CPQ_ShipTo__r.ShipToFormula__c,' +
            ' SBQQ__Quote__r.PMC_CPQ_ContractType__c' +
            ' FROM SBQQ__QuoteLine__c' +
            (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '') +
            ' LIMIT 2000';
        return Database.query(soql);
    }

    public static Map<Id, ContentDocumentLink> queryLatestContractLinksByQuotes(Set<Id> quoteIds) {
        Map<Id, ContentDocumentLink> latestByQuote = new Map<Id, ContentDocumentLink>();
        String cdlQuery = 'SELECT LinkedEntityId, Visibility, ContentDocument.LatestPublishedVersionId, ContentDocument.Title, ContentDocument.LastModifiedDate ' +
                          'FROM ContentDocumentLink ' +
                          'WHERE LinkedEntityId IN :quoteIds ' +
                          'ORDER BY ContentDocument.LastModifiedDate DESC';
        Map<String, Object> cdlBinds = new Map<String, Object>{ 'quoteIds' => quoteIds };
        for (ContentDocumentLink cdl : (List<ContentDocumentLink>) Database.queryWithBinds(cdlQuery, cdlBinds, System.AccessLevel.SYSTEM_MODE)) {
            if (!latestByQuote.containsKey((Id) cdl.LinkedEntityId)) {
                latestByQuote.put((Id) cdl.LinkedEntityId, cdl);
            }
        }
        return latestByQuote;
    }

    public static List<ContentVersion> queryContentVersion(Id cvId) {
        return (List<ContentVersion>) Database.queryWithBinds(
            'SELECT Id, Title, FileExtension, VersionData FROM ContentVersion WHERE Id = :cvId',
            new Map<String, Object>{ 'cvId' => cvId },
            System.AccessLevel.SYSTEM_MODE
        );
    }

    public static List<ContentDocumentLink> queryLatestContractLinkByQuote(Id quoteId) {
        return [
            SELECT ContentDocumentId,
                   ContentDocument.LatestPublishedVersionId,
                   ContentDocument.Title,
                   ContentDocument.LastModifiedDate
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :quoteId
            WITH SECURITY_ENFORCED
            ORDER BY ContentDocument.LastModifiedDate DESC
            LIMIT 1
        ];
    }
}