import { LightningElement, track, wire } from "lwc";
import mosaicLogo from "@salesforce/resourceUrl/mosaicLogo";
import { NavigationMixin } from "lightning/navigation";
// import MD_NAM from "@salesforce/customPermission/MD_NAM";
import MD_NAM_INTRANSIT from "@salesforce/customPermission/MD_NAM_INTRANSIT";
import MD_NAM_CONTRACTREPORT from "@salesforce/customPermission/MD_NAM_CONTRACTREPORT";
import MD_NAM_ORDERREPORT from "@salesforce/customPermission/MD_NAM_ORDERREPORT";

import { publish, MessageContext } from "lightning/messageService";
import ACCOUNT_SELECTION_CHANNEL from "@salesforce/messageChannel/AccountSelectionChannel__c";

import USER_ID from "@salesforce/user/Id";
import { getRecord } from "lightning/uiRecordApi";
import getAccessibleAccountsForUser from "@salesforce/apex/AccountAccessController.getAccessibleAccountsForUser";
import AccountAccessTableModal from "c/accountAccessTable";

const NAME_FIELD = "User.Name";
const PROFILE_NAME_FIELD = "User.Profile.Name";
const READ_ONLY_PROFILE = "Mosaic Direct Partner Community Read Only";

// chaves legado (sem escopo) que já podem existir
const LEGACY_STORAGE_KEYS_TO_TRY = ["mosaic:selectedAccounts", "selectedAccounts", "accountSelections"];
const ALL_ACCOUNTS_KEY = "mosaic:allAccountNames";

export default class MosaicDirectNavBar extends NavigationMixin(LightningElement) {
  @track openSwitchAccountModal = false;
  mosaicLogo = mosaicLogo;
  @track showPlaceOrder = true;
  @track selectedCount = 0;

  userName = '';
  showDropdown = false;
  dropdownTimeout;

  // get hasNewMenu() {
  //   return MD_NAM;
  // }

  get hasIntransitPermission() {
    return MD_NAM_INTRANSIT;
  }

  get hasContractPermission() {
    return MD_NAM_CONTRACTREPORT;
  }

  get hasOrderPermission() {
    return MD_NAM_ORDERREPORT;
  }

  get hasSelected() {
    return this.selectedCount > 0;
  }

  @wire(MessageContext) messageContext;

  @wire(getRecord, { recordId: USER_ID, fields: [NAME_FIELD, PROFILE_NAME_FIELD] })
  wiredUser({ data, error }) {
    if (data) {
      console.log({ data })
      const rel = data.fields?.Profile;
      const profileName = rel?.displayValue || rel?.value?.fields?.Name?.value || "";
      this.userName = data.fields?.Name?.value || '';
      this.showPlaceOrder = profileName !== READ_ONLY_PROFILE;
    } else if (error) {
      console.error("Erro ao obter perfil do usuário:", error);
      this.showPlaceOrder = true;
    }
  }

  connectedCallback() {
    this.initSelection();
  }

  scoped = (k) => `${k}:${USER_ID}`;

  async initSelection() {
    try {
      let names = [];

      // 1) tentar primeiro as chaves ESCOPADAS por usuário
      const scopedCandidates = [this.scoped("mosaic:selectedAccounts")];

      for (const key of [...scopedCandidates, ...LEGACY_STORAGE_KEYS_TO_TRY]) {
        const raw = window.localStorage.getItem(key);
        if (!raw) continue;

        try {
          const parsed = JSON.parse(raw);
          if (Array.isArray(parsed)) {
            names = parsed;
            break;
          }
          if (parsed && Array.isArray(parsed.selectedAccountNames)) {
            names = parsed.selectedAccountNames;
            break;
          }
        } catch {
          const list = raw
            .split(",")
            .map((s) => s.trim())
            .filter(Boolean);
          if (list.length) {
            names = list;
            break;
          }
        }
      }

      // 2) se ainda não tem, tenta ALL_ACCOUNTS escopado e depois legado
      if (!names?.length) {
        const allRaw = window.localStorage.getItem(this.scoped(ALL_ACCOUNTS_KEY)) || window.localStorage.getItem(ALL_ACCOUNTS_KEY);
        if (allRaw) {
          try {
            const allNames = JSON.parse(allRaw);
            if (Array.isArray(allNames) && allNames.length) {
              names = allNames;
            }
          } catch { }
        }
      }

      // 3) fallback absoluto: consulta as contas acessíveis e semeia os storages escopados
      if (!names?.length) {
        const result = await getAccessibleAccountsForUser();
        const allNames = (result || []).map((r) => r.accountName).filter(Boolean);
        if (allNames.length) {
          names = allNames;
          try {
            window.localStorage.setItem(this.scoped(ALL_ACCOUNTS_KEY), JSON.stringify(allNames));
            window.localStorage.setItem(this.scoped("mosaic:selectedAccounts"), JSON.stringify(allNames));
          } catch { }
        }
      }

      if (names?.length) {
        publish(this.messageContext, ACCOUNT_SELECTION_CHANNEL, { selectedAccountNames: names });
      }

      this.selectedCount = Array.isArray(names) ? names.length : 0;

      let keys = [];
      try {
        const rawKeys = window.localStorage.getItem(this.scoped("mosaic:selectedAccountKeys"));
        if (rawKeys) {
          const parsed = JSON.parse(rawKeys);
          if (Array.isArray(parsed)) keys = parsed;
        }
      } catch { }

      if (names?.length) {
        publish(this.messageContext, ACCOUNT_SELECTION_CHANNEL, {
          selectedAccountNames: names,
          selectedAccountKeys: keys
        });
      }
    } catch (e) {
      this.selectedCount = 0;
    }
  }

  handleSwitchAccounts() {
    // this.openSwitchAccountModal = !this.openSwitchAccountModal;
    AccountAccessTableModal.open().then(() => this.initSelection());
  }

  handleAccountsChange(event) {
    const { selectedAccountNames = [], committed = false } = event?.detail || {};
    let names = Array.isArray(selectedAccountNames) ? selectedAccountNames : [];

    this.selectedCount = names.length;

    if (committed) {
      if (!names.length) {
        try {
          const all =
            JSON.parse(localStorage.getItem(this.scoped(ALL_ACCOUNTS_KEY)) || "[]") || JSON.parse(localStorage.getItem(ALL_ACCOUNTS_KEY) || "[]");
          if (Array.isArray(all) && all.length) {
            names = all;
            this.selectedCount = names.length;
          }
        } catch { }
      }

      publish(this.messageContext, ACCOUNT_SELECTION_CHANNEL, { selectedAccountNames: names });
      this.openSwitchAccountModal = false;

      try {
        localStorage.setItem(this.scoped("mosaic:selectedAccounts"), JSON.stringify(names));
      } catch { }
    }
  }

  handleDropdown() {
    this.showDropdown = true;
  }

  closeDropdown() {
    this.dropdownTimeout = setTimeout(() => {
      this.showDropdown = false;
    }, 300);
  }

  cancelLeaveEvent() {
    clearTimeout(this.dropdownTimeout);
  }

  handleLogout() {
    this[NavigationMixin.Navigate]({
      type: "comm__loginPage",
      attributes: {
        actionName: "logout"
      }
    });
  }
}