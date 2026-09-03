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
  // optional: name of the field (or array of field names) to restrict text search to
  searchFieldName,
  dateFilterFieldName,
  endDateFilterFieldName,
  dateFromValue,
  dateToValue,
  selectedAccountIds = [],
  accountNamePath
}) {
  // Parse de valores vindos do datepicker/inputs em objeto Date UTC (start/end of day)
  const parseInputToDate = (v) => {
    if (!v && v !== 0) return null;
    if (v instanceof Date) return new Date(Date.UTC(v.getUTCFullYear(), v.getUTCMonth(), v.getUTCDate(), 0, 0, 0, 0));
    if (typeof v === 'string') {
      // ISO YYYY-MM-DD
      if (/^\d{4}-\d{2}-\d{2}$/.test(v)) {
        const d = new Date(v + 'T00:00:00Z');
        return isNaN(d) ? null : new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), 0, 0, 0, 0));
      }
      // MM/DD/YYYY (common internal display)
      if (/^\d{1,2}\/\d{1,2}\/\d{4}$/.test(v)) {
        const parts = v.split('/');
        const mm = parseInt(parts[0], 10);
        const dd = parseInt(parts[1], 10);
        const yyyy = parseInt(parts[2], 10);
        if (isNaN(mm) || isNaN(dd) || isNaN(yyyy)) return null;
        return new Date(Date.UTC(yyyy, mm - 1, dd, 0, 0, 0, 0));
      }
      // localized or other parseable string
      const dt = new Date(v);
      if (!isNaN(dt)) return new Date(Date.UTC(dt.getUTCFullYear(), dt.getUTCMonth(), dt.getUTCDate(), 0, 0, 0, 0));
    }
    return null;
  };

  dateFromValue = parseInputToDate(dateFromValue);
  dateToValue = parseInputToDate(dateToValue);

  // applyAllFilters entrada

  let out = [...(rows || [])];

  // debug logs removed for production

  // Filtragem por conta: preferir comparacao por Ids quando disponivel; aceitar nomes como fallback
  if (((selectedAccountIds || []).length || (arguments[0] && arguments[0].selectedAccountNames && arguments[0].selectedAccountNames.length)) && accountNamePath) {
    const selIds = (selectedAccountIds || []).map((s) => (s ? String(s).trim() : '')).filter(Boolean);
    const selNames = (arguments[0] && Array.isArray(arguments[0].selectedAccountNames)) ? arguments[0].selectedAccountNames.map((n) => (n ? String(n).trim() : '')).filter(Boolean) : [];
    out = out.filter((r) => {
      const val = getValueFromPath(r, accountNamePath);
      if (val == null) return false;
      const sval = String(val).trim();
      // se tivermos ids selecionados, compara por id
      if (selIds.length) return selIds.some((id) => id && String(id).trim() === sval);
      // fallback: compara por nome quando nomes estiverem presentes
      if (selNames.length) return selNames.some((n) => n && String(n).trim().toLowerCase() === sval.toLowerCase());
      return false;
    });
  }

  if ((dateFilterFieldName || endDateFilterFieldName) && (dateFromValue || dateToValue)) {
      const toStartOfDay = (d) => {
        if (!d) return null;
        if (d instanceof Date) return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), 0, 0, 0, 0));
        return null;
      };
      const toEndOfDay = (d) => {
        if (!d) return null;
        if (d instanceof Date) return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), 23, 59, 59, 999));
        return null;
      };
      const parseRowDate = (v) => {
        if (!v) return null;
        if (v instanceof Date) return toStartOfDay(v);
        // if it's a string like 2025-10-31, parse to UTC start
        if (typeof v === 'string') {
          if (/^\d{4}-\d{2}-\d{2}$/.test(v)) {
            const d = new Date(v + 'T00:00:00Z');
            return isNaN(d) ? null : toStartOfDay(d);
          }
          if (/^\d{1,2}\/\d{1,2}\/\d{4}$/.test(v)) {
            const parts = v.split('/');
            const mm = parseInt(parts[0], 10);
            const dd = parseInt(parts[1], 10);
            const yyyy = parseInt(parts[2], 10);
            if (isNaN(mm) || isNaN(dd) || isNaN(yyyy)) return null;
            return new Date(Date.UTC(yyyy, mm - 1, dd, 0, 0, 0, 0));
          }
          const dt = new Date(v);
          if (!isNaN(dt)) return toStartOfDay(dt);
        }
        return null;
      };
      

    const hasFrom = !!dateFromValue;
    const hasTo = !!dateToValue;
    const from = hasFrom ? toStartOfDay(dateFromValue) : null;
    const to = hasTo ? toEndOfDay(dateToValue) : null;

    // fallback: choose sensible field names if one is missing
    const startField = dateFilterFieldName || endDateFilterFieldName || 'StartDate';
    const endField = endDateFilterFieldName || dateFilterFieldName || 'EndDate';

    out = out.filter((row) => {
      // allow rows where at least one of start/end exists
      const rawStart = getValueFromPath(row, startField);
      const rawEnd = getValueFromPath(row, endField);

      const startParsed = parseRowDate(rawStart);
      const endParsed = parseRowDate(rawEnd);

      // if neither date exists, exclude when filter active
      if (!startParsed && !endParsed) return false;

      // if only one exists, treat both start/end as that date (single-day contract)
      let start = startParsed || endParsed;
      let end = endParsed || startParsed;

      // normalize order
      if (start && end && end < start) {
        const tmp = end;
        end = start;
        start = tmp;
      }

      if (hasFrom && !hasTo) {
        // Apenas From: incluir linhas que sobrepõem [from, +inf)
        // aceitar quando End >= from OU quando Start >= from
        return (!!end && end >= from) || (!!start && start >= from);
      }
      if (!hasFrom && hasTo) {
        // Apenas To: incluir linhas que sobrepõem (-inf, to]
        // aceitar quando Start <= to OU quando End <= to
        return (!!start && start <= to) || (!!end && end <= to);
      }
      if (hasFrom && hasTo) {
        // Quando ambos FROM e TO preenchidos, aceitar linhas cujo intervalo
        // sobrepõe [from, to] (overlap). Se a linha tiver apenas uma data,
        // tratamos como intervalo de um dia.
        if (!start && !end) return false;

        let s = start || end;
        let e = end || start;

        if (s && e && e < s) {
          const tmp = e;
          e = s;
          s = tmp;
        }

        if (!s || !e) return false;

        // overlap test: interval [s,e] overlaps [from,to] when not (e < from || s > to)
        return !(e < from || s > to);
      }

      return true;
    });
  }

  return out;
}