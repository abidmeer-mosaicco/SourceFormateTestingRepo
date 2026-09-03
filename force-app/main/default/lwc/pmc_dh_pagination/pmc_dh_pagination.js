import { LightningElement, api, track } from "lwc";
import {
  sortData,
  registerListener,
  unregisterAllListeners,
  fireEvent
} from "c/pmc_dh_utilityJs";
import pmc_pagination_previous from "@salesforce/label/c.pmc_pagination_previous";
import pmc_pagination_next from "@salesforce/label/c.pmc_pagination_next";

/**
 * A custom LWC to display pagination on datatables
 * @alias Pmc_dh_pagination
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 *
 * @example
 * <c-pmc_dh_pagination></c-pmc_dh_pagination>
 */

export default class Pmc_dh_pagination extends LightningElement {
  @track labels = {
    pmc_pagination_previous,
    pmc_pagination_next
  };
  @track showPagination = true;
  @track themeClass = "";
  @track paginatedData = [];
  @track _genericData = [];
  @track paginationProps = {
    currentPage : 1,
    pageListFirst : [],
    pageListLast : [],
    pageListToShow : [],
    pageNumberList : [],
    showFirstDot : false,
    showNextDot : false
  };
  @api noOfRecordsPerPage;
  @api buttonLimit;
  @api
  get genericdata() {
    return this._genericData;
  }
  set genericdata(value) {
    if (value) {
      this._genericData = JSON.parse(JSON.stringify(value));
    }
  }
  @api
  setDataOnSearch(value) {
    this.paginationProps.currentPage = 1;
    this._genericData = value;
    this.showPagination =
      this._genericData.length > this.noOfRecordsPerPage;
    this.paginatedData = this.processPaginationWithGenericMethod(value);
    this.dispatchDatatoParent(this.paginatedData);
  }

  @api
  setDataOnSort(data) {
    this.paginationProps.currentPage = 1;
    this._genericData = sortData(
      this._genericData,
      data.sortBy,
      data.datatype,
      data.sortDirection
    );
    this.paginatedData = this.processPaginationWithGenericMethod(
      this._genericData
    );
    this.dispatchDatatoParent(this.paginatedData);
    fireEvent(this.pageRef, 'exportToCsvEvent', {'exportData': [...this._genericData]});
  }

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    if (this.modalTheme) {
      this.themeClass = "modal-pagination";
    }
    this.showPagination =
      this._genericData.length > this.noOfRecordsPerPage;
    this.paginatedData = this.processPaginationWithGenericMethod(
      this._genericData
    );
    this.dispatchDatatoParent(this.paginatedData);
    registerListener("colSortEv", this.setDataOnSort, this);
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    try { 
      this.highlightPage();
      this.dispatchDatatoParent(this.paginatedData);
    }
    catch(e) {
      console.log('Error in pagi rc:',e);
    }
  }

  /** 
   * Returns true if you are on first page otherwise false 
   * @function checkStart
   */
  get checkStart() {
    if (Number(this.paginationProps.currentPage) === 1) {
      return true;
    }
    return false;
  }

  /** 
   * Returns true if you are on last page otherwise false 
   * @function checkEnd
   */
  get checkEnd() {
    if (
      this.paginationProps.pageNumberList &&
      this.paginationProps.pageNumberList.length === Number(this.paginationProps.currentPage)
    ) {
      return true;
    }
    return false;
  }

  /**
   * Dispatch current page data to parent component
   * @function dispatchDatatoParent
   * @param {Object[]} data
   */
  dispatchDatatoParent(data) {
    const manipulatedDataEvent = new CustomEvent("paginationchange", {
      detail: data,
      pageNo: this.paginationProps.currentPage
    });
    this.dispatchEvent(manipulatedDataEvent);
  }

  /**
   * Method used to calcuate the number of pages to be displayed and assign value to pageNumberList variable
   * @function processPaginationWithGenericMethod
   * @param {Object[]} data
   * @returns {Object[]} Returns data to be displayed on current page
   */
  processPaginationWithGenericMethod(data) {
    if (data.length > 0) {
      const pageNumberArray = [];
      this.totalPagesToDisplay = Math.ceil(
        data.length / this.noOfRecordsPerPage
      );
      for (let index = 1; index <= this.totalPagesToDisplay; index++) {
        pageNumberArray.push(index);
      }
      this.paginationProps.pageNumberList = pageNumberArray;
      this.displayPageNumbers();
    } else {
      this.totalPagesToDisplay = 0;
      this.paginationProps.pageNumberList = [];
    }
    return data.slice(0, this.noOfRecordsPerPage);
  }

  /**
   * Method used to display page numbers on pagination component
   * @function displayPageNumbers
   */
  displayPageNumbers() {
    let firstDot = false;
    let nextDot = false;
    let startIndexToArray, endIndexToArray;
    const currentPageNumber = Number(this.paginationProps.currentPage);
    const buttonLimit = Number(this.buttonLimit);

    if (this.paginationProps.pageNumberList.length > currentPageNumber + buttonLimit) {
      nextDot = true;
    }
    if (currentPageNumber > 3) {
      firstDot = true;
    }
    if (currentPageNumber < 4) {
      startIndexToArray = 1;
    } else {
      if (currentPageNumber + buttonLimit >= this.paginationProps.pageNumberList.length) {
        startIndexToArray = this.paginationProps.pageNumberList.length - buttonLimit - 1;
      } else {
        startIndexToArray = currentPageNumber - 1;
      }
    }
    if (currentPageNumber + buttonLimit >= this.paginationProps.pageNumberList.length) {
      endIndexToArray = this.paginationProps.pageNumberList.length - 1;
    } else {
      endIndexToArray = 3;
    }
    if (firstDot && nextDot) {
      endIndexToArray = startIndexToArray + 1;
    }
    if (this.paginationProps.pageNumberList.length < 6 && this.paginationProps.pageNumberList.length > 2) {
      nextDot = false;
      firstDot = false;
      startIndexToArray = 1;
      endIndexToArray = this.paginationProps.pageNumberList.length - 1;
    }
    const DynamicPageArray = this.paginationProps.pageNumberList.slice(
      startIndexToArray,
      endIndexToArray
    );
    this.paginationProps.showFirstDot = firstDot;
    this.paginationProps.showNextDot = nextDot;
    this.paginationProps.pageListToShow = DynamicPageArray;
    this.paginationProps.pageListFirst = this.paginationProps.pageNumberList.slice(0, 1);
    if (this.paginationProps.pageNumberList.length !== 1) {
      this.paginationProps.pageListLast = this.paginationProps.pageNumberList.slice(
        this.paginationProps.pageNumberList.length - 1,
        this.paginationProps.pageNumberList.length + 1
      );
    } else {
      this.paginationProps.pageListLast = [];
    }
  }

  /**
   * Handler to fetch next page data
   * @function onNext
   */
  onNext() {
    if (this.paginationProps.currentPage < this.totalPagesToDisplay) {
      this.paginationProps.currentPage = Number(this.paginationProps.currentPage) + 1;
      this.paginatedData = this.fetchCurrentPageData();
      this.displayPageNumbers();
    }
  }

  /**
   * Handler to fetch previous page data
   * @function onPrev
   */
  onPrev() {
    if (this.paginationProps.currentPage > 1) {
      this.paginationProps.currentPage = Number(this.paginationProps.currentPage) - 1;
      this.paginatedData = this.fetchCurrentPageData();
      this.displayPageNumbers();
    }
  }

  /**
   * Passes over current page details to parent and also highlights the current page number
   * @function displayPageDetails
   * @param {Event} event 
   */
  displayPageDetails(event) {
    this.paginationProps.currentPage =
      event && event.target
        ? event.target.dataset.id
        : this.paginationProps.currentPage
        ? this.paginationProps.currentPage
        : 1;
    this.paginatedData = this.fetchCurrentPageData();
    const lastpageData = this.fetchLastPageData();
    if (!this.paginatedData.length) {
      this.paginationProps.currentPage = this.paginationProps.currentPage - 1;
      this.paginatedData = this.fetchCurrentPageData();
      this.paginationProps.pageNumberList.pop();
    }
    if (!lastpageData.length) {
      this.paginationProps.pageNumberList.pop();
    }
    this.displayPageNumbers();
    this.highlightPage();
    const scrollToTopEvent = new CustomEvent("scrolltotop");
    this.dispatchEvent(scrollToTopEvent);
  }

  /**
   * Return current page data
   * @function fetchCurrentPageData
   * @returns {Object[]}
   */
  fetchCurrentPageData() {
    const startIndexCurrent =
      this.paginationProps.currentPage * this.noOfRecordsPerPage - this.noOfRecordsPerPage;
    const endIndexCurrent = this.paginationProps.currentPage * this.noOfRecordsPerPage;
    return this._genericData.slice(startIndexCurrent, endIndexCurrent);
  }

  /**
   * Return last page data
   * @function fetchLastPageData
   * @returns {Object[]}
   */
  fetchLastPageData() {
    const lastPage = this.paginationProps.pageNumberList[this.paginationProps.pageNumberList.length - 1];
    const startIndexCurrent =
      lastPage * this.noOfRecordsPerPage - this.noOfRecordsPerPage;
    const endIndexCurrent = lastPage * this.noOfRecordsPerPage;
    return this._genericData.slice(startIndexCurrent, endIndexCurrent);
  }

  /**
   * Highlight current page number
   * @function highlightPage
   */
  highlightPage() {
    this.template.querySelectorAll("a.paginationlink").forEach((pagebutton) => {
      if (Number(this.paginationProps.currentPage) === parseInt(pagebutton.dataset.id, 10)) {
        pagebutton.classList.add("highlight");
      } else {
        pagebutton.classList.remove("highlight");
      }
    });
  }

  /**
   * Lifecycle Hook
   */
  disconnectedCallback() {
    unregisterAllListeners(this);
  }
}