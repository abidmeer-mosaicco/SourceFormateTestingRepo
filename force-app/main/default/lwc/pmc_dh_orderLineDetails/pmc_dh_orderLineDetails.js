import { LightningElement, api, track } from "lwc";
import basePath from "@salesforce/community/basePath";
import { formatDate, isBrazilRegion, toastMessageHandler } from "c/pmc_dh_utilityJs";
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import getOrderLineDetails from "@salesforce/apex/PMC_DH_OrderLineDetailsController.getOrderLineDetails";
import updateCustomerCallPriceDate from "@salesforce/apex/PMC_DH_OrderManagementController.updateCustomerCallPriceDate";
import getDocDownload from "@salesforce/apex/PMC_DH_DocumentDownloadController.getDocDownload";

import pmc_breadcrumb_homepage from "@salesforce/label/c.pmc_breadcrumb_homepage";
import pmc_orderHistory_myOrderHistory from "@salesforce/label/c.pmc_orderHistory_myOrderHistory";
import pmc_orderDetails_order from "@salesforce/label/c.pmc_orderDetails_order";
import pmc_shipmentDetails_orderLineNumber from "@salesforce/label/c.pmc_shipmentDetails_orderLineNumber";
import pmc_customTabs_previous from "@salesforce/label/c.pmc_customTabs_previous";
import pmc_customTabs_next from "@salesforce/label/c.pmc_customTabs_next";
import pmc_shipmentDetails_orderLineSummary from "@salesforce/label/c.pmc_shipmentDetails_orderLineSummary";
import pmc_leadManagement_product from "@salesforce/label/c.pmc_leadManagement_product";
import pmc_quoteDetailsFlow_customerName from "@salesforce/label/c.pmc_quoteDetailsFlow_customerName";
import pmc_quoteCheckoutFlow_shipTo from "@salesforce/label/c.pmc_quoteCheckoutFlow_shipTo";
import pmc_quoteCheckoutFlow_deliveryInformation from "@salesforce/label/c.pmc_quoteCheckoutFlow_deliveryInformation";
import pmc_shipmentDetails_orderLineQty from "@salesforce/label/c.pmc_shipmentDetails_orderLineQty";
import pmc_shipmentDetails_orderLineStatus from "@salesforce/label/c.pmc_shipmentDetails_orderLineStatus";
import pmc_shipmentDetails_viewAll from "@salesforce/label/c.pmc_shipmentDetails_viewAll";
import pmc_shipmentDetails_scheduled from "@salesforce/label/c.pmc_shipmentDetails_scheduled";
import pmc_shipmentDetails_delivered from "@salesforce/label/c.pmc_shipmentDetails_delivered";
import pmc_shipmentDetails_inTransit from "@salesforce/label/c.pmc_shipmentDetails_inTransit";
import pmc_contractDetails_poNumber from "@salesforce/label/c.pmc_contractDetails_poNumber";
import pmc_shipmentDetails_vehicleId from "@salesforce/label/c.pmc_shipmentDetails_vehicleId";
import pmc_shipmentDetails_estShipmentDt from "@salesforce/label/c.pmc_shipmentDetails_estShipmentDt";
import pmc_shipmentDetails_deliveryQty from "@salesforce/label/c.pmc_shipmentDetails_deliveryQty";
import pmc_shipmentDetails_eta from "@salesforce/label/c.pmc_shipmentDetails_eta";
import pmc_shipmentDetails_document from "@salesforce/label/c.pmc_shipmentDetails_document";
import pmc_shipmentDetails_currentLoc from "@salesforce/label/c.pmc_shipmentDetails_currentLoc";
import pmc_shipmentDetails_chooseDoc from "@salesforce/label/c.pmc_shipmentDetails_chooseDoc";
import pmc_addressDetails_cancel from "@salesforce/label/c.pmc_addressDetails_cancel";
import pmc_leadManagement_confirm from "@salesforce/label/c.pmc_leadManagement_confirm";
import pmc_fpd_callPriceConfMsg from "@salesforce/label/c.pmc_fpd_callPriceConfMsg";
import pmc_fpd_callPrice from "@salesforce/label/c.pmc_fpd_callPrice";
import pmc_fpd_callPriceRequested from "@salesforce/label/c.pmc_fpd_callPriceRequested";
import pmc_fpd_callPriceDate from "@salesforce/label/c.pmc_fpd_callPriceDate";
import PMC_DH_TrizzyTrackingLinkBR from "@salesforce/label/c.PMC_DH_TrizzyTrackingLinkBR";
import pmc_orderStatus_notYetShipped from "@salesforce/label/c.pmc_orderStatus_notYetShipped";
import pmc_orderDetails_statusPlaced from "@salesforce/label/c.pmc_orderDetails_statusPlaced";
import PMC_DH_InProgress from "@salesforce/label/c.PMC_DH_InProgress";
import pmc_orderStatus_partiallyShipped from "@salesforce/label/c.pmc_orderStatus_partiallyShipped";
import pmc_orderStatus_completelyShipped from "@salesforce/label/c.pmc_orderStatus_completelyShipped";
import pmc_orderHistory_download from "@salesforce/label/c.pmc_orderHistory_download";

const STATE = {
  ACTIVE: "active",
  INACTIVE: "inActive"
}

const BADGE_STATUS_WARNING = 'warning';

/**
 * A custom LWC to display order line details.
 * @alias Pmc_dh_orderLineDetails
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 *
 * @example
 * <c-pmc_dh_order-line-details></c-pmc_dh_order-line-details>
 */

export default class Pmc_dh_orderLineDetails extends LightningElement {
  @api orderLineId = "";
  @api orderId = "";
  @api orderNumber;
  @api showCallPrice = false;
  @api showCallPriceBtn = false;
  @api orderLineItems = [];
  pageRendered = false;
  isArrowNeeded = false;
  leftArrow;
  rightArrow;
  arrowMargin = 16;
  scrollSize = 0;
  recordsPerPage = 3;
  isCallPriceModalOpen = false;
  isSpinner = false;
  pageLoaded = false;
  isLocationBrazil = false;
  isDocumentListDisabled;
  trizzyUrl = PMC_DH_TrizzyTrackingLinkBR;
  _orderLineId = '';
  @track _tabsArray = [];
  @track prevOrderLine = {};
  @track nextOrderLine = {};
  @track iconUrlObj = {
    download: `${PMC_BrandingAssetsStaticResource}/icons/icon-download.svg`
  };

  @track tabsArray = [
    {
      id: 1,
      state: STATE.ACTIVE,
      strTabLabel: pmc_shipmentDetails_viewAll,
      strTabValue: pmc_shipmentDetails_viewAll
    },
    {
      id: 2,
      state: STATE.INACTIVE,
      strTabLabel: pmc_orderStatus_notYetShipped,
      strTabValue: pmc_orderStatus_notYetShipped
    },
    {
      id: 3,
      state: STATE.INACTIVE,
      strTabLabel: pmc_orderStatus_partiallyShipped,
      strTabValue: pmc_orderStatus_partiallyShipped
    },
    {
      id: 4,
      state: STATE.INACTIVE,
      strTabLabel: pmc_orderStatus_completelyShipped,
      strTabValue: pmc_orderStatus_completelyShipped
    }
  ];

  @track labels = {
    pmc_breadcrumb_homepage,
    pmc_orderHistory_myOrderHistory,
    pmc_orderDetails_order,
    pmc_shipmentDetails_orderLineNumber,
    pmc_customTabs_previous,
    pmc_customTabs_next,
    pmc_shipmentDetails_orderLineSummary,
    pmc_leadManagement_product,
    pmc_quoteDetailsFlow_customerName,
    pmc_quoteCheckoutFlow_shipTo,
    pmc_quoteCheckoutFlow_deliveryInformation,
    pmc_shipmentDetails_orderLineQty,
    pmc_shipmentDetails_orderLineStatus,
    pmc_shipmentDetails_viewAll,
    pmc_shipmentDetails_scheduled,
    pmc_shipmentDetails_inTransit,
    pmc_shipmentDetails_delivered,
    pmc_contractDetails_poNumber,
    pmc_shipmentDetails_vehicleId,
    pmc_shipmentDetails_estShipmentDt,
    pmc_shipmentDetails_deliveryQty,
    pmc_shipmentDetails_eta,
    pmc_shipmentDetails_document,
    pmc_shipmentDetails_currentLoc,
    pmc_shipmentDetails_chooseDoc,
    pmc_addressDetails_cancel,
    pmc_leadManagement_confirm,
    pmc_fpd_callPriceConfMsg,
    pmc_fpd_callPrice,
    pmc_fpd_callPriceRequested,
    pmc_fpd_callPriceDate,
    pmc_orderStatus_notYetShipped,
    PMC_DH_InProgress,
    pmc_orderStatus_partiallyShipped,
    pmc_orderStatus_completelyShipped,
    pmc_orderDetails_statusPlaced,
    pmc_orderHistory_download
  };

  @track crumbs = [
    {
      label: this.labels.pmc_breadcrumb_homepage,
      url: `${basePath}/`,
      isActive: false
    },
    {
      label: this.labels.pmc_orderHistory_myOrderHistory,
      url: `${basePath}/orders`,
      isActive: false
    },
    {
      label: this.labels.pmc_orderDetails_order,
      url: "",
      isCustomNavigation: true,
      isActive: false
    },
    {
      label: this.labels.pmc_shipmentDetails_orderLineNumber,
      url: "",
      isActive: true
    }
  ];

  @track orderLineItem = {};
  @track lstDeliveries = [];
  @track lstFilteredDeliveries = [];

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    if (isBrazilRegion()) {
      this.isLocationBrazil = true;
    }
    this._orderLineId = this.orderLineId;
    if (!this.orderLineId) {
      let params = new URLSearchParams(window.location.search);
      this._orderLineId = params.get('orderLineId');
    }
    this.fetchOrderLineDetails(this._orderLineId);
    const scrollOptions = {
      left: 0,
      top: 0,
      behavior: 'smooth'
    }
    window.scrollTo(scrollOptions);
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (this.pageRendered) return;
    if (this.isLocationBrazil) {
      this.template.querySelector(".list-container")?.classList.add("brazil-shipments");
    }
    if (this.getMenuSize() > this.getMenuWrapperSize()) {
      this.isArrowNeeded = true;
      this.leftArrow = this.template.querySelector(".left-arrow");
      this.rightArrow = this.template.querySelector(".right-arrow");

      this.template.querySelector(".menu").classList.add("menu-padding");
      this.template
        .querySelector('.item[data-state="active"]')
        .scrollIntoView();

      if (this.leftArrow && this.rightArrow) {
        this.pageRendered = true;
        this.handleEventListner();
      }
    }
  }

  /**
   * Fetches order line details from BE
   * @function fetchOrderLineDetails
   * @param {string} orderLineId 
   */
  fetchOrderLineDetails(orderLineId) {
    this.isSpinner = true;
    let strLocale = sessionStorage.getItem("userRegion");
    getOrderLineDetails({
      orderLineId,
      strLocale: strLocale
    })
      .then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).statusCodeMessage.strStatusMessage)
          }
          this.orderLineItem = JSON.parse(JSON.stringify(response));
          this.updateOrderLineItem();
        }
        this.isSpinner = false;
        this.pageLoaded = true;
      })
      .catch(() => {
        toastMessageHandler();
        this.isSpinner = false;
        this.pageLoaded = true;
      })
  }

  /**
   * Does following operations which usually takes place when the component is loaded:
   * Format dates
   * Updates breadcrumbs for Order Number and Order Line Number
   * Updates the tab count based on different statuses
   * Gets the prev and next order line item
   * @function updateOrderLineItem
   */
  updateOrderLineItem() {
    this.orderLineItem.strOrderLine = this.orderLineItem.strOrderLine ? this.orderLineItem.strOrderLine.padStart(2, '0') : "-";
    if (this.showCallPrice) {
      this.orderLineItem.callPriceCTALabel = this.orderLineItem.objOrderLineSummary.boolCallPriceRequestedBySystem || !this.orderLineItem.objOrderLineSummary.boolCheckModal ? pmc_fpd_callPrice : pmc_fpd_callPriceRequested;
      this.orderLineItem.callPriceCTADisabled = this.orderLineItem.objOrderLineSummary.boolCheckModal;
    }
    this.orderLineItem.objOrderLineSummary.formattedCallPriceDate = this.orderLineItem.objOrderLineSummary.datCallPriceDate ? formatDate(this.orderLineItem.objOrderLineSummary.datCallPriceDate) : '';

    this.orderLineItem.objOrderLineSummary.strShipToAdd =
      this.orderLineItem.objOrderLineSummary.strShipTo.strAddressLine1 +
      (this.orderLineItem.objOrderLineSummary.strShipTo.strAddressLine2
        ? " " + this.orderLineItem.objOrderLineSummary.strShipTo.strAddressLine2
        : "") +
      ", " +
      (this.orderLineItem.objOrderLineSummary.strShipTo.strCity || '') +
      ", " +
      (this.orderLineItem.objOrderLineSummary.strShipTo.strState || '') +
      " " +
      (this.orderLineItem.objOrderLineSummary.strShipTo.strZipCode || '');

    if ([this.labels.pmc_orderDetails_statusPlaced, this.labels.PMC_DH_InProgress, pmc_orderStatus_partiallyShipped].includes(this.orderLineItem.objOrderLineSummary.strOrderLineStatus)) {
      this.orderLineItem.objOrderLineSummary.strOrderLineBadgeStatus = BADGE_STATUS_WARNING;
    }
    this.lstDeliveries = JSON.parse(
      JSON.stringify(this.orderLineItem.objOrderLineSummary.lstDeliveries)
    );
    this.lstDeliveries.forEach((del) => {
      del.datEstimatedShipmentDate = del.datEstimatedShipmentDate ? formatDate(del.datEstimatedShipmentDate) : '';
      del.strETA = del.strETA ? formatDate(del.strETA) : 'N/A';
      if ([this.labels.pmc_orderStatus_notYetShipped, this.labels.PMC_DH_InProgress, pmc_orderStatus_partiallyShipped].includes(del.strStatus))
        del.strBadgeStatus = BADGE_STATUS_WARNING;
      del.lstDocument = this.getUniqueDocuments(del.lstDocument);
      del.isDocumentListDisabled = (del.lstDocument && Object.keys(del.lstDocument).length) ? false : true;
    });
    this.lstFilteredDeliveries = JSON.parse(JSON.stringify(this.lstDeliveries));
    this.template
      .querySelector("c-pmc_dh_pagination")
      ?.setDataOnSearch(this.lstFilteredDeliveries);
    this.crumbs = this.crumbs.map((e, i) => {
      if (i === 2) {
        e.label = this.labels.pmc_orderDetails_order + " " + this.orderNumber;
        e.url = `${basePath}/order/${this.orderId}/detail?orderNumber=${this.orderNumber}&orderId=${this.orderId}`;
      }
      if (i === 3) {
        e.label =
          this.labels.pmc_shipmentDetails_orderLineNumber +
          " #" +
          this.orderLineItem.strOrderLine;
      }
      return e;
    });
    this._tabsArray = JSON.parse(JSON.stringify(this.tabsArray));
    this.updateTabCount();
    this.getPrevOrderLineItem();
    this.getNextOrderLineItem();
  }

  /**
   * Get the unique documents from list
   * @param {Array} lstDocuments 
   * @returns Array
   */
  getUniqueDocuments(lstDocuments) {
    let mapObj = new Map(
      lstDocuments.map((obj) => {
          return [JSON.stringify(obj), obj];
    })
    );
    return Array.from(mapObj.values());
  }

  /**
   * Click Handler for Prev and Next Order Line Items
   * @function navigateToOrderLineDetails
   * @param {Event} event 
   */
  navigateToOrderLineDetails(event) {
    let params = new URLSearchParams(window.location.search);
    params.set('orderLineId', event.target.dataset.id);
    window.location.search = params;
    this.fetchOrderLineDetails(event.target.dataset.id);
  }

  navigateToDetailOnEnter(event) {
    if (event.keyCode === 13) {
      this.navigateToOrderLineDetails(event);
    }
  }

  /**
   * Updates the tab count based on statuses
   * @function updateTabCount
   */
  updateTabCount() {
    this._tabsArray = JSON.parse(JSON.stringify(this.tabsArray)).map((tab) => {
      let count = 0;
      switch (tab.strTabValue) {
        case this.labels.pmc_orderStatus_notYetShipped:
        case this.labels.pmc_orderStatus_partiallyShipped:
        case this.labels.pmc_orderStatus_completelyShipped:
          count = this.lstDeliveries?.filter(
            (del) => del.strStatus === tab.strTabValue
          )?.length;
          break;
        default:
          count = this.lstDeliveries.length;
      }
      tab.strTabLabel = tab.strTabLabel + " (" + count + ")";
      return tab;
    });
  }

  /**
   * Adding event listeners to left and right arrow on status menu
   * @function handleEventListner
   */
  handleEventListner() {
    this.rightArrow.addEventListener("click", () => {
      this.scrollSize = this.getNextItemWidth(true) - this.getMenuWrapperSize() + 2 * this.arrowMargin;
      this.template.querySelector(".menu-wrapper").scroll({
        left: this.scrollSize,
        behavior: "smooth",
        inline: "nearest"
      });
    });

    this.leftArrow.addEventListener("click", () => {
      this.scrollSize = this.getNextItemWidth(false);

      this.template.querySelector(".menu-wrapper").scroll({
        left: this.scrollSize,
        behavior: "smooth",
        inline: "nearest"
      });
    });

    this.template
      .querySelector(".menu-wrapper")
      .addEventListener("scroll", () => { });
  }

  /**
   * Sets/resets 'isDownloadEnabled' and 'selectedDoc' based on the selection of document
   * @function handleDataChange
   * @param {Event} event 
   */
  handleDataChange(event) {
    const selectedOrderItem = this.lstFilteredDeliveries?.find(
      (e) => e.strDeliveryId === event.target.dataset.itemId
    );
    if (event.detail.value && selectedOrderItem) {
      selectedOrderItem.isDownloadEnabled = true;
    } else {
      selectedOrderItem.isDownloadEnabled = false;
    }
    selectedOrderItem.selectedDoc = event.detail.value;
    selectedOrderItem.docName = selectedOrderItem.lstDocument.find((doc) => doc.value === event.detail.value).label;
    let lstDocCodeRecord = Object.entries(selectedOrderItem.mapDocRecord)
    const selectedDocRecord = lstDocCodeRecord?.find(
      (e) => e[0] === event.detail.value
    );
    if (selectedDocRecord.length) {
      selectedOrderItem.deliveryNumber = selectedDocRecord[1].strDeliveryNumber ? selectedDocRecord[1].strDeliveryNumber : "";
      selectedOrderItem.itemNumber = selectedDocRecord[1].strItemNumber ? selectedDocRecord[1].strItemNumber : "";
      selectedOrderItem.billingDocNumber = selectedDocRecord[1].strBillingDocNumber ? selectedDocRecord[1].strBillingDocNumber : "";
    }
  }

  /**
   * Downloads delivery document after selecting the type of document from the list
   * @function downloadDocument
   * @param {Event} event 
   */
  downloadDocument(event) {
    this.isSpinner = true;
    const selectedOrderItem = this.lstFilteredDeliveries?.find(
      (e) => e.strDeliveryId === event.target.dataset.itemId
    );
    let docWrapper = {
      strDocumentCode: selectedOrderItem.selectedDoc,
      strDeliveryNumber: selectedOrderItem.deliveryNumber,
      strItemNumber: selectedOrderItem.itemNumber,
      strBillingDocNumber: selectedOrderItem.billingDocNumber,
    }
    getDocDownload({
      objData: docWrapper
    }).then((response) => {
      if (response && Object.keys(response).length) {
        if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(response)).statusCodeMessage.strStatusMessage)
        }
        if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusCode === "100") {
          toastMessageHandler("PMC_DH_GenericTechnicalError")
        }
        if (response?.objData && response.objData.strStatusCode === "S") {
          const blob = this.base64toBlob(JSON.parse(JSON.stringify(response.objData)).strData, "application/pdf");
          const blobUrl = URL.createObjectURL(blob);
          this.downloadDoc(blobUrl, selectedOrderItem.docName);
        }
      }
      this.isSpinner = false;
    }).catch(() => {
      toastMessageHandler();
      this.isSpinner = false;
    })
  }

  /**
   * Download Document in system
   * @function downloadDoc
   * @param {string} url 
   * @param {string} docName 
   */
  downloadDoc(url, docName) {
    var link = document.createElement('a');
    link.href = url;
    link.download = docName;
    link.click();
    URL.revokeObjectURL(url);
  }

  /**
   * Convert base64 data to Blob
   * @function base64toBlob
   * @param {string} b64Data 
   * @param {string} contentType 
   * @param {number} sliceSize 
   * @returns BLOB
   */
  base64toBlob(b64Data, contentType = "", sliceSize = 512) {
    const byteCharacters = window.atob(b64Data);
    const byteArrays = [];
    for (let offset = 0; offset < byteCharacters.length; offset += sliceSize) {
      const slice = byteCharacters.slice(offset, offset + sliceSize);

      const byteNumbers = new Array(slice.length);
      for (let i = 0; i < slice.length; i++) {
        byteNumbers[i] = slice.charCodeAt(i);
      }
      const byteArray = new Uint8Array(byteNumbers);
      byteArrays.push(byteArray);
    }
    const blob = new Blob(byteArrays, { type: contentType });
    return blob;
  }

  /**
   * Gets the previous order line item
   * @function getPrevOrderLineItem
   */
  getPrevOrderLineItem() {
    let currIndx = this.orderLineItems.findIndex(
      (orderLine) => orderLine.strOrderItemId === this.orderLineItem.strOrderLineItemId
    );
    this.prevOrderLine =
      currIndx > 0 && this.orderLineItems[currIndx - 1]
        ? this.orderLineItems[currIndx - 1]
        : "";
  }

  /**
   * Gets the next order line item
   * @function getNextOrderLineItem
   */
  getNextOrderLineItem() {
    let currIndx = this.orderLineItems.findIndex(
      (orderLine) => orderLine.strOrderItemId === this.orderLineItem.strOrderLineItemId
    );
    this.nextOrderLine =
      currIndx > -1 && this.orderLineItems[currIndx + 1]
        ? this.orderLineItems[currIndx + 1]
        : "";
  }

  /**
   * Returns menu wrapper size
   * @function getMenuWrapperSize
   * @returns {number}
   */
  getMenuWrapperSize() {
    return this.template.querySelector(".menu-wrapper")?.clientWidth;
  }

  /**
   * Returns menu item size
   * @function getMenuSize
   * @returns {number}
   */
  getMenuSize() {
    let width = 0;
    this.template.querySelectorAll(".item").forEach((el) => {
      width += el.clientWidth;
    });

    return width;
  }

  /**
   * Return menu item position
   * @function getMenuPosition
   * @returns {number}
   */
  getMenuPosition() {
    return this.template.querySelector(".menu-wrapper").scrollLeft;
  }

  /**
   * Returns Next Menu Item width
   * @function getNextItemWidth
   * @param {boolean} flag 
   * @returns {number}
   */
  getNextItemWidth(flag) {
    const position = flag
      ? this.getMenuPosition() + this.getMenuWrapperSize()
      : this.getMenuPosition();
    let width = 0;
    let item;
    for (let el of this.template.querySelectorAll(".item")) {
      width += el.clientWidth;
      if (width >= position) {
        if (!flag) width -= el.clientWidth;
        break;
      }
      item = el;
    }
    return Math.floor(width) === Math.floor(position)
      ? width - item?.clientWidth
      : width;
  }

  /**
   * Handles the tab change on enter key
   * @function handleTabChangeOnEnter
   * @param {Event} event 
   */
  handleTabChangeOnEnter(event) {
    if (event.keyCode === 13) {
      this.handleItemClickEvent(event);
    }
  }

  /**
   * Displaying contents of the selected tab 
   * @function handleItemClickEvent
   * @param {Event} event 
   */
  handleItemClickEvent(event) {
    const id = event.target?.dataset?.id;
    const activeTabValue = event.target?.dataset?.value;
    this._tabsArray.forEach((item) => {
      item.state = item.id.toString() === id.toString() ? STATE.ACTIVE : STATE.INACTIVE;
    });
    this.displayDeliveryList(activeTabValue);
    this.template
      .querySelectorAll('.docpicklist[data-id="strDocNm"]')
      .forEach((el) => {
        el.resetInput();
      });
    event.target.scrollIntoView();
  }

  /**
   * Display list on the basis of selected status tab
   * @function displayDeliveryList
   * @param {string} tabValue 
   */
  displayDeliveryList(tabValue) {
    switch (tabValue) {
      case this.labels.pmc_orderStatus_notYetShipped:
      case this.labels.pmc_orderStatus_partiallyShipped:
      case this.labels.pmc_orderStatus_completelyShipped:
        this.lstDeliveries = JSON.parse(
          JSON.stringify(this.orderLineItem.objOrderLineSummary.lstDeliveries)
        ).filter((e) => e.strStatus === tabValue);
        break;
      default:
        this.lstDeliveries = JSON.parse(
          JSON.stringify(this.orderLineItem.objOrderLineSummary.lstDeliveries)
        );
    }
    this.lstDeliveries.forEach((del) => {
      del.datEstimatedShipmentDate = del.datEstimatedShipmentDate ? formatDate(del.datEstimatedShipmentDate) : '';
      del.strETA = del.strETA ? formatDate(del.strETA) : 'N/A';
      if ([this.labels.pmc_orderStatus_notYetShipped, this.labels.pmc_orderStatus_partiallyShipped].includes(del.strStatus)) {
        del.strBadgeStatus = BADGE_STATUS_WARNING;
      }
      del.lstDocument = this.getUniqueDocuments(del.lstDocument);
      del.isDocumentListDisabled = (del.lstDocument && Object.keys(del.lstDocument).length) ? false : true;
    })
    this.lstFilteredDeliveries = JSON.parse(JSON.stringify(this.lstDeliveries));
    this.template
      .querySelector("c-pmc_dh_pagination")
      ?.setDataOnSearch(this.lstFilteredDeliveries);
  }

  /**
   * Return back to Order Details Page
   * @function landToOrderDetailsView
   */
  landToOrderDetailsView() {
    this.dispatchEvent(new CustomEvent("vieworderdetails"));
  }

  /**
   * Updating filtered data to display only current page details
   * @function updatePaginatedData
   * @param {Event} event
   */
  updatePaginatedData(event) {
    this.lstFilteredDeliveries = event.detail;
  }

  /**
   * Open call price confirmation modal
   * @function openCallPriceModal
   */
  openCallPriceModal() {
    if (this.orderLineItem.callPriceCTADisabled) return;
    this.isCallPriceModalOpen = true;
  }

  /**
   * Close call price modal
   * @function cancelCallPrice
   */
  cancelCallPrice() {
    this.isCallPriceModalOpen = false;
  }

  /**
   * Method to call price on an order line item
   * @function confirmSubmit
   */
  confirmSubmit() {
    if (this.orderLineItem.callPriceCTADisabled) return;
    this.isSpinner = true;
    updateCustomerCallPriceDate({ lstOrderItemIDs: [this._orderLineId], boolIsCustomerRequested: true })
      .then((response) => {
        if (response.strStatusCode === '000') {
          this.orderLineItem.callPriceCTALabel = pmc_fpd_callPriceRequested;
          this.orderLineItem.callPriceCTADisabled = true;
        }
        this.isCallPriceModalOpen = false;
        this.isSpinner = false;
      }).catch(() => {
        toastMessageHandler();
        this.isCallPriceModalOpen = false;
        this.isSpinner = false;
      })
  }

  /**
   * Dispatching event to parent component for handling navigation to delivery tracking page
   * @function navigateToDeliveryTrackingPage
   * @param {Event} event 
   */
  navigateToDeliveryTrackingPage(event) {
    this.dispatchEvent(new CustomEvent("navigatetodeliverytracking", {
      detail: {
        vehicleId: event.currentTarget.dataset.id,
        orderLineNum: event.currentTarget.dataset.orderlinenum
      }
    }
    ));
  }
}