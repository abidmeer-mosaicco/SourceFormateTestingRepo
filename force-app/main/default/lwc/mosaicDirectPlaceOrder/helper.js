export function getValueFromPath(obj, path) {
  if (!path) return null;
  return path.split(".").reduce((o, k) => (o == null ? null : o[k]), obj);
}

const isDateFieldName = (name) => (name || "").toLowerCase().includes("date");

export function buildColumnsFromListView(displayColumns = [], listRefId) {
  return displayColumns.map((col) => ({
    label: col.label,
    fieldName: col.fieldApiName,
    type: col.fieldApiName.endsWith("Date") || isDateFieldName(col.fieldApiName) ? "date" : "text",
    editable: !!col.inlineEditAttributes?.[listRefId]?.editable
  }));
}

export function buildManualColumns(manualFields = [], manualLabels = []) {
  const labelsArr = Array.isArray(manualLabels) ? manualLabels : [];
  return (manualFields || []).map((apiName, idx) => {
    const override = (labelsArr[idx] ?? "").toString().trim();
    const label = override || apiName.split(".").slice(-1)[0];
    return {
      label,
      fieldName: apiName,
      type: isDateFieldName(apiName) ? "date" : "text",
      editable: false
    };
  });
}

export function ensureFields(base = [], ...maybeFields) {
  const set = new Set(base);
  maybeFields.filter(Boolean).forEach((f) => set.add(f));
  return Array.from(set);
}

export function mapRecordsToRows(records = [], columns = [], extraPaths = []) {
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
  let out = [...(rows || [])];

  console.log("Applying filters:", {
    searchTerm,
    dateFilterFieldName,
    endDateFilterFieldName,
    dateFromValue,
    dateToValue,
    selectedAccountIds,
    accountNamePath
  });

  if ((selectedAccountIds || []).length && accountNamePath) {
    out = out.filter((r) => selectedAccountIds.includes(r[accountNamePath]));
  }

  if (searchTerm) {
    const term = searchTerm.toLowerCase();
    out = out.filter((row) =>
      columns.some((col) =>
        String(row[col.fieldName] || "")
          .toLowerCase()
          .includes(term)
      )
    );
  }

  if ((dateFilterFieldName || endDateFilterFieldName) && (dateFromValue || dateToValue)) {
    const toStartOfDay = (d) => {
      const dt = new Date(d);
      if (isNaN(dt)) return null;
      dt.setHours(0, 0, 0, 0);
      return dt;
    };
    const toEndOfDay = (d) => {
      const dt = new Date(d);
      if (isNaN(dt)) return null;
      dt.setHours(23, 59, 59, 999);
      return dt;
    };
    const parseRowDate = (v) => {
      if (!v) return null;
      if (v instanceof Date) return v;
      const tryIso = typeof v === "string" && /^\d{4}-\d{2}-\d{2}$/.test(v) ? new Date(v + "T00:00:00") : new Date(v);
      return isNaN(tryIso) ? null : tryIso;
    };

    const hasFrom = !!dateFromValue;
    const hasTo = !!dateToValue;
    const from = hasFrom ? toStartOfDay(dateFromValue) : null;
    const to = hasTo ? toEndOfDay(dateToValue) : null;

    const hasEndField = !!endDateFilterFieldName;

    out = out.filter((row) => {
      let start = parseRowDate(row[dateFilterFieldName]);
      if (!start) return false;

      let end = start;
      if (hasEndField) {
        const maybeEnd = parseRowDate(row[endDateFilterFieldName]);
        end = maybeEnd || start;
      }

      if (end < start) {
        const tmp = end;
        end = start;
        start = tmp;
      }

      if (hasEndField) {
        if (from && start < from) return false;
        if (to && end > to) return false;
      } else {
        if (from && start < from) return false;
        if (to && start > to) return false;
      }
      return true;
    });
  }

  return out;
}