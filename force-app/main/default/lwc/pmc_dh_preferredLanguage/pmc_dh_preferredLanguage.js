import { LightningElement, track, api } from 'lwc';
import pmc_brandingStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import { NavigationMixin } from 'lightning/navigation';
import { languageReload, urlRedirect, toastMessageHandler } from 'c/pmc_dh_utilityJs';
import updateUserLocale from "@salesforce/apex/PMC_DH_LanguagePreferenceController.updateUserLocale";

import pmc_userDetails_language from '@salesforce/label/c.pmc_userDetails_language';
import pmc_userDetails_preferredLanguage from '@salesforce/label/c.pmc_userDetails_preferredLanguage';
import pmc_userDetails_preferredLanHelptext from '@salesforce/label/c.pmc_userDetails_preferredLanHelptext';

export default class Pmc_dh_preferredLanguage extends NavigationMixin(LightningElement) {
  @track labels = {
    pmc_userDetails_language,
    pmc_userDetails_preferredLanguage,
    pmc_userDetails_preferredLanHelptext
  }
  @track _languageDropdownValues = {};
  @track languageOptions = [];
  @track langKeys = [];
  selectedLanguageOption = "";
  isSpinner = false;
  languageReload;

  iconUrl = `${pmc_brandingStaticResource}/icons/icon-info.svg`;

  /**
   * Fetches language dropdown values from parent comp (pmc_dh_customThemeMyAccount)
   */
  @api
  get languageDropdownValues() {
    return this._languageDropdownValues;
  }
  set languageDropdownValues(value) {
    if (value) {
      this._languageDropdownValues = JSON.parse(JSON.stringify(value));
      this.fetchLanguageList();
    }
  }

  /**
   * Fetches list of languages
   * @function fetchLanguageList
   */
  fetchLanguageList() {
    if (this._languageDropdownValues.lstPreferences) {
      this.languageOptions = JSON.parse(JSON.stringify(this._languageDropdownValues.lstPreferences));
      this.languageOptions.forEach((lang) => {
        lang.untranslatedLabel = lang.label;
        lang.label = lang.transLabel;
      });
      this.selectedLanguageOption = this._languageDropdownValues.strUserLanguage;
      this.langKeys = this._languageDropdownValues.lstUrlLanguage;
    }
  }

  /**
   * Called when user selects a preferred language from the dropdown
   * @function handleDataChange
   * @param {Event} event 
   */
  handleDataChange(event) {
    this.selectedLanguageOption = event.detail.value;
    const selectedLanguage = this.languageOptions.find(item => item.value === this.selectedLanguageOption);
    if (selectedLanguage) {
      this.isSpinner = true;
      updateUserLocale({
        // strLanguage: selectedLanguage.label
        strLanguage: selectedLanguage.untranslatedLabel
      }).then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).statusCodeMessage.strStatusMessage)
          }
          this.langReloadUrl = languageReload(this.langKeys, response.strResultUrl);
          this.navigateUrl(this.langReloadUrl);
        }
        this.isSpinner = false;
      }).catch(() => {
        toastMessageHandler();
        this.isSpinner = false;
      });
    }
  }

  /**
   * Navigation mixin : reloads the page
   * @function navigateUrl
   * @param {string} url 
   */
  navigateUrl(url) {
    this[NavigationMixin.GenerateUrl]({
      type: "standard__webPage",
      attributes: {
        url: url
      }
    }).then((generatedUrl) => {
      urlRedirect(generatedUrl);
    });
  }
}