export const EMPTY_FILTERS = Object.freeze({
    contractNumber: "",
    poNumber: "",
    status: [],
    startDate: "",
    endDate: "",
    contractType: [],
    product: [],
    origin: [],
    shipTo: []
});

export const EMPTY_FILTER_OPTIONS = Object.freeze({
    status: ["Open", "Expired", "Completed"],
    contractType: [],
    product: [],
    origin: [],
    shipTo: []
});

export const toOptions = (values = []) =>
    (values || []).map((v) => ({ label: v, value: v }));

export const normalizeFilters = (raw = {}) => ({
    contractNumber: raw.contractNumber || "",
    poNumber: raw.poNumber || "",
    status: Array.isArray(raw.status) ? raw.status : [],
    startDate: raw.startDate || "",
    endDate: raw.endDate || "",
    contractType: Array.isArray(raw.contractType) ? raw.contractType : [],
    product: Array.isArray(raw.product) ? raw.product : [],
    origin: Array.isArray(raw.origin) ? raw.origin : [],
    shipTo: Array.isArray(raw.shipTo) ? raw.shipTo : []
});

export const validateDate = (dateStr) => {
    if (!dateStr || typeof dateStr !== "string") return null;
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) return null;
    const [year, month, day] = dateStr.split("-").map(Number);
    if (year < 1900 || year > 2100 || month < 1 || month > 12 || day < 1 || day > 31) return null;
    return dateStr;
};

export const buildContractWhereClause = (filters) => {
    const conditions = [];
    const esc = (v) => String(v || "").replace(/'/g, "\\'");
    const f = filters;

    if (f.contractNumber) conditions.push(`SBQQ__Quote__r.PMC_CLM_DocumentNumber__c LIKE '%${esc(f.contractNumber)}%'`);
    if (f.poNumber) conditions.push(`SBQQ__Quote__r.PMC_CPQ_PO__c LIKE '%${esc(f.poNumber)}%'`);
    if (f.contractType?.length) conditions.push(`SBQQ__Quote__r.PMC_CPQ_ContractType__c IN (${f.contractType.map((v) => `'${esc(v)}'`).join(",")})`);
    if (f.product?.length) conditions.push(`SBQQ__ProductName__c IN (${f.product.map((v) => `'${esc(v)}'`).join(",")})`);
    if (f.origin?.length) conditions.push(`PMC_CPQ_ProductLocation__r.Name IN (${f.origin.map((v) => `'${esc(v)}'`).join(",")})`);
    if (f.shipTo?.length) conditions.push(`PMC_CPQ_ShipTo__r.ShipToFormula__c IN (${f.shipTo.map((v) => `'${esc(v)}'`).join(",")})`);

    const filterStart = validateDate(f.startDate);
    if (filterStart) conditions.push(`SBQQ__Quote__r.PMC_CPQ_ContractStart__c >= ${filterStart}`);
    const filterEnd = validateDate(f.endDate);
    if (filterEnd) conditions.push(`SBQQ__Quote__r.PMC_CPQ_ContractEnd__c <= ${filterEnd}`);

    return conditions.join(" AND ");
};

export const computeContractStatus = (startDate, endDate, remainingQty) => {
    if (remainingQty != null && remainingQty <= 0) return "Completed";

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    if (endDate) {
        const end = new Date(endDate);
        if (today > end) return "Expired";
    }

    return "Open";
};

export const formatQuantity = (val) => {
    if (val == null || val === "") return "";
    return new Intl.NumberFormat("en-US", { minimumFractionDigits: 3, maximumFractionDigits: 3 }).format(val);
};

export const formatPrice = (val) => {
    if (val == null || val === "") return "";
    return new Intl.NumberFormat("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(val);
};

export const stripQPrefix = (val) => {
    if (!val || typeof val !== "string") return val;
    return val.startsWith("Q-") ? val.slice(2) : val;
};

export const formatDate = (dateStr) => {
    if (!dateStr) return "";
    const parts = String(dateStr).split("-").map(Number);
    if (parts.length !== 3 || parts.some(isNaN)) return "";
    const [year, month, day] = parts;
    return new Intl.DateTimeFormat("en-US", { month: "2-digit", day: "2-digit", year: "numeric" }).format(new Date(year, month - 1, day));
};

export const ensureFields = (base = [], ...maybeFields) => {
    const set = new Set(base);
    maybeFields.filter(Boolean).forEach((f) => set.add(f));
    return Array.from(set);
};

const getValueFromPath = (obj, path) => {
    if (!path) return null;
    return path.split(".").reduce((o, k) => (o == null ? null : o[k]), obj);
};

export const mapRecordsToRows = (records = [], columns = [], extraPaths = []) => {
    return (records || []).map((r) => {
        const row = { Id: r.Id };
        columns.forEach((col) => {
            row[col.fieldName] = getValueFromPath(r, col.fieldName);
        });
        (extraPaths || []).filter(Boolean).forEach((p) => {
            if (row[p] === undefined) row[p] = getValueFromPath(r, p);
        });
        return row;
    });
};