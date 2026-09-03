import { LightningElement, track, api } from "lwc";
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import basePath from "@salesforce/community/basePath";
import { NavigationMixin } from "lightning/navigation";
import { SORT_DIRECTION, sortData, isBrazilRegion, formatDate, urlRedirect, toastMessageHandler } from "c/pmc_dh_utilityJs";
import getShipmentRecords from "@salesforce/apex/PMC_DH_ShipmentHistoryList.getShipmentRecords";
import getDocDownload from "@salesforce/apex/PMC_DH_DocumentDownloadController.getDocDownload";

import pmc_orderHistory_download from "@salesforce/label/c.pmc_orderHistory_download";
import pmc_orderDetails_getInTouchMsg from "@salesforce/label/c.pmc_orderDetails_getInTouchMsg";
import PMC_DH_TrizzyTrackingLinkBR from "@salesforce/label/c.PMC_DH_TrizzyTrackingLinkBR";
import pmc_shipmentDetails_inTransit from "@salesforce/label/c.pmc_shipmentDetails_inTransit";
import pmc_shipmentDetails_scheduled from "@salesforce/label/c.pmc_shipmentDetails_scheduled";
import pmc_orderHistory_orderNumber from "@salesforce/label/c.pmc_orderHistory_orderNumber";
import pmc_contractDetails_poNumber from "@salesforce/label/c.pmc_contractDetails_poNumber";
import pmc_homepage_product from "@salesforce/label/c.pmc_homepage_product";
import pmc_shipmentDetails_vehicleId from "@salesforce/label/c.pmc_shipmentDetails_vehicleId";
import pmc_shipmentHistory_scheduledDate from "@salesforce/label/c.pmc_shipmentHistory_scheduledDate";
import pmc_shipmentDetails_deliveryQty from "@salesforce/label/c.pmc_shipmentDetails_deliveryQty";
import pmc_shipmentDetails_eta from "@salesforce/label/c.pmc_shipmentDetails_eta";
import pmc_shipmentDetails_document from "@salesforce/label/c.pmc_shipmentDetails_document";
import pmc_shipmentDetails_currentLoc from "@salesforce/label/c.pmc_shipmentDetails_currentLoc";
import pmc_shipmentHistory_shipDate from "@salesforce/label/c.pmc_shipmentHistory_shipDate";
import pmc_shipmentHistory_destination from "@salesforce/label/c.pmc_shipmentHistory_destination";
import pmc_shipmentHistory_searchShipments from "@salesforce/label/c.pmc_shipmentHistory_searchShipments";
import pmc_shipmentDetails_chooseDoc from "@salesforce/label/c.pmc_shipmentDetails_chooseDoc";
import pmc_orderHistory_noResultsMsg from "@salesforce/label/c.pmc_orderHistory_noResultsMsg";
import pmc_leadManagement_accordion from "@salesforce/label/c.pmc_leadManagement_accordion";
import pmc_orderShipmentList_delayed from "@salesforce/label/c.pmc_orderShipmentList_delayed";

const DELIVERY_STATUS = {
  SCHEDULED: "Scheduled",
  IN_TRANSIT: "In Transit",
}

const MIN_SEARCH_LENGTH = 3;

/**
 * A custom LWC to display shipment history.
 * @alias Pmc_dh_orderShipmentsList
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 *
 * @example
 * <c-pmc_dh_order-shipments-list></c-pmc_dh_order-shipments-list>
 */

export default class Pmc_dh_orderShipmentsList extends NavigationMixin(LightningElement) {
  @api activeTab = null;
  @track iconUrlObj = {
    arrowRightIconUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-arrowright.svg`,
    download: `${PMC_BrandingAssetsStaticResource}/icons/icon-download.svg`
  };

  @track labels = {
    pmc_orderDetails_getInTouchMsg,
    pmc_orderHistory_download,
    pmc_shipmentDetails_inTransit,
    pmc_shipmentDetails_scheduled,
    pmc_orderHistory_orderNumber,
    pmc_contractDetails_poNumber,
    pmc_homepage_product,
    pmc_shipmentDetails_vehicleId,
    pmc_shipmentHistory_scheduledDate,
    pmc_shipmentDetails_deliveryQty,
    pmc_shipmentDetails_eta,
    pmc_shipmentDetails_document,
    pmc_shipmentDetails_currentLoc,
    pmc_shipmentHistory_shipDate,
    pmc_shipmentHistory_destination,
    pmc_shipmentHistory_searchShipments,
    pmc_shipmentDetails_chooseDoc,
    pmc_orderHistory_noResultsMsg,
    pmc_leadManagement_accordion,
    pmc_orderShipmentList_delayed
  };

  @track filteredData = [];
  @track shipmentsList = [];

  isScheduled = true;
  isSpinner = false;
  pageLoaded = false;
  pageRendered = false;
  isResultSetEmpty = false;
  recordsPerPage = 5;
  isLocationBrazil = false;
  queryString = window.location.search;
  trizzyUrl = PMC_DH_TrizzyTrackingLinkBR;
  effAccId = '';

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    if (isBrazilRegion()) {
      this.isLocationBrazil = true;
    }
    this.strLocale = sessionStorage.getItem("userRegion");
    if (this.activeTab) {
      if (this.activeTab === 'InTransit') {
        this.isScheduled = false
      }
    }

    let that = this;
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.intervalId = setInterval(() => {
      if (sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
        this.effAccId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
        clearInterval(that.intervalId);
        this.fetchShipmentRecords(true);
      }
    }, 100);
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (!this.isScheduled && !this.isLocationBrazil) {
      let productCol = this.template.querySelectorAll(".prdct-nm");
      productCol.forEach(col => {
        col.classList.remove("slds-size_2-of-12");
        col.classList.add("slds-size_1-of-12");
      })
    }
    if (this.isLocationBrazil) {
      this.template.querySelectorAll(".content-info")
        .forEach(col => {
          col.classList.remove("slds-size_1-of-12");
          col.classList.remove("slds-size_2-of-12");
          col.classList.add("slds-size_1-of-8");
        })
      this.template.querySelectorAll(".badge-style")
        .forEach(col => {
          col.classList.remove("slds-size_2-of-12");
          col.classList.add("slds-size_1-of-8");
        })
      this.template.querySelector('.accordion-content')?.classList.add('brazil-shipments');
    }
    this.filteredData?.forEach(shipment => {
      if (shipment.isAccordOpen) {
        this.template.querySelector(`.accordion-icon img[data-str-destination-id="${shipment.strDestinationId}"]`)?.classList.add('down');
      }
      else {
        this.template.querySelector(`.accordion-icon img[data-str-destination-id="${shipment.strDestinationId}"]`)?.classList.remove('down');
      }
    })
    this.highlightStatusBadges();
    if (this.pageRendered) return;
    this.tabStyleHandler();
    this.pageRendered = true;
  }

  /**
   * Get all the shipment records on the basis of selected tab
   * @function fetchShipmentRecords
   * @param {boolean} fetchAll 
   * @param {object} shipmentWrapper 
   */
  fetchShipmentRecords(fetchAll, shipmentWrapper) {
    this.isSpinner = true;
    this.pageLoaded = false;
    this.shipmentsList = [];
    this.filteredData = [];
    let searchParams = {};
    if (!shipmentWrapper) {
      searchParams = {
        strSearchTerm: "",
        datFromDate: null,
        datToDate: null,
        strStatus: this.isScheduled ? DELIVERY_STATUS.SCHEDULED : DELIVERY_STATUS.IN_TRANSIT
      }
    }
    else {
      searchParams = { ...shipmentWrapper, strStatus: this.isScheduled ? DELIVERY_STATUS.SCHEDULED : DELIVERY_STATUS.IN_TRANSIT }
    }
    getShipmentRecords({ searchParams, effAccountId: this.effAccId, strLocale: this.strLocale })
      .then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).statusCodeMessage.strStatusMessage)
          }
          this.updateShipmentDetails(JSON.parse(JSON.stringify(response)).lstShipmentWrapper, fetchAll);
        }
        this.pageLoaded = true;
        this.isSpinner = false;
      })
      .catch(() => {
        toastMessageHandler();
        this.isSpinner = false;
        this.pageLoaded = true;
      });
  }

  /**
   * Display shipment details
   * @function updateShipmentDetails
   * @param {Array} shipments 
   * @param {boolean} fetchAll 
   */
  updateShipmentDetails(shipments, fetchAll = true) {
    this.isResultSetEmpty = false;
    if (!fetchAll && shipments.length === 0) {
      this.isResultSetEmpty = true;
    }
    shipments?.forEach(shipment => {
      shipment.isAccordOpen = false;
    })
    this.filteredData = sortData(
      JSON.parse(JSON.stringify(shipments)),
      "strDestination",
      "string",
      SORT_DIRECTION.ASC
    );
    if (this.filteredData?.length) {
      this.filteredData[0].isAccordOpen = true;
    }
    this.shipmentsList = JSON.parse(JSON.stringify(this.filteredData));
    this.setDefaultMode();
  }

  /**
   * Highlight status badges based on their values
   * @function highlightStatusBadges
   */
  highlightStatusBadges() {
    let dest = this.filteredData.find(el => el.isAccordOpen === true);
    if (this.isScheduled) {
      this.template.querySelectorAll('.badge')?.forEach(el => el?.setAttribute("data-status", "warning"));
      dest?.lstDeliveriesWrapper.forEach((item) => {
        item.formattedShipDate = item.datShipDate ? formatDate(item.datShipDate) : 'N/A';
        item.formattedETA = item.strETA ? formatDate(item.strETA) : "N/A";
      });
    }
    else {
      dest?.lstDeliveriesWrapper.forEach((order) => {
        order.formattedShipDate = order.datShipDate ? formatDate(order.datShipDate) : 'N/A';
        order.formattedETA = order.strETA ? formatDate(order.strETA) : "N/A";
        if (order.strStatus === this.labels.pmc_orderShipmentList_delayed) {
          this.template.querySelector(`.badge[data-delivery-item-id="${order.strDeliveryItemId}"]`)?.setAttribute("data-status", "error");
        }
      });
    }
  }

  /**
   * Open Accordion on click of '>'
   * @function openAccordion
   * @param {Event} event
   */
  openAccordion(event) {
    const strDestinationId = event.target.dataset.strDestinationId;
    this.filteredData.forEach(shipment => {
      if (shipment.strDestinationId === strDestinationId) {
        shipment.isAccordOpen = !shipment.isAccordOpen;
      } else {
        shipment.isAccordOpen = false;
      }
    });
  }

  /**
   * Function called on click of Search CTA/Icon
   * @function handleSearch
   * @param {Event} event 
   */
  handleSearch(event) {
    let targetEl = event.detail.targetId;
    let searchJSON = JSON.parse(JSON.stringify(event.detail.searchObj));
    if (
      searchJSON?.strSearchInput?.length >= MIN_SEARCH_LENGTH ||
      searchJSON?.fromDate ||
      searchJSON?.toDate
    ) {
      let shipmentWrapper = {
        strSearchTerm:
          searchJSON?.strSearchInput?.length >= MIN_SEARCH_LENGTH
            ? searchJSON?.strSearchInput
            : null,
        datFromDate:
          targetEl === "strSearchInput" ? null : searchJSON?.fromDate,
        datToDate: targetEl === "strSearchInput" ? null : searchJSON?.toDate,
        strStatus: this.strStatus
      };
      this.fetchShipmentRecords(false, shipmentWrapper);
    } else {
      this.fetchShipmentRecords(true);
    }
  }

  /**
   * Set the data paginated data
   * @function setDefaultMode
   */
  setDefaultMode() {
    this.template
      .querySelector("c-pmc_dh_pagination")
      ?.setDataOnSearch(this.filteredData);
  }

  /**
   * Clear Search Inputs and reset data
   * @function clearSearchInputs
   */
  clearSearchInputs() {
    this.fetchShipmentRecords(true);
  }

  /**
   * Update the page data based on the current page selection
   * @function updatePaginatedData
   * @param {Event} event 
   */
  updatePaginatedData(event) {
    this.filteredData = event.detail;
  }

  /**
   * Style the selected tab
   * @function tabStyleHandler
   */
  tabStyleHandler() {
    if (this.isScheduled) {
      this.template.querySelector(".sch")?.classList.add("dynamic-border");
      this.template.querySelector(".tran")?.classList.remove("dynamic-border");
    } else {
      this.template.querySelector(".sch")?.classList.remove("dynamic-border");
      this.template.querySelector(".tran")?.classList.add("dynamic-border");
    }
  }

  /**
   * Function called on click of Scheduled/In Transit tab
   * @function tabChangeHandler
   * @param {Event} event 
   */
  tabChangeHandler(event) {
    this.pageRendered = false;
    this.template.querySelector("c-pmc_dh_search-filters").resetInputs();
    this.isScheduled = event.target.dataset.id === DELIVERY_STATUS.SCHEDULED ? true : false;
    this.fetchShipmentRecords(true);
  }

  /**
   * Navigate to order details page
   * @function navigateToOrder
   * @param {Event} event 
   */
  navigateToOrder(event) {
    const orderNum = event.target.dataset.orderNumber;
    const orderId = event.target.dataset.orderId;
    const url = `${basePath}/order/${orderId}?orderNumber=${orderNum}&orderId=${orderId}`;
    this.navigateToUrl(url);
  }

  /**
   * Navigate to delivery tracking page
   * @function navigateToDeliveryTrackingPage
   * @param {Event} event 
   */
  navigateToDeliveryTrackingPage(event) {
    const orderNum = event.target.dataset.orderNumber;
    const orderId = event.target.dataset.orderId;
    const orderLineId = event.target.dataset.orderLineId;
    const vehicleId = event.target.dataset.id;
    const url = `${basePath}/order/${orderId}/detail?orderNumber=${orderNum}&orderId=${orderId}&orderLineId=${orderLineId}&vehicleId=${vehicleId}&shipmentView=true`;
    this.navigateToUrl(url);
  }

  /**
   * Navigate To a URL
   * @function navigateToUrl
   * @param {string} url 
   */
  navigateToUrl(url) {
    const pageRef = {
      type: "standard__webPage",
      attributes: {
        url: url
      }
    };
    this[NavigationMixin.GenerateUrl](pageRef).then((generatedUrl) => {
      urlRedirect(generatedUrl);
    });
  }

  /**
   * On input change event handler 
   * @function handleDataChange
   * @param {Event} event 
   */
  handleDataChange(event) {
    let selectedOrderItem;
    this.filteredData?.forEach((shipment) => {
      shipment.lstDeliveriesWrapper?.forEach((order) => {
        if (event.target.dataset.deliveryItemId === order.strDeliveryItemId) {
          selectedOrderItem = order;
        }
      })
    });
    if (event.detail.value && selectedOrderItem) {
      selectedOrderItem.isDownloadEnabled = true;
      selectedOrderItem.selectedDoc = event.detail.value;
      selectedOrderItem.docName = selectedOrderItem.lstDocument.find((doc) => doc.value === event.detail.value).label;
      let lstDocCodeRecord = Object.entries(selectedOrderItem?.mapDocRecord)
      const selectedDocRecord = lstDocCodeRecord?.find(
        (e) => e[0] === event.detail.value
      );
      if (selectedDocRecord?.length) {
        selectedOrderItem.deliveryNumber = selectedDocRecord[1].strDeliveryNumber ? selectedDocRecord[1].strDeliveryNumber : "";
        selectedOrderItem.itemNumber = selectedDocRecord[1].strItemNumber ? selectedDocRecord[1].strItemNumber : "";
        selectedOrderItem.billingDocNumber = selectedDocRecord[1].strBillingDocNumber ? selectedDocRecord[1].strBillingDocNumber : "";
      }
    } else {
      selectedOrderItem.isDownloadEnabled = false;
    }
  }

  /**
   * Downloads delivery document after selecting the type of document from the list
   * @function downloadDocument
   * @param {Event} event 
   */
  downloadDocument(event) {
    this.isSpinner = true;
    let selectedOrderItem;
    this.filteredData?.forEach((shipment) => {
      shipment.lstDeliveriesWrapper?.forEach((order) => {
        if (event.target.dataset.deliveryItemId === order.strDeliveryItemId) {
          selectedOrderItem = order;
        }
      })
    });
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
}