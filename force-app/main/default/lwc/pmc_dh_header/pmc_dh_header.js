import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import getHeaderDetails from "@salesforce/apex/PMC_DH_HeaderDetails.getHeaderDetails";
import isGuest from "@salesforce/user/isGuest";
import { getRecord } from "lightning/uiRecordApi";
import Id from "@salesforce/user/Id";
import getEffectiveAccountDetails from "@salesforce/apex/PMC_DH_AccountSwitcherController.getEffectiveAccountDetails";
import USER_ACCOUNT_FIELD from "@salesforce/schema/User.AccountId";
import basePath from "@salesforce/community/basePath";
import getSeedzPoints from "@salesforce/apex/PMC_DH_SeedzController.getSeedzPoints";
import { toastMessageHandler } from 'c/pmc_dh_utilityJs';
import { fireEvent, formatLabel, formatNavigationUrl } from "c/pmc_dh_utilityJs";
import { CurrentPageReference } from "lightning/navigation";

import pmc_header_nutivantagens from "@salesforce/label/c.pmc_header_nutivantagens";
import pmc_header_mosaicLogoText from "@salesforce/label/c.pmc_header_mosaicLogoText";
import pmc_header_cart from "@salesforce/label/c.pmc_header_cart";
import pmc_header_search from "@salesforce/label/c.pmc_header_search";
import pmc_dh_hamburger from "@salesforce/label/c.pmc_dh_hamburger";
import pmc_header_nutrivantagensPoints from "@salesforce/label/c.pmc_header_nutrivantagensPoints";
import pmc_header_skipToContent from "@salesforce/label/c.pmc_header_skipToContent";
import pmc_header_error from "@salesforce/label/c.pmc_header_error";
import pmc_header_click from "@salesforce/label/c.pmc_header_click";
import pmc_header_here from "@salesforce/label/c.pmc_header_here";
import pmc_header_toRefresh from "@salesforce/label/c.pmc_header_toRefresh";

const BRAZIL_LOCALE = "Brazil";
const CALLOUT_API_ERROR = "callout failed";

export default class Pmc_dh_header extends NavigationMixin(LightningElement) {
  @api effectiveAccountId;

  /** 
   * Calling pageref 
   */
  @wire(CurrentPageReference) pageRef;

  isSpinner = false;
  basePath = basePath + "/";
  @track labels = {
    pmc_header_nutivantagens,
    pmc_header_mosaicLogoText,
    pmc_header_cart,
    pmc_header_search,
    pmc_dh_hamburger,
    pmc_header_nutrivantagensPoints,
    pmc_header_skipToContent,
    pmc_header_error,
    pmc_header_click,
    pmc_header_here,
    pmc_header_toRefresh
  };
  @track iconUrlObj = {
    mosaicLogoUrl: sessionStorage.getItem("userRegion") ? ((sessionStorage.getItem("userRegion") === BRAZIL_LOCALE) ? `${PMC_BrandingAssetsStaticResource}/images/mosaic_logo_BZ.png` : `${PMC_BrandingAssetsStaticResource}/images/mosaic_logo_NA.png`) : '',
    enrollToNutivanatgensUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-vantagens.svg`,
    cartUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-cart.svg`,
    searchIconUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-search.svg`,
    hamburgerUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-hamburger.svg`
  };
  @track headerDetails = {};
  @track langPrefeWrapper = {};
  @track nutrivantagensData = {};
  effectiveAccountId1;
  error;
  isGuestUser = isGuest;
  showSeedzPoints = false;
  showNutrivantagensButton = false;
  isSeedzError = false;
  isSeedzSpinner = false;
  isRefreshVantagensDisabled;
  _handler;

  @wire(getRecord, { recordId: Id, fields: [USER_ACCOUNT_FIELD] })
  currentUserInfo({ error, data }) {
    if (data) {
      this.effectiveAccountId1 = data.fields.AccountId.value;
    } else if (error) {
      this.error = error;
    }
  }

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    if (this.isGuestUser) {
      localStorage.removeItem("EFFECTIVE_ACCOUNT_ID");
      localStorage.removeItem("EFFECTIVE_ACCOUNT_NAME");
    }

    if (!this.isGuestUser) this.getAccountDetails();
    if (+sessionStorage.getItem('SEEDZ_REFRESH_COUNTER') === 5) {
      this.isRefreshVantagensDisabled = true
    }
    if (this.isGuestUser) this.iconUrlObj.mosaicLogoUrl = `${PMC_BrandingAssetsStaticResource}/images/mosaic_logo_NA.png`;
    if (window.screen.width <= 1023) {
      document.addEventListener('click', this._handler = this.close.bind(this));
    }
  }

  /**
   * Handles click event
   * @function ignore
   * @param {event} event 
   */
  ignore(event) {
    if (window.screen.width <= 1023) {
      event.stopPropagation();
      return false;
    }
    return true;
  }

  /**
   * Adds new class
   * @function close
   */
  close() {
    this.template
      .querySelector(".mobile-nav")
      .classList.add("slds-show_large");
  }

  /**
   * Backend Method to get EFFECTIVE_ACCOUNT_ID and EFFECTIVE_ACCOUNT_NAME into Session Storage
   * @function getAccountDetails
   */
  getAccountDetails() {
    this.headerDetails = sessionStorage.getItem('HEADER_DETAILS') ? JSON.parse(sessionStorage.getItem('HEADER_DETAILS')) : {};
    this.isSpinner = true;
    getEffectiveAccountDetails()
      .then((result) => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
          }
          if (!sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID") && !sessionStorage.getItem("EFFECTIVE_ACCOUNT_NAME")) {
            sessionStorage.setItem("EFFECTIVE_ACCOUNT_ID", result.strAccountId);
            sessionStorage.setItem("EFFECTIVE_ACCOUNT_NAME", result.strAccountName);
          }
          this.getHeaderDetails();
        }
      })
      .catch((error) => {
        toastMessageHandler();
        this.isSpinner = false;
        this.error = error;
      });
  }

  /**
   * Fetch header details based on Account ID 
   * @function getHeaderDetails
   */
  getHeaderDetails() {
    this.effectiveAccountId1 = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
    getHeaderDetails({
      strEffectiveAccountId: this.effectiveAccountId1
    })
      .then((result) => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
          }
          if (result.userData) {
            this.headerDetails = JSON.parse(JSON.stringify(result));
            sessionStorage.setItem('HEADER_DETAILS', JSON.stringify(result));
            this.headerDetails.userData.strAccountName = localStorage.getItem("EFFECTIVE_ACCOUNT_NAME") ? localStorage.getItem("EFFECTIVE_ACCOUNT_NAME") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_NAME");
            sessionStorage.setItem("userRegion", this.headerDetails.userData?.strUserLocation);
            if (this.headerDetails.userData?.strUserLocation === BRAZIL_LOCALE) {
              this.iconUrlObj.mosaicLogoUrl = `${PMC_BrandingAssetsStaticResource}/images/mosaic_logo_BZ.png`;
            } else {
              this.iconUrlObj.mosaicLogoUrl = `${PMC_BrandingAssetsStaticResource}/images/mosaic_logo_NA.png`;
            }
            if (this.headerDetails.boolIsSeedZAccess) {
              this.getSeedzPoints();
            }
            if (result.langPrefeWrapper) {
              this.headerDetails.langPrefeWrapper = JSON.parse(JSON.stringify(result.langPrefeWrapper));
            }
            if (result.langPrefeWrapper) fireEvent(this.pageRef, "languageEvent", result.langPrefeWrapper);
            
            if(this.headerDetails.navigationMenuItems && this.headerDetails.navigationMenuItems.length > 0) {
              this.headerDetails.navigationMenuItems.forEach((menu) => {
                menu.strTarget = formatNavigationUrl(this.headerDetails.langPrefeWrapper.lstUrlLanguage, menu.strTarget);
              });
            }
          }
        }
        this.isSpinner = false;
      })
      .catch((error) => {
        toastMessageHandler();
        this.isSpinner = false;
        this.error = error;
      });
  }

  /**
   * Fetches data for seedz
   * @function getSeedzPoints
   */
  getSeedzPoints() {
    this.isSeedzSpinner = true;
    getSeedzPoints()
      .then((result) => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
          }
          this.nutrivantagensData = result;
          if (Object.keys(this.nutrivantagensData).length) {
            if (this.nutrivantagensData.boolIsSeedzEnrolled) {
              this.showSeedzPoints = true;
              this.labels.pmc_header_nutrivantagensPoints = formatLabel(
                this.labels.pmc_header_nutrivantagensPoints,
                [this.nutrivantagensData.decSeedzPoints]
              );
            }
            this.showNutrivantagensButton = true;
          }
          this.isSeedzError = result.boolHasError ? true : false;
        }
        this.isSeedzSpinner = false;
      })
      .catch((error) => {
        if (error?.body?.message) {
          this.isSeedzError = this.showNutrivantagensButton = ((error.body.message).toLowerCase() === CALLOUT_API_ERROR ? true : false);
        }
        this.error = error;
        this.isSeedzSpinner = false;
      });
  }

  /** 
   * Open header menu items in mobile view 
   * @function hamburgerClickHandler
   */
  hamburgerClickHandler(event) {
    event.stopPropagation();
    this.template.querySelector(".mobile-nav").classList.toggle("slds-show_large");
  }

  /** 
   * Hides/shows the search bar in mobile view 
   * @function notificationClickHandler
   */
  notificationClickHandler() {
    this.template
      .querySelector(".search-bar-mobile")
      .classList.toggle("slds-hide");
  }

  /**
   * Handles refreshing vantagens
   * @function handleClickRefreshVantagens
   */
  handleClickRefreshVantagens() {
    this.getSeedzPoints();
    if (!sessionStorage.getItem('SEEDZ_REFRESH_COUNTER')) {
      sessionStorage.setItem('SEEDZ_REFRESH_COUNTER', 1)
    }
    else if (+sessionStorage.getItem('SEEDZ_REFRESH_COUNTER') < 4) {
      let counter = +sessionStorage.getItem('SEEDZ_REFRESH_COUNTER') + 1;
      sessionStorage.setItem('SEEDZ_REFRESH_COUNTER', counter);
    }
    else if (+sessionStorage.getItem('SEEDZ_REFRESH_COUNTER') === 4) {
      let counter = +sessionStorage.getItem('SEEDZ_REFRESH_COUNTER') + 1;
      sessionStorage.setItem('SEEDZ_REFRESH_COUNTER', counter);
      this.isRefreshVantagensDisabled = true;
    }
  }
}