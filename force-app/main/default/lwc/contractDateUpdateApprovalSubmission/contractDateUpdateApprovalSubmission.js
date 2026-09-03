import { LightningElement, api, track } from 'lwc';
// import getExecutionLinesForApproval from '@salesforce/apex/ContractDateUpdateController.getExecutionLinesForApproval';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ContractDateUpdateApprovalSubmission extends LightningElement {
    @api executionId;
    @api feature;
    @api lines = [];

    @track selectedIds = [];

    get eligibleLines() {
        return this.lines.filter(line => line.EligibilityStatus === 'Success' && !line.AmendApprovalStatus);
    }

    columns = [
        { label: 'Contract #', fieldName: 'ContractUrl', type: 'url', typeAttributes: { label: { fieldName: 'ContractNumber' }, target: '_blank' } },
        { label: 'Latest Quote', fieldName: 'LatestQuoteUrl', type: 'url', typeAttributes: { label: { fieldName: 'QuoteName' }, target: '_blank' } },
        { label: 'Type', fieldName: 'QuoteType' },
        { label: 'SAP Contract Ref', fieldName: 'SapContractRef' },
        { label: 'Account', fieldName: 'AccountUrl', type: 'url', typeAttributes: { label: { fieldName: 'AccountName' }, target: '_blank' } },
        { label: 'Business Type', fieldName: 'QuoteSubType' },
        { label: 'Sales Office', fieldName: 'SalesOffice' },
        { label: 'Account Manager', fieldName: 'AccountManagerUrl', type: 'url', typeAttributes: { label: { fieldName: 'AccountManagerName' }, target: '_blank' } },
        { label: 'Contract Document Status', fieldName: 'QuoteContractStage' },
        { label: 'Valid From (current)', fieldName: 'StartDate', type: 'date', cellAttributes: { style: "color: gray; text-decoration: line-through" } },
        { label: 'Valid To (current)', fieldName: 'EndDate', type: 'date', cellAttributes: { style: "color: gray; text-decoration: line-through" } },
        { label: 'Valid From (new)', fieldName: 'QuoteContractStart', type: 'date' },
        { label: 'Valid To (new)', fieldName: 'QuoteContractEnd', type: 'date' },
        { label: 'Approval Status', fieldName: 'QuoteApprovalStatus' },
        { label: 'Status', fieldName: 'Status' },
        { label: 'Quote Status', fieldName: 'QuoteStatus' },
        { type: 'action', initialWidth: 48, cellAttributes: { alignment: 'center' }, typeAttributes: { rowActions: [ { label: 'Details', name: 'openRecord' } ] } }
    ];

    connectedCallback() {
        if (this.lines && this.lines.length) {
            this.selectedIds = this.lines.map(l => l.Id);
        }
    }

    renderedCallback(){
        if(this.lines && this.lines.length && (!this.selectedIds.length || this.selectedIds.length !== this.lines.length)){
            const dt = this.template.querySelector('lightning-datatable');
            if(dt){
                this.selectedIds = this.lines.map(l => l.Id);
                dt.selectedRows = this.selectedIds;
            }
        }
    }


    @api
    refreshSelectionWithLines() {
        // helper to reset selection after refresh
        this.selectedIds = (this.lines || []).map(l => l.Id);
        const dt = this.template.querySelector('lightning-datatable');
        if (dt) {
            dt.selectedRows = this.selectedIds;
        }
    }

    handleRefresh(){
        this.dispatchEvent(new CustomEvent('refreshlines'));
    }

    handleRowSelection(event){
        this.selectedIds = event.detail.selectedRows.map(r => r.Id);
    }

    async handleSubmitForApproval(){
        this.dispatchEvent(new CustomEvent('submitforapproval', { detail: { selectedIds: this.selectedIds } }));
    }

    handleRowAction(event){
        const actionName = event.detail.action ? event.detail.action.name : undefined;
        const row = event.detail.row;
        if(actionName === 'openRecord' && row && row.Id){
            try{
                const recUrl = '/' + row.Id;
                window.open(recUrl, '_blank');
            } catch (e) {
                // ignore
            }
        }
    }
}