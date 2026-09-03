import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { CurrentPageReference } from "lightning/navigation";
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord, getRecord, getFieldValue } from "lightning/uiRecordApi";
import { customLabel } from 'c/pmc_ss_customLabelUtility';
import select_actionReason from "@salesforce/label/c.PMC_SS_SelectActionReason";
import select_order from "@salesforce/label/c.PMC_SS_SearchOrder";
import select_orderItem from "@salesforce/label/c.PMC_SS_SelectOrderItem";
import select_vehicle from "@salesforce/label/c.PMC_SS_SelectVehicle";
import select_invoice from "@salesforce/label/c.PMC_SS_SelectInvoice";
import select_atFaultParty from "@salesforce/label/c.PMC_SS_SelectAtFaultParty";
import select_modeofTransportation from "@salesforce/label/c.PMC_SS_SelectModeofTransportation";//GSMD-4070
import select_location from "@salesforce/label/c.PMC_SS_Select_Location";
import select_delivery from "@salesforce/label/c.PMC_SS_SelectDelivery";
import uploadDoc from '@salesforce/label/c.PMC_SS_UploadDocumentForSymbolicReturn';
import return_link from "@salesforce/label/c.PMC_SS_SAPFioriReturnLink";
import cancel_link from "@salesforce/label/c.PMC_SS_SAPFioriCancelLink";
import rebill_link from "@salesforce/label/c.PMC_SS_SAPFioriRebillLink";
import credit_link from "@salesforce/label/c.PMC_SS_SAPFioriCreditLink";
import debit_link from "@salesforce/label/c.PMC_SS_SAPFioriDebitLink";
import select_newContract from "@salesforce/label/c.PMC_SS_SelectNewContract";
import select_option from "@salesforce/label/c.PMC_SS_SelectOption";

import getOrderItems from '@salesforce/apex/PMC_SS_CaseDisputeManagementCtrl.getOrderItems';
import getDeliveryItems from '@salesforce/apex/PMC_SS_CaseDisputeManagementCtrl.getDeliveryItems';
import getContracts from '@salesforce/apex/PMC_SS_CaseDisputeManagementCtrl.getContracts';
import getPickListValues from '@salesforce/apex/PMC_SS_CaseDisputeManagementCtrl.getPickListValues';
import uploadFile from '@salesforce/apex/PMC_SS_CaseDisputeManagementCtrl.uploadFile';
import getQuoteLineitems from '@salesforce/apex/PMC_SS_CaseDisputeManagementCtrl.getQuoteLineitems';

import ID_FIELD from "@salesforce/schema/Case.Id";
import ORDER_FIELD from "@salesforce/schema/Case.PMC_SS_Order__c";
import ORDER_ITEM_FIELD from "@salesforce/schema/Case.PMC_SS_OrderProduct__c";
import INVOICE_FIELD from "@salesforce/schema/Case.PMC_SS_Invoice__c";
import ACTION_REASON_FIELD from "@salesforce/schema/Case.PMC_SS_ActionReason__c";
import ACCOUNT_FIELD from "@salesforce/schema/Case.AccountId";
import CONTACT_FIELD from "@salesforce/schema/Case.ContactId";
import CONTRACT_FIELD from "@salesforce/schema/Case.PMC_SS_OriginalContract__c";
import ORIGINAL_INVOICE_AMOUNT_FIELD from "@salesforce/schema/Case.PMC_SS_OriginalInvoiceAmount__c";
import INVOICE_DIIFFERENCE_FIELD from "@salesforce/schema/Case.PMC_SS_InvoiceDifference__c";
import CANCEL_AMOUNT_FIELD from "@salesforce/schema/Case.PMC_SS_CancelAmount__c";
import REBILL_AMOUNT_FIELD from "@salesforce/schema/Case.PMC_SS_RebillAmount__c";
import AT_FAULT_PARTY_FIELD from "@salesforce/schema/Case.PMC_SS_AtFaultParty__c";
import AT_MOT_FIELD from "@salesforce/schema/Case.PMC_SS_MOT__c";//GSMD-4070
import Location_FIELD from "@salesforce/schema/Case.PMC_SS_Location__c";
import SOLD_TO_ACCOUNT_FIELD from "@salesforce/schema/Case.PMC_SS_SoldToAccount__c";
import SHIP_TO_ACCOUNT_FIELD from "@salesforce/schema/Case.PMC_SS_ShipToAccount__c";
import CREDIT_DEBIT_AMOUNT_FIELD from "@salesforce/schema/Case.PMC_SS_CreditDebitAmount__c";
import RETURN_AMOUNT_FIELD from "@salesforce/schema/Case.PMC_SS_ReturnAmount__c";
import RETURN_QUANTITY_FIELD from "@salesforce/schema/Case.PMC_SS_ReturnQuantity__c";
import PLANT_FIELD from "@salesforce/schema/Case.PMC_SS_Plant__c";
import VEHICLEID_FIELD from "@salesforce/schema/Case.PMC_SS_VehicleId__c";
import MODE_OF_TRANSPORTATION_FIELD from "@salesforce/schema/Case.PMC_SS_MOT__c";
import PGI_DATE_FIELD from "@salesforce/schema/Case.PMC_SS_PGIDate__c";
import NEW_CONTRACT_FIELD from "@salesforce/schema/Case.PMC_SS_NewContract__c";
import TON_FIELD from "@salesforce/schema/Case.PMC_SS_Ton__c";
import UOM_FIELD from "@salesforce/schema/Case.PMC_SS_UOM__c";
import SHIP_FROM_FIELD from "@salesforce/schema/Case.PMC_SS_ShipFrom__c";
import SHIP_TO_FIELD from "@salesforce/schema/Case.PMC_SS_ShipTo__c";
import COMMENT_FIELD from "@salesforce/schema/Case.PMC_SS_Comment__c";
import PRODUCTID_FIELD from "@salesforce/schema/Case.ProductId";
import SHIPMENT_DATE_FIELD from "@salesforce/schema/Case.PMC_SS_ShipmentDate__c";
import DELIVERY_FIELD from "@salesforce/schema/Case.PMC_SS_Delivery__c";
import DOLLAR_AMOUNT_FIELD from "@salesforce/schema/Case.PMC_SS_DollarAmount__c";

export default class Pmc_ss_caseDisputeManagement extends NavigationMixin(LightningElement) {

    quickActionAPIName = "";

    cancelSelected = false;
    rebillSelected = false;

    validatedData = true;

    @track screenTitle = "";

    @track isLoading = false;

    @track orderItems = [];
    @track deliveryItems = [];
    @track invoices = [];
    @track deliveries = [];
    @track contracts = [];

    @track atFaultParty = [];
    @track modeofTransportation = [];//GSMD-4070
    @track showMOT=false;//GSMD-4070
    @track location=[]; //added for GSMD-4076
    @track showLocation=false; //added for GSMD-4076 
    @track selectedLocation; //4076
    @track selectedLocationName; //4076

    @track objOrderDetailsWrapper = {};

    @track invoiceDifference = 0.0;
    @track originalInvoiceAmt = 0.0;
    @track returnAmount = 0.0;
    @track cancelAmount = 0.0;
    @track rebillAmount = 0.0;
    @track dollarAmount = 0.0;

    @track productName = '';

    @track objDelivery = {};
    @track objContact = {};

    @track plantId;
    @track shipToAccountName;
    @track modeOfTransportation;
    @track pgiDate;
    @track deliveryQty;
    @track deliveryUoM;
    @track vehicleId;

    @track orderItemId;

    @track filter = '';
    @track recordId = '';
    @track fileData;
    @track actionReasonValues = [];
    @track shipToAccount;
    @track mapOfOrderItemShipTo = [];

    @track allInvoices = [];
    @track filteredInvoices = [];
    @track inputfilteredInvoices = [];

    @track invoiceSearchKey = '';


    fields = {};

    /**
   * Custom Label Details
   */
    @track labels = {
        select_actionReason,
        select_order,
        select_orderItem,
        select_vehicle,
        select_invoice,
        select_atFaultParty,
        select_modeofTransportation, //GSMD-4070
        select_location, //GSMD- 4076
        select_delivery,
        select_newContract,
        uploadDoc,
        return_link,
        cancel_link,
        rebill_link,
        credit_link,
        debit_link,
        select_option
    }
    @track customLabels = customLabel;
    @track preselectedOrderValue; // GSMD-1335
    @track preselectedOrderItemId; // GSMD-1335
    @track preselectedInvoiceId; // GSMD-1335
    @track preselectedAtFaultParty; //GSMD-2757
    @track preselectedMOT; //GSMD-4070
   


    @track selectedInvoiceLabel = '--- Select ---';
    @track isDropdownOpen = false;
    @track isSearchModalOpen = false;

    @track filteredOrderItems = [];
    @track selectedOrderItemLabel = '--- Select ---';
    @track isOrderItemDropdownOpen = false;
    @track isOrderItemSearchModalOpen = false;

   

    toggleDropdown() {
        this.isDropdownOpen = !this.isDropdownOpen;
    }
    get dropdownClass() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.isDropdownOpen ? 'slds-is-open' : ''}`;
    }

    toggleOrderItemDropdown() {
        this.isOrderItemDropdownOpen = !this.isOrderItemDropdownOpen;
    }
    closeOrderItemDropdown() {
        setTimeout(() => {
            this.isOrderItemDropdownOpen = false;
        }, 200);
    }
    get orderItemDropdownClass() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.isOrderItemDropdownOpen ? 'slds-is-open' : ''}`;
    }
    //GSMD- 4076

    handleLocationSelected(event) {
       console.log('Selected location id:', event.detail.locationId);
       console.log('Selected location Name:', event.detail.locationName);
       this.selectedLocation = event.detail.locationId;
       this.selectedLocationName = event.detail.locationName;
   }
    //ended
 
    handleInvoiceSelect(event) {
        const selectedId = event.currentTarget.dataset.id;
        console.log('Selected Invoice ID:', selectedId);

        const selected = this.invoices.find(inv => inv.Id === selectedId);
        console.log('Selected Invoice Object:', selected);

        if (selected) {
            this.selectedInvoiceLabel = selected.Name;
            console.log('Updated selectedInvoiceLabel:', this.selectedInvoiceLabel);

            this.isDropdownOpen = false;
            console.log('selected.Id:', selected.Id);

            this.updateOriginalInvoiceAmount(selected.Id);
        } else {
            console.warn('Invoice not found for ID:', selectedId);
        }
    }
    handleOrderItemSelect(event) {
        /*const selectedId = event.currentTarget.dataset.id;
        const selected = this.orderItems.find(item => item.Id === selectedId);

        if (selected) {
            this.selectedOrderItemLabel = selected.OrderItemNumber;
            this.isOrderItemDropdownOpen = false;

            this.fields[ORDER_ITEM_FIELD.fieldApiName] = selectedId;
            if (this.isCreditDebitReturnAction && selectedId != '' && selectedId != undefined) {
                this.updatePlant(selectedId);
            }
            if (this.isReturnReverseShipmentAction) {
                this.fetchDeliveryItemsDetails(selectedId);
                if (this.isReverseShipmentAction) {
                    this.updateProduct(selectedId);
                }
            }
        } */
        const selectedId = event.currentTarget.dataset.id;
const selected = this.orderItems.find(item => item.Id === selectedId);
if (selected) {
    this.selectedOrderItemLabel = selected.OrderItemNumber;
    this.fields[ORDER_ITEM_FIELD.fieldApiName] = selectedId;

    const orderItemPicklist = this.template.querySelector('select[data-name="orderItem"]');
    if (orderItemPicklist) {
        setTimeout(() => {
            orderItemPicklist.value = selectedId;
        });
    }

    this.isOrderItemDropdownOpen = false;

    // Trigger dependent logic
    if (this.isCreditDebitReturnAction && selectedId) {
        this.updatePlant(selectedId);
    }
    if (this.isReturnReverseShipmentAction) {
        this.fetchDeliveryItemsDetails(selectedId);
        if (this.isReverseShipmentAction) {
            this.updateProduct(selectedId);
        }
    }
} 
        else {
            console.warn('Order Item not found for ID:', selectedId);
        }
    }

    openSearchModal() {
        console.log('Inside 123');
        this.isSearchModalOpen = true;
    }

    closeSearchModal() {
        this.isSearchModalOpen = false;
    }

    openOrderItemSearchModal() {
        this.isOrderItemSearchModalOpen = true;
    }

    closeOrderItemSearchModal() {
        this.isOrderItemSearchModalOpen = false;
    }

    /*<--Start GSMD-2760 -->*/
confirmOrderItemSelection() {
    const selectedRadio = this.template.querySelector('input[name="invoiceSelection"]:checked');
    if (selectedRadio) {
        const selectedId = selectedRadio.dataset.id;
        const selected = this.orderItems.find(item => item.Id === selectedId);

        if (selected) {
            this.selectedOrderItemLabel = selected.OrderItemNumber;
            this.fields[ORDER_ITEM_FIELD.fieldApiName] = selectedId;

            const orderItemPicklist = this.template.querySelector('select[data-name="orderItem"]');
            if (orderItemPicklist) {
                setTimeout(() => {
                    orderItemPicklist.value = selectedId;
                });
            }

            this.isOrderItemSearchModalOpen = false;

            // Trigger dependent logic
            if (this.isCreditDebitReturnAction && selectedId) {
                this.updatePlant(selectedId);
            }
            if (this.isReturnReverseShipmentAction) {
                this.fetchDeliveryItemsDetails(selectedId);
                if (this.isReverseShipmentAction) {
                    this.updateProduct(selectedId);
                }
            }
        }
    } else {
        // Optionally show a toast if nothing is selected
        this.dispatchEvent(new ShowToastEvent({
            title: 'No Selection',
            message: 'Please select an Order Line Item before confirming.',
            variant: 'warning'
        }));
    }
}

    /*<--End GSMD-2760 -->*/

    handleOrderItemSearchKeyChange(event) {
        this.orderItemSearchKey = event.target.value.toLowerCase();
        this.filteredOrderItems = this.orderItems.slice(1).filter(orderItem =>
            (orderItem.OrderItemNumber && orderItem.OrderItemNumber.toLowerCase().includes(this.orderItemSearchKey)) ||
            (orderItem.PMC_CPQ_SAPOrderLineID__c && orderItem.PMC_CPQ_SAPOrderLineID__c.toLowerCase().includes(this.orderItemSearchKey)) ||
            (orderItem.Product2.Name && orderItem.Product2.Name.toLowerCase().includes(this.orderItemSearchKey)) ||
            (orderItem.Quantity.toString() && orderItem.Quantity.toString().toLowerCase().includes(this.orderItemSearchKey)) ||
            (orderItem.PMC_CPQ_OrderLineStatus__c && orderItem.PMC_CPQ_OrderLineStatus__c.toLowerCase().includes(this.orderItemSearchKey)) ||
            (orderItem.PMC_CPQ_LinePONumber__c && orderItem.PMC_CPQ_LinePONumber__c.toLowerCase().includes(this.orderItemSearchKey))
        ).map(item => ({
            ...item,
            productName: item.Product2?.Name || ''
        }));
    }

    handleOrderItemCheckboxChange(event) {
        /*const selectedId = event.target.dataset.id;

        this.filteredOrderItems = this.filteredOrderItems.map(orderItem => ({
            ...orderItem,
            isSelected: orderItem.Id === selectedId
        }));

        const selected = this.orderItems.find(orderItem => orderItem.Id === selectedId);

        if (selected) {
            this.selectedOrderItemLabel = selected.OrderItemNumber;

            this.fields[ORDER_ITEM_FIELD.fieldApiName] = selectedId;
            if (this.isCreditDebitReturnAction && selectedId != '' && selectedId != undefined) {
                this.updatePlant(selectedId);
            }
            if (this.isReturnReverseShipmentAction) {
                this.fetchDeliveryItemsDetails(selectedId);
                if (this.isReverseShipmentAction) {
                    this.updateProduct(selectedId);
                }
            }

            this.isOrderItemDropdownOpen = false;
        }
        */
        const selectedId = event.target.dataset.id;
        this.filteredOrderItems = this.filteredOrderItems.map(orderItem => ({
            ...orderItem,
            isSelected: orderItem.Id === selectedId
        }));
        const selected = this.orderItems.find(orderItem => orderItem.Id === selectedId);
        if (selected) {
            this.selectedOrderItemLabel = selected.OrderItemNumber;
            this.fields[ORDER_ITEM_FIELD.fieldApiName] = selectedId;
            const orderItemPicklist = this.template.querySelector('select[data-name="orderItem"]');
            if (orderItemPicklist) {
                setTimeout(() => {
                    orderItemPicklist.value = selectedId;
                });
            }

            this.isOrderItemDropdownOpen = false;

            // Trigger dependent logic
            if (this.isCreditDebitReturnAction && selectedId) {
                this.updatePlant(selectedId);
            }
            if (this.isReturnReverseShipmentAction) {
                this.fetchDeliveryItemsDetails(selectedId);
                if (this.isReverseShipmentAction) {
                    this.updateProduct(selectedId);
                }
            }
        } 
        
        const orderItemPicklist = this.template.querySelector('select[data-name="orderItem"]');
        if (orderItemPicklist) {    
            setTimeout(() => {
                orderItemPicklist.value = selectedId;
            });
        }

        else {
            console.warn('Order Item not found for ID:', selectedId);
        }
    }

    handleSearchKeyChange(event) {
        this.invoiceSearchKey = event.target.value.toLowerCase();
        console.log('this.invoiceSearchKey=> ', this.invoiceSearchKey);
        this.filteredInvoices = this.allInvoices.filter(inv =>
            (inv.Name && inv.Name.toLowerCase().includes(this.invoiceSearchKey)) ||
            (inv.PMC_CPQ_InvoiceNumber__c && inv.PMC_CPQ_InvoiceNumber__c.toLowerCase().includes(this.invoiceSearchKey))
        );
    }
    filterOptions(event) {
        this.invoiceSearchKey = event.target.value.toLowerCase();
        console.log('this.invoiceSearchKey =>', this.invoiceSearchKey);

        if (!this.invoiceSearchKey) {
            this.inputfilteredInvoices = [...this.invoices];
        } else {
            this.inputfilteredInvoices = this.invoices.filter(inv =>
                (inv.Name && inv.Name.toLowerCase().includes(this.invoiceSearchKey)) ||
                (inv.PMC_CPQ_InvoiceNumber__c && inv.PMC_CPQ_InvoiceNumber__c.toLowerCase().includes(this.invoiceSearchKey))
            );
        }
    }

    handleCheckboxChange(event) {
        const selectedId = event.target.dataset.id;
        console.log('selectedId:', selectedId);



        this.filteredInvoices = this.filteredInvoices.map(inv => ({
            ...inv,
            isSelected: inv.Id === selectedId
        }));

        const selected = this.invoices.find(inv => inv.Id === selectedId);
        console.log('Selected Invoice Object:', selected);

        if (selected) {
            this.selectedInvoiceLabel = selected.Name;
            console.log('Updated selectedInvoiceLabel:', this.selectedInvoiceLabel);

            this.isDropdownOpen = false;
            console.log('selected.Id:', selected.Id);

            this.updateOriginalInvoiceAmount(selected.Id);
        } else {
            console.warn('Invoice not found for ID:', selectedId);
        }
    }
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference.type === "standard__quickAction") {
            let quickActionPath = currentPageReference.attributes.apiName;
            this.quickActionAPIName = quickActionPath.split('.')[1];
        }
        this.recordId = currentPageReference.state.recordId;
        this.fields[ID_FIELD.fieldApiName] = currentPageReference.state.recordId;
    }

    /*<--Start GSMD-1335 -->*/

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [ORDER_FIELD, INVOICE_FIELD, ORDER_ITEM_FIELD,AT_FAULT_PARTY_FIELD, AT_MOT_FIELD]
    })
    wiredCase({ error, data }) {
        if (data) {
            this.preselectedOrderValue = getFieldValue(data, ORDER_FIELD);
            this.preselectedOrderItemId = getFieldValue(data, ORDER_ITEM_FIELD);
            this.preselectedInvoiceId = getFieldValue(data, INVOICE_FIELD);
            this.preselectedAtFaultParty = getFieldValue(data, AT_FAULT_PARTY_FIELD);//GSMD-2757
            this.preselectedMOT = getFieldValue(data, AT_MOT_FIELD);//GSMD-4070

            if (this.preselectedOrderValue) {
                this.fetchOrderItems(this.preselectedOrderValue);
            } else {
                this.preselectPicklistValues();
            }
        } else if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,
                    message: error.body.message,
                    variant: "error",
                })
            );
        }
    }
    /*<--End GSMD-1335  -->*/

    /*<--Start GSMD-2760 -->*/
    get selectedOrderItemNumber() {
    const selected = this.orderItems.find(item => item.Id === this.preselectedOrderItemId);
    return selected ? selected.OrderItemNumber : '';
    }

 /*<--End GSMD-2760  -->*/
    /*<--Start GSMD-1335 -->*/
    prePopulateOrder(orderId) {
        if (orderId) {
            this.template.querySelector('c-pmc_ss_custom-Lookup-With-Filter[data-name="order"]').preselectedRecordId = orderId;
        }
    }
    preselectPicklistValues() {
        if (this.preselectedInvoiceId) {
            const invoicePicklist = this.template.querySelector('select[data-name="invoice"]');
            if (invoicePicklist) {
                setTimeout(() => {
                    invoicePicklist.value = this.preselectedInvoiceId;
                })
                this.fields[INVOICE_FIELD.fieldApiName] = this.preselectedInvoiceId; // Update the fields object
                this.updateOriginalInvoiceAmount(this.preselectedInvoiceId);
            }
        }
        if (this.preselectedOrderItemId) {
            const orderItemPicklist = this.template.querySelector('select[data-name="orderItem"]');
            if (orderItemPicklist) {
                setTimeout(() => {
                    orderItemPicklist.value = this.preselectedOrderItemId;
                })

                this.fields[ORDER_ITEM_FIELD.fieldApiName] = this.preselectedOrderItemId;  // Update the fields object
                if (this.isCreditDebitReturnAction || this.isReturnReverseShipmentAction) {
                    this.updatePlant(this.preselectedOrderItemId);
                    if (this.isReverseShipmentAction) {
                        this.updateProduct(this.preselectedOrderItemId);
                    }
                }
            }
        }
    }

    /*<--End GSMD-1335  -->*/

    connectedCallback() {

        getPickListValues({
            strObjApiName: 'Case',
            strFieldName: 'PMC_SS_AtFaultParty__c'
        }).then(data => {
            if (data) {
                this.atFaultParty.push({
                    label: this.labels.select_option,
                    value: this.labels.select_option,
                    selected:false//GSMD-2757
                
                });
                for (var i = 0; i < data.length; i++) {
                    this.atFaultParty.push({
                        label: data[i].label,
                        value: data[i].value,
                        selected:false//GSMD-2757

                    });
                }
                 //GSMD-2757
                if (this.atFaultParty.length > 0 && this.preselectedAtFaultParty != null && this.preselectedAtFaultParty != undefined) {
                    this.atFaultParty = this.atFaultParty.map(item => {
                        return {
                            ...item,
                            selected: item.label == this.preselectedAtFaultParty
                        };
                    });
                    //GSMD-4070
                    if(this.preselectedAtFaultParty === 'Carrier' || this.preselectedAtFaultParty === 'Logistics Planning' || this.preselectedAtFaultParty === 'Supply Planning'){
                        this.showMOT = true;
                    }else{
                        this.showMOT=false;
                        this.fields[AT_MOT_FIELD.fieldApiName]=null;
                    }
                    //Ended for GSMD-4070
                }
                //GSMD-2757
                
            }
            console.log('this.atFaultParty => ',JSON.stringify(this.atFaultParty));
        }).catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,
                    message: error.body.message,
                    variant: "error",
                }),
            );
        });

        //GSMD-4070
        getPickListValues({
            strObjApiName: 'Case',
            strFieldName: 'PMC_SS_MOT__c'
        }).then(data => {
                if(data) {
                    this.modeofTransportation.push({
                        label: this.labels.select_option,
                        value: this.labels.select_option,
                        selected:false
                    });
                    for (var i=0; i<data.length; i++) {
                        this.modeofTransportation.push({
                            label:   data[i].label,
                            value: data[i].value,
                            selected:false
                        });
                    }

                    if (this.modeofTransportation.length > 0 && this.preselectedMOT != null && this.preselectedMOT != undefined) {
                        this.modeofTransportation = this.modeofTransportation.map(item => {
                            return {
                                ...item,
                                selected: item.label == this.preselectedMOT
                            };
                        });
                    }
                }
        }).catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                      title: this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,
                      message: error.body.message,
                      variant: "error",
                    }),
                  );
        });
        //Ended for GSMD-4070

        getPickListValues({
            strObjApiName: 'Case',
            strFieldName: 'PMC_SS_ActionReason__c'
        }).then(data => {
            if (data) {
                this.actionReasonValues.push({
                    label: this.customLabels.PMC_SS_SelectOption,
                    value: "--- Select ---"
                });
                for (var i = 0; i < data.length; i++) {

                    if (this.quickActionAPIName == 'PMC_SS_CancelRebill' &&
                        (data[i].value == 'Cancel' || data[i].value == 'Rebill')) {
                        this.screenTitle = this.customLabels.PMC_SS_CancelRebill_ScreenTitle;
                        this.actionReasonValues.push({
                            label: data[i].label,
                            value: data[i].value
                        });
                    }
                    else if (this.quickActionAPIName == 'PMC_SS_CreditDebit' &&
                        (data[i].value == 'Credit' || data[i].value == 'Debit')) {
                        this.screenTitle = this.customLabels.PMC_SS_CreditDebit_ScreenTitle;
                        this.actionReasonValues.push({
                            label: data[i].label,
                            value: data[i].value
                        });
                    }
                    else if (this.quickActionAPIName == 'PMC_SS_Return' &&
                        data[i].value == 'Return') {
                        this.screenTitle = this.customLabels.PMC_SS_Return_ScreenTitle;
                        this.actionReasonValues.push({
                            label: data[i].label,
                            value: data[i].value
                        });
                    }
                    else if (this.quickActionAPIName == 'PMC_SS_ReverseShipment' &&
                        data[i].value == 'Reverse Shipment') {
                        this.screenTitle = this.customLabels.PMC_SS_ReverseShipment_ScreenTitle;
                        this.actionReasonValues.push({
                            label: data[i].label,
                            value: data[i].value
                        });
                    }

                }
            }

        }).catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,
                    message: error.body.message,
                    variant: "error",
                }),
            );
        });


    }
    

    fileUploaded(e) {
        this.fileData = e.detail;
    }

    handleOnChange(e) {
        let id = this.getRealId(e.target.id);
            console.log('this.atFaultParty => ',JSON.stringify(this.atFaultParty));

        if (id == 'actionReason') {
            this.fields[ACTION_REASON_FIELD.fieldApiName] = e.target.value;
            this.updateSelectedActionReason(e.target.value);
        }
        else if (id == 'order') {
            this.updateInitialParams();
            this.fetchOrderItems(e.detail);
        }
        else if (id == 'orderItem') {
            this.orderItemId = e.target.value;
            this.fields[ORDER_ITEM_FIELD.fieldApiName] = e.target.value;
            if (this.isCreditDebitReturnAction && e.target.value != '' && e.target.value != undefined) {
                this.updatePlant(e.target.value);
            }
            if (this.isReturnReverseShipmentAction) {
                this.fetchDeliveryItemsDetails(e.target.value);
                if (this.isReverseShipmentAction) {
                    this.updateProduct(e.target.value);
                }
            }
        }
        else if (id == 'deliveryItem') {
            this.vehicleId = '';
            this.deliveryQty = '';
            this.deliveryUoM = '';
            this.updateMOTFromVehicle(e.target.value);
        }
        else if (id == 'invoice') {
            this.updateOriginalInvoiceAmount(e.target.value);
        }
        else if (id == 'atFaultParty') {
            this.preselectedAtFaultParty = e.target.value;//GSMD-2757
            this.fields[AT_FAULT_PARTY_FIELD.fieldApiName] = e.target.value;
            //added for GSMD-4076
            if (e.target.value=== 'Plant / Operations' || e.target.value=== 'Warehouse'){
                this.showLocation=true;
            }
            else{
               this.showLocation=false;
               this.fields['PMC_SS_Location__c']=null;
            }
            // ended for GSMD-4076    
            //GSMD-4070
            if(e.target.value === 'Carrier' || e.target.value === 'Logistics Planning' || e.target.value === 'Supply Planning'){
                this.showMOT = true;
            }else{
                this.showMOT=false;
                this.fields[AT_MOT_FIELD.fieldApiName]=null;
            }
            //Ended for GSMD-4070
        }
        //GSMD-4070
        else if(id == 'modeofTransportation') {
            this.fields[AT_MOT_FIELD.fieldApiName] = e.target.value;
        }
        //Ended for GSMD-4070
        else if (id == 'cancelAmount') {
            this.cancelAmount = e.target.value;
            this.fields[CANCEL_AMOUNT_FIELD.fieldApiName] = e.target.value;
            this.calculateInvoiceDifference(e.target.value);
        }
        else if (id == 'rebillAmount') {
            this.rebillAmount = e.target.value;
            this.fields[REBILL_AMOUNT_FIELD.fieldApiName] = e.target.value;
            this.calculateInvoiceDifference(e.target.value);
        }
        else if (id == 'returnQuantity') {
            this.fields[RETURN_QUANTITY_FIELD.fieldApiName] = e.target.value;
            this.calculateReturnAmount(e.target.value);
        }
        else if (id == 'creditDebitAmount') {
            this.fields[CREDIT_DEBIT_AMOUNT_FIELD.fieldApiName] = e.target.value;
        }
        else if (id == 'delivery') {
            this.vehicleId = '';
            this.deliveryQty = '';
            this.deliveryUoM = '';
            this.updateSelectedDelivery(e.target.value);
        }
        else if (id == 'comments') {
            this.fields[COMMENT_FIELD.fieldApiName] = e.target.value;
        }
        else if (id == 'newContract') {
            this.fields[NEW_CONTRACT_FIELD.fieldApiName] = e.target.value;
        }
        else if (id == 'dollarAmount') {
            this.dollarAmount = e.target.value;
            this.fields[DOLLAR_AMOUNT_FIELD.fieldApiName] = e.target.value;
            this.calculateInvoiceDifference(e.target.value);
        }
    }

    updateInitialParams() {
        this.orderItems = [];
        this.invoices = [];
        this.deliveryItems = [];
        this.deliveries = [];
        this.contracts = [];

        this.invoiceDifference = 0.0;
        this.originalInvoiceAmt = 0.0;
        this.orderItem = 0; // GSMD-1335
        this.returnAmount = 0.0;
        this.rebillAmount = 0.0;
        this.cancelAmount = 0.0;
        this.dollarAmount = 0.0;

        this.objOrderDetailsWrapper = {};
        this.objContact = {};
        this.objDelivery = {};

        this.plantId = '';
        this.shipToAccountName = '';
        this.modeOfTransportation = '';
        this.pgiDate = '';
        this.deliveryQty = '';
        this.deliveryUoM = '';
        this.vehicleId = '';
        this.orderItemId = '';
        this.productName = '';
    

        var inputFields = this.template.querySelectorAll("lightning-input");
        inputFields.forEach(function (item) {
            if (item.name == 'cancelAmount' || item.name == 'rebillAmount' || item.name == 'creditDebitAmount' || item.name == 'returnQuantity' || item.name == 'dollarAmount') {
                item.value = '';
            }
        });
    }

    updateSelectedActionReason(selectedActionReason) {

        if (selectedActionReason == 'Cancel') {
            this.cancelSelected = true;
            this.rebillSelected = false;
        }
        else if (selectedActionReason == 'Rebill') {
            this.rebillSelected = true;
            this.cancelSelected = false;
        }
    }


    updateOriginalInvoiceAmount(strInvoiceId) {
        console.log('strInvoiceId=> ', strInvoiceId);
        console.log('this.invoices.length=> ', this.invoices.length);

        for (var i = 0; i < this.invoices.length; i++) {
            console.log('this.invoices[i].Id=> ', this.invoices[i].Id);

            if (strInvoiceId == this.invoices[i].Id) {
                console.log('this.invoices[i].PMC_CPQ_TotalInvoiceValue__c=> ', this.invoices[i].PMC_CPQ_TotalInvoiceValue__c);

                this.fields[INVOICE_FIELD.fieldApiName] = strInvoiceId;

                this.originalInvoiceAmt = this.invoices[i].PMC_CPQ_TotalInvoiceValue__c != null ? this.invoices[i].PMC_CPQ_TotalInvoiceValue__c : 0.0;
                console.log('this.originalInvoiceAmt=> ', this.originalInvoiceAmt);

                this.fields[ORIGINAL_INVOICE_AMOUNT_FIELD.fieldApiName] = this.originalInvoiceAmt;

                if (this.isCancelRebillReverseShipmentAction) {
                    //if(this.objContact.Id != null && this.objContact.Id != undefined) {
                    //this.fields[CONTACT_FIELD.fieldApiName] = this.objContact.Id;
                    //}

                    if (this.fields[ACTION_REASON_FIELD.fieldApiName] == 'Cancel' && this.cancelAmount != 0.0) {
                        this.calculateInvoiceDifference(this.cancelAmount);
                    }
                    else if (this.fields[ACTION_REASON_FIELD.fieldApiName] == 'Rebill' && this.rebillAmount != 0.0) {
                        this.calculateInvoiceDifference(this.rebillAmount);
                    }
                    else if (this.fields[ACTION_REASON_FIELD.fieldApiName] == 'Reverse Shipment' && this.dollarAmount != 0.0) {
                        this.calculateInvoiceDifference(this.dollarAmount);
                    }
                }
            }
        }
    }

    updateMOTFromVehicle(deliveryItemId) {
        for (var i = 0; i < this.deliveryItems.length; i++) {
            if (deliveryItemId == this.deliveryItems[i].Id) {

                this.fields[VEHICLEID_FIELD.fieldApiName] = this.deliveryItems[i].VehicleId;
                this.vehicleId = this.deliveryItems[i].VehicleId;
                this.deliveryQty = this.deliveryItems[i].DeliveryQty;
                this.deliveryUoM = this.deliveryItems[i].DeliveryUoM;
                this.fields[TON_FIELD.fieldApiName] = this.deliveryQty;
                this.fields[UOM_FIELD.fieldApiName] = this.deliveryUoM;

                if (this.isReturnAction) {
                    this.modeOfTransportation = this.deliveryItems[i].MOT;
                    this.fields[MODE_OF_TRANSPORTATION_FIELD.fieldApiName] = this.modeOfTransportation;

                }
                if (this.deliveryItems[i].ShippedDate != null && this.deliveryItems[i].ShippedDate != undefined) {
                    this.pgiDate = this.deliveryItems[i].ShippedDate;
                    this.fields[PGI_DATE_FIELD.fieldApiName] = this.pgiDate;
                }
            }
        }
    }

    updatePlant(orderItemId) {
        for (var i = 0; i < this.orderItems.length; i++) {
            if (orderItemId == this.orderItems[i].Id) {
                this.plantId = '';
                this.fields[SHIP_TO_ACCOUNT_FIELD.fieldApiName] = '';
                this.shipToAccountName = '';
                if (this.orderItems[i].PMC_CPQ_ProductLocation__c != null) {
                    if (this.orderItems[i].PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__c != null) {
                        this.plantId = this.orderItems[i].PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_Plant__c != null ?
                            this.plantId = this.orderItems[i].PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_Plant__c : '';
                    }
                }
                this.fields[PLANT_FIELD.fieldApiName] = this.plantId;
                if (this.orderItems[i].PMC_CPQ_ShipTo__c != null && this.orderItems[i].PMC_CPQ_ShipTo__c != undefined
                    && this.orderItems[i].PMC_CPQ_ShipTo__r.Name != null && this.orderItems[i].PMC_CPQ_ShipTo__r.Name != undefined) {
                    this.fields[SHIP_TO_ACCOUNT_FIELD.fieldApiName] = this.orderItems[i].PMC_CPQ_ShipTo__c;
                    this.shipToAccountName = this.orderItems[i].PMC_CPQ_ShipTo__r.Name;
                }
            }
        }
    }

    updateProduct(orderItemId) {
        for (var i = 0; i < this.orderItems.length; i++) {
            if (orderItemId == this.orderItems[i].Id) {
                this.productName = this.orderItems[i].Product2.Name;
                this.fields[PRODUCTID_FIELD.fieldApiName] = this.orderItems[i].Product2Id;
            }
        }
    }

    updateSelectedDelivery(deliveryId) {
        for (var i = 0; i < this.deliveries.length; i++) {
            if (deliveryId == this.deliveries[i].Id) {
                this.objDelivery = this.deliveries[i];
                // Add Values to Field Obj
                this.fields[DELIVERY_FIELD.fieldApiName] = deliveryId;
                //this.fields[TON_FIELD.fieldApiName] = this.objDelivery.DeliveryQty;
                //this.fields[UOM_FIELD.fieldApiName] = this.objDelivery.DeliveryUoM;
                this.fields[SHIP_FROM_FIELD.fieldApiName] = this.objDelivery.ShipFromId;
                this.fields[SHIP_TO_FIELD.fieldApiName] = this.objDelivery.ShipToId;
                if (this.objDelivery.ShippedDate != null && this.objDelivery.ShippedDate != undefined) {
                    this.fields[SHIPMENT_DATE_FIELD.fieldApiName] = this.objDelivery.ShippedDate;
                }
                this.fetchDeliveryItemsDetails(this.orderItemId);
            }
        }
    }

    calculateInvoiceDifference(cancelRebillAmount) {
        if (this.originalInvoiceAmt != 0.0) {
            //this.invoiceDifference = this.originalInvoiceAmt - cancelRebillAmount;
            this.invoiceDifference = cancelRebillAmount - this.originalInvoiceAmt;

            this.fields[INVOICE_DIIFFERENCE_FIELD.fieldApiName] = this.invoiceDifference;
        }
    }

    calculateReturnAmount(returnQty) {
        if (this.orderItemId) {
            for (var i = 0; i < this.orderItems.length; i++) {
                if (this.orderItemId == this.orderItems[i].Id) {
                    getQuoteLineitems({
                        productId: this.this.orderItems[i].Product2Id,
                        quoteId: this.objOrderDetailsWrapper.objOrder.SBQQ__Quote__c
                    }).then(result => {
                        if (result) {
                            this.returnAmount = result[0].SBQQ__ListPrice__c != undefined ? returnQty * result[0].SBQQ__ListPrice__c : 0.0;
                            this.fields[RETURN_AMOUNT_FIELD.fieldApiName] = this.returnAmount;
                        } else {
                            this.returnAmount = this.orderItems[i].UnitPrice != undefined ? returnQty * this.orderItems[i].UnitPrice : 0.0;
                            this.fields[RETURN_AMOUNT_FIELD.fieldApiName] = this.returnAmount;
                        }
                    }).catch(error => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,
                                message: error.body.message,
                                variant: "error",
                            }),
                        );
                    });

                }
            }
        }
    }

    calculateInvoiceDifference(cancelRebillAmount) {
        if (this.originalInvoiceAmt != 0.0) {
            // this.invoiceDifference = this.originalInvoiceAmt - cancelRebillAmount;
            this.invoiceDifference = cancelRebillAmount - this.originalInvoiceAmt;
            this.fields[INVOICE_DIIFFERENCE_FIELD.fieldApiName] = this.invoiceDifference;
        }
    }

    calculateReturnAmount(returnQty) {
        if (this.orderItemId) {
            for (var i = 0; i < this.orderItems.length; i++) {
                if (this.orderItemId == this.orderItems[i].Id) {
                    this.returnAmount = this.orderItems[i].UnitPrice != undefined ? returnQty * this.orderItems[i].UnitPrice : 0.0;
                    this.fields[RETURN_AMOUNT_FIELD.fieldApiName] = this.returnAmount;
                }
            }
        }
    }

    /*get actionReasons() {
        if(this.quickActionAPIName == 'PMC_SS_CancelRebill') {
            this.screenTitle = this.customLabels.PMC_SS_CancelRebill_ScreenTitle;
            return ['--- Select ---','Cancel', 'Rebill'];
        }
        else if(this.quickActionAPIName == 'PMC_SS_CreditDebit') {
            this.screenTitle = this.customLabels.PMC_SS_CreditDebit_ScreenTitle;
            return ['--- Select ---','Credit', 'Debit'];
        }
        else if(this.quickActionAPIName == 'PMC_SS_Return') {
            this.screenTitle = this.customLabels.PMC_SS_Return_ScreenTitle;
            return ['--- Select ---', 'Return'];
        }
        else if(this.quickActionAPIName == 'PMC_SS_ReverseShipment') {
            this.screenTitle = this.customLabels.PMC_SS_ReverseShipment_ScreenTitle;
            return ['--- Select ---', 'Reverse Shipment'];
        }
    }*/

    get isCancelRebillAction() {
        return this.quickActionAPIName == 'PMC_SS_CancelRebill';
    }

    get isCreditDebitAction() {
        return this.quickActionAPIName == 'PMC_SS_CreditDebit';
    }

    get isReturnAction() {
        return this.quickActionAPIName == 'PMC_SS_Return';
    }

    get isReverseShipmentAction() {
        return this.quickActionAPIName == 'PMC_SS_ReverseShipment';
    }

    get isCreditDebitReturnAction() {
        return this.quickActionAPIName == 'PMC_SS_CreditDebit' || this.quickActionAPIName == 'PMC_SS_Return';
    }

    get isCancelRebillReturnAction() {
        return this.quickActionAPIName == 'PMC_SS_CancelRebill' || this.quickActionAPIName == 'PMC_SS_Return';
    }

    get isCancelRebillReverseShipmentAction() {
        return this.quickActionAPIName == 'PMC_SS_CancelRebill' || this.quickActionAPIName == 'PMC_SS_ReverseShipment';
    }

    get isReturnReverseShipmentAction() {
        return this.quickActionAPIName == 'PMC_SS_Return' || this.quickActionAPIName == 'PMC_SS_ReverseShipment';
    }

    fetchOrderItems(strOrderId) {
        var orderId = JSON.stringify(strOrderId).replace(/]|[[]/g, '').replaceAll("\"", '');
        this.fields[ORDER_FIELD.fieldApiName] = orderId;

        if (orderId != '' && orderId != undefined) {

            getOrderItems({ strOrderId: orderId }).then(result => {

                if (result) {
                    console.log('result=> ', result);

                    this.objOrderDetailsWrapper = result;
                    //if(this.objOrderDetailsWrapper.objOrder.BillToContactId != null && this.objOrderDetailsWrapper.objOrder.BillToContactId != undefined) {
                    //this.objContact = { 'Id' : this.objOrderDetailsWrapper.objOrder.BillToContactId,
                    //'Name' : this.objOrderDetailsWrapper.objOrder.BillToContact.Name
                    //            };
                    //}


                    if (this.isCancelRebillAction || this.isReverseShipmentAction) {
                        if (this.objOrderDetailsWrapper.objAccountWrapper.idRecord != null && this.objOrderDetailsWrapper.objAccountWrapper.idRecord != undefined) {
                            this.fields[ACCOUNT_FIELD.fieldApiName] = this.objOrderDetailsWrapper.objAccountWrapper.idRecord;
                        }

                        if (this.isCancelRebillAction) {
                            if (this.objOrderDetailsWrapper.objContractWrapper.idRecord != null && this.objOrderDetailsWrapper.objContractWrapper.idRecord != undefined) {
                                this.fields[CONTRACT_FIELD.fieldApiName] = this.objOrderDetailsWrapper.objContractWrapper.idRecord;
                            }

                            if (this.objOrderDetailsWrapper.objAccountWrapper.idRecord != null && this.objOrderDetailsWrapper.objAccountWrapper.idRecord != undefined && this.objOrderDetailsWrapper.objAccountWrapper.idRecord != '') {
                                this.fetchNewContracts(this.objOrderDetailsWrapper.objAccountWrapper.idRecord);
                            }
                        }
                    }
                    else if (this.isCreditDebitAction || this.isReturnAction) {
                        /*if(this.objOrderDetailsWrapper.objShipToAccountWrapper.idRecord != null && this.objOrderDetailsWrapper.objShipToAccountWrapper.idRecord != undefined){
                            this.fields[SHIP_TO_ACCOUNT_FIELD.fieldApiName] = this.objOrderDetailsWrapper.objShipToAccountWrapper.idRecord;
                        }*/

                        if (this.objOrderDetailsWrapper.objSoldToAccountWrapper.idRecord != null && this.objOrderDetailsWrapper.objSoldToAccountWrapper.idRecord != undefined) {
                            this.fields[SOLD_TO_ACCOUNT_FIELD.fieldApiName] = this.objOrderDetailsWrapper.objSoldToAccountWrapper.idRecord;
                        }
                    }
                    /* <-- Block -->
                        this.orderItems.push({
                            'Id' : '--- Select ---',
                            'OrderItemNumber' : '--- Select ---'
                        });
        
                        for (var i=0; i<this.objOrderDetailsWrapper.lstOrderItems.length; i++) {
                            this.orderItems.push(this.objOrderDetailsWrapper.lstOrderItems[i]);
                            this.mapOfOrderItemShipTo.push(this.objOrderDetailsWrapper.lstOrderItems[i].Id,
                                this.objOrderDetailsWrapper.lstOrderItems[i].PMC_CPQ_ShipTo__c);
                        }
        
                        this.invoices.push({
                            'Id' : '--- Select ---',
                            'Name' : '--- Select ---'
                        });
        
                        for (var i=0; i<this.objOrderDetailsWrapper.lstInvoices.length; i++) {
                            this.invoices.push(this.objOrderDetailsWrapper.lstInvoices[i]);
                        }
    
                        if(this.isReverseShipmentAction) {
    
                            this.deliveries.push({
                                'Id' : '--- Select ---',
                                'ShipmentNumber' : '--- Select ---',
                                //'DeliveryQty' : '--- Select ---',
                                //'DeliveryUoM' : '--- Select ---',
                                'ShipFromId' : '--- Select ---',
                                'ShipFrom' : '--- Select ---',
                                'ShipToId' : '--- Select ---',
                                'ShipTo' : '--- Select ---',
                                'ShippedDate' : '--- Select ---',
                                'VehicleId' : '--- Select ---'
                            });
        
                            for (var i=0; i<this.objOrderDetailsWrapper.lstDeliveries.length; i++) {
                                this.deliveries.push({
                                    'Id' : this.objOrderDetailsWrapper.lstDeliveries[i].Id,
                                    'ShipmentNumber' : this.objOrderDetailsWrapper.lstDeliveries[i].ShipmentNumber,
                                    //'DeliveryQty' :  this.objOrderDetailsWrapper.lstDeliveries[i].PMC_CPQ_DeliveryQuantity__c,
                                    //'DeliveryUoM' :  this.objOrderDetailsWrapper.lstDeliveries[i].PMC_CPQ_UoMUnitofMeasure__c,
                                    'ShipFromId' :  this.objOrderDetailsWrapper.lstDeliveries[i].PMC_CPQ_OriginLocation__c,
                                    'ShipFrom' :  this.objOrderDetailsWrapper.lstDeliveries[i].PMC_CPQ_OriginLocation__c != null && this.objOrderDetailsWrapper.lstDeliveries[i].PMC_CPQ_OriginLocation__c != undefined ? this.objOrderDetailsWrapper.lstDeliveries[i].PMC_CPQ_OriginLocation__r.Name : '',
                                    'ShipToId' :  this.objOrderDetailsWrapper.lstDeliveries[i].DestinationLocationId,
                                    'ShipTo' :  this.objOrderDetailsWrapper.lstDeliveries[i].DestinationLocationId != null && this.objOrderDetailsWrapper.lstDeliveries[i].DestinationLocationId != undefined ? this.objOrderDetailsWrapper.lstDeliveries[i].DestinationLocation.Name : '',
                                    'ShippedDate' :  this.objOrderDetailsWrapper.lstDeliveries[i].PMC_CPQ_ShippedDate__c,
                                    'VehicleId' :  this.objOrderDetailsWrapper.lstDeliveries[i].PMC_CPQ_VehicleID__c
                                });
                            }
                        }
                        <-- Block --> */

                    this.orderItems = [{
                        'Id': '--- Select ---',
                        'OrderItemNumber': '--- Select ---'
                    }, ...this.objOrderDetailsWrapper.lstOrderItems];
                    // this.invoices = [{
                    //     'Id' : '--- Select ---',
                    //     'Name' : '--- Select ---'
                    // }, ...this.objOrderDetailsWrapper.lstInvoices];

                    // Added for GSMD- 2759

    /*<--Start GSMD-2760 -->*/      
    // Auto-select the only order item if there's just one
    if (this.objOrderDetailsWrapper.lstOrderItems.length === 1) {
    const onlyItem = this.objOrderDetailsWrapper.lstOrderItems[0];
    this.preselectedOrderItemId = onlyItem.Id;
    this.selectedOrderItemLabel = onlyItem.OrderItemNumber;
    this.fields[ORDER_ITEM_FIELD.fieldApiName] = onlyItem.Id;

    // Trigger dependent updates
    if (this.isCreditDebitReturnAction && onlyItem.Id) {
        this.updatePlant(onlyItem.Id);
    }
    if (this.isReturnReverseShipmentAction) {
        this.fetchDeliveryItemsDetails(onlyItem.Id);
        if (this.isReverseShipmentAction) {
            this.updateProduct(onlyItem.Id);
        }
    }

    // Update dropdown visually
    const orderItemPicklist = this.template.querySelector('select[data-name="orderItem"]');
    if (orderItemPicklist) {
        setTimeout(() => {
            orderItemPicklist.value = onlyItem.Id;
        });
    }
    }
    /*<--End GSMD-2760  -->*/
      console.log(' A this.invoices : ',this.invoices);
       if (this.objOrderDetailsWrapper?.lstInvoices?.length === 0) 
      {
        // No invoice case
         this.invoices = [{
                        'Id': '--- Select ---',
                        'Name': '--- Select ---',
                        'PMC_CPQ_InvoiceNumber__c': '',
                        'PMC_CPQ_Status__c': '',
                        'PMC_CPQ_DateIssued__c': '',
                        'PMC_CPQ_TotalInvoiceValue__c': 0.0 }]
        this.selectedInvoiceLabel='';
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'No Invoice Found',
                message: 'An Invoice is not associated with this Order.',
                variant: 'error',
                mode: 'sticky'})
        );
      }
    console.log(' B this.invoices : ',this.invoices);
                   let invoicesTemp = [];
                    if(this.objOrderDetailsWrapper?.lstInvoices?.length === 1)
                    {
                        //single invoice case

                          this.invoices = [
                    ...this.objOrderDetailsWrapper.lstInvoices.map(invoice => ({
                        'Id': invoice.Id,
                        'Name': invoice.Name,
                        'PMC_CPQ_InvoiceNumber__c': invoice.PMC_CPQ_InvoiceNumber__c,
                        'PMC_CPQ_Status__c': invoice.PMC_CPQ_Status__c,
                        'PMC_CPQ_DateIssued__c': invoice.PMC_CPQ_DateIssued__c,
                        'PMC_CPQ_TotalInvoiceValue__c': invoice.PMC_CPQ_TotalInvoiceValue__c
                    }))
                    ];
                      this.selectedInvoiceLabel = this.objOrderDetailsWrapper.lstInvoices[0].Name;
                      const selected=this.objOrderDetailsWrapper.lstInvoices[0];
        console.log('Selected Invoice Object:', selected);

        if (selected) {
            
        console.log('Updated selectedInvoiceLabel:', this.selectedInvoiceLabel);
            console.log('selected.Id:', selected.Id);

            this.updateOriginalInvoiceAmount(selected.Id);
        } else {
            console.warn('Invoice not found for ID:', selectedId);
        }
                    }
  console.log(' C this.selectedInvoiceLabel : ',this.selectedInvoiceLabel);
                    if(this.objOrderDetailsWrapper?.lstInvoices?.length > 1) {
                        //multiple invoice case
                  this.invoices = [{
                        'Id': '--- Select ---',
                        'Name': '--- Select ---',
                        'PMC_CPQ_InvoiceNumber__c': '',
                        'PMC_CPQ_Status__c': '',
                        'PMC_CPQ_DateIssued__c': '',
                        'PMC_CPQ_TotalInvoiceValue__c': 0.0
                    },
                    ...this.objOrderDetailsWrapper.lstInvoices.map(invoice => ({
                        'Id': invoice.Id,
                        'Name': invoice.Name,
                        'PMC_CPQ_InvoiceNumber__c': invoice.PMC_CPQ_InvoiceNumber__c,
                        'PMC_CPQ_Status__c': invoice.PMC_CPQ_Status__c,
                        'PMC_CPQ_DateIssued__c': invoice.PMC_CPQ_DateIssued__c,
                        'PMC_CPQ_TotalInvoiceValue__c': invoice.PMC_CPQ_TotalInvoiceValue__c
                    }))
                    ];
                    }
                  
                   console.log(' A this.invoices : ',this.invoices);

                    this.inputfilteredInvoices = [...this.invoices];

                    this.allInvoices = this.objOrderDetailsWrapper.lstInvoices.map(invoice => ({
                        Id: invoice.Id,
                        Name: invoice.Name,
                        PMC_CPQ_InvoiceNumber__c: invoice.PMC_CPQ_InvoiceNumber__c,
                        PMC_CPQ_Status__c: invoice.PMC_CPQ_Status__c,
                        Invoice_Date__c: invoice.PMC_CPQ_DateIssued__c,
                        isSelected: false
                    }));

                    this.filteredInvoices = [...this.allInvoices];
                    this.filteredOrderItems = this.orderItems.slice(1).map(item => ({
                        ...item,
                        productName: item.Product2?.Name || ''
                    }));


                    if (this.isReverseShipmentAction) {
                        this.deliveries = [{
                            'Id': '--- Select ---',
                            'ShipmentNumber': '--- Select ---',
                            'ShipFromId': '--- Select ---',
                            'ShipFrom': '--- Select ---',
                            'ShipToId': '--- Select ---',
                            'ShipTo': '--- Select ---',
                            'ShippedDate': '--- Select ---',
                            'VehicleId': '--- Select ---'
                        }, ...this.objOrderDetailsWrapper.lstDeliveries.map(delivery => ({
                            'Id': delivery.Id,
                            'ShipmentNumber': delivery.ShipmentNumber,
                            'ShipFromId': delivery.PMC_CPQ_OriginLocation__c,
                            'ShipFrom': delivery.PMC_CPQ_OriginLocation__c != null && delivery.PMC_CPQ_OriginLocation__c != undefined ? delivery.PMC_CPQ_OriginLocation__r.Name : '',
                            'ShipToId': delivery.DestinationLocationId,
                            'ShipTo': delivery.DestinationLocationId != null && delivery.DestinationLocationId != undefined ? delivery.DestinationLocation.Name : '',
                            'ShippedDate': delivery.PMC_CPQ_ShippedDate__c,
                            'VehicleId': delivery.PMC_CPQ_VehicleID__c
                        }))];
                    }
                    this.preselectPicklistValues();
                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,
                            message: error.body.message,
                            variant: "error",
                        }),
                    );
                }
            }).catch(error => {
                console.log('error : ',error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,
                        message: error.body.message,
                        variant: "error",
                    }),
                );
            });
        }
    }

    fetchNewContracts(strAccountId) {
        getContracts({ strAccountId: strAccountId }).then(result => {
            if (result == undefined) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,
                        message: error.body.message,
                        variant: "error",
                    }),
                );
            }
            else {
                this.contracts = [];

                this.contracts.push({
                    'Id': '--- Select ---',
                    'ContractNumber': '--- Select ---'
                });

                for (var i = 0; i < result.length; i++) {

                    if (this.objOrderDetailsWrapper.objContractWrapper.idRecord != result[i].Id) {
                        this.contracts.push({
                            'Id': result[i].Id,
                            'ContractNumber': result[i].ContractNumber
                        });
                    }
                }
            }

        }).catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,
                    message: error.body.message,
                    variant: "error",
                }),
            );
        });
    }

    fetchDeliveryItemsDetails(strOrderItemId) {
        getDeliveryItems({ strOrderItemId: strOrderItemId }).then(result => {
            if (result == undefined) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,
                        message: error.body.message,
                        variant: "error",
                    }),
                );
            }
            else {
                this.deliveryItems = [];

                this.deliveryItems.push({
                    'Id': '--- Select ---',
                    'VehicleId': '',
                    'MOT': '--- Select ---',
                    'ShippedDate': '--- Select ---',
                    'DeliveryQty': '--- Select ---',
                    'DeliveryUoM': '--- Select ---',
                    'ShipmentId': '--- Select ---',
                    'ShipmentItemNumber': '--- Select ---'
                });

                if (this.isReverseShipmentAction && this.objDelivery.Id != '') {
                    for (var i = 0; i < result.length; i++) {
                        if (result[i].ShipmentId == this.objDelivery.Id) {
                            this.deliveryItems.push({
                                'Id': result[i].Id,
                                'VehicleId': result[i].PMC_CPQ_VehicleID__c,
                                'MOT': result[i].PMC_CPQ_ModeofTransportation__c,
                                'ShippedDate': result[i].PMC_CPQ_ShippedDate__c,
                                'DeliveryQty': result[i].PMC_CPQ_DeliveryQuantity__c,
                                'DeliveryUoM': result[i].PMC_CPQ_UnitofMeasure__c,
                                'ShipmentId': result[i].ShipmentId,
                                'ShipmentItemNumber': result[i].ShipmentItemNumber,
                            });
                        }
                    }
                }
                else {
                    for (var i = 0; i < result.length; i++) {
                        this.deliveryItems.push({
                            'Id': result[i].Id,
                            'VehicleId': result[i].PMC_CPQ_VehicleID__c,
                            'MOT': result[i].PMC_CPQ_ModeofTransportation__c,
                            'ShippedDate': result[i].PMC_CPQ_ShippedDate__c,
                            'DeliveryQty': result[i].PMC_CPQ_DeliveryQuantity__c,
                            'DeliveryUoM': result[i].PMC_CPQ_UnitofMeasure__c,
                            'ShipmentId': result[i].ShipmentId,
                            'ShipmentItemNumber': result[i].ShipmentItemNumber,
                        });
                    }
                }
            }
        }).catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,
                    message: error.body.message,
                    variant: "error",
                }),
            );
        });
    }



    saveAction() {

        if (this.validateFields()) {
            this.isLoading = true;

         // Added  selected location before save for GSMD- 4076
       if (this.selectedLocation) {
           this.fields.PMC_SS_Location__c = this.selectedLocation;
       }
       //

            const recordInput = {
                fields: this.fields
            };

            updateRecord(recordInput).then(result => {
                if (result != undefined) {

                    if (this.fileData != null && this.fileData != undefined) {

                        if (this.fileData.base64 != null && this.fileData.filename != null && this.fileData.recordId != null && this.isReverseShipmentAction) {
                            uploadFile({ strBase64: this.fileData.base64, strFilename: this.fileData.filename, strRecordId: this.fileData.recordId }).then(result => {

                                this.isLoading = false;

                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: this.customLabels.PMC_SS_Success_MessageLabel,
                                        message: this.customLabels.PMC_SS_Caseupdated_MessageLabel,
                                        variant: "success",
                                    }),
                                );

                                this.closeAction();
                            });
                        }
                    }
                    else {
                        this.isLoading = false;

                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: this.customLabels.PMC_SS_Success_MessageLabel,
                                message: this.customLabels.PMC_SS_Caseupdated_MessageLabel,
                                variant: "success",
                            }),
                        );

                        this.closeAction();
                    }
                }
            })
                .catch(error => {
                    console.log('Error --> ' + JSON.stringify(error.body));
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: this.customLabels.PMC_SS_FailedtoUpdateRecord_ErrorMessage,
                            message: error.body.message,
                            variant: "error",
                        }),
                    );
                });
        }
    }

    validateFields() {

        var validationSuccess = true;
        var firstElement;

        let actionReasonElement = this.template.querySelector('select[data-name="actionReason"]');
        actionReasonElement.setCustomValidity('');
        actionReasonElement.reportValidity();

        if (actionReasonElement.value == '--- Select ---') {
            actionReasonElement.setCustomValidity('Select Option');
            actionReasonElement.reportValidity();
            validationSuccess = false;
        }

        if (!firstElement && !validationSuccess) {
            firstElement = actionReasonElement;
        }

        if (validationSuccess) {
            if (!this.template.querySelector(".mandatory").validateFields()) {
                validationSuccess = false;
            }
        }

        if (validationSuccess) {

            var selectFields = this.template.querySelectorAll("select");
            selectFields.forEach(function (item) {

                item.setCustomValidity('');
                item.reportValidity();

                if (validationSuccess) {

                    if (item.name == 'orderItem' || item.name == 'vehicle' || item.name == 'delivery') { //|| item.name == 'invoice'

                        if (item.value == '' || item.value == '--- Select ---') {
                            item.setCustomValidity('Select Option');
                            item.reportValidity();
                            validationSuccess = false;
                        }
                    }
                }

                if (!firstElement && !validationSuccess) {
                    firstElement = item;
                }
            });
        }


        if (validationSuccess) {
            var inputFields = this.template.querySelectorAll("lightning-input");
            inputFields.forEach(function (item) {
                item.setCustomValidity('');
                item.reportValidity();
                if (validationSuccess) {
                    if (item.name == 'cancelAmount' || item.name == 'rebillAmount' || item.name == 'creditDebitAmount' || item.name == 'returnQuantity' || item.name == 'dollarAmount') {
                        if (item.required && item.value == '') {
                            item.setCustomValidity(item.label + ' is Required');
                            item.reportValidity();
                            validationSuccess = false;
                        }
                    }

                    if (!firstElement && !validationSuccess) {
                        firstElement = item;
                    }
                }
            });
        }

        if (validationSuccess) {
            let atFaultPartyElement = this.template.querySelector('select[data-name="atFaultParty"]');
            atFaultPartyElement.setCustomValidity('');
            atFaultPartyElement.reportValidity();

            if (atFaultPartyElement.value == '--- Select ---') {
                atFaultPartyElement.setCustomValidity('Select Option');
                atFaultPartyElement.reportValidity();
                validationSuccess = false;
            }

            if (!firstElement && !validationSuccess) {
                firstElement = atFaultPartyElement;
            }
        }

        //GSMD-4070
        if(validationSuccess && this.showMOT) {
            let modeofTransportationElement = this.template.querySelector('select[data-name="modeofTransportation"]');
            modeofTransportationElement.setCustomValidity('');
            modeofTransportationElement.reportValidity();
    
            if(modeofTransportationElement.value == '--- Select ---') {
                modeofTransportationElement.setCustomValidity('Select Option');
                modeofTransportationElement.reportValidity();
                validationSuccess = false;
            }
    
            if(!firstElement && !validationSuccess) {
                firstElement = modeofTransportationElement;
            }
        }
        //Ended for GSMD-4070

        this.validatedData = validationSuccess;

        if (!validationSuccess && firstElement) {
            this.scrollToItem(firstElement);
            firstElement.setFocus();
        }

        return validationSuccess;
    }

    getRealId(id) {
        const parts = (id || "").split("-");
        parts.pop();
        return parts.join("-");
    }

    scrollToItem(item) {
        setTimeout(() => {
            if (item && item.scrollIntoView) {
                item.scrollIntoView({
                    behavior: "smooth",
                    block: "center"
                });
            }
        });
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}