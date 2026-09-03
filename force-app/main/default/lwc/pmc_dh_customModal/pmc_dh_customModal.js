import { LightningElement, api, track } from 'lwc';
import pmc_modal_close from "@salesforce/label/c.pmc_modal_close";
import PMC_BrandingStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";

const HIDE_MODAL = 'slds-hide';

/**
 * A custom LWC for Footerless Modal.
 * @alias Pmc_dh_customModal
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 * @example
 * <c-pmc_dh_custom-modal open-modal modal-width="500px" modal-heading="Modal Heading"></c-pmc_dh_custom-modal>
 */

export default class Pmc_dh_customModal extends LightningElement {
  class;
  visibilityClass;
  closeIconUrl = `${PMC_BrandingStaticResource}/icons/icon-close.svg`;
  @track labels = {
    pmc_modal_close
  }
  @api modalWidth;
  @api modalHeading;

  @api
  get openModal() {
    return this.visibilityClass;
  }

  /**
   * Setting the visibility of the Modal based on 'open-modal' attribute from parent
   */
  set openModal(value) {
    if (value) {
      this.visibilityClass = '';
    } else {
      this.visibilityClass = HIDE_MODAL;
    }
  }

  /**
   * @function handleCloseModal
   * - Closing the modal on click of 'X'
   * @param {Event} event 
   */
  handleCloseModal(event) {
    if (event) {
      this.dispatchEvent(new CustomEvent("closemodalevent"));
      event.preventDefault();
    }
    this.visibilityClass = HIDE_MODAL;
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    this.template.querySelector('.slds-modal__container').style.width = this.modalWidth;
    this.template.querySelector('.close-icon-container').addEventListener('keydown', event => event.keyCode === 13 && this.handleCloseModal(event));
  }
}