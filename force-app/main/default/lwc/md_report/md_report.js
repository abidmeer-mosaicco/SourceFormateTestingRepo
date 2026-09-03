import { LightningElement, api, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from "lightning/messageService";
import ACCOUNT_SELECTION_CHANNEL from "@salesforce/messageChannel/AccountSelectionChannel__c";
import FILTER_CHANNEL from "@salesforce/messageChannel/FilterEvent__c";
import Toast from "lightning/toast";
import ToastContainer from "lightning/toastContainer";
import listRecordsPaged from "@salesforce/apex/MosaicDirectListController.listRecordsPaged";

import { buildManualColumns, ensureFields, formatValue, getBrowserLocale, mapRecordsToRows } from "./helper";
import USER_ID from "@salesforce/user/Id";

import md_reportfilters_headertitle from "@salesforce/label/c.md_reportfilters_headertitle";
import md_reportfilters_advanced_filters from "@salesforce/label/c.md_reportfilters_advanced_filters";
import md_reportfilters_clear_btn from "@salesforce/label/c.md_reportfilters_clear_btn";
import md_reportfilters_apply_btn from "@salesforce/label/c.md_reportfilters_apply_btn";

import hasDebug from "@salesforce/customPermission/MD_DEBUG";

const DEBUG = (...args) => {
  if (hasDebug) console.log("[Md_report]", ...args);
};

export { SAM_LOCALE, NAM_LOCALE, formatValue, formatBrowserDate, formatBrowserDateTime, getBrowserLocale } from "./helper";

const STORAGE_KEY = "mosaic:selectedAccounts";
const ALL_ACCOUNTS_KEY = "mosaic:allAccountNames";

export default class Md_report extends NavigationMixin(LightningElement) {
  @api objectApiName;
  @api tableType;
  @api manualFieldApiNames = [];
  @api manualFieldLabelNames = [];
  @api filterFieldName;
  @api dateFilterFieldName;
  @api endDateFilterFieldName;
  @api baseWhereClause = "";
  @api pageSize = 50;
  @api accountNamePath = "";
  @api sapNumberPath = "PMC_CPQ_OrderProduct__r.Order.Account.PMC_SS_SAPCustomerNumber__c";
  @api showDownloadButton = false;
  @api showTableTitle = false;

  @track columns = [];
  @track data = [];
  @track allRowsForDownload = [];
  @track draftValues = [];
  @track searchTerm = "";
  @track dateFromValue = "";
  @track dateToValue = "";
  @track pageButtons = [];
  @track page1Variant = "neutral";
  @track lastPageVariant = "neutral";
  @track storedTableType = "";
  @track showAdvancedFilters = false;

  isLoading = false;
  subscription;
  tableTypeSubscription;

  _bootstrapped = false;
  _requestSeq = 0;

  selectedAccountNames = [];
  selectedAccountKeys = [];

  originalData = [];
  _filteredAll = [];
  _manualFieldApiNames = [];
  _manualFieldLabelNames = [];
  _downloadSnapshotKey = null;
  noResults = false;
  noResultsMessage = "No records found.";
  pageNumber = 1;
  totalSize = 0;
  totalPages = 1;
  sortField = "LastModifiedDate";
  sortDir = "DESC";

  @wire(MessageContext) messageContext;

  // -------------------------------------------------------------
  // VIRTUAL HOOKS FOR CHILD COMPONENTS
  // -------------------------------------------------------------
  get showFilters() {
    return false;
  }
  get filterPrimaryFields() {
    return [];
  }
  get filterAdvancedFields() {
    return [];
  }
  get hideAdvancedFiltersButton() {
    return false;
  }
  get exportFileName() {
    return null;
  }

  get filterHeaderLabel() {
    return md_reportfilters_headertitle;
  }
  get filterAdvancedLabel() {
    return md_reportfilters_advanced_filters;
  }
  get filterClearLabel() {
    return md_reportfilters_clear_btn;
  }
  get filterApplyLabel() {
    return md_reportfilters_apply_btn;
  }
  get searchFieldLabel() {
    return "Search";
  }
  get searchPlaceholder() {
    return "Type to search";
  }
  get dateFromLabel() {
    return "From";
  }
  get dateToLabel() {
    return "To";
  }

  get valueLocale() {
    return getBrowserLocale();
  }
  getValueFieldNames() {
    return [];
  }

  getExtraQueryFields() {
    return [];
  }
  getAdditionalWhereClause() {
    return "";
  }
  processColumns(columns) {
    return columns;
  }
  async processData(rows) {
    return rows;
  }
  handleCustomRowAction(actionName, row) {}
  async refreshCustomFilterOptions(pendingFilters) {}
  getFetchCustomMethod() {
    return listRecordsPaged;
  }
  getFetchCustomArgs(queryArgs) {
    return queryArgs;
  }
  // -------------------------------------------------------------

  get hasRecords() {
    return this.totalSize > 0;
  }

  get tableTitle() {
    return this.tableType || "Report";
  }

  get showLegacyFilters() {
    return !this.showFilters;
  }

  get isPrevDisabled() {
    return this.isLoading || this.pageNumber <= 1;
  }

  get isNextDisabled() {
    return this.isLoading || this.pageNumber >= this.totalPages;
  }

  get sortDirLower() {
    return (this.sortDir || "ASC").toLowerCase();
  }

  get isFirstPageActive() {
    return this.pageNumber === 1;
  }

  get isLastPageActive() {
    return this.pageNumber === this.totalPages;
  }

  get showFirstPage() {
    return this.totalPages > 1;
  }

  get showLastPage() {
    return this.totalPages > 1;
  }

  get showLeftEllipsis() {
    return this.pageNumber > 4;
  }

  get showRightEllipsis() {
    return this.pageNumber < this.totalPages - 3;
  }

  _hasClientFilter() {
    return !!this.searchTerm && !(this.dateFromValue || this.dateToValue);
  }

  _sliceClientPage(page = 1) {
    this.pageNumber = Math.min(Math.max(1, page), this.totalPages);
    const start = (this.pageNumber - 1) * this.pageSize;
    const end = start + this.pageSize;
    this.data = (this._filteredAll || []).slice(start, end);
  }

  updatePageButtons() {
    let total = this.totalPages;
    let current = this.pageNumber;

    this.page1Variant = current === 1 ? "brand" : "neutral";
    this.lastPageVariant = current === total ? "brand" : "neutral";

    let middlePages = this.calculateMiddlePages(total, current);

    let pageButtons = [];
    for (const page of middlePages) {
      if (page > 1 && page < total) {
        pageButtons.push({
          page: page,
          label: page.toString(),
          variant: current === page ? "brand" : "neutral",
          active: current === page
        });
      }
    }

    this.pageButtons = pageButtons;
  }

  calculateMiddlePages(total, current) {
    const pages = new Set();
    pages.add(1);

    if (total <= 7) {
      for (let i = 2; i <= total; i++) {
        pages.add(i);
      }
      return Array.from(pages).sort((a, b) => a - b);
    }

    if (current <= 4) {
      for (let i = 2; i <= 6; i++) {
        pages.add(i);
      }
      pages.add(total);
      return Array.from(pages).sort((a, b) => a - b);
    }

    if (current >= total - 3) {
      for (let i = total - 5; i <= total; i++) {
        if (i > 1) pages.add(i);
      }
      return Array.from(pages).sort((a, b) => a - b);
    }

    const start = Math.max(2, current - 3);
    const end = Math.min(total - 1, current + 3);

    for (let i = start; i <= end; i++) {
      pages.add(i);
    }

    pages.add(total);
    return Array.from(pages).sort((a, b) => a - b);
  }

  handleSort(event) {
    const { fieldName, sortDirection } = event.detail;
    this.sortField = fieldName;
    this.sortDir = (sortDirection || "asc").toUpperCase();
    this._invalidateDownloadCache();
    this.fetchPage(1);
  }

  _composeWhereClause() {
    const parts = [];
    if (this.baseWhereClause) parts.push("(" + this.baseWhereClause + ")");

    const namePath = this.accountNamePath || "";
    const sapPath = this.sapNumberPath || "";

    const hasKeys = Array.isArray(this.selectedAccountKeys) && this.selectedAccountKeys.length && namePath && sapPath;

    if (hasKeys) {
      const esc = (v) => String(v ?? "").replace(/'/g, "\\'");
      const orGroups = this.selectedAccountKeys
        .map((k) => {
          const [name, sap] = String(k).split("|");
          return `(${namePath}='${esc(name)}' AND ${sapPath}='${esc(sap)}')`;
        })
        .join(" OR ");
      if (orGroups) parts.push("(" + orGroups + ")");
    } else if (this.selectedAccountNames?.length && namePath) {
      const quoted = this.selectedAccountNames.map((n) => `'${String(n).replace(/'/g, "\\'")}'`).join(",");
      parts.push(`${namePath} IN (${quoted})`);
    }

    return parts.join(" AND ");
  }

  _composeEffectiveWhereClause() {
    const baseWhere = this._composeWhereClause();
    const additionalWhere = this.getAdditionalWhereClause();

    if (additionalWhere && baseWhere) {
      return `(${baseWhere}) AND (${additionalWhere})`;
    } else if (additionalWhere) {
      return additionalWhere;
    }

    return baseWhere;
  }

  _hideInternalIdColumns() {
    const shouldHide = (c) => {
      const fn = c.fieldName || "";
      const lb = c.label || "";
      const isId = fn === "Id" || lb === "Id";
      const isOrderId = fn === "PMC_CPQ_OrderProduct__r.OrderId" || lb === "OrderId";
      return isId || isOrderId;
    };
    this.columns = (this.columns || []).filter((c) => !shouldHide(c));
  }

  handleDocumentDownloadError(event) {
    DEBUG("[md_report] documentdownloaderror:", event?.detail?.error);
  }

  handleToggleAdvanced() {
    this.showAdvancedFilters = !this.showAdvancedFilters;
  }

  handleFilterChange(event) {
    this.dispatchEvent(new CustomEvent("reportfilterchange", { detail: event.detail }));
  }

  handleApplyFilters(event) {
    this._invalidateDownloadCache();
    this.pageNumber = 1;
    this.dispatchEvent(new CustomEvent("reportapplyfilters", { detail: event.detail }));
  }

  handleClearAdvancedFilters(event) {
    this.showAdvancedFilters = false;
    this._invalidateDownloadCache();
    this.pageNumber = 1;
    this.dispatchEvent(new CustomEvent("reportclearfilters", { detail: event.detail }));
  }

  async fetchPage(page = 1) {
    const hasAccountPath = !!(this.accountNamePath && this.accountNamePath.trim());
    const hasSelectedAccounts =
      (Array.isArray(this.selectedAccountNames) && this.selectedAccountNames.length > 0) ||
      (Array.isArray(this.selectedAccountKeys) && this.selectedAccountKeys.length > 0);

    if (hasAccountPath && !hasSelectedAccounts) {
      DEBUG("Nenhuma conta selecionada no switch account. Interrompendo a execução.");
      this.data = [];
      this.totalSize = 0;
      this.totalPages = 1;
      return;
    }

    const seq = ++this._requestSeq;
    this._downloadSnapshotKey = null;
    try {
      this._toggleLoading(true);

      const fieldApiNames = ensureFields(
        [...this._manualFieldApiNames],
        this.filterFieldName,
        this.dateFilterFieldName,
        this.endDateFilterFieldName,
        this.accountNamePath,
        this.sortField
      );

      if (!fieldApiNames.includes("Id")) fieldApiNames.push("Id");
      if (this.sortField && !fieldApiNames.includes(this.sortField)) {
        fieldApiNames.push(this.sortField);
      }

      const extraQueryFields = this.getExtraQueryFields();
      extraQueryFields.forEach((field) => {
        if (!fieldApiNames.includes(field)) fieldApiNames.push(field);
      });

      if (!this.columns?.length) {
        this.columns = buildManualColumns(this._manualFieldApiNames, this._manualFieldLabelNames);
        this._hideInternalIdColumns();
        this.columns = this.processColumns(this.columns);
      }

      this.columns = (this.columns || []).map((c) => {
        const isQuoteLineField = (c.fieldName || "").startsWith("SBQQ__LineItems__r.");
        return { ...c, sortable: !isQuoteLineField };
      });

      const searchFieldApiNames = (this.columns || []).map((c) => c.fieldName).filter(Boolean);

      const queryArgs = {
        objectApiName: this.objectApiName,
        fieldApiNames,
        whereClause: this._composeEffectiveWhereClause(),
        orderByField: this.sortField,
        orderDir: this.sortDir,
        pageSize: this.pageSize,
        pageNumber: page,
        searchTerm: this.searchTerm || null,
        searchFieldApiNames,
        dateFilterFieldName: this.dateFilterFieldName || null,
        endDateFilterFieldName: this.endDateFilterFieldName || null,
        dateFromYmd: this.dateFromValue || null,
        dateToYmd: this.dateToValue || null,
        timezoneId: "America/New_York"
      };

      const fetchMethod = this.getFetchCustomMethod();
      const finalArgs = this.getFetchCustomArgs(queryArgs);
      const res = await fetchMethod(finalArgs);

      if (seq !== this._requestSeq) return;

      const extraPaths = [
        this.filterFieldName,
        this.dateFilterFieldName,
        this.endDateFilterFieldName,
        this.accountNamePath,
        "Id",
        ...extraQueryFields
      ];

      let orderProductIdColumn = {
        label: "PMC_CPQ_OrderProduct__c",
        fieldName: "PMC_CPQ_OrderProduct__c",
        type: "text",
        editable: false,
        sortable: false
      };

      let rows = mapRecordsToRows(res.records, [...this.columns, orderProductIdColumn], extraPaths);

      rows = await this.processData(rows, res);
      rows = this._formatValueColumns(rows);

      const current = this.searchTerm;
      this.searchTerm = "";
      this.originalData = rows;

      const useClient = this._hasClientFilter();
      this._filteredAll = rows;
      this.searchTerm = current;

      if (useClient) {
        this.totalSize = this._filteredAll.length;
        this.totalPages = Math.max(1, Math.ceil(this.totalSize / this.pageSize));
        this._sliceClientPage(1);
      } else {
        this.pageNumber = res.pageNumber || page;
        this.totalSize = res.totalSize || rows.length || 0;
        this.totalPages = Math.max(1, Math.ceil(this.totalSize / this.pageSize));
        this.data = rows;
      }

      this.updatePageButtons();
    } catch (err) {
      this.showError("Error at pagination", err);
    } finally {
      this._toggleLoading(false);
    }
  }

  subscribeToEvents() {
    this.subscription = subscribe(this.messageContext, ACCOUNT_SELECTION_CHANNEL, (msg) => this.handleMessage(msg), { scope: APPLICATION_SCOPE });
    this.tableTypeSubscription = subscribe(this.messageContext, FILTER_CHANNEL, (msg) => this.handleChangeTableType(msg), {
      scope: APPLICATION_SCOPE
    });
  }

  connectedCallback() {
    this.subscribeToEvents();

    const scoped = (k) => `${k}:${USER_ID}`;

    try {
      const stored = JSON.parse(localStorage.getItem(scoped(STORAGE_KEY)) || localStorage.getItem(STORAGE_KEY) || "[]");
      if (Array.isArray(stored) && stored.length) {
        this.selectedAccountNames = stored;
      } else {
        const allRaw = localStorage.getItem(scoped(ALL_ACCOUNTS_KEY)) || localStorage.getItem(ALL_ACCOUNTS_KEY);
        if (allRaw) {
          const allNames = JSON.parse(allRaw);
          if (Array.isArray(allNames) && allNames.length) {
            this.selectedAccountNames = allNames;
            localStorage.setItem(scoped(STORAGE_KEY), JSON.stringify(allNames));
          }
        }
      }

      const keys = JSON.parse(localStorage.getItem(scoped("mosaic:selectedAccountKeys")) || "[]");
      if (Array.isArray(keys) && keys.length) this.selectedAccountKeys = keys;
    } catch (e) {
      console.error("Error parsing stored account names:", e);
      this.selectedAccountNames = [];
    }

    const toastContainer = ToastContainer.instance();
    toastContainer.maxToasts = 5;
    toastContainer.toastPosition = "top-center";

    this._manualFieldApiNames = this.filterManualFields(this.manualFieldApiNames);
    this._manualFieldLabelNames = this.filterManualFields(this.manualFieldLabelNames);

    if (this._canBootstrap()) {
      this._bootstrapped = true;
      this.loadManual();
    } else {
      this._bootstrapped = false;
    }
  }

  filterManualFields(manualFields) {
    return Array.isArray(manualFields)
      ? manualFields
      : typeof manualFields === "string"
        ? manualFields
            .split(",")
            .map((s) => s.trim())
            .filter(Boolean)
        : [];
  }

  disconnectedCallback() {
    unsubscribe(this.subscription);
    this.subscription = null;

    unsubscribe(this.tableTypeSubscription);
    this.tableTypeSubscription = null;
  }

  handleMessage(message) {
    const scoped = (k) => `${k}:${USER_ID}`;

    const hasNamesProp = Object.prototype.hasOwnProperty.call(message || {}, "selectedAccountNames");
    const hasKeysProp = Object.prototype.hasOwnProperty.call(message || {}, "selectedAccountKeys");

    const newNames = hasNamesProp ? message.selectedAccountNames || [] : this.selectedAccountNames;
    const newKeys = hasKeysProp ? message.selectedAccountKeys || [] : this.selectedAccountKeys;

    const changed =
      JSON.stringify(newNames || []) !== JSON.stringify(this.selectedAccountNames || []) ||
      JSON.stringify(newKeys || []) !== JSON.stringify(this.selectedAccountKeys || []);

    if (changed) {
      if (hasNamesProp) this.selectedAccountNames = newNames;
      if (hasKeysProp) this.selectedAccountKeys = newKeys;

      if (hasNamesProp) {
        if ((newNames || []).length) localStorage.setItem(scoped("mosaic:selectedAccounts"), JSON.stringify(newNames));
        else localStorage.removeItem(scoped("mosaic:selectedAccounts"));
      }
      if (hasKeysProp) {
        if ((newKeys || []).length) localStorage.setItem(scoped("mosaic:selectedAccountKeys"), JSON.stringify(newKeys));
        else localStorage.removeItem(scoped("mosaic:selectedAccountKeys"));
      }

      this.pageNumber = 1;
      this.totalSize = 0;
      this.totalPages = 1;
      this._filteredAll = [];
      this._requestSeq++;
      this._invalidateDownloadCache();
    }

    if (!this._bootstrapped) {
      if (this._canBootstrap()) {
        this._bootstrapped = true;
        this.loadManual();
      }
    } else if (changed) {
      this.fetchPage(1);
    }

    if (this._bootstrapped) {
      this.updatePageButtons();
    }
  }

  renderedCallback() {
    if (!this._bootstrapped && this._canBootstrap()) {
      this._bootstrapped = true;
      this.loadManual();
    }
  }

  _canBootstrap() {
    const hasNames = Array.isArray(this.selectedAccountNames) && this.selectedAccountNames.length > 0;
    const hasKeys = Array.isArray(this.selectedAccountKeys) && this.selectedAccountKeys.length > 0;

    const hasNamePath = !!(this.accountNamePath && this.accountNamePath.trim());
    const hasSapPath = !!(this.sapNumberPath && this.sapNumberPath.trim());

    return hasKeys ? hasNamePath && hasSapPath : hasNames && hasNamePath;
  }

  disableSearchBtn = false;

  handleSearchInput(event) {
    this.searchTerm = (event.target.value || "").toString().trim();
    this.disableSearchBtn = this.searchTerm.length === 0;
  }

  handleSearch() {
    if (this.disableSearchBtn) return;
    this._invalidateDownloadCache();
    this.fetchPage(1);
  }

  handleDateFromChange(event) {
    this.dateFromValue = event?.target?.value || "";
    this._invalidateDownloadCache();
    this.fetchPage(1);
  }

  handleDateToChange(event) {
    this.dateToValue = event?.target?.value || "";
    this._invalidateDownloadCache();
    this.fetchPage(1);
  }

  handleClearFilters() {
    this.searchTerm = "";
    this.dateFromValue = "";
    this.dateToValue = "";
    this.noResults = false;
    this.noResultsMessage = "";
    this._invalidateDownloadCache();
    this.fetchPage(1);
  }

  handleRowAction(event) {
    const actionName = event.detail?.action?.name;
    const row = event.detail?.row;

    // Devolve para os filhos
    this.handleCustomRowAction(actionName, row);
  }

  async loadManual() {
    try {
      this._toggleLoading(true);
      this.columns = buildManualColumns(this._manualFieldApiNames, this._manualFieldLabelNames);
      this._hideInternalIdColumns();

      this.columns = this.processColumns(this.columns);

      await this.fetchPage(1);
      this.updatePageButtons();
    } catch (err) {
      this.showError("Erro (modo manual)", err);
    } finally {
      this._toggleLoading(false);
    }
  }

  handlePaginationChange(event) {
    const page = event.detail?.page;
    if (page) {
      this.fetchPage(page);
    }
  }

  handleChangeTableType(message) {
    let tableType = (typeof message === "string" ? message : message?.tableType || message?.value || "").toString();
    if (!tableType) return;

    const normalizedType = tableType.trim().toLowerCase();
    this.storedTableType = normalizedType;
    localStorage.setItem(`mosaic:tableType:${USER_ID}`, normalizedType);

    if (!this._bootstrapped) return;
    this.pageNumber = 1;
    this._invalidateDownloadCache();
    this.fetchPage(1);
  }

  showToast({ label, message, variant = "info", mode = "dismissible", labelLinks, messageLinks, onclose }) {
    Toast.show(
      {
        label,
        message,
        variant,
        mode,
        labelLinks,
        messageLinks,
        onclose
      },
      this
    );
  }

  showError(title, error) {
    const message = error?.body?.message || error?.message || String(error);
    DEBUG("Showing error:", title, message, error);
    this.showToast({ label: title, message, variant: "error", mode: "dismissible" });
  }

  async handleRequestDownload(evt) {
    DEBUG("[MdReport] handleRequestDownload iniciado");
    try {
      if (evt && typeof evt.stopPropagation === "function") evt.stopPropagation();

      const manual = Array.isArray(this._manualFieldApiNames) && this._manualFieldApiNames.length ? this._manualFieldApiNames.slice() : [];
      const fields = ensureFields(manual, "Id");

      const whereClause = this._composeEffectiveWhereClause() || this._composeWhereClause();
      const orderByField = this.sortField;

      DEBUG("[MdReport] Buscando todos os registros...");
      const snapshotKey = `${this.objectApiName}::${whereClause}::${fields.join(",")}::${orderByField}::${this.sortDir}`;
      await this._ensureAllRowsCached(snapshotKey, whereClause, fields, orderByField);

      let rowsToPass =
        Array.isArray(this.allRowsForDownload) && this.allRowsForDownload.length
          ? [...this.allRowsForDownload]
          : Array.isArray(this._filteredAll) && this._filteredAll.length
            ? [...this._filteredAll]
            : Array.isArray(this.originalData)
              ? [...this.originalData]
              : [];

      this.allRowsForDownload = rowsToPass || [];
      DEBUG("[MdReport] Total de registros para download:", this.allRowsForDownload.length);

      const child = this.template.querySelector("c-md_report-download-xls");
      if (child) {
        let exportCols = (this.columns || []).slice();
        const fieldApiNames = exportCols.map((c) => c.fieldName).filter(Boolean);
        const labelNames = exportCols.map((c) => c.label || c.fieldName);

        child.manualFieldApiNames = fieldApiNames;
        child.manualFieldLabelNames = labelNames;

        child.allRows = this.allRowsForDownload || [];
        DEBUG("[MdReport] Chamando child.downloadTable com", child.allRows.length, "registros");
        await child.downloadTable();
      } else {
        DEBUG("[MdReport] Componente filho de download não encontrado!");
      }
    } catch (e) {
      DEBUG("[MdReport] Erro em handleRequestDownload:", e);
      this.showError("Erro no Download", e);
    }
  }

  async _ensureAllRowsCached(snapshotKey, whereClause, fields, orderByField) {
    if (!snapshotKey) return;
    if (this._downloadSnapshotKey === snapshotKey && this.allRowsForDownload && this.allRowsForDownload.length) return;
    this._downloadSnapshotKey = snapshotKey;
    this.allRowsForDownload = await this._fetchAllRows(whereClause, fields, orderByField);
    DEBUG("allRowsForDownload", this.allRowsForDownload);
  }

  async _fetchAllRows(whereClause, fields, orderByField) {
    const ps = Number(this.pageSize) || 50;
    const pages = Math.max(1, Math.ceil((this.totalSize || 0) / ps));
    const items = [];

    const extraQueryFields = this.getExtraQueryFields();
    const extraPaths = [
      this.filterFieldName,
      this.dateFilterFieldName,
      this.endDateFilterFieldName,
      this.accountNamePath,
      "Id",
      ...extraQueryFields
    ].filter(Boolean);

    const orderProductIdColumn = {
      label: "PMC_CPQ_OrderProduct__c",
      fieldName: "PMC_CPQ_OrderProduct__c",
      type: "text",
      editable: false,
      sortable: false
    };

    for (let p = 1; p <= pages; p++) {
      const queryArgs = {
        objectApiName: this.objectApiName,
        fieldApiNames: fields,
        whereClause,
        orderByField: orderByField || this.sortField,
        orderDir: this.sortDir,
        pageSize: ps,
        pageNumber: p,
        searchTerm: this.searchTerm || null,
        searchFieldApiNames: (this.columns || []).map((c) => c.fieldName).filter(Boolean),
        dateFilterFieldName: this.dateFilterFieldName || null,
        endDateFilterFieldName: this.endDateFilterFieldName || null,
        dateFromYmd: this.dateFromValue || null,
        dateToYmd: this.dateToValue || null,
        timezoneId: "America/New_York"
      };

      DEBUG("queryArgs", queryArgs);

      const fetchMethod = this.getFetchCustomMethod();
      const finalArgs = this.getFetchCustomArgs(queryArgs);
      const res = await fetchMethod(finalArgs).catch(() => null);

      DEBUG("fetchMethod", fetchMethod);
      DEBUG("finalArgs", finalArgs);
      DEBUG("res", res);

      if (res && res.records && res.records.length) {
        const rows = mapRecordsToRows(res.records, [...(this.columns || []), orderProductIdColumn], extraPaths);
        rows.forEach((r) => items.push(r));
      }
    }

    DEBUG("items", items);

    try {
      let exportDownloadList = await this.processData(items, { isDownload: true });
      DEBUG("exportDownloadList", exportDownloadList);
      return exportDownloadList;
    } catch (e) {
      return items;
    }
  }

  _formatValueColumns(rows) {
    const valueFieldNames = this.getValueFieldNames();
    if (!valueFieldNames.length) return rows;

    const locale = this.valueLocale;
    return (rows || []).map((row) => {
      const formattedRow = { ...row };
      valueFieldNames.forEach((fieldName) => {
        if (fieldName in formattedRow) formattedRow[fieldName] = formatValue(formattedRow[fieldName], locale);
      });
      return formattedRow;
    });
  }

  _invalidateDownloadCache() {
    this._downloadSnapshotKey = null;
    this.allRowsForDownload = [];
  }

  _toggleLoading(isStart) {
    let action = isStart ? "start" : "stop";
    this.dispatchEvent(
      new CustomEvent("loadingEvent", {
        bubbles: true,
        composed: true,
        detail: { action }
      })
    );
  }
}