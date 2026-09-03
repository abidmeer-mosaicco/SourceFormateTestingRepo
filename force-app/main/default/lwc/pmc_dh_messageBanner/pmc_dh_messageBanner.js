import { LightningElement, api } from 'lwc';
import pmc_brandingStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";

export default class Pmc_dh_messageBanner extends LightningElement {
  @api message;
  @api type = 'info';
  @api showRebatesBanner = false;
  @api hyperlink;
  @api isShipmentHistory;
  iconUrl;
  infoClass;
  altText;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    switch (this.type) {
      case "info":
        this.iconUrl = `${pmc_brandingStaticResource}/icons/icon-info.svg`;
        this.infoClass = 'info-message slds-m-bottom_medium';
        this.altText = 'More Information';
        break;

      case "error":
        this.iconUrl = `${pmc_brandingStaticResource}/icons/icon-error.svg`;
        this.infoClass = "error-message";
        this.altText = 'Error';
        break;

      case "warning":
        this.iconUrl = `${pmc_brandingStaticResource}/icons/icon-info.svg`;
        this.infoClass = "warning-message slds-m-bottom_medium";
        this.altText = 'More Information';
        break;

      default:
        break;
    }
    if (this.isShipmentHistory) {
      this.shipmentAlign = "banner-cont";
    }
  }

  /**
   * Handles hyderlink in the message banner
   * @function hyperlinkHandler
   */
  hyperlinkHandler() {
    const hyperlinkEvent = new CustomEvent("createcase");
    this.dispatchEvent(hyperlinkEvent);
  }
}