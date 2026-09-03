import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getRecentExecutions from "@salesforce/apex/ContractDateUpdateController.getRecentExecutions";
import getExecution from "@salesforce/apex/ContractDateUpdateController.getExecution";
import hasContractDatesUpdatePermission from "@salesforce/customPermission/ContractDatesMassUpdate";
import hasSalesOfficeAccountManagerUpdatePermission from "@salesforce/customPermission/SalesOfficeAccountManagerMassUpdate";

// Import Custom Labels
import LABEL_BUTTON_BACK from "@salesforce/label/c.MassUpdate_Launcher_Button_Back";
import LABEL_LAUNCHER_ALT from "@salesforce/label/c.MassUpdate_Launcher_Alt_MosaicMassUpdate";
import LABEL_LAUNCHER_TITLE from "@salesforce/label/c.MassUpdate_Launcher_Title_MosaicMassUpdate";
import LABEL_LAUNCHER_DESC from "@salesforce/label/c.MassUpdate_Launcher_Text_SelectFeature";
import LABEL_CARD_RECENT_EXECUTIONS from "@salesforce/label/c.MassUpdate_Launcher_Card_RecentExecutions";
import LABEL_FEATURE_UPDATE_CONTRACT_DATES from "@salesforce/label/c.MassUpdate_Launcher_Feature_UpdateContractDates";
import LABEL_FEATURE_UPDATE_CONTRACT_DATES_DESC from "@salesforce/label/c.MassUpdate_Launcher_Feature_UpdateContractDates_Desc";
import LABEL_FEATURE_UPDATE_SALES_OFFICE from "@salesforce/label/c.MassUpdate_Launcher_Feature_UpdateSalesOffice";
import LABEL_FEATURE_UPDATE_SALES_OFFICE_DESC from "@salesforce/label/c.MassUpdate_Launcher_Feature_UpdateSalesOffice_Desc";
import LABEL_UNAUTHORIZED_TITLE from "@salesforce/label/c.MassUpdate_Launcher_Toast_Unauthorized_Title";
import LABEL_UNAUTHORIZED_MSG from "@salesforce/label/c.MassUpdate_Launcher_Toast_Unauthorized_Msg";
import LABEL_COLUMN_RUN_NUMBER from "@salesforce/label/c.MassUpdate_Launcher_Column_RunNumber";
import LABEL_COLUMN_FEATURE from "@salesforce/label/c.MassUpdate_Launcher_Column_Feature";
import LABEL_COLUMN_STATUS from "@salesforce/label/c.MassUpdate_Launcher_Column_Status";
import LABEL_COLUMN_CREATED from "@salesforce/label/c.MassUpdate_Launcher_Column_Created";
import LABEL_COLUMN_USER from "@salesforce/label/c.MassUpdate_Launcher_Column_User";
import LABEL_ACTION_DETAILS from "@salesforce/label/c.MassUpdate_Launcher_Action_Details";

export default class MassUpdateLauncher extends LightningElement {
    @track activeFeature;
    executions = [];
    selectedExecution;
    @track executionId; // current execution context

    get labels() {
        return {
            buttonBack: LABEL_BUTTON_BACK,
            title: LABEL_LAUNCHER_TITLE,
            description: LABEL_LAUNCHER_DESC,
            iconAlt: LABEL_LAUNCHER_ALT,
            cardRecentExecutions: LABEL_CARD_RECENT_EXECUTIONS
        };
    }

    get features() {
        const result = [
            hasContractDatesUpdatePermission && {
                name: "contractDateUpdate",
                label: LABEL_FEATURE_UPDATE_CONTRACT_DATES,
                icon: "standard:time_period",
                description: LABEL_FEATURE_UPDATE_CONTRACT_DATES_DESC,
                api: "ContractDateUpdate"
            },
            hasSalesOfficeAccountManagerUpdatePermission && {
                name: "quoteUpdate",
                label: LABEL_FEATURE_UPDATE_SALES_OFFICE,
                icon: "standard:person_account",
                description: LABEL_FEATURE_UPDATE_SALES_OFFICE_DESC,
                api: "QuoteUpdate"
            }
        ].filter((feature) => !!feature);
        return result;
    }

    get canAccessContractDatesUpdate() {
        return hasContractDatesUpdatePermission;
    }

    get canAccessQuoteUpdate() {
        return hasSalesOfficeAccountManagerUpdatePermission;
    }

    // get canAccessContractDatesUpdate() {
    //     console.log("hasContractDatesUpdatePermission", hasContractDatesUpdatePermission);
    //     if (!hasContractDatesUpdatePermission) {
    //         this.dispatchEvent(
    //             new ShowToastEvent({
    //                 title: "Unauthorized",
    //                 message: "You do not have permission to perform Contract Dates Mass Update.",
    //                 variant: "error",
    //                 mode: "sticky"
    //             })
    //         );
    //         return false;
    //     }
    //     return true;
    // }

    // get canAccessQuoteUpdate() {
    //     console.log("hasSalesOfficeAccountManagerUpdatePermission", hasSalesOfficeAccountManagerUpdatePermission);
    //     if (!hasSalesOfficeAccountManagerUpdatePermission) {
    //         this.dispatchEvent(
    //             new ShowToastEvent({
    //                 title: "Unauthorized",
    //                 message: "You do not have permission to perform Sales Office & Account Manager Mass Update.",
    //                 variant: "error",
    //                 mode: "sticky"
    //             })
    //         );
    //         return false;
    //     }
    //     return true;
    // }

    // Use c__ prefixed param so Lightning preserves it after load; open in same tab.
    executionColumns = [
        {
            label: LABEL_COLUMN_RUN_NUMBER,
            type: "button",
            typeAttributes: { label: { fieldName: "Name" }, name: "selectExecution", variant: "base" }
        },
        { label: LABEL_COLUMN_FEATURE, fieldName: "Feature__c" },
        { label: LABEL_COLUMN_STATUS, fieldName: "Status__c" },
        {
            label: LABEL_COLUMN_CREATED,
            fieldName: "CreatedDate",
            type: "date",
            typeAttributes: { year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit" }
        },
        { label: LABEL_COLUMN_USER, fieldName: "UserUrl", type: "url", typeAttributes: { label: { fieldName: "CreatedByName" } } },
        {
            type: "action",
            initialWidth: 48,
            cellAttributes: { alignment: "center" },
            typeAttributes: { rowActions: [{ label: LABEL_ACTION_DETAILS, name: "openRecord" }] }
        }
    ];

    connectedCallback() {
        if (this.canAccessContractDatesUpdate || this.canAccessQuoteUpdate) {
            this.loadExecutions();
            this.initFromUrl();
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: LABEL_UNAUTHORIZED_TITLE,
                    message: LABEL_UNAUTHORIZED_MSG,
                    variant: "error",
                    mode: "sticky"
                })
            );
        }
    }

    async loadExecutions() {
        try {
            let featuresToLoad = this.features.map(f => f.api);
            const data = await getRecentExecutions({ features: featuresToLoad });
            this.executions = (data || []).map((r) => ({
                ...r,
                CreatedByName: r.CreatedBy?.Name,
                UserUrl: r.CreatedById ? "/" + r.CreatedById : null,
                ExecutionUrl: r.Id ? "/" + r.Id : null
            }));
        } catch {
            // Optional: add toast
        }
    }

    async initFromUrl() {
        try {
            const urlParams = new URL(window.location.href).searchParams;
            // Prefer c__executionId (Lightning custom param), fall back to legacy executionId if present
            const execId = urlParams.get("c__executionId") || urlParams.get("executionId");
            if (execId) {
                const execRec = await getExecution({ executionId: execId });
                this.selectedExecution = execRec;
                this.executionId = execRec.Id;
                const feat = this.features.find((f) => f.name === this.mapFeatureApiToInternal(execRec.Feature__c));
                if (feat) {
                    this.activeFeature = feat;
                }
            }
        } catch (e) {
            // swallow
        }
    }

    get isContractDateUpdate() {
        return this.activeFeature && this.activeFeature.name === "contractDateUpdate";
    }
    get isQuoteUpdate() {
        return this.activeFeature && this.activeFeature.name === "quoteUpdate";
    }

    handleFeatureSelect(event) {
        event.stopPropagation();
        const name = event.currentTarget.dataset.name;
        if (name === "contractDateUpdate" && !this.canAccessContractDatesUpdate) {
            return;
        }
        if (name === "quoteUpdate" && !this.canAccessQuoteUpdate) {
            return;
        }
        this.activeFeature = this.features.find((f) => f.name === name);
    }

    handleExecutionRowAction(event) {
        const actionName = event.detail.action ? event.detail.action.name : undefined;
        const row = event.detail.row;

        // If user clicked the Details button (openRecord), open the record page in a new tab
        if (actionName === "openRecord" && row?.Id) {
            try {
                const recUrl = "/" + row.Id;
                window.open(recUrl, "_blank");
            } catch (e) {}
            return;
        }

        // Default behavior: selecting the row sets the active execution and feature
        if (actionName === "selectExecution" || row) {
            this.selectedExecution = row;
            this.executionId = row.Id;
            this.syncUrlExecutionId();
            const feat = this.features.find((f) => f.name === this.mapFeatureApiToInternal(row.Feature__c));
            if (feat) {
                this.activeFeature = feat;
            }
        }
    }

    mapFeatureApiToInternal(featureApi) {
        if (this.canAccessContractDatesUpdate && featureApi === "ContractDateUpdate") {
            return "contractDateUpdate";
        }
        if (this.canAccessQuoteUpdate && featureApi === "QuoteUpdate") {
            return "quoteUpdate";
        }
        return undefined;
    }

    handleCloseFeature() {
        // Reset feature context
        this.activeFeature = undefined;
        this.selectedExecution = undefined;
        this.executionId = undefined;
        // Remove execution id from URL so reopening starts fresh
        try {
            const url = new URL(window.location.href);
            url.searchParams.delete("c__executionId");
            url.searchParams.delete("executionId");
            window.history.replaceState({}, document.title, url.toString());
        } catch (e) {
            /* ignore */
        }
    }

    handleExecutionCreated(event) {
        this.executionId = event.detail.executionId;
        //this.syncUrlExecutionId();
        this.loadExecutions();
    }

    syncUrlExecutionId() {
        try {
            if (!this.executionId) {
                return;
            }
            const url = new URL(window.location.href);
            url.searchParams.set("c__executionId", this.executionId);
            // Remove legacy param if present
            url.searchParams.delete("executionId");
            window.history.replaceState({}, document.title, url.toString());
        } catch (e) {
            /* ignore */
        }
    }
}