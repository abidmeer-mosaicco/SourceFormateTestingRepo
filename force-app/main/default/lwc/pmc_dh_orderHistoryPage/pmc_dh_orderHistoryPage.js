import { LightningElement, track } from 'lwc';
import basePath from "@salesforce/community/basePath";
import { NavigationMixin } from 'lightning/navigation';
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import { registerListener, isBrazilRegion } from "c/pmc_dh_utilityJs";

import pmc_breadcrumb_homepage from "@salesforce/label/c.pmc_breadcrumb_homepage";
import pmc_orderHistory_myOrderHistory from "@salesforce/label/c.pmc_orderHistory_myOrderHistory";
import pmc_orderHistory_orders from "@salesforce/label/c.pmc_orderHistory_orders";
import pmc_orderHistory_shipments from "@salesforce/label/c.pmc_orderHistory_shipments";
import pmc_orderDetails_getInTouchMsg from "@salesforce/label/c.pmc_orderDetails_getInTouchMsg";
import pmc_orderDetails_shipmentInfoMsg from "@salesforce/label/c.pmc_orderDetails_shipmentInfoMsg";

/**
 * A custom LWC to display order history page.
 * @alias Pmc_dh_orderHistoryPage
 * @extends LightningElement
 * @hideconstructor
 * @author Vanshika
 *
 * @example
 * <c-pmc_dh_order-history-page></c-pmc_dh_order-history-page>
 */

export default class Pmc_dh_orderHistoryPage extends NavigationMixin(LightningElement) {
  @track labels = {
    pmc_orderHistory_myOrderHistory,
    pmc_orderHistory_orders,
    pmc_orderHistory_shipments,
    pmc_orderDetails_getInTouchMsg,
    pmc_orderDetails_shipmentInfoMsg
  }
  isConfirmedList = true;
  @track columnHeader = ['strOrderNumber', 'strContractNumber', 'strPONumber', 'strProducts', 'shipTo', 'totalQuantity', 'orderShipmentDate', 'totalPrice', 'formattedOrderCreationData'];
  @track columnHeaderTitles = ['Order Number', 'Contract Number', 'PO Number', 'Products', 'Ship To', 'Qty (T)', 'Expected Shipment Date', 'Total Price', 'Date Created'];
  @track exportData = [];
  isOrders = true;
  infoIconUrl = `${PMC_BrandingAssetsStaticResource}/icons/icon-info.svg`;
  pageRendered = false;
  isCreateCaseEnabled = false;
  shipmentsActiveTabValue = null;
  crumbs = [
    { label: pmc_breadcrumb_homepage, url: `${basePath}/`, isActive: false },
    { label: pmc_orderHistory_myOrderHistory, url: "", isActive: true },
  ];

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    registerListener("exportToCsvEvent", this.orderList, this);
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (this.pageRendered) return;
    let params = new URLSearchParams(window.location.search);
    if (params.get("activeTab")) {
      let startURLTemp = params.get("activeTab");
      let startURLArray = startURLTemp?.split("?");
      let activeTabValue = startURLArray[0];
      if (activeTabValue === 'Shipments') {
        let tabsetEl = this.template.querySelector('lightning-tabset');
        tabsetEl.activeTabValue = "two";
      }
      if (startURLArray.length > 1)
        this.shipmentsActiveTabValue = startURLArray[1].split("=")[1];
    }
    this.pageRendered = true;
  }


  /**
   * storing isConfirmedList for reference while sorting data table and export
   * @function orderList
   * @param {object} eventData 
   */
  orderList(eventData) {
    this.exportData = eventData.exportData;
    if (eventData.isConfirmedList === undefined) { //pagination sort click
      eventData.isConfirmedList = this.isConfirmedList;
    } else {
      this.isConfirmedList = eventData.isConfirmedList;
    }
    if (eventData.isConfirmedList) {
      this.columnHeaderTitles[0] = "Order Number";
    }
    else {
      this.columnHeaderTitles[0] = "Request Number";
      if (isBrazilRegion){
        this.columnHeader[3] = "strProductNames";
        this.columnHeader[4] = "strShipToNames";
        this.columnHeader[6] = "strReqShipDates";
      }
      if (isBrazilRegion && this.columnHeaderTitles[4] !== "Protocol ID") {
        this.columnHeader.splice(4, 0, "strProtocolNoNames");
        this.columnHeaderTitles.splice(4, 0, "Protocol ID");
      }
    }
  }

  /**
   * Handle selection of Orders or Shipments tab
   * @function tabChangeHandler
   * @param {Event} event 
   */
  tabChangeHandler(event) {
    switch (event.currentTarget.value) {
      case 'one': this.isOrders = true; break;
      case 'two': this.isOrders = false; break;
      default: this.isOrders = true; break;
    }
  }

  /**
   * Create Case Modal open handler
   * @function createCaseHandler
   */
  createCaseHandler() {
    this.isCreateCaseEnabled = !this.isCreateCaseEnabled;
  }

  /**
   * Create Case Modal close handler
   * @function closeCreateCaseModal
   * @param {Event} event 
   */
  closeCreateCaseModal(event) {
    this.isCreateCaseEnabled = event.detail.value;
  }
}