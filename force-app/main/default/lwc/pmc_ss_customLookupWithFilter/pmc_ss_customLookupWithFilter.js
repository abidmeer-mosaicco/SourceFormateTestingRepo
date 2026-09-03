import { api, LightningElement, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import lookUp from '@salesforce/apex/PMC_SS_CustomLookupFieldController.searchOrder';

const FIELDS = ['Case.AccountId'];
const ORDER_FIELDS = ['Order.OrderNumber']; //GSMD-1335

export default class Pmc_ss_customLookupWithFilter extends LightningElement {

    @api objName;
    @api iconName;
    @api filter = '';
    @api recordId;
    @api searchPlaceholder='Search';
    @api preselectedOrderId; //GSMD-1335

    @track selectedName;
    @track records;
    @track recordsCopy;

    @track initialCallout = true;

    @track isValueSelected = false;
    @track blurTimeout;

    @track searchTerm = '';
    @track isOrderSearchModalOpen = false;//GSMD-1467
    @track orderItemSearchKey='';//GSMD-1467
    @track filteredOrders = []; //GSMD-1467

    //css
    @track boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    @track inputClass = '';
    @track preselectedRecord;   //GSMD-1335

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            if(data.fields.AccountId.value) {
                this.filter = data.fields.AccountId.value; 
                if(this.filter != '' && this.filter != null && this.filter != undefined) {
                    this.fetchOrders();
                }
            }
            /*<--Start GSMD-1335 -->*/
        } 
        else if (error) {
            console.error('Error fetching Case record:', error);

        }
    }

    @wire(getRecord, { recordId: '$preselectedOrderId', fields: ORDER_FIELDS })
    wiredPreselectedOrder({ error, data }) {
        if (data) {
            this.preselectedRecord = data;
            this.selectedName = data.fields.OrderNumber.value;
            this.isValueSelected = true;
        } else if (error) {
            console.error('Error fetching preselected Order:', error);
        }
    }
/*<--End GSMD-1335 -->*/

    fetchOrders() {

        lookUp({strSearchTerm: this.searchTerm, strObjectName : this.objName, strFilter : this.filter}).then(result => {
            if(result != undefined) {
                if(this.filter != '' && this.initialCallout) {
                    console.log('result length' + result.length);
                    if(result.length > 0) {
                        this.recordsCopy = result;
                        this.initialCallout = false;
                    }
                    else {
                        this.filter = ''; 
                    }
                }

                this.records = result;
                this.filteredOrders = [...this.records];

            }
        }).catch(error => {

        });
    }

    handleClick() {
        this.searchTerm = '';
        this.inputClass = 'slds-has-focus';
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
    }

    onBlur() {
        this.blurTimeout = setTimeout(() =>  {this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus'}, 300);
    }

    onSelect(event) {
        let selectedId = event.currentTarget.dataset.id;
        let selectedName = event.currentTarget.dataset.name;

        const valueSelectedEvent = new CustomEvent('lookupselected', {detail:  selectedId });
        this.dispatchEvent(valueSelectedEvent);

        this.isValueSelected = true;

        this.selectedName = selectedName;

        if(this.blurTimeout) {
            clearTimeout(this.blurTimeout);
        }

        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    }
    //GSMD-1467
    handleOrderItemCheckboxChange(event) {
        let selectedId = event.currentTarget.dataset.id;
        let selectedName = event.currentTarget.dataset.name;
        this.filteredOrders =  this.filteredOrders.map(orderItem => ({
            ...orderItem,
            isSelected: orderItem.Id === selectedId
        }));
        const valueSelectedEvent = new CustomEvent('lookupselected', {detail:  selectedId });
        this.dispatchEvent(valueSelectedEvent);

        this.isValueSelected = true;

        this.selectedName = selectedName;

        if(this.blurTimeout) {
            clearTimeout(this.blurTimeout);
        }

        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    }
//GSMD-1467
    handleRemovePill() {
        this.isValueSelected = false;
        this.selectedName = '';
        this.searchTerm = '';

        if(this.filter != '' && this.recordsCopy) {
            this.records = this.recordsCopy;
        }
        else {
            this.records = [];
        }

        this.inputClass = 'slds-has-focus';
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';

        const valueRemoveEvent = new CustomEvent('lookupremoved', {detail: ''});
        this.dispatchEvent(valueRemoveEvent);
    }

    onChange(event) {
        this.searchTerm = event.target.value;
        if(this.filter != '' && this.searchTerm != '') {
            let filteredData = this.handleSearch(this.recordsCopy, this.searchTerm);
            this.records = filteredData;
        }
        else if(this.filter == '' && this.searchTerm != '') {
            this.fetchOrders();
        }
    }

    handleSearch = (array, searchText) => {
        const filteredData = array.filter(order => {
            if(order.OrderNumber.includes(searchText)) {
                return order;
            }
        });
        return filteredData;
    }

    @api validateFields() {

        var orderElement = this.template.querySelector('lightning-input');

        if(orderElement) {

            orderElement.setCustomValidity('');
            orderElement.reportValidity();
        
            if(!this.isValueSelected) {
                orderElement.setCustomValidity('Select the Order to Proceed further');
                orderElement.reportValidity();
    
                this.scrollToItem(orderElement);
                orderElement.setFocus();
    
                return false;
            }
        }

        return true;
    }

    scrollToItem(item) {
        setTimeout(() => {
            if(item && item.scrollIntoView) {
                item.scrollIntoView({
                    behavior: "smooth",
                    block: "center"
                });
            }
        });
    }
    //GSMD-1467
    openOrderSearchModal() {
        this.isOrderSearchModalOpen = true;
    }
    closeOrderSearchModal() {
        this.isOrderSearchModalOpen = false;
    }

    handleOrderItemSearchKeyChange(event) {
        this.orderSearchKey = event.target.value.toLowerCase();
        this.filteredOrders = this.records.filter(orderItem =>
            (orderItem.OrderNumber && orderItem.OrderNumber.toLowerCase().includes(this.orderSearchKey)) ||
            (orderItem.PMC_CPQ_SAPOrderNumber__c && orderItem.PMC_CPQ_SAPOrderNumber__c.toLowerCase().includes(this.orderSearchKey)) ||
            (orderItem.PMC_CPQ_PO__c && orderItem.PMC_CPQ_PO__c.toLowerCase().includes(this.orderSearchKey)) ||
            (orderItem.Status.toString() && orderItem.Status.toString().toLowerCase().includes(this.orderSearchKey)) 
        ).map(item => ({
            ...item
        }));
    }
    //GSMD-1467
}