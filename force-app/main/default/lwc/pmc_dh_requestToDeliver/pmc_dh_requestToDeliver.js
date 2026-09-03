import { LightningElement, track } from 'lwc';
import basePath from "@salesforce/community/basePath";
import pmc_breadcrumb_homepage from "@salesforce/label/c.pmc_breadcrumb_homepage";
import pmc_quoteCheckoutFlow_shippingInfo from "@salesforce/label/c.pmc_quoteCheckoutFlow_shippingInfo";
import pmc_requestToDeliverShippingInformation_requestToDeliver from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_requestToDeliver";
import pmc_requestToDeliverShippingInformation_orderReview from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_orderReview";
import pmc_requestToDeliverShippingInformation_orderSubmitted from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_orderSubmitted";

/**
 * A custom LWC to display the RTD flow.
 * @alias Pmc_dh_requestToDeliver
 * @extends LightningElement
 * @hideconstructor
 * @author Himanshu Rathore
 * @example
 * <c-pmc_dh_request-to-deliver> </c-pmc_dh_request-to-deliver>
 */

export default class Pmc_dh_requestToDeliver extends LightningElement {
  @track pageLoaded = true;

  @track rtdFlowHandler = {
    isShipmentInfo: true,
    isOrderReview: false,
    isOrderSubmitted: false,
  }

  @track labels = {
    pmc_quoteCheckoutFlow_shippingInfo,
    pmc_requestToDeliverShippingInformation_requestToDeliver,
    pmc_requestToDeliverShippingInformation_orderReview,
    pmc_requestToDeliverShippingInformation_orderSubmitted
  }

  @track crumbs = [
    { label: pmc_breadcrumb_homepage, url: `${basePath}/`, isActive: false },
    { label: pmc_requestToDeliverShippingInformation_requestToDeliver, url: "", isActive: true },
  ];

  @track stepsData = [
    {
      title: this.labels.pmc_quoteCheckoutFlow_shippingInfo,
      status: 'active',
      icon: "icontruck"
    },
    {
      title: this.labels.pmc_requestToDeliverShippingInformation_orderReview,
      status: 'pending',
      icon: "iconfilecheck"
    },
    {
      title: this.labels.pmc_requestToDeliverShippingInformation_orderSubmitted,
      status: 'pending',
      icon: "iconcheck"
    }
  ];

  @track shipmentInfoObj = {};
  @track shipToObj = {};
  @track picklistObj = {};
  @track orderObj = {};
  @track backButtonTriggered = false;

  /**
   * Handling rtd flow step tracker, upon change of step
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
   * Handling proceed and back button click in child components
   * @function onClickHandler
   * @param {Event} event 
   */
  onClickHandler(event) {
    Object.keys(this.rtdFlowHandler).forEach(el => {
      this.rtdFlowHandler[el] = false;
    });
    if (event.detail.shipmentInfo) {
      this.shipmentInfoObj = event.detail.shipmentInfo;
      this.backButtonTriggered = event.detail.backButtonTriggered;
    }
    if (event.detail.shipToInfo) {
      this.shipToObj = event.detail.shipToInfo;
    }
    if (event.detail.picklistObj) {
      this.picklistObj = event.detail.picklistObj;
    }
    if (event.detail.orderData) {
      this.orderObj = event.detail.orderData;
    }
    this.rtdFlowHandler[event.detail.value] = true;
    this.stepChangeHandler(event.detail.step);
  }
}