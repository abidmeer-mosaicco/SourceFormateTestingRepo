import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getContracts from "@salesforce/apex/QuoteUpdateController.getContracts";
import getExecution from "@salesforce/apex/QuoteUpdateController.getExecution";
import createOrUpdateQuoteExecution from "@salesforce/apex/QuoteUpdateController.createOrUpdateQuoteExecution";
import enqueueQuoteUpdate from "@salesforce/apex/QuoteUpdateController.enqueueQuoteUpdate";
import getSalesOfficeSalesArea from "@salesforce/apex/QuoteUpdateController.getSalesOfficeSalesArea";

import MassUpdate_Selector_Button_ContractColumns from "@salesforce/label/c.MassUpdate_Selector_Button_ContractColumns";
import MassUpdate_Selector_Button_ExpandColumns from "@salesforce/label/c.MassUpdate_Selector_Button_ExpandColumns";
import MassUpdate_Selector_Toast_ErrorLoading from "@salesforce/label/c.MassUpdate_Selector_Toast_ErrorLoading";
import MassUpdate_Selector_Toast_CouldNotLoad from "@salesforce/label/c.MassUpdate_Selector_Toast_CouldNotLoad";
import MassUpdate_Selector_Toast_NoSelection from "@salesforce/label/c.MassUpdate_Selector_Toast_NoSelection";
import MassUpdate_Selector_Toast_MissingDates from "@salesforce/label/c.MassUpdate_Selector_Toast_MissingDates";
import MassUpdate_Selector_Toast_InvalidSelection from "@salesforce/label/c.MassUpdate_Selector_Toast_InvalidSelection";
import MassUpdate_Selector_Toast_NothingToProcess from "@salesforce/label/c.MassUpdate_Selector_Toast_NothingToProcess";
import MassUpdate_Selector_Toast_MissingDatesDetail from "@salesforce/label/c.MassUpdate_Selector_Toast_MissingDatesDetail";
import MassUpdate_Selector_Toast_InvalidRows from "@salesforce/label/c.MassUpdate_Selector_Toast_InvalidRows";
import MassUpdate_Common_Button_First from "@salesforce/label/c.MassUpdate_Common_Button_First";
import MassUpdate_Common_Text_Loading from "@salesforce/label/c.MassUpdate_Common_Text_Loading";
import MassUpdate_Common_Alt_ToggleFilters from "@salesforce/label/c.MassUpdate_Common_Alt_ToggleFilters";
import MassUpdate_Selector_Alt_Contracts from "@salesforce/label/c.MassUpdate_Selector_Alt_Contracts";
import MassUpdate_Selector_Heading_SearchResults from "@salesforce/label/c.MassUpdate_Selector_Heading_SearchResults";
import MassUpdate_Selector_Text_NoRecords from "@salesforce/label/c.MassUpdate_Selector_Text_NoRecords";
import MassUpdate_Selector_Alt_Selected from "@salesforce/label/c.MassUpdate_Selector_Alt_Selected";
import MassUpdate_Selector_Heading_Selected from "@salesforce/label/c.MassUpdate_Selector_Heading_Selected";

import TOAST_ERROR_TITLE from "@salesforce/label/c.MassUpdate_ContractUpdate_Toast_Error_Title";
import TOAST_WARNING_TITLE from "@salesforce/label/c.MassUpdate_ContractUpdate_Toast_Warning_Title";
import TOAST_COULD_NOT_LOAD_FILTERS from "@salesforce/label/c.MassUpdate_Selector_Toast_CouldNotLoadFilters";
import TOAST_ERROR_LOADING_CONTRACTS from "@salesforce/label/c.MassUpdate_Selector_Toast_ErrorLoading";
import TOAST_NO_SELECTION_TITLE from "@salesforce/label/c.MassUpdate_Selector_Toast_NoSelection_Title";
import TOAST_NO_SELECTION from "@salesforce/label/c.MassUpdate_Selector_Toast_NoSelectionUpdateQuote";
import TOAST_NO_SO_OR_AM_TITLE from "@salesforce/label/c.MassUpdate_Selector_Toast_NoSOorAM_Title";
import TOAST_NO_SO_OR_AM from "@salesforce/label/c.MassUpdate_Selector_Toast_NoSOorAM";
import PROGRESS_TITLE from "@salesforce/label/c.MassUpdate_Progress_Title";
import PROGRESS_BATCHES_SENT from "@salesforce/label/c.MassUpdate_Progress_BatchesSent";
import PROGRESS_TOTAL_LINES from "@salesforce/label/c.MassUpdate_Progress_TotalLines";
import ERROR_VALIDATION_TITLE from "@salesforce/label/c.MassUpdate_Error_ValidationTitle";
import ERROR_VALIDATION_SALES_OFFICE_SALES_AREA from "@salesforce/label/c.MassUpdate_Error_Validation_SalesOfficeSalesArea";
import ERROR_VALIDATION_AM_SALES_OFFICE_SALES_AREA from "@salesforce/label/c.MassUpdate_Error_Validation_AMSalesOfficeSalesArea";
import ERROR_VALIDATION_AM_MISSING_SAPID from "@salesforce/label/c.MassUpdate_Error_Validation_AccountManagerMissingSAPID";
import ERROR_VALIDATION_CANNOT_SAVE from "@salesforce/label/c.MassUpdate_Error_Validation_CannotSave";
import ERROR_VALIDATION_RESOLVE_ERRORS from "@salesforce/label/c.MassUpdate_Error_Validation_ResolveErrors";

/**
 * QuoteUpdateSelector is the main component for selecting contracts to update and specifying new values for Sales Office and Account Manager.
 * It handles:
 * - Displaying a list of contracts based on filter criteria
 * - Allowing users to select contracts for update
 * - Capturing new Sales Office and Account Manager values
 * - Managing pagination and selection state across pages
 * - Emitting a "process" event with the selected records and new values when the user initiates the update
 * 
 * @author Sergio Umlauf
 * @storynumber GCPM-2771
 */
export default class QuoteUpdateSelector extends LightningElement {
    // Data state
    _executionId;
    isRendered = false;
    batchSize = 3;

    @api
    get executionId() {
        return this._executionId;
    }
    set executionId(val) {
        this._executionId = val;
        // When executionId changes, attempt to restore filters if none present
        this._handleExecutionIdChange();
    }

    get hasSelection() {
        return this.selected && this.selected.length > 0;
    }

    @track contracts = []; // Original data source (after server-side filtering)
    @track filteredContracts = []; // Kept for logic clarity, but functionally the same as 'contracts' after load
    @track selected = [];
    @track selectedIds = [];
    @track draftValues = [];
    @track dataErrors = { rows: {} };
    executionLineDTOs = [];
    salesOfficeSalesAreaDTO;

    // Pagination state
    pageSize = 100;
    @track currentPageNumber = 1;
    @track paginatedContracts = [];
    @track totalRecords = 0;
    @track hasMore = false;
    @track lastRecordId = null;
    @track lastRecordCreatedDate = null;
    @track pageHistory = []; // Stack to track cursor history for previous page
    @track pagesMap = new Map([[1, { id: null, createdDate: null }]]); // Map of pageNumber to cursor

    // Filters
    @track searchKey = "";
    @track soldTo;
    @track quoteNumber;
    @track type;
    @track sapOriginalContract;
    @track account;
    @track businessType;
    @track salesOffice;
    @track accountManager;
    @track contractDocStatus;
    @track contractValidFrom;
    @track contractValidTo;
    @track approvalStatus;
    @track quoteStatus;
    @track sapContractRef;

    // Update Inputs
    @track newSalesOffice;
    @track newAccountManager;

    // UI State
    @track isLoading = false;
    @track isPanelOpen = true;
    @track showFormModal = false;

    // @api columns = [];
    @api accountManagersAvailable = [];
    @track isSearchColumnsExpanded = false;
    @track isSelectedColumnsExpanded = false;

    _columns = [];
    @api
    set columns(value) {
        this._columns = value || [];
    }

    get columns() {
        return this._columns.map((col) => {
            if (col.fieldName === "AccountManagerName") {
                col = {
                    ...col,
                    fieldName: "AccountManagerUrl",
                    type: "url",
                    typeAttributes: { label: { fieldName: "AccountManagerName" }, target: "_blank" }
                };
            }

            return {
                ...col,
                editable: false,
                initialWidth: this.isSearchColumnsExpanded ? 200 : col.initialWidth || undefined
            };
        });
    }

    get editableColumns() {
        return this._columns?.map((col) => {
            const isDateField = col.fieldName && ["SalesOffice", "AccountManagerName"].includes(col.fieldName);
            const result = {
                ...col,
                initialWidth: this.isSelectedColumnsExpanded ? 200 : col.initialWidth || undefined,
                editable: isDateField
            };
            return result;
        });
    }

    get leftPanelClass() {
        return `slds-var-m-right_small left-panel ${this.isPanelOpen ? "open" : "closed"}`;
    }

    get toggleIcon() {
        return this.isPanelOpen ? "utility:left" : "utility:right";
    }

    get selectedCount() {
        return this.selected.length;
    }

    get disableProcess() {
        return !(this.selected.length && this.newSalesOffice && this.newAccountManager);
    }

    get hideCheckboxes() {
        return false;
    }

    get searchExpandIconName() {
        return this.isSearchColumnsExpanded ? "utility:contract_alt" : "utility:expand_alt";
    }

    get searchExpandButtonLabel() {
        return this.isSearchColumnsExpanded ? "Contrair Colunas" : "Expandir Colunas";
    }

    get selectedExpandIconName() {
        return this.isSelectedColumnsExpanded ? "utility:contract_alt" : "utility:expand_alt";
    }

    get selectedExpandButtonLabel() {
        return this.isSelectedColumnsExpanded ? "Contrair Colunas" : "Expandir Colunas";
    }

    get expandButtonLabel() {
        return this.isColumnsExpanded ? this.labels.contractColumns : this.labels.expandColumns;
    }

    get labels() {
        return {
            contractColumns: MassUpdate_Selector_Button_ContractColumns,
            expandColumns: MassUpdate_Selector_Button_ExpandColumns,
            errorLoading: MassUpdate_Selector_Toast_ErrorLoading,
            couldNotLoad: MassUpdate_Selector_Toast_CouldNotLoad,
            noSelection: MassUpdate_Selector_Toast_NoSelection,
            missingDates: MassUpdate_Selector_Toast_MissingDates,
            invalidSelection: MassUpdate_Selector_Toast_InvalidSelection,
            nothingToProcess: MassUpdate_Selector_Toast_NothingToProcess,
            missingDatesDetail: MassUpdate_Selector_Toast_MissingDatesDetail,
            invalidRows: MassUpdate_Selector_Toast_InvalidRows,
            firstButton: MassUpdate_Common_Button_First,
            loading: MassUpdate_Common_Text_Loading,
            toggleFilters: MassUpdate_Common_Alt_ToggleFilters,
            contracts: MassUpdate_Selector_Alt_Contracts,
            searchResults: MassUpdate_Selector_Heading_SearchResults,
            noRecords: MassUpdate_Selector_Text_NoRecords,
            selected: MassUpdate_Selector_Alt_Selected,
            selectedHeading: MassUpdate_Selector_Heading_Selected.replace("{0}", this.selectedCount)
        };
    }

    // Pagination getters
    get disablePrevious() {
        return this.currentPageNumber === 1;
    }

    get disableNext() {
        return !this.hasMore;
    }

    get showPagination() {
        return this.hasMore || this.pagesMap.size > 1;
    }

    get paginationInfo() {
        const start = this.filteredContracts.length > 0 ? (this.currentPageNumber - 1) * this.pageSize + 1 : 0;
        const end = start + this.filteredContracts.length - 1;
        if (this.totalRecords > 0) {
            return `${start}-${end} of ${this.totalRecords}`;
        }
        if (start === 0) {
            return "";
        }
        return `${start}-${end}`;
    }
    // End Pagination getters

    connectedCallback() {
        if (!this.salesOfficeSalesAreaDTO) {
            this.loadSalesOfficesAndSalesAreas();
        }
    }

    renderedCallback() {
        if (this.isRendered) {
            return;
        }
        this.isRendered = true;

        // Load initial contract data
        if (!this.filteredContracts) {
            this.loadContracts();
        }
    }

    async loadSalesOfficesAndSalesAreas() {
        this.salesOfficeSalesAreaDTO = await getSalesOfficeSalesArea();
    }

    handleToggleSearchColumnWidth() {
        this.isSearchColumnsExpanded = !this.isSearchColumnsExpanded;
    }

    handleToggleSelectedColumnWidth() {
        this.isSelectedColumnsExpanded = !this.isSelectedColumnsExpanded;
    }

    // New child component event handlers
    handleFiltersChange(event) {
        const { name, value } = event.detail;
        if (name === "searchKey") {
            this.searchKey = (value || "").toLowerCase();
        } else {
            this[name] = value;
        }
        // persist last filters JSON in parent so navigation preserves them
        this._captureLastFilters();
        // no client-side filtering; user must click Load to fetch filtered results
    }

    _captureLastFilters() {
        try {
            const payload = {
                search: this.searchKey,
                soldTo: this.soldTo,
                quoteNumber: this.quoteNumber,
                type: this.type,
                sapOriginalContract: this.sapOriginalContract,
                account: this.account,
                businessType: this.businessType,
                salesOffice: this.salesOffice,
                accountManager: this.accountManager,
                contractDocStatus: this.contractDocStatus,
                contractValidFrom: this.contractValidFrom,
                contractValidTo: this.contractValidTo,
                approvalStatus: this.approvalStatus,
                quoteStatus: this.quoteStatus,
                sapContractRef: this.sapContractRef
            };

            this._lastFiltersJSON = JSON.stringify(payload);
        } catch {
            // ignore serialization errors
        }
    }

    async _handleExecutionIdChange() {
        if (!this._executionId) {
            return;
        }
        try {
            const exec = await getExecution({ executionId: this._executionId });
            const qf = exec?.QueryFilters__c;
            if (qf) {
                // attempt to parse stored JSON filters and apply
                try {
                    const parsed = JSON.parse(qf);
                    this.searchKey = (parsed.search || "")?.toLowerCase();
                    this.soldTo = parsed.soldTo;
                    this.quoteNumber = parsed.quoteNumber;
                    this.type = parsed.type;
                    this.sapOriginalContract = parsed.sapOriginalContract;
                    this.account = parsed.account;
                    this.businessType = parsed.businessType;
                    this.salesOffice = parsed.salesOffice;
                    this.accountManager = parsed.accountManager;
                    this.contractDocStatus = parsed.contractDocStatus;
                    this.contractValidFrom = parsed.contractValidFrom;
                    this.contractValidTo = parsed.contractValidTo;
                    this.approvalStatus = parsed.approvalStatus;
                    this.quoteStatus = parsed.quoteStatus;
                    this.sapContractRef = parsed.sapContractRef;

                    // capture into last filters JSON using supported keys only
                    this._captureLastFilters();
                    this.loadContracts();
                } catch {
                    // not JSON — ignore
                }
            }
        } catch (e) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: TOAST_WARNING_TITLE,
                    message: TOAST_COULD_NOT_LOAD_FILTERS.replace("{0}", e.body?.message || e.message),
                    variant: "warning"
                })
            );
        }
    }

    handleLoadRequest() {
        this.resetPagination();
        this.loadContracts();
    }

    handleClearRequest() {
        this.handleClearFilters();
    }

    async loadContracts() {
        if (this.isLoading) return;
        this.isLoading = true;
        try {
            const payload = {
                search: this.searchKey,
                soldTo: this.soldTo,
                quoteNumber: this.quoteNumber,
                type: this.type,
                sapOriginalContract: this.sapOriginalContract,
                account: this.account,
                businessType: this.businessType,
                salesOffice: this.salesOffice,
                accountManager: this.accountManager,
                contractDocStatus: this.contractDocStatus,
                contractValidFrom: this.contractValidFrom,
                contractValidTo: this.contractValidTo,
                approvalStatus: this.approvalStatus,
                quoteStatus: this.quoteStatus,
                sapContractRef: this.sapContractRef
            };
            this._lastFiltersJSON = JSON.stringify(payload);
            let result = await getContracts({
                filtersJSON: this._lastFiltersJSON,
                pageSize: this.pageSize,
                lastRecordId: this.lastRecordId,
                lastRecordCreatedDate: this.lastRecordCreatedDate
            });

            this.totalRecords = result.totalRecords || this.totalRecords; // Keep existing count after first page
            this.hasMore = result.hasMore || false;

            if (result.lastRecordId && result.lastRecordCreatedDate) {
                this.lastRecordId = result.lastRecordId;
                this.lastRecordCreatedDate = result.lastRecordCreatedDate;
            }

            let data = result.contracts || [];
            data = (data || []).map((rec) => {
                const q = rec.PMC_CPQ_LatestQuote__r;
                return {
                    ...rec,
                    ContractUrl: "/" + rec.Id,
                    QuoteName: q != null ? q.Name : null,
                    LatestQuoteUrl: q != null ? "/" + q.Id : null,
                    QuoteType: q != null ? q.SBQQ__Type__c : null,
                    LegacyQuoteId: q != null ? q.PMC_CPQ_LegacyQuoteID__c : null,
                    AccountName: rec.Account != null ? rec.Account.Name : null,
                    AccountUrl: rec.AccountId ? "/" + rec.AccountId : null,
                    QuoteSubType: q != null ? q.PMC_CPQ_QuoteRecordSubType__c : null,
                    SalesOffice: q != null ? q.PMC_CPQ_SalesOffice__c : null,
                    AccountManagerName: q != null && q.PMC_CPQ_AccountManager__r != null ? q.PMC_CPQ_AccountManager__r.Name : null,
                    AccountManagerUrl: q != null && q.PMC_CPQ_AccountManager__c != null ? "/" + q.PMC_CPQ_AccountManager__c : null,
                    AccountManagerId: q != null ? q.PMC_CPQ_AccountManager__c : null,
                    QuoteContractStage: q != null ? q.PMC_CPQ_ContractStageName__c : null,
                    QuoteContractStart: q != null ? q.PMC_CPQ_ContractStart__c : null,
                    QuoteContractEnd: q != null ? q.PMC_CPQ_ContractEnd__c : null,
                    QuoteApprovalStatus: q != null ? q.ApprovalStatus__c : null,
                    QuoteStatus: q != null ? q.SBQQ__Status__c : null,
                    SapContractRef: q != null ? q.PMC_CPQ_SAPContractReference__c : null,
                    SalesArea: q != null ? q.PMC_CPQ_SalesAreaCombination__c : null
                };
            });
            this.contracts = data;
            this.filteredContracts = data;
        } catch (e) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: TOAST_ERROR_LOADING_CONTRACTS,
                    message: e.body?.message || e.message,
                    variant: "error"
                })
            );
        } finally {
            this.isLoading = false;
            this.updatePaginatedData();
        }
    }

    // Fully paginated-aware row selection handler (supports Select All per page)
    handleFilteredRowSelection(event) {
        const incomingRows = event.detail?.selectedRows || [];
        // Prevent selection of rows where the step is already in FinishedSteps__c
        const selectableRows = incomingRows.filter((row) => {
            // If FinishedSteps__c exists and includes the current step, do not allow selection
            if (row && row.FinishedSteps__c && row.Step__c && row.FinishedSteps__c.includes(row.Step__c)) {
                return false;
            }
            return true;
        });
        const incomingIdSet = new Set(selectableRows.map((r) => r.Id));
        // Only consider records on the current page when computing removals
        const currentPageRecords = this.paginatedContracts || [];
        const currentPageIds = new Set(currentPageRecords.map((r) => r.Id));
        const existingIdSet = new Set((this.selected || []).map((r) => r.Id));

        // Rows to add: newly checked in results
        const toAdd = [];
        selectableRows.forEach((row) => {
            if (row && row.Id && !existingIdSet.has(row.Id)) {
                toAdd.push(row);
            }
        });

        // Rows to remove: currently selected but now unchecked in the results set
        const toRemoveIds = new Set();
        (this.selected || []).forEach((r) => {
            if (r && r.Id && currentPageIds.has(r.Id) && !incomingIdSet.has(r.Id)) {
                toRemoveIds.add(r.Id);
            }
        });

        // Rebuild selected: keep everything except toRemoveIds, then add new
        if (toRemoveIds.size || toAdd.length) {
            const kept = (this.selected || []).filter((r) => !toRemoveIds.has(r.Id));
            this.selected = [...kept, ...toAdd];
        }

        // Sync selectedIds: add newly added rows as checked; remove unchecked ones
        const newCheckedSet = new Set(this.selectedIds || []);
        toAdd.forEach((r) => newCheckedSet.add(r.Id));
        toRemoveIds.forEach((id) => newCheckedSet.delete(id));
        this.selectedIds = Array.from(newCheckedSet);

        this.dispatchEvent(new CustomEvent("recordsselected", { detail: { records: this.selected } }));
    }

    /**
     * Sync checkbox state within the Selected Contracts table without creating extra arrays.
     * Keeps all rows in `selected`, but `selectedIds` reflects only the checked subset.
     * Keeps `selected` and `selectedIds` fully in sync when the user interacts
     * with the "Selected Contracts" table.
     */
    handleSelectedRowSelection(event) {
        const newlyCheckedRows = event.detail?.selectedRows || [];
        const newCheckedIds = new Set(newlyCheckedRows.map((r) => r.Id));

        // Remove any rows from selected that are now unchecked
        this.selected = (this.selected || []).filter((r) => newCheckedIds.has(r.Id));

        // Update selectedIds accordingly
        this.selectedIds = Array.from(newCheckedIds);

        // Emit the updated selection
        this.dispatchEvent(new CustomEvent("recordsselected", { detail: { records: this.selected } }));

        // Update paginated data (to refresh checkbox states across pages)
        this.updatePaginatedData();

        // Remove any errors
        this.cleanDataErrors();

        this.cleanDraftValues();
    }

    cleanDraftValues() {
        this.draftValues.forEach((dv, idx) => {
            if (!this.selectedIds.includes(dv.Id)) {
                this.draftValues.splice(idx, 1);
            }
        });
    }

    togglePanel() {
        this.isPanelOpen = !this.isPanelOpen;
    }

    process() {
        this.dispatchEvent(
            new CustomEvent("process", {
                detail: {
                    newSalesOffice: this.newSalesOffice,
                    newAccountManager: this.newAccountManager
                }
            })
        );
    }

    resetSelection() {
        this.selected = [];
        this.selectedIds = [];
        this.dispatchEvent(new CustomEvent("recordsselected", { detail: { records: [] } }));
        // Manually refresh paginated datatable to uncheck rows
        this.updatePaginatedData();
    }

    handleClearFilters() {
        this.searchKey = "";
        this.contracts = [];
        this.filteredContracts = [];
        this.paginatedContracts = [];
        this.currentPageNumber = 1;
        this.totalRecords = 0;
        this.resetSelection();
    }

    async handleCreateOrUpdateExecution() {
        try {
            let checkedIds = this.selectedIds || [];

            if (!checkedIds || !checkedIds.length) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: TOAST_NO_SELECTION_TITLE,
                        message: TOAST_NO_SELECTION,
                        variant: "warning"
                    })
                );
                return;
            }

            // Remove any execution lines without Sales Office or Account Manager
            this.executionLineDTOs = this.executionLineDTOs.filter((line) => line.salesOffice || line.accountManagerId);

            if (this.executionLineDTOs.length === 0) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: TOAST_NO_SO_OR_AM_TITLE,
                        message: TOAST_NO_SO_OR_AM,
                        variant: "error"
                    })
                );
                return;
            }

            const execIdToSend = this.executionId ? this.executionId : null;
            let qf = this._lastFiltersJSON || null;
            if (qf && qf.length > 255) {
                qf = qf.substring(0, 255);
            }

            console.log("Sending Execution Lines:", JSON.stringify(this.executionLineDTOs));

            const dto = await createOrUpdateQuoteExecution({
                feature: "QuoteUpdate",
                executionLineDTOs: JSON.stringify(this.executionLineDTOs),
                executionId: execIdToSend,
                queryFilters: qf
            });

            this._executionId = dto?.execution?.Id;

            let lineCount = 0;
            const updateStatusCounts = {};
            if (dto?.lines) {
                lineCount = dto.lines.length;
                dto.lines.forEach((l) => {
                    const key = l.Status__c || "NULL";
                    updateStatusCounts[key] = (updateStatusCounts[key] || 0) + 1;
                });
            }

            // Enfileira o processamento assíncrono das linhas em lotes de 10, exibindo modal de progresso
            const executionLineIds = dto.lines.map((l) => l.Id);
            let sent = 0;
            let errors = 0;
            let batches = Math.ceil(executionLineIds.length / this.batchSize);

            this.dispatchEvent(
                new CustomEvent("showprogressmodal", {
                    detail: {
                        open: true,
                        modalLabel: PROGRESS_TITLE,
                        progressItems: [
                            { label: PROGRESS_BATCHES_SENT, value: `0/${batches}` },
                            { label: PROGRESS_TOTAL_LINES, value: `${executionLineIds.length}` }
                        ],
                        isWorking: true,
                        isSuccess: false,
                        isError: false,
                        isPartial: false
                    },
                    bubbles: true,
                    composed: true
                })
            );

            for (let i = 0; i < executionLineIds.length; i += this.batchSize) {
                const batch = executionLineIds.slice(i, i + this.batchSize);
                try {
                    // eslint-disable-next-line no-await-in-loop
                    await enqueueQuoteUpdate({
                        executionLineIds: batch,
                        executionId: this.executionId
                    });
                    sent++;
                } catch {
                    errors++;
                }
                this.dispatchEvent(
                    new CustomEvent("showprogressmodal", {
                        detail: {
                            open: true,
                            modalLabel: PROGRESS_TITLE,
                            progressItems: [
                                { label: PROGRESS_BATCHES_SENT, value: `${sent}/${batches}` },
                                { label: PROGRESS_TOTAL_LINES, value: `${executionLineIds.length}` },
                                { label: TOAST_ERROR_TITLE, value: `${errors}` }
                            ],
                            isWorking: sent < batches,
                            isSuccess: errors === 0 && sent === batches,
                            isError: errors === batches,
                            isPartial: errors > 0 && errors < batches && sent === batches
                        },
                        bubbles: true,
                        composed: true
                    })
                );
            }
            this.dispatchEvent(
                new CustomEvent("executioncreated", {
                    detail: {
                        executionId: this.executionId,
                        lineCount,
                        updateStatusCounts
                    },
                    bubbles: true,
                    composed: true
                })
            );
        } catch (e) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: TOAST_ERROR_TITLE,
                    message: e.body?.message || e.message,
                    variant: "error"
                })
            );
        }
    }

    updatePaginatedData() {
        const start = (this.currentPageNumber - 1) * this.pageSize;
        const end = start + this.pageSize;
        const pageData = (this.contracts || []).slice(start, end);

        // Ensure selectedIds is a deduplicated array
        this.selectedIds = Array.from(new Set(this.selectedIds || []));

        // Map contracts by Id for quick lookup
        const contractMap = new Map((this.contracts || []).map((c) => [c.Id, c]));

        // Merge selectedIds into `selected` so we always have record objects for checked ids
        const selectedMap = new Map((this.selected || []).map((s) => [s.Id, s]));
        this.selectedIds.forEach((id) => {
            if (!selectedMap.has(id) && contractMap.has(id)) {
                selectedMap.set(id, contractMap.get(id));
            }
        });
        this.selected = Array.from(selectedMap.values());

        const selectedIdSet = new Set(this.selectedIds || []);
        const selectedFromArray = new Set((this.selected || []).map((s) => s.Id));

        // mark each row as selected if its Id is in selectedIds or present in selected array
        this.paginatedContracts = pageData.map((r) => ({
            ...r,
            _isSelected: selectedIdSet.has(r.Id) || selectedFromArray.has(r.Id)
        }));

        // Trigger reactivity for selectedIds (datatable bindings)
        this.selectedIds = [...this.selectedIds];
    }

    resetPagination() {
        this.currentPageNumber = 1;
        this.lastRecordId = null;
        this.lastRecordCreatedDate = null;
        this.pagesMap = new Map([[1, { id: null, createdDate: null }]]);
        this.hasMore = false;
    }

    handlePreviousPage() {
        if (this.pagesMap.size > 1) {
            this.currentPageNumber--;

            // Get the cursor for the previous page
            const previousCursor = this.pagesMap.get(this.currentPageNumber);
            this.lastRecordId = previousCursor.id;
            this.lastRecordCreatedDate = previousCursor.createdDate;

            this.loadContracts();
        }
    }

    handleNextPage() {
        if (this.hasMore) {
            // Save the next page's cursor before moving forward
            this.currentPageNumber++;

            if (!this.pagesMap.has(this.currentPageNumber)) {
                this.pagesMap.set(this.currentPageNumber, {
                    id: this.lastRecordId,
                    createdDate: this.lastRecordCreatedDate
                });
            }

            // lastRecordId and lastRecordCreatedDate are already set from the last loadContracts result
            this.loadContracts();
        }
    }

    handleFirstPage() {
        if (this.pagesMap.size > 0) {
            this.resetPagination();
            this.loadContracts();
        }
    }
    // End Pagination core logic

    // Computed label for selection summary
    get selectionSummary() {
        const totalSelected = this.selectedIds?.length || 0;
        const totalContracts = this.contracts?.length || 0;
        return `Selected ${totalSelected} of ${totalContracts}`;
    }

    updateDraftValues(updateItem) {
        let draftValueChanged = false;
        let copyDraftValues = [...this.draftValues];
        // Store changed value to do operations on save.
        // This will enable inline editing & show standard cancel & save button.
        copyDraftValues.forEach((item) => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    if (Object.hasOwn(updateItem, field)) {
                        item[field] = updateItem[field];
                    }
                }
                draftValueChanged = true;
            }
        });

        if (draftValueChanged) {
            this.draftValues = [...copyDraftValues];
        } else {
            this.draftValues = [...copyDraftValues, updateItem];
        }
    }

    // Handler to handle cell changes and update values in draft values
    handleCellChange(event) {
        // Here event.detail.draftValues["0"].AccountManagerName is Id of Account Manager.
        event.detail.draftValues.forEach((dv) => {
            let selectedAccountManager = this.accountManagersAvailable.find((am) => am.Id === dv.AccountManagerName);
            if (selectedAccountManager) {
                dv.AccountManagerName = selectedAccountManager.Name;
                dv.AccountManagerId = selectedAccountManager.Id;
            }
        });
        let draftValues = event.detail.draftValues;
        draftValues.forEach((ele) => {
            this.updateDraftValues(ele);
            if (ele.SalesOffice) {
                this.validateSalesOffice(ele);
            }
            if (ele.AccountManagerId) {
                this.validateAccountManager(ele);
            }
        });
    }

    getValidSalesOffices(contractId) {
        let record = this.contracts.find((contract) => contract.Id === contractId);
        const quoteSalesArea = this.salesOfficeSalesAreaDTO.salesAreas[record.PMC_CPQ_LatestQuote__r.PMC_CPQ_SalesAreaCombination__c];
        const result = this.salesOfficeSalesAreaDTO.salesOfficesForSalesAreas[quoteSalesArea];
        return result;
    }

    validateSalesOffice(draftValue) {
        // Remove any existing error message for Sales Office.
        this.removeDataErrorRow(draftValue, "SalesOffice");
        const validSalesOffices = this.getValidSalesOffices(draftValue.Id);
        const isValid = validSalesOffices.includes(draftValue.SalesOffice);
        if (!isValid) {
            this.addDataErrorRow(draftValue, ERROR_VALIDATION_TITLE, [ERROR_VALIDATION_SALES_OFFICE_SALES_AREA], ["SalesOffice"]);
        } else {
            // Remove any existing error message for Sales Office.
            this.removeDataErrorRow(draftValue, "SalesOffice");
        }
    }

    validateAccountManager(draftValue) {
        // Remove any existing error message for Account Manager.
        this.removeDataErrorRow(draftValue, "AccountManagerName");
        const newAccountManager = this.accountManagersAvailable.find((am) => am.Id === draftValue.AccountManagerId);
        if (newAccountManager) {
            // Check if SAP ID is present
            const isValidSAPId = !!newAccountManager.PMC_CPQ_SAPExternalUserId__c;
            // Check if account manager's Sales Office is valid for quote's Sales Area
            const validSalesOffices = this.getValidSalesOffices(draftValue.Id);
            const isValidSalesOffice = newAccountManager.PMC_CPQ_SalesOffice__c
                ? validSalesOffices.includes(newAccountManager.PMC_CPQ_SalesOffice__c)
                : true;
            let messages = [];
            let fieldNames = [];
            if (!isValidSAPId) {
                messages.push(ERROR_VALIDATION_AM_MISSING_SAPID.replace("{0}", draftValue.AccountManagerName));
                fieldNames.push("AccountManagerName");
            }
            if (!isValidSalesOffice) {
                messages.push(
                    ERROR_VALIDATION_AM_SALES_OFFICE_SALES_AREA.replace(
                        "{0}",
                        newAccountManager.PMC_CPQ_SalesOffice__c ? newAccountManager.PMC_CPQ_SalesOffice__c + " " : ""
                    )
                );
                fieldNames.push("AccountManagerName");
            }

            const isValid = isValidSAPId && isValidSalesOffice;

            if (!isValid) {
                this.addDataErrorRow(draftValue, ERROR_VALIDATION_TITLE, messages, fieldNames);
            }
        }
    }

    addDataErrorRow(draftValue, title, messages, fieldNames) {
        let existingRow = this.dataErrors.rows[draftValue.Id];
        if (existingRow) {
            existingRow.messages = [...existingRow.messages, ...messages];
            existingRow.fieldNames = [...existingRow.fieldNames, ...fieldNames];
        } else {
            let rowError = {};
            rowError[draftValue.Id] = {
                title: title,
                messages: messages,
                fieldNames: fieldNames
            };
            this.dataErrors.rows[draftValue.Id] = rowError[draftValue.Id];
        }
    }

    removeDataErrorRow(draftValue, fieldName) {
        // this.dataErrors.rows example:
        //
        // {"800RT00000SNS0HYAX":{  <------ The row Id is the contract Id.
        //     "title":ERROR_VALIDATION_TITLE,
        //     "messages":[
        //         "Account Manager ALAN SILVA is missing the SAP ID.",
        //         "Account Manager's Sales Office BR MT SUL B2C is not valid for quote's Sales Area."
        //     ],
        //     "fieldNames":[
        //         "AccountManagerName",
        //         "AccountManagerName"
        //     ]
        // }}
        let rows = this.dataErrors.rows;
        if (!rows[draftValue.Id]) {
            return;
        }
        if (
            // There is only one row in the dataErrors.rows object and it is for field SalesOffice.
            rows[draftValue.Id].fieldNames.length === 1 &&
            rows[draftValue.Id].fieldNames[0] === fieldName
        ) {
            delete rows[draftValue.Id];
        } else {
            let f = rows[draftValue.Id].fieldNames.find((fn) => fn !== fieldName);
            let onlyOneField = !f || f.length === 0;
            if (onlyOneField) {
                delete rows[draftValue.Id];
            } else {
                let i = rows[draftValue.Id].fieldNames.length;
                while (i--) {
                    if (rows[draftValue.Id].fieldNames[i] === fieldName) {
                        rows[draftValue.Id].fieldNames.splice(i, 1);
                        rows[draftValue.Id].messages.splice(i, 1);
                    }
                }
            }
        }
    }

    cleanDataErrors() {
        let rows = this.dataErrors?.rows;
        if (!rows) {
            return;
        }
        Object.keys(rows).forEach((id) => {
            if (!this.selectedIds.includes(id)) {
                delete rows[id];
            }
        });
    }

    handleSave() {
        if (this.dataErrors && this.dataErrors.rows && Object.keys(this.dataErrors.rows).length > 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: ERROR_VALIDATION_CANNOT_SAVE,
                    message: ERROR_VALIDATION_RESOLVE_ERRORS,
                    variant: "error"
                })
            );
            return;
        }

        // this.showSpinner = true;
        this.saveDraftValues = this.draftValues;
        this.executionLineDTOs = [];

        const recordInputs = this.saveDraftValues.slice().map((draft) => {
            const fields = Object.assign({}, draft);
            return { fields };
        });

        for (let r in recordInputs) {
            if (Object.hasOwn(recordInputs, r)) {
                let recordInput = recordInputs[r];
                let recordId = recordInput.fields.Id;
                // this.selectedIds.push(recordId);
                let record = this.contracts.find((contract) => contract.Id === recordId);
                let recordInputFields = recordInput.fields;
                let executionLineDTO = {
                    contractId: recordId,
                    latestQuoteId: record.PMC_CPQ_LatestQuote__c,
                    salesOffice: recordInputFields.SalesOffice,
                    accountManagerName: recordInputFields.AccountManagerName,
                    accountManagerId: recordInputFields.AccountManagerId,
                    oldSalesOffice: recordInputFields.SalesOffice && record.PMC_CPQ_LatestQuote__r.PMC_CPQ_SalesOffice__c,
                    oldAccountManagerName: recordInputFields.AccountManagerName && record.PMC_CPQ_LatestQuote__r.PMC_CPQ_AccountManager__r.Name,
                    oldAccountManagerId: recordInputFields.AccountManagerId && record.PMC_CPQ_LatestQuote__r.PMC_CPQ_AccountManager__c
                };
                this.executionLineDTOs.push(executionLineDTO);
            }
        }

        this.handleCreateOrUpdateExecution();
    }

    handleCancel() {
        // Remove draftValues and revert data changes
        // this.contracts = JSON.parse(JSON.stringify(this.lastSavedContracts));
        this.draftValues = [];
        this.dataErrors = { rows: {} };
    }
}