import { LightningElement, track, api, wire } from "lwc";
import userId from "@salesforce/user/Id";
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { languageReload, fireEvent, toastMessageHandler } from 'c/pmc_dh_utilityJs';
import { urlRedirect } from 'c/pmc_dh_utilityJs';

import getLanguagePreferences from "@salesforce/apex/PMC_DH_LanguagePreferenceController.getLanguagePreferences";
import updateUserLocale from "@salesforce/apex/PMC_DH_LanguagePreferenceController.updateUserLocale";

/**
 * A custom LWC to select language preference.
 * @alias Pmc_dh_languageDropdown
 * @extends LightningElement
 * @hideconstructor
 * @author Vanshika
 * @example
 * <c-pmc_dh_language-dropdown></c-pmc_dh_language-dropdown>
 */

export default class Pmc_dh_languageDropdown extends NavigationMixin(LightningElement) {
  userId = userId;
  isGuestUser;
  showDropdown = false;
  isSpinner = false;
  selectedLanguageOption;
  langReloadUrl;
  error;
  _handler;

  @track _langPrefData = {};
  @track languageOptions = [];
  @track langKeys = [];

  @api
  get langPrefData() {
    return this._langPrefData;
  }
  set langPrefData(value) {
    if (value) {
      this._langPrefData = JSON.parse(JSON.stringify(value));
      this.fetchLanguageList();
    }
  }

  @wire(CurrentPageReference) pageRef;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    this.isGuestUser = !this.userId ? true : false;
    document.addEventListener('click', this._handler = this.close.bind(this));
    if(this.isGuestUser) {
      this.fetchLanguageList();
    }
  }

  /** 
   * Hide language dropdown when a click occurs outside of it.
   * @function ignore
   * @param {Event} event 
   */
  ignore(event) {
    event.stopPropagation();
    return false;
  }

  /**
   * Closes the language dropdown menu
   * @function close
   */
  close() {
    this.showDropdown = false;
  }

  /**
   * Fetches list of languages
   * @function fetchLanguageList
   */
  fetchLanguageList() {
    if (!this.isGuestUser) {
      if (this._langPrefData.lstPreferences) {
        this.languageOptions = JSON.parse(JSON.stringify(this._langPrefData.lstPreferences));
        this.selectedLanguageOption = this._langPrefData.strUserLanguage;
        this.langKeys = this._langPrefData.lstUrlLanguage;
        let pathname = window.location.pathname;
        let urlKey = this.languageOptions.find(lang => lang.value === this.selectedLanguageOption).key;
        let otherLanguages = this.langKeys.filter(e => e !== 'en-US');
        if ((urlKey !== "en-US" && !(pathname.includes("/" + urlKey)))) {
          this.langReloadUrl = languageReload(this.langKeys, urlKey);
          this.navigateUrl(this.langReloadUrl);
        } else if (urlKey === "en-US") {
          for (let item of otherLanguages) {
            if (pathname.includes("/" + item) && item !== urlKey) {
              this.langReloadUrl = languageReload(this.langKeys, urlKey);
              this.navigateUrl(this.langReloadUrl);
            }
          }
        }
      }
    } else {
      this.isSpinner = true;
      getLanguagePreferences()
        .then((response) => {
          if (response && Object.keys(response).length) {
            if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusMessage) {
              toastMessageHandler(JSON.parse(JSON.stringify(response)).statusCodeMessage.strStatusMessage)
            }
            this.languageOptions = JSON.parse(JSON.stringify(response.lstPreferences));
            this.langKeys = response.lstUrlLanguage;
            let count = 0;
            let pathname = window.location.pathname;
            for (let item of this.langKeys) {
              if (pathname.includes("/" + item)) {
                this.selectedLanguageOption = this.languageOptions.find(lang => lang.key === item).value;
                count++;
              }
              if (count === 0) {
                this.selectedLanguageOption = response.strUserLanguage;
              }
            }
            fireEvent(this.pageRef, "selectedLanguage", { 'languageOptions': this.languageOptions, 'selectedLanguageOption': this.selectedLanguageOption });
          }
          this.isSpinner = false;
        }).catch((error) => {
          toastMessageHandler();
          this.isSpinner = false;
          this.error = error;
        })
    }
  }

  /**
   * called when user selects a preferred language from the dropdown
   * @function changeHandler
   * @param {Event} event 
   */
  changeHandler(event) {
    event.preventDefault();
    event.stopPropagation();
    this.selectedLanguageOption = event.target.dataset.id;
    this.isSpinner = true;
    const selectedLanguageLabel = this.languageOptions.find(item => item.value === this.selectedLanguageOption).label;
    if (!this.isGuestUser) {
      updateUserLocale({
        strLanguage: selectedLanguageLabel
      }).then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).statusCodeMessage.strStatusMessage)
          }
          this.setLanguageSelection(this.selectedLanguageOption);
          this.langReloadUrl = languageReload(this.langKeys, response.strResultUrl);
          this.navigateUrl(this.langReloadUrl);
        }
        this.isSpinner = false;
      }).catch(() => {
        toastMessageHandler();
        this.isSpinner = false;
      })
    } else {
      let selectedKey = this.languageOptions.find(item => item.value === this.selectedLanguageOption).key;
      this.guestUserLangSelection(selectedKey);
    }
    this.showDropdown = false;
  }

  /**
   * Sets the language selected in session storage
   * @function setLanguageSelection
   * @param {string} selectedLanguageOption 
   */
  setLanguageSelection(selectedLanguageOption) {
    let headerDetails = JSON.parse(sessionStorage.getItem('HEADER_DETAILS'));
    headerDetails.langPrefeWrapper.strUserLanguage = selectedLanguageOption;
    sessionStorage.setItem('HEADER_DETAILS', JSON.stringify(headerDetails));
  }

  /**
   * Reloads page for guest users
   * @function guestUserLangSelection
   * @param {String} Key 
   */
  guestUserLangSelection(Key) {
    this.langReloadUrl = languageReload(this.langKeys, Key);
    this.navigateUrl(this.langReloadUrl);
  }

  /**
   * Navigation mixin : reloads the page
   * @function navigateUrl
   * @param {String} url
   */
  navigateUrl(url) {
    this[NavigationMixin.GenerateUrl]({
      type: "standard__webPage",
      attributes: {
        url: url
      }
    }).then((generatedUrl) => {
      // window.location.href = generatedUrl;
      urlRedirect(generatedUrl);
      // Week1 Feb 2024: urlReirect method is resulting continuous page reload in only dev enrionemnt. 
      // Kept original window.location.href for temporary fix.
    });
  }

  /**
   * Shows and hides the dropdown
   * @function toggleDropdown
   * @param {Event} event 
   */
  toggleDropdown(event) {
    if (this.showDropdown) {
      event.stopPropagation();
    }
    clearTimeout(this.clickTimer);
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.clickTimer = setTimeout(() => {
      this.showDropdown = !this.showDropdown;
    }, 500);
  }

  /**
   * Toggles dropdown on enter key
   * @function handleDropdownKeyPress
   * @param {Event} event 
   */
  handleDropdownKeyPress(event) {
    if (event.keyCode === 13) {
      this.toggleDropdown();
    } else if (event.keyCode === 9) {
      if (event.shiftKey) {
        this.showDropdown = false;
        return;
      }
      event.preventDefault();
      this.template.querySelectorAll(".lang")[0]?.focus();
      this.showDropdown = true;
    }
  }

  /**
   * Selects language on enter key
   * @function handleKeyPress
   * @param {Event} event 
   */
  handleKeyPress(event) {
    event.stopPropagation();
    if (event.keyCode === 13) {
      this.changeHandler(event);
    } else if (event.keyCode === 9) {
      const langItems = this.template.querySelectorAll(".lang");
      if (
        !event.shiftKey &&
        event.target.dataset.id === langItems[langItems.length - 1].dataset.id
      ) {
        this.showDropdown = false;
      }
    }
  }

  /**
   * Lifecycle Hook
   */
  disconnectedCallback() {
    document.removeEventListener('click', this._handler);
  }
}