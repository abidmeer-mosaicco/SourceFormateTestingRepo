/**
 * Pmc_SS_ApprovalView
 *
 * Displays the logged-in user's pending approvals and allows inline Approve/Reject
 * with mandatory comments. Rows link to the approval record and related Case.
 *
 * Data source: PMC_SS_ApprovalController.getMyPendingApprovals
 * Actions: PMC_SS_ApprovalController.processApprovalRecord
 */
import { LightningElement, wire, track } from 'lwc';
import getMyPendingApprovals from '@salesforce/apex/PMC_SS_ApprovalController.getMyPendingApprovals';
import processApprovalRecord from '@salesforce/apex/PMC_SS_ApprovalController.processApprovalRecord';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class Pmc_SS_ApprovalView extends NavigationMixin(LightningElement) {
    @track rows = [];
    @track error;
    @track isLoading = true;
    @track isModalOpen = false;
    @track modalAction; // 'approve' | 'reject'
    @track selectedApprovalId;
    @track commentText = '';
    @track isSaving = false; // true while processing approve/reject

    /**
     * Wires pending approvals for the current user.
     * Maps results to a render-friendly structure and handles errors with toast.
     */
    /** Holds the wire result for refreshApex. */
    wiredApprovalsResult;

    @wire(getMyPendingApprovals)
    wiredApprovals(result) {
        this.wiredApprovalsResult = result;
        const { data, error } = result;
        this.isLoading = false;
        if (data) {
            this.rows = data.map((r) => ({
                id: r.recordId,
                recordId: r.caseId,
                caseNumber: r.caseNumber,
                recordName: r.approvalNumber,
                createdDate: r.createdDate,
                status: r.status,
                caseUrl: '/' + r.caseId,
                recordUrl : '/' + r.recordId
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.rows = [];
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.errorLoadingMessage,
                    message: (error && error.body && error.body.message) ? error.body.message : 'Unknown error',
                    variant: 'error'
                })
            );
        }
    }

    /** Whether there is at least one row to display. */
    get hasData() {
        return this.rows && this.rows.length > 0;
    }

    /** Disables row actions when either loading the list or saving an action. */
    get isBusy() {
        return this.isLoading || this.isSaving;
    }

    /** Disables modal actions while saving. */
    get isModalBusy() {
        return this.isSaving;
    }

    get commentsLabel() {
        return 'Comments';
    }

    get commentsPlaceholder() {
        return 'Enter comments (required)';
    }

    get cancelButtonLabel() {
        return 'Cancel';
    }

    get cardTitle() {
        return 'My Pending Approvals';
    }

    get noDataMessage() {
        return 'No pending approvals.';
    }

    get errorLoadingMessage() {
        return 'Error loading approvals';
    }

    get commentsRequiredTitle() {
        return 'Comments required';
    }

    get commentsRequiredMessage() {
        return 'Please enter comments to proceed.';
    }

    /** Whether comments are required based on the selected action. */
    get isCommentsRequired() {
        return this.modalAction === 'Reject';
    }

    /** Navigates to a record page using the provided data-id attribute. */
    handleOpenRecord(event) {
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    /** Opens the modal and captures the selected approval Id and action. */
    openActionModal(event) {
        this.selectedApprovalId = event.currentTarget.dataset.id; // approval record Id
        this.modalAction = event.currentTarget.dataset.action; // 'approve' | 'reject'
        this.commentText = '';
        this.isModalOpen = true;
    }

    /** Closes the modal and clears its transient state. */
    closeModal() {
        this.isModalOpen = false;
        this.selectedApprovalId = undefined;
        this.modalAction = undefined;
        this.commentText = '';
    }

    /** Tracks comment text input within the modal. */
    handleModalCommentChange(event) {
        this.commentText = event.target.value;
    }

    /**
     * Confirms the Approve/Reject action.
     * - Requires non-empty comments
     * - Calls Apex to update the approval
     * - Refreshes the list and closes the modal
     */
    async confirmModalAction() {
        if (this.isCommentsRequired && (!this.commentText || this.commentText.trim().length === 0)) {
            this.dispatchEvent(new ShowToastEvent({
                title: this.commentsRequiredTitle,
                message: this.commentsRequiredMessage,
                variant: 'warning'
            }));
            return;
        }
        this.isSaving = true;
        this.isLoading = true;
        try {
            await processApprovalRecord({
                approvalId: this.selectedApprovalId,
                isApprove: this.modalAction === 'Approve',
                comments: this.commentText
            });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: `Request ${this.modalAction === 'Approve' ? 'Approved' : 'Rejected'} successfully`,
                variant: 'success'
            }));
            await this.refreshList();
            this.closeModal();
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: (e && e.body && e.body.message) ? e.body.message : 'Failed to process the action',
                variant: 'error'
            }));
        } finally {
            this.isSaving = false;
            this.isLoading = false;
        }
    }

    /**
     * Imperatively refreshes the table by re-querying Apex and remapping results.
     */
    refreshList() {
        // Use refreshApex to reliably refetch cacheable wire data
        return refreshApex(this.wiredApprovalsResult);
    }
}