import { LightningElement, api, track } from "lwc";
import { formatLabel } from "c/pmc_dh_utilityJs";
import { handleError } from "c/pmc_dh_utilityJs";
import BrandingAssets from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import basePath from "@salesforce/community/basePath";
import isContactEmailPresent from "@salesforce/apex/PMC_DH_RegistrationUtils.isContactEmailPresent";
import { formatPhoneNumber, unFormatPhoneNumber, toastMessageHandler } from "c/pmc_dh_utilityJs";

import pmc_registration_firstName from "@salesforce/label/c.pmc_registration_firstName";
import pmc_registration_registerTitle from "@salesforce/label/c.pmc_registration_registerTitle";
import pmc_registration_lastName from "@salesforce/label/c.pmc_registration_lastName";
import pmc_registration_workEmail from "@salesforce/label/c.pmc_registration_workEmail";
import pmc_registration_industry from "@salesforce/label/c.pmc_registration_industry";
import pmc_registration_countryCode from "@salesforce/label/c.pmc_registration_countryCode";
import pmc_registration_telephone from "@salesforce/label/c.pmc_registration_telephone";
import pmc_registration_state from "@salesforce/label/c.pmc_registration_state";
import pmc_registration_city from "@salesforce/label/c.pmc_registration_city";
import pmc_registration_agreeCommunications from "@salesforce/label/c.pmc_registration_agreeCommunications";
import pmc_registration_privacyPolicyRegistration from "@salesforce/label/c.pmc_registration_privacyPolicyRegistration";
import pmc_registration_proceed from "@salesforce/label/c.pmc_registration_proceed";
import pmc_registration_backToLogin from "@salesforce/label/c.pmc_registration_backToLogin";
import pmc_userDetails_validPhoneNumber from "@salesforce/label/c.pmc_userDetails_validPhoneNumber";
import pmc_registration_cpf from "@salesforce/label/c.pmc_registration_cpf";
import pmc_registration_cpfPlaceholder from "@salesforce/label/c.pmc_registration_cpfPlaceholder";
import pmc_userDetails_country from "@salesforce/label/c.pmc_userDetails_country";

const BRAZIL = 'Brazil';

export default class Pmc_dh_registration extends LightningElement {
  @track _picklistData = [];
  @api
  get picklistData() {
    return this._picklistData;
  }
  set picklistData(value) {
    if (value) {
      this._picklistData = value;
      this.onlyUnique(this._picklistData);
    }
  }

  @api
  get counrtyCodeData() {
    return this.countryCodeOption;
  }
  set counrtyCodeData(value) {
    if (value) {
      this.countryCodeOption = value;
    }
  }

  @track pageObject = {};
  @track labels = {
    pmc_registration_firstName,
    pmc_registration_lastName,
    pmc_registration_workEmail,
    pmc_registration_industry,
    pmc_registration_countryCode,
    pmc_registration_telephone,
    pmc_registration_state,
    pmc_registration_city,
    pmc_registration_agreeCommunications,
    pmc_registration_privacyPolicyRegistration,
    pmc_registration_proceed,
    pmc_registration_backToLogin,
    pmc_registration_registerTitle,
    pmc_userDetails_validPhoneNumber,
    pmc_registration_cpf,
    pmc_registration_cpfPlaceholder,
    pmc_userDetails_country
  };
  @track stateOptions = [];
  @track countryOption = [];
  @track countryCodeOption = [];
  @track phoneMaxLength = "10";

  closeIconUrl = `${BrandingAssets}/icons/close.svg`;
  errorIconUrl = `${BrandingAssets}/icons/icon-error.svg`;
  errorMessage;
  isCpf = false;
  isLoading = false;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    let baseUrl = window.location.origin;
    let loginUrl = `${baseUrl}${basePath}/login`;
    this.labels.pmc_registration_backToLogin = formatLabel(
      this.labels.pmc_registration_backToLogin,
      [loginUrl]
    );
  }

  uniqueSet = new Set();

  /** 
   * get an array with unique values: 
   * @function onlyUnique
   * @param {Array} data 
   */
  onlyUnique(data) {
    data.forEach((item) => {
      const key = item.Country_Name__c + item.Country_Name__c;
      if (!this.uniqueSet.has(key)) {
        this.uniqueSet.add(key);
        this.countryOption.push({
          label: item.Country_Name__c,
          value: item.Country_Name__c
        });
      }
    });
  }

  /** 
   * Update pageObject for input field change
   * @function handleDataChange
   * @param {Event} event 
   */
  handleDataChange(event) {
    if (event.target.dataset.id === "strMarketingEmailConsent") {
      this.pageObject.strMarketingEmailConsent = event.target.value;
    } else {
      if (
        event.detail.value !== "undefined" &&
        event.detail.value !== null &&
        event.target &&
        event.target.dataset
      ) {
        this.pageObject[event.target.dataset.id] = event.detail.value.trim();
      }
      if (this.pageObject.strCountry) {
        this.stateOptions = this._picklistData
          .filter(
            (state) => state.Country_Name__c === this.pageObject.strCountry
          )
          .map((el) => {
            return {
              label: el.State__c,
              value: el.State__c
            };
          });
      }
      if (event.target.dataset.id === "strEmail") {
        this.template.querySelector('[data-id="strEmail"]').errorMsg = [""];
      }
      if (event.target.dataset.id === "strCountryCode") {
        this.pageObject.strPhoneNumber = null;
        this.checkPhoneNumberMaxLength();
      }
      if (event.target.dataset.id === "strCountry") {
        if(this.pageObject.strState) {
          this.pageObject.strState = null;
        }
        if (this.pageObject.strCountry === BRAZIL) {
          this.isCpf = true;
        }
        else {
          this.isCpf = false;
          delete this.pageObject?.strBrazilCpf;
        }
      }
    }
  }

  /**
   * To update the max length of phone number field
   * @function checkPhoneNumberMaxLength
   */
  checkPhoneNumberMaxLength = () => {
    const BRAZIL_CODE = "BR +55";
    this.phoneMaxLength =
      this.pageObject.strCountryCode === BRAZIL_CODE ? "11" : "10";
  };

  /**
   * Mask for phone number on Blur
   * @function handleDataBlur
   */
  handleDataBlur() {
    if (
      this.pageObject.strPhoneNumber !== undefined &&
      this.pageObject.strPhoneNumber !== null
    ) {
      this.pageObject.strPhoneNumber = formatPhoneNumber(
        this.pageObject.strPhoneNumber,
        this.pageObject.strCountryCode
      );
      this.validateMobileNumber(
        unFormatPhoneNumber(this.pageObject.strPhoneNumber)
      );
    }
  }

  /**
   * Unmask phone number on focus
   * @function handleInputFocus
   */
  handleInputFocus() {
    if (this.pageObject.strPhoneNumber) {
      this.pageObject.strPhoneNumber = unFormatPhoneNumber(
        this.pageObject.strPhoneNumber
      );
    }
  }

  /**
   * On Blur Validate Phone Number & Show Error Message
   * @function validateMobileNumber
   */
  validateMobileNumber = (value) => {
    if (value.length !== 10 && value.length !== 11) {
      this.template.querySelector('[data-id="strPhoneNumber"]').errorMsg = [
        this.labels.pmc_userDetails_validPhoneNumber
      ];
    } else {
      this.template.querySelector('[data-id="strPhoneNumber"]').errorMsg = [""];
    }
  };

  /** 
   * Send registration data on click of proceed button
   * @function proceedButtonHandler
   */
  proceedButtonHandler() {
    if (
      this.pageObject.strPhoneNumber !== undefined &&
      this.pageObject.strPhoneNumber !== null
    ) {
      this.pageObject.strPhoneNumber = unFormatPhoneNumber(
        this.pageObject.strPhoneNumber
      );
    }
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(() => {
      if (this.handleErrorOnSave()) return;
      let userinfo = {
        strEmail: this.pageObject.strEmail,
        strPhoneNumber: this.pageObject.strPhoneNumber,
        strLastName: this.pageObject.strLastName,
        strCountryCode: this.pageObject.strCountryCode
      };
      this.isLoading = true;
      isContactEmailPresent({
        userinfo: userinfo
      })
        .then((data) => {
          if (data && Object.keys(data).length) {
            if (JSON.parse(JSON.stringify(data)).strStatusMessage) {
              this.errorMessage = handleError(
                JSON.parse(JSON.stringify(data)).strStatusMessage
              );
            } else {
              if (!this.pageObject.strMarketingEmailConsent)
                this.pageObject.strMarketingEmailConsent = false;
              this.dispatchEvent(
                new CustomEvent("proceedbuttonclick", {
                  detail: {
                    value: "isAccountInformation",
                    data: this.pageObject
                  }
                })
              );
            }
          }
          this.isLoading = false;
        })
        .catch(() => {
          toastMessageHandler();
          this.isLoading = false;
        });
    });
  }

  /** 
   * Handle error on proceed button click 
   * @function handleErrorOnSave
   */
  handleErrorOnSave() {
    let allValid = true;
    let focusRef;
    this.template.querySelectorAll(`[data-id]`).forEach((inputComponent) => {
      if (!inputComponent.reportValidity()) {
        allValid = false;
        if (!focusRef) focusRef = inputComponent;
      }
    });
    if (!allValid) {
      focusRef.focus();
      focusRef.scrollIntoView({ behavior: "smooth", block: "center" });
      return true;
    }
    return false;
  }

  get strStateDisabled() {
    return !this.pageObject.strCountry;
  }

  /**
   * Disable phone number field until user selects country code
   * @function phoneStrDisabled
   * @returns {boolean}
   */
  get phoneStrDisabled() {
    return !this.pageObject.strCountryCode;
  }
}