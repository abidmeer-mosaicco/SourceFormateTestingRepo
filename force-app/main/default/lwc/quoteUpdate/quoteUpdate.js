import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getExecutionLines from "@salesforce/apex/QuoteUpdateController.getExecutionLines";
import updateQuotes from "@salesforce/apex/QuoteUpdateController.updateQuotes";
import salesOfficeValues from "@salesforce/apex/QuoteUpdateController.salesOfficeValues";
import accountManagers from "@salesforce/apex/QuoteUpdateController.accountManagers";

import STAGE_SELECT from "@salesforce/label/c.MassUpdate_ContractUpdate_Stage_Select";
import STAGE_UPDATE_QUOTES from "@salesforce/label/c.MassUpdate_ContractUpdate_Stage_UpdateQuotes";
import COLUMN_CONTRACT_NUMBER from "@salesforce/label/c.MassUpdate_ContractUpdate_Column_ContractNumber";
import COLUMN_LATEST_QUOTE from "@salesforce/label/c.MassUpdate_ContractUpdate_Column_LatestQuote";
import COLUMN_TYPE from "@salesforce/label/c.MassUpdate_ContractUpdate_Column_Type";
import COLUMN_SAP_CONTRACT_REF from "@salesforce/label/c.MassUpdate_ContractUpdate_Column_SAPContractRef";
import COLUMN_ACCOUNT from "@salesforce/label/c.MassUpdate_ContractUpdate_Column_Account";
import COLUMN_BUSINESS_TYPE from "@salesforce/label/c.MassUpdate_ContractUpdate_Column_BusinessType";
import COLUMN_SALES_AREA from "@salesforce/label/c.MassUpdate_ContractUpdate_Column_SalesArea";
import COLUMN_SALES_OFFICE from "@salesforce/label/c.MassUpdate_ContractUpdate_Column_SalesOffice";
import COLUMN_ACCOUNT_MANAGER from "@salesforce/label/c.MassUpdate_ContractUpdate_Column_AccountManager";
import COLUMN_SALES_OFFICE_CURRENT from "@salesforce/label/c.MassUpdate_ContractUpdate_Column_SalesOfficeCurrent";
import COLUMN_ACCOUNT_MANAGER_CURRENT from "@salesforce/label/c.MassUpdate_ContractUpdate_Column_AccountManagerCurrent";
import COLUMN_QUOTE_STATUS from "@salesforce/label/c.MassUpdate_ContractUpdate_Column_QuoteStatus";
import COLUMN_STATUS from "@salesforce/label/c.MassUpdate_ContractUpdate_Column_Status";
import COLUMN_MESSAGE from "@salesforce/label/c.MassUpdate_ContractUpdate_Column_Message";
import TOAST_ERROR_TITLE from "@salesforce/label/c.MassUpdate_ContractUpdate_Toast_Error_Title";
import TOAST_NO_ROWS_CONTRACT_UPDATE from "@salesforce/label/c.MassUpdate_ContractUpdate_Toast_NoRowsContractUpdate";
import TOAST_CONTRACT_UPDATE_FAILED from "@salesforce/label/c.MassUpdate_ContractUpdate_Toast_UpdateContractsFailed";
import TOAST_EXECUTION_UPDATE from "@salesforce/label/c.MassUpdate_ContractUpdate_Toast_ExecutionUpdate";
import TOAST_STATUS_UPDATED from "@salesforce/label/c.MassUpdate_ContractUpdate_Toast_StatusUpdated";
import PICKLIST_NO_SAP_ID from "@salesforce/label/c.MassUpdate_ContractUpdate_Picklist_NoSAPID";
import BUTTON_REFRESH from "@salesforce/label/c.MassUpdate_Common_Button_Refresh";
import STATUS_QUEUED from "@salesforce/label/c.MassUpdate_ContractUpdate_Status_Queued";
import STATUS_PENDING from "@salesforce/label/c.MassUpdate_ContractUpdate_Status_Pending";
import STATUS_IN_PROGRESS from "@salesforce/label/c.MassUpdate_ContractUpdate_Status_InProgress";
import STATUS_SUCCESS from "@salesforce/label/c.MassUpdate_ContractUpdate_Status_Success";
import STATUS_ERROR from "@salesforce/label/c.MassUpdate_ContractUpdate_Status_Error";
import STATUS_PARTIAL_SUCCESS from "@salesforce/label/c.MassUpdate_ContractUpdate_Status_PartialSuccess";

// English stage values for backend comparisons (FinishedSteps__c is stored in English)
const STAGE_SELECT_EN = "Select";
const STAGE_UPDATE_QUOTES_EN = "Update Quotes";

/**
 * Quote Update component - main component handling the mass update of quotes based 
 * on contract changes of sales office and account manager.
 * 
 * @author Sergiu Umlauf
 * @storynumber GCPM-2771
 */
export default class QuoteUpdate extends LightningElement {
    _styleInjected = false;
    iframeLoaded = false;
    boundHandleVfPlatformEventMessage = null;
    _executionId = null;

    // Map translated labels to English backend values for comparisons
    get stageMap() {
        return {
            [STAGE_SELECT]: STAGE_SELECT_EN,
            [STAGE_UPDATE_QUOTES]: STAGE_UPDATE_QUOTES_EN
        };
    }

    get currentStepEN() {
        return this.stageMap[this.currentStep] || this.currentStep;
    }

    get labels() {
        return {
            STAGE_UPDATE_QUOTES,
            BUTTON_REFRESH
        };
    }

    @api
    get executionId() {
        return this._executionId;
    }
    set executionId(value) {
        this._executionId = value;
    }
    @track currentStep = STAGE_SELECT;
    @track selectedRecords = [];
    @track totalSelected = 0;
    @track allExecutionLines = [];
    @track selectedUpdateQuotes = [];
    @track salesOfficeOptions = [];
    @track accountManagerOptions = [];
    accountManagersList = [];

    get stages() {
        return [
            this.buildStage(STAGE_SELECT, this.currentStep === STAGE_SELECT, this.currentStep !== STAGE_SELECT && this.totalSelected > 0),
            this.buildStage(
                STAGE_UPDATE_QUOTES,
                this.currentStep === STAGE_UPDATE_QUOTES,
                !this.allExecutionLines.some((line) => !line.FinishedSteps__c || !line.FinishedSteps__c.includes(STAGE_UPDATE_QUOTES_EN))
            )
        ];
    }

    get isUpdateQuotesStage() {
        return this.currentStep === STAGE_UPDATE_QUOTES;
    }

    get isSelectStage() {
        return this.currentStep === STAGE_SELECT;
    }

    get totalSelectedLabel() {
        return this.totalSelected ? `${this.totalSelected}` : "0";
    }

    get columns() {
        const cols = [
            {
                label: COLUMN_CONTRACT_NUMBER,
                fieldName: "ContractUrl",
                type: "url",
                typeAttributes: {
                    label: { fieldName: "ContractNumber" },
                    target: "_blank"
                }
            },
            {
                label: COLUMN_LATEST_QUOTE,
                fieldName: "LatestQuoteUrl",
                type: "url",
                typeAttributes: { label: { fieldName: "QuoteName" }, target: "_blank" }
            },
            { label: COLUMN_TYPE, fieldName: "QuoteType", initialWidth: 120 },
            { label: COLUMN_SAP_CONTRACT_REF, fieldName: "SapContractRef", initialWidth: 160 },
            {
                label: COLUMN_ACCOUNT,
                fieldName: "AccountUrl",
                type: "url",
                typeAttributes: {
                    label: { fieldName: "AccountName" },
                    target: "_blank"
                }
            },
            { label: COLUMN_BUSINESS_TYPE, fieldName: "QuoteSubType" },
            this.currentStep === "Select" && {
                label: "Contract Document Status",
                fieldName: "QuoteContractStage"
            },
            { label: COLUMN_SALES_AREA, fieldName: "SalesArea" },
            this.currentStep === STAGE_SELECT && {
                label: COLUMN_SALES_OFFICE,
                fieldName: "SalesOffice",
                initialWidth: 150,
                type: "comboboxColumn",
                editable: true,
                typeAttributes: {
                    options: this.salesOfficeOptions || [],
                    value: { fieldName: "SalesOffice" },
                    label: { fieldName: "SalesOffice" },
                    context: { fieldName: "SalesOffice" }
                }
            },
            this.currentStep === STAGE_SELECT && {
                label: COLUMN_ACCOUNT_MANAGER,
                fieldName: "AccountManagerName",
                initialWidth: 150,
                type: "comboboxColumn",
                editable: true,
                typeAttributes: {
                    options: this.accountManagerOptions || []
                }
            },
            this.currentStep === STAGE_UPDATE_QUOTES && {
                label: COLUMN_SALES_OFFICE_CURRENT,
                fieldName: "OldSalesOffice",
                initialWidth: 150,
                cellAttributes: { style: { fieldName: "OldSalesOfficeCellStyle" } }
            },
            this.currentStep === STAGE_UPDATE_QUOTES && {
                label: COLUMN_SALES_OFFICE,
                fieldName: "NewSalesOffice",
                initialWidth: 150
            },
            this.currentStep === STAGE_UPDATE_QUOTES && {
                label: COLUMN_ACCOUNT_MANAGER_CURRENT,
                fieldName: "OldAccountManagerName",
                initialWidth: 150,
                cellAttributes: { style: { fieldName: "OldAccountManagerNameCellStyle" } }
            },
            this.currentStep === STAGE_UPDATE_QUOTES && {
                label: COLUMN_ACCOUNT_MANAGER,
                fieldName: "NewAccountManagerName",
                initialWidth: 150
            },
            this.currentStep === STAGE_SELECT && {
                label: COLUMN_QUOTE_STATUS,
                fieldName: "QuoteStatus"
            },
            this.currentStep !== STAGE_SELECT && {
                label: COLUMN_STATUS,
                fieldName: "Status",
                initialWidth: 160,
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
            this.currentStep !== STAGE_SELECT && {
                label: COLUMN_MESSAGE,
                fieldName: "Message",
                initialWidth: 160,
            },
            this.currentStep !== STAGE_SELECT && {
                type: "action",
                initialWidth: 48,
                cellAttributes: { alignment: "center" },
                typeAttributes: {
                    rowActions: [{ label: "Details", name: "openRecord" }]
                }
            }
        ].filter((col) => !!col);
        return cols;
    }

    get orderedLines() {
        const stepOrder = {
            [STAGE_SELECT]: 1,
            [STAGE_UPDATE_QUOTES]: 2
        };
        let res = (this.allExecutionLines || []).slice().sort((a, b) => {
            const stepA = stepOrder[a.Step__c] || 99;
            const stepB = stepOrder[b.Step__c] || 99;
            if (stepA !== stepB) {
                return stepA - stepB;
            }
            return a.ContractNumber.localeCompare(b.ContractNumber);
        });
        return res;
    }

    buildStage(label, isCurrent, isComplete) {
        let countLabel = "0";
        const labelEN = this.stageMap[label] || label;
        if (!this.allExecutionLines) {
            countLabel = "0/" + this.allExecutionLines.length.toString();
        } else {
            countLabel =
                (label === STAGE_SELECT && this.allExecutionLines.length) ||
                this.allExecutionLines.filter((l) => l.FinishedSteps__c?.includes(labelEN)).length ||
                0;
            if (countLabel < this.allExecutionLines.length) {
                countLabel = `${countLabel}/${this.allExecutionLines.length}`;
            } else {
                countLabel = this.allExecutionLines.length.toString();
            }
        }
        return { label, countLabel, isCurrent, isComplete };
    }

    handleRecordsSelected(event) {
        this.selectedRecords = [...this.selectedRecords, ...(event.detail.records || [])].filter((record) => record != null);
        this.totalSelected = this.selectedRecords.length;
    }

    get selectedRowIds() {
        return this.selectedRowsForStage.map((row) => row.Id);
    }

    handleRowSelection(event) {
        let selectedRows = event.detail.selectedRows.filter((row) => {
            let filterResult = !row.FinishedSteps__c?.split(";").includes(this.currentStep);
            return filterResult && !row.disabled && row.Step__c === this.currentStep;
        });
        this.selectedUpdateQuotes = selectedRows;
        this.allExecutionLines = (this.allExecutionLines || []).map((l) => this.mapLine(l));
    }

    renderedCallback() {
        if (!this.iframeLoaded) {
            this.iframeLoaded = true;
            this.boundHandleVfPlatformEventMessage = this.handleVfPlatformEventMessage.bind(this);
            window.addEventListener("message", this.boundHandleVfPlatformEventMessage);
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
			c-quote-update-selector .table-scroll .slds-scrollable_y {
				max-height: 50vh !important;
				overflow-y: auto !important;
			}
			c-quote-update-selector .table-scroll[data-has-selection="true"] .slds-scrollable_y {
				max-height: 30vh !important;
				overflow-y: auto !important;
			}
			c-quote-update-datatable td[data-label="Message"] lightning-base-formatted-text {
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
            window.removeEventListener("message", this.boundHandleVfPlatformEventMessage);
        }
    }

    handleVfPlatformEventMessage = (event) => {
        if (!event || !event.data) {
            return;
        }
        if (event.data.type === "cometd-event" && event.data.event === "/event/MassUpdateEvent__e") {
            console.log("MassUpdateEvent__e received", event);
            const payload = event.data.payload && event.data.payload.payload;
            // console.log('payload:::', payload);
            if (payload && payload.LineId__c) {
                let lineUpdated = false;
                this.allExecutionLines = (this.allExecutionLines || []).map((line) => {
                    if (line.Id === payload.LineId__c || line.lineRecord?.Id === payload.LineId__c) {
                        lineUpdated = true;
                        const currentFinishedSteps = line.FinishedSteps__c || "";
                        let newFinishedSteps = currentFinishedSteps;

                        if (payload.Status__c?.toLowerCase().includes("success") && !currentFinishedSteps.includes(payload.Step__c)) {
                            newFinishedSteps += (currentFinishedSteps ? ";" : "") + payload.Step__c;
                        }
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: payload.Step__c ? `${payload.Step__c} ${COLUMN_STATUS}` : TOAST_EXECUTION_UPDATE,
                                message: payload.Message__c || TOAST_STATUS_UPDATED.replace("{0}", payload.Status__c),
                                variant: this.determineToastVariant(payload.Status__c)
                            })
                        );
                        return this.mapLine({
                            ...line,
                            Status__c: payload.Status__c,
                            Step__c: payload.Step__c,
                            Message__c: payload.Message__c,
                            FinishedSteps__c: newFinishedSteps
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
    };

    connectedCallback() {
        if (this._executionId) {
            this.loadExecutionContext();
        }
        if (!this.salesOfficeOptions || this.salesOfficeOptions.length === 0) {
            this.loadSalesOfficeValues();
        }
        if (!this.accountManagerOptions || this.accountManagerOptions.length === 0) {
            this.loadAccountManagerValues();
        }
    }

    loadExecutionContext() {
        getExecutionLines({ executionId: this._executionId })
            .then((response) => {
                // console.log("Execution lines loaded:", JSON.stringify(response));
                try {
                    this.allExecutionLines = (response || []).map((row) => this.mapLine(row));
                    this.totalSelected = this.allExecutionLines.length;
                    if (!this.refreshingLines) {
                        this.openStagePanel(this.currentStep === STAGE_SELECT ? STAGE_UPDATE_QUOTES : this.currentStep);
                    }
                } catch (e) {
                    console.error(e);
                    console.log(
                        "Error loading execution context:",
                        e,
                        JSON.stringify(e),
                        JSON.stringify(e.body),
                        JSON.stringify([{ Id: this._executionId, message: e.body?.message || e.message }])
                    );
                }
            })
            .catch((error) => {
                console.error("Error loading execution lines:", error);
            });
    }

    mapLine(l) {
        if (l.lineRecord) {
            l = { ...l.lineRecord, ...l };
        }
        let c = l.Contract__r;
        let q = c.PMC_CPQ_LatestQuote__r || null;
        let newValues;
        try {
            newValues = JSON.parse(l.NewValues__c);
        } catch (e) {
            console.error("Error parsing NewValues__c: ", JSON.stringify(e));
        }
        let newAccountManagerName = "";
        if (newValues && newValues.PMC_CPQ_AccountManager__c) {
            const newAccountManager = this.getAccountManager(newValues.PMC_CPQ_AccountManager__c);
            newAccountManagerName = newAccountManager?.Name || "";
        }
        let newSalesOffice = newValues?.PMC_CPQ_SalesOffice__c || q?.PMC_CPQ_SalesOffice__c;
        let oldValues;
        try {
            oldValues = JSON.parse(l.OldValues__c);
        } catch (e) {
            console.error("Error parsing OldValues__c: ", JSON.stringify(e));
        }
        let oldAccountManagerName = "";
        if (oldValues && oldValues.PMC_CPQ_AccountManager__c) {
            const oldAccountManager = this.getAccountManager(oldValues.PMC_CPQ_AccountManager__c);
            oldAccountManagerName = oldAccountManager?.Name || q?.PMC_CPQ_AccountManager__r?.Name;
        }
        let oldSalesOffice = oldValues?.PMC_CPQ_SalesOffice__c || q?.PMC_CPQ_SalesOffice__c;
        let amend = l.CreatedQuote__r || null;
        let status = l.Status__c;
        let title = l.Step__c + ": " + l.Status__c;
        let statusIcon = "";
        let statusIconVariant = "";
        let statusText;
        let textClass;
        let finishedForCurrentStep = this.currentStep && l.FinishedSteps__c?.includes(this.currentStepEN);
        let disabled = false;
        let showSpinner = false;
        /*if (l.Step__c !== this.currentStep) {
            statusIcon = "utility:clock";
            statusText = STATUS_PENDING + " " + l.Step__c;
        } else */
        if (finishedForCurrentStep || status === "Success") {
            statusIcon = "utility:success";
            statusIconVariant = "success";
            status = "Success";
            statusText = STATUS_SUCCESS;
            textClass = "slds-col slds-grid_vertical-align-center";
        } else if (status === "Queued") {
            statusIcon = "utility:clock";
            statusIconVariant = "info";
            statusText = STATUS_QUEUED;
            textClass = "slds-col slds-grid_vertical-align-center";
        } else if (status === "Error") {
            statusIcon = "utility:error";
            statusIconVariant = "error";
            statusText = STATUS_ERROR;
            textClass = "slds-col slds-grid_vertical-align-center slds-text-color_error";
        } else if (status === "In Progress") {
            showSpinner = true;
            statusIconVariant = "warning";
            statusText = STATUS_IN_PROGRESS;
            textClass = "slds-col slds-grid_vertical-align-center";
        } else if (status === "Partial Success") {
            statusIcon = "utility:success";
            statusIconVariant = "warning";
            statusText = STATUS_PARTIAL_SUCCESS;
            textClass = "slds-col slds-grid_vertical-align-center";
        } else {
            statusIcon = "utility:clock";
            statusIconVariant = "warning";
            statusText = STATUS_PENDING;
            textClass = "slds-col slds-grid_vertical-align-center";
        }
        return {
            lineRecord: l,
            Id: l.Id,
            title,
            statusText,
            textClass: textClass || "slds-text-color_default",
            disabled,
            Status: status,
            Step__c: l.Step__c,
            CheckEligibilityStatus__c: l.CheckEligibilityStatus__c,
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
            AccountManagerId: q?.PMC_CPQ_AccountManager__c,
            AccountManagerName: q?.PMC_CPQ_AccountManager__r?.Name,
            AccountManagerUrl: q?.PMC_CPQ_AccountManager__c ? "/" + q.PMC_CPQ_AccountManager__c : null,
            QuoteContractStage: q?.PMC_CPQ_ContractStageName__c,
            QuoteContractStart: q?.PMC_CPQ_ContractStart__c,
            QuoteContractEnd: q?.PMC_CPQ_ContractEnd__c,
            QuoteApprovalStatus: q?.ApprovalStatus__c,
            QuoteStatus: q?.SBQQ__Status__c,
            SapContractRef: q?.PMC_CPQ_SAPContractReference__c,
            AmendApprovalStatus: amend?.ApprovalStatus__c,
            OldSalesOffice: oldSalesOffice || q?.PMC_CPQ_SalesOffice__c,
            NewSalesOffice: newSalesOffice,
            OldSalesOfficeCellStyle: newSalesOffice !== oldSalesOffice ? "color: gray; text-decoration: line-through" : "",
            OldAccountManagerName: oldAccountManagerName || q?.PMC_CPQ_AccountManager__r?.Name,
            NewAccountManagerName: newAccountManagerName,
            OldAccountManagerNameCellStyle: newAccountManagerName !== oldAccountManagerName ? "color: gray; text-decoration: line-through" : "",
            SalesArea: q?.PMC_CPQ_SalesAreaCombination__c,
            Message: l.Message__c
        };
    }

    getAccountManager(accountManagerId) {
        return this.accountManagersList.find((am) => am.Id === accountManagerId);
    }

    handleStageClick(event) {
        if (event.detail && this._executionId) {
            this.openStagePanel(event.detail);
        } else {
            console.log("Not opening stage panel. stage:", event.detail, "executionId:", this.executionId);
        }
    }

    handleExecutionCreated(event) {
        const { executionId } = event.detail || {};
        if (executionId) {
            this._executionId = executionId;
            this.openStagePanel(STAGE_UPDATE_QUOTES);
            // Fetch latest lines for the new execution context
            this.loadExecutionContext();
        }
    }

    openStagePanel(stageName) {
        this.currentStep = stageName;
        this.allExecutionLines = (this.allExecutionLines || []).map((l) => this.mapLine(l));
    }

    get currentStageLines() {
        return this.allExecutionLines.filter((l) => l.Step__c === this.currentStepEN);
    }

    get selectedRowsForStage() {
        if (this.isUpdateQuotesStage) {
            return this.selectedUpdateQuotes;
        }
        return [];
    }

    refreshingLines = false;
    handleRefreshLines() {
        if (this._executionId) {
            this.refreshingLines = true;
            this.loadExecutionContext();
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action ? event.detail.action.name : undefined;
        const row = event.detail.row;
        if (actionName === "openRecord" && row && row.Id) {
            try {
                const recUrl = "/" + row.Id;
                window.open(recUrl, "_blank");
            } catch {
                // ignore
            }
        }
    }

    async handleUpdateQuotes() {
        if (!this.selectedUpdateQuotes || this.selectedUpdateQuotes.length === 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: TOAST_ERROR_TITLE,
                    message: TOAST_NO_ROWS_CONTRACT_UPDATE,
                    variant: "error"
                })
            );
            return;
        }
        const batchSize = 10;
        const ids = this.selectedUpdateQuotes.map((l) => l.lineRecord?.CreatedQuote__r?.Id).filter((id) => !!id);

        let errors = [];
        for (let i = 0; i < ids.length; i += batchSize) {
            const batchIds = ids.slice(i, i + batchSize);
            try {
                // Imperative Apex call
                await updateQuotes({ executionId: this._executionId, executionLineIds: batchIds });
            } catch (e) {
                errors.push(...batchIds);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: TOAST_ERROR_TITLE,
                        message: e.body && e.body.message ? e.body.message : TOAST_CONTRACT_UPDATE_FAILED,
                        variant: "error"
                    })
                );
            }
        }
        // if (errors.length === 0) {
        //     this.dispatchEvent(
        //         new ShowToastEvent({
        //             title: TOAST_SUCCESS_TITLE,
        //             message: TOAST_CONTRACT_UPDATE_COMPLETED,
        //             variant: "success"
        //         })
        //     );
        // }
        this.handleRefreshLines();
    }

    async loadSalesOfficeValues() {
        try {
            let salesOffices = await salesOfficeValues();
            this.salesOfficeOptions = [{ label: "", value: "" }, ...salesOffices];
        } catch (err) {
            console.error("Error fetching Sales Office values:", JSON.stringify(err));
        }
    }

    async loadAccountManagerValues() {
        try {
            this.accountManagersList = await accountManagers();
            let acctMngrs = this.accountManagersList.map((rec) => {
                return {
                    label: rec.PMC_CPQ_SAPExternalUserId__c ? rec.Name : `${rec.Name} - ${PICKLIST_NO_SAP_ID}`,
                    value: rec.Id
                };
            });
            this.accountManagerOptions = [{ label: "", value: "" }, ...acctMngrs];
        } catch (err) {
            console.error("Error fetching Account Manager values:", JSON.stringify(err));
        }
    }

    get accountManagersAvailable() {
        return this.accountManagersList;
    }

    determineToastVariant(status) {
        const normalized = status?.toLowerCase() || "";
        if (normalized.includes("error")) {
            return "error";
        }
        if (normalized.includes("success")) {
            return "success";
        }
        return "info";
    }
}