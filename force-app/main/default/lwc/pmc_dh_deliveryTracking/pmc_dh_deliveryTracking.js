import { LightningElement, track, api } from "lwc";
import basePath from "@salesforce/community/basePath";
import { NavigationMixin } from "lightning/navigation";
import { formatDate, urlRedirect, toastMessageHandler } from "c/pmc_dh_utilityJs";
import getDeliveryTracking from "@salesforce/apex/PMC_DH_OrderLineDetailsUtil.getDeliveryTracking";

import pmc_breadcrumb_homepage from "@salesforce/label/c.pmc_breadcrumb_homepage";
import pmc_orderHistory_myOrderHistory from "@salesforce/label/c.pmc_orderHistory_myOrderHistory";
import pmc_orderDetails_order from "@salesforce/label/c.pmc_orderDetails_order";
import pmc_shipmentDetails_orderLineNumber from "@salesforce/label/c.pmc_shipmentDetails_orderLineNumber";
import pmc_orderHistory_orderNumber from "@salesforce/label/c.pmc_orderHistory_orderNumber";
import pmc_homepage_product from "@salesforce/label/c.pmc_homepage_product";
import pmc_shipmentDetails_eta from "@salesforce/label/c.pmc_shipmentDetails_eta";
import pmc_deliveryTracking_deliveryTracking from "@salesforce/label/c.pmc_deliveryTracking_deliveryTracking";
import pmc_deliveryTracking_backToOrderLine from "@salesforce/label/c.pmc_deliveryTracking_backToOrderLine";
import pmc_deliveryTracking_deliveryDetails from "@salesforce/label/c.pmc_deliveryTracking_deliveryDetails";
import pmc_deliveryTracking_shipper from "@salesforce/label/c.pmc_deliveryTracking_shipper";
import pmc_deliveryTracking_carrier from "@salesforce/label/c.pmc_deliveryTracking_carrier";
import pmc_deliveryTracking_deliveryStatus from "@salesforce/label/c.pmc_deliveryTracking_deliveryStatus";
import pmc_shipmentHistory_myShipments from "@salesforce/label/c.pmc_shipmentHistory_myShipments";
import pmc_orderStatus_notYetShipped from "@salesforce/label/c.pmc_orderStatus_notYetShipped";
import pmc_orderStatus_partiallyShipped from "@salesforce/label/c.pmc_orderStatus_partiallyShipped";

/**
 * A custom LWC to display delivery tracking.
 * @alias Pmc_dh_deliveryTracking
 * @extends LightningElement
 * @hideconstructor
 * @author Venkata Sai Mouli, Agastya
 * @example
 * <c-pmc_dh_delivery-tracking></c-pmc_dh_delivery-tracking>
 */

const BADGE_STATUS_WARNING = "warning";

export default class Pmc_dh_deliveryTracking extends NavigationMixin(LightningElement) {
  @api orderNumber;
  @api orderId;
  @api orderLineNum;
  @api orderLineId;
  @api vehicleId;
  pageLoaded = false;
  isSpinner = true;
  isShipmentView = false;
  labels = {
    pmc_breadcrumb_homepage,
    pmc_orderHistory_myOrderHistory,
    pmc_orderDetails_order,
    pmc_shipmentDetails_orderLineNumber,
    pmc_orderHistory_orderNumber,
    pmc_homepage_product,
    pmc_shipmentDetails_eta,
    pmc_deliveryTracking_deliveryTracking,
    pmc_deliveryTracking_backToOrderLine,
    pmc_deliveryTracking_deliveryDetails,
    pmc_deliveryTracking_shipper,
    pmc_deliveryTracking_carrier,
    pmc_deliveryTracking_deliveryStatus,
    pmc_shipmentHistory_myShipments,
    pmc_orderStatus_notYetShipped,
    pmc_orderStatus_partiallyShipped
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

  @track deliveryTrackingData = {};
  @track stepsData = [];
  shipmentHistoryCrumbs = [
    {
      label: this.labels.pmc_breadcrumb_homepage,
      url: `${basePath}/`,
      isActive: false
    },
    {
      label: this.labels.pmc_shipmentHistory_myShipments,
      url: `${basePath}/orders?activeTab=Shipments`,
      isActive: false
    },
    {
      label: this.labels.pmc_deliveryTracking_deliveryTracking,
      url: "",
      isActive: true
    }
  ]
  zoomLevel = 16;

  /**
   * Life cycle hook
   */
  connectedCallback() {
    this.fetchDeliveryTrackingData();
    let params = new URLSearchParams(window.location.search);
    this.isShipmentView = params.get("shipmentView");
    if(!this.isShipmentView) {
      this.crumbs = this.crumbs.map((e, i) => {
        if (i === 2) {
          e.label = this.labels.pmc_orderDetails_order + " " + this.orderNumber;
          e.url = `${basePath}/order/${this.orderId}/detail?orderNumber=${this.orderNumber}&orderId=${this.orderId}`;
        }
        if (i === 3) {
          e.label =
            this.labels.pmc_shipmentDetails_orderLineNumber +
            " #" +
            this.orderLineNum;
        }
        return e;
      });
    }
    else {
      this.crumbs = JSON.parse(JSON.stringify(this.shipmentHistoryCrumbs));
    }
  }

  /**
   * Life cycle hook
   */
  renderedCallback() {
    if (!this.deliveryTrackingData.deliveryProgress) {
      let mapContainer = this.template.querySelector(".map-container");
      if (mapContainer) {
        mapContainer.classList.remove("slds-medium-size_8-of-12");
        mapContainer.classList.add("slds-medium-size_12-of-12");
      }
    }
    if(this.deliveryTrackingData.strDeliveryStatus){
      this.statusBadgeHandler(this.deliveryTrackingData.strDeliveryStatus);
    }
  }

  /**
   * Fetch Delivery Tracking Data
   * @function fetchDeliveryTrackingData
   */
  fetchDeliveryTrackingData() {
    getDeliveryTracking({
      strOrderLineId: this.orderLineId,
      strVehicleId: this.vehicleId
    })
      .then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).statusCodeMessage.strStatusMessage)
          }
          this.deliveryTrackingData = response;
          this.deliveryTrackingData.datETA =
            this.deliveryTrackingData.datETA &&
            formatDate(this.deliveryTrackingData.datETA);
          if (
            this.deliveryTrackingData.lstProgressTracker &&
            this.deliveryTrackingData.lstProgressTracker.length
          ) {
            this.deliveryTrackingData.lstProgressTracker.forEach(
              (progressItem) => {
                progressItem.icon =
                  progressItem.strStatus === "Completed" ||
                  progressItem.strStatus === "Active"
                    ? "icontruck"
                    : "icontruckpending";
              }
            );
            this.stepsData = this.deliveryTrackingData.lstProgressTracker;
          }
          let mapMarkers = [];
          if (this.deliveryTrackingData.mapMarkers) {
            this.deliveryTrackingData.mapMarkers.forEach((marker, index) => {
              mapMarkers.push({location:{}});
              if (marker.location.strLatitude && marker.location.strLongitude) {
                mapMarkers[index].location.Latitude = marker.location.strLatitude;
                mapMarkers[index].location.Longitude = marker.location.strLongitude;
              } else {
                mapMarkers[index].location.Street = marker.location.strStreet ? marker.location.strStreet : "";
                mapMarkers[index].location.City = marker.location.strCity ? marker.location.strCity : "";
                mapMarkers[index].location.State = marker.location.strState ? marker.location.strState : "";
                mapMarkers[index].location.Country = marker.location.strCountry ? marker.location.strCountry : "";
              }
              if(marker?.strTitle){
                mapMarkers[index].title = marker.strTitle;
              }
              if(marker?.strDescription){
                mapMarkers[index].description = this.formatMapDescription(marker.strDescription);
              }
            });
          }
          this.deliveryTrackingData.mapMarkers = mapMarkers;
        }
        this.pageLoaded = true;
        this.isSpinner = false;
      })
      .catch(() => {
        toastMessageHandler();
        this.pageLoaded = true;
        this.isSpinner = false;
      });
  }

  /**
   * Handles delivery status
   * @function statusBadgeHandler
   * @param {string} status 
   */
  statusBadgeHandler(status){
    let element = this.template.querySelector('.badge');
    let badgeStatus = '';
    switch (status) {
        case this.labels.pmc_orderStatus_notYetShipped:
            badgeStatus = BADGE_STATUS_WARNING;
            break;
        case this.labels.pmc_orderStatus_partiallyShipped:
            badgeStatus = BADGE_STATUS_WARNING;
            break;
        default:
            break;
    }
    element.setAttribute("data-status", badgeStatus)
  }

  /**
   * Format the map description
   * @function formatMapDescription
   * @param {object} description 
   */
  formatMapDescription(description){
    let street = description?.street ? `${description.street}, ` : "";
    let city = description?.city ? `${description.city}, ` : "";
    let country = description?.country ? `${description.country}` : "";
    return `${street}${city}${country}`;
  }

  /**
   * Navigate to Order Line Details Page
   * @function navigateToOrderLineDetails
   */
  navigateToOrderLineDetails() {
    let url = `${basePath}/order/${this.orderId}/detail?orderNumber=${this.orderNumber}&orderId=${this.orderId}&orderLineId=${this.orderLineId}`;
    this[NavigationMixin.GenerateUrl]({
      type: "standard__webPage",
      attributes: {
        url: url
      }
    }).then((generatedUrl) => {
      this.deliveryTrackingData = {};
      this.stepsData = [];
      this.pageLoaded = false;
      urlRedirect(generatedUrl);
    });
  }

  /**
   * Return back to Order Details Page
   * @function landToOrderDetailsView
   */
  landToOrderDetailsView() {
    this.dispatchEvent(new CustomEvent("vieworderdetails"));
  }
}