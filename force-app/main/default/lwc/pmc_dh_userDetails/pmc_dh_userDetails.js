import { LightningElement, track } from "lwc";
import { handleError } from "c/pmc_dh_utilityJs";
import BrandingAssets from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import { formatPhoneNumber, unFormatPhoneNumber, toastMessageHandler } from "c/pmc_dh_utilityJs";
import getUserInfo from "@salesforce/apex/PMC_DH_UserInfoController.getUserInfo";
import updateUserInfo from "@salesforce/apex/PMC_DH_UserInfoController.updateUserInfo";

import pmc_userDetails_userInformation from "@salesforce/label/c.pmc_userDetails_userInformation";
import pmc_userDetails_firstName from "@salesforce/label/c.pmc_userDetails_firstName";
import pmc_userDetails_lastName from "@salesforce/label/c.pmc_userDetails_lastName";
import pmc_userDetails_email from "@salesforce/label/c.pmc_userDetails_email";
import pmc_userDetails_country from "@salesforce/label/c.pmc_userDetails_country";
import pmc_userDetails_phone from "@salesforce/label/c.pmc_userDetails_phone";
import pmc_userDetails_dateOfBirth from "@salesforce/label/c.pmc_userDetails_dateOfBirth";
import pmc_userDetails_edit from "@salesforce/label/c.pmc_userDetails_edit";
import pmc_userDetails_countryCode from "@salesforce/label/c.pmc_userDetails_countryCode";
import pmc_registration_countryCode from "@salesforce/label/c.pmc_registration_countryCode";
import pmc_userDetails_validPhoneNumber from "@salesforce/label/c.pmc_userDetails_validPhoneNumber";
import pmc_userDetails_saveChanges from "@salesforce/label/c.pmc_userDetails_saveChanges";
import pmc_userDetails_saveUserDetails from "@salesforce/label/c.pmc_userDetails_saveUserDetails";
import pmc_editUserInfo_text from "@salesforce/label/c.pmc_editUserInfo_text";

/**
 * A custom LWC for view/edit user details.
 * @alias Pmc_dh_userDetails
 * @extends LightningElement
 * @hideconstructor
 * @author Hemant Soni
 * @example
 * <c-pmc_dh_user-details></c-pmc_dh_user-details>
 */

export default class Pmc_dh_userDetails extends LightningElement {
  @track labels = {
    pmc_userDetails_userInformation,
    pmc_userDetails_firstName,
    pmc_userDetails_lastName,
    pmc_userDetails_email,
    pmc_userDetails_country,
    pmc_userDetails_phone,
    pmc_userDetails_dateOfBirth,
    pmc_userDetails_edit,
    pmc_userDetails_countryCode,
    pmc_registration_countryCode,
    pmc_userDetails_validPhoneNumber,
    pmc_userDetails_saveChanges,
    pmc_userDetails_saveUserDetails,
    pmc_editUserInfo_text
  };

  @track editableInfoObj = {};
  @track userInfoObj = {};
  @track countryCodeOption = [];
  _phoneStrDisabled = true;
  _apexError;
  phoneMaxLength = "10";
  isEditUserInfoModal = false;
  errorIconUrl = `${BrandingAssets}/icons/icon-error.svg`;
  errorMessage;
  isSpinner = true;

  connectedCallback() {
    this.fetchUserDetails();
  }

  /**
   * Fetch user details
   * @function fetchUserDetails
   */
  fetchUserDetails() {
    getUserInfo()
      .then((data) => {
        if (data && Object.keys(JSON.parse(data)).length) {
          this.userInfoObj = JSON.parse(data);
          if (this.userInfoObj.statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(this.userInfoObj.statusCodeMessage.strStatusMessage)
          }
          if (
            this.userInfoObj.strContactPhone !== null &&
            this.userInfoObj.strCountryCode !== null
          ) {
            this.userInfoObj.strContactPhone = `${this.userInfoObj.strCountryCode.replace(
              /[a-zA-Z]/g,
              ""
            )} ${formatPhoneNumber(
              this.userInfoObj.strContactPhone,
              this.userInfoObj.strCountryCode
            )}`;
          }
          this.countryCodeOption = [
            ...this.userInfoObj.countryCodePhoneFormat.lstCountryCode
          ].map((option) => {
            return { label: option.label, value: option.value };
          });
        }
        this.isSpinner = false;
      })
      .catch((error) => {
        toastMessageHandler();
        this._apexError = error;
        this.isSpinner = false;
      });
  }

  /**
   * Update user details (Last Name and Phone)
   * @function updateUserDetails
   */
  updateUserDetails() {
    this.isSpinner = true;
    updateUserInfo({
      strLastName: this.editableInfoObj.lastNameStr,
      strPhoneCode: this.editableInfoObj.userEnteredCountryStr,
      strPhoneNumber: this.editableInfoObj.userEnteredPhoneStr
    })
      .then((data) => {
        if (JSON.parse(data).statusCodeMessage?.strStatusMessage) {
          this.errorMessage = handleError(
            JSON.parse(data).statusCodeMessage.strStatusMessage
          );
        } else {
          this.showUserInfo(data);
        }
        this.isSpinner = false;
      })
      .catch((error) => {
        toastMessageHandler();
        this.isSpinner = false;
        this._apexError = error;
      });
  }

  /**
   * save/update user info when user has updated new details
   * @function showUserInfo
   * @param {object} data
   */
  showUserInfo = (data) => {
    if (data) {
      this.userInfoObj = JSON.parse(data);
    }
    this.userInfoObj.strContactPhone = `${this.userInfoObj.strCountryCode.replace(
      /[a-zA-Z]/g,
      ""
    )} ${formatPhoneNumber(
      this.userInfoObj.strContactPhone,
      this.userInfoObj.strCountryCode
    )}`;
    this.handleCloseEditPopUp();
  };

  /**
   * Reset all the input fields of the edit form
   * @function resetForm
   *
   */
  resetForm() {
    this.template.querySelectorAll(`[data-id]`).forEach((inputComponent) => {
      inputComponent.resetInput();
    });
    this.errorMessage = "";
  }

  /**
   * Close the Edit Modal
   * @function handleCloseEditPopUp
   */
  handleCloseEditPopUp() {
    this.isEditUserInfoModal = false;
    this._phoneStrDisabled = true;
    this.resetForm();
  }

  /**
   * Open the Edit Modal
   * @function editUserInfoModal
   */
  editUserInfoModal() {
    this.isEditUserInfoModal = true;
    this.template.querySelectorAll(`[data-id]`).forEach((inputComponent) => {
      inputComponent.updateIsRequired();
    });
  }

  /**
   * Assign edited value to 'editableInfoObj'
   * @function handleDataChange
   * @param {Event} event
   */
  handleDataChange(event) {
    if (
      event.detail.value !== "undefined" &&
      event.target &&
      event.target.dataset
    ) {
      this.editableInfoObj[event.target.dataset.id] = event.detail.value;
    }
    if (event.target.dataset.id === "userEnteredCountryStr") {
      this._phoneStrDisabled = false;
      this.editableInfoObj.userEnteredPhoneStr = null;
      this.checkPhoneNumberMaxLength();
    }
  }

  /**
   * To update the max length of phone number field
   * @function checkPhoneNumberMaxLength
   */
  checkPhoneNumberMaxLength = () => {
    const BRAZIL_CODE = "BR +55";
    this.phoneMaxLength =
      this.editableInfoObj.userEnteredCountryStr === BRAZIL_CODE ? "11" : "10";
  };

  /**
   * Mask for phone number on Blur
   * @function handleDataBlur
   */
  handleDataBlur() {
    if (
      this.editableInfoObj.userEnteredPhoneStr !== undefined &&
      this.editableInfoObj.userEnteredPhoneStr !== null
    ) {
      this.editableInfoObj.userEnteredPhoneStr = formatPhoneNumber(
        this.editableInfoObj.userEnteredPhoneStr,
        this.editableInfoObj.userEnteredCountryStr
      );
      this.validateMobileNumber(
        unFormatPhoneNumber(this.editableInfoObj.userEnteredPhoneStr)
      );
    }
  }

  /**
   * Unmask phone number on focus
   * @function handleInputFocus
   */
  handleInputFocus() {
    if (this.editableInfoObj.userEnteredPhoneStr) {
      this.editableInfoObj.userEnteredPhoneStr = unFormatPhoneNumber(
        this.editableInfoObj.userEnteredPhoneStr
      );
    }
  }

  /**
   * On Blur Validate Phone Number & Show Error Message
   * @function validateMobileNumber
   * @param {string} value
   */
  validateMobileNumber = (value) => {
    const MIN_LENGTH = 10;
    const MAX_LENGTH = 11;
    if (value.length !== MIN_LENGTH && value.length !== MAX_LENGTH) {
      this.template.querySelector('[data-id="userEnteredPhoneStr"]').errorMsg =
        [this.labels.pmc_userDetails_validPhoneNumber];
    } else {
      this.template.querySelector('[data-id="userEnteredPhoneStr"]').errorMsg =
        [""];
    }
  };

  /**
   * Function called on click of Save Changes to save updated data or throw error if any
   * @function saveChangesHandler
   */
  saveChangesHandler() {
    if (
      this.editableInfoObj.userEnteredPhoneStr !== undefined &&
      this.editableInfoObj.userEnteredPhoneStr !== null
    ) {
      this.editableInfoObj.userEnteredPhoneStr = unFormatPhoneNumber(
        this.editableInfoObj.userEnteredPhoneStr
      );
    }
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(() => {
      if (this.handleErrorOnSave()) return;
      this.updateUserDetails();
    });
  }

  /**
   * Edit User Info Form error handling
   * @function handleErrorOnSave
   * @returns {boolean} - true in case of error, false otherwise
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
}