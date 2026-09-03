import { api, track } from "lwc";
import md_report, { NAM_LOCALE, formatBrowserDate } from "c/md_report";
import getShipmentDataForOrderItems from "@salesforce/apex/md_reportOrdersController.getDataForOrderItems";
import getOrderFilterOptions from "@salesforce/apex/md_reportOrdersController.getOrderFilterOptions";
import hasDebug from "@salesforce/customPermission/MD_DEBUG";
import { EMPTY_FILTERS, EMPTY_FILTER_OPTIONS, toOptions, normalizeFilters, buildOrderWhereClause } from "./helper";

const DEBUG = (...args) => {
  if (hasDebug) console.log("[Md_reportOrders]", ...args);
};

const VEHICLE_ID_KEY = "Shipment__VehicleID";
const SHIPPED_DATE_KEY = "Shipment__ShippedDate";
const API_VEHICLE_ID = "__VEHICLE_ID__";
const API_SHIPPED_DATE = "__SHIPPED_DATE__";
const RESERVED_API_NAMES = new Set([API_VEHICLE_ID, API_SHIPPED_DATE]);

export default class Md_reportOrders extends md_report {
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
  @api sapNumberPath = "PMC_CPQ_SoldToAccount__r.PMC_SS_SAPCustomerNumber__c";
  @api showTableTitle = false;
  @api showDownloadButton = false;
  @api fixedColumnIndexVehicleId;
  @api fixedColumnIndexShippedDate;
  @api exportFileName = "Order";

  @track shipmentFilterOptions = { ...EMPTY_FILTER_OPTIONS };

  pendingFilters = { ...EMPTY_FILTERS };
  appliedFilters = { ...EMPTY_FILTERS };

  _filterOptionsSeq = 0;

  get showFilters() {
    return true;
  }

  get filterPrimaryFields() {
    return [
      { name: "orderNumber", label: "Order Number", type: "text", value: this.pendingFilters.orderNumber },
      { name: "poNumber", label: "PO Number", type: "text", value: this.pendingFilters.poNumber },
      { name: "dataInicio", label: "Start Date", type: "date", value: this.pendingFilters.dataInicio },
      { name: "dataFim", label: "End Date", type: "date", value: this.pendingFilters.dataFim }
    ];
  }

  get filterAdvancedFields() {
    return [
      {
        name: "orderStatus",
        label: "Order Status",
        isPicklist: true,
        options: toOptions(this.shipmentFilterOptions.orderStatus),
        value: [...(this.pendingFilters.orderStatus || [])]
      },
      {
        name: "product",
        label: "Product",
        isPicklist: true,
        options: toOptions(this.shipmentFilterOptions.product),
        value: [...(this.pendingFilters.product || [])]
      },
      {
        name: "origin",
        label: "Origin",
        isPicklist: true,
        options: toOptions(this.shipmentFilterOptions.origin),
        value: [...(this.pendingFilters.origin || [])]
      },
      {
        name: "shipTo",
        label: "Ship To",
        isPicklist: true,
        options: toOptions(this.shipmentFilterOptions.shipTo),
        value: [...(this.pendingFilters.shipTo || [])]
      }
    ];
  }

  connectedCallback() {
    super.connectedCallback();
    this.showAdvancedFilters = true;
    if (this._composeWhereClause()) {
      this._refreshFilterOptions();
    }
  }

  handleMessage(message) {
    super.handleMessage(message);
    if (this._composeWhereClause()) {
      this._refreshFilterOptions();
    }
  }

  getAdditionalWhereClause() {
    const clause = buildOrderWhereClause(this.appliedFilters);
    DEBUG({ additionalWhereClause: clause });
    return clause;
  }

  filterManualFields(manualFields) {
    DEBUG("filterManualFields");
    return super.filterManualFields(manualFields).filter((f) => !RESERVED_API_NAMES.has(f));
  }

  getFetchCustomArgs(queryArgs) {
    DEBUG("getFetchCustomArgs");
    const VIRTUAL_FIELDS = new Set([VEHICLE_ID_KEY, SHIPPED_DATE_KEY]);
    const seen = new Set();
    const deduped = (queryArgs.fieldApiNames || [])
      .filter((f) => !VIRTUAL_FIELDS.has(f))
      .filter((f) => {
        const key = (f || "").trim().toLowerCase();
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
      });
    const orderByField = Md_reportOrders.CLIENT_SORT_FIELDS.has(queryArgs.orderByField) ? null : queryArgs.orderByField;
    return { ...queryArgs, fieldApiNames: deduped, orderByField };
  }

  processColumns(columns = []) {
    DEBUG("processColumns");

    const injected = {
      [API_VEHICLE_ID]: { fieldName: VEHICLE_ID_KEY, type: "text", editable: false, sortable: false, initialWidth: 180 },
      [API_SHIPPED_DATE]: { fieldName: SHIPPED_DATE_KEY, type: "text", editable: false, sortable: false, initialWidth: 180 }
    };

    const byField = {};
    (Array.isArray(columns) ? [...columns] : []).forEach((c) => {
      byField[c.fieldName] = c;
    });

    const ORDER = this._parseCSV(this.manualFieldApiNames);
    const allLabels = this._parseCSV(this.manualFieldLabelNames);

    const result = [];
    const seen = new Set();

    ORDER.forEach((key, i) => {
      const label = allLabels[i] || key || "";

      if (!key) {
        result.push({ label, fieldName: `blank_${i}`, type: "text", editable: false, sortable: false });
        return;
      }

      const col = injected[key] || byField[key];
      if (col) {
        result.push({ ...col, label });
        seen.add(col.fieldName);
      }
    });

    (Array.isArray(columns) ? columns : []).forEach((c) => {
      if (!seen.has(c.fieldName)) result.push(c);
    });

    return result.map((c) => {
      return c.type === "date-local" ? { ...c, type: "text", typeAttributes: undefined } : c;
    });
  }

  static SORTABLE_FIELDS = new Set([
    "Quantity",
    "ActualShippedQuantity__c",
    "PMC_CPQ_SAPOrderLineID__c",
    "PMC_CPQ_OrderLineStatus__c",
    "PMC_CPQ_LinePONumber__c",
    "PMC_CPQ_Incoterms1__c",
    "PMC_CPQ_ModeofTransportation__c",
    "PMC_CPQ_UnitofMeasure__c",
    "LastModifiedDate"
  ]);

  static CLIENT_SORT_FIELDS = new Set([
    VEHICLE_ID_KEY,
    SHIPPED_DATE_KEY,
    "SBQQ__Contract__r.SBQQ__Quote__r.Name",
    "Product2.Name",
    "PMC_CPQ_ProductLocation__r.Name",
    "PMC_CPQ_SoldToAccount__r.Name",
    "PMC_CPQ_SoldtoAccount__r.Name",
    "PMC_CPQ_SoldToAccount__r.PMC_SS_SAPCustomerNumber__c",
    "PMC_CPQ_SoldtoAccount__r.PMC_SS_SAPCustomerNumber__c",
    "PMC_CPQ_ShipTo__r.ShipToFormula__c",
    "Order.PMC_DH_SAPOrderCreatedDate__c"
  ]);

  handleSort(event) {
    const { fieldName, sortDirection } = event.detail;
    if (Md_reportOrders.CLIENT_SORT_FIELDS.has(fieldName)) {
      this._doClientSort(fieldName, sortDirection);
      return;
    }
    if (!Md_reportOrders.SORTABLE_FIELDS.has(fieldName)) return;
    super.handleSort(event);
  }

  _doClientSort(fieldName, sortDirection) {
    const normalDir = (sortDirection || "asc").toLowerCase();
    const dir = normalDir === "asc" ? 1 : -1;
    this.data = [...(this.data || [])].sort((a, b) => {
      const va = a[fieldName] ?? "";
      const vb = b[fieldName] ?? "";
      if (va < vb) return -dir;
      if (va > vb) return dir;
      return 0;
    });
    this.sortField = fieldName;
    this.sortDir = normalDir.toUpperCase();
  }

  async fetchPage(page = 1) {
    await super.fetchPage(page);
    this._reapplySortable();
  }

  _reapplySortable() {
    const serverSort = Md_reportOrders.SORTABLE_FIELDS;
    const clientSort = Md_reportOrders.CLIENT_SORT_FIELDS;
    this.columns = (this.columns || []).map((c) => {
      if (serverSort.has(c.fieldName) || clientSort.has(c.fieldName)) return c;
      return { ...c, sortable: false };
    });
  }

  _parseCSV(value) {
    if (typeof value === "string") return value.split(",").map((s) => s.trim());
    if (Array.isArray(value)) return value.map((v) => String(v ?? "").trim());
    return [];
  }

  normalizeOrderNumber(value) {
    if (!value || !value.includes("_")) {
      return value;
    }

    const [prefix, suffix] = String(value).split("_");

    return `${prefix}${suffix.padStart(4, "0")}`;
  }

  get valueLocale() {
    return NAM_LOCALE;
  }

  getValueFieldNames() {
    return ["Quantity", "ActualShippedQuantity__c"];
  }

  formatContractNumber(value) {
    if (!value) {
      return value;
    }

    return String(value).replace(/^Q-/, "");
  }

  _formatDateValue(value) {
    if (!value || typeof value !== "string") return value;
    return /^\d{4}-\d{2}-\d{2}([T ]|$)/.test(value) ? formatBrowserDate(value) : value;
  }

  async processData(rows = []) {
    if (!rows?.length) return rows;

    const orderItemIds = rows.map((r) => r.Id).filter(Boolean);
    if (!orderItemIds.length) return rows;

    DEBUG("orderItemIds", orderItemIds);
    try {
      DEBUG("orderItemIds:", orderItemIds);
      const shipments = await getShipmentDataForOrderItems({ orderItemIds });
      DEBUG("Shipment data fetched:", shipments?.length);

      const shipmentMap = {};
      (shipments || []).forEach((shipment) => {
        if (shipment?.orderItemId) shipmentMap[shipment.orderItemId] = shipment;
      });

      let rawRows = rows.map((row) => {
        const shipment = shipmentMap[row.Id];
        const orderStatus = row.PMC_CPQ_OrderLineStatus__c === "Shipped" ? "Shipped" : "Open";
        const normalizedOrderNumber = this.normalizeOrderNumber(row.PMC_CPQ_SAPOrderLineID__c);
        const mapped = {
          ...row,
          PMC_CPQ_OrderLineStatus__c: orderStatus,
          PMC_CPQ_SAPOrderLineID__c: normalizedOrderNumber,
          export_order_number: normalizedOrderNumber,
          "SBQQ__Contract__r.SBQQ__Quote__r.Name": this.formatContractNumber(row["SBQQ__Contract__r.SBQQ__Quote__r.Name"]),
          [VEHICLE_ID_KEY]: shipment ? shipment.vehicleID : null,
          [SHIPPED_DATE_KEY]: shipment ? shipment.ShippedDate : null
        };
        Object.keys(mapped).forEach((k) => {
          mapped[k] = this._formatDateValue(mapped[k]);
        });
        return mapped;
      });

      DEBUG("rawRows", rawRows);

      return rawRows;
    } catch (e) {
      DEBUG("Error fetching shipment data:", e);
      return rows.map((row) => {
        const orderStatus = row.PMC_CPQ_OrderLineStatus__c === "Shipped" ? "Shipped" : "Open";
        const normalizedOrderNumber = this.normalizeOrderNumber(row.PMC_CPQ_SAPOrderLineID__c);
        const mapped = {
          ...row,
          PMC_CPQ_OrderLineStatus__c: orderStatus,
          PMC_CPQ_SAPOrderLineID__c: normalizedOrderNumber,
          export_order_number: normalizedOrderNumber,
          "SBQQ__Contract__r.SBQQ__Quote__r.Name": this.formatContractNumber(row["SBQQ__Contract__r.SBQQ__Quote__r.Name"]),
          [VEHICLE_ID_KEY]: null,
          [SHIPPED_DATE_KEY]: null
        };
        Object.keys(mapped).forEach((k) => {
          mapped[k] = this._formatDateValue(mapped[k]);
        });
        return mapped;
      });
    }
  }

  _validateDateRange(from, to) {
    if (!from || !to) return true;
    const diffDays = (new Date(to) - new Date(from)) / 86400000;
    return diffDays >= 0 && diffDays <= 10;
  }

  handleFilterChange(event) {
    const { section, filters } = event.detail || {};
    if (section === "text") {
      const resetAdvanced = { orderStatus: [], product: [], origin: [], shipTo: [] };
      this.pendingFilters = { ...this.pendingFilters, ...filters, ...resetAdvanced };
    } else {
      this.pendingFilters = { ...this.pendingFilters, ...filters };
    }
  }

  handleApplyFilters(event) {
    const filters = event.detail;
    /*if (!this._validateDateRange(filters.dataInicio, filters.dataFim)) {
            this.showToast({ label: "Intervalo inválido", message: "O intervalo máximo entre as datas é de 10 dias.", variant: "error" });
            return;
        }*/
    this.appliedFilters = normalizeFilters(filters);
    this._invalidateDownloadCache();
    this._refreshFilterOptions();
    this.fetchPage(1);
  }

  handleClearAdvancedFilters() {
    this.pendingFilters = { ...EMPTY_FILTERS };
    this.appliedFilters = { ...EMPTY_FILTERS };
    this._invalidateDownloadCache();
    this._refreshFilterOptions();
    this.fetchPage(1);
  }

  _refreshFilterOptions() {
    const accountWhere = this._composeWhereClause();
    if (!accountWhere) return;

    const filters = this.appliedFilters || EMPTY_FILTERS;
    const seq = ++this._filterOptionsSeq;

    getOrderFilterOptions({
      baseWhereClause: accountWhere,
      orderNumber: filters.orderNumber || null,
      poNumber: filters.poNumber || null,
      dataFim: filters.dataFim || null,
      dataInicio: filters.dataInicio || null,
      appliedOrderStatus: filters.orderStatus?.length ? filters.orderStatus : null,
      appliedProduct: filters.product?.length ? filters.product : null,
      appliedOrigin: filters.origin?.length ? filters.origin : null,
      appliedShipTo: filters.shipTo?.length ? filters.shipTo : null
    })
      .then((result) => {
        if (seq !== this._filterOptionsSeq) return;

        DEBUG("orderStatus", result?.orderStatus);

        const normalizedOrderStatus = [];
        const hasShipped = result?.orderStatus?.includes("Shipped");
        const hasOpen = result?.orderStatus?.some((status) => status !== "Shipped");

        if (hasOpen) {
          normalizedOrderStatus.push("Open");
        }

        if (hasShipped) {
          normalizedOrderStatus.push("Shipped");
        }

        this.shipmentFilterOptions = {
          orderStatus: normalizedOrderStatus,
          product: result?.product || [],
          origin: result?.origin || [],
          shipTo: result?.shipTo || []
        };
      })
      .catch((error) => {
        if (seq !== this._filterOptionsSeq) return;
        console.error("[Md_reportOrders] Error loading filter options:", error);
        this.shipmentFilterOptions = { ...EMPTY_FILTER_OPTIONS };
      });
  }
}