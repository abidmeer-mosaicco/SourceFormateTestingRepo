import { LightningElement, api, track } from 'lwc';
import getQuoteShares from '@salesforce/apex/QuoteSharingController.getQuoteShares';
import shareQuote from '@salesforce/apex/QuoteSharingController.shareQuote';
import updateAccessLevels from '@salesforce/apex/QuoteSharingController.updateAccessLevels';
import removeQuoteShare from '@salesforce/apex/QuoteSharingController.removeQuoteShare';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class QuoteShareModal extends LightningElement {
    _recordId;
    @track sharedUsers = [];
    @track sharedCount = 0;
    @track selectedUserIds = [];
    @track accessLevel = 'Read';
    @track editMode = false;
    @track filterText = '';

    accessOptions = [
        { label: 'Read Only', value: 'Read' },
        { label: 'Read/Write', value: 'Edit' }
    ];

    @api
    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.loadSharedUsers();
        }
    }

    get recordId() {
        return this._recordId;
    }

    get shareCountMessage() {
        if (this.sharedCount === 0) return 'Shared with 0 group of users.';
        if (this.sharedCount === 1) return 'Shared with 1 group of users.';
        return `Shared with ${this.sharedCount} groups of users.`;
    }

    get editButtonLabel() {
        return this.editMode ? 'Close' : 'Edit';
    }

    get filteredShares() {
        if (!this.filterText) return this.sharedUsers;
        return this.sharedUsers.filter(u =>
            (u.name || '').toLowerCase().includes(this.filterText.toLowerCase())
        );
    }

    get disableShare() {
        return !this.selectedUserIds || this.selectedUserIds.length === 0 || !this.accessLevel;
    }

    loadSharedUsers() {
        if (!this.recordId) return;

        getQuoteShares({ quoteId: this.recordId })
            .then(result => {
                this.sharedUsers = result.map(share => ({
                    id: share.id,
                    name: share.name,
                    type: share.type,
                    accessLevel: share.accessLevel === 'Edit' ? 'Edit' : 'Read'
                }));
                this.sharedCount = this.sharedUsers.length;
            })
            .catch(error => {
                console.error('Error loading shares:', error);
                this.sharedUsers = [];
                this.sharedCount = 0;
            });
    }

    handleUserSelected(event) {
        this.selectedUserIds = event.detail.userIds;
    }

    handleAccessChange(event) {
        this.accessLevel = event.detail.value;
    }

    handleFilterChange(event) {
        this.filterText = event.detail.value;
    }

    handleInlineAccessChange(event) {
        const shareId = event.target.dataset.id;
        const newAccess = event.detail.value;

        this.sharedUsers = this.sharedUsers.map(user => {
            if (user.id === shareId) {
                return { ...user, accessLevel: newAccess };
            }
            return user;
        });
    }

    handleShare() {
        if (!this.selectedUserIds || this.selectedUserIds.length === 0 || !this.accessLevel) {
            this.showToast('Error', 'Please select at least one user and an access level', 'error');
            return;
        }
         
        const promises = this.selectedUserIds.map(userId =>
            shareQuote({
                quoteId: this.recordId,
                userOrGroupId: userId,
                accessLevel: this.accessLevel 
            })
        );

        Promise.all(promises)
            .then(() => {
                this.showToast('Success', 'Quote shared successfully', 'success');
                this.selectedUserIds = [];
                this.accessLevel = 'Read';

               // this.loadSharedUsers();
               return this.loadSharedUsers();
            })
            .then(() => {
           
            this.sharedCount = this.sharedUsers.length;
        })
            .catch(error => {
                console.error('Error sharing quote:', error);
                this.showToast('Error', 'Error sharing quote', 'error');
            });
    }

    handleSave() {
        const updates = this.sharedUsers.map(user => ({
            id: user.id,
           // accessLevel: user.accessLevel
            accessLevel: user.accessLevel
        }));

        updateAccessLevels({ updates })
            .then(() => {
                this.showToast('Success', 'Access levels updated', 'success');
                 // this.editMode = false;
                this.loadSharedUsers();
            })
            .then(() => {
           
            this.editMode = false;
        })
            .catch(error => {
                console.error('Save error', error);
                this.showToast('Error', 'Failed to update access levels', 'error');
            });
    }

    handleRemoveShare(event) {
        const shareId = event.currentTarget.dataset.id;

        removeQuoteShare({ shareId })
            .then(() => {
                this.sharedUsers = this.sharedUsers.filter(user => user.id !== shareId);
                this.sharedCount = this.sharedUsers.length;
                this.showToast('Success', 'Share removed', 'success');
            })
            .catch(error => {
                console.error('Error removing share:', error);
                this.showToast('Error', 'Error removing share', 'error');
            });
    }

    toggleEditShares() {
        this.editMode = !this.editMode;
        if (this.editMode) {
            this.loadSharedUsers();
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}