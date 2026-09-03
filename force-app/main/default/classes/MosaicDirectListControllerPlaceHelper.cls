public without sharing class MosaicDirectListControllerPlaceHelper {
  public static final String MULTIPLE_LABEL = 'Multiple';

  public static String normalizeForCompare(Object o) {
    if (o == null) return null;
    String s = String.valueOf(o).trim();
    if (s == '') return null;
    return s.toLowerCase();
  }

  public class MultipleLinesResult {
    public String modeOfTransportation;
    public String productName;
    public String shippingType;
    public String incoterm;
    public String origin;
    public String shipTo;
    public Id quoteLineId;
  }

  public static MultipleLinesResult analyzeMultipleQuoteLines(List<SObject> listQl) {
    MultipleLinesResult out = new MultipleLinesResult();
    if (listQl == null || listQl.isEmpty()) return out;

    SObject firstQl = listQl[0];
    String firstModeRaw; String firstProdRaw; String firstShipRaw; String firstIncRaw; String firstOriginRaw; String firstShipToRaw;
    try { Object v = firstQl.get('PMC_CPQ_ModeofTransportation__c'); firstModeRaw = v == null ? null : String.valueOf(v).trim(); } catch (Exception ex) { firstModeRaw = null; }
    try { Object v = firstQl.get('SBQQ__ProductName__c'); firstProdRaw = v == null ? null : String.valueOf(v).trim(); } catch (Exception ex) { firstProdRaw = null; }
    try { Object v = firstQl.get('PMC_CPQ_ShippingType__c'); firstShipRaw = v == null ? null : String.valueOf(v).trim(); } catch (Exception ex) { firstShipRaw = null; }
    try { Object v = firstQl.get('PMC_CPQ_Incoterms1__c'); firstIncRaw = v == null ? null : String.valueOf(v).trim(); } catch (Exception ex) { firstIncRaw = null; }
    try {
      SObject loc = (SObject) firstQl.getSObject('PMC_CPQ_ProductLocation__r');
      firstOriginRaw = loc != null ? (String) loc.get('Name') : null;
      if (firstOriginRaw != null) firstOriginRaw = firstOriginRaw.trim();
    } catch (Exception ex) { firstOriginRaw = null; }
    try {
      SObject st = (SObject) firstQl.getSObject('PMC_CPQ_SoldToShipToJunction__r');
      firstShipToRaw = st != null ? (String) st.get('Name') : null;
      if (firstShipToRaw != null) firstShipToRaw = firstShipToRaw.trim();
    } catch (Exception ex) { firstShipToRaw = null; }

    String firstMode = normalizeForCompare(firstModeRaw);
    String firstProd = normalizeForCompare(firstProdRaw);
    String firstShip = normalizeForCompare(firstShipRaw);
    String firstIncoterm = normalizeForCompare(firstIncRaw);
    String firstOrigin = normalizeForCompare(firstOriginRaw);
    String firstShipTo = normalizeForCompare(firstShipToRaw);

    Boolean sameMode = true; Boolean sameProd = true; Boolean sameShip = true; Boolean sameInc = true; Boolean sameOrigin = true; Boolean sameShipTo = true;

    for (Integer i = 1; i < listQl.size(); i++) {
      SObject cur = listQl[i];
      String cModeRaw; String cProdRaw; String cShipRaw; String cIncRaw; String cOrigRaw; String cShipToRaw;
      try { Object v = cur.get('PMC_CPQ_ModeofTransportation__c'); cModeRaw = v == null ? null : String.valueOf(v).trim(); } catch (Exception ex) { cModeRaw = null; }
      try { Object v = cur.get('SBQQ__ProductName__c'); cProdRaw = v == null ? null : String.valueOf(v).trim(); } catch (Exception ex) { cProdRaw = null; }
      try { Object v = cur.get('PMC_CPQ_ShippingType__c'); cShipRaw = v == null ? null : String.valueOf(v).trim(); } catch (Exception ex) { cShipRaw = null; }
      try { Object v = cur.get('PMC_CPQ_Incoterms1__c'); cIncRaw = v == null ? null : String.valueOf(v).trim(); } catch (Exception ex) { cIncRaw = null; }
      try {
        SObject loc = (SObject) cur.getSObject('PMC_CPQ_ProductLocation__r');
        cOrigRaw = loc != null ? (String) loc.get('Name') : null;
        if (cOrigRaw != null) cOrigRaw = cOrigRaw.trim();
      } catch (Exception ex) { cOrigRaw = null; }
      try {
        SObject st = (SObject) cur.getSObject('PMC_CPQ_SoldToShipToJunction__r');
        cShipToRaw = st != null ? (String) st.get('Name') : null;
        if (cShipToRaw != null) cShipToRaw = cShipToRaw.trim();
      } catch (Exception ex) { cShipToRaw = null; }

      String cMode = normalizeForCompare(cModeRaw);
      String cProd = normalizeForCompare(cProdRaw);
      String cShip = normalizeForCompare(cShipRaw);
      String cInc = normalizeForCompare(cIncRaw);
      String cOrig = normalizeForCompare(cOrigRaw);
      String cShipTo = normalizeForCompare(cShipToRaw);

      if (!((firstMode == null && cMode == null) || (firstMode != null && firstMode == cMode))) { sameMode = false; }
      if (!((firstProd == null && cProd == null) || (firstProd != null && firstProd == cProd))) { sameProd = false; }
      if (!((firstShip == null && cShip == null) || (firstShip != null && firstShip == cShip))) { sameShip = false; }
      if (!((firstIncoterm == null && cInc == null) || (firstIncoterm != null && firstIncoterm == cInc))) { sameInc = false; }
      if (!((firstOrigin == null && cOrig == null) || (firstOrigin != null && firstOrigin == cOrig))) { sameOrigin = false; }
      if (!((firstShipTo == null && cShipTo == null) || (firstShipTo != null && firstShipTo == cShipTo))) { sameShipTo = false; }

      if (!sameMode && !sameProd && !sameShip && !sameInc && !sameOrigin && !sameShipTo) break;
    }

    out.modeOfTransportation = sameMode ? firstModeRaw : MULTIPLE_LABEL;
    // Se houver mais de uma QuoteLine, sempre marcar productName como MULTIPLE
    if (listQl.size() > 1) {
      out.productName = MULTIPLE_LABEL;
    } else {
      out.productName = sameProd ? firstProdRaw : MULTIPLE_LABEL;
    }
    out.shippingType = sameShip ? firstShipRaw : MULTIPLE_LABEL;
    out.incoterm = sameInc ? firstIncRaw : MULTIPLE_LABEL;
    out.origin = sameOrigin ? firstOriginRaw : MULTIPLE_LABEL;
    out.shipTo = sameShipTo ? firstShipToRaw : MULTIPLE_LABEL;

    Boolean anyFieldSame = sameMode || sameProd || sameShip || sameInc || sameOrigin || sameShipTo;
    if (anyFieldSame) {
      // Use helper-safe id parsing to avoid casting exceptions when tests inject synthetic id strings
      try { out.quoteLineId = safeIdForHelper(firstQl.get('Id')); } catch (Exception ex) { out.quoteLineId = null; }
    } else {
      out.quoteLineId = null;
    }

    return out;
  }

  // Helper-local safe Id conversion to avoid direct casts from arbitrary SObject.get(...) values.
  // Mirrors the behavior needed for test-injected synthetic ids: return null in Test context for invalid-length strings.
  public static Id safeIdForHelper(Object o) {
    if (o == null) return null;
    try { if (o instanceof Id) return (Id)o; } catch (Exception e) { /* fallthrough */ }
    String s = String.valueOf(o);
    if (s == null) return null;
    Integer l = s.length();
    if (l == 15 || l == 18) {
      try { return (Id) s; } catch (Exception e) { return null; }
    }
    if (Test.isRunningTest()) return null;
    try { return (Id) o; } catch (Exception e) { return null; }
  }

}