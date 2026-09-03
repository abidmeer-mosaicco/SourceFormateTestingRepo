import { LightningElement, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { registerListener, unregisterAllListeners, toastMessageHandler } from "c/pmc_dh_utilityJs";
import basePath from "@salesforce/community/basePath";
import verifyAccessForUserCreation from "@salesforce/apex/PMC_DH_RegistrationUtils.verifyAccessForUserCreation";

import pmc_userManagement_userRoleExists from "@salesforce/label/c.pmc_userManagement_userRoleExists";
import pmc_userManagement_superBuyerNotAuthorized from "@salesforce/label/c.pmc_userManagement_superBuyerNotAuthorized";
import pmc_breadcrumb_myAccount from "@salesforce/label/c.pmc_breadcrumb_myAccount";

/**
 * @slot header
 * @slot footer
 * @slot tabs
 * @slot ootb
 * @slot accountdetail
 * @slot addresses
 * @slot userdetail
 * @slot usermanagement
 * @slot preferences
 * @slot rebates
 * @slot leadmanagement
 * @slot outage
 */

export default class Pmc_dh_customThemeMyAccount extends NavigationMixin(LightningElement) {
  @track labels = {
    pmc_userManagement_userRoleExists,
    pmc_userManagement_superBuyerNotAuthorized
  };

  email;
  activeTab;
  pageRendered = false;

  @track userManagementTabsHandler = {
    AccountDetails: true,
    Addresses: false,
    Credit: false,
    LeadManagement: false,
    Preferences: false,
    Rebates: false,
    UserDetails: false,
    UserManagement: false
  };

  @track languageDropdownValues = [];
  @track childTabsData;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    let params = new URLSearchParams(window.location.search);
    this.email = params.get("email");
    this.activeTab = params.get("activeTab");
    registerListener("tabArrayData", this.handleCustomTabArrayEvent, this);
    if (!this.isOutage) {
      if (window.location.href.includes("app=commeditor")) {
        Object.keys(this.userManagementTabsHandler).forEach((el) => {
          this.userManagementTabsHandler[el] = true;
        });
      } else {
        if (this.activeTab !== null) {
          this.activeTab = this.activeTab.replace(/(?:^|-)(\w)/g, (_, c) =>
            c.toUpperCase()
          );
        }
        this.activeTab = this.activeTab || "AccountDetails";
      }
      if (this.email) {
        verifyAccessForUserCreation({
          emailId: this.email
        })
          .then((responseString) => {
            if (responseString && Object.keys(responseString).length) {
              let response = JSON.parse(responseString);
              if (response.statusCodeMessage?.strStatusMessage) {
                toastMessageHandler(response.statusCodeMessage.strStatusMessage)
              }
              if (response.boolIsSuperBuyerAuthorized) {
                if (response.boolIsUserExisting) {
                  toastMessageHandler("pmc_userManagement_userRoleExists");
                  this.navigateUrl(`${basePath}/my-accounts`);
                } else {
                  this.modalHandler(response);
                }
              } else {
                toastMessageHandler("pmc_userManagement_superBuyerNotAuthorized"
                );
                this.navigateUrl(
                  `${basePath}/my-accounts?activeTab=user-management`
                );
              }
            }
          })
          .catch(() => {
            toastMessageHandler();
          });
      }
      registerListener("languageEvent", this.handleLanguage, this);
    }
    this.setPageTitle();
  }

    /** 
   * Set title of checkout page
   * @function setPageTitle
   */
    setPageTitle() {
      document.title = pmc_breadcrumb_myAccount;
  }

  /**
   * Fetching language data through header
   * @function handleLanguage
   * @param {object} langOptions 
   */
  handleLanguage(langOptions) {
    if (langOptions) {
      this.languageDropdownValues = langOptions;
    }
  }

  /**
   * Lifecycle Hook
   */
  disconnectedCallback() {
    unregisterAllListeners(this);
  }

  /** 
   * Setting active tab on page load and on tab click as well 
   * @function activeTabOnPageLoad
   * @param {string} tabName
   */
  activeTabOnPageLoad = (tabName) => {
    Object.keys(this.userManagementTabsHandler).forEach((el) => {
      this.userManagementTabsHandler[el] = false;
    });
    const isTabActive = this.childTabsData?.some(tabData => tabData.strTabValue === tabName);
    this.userManagementTabsHandler[isTabActive ? tabName : 'AccountDetails'] = true;
  };

  /**
   * Fetching tabs data from customTabs Component
   * @function handleCustomTabArrayEvent
   * @param {object} data 
   */
  handleCustomTabArrayEvent(data) {
    if (data && data.length) {
      this.childTabsData = data;
      this.activeTabOnPageLoad(this.activeTab);
    }
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (this.pageRendered) return;
    this.template
      .querySelector("c-pmc_dh_custom-tabs")
      .setActiveTab(this.activeTab);
    this.pageRendered = true;
  }

  /**
   * Selects the tab clicked
   * @function tabClickHandler
   * @param {event} event 
   */
  tabClickHandler(event) {
    this.activeTabOnPageLoad(event.detail.name);
  }

  /**
   * Shows add new user modal for access to super buyer
   * @function modalHandler
   * @param {object} data 
   */
  modalHandler(data) {
    this.template.querySelector("c-pmc_dh_add-new-user-prefilled").showModal();
    this.template
      .querySelector("c-pmc_dh_add-new-user-prefilled")
      .setModalData(data);
  }

  /**
   * Navigation mixin : navigate to another page
   * @function navigateUrl
   * @param {string} url 
   */
  navigateUrl(url) {
    const pageRef = {
      type: "standard__webPage",
      attributes: {
        url: url
      }
    };
    this[NavigationMixin.Navigate](pageRef);
  }
}