import { LightningElement, wire } from "lwc";
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import { getRecord } from "lightning/uiRecordApi";
import { publish, MessageContext } from "lightning/messageService";

import USER_ID from "@salesforce/user/Id";
import AccountAccessTableModal from "c/accountAccessTable";
import ACCOUNT_SELECTION_CHANNEL from "@salesforce/messageChannel/AccountSelectionChannel__c";
import getAccessibleAccountsForUser from "@salesforce/apex/AccountAccessController.getAccessibleAccountsForUser";
import mosaicLogo from "@salesforce/resourceUrl/mosaicLogo";

import md_switchaccount_totalaccounts from '@salesforce/label/c.md_switchaccount_totalaccounts';
import md_switchaccount from '@salesforce/label/c.md_switchaccount';

const NAME_FIELD = "User.Name";

const STORAGE_KEYS = {
    selectedAccounts: "mosaic:selectedAccounts",
    selectedAccountKeys: "mosaic:selectedAccountKeys",
    allAccountNames: "mosaic:allAccountNames"
};

const LEGACY_STORAGE_KEYS = ["mosaic:selectedAccounts", "selectedAccounts", "accountSelections"];

export default class MdHeader extends NavigationMixin(LightningElement) {
    mosaicLogo = mosaicLogo;
    selectedCount = 0;
    userName = "";
    showDropdown = false;
    isHome = false;

    #dropdownTimeout;

    labels = {
        md_switchaccount_totalaccounts,
        md_switchaccount,
    };

    get hasSelected() {
        return this.selectedCount > 0;
    }

    get showSwitchAccounts() {
        return !this.isHome;
    }

    @wire(MessageContext) messageContext;

    @wire(CurrentPageReference)
    pageRef(reference) {
        if (!reference) return;

        let pageName = reference.attributes?.name;
        let path = window.location.pathname.toLowerCase();

        this.isHome = (pageName === 'Home' || path.endsWith('/home') || path.endsWith('/s/') || path === '/');
    }

    @wire(getRecord, { recordId: USER_ID, fields: [NAME_FIELD] })
    wiredUser({ data, error }) {
        if (error) console.error("Erro ao obter nome do usuário:", error);
        if (!data) return;

        this.userName = data.fields?.Name?.value || "";
    }

    connectedCallback() {
        this.initSelection();
    }

    scoped(key) {
        return `${key}:${USER_ID}`;
    }

    _parseNames(raw) {
        try {
            let parsed = JSON.parse(raw);
            if (Array.isArray(parsed)) return parsed;
            if (parsed?.selectedAccountNames && Array.isArray(parsed.selectedAccountNames)) return parsed.selectedAccountNames;
        } catch {
            let list = raw.split(",").map((s) => s.trim()).filter(Boolean);
            if (list.length) return list;
        }

        return null;
    }

    _getFromStorage(keys) {
        for (const key of keys) {
            let raw = window.localStorage.getItem(key);
            if (!raw) continue;

            let names = this._parseNames(raw);
            if (names?.length) return names;
        }

        return null;
    }

    _publishSelection(names, keys = []) {
        setTimeout(() => {
            publish(this.messageContext, ACCOUNT_SELECTION_CHANNEL, {
                selectedAccountNames: names,
                ...(keys.length && { selectedAccountKeys: keys })
            });
        }, 0);
    }

    async initSelection() {
        try {
            let names = this._getFromStorage([this.scoped(STORAGE_KEYS.selectedAccounts), ...LEGACY_STORAGE_KEYS])
                || this._getFromStorage([this.scoped(STORAGE_KEYS.allAccountNames), STORAGE_KEYS.allAccountNames]);

            if (!names?.length) {
                const result = await getAccessibleAccountsForUser();
                let allNames = (result || []).map((r) => r.accountName).filter(Boolean);

                if (!allNames.length) {
                    this.selectedCount = 0;
                    return;
                }

                names = allNames;

                try {
                    window.localStorage.setItem(this.scoped(STORAGE_KEYS.allAccountNames), JSON.stringify(allNames));
                    window.localStorage.setItem(this.scoped(STORAGE_KEYS.selectedAccounts), JSON.stringify(allNames));
                } catch (e) {
                    console.warn("localStorage indisponível/cheio", e);
                }
            }

            let keys = [];

            try {
                const rawKeys = window.localStorage.getItem(this.scoped(STORAGE_KEYS.selectedAccountKeys));
                keys = rawKeys ? JSON.parse(rawKeys) : [];

                if (!Array.isArray(keys)) keys = [];
            } catch (e) {
                console.warn("Erro ao ler chaves do localStorage", e);
            }

            this.selectedCount = keys.length > 0 ? keys.length : (Array.isArray(names) ? names.length : 0);
            if (this.selectedCount === 0) return;

            this._publishSelection(names, keys);
        } catch (e) {
            console.error("Erro ao inicializar seleção de contas:", e);
            this.selectedCount = 0;
        }
    }

    handleSwitchAccounts() {
        AccountAccessTableModal.open().then(() => this.initSelection());
    }

    handleDropdown() {
        this.showDropdown = true;
    }

    closeDropdown() {
        this.#dropdownTimeout = setTimeout(() => {
            this.showDropdown = false;
        }, 300);
    }

    cancelLeaveEvent() {
        clearTimeout(this.#dropdownTimeout);
    }

    handleLogout() {
        this[NavigationMixin.Navigate]({
            type: "comm__loginPage",
            attributes: { actionName: "logout" }
        });
    }
}