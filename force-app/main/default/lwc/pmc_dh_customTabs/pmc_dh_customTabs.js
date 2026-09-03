import { LightningElement, track, api, wire } from "lwc";
import { toastMessageHandler, fireEvent } from "c/pmc_dh_utilityJs";
import { CurrentPageReference } from "lightning/navigation";
import getUserManagementTabs from "@salesforce/apex/PMC_DH_PermissionsFrameworkUtilClass.getFeatureVisibilityMyAccountData";
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import basePath from "@salesforce/community/basePath";

import pmc_customTabs_previous from "@salesforce/label/c.pmc_customTabs_previous";
import pmc_customTabs_next from "@salesforce/label/c.pmc_customTabs_next";
import pmc_breadcrumb_myAccount from "@salesforce/label/c.pmc_breadcrumb_myAccount";
import pmc_breadcrumb_homepage from "@salesforce/label/c.pmc_breadcrumb_homepage";
import pmc_leadManagement_switchAccMsg from "@salesforce/label/c.pmc_leadManagement_switchAccMsg";
import pmc_leadManagement_switchAcc from "@salesforce/label/c.pmc_leadManagement_switchAcc";
import pmc_rebates_openACase from "@salesforce/label/c.pmc_rebates_openACase";
import pmc_rebates_rebateInfoMsg from "@salesforce/label/c.pmc_rebates_rebateInfoMsg";
import pmc_leadManagement_moreInformation from "@salesforce/label/c.pmc_leadManagement_moreInformation";

const ADDRESSES_LOCALE = "Addresses";
const USER_MANAGEMENT_LOCALE = "UserManagement";
const LEAD_MANAGEMENT_LOCALE = "LeadManagement";
const REBATES_LOCALE = "Rebates";

export default class Pmc_dh_customTabs extends LightningElement {
  @track baseUrl = basePath + "/";
  @track tabsArray = [];
  @api userManagementTabsHandler;

  @track labels = {
    pmc_customTabs_previous,
    pmc_customTabs_next,
    pmc_breadcrumb_myAccount,
    pmc_leadManagement_switchAccMsg,
    pmc_leadManagement_switchAcc,
    pmc_rebates_openACase,
    pmc_rebates_rebateInfoMsg,
    pmc_leadManagement_moreInformation
  };

  scrollDuration = 300;
  leftArrow;
  rightArrow;
  arrowMargin = 16;
  isContentLoaded = false;
  isArrowNeeded = false;
  prevDisabled = false;
  nextDisabled = false;
  mobileItemWidth;
  scrollSize = 0;
  pageRendered = false;
  error;
  intervalId;

  isActiveTabAddress = false;
  isAddNewAddressModal = false;
  isActiveTabUserManagement = false;
  isActiveTabLeadsManagement = false;
  isActiveTabRebates = false;
  isCreateCaseEnabled = false;

  isShowSwitchAccountModal = false;
  currentAccountSessionId = "";
  isSpinner = false;
  @track cloneAccArray = [];
  @track iconUrlObj = {
    infoIconUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-info.svg`
  };

  @track activeTab = "";
  @api
  setActiveTab(data) {
    this.activeTab = data;
    if (this.activeTab === "Addresses") {
      this.isActiveTabAddress = true;
      this.isAddNewAddressModal = true;
    }
  }

  crumbs = [
    { label: pmc_breadcrumb_homepage, url: this.baseUrl, isActive: false },
    { label: pmc_breadcrumb_myAccount, url: "", isActive: true }
  ];

  /**
 * Calling pageref
 */
  @wire(CurrentPageReference) pageRef;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    let that = this;
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.intervalId = setInterval(() => {
      if (sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
        clearInterval(that.intervalId);
        that.loadNavigation();
      }
    }, 100);
    if (this.userManagementTabsHandler?.Addresses) {
      this.isActiveTabAddress = true;
      this.isAddNewAddressModal = true;
    }
  }

  /** 
   * Tetching data from apex class 
   * @function loadNavigation
   */
  loadNavigation() {
    let effectiveAccountId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
    getUserManagementTabs({
      strEffAccountId: effectiveAccountId
    })
      .then((result) => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
          }
          this.tabsArray = JSON.parse(result.strResult);
          this.tabsArray.forEach((el, i) => {
            el.id = i + 1;
            if (this.activeTab) {
              el.state =
                el.strTabValue === this.activeTab ? "active" : "inActive";
            } else {
              el.state = i === 0 ? "active" : "inActive";
            }
          });
          const isTabActive = this.tabsArray?.some(tabData => tabData.state === 'active');
          if (!isTabActive) {
            this.tabsArray[0].state = 'active';
          }
          fireEvent(this.pageRef, "tabArrayData", this.tabsArray);
        }
        this.isContentLoaded = true;
      })
      .catch((err) => {
        toastMessageHandler();
        this.error = err;
      });
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (this.pageRendered && this.isContentLoaded) return;
    if (this.getMenuSize() > this.getMenuWrapperSize()) {
      this.isArrowNeeded = true;
      this.leftArrow = this.template.querySelector(".left-arrow");
      this.rightArrow = this.template.querySelector(".right-arrow");

      this.template.querySelector(".menu").classList.add("menu-padding");
      this.template
        .querySelector('.item[data-state="active"]')
        .scrollIntoView();

      if (this.leftArrow && this.rightArrow) {
        this.pageRendered = true;
        this.handleEventListner();
      }
    }
  }

  /**
  * On click of scroll arrows
  * @function handleEventListner
  */
  handleEventListner() {
    this.rightArrow.addEventListener("click", () => {
      this.scrollSize =
        this.getNextItemWidth(true) -
        this.getMenuWrapperSize() +
        2 * this.arrowMargin;

      this.template.querySelector(".menu-wrapper").scroll({
        left: this.scrollSize,
        behavior: "smooth",
        inline: "nearest"
      });
    });

    this.leftArrow.addEventListener("click", () => {
      this.scrollSize = this.getNextItemWidth(false);

      this.template.querySelector(".menu-wrapper").scroll({
        left: this.scrollSize,
        behavior: "smooth",
        inline: "nearest"
      });
    });
  }

  /**
  * Returns width of device
  * @function getMenuWrapperSize
  */
  getMenuWrapperSize() {
    return this.template.querySelector(".menu-wrapper").clientWidth;
  }

  /**
  * Returns total width of all tabs
  * @function getMenuSize
  */
  getMenuSize() {
    let width = 0;
    this.template.querySelectorAll(".item").forEach((el) => {
      width += el.clientWidth;
    });
    return width;
  }

  /**
  * Scrolls to the selected tab
  * @function getMenuPosition
  */
  getMenuPosition() {
    return this.template.querySelector(".menu-wrapper").scrollLeft;
  }

  /**
  * Returns width of next tab
  * @function getNextItemWidth
  * @param {boolean} flag 
  */
  getNextItemWidth(flag) {
    const position = flag
      ? this.getMenuPosition() + this.getMenuWrapperSize()
      : this.getMenuPosition();
    let width = 0;
    let item;
    for (let el of this.template.querySelectorAll(".item")) {
      width += el.clientWidth;
      if (width >= position) {
        if (!flag) width -= el.clientWidth;
        break;
      }
      item = el;
    }
    return Math.floor(width) === Math.floor(position)
      ? width - item?.clientWidth
      : width;
  }

  /**
   * Displaying contents of the selected tab 
   * @function handleItemClickEvent
   * @param {event} event 
   */
  handleItemClickEvent(event) {
    const id = event.target?.dataset?.id;
    this.dispatchEvent(
      new CustomEvent("tabclick", {
        detail: {
          name: event.target.dataset.value
        }
      })
    );
    this.tabsArray.forEach((item) => {
      item.state = item.id.toString() === id.toString() ? "active" : "inActive";
    });
    event.target.scrollIntoView();
    if (
      event.target?.dataset?.value &&
      event.target.dataset.value === ADDRESSES_LOCALE
    ) {
      this.isActiveTabAddress = !this.isActiveTabAddress;
    } else {
      this.isActiveTabAddress = false;
    }

    if (
      event.target?.dataset?.value &&
      event.target.dataset.value === USER_MANAGEMENT_LOCALE
    ) {
      this.isActiveTabUserManagement = !this.isActiveTabUserManagement;
    } else {
      this.isActiveTabUserManagement = false;
    }

    if (
      event.target?.dataset?.value &&
      event.target.dataset.value === LEAD_MANAGEMENT_LOCALE
    ) {
      this.isActiveTabLeadsManagement = !this.isActiveTabLeadsManagement;
    } else {
      this.isActiveTabLeadsManagement = false;
    }

    if (
      event.target?.dataset?.value &&
      event.target.dataset.value === REBATES_LOCALE
    ) {
      this.isActiveTabRebates = !this.isActiveTabRebates;
    } else {
      this.isActiveTabRebates = false;
    }
  }

  /**
   * Close Switch Account Modal
   * @function closeSwitchAccountModal
   */
  closeSwitchAccountModal() {
    this.isShowSwitchAccountModal = false;
  }

  /**
   * Open Switch Account Modal
   * @function openSwitchAccountModal
   */
  openSwitchAccountModal() {
    this.isShowSwitchAccountModal = true;
  }

  /**
   * Create Case Modal open handler
   * @function createCaseHandler
   */
  createCaseHandler() {
    this.isCreateCaseEnabled = !this.isCreateCaseEnabled;
  }

  /**
   * Create Case Modal close handler
   * @function closeCreateCaseModal
   * @param {Event} event 
   */
  closeCreateCaseModal(event) {
    this.isCreateCaseEnabled = event.detail.value;
  }
}