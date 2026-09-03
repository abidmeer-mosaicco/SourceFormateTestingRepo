import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { urlRedirect, toastMessageHandler } from 'c/pmc_dh_utilityJs';
import basePath from '@salesforce/community/basePath';
import createNewUser from '@salesforce/apex/PMC_DH_ContactUtils.createNewUser';

import pmc_userDetails_firstName from "@salesforce/label/c.pmc_userDetails_firstName";
import pmc_userDetails_lastName from "@salesforce/label/c.pmc_userDetails_lastName";
import pmc_userDetails_email from "@salesforce/label/c.pmc_userDetails_email";
import pmc_addNewUser_phoneNumber from "@salesforce/label/c.pmc_addNewUser_phoneNumber";
import pmc_addNewUser_userType from "@salesforce/label/c.pmc_addNewUser_userType";
import pmc_addNewUser_title from "@salesforce/label/c.pmc_addNewUser_title";

/**
 * A custom LWC to add new user.
 * @alias Pmc_dh_addNewUserPrefilled
 * @extends LightningElement
 * @hideconstructor
 * @author Vanshika, Raghu Mothukapally
 *
 * @example
 * <c-pmc_dh_add-new-user-prefilled></c-pmc_dh_add-new-user-prefilled>
 */

export default class Pmc_dh_addNewUserPrefilled extends NavigationMixin(LightningElement) {
  queryString = window.location.search;
  @track userData = {}
  @track pageObject = {};
  isSpinner = false;
  isAddNewUserModal = false;

  /**
   * labels details
   */
  @track labels = {
    pmc_userDetails_firstName,
    pmc_userDetails_lastName,
    pmc_userDetails_email,
    pmc_addNewUser_phoneNumber,
    pmc_addNewUser_userType,
    pmc_addNewUser_title
  }

  /**
   * Modal control exposed
   * @function showModal
   */
  @api
  showModal() {
    this.isAddNewUserModal = !this.isAddNewUserModal;
  }

  /**
   * set Modal data
   * @function setModalData
   * @param {object} data
   */
  @api
  setModalData(data) {
    this.userData = { ...data };
  }

  /** 
   * Lifecycle Hook 
   */
  connectedCallback() {
    this.queryParamsHandler();
  }

  /**
   * Modal close handler
   * @function handleCloseNewUserModal
   */
  handleCloseNewUserModal() {
    this.isAddNewUserModal = !this.isAddNewUserModal;
  }

  /**
   * Modal open handler
   * @function openNewUserModal
   */
  openNewUserModal() {
    this.isAddNewUserModal = !this.isAddNewUserModal;
  }

  /**
   * On input change event handler
   * @function handleDataChange
   * @param {event} event
   */
  handleDataChange(event) {
    if (event.detail.value !== 'undefined' && event.target && event.target.dataset) {
      this.pageObject.roleLabel = event.detail.value;
    }
  }

  /**
   * On button click event handler
   * @function addNewUserHandler
   */
  addNewUserHandler() {
    if (this.handleErrorOnSave()) return;
    this.createNewUserHandler();
  }

  /**
   * Form fields validation
   * @function handleErrorOnSave
   */
  handleErrorOnSave() {
    let allValid = true;
    let focusRef;
    this.template.querySelectorAll(`[data-id]`).forEach(inputComponent => {
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
   * Reading query params
   * @function queryParamsHandler
   */
  queryParamsHandler() {
    if (this.queryString) {
      let params = new URLSearchParams(this.queryString);
      this.pageObject.emailId = params.get('email');
    }
  }

  /**
   * Create new user with apex method
   * @function createNewUserHandler
   */
  createNewUserHandler() {
    this.isSpinner = true;
    createNewUser({
      emailId: this.pageObject.emailId,
      roleLabel: this.pageObject.roleLabel
    }).then((response) => {
      if (response && Object.keys(response).length) {
        if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
        }
        if (response.strStatusCode === '000') {
          this.isAddNewUserModal = !this.isAddNewUserModal;
          this.generateUrl(`${basePath}/my-accounts?activeTab=user-management`);
        }
      }
      this.isSpinner = false;
    }).catch(() => {
      toastMessageHandler();
      this.isSpinner = false;
    });
  }

  /**
   * Navigation mixin : navigate to another page
   * @function navigateUrl
   * @param {string} url
   */
  navigateUrl(url) {
    const pageRef = {
      type: 'standard__webPage',
      attributes: {
        url: url
      }
    };
    this[NavigationMixin.Navigate](pageRef)
  }

  /**
   * Generate url handler
   * @function generateUrl
   * @param {string} url
   */
  generateUrl(url) {
    const pageRef = {
      type: 'standard__webPage',
      attributes: {
        url: url
      }
    };
    this[NavigationMixin.GenerateUrl](pageRef)
      .then(generatedUrl => {
        urlRedirect(generatedUrl);
      });
  }
}