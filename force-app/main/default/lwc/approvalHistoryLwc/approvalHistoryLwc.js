import { LightningElement, api, wire, track } from 'lwc';
import getApprovalHistory from '@salesforce/apex/ApprovalHistoryController.getApprovalHistory';

export default class ApprovalHistoryLwc extends LightningElement {
    @api recordId;
    @track approvalItems = [];
    @track error;

    isModalOpen = false;
    selectedComment = '';

    @wire(getApprovalHistory, { recordId: '$recordId' })
    wiredHistory({ error, data }) {
        if (data) {
            this.approvalItems = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.approvalItems = [];
        }
    }

    get noApprovalItemsAndNoError() {
        return !this.approvalItems.length && !this.error;
    }

    get errorMessage() {
        if (!this.error) return '';
        if (this.error.body) {
            if (Array.isArray(this.error.body)) {
                return this.error.body.map(e => e.message).join(', ');
            }
            return this.error.body.message || JSON.stringify(this.error.body);
        }
        return this.error.message || JSON.stringify(this.error);
    }

    columns = [
        {
            label: 'Comments',
            type: 'button',
            typeAttributes: {
                label: 'View',
                name: 'view_comment',
                variant: 'base'
            }
        },
        { label: 'Status', fieldName: 'status', type: 'text' },
        { label: 'Reviewed By', fieldName: 'reviewedByName', type: 'text' },
        { label: 'Assigned To', fieldName: 'assignedToId', type: 'text' },
        { label: 'Reviewed Date', fieldName: 'reviewedDate', type: 'date' },
        { label: 'Name', fieldName: 'name', type: 'text' }
    ];

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if (actionName === 'view_comment') {
            this.selectedComment = row.comments || '';
            this.isModalOpen = true;
        }
    }

    closeModal() {
        this.isModalOpen = false;
        this.selectedComment = '';
    }
}