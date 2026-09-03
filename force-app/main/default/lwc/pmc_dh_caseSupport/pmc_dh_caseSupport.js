import { LightningElement, track } from "lwc";
import basePath from "@salesforce/community/basePath";
import pmc_brandingStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";

import pmc_breadcrumb_homepage from "@salesforce/label/c.pmc_breadcrumb_homepage";
import pmc_breadcrumb_support from "@salesforce/label/c.pmc_breadcrumb_support";
import pmc_breadcrumb_cases from "@salesforce/label/c.pmc_breadcrumb_cases";
import pmc_caseMgmt_createNewCase from "@salesforce/label/c.pmc_caseMgmt_createNewCase";

/**
 * A custom LWC for displaying Support Page breadcrumbs and tabs
 * @alias Pmc_dh_caseSupport
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 *
 * @example
 * <c-pmc_dh_case-support></c-pmc_dh_case-support>
 */

export default class Pmc_dh_caseSupport extends LightningElement {
  buttonUrl = `${pmc_brandingStaticResource}/icons/icon-new-case.svg`;
  @track labels = {
    pmc_breadcrumb_homepage,
    pmc_breadcrumb_support,
    pmc_breadcrumb_cases,
    pmc_caseMgmt_createNewCase
  };
  tabsArray = [{ label: this.labels.pmc_breadcrumb_cases, value: "Cases" }];
  crumbs = [
    {
      label: this.labels.pmc_breadcrumb_homepage,
      url: `${basePath}/`,
      isActive: false
    },
    { label: this.labels.pmc_breadcrumb_support, url: "", isActive: false },
    { label: this.labels.pmc_breadcrumb_cases, url: "", isActive: true }
  ];
  isCreateCaseEnabled = false;
  isMouseOver = false;

  /**
   * Create Case Modal open handler
   * @function openCreateCaseModal
   */
  openCreateCaseModal() {
    this.isCreateCaseEnabled = !this.isCreateCaseEnabled;
  }

  /**
   * Create Case Modal close handler
   * @function closeCreateCaseModal
   */
  closeCreateCaseModal(event) {
    this.isCreateCaseEnabled = event.detail.value;
  }

  /**
   * Modal accessibility handler
   * @function handleIconKeyDown
   * @param {event} event
   */
  handleIconKeyDown(event) {
    if (event.keyCode === 13) {
      this.openCreateCaseModal();
    }
  }

  /**
   * Mouse over Icon Handler
   * @function handleMouseEnter
   */
  handleMouseEnter() {
    this.isMouseOver = true;
  }

  /**
   * Mouse Leave Handler
   * @function handleMouseLeave
   */
  handleMouseLeave() {
    this.isMouseOver = false;
  }
}