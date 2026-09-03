import { LightningElement, api, track } from "lwc";
import pmc_addresses_searchFilters from "@salesforce/label/c.pmc_addresses_searchFilters";
import pmc_searchFilters_filter from "@salesforce/label/c.pmc_searchFilters_filter";
import pmc_searchInput_search from "@salesforce/label/c.pmc_searchInput_search";
import pmc_addresses_apply from "@salesforce/label/c.pmc_addresses_apply";
import pmc_addresses_clear from "@salesforce/label/c.pmc_addresses_clear";
import pmc_caseMgmt_from from "@salesforce/label/c.pmc_caseMgmt_from";
import pmc_caseMgmt_to from "@salesforce/label/c.pmc_caseMgmt_to";
import pmc_caseMgmt_invalidDateErr from "@salesforce/label/c.pmc_caseMgmt_invalidDateErr";
import pmc_searchFilters_futureDateError from "@salesforce/label/c.pmc_searchFilters_futureDateError";
import pmc_searchFilters_pastDateError from "@salesforce/label/c.pmc_searchFilters_pastDateError";
import { getTodayDate } from "c/pmc_dh_utilityJs";

const BORDER_RAD_CLASS = "brdr-rad";

/**
 * A custom LWC for search filters
 * @alias Pmc_dh_searchFilters
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 *
 * @example
 * <c-pmc_dh_search-filters></c-pmc_dh_search-filters>
 */

export default class Pmc_dh_searchFilters extends LightningElement {
  @api
  resetInputs() {
    this.clearFiltersHandler();
    this.searchFormObject = {};
    this.template
      .querySelectorAll(".inputDate")
      .forEach((inpt) => inpt.resetInput());
  }
  @track searchFormObject = {
    strSearchInput: null,
    toDate: "",
    fromDate: ""
  };
  @track _filters = [];
  @track minDate = "";
  @track maxDate = "";
  showFilter = true;
  pageRendered = false;
  @track labels = {
    pmc_addresses_searchFilters,
    pmc_searchFilters_filter,
    pmc_caseMgmt_from,
    pmc_caseMgmt_to,
    pmc_searchInput_search,
    pmc_addresses_apply,
    pmc_addresses_clear,
    pmc_caseMgmt_invalidDateErr,
    pmc_searchFilters_futureDateError,
    pmc_searchFilters_pastDateError
  };
  @api searchInputLabel = "";
  @api futureDateAllowed = false;
  @api
  get filters() {
    return this._filters;
  }
  set filters(val) {
    this._filters = JSON.parse(JSON.stringify(val));
  }

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    if (!this.futureDateAllowed) {
      this.maxDate = getTodayDate()
    }
    if (window.innerWidth < 768) {
      this.showFilter = false;
    }
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (this.pageRendered) return;
    if (window.innerWidth < 768 && !this.showFilter) {
      this.template
        .querySelector(".card-header")
        .classList.add(BORDER_RAD_CLASS);
    }
    this.pageRendered = true;
  }

  /**
   * Show/Hide search filters in mobile device
   * @function showSearchFilters
   */
  showSearchFilters() {
    this.showFilter = !this.showFilter;
    if (this.showFilter) {
      this.template
        .querySelector(".card-header")
        .classList.remove(BORDER_RAD_CLASS);
    } else {
      this.template
        .querySelector(".card-header")
        .classList.add(BORDER_RAD_CLASS);
    }
  }

  /** 
   * On input change event handler 
   * @function handleDataChange
   * @param {Event} event 
   */
  handleDataChange(event) {
    if (
      event.detail.value !== "undefined" &&
      event.target &&
      event.target.dataset
    ) {
      this.searchFormObject[event.target.dataset.id] = (event.target.dataset.id === "strSearchInput") ? event.detail.value.trim() : event.detail.value;
    }
    if (
      event.target.dataset.id === "fromDate" &&
      this.searchFormObject?.fromDate
    ) {
      this.minDate = this.searchFormObject.fromDate;
    }
  }

  /**
   * checking validity of all required fields
   * @function handleErrorOnSearch
   * @returns {boolean} - Returns true in case of error otherwise false
   */
  handleErrorOnSearch() {
    let allValid = true;
    this.template.querySelectorAll(".inputDate").forEach((inputComponent) => {
      if (!inputComponent.reportValidity()) {
        allValid = false;
      }
    });
    if (!allValid) {
      return true;
    }
    return false;
  }

  /**
   * Reset Date inputs
   * @function resetDateInputs
   */
  resetDateInputs() {
    this.template
      .querySelectorAll(".inputDate")
      .forEach((inpt) => inpt.resetInput());
    this.searchFormObject.fromDate = "";
    this.searchFormObject.toDate = "";
    this.minDate = "";
  }

  /** 
   * On key up event from search input
   * @function handleEnterKeyUp
   * @param {Event} event 
   */
  handleEnterKeyUp(event) {
    if (event.detail.keyCode === 13) {
      this.searchHandler(event);
    }
  }

  /**
   * Dispatches event to parent component to search on basis of user inputs otherwise reports error on inputs
   * @function searchHandler
   * @param {Event} event
   */
  searchHandler(event) {
    if (
      !(event.currentTarget.dataset.id === "strSearchInput") &&
      this.handleErrorOnSearch()
    )
      return;
    if (event.currentTarget.dataset.id === "strSearchInput") {
      this.resetDateInputs();
    }
    this.clearFiltersHandler();
    const searchEv = new CustomEvent("searchev", {
      detail: {
        targetId: event.currentTarget.dataset.id,
        searchObj: this.searchFormObject
      }
    });
    this.dispatchEvent(searchEv);
  }

  /**
   * Dispatches event to parent component to filter the search results
   * @function applyFilterHandler
   */
  applyFilterHandler() {
    const applyFilterEv = new CustomEvent("applyfilterev", {
      detail: {
        searchObj: this.searchFormObject
      }
    });
    this.dispatchEvent(applyFilterEv);
  }

  /**
   * Resets Filter picklist
   * @function clearFiltersHandler
   */
  clearFiltersHandler() {
    this._filters.forEach((filter) => {
      if (this.template.querySelector(`[data-id="${filter.name}"]`)) {
        this.template.querySelector(`[data-id="${filter.name}"]`).resetInput();
      }
      this.searchFormObject[filter.name] = "";
    });
    const clearFilter = new CustomEvent("clearfilterev", {});
    this.dispatchEvent(clearFilter);
  }

  /**
   * Reset search inputs
   * @function clearSearchInputs
   */
  clearSearchInputs() {
    this.clearFiltersHandler();
    this.searchFormObject = {};
    this.template
      .querySelectorAll(".inputDate")
      .forEach((inpt) => inpt.resetInput());
    const clearSearchInputs = new CustomEvent("clearsearchinputsev", {});
    this.dispatchEvent(clearSearchInputs);
  }
}