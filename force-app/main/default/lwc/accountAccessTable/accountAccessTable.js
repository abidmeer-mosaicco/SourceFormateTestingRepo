import { track, wire } from "lwc";
import { publish, MessageContext } from "lightning/messageService";
import LightningModal from 'lightning/modal';
import Toast from "lightning/toast";
import ToastContainer from "lightning/toastContainer";

import getAccessibleAccountsForUser from "@salesforce/apex/AccountAccessController.getAccessibleAccountsForUser";

import ACCOUNT_SELECTION_CHANNEL from "@salesforce/messageChannel/AccountSelectionChannel__c";
import USER_ID from "@salesforce/user/Id";

import md_switchaccount_col1 from '@salesforce/label/c.md_switchaccount_col1';
import md_switchaccount_col2 from '@salesforce/label/c.md_switchaccount_col2';
import md_switchaccount_col3 from '@salesforce/label/c.md_switchaccount_col3';
import md_switchaccount_col4 from '@salesforce/label/c.md_switchaccount_col4';
import md_switchaccount_button1 from '@salesforce/label/c.md_switchaccount_button1';
import md_switchaccount_button2 from '@salesforce/label/c.md_switchaccount_button2';
import md_switchaccount_button3 from '@salesforce/label/c.md_switchaccount_button3';
import md_switchaccount_input_title from '@salesforce/label/c.md_switchaccount_input_title';
import md_switchaccount_title from '@salesforce/label/c.md_switchaccount_title';
import md_switchaccount_errormessage from '@salesforce/label/c.md_switchaccount_errormessage';

const STORAGE_KEYS_KEY = "mosaic:selectedAccountKeys"; // Nome|SAP
const ALL_ACCOUNTS_KEY = "mosaic:allAccountNames";
const SELECTED_ACCOUNTS_KEY = "mosaic:selectedAccounts"; // Nome — lido por md_header.initSelection() e telas md_report

export default class AccountAccessTable extends LightningModal {
  @track accounts = [];
  @track searchTerm = "";
  @wire(MessageContext) messageContext;

  labels = {
    col1: md_switchaccount_col1, // Select
    col2: md_switchaccount_col2, // Account Name
    col3: md_switchaccount_col3, // SAP Customer Number
    col4: md_switchaccount_col4, // Shipping Address
    button1: md_switchaccount_button1, // Select All
    button2: md_switchaccount_button2, // Clear
    button3: md_switchaccount_button3, // Save Access
    input_title: md_switchaccount_input_title, // Search Accounts
    title: md_switchaccount_title, // Select Accounts
    errorMessage: md_switchaccount_errormessage, // It is necessary to have at least one selected account
  };

  get hasSelectedItems() {
    return this.accounts.filter((acc) => acc.selected).length > 0;
  }

  connectedCallback() {
    this.loadAccounts();
  }

  userKey(base) {
    return `${base}:${USER_ID}`;
  }

  selectionKey(name, sap) {
    return `${name || ""}|${sap || ""}`;
  }

  async loadAccounts() {
    try {
      const result = await getAccessibleAccountsForUser();

      const allNames = result.map((r) => r.accountName).filter(Boolean);
      try {
        localStorage.setItem(this.userKey(ALL_ACCOUNTS_KEY), JSON.stringify(allNames));
      } catch { }

      let savedKeys = [];
      try {
        savedKeys = JSON.parse(localStorage.getItem(this.userKey(STORAGE_KEYS_KEY)) || "[]");
        if (!Array.isArray(savedKeys) || !savedKeys.length) {
          const legacy = JSON.parse(localStorage.getItem(STORAGE_KEYS_KEY) || "[]");
          if (Array.isArray(legacy) && legacy.length) {
            savedKeys = legacy;
            try {
              localStorage.setItem(this.userKey(STORAGE_KEYS_KEY), JSON.stringify(legacy));
            } catch { }
          }
        }
      } catch { }

      const hasSaved = Array.isArray(savedKeys) && savedKeys.length > 0;

      this.accounts = result.map((row) => {
        const key = this.selectionKey(row.accountName, row.sapCustomerNumber);
        const selected = hasSaved ? savedKeys.includes(key) : true; // default: tudo selecionado
        return {
          accountId: row.accountId,
          accountName: row.accountName,
          sapCustomerNumber: row.sapCustomerNumber,
          shippingAddress: row.shippingAddress,
          selected,
          _selKey: key
        };
      });

      if (!hasSaved && this.accounts.length > 0) {
        const allKeys = this.accounts.map((a) => a._selKey);
        try {
          localStorage.setItem(this.userKey(STORAGE_KEYS_KEY), JSON.stringify(allKeys));
        } catch { }
      }
      const selectedNow = (this.accounts || [])
        .filter((a) => a.selected)
        .map((a) => a.accountName)
        .filter(Boolean);
      const selectedKeysNow = (this.accounts || []).filter((a) => a.selected).map((a) => a._selKey);

      if (selectedNow.length) {
        publish(this.messageContext, ACCOUNT_SELECTION_CHANNEL, {
          selectedAccountNames: selectedNow,
          selectedAccountKeys: selectedKeysNow // << incluir
        });
      }
      this.dispatchSwitchAccountChangeEvent(selectedNow, allNames);
    } catch (error) {
      console.error("Erro ao carregar contas:", error);
    }
  }

  get filteredAccounts() {
    const term = (this.searchTerm || "").trim().toLowerCase();
    if (!term) return this.accounts;

    return this.accounts.filter((acc) => {
      const name = (acc.accountName || "").toLowerCase();
      const sap = String(acc.sapCustomerNumber || "").toLowerCase();
      const addr = (acc.shippingAddress || "").toLowerCase();
      return name.includes(term) || sap.includes(term) || addr.includes(term);
    });
  }

  handleSearchChange(event) {
    this.searchTerm = event.target.value;
  }

  handleCheckboxChange(event) {
    const id = event.target.dataset.id;
    const checked = event.target.checked;
    this.accounts = this.accounts.map((acc) => (acc.accountId === id ? { ...acc, selected: checked } : acc));
  }

  handleSelectAll() {
    const visibleIds = new Set(this.filteredAccounts.map((acc) => acc.accountId));
    this.accounts = this.accounts.map((acc) => (visibleIds.has(acc.accountId) ? { ...acc, selected: true } : acc));
  }

  handleClearAll() {
    const visibleIds = new Set(this.filteredAccounts.map((acc) => acc.accountId));
    this.accounts = this.accounts.map((acc) => (visibleIds.has(acc.accountId) ? { ...acc, selected: false } : acc));
    const selectedNow = this.accounts.filter((a) => a.selected).map((a) => a.accountName);
    const allNames = this.accounts.map((a) => a.accountName).filter(Boolean);
    this.dispatchSwitchAccountChangeEvent(selectedNow, allNames, false);
  }

  handleSave() {
    const selectedAccounts = this.accounts.filter((acc) => acc.selected);

    if (!selectedAccounts.length) {
      this.showToast({ label: this.labels.title, message: this.labels.errorMessage, variant: "error", mode: "dismissible" });
      return;
    }

    const selectedKeys = selectedAccounts.map((acc) => acc._selKey);
    const selectedNames = selectedAccounts.map((acc) => acc.accountName);
    const selectedIds = selectedAccounts.map((acc) => acc.accountId);
    const allNames = this.accounts.map((a) => a.accountName).filter(Boolean);

    console.log({ selectedKeys, selectedNames, selectedIds, allNames })

    try {
      localStorage.setItem(this.userKey(STORAGE_KEYS_KEY), JSON.stringify(selectedKeys));
      localStorage.setItem(this.userKey(SELECTED_ACCOUNTS_KEY), JSON.stringify(selectedNames));
      localStorage.setItem(this.userKey("mosaic:selectedAccountIds"), JSON.stringify(selectedIds));
    } catch { }

    // Dispatch local event for legacy listeners and include ids for compatibility
    this.dispatchSwitchAccountChangeEvent(selectedNames, allNames, true, selectedIds);

    // Publish via LMS both names and ids to preserve backward compatibility
    publish(this.messageContext, ACCOUNT_SELECTION_CHANNEL, {
      selectedAccountKeys: selectedKeys, // Nome|SAP
      selectedAccountNames: selectedNames,
      selectedAccountIds: selectedIds
    });

    this.close();
  }

  showToast({ label, message, variant = "info", mode = "dismissible", labelLinks, messageLinks, onclose }) {
    Toast.show({ label, message, variant, mode, labelLinks, messageLinks, onclose }, this);
  }

  dispatchSwitchAccountChangeEvent(selectedNames, allNames, committed = false, selectedIds = []) {
    this.dispatchEvent(
      new CustomEvent("accountschange", {
        detail: {
          selectedAccountNames: selectedNames, // <<< por NOME
          allAccountNames: allNames,
          selectedAccountIds: selectedIds,
          committed
        },
        bubbles: true,
        composed: true
      })
    );
  }
}