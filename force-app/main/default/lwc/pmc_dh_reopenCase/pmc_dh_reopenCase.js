import { LightningElement, track, wire } from "lwc";
import pmc_brandingStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import reopenCase from "@salesforce/apex/PMC_DH_CaseUtil.reopenCase";
import getReopenReasonList from "@salesforce/apex/PMC_DH_CaseUtil.getReopenReasonList";
import { CurrentPageReference } from "lightning/navigation";

import pmc_caseMgmt_reopenCase from "@salesforce/label/c.pmc_caseMgmt_reopenCase";
import pmc_caseMgmt_reopenComments from "@salesforce/label/c.pmc_caseMgmt_reopenComments";
import pmc_caseMgmt_reopenReasonLabel from "@salesforce/label/c.pmc_caseMgmt_reopenReasonLabel";
import pmc_caseMgmt_commentPlaceholder from "@salesforce/label/c.pmc_caseMgmt_commentPlaceholder";
import { toastMessageHandler } from "c/pmc_dh_utilityJs";

/**
 * A custom LWC for reopen a Case.
 * @alias Pmc_dh_reopenCase
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 *
 * @example
 * <c-pmc_dh_reopen-case></c-pmc_dh_reopen-case>
 */

export default class Pmc_dh_reopenCase extends LightningElement {
  buttonUrl = `${pmc_brandingStaticResource}/icons/icon-reopen.svg`;
  isReopenCaseEnabled = false;
  isMouseOver = false;
  caseId = "";
  disableSubmit = true;
  loadSpinner = false;
  modalWidth = "537px";
  @track caseObject = {};
  @track picklistOptions = [];
  @track labels = {
    pmc_caseMgmt_reopenReasonLabel,
    pmc_caseMgmt_commentPlaceholder,
    pmc_caseMgmt_reopenComments,
    pmc_caseMgmt_reopenCase
  };

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    if (currentPageReference) {
      this.caseId = currentPageReference.attributes?.recordId || "";
    }
  }

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    this.loadPicklistDetails();
    this.disableSubmit = true;
  }

  /**
   * Fetch Picklist Values for case inquiry types and topics
   * @function loadPicklistDetails
   */
  loadPicklistDetails() {
    this.loadSpinner = true;
    getReopenReasonList()
      .then((options) => {
        this.picklistOptions = options ? JSON.parse(JSON.stringify(options)) : [];
        this.loadSpinner = false;
      })
      .catch(() => {
        toastMessageHandler();
        this.loadSpinner = false;
       });
  }

  /**
   * On input change event handler
   * @function handleDataChange
   * @param {Event} event 
   */
  handleDataChange(event) {
    if (event.detail.value !== "undefined" && event.detail.name) {
      this.caseObject[event.detail.name] = event.detail.value.trim();
      this.isFormInvalid();
    }
  }

  /**
   * Check if form fields are invalid or not
   * @function isFormInvalid
   */
  isFormInvalid() {
    this.disableSubmit = false;
    if (
      !this.caseObject.strReason ||
      (this.caseObject.strReason === "Other" &&
        !this.caseObject.strOthersComment)
    ) {
      this.disableSubmit = true;
    }
  }

  /**
   * Saving the data on 'Proceed' button click and navigating to case detail page
   * @function createCaseHandler
   */
  reopenCaseHandler() {
    this.caseObject.strCaseId = this.caseId;
    if (this.isFormInvalid()) return;
    this.loadSpinner = true;
    reopenCase({
      cseWrapper: this.caseObject
    })
      .then(() => {
        this.loadSpinner = false;
        this.closeReopenCaseModal();
        window.location.reload();
      })
      .catch(() => {
        toastMessageHandler();
        this.loadSpinner = false;
        this.closeReopenCaseModal();
      });
  }

  /**
   * Create Case Modal open handler
   * @function openReopenCaseModal
   */
  openReopenCaseModal() {
    this.isReopenCaseEnabled = !this.isReopenCaseEnabled;
    this.disableSubmit = true;
  }

  /**
   * Create Case Modal close handler
   * @function closeReopenCaseModal
   */
  closeReopenCaseModal() {
    this.clearForm();
    this.isReopenCaseEnabled = !this.isReopenCaseEnabled;
  }

  /**
   * Reset all the input fields of the create case form
   * @function clearForm
   */
  clearForm() {
    this.caseObject = {};
    this.template.querySelector("c-pmc_dh_feedback-form").resetInputs();
  }

  /**
   * Modal accessibility handler
   * @function handleIconKeyDown
   * @param {Event} event 
   */
  handleIconKeyDown(event) {
    if (event.keyCode === 13) {
      this.openReopenCaseModal();
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