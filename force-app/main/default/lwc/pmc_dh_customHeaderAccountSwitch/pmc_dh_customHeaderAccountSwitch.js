import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin } from 'lightning/navigation';
import { toastMessageHandler } from 'c/pmc_dh_utilityJs';
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import getHeaderDetails from '@salesforce/apex/PMC_DH_HeaderDetails.getHeaderDetails';
import isGuest from "@salesforce/user/isGuest";

import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import USER_ACCOUNT_FIELD from '@salesforce/schema/User.AccountId';


const BRAZIL_LOCALE = 'Brazil';

export default class Pmc_dh_customHeaderAccountSwitch extends NavigationMixin(LightningElement) {
  showMiniCart= false;

  @track iconUrlObj = {
    mosaicLogoUrl: `${PMC_BrandingAssetsStaticResource}/images/mosaic_logo_NA.png`,
    enrollToNutivanatgensUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-vantagens.svg`,
    notificationUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-notification-bell.svg`,
    cartUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-cart.svg`,
    searchIconUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-search.svg`,
    hamburgerUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-hamburger.svg`,
  };

  @track mainMenuList = [
    {
      id: '1',
      label: 'Home',
      url: '',
    },
    {
      id: '2',
      label: 'Products',
      url: '',
      subMenuList: [{
        id: 'p1',
        label: 'Product 1',
        url: ''
      },
      {
        id: 'p2',
        label: 'Product 2',
        url: ''
      },
      {
        id: 'p3',
        label: 'Product 3',
        url: ''
      }]
    },
    {
      id: '3',
      label: 'Quotes',
      url: '',
    },
    {
      id: '4',
      label: 'Contracts',
      url: '',
    },
    {
      id: '5',
      label: 'Orders',
      url: '',
    },
    {
      id: '6',
      label: 'Documents',
      url: '',
    },
    {
      id: '7',
      label: 'Support',
      url: '',
    },
  ];

  @track languageOptions = [
    { label: "English", value: "EN" },
    { label: "Portuguese", value: "PT" },
    { label: "Spanish", value: "SP" }
  ];
  @track headerDetails = {};

  isGuestUser = isGuest;
  pageLodaed = false;
  isLoading = false;

  @api effectiveAccountId;

  @track effAccountId;
  @track error;

  @wire(getRecord, { recordId: Id, fields: [USER_ACCOUNT_FIELD] })

  currentUserInfo({ error, data }) {
    if (data) {
      this.effAccountId = data.fields.AccountId.value
    } else if (error) {
      this.error = error;
    }
  }

  connectedCallback() {
    if (!isGuest) this.getHeaderDetails();
  }

  cartClickHandler() {
    this.showMiniCart=!this.showMiniCart;
  }

  closeMiniCartHandler(){
    this.showMiniCart = false;
  }

  getHeaderDetails() {
    this.isLoading = true;
    getHeaderDetails({
      strEffectiveAccountId: this.effAccountId,
    })
      .then(result => {
        if (result && Object.keys(result).length) {
        if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
        }
        this.headerDetails = JSON.parse(JSON.stringify(result));
        if (this.headerDetails.userData?.strUserLocation === BRAZIL_LOCALE) {
          this.iconUrlObj.mosaicLogoUrl = `${PMC_BrandingAssetsStaticResource}/images/mosaic_logo_BZ.png`
        }
      }
        this.pageLodaed = true;
        this.isLoading = false;
      })
      .catch(() => {
        toastMessageHandler();
        this.isLoading = false;
      });
  }

  renderedCallback() {
    if (!this.pageLoaded) {
      this.template.querySelector('[data-id="Home"]')?.classList.add("active");
    }
  }

  hanburgerClickHandler() {
    this.template.querySelector(".mobile-nav").classList.toggle('slds-show_large');
  }

  logoClickHandler(event) {
    event.stopPropagation();
    const basePath = '/digitalhub/';
    const pageRef = {
      type: 'standard__webPage',
      attributes: {
        url: basePath
      }
    };

    this[NavigationMixin.Navigate](pageRef, true);
  }

  notificationClickHandler() {
    this.template.querySelector('.search-bar-mobile').classList.toggle('slds-hide');
  }

  vantagensClickHandler() {
    const pageRef = {
      type: 'standard__webPage',
      attributes: {
        url: `https://www.nutrivantagens.com.br/home`,
      }
    };
    this[NavigationMixin.Navigate](pageRef);
  }
}