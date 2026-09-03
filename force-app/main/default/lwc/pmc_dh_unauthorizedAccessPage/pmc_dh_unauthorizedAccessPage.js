import { LightningElement, track, api } from 'lwc';
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";

import pmc_unauthorizedAccess_restrictedAccess from "@salesforce/label/c.pmc_unauthorizedAccess_restrictedAccess";
import pmc_unauthorizedAccess_restrictedAccessText from "@salesforce/label/c.pmc_unauthorizedAccess_restrictedAccessText";
import pmc_cartCheckout_checkout from '@salesforce/label/c.pmc_cartCheckout_checkout';

export default class Pmc_dh_unauthorizedAccessPage extends LightningElement {
  mosaicLogoUrl = `${PMC_BrandingAssetsStaticResource}/images/mosaic_logo_NA.png`;
  @api message = pmc_unauthorizedAccess_restrictedAccessText;

  @track labels = {
    pmc_unauthorizedAccess_restrictedAccess
  }

  connectedCallback() {
    if (window.location.href.includes("checkout")) {
      document.title = pmc_cartCheckout_checkout;
    }
  }
}