import { LightningElement, api, track, wire } from "lwc";
import { urlRedirect } from 'c/pmc_dh_utilityJs';
import getAccountForModal from "@salesforce/apex/PMC_DH_AccountSwitcherController.getAccountForModal";
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import communityId from "@salesforce/community/Id";
import { NavigationMixin } from "lightning/navigation";
import pmc_searchBar_currentAccountText from "@salesforce/label/c.pmc_searchBar_currentAccountText";
import pmc_accountDetails_switchAccounts from "@salesforce/label/c.pmc_accountDetails_switchAccounts";
import pmc_accountDetails_searchAccLbl from "@salesforce/label/c.pmc_accountDetails_searchAccLbl";
import pmc_accountDetails_searchAccTitle from "@salesforce/label/c.pmc_accountDetails_searchAccTitle";


import { toastMessageHandler } from "c/pmc_dh_utilityJs";
import { publish, MessageContext } from 'lightning/messageService';
import USER_ID from '@salesforce/user/Id';
import ACCOUNT_SELECTION_CHANNEL from '@salesforce/messageChannel/AccountSelectionChannel__c';

export default class Pmc_dh_switchAccountModal extends NavigationMixin(LightningElement) {
  @wire(MessageContext) messageContext;
  isSpinner = false;
  currentAccountSessionId = "";
  modalWidth = "700px";
  _isShowSwitchAccountModal = false;
  error;

  @api
  get openSwitchAccountModal() {
    return this._isShowSwitchAccountModal;
  }
  set openSwitchAccountModal(value) {
    this._isShowSwitchAccountModal = value;
    if (value) {
      this.currentAccountSessionId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
      this.getAccountForModal(this.currentAccountSessionId);
    }
  }
  @track searchInput = '';
  @track filteredAccounts = [];
  @track cloneAccArray = [];
  @track iconUrlObj = {
    newAccountUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-account.svg`,
    infoIconUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-info.svg`
  };
  @track labels = {
    pmc_accountDetails_switchAccounts,
    pmc_accountDetails_searchAccLbl,
    pmc_accountDetails_searchAccTitle
  };

  /**
   * Backend Method to get Account Details inside Switch Account Modal
   * @function getAccountForModal
   * @param {String} currentUserSessionStorageID -  User's EFFECTIVE_ACCOUNT_ID from Session Storage
   */
  getAccountForModal = (currentUserSessionStorageID) => {
    this.isSpinner = true;
    getAccountForModal({
      strEffectiveAccountId: currentUserSessionStorageID,
      strCommunityId: communityId
    })
      .then((result) => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
          }
          if (JSON.parse(result.strAccountData).length) {
            this.cloneAccArray = JSON.parse(result.strAccountData).map((el) => {
              // const address = `${el.strStreet}, ${el.strCity}, ${el.strState} ${el.strZip} ${el.strCountry} ${el.strStateTaxNumber}.`;
              let addressArr = [];
              el.strStreet && addressArr.push(el.strStreet);
              el.strCity && addressArr.push(el.strCity);
              el.strState && addressArr.push(el.strState);
              el.strZip && addressArr.push(el.strZip);
              el.strCountry && addressArr.push(el.strCountry);
              el.strStateTaxNumber && addressArr.push(el.strStateTaxNumber);
              let address = '';
              address = addressArr.join(', ');
              address = addressArr.length > 0 ? address + '.' : '';
              return {
                ...el,
                strCompleteAddress: address
              };
            });
            this.filteredAccounts = JSON.parse(JSON.stringify(this.cloneAccArray));
            this.formateAccounts(currentUserSessionStorageID);
          }
        }
        this.isSpinner = false;
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
      });
  };

  formateAccounts = (currentUserSessionStorageID) => {
    // To find the account that matches the current user's accountID and sessionID
    const currentUserAccount = this.filteredAccounts.find(
      (acc) => acc.strAccountId === currentUserSessionStorageID
    );
    // to update strAccountName if the current user's account matches
    let text = ` (${pmc_searchBar_currentAccountText})`
    if (currentUserAccount && !currentUserAccount.strAccountName.includes(text)) {
      currentUserAccount.strAccountName += text;
    }
  }

  /**
   * Persistir e publicar seleção de contas usando IDs (normaliza escrita em várias chaves
   * e publica via Message Channel e evento window). Mantém compatibilidade com outros consumidores
   * que aguardam keys como `mosaic:selectedAccounts` ou `mosaic:selectedAccountIds`.
   * @param {Array<string>} ids
   */
  /**
   * Persistir e publicar seleção: grava legacy `mosaic:selectedAccounts` com nomes (se fornecidas)
   * e grava `mosaic:selectedAccountIds` com ids. Publica via LMS ambos os campos quando disponíveis.
   * @param {Array<string>} ids
   * @param {Array<string>} names
   */
  publishSelectedAccountsById(ids, names) {
    if (!Array.isArray(ids)) ids = (ids ? [ids] : []);
    if (!Array.isArray(names)) names = (names ? [names] : []);
    const normalizedIds = ids.map((i) => String(i)).filter((s) => s && s.trim());
    const normalizedNames = names.map((n) => String(n)).filter((s) => s && s.trim());
    try {
      // gravar nomes (legado) para compatibilidade com consumidores que esperam names
      if (normalizedNames.length) {
        const serialNames = JSON.stringify(normalizedNames);
        try { localStorage.setItem('mosaic:selectedAccounts', serialNames); } catch (e) { }
        try { sessionStorage.setItem('mosaic:selectedAccounts', serialNames); } catch (e) { }
        try { localStorage.setItem(`mosaic:selectedAccounts:${USER_ID}`, serialNames); } catch (e) { }
        try { sessionStorage.setItem(`mosaic:selectedAccounts:${USER_ID}`, serialNames); } catch (e) { }
      }

      if (normalizedIds.length) {
        const serialIds = JSON.stringify(normalizedIds);
        try { localStorage.setItem('mosaic:selectedAccountIds', serialIds); } catch (e) { }
        try { sessionStorage.setItem('mosaic:selectedAccountIds', serialIds); } catch (e) { }
        try { localStorage.setItem(`mosaic:selectedAccountIds:${USER_ID}`, serialIds); } catch (e) { }
        try { sessionStorage.setItem(`mosaic:selectedAccountIds:${USER_ID}`, serialIds); } catch (e) { }
      }
    } catch (e) {
      // ignore storage errors
    }

    try {
      const payload = {};
      if (normalizedIds.length) payload.selectedAccountIds = normalizedIds;
      if (normalizedNames.length) payload.selectedAccountNames = normalizedNames;
      if (this.messageContext && typeof publish === 'function' && Object.keys(payload).length) {
        console.debug('[pmc_dh_switchAccountModal] publishing selection to MessageChannel:', payload);
        publish(this.messageContext, ACCOUNT_SELECTION_CHANNEL, payload);
      }
    } catch (e) {
      // ignore publishing errors
    }
  }


  /**
   * To Navigate Home Page on Account Selection Click
   * @function switchAccountHandler
   * @param {Event} event
   */
  switchAccountHandler = (event) => {
    let SS = sessionStorage;
    let LS = localStorage;
    const homePageUrl = "/";
    const dataAccId = event.target.closest("li").dataset.accId;
    const dataAccName = event.target.closest("li").dataset.accName.split(" (")[0];
    SS.setItem("EFFECTIVE_ACCOUNT_ID", dataAccId);
    SS.setItem("EFFECTIVE_ACCOUNT_NAME", dataAccName);
    LS.setItem("EFFECTIVE_ACCOUNT_ID", dataAccId);
    LS.setItem("EFFECTIVE_ACCOUNT_NAME", dataAccName);
  // também grava a chave esperada pelo mosaic list e publica via MessageChannel (garantir IDs/names)
  this.publishSelectedAccountsById([dataAccId], [dataAccName]);
    // Dispatch a fallback custom event for components that listen on window
    try {
      // Dispatch a fallback custom event for components that listen on window
      // Validate dataAccId looks like a Salesforce Id (15 or 18 chars, alphanumeric)
      if (dataAccId && (dataAccId.length === 15 || dataAccId.length === 18) && /^[a-zA-Z0-9]+$/.test(dataAccId)) {
        const detail = { selectedAccountIds: [dataAccId] };
        // DEBUG: dispatcha evento de fallback no window
        console.debug('[pmc_dh_switchAccountModal] dispatching window mosaic:accountSelectionChanged', detail);
        window.dispatchEvent(new CustomEvent('mosaic:accountSelectionChanged', { detail }));
      }
    } catch (e) {
      // noop: do not break existing behavior if dispatch fails
    }
    // To Close the Switch Modal and then navigate to Home Page.
    this.isShowSwitchAccountModal = false;
    this._isShowSwitchAccountModal = false;
    this[NavigationMixin.GenerateUrl]({
      type: "standard__webPage",
      attributes: {
        url: homePageUrl
      }
    }).then((generatedUrl) => {
      urlRedirect(generatedUrl);
    });
  };

  /** 
   * Key Press for Account Selection in Switch Account Modal
   * @function switchAccountKeypressHandler
   * @param {Event} event
   */
  switchAccountKeypressHandler = (event) => {
    if (event.keyCode === 13) {
      event.preventDefault();
      this.switchAccountHandler(event);
    }
  };

  /**
   * Close Switch Account Modal
   * @function closeSwitchAccountModal
   */
  closeSwitchAccountModal() {
    this.dispatchEvent(new CustomEvent("closeswitchaccount"));
    this._isShowSwitchAccountModal = false;
    this.searchInput = '';
  }

  /** 
   * Set the value of searchInput on input change 
   * @function handleDataChange
   * @param {Event} event 
   * */
  handleDataChange(event) {
    if(event.detail.value !== "undefined") {
      this.searchInput = event.detail.value.trim();
    }
  }

  /** 
   * Handle Enter Key press on search imput
   * @function handleEnterKeyUp
   * @param {Event} event 
   * */
  handleEnterKeyUp() {
    this.searchHandler();
  }

  /**
   * Search Accounts 
   * @function searchHandler
   * */
  searchHandler() {
    if(this.searchInput.length > 2) {
      this.filteredAccounts = this.cloneAccArray.filter((acc) => 
        (acc.strCompleteAddress.toLowerCase()).includes(this.searchInput.toLowerCase()) || (acc.strAccountName.toLowerCase()).includes(this.searchInput.toLowerCase())
      );
    }
    else {
      this.filteredAccounts = JSON.parse(JSON.stringify(this.cloneAccArray));
    }
    this.formateAccounts(this.currentAccountSessionId);
  }
}