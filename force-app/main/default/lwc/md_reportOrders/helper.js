const getLocalDateStr = (date) => {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
};

const today = new Date();
const threeMonthsAgo = new Date();
threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

export const EMPTY_FILTERS = Object.freeze({
  orderNumber: "",
  poNumber: "",
  dataInicio: getLocalDateStr(threeMonthsAgo),
  dataFim: getLocalDateStr(today),
  orderStatus: [],
  product: [],
  origin: [],
  shipTo: []
});

export const EMPTY_FILTER_OPTIONS = Object.freeze({
  orderStatus: [],
  product: [],
  origin: [],
  shipTo: []
});

export const toOptions = (values = []) => (values || []).map((v) => ({ label: v, value: v }));

export const normalizeFilters = (raw = {}) => ({
  dataInicio: raw.dataInicio || "",
  dataFim: raw.dataFim || "",
  orderNumber: raw.orderNumber || "",
  poNumber: raw.poNumber || "",
  orderStatus: Array.isArray(raw.orderStatus) ? raw.orderStatus : [],
  product: Array.isArray(raw.product) ? raw.product : [],
  origin: Array.isArray(raw.origin) ? raw.origin : [],
  shipTo: Array.isArray(raw.shipTo) ? raw.shipTo : []
});

export const buildOrderWhereClause = (filters) => {
  const esc = (v) => String(v || "").replace(/'/g, "\\'");
  const f = filters;

  const conditions = [];

  if (f.dataInicio || f.dataFim) {
    const dateConds = [];
    if (f.dataInicio) dateConds.push(`Order.PMC_DH_SAPOrderCreatedDate__c >= ${f.dataInicio}`);
    if (f.dataFim) dateConds.push(`Order.PMC_DH_SAPOrderCreatedDate__c <= ${f.dataFim}`);
    conditions.push(`(${dateConds.join(" AND ")})`);
  }
  if (f.orderNumber)
    conditions.push(
      `PMC_CPQ_SAPOrderLineID__c LIKE '%${esc(f.orderNumber.length === 12 ? `${f.orderNumber.slice(0, 8)}_${f.orderNumber.slice(8).replace(/^0+/, "") || "0"}` : f.orderNumber)}%'`
    );
  if (f.poNumber) conditions.push(`PMC_CPQ_LinePONumber__c LIKE '%${esc(f.poNumber)}%'`);
  if (f.orderStatus?.length) {
    const hasOpen = f.orderStatus.includes("Open");
    const hasShipped = f.orderStatus.includes("Shipped");
    if (hasOpen && !hasShipped) {
      conditions.push(`PMC_CPQ_OrderLineStatus__c != 'Shipped'`);
    } else if (!hasOpen && hasShipped) {
      conditions.push(`PMC_CPQ_OrderLineStatus__c = 'Shipped'`);
    }
  }
  if (f.product?.length) conditions.push(`Product2.Name IN (${f.product.map((v) => `'${esc(v)}'`).join(",")})`);
  if (f.origin?.length) conditions.push(`PMC_CPQ_ProductLocation__r.Name IN (${f.origin.map((v) => `'${esc(v)}'`).join(",")})`);
  if (f.shipTo?.length) conditions.push(`PMC_CPQ_ShipTo__r.ShipToFormula__c IN (${f.shipTo.map((v) => `'${esc(v)}'`).join(",")})`);

  return conditions.join(" AND ");
};