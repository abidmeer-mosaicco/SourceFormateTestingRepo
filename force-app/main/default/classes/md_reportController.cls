public without sharing class md_reportController {
  // ---------------------------------------------------------------------------
  // Controle de teste — permite injetar IDs permitidos em unit tests
  // ---------------------------------------------------------------------------
  @TestVisible
  static Set<Id> TEST_ALLOWED_IDS;

  // ---------------------------------------------------------------------------
  // SEÇÃO 1 — Controle de acesso
  // ---------------------------------------------------------------------------

  /**
   * Retorna os IDs de contas que o usuário logado tem permissão de visualizar.
   * Em contexto de teste, usa TEST_ALLOWED_IDS se definido.
   */
  private static Set<Id> getAllowedAccountIds() {
    if (Test.isRunningTest() && TEST_ALLOWED_IDS != null) {
      return new Set<Id>(TEST_ALLOWED_IDS);
    }

    Set<Id> allowed = new Set<Id>();
    for (AccountAccessController.AccountAccessDTO dto : AccountAccessController.getAccessibleAccountsForUser()) {
      if (dto != null && dto.accountId != null) {
        allowed.add(dto.accountId);
      }
    }
    return allowed;
  }

  // ---------------------------------------------------------------------------
  // SEÇÃO 2 — Data Transfer Objects (DTOs)
  // ---------------------------------------------------------------------------

  /**
   * Resultado paginado retornado ao LWC.
   * Inclui os registros da página atual e metadados de paginação.
   */
  public class PagedResult {
    @AuraEnabled public List<SObject>              records;
    @AuraEnabled public Integer                    pageNumber;
    @AuraEnabled public Integer                    pageSize;
    @AuraEnabled public Integer                    totalSize;
    @AuraEnabled public Boolean                    hasNext;
    @AuraEnabled public Boolean                    hasPrev;
    @AuraEnabled public String                     nextCursor;
    @AuraEnabled public Map<Id, Map<String, String>> computedValues;
  }

  /**
   * Resultado da busca de opções de filtro para o relatório InTransit.
   */
  public class InTransitFilterOptionsResult {
    @AuraEnabled public List<String> products;
    @AuraEnabled public List<String> origins;
    @AuraEnabled public List<String> shipTos;
    @AuraEnabled public List<String> destinations;
    @AuraEnabled public List<String> statuses;
  }

  /**
   * Encapsula os parâmetros do filtro de data resolvidos pelo buildDatePredicate.
   * Valores nulos indicam que o filtro de data não se aplica ao campo/tipo.
   */
  private class ResolvedDateFilter {
    String soqlFragment; // ex: "(StartDate__c >= :fromDate AND EndDate__c <= :toDate)"
    Date   fromDate;
    Date   toDate;
    Datetime fromDatetime;
    Datetime toDatetimeExclusive; // dia seguinte ao toDate (para campos DateTime)
  }

  /**
   * Busca um conjunto fixo de registros pelos seus IDs.
   * Usado para recarregar registros específicos após edição inline.
   *
   * @param objectApiName  Nome do objeto (ex: "SBQQ__Quote__c")
   * @param recordIds      Lista de IDs a buscar
   * @param fieldApiNames  Campos a retornar
   */
  @AuraEnabled(cacheable=true)
  public static List<SObject> getRecordsByIds(
    String objectApiName,
    List<Id> recordIds,
    List<String> fieldApiNames
  ) {
    if (recordIds == null || recordIds.isEmpty() || fieldApiNames == null || fieldApiNames.isEmpty()) {
      return new List<SObject>();
    }

    String fieldList = String.join(fieldApiNames, ',');
    String soql = 'SELECT ' + fieldList + ' FROM ' + objectApiName + ' WHERE Id IN :recordIds';
    return Database.query(soql);
  }

  /**
   * Método principal de paginação — usado pelo md_report base e seus filhos.
   *
   * Funcionalidades:
   * - Paginação via OFFSET
   * - Filtro de visibilidade por conta (AccountId, SBQQ__Account__c ou Account__c)
   * - Busca textual em campos de texto/picklist
   * - Filtro de data com suporte a DateTime e Date, com timezone configurável
   * - Suporte a subcampos de QuoteLine via SBQQ__LineItems__r (apenas para SBQQ__Quote__c)
   *
   * @param objectApiName         API name do objeto a consultar
   * @param fieldApiNames         Campos a retornar (aceita paths relacionados ex: "Account.Name")
   * @param whereClause           Cláusula WHERE adicional (sem a palavra WHERE)
   * @param orderByField          Campo para ordenação
   * @param orderDir              "ASC" ou "DESC"
   * @param pageSize              Registros por página
   * @param pageNumber            Página a buscar (1-based)
   * @param searchTerm            Texto livre para busca
   * @param searchFieldApiNames   Campos onde a busca textual será aplicada
   * @param dateFilterFieldName   Campo de data início para filtro de período
   * @param endDateFilterFieldName Campo de data fim (para filtro por sobreposição de intervalos)
   * @param dateFromYmd           Data início no formato YYYY-MM-DD
   * @param dateToYmd             Data fim no formato YYYY-MM-DD
   * @param timezoneId            Timezone para conversão de datas (default: America/New_York)
   */
  @AuraEnabled(cacheable=false)
  public static PagedResult listRecordsPaged(
    String objectApiName,
    List<String> fieldApiNames,
    String whereClause,
    String orderByField,
    String orderDir,
    Integer pageSize,
    Integer pageNumber,
    String searchTerm,
    List<String> searchFieldApiNames,
    String dateFilterFieldName,
    String endDateFilterFieldName,
    String dateFromYmd,
    String dateToYmd,
    String timezoneId,
    String cursor
  ) {
    // Defaults e validações básicas
    if (pageSize   == null || pageSize   <= 0) pageSize   = 50;
    if (pageNumber == null || pageNumber <= 0) pageNumber = 1;
    if (String.isBlank(timezoneId))            timezoneId = 'America/New_York';

    // Guard 1: usuário sem nenhuma conta permitida → retorno vazio imediato
    Boolean isCommissionAgent = FeatureManagement.checkPermission('MD_AGENTE_COMISSIONADO');
    Set<Id> allowedAccountIds = isCommissionAgent ? null : getAllowedAccountIds();
    if (!isCommissionAgent) {
      debugLog('listRecordsPaged: allowedAccountIds.size() = ' + allowedAccountIds.size());
      if (allowedAccountIds.isEmpty()) {
        debugLog('listRecordsPaged: nenhuma conta permitida, retornando vazio');
        return buildEmptyResult(pageSize);
      }
    }

    // Guard 2: objeto inexistente no org
    Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
    if (objectType == null) {
      debugLog('listRecordsPaged: objectApiName inválido → ' + objectApiName);
      return buildEmptyResult(pageSize);
    }
    Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

    // --- Resolução da ordenação ---
    String orderExpression = resolveOrderExpression(orderByField);
    String orderDirection  = (orderDir != null && orderDir.toUpperCase() == 'ASC') ? 'ASC' : 'DESC';

    // --- Separação de campos: nível raiz vs subcampos de QuoteLine ---
    FieldClassification classified = classifyFields(fieldApiNames, objectApiName);

    // Sempre incluir Id e o campo de ordenação no SELECT
    classified.topLevel.add('Id');
    classified.topLevel.add(orderExpression);

    // --- Montagem da cláusula WHERE ---
    List<String> whereParts = new List<String>();

    // Cláusula passada pelo caller (ex: filtros de conta já resolvidos no LWC)
    if (!String.isBlank(whereClause)) {
      whereParts.add('(' + stripQuotedDateLiterals(whereClause) + ')');
    }

    // Filtro de visibilidade por conta (agentes comissionados usam controle diferente via WHERE clause)
    if (!isCommissionAgent) {
      String accountField = resolveAccountField(fieldMap);
      if (accountField != null) {
        whereParts.add(accountField + ' IN :allowedAccountIds');
      }
    }

    // Busca textual
    String likeParam;
    if (!String.isBlank(searchTerm) && searchFieldApiNames != null && !searchFieldApiNames.isEmpty()) {
      likeParam = '%' + searchTerm + '%';
      List<String> textSearchClauses = buildTextSearchClauses(searchFieldApiNames, fieldMap, likeParam);
      if (!textSearchClauses.isEmpty()) {
        whereParts.add('(' + String.join(textSearchClauses, ' OR ') + ')');
      }
    }

    // Filtro de data
    ResolvedDateFilter dateFilter = buildDatePredicate(
      fieldMap, dateFilterFieldName, endDateFilterFieldName, dateFromYmd, dateToYmd, timezoneId
    );
    // Variáveis usadas por binding dinâmico no Database.query
    Date     fromDate           = dateFilter.fromDate;
    Date     toDate             = dateFilter.toDate;
    Datetime fromDatetime       = dateFilter.fromDatetime;
    Datetime toDatetimeExclusive = dateFilter.toDatetimeExclusive;

    if (!String.isBlank(dateFilter.soqlFragment)) {
      whereParts.add(dateFilter.soqlFragment);
    }

    String whereExpression = whereParts.isEmpty() ? '' : ' WHERE ' + String.join(whereParts, ' AND ');
    debugLog('listRecordsPaged: whereExpression = ' + whereExpression);

    Datetime cursorDatetime = null;
    Date cursorDate = null;
    Decimal cursorDecimal = null;
    String cursorString = null;
    Id cursorId = null;
    Boolean useKeyset = false;
    Integer partsSize = whereParts.size();

    if (!String.isBlank(cursor)) {
      try {
        KeysetCursor kc = parseCursor(cursor, orderExpression, orderDirection);
        if (kc != null && kc.lastId != null) {
          String cmp = orderDirection == 'ASC' ? '>' : '<';
          String fragment = null;
          if (kc.typeCode == 'DT') {
            cursorDatetime = kc.sortValue != null ? (Datetime) kc.sortValue : null;
            fragment = '(' + orderExpression + ' ' + cmp + ' :cursorDatetime OR (' + orderExpression + ' = :cursorDatetime AND Id ' + cmp + ' :cursorId))';
          } else if (kc.typeCode == 'D') {
            cursorDate = kc.sortValue != null ? (Date) kc.sortValue : null;
            fragment = '(' + orderExpression + ' ' + cmp + ' :cursorDate OR (' + orderExpression + ' = :cursorDate AND Id ' + cmp + ' :cursorId))';
          } else if (kc.typeCode == 'N' || kc.typeCode == 'I') {
            cursorDecimal = kc.sortValue != null ? (Decimal) kc.sortValue : null;
            fragment = '(' + orderExpression + ' ' + cmp + ' :cursorDecimal OR (' + orderExpression + ' = :cursorDecimal AND Id ' + cmp + ' :cursorId))';
          } else if (kc.typeCode == 'S') {
            cursorString = kc.sortValue != null ? (String) kc.sortValue : '';
            fragment = '(' + orderExpression + ' ' + cmp + ' :cursorString OR (' + orderExpression + ' = :cursorString AND Id ' + cmp + ' :cursorId))';
          }
          if (fragment != null) {
            cursorId = kc.lastId;
            whereParts.add(fragment);
            useKeyset = true;
          }
        }
      } catch (Exception ex) {
        System.debug(LoggingLevel.WARN, 'md_reportController: cursor parse error → ' + ex.getMessage());
        while (whereParts.size() > partsSize) whereParts.remove(whereParts.size() - 1);
        useKeyset = false;
      }
    }

    Integer totalSize = Database.countQuery('SELECT COUNT() FROM ' + objectApiName + whereExpression);
    debugLog('listRecordsPaged: totalSize = ' + totalSize);

    String queryWhereExpression = useKeyset
      ? (whereParts.isEmpty() ? '' : ' WHERE ' + String.join(whereParts, ' AND '))
      : whereExpression;

    Integer offset = (pageNumber - 1) * pageSize;
    String fieldList = String.join(new List<String>(classified.topLevel), ',');
    String soql;
    if (useKeyset) {
      soql =
        'SELECT ' + fieldList +
        ' FROM ' + objectApiName +
        queryWhereExpression +
        ' ORDER BY ' + orderExpression + ' ' + orderDirection + ', Id ' + orderDirection +
        ' LIMIT ' + pageSize;
    } else {
      soql =
        'SELECT ' + fieldList +
        ' FROM ' + objectApiName +
        whereExpression +
        ' ORDER BY ' + orderExpression + ' ' + orderDirection + ', Id ' + orderDirection +
        ' LIMIT ' + pageSize +
        ' OFFSET ' + Math.min(offset, 2000);
    }

    debugLog('listRecordsPaged: soql = ' + soql);

    List<SObject> records = new List<SObject>();
    try {
      records = Database.query(soql);
    } catch (Exception ex) {
      System.debug(LoggingLevel.ERROR, 'md_reportController.listRecordsPaged: erro na query → ' + ex.getMessage());
    }

    Map<Id, Map<String, String>> computedValues = resolveComputedValues(
      records, classified.quoteLineSimpleFields, classified.quoteLineRelPaths, objectApiName
    );

    SObject lastRecord = records.isEmpty() ? null : records.get(records.size() - 1);
    String nextCursorValue = buildNextCursor(lastRecord, orderExpression, orderDirection, fieldMap);

    Integer reportedTotal = useKeyset ? totalSize : Math.min(totalSize, ((2000 / pageSize) + 1) * pageSize);

    PagedResult result    = new PagedResult();
    result.records        = records;
    result.pageNumber     = pageNumber;
    result.pageSize       = pageSize;
    result.totalSize      = reportedTotal;
    result.hasPrev        = pageNumber > 1;
    result.hasNext        = useKeyset ? (records.size() == pageSize) : ((offset + records.size()) < reportedTotal);
    result.nextCursor     = nextCursorValue;
    result.computedValues = computedValues;
    return result;
  }

  private class KeysetCursor {
    String fieldName;
    String direction;
    String typeCode;
    Object sortValue;
    Id lastId;
  }

  /**
   * Container para campos classificados por nível de query.
   */
  private class FieldClassification {
    Set<String> topLevel              = new Set<String>();
    Set<String> quoteLineSimpleFields = new Set<String>(); // ex: PMC_CPQ_FinalPricePerTon__c
    Set<String> quoteLineRelPaths     = new Set<String>(); // ex: PMC_CPQ_SoldToShipToJunction__r.Name
  }

  /**
   * Separa os campos em: campos do nível raiz do objeto e campos de QuoteLine
   * (prefixados com "SBQQ__LineItems__r."), que serão buscados em subquery separada.
   */
  private static FieldClassification classifyFields(List<String> fieldApiNames, String objectApiName) {
    FieldClassification result = new FieldClassification();
    if (fieldApiNames == null) return result;

    Schema.SObjectType quoteLineType = Schema.getGlobalDescribe().get('SBQQ__QuoteLine__c');
    Map<String, Schema.SObjectField> quoteLineFieldMap = (quoteLineType == null)
      ? new Map<String, Schema.SObjectField>()
      : quoteLineType.getDescribe().fields.getMap();

    for (String field : fieldApiNames) {
      if (String.isBlank(field)) continue;

      if (field.startsWith('SBQQ__LineItems__r.')) {
        String subField = field.substringAfter('.');
        if (String.isBlank(subField)) continue;

        if (subField.contains('__r.')) {
          result.quoteLineRelPaths.add(subField);
        } else if (!subField.contains('.') && quoteLineFieldMap.containsKey(subField)) {
          result.quoteLineSimpleFields.add(subField);
        }
      } else {
        result.topLevel.add(field);
      }
    }

    return result;
  }

  private static final String PRICE_PER_TON_FIELD = 'PMC_CPQ_FinalPricePerTon__c';

  /**
   * Para quotes (SBQQ__Quote__c), agrega os valores dos campos de QuoteLine.
   * Se todas as linhas tiverem o mesmo valor → retorna esse valor.
   * Se houver valores distintos → retorna "MULTIPLE".
   *
   * @param records        registros já buscados (quotes)
   * @param simpleFields   campos diretos de QuoteLine a agregar
   * @param relPaths       campos relacionados de QuoteLine a agregar (ex: "Rel__r.Name")
   * @param objectApiName  usado para confirmar que é SBQQ__Quote__c antes de executar
   * @returns mapa quoteId → (fieldPath → valorAgregado)
   */
  private static Map<Id, Map<String, String>> resolveComputedValues(
    List<SObject> records,
    Set<String> simpleFields,
    Set<String> relPaths,
    String objectApiName
  ) {
    Boolean isQuoteObject = objectApiName != null && objectApiName.equalsIgnoreCase('SBQQ__Quote__c');
    Boolean hasSubFields  = !simpleFields.isEmpty() || !relPaths.isEmpty();

    if (!isQuoteObject || !hasSubFields || records.isEmpty()) return null;

    // Coleta IDs das quotes
    Set<Id> quoteIds = new Set<Id>();
    for (SObject r : records) {
      Id rid = (Id) r.get('Id');
      if (rid != null) quoteIds.add(rid);
    }
    if (quoteIds.isEmpty()) return null;

    // Monta SELECT de QuoteLine
    List<String> selectParts = new List<String>{'SBQQ__Quote__c'};
    if (!simpleFields.isEmpty()) selectParts.add(String.join(new List<String>(simpleFields), ','));
    if (!relPaths.isEmpty())     selectParts.add(String.join(new List<String>(relPaths), ','));

    List<SObject> quoteLines = Database.query(
      'SELECT ' + String.join(selectParts, ',') + ' FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :quoteIds'
    );
    debugLog('resolveComputedValues: quoteLines.size() = ' + quoteLines.size());

    // Agrupa linhas por quote
    Map<Id, List<SObject>> linesByQuote = new Map<Id, List<SObject>>();
    for (SObject line : quoteLines) {
      Id qid = (Id) line.get('SBQQ__Quote__c');
      if (qid == null) continue;
      if (!linesByQuote.containsKey(qid)) linesByQuote.put(qid, new List<SObject>());
      linesByQuote.get(qid).add(line);
    }

    // Agrega por quote
    Map<Id, Map<String, String>> computedValues = new Map<Id, Map<String, String>>();
    for (Id qid : quoteIds) {
      List<SObject> lines = linesByQuote.containsKey(qid) ? linesByQuote.get(qid) : new List<SObject>();
      Map<String, String> aggregated = new Map<String, String>();

      for (String field : simpleFields) {
        aggregated.put('SBQQ__LineItems__r.' + field, aggregateSimpleField(lines, field));
      }

      for (String relPath : relPaths) {
        aggregated.put('SBQQ__LineItems__r.' + relPath, aggregateRelatedField(lines, relPath));
      }

      computedValues.put(qid, aggregated);
    }

    return computedValues;
  }

  /**
   * Agrega um campo simples de QuoteLine.
   * Regra especial para PMC_CPQ_FinalPricePerTon__c: considera MULTIPLE apenas se > 1 valor não nulo.
   */
  private static String aggregateSimpleField(List<SObject> lines, String fieldName) {
    Set<String> uniqueValues = new Set<String>();
    Integer nonNullCount     = 0;

    for (SObject line : lines) {
      Object val = line.get(fieldName);
      if (val == null) continue;
      nonNullCount++;
      uniqueValues.add(String.valueOf(val));
    }

    // Campo de preço: MULTIPLE apenas quando há mais de 1 valor distinto não nulo
    if (fieldName == PRICE_PER_TON_FIELD) {
      if (nonNullCount > 1)  return 'MULTIPLE';
      if (nonNullCount == 1) return uniqueValues.iterator().next();
      return null;
    }

    // Campos gerais
    if (uniqueValues.isEmpty()) return null;
    if (uniqueValues.size() == 1 && nonNullCount == lines.size()) return uniqueValues.iterator().next();
    return 'MULTIPLE';
  }

  /**
   * Agrega um campo de relacionamento de QuoteLine (ex: "Rel__r.Name").
   */
  private static String aggregateRelatedField(List<SObject> lines, String relPath) {
    Integer dotIdx   = relPath.indexOf('.');
    String relName   = (dotIdx > 0) ? relPath.substring(0, dotIdx) : relPath;
    String relField  = (dotIdx > 0 && dotIdx < relPath.length() - 1) ? relPath.substring(dotIdx + 1) : 'Name';

    Set<String> uniqueValues = new Set<String>();
    Integer nonNullCount     = 0;

    for (SObject line : lines) {
      SObject related = (SObject) line.getSObject(relName);
      Object val = (related == null) ? null : related.get(relField);
      if (val == null) continue;
      nonNullCount++;
      uniqueValues.add(String.valueOf(val));
    }

    if (uniqueValues.isEmpty()) return null;
    if (uniqueValues.size() == 1 && nonNullCount == lines.size()) return uniqueValues.iterator().next();
    return 'MULTIPLE';
  }

  /**
   * Resolve os parâmetros de data em um fragmento SOQL e variáveis de binding.
   *
   * Suporta:
   * - Campos Date e DateTime (com conversão automática de timezone)
   * - Apenas campo início, apenas campo fim, ou ambos
   * - Apenas dateFrom, apenas dateTo, ou intervalo completo
   * - Filtro por sobreposição de intervalos (quando startField e endField fornecidos)
   */
  private static ResolvedDateFilter buildDatePredicate(
    Map<String, Schema.SObjectField> fieldMap,
    String startFieldName,
    String endFieldName,
    String dateFromYmd,
    String dateToYmd,
    String timezoneId
  ) {
    ResolvedDateFilter resolved = new ResolvedDateFilter();

    // Sem campos configurados ou sem datas → sem filtro
    if (String.isBlank(startFieldName) && String.isBlank(endFieldName)) return resolved;
    if (String.isBlank(dateFromYmd)    && String.isBlank(dateToYmd))    return resolved;

    // Converte strings para Date
    Date fromDate = String.isBlank(dateFromYmd) ? null : Date.valueOf(dateFromYmd);
    Date toDate   = String.isBlank(dateToYmd)   ? null : Date.valueOf(dateToYmd);

    // Garante from <= to
    if (fromDate != null && toDate != null && fromDate > toDate) {
      Date temp = fromDate; fromDate = toDate; toDate = temp;
    }

    // Verifica quais campos existem no objeto
    String startField = resolveExistingField(fieldMap, startFieldName);
    String endField   = resolveExistingField(fieldMap, endFieldName);
    if (startField == null && endField == null) return resolved;

    // Tipos dos campos
    Schema.DisplayType startType = (startField != null) ? fieldMap.get(startField).getDescribe().getType() : null;
    Schema.DisplayType endType   = (endField   != null) ? fieldMap.get(endField).getDescribe().getType()   : null;

    // Conversão de timezone para campos DateTime
    TimeZone tz = TimeZone.getTimeZone(timezoneId);
    Datetime fromDatetime        = null;
    Datetime toDatetimeExclusive = null;

    if (fromDate != null) {
      Datetime midnightGmt = Datetime.newInstanceGmt(fromDate.year(), fromDate.month(), fromDate.day(), 0, 0, 0);
      fromDatetime = midnightGmt.addSeconds(-(tz.getOffset(midnightGmt) / 1000));
    }
    if (toDate != null) {
      Date nextDay = toDate.addDays(1);
      Datetime nextMidnight = Datetime.newInstanceGmt(nextDay.year(), nextDay.month(), nextDay.day(), 0, 0, 0);
      toDatetimeExclusive = nextMidnight.addSeconds(-(tz.getOffset(nextMidnight) / 1000));
    }

    resolved.fromDate            = fromDate;
    resolved.toDate              = toDate;
    resolved.fromDatetime        = fromDatetime;
    resolved.toDatetimeExclusive = toDatetimeExclusive;
    resolved.soqlFragment        = buildDateSoqlFragment(
      startField, endField, startType, endType, fromDate, toDate
    );

    return resolved;
  }

  /**
   * Monta o fragmento SOQL para o filtro de data com base nos campos e tipo presentes.
   */
  private static String buildDateSoqlFragment(
    String startField, String endField,
    Schema.DisplayType startType, Schema.DisplayType endType,
    Date fromDate, Date toDate
  ) {
    Boolean isStartDateTime = (startType == Schema.DisplayType.DateTime);
    Boolean isEndDateTime   = (endType   == Schema.DisplayType.DateTime);

    // Aliases de condição para legibilidade
    String startGte = startField + (isStartDateTime ? ' >= :fromDatetime'        : ' >= :fromDate');
    String startLte = startField + (isStartDateTime ? ' < :toDatetimeExclusive'  : ' <= :toDate');
    String endGte   = endField   + (isEndDateTime   ? ' >= :fromDatetime'        : ' >= :fromDate');
    String endLte   = endField   + (isEndDateTime   ? ' < :toDatetimeExclusive'  : ' <= :toDate');

    // Intervalo completo com ambos os campos → filtro por sobreposição
    if (fromDate != null && toDate != null && startField != null && endField != null) {
      return '(' + startGte + ' AND ' + endLte + ')';
    }

    // Intervalo completo com apenas um campo
    if (fromDate != null && toDate != null) {
      String f = (startField != null) ? startField : endField;
      Boolean isDT = (startField != null) ? isStartDateTime : isEndDateTime;
      String gte = f + (isDT ? ' >= :fromDatetime' : ' >= :fromDate');
      String lte = f + (isDT ? ' < :toDatetimeExclusive' : ' <= :toDate');
      return '(' + gte + ' AND ' + lte + ')';
    }

    // Apenas fromDate
    if (fromDate != null) {
      String f  = (startField != null) ? startField : endField;
      Boolean isDT = (startField != null) ? isStartDateTime : isEndDateTime;
      return '(' + f + (isDT ? ' >= :fromDatetime' : ' >= :fromDate') + ')';
    }

    // Apenas toDate
    if (toDate != null) {
      String f  = (endField != null) ? endField : startField;
      Boolean isDT = (endField != null) ? isEndDateTime : isStartDateTime;
      return '(' + f + (isDT ? ' < :toDatetimeExclusive' : ' <= :toDate') + ')';
    }

    return null;
  }

  /**
   * Monta predicado para busca de número de pedido.
   * Aceita formato "ORDEM0010" (order + item suffix) ou número simples.
   */
  private static String buildOrderNumberPredicate(String orderNumber) {
    if (String.isBlank(orderNumber)) return null;

    final String ORDER_FIELD = 'PMC_CPQ_OrderProduct__r.Order.PMC_CPQ_SAPOrderNumber__c';
    final String ITEM_FIELD  = 'PMC_CPQ_OrderProduct__r.OrderItemNumber__c';

    String cleaned = orderNumber.trim();
    Boolean allDigits           = cleaned.replaceAll('[^0-9]', '').length() == cleaned.length();
    Boolean hasItemSuffixPattern = cleaned.length() >= 5 &&
      cleaned.substring(cleaned.length() - 4, cleaned.length() - 3) == '0';

    if (allDigits && hasItemSuffixPattern) {
      String orderPart = cleaned.substring(0, cleaned.length() - 4);
      String itemPart  = stripLeadingZeros(cleaned.substring(cleaned.length() - 4));
      return ORDER_FIELD + ' LIKE \'%' + escapeSoql(orderPart) + '%\'' +
        ' AND ' + ITEM_FIELD + ' = \'' + escapeSoql(itemPart) + '\'';
    }

    return buildLikeClause(ORDER_FIELD, cleaned);
  }

  /** Retorna o nome do campo de conta presente no objeto, ou null se nenhum existir. */
  private static String resolveAccountField(Map<String, Schema.SObjectField> fieldMap) {
    if (fieldMap.containsKey('AccountId'))       return 'AccountId';
    if (fieldMap.containsKey('SBQQ__Account__c')) return 'SBQQ__Account__c';
    if (fieldMap.containsKey('Account__c'))       return 'Account__c';
    return null;
  }

  /**
   * Valida e retorna a expressão de ordenação, aceitando apenas caracteres
   * alfanuméricos, underscore e ponto (evita injeção SOQL).
   */
  private static String resolveOrderExpression(String orderByField) {
    if (!String.isBlank(orderByField)) {
      String cleaned = orderByField.trim();
      if (cleaned.replaceAll('[A-Za-z0-9_\\.]+', '') == '') return cleaned;
    }
    return 'LastModifiedDate';
  }

  /** Verifica se um campo existe no schema do objeto e retorna seu nome, ou null. */
  private static String resolveExistingField(Map<String, Schema.SObjectField> fieldMap, String fieldName) {
    if (String.isBlank(fieldName)) return null;
    return fieldMap.containsKey(fieldName) ? fieldName : null;
  }

  /**
   * Constrói cláusulas LIKE para busca textual, ignorando campos não textuais
   * e campos de subconsulta (ex: SBQQ__LineItems__r.*).
   */
  private static List<String> buildTextSearchClauses(
    List<String> fieldNames,
    Map<String, Schema.SObjectField> fieldMap,
    String likeParam
  ) {
    List<String> clauses = new List<String>();
    Set<Schema.DisplayType> textTypes = new Set<Schema.DisplayType>{
      Schema.DisplayType.String, Schema.DisplayType.TextArea,
      Schema.DisplayType.Phone,  Schema.DisplayType.Email,
      Schema.DisplayType.Picklist, Schema.DisplayType.Multipicklist,
      Schema.DisplayType.Url
    };

    for (String field : fieldNames) {
      if (String.isBlank(field) || field.startsWith('SBQQ__LineItems__r.')) continue;
      if (field.replaceAll('[A-Za-z0-9_\\.]+', '') != '') continue;

      if (field.contains('.')) {
        // Campo relacionado: confiar na query para validar o tipo
        clauses.add(field + ' LIKE :likeParam');
      } else {
        if (!fieldMap.containsKey(field)) continue;
        Schema.DisplayType fieldType = fieldMap.get(field).getDescribe().getType();
        if (textTypes.contains(fieldType)) {
          clauses.add(field + ' LIKE :likeParam');
        }
      }
    }

    return clauses;
  }

  /** Combina uma cláusula base com partes adicionais usando AND, ignorando nulos/vazios. */
  private static String combineWhereParts(String baseWhere, List<String> additionalParts) {
    List<String> parts = new List<String>();
    if (!String.isBlank(baseWhere)) parts.add('(' + baseWhere + ')');

    if (additionalParts != null) {
      for (String part : additionalParts) {
        if (!String.isBlank(part)) parts.add('(' + part + ')');
      }
    }

    return parts.isEmpty() ? '' : String.join(parts, ' AND ');
  }

  /** Remove aspas simples ao redor de literais de data, que o Apex não aceita em queries dinâmicas. */
  private static String stripQuotedDateLiterals(String soqlFragment) {
    if (String.isBlank(soqlFragment)) return soqlFragment;
    return soqlFragment.replaceAll('\'(\\d{4}-\\d{2}-\\d{2})\'', '$1');
  }

  /** Monta cláusula "field IN ('v1','v2')" a partir de uma lista de valores. */
  private static String buildInClause(String fieldName, List<String> values) {
    if (String.isBlank(fieldName) || values == null || values.isEmpty()) return null;
    List<String> quoted = new List<String>();
    for (String v : values) {
      if (!String.isBlank(v)) quoted.add('\'' + escapeSoql(v.trim()) + '\'');
    }
    return quoted.isEmpty() ? null : fieldName + ' IN (' + String.join(quoted, ',') + ')';
  }

  /** Monta cláusula "field LIKE '%value%'". */
  private static String buildLikeClause(String fieldName, String value) {
    if (String.isBlank(fieldName) || String.isBlank(value)) return null;
    return fieldName + ' LIKE \'%' + escapeSoql(value.trim()) + '%\'';
  }

  /** Escapa aspas simples para uso seguro em literais SOQL. */
  private static String escapeSoql(String value) {
    return String.escapeSingleQuotes(String.valueOf(value));
  }

  /** Remove zeros à esquerda mantendo ao menos um dígito. */
  private static String stripLeadingZeros(String value) {
    if (String.isBlank(value)) return value;
    Integer i = 0;
    while (i < value.length() - 1 && value.substring(i, i + 1) == '0') i++;
    return value.substring(i);
  }

  private static String getRelatedString(SObject record, String relName, String fieldName) {
    SObject related = record.getSObject(relName);
    return (related == null) ? null : (String) related.get(fieldName);
  }

  private static String getRelatedNestedString(SObject record, String rel1, String rel2, String fieldName) {
    SObject first = record.getSObject(rel1);
    if (first == null) return null;
    SObject second = first.getSObject(rel2);
    return (second == null) ? null : (String) second.get(fieldName);
  }

  private static String getFieldString(SObject record, String relName, String fieldName) {
    SObject related = record.getSObject(relName);
    return (related == null) ? null : String.valueOf(related.get(fieldName));
  }

  private static KeysetCursor parseCursor(String cursorJson, String expectedField, String expectedDirection) {
    if (String.isBlank(cursorJson)) return null;
    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(cursorJson);
    String field = (String) data.get('f');
    String dir = (String) data.get('d');
    String typeCode = (String) data.get('t');
    String lastIdStr = (String) data.get('si');
    if (String.isBlank(field) || String.isBlank(dir) || String.isBlank(typeCode) || String.isBlank(lastIdStr)) return null;
    if (!field.equals(expectedField) || !dir.equals(expectedDirection)) return null;

    KeysetCursor kc = new KeysetCursor();
    kc.fieldName = field;
    kc.direction = dir;
    kc.typeCode = typeCode;
    kc.lastId = (Id) lastIdStr;

    Object rawSortValue = data.get('sv');
    if (rawSortValue != null) {
      String sv = String.valueOf(rawSortValue);
      if (typeCode == 'DT') {
        kc.sortValue = (Datetime) JSON.deserialize('"' + sv + '"', Datetime.class);
      } else if (typeCode == 'D') {
        kc.sortValue = Date.valueOf(sv);
      } else if (typeCode == 'N' || typeCode == 'I') {
        kc.sortValue = Decimal.valueOf(sv);
      } else {
        kc.sortValue = sv;
      }
    }

    return kc;
  }

  private static String buildNextCursor(SObject lastRecord, String fieldName, String direction, Map<String, Schema.SObjectField> fieldMap) {
    if (lastRecord == null) return null;
    Id lastId = (Id) lastRecord.get('Id');
    if (lastId == null) return null;

    Object sortVal = lastRecord.get(fieldName);
    if (sortVal == null) return null;

    String typeCode;
    String sortValueStr;

    if (fieldName.contains('.') || !fieldMap.containsKey(fieldName)) {
      typeCode = 'S';
      sortValueStr = String.valueOf(sortVal);
    } else {
      Schema.DisplayType dt = fieldMap.get(fieldName).getDescribe().getType();
      if (dt == Schema.DisplayType.DateTime) {
        typeCode = 'DT';
        sortValueStr = ((Datetime) sortVal).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
      } else if (dt == Schema.DisplayType.Date) {
        typeCode = 'D';
        sortValueStr = String.valueOf(sortVal);
      } else if (dt == Schema.DisplayType.Currency || dt == Schema.DisplayType.Double || dt == Schema.DisplayType.Percent) {
        typeCode = 'N';
        sortValueStr = String.valueOf(sortVal);
      } else if (dt == Schema.DisplayType.Integer || dt == Schema.DisplayType.Long) {
        typeCode = 'I';
        sortValueStr = String.valueOf(sortVal);
      } else {
        typeCode = 'S';
        sortValueStr = String.valueOf(sortVal);
      }
    }

    Map<String, Object> cursorData = new Map<String, Object>{
      'f' => fieldName,
      'd' => direction,
      't' => typeCode,
      'si' => (String) lastId,
      'sv' => sortValueStr
    };

    return JSON.serialize(cursorData);
  }

  /**
   * Constrói um PagedResult vazio.
   * Centraliza a lógica de retorno antecipado (sem contas, objeto inválido etc.).
   */
  private static PagedResult buildEmptyResult(Integer pageSize) {
    PagedResult result    = new PagedResult();
    result.records        = new List<SObject>();
    result.pageNumber     = 1;
    result.pageSize       = pageSize;
    result.totalSize      = 0;
    result.hasNext        = false;
    result.hasPrev        = false;
    result.nextCursor     = null;
    result.computedValues = null;
    return result;
  }

  /**
   * Emite um log de debug apenas quando o usuário possui a custom permission MD_DEBUG.
   * Em testes, sempre emite (para facilitar diagnóstico em assertions).
   *
   * @param message mensagem descritiva do ponto de execução
   */
  private static void debugLog(String message) {
    Boolean hasDebugPermission = FeatureManagement.checkPermission('MD_DEBUG');
    if (hasDebugPermission || Test.isRunningTest()) {
      System.debug(LoggingLevel.DEBUG, '[md_reportController] ' + message);
    }
  }
}