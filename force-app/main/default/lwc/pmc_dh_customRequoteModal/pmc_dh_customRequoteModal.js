import { LightningElement, api, track } from 'lwc';
import pmc_addressDetails_cancel from "@salesforce/label/c.pmc_addressDetails_cancel";

/**
 * A custom LWC to display generic modal.
 * @alias Pmc_dh_customRequoteModal
 * @extends LightningElement
 * @hideconstructor
 * @author Vanshika
 *
 * @example
 * <c-pmc_dh_custom-requote-modal></c-pmc_dh_custom-requote-modal>
 */

export default class Pmc_dh_customRequoteModal extends LightningElement {
  @api isModal;
  @api modalHeading;
  @api modalText;

  @track labels = {
    pmc_addressDetails_cancel
  }

  /**
   * @function closeModalHandler
   * Closing the modal on click of 'X' and Cancel
   */
  closeModalHandler() {
    this.dispatchEvent(new CustomEvent("closemodal"));
  }

  /**
   * @function productActionHandler
   * Handles the requote/reorder
   * @param {Event} event 
   */
  productActionHandler(event) {
    if (event) {
      this.dispatchEvent(new CustomEvent("handleproductaction"));
      event.preventDefault();
    }
  }
}