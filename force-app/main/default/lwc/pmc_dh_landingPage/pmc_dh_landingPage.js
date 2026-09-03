import { LightningElement, track } from 'lwc';
import basePath from '@salesforce/community/basePath';
import { formatLabel, registerListener, unregisterAllListeners, toastMessageHandler } from 'c/pmc_dh_utilityJs';
import getLandingPageData from '@salesforce/apex/PMC_DH_GuestLandingPageController.getLandingPageData';

import pmc_login_text from "@salesforce/label/c.pmc_login_text";
import pmc_landingPage_needHelp from "@salesforce/label/c.pmc_landingPage_needHelp";
import pmc_landingPage_supportText from "@salesforce/label/c.pmc_landingPage_supportText";

/**
 * A custom LWC to view landing page.
 * @alias Pmc_dh_landingPage
 * @extends LightningElement
 * @hideconstructor
 * @author Vanshika
 * @example
 * <c-pmc_dh_landing-page></c-pmc_dh_landing-page>
 */

export default class Pmc_dh_landingPage extends LightningElement {
  isContentVisible = true;
  isLoginHidden = true;
  supporturl;
  bgUrl;
  error;
  userSelectedPreference;
  isSpinner = true;
  @track bannerDetails = {};
  @track iconDetails = [];

  /**
   * Custom labels
   */
  @track labels = {
    pmc_login_text,
    pmc_landingPage_needHelp,
    pmc_landingPage_supportText
  }

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    this.supporturl = `${basePath}/contactus`;
    this.labels.pmc_landingPage_supportText = formatLabel(this.labels.pmc_landingPage_supportText, [this.supporturl]);
    registerListener("selectedLanguage", this.handleLanguage, this);
  }

  /**
   * Fetching the user selected language
   * @function handleLanguage
   * @param {Array} selectedLang 
   */
  handleLanguage(selectedLang) {
    if (selectedLang) {
      let langOptions = JSON.parse(JSON.stringify(selectedLang.languageOptions));
      this.userSelectedPreference = langOptions.find(item => item.value === selectedLang.selectedLanguageOption).label;
      this.fetchLandingPageDetails();
    }
  }

  /**
   * Lifecycle Hook
   */
  disconnectedCallback() {
    unregisterAllListeners(this);
  }

  /**
   * Fetching the data for Landing Page
   * @function fetchLandingPageDetails
   */
  fetchLandingPageDetails() {
    getLandingPageData({
      strLanguage: this.userSelectedPreference
    }).then((response) => {
      if (response && Object.keys(response).length) {
        if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(response)).statusCodeMessage.strStatusMessage)
        }
        this.bannerDetails = JSON.parse(JSON.stringify(response.heroBannerDetail));
        this.iconDetails = JSON.parse(JSON.stringify(response.lstIconDetail));
        this.updateLandingPageData();
      }
      this.isSpinner = false;
    }).catch((error) => {
      toastMessageHandler();
      this.error = error;
      this.isSpinner = false;
    })
  }

  /**
   * Updating data for background image and icons
   * @function updateLandingPageData
   */
  updateLandingPageData() {
    this.bgUrl = this.bannerDetails.imageUrl;
    let element = this.template.querySelector(".bgContainer .login-section");
    element.style = `background-image:url(${this.bgUrl})`;
    this.iconDetails.sort((a, b) => {
      return a.intSequence - b.intSequence
    });
  }

  /**
   * Shows login widget in mobile resolution
   * @function toggleLogin
   */
  toggleLogin() {
    this.isContentVisible = false;
    this.isLoginHidden = false;
  }
}