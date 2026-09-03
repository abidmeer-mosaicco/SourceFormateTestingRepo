import { LightningElement, track, api } from 'lwc';
import { isBrazilRegion, urlRedirect } from 'c/pmc_dh_utilityJs';
import basePath from "@salesforce/community/basePath";
import { NavigationMixin } from "lightning/navigation";

import pmc_requestToDeliver_successMessage from "@salesforce/label/c.pmc_requestToDeliver_successMessage";
import pmc_requestToDeliver_orderRequestedNumber from "@salesforce/label/c.pmc_requestToDeliver_orderRequestedNumber";
import pmc_requestToDeliver_requestAnotherOrder from "@salesforce/label/c.pmc_requestToDeliver_requestAnotherOrder";
import pmc_requestToDeliver_viewMyOrders from "@salesforce/label/c.pmc_requestToDeliver_viewMyOrders";

const REQUESTED = "Requested";

/**
 * A custom LWC to display order submission page in RTD flow.
 * @alias Pmc_dh_requestToDeliverOrderSubmitted
 * @extends LightningElement
 * @hideconstructor
 * @author Vanshika
 *
 * @example
 * <c-pmc_dh_request-to-deliver-order-submitted></c-pmc_dh_request-to-deliver-order-submitted>
 */

export default class Pmc_dh_requestToDeliverOrderSubmitted extends NavigationMixin(LightningElement) {
  @api get orderObj() {
    return this.lstData;
  }
  set orderObj(value) {
    if (value) {
      this.lstData = value;
    }
  }
  @track lstData = [];
  @track pageLoaded = false;
  @track isLocationBrazil = false;
  orderNumber = '';

  /**
   * Custom Label Details
   */
  @track labels = {
    pmc_requestToDeliver_successMessage,
    pmc_requestToDeliver_orderRequestedNumber,
    pmc_requestToDeliver_requestAnotherOrder,
    pmc_requestToDeliver_viewMyOrders
  }

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    this.pageLoaded = false;
    if (isBrazilRegion()) {
      this.isLocationBrazil = !this.isLocationBrazil;
    }
    if (this.lstData) {
      let strOrderId,orderArray;
      if (this.isLocationBrazil && this.lstData?.lstResultData) {
        if(Array.isArray(this.lstData.lstResultData)) {
          orderArray = this.lstData.lstResultData[0].strReqId.split('-');
        }
        else {
          orderArray = this.lstData.lstResultData.strReqId.split('-');
        }
        strOrderId = `${orderArray[0]}-${orderArray[1]}`;
      }
      this.orderNumber = this.isLocationBrazil ? strOrderId : this.lstData.orderNumber;
      this.pageLoaded = true;
    }
  }

  /**
   * Redirects to Contract History Page
   * @function requestAnotherOrderHandler
   */
  requestAnotherOrderHandler() {
    this[NavigationMixin.GenerateUrl]({
      type: "standard__webPage",
      attributes: {
        url: `${basePath}/contracts`
      }
    }).then((generatedUrl) => {
      urlRedirect(generatedUrl);
    });
  }

  /**
   * Redirects to Order Details Page
   * @function viewMyOrderHandler
   */
  viewMyOrderHandler() {
    if (this.isLocationBrazil) {
      sessionStorage.setItem('ORDER_STATUS', REQUESTED);
    }
    let orderPageUrl = this.isLocationBrazil ? `${basePath}/orders?menu=Requested` : `${basePath}/order/${this.lstData.orderId}?orderNumber=${this.lstData.orderNumber}&orderId=${this.lstData.orderId}`
    this[NavigationMixin.GenerateUrl]({
      type: "standard__webPage",
      attributes: {
        url: orderPageUrl
      }
    }).then((generatedUrl) => {
      urlRedirect(generatedUrl);
    });
  }
}