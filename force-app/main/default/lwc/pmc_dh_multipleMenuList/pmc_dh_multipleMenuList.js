import { LightningElement, api, track } from "lwc";
import PMC_BrandingStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import pmc_requestToDeliverShippingInformation_multiple from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_multiple";
import pmc_leadManagement_accordion from "@salesforce/label/c.pmc_leadManagement_accordion";

/**
 * A custom LWC to display dropdown for 'Multiple' value field.
 * @alias Pmc_dh_multipleMenuList
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 * @example
 * <c-pmc_dh_multiple-menu-list></c-pmc_dh_multiple-menu-list>
 */
export default class Pmc_dh_multipleMenuList extends LightningElement {
  @track iconUrlObj = {
    arrowRightIconUrl: `${PMC_BrandingStaticResource}/icons/icon-arrowright.svg`
  };
  @track labels = {
    pmc_requestToDeliverShippingInformation_multiple,
    pmc_leadManagement_accordion
  };
  @api listItems = [];
  @api recordIndex = "";

  /**
   * Open the multiple menu accordion
   * @function openMenu
   */
  openMenu() {
    const accordionContent = this.template.querySelector(
      `.list-info[data-record-index="${this.recordIndex}"]`
    );
    const accordionIcon = this.template.querySelector(
      `.acc-icon[data-record-index="${this.recordIndex}"] img`
    );
    accordionContent.style.display =
      accordionContent.style.display === "block" ? "none" : "block";
    accordionIcon.classList.toggle("down");
  }
}