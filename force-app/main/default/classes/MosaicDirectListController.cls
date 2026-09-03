public without sharing class MosaicDirectListController {
  @TestVisible
  static Set<Id> TEST_ALLOWED_IDS;

  private static Set<Id> getAllowedAccountIds() {
    if (Test.isRunningTest() && TEST_ALLOWED_IDS != null) {
      return new Set<Id>(TEST_ALLOWED_IDS);
    }
    Set<Id> ids = new Set<Id>();
    for (AccountAccessController.AccountAccessDTO dto : AccountAccessController.getAccessibleAccountsForUser()) {
      if (dto != null && dto.accountId != null) {
        ids.add(dto.accountId);
      }
    }
    return ids;
  }

  @AuraEnabled(cacheable=true)
  public static List<SObject> getRecordsByIds(String objectApiName, List<Id> recordIds, List<String> fieldApiNames) {
    if (recordIds == null || recordIds.isEmpty() || fieldApiNames == null || fieldApiNames.isEmpty()) {
      return new List<SObject>();
    }
    String fieldList = String.join(fieldApiNames, ',');
    String soql = 'SELECT ' + fieldList + ' FROM ' + objectApiName + ' WHERE Id IN :recordIds';
    return Database.query(soql);
  }

  @AuraEnabled(cacheable=false)
  public static List<SObject> searchRecords(
    String objectApiName,
    String filterFieldName,
    String searchTerm,
    List<String> fieldApiNames,
    List<Id> accountIds
  ) {
    Set<Id> allowedIds = getAllowedAccountIds();
    if (allowedIds.isEmpty())
      return new List<SObject>();

    if (accountIds != null && !accountIds.isEmpty()) {
      allowedIds.retainAll(new Set<Id>(accountIds));
      if (allowedIds.isEmpty())
        return new List<SObject>();
    }

    String soqlFields = String.join(fieldApiNames, ',');
    String base = 'SELECT ' + soqlFields + ' FROM ' + objectApiName;

    Schema.SObjectType st = Schema.getGlobalDescribe().get(objectApiName);
    if (st == null)
      return new List<SObject>();
    Map<String, Schema.SObjectField> fmap = st.getDescribe().fields.getMap();

    List<String> whereParts = new List<String>();
    if (fmap.containsKey('AccountId')) {
      whereParts.add('AccountId IN :allowedIds');
    }

    String whereClause = whereParts.isEmpty() ? '' : ' WHERE ' + String.join(whereParts, ' AND ');
    String query = base + whereClause + ' LIMIT 100';
    return Database.query(query);
  }

  @AuraEnabled(cacheable=false)
  public static List<SObject> listRecords(String objectApiName, List<String> fieldApiNames, String whereClause, Integer limitSize) {
    if (limitSize == null || limitSize <= 0)
      limitSize = 200;

    Set<Id> allowedIds = getAllowedAccountIds();
    if (allowedIds.isEmpty())
      return new List<SObject>();

    Schema.SObjectType st = Schema.getGlobalDescribe().get(objectApiName);
    if (st == null)
      return new List<SObject>();
    Map<String, Schema.SObjectField> fmap = st.getDescribe().fields.getMap();

    List<String> whereParts = new List<String>();
    if (!String.isBlank(whereClause))
      whereParts.add('(' + whereClause + ')');
    if (fmap.containsKey('AccountId'))
      whereParts.add('AccountId IN :allowedIds');

    String soql = 'SELECT ' + String.join(fieldApiNames, ',') + ' FROM ' + objectApiName;
    if (!whereParts.isEmpty()) {
      soql += ' WHERE ' + String.join(whereParts, ' AND ');
    }
    soql += ' LIMIT ' + limitSize;

    return Database.query(soql);
  }

  public class PagedResult {
    @AuraEnabled
    public List<SObject> records;
    @AuraEnabled
    public Integer pageNumber;
    @AuraEnabled
    public Integer pageSize;
    @AuraEnabled
    public Integer totalSize;
    @AuraEnabled
    public Boolean hasNext;
    @AuraEnabled
    public Boolean hasPrev;
    @AuraEnabled
    public Map<Id, Map<String, String>> computedValues;
  }

  private class DateWhere {
    String soql;
    Date fromDate;
    Date toDate;
    Datetime fromGmt;
    Datetime toGmtNext;
  }

  private static DateWhere buildDatePredicate(
    Map<String, Schema.SObjectField> fmap,
    String dateFieldName, // nome dinâmico do campo "início" (p.ex. ContractStart__c)
    String endDateFieldName, // nome dinâmico do campo "fim"    (p.ex. ContractEnd__c)
    String dateFromYmd, // "YYYY-MM-DD"
    String dateToYmd, // "YYYY-MM-DD"
    String timezoneId
  ) {
    DateWhere dw = new DateWhere();

    // Sem parâmetros de campos e sem limites -> sem filtro
    if (String.isBlank(dateFieldName) && String.isBlank(endDateFieldName))
      return dw;
    if (String.isBlank(dateFromYmd) && String.isBlank(dateToYmd))
      return dw;

    Date fromD = String.isBlank(dateFromYmd) ? null : Date.valueOf(dateFromYmd);
    Date toD = String.isBlank(dateToYmd) ? null : Date.valueOf(dateToYmd);
    if (fromD != null && toD != null && fromD > toD) {
      Date t = fromD;
      fromD = toD;
      toD = t;
    }

    // Resolve campos existentes dinamicamente
    String startF = (!String.isBlank(dateFieldName) && fmap.containsKey(dateFieldName)) ? dateFieldName : null;
    String endF = (!String.isBlank(endDateFieldName) && fmap.containsKey(endDateFieldName)) ? endDateFieldName : null;
    if (startF == null && endF == null)
      return dw;

    Schema.DisplayType tStart = (startF != null) ? fmap.get(startF).getDescribe().getType() : null;
    Schema.DisplayType tEnd = (endF != null) ? fmap.get(endF).getDescribe().getType() : null;

    if (String.isBlank(timezoneId))
      timezoneId = 'America/New_York';
    TimeZone tz = TimeZone.getTimeZone(timezoneId);

    // Pré-calcula janelas DateTime
    Datetime fromGmt = null, toGmtNext = null;
    if (fromD != null) {
      Datetime fromLocalMidnightGmt = Datetime.newInstanceGmt(fromD.year(), fromD.month(), fromD.day(), 0, 0, 0);
      fromGmt = fromLocalMidnightGmt.addSeconds(-(tz.getOffset(fromLocalMidnightGmt) / 1000));
    }
    if (toD != null) {
      Date toPlus1 = toD.addDays(1);
      Datetime toLocalMidnightNextGmt = Datetime.newInstanceGmt(toPlus1.year(), toPlus1.month(), toPlus1.day(), 0, 0, 0);
      toGmtNext = toLocalMidnightNextGmt.addSeconds(-(tz.getOffset(toLocalMidnightNextGmt) / 1000));
    }

    dw.fromDate = fromD;
    dw.toDate = toD;
    dw.fromGmt = fromGmt;
    dw.toGmtNext = toGmtNext;

    if (fromD != null && toD != null) {
      if (startF != null && endF != null) {
        if (tStart == Schema.DisplayType.DateTime && tEnd == Schema.DisplayType.DateTime) {
          dw.soql = '(' + startF + ' >= :fromGmt AND ' + endF + ' < :toGmtNext)';
          return dw;
        } else if (tStart == Schema.DisplayType.Date && tEnd == Schema.DisplayType.Date) {
          dw.soql = '(' + startF + ' >= :fromDate AND ' + endF + ' <= :toDate)';
          return dw;
        } else {
          String startCond = (tStart == Schema.DisplayType.DateTime) ? startF + ' >= :fromGmt' : startF + ' >= :fromDate';
          String endCond = (tEnd == Schema.DisplayType.DateTime) ? endF + ' < :toGmtNext' : endF + ' <= :toDate';
          dw.soql = '(' + startCond + ' AND ' + endCond + ')';
          return dw;
        }
      }
      if (startF != null) {
        dw.soql = (tStart == Schema.DisplayType.DateTime)
          ? '(' + startF + ' >= :fromGmt AND ' + startF + ' < :toGmtNext)'
          : '(' + startF + ' >= :fromDate AND ' + startF + ' <= :toDate)';
        return dw;
      }
      if (endF != null) {
        dw.soql = (tEnd == Schema.DisplayType.DateTime)
          ? '(' + endF + ' >= :fromGmt AND ' + endF + ' < :toGmtNext)'
          : '(' + endF + ' >= :fromDate AND ' + endF + ' <= :toDate)';
        return dw;
      }
      return dw;
    }

    if (fromD != null) {
      if (startF != null) {
        dw.soql = (tStart == Schema.DisplayType.DateTime) ? '(' + startF + ' >= :fromGmt)' : '(' + startF + ' >= :fromDate)';
        return dw;
      }
      if (endF != null) {
        dw.soql = (tEnd == Schema.DisplayType.DateTime) ? '(' + endF + ' >= :fromGmt)' : '(' + endF + ' >= :fromDate)';
        return dw;
      }
      return dw;
    }

    if (toD != null) {
      if (endF != null) {
        dw.soql = (tEnd == Schema.DisplayType.DateTime) ? '(' + endF + ' < :toGmtNext)' : '(' + endF + ' <= :toDate)';
        return dw;
      }
      if (startF != null) {
        dw.soql = (tStart == Schema.DisplayType.DateTime) ? '(' + startF + ' < :toGmtNext)' : '(' + startF + ' <= :toDate)';
        return dw;
      }
    }

    return dw;
  }

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
    String timezoneId
  ) {
    if (pageSize == null || pageSize <= 0)
      pageSize = 50;
    if (pageNumber == null || pageNumber <= 0)
      pageNumber = 1;

    Set<Id> allowedIds = getAllowedAccountIds();
    System.debug('allowedIds:: ' + allowedIds);

    if (allowedIds.isEmpty()) {
      PagedResult emptyRes = new PagedResult();
      emptyRes.records = new List<SObject>();
      emptyRes.pageNumber = 1;
      emptyRes.pageSize = pageSize;
      emptyRes.totalSize = 0;
      emptyRes.hasPrev = false;
      emptyRes.hasNext = false;
      return emptyRes;
    }

    System.debug('objectApiName:: ' + objectApiName);

    Schema.SObjectType st = Schema.getGlobalDescribe().get(objectApiName);
    if (st == null) {
      PagedResult emptyRes = new PagedResult();
      emptyRes.records = new List<SObject>();
      emptyRes.pageNumber = 1;
      emptyRes.pageSize = pageSize;
      emptyRes.totalSize = 0;
      emptyRes.hasPrev = false;
      emptyRes.hasNext = false;
      return emptyRes;
    }
    Map<String, Schema.SObjectField> fmap = st.getDescribe().fields.getMap();

    String orderExpr = 'LastModifiedDate';
    if (!String.isBlank(orderByField)) {
      String ob = orderByField.trim();
      if (ob.replaceAll('[A-Za-z0-9_\\.]+', '') == '') {
        orderExpr = ob;
      }
    }
    String dir = (orderDir != null && orderDir.toUpperCase() == 'ASC') ? 'ASC' : 'DESC';

    Set<String> topLevelFields = new Set<String>();
    Set<String> qlSimpleFields = new Set<String>(); // ex: PMC_CPQ_FinalPricePerTon__c
    Set<String> qlRelPaths = new Set<String>(); // ex: PMC_CPQ_SoldToShipToJunction__r.Name

    if (fieldApiNames != null) {
      Schema.SObjectType qlType = Schema.getGlobalDescribe().get('SBQQ__QuoteLine__c');
      Map<String, Schema.SObjectField> qlMap = (qlType == null) ? new Map<String, Schema.SObjectField>() : qlType.getDescribe().fields.getMap();

      for (String f : fieldApiNames) {
        if (String.isBlank(f))
          continue;

        if (f.startsWith('SBQQ__LineItems__r.')) {
          Integer dot = f.indexOf('.');
          String lineFieldFull = (dot >= 0 && dot < f.length() - 1) ? f.substring(dot + 1) : null;
          if (String.isBlank(lineFieldFull))
            continue;

          if (lineFieldFull.contains('__r.')) {
            qlRelPaths.add(lineFieldFull);
          } else {
            if (lineFieldFull.indexOf('.') == -1 && qlMap.containsKey(lineFieldFull)) {
              qlSimpleFields.add(lineFieldFull);
            }
          }
        } else {
          topLevelFields.add(f.trim());
        }
      }
    }

    // Campos do SELECT principal
    topLevelFields.add(orderExpr);
    topLevelFields.add('Id');
    Set<String> seenLower = new Set<String>();
    List<String> dedupedFields = new List<String>();
    for (String f : topLevelFields) {
      String normalized = f.replaceAll('[^A-Za-z0-9_.]', '');
      if (String.isBlank(normalized)) continue;
      if (seenLower.add(normalized.toLowerCase())) {
        dedupedFields.add(normalized);
      }
    }
    String fieldList = String.join(dedupedFields, ',');

    // WHERE base
    List<String> whereParts = new List<String>();
    if (!String.isBlank(whereClause))
      whereParts.add('(' + whereClause + ')');
    String accountField = null;
    if (fmap.containsKey('AccountId')) {
      accountField = 'AccountId';
    } else if (fmap.containsKey('SBQQ__Account__c')) {
      accountField = 'SBQQ__Account__c';
    } else if (fmap.containsKey('Account__c')) {
      accountField = 'Account__c';
    }
    if (accountField != null)
      whereParts.add(accountField + ' IN :allowedIds');

    String likeParam;
    if (!String.isBlank(searchTerm) && searchFieldApiNames != null && !searchFieldApiNames.isEmpty()) {
      List<String> ors = new List<String>();
      likeParam = '%' + searchTerm + '%';

      for (String f : searchFieldApiNames) {
        if (String.isBlank(f))
          continue;
        if (f.startsWith('SBQQ__LineItems__r.'))
          continue; // não dá pra buscar texto em linhas aqui
        if (f.replaceAll('[A-Za-z0-9_\\.]+', '') != '')
          continue;

        if (f.contains('.')) {
          ors.add(f + ' LIKE :likeParam');
        } else {
          if (!fmap.containsKey(f))
            continue;
          Schema.DisplayType t = fmap.get(f).getDescribe().getType();
          if (
            t == Schema.DisplayType.String ||
            t == Schema.DisplayType.TextArea ||
            t == Schema.DisplayType.Phone ||
            t == Schema.DisplayType.Email ||
            t == Schema.DisplayType.Picklist ||
            t == Schema.DisplayType.Multipicklist ||
            t == Schema.DisplayType.Url
          ) {
            ors.add(f + ' LIKE :likeParam');
          }
        }
      }
      if (!ors.isEmpty())
        whereParts.add('(' + String.join(ors, ' OR ') + ')');
    }

    // ===== Filtro de DATA =====
    DateWhere dateWhere = buildDatePredicate(fmap, dateFilterFieldName, endDateFilterFieldName, dateFromYmd, dateToYmd, timezoneId);

    Date fromDate = (dateWhere != null) ? dateWhere.fromDate : null;
    Date toDate = (dateWhere != null) ? dateWhere.toDate : null;
    Datetime fromGmt = (dateWhere != null) ? dateWhere.fromGmt : null;
    Datetime toGmtNext = (dateWhere != null) ? dateWhere.toGmtNext : null;

    if (dateWhere != null && !String.isBlank(dateWhere.soql)) {
      whereParts.add(dateWhere.soql);
    }

    String whereSql = whereParts.isEmpty() ? '' : ' WHERE ' + String.join(whereParts, ' AND ');

    System.debug('whereSql:: ' + whereSql);

    // System.debug('whereSQL:: ' + whereSql);
    // whereSql = whereSql.replace('(Delivery_RecordTyeName = \'FPD_Delivery\') AND ', ''); // PALIATIVO

    Integer totalSize = Database.countQuery('SELECT COUNT() FROM ' + objectApiName + whereSql);
    Integer offsetVal = (pageNumber - 1) * pageSize;

    String soql =
      'SELECT ' +
      fieldList +
      ' FROM ' +
      objectApiName +
      whereSql +
      ' ORDER BY ' +
      orderExpr +
      ' ' +
      dir +
      ', Id ' +
      dir +
      ' LIMIT ' +
      pageSize +
      ' OFFSET ' +
      offsetVal;

    List<SObject> recs = new List<SObject>();

    System.debug('soql:: ' + soql);

    try {
      recs = Database.query(soql);
    } catch (Exception ex) {
      System.debug('Erro ao executar SOQL: ' + ex.getMessage());
    }

    Map<Id, Map<String, String>> computedValues;

    if (
      objectApiName != null &&
      objectApiName.equalsIgnoreCase('SBQQ__Quote__c') &&
      (!qlSimpleFields.isEmpty() || !qlRelPaths.isEmpty()) &&
      !recs.isEmpty()
    ) {
      Set<Id> quoteIds = new Set<Id>();
      for (SObject r : recs) {
        Id rid = (Id) r.get('Id');
        if (rid != null)
          quoteIds.add(rid);
      }

      if (!quoteIds.isEmpty()) {
        // Monta campos do SELECT em QuoteLine (simples + relacionamento)
        List<String> qlSelectPieces = new List<String>();
        qlSelectPieces.add('SBQQ__Quote__c');
        if (!qlSimpleFields.isEmpty())
          qlSelectPieces.add(String.join(new List<String>(qlSimpleFields), ','));
        if (!qlRelPaths.isEmpty())
          qlSelectPieces.add(String.join(new List<String>(qlRelPaths), ','));
        String qlFieldList = String.join(qlSelectPieces, ',');

        List<SObject> qls = Database.query('SELECT ' + qlFieldList + ' FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :quoteIds');

        Map<Id, List<SObject>> byQuote = new Map<Id, List<SObject>>();
        for (SObject ln : qls) {
          Id qid = (Id) ln.get('SBQQ__Quote__c');
          if (qid == null)
            continue;
          List<SObject> bucket = byQuote.get(qid);
          if (bucket == null) {
            bucket = new List<SObject>();
            byQuote.put(qid, bucket);
          }
          bucket.add(ln);
        }

        final String SPECIAL_PRICE_FIELD = 'PMC_CPQ_FinalPricePerTon__c';

        computedValues = new Map<Id, Map<String, String>>();
        for (Id qid : quoteIds) {
          List<SObject> lines = byQuote.get(qid);
          if (lines == null)
            lines = new List<SObject>();

          Map<String, String> perField = new Map<String, String>();

          for (String lf : qlSimpleFields) {
            Set<String> uniq = new Set<String>();
            Boolean sawNull = false;
            Integer nonNullCount = 0;

            for (SObject ln : lines) {
              Object v = ln.get(lf);
              if (v == null) {
                sawNull = true;
              } else {
                nonNullCount++;
                uniq.add(String.valueOf(v));
              }
            }

            String resolved;
            if (lf == SPECIAL_PRICE_FIELD) {
              if (nonNullCount > 1)
                resolved = 'MULTIPLE';
              else if (nonNullCount == 1)
                resolved = uniq.isEmpty() ? null : uniq.iterator().next();
              else
                resolved = null;
            } else {
              if (uniq.isEmpty() && sawNull)
                resolved = null;
              else if (!sawNull && uniq.size() == 1)
                resolved = uniq.iterator().next();
              else if (!sawNull && uniq.isEmpty())
                resolved = null;
              else
                resolved = 'MULTIPLE';
            }

            perField.put('SBQQ__LineItems__r.' + lf, resolved);
          }

          for (String relPath : qlRelPaths) {
            Integer idx = relPath.indexOf('.');
            String relName = (idx > 0) ? relPath.substring(0, idx) : relPath;
            String relField = (idx > 0 && idx < relPath.length() - 1) ? relPath.substring(idx + 1) : 'Name';

            Set<String> uniq = new Set<String>();
            Boolean sawNull = false;
            Integer nonNullCount = 0;

            for (SObject ln : lines) {
              SObject rel = (SObject) ln.getSObject(relName);
              Object v = (rel == null) ? null : rel.get(relField);
              if (v == null) {
                sawNull = true;
              } else {
                nonNullCount++;
                uniq.add(String.valueOf(v));
              }
            }

            String resolved;
            if (uniq.isEmpty() && sawNull)
              resolved = null;
            else if (!sawNull && uniq.size() == 1)
              resolved = uniq.iterator().next();
            else if (!sawNull && uniq.isEmpty())
              resolved = null;
            else
              resolved = 'MULTIPLE';

            perField.put('SBQQ__LineItems__r.' + relPath, resolved);
          }

          computedValues.put(qid, perField);
        }
      }
    }

    PagedResult pr = new PagedResult();
    pr.records = recs;
    pr.pageNumber = pageNumber;
    pr.pageSize = pageSize;
    pr.totalSize = totalSize;
    pr.hasPrev = pageNumber > 1;
    pr.hasNext = offsetVal + recs.size() < totalSize;
    pr.computedValues = computedValues;
    return pr;
  }

  public class InTransitFilterOptionsResult {
    @AuraEnabled
    public List<String> products;
    @AuraEnabled
    public List<String> origins;
    @AuraEnabled
    public List<String> shipTos;
    @AuraEnabled
    public List<String> destinations;
    @AuraEnabled
    public List<String> statuses;
  }

  private static String escapeSoqlLiteral(String value) {
    return String.escapeSingleQuotes(String.valueOf(value));
  }

  private static String buildInClause(String fieldName, List<String> values) {
    if (String.isBlank(fieldName) || values == null || values.isEmpty())
      return null;
    List<String> quoted = new List<String>();
    for (String v : values) {
      if (String.isBlank(v))
        continue;
      quoted.add('\'' + escapeSoqlLiteral(v.trim()) + '\'');
    }
    if (quoted.isEmpty())
      return null;
    return fieldName + ' IN (' + String.join(quoted, ',') + ')';
  }

  private static String buildLikeClause(String fieldName, String value) {
    if (String.isBlank(fieldName) || String.isBlank(value))
      return null;
    return fieldName + ' LIKE \'%' + escapeSoqlLiteral(value.trim()) + '%\'';
  }

  private static String combineWhere(String baseWhere, List<String> additionalParts) {
    List<String> parts = new List<String>();
    if (!String.isBlank(baseWhere))
      parts.add('(' + baseWhere + ')');
    if (additionalParts != null) {
      for (String p : additionalParts) {
        if (!String.isBlank(p))
          parts.add('(' + p + ')');
      }
    }
    return parts.isEmpty() ? '' : String.join(parts, ' AND ');
  }

  @AuraEnabled(cacheable=false)
  public static InTransitFilterOptionsResult getInTransitFilterOptions(
    String objectApiName,
    String baseWhereClause,
    String orderNumber,
    String vehicleId,
    String contract,
    String poNumber
  ) {
    InTransitFilterOptionsResult result = new InTransitFilterOptionsResult();
    result.products = new List<String>();
    result.origins = new List<String>();
    result.shipTos = new List<String>();
    result.destinations = new List<String>();
    result.statuses = new List<String>();

    if (String.isBlank(objectApiName) || !objectApiName.equalsIgnoreCase('ShipmentItem'))
      return result;

    List<String> additionalParts = new List<String>();
    additionalParts.add(buildLikeClause('PMC_CPQ_OrderProduct__r.Order.PMC_CPQ_SAPOrderNumber__c', orderNumber));
    additionalParts.add(buildLikeClause('Shipment.PMC_CPQ_VehicleID__c', vehicleId));
    additionalParts.add(buildLikeClause('PMC_CPQ_OrderProduct__r.SBQQ__Contract__r.SBQQ__Quote__r.Name', contract));
    additionalParts.add(buildLikeClause('PMC_CPQ_OrderProduct__r.PMC_CPQ_LinePONumber__c', poNumber));

    String whereClause = combineWhere(baseWhereClause, additionalParts);
    String soql =
      'SELECT Product2.Name, PMC_CPQ_ProductLocation__r.Name, Shipment.PMC_CPQ_Account__r.ShipToFormula__c, Shipment.DestinationFormula__c, Shipment.StatusCode__c ' +
      'FROM ' +
      objectApiName +
      (String.isBlank(whereClause) ? '' : ' WHERE ' + whereClause) +
      ' LIMIT 2000';

    Set<String> products = new Set<String>();
    Set<String> origins = new Set<String>();
    Set<String> shipTos = new Set<String>();
    Set<String> destinations = new Set<String>();
    Set<String> statuses = new Set<String>();

    for (SObject row : Database.query(soql)) {
      SObject product2 = row.getSObject('Product2');
      if (product2 != null) {
        String productName = (String) product2.get('Name');
        if (!String.isBlank(productName))
          products.add(productName);
      }

      SObject shipment = row.getSObject('Shipment');
      SObject productLocation = row.getSObject('PMC_CPQ_ProductLocation__r');
      if (productLocation != null) {
        String origin = (String) productLocation.get('Name');
        if (!String.isBlank(origin))
          origins.add(origin);
      }

      if (shipment != null) {
        SObject shipAccount = shipment.getSObject('PMC_CPQ_Account__r');
        if (shipAccount != null) {
          String shipTo = (String) shipAccount.get('ShipToFormula__c');
          if (!String.isBlank(shipTo))
            shipTos.add(shipTo);
        }

        String destination = (String) shipment.get('DestinationFormula__c');
        if (!String.isBlank(destination))
          destinations.add(destination);

        String status = (String) shipment.get('StatusCode__c');
        if (!String.isBlank(status))
          statuses.add(status);
      }
    }

    result.products.addAll(products);
    result.origins.addAll(origins);
    result.shipTos.addAll(shipTos);
    result.destinations.addAll(destinations);
    result.statuses.addAll(statuses);

    result.products.sort();
    result.origins.sort();
    result.shipTos.sort();
    result.destinations.sort();
    result.statuses.sort();

    return result;
  }

  @AuraEnabled(cacheable=false)
  public static PagedResult listInTransitRecordsPaged(
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
    String orderNumber,
    String vehicleId,
    String contract,
    String poNumber,
    List<String> products,
    List<String> origins,
    List<String> shipTos,
    List<String> destinations,
    List<String> statuses
  ) {
    if (String.isBlank(objectApiName) || !objectApiName.equalsIgnoreCase('ShipmentItem')) {
      return listRecordsPaged(
        objectApiName,
        fieldApiNames,
        whereClause,
        orderByField,
        orderDir,
        pageSize,
        pageNumber,
        searchTerm,
        searchFieldApiNames,
        dateFilterFieldName,
        endDateFilterFieldName,
        dateFromYmd,
        dateToYmd,
        timezoneId
      );
    }

    List<String> additionalParts = new List<String>();
    additionalParts.add(buildLikeClause('PMC_CPQ_OrderProduct__r.Order.PMC_CPQ_SAPOrderNumber__c', orderNumber));
    additionalParts.add(buildLikeClause('Shipment.PMC_CPQ_VehicleID__c', vehicleId));
    additionalParts.add(buildLikeClause('PMC_CPQ_OrderProduct__r.SBQQ__Contract__r.SBQQ__Quote__r.Name', contract));
    additionalParts.add(buildLikeClause('PMC_CPQ_OrderProduct__r.PMC_CPQ_LinePONumber__c', poNumber));
    additionalParts.add(buildInClause('Product2.Name', products));
    additionalParts.add(buildInClause('PMC_CPQ_ProductLocation__r.Name', origins));
    additionalParts.add(buildInClause('Shipment.PMC_CPQ_Account__r.ShipToFormula__c', shipTos));
    additionalParts.add(buildInClause('Shipment.DestinationFormula__c', destinations));
    additionalParts.add(buildInClause('Shipment.StatusCode__c', statuses));

    String mergedWhere = combineWhere(whereClause, additionalParts);

    return listRecordsPaged(
      objectApiName,
      fieldApiNames,
      mergedWhere,
      orderByField,
      orderDir,
      pageSize,
      pageNumber,
      searchTerm,
      searchFieldApiNames,
      dateFilterFieldName,
      endDateFilterFieldName,
      dateFromYmd,
      dateToYmd,
      timezoneId
    );
  }
}