import { api, LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { urlRedirect, formatNavigationUrl } from 'c/pmc_dh_utilityJs';
import Id from '@salesforce/user/Id';
import USER_ACCOUNT_FIELD from '@salesforce/schema/User.AccountId';
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import basePath from '@salesforce/community/basePath';

// import pmc_accountDetails_switchAccounts from "@salesforce/label/c.pmc_accountDetails_switchAccounts";
// import pmc_accountDetailsMenu_logout from "@salesforce/label/c.pmc_accountDetailsMenu_logout";

const INTERNAL_LINK = 'InternalLink';
const EXTERNAL_LINK = 'ExternalLink';

export default class Pmc_dh_accountDetailsMenu extends NavigationMixin(LightningElement) {
  @track iconUrlObj = {
    newAccountUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-account.svg`,
    logoutUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-logout.svg`,
    iconDownUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-arrowdown.svg`,
    iconRightUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-arrowright.svg`,
    iconAccountsUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-arrowright.svg`,
  }

  @track _userData = {};
  @track _langKeys = [];

  @api get userData() {
    return this._userData;
  }
  set userData(value) {
    if (value) {
      this._userData = value;
      this.userName = value.strUserName;
      this.accountName = value.strAccountName;
    }
  }

  @api
  get langKeys() {
    return this._langKeys;
  }
  set langKeys(value) {
    if (value) {
      this._langKeys = JSON.parse(JSON.stringify(value));
    }
  }

  @track _userAccountOptions = [];
  @api
  get userAccountOptions() {
    return this._userAccountOptions;
  }
  set userAccountOptions(value) {
    if (value) {
      this._userAccountOptions = JSON.parse(JSON.stringify(value));
      this._userAccountOptions.forEach((option, index) => {
        option.strRecId = String(index + 1);
        if (option.strTarget === "force:logout") {
          option.logoUrl = this.iconUrlObj.logoutUrl;
        }
      });
    }
  }

  showAccountMenuOption = false;
  userName = '';
  accountName = '';
  _handler;
  isShowSwitchAccountModal = false;
  error;

  /**
   * To Fetch Effective Account Id
   */
  @wire(getRecord, { recordId: Id, fields: [USER_ACCOUNT_FIELD] })
  currentUserInfo({ error, data }) {
    if (data) {
      this.effectiveAccountId = data.fields.AccountId.value;
    } else if (error) {
      this.error = error;
    }
  }

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    document.addEventListener('click', this._handler = this.close.bind(this));
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (window.screen.width <= 1023) {
      this.showAccountMenuOption = true;
    }
  }

  /**
   * Function to close switch account modal 
   * @function closeSwitchAccountModal
   */
  closeSwitchAccountModal() {
    this.isShowSwitchAccountModal = false;
  }

  /**
   * Function to ignore 
   * @function ignore
   * @param {event} event
   */
  ignore(event) {
    event.stopPropagation();
    return false;
  }

  /**
   * Closes the account menu popup on click of icon 
   * @function close
   */
  close() {
    this.showAccountMenuOption = false;
  }

  /**
   * Handle redirection on click of account menu option 
   * @function accountMenuClickHandler
   * @param {event} event
   */
  accountMenuClickHandler(event) {
    event.stopPropagation();
    this.userAccountClickHandler();
    const id = event?.currentTarget.dataset.id;
    const option = this._userAccountOptions.find(el => el.strRecId === id);
    if (option.strType === INTERNAL_LINK || option.strType === EXTERNAL_LINK) {
      option.strTarget = formatNavigationUrl(this._langKeys, option.strTarget);
      this.navigateToUrl(option.strTarget)
    } else if (option.strType === 'Event') {
      let url = window.location.origin;
      this[NavigationMixin.GenerateUrl]({
        type: 'standard__webPage',
        attributes: {
          url: `${url}/vforcesite/secur/logout.jsp`
        }
      }).then(generatedUrl => {
        urlRedirect(generatedUrl);
        localStorage.removeItem("EFFECTIVE_ACCOUNT_ID");
        localStorage.removeItem("EFFECTIVE_ACCOUNT_NAME");
        sessionStorage.clear();
      });
    } else if (option.strType === "Modal" && option.strTarget === "commerce_my_account:accountSwitcherModal") {
      this.isShowSwitchAccountModal = true;
      this.dispatchEvent(new CustomEvent('closehamburger'));
    }
  }

  /** 
   * Handles navigation to the requested page 
   * @function navigateToUrl
   * @param {string} url
   */
  navigateToUrl(url) {
    const pageRef = {
      type: 'standard__webPage',
      attributes: {
        url: `${basePath}${url}`,
      }
    };
    this[NavigationMixin.GenerateUrl](pageRef)
      .then(generatedUrl => {
        urlRedirect(generatedUrl);
      });
  }

  /** 
   * Handles click on username
   * @function accountMenuFirstItemClickHandler
   * @param {event} event
   */
  accountMenuFirstItemClickHandler(event) {
    event.stopPropagation();
  }

  /** 
   * Opens up the account menu popup on click of icon 
   * @function userAccountClickHandler
   * @param {event} event
   */
  userAccountClickHandler(event) {
    if (this.showAccountMenuOption) {
      event?.stopPropagation();
    }
    clearTimeout(this.clickTimer);
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.clickTimer = setTimeout(() => {
      if (window.screen.width > 1023) {
        this.showAccountMenuOption = !this.showAccountMenuOption;
      }
      if (this.showAccountMenuOption) {
        this.iconUrlObj.iconAccountsUrl = this.iconUrlObj.iconDownUrl;
      } else {
        this.iconUrlObj.iconAccountsUrl = this.iconUrlObj.iconRightUrl;
      }
    }, 500);
  }

  /** 
   * Handle account menu enter key press 
   * @function accountMenuKeydownHandler
   * @param {event} event
   */
  accountMenuKeydownHandler(event) {
    event.stopPropagation();
    if (event.keyCode === 13) {
      event.preventDefault();
      this.accountMenuClickHandler(event);
    } else if (event.keyCode === 9) {
      const accountMenuItem = this.template.querySelectorAll('.accounts-menu-item');
      if (!event.shiftKey && event.target.dataset.id === accountMenuItem[accountMenuItem.length - 1].dataset.id) {
        this.iconUrlObj.iconAccountsUrl = this.iconUrlObj.iconRightUrl;
        this.showAccountMenuOption = false;
      }
    }
  }

  /** 
   * Handle account icon enter key press 
   * @function userAccountKeypressHandler
   * @param {event} event
   */
  userAccountKeypressHandler(event) {
    if (event.keyCode === 13) {
      event.preventDefault();
      this.userAccountClickHandler();
    } else if (event.keyCode === 9) {
      if (event.shiftKey) {
        this.iconUrlObj.iconAccountsUrl = this.iconUrlObj.iconRightUrl;
        this.showAccountMenuOption = false;
        return;
      }
      event.preventDefault();
      this.template.querySelectorAll('.accounts-menu-item')[0]?.focus();
      this.iconUrlObj.iconAccountsUrl = this.iconUrlObj.iconDownUrl;
      this.showAccountMenuOption = true;
    }
  }
}