import { LightningElement, track } from "lwc";
import BrandingAssets from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import getNavigationMenuItems from "@salesforce/apex/PMC_DH_FooterController.getNavigationMenuItems";
import basePath from '@salesforce/community/basePath';
import { toastMessageHandler, formatLabel } from "c/pmc_dh_utilityJs";
import isGuest from "@salesforce/user/isGuest";

import pmc_footer_copyright from "@salesforce/label/c.pmc_footer_copyright";
import pmc_footer_mosaicLogo from "@salesforce/label/c.pmc_footer_mosaicLogo";

const BRAZIL_LOCALE = 'Brazil';

/**
 * A custom LWC to display footer.
 * @alias Pmc_dh_footer
 * @extends LightningElement
 * @hideconstructor
 * @author Vanshika
 *
 * @example
 * <c-pmc_dh_footer></c-pmc_dh_footer>
 */

export default class Pmc_dh_footer extends LightningElement {
  mosaicLogoUrl = (sessionStorage.getItem("userRegion") === BRAZIL_LOCALE) ? `${BrandingAssets}/images/mosaic_logo_BZ.png` : `${BrandingAssets}/images/mosaic_logo_NA.png`;
  footerNav;
  navItems;
  error;

  /**
   * Labels details
   */
  @track labels = {
    pmc_footer_copyright,
    pmc_footer_mosaicLogo
  }

  /** 
   * Lifecycle hook 
   */
  connectedCallback() {
    this.labels.pmc_footer_copyright = formatLabel(this.labels.pmc_footer_copyright, [new Date().getFullYear()]);

    let that = this;
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.intervalId = setInterval(() => {
      if(isGuest) {
        this.loadNavigation();
      }
      else if (sessionStorage.getItem("userRegion")) {
        clearInterval(that.intervalId);
        this.loadNavigation();
      }
    }, 100);
  }

  /** 
   * Fetch footer navigation details
   * @function loadNavigation
   */
  loadNavigation() {
    let strMenuName = (sessionStorage.getItem("userRegion") === BRAZIL_LOCALE) ? "DH_Footer_Menus_BR" : "DH_Footer_Menus1";
    getNavigationMenuItems({
      menuName: strMenuName,
      publishedState: "live"
    })
      .then((result) => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
          }
          this.footerNav = result;
          this.navItems = this.footerNav.myAccountNavItems.map(a => { return { ...a } });
          this.navItems.forEach(el => {
            if (el?.strLabel === "Contact Us")
              el.strTarget = window.location.origin + basePath + el.strTarget;
          })
          if (this.footerNav?.userData?.strUserLocation === BRAZIL_LOCALE) {
            this.mosaicLogoUrl = `${BrandingAssets}/images/mosaic_logo_BZ.png`;
          }
        }
      })
      .catch((err) => {
        toastMessageHandler();
        this.error = err;
      });
  }
}