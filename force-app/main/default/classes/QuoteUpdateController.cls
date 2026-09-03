/**
 * @description QuoteUpdateController is an Apex class responsible for handling the retrieval a
 * nd processing of Contract records related to quote updates in Salesforce.
 *
 * It provides methods to enqueue asynchronous processing of quote updates and to search for
 * contracts based on various filters. The class uses a QueryBuilder utility to construct dynamic
 * SOQL queries for efficient data retrieval, including support for keyset pagination.
 *
 * It also ensures that only users with the appropriate profile can access the contract data
 * and applies necessary filters based on the user's sales region.
 *
 * The enqueueQuoteUpdate method is responsible for enqueuing Queueable jobs to process quote
 * updates asynchronously, while the getContracts method retrieves contracts based on the
 * provided filters and pagination parameters.
 *
 * @author Sergio Umlauf
 * @storynumber GCPM-2771
 */
public with sharing class QuoteUpdateController {
    private static final Integer CONTRACT_QUERY_LIMIT = 100;
    private static final String CONTRACT_QUERY_ORDER_FIELD = 'CreatedDate';
    private static final String CONTRACT_QUERY_ORDER_SORTING_ORDER = 'DESC';
    private static final String ACCOUNT_MANAGER_PROFILE = 'Sales User';
    private static final List<String> CONTRACT_FIELD_LIST = new List<String>{
        'Id',
        'ContractNumber',
        'StartDate',
        'EndDate',
        'Status',
        'PMC_CPQ_LatestQuote__c',
        'AccountId',
        'Account.Name',
        'PMC_CPQ_LatestQuote__r.SBQQ__Account__r.PMC_SS_AccountExternalID__c',
        'PMC_CPQ_LatestQuote__r.SBQQ__Account__r.Name',
        'PMC_CPQ_LatestQuote__r.Name',
        'PMC_CPQ_LatestQuote__r.SBQQ__Type__c',
        'PMC_CPQ_LatestQuote__r.PMC_CPQ_LegacyQuoteID__c',
        'PMC_CPQ_LatestQuote__r.SBQQ__Account__c',
        'PMC_CPQ_LatestQuote__r.PMC_CPQ_QuoteRecordSubType__c',
        'PMC_CPQ_LatestQuote__r.PMC_CPQ_SalesOffice__c',
        'PMC_CPQ_LatestQuote__r.PMC_CPQ_AccountManager__c',
        'PMC_CPQ_LatestQuote__r.PMC_CPQ_AccountManager__r.Name',
        'PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStageName__c',
        'PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStart__c',
        'PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractEnd__c',
        'PMC_CPQ_LatestQuote__r.ApprovalStatus__c',
        'PMC_CPQ_LatestQuote__r.SBQQ__Status__c',
        'PMC_CPQ_LatestQuote__r.PMC_CPQ_SAPContractReference__c',
        'PMC_CPQ_LatestQuote__r.PMC_CPQ_SalesAreaCombination__c'
    };
    private static final Map<String, String> REGION_COUNTRY_CODE_MAP = new Map<String, String>{
        'North America' => 'US',
        'Brazil' => 'BR'
    };

    public class ContractProcessingResult {
        @AuraEnabled
        public List<Id> successIds;
        @AuraEnabled
        public List<ErrorResult> errorResults;
    }

    public class ErrorResult {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String message;
    }

    /**
     * Enfileira as linhas de execução para processamento assíncrono via Queueable.
     */
    @AuraEnabled(cacheable=false)
    public static Integer enqueueQuoteUpdate(List<Id> executionLineIds, Id executionId) {
        System.debug('Enfileirando linhas para processamento: ' + executionLineIds);

        if (executionLineIds == null || executionLineIds.isEmpty() || executionId == null) {
            return -1;
        }

        // Atualiza status da execução para In Progress antes de enfileirar os jobs
        if (executionId != null) {
            MassUpdateExecution__c exec = [
                SELECT Id, Status__c
                FROM MassUpdateExecution__c
                WHERE Id = :executionId
                LIMIT 1
            ];
            if (exec != null && exec.Status__c != 'Queued') {
                exec.Status__c = 'Queued';
                update exec;
            }
        }
        List<MassUpdateExecutionLine__c> linesToUpdate = new List<MassUpdateExecutionLine__c>();
        List<MassUpdateExecutionLine__c> lines = [
            SELECT Id, Contract__c, Feature__c, FinishedSteps__c, Step__c, Status__c, NewValues__c, QueryFilters__c
            FROM MassUpdateExecutionLine__c
            WHERE Id IN :executionLineIds
        ];

        for (MassUpdateExecutionLine__c line : lines) {
            line.Status__c = 'Queued';
            line.Step__c = 'Update Quotes';
            linesToUpdate.add(line);
            System.enqueueJob(new QuoteUpdateContractsQueueable(line.Id, executionId));
        }

        if (!linesToUpdate.isEmpty()) {
            update linesToUpdate;
        }

        return 0;
    }

    public class ContractSearchResult {
        @AuraEnabled
        public List<Contract> contracts;
        @AuraEnabled
        public Integer totalRecords;
        @AuraEnabled
        public Integer pageSize;
        @AuraEnabled
        public Boolean hasMore;
        @AuraEnabled
        public String lastRecordId;
        @AuraEnabled
        public DateTime lastRecordCreatedDate;

        public ContractSearchResult() {
            this.contracts = new List<Contract>();
            this.totalRecords = 0;
            this.pageSize = 0;
            this.hasMore = false;
            this.lastRecordId = null;
            this.lastRecordCreatedDate = null;
        }
    }

    @AuraEnabled(cacheable=false)
    public static ContractSearchResult getContracts(
        String filtersJSON,
        Integer pageSize,
        String lastRecordId,
        DateTime lastRecordCreatedDate
    ) {
        System.debug('filtersJSON::: ' + filtersJSON);
        if (!Schema.sObjectType.Contract.isAccessible()) {
            return new ContractSearchResult();
        }

        // Default pagination values
        if (pageSize == null || pageSize <= 0) {
            pageSize = CONTRACT_QUERY_LIMIT;
        }

        Map<String, Object> filters = parseFilters(filtersJSON);
        System.debug('Parsed filters::: ' + filters);
        String search = (String) filters.get('search');
        // New quote-related filters
        String fSoldTo = (String) filters.get('soldTo');
        String fQuoteNumber = (String) filters.get('quoteNumber');
        String fType = (String) filters.get('type');
        String fSapOriginalContract = (String) filters.get('sapOriginalContract');
        String fAccount = (String) filters.get('account');
        System.debug('Parsed fAccount::: ' + fAccount);
        String fBusinessType = (String) filters.get('businessType');
        String fSalesOffice = (String) filters.get('salesOffice');
        String fAccountManager = (String) filters.get('accountManager');
        String fContractDocStatus = (String) filters.get('contractDocStatus');
        Date fContractValidFrom = StringUtils.toDate((String) filters.get('contractValidFrom'));
        Date fContractValidTo = StringUtils.toDate((String) filters.get('contractValidTo'));
        String fApprovalStatus = (String) filters.get('approvalStatus');
        String fQuoteStatus = (String) filters.get('quoteStatus');
        String fSapContractRef = (String) filters.get('sapContractRef');
        // Removed contract-level date range filters (startFrom/startTo/endFrom/endTo)

        // Get current user's sales region
        String userSalesRegion = getUserSalesRegion();

        // Keyset pagination: fetch one extra record to check if there are more pages
        QueryBuilder qb = new QueryBuilder('Contract')
            .addFields(CONTRACT_FIELD_LIST)
            .addField('CreatedDate')
            .addOrderDesc('CreatedDate')
            .addOrderDesc('Id')
            .setLimit(pageSize + 1); // Fetch one extra to check hasMore

        QueryBuilder.ConditionsManager cm = qb.addConditions();

        // Build a single ComplexCondition with ANDed filters; nest ORs where needed
        QueryBuilder.ComplexCondition criteria = new QueryBuilder.ComplexCondition()
            .andCondition(new QueryBuilder.NullCondition('PMC_CPQ_LatestQuote__c').notNull())
            .andCondition(new QueryBuilder.CompareCondition('Status').eq('Activated'));

        // Add region filter if user has a sales region
        if (String.isNotBlank(userSalesRegion)) {
            criteria.andCondition(
                new QueryBuilder.CompareCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_Region__c').eq(userSalesRegion)
            );
        }

        // Keyset pagination: if we have a cursor (lastRecordId and lastRecordCreatedDate), add conditions
        if (String.isNotBlank(lastRecordId) && lastRecordCreatedDate != null) {
            // Use keyset pagination: WHERE (CreatedDate < :lastDate) OR (CreatedDate = :lastDate AND Id < :lastId)
            QueryBuilder.ComplexCondition cursorCondition = new QueryBuilder.ComplexCondition()
                .startCondition(new QueryBuilder.CompareCondition('CreatedDate').lt(lastRecordCreatedDate))
                .orCondition(
                    new QueryBuilder.ComplexCondition()
                        .startCondition(new QueryBuilder.CompareCondition('CreatedDate').eq(lastRecordCreatedDate))
                        .andCondition(new QueryBuilder.CompareCondition('Id').lt(lastRecordId))
                );
            criteria.andCondition(cursorCondition);
        }

        // Free-text search across ContractNumber and Status
        if (String.isNotBlank(search)) {
            QueryBuilder.ComplexCondition searchCond = new QueryBuilder.ComplexCondition()
                .startCondition(new QueryBuilder.LikeCondition('ContractNumber').likeAnyBoth(search))
                .orCondition(new QueryBuilder.LikeCondition('Status').likeAnyBoth(search));
            criteria.andCondition(searchCond);
        }

        // Quote-level filters under Contract.PMC_CPQ_LatestQuote__r
        if (String.isNotBlank(fSoldTo)) {
            criteria.andCondition(
                new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.SBQQ__Account__r.PMC_SS_AccountExternalID__c')
                    .likeAnyBoth(fSoldTo)
            );
        }
        if (String.isNotBlank(fQuoteNumber)) {
            Set<String> quoteNumbers = normalizeQuoteNumbers(splitTokens(fQuoteNumber));
            if (!quoteNumbers.isEmpty()) {
                criteria.andCondition(
                    new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CLM_DocumentNumber__c')
                        .inCollection(quoteNumbers)
                );
            }
        }
        if (String.isNotBlank(fType)) {
            criteria.andCondition(
                new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.SBQQ__Type__c').likeAnyBoth(fType)
            );
        }
        if (String.isNotBlank(fSapOriginalContract)) {
            Set<String> sapOriginals = splitTokens(fSapOriginalContract);
            if (!sapOriginals.isEmpty()) {
                criteria.andCondition(
                    new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_LegacyQuoteID__c')
                        .inCollection(sapOriginals)
                );
            }
        }
        if (String.isNotBlank(fAccount)) {
            criteria.andCondition(
                new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.SBQQ__Account__r.Name').likeAnyBoth(fAccount)
            );
        }
        if (String.isNotBlank(fBusinessType)) {
            if (fBusinessType.contains(',') || fBusinessType.contains(';')) {
                Set<String> businessTypes = splitTokens(fBusinessType);
                if (!businessTypes.isEmpty()) {
                    criteria.andCondition(
                        new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_QuoteRecordSubType__c')
                            .inCollection(businessTypes)
                    );
                }
            } else {
                criteria.andCondition(
                    new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_QuoteRecordSubType__c')
                        .likeAnyBoth(fBusinessType)
                );
            }
        }
        if (String.isNotBlank(fSalesOffice)) {
            if (fSalesOffice.contains(',') || fSalesOffice.contains(';')) {
                Set<String> salesOffices = splitTokens(fSalesOffice);
                if (!salesOffices.isEmpty()) {
                    criteria.andCondition(
                        new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_SalesOffice__c')
                            .inCollection(salesOffices)
                    );
                }
            } else {
                criteria.andCondition(
                    new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_SalesOffice__c')
                        .likeAnyBoth(fSalesOffice)
                );
            }
        }
        if (String.isNotBlank(fAccountManager)) {
            criteria.andCondition(
                new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_AccountManager__r.Name')
                    .likeAnyBoth(fAccountManager)
            );
        }
        if (String.isNotBlank(fContractDocStatus)) {
            if (fContractDocStatus.contains(',') || fContractDocStatus.contains(';')) {
                Set<String> docStatuses = splitTokens(fContractDocStatus);
                if (!docStatuses.isEmpty()) {
                    criteria.andCondition(
                        new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStageName__c')
                            .inCollection(docStatuses)
                    );
                }
            } else {
                criteria.andCondition(
                    new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStageName__c')
                        .likeAnyBoth(fContractDocStatus)
                );
            }
        }
        if (fContractValidFrom != null) {
            criteria.andCondition(
                new QueryBuilder.CompareCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStart__c')
                    .gte(fContractValidFrom)
            );
        }
        if (fContractValidTo != null) {
            criteria.andCondition(
                new QueryBuilder.CompareCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractEnd__c').lte(fContractValidTo)
            );
        }
        if (String.isNotBlank(fApprovalStatus)) {
            if (fApprovalStatus.contains(',') || fApprovalStatus.contains(';')) {
                Set<String> approvalStatuses = splitTokens(fApprovalStatus);
                if (!approvalStatuses.isEmpty()) {
                    criteria.andCondition(
                        new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.ApprovalStatus__c')
                            .inCollection(approvalStatuses)
                    );
                }
            } else {
                criteria.andCondition(
                    new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.ApprovalStatus__c')
                        .likeAnyBoth(fApprovalStatus)
                );
            }
        }
        if (String.isNotBlank(fQuoteStatus)) {
            if (fQuoteStatus.contains(',') || fQuoteStatus.contains(';')) {
                Set<String> quoteStatuses = splitTokens(fQuoteStatus);
                if (!quoteStatuses.isEmpty()) {
                    criteria.andCondition(
                        new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.SBQQ__Status__c')
                            .inCollection(quoteStatuses)
                    );
                }
            } else {
                criteria.andCondition(
                    new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.SBQQ__Status__c').likeAnyBoth(fQuoteStatus)
                );
            }
        }
        if (String.isNotBlank(fSapContractRef)) {
            if (fSapContractRef.contains(',') || fSapContractRef.contains(';')) {
                Set<String> sapRefs = normalizeSapContractRefs(splitTokens(fSapContractRef));
                if (!sapRefs.isEmpty()) {
                    criteria.andCondition(
                        new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_SAPContractReference__c')
                            .inCollection(sapRefs)
                    );
                }
            } else {
                String normalizedRef = StringUtils.padLeftZeros(fSapContractRef.trim(), 10);
                criteria.andCondition(
                    new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_SAPContractReference__c')
                        .likeAnyBoth(normalizedRef)
                );
            }
        }

        // Exclude Contracts which already have a Pending/In-Progress execution line
        // WHERE Id NOT IN (SELECT Contract__c FROM MassUpdateExecutionLine__c WHERE Feature__c = 'QuoteUpdate' AND Status__c IN ('Pending','In Progress'))
        QueryBuilder subQb = new QueryBuilder('MassUpdateExecutionLine__c').addFields('Contract__c');
        QueryBuilder.ConditionsManager subCm = subQb.addConditions();
        QueryBuilder.ComplexCondition subCrit = new QueryBuilder.ComplexCondition()
            .andCondition(new QueryBuilder.CompareCondition('Feature__c').eq('QuoteUpdate'))
            .andCondition(
                new QueryBuilder.InCondition('Status__c').inCollection(new List<String>{ 'Pending', 'In Progress' })
            );
        subCm.add(subCrit);
        subCm.endConditions();

        criteria.andCondition(new QueryBuilder.InCondition('Id').notIn(subQb));

        cm.add(criteria);
        System.debug('cm conditions::: ' + cm);

        // Get total count (only on first page for performance)
        Integer totalRecords = 0;
        if (String.isBlank(lastRecordId)) {
            // Only count on first page load to improve performance
            QueryBuilder countQb = new QueryBuilder('Contract').addField('Id');
            QueryBuilder.ConditionsManager countCm = countQb.addConditions();
            // Use base criteria without cursor condition for count
            QueryBuilder.ComplexCondition countCriteria = new QueryBuilder.ComplexCondition()
                .andCondition(new QueryBuilder.NullCondition('PMC_CPQ_LatestQuote__c').notNull())
                .andCondition(new QueryBuilder.CompareCondition('Status').eq('Activated'));

            if (String.isNotBlank(userSalesRegion)) {
                countCriteria.andCondition(
                    new QueryBuilder.CompareCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_Region__c').eq(userSalesRegion)
                );
            }
            // Add all other filter conditions to count criteria
            if (String.isNotBlank(search)) {
                QueryBuilder.ComplexCondition searchCond = new QueryBuilder.ComplexCondition()
                    .startCondition(new QueryBuilder.LikeCondition('ContractNumber').likeAnyBoth(search))
                    .orCondition(new QueryBuilder.LikeCondition('Status').likeAnyBoth(search));
                countCriteria.andCondition(searchCond);
            }
            if (String.isNotBlank(fSoldTo)) {
                countCriteria.andCondition(
                    new QueryBuilder.LikeCondition(
                            'PMC_CPQ_LatestQuote__r.SBQQ__Account__r.PMC_SS_AccountExternalID__c'
                        )
                        .likeAnyBoth(fSoldTo)
                );
            }
            if (String.isNotBlank(fQuoteNumber)) {
                Set<String> quoteNumbers = normalizeQuoteNumbers(splitTokens(fQuoteNumber));
                if (!quoteNumbers.isEmpty()) {
                    countCriteria.andCondition(
                        new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CLM_DocumentNumber__c')
                            .inCollection(quoteNumbers)
                    );
                }
            }
            if (String.isNotBlank(fType)) {
                countCriteria.andCondition(
                    new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.SBQQ__Type__c').likeAnyBoth(fType)
                );
            }
            if (String.isNotBlank(fSapOriginalContract)) {
                Set<String> sapOriginals = splitTokens(fSapOriginalContract);
                if (!sapOriginals.isEmpty()) {
                    countCriteria.andCondition(
                        new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_LegacyQuoteID__c')
                            .inCollection(sapOriginals)
                    );
                }
            }
            if (String.isNotBlank(fAccount)) {
                countCriteria.andCondition(
                    new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.SBQQ__Account__r.Name').likeAnyBoth(fAccount)
                );
            }
            if (String.isNotBlank(fBusinessType)) {
                if (fBusinessType.contains(',') || fBusinessType.contains(';')) {
                    Set<String> businessTypes = splitTokens(fBusinessType);
                    if (!businessTypes.isEmpty()) {
                        countCriteria.andCondition(
                            new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_QuoteRecordSubType__c')
                                .inCollection(businessTypes)
                        );
                    }
                } else {
                    countCriteria.andCondition(
                        new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_QuoteRecordSubType__c')
                            .likeAnyBoth(fBusinessType)
                    );
                }
            }
            if (String.isNotBlank(fSalesOffice)) {
                if (fSalesOffice.contains(',') || fSalesOffice.contains(';')) {
                    Set<String> salesOffices = splitTokens(fSalesOffice);
                    if (!salesOffices.isEmpty()) {
                        countCriteria.andCondition(
                            new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_SalesOffice__c')
                                .inCollection(salesOffices)
                        );
                    }
                } else {
                    countCriteria.andCondition(
                        new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_SalesOffice__c')
                            .likeAnyBoth(fSalesOffice)
                    );
                }
            }
            if (String.isNotBlank(fAccountManager)) {
                countCriteria.andCondition(
                    new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_AccountManager__r.Name')
                        .likeAnyBoth(fAccountManager)
                );
            }
            if (String.isNotBlank(fContractDocStatus)) {
                if (fContractDocStatus.contains(',') || fContractDocStatus.contains(';')) {
                    Set<String> docStatuses = splitTokens(fContractDocStatus);
                    if (!docStatuses.isEmpty()) {
                        countCriteria.andCondition(
                            new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStageName__c')
                                .inCollection(docStatuses)
                        );
                    }
                } else {
                    countCriteria.andCondition(
                        new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStageName__c')
                            .likeAnyBoth(fContractDocStatus)
                    );
                }
            }
            if (fContractValidFrom != null) {
                countCriteria.andCondition(
                    new QueryBuilder.CompareCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStart__c')
                        .gte(fContractValidFrom)
                );
            }
            if (fContractValidTo != null) {
                countCriteria.andCondition(
                    new QueryBuilder.CompareCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractEnd__c')
                        .lte(fContractValidTo)
                );
            }
            if (String.isNotBlank(fApprovalStatus)) {
                if (fApprovalStatus.contains(',') || fApprovalStatus.contains(';')) {
                    Set<String> approvalStatuses = splitTokens(fApprovalStatus);
                    if (!approvalStatuses.isEmpty()) {
                        countCriteria.andCondition(
                            new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.ApprovalStatus__c')
                                .inCollection(approvalStatuses)
                        );
                    }
                } else {
                    countCriteria.andCondition(
                        new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.ApprovalStatus__c')
                            .likeAnyBoth(fApprovalStatus)
                    );
                }
            }
            if (String.isNotBlank(fQuoteStatus)) {
                if (fQuoteStatus.contains(',') || fQuoteStatus.contains(';')) {
                    Set<String> quoteStatuses = splitTokens(fQuoteStatus);
                    if (!quoteStatuses.isEmpty()) {
                        countCriteria.andCondition(
                            new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.SBQQ__Status__c')
                                .inCollection(quoteStatuses)
                        );
                    }
                } else {
                    countCriteria.andCondition(
                        new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.SBQQ__Status__c')
                            .likeAnyBoth(fQuoteStatus)
                    );
                }
            }
            if (String.isNotBlank(fSapContractRef)) {
                if (fSapContractRef.contains(',') || fSapContractRef.contains(';')) {
                    Set<String> sapRefs = normalizeSapContractRefs(splitTokens(fSapContractRef));
                    if (!sapRefs.isEmpty()) {
                        countCriteria.andCondition(
                            new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_SAPContractReference__c')
                                .inCollection(sapRefs)
                        );
                    }
                } else {
                    String normalizedRef = StringUtils.padLeftZeros(fSapContractRef.trim(), 10);
                    countCriteria.andCondition(
                        new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_SAPContractReference__c')
                            .likeAnyBoth(normalizedRef)
                    );
                }
            }

            countCm.add(countCriteria);
            totalRecords = countCm.endConditions().toCount();
        }

        // Get records for current page (pageSize + 1 to check if there are more)
        List<Contract> allRows = (List<Contract>) cm.endConditions().toList();

        // Check if there are more pages
        Boolean hasMore = allRows.size() > pageSize;

        // Return only pageSize records (remove the extra one)
        List<Contract> rows = hasMore ? new List<Contract>() : allRows;
        if (hasMore) {
            for (Integer i = 0; i < pageSize; i++) {
                rows.add(allRows[i]);
            }
        }

        // Build and return result
        ContractSearchResult result = new ContractSearchResult();
        result.contracts = rows;
        result.totalRecords = totalRecords;
        result.pageSize = pageSize;
        result.hasMore = hasMore;

        // Set cursor for next page if there are results
        if (!rows.isEmpty()) {
            Contract lastRecord = rows[rows.size() - 1];
            result.lastRecordId = lastRecord.Id;
            result.lastRecordCreatedDate = lastRecord.CreatedDate;
        }

        return result;
    }

    private static Set<String> normalizeSapContractRefs(Set<String> raw) {
        Set<String> out = new Set<String>();
        for (String v : raw) {
            if (String.isBlank(v)) {
                continue;
            }
            String normalized = StringUtils.padLeftZeros(v.trim(), 10);
            if (String.isNotBlank(normalized)) {
                out.add(normalized);
            }
        }
        return out;
    }

    @AuraEnabled(cacheable=false)
    public static MassUpdateExecution__c getExecution(Id executionId) {
        if (executionId == null) {
            throw createAuraException('executionId is required');
        }
        if (!Schema.sObjectType.MassUpdateExecution__c.isAccessible()) {
            throw createAuraException('Insufficient access to MassUpdateExecution__c');
        }
        List<MassUpdateExecution__c> rows = [
            SELECT Id, Name, Feature__c, Status__c, CreatedDate, CreatedById, CreatedBy.Name, QueryFilters__c
            FROM MassUpdateExecution__c
            WHERE Id = :executionId
            LIMIT 1
        ];
        if (rows.isEmpty()) {
            throw createAuraException('Execution not found');
        }
        return rows[0];
    }

    @AuraEnabled(cacheable=false)
    public static QuoteUpdateUtils.ExecutionDTO createOrUpdateQuoteExecution(
        String feature,
        String executionLineDTOs,
        Id executionId,
        String queryFilters
    ) {
        if (String.isBlank(feature)) {
            throw createAuraException('Feature parameter required.');
        }

        if (String.isBlank(executionLineDTOs)) {
            throw createAuraException('At least one contract must be selected.');
        }

        if (executionId == null && !Schema.sObjectType.MassUpdateExecution__c.isCreateable()) {
            throw createAuraException('Insufficient permissions to create execution record.');
        }

        if (executionId != null && !Schema.sObjectType.MassUpdateExecution__c.isUpdateable()) {
            throw createAuraException('Insufficient permissions to update execution record.');
        }

        if (!Schema.sObjectType.MassUpdateExecutionLine__c.isCreateable()) {
            throw createAuraException('Insufficient permissions to create execution line records.');
        }

        List<QuoteUpdateUtils.ExecutionLineDTO> executionLines = (List<QuoteUpdateUtils.ExecutionLineDTO>) JSON.deserialize(
            executionLineDTOs,
            List<QuoteUpdateUtils.ExecutionLineDTO>.class
        );
        System.debug('Deserialized executionLines::: ' + executionLines);

        List<Id> contractIds = new List<Id>();
        for (QuoteUpdateUtils.ExecutionLineDTO execLine : executionLines) {
            contractIds.add(execLine.contractId);
        }
        Set<Id> validContractIds = new Set<Id>();
        for (Contract c : [SELECT Id FROM Contract WHERE Id IN :contractIds]) {
            validContractIds.add(c.Id);
        }
        if (validContractIds.isEmpty()) {
            throw createAuraException('No valid Contracts found for provided Ids.');
        }

        MassUpdateExecution__c execRec;
        if (executionId == null) {
            // Create new execution
            execRec = new MassUpdateExecution__c(Feature__c = feature, Status__c = 'Started');
            if (queryFilters != null) {
                if (queryFilters.length() > 255) {
                    execRec.QueryFilters__c = queryFilters.substring(0, 255);
                } else {
                    execRec.QueryFilters__c = queryFilters;
                }
            }
            insert execRec;
        } else {
            // Update existing execution
            List<MassUpdateExecution__c> existing = [
                SELECT Id, Feature__c, QueryFilters__c
                FROM MassUpdateExecution__c
                WHERE Id = :executionId
                LIMIT 1
            ];

            if (existing.isEmpty()) {
                throw createAuraException('Execution not found for provided executionId.');
            }

            execRec = existing[0];
            if (execRec.Feature__c != feature) {
                throw createAuraException('Provided executionId feature mismatch.');
            }

            if (queryFilters != null) {
                String tf = queryFilters;
                if (tf.length() > 255) {
                    tf = tf.substring(0, 255);
                }
                if (execRec.QueryFilters__c != tf) {
                    execRec.QueryFilters__c = tf;
                    update execRec;
                }
            }
        }

        // Check for existing lines for the provided contracts
        Set<Id> existingContractIds = new Set<Id>();
        for (MassUpdateExecutionLine__c l : [
            SELECT Contract__c
            FROM MassUpdateExecutionLine__c
            WHERE MassUpdateExecution__c = :execRec.Id AND Contract__c IN :validContractIds
        ]) {
            if (l.Contract__c != null) {
                existingContractIds.add(l.Contract__c);
            }
        }

        // Create new lines for contracts without existing lines
        List<MassUpdateExecutionLine__c> newLines = new List<MassUpdateExecutionLine__c>();
        for (QuoteUpdateUtils.ExecutionLineDTO execLine : executionLines) {
            if (existingContractIds.contains(execLine.contractId)) {
                continue;
            }

            Map<String, Object> newValues = new Map<String, Object>();
            if (String.isNotBlank(execLine.salesOffice)) {
                newValues.put('PMC_CPQ_SalesOffice__c', execLine.salesOffice);
            }
            if (String.isNotBlank(execLine.accountManagerId)) {
                newValues.put('PMC_CPQ_AccountManager__c', execLine.accountManagerId);
            }

            Map<String, Object> oldValues = new Map<String, Object>();
            if (String.isNotBlank(execLine.oldSalesOffice)) {
                oldValues.put('PMC_CPQ_SalesOffice__c', execLine.oldSalesOffice);
            }
            if (String.isNotBlank(execLine.oldAccountManagerId)) {
                oldValues.put('PMC_CPQ_AccountManager__c', execLine.oldAccountManagerId);
            }

            MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
                MassUpdateExecution__c = execRec.Id,
                Contract__c = execLine.contractId,
                CreatedQuote__c = execLine.latestQuoteId,
                Feature__c = feature,
                Step__c = 'Update Quotes',
                Status__c = 'Pending',
                NewValues__c = JSON.serialize(newValues),
                OldValues__c = JSON.serialize(oldValues)
            );

            if (execRec.QueryFilters__c != null) {
                String lq = execRec.QueryFilters__c;
                if (lq.length() > 255) {
                    lq = lq.substring(0, 255);
                }
                line.QueryFilters__c = lq;
            }
            newLines.add(line);
        }

        if (!newLines.isEmpty()) {
            insert newLines;
        }

        return new QuoteUpdateUtils.ExecutionDTO(feature, execRec, newLines);
    }

    @AuraEnabled(cacheable=false)
    public static List<MassUpdateExecutionLine__c> getExecutionLines(Id executionId) {
        if (executionId == null) {
            throw new AuraHandledException('executionId is required');
        }
        if (!Schema.sObjectType.MassUpdateExecutionLine__c.isAccessible()) {
            throw new AuraHandledException('Insufficient access to MassUpdateExecutionLine__c');
        }
        return [
            SELECT
                Id,
                CheckEligibilityStatus__c,
                CreatedQuote__c,
                CreatedQuote__r.Name,
                CreatedQuote__r.PMC_CPQ_ContactEmail__c,
                CreatedQuote__r.PMC_CPQ_IntegrationMessage__c,
                CreatedQuote__r.PMC_CPQ_IntegrationStatus__c,
                Contract__c,
                Feature__c,
                FinishedSteps__c,
                Step__c,
                Status__c,
                MassUpdateExecution__c,
                OldValues__c,
                NewValues__c,
                Message__c,
                Contract__r.Id,
                Contract__r.ContractNumber,
                Contract__r.StartDate,
                Contract__r.EndDate,
                Contract__r.Status,
                Contract__r.PMC_CPQ_LatestQuote__c,
                Contract__r.AccountId,
                Contract__r.Account.Name,
                Contract__r.PMC_CPQ_LatestQuote__r.Name,
                Contract__r.PMC_CPQ_LatestQuote__r.SBQQ__Type__c,
                Contract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_LegacyQuoteID__c,
                Contract__r.PMC_CPQ_LatestQuote__r.SBQQ__Account__c,
                Contract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_QuoteRecordSubType__c,
                Contract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_SalesOffice__c,
                Contract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_AccountManager__c,
                Contract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_AccountManager__r.Name,
                Contract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStageName__c,
                Contract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStart__c,
                Contract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractEnd__c,
                Contract__r.PMC_CPQ_LatestQuote__r.ApprovalStatus__c,
                Contract__r.PMC_CPQ_LatestQuote__r.SBQQ__Status__c,
                Contract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_SAPContractReference__c,
                Contract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_SalesAreaCombination__c,
                CreatedQuote__r.ApprovalStatus__c
            FROM MassUpdateExecutionLine__c
            WHERE MassUpdateExecution__c = :executionId
            ORDER BY CreatedDate DESC
        ];
    }

    private static String getUserSalesRegion() {
        try {
            List<User> users = [
                SELECT Id, PMC_CPQ_SalesRegion__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            // System.debug('users::: ' + users);
            if (!users.isEmpty() && String.isNotBlank(users[0].PMC_CPQ_SalesRegion__c)) {
                return users[0].PMC_CPQ_SalesRegion__c;
            }
        } catch (Exception e) {
            System.debug('Error fetching user sales region: ' + e.getMessage());
        }
        return null;
    }

    // --- Helpers ---
    private static Set<String> splitTokens(String input) {
        Set<String> out = new Set<String>();
        if (String.isBlank(input)) {
            return out;
        }
        // List<String> parts = input.split('[,;\\s\\t]+');
        // Split on comma, semicolon
        List<String> parts = input.split('[,;]+');
        for (String p : parts) {
            if (String.isNotBlank(p)) {
                out.add(p.trim());
            }
        }
        return out;
    }

    private static Set<String> normalizeQuoteNumbers(Set<String> raw) {
        Set<String> out = new Set<String>();
        for (String v : raw) {
            if (String.isBlank(v)) {
                continue;
            }
            String t = v.trim();
            // remove starting "Q-" (case-insensitive)
            if (t.length() >= 2 && t.substring(0, 2).toUpperCase() == 'Q-') {
                t = t.substring(2);
            }
            if (String.isNotBlank(t)) {
                out.add(t);
            }
        }
        return out;
    }

    private static Map<String, Object> parseFilters(String jsonTxt) {
        if (String.isBlank(jsonTxt))
            return new Map<String, Object>();
        try {
            return (Map<String, Object>) JSON.deserializeUntyped(jsonTxt);
        } catch (Exception e) {
            return new Map<String, Object>();
        }
    }

    @AuraEnabled(cacheable=false)
    public static void updateQuotes(Id executionId, List<Id> executionLineIds) {
        if (executionLineIds == null || executionLineIds.isEmpty()) {
            return;
        }
        List<MassUpdateExecutionLine__c> lines = [
            SELECT Id, CreatedQuote__c
            FROM MassUpdateExecutionLine__c
            WHERE Id IN :executionLineIds
        ];
        for (MassUpdateExecutionLine__c line : lines) {
            if (line.CreatedQuote__c != null) {
                System.enqueueJob(new QuoteUpdateContractsQueueable(line.Id, executionId));
            }
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<QuoteUpdateUtils.PicktListValueDTO> salesOfficeValues() {
        List<QuoteUpdateUtils.PicktListValueDTO> picklistValues = new List<QuoteUpdateUtils.PicktListValueDTO>();

        // Get current user's sales region
        String userSalesRegion = getUserSalesRegion();
        if (!REGION_COUNTRY_CODE_MAP.containsKey(userSalesRegion)) {
            return picklistValues;
        }

        String countryCode = REGION_COUNTRY_CODE_MAP.get(userSalesRegion);

        List<PMC_SS_SalesArea__c> salesAreas = [
            SELECT Id, Name, PMC_SS_EntityAddress__CountryCode__s
            FROM PMC_SS_SalesArea__c
            WHERE PMC_SS_EntityAddress__CountryCode__s = :countryCode
            ORDER BY Name
        ];

        if (salesAreas.isEmpty()) {
            return picklistValues;
        }

        QuoteUpdateUtils.SalesOfficeSalesAreaDTO sosa = getSalesOfficeSalesArea();
        Set<String> addedSalesOffices = new Set<String>();

        for (PMC_SS_SalesArea__c sa : salesAreas) {
            String salesArea = sosa.salesAreas.get(sa.Name);
            List<String> salesOffices = sosa.salesOfficesForSalesAreas.get(salesArea);
            if (salesOffices == null) {
                continue;
            }
            for (String so : salesOffices) {
                if (String.isBlank(so) || addedSalesOffices.contains(so)) {
                    continue;
                }
                picklistValues.add(new QuoteUpdateUtils.PicktListValueDTO(so, so));
                addedSalesOffices.add(so);
            }
        }

        // Schema.DescribeFieldResult fieldResult = SBQQ__Quote__c.PMC_CPQ_SalesOffice__c.getDescribe();
        // List<Schema.PicklistEntry> picklistOptions = fieldResult.getPicklistValues();
        // for (Schema.PicklistEntry entry : picklistOptions) {
        //     picklistValues.add(new QuoteUpdateUtils.PicktListValueDTO(entry.getLabel(), entry.getValue()));
        // }
        return picklistValues;
    }

    @AuraEnabled(cacheable=false)
    public static List<User> accountManagers() {
        // Get current user's sales region
        String userSalesRegion = getUserSalesRegion();
        List<User> users = [
            SELECT Id, Name, Email, IsActive, PMC_CPQ_SalesOffice__c, PMC_CPQ_SAPExternalUserId__c, Profile.Name
            FROM User
            WHERE
                IsActive = TRUE
                AND Profile.Name = :ACCOUNT_MANAGER_PROFILE
                AND PMC_CPQ_SalesRegion__c = :userSalesRegion
            WITH SECURITY_ENFORCED
            ORDER BY Name
        ];
        return users;
    }

    @AuraEnabled(cacheable=false)
    public static QuoteUpdateUtils.SalesOfficeSalesAreaDTO getSalesOfficeSalesArea() {
        QuoteUpdateUtils.SalesOfficeSalesAreaDTO result = new QuoteUpdateUtils.SalesOfficeSalesAreaDTO();
        try {
            Map<String, List<String>> salesOfficesForSalesAreas = SObjectUtils.getDependentPicklistValues2(
                'SBQQ__Quote__c',
                'PMC_CPQ_SalesOffice__c'
            );
            List<Schema.PicklistEntry> pe = SObjectUtils.getPickListValues(
                'SBQQ__Quote__c',
                'PMC_CPQ_SalesAreaCombination__c'
            );

            // SBQQ__Quote__c.PMC_CPQ_SalesAreaCombination__c holds the value of the picklist field
            // i.e. 'Mosaic Fertilizantes do B Domestic Common', while the dependent sales office values
            // (the key in salesOfficesForSalesArea) are grouped by the label of the sales area
            // i.e. 'Mosaic Fert Brasil Domestic Common'.
            //
            // salesAreas is a map of the picklist values and labels
            Map<String, String> salesAreas = new Map<String, String>();
            for (Schema.PicklistEntry p : pe) {
                if (!salesAreas.containsKey(p.getValue())) {
                    salesAreas.put(p.getValue(), p.getLabel());
                }
            }

            result.salesOfficesForSalesAreas = salesOfficesForSalesAreas;
            result.salesAreas = salesAreas;

            return result;
        } catch (Exception e) {
            throw createAuraException(e.getMessage());
        }
    }

    private static AuraHandledException createAuraException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
}