import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import generateAmendments from "@salesforce/apex/ContractDateUpdateController.generateAmendments";
import enqueueAmendmentProcessing from "@salesforce/apex/ContractDateUpdateController.enqueueAmendmentProcessing";
import saveLinesAndEnqueue from "@salesforce/apex/ContractDateUpdateController.saveLinesAndEnqueue";
import getExecutionLines from "@salesforce/apex/ContractDateUpdateController.getExecutionLines";
import checkEligibility from "@salesforce/apex/ContractDateUpdateController.checkEligibility";
import submitForApproval from "@salesforce/apex/ContractDateUpdateController.submitForApproval";
import generateContracts from "@salesforce/apex/ContractDateUpdateController.generateContracts";

import STAGE_SELECT from '@salesforce/label/c.MassUpdate_ContractUpdate_Stage_Select';
import STAGE_GENERATE_AMENDMENTS from '@salesforce/label/c.MassUpdate_ContractUpdate_Stage_GenerateAmendments';
import STAGE_CHECK_ELIGIBILITY from '@salesforce/label/c.MassUpdate_ContractUpdate_Stage_CheckEligibility';
import STAGE_SUBMIT_FOR_APPROVAL from '@salesforce/label/c.MassUpdate_ContractUpdate_Stage_SubmitForApproval';
import STAGE_GENERATE_CONTRACTS from '@salesforce/label/c.MassUpdate_ContractUpdate_Stage_GenerateContracts';
import CARD_PROCESSING from '@salesforce/label/c.MassUpdate_ContractUpdate_Card_Processing';
import TEXT_PROCESSING from '@salesforce/label/c.MassUpdate_ContractUpdate_Text_Processing';
import COLUMN_CONTRACT_NUMBER from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_ContractNumber';
import COLUMN_LATEST_QUOTE from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_LatestQuote';
import COLUMN_TYPE from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_Type';
import COLUMN_SAP_CONTRACT_REF from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_SAPContractRef';
import COLUMN_ACCOUNT from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_Account';
import COLUMN_BUSINESS_TYPE from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_BusinessType';
import COLUMN_SALES_OFFICE from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_SalesOffice';
import COLUMN_ACCOUNT_MANAGER from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_AccountManager';
import COLUMN_QUOTE_STATUS from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_QuoteStatus';
import COLUMN_CONTRACT_DOC_STATUS from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_ContractDocStatus';
import COLUMN_VALID_FROM_CURRENT from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_ValidFromCurrent';
import COLUMN_VALID_TO_CURRENT from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_ValidToCurrent';
import COLUMN_VALID_FROM from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_ValidFrom';
import COLUMN_VALID_TO from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_ValidTo';
import COLUMN_CREATED_AMENDMENT from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_CreatedAmendment';
import COLUMN_CONTACT_EMAIL from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_ContactEmail';
import COLUMN_STATUS from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_Status';
import COLUMN_INTEGRATION_RESULT from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_IntegrationResult';
import COLUMN_DOCUMENT_STATUS from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_DocumentStatus';
import COLUMN_MESSAGE from '@salesforce/label/c.MassUpdate_ContractUpdate_Column_Message';
import TOAST_ERROR_TITLE from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_Error_Title';
import TOAST_SUCCESS_TITLE from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_Success_Title';
import TOAST_INFO_TITLE from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_Info_Title';
import TOAST_PARTIAL_SUCCESS_TITLE from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_PartialSuccess_Title';
import TOAST_NO_ROWS_SELECTED from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_NoRowsSelected';
import TOAST_SENDING from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_Sending';
import TOAST_GENERATE_AMENDMENTS_FAILED from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_GenerateAmendmentsFailed';
import TOAST_AMENDMENT_ENQUEUED from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_AmendmentEnqueued';
import TOAST_LINES_UPDATED from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_LinesUpdated';
import TOAST_ERROR_SAVING from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_ErrorSaving';
import TOAST_UNKNOWN_ERROR from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_UnknownError';
import TOAST_ERROR_GENERATING from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_ErrorGenerating';
import TOAST_UNKNOWN_ERROR_GENERATING from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_UnknownErrorGenerating';
import TOAST_EXECUTION_LINES_CREATED from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_ExecutionLinesCreated';
import TOAST_PARTIAL_CREATION from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_PartialCreation';
import TOAST_ERROR_PROCESSING from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_ErrorProcessing';
import TOAST_UNKNOWN_ERROR_PROCESSING from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_UnknownErrorProcessing';
import STATUS_NOT_ELIGIBLE from '@salesforce/label/c.MassUpdate_ContractUpdate_Status_NotEligible';
import STATUS_PENDING from '@salesforce/label/c.MassUpdate_ContractUpdate_Status_Pending';
import STATUS_PENDING_APPROVAL from '@salesforce/label/c.MassUpdate_ContractUpdate_Status_PendingApproval';
import TOAST_NO_ROWS_ELIGIBILITY from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_NoRowsEligibility';
import TOAST_ELIGIBILITY_FAILED from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_EligibilityFailed';
import TOAST_ELIGIBILITY_ENQUEUED from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_EligibilityEnqueued';
import TOAST_NO_ROWS_APPROVAL from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_NoRowsApproval';
import TOAST_APPROVAL_FAILED from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_ApprovalFailed';
import TOAST_APPROVAL_COMPLETED from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_ApprovalCompleted';
import TOAST_NO_ROWS_CONTRACT from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_NoRowsContract';
import TOAST_CONTRACT_FAILED from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_ContractFailed';
import TOAST_CONTRACT_INITIATED from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_ContractInitiated';
import TOAST_EXECUTION_UPDATE from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_ExecutionUpdate';
import TOAST_STATUS_UPDATED from '@salesforce/label/c.MassUpdate_ContractUpdate_Toast_StatusUpdated';
import BUTTON_DETAILS from '@salesforce/label/c.MassUpdate_Common_Button_Details';
import BUTTON_REFRESH from '@salesforce/label/c.MassUpdate_Common_Button_Refresh';
import ERROR_NOT_ELIGIBLE_FINAL_PRICE from '@salesforce/label/c.MassUpdate_Error_NotEligibleFinalPricePerTonne';
import ERROR_NOT_ELIGIBLE_MARGIN from '@salesforce/label/c.MassUpdate_Error_NotEligibleMargin';

// English stage values for backend comparisons (FinishedSteps__c is stored in English)
const STAGE_SELECT_EN = 'Select';
const STAGE_GENERATE_AMENDMENTS_EN = 'Generate Amendments';
const STAGE_CHECK_ELIGIBILITY_EN = 'Check Eligibility';
const STAGE_SUBMIT_FOR_APPROVAL_EN = 'Submit for Approval';
const STAGE_GENERATE_CONTRACTS_EN = 'Generate Contracts';

// English status values for backend comparisons (CheckEligibilityStatus__c is stored in English)
const STATUS_NOT_ELIGIBLE_EN = 'Not Eligible';

// Remove direct import for submitForApproval, use imperative Apex call
export default class ContractDateUpdate extends LightningElement {
	_styleInjected = false;
	iframeLoaded = false;
	boundHandleVfPlatformEventMessage = null;

	// Map translated labels to English backend values for comparisons
	get stageMap() {
		return {
			[STAGE_SELECT]: STAGE_SELECT_EN,
			[STAGE_GENERATE_AMENDMENTS]: STAGE_GENERATE_AMENDMENTS_EN,
			[STAGE_CHECK_ELIGIBILITY]: STAGE_CHECK_ELIGIBILITY_EN,
			[STAGE_SUBMIT_FOR_APPROVAL]: STAGE_SUBMIT_FOR_APPROVAL_EN,
			[STAGE_GENERATE_CONTRACTS]: STAGE_GENERATE_CONTRACTS_EN
		};
	}

	get currentStepEN() {
		return this.stageMap[this.currentStep] || this.currentStep;
	}

	get labels() {
		return {
			STAGE_SELECT,
			STAGE_GENERATE_AMENDMENTS,
			STAGE_CHECK_ELIGIBILITY,
			STAGE_SUBMIT_FOR_APPROVAL,
			STAGE_GENERATE_CONTRACTS,
			CARD_PROCESSING,
			TEXT_PROCESSING: TEXT_PROCESSING.replace('{0}', this.totalSelected),
			COLUMN_CONTRACT_NUMBER,
			COLUMN_LATEST_QUOTE,
			COLUMN_TYPE,
			COLUMN_SAP_CONTRACT_REF,
			COLUMN_ACCOUNT,
			COLUMN_BUSINESS_TYPE,
			COLUMN_SALES_OFFICE,
			COLUMN_ACCOUNT_MANAGER,
			COLUMN_QUOTE_STATUS,
			COLUMN_CONTRACT_DOC_STATUS,
			COLUMN_VALID_FROM_CURRENT,
			COLUMN_VALID_TO_CURRENT,
			COLUMN_VALID_FROM,
			COLUMN_VALID_TO,
			COLUMN_CREATED_AMENDMENT,
			COLUMN_CONTACT_EMAIL,
			COLUMN_STATUS,
			COLUMN_INTEGRATION_RESULT,
			COLUMN_DOCUMENT_STATUS,
			COLUMN_MESSAGE,
			TOAST_ERROR_TITLE,
			TOAST_SUCCESS_TITLE,
			TOAST_INFO_TITLE,
			BUTTON_DETAILS,
			BUTTON_REFRESH
		};
	}
	@api executionId; // propagated from launcher
	@track currentStep = STAGE_SELECT;
	@track selectedRecords = [];
	@track successRecords = [];
	@track errorRecords = [];
	@track totalSelected = 0;
	@track allExecutionLines = [];
	@track selectedGenerateAmendments = [];
	@track selectedCheckEligibility = [];
	@track selectedSubmitForApproval = [];
	@track selectedGenerateContracts = [];
	get stages() {
		return [
			this.buildStage(STAGE_SELECT, this.currentStep === STAGE_SELECT, this.currentStep !== STAGE_SELECT && this.totalSelected > 0),
			this.buildStage(
				STAGE_GENERATE_AMENDMENTS,
				this.currentStep === STAGE_GENERATE_AMENDMENTS,
				this.allExecutionLines.some(line => line.FinishedSteps__c && line.FinishedSteps__c.includes(STAGE_GENERATE_AMENDMENTS_EN))
			),
			this.buildStage(STAGE_CHECK_ELIGIBILITY, this.currentStep === STAGE_CHECK_ELIGIBILITY, this.allExecutionLines.some(line => line.FinishedSteps__c && line.FinishedSteps__c.includes(STAGE_CHECK_ELIGIBILITY_EN))),
			this.buildStage(
				STAGE_SUBMIT_FOR_APPROVAL,
				this.currentStep === STAGE_SUBMIT_FOR_APPROVAL,
				this.allExecutionLines.some(line => line.FinishedSteps__c && line.FinishedSteps__c.includes(STAGE_SUBMIT_FOR_APPROVAL_EN))
			),
			this.buildStage(STAGE_GENERATE_CONTRACTS, this.currentStep === STAGE_GENERATE_CONTRACTS, this.allExecutionLines.some(line => line.FinishedSteps__c && line.FinishedSteps__c.includes(STAGE_GENERATE_CONTRACTS_EN)))
		];
	}

	get isGenerateAmendmentsStage() {
		return this.currentStep === STAGE_GENERATE_AMENDMENTS;
	}

	get isCheckEligibilityStage() {
		return this.currentStep === STAGE_CHECK_ELIGIBILITY;
	}

	get isSubmitForApprovalStage() {
		return this.currentStep === STAGE_SUBMIT_FOR_APPROVAL;
	}

	get isGenerateContractsStage() {
		return this.currentStep === STAGE_GENERATE_CONTRACTS;
	}

	get isSelectStage() {
		return this.currentStep === STAGE_SELECT;
	}

	get isProcessingStage() {
		return this.currentStep === "processing";
	}
	get isResultsStage() {
		return this.currentStep === "results";
	}
	get totalSelectedLabel() {
		return this.totalSelected ? `${this.totalSelected}` : "0";
	}
	get processingLabel() {
		return this.totalSelected ? `${this.successRecords.length + this.errorRecords.length}/${this.totalSelected}` : "0/0";
	}
	get resultsLabel() {
		return this.totalSelected ? `${this.successRecords.length}/${this.totalSelected}` : "0/0";
	}
	get generatedAmendmentsCountLabel() {
		return this.generatedAmendmentsTotal ? `${this.generatedAmendmentsTotal}` : "0";
	}
	get generatedAmendmentsTotal() {
		return this.allExecutionLines.length;
	}
	get showRefreshButton() {
		return [STAGE_GENERATE_AMENDMENTS, STAGE_CHECK_ELIGIBILITY, STAGE_SUBMIT_FOR_APPROVAL, STAGE_GENERATE_CONTRACTS, "results"].includes(this.currentStep);
	}
	get processingPercent() {
		if (!this.totalSelected) {
			return 0;
		}
		return Math.round(((this.successRecords.length + this.errorRecords.length) / this.totalSelected) * 100);
	}

	get columns() {
		return [
			{
				label: COLUMN_CONTRACT_NUMBER,
				fieldName: "ContractUrl",
				type: "url",
				typeAttributes: { label: { fieldName: "ContractNumber" }, target: "_blank" }
			},
			{
				label: COLUMN_LATEST_QUOTE,
				fieldName: "LatestQuoteUrl",
				type: "url",
				typeAttributes: { label: { fieldName: "QuoteName" }, target: "_blank" }
			},
			{ label: COLUMN_TYPE, fieldName: "QuoteType" },
			{ label: COLUMN_SAP_CONTRACT_REF, fieldName: "SapContractRef" },
			{
				label: COLUMN_ACCOUNT,
				fieldName: "AccountUrl",
				type: "url",
				typeAttributes: { label: { fieldName: "AccountName" }, target: "_blank" }
			},
			{ label: COLUMN_BUSINESS_TYPE, fieldName: "QuoteSubType" },
			{ label: COLUMN_SALES_OFFICE, fieldName: "SalesOffice" },
			{
				label: COLUMN_ACCOUNT_MANAGER,
				fieldName: "AccountManagerUrl",
				type: "url",
				typeAttributes: { label: { fieldName: "AccountManagerName" }, target: "_blank" }
			},
			this.currentStep == STAGE_SELECT && { label: COLUMN_QUOTE_STATUS, fieldName: "QuoteStatus" },
			this.currentStep == STAGE_SELECT && { label: COLUMN_CONTRACT_DOC_STATUS, fieldName: "QuoteContractStage" },
			this.currentStep == STAGE_GENERATE_AMENDMENTS && {
				label: COLUMN_VALID_FROM_CURRENT,
				fieldName: "StartDate",
				type: "date-local",
				typeAttributes: {
					year: "numeric",
					month: "2-digit",
					day: "2-digit"
				},
				cellAttributes: { style: "color: gray; text-decoration: line-through" }
			},
			this.currentStep == STAGE_GENERATE_AMENDMENTS && {
				label: COLUMN_VALID_TO_CURRENT,
				fieldName: "EndDate",
				type: "date-local",
				typeAttributes: {
					year: "numeric",
					month: "2-digit",
					day: "2-digit"
				},
				cellAttributes: { style: "color: gray; text-decoration: line-through" }
			},
			{ label: COLUMN_VALID_FROM, fieldName: "QuoteContractStart", 
				initialWidth: 128,
				editable: {fieldName: "editable"},
				type: 'date-local',
				typeAttributes: {
					year: "numeric",
					month: "2-digit",
					day: "2-digit"
				} },
			{ label: COLUMN_VALID_TO, fieldName: "QuoteContractEnd", 
				initialWidth: 128,
				editable: {fieldName: "editable"},
				type: 'date-local',
				typeAttributes: {
					year: "numeric",
					month: "2-digit",
					day: "2-digit"
				} },
			this.currentStep != STAGE_SELECT && {
				label: COLUMN_CREATED_AMENDMENT,
				fieldName: "CreatedQuoteUrl",
				type: "url",
				typeAttributes: { label: { fieldName: "amendName" }, target: "_blank" }
			},
			this.currentStep == STAGE_SUBMIT_FOR_APPROVAL && { label: COLUMN_CONTACT_EMAIL, fieldName: "amendContactEmail" },
			this.currentStep != STAGE_SELECT && {
				label: COLUMN_STATUS,
				fieldName: "Status",
				initialWidth: 100,
				type: "CustomIcon",
				typeAttributes: {
					iconName: { fieldName: "statusIcon" },
					variant: { fieldName: "statusIconVariant" },
					text: { fieldName: "statusText" },
					textClass: { fieldName: "textClass" },
					title: { fieldName: "title" },
					showSpinner: { fieldName: "showSpinner" }
				}
			},
			this.currentStep == STAGE_CHECK_ELIGIBILITY && {
				label: COLUMN_INTEGRATION_RESULT,
				fieldName: "integrationResult",
				initialWidth: 200,
				type: "text",
				cellAttributes: { title: { fieldName: "integrationResult" } }
			},
			this.currentStep == STAGE_GENERATE_CONTRACTS && { 
				label: COLUMN_DOCUMENT_STATUS, fieldName: "amendContractStageName" 

			},
			[STAGE_GENERATE_AMENDMENTS, STAGE_CHECK_ELIGIBILITY].includes(this.currentStep) && { label: COLUMN_MESSAGE, fieldName: "Message", initialWidth: 140 },
			this.currentStep != STAGE_SELECT && {
				type: "action",
				initialWidth: 48,
				cellAttributes: { alignment: "center" },
				typeAttributes: { rowActions: [{ label: BUTTON_DETAILS, name: "openRecord" }] }
			},
		].filter(col => !!col);
	}

	get orderedLines() {
		const stepOrder = {
			[STAGE_GENERATE_CONTRACTS]: 1,
			[STAGE_SUBMIT_FOR_APPROVAL]: 2,
			[STAGE_CHECK_ELIGIBILITY]: 3,
			[STAGE_GENERATE_AMENDMENTS]: 4
		};
		return (this.allExecutionLines || []).slice().sort((a, b) => {
			const stepA = stepOrder[a.Step__c] || 99;
			const stepB = stepOrder[b.Step__c] || 99;
			if (stepA !== stepB) {
				return stepA - stepB;
			}
			return a.ContractNumber.localeCompare(b.ContractNumber);
		});
	}

	buildStage(label, isCurrent, isComplete) {
		let countLabel = "0";
		const labelEN = this.stageMap[label] || label;
		if (!this.allExecutionLines) {
			countLabel = "0/" + this.allExecutionLines.length.toString();
		} else {
			countLabel = (label == STAGE_SELECT && this.allExecutionLines.length) || this.allExecutionLines.filter(l => l.FinishedSteps__c?.includes(labelEN)).length || 0;
			if (countLabel < this.allExecutionLines.length) {
				countLabel = `${countLabel}/${label == STAGE_SELECT || label == STAGE_CHECK_ELIGIBILITY ? this.allExecutionLines.length : this.allExecutionLines.filter(l => l.CheckEligibilityStatus__c != STATUS_NOT_ELIGIBLE).length}`;
			} else {
				countLabel = this.allExecutionLines.length.toString();
			}
		}
		return { label, countLabel, isCurrent, isComplete };
	}

	handleRecordsSelected(event) {
		this.selectedRecords = [...this.selectedRecords, ...(event.detail.records || [])].filter(record => record != null);
		this.totalSelected = this.selectedRecords.length;
	}

	get selectedRowIds() {
		return this.selectedRowsForStage.map(row => row.Id);
	}

	handleRowSelection(event) {
		let selectedRows = event.detail.selectedRows.filter(row => {
			let filterResult = !row.FinishedSteps__c?.split(";").includes(this.currentStepEN);
			return filterResult && !row.disabled && row.Step__c == this.currentStepEN;
		});
		if (this.isGenerateAmendmentsStage) {
			this.selectedGenerateAmendments = selectedRows.filter(row => !row.CreatedQuote__c);
		} else if (this.isCheckEligibilityStage) {
			this.selectedCheckEligibility = selectedRows;
		} else if (this.isSubmitForApprovalStage) {
			this.selectedSubmitForApproval = selectedRows.filter(row => {
				console.log('row.CheckEligibilityStatus__c:::', row.CheckEligibilityStatus__c);
				return row.CheckEligibilityStatus__c !== STATUS_NOT_ELIGIBLE_EN;
			});
		} else if (this.isGenerateContractsStage) {
			this.selectedGenerateContracts = selectedRows.filter(row => row.AmendApprovalStatus == 'Approved');
		}
		this.allExecutionLines = (this.allExecutionLines || []).map(l => this.mapLine(l));
	}

	async handleGenerateAmendments() {
		if (!this.selectedGenerateAmendments || this.selectedGenerateAmendments.length === 0) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: TOAST_ERROR_TITLE,
					message: TOAST_NO_ROWS_SELECTED,
					variant: "error"
				})
			);
			return;
		}
		const batchSize = 10;
		const ids = this.selectedGenerateAmendments.map(l => l.Id);
		let errors = [];
		for (let i = 0; i < ids.length; i += batchSize) {
			const batchIds = ids.slice(i, i + batchSize);
				try {
					// Enqueue amendment processing for execution lines (dates are read per-line on server)
					this.setStatusByIds(STAGE_GENERATE_AMENDMENTS, TOAST_SENDING, batchIds);
					const resp = await enqueueAmendmentProcessing({ executionLineIds: batchIds, executionId: this.executionId });
					console.log('resp', JSON.stringify(resp));
					
					// If server returned execution info (created or existing), persist executionId and update URL
					try {
						if (resp?.execution?.Id) {
							this.executionId = resp.execution.Id;
							const url = new URL(window.location.href);
							url.searchParams.set('c__executionId', this.executionId);
							window.history.replaceState({}, '', url.toString());
						}
					} catch (uErr) {
						console.warn('Failed to persist executionId from enqueue response', uErr);
					}
				} catch (e) {
				this.setStatusByIds(STAGE_GENERATE_AMENDMENTS, TOAST_ERROR_TITLE, batchIds);
				errors.push(...batchIds);
				this.dispatchEvent(
					new ShowToastEvent({
						title: TOAST_ERROR_TITLE,
						message: this.translateMessage(e.body && e.body.message ? e.body.message : TOAST_GENERATE_AMENDMENTS_FAILED),
						variant: "error"
					})
				);
			}
		}
		if (errors.length === 0) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: TOAST_SUCCESS_TITLE,
					message: TOAST_AMENDMENT_ENQUEUED,
					variant: "success"
				})
			);
		}
		this.handleRefreshLines();
	}

	/**
	 * Handle datatable save. When on Generate Amendments stage, persist edited valid-from/valid-to
	 * values onto execution lines (NewValues__c) and enqueue amendment processing for those lines.
	 */
	async handleSaveGenerateAmendments(event) {
		if (!this.isGenerateAmendmentsStage) {
			return;
		}
		const drafts = event?.detail?.draftValues || [];
		if (!drafts.length) {
			return;
		}
		// Map drafts into minimal execution line sObjects with Id and NewValues__c
		const linesToUpdate = drafts.map(d => {
			const nv = {};
			if (d.QuoteContractStart) nv.PMC_CPQ_ContractStart__c = d.QuoteContractStart;
			if (d.QuoteContractEnd) nv.PMC_CPQ_ContractEnd__c = d.QuoteContractEnd;
			return { Id: d.Id, NewValues__c: JSON.stringify(nv) };
		});
		try {
			const updated = await saveLinesAndEnqueue({ linesToUpdate, executionId: this.executionId });
			const updatedCount = Array.isArray(updated) ? updated.length : (updated ? 1 : 0);
			this.dispatchEvent(
				new ShowToastEvent({ title: TOAST_SUCCESS_TITLE, message: TOAST_LINES_UPDATED.replace('{0}', updatedCount), variant: 'success' })
			);
			// Refresh execution lines to reflect new values / enqueued status
			this.handleRefreshLines();
		} catch (err) {
			console.error('handleSave error', err);
			this.dispatchEvent(
				new ShowToastEvent({ title: TOAST_ERROR_SAVING, message: this.translateMessage(err?.body?.message || err?.message || TOAST_UNKNOWN_ERROR), variant: 'error' })
			);
		}
	}

	async handleProcessRequest(event) {
		// Expecting event.detail.items = [{ contractId, startDate, endDate }, ...]
		const items = (event.detail && event.detail.items) ? event.detail.items : [];
		// Use a mutable executionId so we can persist the id created by the first batch
		let executionId = (event.detail && event.detail.executionId) ? event.detail.executionId : (this.executionId || null);
		const queryFilters = event.detail && event.detail.queryFilters ? event.detail.queryFilters : null;
		if (!items || items.length === 0) {
			// nothing to process
			return;
		}
		try {
			const batchSize = 10;
			const allSuccess = [];
			const allErrors = [];
			for (let i = 0; i < items.length; i += batchSize) {
				const batch = items.slice(i, i + batchSize);
				try {
					// Log payload being sent to server for debugging
					try {
						// Log the serialized payload to ensure network request contains exact JSON
						const payloadForLog = { feature: 'ContractDateUpdate', itemsJson: JSON.stringify(batch), executionId, queryFilters };
						console.log('Calling generateAmendments', JSON.stringify(payloadForLog));
					} catch (dbgErr) {
						console.log('Calling generateAmendments (non-serializable payload)', { feature: 'ContractDateUpdate', items, executionId, queryFilters });
					}
					const result = await generateAmendments({ feature: 'ContractDateUpdate', itemsJson: JSON.stringify(batch), executionId, queryFilters });
					console.log(`result::` , result);
					
					// generateAmendments returns ExecutionDTO with lines created. Collect created line ids as success markers.
					const createdLines = (result && result.lines) ? result.lines.map(l => l.Id) : [];
					allSuccess.push(...createdLines);
					// If execution was created on server side, store it locally and update URL so component loads context
					if (result && result.execution && result.execution.Id) {
						// persist both the local mutable executionId for subsequent batches and the component state
						executionId = result.execution.Id;
						if(executionId && !this.executionId){
							this.dispatchEvent(new CustomEvent('executioncreated', { detail: { executionId }, bubbles: true, composed: true }));
						}
						this.executionId = result.execution.Id;
						try {
							const url = new URL(window.location.href);
							url.searchParams.set('c__executionId', this.executionId);
							window.history.replaceState({}, '', url.toString());
						} catch (uErr) {
							console.warn('Failed to update URL with executionId', uErr);
						}
					}
				} catch (err) {
					// mark all ids in this batch as error if call failed
					batch.forEach(b => allErrors.push({ Id: b.contractId, message: this.translateMessage(err.body?.message || err.message) }));
					// Log detailed error and show toast so user sees server-side exception
					console.error('generateAmendments batch error:', err);
					this.dispatchEvent(
						new ShowToastEvent({
							title: TOAST_ERROR_GENERATING,
							message: this.translateMessage(err?.body?.message || err?.message || TOAST_UNKNOWN_ERROR_GENERATING),
							variant: 'error'
						})
					);
				}
			}
			this.successRecords = allSuccess.map(id => ({ Id: id }));
			this.errorRecords = allErrors || [];
			// Show summary toast
			if ((allErrors || []).length === 0) {
				this.dispatchEvent(
					new ShowToastEvent({
						title: TOAST_SUCCESS_TITLE,
						message: TOAST_EXECUTION_LINES_CREATED.replace('{0}', allSuccess.length),
						variant: 'success'
					})
				);
			} else {
				this.dispatchEvent(
					new ShowToastEvent({
						title: TOAST_PARTIAL_SUCCESS_TITLE,
						message: TOAST_PARTIAL_CREATION.replace('{0}', allSuccess.length).replace('{1}', allErrors.length),
						variant: 'warning'
					})
				);
			}
			
			if (this.executionId) {
				this.currentStep = STAGE_GENERATE_AMENDMENTS;
				this.handleRefreshLines();
			}
		} catch (e) {
			this.errorRecords = items.map(it => ({ Id: it.contractId, message: this.translateMessage(e.body?.message || e.message) }));
			console.error('handleProcessRequest error:', e);
			this.dispatchEvent(
				new ShowToastEvent({
					title: TOAST_ERROR_PROCESSING,
					message: this.translateMessage(e?.body?.message || e?.message || TOAST_UNKNOWN_ERROR_PROCESSING),
					variant: 'error'
				})
			);
		}
	}

	renderedCallback() {
		if (!this.iframeLoaded) {
			this.iframeLoaded = true;
			this.boundHandleVfPlatformEventMessage = this.handleVfPlatformEventMessage.bind(this);
			window.addEventListener('message', this.boundHandleVfPlatformEventMessage);
		}
		if (this._styleInjected) {
			return;
		}
		this._styleInjected = true;

		const css = `
			c-progress-path .slds-path__nav .slds-is-complete .slds-path__stage {
				display: none !important;
				transform: none !important;
			}
			c-contract-date-update-selector .table-scroll .slds-scrollable_y {
				max-height: 50vh !important;
				overflow-y: auto !important;
			}
			c-contract-date-update-selector .table-scroll[data-has-selection="true"] .slds-scrollable_y {
				max-height: 30vh !important;
				overflow-y: auto !important;
			}
			c-contract-date-update-datatable td[data-label="Message"] lightning-base-formatted-text {
				text-wrap-mode: wrap;
			}
		`;

		const element = this.template.querySelector(".style-container");
		const style = document.createElement("style");
		style.textContent = css;
		element.appendChild(style);
	}
    
	disconnectedCallback() {
		if (this.boundHandleVfPlatformEventMessage) {
			window.removeEventListener('message', this.boundHandleVfPlatformEventMessage);
		}
	}

	handleVfPlatformEventMessage = (event) => {
		console.log('handleVfPlatformEventMessage called', event);
		if (!event || !event.data) {
			return;
		}
		if (event.data.type === 'cometd-event' && event.data.event === '/event/MassUpdateEvent__e') {
			const payload = event.data.payload && event.data.payload.payload;
			if (payload && payload.LineId__c) {
				let lineUpdated = false;

				this.allExecutionLines = (this.allExecutionLines || []).map(line => {
					if (line.Id === payload.LineId__c || line.lineRecord?.Id === payload.LineId__c) {
						lineUpdated = true;
						const checkEligibilityStatus = payload.CheckEligibilityStatus__c || line?.CheckEligibilityStatus__c;
						const currentFinishedSteps = line.FinishedSteps__c || '';
						let newFinishedSteps = currentFinishedSteps;
						
						if(line.Step__c === STAGE_CHECK_ELIGIBILITY_EN){
							if(payload.CheckEligibilityStatus__c === 'Eligible' && !currentFinishedSteps.includes(STAGE_CHECK_ELIGIBILITY_EN)){
								newFinishedSteps += (currentFinishedSteps ? ';' : '') + STAGE_CHECK_ELIGIBILITY_EN;
							}
						} else if(payload.Status__c?.toLowerCase().includes('success') && !currentFinishedSteps.includes(payload.Step__c)){
							newFinishedSteps += (currentFinishedSteps ? ';' : '') + payload.Step__c;
						}

						this.dispatchEvent(new ShowToastEvent({
							title: payload.Step__c ? `${payload.Step__c} ${COLUMN_STATUS}` : TOAST_EXECUTION_UPDATE,
							message: payload.Message__c || TOAST_STATUS_UPDATED.replace('{0}', payload.Status__c),
							variant: this.determineToastVariant(payload.Status__c)
						}));
						return this.mapLine({
							...line,
							Status__c: payload.Status__c,
							Step__c: payload.Step__c,
							Message__c: payload.Message__c,
							FinishedSteps__c: newFinishedSteps,
							CheckEligibilityStatus__c: checkEligibilityStatus
						});
					}
					return line;
				});

				// Force refresh to ensure UI updates including the path
				if (lineUpdated) {
					// Trigger re-render by updating a tracked property
					this.allExecutionLines = [...this.allExecutionLines];
				}
			}
		}
	}

	connectedCallback() {
		if (this.executionId) {
			this.loadExecutionContext();
		}
	}

	loadExecutionContext() {
		getExecutionLines({ executionId: this.executionId })
			.then(response => {
				// console.log('Execution lines loaded:', response);
				try {
					this.allExecutionLines = (response || []).map(row => this.mapLine(row));
					this.totalSelected = this.allExecutionLines.length;

					// Determine the next pending stage
					if(!this.refreshingLines){
						const nextStage = this.determineNextPendingStage();
						this.openStagePanel(nextStage);
					}
				} catch (e) {
					console.error(e);
					console.log("Error loading execution context:", e, JSON.stringify(e), JSON.stringify(e.body), [
						{ Id: this.executionId, message: e.body?.message || e.message }
					]);
				}
			})
			.catch(error => {
				console.error("Error loading execution lines:", error);
			});
	}

	determineNextPendingStage() {
		if (!this.allExecutionLines || this.allExecutionLines.length === 0) {
			return STAGE_GENERATE_AMENDMENTS;
		}

		const lines = this.allExecutionLines.map(l => l.lineRecord || l);

		// Check if all lines have CreatedQuote__c (amendments generated)
		const allHaveAmendments = lines.every(line => line.CreatedQuote__c);
		if (!allHaveAmendments) {
			return STAGE_GENERATE_AMENDMENTS;
		}

		// Check if all lines have Check Eligibility in FinishedSteps__c
		const allCheckedEligibility = lines.every(line =>
			line.FinishedSteps__c && line.FinishedSteps__c.includes(STAGE_CHECK_ELIGIBILITY_EN)
		);
		if (!allCheckedEligibility) {
			return STAGE_CHECK_ELIGIBILITY;
		}

		// Check if all eligible lines have Submit for Approval in FinishedSteps__c
		const eligibleLines = lines.filter(line => line.CheckEligibilityStatus__c !== STATUS_NOT_ELIGIBLE) || [];
		const allSubmittedForApproval = eligibleLines.every(line =>
			line.FinishedSteps__c && line.FinishedSteps__c.includes(STAGE_SUBMIT_FOR_APPROVAL_EN)
		);
		if (eligibleLines.length > 0 && !allSubmittedForApproval) {
			return STAGE_SUBMIT_FOR_APPROVAL;
		}

		// Check if all approved lines have Generate Contracts in FinishedSteps__c
		const approvedLines = eligibleLines.filter(line => {
			const amend = line.CreatedQuote__r;
			return amend && amend.ApprovalStatus__c === "Approved";
		});
		// If all stages are complete, stay on Generate Contracts
		return STAGE_GENERATE_CONTRACTS;
	}

	/**
	 * Translates error messages from backend (always in English) to user's language
	 * @param {String} message - The message to translate (may contain multiple messages separated by semicolons)
	 * @returns {String} - Translated message or original if no translation pattern matches
	 */
	translateMessage(message) {
		if (!message) {
			return message;
		}

		// Messages may be concatenated with semicolons (from addPicklistValueToMultiSelect)
		const messages = message.split(';').map(msg => msg.trim());
		const translatedMessages = messages.map(msg => {
			// Check for Final Price Per Tonne error - extract line name
			if (msg.includes('Final Price Per Tonne change on line')) {
				// Extract everything after "on line "
				const lineNameStart = msg.indexOf('on line ') + 8;
				const lineName = msg.substring(lineNameStart).trim();
				return ERROR_NOT_ELIGIBLE_FINAL_PRICE.replace('{0}', lineName);
			}

			// Check for Margin error - extract line name
			if (msg.includes('Margin change on line')) {
				// Extract everything after "on line "
				const lineNameStart = msg.indexOf('on line ') + 8;
				const lineName = msg.substring(lineNameStart).trim();
				return ERROR_NOT_ELIGIBLE_MARGIN.replace('{0}', lineName);
			}

			// Return original message if no pattern matches
			return msg;
		});

		return translatedMessages.join('; ');
	}

	mapLine(l) {
		if (l.lineRecord) {
			l = {...l.lineRecord, ...l};
		}
		let c = l.Contract__r;
		let q = c.PMC_CPQ_LatestQuote__r || null;
		let amend = l.CreatedQuote__r || null;
		let status = l.Status__c;
		let title = l.Step__c + ": " + l.Status__c;
		let statusIcon = "",
			statusIconVariant = "";
		let statusText;
		let textClass;
		let finishedForCurrentStep = this.currentStep && l.FinishedSteps__c?.includes(this.currentStepEN);
		console.log('finishedForCurrentStep', this.currentStep, l.Id, l.Step__c, l.Status__c, l.FinishedSteps__c, finishedForCurrentStep, l, JSON.stringify(l));
		let disabled = false;
		let showSpinner = false;
		const translatedMessage = this.translateMessage(l.Message__c);
		
		// Priority 1: Check Not Eligible status first (highest priority)
		if (l.CheckEligibilityStatus__c === STATUS_NOT_ELIGIBLE_EN) {
			statusText = STATUS_NOT_ELIGIBLE;
			textClass = "slds-text-color_error";
			status = "Error";
			disabled = !this.isCheckEligibilityStage;
			title = STATUS_NOT_ELIGIBLE + (translatedMessage ? " - " + translatedMessage : "");
		} else if (finishedForCurrentStep) {
			statusIcon = "utility:success";
			statusIconVariant = "success";
			status = "Success";
		} else if (status === "Error") {
			statusIcon = "utility:error";
			statusIconVariant = "error";
			textClass = "slds-text-color_error";
			title += " - " + translatedMessage;
		} else if (status === "In Progress") {
			showSpinner = true;
			statusIconVariant = "warning";
			if(l.Step__c == STAGE_SUBMIT_FOR_APPROVAL_EN){
				statusText = STATUS_PENDING_APPROVAL;
			} else {
				statusText = status;
			}
		} else if (status === "Queued") {
			showSpinner = true;
			statusIconVariant = "warning";
			statusText = status;
		} else if (l.Step__c != this.currentStepEN) {
			statusIcon = "utility:error";
			statusText = STATUS_PENDING + " " + l.Step__c;
		} else {
			statusIcon = "utility:clock";
			statusIconVariant = "warning";
            statusText = status;
		}
		// Prefer any per-line new values stored on the execution line (NewValues__c)
		let quoteStart = q?.PMC_CPQ_ContractStart__c;
		let quoteEnd = q?.PMC_CPQ_ContractEnd__c;
		if (l.NewValues__c) {
			try {
				const nv = JSON.parse(l.NewValues__c || '{}');
				if (nv.PMC_CPQ_ContractStart__c) quoteStart = nv.PMC_CPQ_ContractStart__c;
				if (nv.PMC_CPQ_ContractEnd__c) quoteEnd = nv.PMC_CPQ_ContractEnd__c;
			} catch (e) {
				// ignore parse errors and fall back to quote values
			}
		}
		return {
			lineRecord: l,
			editable: this.currentStep === STAGE_SELECT.toLowerCase() || l.FinishedSteps__c?.includes(STAGE_GENERATE_AMENDMENTS_EN) ? false : true,
			Id: l.Id,
			Message: translatedMessage,
			title,
			statusText,
			textClass: textClass || "slds-text-color_default",
			disabled,
			Status: status,
			Step__c: l.Step__c,
			CheckEligibilityStatus__c: l.CheckEligibilityStatus__c,
			amendContractStageName: amend?.PMC_CPQ_ContractStageName__c || l.Message__c,
			amendName: amend?.Name,
			amendContactEmail: amend?.PMC_CPQ_ContactEmail__c,
			CreatedQuoteUrl: l?.CreatedQuote__c ? "/" + l.CreatedQuote__c : null,
			FinishedSteps__c: l.FinishedSteps__c,
			PMC_CPQ_IntegrationStatus__c: amend?.PMC_CPQ_IntegrationStatus__c,
			PMC_CPQ_IntegrationMessage__c: amend?.PMC_CPQ_IntegrationMessage__c,
			integrationResult: amend?.PMC_CPQ_IntegrationStatus__c
				? amend?.PMC_CPQ_IntegrationStatus__c + ": " + amend?.PMC_CPQ_IntegrationMessage__c
				: null,
			statusIcon,
			showSpinner,
			statusIconVariant,
			ContractUrl: l.Contract__c ? "/" + l.Contract__c : null,
			ContractNumber: c?.ContractNumber,
			StartDate: c?.StartDate,
			EndDate: c?.EndDate,
			LatestQuoteUrl: q ? "/" + q.Id : null,
			QuoteName: q?.Name,
			QuoteType: q?.SBQQ__Type__c,
			LegacyQuoteId: q?.PMC_CPQ_LegacyQuoteID__c,
			AccountName: c?.Account?.Name,
			AccountUrl: c?.AccountId ? "/" + c.AccountId : null,
			QuoteSubType: q?.PMC_CPQ_QuoteRecordSubType__c,
			SalesOffice: q?.PMC_CPQ_SalesOffice__c,
			AccountManagerName: q?.PMC_CPQ_AccountManager__r?.Name,
			AccountManagerUrl: q?.PMC_CPQ_AccountManager__c ? "/" + q.PMC_CPQ_AccountManager__c : null,
			QuoteContractStage: q?.PMC_CPQ_ContractStageName__c,
			QuoteContractStart: quoteStart,
			QuoteContractEnd: quoteEnd,
			QuoteApprovalStatus: q?.ApprovalStatus__c,
			QuoteStatus: q?.SBQQ__Status__c,
			SapContractRef: q?.PMC_CPQ_SAPContractReference__c,
			AmendApprovalStatus: amend?.ApprovalStatus__c
		};
	}

	handleStageClick(event) {
		console.log('handleStageClick called', event);
		console.log("Event detail:", event.detail);
		if (event.detail && this.executionId) {
			console.log("Opening stage panel:", event.detail);
			this.openStagePanel(event.detail);
			this.handleRefreshLines();
		} else {
			console.log("Not opening stage panel. stage:", event.detail, "executionId:", this.executionId);
		}
	}

	handleExecutionCreated(event) {
		const { executionId } = event.detail || {};
		if (executionId) {
			this.executionId = executionId;
			this.openStagePanel(STAGE_GENERATE_AMENDMENTS);
			// Fetch latest lines for the new execution context
			this.loadExecutionContext();
		}
	}

	openStagePanel(stageName) {
		this.currentStep = stageName;
		this.allExecutionLines = (this.allExecutionLines || []).map(l => this.mapLine(l));
	}

	get currentStageLines() {
		return this.allExecutionLines.filter(l => l.Step__c === this.currentStepEN);
	}

	get selectedRowsForStage() {
		if (this.isGenerateAmendmentsStage) {
			return this.selectedGenerateAmendments;
		}
		if (this.isCheckEligibilityStage) {
			return this.selectedCheckEligibility;
		}
		if (this.isSubmitForApprovalStage) {
			return this.selectedSubmitForApproval;
		}
		if (this.isGenerateContractsStage) {
			return this.selectedGenerateContracts;
		}
		return [];
	}

	refreshingLines = false;
	handleRefreshLines() {
		if (this.executionId) {
			this.refreshingLines = true;
			this.loadExecutionContext();
		}
	}

	async handleCheckEligibility() {
		if (!this.selectedCheckEligibility || this.selectedCheckEligibility.length === 0) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: TOAST_ERROR_TITLE,
					message: TOAST_NO_ROWS_ELIGIBILITY,
					variant: "error"
				})
			);
			return;
		}
		const batchSize = 10;
		const ids = this.selectedCheckEligibility.map(l => l.Id);
		let errors = [];
		for (let i = 0; i < ids.length; i += batchSize) {
			const batchIds = ids.slice(i, i + batchSize);
			try {
				this.setStatusByIds(STAGE_CHECK_ELIGIBILITY, TOAST_SENDING, batchIds);
				await checkEligibility({ executionId: this.executionId, executionLineIds: batchIds });
			} catch (e) {
				this.setStatusByIds(STAGE_CHECK_ELIGIBILITY, TOAST_ERROR_TITLE, batchIds);
				errors.push(...batchIds);
				this.dispatchEvent(
					new ShowToastEvent({
						title: TOAST_ERROR_TITLE,
						message: e.body && e.body.message ? e.body.message : TOAST_ELIGIBILITY_FAILED,
						variant: "error"
					})
				);
			}
		}
		if (errors.length === 0) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: TOAST_SUCCESS_TITLE,
					message: TOAST_ELIGIBILITY_ENQUEUED,
					variant: "success"
				})
			);
		}
	}

	setStatusByIds(step, status, ids) {
		if(!status || !step || !ids || ids.length === 0){
			return;
		}
		this.allExecutionLines = (this.allExecutionLines || []).map(l => {
			if (ids.includes(l.Id)) {
				return this.mapLine({
					...l,
					Status__c: status,
					Step__c: step,
					Message__c: null
				});
			}
			return l;
		});
	}

	handleRowAction(event) {
		const actionName = event.detail.action ? event.detail.action.name : undefined;
		const row = event.detail.row;
		if (actionName === "openRecord" && row && row.Id) {
			try {
				const recUrl = "/" + row.Id;
				window.open(recUrl, "_blank");
			} catch (e) {
				// ignore
			}
		}
	}

	async handleSubmitForApproval() {
		if (!this.selectedSubmitForApproval || this.selectedSubmitForApproval.length === 0) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: TOAST_ERROR_TITLE,
					message: TOAST_NO_ROWS_APPROVAL,
					variant: "error"
				})
			);
			return;
		}
		const batchSize = 10;
		const ids = this.selectedSubmitForApproval.map(l => l.Id);
		let errors = [];
		for (let i = 0; i < ids.length; i += batchSize) {
			const batchIds = ids.slice(i, i + batchSize);
			try {
				// Imperative Apex call
				this.setStatusByIds(STAGE_SUBMIT_FOR_APPROVAL, TOAST_SENDING, batchIds);
				await submitForApproval({ executionId: this.executionId, executionLineIds: batchIds });
			} catch (e) {
				this.setStatusByIds(STAGE_SUBMIT_FOR_APPROVAL, TOAST_ERROR_TITLE, batchIds);
				errors.push(...batchIds);
				this.dispatchEvent(
					new ShowToastEvent({
						title: TOAST_ERROR_TITLE,
						message: e.body && e.body.message ? e.body.message : TOAST_APPROVAL_FAILED,
						variant: "error"
					})
				);
			}
		}
		if (errors.length === 0) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: TOAST_SUCCESS_TITLE,
					message: TOAST_APPROVAL_COMPLETED,
					variant: "success"
				})
			);
		}
		this.handleRefreshLines();
	}

	async handleGenerateContracts() {
		if (!this.selectedGenerateContracts || this.selectedGenerateContracts.length === 0) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: TOAST_ERROR_TITLE,
					message: TOAST_NO_ROWS_CONTRACT,
					variant: "error"
				})
			);
			return;
		}
		const batchSize = 10;
		const ids = this.selectedGenerateContracts.map(l => l.Id);
		console.log(ids, this.selectedGenerateContracts, Object.values(this.selectedGenerateContracts));
		
		let errors = [];
		for (let i = 0; i < ids.length; i += batchSize) {
			const batchIds = ids.slice(i, i + batchSize);
			try {
				const params = { executionId: this.executionId, executionLineIds: batchIds };
				console.log(`handleGenerateContracts ${i + 1} - ${i + batchSize} > params `, JSON.stringify({...params}), batchIds);
				
				this.setStatusByIds(STAGE_GENERATE_CONTRACTS, TOAST_SENDING, batchIds);
				await generateContracts(params);
			} catch (e) {
				this.setStatusByIds(STAGE_GENERATE_CONTRACTS, TOAST_ERROR_TITLE, batchIds);
				errors.push(...batchIds);
				this.dispatchEvent(
					new ShowToastEvent({
						title: TOAST_ERROR_TITLE,
						message: e.body && e.body.message ? e.body.message : TOAST_CONTRACT_FAILED,
						variant: "error"
					})
				);
			}
		}
		if (errors.length === 0) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: TOAST_INFO_TITLE,
					message: TOAST_CONTRACT_INITIATED,
					variant: "info"
				})
			);
		}
	}

	determineToastVariant(status) {
		const normalized = status?.toLowerCase() || '';
		if (normalized.includes('error')) {
			return 'error';
		}
		if (normalized.includes('success')) {
			return 'success';
		}
		return 'info';
	}
}