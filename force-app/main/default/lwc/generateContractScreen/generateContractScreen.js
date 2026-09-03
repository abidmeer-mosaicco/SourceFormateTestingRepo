import { LightningElement, api, track, wire } from 'lwc';
import getQuotePrimaryContact from '@salesforce/apex/PMC_CPQ_GenerateQuoteHelper.getQuotePrimaryContact';
import generateContract from '@salesforce/apex/PMC_CPQ_GenerateQuoteHelper.generateContract';
import updateDocusignPicklist from '@salesforce/apex/PMC_CPQ_GenerateQuoteHelper.updateDocusignPicklist';
import { CloseActionScreenEvent } from 'lightning/actions';
import ContractLabel from '@salesforce/label/c.PMC_CPQ_GenerateContract';
import ContractPrimaryLabel  from '@salesforce/label/c.PMC_CPQ_PrimaryContactDetails';
import ContractNameLabel  from '@salesforce/label/c.PMC_CPQ_NameContractScreen';
import ContractSignerUpdateLabel  from '@salesforce/label/c.PMC_CPQ_SignerUpdate';
import ContractYesLabel  from '@salesforce/label/c.PMC_CPQ_YesValue';
import ContractNoLabel  from '@salesforce/label/c.PMC_CPQ_NoValue';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class GenerateContract extends LightningElement {
    @api recordId;
    @track primaryContactName;
    @track primaryContactEmail;
    @track quoteName;
    @track addUsersValue = null;
    labelPrimaryContact = ContractPrimaryLabel;
    labelContract=ContractLabel;
    labelName=ContractNameLabel;
    labelSignerUpdate=ContractSignerUpdateLabel;
    labelYes=ContractYesLabel;
    labelNo=ContractNoLabel;

    yesNoOptions = [
        { label: ContractYesLabel, value: 'Yes' },
        { label: ContractNoLabel, value: 'No' }
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
        else if(error)
        {
            this.showToast('Error','Unable to fetch contact details','error');
        }
    }
    showToast(title,message,variant)
    {
        this.dispatchEvent(new ShowToastEvent({
            title,message,variant,mode:'sticky'
        }));
    }
    // Handle Yes/No selection
  /*  handleSelection(event) {
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
    }*/
     handleSelection(event) {
        this.addUsersValue = event.detail.value;
 
        // Update picklist and generate contract
        updateDocusignPicklist({ quoteId: this.recordId, picklistValue: this.addUsersValue })
            .then(() => this.generateContractAndOpen())
            .catch((e) => {
                // Show any exception as toast
                const errorMsg = e.body?.message || e.message || 'Failed to update DocuSign picklist.';
                console.error('Picklist update failed:', e);
                this.showToast('Error', errorMsg, 'error');
                // Modal stays open
            });
    }

    // Cancel button
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // Generate contract URL and open
    /*async generateContractAndOpen() {
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
    }*/
    async generateContractAndOpen() {
    try {
        const url = await generateContract({ quoteId: this.recordId });
 
        if (url) {
            const newTab = window.open(url, '_blank');
            // Do not show success or popup-blocked toast
            if (newTab) {
                // Close modal only if the contract opens successfully
                setTimeout(() => {
                    this.dispatchEvent(new CloseActionScreenEvent());
                }, 200);
            }
            // If window.open failed, do nothing; modal stays open
        } else {
            this.dispatchEvent(
    new ShowToastEvent({
        title: 'No Contract',
        message: 'No URL returned. Check contract conditions or permissions.',
        variant: 'error'
    })
);
            //this.showToast('No Contract', 'No URL returned. Check contract conditions or permissions.', 'error');
            // Modal stays open
        }
    } catch (e) {
        const errorMsg = e.body?.message || e.message || 'Unknown error occurred.';
        console.error('Generate Contract failed:', e);
        this.showToast('Error', errorMsg, 'error');
        // Modal stays open
    }
}

}