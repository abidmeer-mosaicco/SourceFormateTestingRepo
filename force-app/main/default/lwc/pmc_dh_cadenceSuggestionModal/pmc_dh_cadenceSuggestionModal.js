import { LightningElement, api, track } from 'lwc';
import getCadenceRecords from "@salesforce/apex/PMC_DH_CadenceUtil.getCadenceRecords";
import updateCadence from "@salesforce/apex/PMC_DH_CadenceUtil.updateCadence";
import createCadence from "@salesforce/apex/PMC_DH_CadenceUtil.createCadence";
import { formatDate, toastMessageHandler } from "c/pmc_dh_utilityJs";

import pmc_addressDetails_cancel from "@salesforce/label/c.pmc_addressDetails_cancel";
import pmc_quoteCheckoutFlow_deliveryInformation from "@salesforce/label/c.pmc_quoteCheckoutFlow_deliveryInformation";
import pmc_quoteCheckoutFlow_shipTo from "@salesforce/label/c.pmc_quoteCheckoutFlow_shipTo";
import pmc_quoteCheckoutFlow_shipFrom from "@salesforce/label/c.pmc_quoteCheckoutFlow_shipFrom";
import pmc_homepage_product from "@salesforce/label/c.pmc_homepage_product";
import pmc_contractDetails_validityPeriod from "@salesforce/label/c.pmc_contractDetails_validityPeriod";
import pmc_requestToDeliverShippingInformation_frequency from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_frequency";
import pmc_quoteCheckoutFlow_quantity from "@salesforce/label/c.pmc_quoteCheckoutFlow_quantity";
import pmc_cadenceSuggestion_confirmCadenceSuggestion from "@salesforce/label/c.pmc_cadenceSuggestion_confirmCadenceSuggestion";
import pmc_requestToDeliver_qty from "@salesforce/label/c.pmc_requestToDeliver_qty";
import pmc_cadenceSuggestion_infoText from "@salesforce/label/c.pmc_cadenceSuggestion_infoText";
import pmc_cadenceSuggestion_cadenceSuggestion from "@salesforce/label/c.pmc_cadenceSuggestion_cadenceSuggestion";
import pmc_cadenceSuggestion_whichQuoteLine from "@salesforce/label/c.pmc_cadenceSuggestion_whichQuoteLine";
import pmc_cadenceSuggestion_subjectToChange from "@salesforce/label/c.pmc_cadenceSuggestion_subjectToChange";
import pmc_cadenceSuggestion_emptyQtyError from "@salesforce/label/c.pmc_cadenceSuggestion_emptyQtyError";
import pmc_cadenceSuggestion_qtyMismatchError from "@salesforce/label/c.pmc_cadenceSuggestion_qtyMismatchError";
import pmc_cadenceSuggestion_whichQuoteLineView from "@salesforce/label/c.pmc_cadenceSuggestion_whichQuoteLineView";
import pmc_cadenceSuggestion_monthly from "@salesforce/label/c.pmc_cadenceSuggestion_monthly";
import pmc_cadenceSuggestion_month from "@salesforce/label/c.pmc_cadenceSuggestion_month";
import pmc_cadenceSuggestion_viewCadence from "@salesforce/label/c.pmc_cadenceSuggestion_viewCadence";

export default class Pmc_dh_cadenceSuggestionModal extends LightningElement {
  @api quoteId;
  @api isReadOnly = false;

  @track cadenceData = [];
  @track selectedQuoteLineObj = {};
  @track labels = {
    pmc_addressDetails_cancel,
    pmc_quoteCheckoutFlow_deliveryInformation,
    pmc_quoteCheckoutFlow_shipTo,
    pmc_quoteCheckoutFlow_shipFrom,
    pmc_homepage_product,
    pmc_contractDetails_validityPeriod,
    pmc_requestToDeliverShippingInformation_frequency,
    pmc_quoteCheckoutFlow_quantity,
    pmc_cadenceSuggestion_confirmCadenceSuggestion,
    pmc_cadenceSuggestion_infoText,
    pmc_requestToDeliver_qty,
    pmc_cadenceSuggestion_subjectToChange,
    pmc_cadenceSuggestion_monthly,
    pmc_cadenceSuggestion_month,
  };
  
  modalTitle = pmc_cadenceSuggestion_cadenceSuggestion;
  headerText = pmc_cadenceSuggestion_whichQuoteLine;
  showQuantityFields = false;
  isConfirmBtnDisabled = true;
  isSpinner = false;
  pageLoaded = false;
  warningMsg = '';
  error;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    if (this.isReadOnly) {
      this.headerText = pmc_cadenceSuggestion_whichQuoteLineView;
      this.modalTitle = pmc_cadenceSuggestion_viewCadence;
    }
    this.loadCadenceData();
  }

  /**
   * fetch cadence details from backend method
   * @function loadCadenceData
   */
  loadCadenceData = () => {
    this.isSpinner = true;
    getCadenceRecords({
      strQuoteId: this.quoteId
    })
      .then((result) => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
          }
          if (!result.lstQuoteCadenceRecords[0].boolCadenceAvailable) {
            this.createCadence()
          }
          else {
            this.cadenceData = JSON.parse(JSON.stringify(result)).lstQuoteCadenceRecords;
            this.buildCadenceData();
            this.pageLoaded = true;
            this.isSpinner = false;
          }
        }
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.pageLoaded = true;
        this.isSpinner = false;
      });
  };

  /**
   * Format cadence data
   * @function buildCadenceData
   */
  buildCadenceData() {
    this.showQuantityFields = false;
    this.isConfirmBtnDisabled = true;
    this.cadenceData.forEach(item => {
      item.strStartDate = item.strStartDate ? formatDate(item.strStartDate) : "";
      item.strEndDate = item.strEndDate ? formatDate(item.strEndDate) : "";
      item.isRadioBtnChecked = false;
      if (item.lstCadence) {
        switch (item.lstCadence.length) {
          case 0:
            item.isMoreThanOneRecord = false;
            item.isMoreThanTwoRecords = false;
            break;
          case 1:
            item.isMoreThanOneRecord = false;
            item.isMoreThanTwoRecords = false;
            break;
          case 2:
            item.isMoreThanOneRecord = true;
            item.isMoreThanTwoRecords = false;
            break;
          default:
            item.isMoreThanOneRecord = true;
            item.isMoreThanTwoRecords = true;
            break;
        }
      }
    })
  }

  /**
   * Handle Data Change
   * @function handleDataChange
   * @param {Event} event 
   */
  handleDataChange(event) {
    if (event.detail.value === '') {
      this.selectedQuoteLineObj.lstCadence.find((item) =>
        item.strCadenceId === event.currentTarget.dataset.cadenceId
      ).intQuantity = '';

      this.cadenceData.find((item) =>
        item.strQuoteLineId === this.selectedQuoteLineObj.strQuoteLineId
      ).lstCadence.find((item) =>
        item.strCadenceId === event.currentTarget.dataset.cadenceId
      ).intQuantity = '';
    }
    else {
      this.selectedQuoteLineObj.lstCadence.find((item) =>
        item.strCadenceId === event.currentTarget.dataset.cadenceId
      ).intQuantity = Number(event.detail.value);

      this.cadenceData.find((item) =>
        item.strQuoteLineId === this.selectedQuoteLineObj.strQuoteLineId
      ).lstCadence.find((item) =>
        item.strCadenceId === event.currentTarget.dataset.cadenceId
      ).intQuantity = Number(event.detail.value);
    }
  }

  /**
   * Calculate totlal entered quantity
   * @function calculateTotalQty
   */
  calculateTotalQty() {
    let totalEnteredQty = 0;
    if (this.selectedQuoteLineObj?.lstCadence) {
      this.selectedQuoteLineObj?.lstCadence.forEach((item) => {
        totalEnteredQty += Number(item.intQuantity)
      })
    }
    return totalEnteredQty;
  }

  /**
   * Handle click on radio button
   * @function handleClick
   * @param {Event} event 
   */
  handleClick(event) {
    if (this.checkQuantityFieldsError()) {
      event.preventDefault();
    }
  }

  /**
   * Handle radio button change
   * @function handleRadioOptionChange
   * @param {Event} event 
   */
  handleRadioOptionChange(event) {
    this.cadenceData.forEach((item) => {
      if (item.strQuoteLineId === event.target.dataset.quoteLineId) {
        item.isRadioBtnChecked = true;
        this.selectedQuoteLineObj = JSON.parse(JSON.stringify(item));
      }
      else {
        item.isRadioBtnChecked = false
      }
    });
    this.showQuantityFields = true;
    this.warningMsg = "";
    this.isConfirmBtnDisabled = false;
  }

  /**
   * validate quantity fields
   * @function checkQuantityFieldsError
   */
  checkQuantityFieldsError() {
    let isAnyQuantityEmpty = false;
    let totalEnteredQty = this.calculateTotalQty();
    let isQuantityMismatch = this.selectedQuoteLineObj.intTotalQuantity ? this.selectedQuoteLineObj.intTotalQuantity !== totalEnteredQty : false;
    if (this.selectedQuoteLineObj?.lstCadence) {
      this.selectedQuoteLineObj?.lstCadence.forEach((item) => {
        if (item.intQuantity === "") {
          isAnyQuantityEmpty = true
        }
      })
    }
    if (isAnyQuantityEmpty) {
      this.warningMsg = pmc_cadenceSuggestion_emptyQtyError
    }
    else if (isQuantityMismatch) {
      this.warningMsg = pmc_cadenceSuggestion_qtyMismatchError
    } else {
      this.warningMsg = ""
    }
    return (isAnyQuantityEmpty || isQuantityMismatch)
  }

  /**
   * Handling Confirm button click 
   * @function confirmBtnHandler
   */
  confirmBtnHandler() {
    if (this.checkQuantityFieldsError()) return;
    this.updateCadence();
  }

  /**
   * Saving updated cadence record in Backend 
   * @function updateCadence
   */
  updateCadence() {
    this.isSpinner = true;
    let lstCadenceWrapper = [];
    this.cadenceData.forEach((item) => {
      item.lstCadence.forEach((cadence) => {
        lstCadenceWrapper.push(cadence)
      })
    });
    updateCadence({
      lstCadenceWrapper: lstCadenceWrapper
    })
      .then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
          }
          if (response.strStatusCode === "000") {
            this.closeModalHandler();
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
   * creating cadence record in Backend 
   * @function createCadence
   */
  createCadence = () => {
    createCadence({
      strQuoteId: this.quoteId,
      boolIsContractPeriodChanged: false
    })
      .then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
          }
          if (response.strStatusCode === "000") {
            this.loadCadenceData()
          }
        }
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
      });
  }

  /**
   * close modal 
   * @function closeModalHandler
   */
  closeModalHandler() {
    this.dispatchEvent(new CustomEvent("closemodal"));
  }
}