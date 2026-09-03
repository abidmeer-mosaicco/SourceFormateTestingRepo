import { LightningElement, track, wire } from "lwc";
import pmc_brandingStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import { formatPhoneNumber, unFormatPhoneNumber, handleError, fireEvent, toastMessageHandler } from "c/pmc_dh_utilityJs";
import userId from "@salesforce/user/Id";
import { CurrentPageReference } from "lightning/navigation";

import getModalDetails from "@salesforce/apex/PMC_DH_UserInfoController.getModalDetails";
import createNewUserWithoutApproval from "@salesforce/apex/PMC_DH_UserInfoController.createNewUserWithoutApproval";

import pmc_userDetails_firstName from "@salesforce/label/c.pmc_userDetails_firstName";
import pmc_userDetails_lastName from "@salesforce/label/c.pmc_userDetails_lastName";
import pmc_addNewUser_userEmail from "@salesforce/label/c.pmc_addNewUser_userEmail";
import pmc_userDetails_countryCode from "@salesforce/label/c.pmc_userDetails_countryCode";
import pmc_userDetails_userPhone from "@salesforce/label/c.pmc_userDetails_userPhone";
import pmc_addNewUser_userType from "@salesforce/label/c.pmc_addNewUser_userType";
import pmc_addNewUser_soldToAccount from "@salesforce/label/c.pmc_addNewUser_soldToAccount";
import pmc_addNewUser_title from "@salesforce/label/c.pmc_addNewUser_title";
import pmc_userDetails_validPhoneNumber from "@salesforce/label/c.pmc_userDetails_validPhoneNumber";
import pmc_addNewUser_emailErrorMsg from "@salesforce/label/c.pmc_addNewUser_emailErrorMsg";

/**
 * A custom LWC for adding new user.
 * @alias Pmc_dh_addNewUser
 * @extends LightningElement
 * @hideconstructor
 * @author Vanshika
 *
 * @example
 * <c-pmc_dh_add-new-user></c-pmc_dh_add-new-user>
 */

export default class Pmc_dh_addNewUser extends LightningElement {
  buttonUrl = `${pmc_brandingStaticResource}/icons/icon-add-user.svg`;
  @track isAddNewUser = false;
  @track isMouseOver = false;
  @track _phoneStrDisabled = true;
  @track pageObject = {
    strCountry: "United States",
    strState: "",
    strCity: "Texas"
  };
  @track picklistOptions = {};
  @track phoneMaxLength = "10";
  errorMessage;
  currentUserId = userId;
  isLoading = false;
  error;

  /**
   * Label Details
   */
  @track labels = {
    pmc_userDetails_firstName,
    pmc_userDetails_lastName,
    pmc_addNewUser_userEmail,
    pmc_userDetails_countryCode,
    pmc_userDetails_userPhone,
    pmc_addNewUser_userType,
    pmc_addNewUser_soldToAccount,
    pmc_addNewUser_title,
    pmc_userDetails_validPhoneNumber,
    pmc_addNewUser_emailErrorMsg
  };

  /**
   * Calling pageref
   */
  @wire(CurrentPageReference) pageRef;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    this.loadPicklistDetails();
  }

  /**
   * Fetch Picklist Values
   * @function loadPicklistDetails
   */
  loadPicklistDetails() {
    this.isLoading = true;
    getModalDetails({
      strcurrentUserId: this.currentUserId
    })
      .then((result) => {
        if (result && Object.keys(result).length) {
          let parsedResult = JSON.parse(result);
          this.picklistOptions = parsedResult;
          if (parsedResult.statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(parsedResult.statusCodeMessage.strStatusMessage)
          }
        }
        this.isLoading = false
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isLoading = false
      });
  }

  /**
   * On input change event handler
   * @function handleDataChange
   * @param {event} event
   */
  handleDataChange(event) {
    if (event.detail.value !== "undefined" && event.target && event.target.dataset) {
      this.pageObject[event.target.dataset.id] =
        event.target.type === "text" ? event.detail.value.trim() : event.detail.value;
    }
    if (event.target.dataset.id === "strEmail") {
      this.template.querySelector('[data-id="strEmail"]').errorMsg = [''];
    }
    if (event.target.dataset.id === "strCountryCode") {
      this._phoneStrDisabled = false;
      this.pageObject.strPhoneNumber = "";
      this.checkPhoneNumberMaxLength();
    }
  }

  /**
   * Saving the data on 'Add New User' button click
   * @function addUserHandler
   */
  addUserHandler() {
    if (this.pageObject.strPhoneNumber !== undefined && this.pageObject.strPhoneNumber !== null) {
      this.pageObject.strPhoneNumber = unFormatPhoneNumber(this.pageObject.strPhoneNumber);
    }
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(() => {
      if (this.handleErrorOnSave()) return;
      this.isLoading = true;
      createNewUserWithoutApproval({
        userInfoData: this.pageObject
      })
        .then((result) => {
          if (result && Object.keys(result).length) {
            if (result.strStatusMessage) {
              this.errorMessage = handleError(result.strStatusMessage);
            } else {
              fireEvent(this.pageRef, "newUserDetails", this.pageObject);
              this.handleCloseNewUserModal();
            }
          }
          this.isLoading = false
        })
        .catch((err) => {
          toastMessageHandler();
          this.error = err;
          this.isLoading = false
        });
    });
  }

  /**
   * Mask for phone number on Blur
   * @function handleDataBlur
   * @param {event} event
   */
  handleDataBlur(event) {
    switch (event.target.dataset.id) {
      case "strPhoneNumber":
        if (this.pageObject.strPhoneNumber) {
          this.handleDataChange(event);
          this.pageObject.strPhoneNumber = formatPhoneNumber(this.pageObject.strPhoneNumber, this.pageObject.strCountryCode);
          this.validateMobileNumber(unFormatPhoneNumber(this.pageObject.strPhoneNumber));
        }
        break;
      case "strEmail":
        if (this.pageObject.strEmail) {
          const inputValue = event.detail.value;
          const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
          if (!emailRegex.test(inputValue)) {
            this.template.querySelector('[data-id="strEmail"]').errorMsg = [this.labels.pmc_addNewUser_emailErrorMsg];
          } else {
            this.template.querySelector('[data-id="strEmail"]').errorMsg = [''];
          }
          event.target.reportValidity();
        }
        break;
      default:
        break;
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
   * To update the max length of phone number field
   * @function checkPhoneNumberMaxLength
   */
  checkPhoneNumberMaxLength = () => {
    const BRAZIL_CODE = "BR +55";
    this.phoneMaxLength =
      this.pageObject.strCountryCode === BRAZIL_CODE ? "11" : "10";
  };

  /**
   * Validating Phone Number length
   * @function checkPhoneNumberMaxLength
   * @param {string} value
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
   * Reset all the input fields of the new user form
   * @function clearForm
   */
  clearForm() {
    this.template.querySelectorAll(`[data-id]`).forEach((inputComponent) => {
      inputComponent.resetInput();
    });
    this.errorMessage = "";
  }

  /**
   * Form fields validation
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

  /**
   * Modal open handler
   * @function openNewUserModal
   */
  openNewUserModal() {
    this.isAddNewUser = !this.isAddNewUser;
    this.template.querySelectorAll(`[data-id]`).forEach((inputComponent) => {
      inputComponent.updateIsRequired();
    });
  }

  /**
   * Modal close handler
   * @function handleCloseNewUserModal
   */
  handleCloseNewUserModal() {
    this.isAddNewUser = !this.isAddNewUser;
    this.clearForm();
    this._phoneStrDisabled = true;
  }

  /**
   * Modal accessibility handler
   * @function handleIconKeyDown
   * @param {event} event
   */
  handleIconKeyDown(event) {
    if (event.keyCode === 13) {
      this.openNewUserModal();
    }
  }

  /**
   * Mouse over Icon Handler
   * @function handleMouseEnter
   */
  handleMouseEnter() {
    this.isMouseOver = true;
  }

  /**
   * Mouse Leave Handler
   * @function handleMouseLeave
   */
  handleMouseLeave() {
    this.isMouseOver = false;
  }
}