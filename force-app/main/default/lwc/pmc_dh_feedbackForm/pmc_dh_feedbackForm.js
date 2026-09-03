import { LightningElement, api } from "lwc";
import { formatLabel } from 'c/pmc_dh_utilityJs';
import pmc_inputElement_patternMismatchError from "@salesforce/label/c.pmc_inputElement_patternMismatchError";

const REASON_OTHERS = "Other";
export default class Pmc_dh_feedbackForm extends LightningElement {
  isCommentDisabled = true;
  @api reasonLabel = "";
  @api commentLabel = "";
  @api picklistOptions = [];
  @api reasonFieldName = "";
  @api commentFieldName = "";
  @api textareaPlaceholder = "";

  @api
  resetInputs() {
    this.template.querySelectorAll(`[data-name]`).forEach(element => {
      element.value = '';
    });
    this.isCommentDisabled = true;
  }

  /**
   * Input change handler
   * @function handleDataChange
   * @param {Event} event 
   */
  handleDataChange(event) {
    let isValid = true;
    if (
      event.target.dataset.name === this.reasonFieldName &&
      event.target.value === REASON_OTHERS
    ) {
      this.isCommentDisabled = false;
    } else if (
      event.target.dataset.name === this.reasonFieldName &&
      event.target.value !== REASON_OTHERS
    ) {
      this.resetComments();
      this.isCommentDisabled = true;
    } else if (event.target.dataset.name === this.commentFieldName) {
      const inputValue = event.detail.value;
      const regex = /^[A-Za-z0-9#,./ -]*$/
      if (!regex.test(inputValue)) {
        event.target.setCustomValidity(formatLabel(pmc_inputElement_patternMismatchError, [event.target.label]));
        isValid = false;
      } else {
        event.target.setCustomValidity('');
      }
      event.target.reportValidity();
    }
    this.dispatchEvent(
      new CustomEvent("inputchange", {
        detail: {
          name: event.target.dataset.name,
          value: event.target.value,
          validity: isValid
        }
      })
    );
  }

  /**
   * Resets comments to empty string
   * @function resetComments
   */
  resetComments() {
    this.template.querySelector(`[data-name=${this.commentFieldName}]`).value = '';
    this.dispatchEvent(
      new CustomEvent("inputchange", {
        detail: {
          name: this.commentFieldName,
          value: ''
        }
      })
    );
  }
}