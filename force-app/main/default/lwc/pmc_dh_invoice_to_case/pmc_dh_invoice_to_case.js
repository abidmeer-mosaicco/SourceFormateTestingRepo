import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getRelatedCases from '@salesforce/apex/InvoiceCasesController.getRelatedCases';
import getInvoiceDetails from '@salesforce/apex/InvoiceCasesController.getInvoiceDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLUMNS = [
    {
  label: 'Case Number',
  fieldName: 'caseLink',
  type: 'url',
  hideDefaultActions: true,
  typeAttributes: {
    label: { fieldName: 'CaseNumber' },
    target: '_blank'
  }
},
    { label: 'Status', fieldName: 'Status', type: 'text', hideDefaultActions: true },
    { label: 'Type', fieldName: 'Type', type: 'text', hideDefaultActions: true },
    { label: 'Contact Name', fieldName: 'ContactName', type: 'text', hideDefaultActions: true },
    { label: 'At Fault Party', fieldName: 'PMC_SS_AtFaultParty__c', type: 'text', hideDefaultActions: true },
    { label: 'Date/Time Opened', fieldName: 'CreatedDate', type: 'date', typeAttributes: {
        year: "numeric",
        month: "short",
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit"
    }, hideDefaultActions: true }
];

export default class Pmc_dh_invoice_to_case extends LightningElement {
    
    @api recordId;
    @track displayedCases;
    @track allCases;
    @track columns = COLUMNS;
    @track isLoading = true;
    @track showViewAll = false;
    @track showNewCaseModal = false;
    @track invoiceDetails;
    @track isSubmitting = false;
    wiredCasesResult;

    @wire(getRelatedCases, { invoiceId: '$recordId' })
wiredCases(result) {
    this.wiredCasesResult = result;
    if (result.data) {
        // Clone each record and add the caseLink property
        const updatedCases = result.data.map(record => ({
            ...record,
            caseLink: '/' + record.Id
        }));
        this.allCases = updatedCases;
        this.displayedCases = updatedCases.length > 5 ? updatedCases.slice(0, 5) : updatedCases;
        this.showViewAll = updatedCases.length > 5;
        this.isLoading = false;
    } else if (result.error) {
        this.showToast('Error', 'Error fetching cases', 'error');
        this.isLoading = false;
    }
}


    @wire(getInvoiceDetails, { invoiceId: '$recordId' })
    wiredInvoiceDetails({ error, data }) {
        if (data) {
            this.invoiceDetails = data;
            console.log('Data-->' + JSON.stringify(data));
        } else if (error) {
            this.showToast('Error', 'Error fetching order details', 'error');
        }
    }

    handleNewCase() {
        this.showNewCaseModal = true;
    }

    handleCloseModal() {
        this.showNewCaseModal = false;
    }

     handleSubmit(event) {
        event.preventDefault();
        
        const fields = event.detail.fields;
        let missingfields = [];

        if(!fields.AccountId){
            missingfields.push('AccountId');
        }
        if(!fields.ContactId){
            missingfields.push('ContactId');
        }
        if(!fields.Subject){
            missingfields.push('Subject');
        }
        if(!fields.Description){
            missingfields.push('Description');
        }
        if(!fields.Status){
            missingfields.push('Status');
        }
        if(!fields.Priority){
            missingfields.push('Priority');
        }
        if(!fields.Type){
            missingfields.push('Type');
        }
        if(!fields.Origin){
            missingfields.push('Origin');
        }

        if(missingfields.length > 0){
            const errorMsg = 'Please enter: ' + missingfields.join(', ');
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Missing Required Fields',
                    message: errorMsg,
                    variant: 'error'
                })
            );
        }else{
            this.isSubmitting = true;
            fields.PMC_SS_SoldToAccount__c =  this.invoiceDetails.PMC_SS_SoldToAccount__c;
            fields.PMC_SS_SAPOrderNumber__c =  this.invoiceDetails.PMC_SS_SAPOrderNumber__c;
            fields.PMC_SS_Invoice__c = this.recordId;
            fields.PMC_SS_Order__c =  this.invoiceDetails.PMC_SS_Order__c;
            fields.PMC_SS_SAPInvoiceNumber__c =  this.invoiceDetails.PMC_SS_SAPInvoiceNumber__c;  
            fields.Customer_Purchase_Order__c =  this.invoiceDetails.Customer_Purchase_Order__c;
            fields.PMC_SS_OriginalInvoiceAmount__c =  this.invoiceDetails.PMC_SS_OriginalInvoiceAmount__c;
            fields.PMC_SS_VehicleId__c =  this.invoiceDetails.PMC_SS_VehicleID__c;
            fields.PMC_SS_PGIDate__c =  this.invoiceDetails.PMC_CPQ_BillingDate__c;
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        }
    }

 handleSuccess(event) {
        const newCaseId = event.detail.id;
        // Refresh the list to ensure the new case is included
        refreshApex(this.wiredCasesResult).then(() => {
            // Locate the new case to use its CaseNumber as the clickable label
            const newCase = this.allCases.find(rec => rec.Id === newCaseId);
            const labelName = newCase && newCase.CaseNumber ? newCase.CaseNumber : 'View Case';
            const viewUrl = '/' + newCaseId;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success!',
                    message: 'Case created successfully. {0}',
                    messageData: [{
                        url: viewUrl,
                        label: labelName
                    }],
                    variant: 'success'
                })
            );
            this.isSubmitting = false; // stop the spinner
            this.showNewCaseModal = false;
        });
    }


    handleViewAll() {
        console.log('I got triggered!')
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'PMC_CPQ_Invoice__c',
                relationshipApiName: 'Cases__r',
                actionName: 'view'
            }
        });
    }
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}