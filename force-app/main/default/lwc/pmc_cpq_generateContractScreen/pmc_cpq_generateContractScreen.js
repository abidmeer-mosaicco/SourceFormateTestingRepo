import { LightningElement, api, track, wire } from 'lwc';
import getQuotePrimaryContact from '@salesforce/apex/PMC_CPQ_GenerateQuoteHelper.getQuotePrimaryContact';
import generateContract from '@salesforce/apex/PMC_CPQ_GenerateQuoteHelper.generateContract';
import updateDocusignPicklist from '@salesforce/apex/PMC_CPQ_GenerateQuoteHelper.updateDocusignPicklist';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class GenerateContract extends LightningElement {
    @api recordId;
    @track primaryContactName;
    @track primaryContactEmail;
    @track quoteName;
    @track addUsersValue = null;

    yesNoOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    // Computed mailto link
    get emailLink() {
        return this.primaryContactEmail ? `mailto:${this.primaryContactEmail}` : '';
    }

    @wire(getQuotePrimaryContact, { quoteId: '$recordId' })
    wiredQuote({ error, data }) {
        if (data) {
            this.primaryContactName = data.primaryContactName;
            this.primaryContactEmail = data.primaryContactEmail;
            this.quoteName = data.quoteName;
        }
    }

    // Handle Yes/No selection
    handleSelection(event) {
        this.addUsersValue = event.detail.value;

        // Update picklist for both Yes/No
        updateDocusignPicklist({ quoteId: this.recordId, picklistValue: this.addUsersValue })
            .then(() => {
                // Open contract URL for both Yes and No
                this.generateContractAndOpen();
            })
            .catch(() => {
                // Optional: silently handle error
            });
    }

    // Cancel button
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // Generate contract URL and open
    async generateContractAndOpen() {
        try {
            const url = await generateContract({ quoteId: this.recordId });
            window.open(url, '_blank');

            setTimeout(() => {
                this.dispatchEvent(new CloseActionScreenEvent());
            }, 500);
        } catch {
            setTimeout(() => {
                this.dispatchEvent(new CloseActionScreenEvent());
            }, 3000);
        }
    }
}