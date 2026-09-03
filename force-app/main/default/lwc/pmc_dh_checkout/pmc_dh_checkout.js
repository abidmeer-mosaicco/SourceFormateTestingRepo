import { LightningElement, track } from 'lwc';
import pmc_cartCheckout_checkout from '@salesforce/label/c.pmc_cartCheckout_checkout';

export default class Pmc_dh_checkout extends LightningElement {
  @track checkoutPageHandler = {
    RFQ: false,
    RTD: false,
  };
  checkoutFlag;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    if (sessionStorage.getItem('CHECKOUT_FLAG')) {
      this.checkoutFlag = sessionStorage.getItem('CHECKOUT_FLAG');
      this.fetchPageDetails();
    }
    this.setPageTitle();
  }


  /** 
   * Set title of checkout page
   * @function setPageTitle
   */
  setPageTitle() {
    document.title = pmc_cartCheckout_checkout;
  }

  /**
   * Fetches page details according to checkout flag
   * @function fetchPageDetails
   */
  fetchPageDetails() {
    Object.keys(this.checkoutPageHandler).forEach(el => {
      this.checkoutPageHandler[el] = false;
    });
    this.checkoutPageHandler[this.checkoutFlag] = true;
  }
}