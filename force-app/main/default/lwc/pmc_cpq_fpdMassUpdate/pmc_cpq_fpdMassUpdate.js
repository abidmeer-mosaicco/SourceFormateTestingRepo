import { LightningElement, track, api, wire } from "lwc";
import getOPDetails from "@salesforce/apex/PMC_CPQ_FPDMassUpdateController.getOPDetails";
import getDefaultOrderLines from "@salesforce/apex/PMC_CPQ_FPDMassUpdateController.getDefaultOrderLines";
import getPriceFromPriceFX from "@salesforce/apex/PMC_CPQ_sendFPDOrderProductsSAPClass.getPriceFromPriceFX";
import saveOPFromUI from "@salesforce/apex/PMC_CPQ_sendFPDOrderProductsSAPClass.saveOPFromUI";
import userid from "@salesforce/user/Id";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import { subscribe, onError } from "lightning/empApi";
import noOL from "@salesforce/label/c.PMC_CPQ_NoOLSelectedFPDMassUpdate";
import fapMiss from "@salesforce/label/c.PMC_CPQ_FAPMissingFPDMassUpdate";
import sendFPDError from "@salesforce/label/c.PMC_CPQ_sendFPDErrorMassUpdate";
import getFPDError from "@salesforce/label/c.PMC_CPQ_getFPDErrorMassUpdate";
import getFPDIntSuccess from "@salesforce/label/c.PMC_CPQ_GetFPDIntSuccess";
import getFPDIntFail from "@salesforce/label/c.PMC_CPQ_GetFPDIntFail";
import sendFPDIntSuccess from "@salesforce/label/c.PMC_CPQ_SendFPDIntSuccess";
import sendFPDIntFail from "@salesforce/label/c.PMC_CPQ_SendFPDIntFail";
import sendFPDPartialSuccess from "@salesforce/label/c.PMC_CPQ_SendFPDPartialSuccess";
import getFPDPartialSuccess from "@salesforce/label/c.PMC_CPQ_GetFPDPartialSuccess";
import sendFPDPriceFXURL from "@salesforce/apex/PMC_CPQ_sendFPDOrderProductsSAPClass.sendFPDPriceFXURL";
import getRowsForProcessing from "@salesforce/apex/PMC_CPQ_sendFPDOrderProductsSAPClass.getRowsForProcessing";

const columns = [
	{
		label: "Order line",
		fieldName: "lineName",
		cellAttributes: {
			class: { fieldName: "rowStyle" }
		},
		type: "url",
		typeAttributes: {
			label: {
				fieldName: "orderLine"
			},
			target: "_blank"
		}
	},
	{
		label: "Order Number",
		fieldName: "orderNum",
		type: "text",
		cellAttributes: {
			style: { fieldName: "rowStyle" }
		}
	},
	//For US GCPM - 2396
	{
		label: "Approval Status",
		fieldName: "approvalStatus",
		type: "text",
		cellAttributes: {
			style: { fieldName: "rowStyle" }
		}
	},
	/*Start GCPM-5209*/
	{
		label: "Rejected Reason",
		fieldName: "rejectedReason",
		type: "text",
		cellAttributes: {
			style: { fieldName: "rowStyle" }
		}
	},
	/*End GCPM-5209*/
	// {label: 'SAP Order Number',    type: 'text',    fieldName: 'sapOrderNumber'},
	//For US GCPM - 2121,Added the label "SAP Order Line ID"
	{
		label: "SAP Order Line ID",
		type: "text",
		fieldName: "sapOrderLineID",
		cellAttributes: {
			style: { fieldName: "rowStyle" }
		}
	},
	{
		label: "Contract Number",
		fieldName: "contractNum",
		type: "text",
		cellAttributes: {
			style: { fieldName: "rowStyle" }
		}
	},
	{
		label: "Customer Purchase Order #",
		fieldName: "po",
		type: "text",
		cellAttributes: {
			style: { fieldName: "rowStyle" }
		}
	},
	{
		label: "Ship To",
		fieldName: "shipTo",
		type: "text",
		cellAttributes: {
			style: { fieldName: "rowStyle" }
		}
	},
	{
		label: "Account Name",
		fieldName: "accountName",
		type: "text",
		cellAttributes: {
			style: { fieldName: "rowStyle" }
		}
	},
	{
		label: "Product",
		type: "text",
		fieldName: "productName",
		cellAttributes: {
			style: { fieldName: "rowStyle" }
		}
	},
	{
		label: "Quantity",
		type: "Number",
		fieldName: "quantity",
		cellAttributes: {
			style: { fieldName: "rowStyle" }
		}
	},
	{
		label: "Price By Date",
		type: "Date",
		fieldName: "priceByDate",
		cellAttributes: {
			style: { fieldName: "rowStyle" }
		}
	},
	{
		label: "Freight",
		type: "Currency",
		fieldName: "freight",
		cellAttributes: {
			style: { fieldName: "rowStyle" }
		}
	},
	{
		label: "List Price",
		type: "Currency",
		fieldName: "fpdPrice",
		cellAttributes: {
			style: { fieldName: "rowStyle" }
		}
	},
	{
		label: "Agreed Final Price",
		type: "Currency",
		fieldName: "finalAgreedPrice",
		cellAttributes: {
			style: { fieldName: "rowStyle" },
			editable: true
		}
	},
	{
		label: "Status",
		type: "text",
		fieldName: "status",
		cellAttributes: {
			style: { fieldName: "rowStyle" }
		}
	},
	{
		label: "Integration Message",
		type: "text",
		fieldName: "integrationMessage",
		cellAttributes: {
			style: { fieldName: "rowStyle" }
		}
	}
];
export default class Pmc_cpq_fpdMassUpdate extends LightningElement {
	@track selectedRows = [];
	@track showConvTable = false;
	@track filteredData = [];
	@track nonPendingData = [];
	@track isSaveAndSendToSapButtonDisabled = false;
	@track isFiltersPaneOpen = false;
	@track data;
	@track columns = columns;
	@track availableItems;
	@track error;
	@track initialRecords = {};
	@track filterSearchRecords = {};
	@track fldsItemValues = [];
	@track fpdLines = [];
	@track showdefault = false;
	@track accountId;
	@track productId;
	@track OrderId;
	@track shipTo;
	@track ownerId = userid;
	@track searchKey = "";
	@track recordCount = 0;
	@track recordQuantity = 0;
	@track hasNullColumn;
	@track suppress = false;
	@track isLoading = false;
	copyFilterSearchRecords;
	subscription = {};
	@api channelName = "/event/PMC_CPQ_FPDPriceFx__e";
	@track finalWrapper = {};
	fpdEndpointPriceFX;
	fpdEndpointSAP;

	progressModal = {
		open: false,
		totalRows: 0,
		approvalTotal: 0,
		sapTotal: 0,
		approvalProcessed: 0,
		sapProcessed: 0,
		isWorking: false,
		isSuccess: false,
		isError: false,
		isPartial: false
	};

	// Debounce helpers for selection toasts
	toastPendingApprovalTimer;
	toastPendingApprovalMessage;

	// Async tracking for SAP submissions via platform events
	pendingSapIds = new Set();
	sapEventErrorIds = new Set();
	processingErrors = []; // collect synchronous errors (saveOPFromUI) and others

	// Only show the full-page spinner when general data loads are occurring and the modal is not managing progress.
	get displayPageSpinner() {
		return this.isLoading && !this.progressModal.open;
	}

	handleAccountChange(event) {
		if (event.target.value) {
			this.accountId = event.target.value;
		} else this.accountId = null;
	}
	handleOwnerChange(event) {
		if (event.target.value) {
			this.ownerId = event.target.value;
		} else this.ownerId = null;
	}
	handleProductChange(event) {
		if (event.target.value) {
			this.productId = event.target.value;
			console.log("productID clicked!"); // Checking the Product ID
		} else this.productId = null;
	}
	handleShipToChange(event) {
		if (event.target.value) {
			this.shipTo = event.target.value;
		} else this.shipTo = null;
	}
	handleOrderChange(event) {
		if (event.target.value) {
			this.OrderId = event.target.value;
		} else {
			this.OrderId = null;
		}
	}

	//Function which calls the getDefaultOrderLines() method and returns the Order Lines owned by the Logged in user
	async connectedCallback() {
		this.isLoading = true;

		getDefaultOrderLines()
			.then(result => {
				this.showdefault = true;
				let tempOPList = [];
				result = JSON.parse(result);
				result.forEach(record => {
					let tempOPRec = Object.assign({}, record);
					tempOPRec.lineName = "/" + tempOPRec.customId;
					tempOPRec.Id = tempOPRec.customId;
					// Add rowStyle and pending flag for coloring / disabling checkbox

					tempOPRec.rowStyle =
						tempOPRec.approvalStatus === "Pending Approval"
							? "background-color: #fff7e6; font-weight: bold;"
							: tempOPRec.integrationMessage && tempOPRec.integrationStatus.includes("Error")
								? "background-color: #f8d7da; color: #721c24; font-weight: bold;"
								: "";
					tempOPRec.isPendingApproval = tempOPRec.approvalStatus === "Pending Approval";
					tempOPRec.isRejected = this.isRejectedRow(tempOPRec); //GCPM-5209

					tempOPList.push(tempOPRec);
				});
				this.initialRecords = tempOPList;
				this.filterSearchRecords = this.initialRecords;

				const letsearch = this.filterSearchRecords.map(a => ({ ...a }));
				this.copyFilterSearchRecords = letsearch;
				this.error = undefined;
				this.isLoading = false;
				this.getEndpointSAP();
				this.updateNonPendingData();
				this.isSaveAndSendToSapButtonDisabled = false;
			})
			.catch(error => {
				this.isLoading = false;
				this.initialRecords = undefined;
				this.filterSearchRecords = this.initialRecords;
				this.error = error;
				this.updateNonPendingData();
				this.isSaveAndSendToSapButtonDisabled = false;
			});
		this.handleSubscribe();
		this.registerErrorListener();
	}

	//Function which calls the getOPDetails() method and returns the Order Lines based on the filter value passed
	handleSearchPrimary() {
		if (!this.OrderId) {
			return;
		}
		const paramsVariable = {
			acctId: this.accountId,
			userId: this.ownerId,
			prodId: this.productId,
			shipId: this.shipTo,
			ordId: this.OrderId
		};
		const paramsVarStr = JSON.stringify(paramsVariable);
		getOPDetails({ paramsVar: paramsVarStr })
			.then(result => {
				this.isLoading = false;
				this.showdefault = false;
				let tempOPList = [];
				result = JSON.parse(result);
				result.forEach(record => {
					let tempOPRec = Object.assign({}, record);
					tempOPRec.lineName = "/" + tempOPRec.customId;
					tempOPRec.Id = tempOPRec.customId;
					//Add rowStyle and pending flag
					tempOPRec.rowStyle =
						tempOPRec.approvalStatus === "Pending Approval"
							? "background-color: #fff7e6; font-weight: bold;"
							: tempOPRec.integrationMessage && tempOPRec.integrationStatus.includes("Error")
								? "background-color: #f8d7da; color: #721c24; font-weight: bold;"
								: "";
					tempOPRec.isPendingApproval = tempOPRec.approvalStatus === "Pending Approval";
					tempOPRec.isRejected = this.isRejectedRow(tempOPRec); //GCPM-5209

					tempOPList.push(tempOPRec);
				});

				this.availableItems = tempOPList;
				this.filterSearchRecords = this.availableItems;
				const letsearch = this.filterSearchRecords.map(a => ({ ...a }));
				this.copyFilterSearchRecords = letsearch;
				this.error = undefined;
				this.updateNonPendingData();
				this.isSaveAndSendToSapButtonDisabled = false;
			})
			.catch(error => {
				this.isLoading = false;
				this.availableItems = undefined;
				this.filterSearchRecords = this.availableItems;
				this.error = error;
				this.updateNonPendingData();
				this.isSaveAndSendToSapButtonDisabled = false;
			});
	}

	//US 2633
	/*Start GCPM-5209*/
	isRejectedRow(record){
		return record.rejectedReason && record.rejectedReason.trim() !== "";
	}
	
	/*End GCPM-5209*/


	handleRowSelection(event) {
		// Consolidate toast messages for Pending Approval rows to avoid spamming when bulk-selecting.
		const attemptedSelection = event.detail.selectedRows || [];
		console.log("Row selection event fired. Attempted selection count:", attemptedSelection.length);
		const rejectedRows = []; //GCPM-5209
		const pendingRows = [];
		const selectableRows = [];

		attemptedSelection.forEach(row => {
			if (row.approvalStatus === "Pending Approval") {
				pendingRows.push(row);
			} else if (this.isRejectedRow(row)){
				rejectedRows.push(row);//GCPM-5209
			}else {
				selectableRows.push(row);
			}
		});

		// Prepare a single (debounced) toast depending on how many Pending Approval rows were blocked.
		if (pendingRows.length === 1) {
			this.toastPendingApprovalMessage = `Order Line ${pendingRows[0].orderLine} cannot be selected because it is Pending Approval`;
		} else if (pendingRows.length > 1) {
			this.toastPendingApprovalMessage = "Some Order Lines could not be selected because they're Pending Approval";
		}
		/*Start GCPM-5209*/
		if (rejectedRows.length > 0){
			this.toastPendingApprovalMessage = ` ${rejectedRows[0].orderLine} You can’t price a rejected line`;
		} else if (pendingRows.length > 1) {
			this.toastPendingApprovalMessage = "Some Order Lines could not be selected because they're Rejected";
		}
		/*End GCPM-5209*/

		if (this.toastPendingApprovalMessage) {
			clearTimeout(this.toastPendingApprovalTimer);
			this.toastPendingApprovalTimer = setTimeout(() => {
				this.dispatchEvent(
					new ShowToastEvent({
						title: "Info",
						message: this.toastPendingApprovalMessage,
						variant: "info"
					})
				);
				// Reset message after showing so future selections re-schedule appropriately
				this.toastPendingApprovalMessage = undefined;
			}, 150); // short debounce window to collapse rapid events
		}

		this.selectedRows = selectableRows;

		// Sync datatable selected state with filtered rows
		const datatable = this.template.querySelector("lightning-datatable");
		if (datatable) {
			datatable.selectedRows = this.selectedRows.map(r => r.Id);
		}

		// Inform about any Under Revision rows in the (allowed) selection
		const underRevisionRecord = this.selectedRows.find(r => r.approvalStatus === "Under Revision");
		if (underRevisionRecord) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: "Information",
					message: "By selection an Order Line Under Approval , the Approval will be recalled",
					variant: "info"
				})
			);
		}

		this.showConvTable = this.selectedRows.length > 0;
		if (this.showConvTable) {
			this.filteredData = this.selectedRows;
			this.getNonPendingData();
			this.recordCount = this.selectedRows.length;
			this.calculateTotalSum();
		} else {
			this.filteredData = [];
			this.nonPendingData = [];
		}
	}
	// end US 2633


	// Fix GCPM-5179 - only allow non-Pending Approval rows to be selected, avoiding items to be resubmitted erroneously.
	getNonPendingData() {
		try {
			const rows = this.filteredData || [];
			this.nonPendingData = rows.filter(r => r && r.approvalStatus !== 'Pending Approval' && !this.isRejectedRow(r));//GCPM-5209
		} catch {
			this.nonPendingData = [];
		}
	}

	updateNonPendingData() {
		this.filteredData.forEach(filteredItem => {
			let record = this.filterSearchRecords.find(a => a.Id === filteredItem.Id);
			if (record) {
				filteredItem.approvalStatus = record.approvalStatus;
			}
		});
		this.getNonPendingData();
	}

	//Method to handle row selection from the first table
	/*
handleRowSelection(event) {
    //testing 
    console.log('Testing First Line - Event Triggered');
    this.selectedRows = event.detail.selectedRows;
    console.log('Testing Second Line - After Assigning Selected Rows:', this.selectedRows);
    this.showConvTable = this.selectedRows.length > 0;
    console.log('Show Conversation Table:', this.showConvTable);
    if (this.showConvTable) {
        this.filteredData = this.selectedRows;
        this.recordCount = this.selectedRows.length;
       console.log('Filtered Data:', JSON.stringify(this.filteredData));
       console.log('Record Count:', JSON.stringify(this.recordCount));
        this.calculateTotalSum();
          console.log('calculated Sum:', JSON.stringify(this.calculateTotalSum()));
    } else {
        this.filteredData = [];
        console.log('No rows selected, clearing filteredData');
    }
}*/
	//Function to calculate the total count and the quantity of the records selected from the first table
	calculateTotalSum() {
		let sum = 0;
		const columnToSum = "quantity";
		this.selectedRows.forEach(row => {
			sum += row[columnToSum] ? parseFloat(row[columnToSum]) : 0;
		});
		this.recordQuantity = sum;
	}
	//Function which handles the search list of the first table
	handleSearch(event) {
		this.isLoading = true;
		this.searchKey = event.target.value.toLowerCase();
		if (this.searchKey) {
			this.filterSearchRecords = this.copyFilterSearchRecords;
			if (this.filterSearchRecords) {
				let recs = [];
				for (let rec of this.filterSearchRecords) {
					let valuesArray = Object.values(rec);
					for (let val of valuesArray) {
						let strVal = String(val);
						if (strVal) {
							if (strVal.toLowerCase().includes(this.searchKey)) {
								recs.push(rec);
								break;
							}
						}
					}
				}
				this.filterSearchRecords = recs;
			}
		} else {
			this.filterSearchRecords = this.copyFilterSearchRecords;
		}
		this.isLoading = false;
	}
	//Method to handle row selection from the second table
	handleRowSelectionFPD(event) {
		this.selectedRows = event.detail.selectedRows;
		this.fpdLines = this.selectedRows;
	}
	//Method to handle inline editing of Agreed Final price column from the second table
	handleDraftValues(event) {
		let draftValues = event.detail.draftValues;
		this.fldsItemValues = draftValues;
		const fldsItemValuesMap = new Map(this.fldsItemValues.map(item => [item.Id, item.finalAgreedPrice]));
		this.selectedRows.forEach(element => {
			if (fldsItemValuesMap.has(element.customId)) {
				element.finalAgreedPrice = fldsItemValuesMap.get(element.customId);
			}
		});
	}
	// This disables checkbox for Pending Approval rows
	rowSelectable(row) {
		return row.approvalStatus !== "Pending Approval";
	}

	//Method which makes callout to SAP on click of Save and Send to SAP button

	async handleSendPriceToSAP() {
		console.log("Testing Submit and SAP Button");
		let fapNull = false;
		for (let i = 0; i < this.selectedRows.length; i++) {
			if (!this.selectedRows[i].finalAgreedPrice || this.selectedRows[i].finalAgreedPrice === 0) {
				fapNull = true;
				console.log("SAP BUTTON CHECKING is TRUE");
				break;
			}
		}

		if (fapNull) {
			this.ShowToast("Error", fapMiss, "error");
			return;
		}

		this.isSaveAndSendToSapButtonDisabled = true;
		// Do not show the page overlay spinner; modal will convey progress
		this.isLoading = false;
		// Fully reset counters & status flags to avoid stale values from previous runs
		this.progressModal = {
			open: true,
			totalRows: this.selectedRows.length,
			approvalTotal: 0,
			sapTotal: 0,
			approvalProcessed: 0,
			sapProcessed: 0,
			isWorking: true,
			isSuccess: false,
			isError: false,
			isPartial: false
		};

		// Reset async tracking for this run
		this.pendingSapIds = new Set();
		this.sapEventErrorIds = new Set();
		this.processingErrors = [];

		// Build updatedPrices map and get split rows
		let updatedPrices = {};
		this.selectedRows.forEach(row => {
			if (row.finalAgreedPrice != null) {
				updatedPrices[row.customId] = row.finalAgreedPrice;
			}
		});
		// Step 1: Split rows into approval and non-approval
		const result = await getRowsForProcessing({
			selectedIds: this.selectedRows.map(row => row.customId),
			updatedPrices: updatedPrices
		});
		const approvalRows = result.approvalRows;
		const nonApprovalRows = result.nonApprovalRows;

		this.progressModal.approvalTotal = approvalRows && approvalRows.length ? approvalRows.length : 0;
		this.progressModal.sapTotal = nonApprovalRows && nonApprovalRows.length ? nonApprovalRows.length : 0;
		this.progressModal = { ...this.progressModal };

		// Non-approval batch (single call) - do NOT increment sapProcessed yet; rely on platform events
		if (nonApprovalRows && nonApprovalRows.length > 0) {
			this.pendingSapIds = new Set(nonApprovalRows.map(r => r.customId));
			try {
				const resNonApproval = await saveOPFromUI({ lstOlines: JSON.stringify(nonApprovalRows) });
				this.handleResult(resNonApproval);
				if (resNonApproval && resNonApproval.startsWith("Error")) {
					this.processingErrors.push(resNonApproval);
				}
			} catch (e) {
				this.processingErrors.push(e.message || "Unknown SAP submission error");
			}
			this.progressModal = { ...this.progressModal };
		}

		// Approval rows batched
		if (approvalRows && approvalRows.length > 0) {
			const batchSize = 10;
			for (let i = 0; i < approvalRows.length; i += batchSize) {
				const batch = approvalRows.slice(i, i + batchSize);
				try {
					const resApproval = await saveOPFromUI({ lstOlines: JSON.stringify(batch) });
					this.handleResult(resApproval);
					if (resApproval && resApproval.startsWith("Error")) {
						this.processingErrors.push(resApproval);
					} else {
						this.progressModal.approvalProcessed += batch.length;
					}
				} catch (e) {
					this.processingErrors.push(e.message || "Unknown approval submission error");
				}
				this.progressModal = { ...this.progressModal };
			}
		}

		// If there are no SAP submissions pending, finalize; else keep working until events processed
		if (this.pendingSapIds.size === 0) {
			this.finalizeProcessing();
		} else {
			this.progressModal.isWorking = true; // still waiting on SAP events
			this.progressModal = { ...this.progressModal };
		}

		this.isLoading = false;
	}

	finalizeProcessing() {
		// Compute final status flags based on processed counts and error collections
		const hadErrors = this.processingErrors.length > 0 || this.sapEventErrorIds.size > 0;
		const anySuccess =
			this.progressModal.approvalProcessed > 0 ||
			this.progressModal.sapProcessed > 0 ||
			(this.progressModal.approvalTotal === 0 && this.progressModal.sapTotal === 0);
		const allSucceeded =
			this.progressModal.approvalProcessed === this.progressModal.approvalTotal &&
			this.progressModal.sapProcessed === this.progressModal.sapTotal &&
			!hadErrors;

		this.progressModal.isWorking = false;
		this.progressModal.isSuccess = allSucceeded;
		this.progressModal.isError = hadErrors && !anySuccess;
		this.progressModal.isPartial = hadErrors && anySuccess;
		this.progressModal = { ...this.progressModal };

		// Refresh data now that processing completed
		try {
			if (this.OrderId) {
				this.handleSearchPrimary();
			} else {
				this.connectedCallback();
			}
		} catch (e) {
			// eslint-disable-next-line no-console
			console.warn("Refresh after finalization failed", e);
		}
	}

	// Optional helper method to handle Apex result messages
	handleResult(result) {
		if (result) {
			if (result.startsWith("Error")) {
				this.dispatchEvent(
					new ShowToastEvent({
						title: "Error",
						message: this.extractCustomValidationMessage(result),
						variant: "error"
					})
				);
			} /* else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Info",
                  // message: result,
                   // variant: "info"
				 message:'Successfully Sent Order Items to SAP',
				   variant: "Success"
                })
            );
        } */
		}
	}

	extractCustomValidationMessage(errorMessage) {
		if (errorMessage.includes("FIELD_CUSTOM_VALIDATION_EXCEPTION")) {
			return errorMessage
				.split("FIELD_CUSTOM_VALIDATION_EXCEPTION, ")[1]
				.split(": [")[0]
				.replace(/&quot;/g, '"');
		}
		return errorMessage;
	}

	//Function which calls the getEndpointSAP method to return the endpoint for Send Price to SAP callout
	getEndpointSAP() {
		const self = this;
		sendFPDPriceFXURL()
			.then(result => {
				this.isLoading = false;
				self.fpdEndpointSAP = JSON.parse(result);
			})
			.catch(error => {
				this.isLoading = false;
				this.error = error;
			});
	}

	//Method which makes callout to Price on click of Get FPD Price button
	requestTimeout;
	handleGetFPD() {
		this.isLoading = true;
		getPriceFromPriceFX({
			lstOlines: JSON.stringify(this.fpdLines)
		})
			.then(result => {
				if (this.fpdLines.length === 0) {
					this.isLoading = false;
					this.ShowToast("Error", noOL, "error");
				} else {
					this.requestTimeout = setTimeout(() => {
						this.isLoading = false;
					}, 25000);
				}
			})
			.catch(error => {
				this.requestTimeout = setTimeout(() => {
					this.isLoading = false;
				}, 25000);
				this.ShowToast("Error", getFPDError, "error");
			});

		refreshApex(this.filterSearchRecords);
		refreshApex(this.filteredData);
		refreshApex(this.nonPendingData);
	}

	// Handles subscribe button click
	handleSubscribe() {
		const self = this;
		const messageCallback = function (response) {
			var obj = JSON.parse(JSON.stringify(response));
			console.log(this.channel, "event::: ", obj, JSON.stringify(response));

			const index = self.filteredData.findIndex(item => item.Id === obj.data.payload.PMC_CPQ_OrderItemId__c);
			self.isLoading = false;
			clearTimeout(self.requestTimeout);
			if (index !== -1) {
				self.filteredData = [...self.filteredData];
				self.filteredData[index].listPrice = obj.data.payload.PMC_CPQ_FPDPrice__c;
				self.filteredData[index].fpdPrice = obj.data.payload.PMC_CPQ_FPDPrice__c;
				self.filteredData[index].integrationMessage = obj.data.payload.PMC_CPQ_IntegrationStatusMessage__c;
				self.getNonPendingData();
			}
			//check Get FPD status
			if (!obj.data.payload.PMC_CPQ_InterfaceURL__c.includes(self.fpdEndpointSAP)) {
				if (obj.data.payload.PMC_CPQ_OrderLineIntegrationStatus__c === "Success") {
					self.ShowToast("Success", getFPDIntSuccess, "Success");
				} else if (obj.data.payload.PMC_CPQ_OrderLineIntegrationStatus__c === "Partial Success") {
					self.ShowToast("Partial Success", getFPDPartialSuccess, "warning");
				} else {
					self.ShowToast("Error", getFPDIntFail, "Error");
				}
			}
			//check Send FPD status (drive modal progress via platform events)
			if (obj.data.payload.PMC_CPQ_InterfaceURL__c.includes(self.fpdEndpointSAP)) {
				const orderItemId = obj.data.payload.PMC_CPQ_OrderItemId__c;
				// Only count if this was part of the current pending SAP submissions
				if (self.pendingSapIds && self.pendingSapIds.has(orderItemId)) {
					self.pendingSapIds.delete(orderItemId);
					const status = obj.data.payload.PMC_CPQ_OrderLineIntegrationStatus__c;
					if (status === "Error") {
						self.sapEventErrorIds.add(orderItemId);
					}
					self.progressModal.sapProcessed += 1; // processed regardless of success/error
					self.progressModal = { ...self.progressModal };
					if (self.pendingSapIds.size === 0) {
						self.finalizeProcessing();
					}
				}
			}
		};

		subscribe(this.channelName, -1, messageCallback).then(response => {
			console.log("Subscription request sent to: ", JSON.stringify(response.channel));
			this.subscription = response;
		});
	}
	//Method to show toast messages for various scenarios
	ShowToast(title, message, variant) {
		const evt = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant
		});
		this.dispatchEvent(evt);
	}

	registerErrorListener() {
		onError(error => {
			console.log("Received error from server: ", JSON.stringify(error));
			this.isLoading = false;
		});
	}

	togglePanel() {
		let leftPanel = this.template.querySelector("div[data-my-id=leftPanel]");
		let rightPanel = this.template.querySelector("div[data-my-id=rightPanel]");
		if (leftPanel.classList.contains("slds-is-open")) {
			leftPanel.classList.remove("slds-is-open");
			leftPanel.classList.remove("open-panel");
			leftPanel.classList.add("slds-is-closed");
			leftPanel.classList.add("close-panel");
			rightPanel.classList.add("expand-panel");
			rightPanel.classList.remove("collapse-panel");
		} else {
			leftPanel.classList.add("slds-is-open");
			leftPanel.classList.add("open-panel");
			leftPanel.classList.remove("slds-is-closed");
			leftPanel.classList.remove("close-panel");
			rightPanel.classList.remove("expand-panel");
			rightPanel.classList.add("collapse-panel");
		}
		this.isFiltersPaneOpen = !this.isFiltersPaneOpen;
		this.adjustRightPanelWidth(this.isFiltersPaneOpen);
	}
	refreshUserData(evt) {
		const buttonIcon = evt.target.querySelector(".slds-button__icon");
		buttonIcon.classList.add("refreshRotate");
		setTimeout(() => {
			buttonIcon.classList.remove("refreshRotate");
		}, 1000);
	}
	adjustRightPanelWidth(isOpen) {
		const rightPanel = this.template.querySelector(".right-panel");
		if (isOpen) {
			rightPanel.style.width = "82.5%";
		} else {
			rightPanel.style.width = "100%";
		}
	}
	handleProgressClose() {
		this.progressModal.open = false;
		this.progressModal = { ...this.progressModal };
	}
}