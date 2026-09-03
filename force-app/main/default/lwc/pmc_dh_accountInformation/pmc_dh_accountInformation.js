import { LightningElement, track } from "lwc";
import { toastMessageHandler } from 'c/pmc_dh_utilityJs';
import isAccountInfoValid from '@salesforce/apex/PMC_DH_RegistrationUtils.isAccountInfoValid';

import pmc_registration_accountInvoice from "@salesforce/label/c.pmc_registration_accountInvoice";
import pmc_registration_number from "@salesforce/label/c.pmc_registration_number";
import pmc_registration_accountManagerEmail from "@salesforce/label/c.pmc_registration_accountManagerEmail";
import pmc_registration_existingAccount from "@salesforce/label/c.pmc_registration_existingAccount";
import pmc_registration_proceed from "@salesforce/label/c.pmc_registration_proceed";
import pmc_registration_accountInfoTitle from "@salesforce/label/c.pmc_registration_accountInfoTitle";
import pmc_registration_account from "@salesforce/label/c.pmc_registration_account";
import pmc_registration_invoice from "@salesforce/label/c.pmc_registration_invoice";
import pmc_registration_accountError from "@salesforce/label/c.pmc_registration_accountError";

export default class Pmc_dh_accountInformation extends LightningElement {
  @track labels = {
    pmc_registration_accountInvoice,
    pmc_registration_number,
    pmc_registration_accountManagerEmail,
    pmc_registration_existingAccount,
    pmc_registration_proceed,
    pmc_registration_accountInfoTitle,
    pmc_registration_account,
    pmc_registration_invoice,
    pmc_registration_accountError
  };
  @track options = [
    { label: this.labels.pmc_registration_account, value: this.labels.pmc_registration_account },
    { label: this.labels.pmc_registration_invoice, value: this.labels.pmc_registration_invoice },
  ];
  @track pageObject = {};
  showErrorMessage = false;
  isLoading = false;
  error;

  /** 
   * Update pageObject with the value entered by user for every field 
   * @function handleDataChange
   * @param {event} event
   */
  handleDataChange(event) {
    if (
      event.detail.value !== "undefined" &&
      event.target &&
      event.target.dataset
    ) {
      this.pageObject[event.target.dataset.id] = event.detail.value;
      if (event.target.dataset.id === 'strAccountNumber') {
        this.template.querySelector('c-pmc_dh_input-element').errorMsg = [];
      }
    }
  }

  /**
   * Call isAccountInfoValid method and show error message or move to next screen based on response from BE 
   * @function handleProceed
   */
  handleProceed() {
    if (this.handleErrorOnSave()) return;
    this.isLoading = true;
    isAccountInfoValid({
      accNumber: this.pageObject.strAccountNumber,
      managerEmailId: this.pageObject.managerEmailId
    })
      .then(result => {
        if (result) {
          this.dispatchEvent(
            new CustomEvent("proceedbuttonclick", {
              detail: {
                value: "isDigitalHubProfile",
                data: this.pageObject
              }
            })
          );
        } else {
          this.showErrorMessage = true;
        }
        this.isLoading = false
      })
      .catch(error => {
        toastMessageHandler();
        this.error = error
        this.isLoading = false
      })
  }

  /** 
   * Validate input field 
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
}