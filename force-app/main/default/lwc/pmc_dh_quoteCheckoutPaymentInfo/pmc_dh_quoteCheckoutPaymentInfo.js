import { LightningElement, track, api } from "lwc";
import { sortData, SORT_DIRECTION, toastMessageHandler, isBrazilRegion, getRawDateUtil } from 'c/pmc_dh_utilityJs';
import updatePaymentInfo from "@salesforce/apex/PMC_DH_RequestForQuoteController.updatePaymentInfoForCart";
import getPaymentInfo from "@salesforce/apex/PMC_DH_RequestForQuoteController.getPaymentInfoForCart";
import DisableAddtoOrder from '@salesforce/customPermission/DisableAddtoOrder';

import pmc_quoteCheckoutFlow_enterRequestedContract from "@salesforce/label/c.pmc_quoteCheckoutFlow_enterRequestedContract";
import pmc_quoteCheckoutFlow_contractPeriod from "@salesforce/label/c.pmc_quoteCheckoutFlow_contractPeriod";
import pmc_quoteCheckoutFlow_paymentInfo from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentInfo";
import pmc_quoteCheckoutFlow_startingFrom from "@salesforce/label/c.pmc_quoteCheckoutFlow_startingFrom";
import pmc_quoteCheckoutFlow_endDate from "@salesforce/label/c.pmc_quoteCheckoutFlow_endDate";
import pmc_quoteCheckoutFlow_paymentTerms from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentTerms";
import pmc_quoteCheckoutFlow_paymentMethod from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentMethod";
import pmc_quoteCheckoutFlow_currency from "@salesforce/label/c.pmc_quoteCheckoutFlow_currency";
import pmc_quoteCheckoutFlow_back from "@salesforce/label/c.pmc_quoteCheckoutFlow_back";
import pmc_quoteCheckoutFlow_proceed from "@salesforce/label/c.pmc_quoteCheckoutFlow_proceed";
import pmc_quoteCheckoutFlow_maxEndDateError from "@salesforce/label/c.pmc_quoteCheckoutFlow_maxEndDateError";
import pmc_quoteCheckout_startDateErrorMsg from "@salesforce/label/c.pmc_quoteCheckout_startDateErrorMsg";
import pmc_quoteCheckout_endDateErrorMsg from "@salesforce/label/c.pmc_quoteCheckout_endDateErrorMsg";
import pmc_quoteCheckoutFlow_paymentDate from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentDate";
import pmc_quoteCheckoutFlow_paymentDateErrorMsg1 from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentDateErrorMsg1";
import pmc_quoteCheckoutFlow_paymentDateErrorMsg2 from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentDateErrorMsg2";

const LABEL = "label";

/**
 * A custom LWC to display the payment information step in checkout flow.
 * @alias Pmc_dh_quoteCheckoutPaymentInfo
 * @extends LightningElement
 * @hideconstructor
 * @author Hemant
 * @example
 * <c-pmc_dh_quote-checkout-payment-info></c-pmc_dh_quote-checkout-payment-info>
 */

export default class Pmc_dh_quoteCheckoutPaymentInfo extends LightningElement {
  @api paymentInfoObj = {};
  @api productFamiliesList;
  @api cartId;
  @track pageObj = {};
  @track paymentTermsOptions = [];
  @track currencyOptions = [];
  @track labels = {
    pmc_quoteCheckoutFlow_enterRequestedContract,
    pmc_quoteCheckoutFlow_contractPeriod,
    pmc_quoteCheckoutFlow_startingFrom,
    pmc_quoteCheckoutFlow_paymentInfo,
    pmc_quoteCheckoutFlow_endDate,
    pmc_quoteCheckoutFlow_paymentTerms,
    pmc_quoteCheckoutFlow_paymentMethod,
    pmc_quoteCheckoutFlow_currency,
    pmc_quoteCheckoutFlow_back,
    pmc_quoteCheckoutFlow_proceed,
    pmc_quoteCheckoutFlow_maxEndDateError,
    pmc_quoteCheckout_startDateErrorMsg,
    pmc_quoteCheckout_endDateErrorMsg,
    pmc_quoteCheckoutFlow_paymentDate
  };
  isEndDateDisabled = true;
  isPageRendered = false;
  isPageLoaded = false;
  isPrepaymentAllowed = false;
  isPrepaymentDateField = false;
  isSpinner = true;
  isLocationBrazil = false;
  isBuyerOrSuperBuyer = !DisableAddtoOrder;
  strCountry;
  today;
  minEndDate;
  error;
  maxEndDate;
  maxPrepaymentDate;
  minPrepaymentDate;
  paymentDateErrorMsg;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    this.today = new Date().toISOString().slice(0, 10);
    this.minPrepaymentDate = this.today;
    this.isLocationBrazil = isBrazilRegion();
    this.isPrepaymentAllowed = this.isLocationBrazil && this.isBuyerOrSuperBuyer;
    this.strCountry = sessionStorage.getItem("userRegion");
    this.fetchPaymentInfo();
  }

  /**
   * Fetch picklist options from backend method
   * @function fetchPaymentInfo
   */
  fetchPaymentInfo() {
    getPaymentInfo({
      strCountry: this.strCountry,
      strCartId: this.cartId
    })
      .then((data) => {
        if (data && Object.keys(data).length) {
          if (JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(data)).statusCodeMessage.strStatusMessage)
          }
          this.currencyOptions = [...data.lstCurrencyIsoCode];
          this.currencyOptions = sortData(this.currencyOptions, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
          this.paymentTermsOptions = [...data.lstPaymentTerms];
          this.paymentTermsOptions = sortData(this.paymentTermsOptions, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
          if (data.objPaymentInfo) {
            this.pageObj = { ...data.objPaymentInfo };
          }
        }
        this.isPageLoaded = true;
        this.isSpinner = false;
      })
      .catch((error) => {
        toastMessageHandler();
        this.isPageLoaded = true;
        this.error = error;
        this.isSpinner = false;
      });
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (this.pageRendered) return;
    if (this.isPageLoaded) {
      if (this.paymentInfoObj) {
        this.pageObj = JSON.parse(JSON.stringify(this.paymentInfoObj));
        let strPaymentTermSelectedLabel = this.paymentTermsOptions?.find(
          (data) => this.pageObj.strPaymentTerms === data.value
        );
        this.pageObj.strPaymentTermSelectedLabel = strPaymentTermSelectedLabel ? strPaymentTermSelectedLabel.label : "";
      }
      if (this.pageObj.datContractStartDate) {
        this.setMinAndMaxDate(this.pageObj.datContractStartDate);
      }
      if (this.pageObj.datContractEndDate || this.pageObj.datContractStartDate) {
        this.isEndDateDisabled = !this.isEndDateDisabled;
      }
      if ((this.pageObj.strPaymentTerms === "Fixed Date" || this.pageObj.strPaymentTerms === "Prepayment") && this.isPrepaymentAllowed) {
        this.isPrepaymentDateField = true;
        this.paymentDateErrorMsg = this.pageObj.strPaymentTerms === "Prepayment" ? pmc_quoteCheckoutFlow_paymentDateErrorMsg1 : pmc_quoteCheckoutFlow_paymentDateErrorMsg2;
        this.setMinAndMaxPrepaymentDate();
      }
      this.pageRendered = true;
    }
  }

  /**
   * On input change event handler
   * @function handleDataChange
   * @param {Event} event 
   */
  handleDataChange(event) {
    this.pageObj[event.target.dataset.id] = event.detail.value;
    if (event.target.dataset.id === "datContractStartDate") {
      this.isEndDateDisabled = false;
      this.template.querySelector(".inputDate").resetInput();
      this.pageObj.datContractEndDate = "";
      if (event.detail.value) {
        this.setMinAndMaxDate(event.detail.value);
        if (this.pageObj.strPaymentTerms === "Prepayment") {
          this.setMinAndMaxPrepaymentDate()
        }
      }
      else {
        this.minEndDate = this.today;
      }
    }
    if (event.target.dataset.id === "strPaymentTerms") {
      let strPaymentTermSelectedLabel = this.paymentTermsOptions?.find(
        (data) => event.detail.value === data.value
      );
      this.pageObj.strPaymentTermSelectedLabel = strPaymentTermSelectedLabel ? strPaymentTermSelectedLabel.label : "";
      if (this.isPrepaymentAllowed) {
        if (event.detail.value === "Fixed Date" || event.detail.value === "Prepayment") {
          this.isPrepaymentDateField = true;
          this.setMinAndMaxPrepaymentDate();
          this.paymentDateErrorMsg = event.detail.value === "Prepayment" ? pmc_quoteCheckoutFlow_paymentDateErrorMsg1 : pmc_quoteCheckoutFlow_paymentDateErrorMsg2;
        }
        else {
          this.isPrepaymentDateField = false;
          delete this.pageObj.datPrepaymentDate;
        }
      }
    }
    if (event.target.dataset.id === "datPrepaymentDate") {
      let dayValue = getRawDateUtil(event.detail.value).getDay();
      if (dayValue === 6 || dayValue === 0) {
        event.target.setCustomValidity(this.paymentDateErrorMsg)
      }
      else {
        event.target.removeReportErrorValidity();
      }
    }
  }

  /**
   * Sets min and max date
   * @function setMinAndMaxDate
   * @param {Date} startdate 
   */
  setMinAndMaxDate(dateVal) {
    let startDate = getRawDateUtil(dateVal);
    let maxEndDate = new Date(startDate);
    let minEndDate = new Date(startDate);
    minEndDate.setDate(minEndDate.getDate() + 30);
    this.minEndDate = minEndDate.toISOString().slice(0, 10);
    maxEndDate.setDate(startDate.getDate() + 547);
    this.maxEndDate = maxEndDate.toISOString().slice(0, 10);
  }

  /**
   * Sets min and max preypayment date
   * @function setMinAndMaxPrepaymentDate
   */
  setMinAndMaxPrepaymentDate() {
    this.maxPrepaymentDate = this.pageObj.strPaymentTerms === "Prepayment" && this.pageObj.datContractStartDate ? this.pageObj.datContractStartDate : null;
  }

  /**
   * checking validity of all required fields
   * @function handleErrorOnSave
   */
  handleErrorOnSave() {
    let allValid = true;
    this.template.querySelectorAll(`[data-id]`).forEach((inputComponent) => {
      if (!inputComponent.reportValidity()) {
        allValid = false;
      }
    });
    if (!allValid) {
      return true;
    }
    return false;
  }

  /**
   * Moving to the next step in the checkout flow
   * @function proceedButtonHandler
   */
  proceedButtonHandler() {
    if (this.handleErrorOnSave()) return;
    let obj = {
      ...this.pageObj,
      strCartId: this.cartId,
      lstProductFamilies: this.productFamiliesList
    };
    this.isSpinner = true;
    updatePaymentInfo({
      paymentInfoWrapper: obj
    })
      .then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
          }
          if (Number.parseInt(response.strStatusCode, 10) !== 100) {
            this.dispatchEvent(
              new CustomEvent("buttonclick", {
                detail: {
                  value: "isRequestReview",
                  step: 3,
                  paymentInfoObj: this.pageObj
                }
              })
            );
          }
        }
        this.isSpinner = false;
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isSpinner = false;
      });
  }

  /**
   * Going back to the previous step in the checkout flow
   * @function backButtonHandler
   */
  backButtonHandler() {
    this.dispatchEvent(
      new CustomEvent("buttonclick", {
        detail: {
          value: "isDeliveryInfo",
          step: 1,
          paymentInfoObj: this.pageObj
        }
      })
    );
  }
}