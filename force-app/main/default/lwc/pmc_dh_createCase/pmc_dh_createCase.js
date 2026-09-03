import { LightningElement, track, wire, api } from "lwc";
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import basePath from "@salesforce/community/basePath";
import { formatLabel, toastMessageHandler, urlRedirect } from 'c/pmc_dh_utilityJs';
import createNewCase from "@salesforce/apex/PMC_DH_CaseMgmtClass.createNewCase";
import getIssueReasonForCase from "@salesforce/apex/PMC_DH_CaseMgmtClass.getIssueReasonForCase";
import getTypeForCase from "@salesforce/apex/PMC_DH_CaseMgmtClass.getTypeForCase";

import pmc_caseMgmt_createNewCase from "@salesforce/label/c.pmc_caseMgmt_createNewCase";
import pmc_caseMgmt_createCase from "@salesforce/label/c.pmc_caseMgmt_createCase";
import pmc_caseMgmt_inquiryType from "@salesforce/label/c.pmc_caseMgmt_inquiryType";
import pmc_caseMgmt_topic from "@salesforce/label/c.pmc_caseMgmt_topic";
import pmc_caseMgmt_subject from "@salesforce/label/c.pmc_caseMgmt_subject";
import pmc_caseMgmt_description from "@salesforce/label/c.pmc_caseMgmt_description";
import pmc_caseMgmt_proceedToCreateCase from "@salesforce/label/c.pmc_caseMgmt_proceedToCreateCase";
import pmc_quoteCheckoutFlow_proceed from "@salesforce/label/c.pmc_quoteCheckoutFlow_proceed";
import pmc_caseMgmt_descRequiredErr from "@salesforce/label/c.pmc_caseMgmt_descRequiredErr";
import pmc_inputElement_patternMismatchError from "@salesforce/label/c.pmc_inputElement_patternMismatchError";
import pmc_orderDetails_order from "@salesforce/label/c.pmc_orderDetails_order";

/**
 * A custom LWC for Create a New Case.
 * @alias Pmc_dh_createCase
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 *
 * @example
 * <c-pmc_dh_create-case></c-pmc_dh_create-case>
 */

export default class Pmc_dh_createCase extends NavigationMixin(
  LightningElement
) {
  @api
  get orderNumber() {
    return this._orderNumberStr;
  }
  set orderNumber(value) {
    this._orderNumberStr = `${pmc_orderDetails_order} ${value}`;
  }
  @api
  get isCreateCaseEnabled() {
    return this._createCaseModalOpen;
  }
  set isCreateCaseEnabled(value) {
    this._createCaseModalOpen = value;
    this.caseObject.strSubject = this._orderNumberStr;
  }
  _createCaseModalOpen = false;
  _orderNumberStr = "";
  isMultiple = true;
  isInvalidForm = true;
  loadSpinner = false;
  modalOpened = false;
  @track filesData = [];
  @track caseObject = {
    strType: "",
    strIssueReason: "",
    strSubject: "",
    strDescription: ""
  };
  @track inquiryTypes = [];
  @track topics = [];
  @track issueReasonMap = {};
  @track labels = {
    pmc_caseMgmt_createNewCase,
    pmc_caseMgmt_createCase,
    pmc_caseMgmt_inquiryType,
    pmc_caseMgmt_topic,
    pmc_caseMgmt_subject,
    pmc_caseMgmt_description,
    pmc_caseMgmt_proceedToCreateCase,
    pmc_quoteCheckoutFlow_proceed,
    pmc_caseMgmt_descRequiredErr
  };

  @wire(CurrentPageReference) pageRef;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    this.loadTypeDetails();
    this.loadIssueReasons();
    this.isInvalidForm = true;
    this.caseObject.strSubject = this._orderNumberStr;
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (this.modalOpened) return;
    this.disableProceed();
    this.template
      .querySelectorAll("c-pmc_dh_input-element,c-pmc_dh_selection-picklist")
      .forEach((inputComponent) => {
        inputComponent.updateIsRequired();
      });
    this.modalOpened = true;
  }

  /**
   * Fetch Picklist Values for case inquiry types
   * @function loadTypeDetails
   */
  loadTypeDetails() {
    getTypeForCase()
      .then((types) => {
        if (types?.length) {
          this.inquiryTypes = JSON.parse(JSON.stringify(types));
        }
      })
      .catch(() => {
        toastMessageHandler()
      });
  }

  /**
   * Fetch Picklist Values for case topics
   * @function loadIssueReasons
   */
  loadIssueReasons() {
    getIssueReasonForCase()
      .then((reasons) => {
        if (reasons && Object.keys(reasons).length) {
          let issueReasonMap = JSON.parse(JSON.stringify(reasons));
          Object.keys(issueReasonMap).forEach((issue) => {
            let reasonMap = issueReasonMap[issue];
            // let reasonMap = issueReasonMap[issue].map((reason) => {
            //   let option = {
            //     label: reason,
            //     value: reason
            //   };
            //   return option;
            // });
            this.issueReasonMap[issue] = reasonMap;
          });
        }
      })
      .catch(() => {
        toastMessageHandler();
      });
  }

  /**
   * Get topics respective to the selected inquiry type
   * @function getTopics
   */
  getTopics() {
    return this.caseObject.strType
      ? this.issueReasonMap[this.caseObject.strType]
      : [];
  }

  /**
   * On input change event handler
   * @function handleDataChange
   * @param {Event} event
   */
  handleDataChange(event) {
    if (
      event.detail.value !== "undefined" &&
      event.target &&
      event.target.dataset
    ) {
      this.caseObject[event.target.dataset.id] =
        event.target.type === "text" ||
          event.target.dataset.id === "strDescription"
          ? event.detail.value.trim()
          : event.detail.value;
    }
    if (event.target.dataset.id === "strType") {
      this.topics = this.getTopics();
      this.caseObject.strIssueReason = '';
    }
    if (event.target.dataset.id === "strDescription") {
      const inputValue = event.detail.value;
      const regex = /^[A-Za-z0-9#,./ -]*$/
      if (!regex.test(inputValue)) {
        event.target.setCustomValidity(formatLabel(pmc_inputElement_patternMismatchError, [event.target.label]));
      } else {
        event.target.setCustomValidity('');
      }
      event.target.reportValidity();
    }
    this.disableProceed();
  }

  /**
   * File upload handler
   * @function handleUpload
   * @param {Event} event
   */
  handleUpload(event) {
    if (event.detail.filesData) {
      this.filesData = event.detail.filesData;
    }
  }

  /**
   * Disables proceed button if any required field is empty
   * @function disableProceed
   */
  disableProceed() {
    this.isInvalidForm = false;
    if (
      !this.caseObject.strType ||
      !this.caseObject.strIssueReason ||
      !this.caseObject.strSubject ||
      !this.caseObject.strDescription
    ) {
      this.isInvalidForm = true;
    }
  }

  /**
   * Check if form fields are invalid or not
   * @function isFormInvalid
   * @returns {boolean}
   */
  isFormInvalid() {
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
   * Saving the data on 'Proceed' button click and navigating to case detail page
   * @function createCaseHandler
   */
  createCaseHandler() {
    if (this.isFormInvalid()) return;
    this.filesData = this.filesData.map((file) => {
      let fileDetail = {
        strFileName: file.filename,
        strBase64Data: file.base64
      };
      return fileDetail;
    });
    this.loadSpinner = true;
    let effectiveAccountId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
    createNewCase({
      effAccountId: effectiveAccountId,
      caseCreation: this.caseObject,
      lstFileWrapper: this.filesData
    })
      .then((res) => {
        if (res && Object.keys(res).length) {
          if (JSON.parse(JSON.stringify(res)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(res)).statusCodeMessage.strStatusMessage)
          }
          this.closeCreateCaseModal();
          this.navigateToUrl(`/case/${res.objCaseDetail.Id}?caseNumber=${res.objCaseDetail.CaseNumber}`);
        }
        this.loadSpinner = false;
      })
      .catch(() => {
        toastMessageHandler();
        this.loadSpinner = false;
        this.closeCreateCaseModal();
      });
  }

  /**
   * Create Case Modal close handler
   * @function closeCreateCaseModal
   */
  closeCreateCaseModal() {
    this.clearForm();
    this._createCaseModalOpen = !this._createCaseModalOpen;
    this.dispatchEvent(
      new CustomEvent("closecreatecasepopup", {
        detail: {
          value: this._createCaseModalOpen
        }
      })
    );
  }

  /**
   * Reset all the input fields of the create case form
   * @function clearForm
   */
  clearForm() {
    this.caseObject = {};
    this.filesData = [];
    this.template
      .querySelectorAll("c-pmc_dh_input-element,c-pmc_dh_selection-picklist")
      .forEach((inputComponent) => {
        inputComponent.resetInput();
      });
    this.template.querySelector("lightning-textarea").value = "";
    this.template.querySelector("c-pmc_dh_file-upload-element").resetFiles();
  }

  /**
   * Modal accessibility handler
   * @function handleIconKeyDown
   * @param {event} event 
   */
  handleIconKeyDown(event) {
    if (event.keyCode === 13) {
      this.openCreateCaseModal();
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

  /** Navigate to different page
   * @function navigateToUrl
   * @param {string} url - Navigation URL
   */
  navigateToUrl(url) {
    this[NavigationMixin.GenerateUrl]({
      type: "standard__webPage",
      attributes: {
        url: `${basePath}${url}`
      }
    }).then((generatedUrl) => {
      urlRedirect(generatedUrl);
    });
  }
}