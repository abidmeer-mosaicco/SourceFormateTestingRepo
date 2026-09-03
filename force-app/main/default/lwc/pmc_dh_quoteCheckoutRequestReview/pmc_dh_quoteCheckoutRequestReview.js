import { LightningElement, api, track } from "lwc";
import { formatLabel, formatDate, getCurrencyAndPrice, isBrazilRegion, toastMessageHandler } from "c/pmc_dh_utilityJs";
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";

import createQuoteFromCart from "@salesforce/apex/PMC_DH_RequestForQuoteController.createQuoteFromCart";
import convertPriceInfoToResponseWrapper from "@salesforce/apex/PMC_DH_GetPriceResponseParsing.convertPriceInfoToResponseWrapper";
import getCountryValidation from "@salesforce/apex/PMC_DH_QuoteListViewController.getCountryValidation";
import DisableAddtoOrder from '@salesforce/customPermission/DisableAddtoOrder';

import pmc_requestForQuote_reviewInfo from "@salesforce/label/c.pmc_requestForQuote_reviewInfo";
import pmc_quoteCheckoutFlow_paymentInfo from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentInfo";
import pmc_quoteCheckoutFlow_paymentTerms from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentTerms";
import pmc_quoteCheckoutFlow_paymentMethod from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentMethod";
import pmc_quoteCheckoutFlow_currency from "@salesforce/label/c.pmc_quoteCheckoutFlow_currency";
import pmc_requestForQuote_quoteId from "@salesforce/label/c.pmc_requestForQuote_quoteId";
import pmc_requestForQuote_identifyQuote from "@salesforce/label/c.pmc_requestForQuote_identifyQuote";
import pmc_requestForQuote_requestedContractInfo from "@salesforce/label/c.pmc_requestForQuote_requestedContractInfo";
import pmc_quoteCheckoutFlow_startingFrom from "@salesforce/label/c.pmc_quoteCheckoutFlow_startingFrom";
import pmc_quoteCheckoutFlow_endDate from "@salesforce/label/c.pmc_quoteCheckoutFlow_endDate";
import pmc_requestForQuote_productsInformation from "@salesforce/label/c.pmc_requestForQuote_productsInformation";
import pmc_requestForQuote_totalQty from "@salesforce/label/c.pmc_requestForQuote_totalQty";
import pmc_requestForQuote_qty from "@salesforce/label/c.pmc_requestForQuote_qty";
import pmc_quoteCheckoutFlow_shipTo from "@salesforce/label/c.pmc_quoteCheckoutFlow_shipTo";
import pmc_quoteCheckoutFlow_incoterms from "@salesforce/label/c.pmc_quoteCheckoutFlow_incoterms";
import pmc_quoteCheckoutFlow_deliveryMode from "@salesforce/label/c.pmc_quoteCheckoutFlow_deliveryMode";
import pmc_quoteCheckoutFlow_back from "@salesforce/label/c.pmc_quoteCheckoutFlow_back";
import pmc_requestForQuote_submitQuoteRequest from "@salesforce/label/c.pmc_requestForQuote_submitQuoteRequest";
import pmc_requestForQuote_legalInfo from "@salesforce/label/c.pmc_requestForQuote_legalInfo";
import pmc_requestForQuote_patternMismatchErr from "@salesforce/label/c.pmc_requestForQuote_patternMismatchErr";
import pmc_requestForQuote_mandatoryFieldErr from "@salesforce/label/c.pmc_requestForQuote_mandatoryFieldErr";
import pmc_requestForQuote_finePrintUrl from "@salesforce/label/c.pmc_requestForQuote_finePrintUrl";
import pmc_contractDetails_pricePerUnit from "@salesforce/label/c.pmc_contractDetails_pricePerUnit";
import pmc_contractDetails_averagePricePerUnit from "@salesforce/label/c.pmc_contractDetails_averagePricePerUnit";
import pmc_priceSummary_priceSummaryMessage from "@salesforce/label/c.pmc_priceSummary_priceSummaryMessage";
import pmc_requestForQuote_unitOfMeasure from "@salesforce/label/c.pmc_requestForQuote_unitOfMeasure";
import pmc_requestForQuote_packType from "@salesforce/label/c.pmc_requestForQuote_packType";
import pmc_quoteCheckoutFlow_preferredShipFrom from "@salesforce/label/c.pmc_quoteCheckoutFlow_preferredShipFrom";
import pmc_quoteCheckoutFlow_paymentDate from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentDate";

/**
 * A custom LWC to display quote checkout request review details.
 * @alias Pmc_dh_quoteCheckoutRequestReview
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 *
 * @example
 * <c-pmc_dh_quote-checkout-request-review></c-pmc_dh_quote-checkout-request-review>
 */

export default class Pmc_dh_quoteCheckoutRequestReview extends LightningElement {
  @track labels = {
    pmc_requestForQuote_reviewInfo,
    pmc_quoteCheckoutFlow_paymentInfo,
    pmc_quoteCheckoutFlow_paymentTerms,
    pmc_quoteCheckoutFlow_paymentMethod,
    pmc_quoteCheckoutFlow_currency,
    pmc_requestForQuote_quoteId,
    pmc_requestForQuote_identifyQuote,
    pmc_requestForQuote_requestedContractInfo,
    pmc_quoteCheckoutFlow_startingFrom,
    pmc_quoteCheckoutFlow_endDate,
    pmc_requestForQuote_productsInformation,
    pmc_requestForQuote_totalQty,
    pmc_requestForQuote_qty,
    pmc_quoteCheckoutFlow_shipTo,
    pmc_quoteCheckoutFlow_incoterms,
    pmc_quoteCheckoutFlow_deliveryMode,
    pmc_quoteCheckoutFlow_back,
    pmc_requestForQuote_submitQuoteRequest,
    pmc_requestForQuote_legalInfo,
    pmc_requestForQuote_patternMismatchErr,
    pmc_requestForQuote_mandatoryFieldErr,
    pmc_contractDetails_pricePerUnit,
    pmc_contractDetails_averagePricePerUnit,
    pmc_priceSummary_priceSummaryMessage,
    pmc_requestForQuote_unitOfMeasure,
    pmc_requestForQuote_packType,
    pmc_quoteCheckoutFlow_preferredShipFrom,
    pmc_quoteCheckoutFlow_paymentDate
  };
  @track iconUrlObj = {
    mosaicLogoUrl: `${PMC_BrandingAssetsStaticResource}/images/logo-mosaic.png`
  };

  @track _apexError = "";
  @track quoteInfoObj = {};
  @track _paymentInfoObj = {};
  @track _productInfoArray = [];
  @track pageLoaded = false;
  @track priceLoaded = false;
  @api
  get paymentInfoObj() {
    return this._paymentInfoObj;
  }
  set paymentInfoObj(value) {
    if (value) {
      this._paymentInfoObj = JSON.parse(JSON.stringify(value));
      this._paymentInfoObj.datContractEndDate = formatDate(
        this._paymentInfoObj.datContractEndDate
      );
      this._paymentInfoObj.datContractStartDate = formatDate(
        this._paymentInfoObj.datContractStartDate
      );
      if ((this._paymentInfoObj.strPaymentTerms === "Fixed Date" || this._paymentInfoObj.strPaymentTerms === "Prepayment") && !DisableAddtoOrder && isBrazilRegion()) {
        this.isPrepaymentDateField = true;
      }
      if (this._paymentInfoObj.datPrepaymentDate)
        this._paymentInfoObj.datPrepaymentDate = formatDate(
          this._paymentInfoObj.datPrepaymentDate
        );
    }
  }
  @api
  get productInfoArray() {
    return this._productInfoArray;
  }
  set productInfoArray(value) {
    if (value) {
      this._productInfoArray = JSON.parse(JSON.stringify(value));
      this.updateShippingInfo();
    }
  }
  @api quoteInfo = {};
  @api cartId = "";

  @track priceSummaryData = null;
  @track countryRegion;
  @track priceSummaryValidation;
  isLocationBrazil = false;
  isPrepaymentDateField = false;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    const legalInfoUrl = pmc_requestForQuote_finePrintUrl;
    if (isBrazilRegion()) {
      this.isLocationBrazil = true;
    }
    this.labels.pmc_requestForQuote_legalInfo = formatLabel(
      this.labels.pmc_requestForQuote_legalInfo,
      [legalInfoUrl]
    );
    this.quoteInfoObj = JSON.parse(JSON.stringify(this.quoteInfo));
    this.countryValidation();
  }

  /**
   * Update ShipTo and ShipFrom values
   * @function updateShippingInfo
   */
  updateShippingInfo() {
    this._productInfoArray.forEach((prod) => {
      prod.shipmentInfoArray.forEach((item) => {
        let shipTo = prod.lstShipTo.find(
          (data) => item.strShipTo === data.value
        );
        item.strShipTo = shipTo ? shipTo.label : "";
        let shipFrom = prod.lstShipFrom.find(
          (data) => item.strShipFrom === data.value
        );
        item.strShipFrom = shipFrom ? shipFrom.label : "";
        let packType = prod.lstPackType.find(
          (data) => item.strPackType === data.value
        );
        item.strPackType = packType ? packType.label : "";
        let deliveryMode = prod.lstDeliveryModes?.find(
          (data) => item.strDeliveryMode === data.value
        );
        if (deliveryMode) {
          item.strDeliveryMode = deliveryMode.label;
        }
        else {
          deliveryMode = prod.lstDeliveryModesCPT?.find(
            (data) => item.strDeliveryMode === data.value
          );
          item.strDeliveryMode = deliveryMode ? deliveryMode.label : "";
        }
      });
    });
  }

  /**
   * Get country validation for price summary section
   * @function countryValidation
   */
  countryValidation() {
    this.pageLoaded = false;
    if (sessionStorage.getItem("userRegion")) {
      this.countryRegion = sessionStorage.getItem("userRegion");
    }
    getCountryValidation({
      strcountryRegion: this.countryRegion
    }).then((res) => {
      if (res && Object.keys(res).length) {
        if (JSON.parse(JSON.stringify(res)).statusCodeMessage?.strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(res)).statusCodeMessage.strStatusMessage)
        }
        this.priceSummaryValidation = res.boolFlag;
        if (this.priceSummaryValidation) {
          this.priceSummaryInfo();
        }
      }
      this.pageLoaded = true;
    }).catch((error) => {
      toastMessageHandler();
      this.pageLoaded = true;
      this._apexError = error;
    })
  }

  /**
   * Fetches price summary info
   * @function priceSummaryInfo
   */
  priceSummaryInfo() {
    this.priceLoaded = false;
    this.priceSummaryValidation = false;
    convertPriceInfoToResponseWrapper({
      strCartId: this.cartId
    }).then((res) => {
      if (res && Object.keys(res).length) {
        if (JSON.parse(JSON.stringify(res)).statusCodeMessage?.strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(res)).statusCodeMessage.strStatusMessage)
        }
        if (res.boolIsPriceEnabled) {
          this.priceSummaryValidation = true;
          this.priceSummaryData = JSON.parse(JSON.stringify(res));
          this._productInfoArray.forEach((product) => {
            let avgPricePerUnit = 0;
            if (this.priceSummaryData.lstPriceSummary && this.priceSummaryData.lstPriceSummary.length) {
              this.priceSummaryData.lstPriceSummary.forEach((price) => {
                if (product.strSku === price.strProductSKU) {
                  product.shipmentInfoArray.forEach((ship, index) => {
                    ship.pricePerUnit = price.lstCartLineItem ? price.lstCartLineItem[index].decPrice : 0;
                  })
                  avgPricePerUnit = +price.decPrice / +product.strTotalQty;
                  product.avgPricePerUnit = parseFloat(avgPricePerUnit).toFixed(2);
                }
              })
            }
          })
          this.updatePriceCurrency();
        }
      }
      this.priceLoaded = true;
      this.pageLoaded = true;
    }).catch((error) => {
      toastMessageHandler();
      this._apexError = error;
      this.priceLoaded = true;
      this.pageLoaded = true;
    })
  }

  /**
   * Updates Price related values
   * @function updatePriceCurrency
   */
  updatePriceCurrency() {
    this._productInfoArray.forEach(prod => {
      prod.shipmentInfoArray.forEach(item => {
        item.pricePerUnit = getCurrencyAndPrice(this.priceSummaryData.strCurrencyIsoCode, parseFloat(item.pricePerUnit).toFixed(2));
      })
      prod.avgPricePerUnit = getCurrencyAndPrice(this.priceSummaryData.strCurrencyIsoCode, parseFloat(prod.avgPricePerUnit).toFixed(2)
      );
    })
  }

  /**
   * On input change event handler
   * @function handleDataChange
   * @param {Event} event 
   */
  handleDataChange(event) {
    this.quoteInfoObj[event.target.dataset.id] = event.detail.value;
  }

  /**
   * Checking validity of all required fields
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
   * If product image doesn't load, display default image
   * @function handleImageError
   * @param {Event} event  
   */
  handleImageError(event) {
    event.currentTarget.src = this.iconUrlObj.mosaicLogoUrl;
    event.currentTarget.style.height = "unset";
    event.currentTarget.onerror = null;
  }

  /**
   * Going back to the Payment Info screen in the checkout flow
   * @function goBack
   */
  goBack() {
    this.dispatchEvent(
      new CustomEvent("buttonclick", {
        detail: {
          value: "isPaymentInfo",
          step: 2,
          quoteInfo: this.quoteInfoObj
        }
      })
    );
  }

  /**
   * Submit Request Review Handler
   * @function submitRequest
   */
  submitRequest() {
    if (this.handleErrorOnSave()) return;
    const requestObj = {
      cartId: this.cartId,
      quoteName: this.quoteInfoObj.quoteName
    };
    this.pageLoaded = false;
    createQuoteFromCart(requestObj)
      .then((resp) => {
        if (resp && Object.keys(resp).length) {
          if (JSON.parse(JSON.stringify(resp)).strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(resp)).strStatusMessage)
          }
          let quoteData = JSON.parse(resp.strData);
          this.quoteInfoObj.quoteId = quoteData.quoteId;
          this.quoteInfoObj.quoteNumber = quoteData.quoteNumber;
          this.dispatchEvent(
            new CustomEvent("buttonclick", {
              detail: {
                value: "isRequestSubmitted",
                step: 5,
                quoteInfo: this.quoteInfoObj
              }
            })
          );
        }
        this.pageLoaded = true;
      })
      .catch((error) => {
        toastMessageHandler();
        this.pageLoaded = true;
        this._apexError = error;
      });
  }
}