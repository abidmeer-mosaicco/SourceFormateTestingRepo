export function getValueFromPath(obj, path) {
  if (!path) return null;
  return path.split(".").reduce((acc, key) => (acc == null ? null : acc[key]), obj);
}

export const MULTIPLE = "MULTIPLE";
export const QL_FIELDS = [
  "SBQQ__ProductName__c",
  "PMC_CPQ_ModeofTransportation__c",
  "PMC_CPQ_ShippingType__c",
  "PMC_CPQ_Incoterms1__c",
  "PMC_CPQ_ProductLocation__c",
  "PMC_CPQ_SoldToShipToJunction__c"
];

export function fixUserDateFormat(input) {
  if (!input) return input;
  const normalized = String(input).trim().replace(/\s+/g, " ");
  const match = normalized.match(/^(\d{1,2})\s*([A-Za-zÀ-ÿ]+)\s*,?\s*(\d{4})$/);
  if (!match) return input;

  const day = String(parseInt(match[1], 10));
  const month3 = match[2].slice(0, 3).toLowerCase();
  const monthTitle = month3.charAt(0).toUpperCase() + month3.slice(1);
  const year = match[3];

  return `${monthTitle} ${day}, ${year}`;
}

export function _escapeId(id) {
  return `'${String(id).replace(/'/g, "\\'")}'`;
}

const isDateFieldName = (name) => {
  const normalized = (name || "").toLowerCase();
  return normalized.includes("date") || normalized.endsWith("start__c") || normalized.endsWith("end__c");
};

export function buildColumnsFromListView(displayColumns = [], listRefId) {
  return displayColumns.map((column) => ({
    label: column.label,
    fieldName: column.fieldApiName,
    type: column.fieldApiName.endsWith("Date") || isDateFieldName(column.fieldApiName) ? "date-local" : "text",
    editable: !!column.inlineEditAttributes?.[listRefId]?.editable,
    ...(column.fieldApiName.endsWith("Date") || isDateFieldName(column.fieldApiName)
      ? { typeAttributes: { year: "numeric", month: "short", day: "2-digit" } }
      : {})
  }));
}

export function buildManualColumns(manualFields = [], manualLabels = []) {
  const labels = Array.isArray(manualLabels) ? manualLabels : [];

  return (manualFields || []).map((apiName, index) => {
    const override = (labels[index] ?? "").toString().trim();
    const label = override || apiName.split(".").slice(-1)[0];

    if (isDateFieldName(apiName)) {
      return {
        label,
        fieldName: apiName,
        type: "date-local",
        editable: false,
        typeAttributes: {
          year: "numeric",
          month: "short",
          day: "2-digit"
        }
      };
    }

    return { label, fieldName: apiName, type: "text", editable: false, wrapText: true };
  });
}

export function ensureFields(base = [], ...maybeFields) {
  const set = new Set(base);
  maybeFields.filter(Boolean).forEach((fieldName) => set.add(fieldName));
  return Array.from(set);
}

export function mapRecordsToRows(records = [], columns = [], extraPaths = []) {
  return (records || []).map((record) => {
    const row = { Id: record.Id };

    columns.forEach((column) => {
      row[column.fieldName] = getValueFromPath(record, column.fieldName);
    });

    (extraPaths || []).filter(Boolean).forEach((path) => {
      if (row[path] === undefined) row[path] = getValueFromPath(record, path);
    });

    return row;
  });
}

const TZ_NY = "America/New_York";

function toYmdInNY(value) {
  if (!value) return null;

  if (typeof value === "string") {
    const normalized = value.trim();
    if (/^\d{4}-\d{2}-\d{2}$/.test(normalized)) return normalized;

    const match = normalized.match(/^([A-Za-z]+)\s+(\d{1,2}),\s*(\d{4})$/);
    if (match) {
      const months = {
        jan: "01",
        feb: "02",
        mar: "03",
        apr: "04",
        may: "05",
        jun: "06",
        jul: "07",
        aug: "08",
        sep: "09",
        sept: "09",
        oct: "10",
        nov: "11",
        dec: "12"
      };
      const monthKey = match[1].toLowerCase();
      const month = months[monthKey.slice(0, 4)] || months[monthKey.slice(0, 3)];
      if (month) {
        const day = String(parseInt(match[2], 10)).padStart(2, "0");
        return `${match[3]}-${month}-${day}`;
      }
    }
  }

  const dateValue = value instanceof Date ? value : new Date(value);
  if (isNaN(dateValue)) return null;

  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ_NY,
    year: "numeric",
    month: "2-digit",
    day: "2-digit"
  }).formatToParts(dateValue);

  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return `${values.year}-${values.month}-${values.day}`;
}

function cmpYmd(left, right) {
  if (left === right) return 0;
  return left < right ? -1 : 1;
}

function overlaps(a1, a2, b1, b2) {
  return !(a2 < b1 || b2 < a1);
}

export function applyAllFilters({
  rows = [],
  columns = [],
  searchTerm = "",
  dateFilterFieldName,
  endDateFilterFieldName,
  dateFromValue,
  dateToValue,
  selectedAccountIds = [],
  accountNamePath
}) {
  let filtered = [...(rows || [])];

  if ((selectedAccountIds || []).length && accountNamePath) {
    filtered = filtered.filter((row) => selectedAccountIds.includes(row[accountNamePath]));
  }

  if (searchTerm) {
    const term = searchTerm.toLowerCase();
    filtered = filtered.filter((row) =>
      columns.some((column) =>
        String(row[column.fieldName] ?? "")
          .toLowerCase()
          .includes(term)
      )
    );
  }

  const hasDateField = !!dateFilterFieldName;
  if (hasDateField && (dateFromValue || dateToValue)) {
    const start = dateFromValue ? toYmdInNY(dateFromValue) : null;
    const end = dateToValue ? toYmdInNY(dateToValue) : null;

    let winStart;
    let winEnd;

    if (start && end) {
      winStart = cmpYmd(start, end) <= 0 ? start : end;
      winEnd = cmpYmd(start, end) <= 0 ? end : start;
    } else {
      const only = start || end;
      winStart = only;
      winEnd = only;
    }

    filtered = filtered.filter((row) => {
      const startYmd = toYmdInNY(row[dateFilterFieldName]);
      if (!startYmd) return false;

      if (endDateFilterFieldName) {
        const endYmdRaw = toYmdInNY(row[endDateFilterFieldName]);
        const endYmd = endYmdRaw || startYmd;
        const rowStart = cmpYmd(startYmd, endYmd) <= 0 ? startYmd : endYmd;
        const rowEnd = cmpYmd(startYmd, endYmd) <= 0 ? endYmd : startYmd;
        const windowStart = winStart || rowStart;
        const windowEnd = winEnd || rowEnd;
        return overlaps(rowStart, rowEnd, windowStart, windowEnd);
      }

      const leftOk = !winStart || cmpYmd(startYmd, winStart) >= 0;
      const rightOk = !winEnd || cmpYmd(startYmd, winEnd) <= 0;
      return leftOk && rightOk;
    });
  }

  return filtered;
}