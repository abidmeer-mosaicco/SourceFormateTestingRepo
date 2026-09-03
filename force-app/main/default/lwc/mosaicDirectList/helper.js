// ===== Path reader util =====
export function getValueFromPath(obj, path) {
  if (!path) return null;
  return path.split(".").reduce((o, k) => (o == null ? null : o[k]), obj);
}

// ===== Consts =====
export const MULTIPLE = "MULTIPLE";
export const QL_FIELDS = [
  "SBQQ__ProductName__c", // Product
  "PMC_CPQ_ModeofTransportation__c", // MOT
  "PMC_CPQ_ShippingType__c", // Shipping Type
  "PMC_CPQ_Incoterms1__c", // Incoterm
  "PMC_CPQ_ProductLocation__c", // Origin
  "PMC_CPQ_SoldToShipToJunction__c" // Ship to
];

export const NAM_LOCALE = "en-US";
export const VALUE_FRACTION_DIGITS = 3;

export function getBrowserLocale() {
  if (typeof navigator === "undefined") return NAM_LOCALE;
  return navigator.languages?.[0] || navigator.language || NAM_LOCALE;
}

export function formatValue(value, locale = getBrowserLocale()) {
  if (value === null || value === undefined || value === "") return "";
  const numeric = typeof value === "number" ? value : Number(String(value).trim());
  if (!Number.isFinite(numeric)) return value;

  return new Intl.NumberFormat(locale, {
    minimumFractionDigits: VALUE_FRACTION_DIGITS,
    maximumFractionDigits: VALUE_FRACTION_DIGITS
  }).format(numeric);
}

export function formatBrowserDate(value) {
  if (!value) return "";
  const isoParts = String(value).match(/^(\d{4})-(\d{2})-(\d{2})/);
  const parsed = isoParts ? new Date(Number(isoParts[1]), Number(isoParts[2]) - 1, Number(isoParts[3])) : new Date(value);
  if (Number.isNaN(parsed.getTime())) return value;

  return new Intl.DateTimeFormat(getBrowserLocale()).format(parsed);
}

export function _escapeId(id) {
  return `'${String(id).replace(/'/g, "\\'")}'`;
}

const isDateFieldName = (name) => {
  const fieldPart = ((name || "").split(".").pop() || "").toLowerCase();
  return fieldPart.includes("date") || fieldPart.endsWith("start__c") || fieldPart.endsWith("end__c") || fieldPart.endsWith("eta__c");
};

// ===== Columns builders (com TZ para datas) =====
export function buildColumnsFromListView(displayColumns = [], listRefId) {
  return displayColumns.map((col) => ({
    label: col.label,
    fieldName: col.fieldApiName,
    type: "text",
    editable: !!col.inlineEditAttributes?.[listRefId]?.editable,
    ...(isDateFieldName(col.fieldApiName) ? { isDateColumn: true } : {})
  }));
}

export function buildManualColumns(manualFields = [], manualLabels = []) {
  const labelsArr = Array.isArray(manualLabels) ? manualLabels : [];
  return (manualFields || []).map((apiName, idx) => {
    const override = (labelsArr[idx] ?? "").toString().trim();
    const label = override || apiName.split(".").slice(-1)[0];

    if (isDateFieldName(apiName)) {
      return { label, fieldName: apiName, type: "text", editable: false, isDateColumn: true };
    }

    let tmpColumn = { label, fieldName: apiName, type: "text", editable: false, wrapText: true };
    // if (tmpColumn.label.toLowerCase() == 'origin') tmpColumn = { ...tmpColumn, initialWidth: 200, wrapText: true };
    // if (tmpColumn.label.toLowerCase() == 'ship to') tmpColumn = { ...tmpColumn, initialWidth: 200, wrapText: true };
    // if (tmpColumn.label.toLowerCase() == 'account name') tmpColumn = { ...tmpColumn, initialWidth: 200, wrapText: true };
    // if (tmpColumn.label.toLowerCase() == 'order number') tmpColumn = { ...tmpColumn, initialWidth: 150 };

    // Id, OrderId, Account name, Order Number, Order Item, Contract Number, PO Number, Shipment date, Origin, Ship To, MOT, Vehicle ID

    return tmpColumn;
  });
}

export function ensureFields(base = [], ...maybeFields) {
  const set = new Set(base);
  maybeFields.filter(Boolean).forEach((f) => set.add(f));
  return Array.from(set);
}

// ===== Records -> Rows =====
export function mapRecordsToRows(records = [], columns = [], extraPaths = []) {
  return (records || []).map((r) => {
    const row = { Id: r.Id };
    columns.forEach((col) => {
      const rawValue = getValueFromPath(r, col.fieldName);
      row[col.fieldName] = col.isDateColumn ? formatBrowserDate(rawValue) : rawValue;
    });
    (extraPaths || []).filter(Boolean).forEach((p) => {
      if (row[p] === undefined) row[p] = getValueFromPath(r, p);
    });
    return row;
  });
}

// ====== TZ + parsing helpers (America/New_York) ======
const TZ_NY = "America/New_York";

// Converte qualquer Date/DateTime/string em 'YYYY-MM-DD' na TZ de NY.
// Aceita 'YYYY-MM-DD', 'Oct 30, 2023', 'October 30, 2023', etc.
function toYmdInNY(value) {
  if (!value) return null;

  if (typeof value === "string") {
    const s = value.trim();

    // YYYY-MM-DD
    if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;

    // "Oct 30, 2023" / "October 30, 2023"
    const m = s.match(/^([A-Za-z]+)\s+(\d{1,2}),\s*(\d{4})$/);
    if (m) {
      const MONTHS = {
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
      const monKey = m[1].toLowerCase();
      const mm = MONTHS[monKey.slice(0, 4)] || MONTHS[monKey.slice(0, 3)];
      if (mm) {
        const dd = String(parseInt(m[2], 10)).padStart(2, "0");
        return `${m[3]}-${mm}-${dd}`;
      }
    }
  }

  const d = value instanceof Date ? value : new Date(value);
  if (isNaN(d)) return null;

  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ_NY,
    year: "numeric",
    month: "2-digit",
    day: "2-digit"
  }).formatToParts(d);

  const by = Object.fromEntries(parts.map((p) => [p.type, p.value]));
  return `${by.year}-${by.month}-${by.day}`;
}

function cmpYmd(a, b) {
  if (a === b) return 0;
  return a < b ? -1 : 1;
}

function overlaps(a1, a2, b1, b2) {
  return !(a2 < b1 || b2 < a1);
}

// ===== Filtro unificado (texto, contas, data com TZ NY) =====
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
  let out = [...(rows || [])];

  // filtro por conta (nome)
  if ((selectedAccountIds || []).length && accountNamePath) {
    out = out.filter((r) => selectedAccountIds.includes(r[accountNamePath]));
  }

  // busca textual (client-side complementar)
  if (searchTerm) {
    const term = searchTerm.toLowerCase();
    out = out.filter((row) =>
      columns.some((col) =>
        String(row[col.fieldName] ?? "")
          .toLowerCase()
          .includes(term)
      )
    );
  }

  // filtro por data (sempre em NY) — ***CORRIGIDO: sem anexar 'T...' no input***
  const hasDateField = !!dateFilterFieldName;
  if (hasDateField && (dateFromValue || dateToValue)) {
    // Normaliza a janela do usuário diretamente (ex.: "Oct 30, 2023" -> "2023-10-30")
    const start = dateFromValue ? toYmdInNY(dateFromValue) : null;
    const end = dateToValue ? toYmdInNY(dateToValue) : null;

    console.log(
      `[mosaicDirectList] date filter: ${dateFilterFieldName} / ${endDateFilterFieldName || "<none>"} from ${start || "<none>"} to ${end || "<none>"}`
    );

    let winStart, winEnd;
    if (start && end) {
      winStart = cmpYmd(start, end) <= 0 ? start : end;
      winEnd = cmpYmd(start, end) <= 0 ? end : start;

      console.log(`[mosaicDirectList] date filter window normalized: from ${winStart} to ${winEnd}`);
    } else {
      const only = start || end;
      console.log(`[mosaicDirectList] date filter window single date: ${only}`);

      winStart = only;
      winEnd = only; // FROM = TO se só um foi informado

      console.log(`[mosaicDirectList] date filter window single date normalized: ${only}`);
    }

    out = out.filter((row) => {
      const startY = toYmdInNY(row[dateFilterFieldName]);
      if (!startY) return false;

      if (endDateFilterFieldName) {
        const endYraw = toYmdInNY(row[endDateFilterFieldName]);
        const endY = endYraw || startY;

        console.log(`[mosaicDirectList] date range row: from ${startY} to ${endYraw || "<none>"} normalized to ${endY}`);

        const rStart = cmpYmd(startY, endY) <= 0 ? startY : endY;
        const rEnd = cmpYmd(startY, endY) <= 0 ? endY : startY;

        console.log(`[mosaicDirectList] date range row normalized: from ${rStart} to ${rEnd}`);

        const wStart = winStart || rStart;
        const wEnd = winEnd || rEnd;

        console.log(`[mosaicDirectList] date range window adjusted: from ${wStart} to ${wEnd}`);

        return overlaps(rStart, rEnd, wStart, wEnd);
      } else {
        const leftOk = !wStart || cmpYmd(startY, wStart) >= 0;
        const rightOk = !wEnd || cmpYmd(startY, wEnd) <= 0;
        return leftOk && rightOk;
      }
    });
  }

  return out;
}