import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import QUOTE_OBJECT from '@salesforce/schema/SBQQ__Quote__c';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import BUSINESS_TYPE_FIELD from '@salesforce/schema/SBQQ__Quote__c.PMC_CPQ_QuoteRecordSubType__c';
import SALES_OFFICE_FIELD from '@salesforce/schema/SBQQ__Quote__c.PMC_CPQ_SalesOffice__c';

// Import Custom Labels
import LABEL_SOLD_TO from '@salesforce/label/c.MassUpdate_Filters_Field_SoldTo';
import LABEL_QUOTE_NUMBER from '@salesforce/label/c.MassUpdate_Filters_Field_QuoteNumber';
import LABEL_TYPE from '@salesforce/label/c.MassUpdate_Filters_Field_Type';
import LABEL_SAP_ORIGINAL_CONTRACT from '@salesforce/label/c.MassUpdate_Filters_Field_SAPOriginalContract';
import LABEL_ACCOUNT from '@salesforce/label/c.MassUpdate_Filters_Field_Account';
import LABEL_BUSINESS_TYPE from '@salesforce/label/c.MassUpdate_Filters_Field_BusinessType';
import LABEL_SALES_OFFICE from '@salesforce/label/c.MassUpdate_Filters_Field_SalesOffice';
import LABEL_ACCOUNT_MANAGER from '@salesforce/label/c.MassUpdate_Filters_Field_AccountManager';
import LABEL_CONTRACT_DOC_STATUS from '@salesforce/label/c.MassUpdate_Filters_Field_ContractDocStatus';
import LABEL_CONTRACT_VALID_FROM from '@salesforce/label/c.MassUpdate_Filters_Field_ContractValidFrom';
import LABEL_CONTRACT_VALID_TO from '@salesforce/label/c.MassUpdate_Filters_Field_ContractValidTo';
import LABEL_APPROVAL_STATUS from '@salesforce/label/c.MassUpdate_Filters_Field_ApprovalStatus';
import LABEL_STATUS from '@salesforce/label/c.MassUpdate_Filters_Field_Status';
import LABEL_SAP_CONTRACT_REF from '@salesforce/label/c.MassUpdate_Filters_Field_SAPContractRef';
import LABEL_CARD_TITLE from '@salesforce/label/c.MassUpdate_Filters_Card_FilterContracts';
import LABEL_BUTTON_CLEAR from '@salesforce/label/c.MassUpdate_Filters_Button_Clear';
import LABEL_BUTTON_LOAD from '@salesforce/label/c.MassUpdate_Filters_Button_Load';
import LABEL_QUOTE_STATUS from '@salesforce/label/c.MassUpdate_Filters_Field_Status';

/**
 * contractDateUpdateFilters
 * Emits bubbling events to parent selector so logic stays centralized.
 * Events (all bubble+composed):
 *  - filterschange { name, value }
 *  - load
 *  - clear
 *  - datechange { field, value }
 *  - process
 *  - resetselection
 */
export default class ContractDateUpdateFilters extends LightningElement {
    @api searchKey;
    
    // New quote-level filters
    @api soldTo;
    @api quoteNumber;
    @api type;
    @api sapOriginalContract;
    @api account;
    @api businessType;
    @api salesOffice;
    @api accountManager;
    @api contractDocStatus;
    @api contractValidFrom;
    @api contractValidTo;
    @api approvalStatus;
    @api quoteStatus;
    @api sapContractRef;
    @api totalRecords = 0;
    @api selectedCount = 0;

    // UI API: object metadata for localized labels
    @wire(getObjectInfo, { objectApiName: QUOTE_OBJECT })
    quoteInfo;

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    accountInfo;

    // Wire picklist values with automatic translation
    @wire(getPicklistValues, { recordTypeId: '$quoteInfo.data.defaultRecordTypeId', fieldApiName: BUSINESS_TYPE_FIELD })
    businessTypePicklist;

    @wire(getPicklistValues, { recordTypeId: '$quoteInfo.data.defaultRecordTypeId', fieldApiName: SALES_OFFICE_FIELD })
    salesOfficePicklist;

    // Compute picklist options for lightning-combobox
    get businessTypeOptions() {
        if (!this.businessTypePicklist?.data?.values) {
            return [{ label: '--Select--', value: '' }];
        }
        const options = this.businessTypePicklist.data.values.map(item => ({
            label: item.label,
            value: item.label  // Use label as value for filtering with translated text
        }));
        return [{ label: '--Select--', value: '' }, ...options];
    }

    get salesOfficeOptions() {
        if (!this.salesOfficePicklist?.data?.values) {
            return [{ label: '--Select--', value: '' }];
        }
        const options = this.salesOfficePicklist.data.values.map(item => ({
            label: item.label,
            value: item.label  // Use label as value for filtering with translated text
        }));
        return [{ label: '--Select--', value: '' }, ...options];
    }

    // Compute localized labels with safe fallbacks
    get labels() {
        const q = this.quoteInfo?.data?.fields || {};
        const a = this.accountInfo?.data?.fields || {};

        return {
            // Account-level field via relationship (Sold-To): Account.PMC_SS_AccountExternalID__c
            soldTo: a.PMC_SS_AccountExternalID__c?.label || LABEL_SOLD_TO,

            // Quote fields
            quoteNumber: q.Name?.label || LABEL_QUOTE_NUMBER,
            type: q.SBQQ__Type__c?.label || LABEL_TYPE,
            sapOriginalContract: q.PMC_CPQ_LegacyQuoteID__c?.label || LABEL_SAP_ORIGINAL_CONTRACT,
            account: q.SBQQ__Account__c?.label || LABEL_ACCOUNT,
            businessType: q.PMC_CPQ_QuoteRecordSubType__c?.label || LABEL_BUSINESS_TYPE,
            salesOffice: q.PMC_CPQ_SalesOffice__c?.label || LABEL_SALES_OFFICE,
            accountManager: q.PMC_CPQ_AccountManager__c?.label || LABEL_ACCOUNT_MANAGER,
            contractDocStatus: q.PMC_CPQ_ContractStageName__c?.label || LABEL_CONTRACT_DOC_STATUS,
            contractValidFrom: q.PMC_CPQ_ContractStart__c?.label || LABEL_CONTRACT_VALID_FROM,
            contractValidTo: q.PMC_CPQ_ContractEnd__c?.label || LABEL_CONTRACT_VALID_TO,
            approvalStatus: q.ApprovalStatus__c?.label || LABEL_APPROVAL_STATUS,
            quoteStatus: q.SBQQ__Status__c?.label || LABEL_QUOTE_STATUS,
            sapContractRef: q.PMC_CPQ_SAPContractReference__c?.label || LABEL_SAP_CONTRACT_REF,
            cardTitle: LABEL_CARD_TITLE,
            buttonClear: LABEL_BUTTON_CLEAR,
            buttonLoad: LABEL_BUTTON_LOAD
        };
    }

    handleInput(event) {
        const { name, value } = event.target;
        this.dispatchEvent(new CustomEvent('filterschange', { detail: { name, value }, bubbles: true, composed: true }));
    }

    handleComboboxChange(event) {
        const { name, value } = event.target;
        // Convert array to semicolon-separated string for multiple selections
        const finalValue = Array.isArray(value) ? value.join(';') : value;
        this.dispatchEvent(new CustomEvent('filterschange', { detail: { name, value: finalValue }, bubbles: true, composed: true }));
    }


    handleLoad() {
        this.dispatchEvent(new CustomEvent('load', { bubbles: true, composed: true }));
    }

    handleClear() {
        this.dispatchEvent(new CustomEvent('clear', { bubbles: true, composed: true }));
    }

    // Removed date change & process/reset actions (moved to modal form component)
}