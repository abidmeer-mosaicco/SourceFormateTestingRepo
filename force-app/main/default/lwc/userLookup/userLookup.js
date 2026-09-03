import { LightningElement, track } from 'lwc';
import searchUsers from '@salesforce/apex/UserLookupController.searchUsers';

export default class UserLookup extends LightningElement {
  @track searchKey = '';
  @track userList = [];
  @track selectedUsers = [];
  @track isLoading = false;

  timeout;
  DEBOUNCE_DELAY = 300;

  get hasSelectedUsers() {
    return this.selectedUsers.length > 0;
  }

  get isDropdownOpen() {
    return this.userList.length > 0 && this.searchKey.length >= 2;
  }

  get computedComboboxClass() {
    return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${
      this.isDropdownOpen ? 'slds-is-open' : ''
    }`;
  }

  handleInputChange(event) {
    this.searchKey = event.detail.value;
    clearTimeout(this.timeout);

    if (this.searchKey.length >= 2) {
      this.isLoading = true;

      this.timeout = setTimeout(() => {
        searchUsers({ searchKey: this.searchKey })
          .then((result) => {
            const selectedIds = new Set(this.selectedUsers.map((u) => u.id));
            this.userList = result.filter((user) => !selectedIds.has(user.Id));
          })
          .catch((error) => {
            console.error('Search error:', error);
            this.userList = [];
          })
          .finally(() => {
            this.isLoading = false;
          });
      }, this.DEBOUNCE_DELAY);
    } else {
      this.userList = [];
      this.isLoading = false;
    }
  }

  handleSelect(event) {
    const userId = event.currentTarget.dataset.id;
    const userName = event.currentTarget.dataset.name;

    // Add to selected users
    this.selectedUsers = [...this.selectedUsers, { id: userId, name: userName }];

    // Set selected user's name as searchKey to preserve in the input
    this.searchKey = '';

    // Clear dropdown
    this.userList = [];

    this.dispatchSelectedUsers();
  }

  handleRemoveUser(event) {
    const userIdToRemove = event.currentTarget.dataset.id;
    this.selectedUsers = this.selectedUsers.filter((user) => user.id !== userIdToRemove);

    // If removed user was shown in input, clear it
    if (this.searchKey && this.selectedUsers.every(u => u.name !== this.searchKey)) {
      this.searchKey = '';
    }

    this.dispatchSelectedUsers();
  }

  dispatchSelectedUsers() {
    this.dispatchEvent(
      new CustomEvent('usersselected', {
        detail: { userIds: this.selectedUsers.map((u) => u.id) }
      })
    );
  }
}