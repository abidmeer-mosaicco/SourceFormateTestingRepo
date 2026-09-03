import { LightningElement, api, wire, track } from 'lwc';
import getContractItems from '@salesforce/apex/MosaicDirectContractSummaryCtrl.getContractItems';
import getShipToOptions from '@salesforce/apex/MosaicDirectContractSummaryCtrl.getShipToOptions';
//import getContractDocData from "@salesforce/apex/MosaicDirectContractDocCtrl.getContractDocData";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class MosaicDirectContractSummary extends LightningElement {
    @track contractId = 'test';
    @track accountName = '';
    @track contract = {};
    @track error;
    @track aberto = false;
    @track selectedRecord;
    @track searchKey = '';
    @track items = [];
    @track shipToOptions = [];
    @track isOpen = false;
    @track contractDocumentId = 'ccc86069-bf67-4f46-83fa-648b7eb6c7fb';
    closeModalTimeout;

    get hasContract() {
        return this.contract?.quoteName;
    }

    get filteredItems() {
        if (!this.searchKey) {
            return this.items;
        }
        const key = this.searchKey.toLowerCase();
        return this.items.filter(
            item =>
                (item.Description__c && item.Description__c.toLowerCase().includes(key)) ||
                (item.Name && item.Name.toLowerCase().includes(key))
        );
    }

    connectedCallback() {
        try {
            const storedData = sessionStorage.getItem("contractData");

            if (storedData) {
                this.contract = JSON.parse(storedData);
                console.log(">>> Loaded contract from sessionStorage:", this.contract);
                this.loadContractItems(this.contract.quoteId);
                console.log('>>> contractData:', this.contract.quoteId);
            } else {
                console.warn("No contract data found.");
            }
        } catch (err) {
            this.error = err;
            console.error("Error loading contract data:", err);
        }
    }

    handlePlaceOrderChange(event) {
        const { action, header, loads, totals } = event.detail;
        console.log('handlePlaceOrderChange >>> ', event.detail);

        if (action === "save") {
            this.isOpen = false;
            console.log("Order saved:", header, loads);

            const orderTable = this.template.querySelector('c-mosaic-direct-order-table');
            if (orderTable) {
                orderTable.newOrderData = event.detail;
            }
        }
    }

    async loadContractItems(quoteName) {
        try {
            const subs = await getContractItems({ quoteName });
            this.items = subs.map(s => ({
                Id: s.subscriptionId,
                Quote: s.quoteId,
                QuoteLine: s.quoteLineId,
                Contract: s.contractId,
                Account: s.accountId,
                AccountName: s.accountName,
                Name: s.productCode,
                Description__c: s.productName,
                Quantity__c: s.qtyAvailable,
                TotalQantity: s.qtyAvailable,
                UOM: s.uom,
                MOT: s.mot,
                SHIPPINGTYPE: s.shippingType,
                INCOTERM: s.incoterm,
                StartDate: s.startDate,
                EndDate: s.endDate,
                ContractEndDate: s.contractEndDate,
                ProductLocation: s.productLocationId,
                UnitOfMeasure: s.uom,
                PaymentTerms: s.paymentTerms,
                AdvanceBilling: s.advanceBilling,
                Incoterm2: s.incoterm2,
                ExchangeRate: s.exchangeRate,
                Origin: s.productLocationName,
                ShipTo: s.shipToName,
                ShipToId: s.shipToId,
                Opportunity: s.opportunityId,
                SalesOffice: s.salesOffice,
                SalesChannel: s.salesChannel,
            }));

            if (this.items.length > 0 && this.items[0].Contract) {
                this.contractId = this.items[0].Contract;

                this.accountName = this.items[0].AccountName ? this.items[0].AccountName : '';
                console.log('>>> AccountName:', this.items[0].Account);
                console.log('>>> Contract ID captured:', this.contractId);
                console.log('>>> quoteName:', quoteName);
                this.shipToOptions = await getShipToOptions({ quoteId: quoteName });
                console.log('shipToOptions ' + this.shipToOptions);

                const orderModal = this.template.querySelector('c-mosaic-direct-place-order-modal');

                if (orderModal) {
                    orderModal.contractId = this.contractId;
                    orderModal.shipToOptionsFromContract = this.shipToOptions;
                }

                const orderTable = this.template.querySelector('c-mosaic-direct-order-table');

                if (orderTable) {
                    orderTable.contractId = this.contractId;
                    orderTable.loadOrders(this.contractId);
                }
            }

            console.log('>>> contractData:', this.items);
        } catch (err) {
            this.error = err;
            console.error("Error loading contract items:", err);
        }
    }

    toggleDropdown() {
        this.aberto = !this.aberto;
    }

    handleMouseLeave() {
        this.closeModalTimeout = setTimeout(() => {
            this.aberto = false;
        }, 500);
    }

    handleMouseEnter() {
        clearTimeout(this.closeModalTimeout);
    }

    handleSearch(event) {
        this.searchKey = event.target.value;
    }

    handleModalClose = () => {
        this.isOpen = false;
    };

    selectItem(event) {
        const recordId = event.currentTarget.dataset.id;
        this.selectedRecord = this.items.find(i => i.Id === recordId);
        if (this.selectedRecord.Quantity__c > 0) {
            this.searchKey = '';
            this.aberto = false;
            this.isOpen = true;
        } else {
            this.showToast('Oops!', 'There is no amount available for new orders', 'error');
        }
        console.log(">>> Selected record:", this.selectedRecord);
    }

    /*async handleContractClick() {

        try {
            const response = await getContractDocData({
                strAction: "Download",
                strDocId: this.contractDocumentId
            });

            if (response && Object.keys(response).length) {
                const parsedResponse = JSON.parse(JSON.stringify(response));

                if (parsedResponse.statusCodeMessage?.strStatusMessage) {
                    console.log('error', parsedResponse.statusCodeMessage.strStatusMessage);
                } else if (parsedResponse.strDownloadLink) {
                    console.log(parsedResponse.strDownloadLink);
                    this._downloadViaLink(parsedResponse.strDownloadLink);
                   
                } else {
                    console.log('error: "Invalid response from server"');
                }
            }
        } catch (error) {
            console.log("Something went wrong",error);
        } finally {
           console.log("document download complete");
        }
    }*/

    _downloadViaLink(url) {
        const link = document.createElement("a");
        link.href = url;
        link.target = "_blank";
        link.rel = "noopener noreferrer";
        link.click();
    }

    handleOrderCreated(event) {
        const orderTable = this.template.querySelector('c-mosaic-direct-order-table');
        if (orderTable) {
            orderTable.refreshOrders();
        }
    }

    handleOrderTotalsChange(event) {
        const { totalsByItem } = event.detail;
        console.log('handleOrderTotalsChange >>> totalsByItem:', totalsByItem);

        if (!totalsByItem || !this.items) return;

        this.items = this.items.map(item => {
            const usedQty = totalsByItem[item.Id] || 0;
            const newAvailable = Math.max(item.TotalQantity - usedQty, 0);
            return { ...item, Quantity__c: newAvailable };
        });

        console.log('Updated dropdown quantities:', this.items);
    }

    showToast(toastTitle, toastMessage, toastVariant) {
        const event = new ShowToastEvent({
            title: toastTitle,
            message: toastMessage,
            variant: toastVariant
        });

        this.dispatchEvent(event);
    }
}