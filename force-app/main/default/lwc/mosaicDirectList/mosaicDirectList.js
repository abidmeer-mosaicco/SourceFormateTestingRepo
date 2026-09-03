import { LightningElement, api, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from "lightning/messageService";
import ACCOUNT_SELECTION_CHANNEL from "@salesforce/messageChannel/AccountSelectionChannel__c";
import FILTER_CHANNEL from "@salesforce/messageChannel/FilterEvent__c";
import Toast from "lightning/toast";
import ToastContainer from "lightning/toastContainer";
import listRecordsPaged from "@salesforce/apex/MosaicDirectListController.listRecordsPaged";
import listInTransitRecordsPaged from "@salesforce/apex/MosaicDirectListController.listInTransitRecordsPaged";
import getInTransitFilterOptions from "@salesforce/apex/MosaicDirectListController.getInTransitFilterOptions";
import checkDocumentButtons from "@salesforce/apex/MosaicDirectDocumentCheckAvailability.checkDocumentButtons";
import { buildManualColumns, ensureFields, formatValue, getBrowserLocale, mapRecordsToRows } from "./helper";
import USER_ID from "@salesforce/user/Id";

import md_reportfilters_headertitle from "@salesforce/label/c.md_reportfilters_headertitle";
import md_reportfilters_clear_btn from "@salesforce/label/c.md_reportfilters_clear_btn";
import md_reportfilters_apply_btn from "@salesforce/label/c.md_reportfilters_apply_btn";

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

const VALUE_FIELD_NAMES = ["PMC_CPQ_DeliveryQuantity__c"];

export default class MosaicDirectList extends NavigationMixin(LightningElement) {
  static VALUE_FIELD_NAMES = VALUE_FIELD_NAMES;

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
  @api numberLocale = "";
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
  _downloadSnapshotKey = null;
  noResults = false;
  noResultsMessage = "No records found.";
  pageNumber = 1;
  totalSize = 0;
  totalPages = 1;
  sortField = "LastModifiedDate";
  sortDir = "DESC";

  labels = {
    md_reportfilters_headertitle,
    md_reportfilters_clear_btn,
    md_reportfilters_apply_btn
  };

  @wire(MessageContext) messageContext;

  get hasRecords() {
    return this.totalSize > 0;
  }

  get tableTitle() {
    if (this.isInTrasitTable()) return "In Transit";

    const type = (this.datatableType || "").toString().trim();
    return type || "Documents";
  }

  get showTableTitle() {
    return !this.isInTrasitTable();
  }

  get showLegacyFilters() {
    return !this.isInTrasitTable();
  }

  get isInTransitTable() {
    return this.isInTrasitTable();
  }

  get datatableType() {
    return this.tableType;
  }

  get normalizedDatatableType() {
    return (this.datatableType || "").toString().trim().toLowerCase();
  }

  isInTrasitTable() {
    const type = this.normalizedDatatableType;
    return type === "intransit" || type === "in transit" || type === "in_transit";
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

  isQuote() {
    return (this.objectApiName || "").toLowerCase() === "sbqq__quote__c";
  }

  isShipmentItemTable() {
    return (this.objectApiName || "").toLowerCase() === "shipmentitem";
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

    const isQuote = this.isQuote();
    const namePath = this.accountNamePath || "";
    const sapPath = this.sapNumberPath || "";

    const hasInvalidPathsForQuote = isQuote && (namePath.includes("PMC_CPQ_OrderProduct__r") || sapPath.includes("PMC_CPQ_OrderProduct__r"));

    if (hasInvalidPathsForQuote) {
      return parts.join(" AND ");
    }

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
    if (!this.isInTrasitTable()) return baseWhere;

    const normalizedType = (this.storedTableType || "").toString().trim().toLowerCase();
    if (normalizedType !== "rail" && normalizedType !== "barge") return baseWhere;

    const motWhere = `${IN_TRANSIT_MODE_FIELD} = '${normalizedType === "rail" ? "Rail" : "Barge"}'`;
    if (!baseWhere) return motWhere;
    return `(${baseWhere}) AND (${motWhere})`;
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

  handleDocumentDownloadError() {
    this.showError("Document is not available, please contact your SSR.", "");
  }

  _removeDownloadColumns() {
    const removeLabels = new Set(["Invoice", "BOL", "COA", "Download All"]);
    this.columns = (this.columns || []).filter((c) => !removeLabels.has(c.label));
  }

  _appendQuoteContractColumn() {
    if (!this.isQuote()) return;
    if (this.isInTrasitTable()) return;

    this._removeDownloadColumns();

    const exists = (this.columns || []).some((c) => c.fieldName === "__open_contract__");
    if (exists) return;

    this.columns = [
      ...(this.columns || []),
      {
        label: "Contract",
        fieldName: "__open_contract__",
        type: "button-icon",
        fixedWidth: 90,
        initialWidth: 90,
        sortable: false,
        editable: false,
        cellAttributes: { alignment: "center" },
        typeAttributes: {
          iconName: "utility:download",
          alternativeText: "Open contract",
          title: "Open contract",
          name: "openContractUrl",
          size: "medium",
          variant: "bare"
        }
      }
    ];
  }

  _appendDownloadColumn() {
    if (this.isQuote() || this.isInTrasitTable()) return;
    if (this.isInTrasitTable()) return;

    const exists = (this.columns || []).some((c) => c.type === "documentDownload" || c.label === "Download");
    if (exists) return;

    this.columns = [
      ...(this.columns || []),
      {
        label: "Invoice",
        fieldName: "__invoice__",
        type: "documentDownloadInvoice",
        sortable: false,
        editable: false,
        typeAttributes: {
          orderId: { fieldName: "PMC_CPQ_OrderProduct__r.OrderId" },
          shipmentItemId: { fieldName: "Id" },
          invoiceFounded: { fieldName: "invoiceFounded" }
        }
      },
      {
        label: "BOL",
        fieldName: "__bol__",
        type: "documentDownloadBol",
        sortable: false,
        editable: false,
        typeAttributes: {
          orderId: { fieldName: "PMC_CPQ_OrderProduct__r.OrderId" },
          shipmentItemId: { fieldName: "Id" },
          bolFounded: { fieldName: "bolFounded" }
        }
      },
      {
        label: "COA",
        fieldName: "__coa__",
        type: "documentDownloadCoa",
        sortable: false,
        editable: false,
        typeAttributes: {
          orderId: { fieldName: "PMC_CPQ_OrderProduct__r.OrderId" },
          shipmentItemId: { fieldName: "Id" },
          coaFounded: { fieldName: "coaFounded" }
        }
      },
      // {
      //   label: "Contract",
      //   fieldName: "__contract__",
      //   type: "documentDownloadContract",
      //   sortable: false,
      //   editable: false,
      //   typeAttributes: {
      //     contractDocumentId: { fieldName: "PMC_CLM_ContractDocumentId__c" },
      //   }
      // },
      {
        label: "Download All",
        fieldName: "__download_all__",
        type: "documentDownloadAll",
        sortable: false,
        editable: false,
        typeAttributes: {
          orderId: { fieldName: "PMC_CPQ_OrderProduct__r.OrderId" },
          shipmentItemId: { fieldName: "Id" },
          invoiceFounded: { fieldName: "invoiceFounded" },
          bolFounded: { fieldName: "bolFounded" },
          coaFounded: { fieldName: "coaFounded" }
        }
      }
    ];
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
    if (fieldName.includes("sapordernumber")) return true;
    return false;
  }

  _isOrderFieldName(fieldName = "") {
    const normalized = String(fieldName || "")
      .trim()
      .toLowerCase();
    return normalized.endsWith(".ordernumber") || normalized.includes("sapordernumber");
  }

  _isOrderItemFieldName(fieldName = "") {
    const normalized = String(fieldName || "")
      .trim()
      .toLowerCase();
    return normalized.includes("orderitemnumber");
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
    if (!normalized) return "";
    return normalized.padStart(4, "0");
  }

  _mergeOrderItemIntoOrderForInTransit(rows = []) {
    if (!this.isShipmentItemTable()) return rows;

    const { orderFieldName, orderItemFieldName } = this._getOrderAndOrderItemFieldNames();
    if (!orderFieldName || !orderItemFieldName) return rows;

    return (rows || []).map((row) => {
      const orderValue = row?.[orderFieldName];
      const orderItemValue = row?.[orderItemFieldName];
      const paddedOrderItem = this._formatOrderItemWithLeftZeros(orderItemValue);

      if (!paddedOrderItem) return row;

      const ov = orderValue === null || orderValue === undefined ? "" : String(orderValue);

      if (ov.endsWith(paddedOrderItem)) return row;

      return {
        ...row,
        [orderFieldName]: `${ov}${paddedOrderItem}`
      };
    });
  }

  _normalizeContractNumber(rows = []) {
    const contractFieldName = "PMC_CPQ_OrderProduct__r.SBQQ__Contract__r.SBQQ__Quote__r.Name";

    return (rows || []).map((row) => {
      const contractValue = row?.[contractFieldName];
      if (typeof contractValue !== "string") return row;

      const normalizedContract = contractValue.replace(/^Q-/, "");
      if (normalizedContract === contractValue) return row;

      return {
        ...row,
        [contractFieldName]: normalizedContract
      };
    });
  }

  _removeOrderItemColumnForInTransit() {
    if (!this.isShipmentItemTable()) return;
    this.columns = (this.columns || []).filter((column) => !this._isOrderItemColumn(column));
  }

  _applyInTransitColumnStyling() {
    if (!this.isInTrasitTable()) return;
    this.columns = (this.columns || []).map((c, index) => ({
      ...c,
      initialWidth: index === this.columns.length - 1 ? 250 : 160,
      wrapText: true
    }));
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
    if (!this.isInTrasitTable()) return;

    const result = await getInTransitFilterOptions({
      objectApiName: this.objectApiName,
      baseWhereClause: this._composeEffectiveWhereClause(),
      orderNumber: this.inTransitPendingFilters.orderNumber,
      vehicleId: this.inTransitPendingFilters.vehicleId,
      contract: this.inTransitPendingFilters.contract,
      poNumber: this.inTransitPendingFilters.poNumber,
      products: [...(this.inTransitPendingFilters.products || [])],
      origins: [...(this.inTransitPendingFilters.origins || [])],
      shipTos: [...(this.inTransitPendingFilters.shipTos || [])],
      destinations: [...(this.inTransitPendingFilters.destinations || [])],
      statuses: [...(this.inTransitPendingFilters.statuses || [])]
    });

    this.inTransitFilterOptions = {
      products: result?.products || [],
      origins: result?.origins || [],
      shipTos: result?.shipTos || [],
      destinations: result?.destinations || [],
      statuses: result?.statuses || []
    };
  }

  handleInTransitFilterChange(event) {
    if (!this.isInTrasitTable()) return;
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

      this.refreshInTransitFilterOptions().catch((error) => {
        this.showError("Error refreshing advanced filters", error);
      });
      return;
    }

    this.inTransitPendingFilters = nextFilters;
    this.refreshInTransitFilterOptions().catch((error) => {
      this.showError("Error refreshing advanced filters", error);
    });
  }

  handleToggleAdvanced() {
    if (!this.isInTrasitTable()) return;
    this.showAdvancedFilters = !this.showAdvancedFilters;
  }

  handleApplyFilters(event) {
    if (!this.isInTrasitTable()) return;
    this.inTransitApplyTriggered = true;
    this.inTransitAppliedFilters = this._cloneInTransitFilters(event.detail);
    this._invalidateDownloadCache();
    this.pageNumber = 1;
    this.fetchPage(1);
  }

  handleClearInTransitFilters() {
    if (!this.isInTrasitTable()) return;

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

    this._invalidateDownloadCache();
    this.fetchPage(1);
    this.refreshInTransitFilterOptions().catch((error) => {
      this.showError("Error clearing advanced filters", error);
    });
  }

  async fetchPage(page = 1) {
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
      if (this.isQuote() && !fieldApiNames.includes("PMC_CLM_ContractURL__c")) {
        fieldApiNames.push("PMC_CLM_ContractURL__c");
      }
      if (this.objectApiName && this.objectApiName.toLowerCase() !== "sbqq__quote__c") {
        if (!fieldApiNames.includes("PMC_CPQ_OrderProduct__r.OrderId")) fieldApiNames.push("PMC_CPQ_OrderProduct__r.OrderId");
      }
      if (this.sortField && !fieldApiNames.includes(this.sortField)) {
        fieldApiNames.push(this.sortField);
      }
      if (this.isInTrasitTable() && !fieldApiNames.includes(IN_TRANSIT_MODE_FIELD)) {
        fieldApiNames.push(IN_TRANSIT_MODE_FIELD);
      }

      if (!this.columns?.length) {
        this.columns = buildManualColumns(this._manualFieldApiNames, this._manualFieldLabelNames);
        this._hideInternalIdColumns();
        this._removeOrderItemColumnForInTransit();
        this._appendDownloadColumn();
        this._appendQuoteContractColumn();
        this._applyInTransitColumnStyling();
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

      console.log("queryArgs", queryArgs);

      const res =
        this.isInTrasitTable() && this.inTransitApplyTriggered
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

      const extraPaths = [this.filterFieldName, this.dateFilterFieldName, this.endDateFilterFieldName, this.accountNamePath, "Id"];
      if (!this.isQuote()) {
        extraPaths.push("PMC_CPQ_OrderProduct__r.OrderId");
      } else {
        extraPaths.push("PMC_CLM_ContractURL__c");
        extraPaths.push("PMC_CPQ_OrderProduct__c");
      }

      if (this.isShipmentItemTable()) {
        const { orderItemFieldName } = this._getOrderAndOrderItemFieldNames();
        if (orderItemFieldName && !extraPaths.includes(orderItemFieldName)) {
          extraPaths.push(orderItemFieldName);
        }
      }

      let orderProductIdColumn = {
        label: "PMC_CPQ_OrderProduct__c",
        fieldName: "PMC_CPQ_OrderProduct__c",
        type: "text",
        editable: false,
        sortable: false
      };

      let rows = mapRecordsToRows(res.records, [...this.columns, orderProductIdColumn], extraPaths);

      if (this.objectApiName && this.objectApiName.toLowerCase() === "sbqq__quote__c" && res && res.computedValues) {
        const comp = res.computedValues;
        for (const row of rows) {
          const perField = comp[row.Id];
          if (!perField) continue;
          for (const key in perField) {
            if (Object.prototype.hasOwnProperty.call(perField, key)) {
              row[key] = perField[key];
            }
          }
        }
      }

      rows = this._mergeOrderItemIntoOrderForInTransit(rows);
      rows = this._normalizeContractNumber(rows);

      console.log({ columns: this.columns });
      console.log({ rows });

      if (this.objectApiName.toLowerCase() === "shipmentitem") {
        console.log({ res });

        if (res.records) {
          await checkDocumentButtons({ rawShipmentItems: JSON.stringify(rows) })
            .then((result) => {
              console.log({ result });

              try {
                let resultParsed = JSON.parse(result);
                console.log({ resultParsed });
                rows = [...resultParsed];
              } catch (error) {
                console.log({ error });
              }
            })
            .catch((error) => {
              console.log({ checkDocumentButtons_ERROR: error });
            });
        }
      }

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
      if (seq === this._requestSeq) this._toggleLoading(false);
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

    if (this.isInTrasitTable()) {
      const localStorageTableType = localStorage.getItem(scoped("mosaic:tableType")) || localStorage.getItem("mosaic:tableType");
      if (localStorageTableType) {
        this.storedTableType = localStorageTableType;
      }
    }

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
    if (actionName === "navigateToRecord" && row?.Id) {
      try {
        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: {
            recordId: row.Id,
            objectApiName: "Contract",
            actionName: "view"
          }
        });
      } catch (err) {
        this.showError("Error opening Contract", err);
      }
    } else if (actionName === "openContractUrl") {
      const url = row?.PMC_CLM_ContractURL__c;
      if (url) {
        try {
          window.open(url, "_blank");
        } catch (e) {
          this.showError("Unable to open contract link.", e);
        }
      } else {
        this.showError("No contract URL is available for this record.");
      }
    }
  }

  async loadManual() {
    try {
      this._toggleLoading(true);
      this.columns = buildManualColumns(this._manualFieldApiNames, this._manualFieldLabelNames);
      console.log("this.columns", this.columns);

      this._hideInternalIdColumns();
      this._removeOrderItemColumnForInTransit();
      this._appendDownloadColumn();
      this._appendQuoteContractColumn();
      this._applyInTransitColumnStyling();

      await this.fetchPage(1);
      if (this.isInTrasitTable()) {
        await this.refreshInTransitFilterOptions();
      }
      this.updatePageButtons();
    } catch (err) {
      this.showError("Erro (modo manual)", err);
    } finally {
      this._toggleLoading(false);
    }
  }

  handleNextPage() {
    if (this.isNextDisabled) return;
    this.fetchPage(this.pageNumber + 1);
  }

  handlePrevPage() {
    if (this.isPrevDisabled) return;
    this.fetchPage(this.pageNumber - 1);
  }

  handlePageClick(event) {
    const page = parseInt(event.currentTarget.dataset.page, 10);
    if (!isNaN(page) && page >= 1 && page <= this.totalPages && page !== this.pageNumber) {
      this.fetchPage(page);
    }
  }

  handleChangeTableType(message) {
    if (!this.isInTrasitTable()) return;
    console.log("message", message);

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
    this._invalidateDownloadCache();
    this.fetchPage(1);
    this.refreshInTransitFilterOptions().catch((error) => {
      this.showError("Error refreshing mode filter", error);
    });
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
    console.log("Showing error:", title, message, error);
    this.showToast({ label: title, message, variant: "error", mode: "dismissible" });
  }

  async handleRequestDownload(evt) {
    try {
      if (evt && typeof evt.stopPropagation === "function") evt.stopPropagation();

      // prepare to fetch all pages respecting current filters/sort like WalletList
      const manual = Array.isArray(this._manualFieldApiNames) && this._manualFieldApiNames.length ? this._manualFieldApiNames.slice() : [];
      // ensure some base fields present
      const fields = ensureFields(manual, "Id");

      const whereClause = this._composeEffectiveWhereClause() || this._composeWhereClause();
      const orderByField = this.sortField;

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

      rowsToPass = this._mergeOrderItemIntoOrderForInTransit(rowsToPass || []);

      const { orderFieldName, orderItemFieldName } = this._getOrderAndOrderItemFieldNames() || {};

      for (const row of rowsToPass) {
        let val = "";
        try {
          const orderVal = row?.[orderFieldName] ?? "";
          const itemVal = row?.[orderItemFieldName];
          const padded = this._formatOrderItemWithLeftZeros
            ? this._formatOrderItemWithLeftZeros(itemVal)
            : itemVal
              ? String(itemVal).padStart(4, "0")
              : "";
          const ovStr = String(orderVal ?? "");
          if (padded && ovStr.endsWith(padded)) {
            val = ovStr;
          } else {
            val = ovStr + (padded || "");
          }
        } catch (e) {
          val = "";
        }

        // fallback: prefer the exact value shown in the UI (`this.data`), then _filteredAll, then originalData
        if (!val) {
          const displayed =
            (this.data || []).find((r) => r?.Id === row?.Id) ||
            (this._filteredAll || []).find((r) => r?.Id === row?.Id) ||
            (this.originalData || []).find((r) => r?.Id === row?.Id);
          if (displayed && orderFieldName && displayed[orderFieldName]) {
            val = String(displayed[orderFieldName] ?? "").trim();
          }
        }

        row.export_order_number = val || "";
      }

      this.allRowsForDownload = rowsToPass || [];

      const child = this.template.querySelector("c-mosaic-direct-xls-download-btn");
      if (child) {
        let exportCols = (this.columns || []).slice();

        if (this.isInTrasitTable && this.isInTrasitTable()) {
          exportCols = exportCols.filter((c) => !this._isOrderItemColumn(c));
        }

        const fieldApiNames = exportCols.map((c) => c.fieldName).filter(Boolean);
        const labelNames = exportCols.map((c) => c.label || c.fieldName);

        child.manualFieldApiNames = fieldApiNames;
        child.manualFieldLabelNames = labelNames;

        child.allRows = this.allRowsForDownload || [];
        await child.downloadTable();
      }
    } catch (e) {
      // ignore
    }
  }

  async _ensureAllRowsCached(snapshotKey, whereClause, fields, orderByField) {
    if (!snapshotKey) return;
    if (this._downloadSnapshotKey === snapshotKey && this.allRowsForDownload && this.allRowsForDownload.length) return;
    this._downloadSnapshotKey = snapshotKey;
    this.allRowsForDownload = await this._fetchAllRows(whereClause, fields, orderByField);
  }

  async _fetchAllRows(whereClause, fields, orderByField) {
    const ps = Number(this.pageSize) || 50;
    const pages = Math.max(1, Math.ceil((this.totalSize || 0) / ps));
    const accum = [];

    const extraPaths = [this.filterFieldName, this.dateFilterFieldName, this.endDateFilterFieldName, this.accountNamePath, "Id"].filter(Boolean);
    if (!this.isQuote()) {
      extraPaths.push("PMC_CPQ_OrderProduct__r.OrderId");
    } else {
      extraPaths.push("PMC_CLM_ContractURL__c");
      extraPaths.push("PMC_CPQ_OrderProduct__c");
    }

    if (this.isShipmentItemTable()) {
      const { orderItemFieldName } = this._getOrderAndOrderItemFieldNames();
      if (orderItemFieldName && !extraPaths.includes(orderItemFieldName)) extraPaths.push(orderItemFieldName);
    }

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

      const res =
        this.isInTrasitTable() && this.inTransitApplyTriggered
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
            }).catch(() => null)
          : await listRecordsPaged(queryArgs).catch(() => null);

      if (res && res.records && res.records.length) {
        const rows = mapRecordsToRows(res.records, [...(this.columns || []), orderProductIdColumn], extraPaths);
        rows.forEach((r) => accum.push(r));
      }
    }

    try {
      if (typeof this._enrichRows === "function") await this._enrichRows(accum);
    } catch (e) {
      // ignore enrichment errors
    }

    // apply same client-side transforms as fetchPage
    let out = this._mergeOrderItemIntoOrderForInTransit(accum || []);
    out = this._normalizeContractNumber(out || []);
    return out;
  }

  get valueLocale() {
    return this.numberLocale || getBrowserLocale();
  }

  _formatValueColumns(rows) {
    const locale = this.valueLocale;
    return (rows || []).map((row) => {
      const formattedRow = { ...row };
      MosaicDirectList.VALUE_FIELD_NAMES.forEach((fieldName) => {
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