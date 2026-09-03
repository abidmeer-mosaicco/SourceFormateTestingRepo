import { LightningElement, track } from 'lwc';
import basePath from "@salesforce/community/basePath";

import pmc_quoteCheckoutFlow_title from "@salesforce/label/c.pmc_quoteCheckoutFlow_title";
import pmc_quoteCheckoutFlow_shippingInfo from "@salesforce/label/c.pmc_quoteCheckoutFlow_shippingInfo";
import pmc_quoteCheckoutFlow_paymentInfo from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentInfo";
import pmc_quoteCheckoutFlow_requestReview from "@salesforce/label/c.pmc_quoteCheckoutFlow_requestReview";
import pmc_quoteCheckoutFlow_requestSubmitted from "@salesforce/label/c.pmc_quoteCheckoutFlow_requestSubmitted";
import pmc_breadcrumb_homepage from "@salesforce/label/c.pmc_breadcrumb_homepage";

/**
 * A custom LWC to display the quote checkout flow.
 * @alias Pmc_dh_quoteCheckoutFlow
 * @extends LightningElement
 * @hideconstructor
 * @author Hemant
 * @example
 * <c-pmc_dh_quote-checkout-flow></c-pmc_dh_quote-checkout-flow>
 */

export default class Pmc_dh_quoteCheckoutFlow extends LightningElement {
  @track checkoutFlowHandler = {
    isDeliveryInfo: true,
    isPaymentInfo: false,
    isRequestReview: false,
    isRequestSubmitted: false,
  }

  @track labels = {
    pmc_quoteCheckoutFlow_title,
    pmc_quoteCheckoutFlow_shippingInfo,
    pmc_quoteCheckoutFlow_paymentInfo,
    pmc_quoteCheckoutFlow_requestReview,
    pmc_quoteCheckoutFlow_requestSubmitted,
  };

  @track crumbs = [
    { label: pmc_breadcrumb_homepage, url: `${basePath}/`, isActive: false },
    { label: pmc_quoteCheckoutFlow_title, url: "", isActive: true },
  ];

  @track stepsData = [
    {
      title: this.labels.pmc_quoteCheckoutFlow_shippingInfo,
      status: 'active',
      icon: "icontruck"
    },
    {
      title: this.labels.pmc_quoteCheckoutFlow_paymentInfo,
      status: 'pending',
      icon: "iconcash"
    },
    {
      title: this.labels.pmc_quoteCheckoutFlow_requestReview,
      status: 'pending',
      icon: "iconfilecheck"
    },
    {
      title: this.labels.pmc_quoteCheckoutFlow_requestSubmitted,
      status: 'pending',
      icon: "iconcheck"
    }
  ];
  @track paymentInfoObj = null;
  @track productInfoArray = [];
  @track quoteInfo = {};
  cartId;
  lstProductFamilies;

  /**
   * handling checkout flow step tracker, upon change of step
   * @function stepChangeHandler
   * @param {number} step 
   */
  stepChangeHandler(step) {
    this.stepsData.forEach((el, i) => {
      if (i < step - 1) {
        el.status = 'complete';
      }
      else if (i === step - 1) {
        el.status = 'active';
      }
      else {
        el.status = 'pending';
      }
    })
  }

  /**
   * handling proceed and back button click in child components
   * @function onClickHandler
   * @param {Event} event 
   */
  onClickHandler(event) {
    Object.keys(this.checkoutFlowHandler).forEach(el => {
      this.checkoutFlowHandler[el] = false;
    });
    if (event.detail.paymentInfoObj) {
      this.paymentInfoObj = event.detail.paymentInfoObj;
    }
    if (event.detail.productInfoArray) {
      this.productInfoArray = event.detail.productInfoArray;
    }
    if (event.detail.lstProductFamilies) {
      this.lstProductFamilies = event.detail.lstProductFamilies;
    }
    if (event.detail.quoteInfo) {
      this.quoteInfo = event.detail.quoteInfo;
    }
    if (event.detail.cartId) {
      this.cartId = event.detail.cartId;
    }
    this.checkoutFlowHandler[event.detail.value] = true;
    this.stepChangeHandler(event.detail.step);
  }
}