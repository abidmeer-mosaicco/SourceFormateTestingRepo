import { LightningElement, track, api } from 'lwc';
import getContracts from '@salesforce/apex/ContractDateUpdateController.getContracts';
import getExecution from '@salesforce/apex/ContractDateUpdateController.getExecution';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import MassUpdate_Selector_Button_ContractColumns from '@salesforce/label/c.MassUpdate_Selector_Button_ContractColumns';
import MassUpdate_Selector_Button_ExpandColumns from '@salesforce/label/c.MassUpdate_Selector_Button_ExpandColumns';
import MassUpdate_Selector_Toast_ErrorLoading from '@salesforce/label/c.MassUpdate_Selector_Toast_ErrorLoading';
import MassUpdate_Selector_Toast_CouldNotLoad from '@salesforce/label/c.MassUpdate_Selector_Toast_CouldNotLoad';
import MassUpdate_Selector_Toast_NoSelection from '@salesforce/label/c.MassUpdate_Selector_Toast_NoSelection';
import MassUpdate_Selector_Toast_MissingDates from '@salesforce/label/c.MassUpdate_Selector_Toast_MissingDates';
import MassUpdate_Selector_Toast_InvalidSelection from '@salesforce/label/c.MassUpdate_Selector_Toast_InvalidSelection';
import MassUpdate_Selector_Toast_NothingToProcess from '@salesforce/label/c.MassUpdate_Selector_Toast_NothingToProcess';
import MassUpdate_Selector_Toast_MissingDatesDetail from '@salesforce/label/c.MassUpdate_Selector_Toast_MissingDatesDetail';
import MassUpdate_Selector_Toast_InvalidRows from '@salesforce/label/c.MassUpdate_Selector_Toast_InvalidRows';
import MassUpdate_Common_Button_First from '@salesforce/label/c.MassUpdate_Common_Button_First';
import MassUpdate_Common_Text_Loading from '@salesforce/label/c.MassUpdate_Common_Text_Loading';
import MassUpdate_Common_Alt_ToggleFilters from '@salesforce/label/c.MassUpdate_Common_Alt_ToggleFilters';
import MassUpdate_Selector_Alt_Contracts from '@salesforce/label/c.MassUpdate_Selector_Alt_Contracts';
import MassUpdate_Selector_Heading_SearchResults from '@salesforce/label/c.MassUpdate_Selector_Heading_SearchResults';
import MassUpdate_Selector_Text_NoRecords from '@salesforce/label/c.MassUpdate_Selector_Text_NoRecords';
import MassUpdate_Selector_Alt_Selected from '@salesforce/label/c.MassUpdate_Selector_Alt_Selected';
import MassUpdate_Selector_Heading_Selected from '@salesforce/label/c.MassUpdate_Selector_Heading_Selected';

/**
 * ContractDateUpdateSelector
 * Heavily inspired by pmc_cpq_QuoteMassUpdate, adapted for Contract object selection.
 * Emits:
 *  - recordsselected { records: Contract[] }
 *  - process { items: [{ contractId, startDate, endDate }], executionId, queryFilters }
 */
export default class ContractDateUpdateSelector extends LightningElement {
	// Data state
	_executionId;
	isRendered = false
	batchSize = 3;
	@api
	get executionId() {
		return this._executionId;
	}
	set executionId(val) {
		this._executionId = val;
		// when executionId changes, attempt to restore filters if none present
		this._handleExecutionIdChange();
	}

	get hasSelection(){
		return this.selected && this.selected.length > 0;
	}

	@track contracts = [];
	@track filteredContracts = [];
	@track selected = [];
	@track selectedIds = [];

	// Pagination state (keyset-based)
	@track pageSize = 100;
	@track totalRecords = 0;
	@track hasMore = false;
	@track lastRecordId = null;
	@track lastRecordCreatedDate = null;
	@track pageHistory = []; // Stack to track cursor history for previous page
	@track currentPageNumber = 1;

	// Filters
	@track searchKey = '';
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



	@track isLoading = false;
	@track isPanelOpen = true;
	@track isColumnsExpanded = false;

	// datatable draftValues binding for native inline edit
	@track draftValues = [];

	_columns = [];
	@api 
	set columns(value){
		this._columns = value || [];
	}

	get columns(){
		return this._columns.map(col => {
			return { 
				...col,
				editable: false,
				initialWidth: col.initialWidth || (this.isColumnsExpanded ? 200 : undefined),
			 };
		});
	}

	get editableColumns() {
		return this._columns?.map(col => {
			const isDateField = col.fieldName && ['QuoteContractStart','QuoteContractEnd'].includes(col.fieldName);
			const result = { 
				...col,
				initialWidth: col.initialWidth || (this.isColumnsExpanded ? 200 : undefined),
				editable: isDateField,
			 };
			 return result;
		});
	}

	get leftPanelClass() {
		return `slds-var-m-right_small left-panel ${this.isPanelOpen ? 'open' : 'closed'}`;
	}

	get toggleIcon() {
		return this.isPanelOpen ? 'utility:left' : 'utility:right';
	}

	get expandIconName() {
		return this.isColumnsExpanded ? 'utility:contract_alt' : 'utility:expand_alt';
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
			selectedHeading: MassUpdate_Selector_Heading_Selected.replace('{0}', this.selectedCount)
		};
	}

	get selectedCount() {
		return this.selected.length;
	}

	get disableProcess() {
		return !(this.selected && this.selected.length);
	}

	get hideCheckboxes() {
		return false;
	}

	get showPagination() {
		return this.hasMore || this.pageHistory.length > 0;
	}

	get disablePrevious() {
		return this.pageHistory.length === 0;
	}

	get disableNext() {
		return !this.hasMore;
	}

	get paginationInfo() {
		const start = this.filteredContracts.length > 0 ? ((this.currentPageNumber - 1) * this.pageSize) + 1 : 0;
		const end = start + this.filteredContracts.length - 1;
		if (this.totalRecords > 0) {
			return `${start}-${end} of ${this.totalRecords}`;
		}
		return `${start}-${end}`;
	}

	renderedCallback(){
		if(this.isRendered){
			return;
		}
		this.isRendered = true;

		// Load initial contract data
		if(!this.filteredContracts){
			this.loadContracts();
		}
	}

	handleFiltersChange(event) {
		const { name, value } = event.detail;
			console.log('handleFiltersChange:::', event.detail);
		if (name === 'searchKey') {
			this.searchKey = (value || '').toLowerCase();
		} else {
			this[name] = value;
		}
		this._captureLastFilters();
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
				sapContractRef: this.sapContractRef,

			};
			console.log('payload:::', payload);
			
			this._lastFiltersJSON = JSON.stringify(payload);
		} catch (e) {
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
					this.searchKey = (parsed.search || '')?.toLowerCase();
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
				} catch (pe) {
					// not JSON — ignore
				}
			}
		} catch (e) {
			this.dispatchEvent(new ShowToastEvent({ title: 'Warning', message: 'Could not load execution filters: ' + (e.body?.message || e.message), variant: 'warning' }));
		}
	}


	handleLoadRequest() {
		this.resetPagination();
		this.loadContracts();
	}

	resetPagination() {
		this.currentPageNumber = 1;
		this.lastRecordId = null;
		this.lastRecordCreatedDate = null;
		this.pageHistory = [];
		this.hasMore = false;
	}

	handleClearRequest() {
		this.handleClearFilters();
	}

	async loadContracts() {
		if(this.isLoading) return;
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
				sapContractRef: this.sapContractRef,

			};
			this._lastFiltersJSON = JSON.stringify(payload);
			const result = await getContracts({
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
			data = (data || []).map(rec => {
				const q = rec.PMC_CPQ_LatestQuote__r;
				let QuoteContractStart = q?.PMC_CPQ_ContractStart__c ? q.PMC_CPQ_ContractStart__c.split('T')[0] : null,
					QuoteContractEnd = q?.PMC_CPQ_ContractEnd__c ? q.PMC_CPQ_ContractEnd__c.split('T')[0] : null;

				return {
					...rec,
					ContractUrl: '/' + rec.Id,
					QuoteName: q?.Name,
					LatestQuoteUrl: q ? '/' + q.Id : null,
					QuoteType: q?.SBQQ__Type__c,
					LegacyQuoteId: q?.PMC_CPQ_LegacyQuoteID__c,
					AccountName: rec.Account?.Name,
					AccountUrl: rec.AccountId ? '/' + rec.AccountId : null,
					QuoteSubType: q?.PMC_CPQ_QuoteRecordSubType__c,
					SalesOffice: q?.PMC_CPQ_SalesOffice__c,
					AccountManagerName: q?.PMC_CPQ_AccountManager__r?.Name,
					AccountManagerUrl: q?.PMC_CPQ_AccountManager__c ? '/' + q.PMC_CPQ_AccountManager__c : null,
					QuoteContractStage: q?.PMC_CPQ_ContractStageName__c,
					QuoteContractStart: q?.PMC_CPQ_ContractStart__c ? q.PMC_CPQ_ContractStart__c.split('T')[0] : null,
					QuoteContractEnd: q?.PMC_CPQ_ContractEnd__c ? q.PMC_CPQ_ContractEnd__c.split('T')[0] : null,
					QuoteApprovalStatus: q?.ApprovalStatus__c,
					QuoteStatus: q?.SBQQ__Status__c,
					SapContractRef: q?.PMC_CPQ_SAPContractReference__c
				};
			});
			this.contracts = data;
			this.filteredContracts = data;
		} catch (e) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Error loading contracts',
					message: e.body?.message || e.message,
					variant: 'error'
				})
			);
		} finally {
			this.isLoading = false;
		}
	}

	handleRowSelection(event) {
		const incomingRows = event.detail?.selectedRows || [];
		// Prevent selection of rows where the step is already in FinishedSteps__c
		const selectableRows = incomingRows.filter(row => {
			// If FinishedSteps__c exists and includes the current step, do not allow selection
			if (row && row.FinishedSteps__c && row.Step__c && row.FinishedSteps__c.includes(row.Step__c)) {
				return false;
			}
			return true;
		});
		const incomingIdSet = new Set(selectableRows.map(r => r.Id));
		const resultsIdSet = new Set((this.filteredContracts || []).map(r => r.Id));
		const existingIdSet = new Set((this.selected || []).map(r => r.Id));

		// Rows to add: newly checked in results
		const toAdd = [];
		selectableRows.forEach(row => {
			if (row && row.Id && !existingIdSet.has(row.Id)) {
				toAdd.push(row);
			}
		});

		// Rows to remove: currently selected but now unchecked in the results set
		const toRemoveIds = new Set();
		(this.selected || []).forEach(r => {
			if (r && r.Id && resultsIdSet.has(r.Id) && !incomingIdSet.has(r.Id)) {
				toRemoveIds.add(r.Id);
			}
		});

		// Rebuild selected: keep everything except toRemoveIds, then add new
		if (toRemoveIds.size || toAdd.length) {
			const kept = (this.selected || []).filter(r => !toRemoveIds.has(r.Id));
			this.selected = [...kept, ...toAdd];
		}

		// Sync selectedIds: add newly added rows as checked; remove unchecked ones
		const newCheckedSet = new Set(this.selectedIds || []);
		toAdd.forEach(r => newCheckedSet.add(r.Id));
		toRemoveIds.forEach(id => newCheckedSet.delete(id));
		this.selectedIds = Array.from(newCheckedSet);

		this.dispatchEvent(new CustomEvent('recordsselected', { detail: { records: this.selected } }));
	}

	/**
	 * Sync checkbox state within the Selected Contracts table without creating extra arrays.
	 * Keeps all rows in `selected`, but `selectedIds` reflects only the checked subset.
	 */
	handleSelectedRowSelection(event) {
		//let rows = [...this.selected, ...(event.detail.selectedRows || [])].filter(record => record != null);
		this.selectedIds = event.detail.selectedRows.map(r => r.Id);
	}

	togglePanel() {
		this.isPanelOpen = !this.isPanelOpen;
	}

	handleToggleColumnWidth() {
		this.isColumnsExpanded = !this.isColumnsExpanded;
	}

	resetSelection() {
		this.selected = [];
		this.selectedIds = [];
		this.dispatchEvent(new CustomEvent('recordsselected', { detail: { records: [] } }));
	}

	handleClearFilters() {
		this.searchKey = '';
		this.soldTo = null;
		this.quoteNumber = null;
		this.type = null;
		this.sapOriginalContract = null;
		this.account = null;
		this.businessType = null;
		this.salesOffice = null;
		this.accountManager = null;
		this.contractDocStatus = null;
		this.contractValidFrom = null;
		this.contractValidTo = null;
		this.approvalStatus = null;
		this.quoteStatus = null;
		this.sapContractRef = null;
		this.filteredContracts = [];
		this.resetPagination();
	}

	handlePreviousPage() {
		if (this.pageHistory.length > 0) {
			this.currentPageNumber--;
			// Pop the last cursor from history and use it
			const previousCursor = this.pageHistory.pop();
			this.lastRecordId = previousCursor.id;
			this.lastRecordCreatedDate = previousCursor.createdDate;
			this.loadContracts();
		}
	}

	handleNextPage() {
		if (this.hasMore) {
			// Save the current page's cursor before moving forward
			this.pageHistory.push({
				id: this.pageHistory.length === 0 ? null : this.lastRecordId,
				createdDate: this.pageHistory.length === 0 ? null : this.lastRecordCreatedDate
			});

			this.currentPageNumber++;
			// lastRecordId and lastRecordCreatedDate are already set from the last loadContracts result
			this.loadContracts();
		}
	}

	handleFirstPage() {
		if (this.pageHistory.length > 0) {
			this.resetPagination();
			this.loadContracts();
		}
	}

	async handleGenerateAmendments() {
		const checkedIds = this.selectedIds || [];
		if (!checkedIds.length) {
			this.dispatchEvent(new ShowToastEvent({ title: 'Warning', message: this.labels.noSelection, variant: 'warning'}));
			return;
		}
		const selectedMap = new Map((this.selected || []).map(r => [r.Id, r]));
		const checkedContracts = checkedIds.map(id => selectedMap.get(id) || (this.filteredContracts || []).find(r => r.Id === id)).filter(Boolean);
		const missing = checkedContracts.filter(c => !c.QuoteContractStart && !c.QuoteContractEnd);
		if (missing.length) {
			this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: this.labels.missingDates, variant: 'error'}));
			return;
		}
		const items = checkedContracts.map(c => ({ contractId: c.Id, startDate: c.QuoteContractStart || null, endDate: c.QuoteContractEnd || null }));

		const validItems = items.filter(it => it && it.contractId);
		const invalidCount = items.length - validItems.length;
		if (invalidCount > 0) {
			this.dispatchEvent(new ShowToastEvent({ title: 'Warning', message: this.labels.invalidSelection.replace('{0}', invalidCount), variant: 'warning' }));
		}
		this.dispatchEvent(new CustomEvent('process', { detail: { items: validItems, executionId: this.executionId, queryFilters: this._lastFiltersJSON } }));
	}

	/**
	 * Handler for lightning-datatable onsave. Accepts draft values, updates local records,
	 * then groups by date-pair and calls generateAmendments for each group. Enqueues processing.
	 */

	async handleSave(event) {
		const drafts = event.detail.draftValues || [];
		if (!drafts.length) return;

		// Apply drafts to local state first
		const changedById = new Map(drafts.map(d => [d.Id, d]));
		const applyDrafts = arr => (arr || []).map(r => {
			const d = changedById.get(r.Id);
			if (!d) return r;
			return { ...r, ...(d.QuoteContractStart !== undefined ? { QuoteContractStart: d.QuoteContractStart } : {}), ...(d.QuoteContractEnd !== undefined ? { QuoteContractEnd: d.QuoteContractEnd } : {}) };
		});

		this.filteredContracts = applyDrafts(this.filteredContracts);
		this.contracts = applyDrafts(this.contracts);
		this.selected = applyDrafts(this.selected);

		// Determine which edited rows to process: prefer selected intersection, otherwise all draft rows
		const draftIds = drafts.map(d => d.Id).filter(Boolean);
		let targetIds = [];
		if (this.selectedIds && this.selectedIds.length) {
			targetIds = this.selectedIds.filter(id => draftIds.includes(id));
		}
		if (!targetIds.length) {
			targetIds = draftIds.slice();
		}

		if (!targetIds.length) {
			this.dispatchEvent(new ShowToastEvent({ title: 'Warning', message: this.labels.nothingToProcess, variant: 'warning' }));
			return;
		}

		// Build contract objects with new dates
		const selectedMap = new Map((this.selected || []).map(r => [r.Id, r]));
		const lookupFiltered = id => (this.filteredContracts || []).find(r => r.Id === id);
		const targetContracts = targetIds.map(id => {
			const draft = changedById.get(id) || {};
			const base = selectedMap.get(id) || lookupFiltered(id) || {};
			return { Id: id, QuoteContractStart: (draft.QuoteContractStart !== undefined ? draft.QuoteContractStart : base.QuoteContractStart), QuoteContractEnd: (draft.QuoteContractEnd !== undefined ? draft.QuoteContractEnd : base.QuoteContractEnd) };
		}).filter(Boolean);

		// Validate at least one date per contract
		const missing = targetContracts.filter(c => !c.QuoteContractStart && !c.QuoteContractEnd);
		if (missing.length) {
			this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: this.labels.missingDatesDetail, variant: 'error' }));
			return;
		}


		const items = targetContracts.map(c => ({ contractId: c.Id, startDate: c.QuoteContractStart || null, endDate: c.QuoteContractEnd || null }));
		const validItems = items.filter(it => it && it.contractId);
		const invalidCountSave = items.length - validItems.length;
		if (invalidCountSave > 0) {
			this.dispatchEvent(new ShowToastEvent({ title: 'Warning', message: this.labels.invalidRows.replace('{0}', invalidCountSave), variant: 'warning' }));
		}
		this.dispatchEvent(new CustomEvent('process', { detail: { items: validItems, executionId: this.executionId, queryFilters: this._lastFiltersJSON } }));

		this.draftValues = [];
	}

	handleCancel() {
		this.draftValues = [];
	}

}