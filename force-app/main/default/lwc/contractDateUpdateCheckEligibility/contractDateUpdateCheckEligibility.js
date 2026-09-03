import { LightningElement, api, track } from 'lwc';
import checkEligibility from '@salesforce/apex/ContractDateUpdateController.checkEligibility';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ContractDateUpdateCheckEligibility extends LightningElement {
    @api executionId;
    @api feature;
    // @api lines removido para evitar duplicidade

    @track selectedIds = [];

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
        // Status com ícone
        { label: 'Status', fieldName: 'Status', type: 'customStatusIcon', cellAttributes: { iconName: { fieldName: 'statusIcon' }, iconAlternativeText: { fieldName: 'statusAlt' } } },
        { label: 'Check Eligibility', fieldName: 'CheckEligibilityStatus__c', type: 'customEligibilityIcon', cellAttributes: { iconName: { fieldName: 'eligibilityIcon' }, iconAlternativeText: { fieldName: 'eligibilityAlt' } } },
        // Integração
        { label: 'Integration Status', fieldName: 'PMC_CPQ_IntegrationStatus__c', type: 'customIntegrationIcon', cellAttributes: { iconName: { fieldName: 'integrationIcon' }, iconAlternativeText: { fieldName: 'integrationAlt' } } },
        { label: 'Integration Message', fieldName: 'PMC_CPQ_IntegrationMessage__c' },
        { label: 'Quote Status', fieldName: 'QuoteStatus' },
        { type: 'action', initialWidth: 48, cellAttributes: { alignment: 'center' }, typeAttributes: { rowActions: [ { label: 'Details', name: 'openRecord' } ] } }
    ];

    // Adiciona ícones aos dados das linhas para status, elegibilidade e integração
    @api
    get lines() {
        return this._linesWithIcons || [];
    }
    set lines(val) {
        this._linesWithIcons = (val || []).map(l => {
            // Status
            let statusIcon = '', statusAlt = '';
            if (l.Status === 'Success') {
                statusIcon = 'utility:success'; statusAlt = 'Success';
            } else if (l.Status === 'Error') {
                statusIcon = 'utility:error'; statusAlt = 'Error';
            } else if (l.Status === 'In Progress') {
                statusIcon = 'utility:sync'; statusAlt = 'In Progress';
            } else {
                statusIcon = 'utility:clock'; statusAlt = l.Status || 'Pending';
            }
            // Eligibility
            let eligibilityIcon = '', eligibilityAlt = '';
            if (l.CheckEligibilityStatus__c === 'Eligible' || l.CheckEligibilityStatus__c === 'Success') {
                eligibilityIcon = 'utility:success'; eligibilityAlt = 'Eligible';
            } else if (l.CheckEligibilityStatus__c === 'Not Eligible' || l.CheckEligibilityStatus__c === 'Error') {
                eligibilityIcon = 'utility:error'; eligibilityAlt = 'Not Eligible';
            } else if (l.CheckEligibilityStatus__c === 'In Progress') {
                eligibilityIcon = 'utility:sync'; eligibilityAlt = 'In Progress';
            } else {
                eligibilityIcon = 'utility:clock'; eligibilityAlt = l.CheckEligibilityStatus__c || 'Pending';
            }
            // Integração
            let integrationIcon = '', integrationAlt = '';
            if (l.PMC_CPQ_IntegrationStatus__c === 'Success') {
                integrationIcon = 'utility:success'; integrationAlt = 'Integration Success';
            } else if (l.PMC_CPQ_IntegrationStatus__c === 'Error') {
                integrationIcon = 'utility:error'; integrationAlt = 'Integration Error';
            } else if (l.PMC_CPQ_IntegrationStatus__c === 'In Progress') {
                integrationIcon = 'utility:sync'; integrationAlt = 'Integration In Progress';
            } else if (l.PMC_CPQ_IntegrationStatus__c) {
                integrationIcon = 'utility:info'; integrationAlt = l.PMC_CPQ_IntegrationStatus__c;
            }
            return {
                ...l,
                statusIcon, statusAlt,
                eligibilityIcon, eligibilityAlt,
                integrationIcon, integrationAlt
            };
        });
    }
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

    async handleCheckEligibility(){
        const idsToSend = this.selectedIds.length ? this.selectedIds : this.lines.map(l => l.Id);
        try {
            await checkEligibility({ executionId: this.executionId, executionLineIds: idsToSend });
            this.dispatchEvent(new CustomEvent('refreshlines'));
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: e.body && e.body.message ? e.body.message : 'Eligibility check failed',
                variant: 'error'
            }));
        }
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