public with sharing class ContractDateUpdateController {
	private static final Integer CONTRACT_QUERY_LIMIT = 100;
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
		'PMC_CPQ_LatestQuote__r.Name',
		'toLabel(PMC_CPQ_LatestQuote__r.SBQQ__Type__c)',
		'PMC_CPQ_LatestQuote__r.PMC_CPQ_LegacyQuoteID__c',
		'PMC_CPQ_LatestQuote__r.SBQQ__Account__c',
		'PMC_CPQ_LatestQuote__r.PMC_CPQ_QuoteRecordSubType__c',
		'PMC_CPQ_LatestQuote__r.PMC_CPQ_SalesOffice__c',
		'PMC_CPQ_LatestQuote__r.PMC_CPQ_AccountManager__c',
		'PMC_CPQ_LatestQuote__r.PMC_CPQ_AccountManager__r.Name',
		'toLabel(PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStageName__c)',
		'PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStart__c',
		'PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractEnd__c',
		'PMC_CPQ_LatestQuote__r.ApprovalStatus__c',
		'toLabel(PMC_CPQ_LatestQuote__r.SBQQ__Status__c)',
		'PMC_CPQ_LatestQuote__r.PMC_CPQ_SAPContractReference__c'
	};

    /**
     * Enfileira as linhas de execução para processamento assíncrono via Queueable.
     */
	@AuraEnabled(cacheable=false)
	public static ExecutionDTO enqueueAmendmentProcessing(List<Id> executionLineIds, Id executionId) {
		System.debug('Enfileirando linhas para processamento: ' + executionLineIds + ' executionId=' + executionId);
		if (executionLineIds == null || executionLineIds.isEmpty()) {
			throw new AuraHandledException(System.Label.MassUpdate_Error_NoExecutionLineIds);
		}

		MassUpdateExecution__c execRec;
		if (executionId == null) {
			if (!Schema.sObjectType.MassUpdateExecution__c.isCreateable()) {
				throw new AuraHandledException(System.Label.MassUpdate_Error_InsufficientPermissionsCreateExecution);
			}
			execRec = new MassUpdateExecution__c(Feature__c = 'ContractDateUpdate', Status__c = 'Queued');
			insert execRec;
			executionId = execRec.Id;
		} else {
			List<MassUpdateExecution__c> existing = [SELECT Id, Feature__c, QueryFilters__c, Status__c FROM MassUpdateExecution__c WHERE Id = :executionId LIMIT 1];
			if (existing.isEmpty()) {
				throw new AuraHandledException(System.Label.MassUpdate_Error_ExecutionNotFoundForId);
			}
			execRec = existing[0];
		}

		if (execRec != null && execRec.Status__c != 'Queued') {
			execRec.Status__c = 'Queued';
			update execRec;
		}

		List<MassUpdateExecutionLine__c> linesToUpdate = new List<MassUpdateExecutionLine__c>();
		List<MassUpdateExecutionLine__c> lines = [
			SELECT Id, Contract__c, Feature__c, FinishedSteps__c, Step__c, Status__c, NewValues__c, QueryFilters__c
			FROM MassUpdateExecutionLine__c
			WHERE Id IN :executionLineIds AND CreatedQuote__c = null
		];
		for (MassUpdateExecutionLine__c line : lines) {
			line.Status__c = 'Queued';
			line.Step__c = 'Generate Amendments';
			linesToUpdate.add(line);
			System.enqueueJob(new ContractDateAmendmentQueueable(line.Id, executionId));
		}
		if (!linesToUpdate.isEmpty()) {
			update linesToUpdate;
		}

		return new ExecutionDTO(execRec.Feature__c, execRec, lines);
	}
	public class ContractProcessingResult {
		@AuraEnabled
		public List<Id> successIds;
		@AuraEnabled
		public List<ErrorResult> errorResults;
	}
	public class ErrorResult {
		@AuraEnabled
		public Id Id;
		@AuraEnabled
		public String message;
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
	public static ContractSearchResult getContracts(String filtersJSON, Integer pageSize, String lastRecordId, DateTime lastRecordCreatedDate) {
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
				new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.SBQQ__Account__r.PMC_SS_AccountExternalID__c').likeAnyBoth(fSoldTo)
			);
		}
		if (String.isNotBlank(fQuoteNumber)) {
			Set<String> quoteNumbers = normalizeQuoteNumbers(splitTokens(fQuoteNumber));
			if (!quoteNumbers.isEmpty()) {
				criteria.andCondition(
					new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CLM_DocumentNumber__c').inCollection(quoteNumbers)
				);
			}
		}
		if (String.isNotBlank(fType)) {
			criteria.andCondition(new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.SBQQ__Type__c').likeAnyBoth(fType));
		}
		if (String.isNotBlank(fSapOriginalContract)) {
			Set<String> sapOriginals = splitTokens(fSapOriginalContract);
			if (!sapOriginals.isEmpty()) {
				criteria.andCondition(
					new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_LegacyQuoteID__c').inCollection(sapOriginals)
				);
			}
		}
		if (String.isNotBlank(fAccount)) {
			criteria.andCondition(new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.SBQQ__Account__r.Name').likeAnyBoth(fAccount));
		}
		if (String.isNotBlank(fBusinessType)) {
			if (fBusinessType.contains(',') || fBusinessType.contains(';')) {
				Set<String> businessTypes = splitTokens(fBusinessType);
				if (!businessTypes.isEmpty()) {
					criteria.andCondition(
						new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_QuoteRecordSubType__c').inCollection(businessTypes)
					);
				}
			} else {
				criteria.andCondition(
					new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_QuoteRecordSubType__c').likeAnyBoth(fBusinessType)
				);
			}
		}
		if (String.isNotBlank(fSalesOffice)) {
			if (fSalesOffice.contains(',') || fSalesOffice.contains(';')) {
				Set<String> salesOffices = splitTokens(fSalesOffice);
				if (!salesOffices.isEmpty()) {
					criteria.andCondition(
						new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_SalesOffice__c').inCollection(salesOffices)
					);
				}
			} else {
				criteria.andCondition(
					new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_SalesOffice__c').likeAnyBoth(fSalesOffice)
				);
			}
		}
		if (String.isNotBlank(fAccountManager)) {
			criteria.andCondition(
				new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_AccountManager__r.Name').likeAnyBoth(fAccountManager)
			);
		}
		if (String.isNotBlank(fContractDocStatus)) {
			if (fContractDocStatus.contains(',') || fContractDocStatus.contains(';')) {
				Set<String> docStatuses = splitTokens(fContractDocStatus);
				if (!docStatuses.isEmpty()) {
					criteria.andCondition(
						new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStageName__c').inCollection(docStatuses)
					);
				}
			} else {
				criteria.andCondition(
					new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStageName__c').likeAnyBoth(fContractDocStatus)
				);
			}
		}
		if (fContractValidFrom != null) {
			criteria.andCondition(
				new QueryBuilder.CompareCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStart__c').gte(fContractValidFrom)
			);
		}
		if (fContractValidTo != null) {
			criteria.andCondition(new QueryBuilder.CompareCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractEnd__c').lte(fContractValidTo));
		}
		if (String.isNotBlank(fApprovalStatus)) {
			if (fApprovalStatus.contains(',') || fApprovalStatus.contains(';')) {
				Set<String> approvalStatuses = splitTokens(fApprovalStatus);
				if (!approvalStatuses.isEmpty()) {
					criteria.andCondition(
						new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.ApprovalStatus__c').inCollection(approvalStatuses)
					);
				}
			} else {
				criteria.andCondition(
					new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.ApprovalStatus__c').likeAnyBoth(fApprovalStatus)
				);
			}
		}
		if (String.isNotBlank(fQuoteStatus)) {
			if (fQuoteStatus.contains(',') || fQuoteStatus.contains(';')) {
				Set<String> quoteStatuses = splitTokens(fQuoteStatus);
				if (!quoteStatuses.isEmpty()) {
					criteria.andCondition(new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.SBQQ__Status__c').inCollection(quoteStatuses));
				}
			} else {
				criteria.andCondition(new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.SBQQ__Status__c').likeAnyBoth(fQuoteStatus));
			}
		}
		if (String.isNotBlank(fSapContractRef)) {
			if (fSapContractRef.contains(',') || fSapContractRef.contains(';')) {
				Set<String> sapRefs = normalizeSapContractRefs(splitTokens(fSapContractRef));
				if (!sapRefs.isEmpty()) {
					criteria.andCondition(
						new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_SAPContractReference__c').inCollection(sapRefs)
					);
				}
			} else {
				String normalizedRef = StringUtils.padLeftZeros(fSapContractRef.trim(), 10);
				criteria.andCondition(
					new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_SAPContractReference__c').likeAnyBoth(normalizedRef)
				);
			}
		}

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
				countCriteria.andCondition(new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.SBQQ__Account__r.PMC_SS_AccountExternalID__c').likeAnyBoth(fSoldTo));
			}
			if (String.isNotBlank(fQuoteNumber)) {
				Set<String> quoteNumbers = normalizeQuoteNumbers(splitTokens(fQuoteNumber));
				if (!quoteNumbers.isEmpty()) {
					countCriteria.andCondition(new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CLM_DocumentNumber__c').inCollection(quoteNumbers));
				}
			}
			if (String.isNotBlank(fType)) {
				countCriteria.andCondition(new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.SBQQ__Type__c').likeAnyBoth(fType));
			}
			if (String.isNotBlank(fSapOriginalContract)) {
				Set<String> sapOriginals = splitTokens(fSapOriginalContract);
				if (!sapOriginals.isEmpty()) {
					countCriteria.andCondition(new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_LegacyQuoteID__c').inCollection(sapOriginals));
				}
			}
			if (String.isNotBlank(fAccount)) {
				countCriteria.andCondition(new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.SBQQ__Account__r.Name').likeAnyBoth(fAccount));
			}
			if (String.isNotBlank(fBusinessType)) {
				if (fBusinessType.contains(',') || fBusinessType.contains(';')) {
					Set<String> businessTypes = splitTokens(fBusinessType);
					if (!businessTypes.isEmpty()) {
						countCriteria.andCondition(
							new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_QuoteRecordSubType__c').inCollection(businessTypes)
						);
					}
				} else {
					countCriteria.andCondition(
						new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_QuoteRecordSubType__c').likeAnyBoth(fBusinessType)
					);
				}
			}
			if (String.isNotBlank(fSalesOffice)) {
				if (fSalesOffice.contains(',') || fSalesOffice.contains(';')) {
					Set<String> salesOffices = splitTokens(fSalesOffice);
					if (!salesOffices.isEmpty()) {
						countCriteria.andCondition(new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_SalesOffice__c').inCollection(salesOffices));
					}
				} else {
					countCriteria.andCondition(new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_SalesOffice__c').likeAnyBoth(fSalesOffice));
				}
			}
			if (String.isNotBlank(fAccountManager)) {
				countCriteria.andCondition(new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_AccountManager__r.Name').likeAnyBoth(fAccountManager));
			}
			if (String.isNotBlank(fContractDocStatus)) {
				if (fContractDocStatus.contains(',') || fContractDocStatus.contains(';')) {
					Set<String> docStatuses = splitTokens(fContractDocStatus);
					if (!docStatuses.isEmpty()) {
						countCriteria.andCondition(new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStageName__c').inCollection(docStatuses));
					}
				} else {
					countCriteria.andCondition(new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStageName__c').likeAnyBoth(fContractDocStatus));
				}
			}
			if (fContractValidFrom != null) {
				countCriteria.andCondition(new QueryBuilder.CompareCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStart__c').gte(fContractValidFrom));
			}
			if (fContractValidTo != null) {
				countCriteria.andCondition(new QueryBuilder.CompareCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractEnd__c').lte(fContractValidTo));
			}
			if (String.isNotBlank(fApprovalStatus)) {
				if (fApprovalStatus.contains(',') || fApprovalStatus.contains(';')) {
					Set<String> approvalStatuses = splitTokens(fApprovalStatus);
					if (!approvalStatuses.isEmpty()) {
						countCriteria.andCondition(new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.ApprovalStatus__c').inCollection(approvalStatuses));
					}
				} else {
					countCriteria.andCondition(new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.ApprovalStatus__c').likeAnyBoth(fApprovalStatus));
				}
			}
			if (String.isNotBlank(fQuoteStatus)) {
				if (fQuoteStatus.contains(',') || fQuoteStatus.contains(';')) {
					Set<String> quoteStatuses = splitTokens(fQuoteStatus);
					if (!quoteStatuses.isEmpty()) {
						countCriteria.andCondition(new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.SBQQ__Status__c').inCollection(quoteStatuses));
					}
				} else {
					countCriteria.andCondition(new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.SBQQ__Status__c').likeAnyBoth(fQuoteStatus));
				}
			}
				if (String.isNotBlank(fSapContractRef)) {
				if (fSapContractRef.contains(',') || fSapContractRef.contains(';')) {
					Set<String> sapRefs = normalizeSapContractRefs(splitTokens(fSapContractRef));
					if (!sapRefs.isEmpty()) {
						countCriteria.andCondition(new QueryBuilder.InCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_SAPContractReference__c').inCollection(sapRefs));
					}
				} else {
					String normalizedRef = StringUtils.padLeftZeros(fSapContractRef.trim(), 10);
					countCriteria.andCondition(new QueryBuilder.LikeCondition('PMC_CPQ_LatestQuote__r.PMC_CPQ_SAPContractReference__c').likeAnyBoth(normalizedRef));
				}
			}

			countCm.add(countCriteria);
			totalRecords = countCm.endConditions().toCount();
		}

		List<Contract> co = [
			SELECT Id, PMC_CPQ_LatestQuote__r.PMC_CPQ_Region__c
			FROM Contract 
			WHERE PMC_CPQ_LatestQuote__c != NULL  
			LIMIT 101
		];
		System.debug('co::: ' + co);

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

	@AuraEnabled(cacheable=false)
	public static List<MassUpdateExecution__c> getRecentExecutions() {
		if (!Schema.sObjectType.MassUpdateExecution__c.isAccessible()) {
			return new List<MassUpdateExecution__c>();
		}
		return [
			SELECT Id, Name, Feature__c, Status__c, CreatedDate, CreatedById, CreatedBy.Name
			FROM MassUpdateExecution__c
			ORDER BY CreatedDate DESC
			LIMIT 50
		];
	}

	@AuraEnabled(cacheable=false)
	public static MassUpdateExecution__c getExecution(Id executionId) {
		if (executionId == null) {
			throw new AuraHandledException(System.Label.MassUpdate_Error_ExecutionIdRequired);
		}
		if (!Schema.sObjectType.MassUpdateExecution__c.isAccessible()) {
			throw new AuraHandledException(System.Label.MassUpdate_Error_InsufficientAccessExecution);
		}
		List<MassUpdateExecution__c> rows = [
			SELECT Id, Name, Feature__c, Status__c, CreatedDate, CreatedById, CreatedBy.Name, QueryFilters__c
			FROM MassUpdateExecution__c
			WHERE Id = :executionId
			LIMIT 1
		];
		if (rows.isEmpty()) {
			throw new AuraHandledException(System.Label.MassUpdate_Error_ExecutionNotFound);
		}
		return rows[0];
	}

	@AuraEnabled(cacheable=false)
	public static ExecutionDTO generateAmendments(
		String feature,
		String itemsJson,
		Id executionId,
		String queryFilters
	) {
		List<ContractDateUpdateItem> items;
		try {
			if (String.isBlank(itemsJson)) {
				items = new List<ContractDateUpdateItem>();
			} else {
				items = (List<ContractDateUpdateItem>) JSON.deserialize(itemsJson, List<ContractDateUpdateItem>.class);
			}
		} catch (Exception e) {
			throw new AuraHandledException(System.Label.MassUpdate_Error_InvalidItemsJSON.replace('{0}', e.getMessage()));
		}
		try {
			System.debug(LoggingLevel.DEBUG, 'generateAmendments items payload: ' + JSON.serialize(items));
		} catch (Exception e) {
			System.debug(LoggingLevel.WARN, 'generateAmendments: unable to serialize items payload: ' + e.getMessage());
		}
		if (String.isBlank(feature)) {
			throw new AuraHandledException(System.Label.MassUpdate_Error_FeatureParameterRequired);
		}
		if (items == null || items.isEmpty()) {
			throw new AuraHandledException(System.Label.MassUpdate_Error_AtLeastOneContractRequired);
		}
		if (!Schema.sObjectType.MassUpdateExecution__c.isCreateable()) {
			throw new AuraHandledException(System.Label.MassUpdate_Error_InsufficientPermissionsCreateExecution);
		}
		if (!Schema.sObjectType.MassUpdateExecutionLine__c.isCreateable()) {
			throw new AuraHandledException(System.Label.MassUpdate_Error_InsufficientPermissionsCreateExecutionLines);
		}

		Set<Id> validContractIds = new Set<Id>();
		for (ContractDateUpdateItem it : items) {
			if (it != null && it.contractId != null) validContractIds.add(it.contractId);
		}
		if (validContractIds.isEmpty()) {
			throw new AuraHandledException(System.Label.MassUpdate_Error_NoValidContracts);
		}

		MassUpdateExecution__c execRec;
		if (executionId == null) {
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
			List<MassUpdateExecution__c> existing = [
				SELECT Id, Feature__c, QueryFilters__c, Status__c
				FROM MassUpdateExecution__c
				WHERE Id = :executionId
				LIMIT 1
			];
			if (existing.isEmpty()) {
				throw new AuraHandledException(System.Label.MassUpdate_Error_ExecutionNotFoundForId);
			}
			execRec = existing[0];
			if (execRec.Feature__c != feature) {
				throw new AuraHandledException(System.Label.MassUpdate_Error_FeatureMismatch);
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

		Set<Id> existingContractIds = new Set<Id>();
		for (MassUpdateExecutionLine__c l : [
			SELECT Contract__c
			FROM MassUpdateExecutionLine__c
			WHERE MassUpdateExecution__c = :execRec.Id AND Contract__c IN :validContractIds
		]) {
			if (l.Contract__c != null) existingContractIds.add(l.Contract__c);
		}

		Map<Id, ContractDateUpdateItem> lastById = new Map<Id, ContractDateUpdateItem>();
		for (ContractDateUpdateItem it : items) {
			if (it != null && it.contractId != null) lastById.put(it.contractId, it);
		}

		List<MassUpdateExecutionLine__c> lines = new List<MassUpdateExecutionLine__c>();
		for (Id cid : validContractIds) {
			if (existingContractIds.contains(cid)) continue;
			ContractDateUpdateItem it = lastById.get(cid);
			Map<String, Object> newValues = new Map<String, Object>();
			if (it != null) {
				if (it.startDate != null) newValues.put('PMC_CPQ_ContractStart__c', it.startDate);
				if (it.endDate != null) newValues.put('PMC_CPQ_ContractEnd__c', it.endDate);
			}
			MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
				MassUpdateExecution__c = execRec.Id,
				Contract__c = cid,
				Feature__c = feature,
				Step__c = 'Generate Amendments',
				Status__c = 'In Progress',
				NewValues__c = JSON.serialize(newValues)
			);
			if (execRec.QueryFilters__c != null) {
				String lq = execRec.QueryFilters__c;
				if (lq.length() > 255) lq = lq.substring(0,255);
				line.QueryFilters__c = lq;
			}
			lines.add(line);
		}

		if (!lines.isEmpty()) {
			insert lines;
			if (execRec.Id != null) {
				execRec.Status__c = 'Queued';
				update execRec;
			}

			try {
				List<Id> newLineIds = new List<Id>();
				for (MassUpdateExecutionLine__c l : lines) {
					if (l.Id != null) newLineIds.add(l.Id);
				}
				if (!newLineIds.isEmpty()) {
					enqueueAmendmentProcessing(newLineIds, execRec.Id);
				}
			} catch (Exception e) {
				System.debug(LoggingLevel.WARN, 'generateAmendments: failed to enqueue amendment processing: ' + e.getMessage());
			}
		}

		return new ExecutionDTO(feature, execRec, lines);
	}

		@AuraEnabled(cacheable=false)
		public static List<MassUpdateExecutionLine__c> saveLinesAndEnqueue(List<MassUpdateExecutionLine__c> linesToUpdate, Id executionId) {
			if (linesToUpdate == null || linesToUpdate.isEmpty()) {
				throw new AuraHandledException(System.Label.MassUpdate_Error_NoLinesProvided);
			}
			if (!Schema.sObjectType.MassUpdateExecutionLine__c.isUpdateable()) {
				throw new AuraHandledException(System.Label.MassUpdate_Error_InsufficientPrivilegesUpdateExecutionLines);
			}
			List<MassUpdateExecutionLine__c> updates = new List<MassUpdateExecutionLine__c>();
			for (MassUpdateExecutionLine__c l : linesToUpdate) {
				if (l == null || l.Id == null) continue;
				MassUpdateExecutionLine__c upd = new MassUpdateExecutionLine__c(Id = l.Id);
				if (l.NewValues__c != null) {
					upd.NewValues__c = l.NewValues__c;
				}
				updates.add(upd);
			}
			if (!updates.isEmpty()) {
				update updates;
			}
			List<Id> ids = new List<Id>();
			for (MassUpdateExecutionLine__c u : updates) ids.add(u.Id);
			try {
				if (!ids.isEmpty()) {
					enqueueAmendmentProcessing(ids, executionId);
				}
			} catch (Exception e) {
				System.debug(LoggingLevel.WARN, 'saveLinesAndEnqueue: failed to enqueue amendment processing: ' + e.getMessage());
			}
			return [SELECT Id, NewValues__c, Status__c, Step__c, CreatedQuote__c, MassUpdateExecution__c FROM MassUpdateExecutionLine__c WHERE Id IN :ids];
		}

	public class ContractDateUpdateItem {
		@AuraEnabled
		public Id contractId;
		@AuraEnabled
		public Date startDate;
		@AuraEnabled
		public Date endDate;
	}

	@AuraEnabled(cacheable=false)
	public static List<MassUpdateExecutionLine__c> getExecutionLines(Id executionId) {
		if (executionId == null) {
			throw new AuraHandledException(System.Label.MassUpdate_Error_ExecutionIdRequired);
		}
		return [
			SELECT
				Id,
				CheckEligibilityStatus__c,
				CreatedQuote__c,
				CreatedQuote__r.Name, 
				toLabel(CreatedQuote__r.PMC_CPQ_ContractStageName__c),
				CreatedQuote__r.PMC_CPQ_ContactEmail__c,
				CreatedQuote__r.PMC_CPQ_IntegrationMessage__c,
				CreatedQuote__r.PMC_CPQ_IntegrationStatus__c,
				Contract__c,
				Feature__c,
				FinishedSteps__c,
				Step__c,
				Status__c,
				MassUpdateExecution__c,
				Message__c,
				NewValues__c,
				Contract__r.Id,
				Contract__r.ContractNumber,
				Contract__r.StartDate,
				Contract__r.EndDate,
				Contract__r.Status,
				Contract__r.PMC_CPQ_LatestQuote__c,
				Contract__r.AccountId,
				Contract__r.Account.Name,
				Contract__r.PMC_CPQ_LatestQuote__r.Name,
				toLabel(Contract__r.PMC_CPQ_LatestQuote__r.SBQQ__Type__c),
				Contract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_LegacyQuoteID__c,
				Contract__r.PMC_CPQ_LatestQuote__r.SBQQ__Account__c,
				toLabel(Contract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_QuoteRecordSubType__c),
				toLabel(Contract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_SalesOffice__c),
				Contract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_AccountManager__c,
				Contract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_AccountManager__r.Name,
				toLabel(Contract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStageName__c),
				Contract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractStart__c,
				Contract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_ContractEnd__c,
				Contract__r.PMC_CPQ_LatestQuote__r.ApprovalStatus__c,
				toLabel(Contract__r.PMC_CPQ_LatestQuote__r.SBQQ__Status__c),
				Contract__r.PMC_CPQ_LatestQuote__r.PMC_CPQ_SAPContractReference__c,
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
			System.debug('users::: ' + users);
			if (!users.isEmpty() && String.isNotBlank(users[0].PMC_CPQ_SalesRegion__c)) {
				return users[0].PMC_CPQ_SalesRegion__c;
			}
		} catch (Exception e) {
			System.debug('Error fetching user sales region: ' + e.getMessage());
		}
		return null;
	}

	private static Set<String> splitTokens(String input) {
		Set<String> out = new Set<String>();
		if (String.isBlank(input)) {
			return out;
		}
		List<String> parts = input.split('[,;\\s\\t]+');
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

	@AuraEnabled(cacheable=false)
	public static List<MassUpdateExecutionLine__c> checkEligibility(Id executionId, List<Id> executionLineIds) {
		if (executionId == null) {
			throw new AuraHandledException(System.Label.MassUpdate_Error_ExecutionIdRequired);
		}
		if (executionLineIds == null || executionLineIds.isEmpty()) {
			throw new AuraHandledException(System.Label.MassUpdate_Error_NoExecutionLineIds);
		}
		if (!Schema.sObjectType.MassUpdateExecutionLine__c.isUpdateable()) {
			throw new AuraHandledException(System.Label.MassUpdate_Error_InsufficientPermissionsUpdateExecutionLines);
		}
		List<MassUpdateExecutionLine__c> lines = [
			SELECT Id, CreatedQuote__c, Status__c, Step__c, Feature__c, FinishedSteps__c, MassUpdateExecution__c
			FROM MassUpdateExecutionLine__c
			WHERE MassUpdateExecution__c = :executionId AND Id IN :executionLineIds AND CheckEligibilityStatus__c = null AND CreatedQuote__c != null
		];
		for (MassUpdateExecutionLine__c l : lines) {
			l.Status__c = 'Queued';
			l.Step__c = 'Check Eligibility';
			l.Message__c = '';
			System.enqueueJob(new ContractUpdateCheckEligibilityQueueable(l.Id, executionId));
		}
		if (!lines.isEmpty()) {
			update lines;
		}
		return lines;
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

	public class ExecutionDTO {
		@AuraEnabled
		public String feature;
		@AuraEnabled
		public MassUpdateExecution__c execution;
		@AuraEnabled
		public List<MassUpdateExecutionLine__c> lines;

		public ExecutionDTO(String feature, MassUpdateExecution__c exec, List<MassUpdateExecutionLine__c> lines) {
			this.feature = feature;
			this.execution = exec;
			this.lines = lines;
		}
	}

	@AuraEnabled(cacheable=false)
	public static void submitForApproval(Id executionId, List<Id> executionLineIds) {
		if (executionLineIds == null || executionLineIds.isEmpty()) {
			return;
		}
		List<MassUpdateExecutionLine__c> linesToUpdate = new List<MassUpdateExecutionLine__c>();
		List<MassUpdateExecutionLine__c> lines = [SELECT Id, CreatedQuote__c, CheckEligibilityStatus__c, FinishedSteps__c FROM MassUpdateExecutionLine__c WHERE CheckEligibilityStatus__c = 'Eligible' AND Id IN :executionLineIds];
		for (MassUpdateExecutionLine__c line : lines) {
			if (line.CreatedQuote__c != null && String.isNotBlank(line.FinishedSteps__c) && !line.FinishedSteps__c.contains('Submit for Approval')) {
				line.Status__c = 'Queued';
				line.Step__c = 'Submit for Approval';
				linesToUpdate.add(line);
				System.enqueueJob(new ContractSubmitForApprovalQueueable(line.Id, line.CreatedQuote__c));
			}
		}
		if (!linesToUpdate.isEmpty()) {
			update linesToUpdate;
		}
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
	public static void generateContracts(Id executionId, List<Id> executionLineIds) {
		if (executionLineIds == null || executionLineIds.isEmpty()) {
			return;
		}
		List<MassUpdateExecutionLine__c> linesToUpdate = new List<MassUpdateExecutionLine__c>();
		List<MassUpdateExecutionLine__c> lines = [SELECT Id, CreatedById, CreatedQuote__c, FinishedSteps__c FROM MassUpdateExecutionLine__c WHERE CreatedQuote__r.ApprovalStatus__c = 'Approved' AND Id IN :executionLineIds];
		for (MassUpdateExecutionLine__c line : lines) {
			if (line.FinishedSteps__c != null && (line.FinishedSteps__c?.contains('Generate Contracts') == false)) {
				line.Status__c = 'Queued';
				line.Step__c = 'Generate Contracts';
				linesToUpdate.add(line);
				System.enqueueJob(new ContractUpdateGenContrsQueueable(line.Id, line.CreatedQuote__c, line.CreatedById));
			}
		}
		if (!linesToUpdate.isEmpty()) {
			update linesToUpdate;
		}
	}

}