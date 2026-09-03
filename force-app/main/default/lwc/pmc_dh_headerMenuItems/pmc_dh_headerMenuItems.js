import { LightningElement, api, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import basePath from "@salesforce/community/basePath";
import pmc_brandingStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import { urlRedirect, formatNavigationUrl } from "c/pmc_dh_utilityJs";
import { getNavigationMenu } from "experience/navigationMenuApi";
import { productCategories } from "c/pmc_dh_navMenuUtility";

import pmc_contractDetails_products from "@salesforce/label/c.pmc_contractDetails_products";

export default class Pmc_dh_headerMenuItems extends NavigationMixin(LightningElement) {
  arrowDownUrl = `${pmc_brandingStaticResource}/icons/icon-arrowdown.svg`;
  pageRendered = false;
  _handler;
  @track _mainMenuList = [];
  @track productMenuItem = [];
  @track _langKeys = [];
  isSubMenuVisible = false;
  error;
  cssDropdownIcon = "dropdown-icon";

  @api
  get langKeys() {
    return this._langKeys;
  }
  set langKeys(value) {
    if (value) {
      this._langKeys = JSON.parse(JSON.stringify(value));
    }
  }

  @api
  get mainMenuList() {
    return this._mainMenuList;
  }
  set mainMenuList(value) {
    if (value) {
      this._mainMenuList = JSON.parse(JSON.stringify(value));
      
      this._mainMenuList.forEach((menu) => {
        menu.strTarget = formatNavigationUrl(this._langKeys, menu.strTarget);
      });
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      setTimeout(() => {
        this.fetchSubMenuOptions(this.productMenuItem);
      });
    }
  }

  /**
   * getNavigationMenu API from navigationMenuApi for sub-products under product category
   */
  @wire(getNavigationMenu)
  navMenu({ error, data }) {
    if (data) {
      this.productMenuItem = productCategories(data);
      this.productMenuItem.forEach((item) => {
        item.value = formatNavigationUrl(this._langKeys, item.value);
      });
    } else if (error) {
      this.error = error;
    }
  }

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    document.addEventListener("click", (this._handler = this.close.bind(this)));
  }

  /**
   * preventing default beahvior
   * @function ignore
   * @param {event} event
   */
  ignore(event) {
    event.stopPropagation();
    return false;
  }

  /**
   * closing the submenu
   * @function close
   */
  close() {
    this.isSubMenuVisible = false;
    this.cssDropdownIcon = "dropdown-icon";
  }

  /**
   * Method to align Submenu items for Products Category
   * @function fetchSubMenuOptions
   * @param {object} productMenuItem
   */
  fetchSubMenuOptions = (productMenuItem) => {
    const productsItem = this._mainMenuList.find(
      (item) => item.strLabel === pmc_contractDetails_products
    );
    if (productsItem) {
      this._mainMenuList = this._mainMenuList.map((el) => {
        if (el.strLabel === pmc_contractDetails_products && productMenuItem.length) {
          return {
            ...el,
            subMenuOptions: productMenuItem
          };
        }
        return el;
      });
    }
  };

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (this.pageRendered) return;
    this.pageRendered = true;
    const href = window.location.href.split(`${basePath}`)[1];
    this.template.querySelectorAll(".main-menu")?.forEach((el) => {
      if (href === el.dataset.target) {
        el.classList?.add("active");
      } else {
        el.classList?.remove("active");
      }
      if (el.dataset?.target?.includes("products")) {
        if (href.includes("global-search") || href.includes("products")) {
          el.classList?.add("active");
        }
      }
    });
  }

  /**
   * Handle header menu click and redirect to respective page
   * @function menuItemClickHandler
   * @param {event} event
   */
  menuItemClickHandler(event) {
    if (event.target.dataset.target === "dropdown-icon") {
      this.handleSubMenuList(event);
    } else {
      this.navigateToUrl(event.currentTarget.dataset.target);
      if (window.location.href.indexOf(event.currentTarget.dataset.id) === -1) {
        this.dispatchEvent(new CustomEvent("menuitemclicked"));
      }
    }
  }

  /**
   * Method to redirect once user clicks on sub products
   * @function subMenuOptionsClickHandler
   * @param {event} event
   */
  subMenuOptionsClickHandler = (event) => {
    
    event.stopPropagation();
    this.navigateToUrl(event.currentTarget.dataset.target);
  };

  /**
   * Handle redirection based on url
   * @function navigateToUrl
   * @param {string} url
   */
  navigateToUrl(url) {
    this[NavigationMixin.GenerateUrl]({
      type: "standard__webPage",
      attributes: {
        url: `${basePath}${url}`
      }
    }).then((generatedUrl) => {
      urlRedirect(generatedUrl);
    });
  }

  /**
   * Method to toggle dropdown list when user clicks on products.
   * @function handleSubMenuList
   * @param {event} event
   */
  handleSubMenuList(event) {
    if (this.isSubMenuVisible) {
      event?.stopPropagation();
    }
    clearTimeout(this.clickTimer);
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.clickTimer = setTimeout(() => {
      this.isSubMenuVisible = !this.isSubMenuVisible;
      this.cssDropdownIcon = this.isSubMenuVisible
        ? "dropdown-icon down"
        : "dropdown-icon";
    }, 500);
  }

  /**
   * Called on enter click and handle menu click
   * @function menuItemKeydownHandler
   * @param {event} event
   */
  menuItemKeydownHandler(event) {
    if (event.keyCode === 13) {
      event.preventDefault();
      this.menuItemClickHandler(event);
    }
  }
}