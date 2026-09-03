import { api, track } from "lwc";
import md_report, { NAM_LOCALE, formatBrowserDate } from "c/md_report";
import getContractFilterOptions from "@salesforce/apex/md_reportContractController.getContractFilterOptions";
import getQuotesWithContractFile from "@salesforce/apex/md_reportContractController.getQuotesWithContractFile";
import USER_ID from "@salesforce/user/Id";
import {
    EMPTY_FILTERS,
    EMPTY_FILTER_OPTIONS,
    toOptions,
    normalizeFilters,
    buildContractWhereClause,
    computeContractStatus,
    formatQuantity,
    formatPrice,
    formatDate,
    stripQPrefix
} from "./helper";
import ContractReportOrchestrator from "./orchestrator";

import hasDebug from "@salesforce/customPermission/MD_DEBUG";

const DEBUG = (...args) => {
    if (hasDebug) console.log("[md_reportContract]", ...args);
};

const CONTRACT_ACCOUNT_IDS_KEY = "mosaic:contractSelectedAccountIds";

const CONTRACT_STAGE_LABELS = {
    collecting_quotes: "Fetching contracts...",
    collecting_rejected: "Filtering rejected items...",
    collecting_enrichment: "Loading contract details..."
};
const scoped = (k) => `${k}:${USER_ID}`;

export default class Md_reportContract extends md_report {
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
    @api sapNumberPath = "";
    @api showDownloadButton = false;
    @api showTableTitle = false;

    exportFileName = "Contract";

    _ready = false;
    _orchestrator = null;
    _quoteIds = [];
    _rejectedClause = "";
    _lastAccountIds = [];

    @track _enrichmentMap = {};

    contractFilterOptions = { ...EMPTY_FILTER_OPTIONS };
    pendingFilters = { ...EMPTY_FILTERS };
    appliedFilters = { ...EMPTY_FILTERS };

    get showFilters() {
        return true;
    }

    get valueLocale() {
        return NAM_LOCALE;
    }

    getValueFieldNames() {
        return ["SBQQ__Quantity__c", "shippedQty", "openOrderQty", "remainingQty"];
    }

    get filterPrimaryFields() {
        return [
            { name: "contractNumber", label: "Contract Number", type: "text", value: this.pendingFilters.contractNumber },
            { name: "poNumber", label: "PO Number", type: "text", value: this.pendingFilters.poNumber },
            {
                name: "status",
                label: "Contract Status",
                isPicklist: true,
                options: toOptions(EMPTY_FILTER_OPTIONS.status),
                value: [...(this.pendingFilters.status || [])]
            },
            { name: "startDate", label: "Start Date", type: "date", value: this.pendingFilters.startDate },
            { name: "endDate", label: "End Date", type: "date", value: this.pendingFilters.endDate }
        ];
    }

    get filterAdvancedFields() {
        return [
            {
                name: "contractType",
                label: "Contract Type",
                isPicklist: true,
                options: toOptions(this.contractFilterOptions.contractType),
                value: [...(this.pendingFilters.contractType || [])]
            },
            {
                name: "product",
                label: "Product",
                isPicklist: true,
                options: toOptions(this.contractFilterOptions.product),
                value: [...(this.pendingFilters.product || [])]
            },
            {
                name: "origin",
                label: "Origin",
                isPicklist: true,
                options: toOptions(this.contractFilterOptions.origin),
                value: [...(this.pendingFilters.origin || [])]
            },
            {
                name: "shipTo",
                label: "Ship To",
                isPicklist: true,
                options: toOptions(this.contractFilterOptions.shipTo),
                value: [...(this.pendingFilters.shipTo || [])]
            }
        ];
    }

    connectedCallback() {
        super.connectedCallback();

        this._orchestrator = new ContractReportOrchestrator({
            onProgress: ({ stage, count, total }) => {
                DEBUG(`[Orchestrator] ${stage} | count: ${count ?? "-"}`);
                this._emitOrchestratorProgress({ action: 'progress', stage, label: CONTRACT_STAGE_LABELS[stage], count, total });
            },
            onComplete: ({ quoteIds, rejectedClause, enrichmentMap }) => {
                this._quoteIds = quoteIds;
                this._rejectedClause = rejectedClause;
                this._enrichmentMap = enrichmentMap;
                this._ready = true;
                this._emitOrchestratorProgress({ action: 'stop' });
                DEBUG({ _quoteIds: this._quoteIds, _enrichmentMap: this._enrichmentMap });
                this._refreshFilterOptions();
                this.fetchPage(1);
            },
            onError: (err) => {
                console.error("[ContractReport] Orchestrator error:", err);
                this._ready = true;
                this._emitOrchestratorProgress({ action: 'stop' });
                this._refreshFilterOptions();
                this.fetchPage(1);
            }
        });

        const storedIds = this._readStoredAccountIds();
        DEBUG("connectedCallback — storedAccountIds:", storedIds);
        if (!storedIds.length) return;

        this._lastAccountIds = storedIds;
        this._emitOrchestratorProgress({ action: 'start', title: 'Loading contracts...' });
        this._orchestrator.start(storedIds);
    }

    getFetchCustomArgs(queryArgs) {
        const fields = (queryArgs.fieldApiNames || []).filter((f) => f !== "PMC_CPQ_OrderProduct__c");
        return {
            ...queryArgs,
            fieldApiNames: fields
        };
    }

    getExtraQueryFields() {
        return [
            "SBQQ__Quote__c",
            "SBQQ__Quote__r.PMC_CPQ_PO__c"
        ];
    }

    processColumns(columns = []) {
        const DATE_TEXT_FIELDS = new Set([
            "SBQQ__Quote__r.PMC_CPQ_ContractStart__c",
            "SBQQ__Quote__r.PMC_CPQ_ContractEnd__c"
        ]);
        const base = (Array.isArray(columns) ? [...columns] : []).map((c) =>
            DATE_TEXT_FIELDS.has(c.fieldName) ? { ...c, type: "text", typeAttributes: undefined } : c
        );

        const injected = {
            contractItem: { label: "Contract Item", fieldName: "contractItem", type: "text", editable: false, sortable: false, wrapText: false, initialWidth: 150 },
            contractStatus: { label: "Contract Status", fieldName: "contractStatus", type: "text", editable: false, sortable: false, wrapText: false, initialWidth: 150 },
            shippedQty: { label: "Shipped Qty", fieldName: "shippedQty", type: "text", editable: false, sortable: false, wrapText: false, initialWidth: 150 },
            openOrderQty: { label: "Open Order Qty", fieldName: "openOrderQty", type: "text", editable: false, sortable: false, wrapText: false, initialWidth: 150 },
            remainingQty: { label: "Remaining Contract Qty", fieldName: "remainingQty", type: "text", editable: false, sortable: false, wrapText: false, initialWidth: 150 },
            downloadCol: {
                label: "Download Contract",
                fieldName: "contractDownloadAvailable",
                type: "documentDownloadQuoteContract",
                editable: false,
                wrapText: false,
                initialWidth: 140,
                typeAttributes: {
                    downloadUrl: { fieldName: "contractDownloadUrl" },
                    fileName: { fieldName: "contractDownloadFileName" },
                    hasFile: { fieldName: "contractDownloadAvailable" }
                }
            }
        };

        const byField = {};
        base.forEach((c) => { byField[c.fieldName] = c; });

        const ORDER = [
            "PMC_CPQ_Account__r.PMC_SS_SAPCustomerNumber__c",
            "PMC_CPQ_Account__r.Name",
            "SBQQ__Quote__r.MD_QuoteName__c",
            "contractItem",
            "SBQQ__Quote__r.PMC_CPQ_PO__c",
            "contractStatus",
            "PMC_CPQ_ContractType__c",
            "SBQQ__ProductName__c",
            "PMC_CPQ_ProductLocation__r.Name",
            "PMC_CPQ_ShipTo__r.ShipToFormula__c",
            "PMC_CPQ_Incoterms1__c",
            "PMC_CPQ_ModeofTransportation__c",
            "SBQQ__Quote__r.PMC_CPQ_ContractStart__c",
            "SBQQ__Quote__r.PMC_CPQ_ContractEnd__c",
            "PMC_CPQ_UnitofMeasure__c",
            "SBQQ__Quantity__c",
            "shippedQty",
            "openOrderQty",
            "remainingQty",
            "downloadCol"
        ];

        const UNSORTABLE_FIELDS = new Set([
            "PMC_CPQ_Account__r.PMC_SS_SAPCustomerNumber__c",
            "PMC_CPQ_Account__r.Name",
            "SBQQ__Quote__r.MD_QuoteName__c",
            "SBQQ__Quote__r.PMC_CPQ_PO__c",
            "PMC_CPQ_ProductLocation__r.Name",
            "PMC_CPQ_ShipTo__r.ShipToFormula__c",
            "SBQQ__Quote__r.PMC_CPQ_ContractStart__c",
            "SBQQ__Quote__r.PMC_CPQ_ContractEnd__c"
        ]);

        const result = [];
        const seen = new Set();

        ORDER.forEach((key) => {
            const col = injected[key] || byField[key];
            if (col) {
                const isUnsortable = UNSORTABLE_FIELDS.has(key) || key in injected;
                result.push(isUnsortable ? { ...col, sortable: false } : col);
                seen.add(key);
            }
        });

        base.forEach((c) => {
            if (!seen.has(c.fieldName)) {
                const isUnsortable = UNSORTABLE_FIELDS.has(c.fieldName);
                result.push(isUnsortable ? { ...c, sortable: false } : c);
            }
        });

        return result;
    }

    async processData(rows = []) {
        const map = this._enrichmentMap || {};

        const safeRows = Array.isArray(rows) ? rows : [];
        DEBUG("processData — rows in:", safeRows.length, "| enrichmentMap keys:", Object.keys(map).length, "| appliedFilters:", this.appliedFilters);
        DEBUG("processData — columns:", JSON.parse(JSON.stringify(this.columns || [])));
        if (safeRows[0]) {
            const sample = safeRows[0];
            const sampleEnr = map[sample.Id] || {};
            DEBUG("processData — sample row:", JSON.parse(JSON.stringify(sample)));
            DEBUG("processData — sample row date fields:", {
                raw_ContractStart: sample["SBQQ__Quote__r.PMC_CPQ_ContractStart__c"],
                raw_ContractEnd: sample["SBQQ__Quote__r.PMC_CPQ_ContractEnd__c"],
                enrichment_startDate: sampleEnr.startDate,
                enrichment_endDate: sampleEnr.endDate
            });
        }

        const quoteIdSet = new Set();
        let rowsMatched = 0;
        let rowsWithOrigQuote = 0;
        for (let i = 0; i < safeRows.length; i++) {
            const row = safeRows[i];
            const enr = row && map[row.Id];
            if (enr) rowsMatched++;
            const qId = (enr && enr.originalQuoteId) || (row && row.SBQQ__Quote__c) || null;
            if (qId) {
                rowsWithOrigQuote++;
                quoteIdSet.add(qId);
            }
        }
        const uniqueQuoteIds = Array.from(quoteIdSet);
        DEBUG("processData — rowsMatched:", rowsMatched, "| rowsWithOrigQuote:", rowsWithOrigQuote, "| uniqueQuoteIds:", uniqueQuoteIds);

        let downloadInfoByQuote = {};
        if (uniqueQuoteIds.length) {
            try {
                downloadInfoByQuote = (await getQuotesWithContractFile({ quoteIds: uniqueQuoteIds })) || {};
                DEBUG("processData — downloadInfoByQuote:", downloadInfoByQuote);
            } catch (err) {
                downloadInfoByQuote = {};
                DEBUG("processData — getQuotesWithContractFile error:", err);
            }
        }

        const result = [];
        for (let i = 0; i < safeRows.length; i++) {
            const row = safeRows[i] || {};
            const enrichment = map[row.Id] || {};
            const status = enrichment.contractStatus || computeContractStatus(enrichment.startDate, enrichment.endDate, enrichment.remainingQty);

            if (this.appliedFilters.status?.length && !this.appliedFilters.status.includes(status)) continue;

            const contractQty = enrichment.contractQty;
            const openOrderQty = enrichment.openOrderQty;
            const shippedQty = enrichment.shippedQty;
            const remainingQty = enrichment.remainingQty;

            const quoteIdForRow = (enrichment && enrichment.originalQuoteId) || row.SBQQ__Quote__c || null;
            const downloadInfo = (quoteIdForRow && downloadInfoByQuote[quoteIdForRow]) || {};

            result.push({
                ...row,
                contractItem: enrichment.sapItemNumber || "",
                contractStatus: status,
                openOrderQty: formatQuantity(openOrderQty),
                shippedQty: formatQuantity(shippedQty),
                remainingQty: formatQuantity(remainingQty),
                contractDownloadAvailable: !!downloadInfo.hasFile,
                contractDownloadUrl: downloadInfo.downloadUrl || "",
                contractDownloadFileName: downloadInfo.fileName || "",
                "SBQQ__Quantity__c": contractQty,
                "SBQQ__Quote__r.PMC_CPQ_PO__c": row["SBQQ__Quote__r.PMC_CPQ_PO__c"] || "",
                "SBQQ__Quote__r.PMC_CPQ_ContractStart__c": row["SBQQ__Quote__r.PMC_CPQ_ContractStart__c"] || formatDate(enrichment.startDate),
                "SBQQ__Quote__r.PMC_CPQ_ContractEnd__c": row["SBQQ__Quote__r.PMC_CPQ_ContractEnd__c"] || formatDate(enrichment.endDate),
                "SBQQ__Quote__r.MD_QuoteName__c": stripQPrefix(row["SBQQ__Quote__r.MD_QuoteName__c"] || enrichment.originalQuoteName || ""),
                contractNumber: enrichment.contractNumber || ""
            });
        }
        DEBUG("processData — rows out:", result.length);
        return result;
    }

    static SORTABLE_FIELDS = new Set([
        "SBQQ__ProductName__c",
        "PMC_CPQ_ContractType__c",
        "PMC_CPQ_Incoterms1__c",
        "PMC_CPQ_ModeofTransportation__c",
        "PMC_CPQ_UnitofMeasure__c",
        "LastModifiedDate"
    ]);

    handleSort(event) {
        const { fieldName } = event.detail;
        if (!Md_reportContract.SORTABLE_FIELDS.has(fieldName)) return;
        super.handleSort(event);
    }

    onPageLoaded(rows, res) {
        DEBUG("onPageLoaded — rows:", rows, "| totalSize:", res?.totalSize, "| pageNumber:", res?.pageNumber);
    }

    async fetchPage(page = 1) {
        if (!this._ready) return;
        await super.fetchPage(page);
        this._reapplySortable();
    }

    _reapplySortable() {
        const sortable = Md_reportContract.SORTABLE_FIELDS;
        this.columns = (this.columns || []).map((c) => {
            if (!sortable.has(c.fieldName)) return { ...c, sortable: false };
            return c;
        });
    }

    handleMessage(message) {
        const accountIds = message?.selectedAccountIds || [];
        const accountsChanged = JSON.stringify(accountIds) !== JSON.stringify(this._lastAccountIds);
        DEBUG("handleMessage — accountIds:", accountIds, "| accountsChanged:", accountsChanged);

        if (accountIds.length && accountsChanged) {
            this._lastAccountIds = accountIds;

            try {
                if (accountIds.length) localStorage.setItem(scoped(CONTRACT_ACCOUNT_IDS_KEY), JSON.stringify(accountIds));
                else localStorage.removeItem(scoped(CONTRACT_ACCOUNT_IDS_KEY));
            } catch (e) {
                DEBUG("Error saving to storage:", e);
            }

            this._orchestrator.abort();
            this._enrichmentMap = {};
            this._quoteIds = [];
            this._rejectedClause = "";
            this._ready = false;
            this._cursorCache = {};
            this._emitOrchestratorProgress({ action: 'start', title: 'Loading contracts...' });
            this._orchestrator.start(accountIds);
            return;
        }

        super.handleMessage(message);
    }

    getAdditionalWhereClause() {
        const parts = [];

        if (this._quoteIds?.length) {
            const quoted = this._quoteIds.map((id) => `'${String(id).replace(/'/g, "\\'")}'`).join(",");
            parts.push(`SBQQ__Quote__c IN (${quoted})`);
        }

        if (this._rejectedClause) parts.push(this._rejectedClause);

        const filtersClause = buildContractWhereClause(this.appliedFilters);
        if (filtersClause) parts.push(filtersClause);

        const statusFilter = this.appliedFilters?.status;
        if (statusFilter?.length) {
            const map = this._enrichmentMap || {};
            const matchingIds = Object.keys(map).filter((id) => {
                const e = map[id];
                const s = e.contractStatus || computeContractStatus(e.startDate, e.endDate, e.remainingQty);
                return statusFilter.includes(s);
            });
            if (matchingIds.length) {
                const quoted = matchingIds.map((id) => `'${String(id).replace(/'/g, "\\'")}'`).join(",");
                parts.push(`Id IN (${quoted})`);
            } else {
                parts.push("Id = null");
            }
        }

        DEBUG({ additionalWhereClause: parts.join(" AND ") });
        return parts.join(" AND ");
    }

    handleFilterChange(event) {
        const { section, filters } = event.detail || {};
        const resetAdvanced = { contractType: [], product: [], origin: [], shipTo: [] };
        if (section === "text") {
            this.pendingFilters = { ...this.pendingFilters, ...filters, ...resetAdvanced };
        } else {
            this.pendingFilters = { ...this.pendingFilters, ...filters };
        }
    }

    handleApplyFilters(event) {
        this.appliedFilters = normalizeFilters(event.detail);
        this._invalidateDownloadCache();
        this.fetchPage(1);
    }

    handleClearAdvancedFilters() {
        this.pendingFilters = { ...EMPTY_FILTERS };
        this.appliedFilters = { ...EMPTY_FILTERS };
        this._invalidateDownloadCache();
        this._refreshFilterOptions();
        this.fetchPage(1);
    }

    _emitOrchestratorProgress(detail) {
        window.dispatchEvent(new CustomEvent('openAmountProgress', { detail }));
    }

    _readStoredAccountIds() {
        try {
            const stored = JSON.parse(localStorage.getItem(scoped(CONTRACT_ACCOUNT_IDS_KEY)) || "[]");
            return Array.isArray(stored) ? stored : [];
        } catch (e) {
            return [];
        }
    }

    _refreshFilterOptions() {
        const f = this.pendingFilters;
        const openQuoteIds = this._quoteIds?.length ? this._quoteIds : null;

        const request = {
            baseWhereClause: this.baseWhereClause || null,
            quoteIds: openQuoteIds,
            appliedContractType: f.contractType?.length ? f.contractType : null,
            appliedProduct: f.product?.length ? f.product : null,
            appliedOrigin: f.origin?.length ? f.origin : null,
            appliedShipTo: f.shipTo?.length ? f.shipTo : null
        };
        DEBUG("_refreshFilterOptions — request:", request);

        getContractFilterOptions(request).then((result) => {
            this.contractFilterOptions = {
                status: EMPTY_FILTER_OPTIONS.status,
                contractType: result?.contractType || [],
                product: result?.product || [],
                origin: result?.origin || [],
                shipTo: result?.shipTo || []
            };
            DEBUG("_refreshFilterOptions — contractFilterOptions:", this.contractFilterOptions);
        }).catch((error) => {
            console.error("[ContractReport] Error loading filter options:", error);
            this.contractFilterOptions = { ...EMPTY_FILTER_OPTIONS };
        });
    }
}