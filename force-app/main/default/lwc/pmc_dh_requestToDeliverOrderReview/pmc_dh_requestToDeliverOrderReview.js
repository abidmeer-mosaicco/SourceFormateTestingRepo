import { LightningElement, track, api } from 'lwc';
import { isBrazilRegion, formatDate, formatLabel, toastMessageHandler, getLineItemDataFromSessionStorage, getWithExpirationFromSession, upsertLineItemData } from 'c/pmc_dh_utilityJs';
import basePath from '@salesforce/community/basePath';
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";

import getContractSummary from "@salesforce/apex/PMC_DH_ContractManagementHelper.getContractSummary";
import createOrderFromCart from "@salesforce/apex/PMC_DH_RequestToDeliverController.createOrderFromCart";
import getPricingSummary from "@salesforce/apex/PMC_DH_OrderManagementController.getPricingSummaryForOrder";
import submitOrder from "@salesforce/apex/PMC_DH_OrderSubmitController.submitOrder";

import pmc_requestForQuote_productsInformation from "@salesforce/label/c.pmc_requestForQuote_productsInformation";
import pmc_contractDetails_itemNumber from "@salesforce/label/c.pmc_contractDetails_itemNumber";
import pmc_quoteHistory_totalQty from "@salesforce/label/c.pmc_quoteHistory_totalQty";
import pmc_requestToDeliver_qty from "@salesforce/label/c.pmc_requestToDeliver_qty";
import pmc_quoteCheckoutFlow_shipTo from "@salesforce/label/c.pmc_quoteCheckoutFlow_shipTo";
import pmc_quoteCheckoutFlow_incoterms from "@salesforce/label/c.pmc_quoteCheckoutFlow_incoterms";
import pmc_quoteCheckoutFlow_deliveryMode from "@salesforce/label/c.pmc_quoteCheckoutFlow_deliveryMode";
import pmc_requestToDeliverShippingInformation_deliveryInstructions from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_deliveryInstructions";
import pmc_requestToDeliverShippingInformation_sellOutPrice from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_sellOutPrice";
import pmc_requestToDeliver_notaFiscal from "@salesforce/label/c.pmc_requestToDeliver_notaFiscal";
import pmc_quoteCheckoutFlow_tons from "@salesforce/label/c.pmc_quoteCheckoutFlow_tons";
import pmc_requestToDeliver_contractInformation from "@salesforce/label/c.pmc_requestToDeliver_contractInformation";
import pmc_requestToDeliver_contractNumber from "@salesforce/label/c.pmc_requestToDeliver_contractNumber";
import pmc_contractDetails_poNumber from "@salesforce/label/c.pmc_contractDetails_poNumber";
import pmc_contractDetails_validityPeriod from "@salesforce/label/c.pmc_contractDetails_validityPeriod";
import pmc_contractDetails_contractType from "@salesforce/label/c.pmc_contractDetails_contractType";
import pmc_quoteCheckoutFlow_paymentTerms from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentTerms";
import pmc_requestToDeliver_submitOrder from "@salesforce/label/c.pmc_requestToDeliver_submitOrder";
import pmc_requestForQuote_finePrintUrl from "@salesforce/label/c.pmc_requestForQuote_finePrintUrl";
import pmc_requestForQuote_legalInfo from "@salesforce/label/c.pmc_requestForQuote_legalInfo";
import pmc_contractDetails_pricePerUnit from "@salesforce/label/c.pmc_contractDetails_pricePerUnit";
import pmc_contractDetails_averagePricePerUnit from "@salesforce/label/c.pmc_contractDetails_averagePricePerUnit";
import pmc_quoteCheckoutFlow_back from "@salesforce/label/c.pmc_quoteCheckoutFlow_back";
import pmc_fpd_callPrice from "@salesforce/label/c.pmc_fpd_callPrice";
import pmc_deleteAddress_no from "@salesforce/label/c.pmc_deleteAddress_no";
import pmc_orderReview_tooltipMsg from "@salesforce/label/c.pmc_orderReview_tooltipMsg";
import pmc_orderReview_calledPrice from "@salesforce/label/c.pmc_orderReview_calledPrice";
import pmc_orderReview_priceRequested from "@salesforce/label/c.pmc_orderReview_priceRequested";
import pmc_orderReview_yesCallPriceBtn from "@salesforce/label/c.pmc_orderReview_yesCallPriceBtn";
import pmc_orderReview_noCallPriceBtn from "@salesforce/label/c.pmc_orderReview_noCallPriceBtn";
import pmc_orderReview_cancelCalledPrice from "@salesforce/label/c.pmc_orderReview_cancelCalledPrice";
import pmc_orderReview_cancelCalledPriceBtn from "@salesforce/label/c.pmc_orderReview_cancelCalledPriceBtn";
import pmc_orderReview_cancelCalledPriceModalText from "@salesforce/label/c.pmc_orderReview_cancelCalledPriceModalText";
import pmc_orderReview_calledPriceModalText1 from "@salesforce/label/c.pmc_orderReview_calledPriceModalText1";
import pmc_orderReview_calledPriceModalText2 from "@salesforce/label/c.pmc_orderReview_calledPriceModalText2";
import pmc_orderReview_calledPriceModalText3 from "@salesforce/label/c.pmc_orderReview_calledPriceModalText3";
import pmc_requestForQuote_packType from "@salesforce/label/c.pmc_requestForQuote_packType";
import pmc_requestForQuote_packagingType from "@salesforce/label/c.pmc_requestForQuote_packagingType";
import pmc_requestToDeliverShippingInformation_notaFiscalBillingDate from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_notaFiscalBillingDate";
import pmc_quoteDetailsFlow_statusNotApplicable from "@salesforce/label/c.pmc_quoteDetailsFlow_statusNotApplicable";
import pmc_requestToDeliver_expectedShipmentDate from "@salesforce/label/c.pmc_requestToDeliver_expectedShipmentDate";

/**
 * A custom LWC to display order review page in RTD flow.
 * @alias Pmc_dh_requestToDeliverOrderReview
 * @extends LightningElement
 * @hideconstructor
 * @author Vanshika
 *
 * @example
 * <c-pmc_dh_request-to-deliver-order-review></c-pmc_dh_request-to-deliver-order-review>
 */

const CONTRACT_STATUS_FPD = "FPD";

export default class Pmc_dh_requestToDeliverOrderReview extends LightningElement {
  mosaicLogoUrl = `${PMC_BrandingAssetsStaticResource}/images/logo-mosaic.png`;
  @track isLocationBrazil = false;
  @track pageLoaded = false;
  @track orderData = {};
  @track _shipmentInfoObj = {};
  @track _shipToObj = {};
  @track _picklistObj = {};
  @track contractInfo = [];
  @track skuToPush = [];
  isCallPriceModal = false;
  isCancelCalledPriceModal = false;
  isContractTypeFPD = false;
  communityId;
  cartId;
  columnCount = 6;
  currencyCode = "$";
  backButtonTriggered = true;
  @api
  get shipmentInfoObj() {
    return this._shipmentInfoObj;
  }
  set shipmentInfoObj(value) {
    if (value) {
      this._shipmentInfoObj = JSON.parse(JSON.stringify(value));
    }
  }

  @api
  get shipToObj() {
    return this._shipToObj;
  }
  set shipToObj(value) {
    if (value) {
      this._shipToObj = JSON.parse(JSON.stringify(value));
    }
  }

  @api
  get picklistObj() {
    return this._picklistObj;
  }
  set picklistObj(value) {
    if (value) {
      this._picklistObj = JSON.parse(JSON.stringify(value));
    }
  }

  /**
   * Custom Label Details
   */
  @track labels = {
    pmc_requestForQuote_productsInformation,
    pmc_contractDetails_itemNumber,
    pmc_quoteHistory_totalQty,
    pmc_requestToDeliver_qty,
    pmc_quoteCheckoutFlow_shipTo,
    pmc_quoteCheckoutFlow_incoterms,
    pmc_quoteCheckoutFlow_deliveryMode,
    pmc_quoteCheckoutFlow_tons,
    pmc_requestToDeliver_contractInformation,
    pmc_requestToDeliver_contractNumber,
    pmc_contractDetails_poNumber,
    pmc_contractDetails_validityPeriod,
    pmc_contractDetails_contractType,
    pmc_quoteCheckoutFlow_paymentTerms,
    pmc_requestToDeliver_submitOrder,
    pmc_requestForQuote_finePrintUrl,
    pmc_requestForQuote_legalInfo,
    pmc_contractDetails_pricePerUnit,
    pmc_contractDetails_averagePricePerUnit,
    pmc_quoteCheckoutFlow_back,
    pmc_requestToDeliverShippingInformation_deliveryInstructions,
    pmc_requestToDeliverShippingInformation_sellOutPrice,
    pmc_requestToDeliver_notaFiscal,
    pmc_fpd_callPrice,
    pmc_deleteAddress_no,
    pmc_orderReview_tooltipMsg,
    pmc_orderReview_calledPrice,
    pmc_orderReview_priceRequested,
    pmc_orderReview_yesCallPriceBtn,
    pmc_orderReview_noCallPriceBtn,
    pmc_orderReview_cancelCalledPrice,
    pmc_orderReview_cancelCalledPriceBtn,
    pmc_orderReview_cancelCalledPriceModalText,
    pmc_orderReview_calledPriceModalText1,
    pmc_orderReview_calledPriceModalText2,
    pmc_orderReview_calledPriceModalText3,
    pmc_requestForQuote_packType,
    pmc_requestForQuote_packagingType,
    pmc_requestToDeliverShippingInformation_notaFiscalBillingDate,
    pmc_quoteDetailsFlow_statusNotApplicable,
    pmc_requestToDeliver_expectedShipmentDate
  };

  @track priceSummaryData = {};

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    if (isBrazilRegion()) {
      this.isLocationBrazil = !this.isLocationBrazil;
      this.columnCount = 7;
    }
    if (sessionStorage.getItem('CONTRACT_ID')) {
      this.contractId = sessionStorage.getItem("CONTRACT_ID");
    }
    if (sessionStorage.getItem('CART_ID')) {
      this.cartId = sessionStorage.getItem("CART_ID");
    }
    const legalInfoUrl = this.labels.pmc_requestForQuote_finePrintUrl;
    this.labels.pmc_requestForQuote_legalInfo = formatLabel(
      this.labels.pmc_requestForQuote_legalInfo,
      [legalInfoUrl]
    );
    this.handleShipmentInfoObj();

    const promise1 = new Promise((resolve, reject) => {
      getContractSummary({
        strContractId: this.contractId,
        strCartId: this.cartId
      }).then((result) => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
          }
          this.contractInfo.push(JSON.parse(JSON.stringify(result)));
          this.contractInfo.forEach(el => {
            el.datContractEndDate = el.datContractEndDate ? formatDate(el.datContractEndDate) : "";
            el.datContractStartDate = el.datContractStartDate ? formatDate(el.datContractStartDate) : "";
            el.validityPeriod = el.datContractStartDate + ' - ' + el.datContractEndDate;
          })
          this.isContractTypeFPD = (this.contractInfo[0].strContractType === CONTRACT_STATUS_FPD && !this.isLocationBrazil);
          resolve();
        }
      }).catch((error) => {
        reject(error);
      })
    });

    const promise2 = new Promise((resolve, reject) => {
      getPricingSummary({
        strCartId: this.cartId
      }).then((result) => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
          }
          this.priceSummaryData = JSON.parse(JSON.stringify(result));
          let currencyBRL = this.priceSummaryData.strCurrencyIsoCode === "BRL" ? true : false;
          this.currencyCode = currencyBRL ? "R$" : "$";
          resolve();
        }
      }).catch((error) => {
        reject(error)
      })
    });

    const allPromise = Promise.all([promise1, promise2]);
    allPromise.then(() => {
      this.pageLoaded = true;
    })
      .catch((error) => {
        toastMessageHandler();
        this.pageLoaded = true;
        this.error = error;
      });
  }

  adjustValuesOnSessionStorage() {

    let valueCurrentCartSelectedQuantity = parseInt(sessionStorage.getItem('currentCartSelectedQuantity'), 10);

    this._shipmentInfoObj.forEach((e1, indx) => {
      e1.lstCartItems.forEach(e2 => {
        let fromSessionContractDetailsbyProduct = JSON.parse(JSON.stringify(getWithExpirationFromSession(`lstContractItems_${e1.strProductId}`)));

        let dataFromSession = getLineItemDataFromSessionStorage(`${e1.strProductId}_${sessionStorage.getItem("CONTRACT_ID")}_${fromSessionContractDetailsbyProduct[0].strContractItemId}`);

        upsertLineItemData(`${e1.strProductId}_${sessionStorage.getItem("CONTRACT_ID")}_${fromSessionContractDetailsbyProduct[0].strContractItemId}`, dataFromSession.intAvailableQty - valueCurrentCartSelectedQuantity , dataFromSession.intOrderedQty + valueCurrentCartSelectedQuantity);
        sessionStorage.setItem("currentCartSelectedQuantity", 0);

      });
    });
  }


  /**
   * Submit Order Review Handler
   * @function submitOrderHandler
   */
  submitOrderHandler() {
    this.pageLoaded = false;
    if (this.isLocationBrazil) {
      submitOrder({
        strCartId: this.cartId,
      }).then((result) => {
        if (result && Object.keys(result).length) {
          let data = JSON.parse(result.strData)
          this.orderData = data;
          this.dispatchEvent(
            new CustomEvent("buttonclick", {
              detail: {
                value: "isOrderSubmitted",
                step: 4,
                orderData: this.orderData
              }
            })
          );
        }
        this.pageLoaded = true;
      }).catch(() => {
        toastMessageHandler();
        this.pageLoaded = true;
      })
    } else {
      let objWrapper = {
        strCartId: this.cartId,
        lstProductSKU: this.skuToPush
      }
      createOrderFromCart({
        inputParams: objWrapper
      }).then((result) => {
        if (result && Object.keys(result).length) {
          let data = JSON.parse(result.strData)
          this.orderData = data;
          this.dispatchEvent(
            new CustomEvent("buttonclick", {
              detail: {
                value: "isOrderSubmitted",
                step: 4,
                orderData: this.orderData
              }
            })
          );
        }
        this.pageLoaded = true;
      }).catch(() => {
        toastMessageHandler();
        this.pageLoaded = true;
      })
    }

    this.adjustValuesOnSessionStorage();

  }

  /**
   * Fetches count for column according to user region
   * @function getColumnsCount
   */
  getColumnsCount() {
    if (isBrazilRegion()) {
      return 7;
    }
    return 6;
  }

  /**
   * Optimising the Shipment Info Object received from Parent
   * @function handleShipmentInfoObj
   */
  handleShipmentInfoObj() {
    let baseUrl = window.location.origin;
    this._shipmentInfoObj.forEach((e1, indx) => {
      let href = `${baseUrl}${basePath}/product/${e1.strProductId}`;
      e1.href = href;
      e1.intSelectedQuantity = 0;
      e1.isMouseOver = false;
      e1.isCallPriceButton = true;
      e1.isCancelCalledPriceButton = false;
      e1.lstCartItems.forEach(e2 => {
        let shipToItem = this._shipToObj[indx].find(item =>
          (e2.strShipTo === item.value)
        );
        e2.strShipTo = shipToItem ? shipToItem.label : '';
        let incoterm = this._picklistObj.incoterms.find(inco=>(e2.strIncoterms === inco.value));
        e2.strIncoterms = incoterm ? incoterm.label : '';
        let mot = this._picklistObj.mot.find(mode=>(e2.strDeliveryMode === mode.value));
        e2.strDeliveryMode = mot ? mot.label : '';
        let pckTyp = e2.strPackType?this._picklistObj.packType.find(pckT=>(e2.strPackType === pckT.value)):'';
        e2.strPackType = pckTyp ? pckTyp.label : '';
        let pckgTyp = e2.strPackageType?this._picklistObj.packagingType.find(pckg=>(e2.strPackageType === pckg.value)):'';
        e2.strPackageType = pckgTyp ? pckgTyp.label : '';
        e1.intSelectedQuantity += e2.intQuantity;
        e2.datRequestedShipmentDate = e2.datRequestedShipmentDate ? formatDate(e2.datRequestedShipmentDate) : "";
        e2.intFiscalNumber = e2.intFiscalNumber ? e2.intFiscalNumber : this.labels.pmc_quoteDetailsFlow_statusNotApplicable;
        e2.datNotaFiscalDate = e2.datNotaFiscalDate ? formatDate(e2.datNotaFiscalDate) : this.labels.pmc_quoteDetailsFlow_statusNotApplicable;
        e2.lstShipmentPlan.forEach(e3 => {
          e3.datRequestedShipmentDate = e3.datRequestedShipmentDate ? formatDate(e3.datRequestedShipmentDate) : "";
        });
      })
    });
  }

  /**
   * If product image doesn't load, display default image
   * @function handleImageError
   * @param {Event} event
   */
  handleImageError(event) {
    event.currentTarget.src = this.mosaicLogoUrl;
    event.currentTarget.style.height = "unset";
    event.currentTarget.onerror = null;
  }

  /**
   * Goes back to shipping information
   * @function goBack
   */
  goBack() {
    this.dispatchEvent(
      new CustomEvent("buttonclick", {
        detail: {
          value: "isShipmentInfo",
          step: 1,
          shipmentInfo: this._shipmentInfoObj,
          backButtonTriggered: this.backButtonTriggered
        }
      })
    );
  }

  /**
   * Mouse over Icon Handler
   * @function handleMouseEnter
   * @param {Event} event
   */
  handleMouseEnter(event) {
    let index = parseInt(event.target.dataset.productIndex, 10);
    this._shipmentInfoObj[index].isMouseOver = true;
  }

  /**
   * Mouse Leave Handler
   * @function handleMouseLeave
   * @param {Event} event
   */
  handleMouseLeave(event) {
    let index = parseInt(event.target.dataset.productIndex, 10);
    this._shipmentInfoObj[index].isMouseOver = false;
  }

  /**
   * Open Called Price Modal
   * @function openCallPriceModalHandler
   * @param {Event} event
   */
  openCallPriceModalHandler = (event) => {
    this.handleModal(event, '.call-price-modal-wrapper', 'isCallPriceModal');
  }

  /**
   * Close Called Price Modal
   * @function handleCloseCallPriceModal
   */
  handleCloseCallPriceModal = () => {
    this.isCallPriceModal = false;
  }

  /**
   * click Handler of 'Yes, Call Price CTA' in Called Price Modal
   * @function callPriceNowHandler
   * @param {Event} event
   */
  callPriceNowHandler = (event) => {
    let index = parseInt(event.target.dataset.productIndex, 10);
    let pushSku = event.target.dataset.productSku;
    this._shipmentInfoObj[index].isCallPriceButton = false;
    this._shipmentInfoObj[index].isCancelCalledPriceButton = true;
    this.skuToPush.push(pushSku);
    this.handleCloseCallPriceModal();
  }

  /**
   * Open Cancel Called Price Modal
   * @function openCancelCalledPriceModalHandler
   * @param {Event} event
   */
  openCancelCalledPriceModalHandler = (event) => {
    this.handleModal(event, '.cancel-call-price-modal-wrapper', 'isCancelCalledPriceModal');
  }

  /**
   * add product index for modal button
   * @function handleModal
   * @param {Event} event
   * @param {string} modalSelector
   * @param {string} modalAttribute
   */
  handleModal = (event, modalSelector, modalAttribute) => {
    const index = parseInt(event.target.dataset.productIndex, 10);
    const productSku = event.target.dataset.productSku;
    this[modalAttribute] = true;
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(() => {
      const modalWrapper = this.template.querySelector(modalSelector);
      const buttonEl = modalWrapper.querySelector('lightning-button[variant="brand"]');
      if (buttonEl) {
        const existingIndex = buttonEl.getAttribute('data-product-index');
        const existingSku = buttonEl.getAttribute('data-product-sku');
        if (existingIndex && existingSku) {
          buttonEl.removeAttribute('data-product-index');
          buttonEl.removeAttribute('data-product-sku');
        }
        buttonEl.setAttribute('data-product-index', index);
        buttonEl.setAttribute('data-product-sku', productSku);
      }
    });
  }

  /**
   * Close Cancel Called Price Modal
   * @function handleCloseCancelCalledPriceModal
   */
  handleCloseCancelCalledPriceModal = () => {
    this.isCancelCalledPriceModal = false;
  }

  /**
   * click Handler of 'Yes, Cancel Called Price CTA' in Cancel Called Price Modal
   * @function cancelCalledPriceNowHandler
   * @param {Event} event
   */
  cancelCalledPriceNowHandler = (event) => {
    let index = parseInt(event.target.dataset.productIndex, 10);
    let removeSku = event.target.dataset.productSku;
    const indexToRemove = this.skuToPush.indexOf(removeSku);
    this._shipmentInfoObj[index].isCancelCalledPriceButton = false;
    this._shipmentInfoObj[index].isCallPriceButton = true;
    if (indexToRemove !== -1) {
      this.skuToPush.splice(indexToRemove, 1);
    }
    this.handleCloseCancelCalledPriceModal();
  }
}