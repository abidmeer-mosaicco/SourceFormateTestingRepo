import { LightningElement, track, api, wire } from 'lwc';
import basePath from '@salesforce/community/basePath';
import { getNavigationMenu } from 'experience/navigationMenuApi';

import pmc_quoteCheckoutFlow_thankyouForSubmitting from "@salesforce/label/c.pmc_quoteCheckoutFlow_thankyouForSubmitting";
import pmc_quoteCheckoutFlow_quoteRequestNumber from "@salesforce/label/c.pmc_quoteCheckoutFlow_quoteRequestNumber";
import pmc_quoteCheckoutFlow_requestAnotherQuote from "@salesforce/label/c.pmc_quoteCheckoutFlow_requestAnotherQuote";
import pmc_quoteCheckoutFlow_viewMyRequestedQuote from "@salesforce/label/c.pmc_quoteCheckoutFlow_viewMyRequestedQuote";
import pmc_contractDetails_products from "@salesforce/label/c.pmc_contractDetails_products";

/**
 * A custom LWC to display the request submit success step in checkout flow.
 * @alias Pmc_dh_quoteCheckoutRequestSubmitted
 * @extends LightningElement
 * @hideconstructor
 * @author Hemant
 * @example
 * <c-pmc_dh_quote-checkout-request-submitted></c-pmc_dh_quote-checkout-request-submitted>
 */

export default class Pmc_dh_quoteCheckoutRequestSubmitted extends LightningElement {
  @api quoteInfo = {};
  @track labels = {
    pmc_quoteCheckoutFlow_thankyouForSubmitting,
    pmc_quoteCheckoutFlow_quoteRequestNumber,
    pmc_quoteCheckoutFlow_requestAnotherQuote,
    pmc_quoteCheckoutFlow_viewMyRequestedQuote
  };
  productPageUrl;
  quotePageUrl;
  error;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    let baseUrl = window.location.origin;
    if (this.quoteInfo) {
      this.quotePageUrl = `${baseUrl}${basePath}/quote?quoteNumber=${this.quoteInfo.quoteNumber}?quoteId=${this.quoteInfo.quoteId}`;
    }
  }

  @wire(getNavigationMenu)
  navMenu({ error, data }) {
    if (data) {
      this.fetchProductLink(data.menuItems);
    } else if (error) {
      this.error = error;
    }
  }

  /**
   * Generates link for product detail page
   * @function fetchProductLink
   * @param {Array} menuItems 
   */
  fetchProductLink(menuItems) {
    let baseUrl = window.location.origin;
    const productsItem = menuItems.find(item => item.label === pmc_contractDetails_products);
    this.productPageUrl = `${baseUrl}${productsItem.actionValue}`;
  }
}