import { LightningElement, track } from 'lwc';
import BrandingAssets from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import { registerListener, unregisterAllListeners, toastMessageHandler } from "c/pmc_dh_utilityJs";

import getUserRegistationDetails from '@salesforce/apex/PMC_DH_RegistrationUtils.getUserRegistationDetails';
import registerUser from '@salesforce/apex/PMC_DH_RegistrationController.registerUser';

export default class Pmc_dh_registrationFlow extends LightningElement {
  bgUrl = BrandingAssets + "/images/background.jpg";
  pageLoaded = false;
  pageRendered = false;
  userSelectedPreference;

  @track registrationWidgetHandler = {
    isRegistration: true,
    isAccountInformation: false,
    isDigitalHubProfile: false,
    isThankYouForRegistration: false,
  }

  @track regsitrationDetails = {};
  @track saveObject = {};
  isLoading = false;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    this.getUserRegistationDetails();
    registerListener("selectedLanguage", this.handleLanguage, this);
  }

  /**
   * Fetching selected user language from header
   * @function handleLanguage
   * @param {Array} selectedLang 
   */
  handleLanguage(selectedLang) {
    if (selectedLang) {
      let langOptions = JSON.parse(JSON.stringify(selectedLang.languageOptions));
      this.userSelectedPreference = langOptions.find(item => item.value === selectedLang.selectedLanguageOption).label;
    }
  }

  /**
   * Lifecycle Hook
   */
  disconnectedCallback() {
    unregisterAllListeners(this);
  }

  /** 
   * Fetch user registration details 
   * @function getUserRegistationDetails
   */
  getUserRegistationDetails() {
    this.isLoading = true;
    getUserRegistationDetails()
      .then(result => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(result).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(result).statusCodeMessage.strStatusMessage)
          }
          if (result) {
            this.regsitrationDetails = JSON.parse(result);
            this.pageLoaded = true;
          }
        }
        this.isLoading = false;
      })
      .catch(() => {
        toastMessageHandler();
        this.isLoading = false;
      })
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (this.pageRendered) return;
    let element = this.template.querySelector(".bgContainer");
    element.style = `background-image:url(${this.bgUrl})`;
    this.pageRendered = true;
  }

  /** 
   * Save user registration details on click of proceed button from Digital hub profile page 
   * @function proceedButtonHandler
   * @param {Event} event 
   */
  proceedButtonHandler(event) {
    this.saveObject = { ...this.saveObject, ...event.detail.data };
    this.saveObject.strLanguage = this.userSelectedPreference;
    if (event.detail.value !== 'isThankYouForRegistration') {
      Object.keys(this.registrationWidgetHandler).forEach(el => {
        this.registrationWidgetHandler[el] = false;
      });
      this.registrationWidgetHandler[event.detail.value] = true;
    } else {
      delete this.saveObject.managerEmailId;
      delete this.saveObject.validationType;
      this.isLoading = true;
      registerUser({
        strRegistrationInfo: JSON.stringify(this.saveObject)
      })
        .then((result) => {
          if (result && Object.keys(result).length) {
            if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
              toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
            }
            if (result.boolRegistrationStatus) {
              Object.keys(this.registrationWidgetHandler).forEach(el => {
                this.registrationWidgetHandler[el] = false;
              });
              this.registrationWidgetHandler[event.detail.value] = true;
            }
          }
          this.isLoading = false;
        })
        .catch(() => {
          toastMessageHandler();
          this.isLoading = false;
        })
    }
  }
}