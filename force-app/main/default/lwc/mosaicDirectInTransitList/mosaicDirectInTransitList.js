import { LightningElement, api, track, wire } from "lwc";
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from "lightning/messageService";
import ACCOUNT_SELECTION_CHANNEL from "@salesforce/messageChannel/AccountSelectionChannel__c";
import FILTER_CHANNEL from "@salesforce/messageChannel/FilterEvent__c";
import Toast from "lightning/toast";
import ToastContainer from "lightning/toastContainer";
import listRecordsPaged from "@salesforce/apex/MosaicDirectListController.listRecordsPaged";
import listInTransitRecordsPaged from "@salesforce/apex/MosaicDirectListController.listInTransitRecordsPaged";
import getInTransitFilterOptions from "@salesforce/apex/MosaicDirectListController.getInTransitFilterOptions";
import { buildManualColumns, ensureFields, mapRecordsToRows } from "c/mosaicDirectListUtils";
import USER_ID from "@salesforce/user/Id";
import MD_NAM_INTRANSIT from "@salesforce/customPermission/MD_NAM_INTRANSIT";

const STORAGE_KEY = "mosaic:selectedAccounts";
const ALL_ACCOUNTS_KEY = "mosaic:allAccountNames";
const IN_TRANSIT_MODE_FIELD = "PMC_CPQ_ModeofTransportation__c";
const IN_TRANSIT_TEXT_FILTER_FIELDS = [
  { name: "orderNumber", label: "Order Number" },
  { name: "vehicleId", label: "Vehicle ID" },
  { name: "contract", label: "Contract" },
  { name: "poNumber", label: "PO Number" }
];
const IN_TRANSIT_ADVANCED_FILTER_FIELDS = [
  { name: "products", label: "Product", optionKey: "products" },
  { name: "origins", label: "Origin", optionKey: "origins" },
  { name: "shipTos", label: "Ship To", optionKey: "shipTos" },
  { name: "destinations", label: "Destination", optionKey: "destinations" },
  { name: "statuses", label: "Status", optionKey: "statuses" }
];
const EMPTY_IN_TRANSIT_FILTERS = {
  orderNumber: "",
  vehicleId: "",
  contract: "",
  poNumber: "",
  products: [],
  origins: [],
  shipTos: [],
  destinations: [],
  statuses: []
};

export default class MosaicDirectInTransitList extends LightningElement {
  @api manualFieldApiNames;
  @api manualFieldLabelNames;
  @api filterFieldName;
  @api dateFilterFieldName;
  @api endDateFilterFieldName;
  @api baseWhereClause = "";
  @api pageSize = 50;
  @api accountNamePath = "";
  @api sapNumberPath = "PMC_CPQ_OrderProduct__r.Order.Account.PMC_SS_SAPCustomerNumber__c";

  @track columns = [];
  @track data = [];
  @track draftValues = [];
  @track searchTerm = "";
  @track dateFromValue = "";
  @track dateToValue = "";
  @track pageButtons = [];
  @track storedTableType = "";
  @track inTransitFilterOptions = {
    products: [],
    origins: [],
    shipTos: [],
    destinations: [],
    statuses: []
  };
  @track showAdvancedFilters = false;

  isLoading = false;
  subscription;
  tableTypeSubscription;
  inTransitApplyTriggered = false;
  inTransitPendingFilters = { ...EMPTY_IN_TRANSIT_FILTERS };
  inTransitAppliedFilters = { ...EMPTY_IN_TRANSIT_FILTERS };
  _bootstrapped = false;
  _requestSeq = 0;

  selectedAccountNames = [];
  selectedAccountKeys = [];
  originalData = [];
  _filteredAll = [];
  _manualFieldApiNames = [];
  _manualFieldLabelNames = [];
  noResults = false;
  noResultsMessage = "No records found.";
  pageNumber = 1;
  totalSize = 0;
  totalPages = 1;
  sortField = "LastModifiedDate";
  sortDir = "DESC";

  @wire(MessageContext) messageContext;

  get hasIntransitPermission() {
    return MD_NAM_INTRANSIT;
  }

  get hasRecords() {
    return this.totalSize > 0;
  }

  get tableTitle() {
    return "In Transit";
  }

  get showTableTitle() {
    return false;
  }

  get showLegacyFilters() {
    return false;
  }

  get isInTransitTable() {
    return true;
  }

  get inTransitTextFields() {
    return IN_TRANSIT_TEXT_FILTER_FIELDS.map((field) => ({
      ...field,
      value: this.inTransitPendingFilters[field.name] || ""
    }));
  }

  get inTransitAdvancedFields() {
    return IN_TRANSIT_ADVANCED_FILTER_FIELDS.map((field) => ({
      name: field.name,
      label: field.label,
      options: this._toDualListOptions(this.inTransitFilterOptions[field.optionKey]),
      value: [...(this.inTransitPendingFilters[field.name] || [])]
    }));
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

  get showLastPage() {
    return this.totalPages > 1;
  }

  get showLeftEllipsis() {
    return this.pageNumber > 4;
  }

  get showRightEllipsis() {
    return this.pageNumber < this.totalPages - 3;
  }

  isShipmentItemTable() {
    return true;
  }

  updatePageButtons() {
    const total = this.totalPages;
    const current = this.pageNumber;
    const middlePages = this.calculateMiddlePages(total, current);

    this.pageButtons = middlePages
      .filter((page) => page > 1 && page < total)
      .map((page) => ({
        page,
        label: page.toString(),
        active: current === page
      }));
  }

  calculateMiddlePages(total, current) {
    const pages = new Set([1]);

    if (total <= 7) {
      for (let i = 2; i <= total; i++) pages.add(i);
      return Array.from(pages).sort((a, b) => a - b);
    }

    if (current <= 4) {
      for (let i = 2; i <= 6; i++) pages.add(i);
      pages.add(total);
      return Array.from(pages).sort((a, b) => a - b);
    }

    if (current >= total - 3) {
      for (let i = total - 5; i <= total; i++) {
        if (i > 1) pages.add(i);
      }
      return Array.from(pages).sort((a, b) => a - b);
    }

    for (let i = Math.max(2, current - 3); i <= Math.min(total - 1, current + 3); i++) pages.add(i);
    pages.add(total);
    return Array.from(pages).sort((a, b) => a - b);
  }

  _composeWhereClause() {
    const parts = [];
    if (this.baseWhereClause) parts.push(`(${this.baseWhereClause})`);

    const namePath = this.accountNamePath || "";
    const sapPath = this.sapNumberPath || "";
    const hasKeys = Array.isArray(this.selectedAccountKeys) && this.selectedAccountKeys.length && namePath && sapPath;

    if (hasKeys) {
      const esc = (value) => String(value ?? "").replace(/'/g, "\\'");
      const orGroups = this.selectedAccountKeys
        .map((key) => {
          const [name, sap] = String(key).split("|");
          return `(${namePath}='${esc(name)}' AND ${sapPath}='${esc(sap)}')`;
        })
        .join(" OR ");
      if (orGroups) parts.push(`(${orGroups})`);
    } else if (this.selectedAccountNames?.length && namePath) {
      const quoted = this.selectedAccountNames.map((name) => `'${String(name).replace(/'/g, "\\'")}'`).join(",");
      parts.push(`${namePath} IN (${quoted})`);
    }

    return parts.join(" AND ");
  }

  _composeEffectiveWhereClause() {
    const baseWhere = this._composeWhereClause();
    const normalizedType = (this.storedTableType || "").toString().trim().toLowerCase();
    if (normalizedType !== "rail" && normalizedType !== "barge") return baseWhere;

    const motWhere = `${IN_TRANSIT_MODE_FIELD} = '${normalizedType === "rail" ? "Rail" : "Barge"}'`;
    return baseWhere ? `(${baseWhere}) AND (${motWhere})` : motWhere;
  }

  _hideInternalIdColumns() {
    this.columns = (this.columns || []).filter((column) => {
      const fieldName = column.fieldName || "";
      const label = column.label || "";
      return fieldName !== "Id" && label !== "Id" && fieldName !== "PMC_CPQ_OrderProduct__r.OrderId" && label !== "OrderId";
    });
  }

  _isOrderItemColumn(column = {}) {
    const label = (column.label || "").toString().trim().toLowerCase();
    const fieldName = (column.fieldName || "").toString().trim().toLowerCase();
    return label === "order item" || fieldName.includes("orderitemnumber") || fieldName === "pmc_cpq_orderproduct__c";
  }

  _isOrderColumn(column = {}) {
    const label = (column.label || "").toString().trim().toLowerCase();
    const fieldName = (column.fieldName || "").toString().trim().toLowerCase();
    if (label === "order" || label === "order number") return true;
    if (fieldName.endsWith(".ordernumber")) return true;
    return fieldName.includes("sapordernumber");
  }

  _isOrderFieldName(fieldName = "") {
    const normalized = String(fieldName || "")
      .trim()
      .toLowerCase();
    return normalized.endsWith(".ordernumber") || normalized.includes("sapordernumber");
  }

  _isOrderItemFieldName(fieldName = "") {
    return String(fieldName || "")
      .trim()
      .toLowerCase()
      .includes("orderitemnumber");
  }

  _getOrderAndOrderItemFieldNames() {
    const cols = this.columns || [];
    const orderColumn = cols.find((column) => this._isOrderColumn(column));
    const orderItemColumn = cols.find((column) => this._isOrderItemColumn(column));
    const manualOrderField = (this._manualFieldApiNames || []).find((fieldName) => this._isOrderFieldName(fieldName));
    const manualOrderItemField = (this._manualFieldApiNames || []).find((fieldName) => this._isOrderItemFieldName(fieldName));

    return {
      orderFieldName: orderColumn?.fieldName || manualOrderField,
      orderItemFieldName: orderItemColumn?.fieldName || manualOrderItemField
    };
  }

  _formatOrderItemWithLeftZeros(orderItemValue) {
    if (orderItemValue === null || orderItemValue === undefined) return "";
    const normalized = String(orderItemValue).trim();
    return normalized ? normalized.padStart(4, "0") : "";
  }

  _mergeOrderItemIntoOrderForInTransit(rows = []) {
    const { orderFieldName, orderItemFieldName } = this._getOrderAndOrderItemFieldNames();
    if (!orderFieldName || !orderItemFieldName) return rows;

    return (rows || []).map((row) => {
      const paddedOrderItem = this._formatOrderItemWithLeftZeros(row?.[orderItemFieldName]);
      return paddedOrderItem ? { ...row, [orderFieldName]: `${row?.[orderFieldName] ?? ""}${paddedOrderItem}` } : row;
    });
  }

  _normalizeContractNumber(rows = []) {
    const contractFieldName = "PMC_CPQ_OrderProduct__r.SBQQ__Contract__r.SBQQ__Quote__r.Name";
    return (rows || []).map((row) => {
      const contractValue = row?.[contractFieldName];
      if (typeof contractValue !== "string") return row;
      const normalizedContract = contractValue.replace(/^Q-/, "");
      return normalizedContract === contractValue ? row : { ...row, [contractFieldName]: normalizedContract };
    });
  }

  _removeOrderItemColumnForInTransit() {
    this.columns = (this.columns || []).filter((column) => !this._isOrderItemColumn(column));
  }

  _initializeColumns(forceRebuild = false) {
    if (this.columns?.length && !forceRebuild) return;

    this.columns = buildManualColumns(this._manualFieldApiNames, this._manualFieldLabelNames);
    this._hideInternalIdColumns();
    this._removeOrderItemColumnForInTransit();

    const totalCols = this.columns.length;
    this.columns = this.columns.map((col, index) => {
      const isLast = index === totalCols - 1;
      return {
        ...col,
        initialWidth: 160,
        // initialWidth: isLast ? undefined : 160,
        wrapText: true
      };
    });
  }

  _toDualListOptions(values = []) {
    return (values || []).map((value) => ({ label: value, value }));
  }

  _cloneInTransitFilters(filters = {}) {
    return {
      orderNumber: (filters.orderNumber ?? EMPTY_IN_TRANSIT_FILTERS.orderNumber).trim(),
      vehicleId: (filters.vehicleId ?? EMPTY_IN_TRANSIT_FILTERS.vehicleId).trim(),
      contract: (filters.contract ?? EMPTY_IN_TRANSIT_FILTERS.contract).trim(),
      poNumber: (filters.poNumber ?? EMPTY_IN_TRANSIT_FILTERS.poNumber).trim(),
      products: [...(filters.products || EMPTY_IN_TRANSIT_FILTERS.products)],
      origins: [...(filters.origins || EMPTY_IN_TRANSIT_FILTERS.origins)],
      shipTos: [...(filters.shipTos || EMPTY_IN_TRANSIT_FILTERS.shipTos)],
      destinations: [...(filters.destinations || EMPTY_IN_TRANSIT_FILTERS.destinations)],
      statuses: [...(filters.statuses || EMPTY_IN_TRANSIT_FILTERS.statuses)]
    };
  }

  async refreshInTransitFilterOptions() {
    const result = await getInTransitFilterOptions({
      objectApiName: "ShipmentItem",
      baseWhereClause: this._composeEffectiveWhereClause(),
      orderNumber: this.inTransitPendingFilters.orderNumber,
      vehicleId: this.inTransitPendingFilters.vehicleId,
      contract: this.inTransitPendingFilters.contract,
      poNumber: this.inTransitPendingFilters.poNumber
    });

    this.inTransitFilterOptions = {
      products: result?.products || [],
      origins: result?.origins || [],
      shipTos: result?.shipTos || [],
      destinations: result?.destinations || [],
      statuses: result?.statuses || []
    };
  }

  async fetchPage(page = 1) {
    const seq = ++this._requestSeq;
    try {
      this.isLoading = true;

      const fieldApiNames = ensureFields(
        [...this._manualFieldApiNames],
        this.filterFieldName,
        this.dateFilterFieldName,
        this.endDateFilterFieldName,
        this.accountNamePath,
        this.sortField,
        IN_TRANSIT_MODE_FIELD,
        "Id",
        "PMC_CPQ_OrderProduct__r.OrderId"
      );

      this._initializeColumns(false);

      const searchFieldApiNames = (this.columns || []).map((column) => column.fieldName).filter(Boolean);
      const queryArgs = {
        objectApiName: "ShipmentItem",
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

      const res = this.inTransitApplyTriggered
        ? await listInTransitRecordsPaged({
          ...queryArgs,
          orderNumber: this.inTransitAppliedFilters.orderNumber || null,
          vehicleId: this.inTransitAppliedFilters.vehicleId || null,
          contract: this.inTransitAppliedFilters.contract || null,
          poNumber: this.inTransitAppliedFilters.poNumber || null,
          products: this.inTransitAppliedFilters.products || [],
          origins: this.inTransitAppliedFilters.origins || [],
          shipTos: this.inTransitAppliedFilters.shipTos || [],
          destinations: this.inTransitAppliedFilters.destinations || [],
          statuses: this.inTransitAppliedFilters.statuses || []
        })
        : await listRecordsPaged(queryArgs);

      if (seq !== this._requestSeq) return;

      const extraPaths = [
        this.filterFieldName,
        this.dateFilterFieldName,
        this.endDateFilterFieldName,
        this.accountNamePath,
        "Id",
        "PMC_CPQ_OrderProduct__r.OrderId"
      ];

      const { orderItemFieldName } = this._getOrderAndOrderItemFieldNames();
      if (orderItemFieldName && !extraPaths.includes(orderItemFieldName)) extraPaths.push(orderItemFieldName);

      const orderProductIdColumn = {
        label: "PMC_CPQ_OrderProduct__c",
        fieldName: "PMC_CPQ_OrderProduct__c",
        type: "text",
        editable: false,
        sortable: false
      };

      let rows = mapRecordsToRows(res.records, [...this.columns, orderProductIdColumn], extraPaths);
      rows = this._mergeOrderItemIntoOrderForInTransit(rows);
      rows = this._normalizeContractNumber(rows);

      this.originalData = rows;
      this.pageNumber = res.pageNumber || page;
      this.totalSize = res.totalSize || rows.length || 0;
      this.totalPages = Math.max(1, Math.ceil(this.totalSize / this.pageSize));
      this.data = rows;
      this.updatePageButtons();
    } catch (error) {
      this.showError("Error at pagination", error);
    } finally {
      if (seq === this._requestSeq) this.isLoading = false;
    }
  }

  connectedCallback() {
    this.subscription = subscribe(this.messageContext, ACCOUNT_SELECTION_CHANNEL, (msg) => this.handleMessage(msg), { scope: APPLICATION_SCOPE });
    this.tableTypeSubscription = subscribe(this.messageContext, FILTER_CHANNEL, (msg) => this.handleChangeTableType(msg), {
      scope: APPLICATION_SCOPE
    });

    const scoped = (key) => `${key}:${USER_ID}`;
    const localStorageTableType = localStorage.getItem(scoped("mosaic:tableType")) || localStorage.getItem("mosaic:tableType");
    if (localStorageTableType) this.storedTableType = localStorageTableType;

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
    } catch (error) {
      console.error("Error parsing stored account names:", error);
      this.selectedAccountNames = [];
    }

    const toastContainer = ToastContainer.instance();
    toastContainer.maxToasts = 5;
    toastContainer.toastPosition = "top-center";

    this._manualFieldApiNames = this.filterManualFields(this.manualFieldApiNames);
    this._manualFieldLabelNames = this.filterManualFields(this.manualFieldLabelNames);

    this._bootstrapped = this._canBootstrap();
    if (this._bootstrapped) this.loadManual();
  }

  disconnectedCallback() {
    unsubscribe(this.subscription);
    unsubscribe(this.tableTypeSubscription);
    this.subscription = null;
    this.tableTypeSubscription = null;
  }

  filterManualFields(manualFields) {
    return Array.isArray(manualFields)
      ? manualFields
      : typeof manualFields === "string"
        ? manualFields
          .split(",")
          .map((item) => item.trim())
          .filter(Boolean)
        : [];
  }

  handleMessage(message) {
    const scoped = (key) => `${key}:${USER_ID}`;
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
    }

    if (!this._bootstrapped) {
      if (this._canBootstrap()) {
        this._bootstrapped = true;
        this.loadManual();
      }
    } else if (changed) {
      this.fetchPage(1);
    }

    if (this._bootstrapped) this.updatePageButtons();
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

  handleSort(event) {
    const { fieldName, sortDirection } = event.detail;
    this.sortField = fieldName;
    this.sortDir = (sortDirection || "asc").toUpperCase();
    this.fetchPage(1);
  }

  handlePageChange(event) {
    const page = parseInt(event.detail?.page, 10);
    if (!isNaN(page) && page >= 1 && page <= this.totalPages && page !== this.pageNumber) this.fetchPage(page);
  }

  handleInTransitFilterChange(event) {
    const { section, filters } = event.detail || {};
    const nextFilters = this._cloneInTransitFilters(filters);

    if (section === "text") {
      this.inTransitPendingFilters = {
        ...nextFilters,
        products: [],
        origins: [],
        shipTos: [],
        destinations: [],
        statuses: []
      };
      this.refreshInTransitFilterOptions().catch((error) => this.showError("Error refreshing advanced filters", error));
      return;
    }

    this.inTransitPendingFilters = nextFilters;
  }

  handleToggleAdvanced() {
    this.showAdvancedFilters = !this.showAdvancedFilters;
  }

  handleApplyFilters(event) {
    this.inTransitApplyTriggered = true;
    this.inTransitAppliedFilters = this._cloneInTransitFilters(event.detail);
    this.pageNumber = 1;
    this.fetchPage(1);
  }

  handleClearInTransitFilters() {
    this.inTransitApplyTriggered = false;
    this.showAdvancedFilters = false;
    this.inTransitPendingFilters = this._cloneInTransitFilters({});
    this.inTransitAppliedFilters = this._cloneInTransitFilters({});
    this.inTransitFilterOptions = {
      products: [],
      origins: [],
      shipTos: [],
      destinations: [],
      statuses: []
    };

    this.fetchPage(1);
    this.refreshInTransitFilterOptions().catch((error) => this.showError("Error clearing advanced filters", error));
  }

  async loadManual() {
    try {
      this.isLoading = true;
      this._initializeColumns(true);
      await this.fetchPage(1);
      await this.refreshInTransitFilterOptions();
      this.updatePageButtons();
    } catch (error) {
      this.showError("Erro (modo manual)", error);
    } finally {
      this.isLoading = false;
    }
  }

  handleChangeTableType(message) {
    let tableType = (typeof message === "string" ? message : message?.tableType || message?.value || "").toString();
    if (!tableType) return;

    const normalizedType = tableType.trim().toLowerCase();
    let nextStoredType = "";
    if (normalizedType.includes("rail")) nextStoredType = "Rail";
    else if (normalizedType.includes("barge")) nextStoredType = "Barge";
    else return;

    this.storedTableType = nextStoredType;
    localStorage.setItem(`mosaic:tableType:${USER_ID}`, normalizedType);

    if (!this._bootstrapped) return;
    this.pageNumber = 1;
    this.fetchPage(1);
    this.refreshInTransitFilterOptions().catch((error) => this.showError("Error refreshing mode filter", error));
  }

  showToast({ label, message, variant = "info", mode = "dismissible", labelLinks, messageLinks, onclose }) {
    Toast.show({ label, message, variant, mode, labelLinks, messageLinks, onclose }, this);
  }

  showError(title, error) {
    const message = error?.body?.message || error?.message || String(error);
    this.showToast({ label: title, message, variant: "error", mode: "dismissible" });
  }
}