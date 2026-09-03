import { LightningElement, track } from 'lwc';
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import { NavigationMixin } from "lightning/navigation";
import { urlRedirect } from 'c/pmc_dh_utilityJs';

import pmc_header_mosaicLogoText from "@salesforce/label/c.pmc_header_mosaicLogoText";
import pmc_header_skipToContent from "@salesforce/label/c.pmc_header_skipToContent";

/**
 * A custom LWC to select language preference.
 * @alias Pmc_dh_guestHeader
 * @extends LightningElement
 * @hideconstructor
 * @author Vanshika
 * @example
 * <c-pmc_dh_guest-header></c-pmc_dh_guest-header>
 */

export default class Pmc_dh_guestHeader extends NavigationMixin(LightningElement) {
  @track iconUrlObj = {
    mosaicLogoUrl: `${PMC_BrandingAssetsStaticResource}/images/mosaic_logo_NA.png`,
  }

  @track labels = {
    pmc_header_mosaicLogoText,
    pmc_header_skipToContent
  }

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    let pathname = window.location.pathname;
    if (!window.location.href.includes("commeditor")) {
      if (pathname.includes('cart') || pathname.includes('checkout')) this.redirectToLoginPage();
    }
  }

  /**
   * redirecting to login page
   * @function redirectToLoginPage
   */
  redirectToLoginPage() {
    let url = window.location.origin;
    this[NavigationMixin.GenerateUrl]({
      type: 'standard__webPage',
      attributes: {
        url: `${url}/login`
      }
    }).then(generatedUrl => {
      urlRedirect(generatedUrl);
      sessionStorage.clear();
    });
  }
}