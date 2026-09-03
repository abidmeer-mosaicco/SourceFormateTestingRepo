import { LightningElement, track } from "lwc";
import basePath from "@salesforce/community/basePath";
import { NavigationMixin } from "lightning/navigation";
import { SORT_DIRECTION, sortData, formatDateTime, urlRedirect, toastMessageHandler } from "c/pmc_dh_utilityJs";

import fetchQuoteRecords from "@salesforce/apex/PMC_DH_QuoteListViewController.fetchQuoteRecords";

import pmc_requestForQuote_quoteId from "@salesforce/label/c.pmc_requestForQuote_quoteId";
import pmc_quoteHistory_quoteNumber from "@salesforce/label/c.pmc_quoteHistory_quoteNumber";
import pmc_quoteCheckoutFlow_shipTo from "@salesforce/label/c.pmc_quoteCheckoutFlow_shipTo";
import pmc_quoteCheckoutFlow_deliveryMode from "@salesforce/label/c.pmc_quoteCheckoutFlow_deliveryMode";
import pmc_contractDetails_products from "@salesforce/label/c.pmc_contractDetails_products";
import pmc_quoteHistory_totalQty from "@salesforce/label/c.pmc_quoteHistory_totalQty";
import pmc_quoteHistory_totalPrice from "@salesforce/label/c.pmc_quoteHistory_totalPrice";
import pmc_quoteHistory_expiresAt from "@salesforce/label/c.pmc_quoteHistory_expiresAt";
import pmc_userManagement_userStatus from "@salesforce/label/c.pmc_userManagement_userStatus";
import pmc_quoteHistory_viewQuote from "@salesforce/label/c.pmc_quoteHistory_viewQuote";
import pmc_quoteHistory_quoteHistory from "@salesforce/label/c.pmc_quoteHistory_quoteHistory";
import pmc_quoteHistory_searchQuotes from "@salesforce/label/c.pmc_quoteHistory_searchQuotes";
import pmc_quoteHistory_filterByProducts from "@salesforce/label/c.pmc_quoteHistory_filterByProducts";
import pmc_orderHistory_noResultsMsg from "@salesforce/label/c.pmc_orderHistory_noResultsMsg";
import pmc_orderDetails_inactive from "@salesforce/label/c.pmc_orderDetails_inactive";
import pmc_quoteDetailsFlow_statusActionPending from "@salesforce/label/c.pmc_quoteDetailsFlow_statusActionPending";

const SUCCESS_BADGE_CLASS = "success";
const STATUS_BADGE_FINISHED = "finished";
const expiresAtField = "expirationDateTime";
const productPicklist = "product";

const columns = [
  {
    label: pmc_requestForQuote_quoteId,
    fieldName: "quoteFriendlyId",
    type: "dynamiclink",
    dataType: "alphanumeric",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_quoteHistory_quoteNumber,
    fieldName: "quoteNumber",
    type: "text",
    dataType: "alphanumeric",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_quoteCheckoutFlow_shipTo,
    fieldName: "shipTo",
    type: "text",
    cellAttributes: {
      class: "fixedWidthCol"
    },
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_quoteCheckoutFlow_deliveryMode,
    fieldName: "deliveryMode",
    type: "text",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_contractDetails_products,
    fieldName: "products",
    type: "text",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_quoteHistory_totalQty,
    fieldName: "totalQuantity",
    type: "text",
    dataType: "number",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_quoteHistory_totalPrice,
    fieldName: "totalPrice",
    type: "text",
    dataType: "number",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_quoteHistory_expiresAt,
    fieldName: "expirationDateTime",
    type: "text",
    dataType: "datetime",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_userManagement_userStatus,
    fieldName: "status",
    type: "badge",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true,
    typeAttributes: {
      variant: "slds-badge_lightest"
    }
  },
  {
    label: "",
    fieldName: "",
    type: "link",
    typeAttributes: {
      rowActionName: pmc_quoteHistory_viewQuote
    }
  }
];

/**
 * A custom LWC to display quote history list.
 * @alias Pmc_dh_quoteHistoryList
 * @extends LightningElement
 * @hideconstructor
 * @author Vanshika
 *
 * @example
 * <c-pmc_dh_quote-history-list></c-pmc_dh_quote-history-list>
 */

export default class Pmc_dh_quoteHistoryList extends NavigationMixin(LightningElement) {
  recordsPerPage = 10;
  defaultSortOrder = SORT_DIRECTION.ASC;
  effAccId = '';
  isResultSetEmpty = false;
  @track columns = columns;
  @track pageLoaded = false;
  @track isSpinner = false;
  @track quoteList = [];
  @track filteredData = [];
  @track searchData = [];
  @track filters = [
    {
      label: pmc_quoteHistory_filterByProducts,
      name: productPicklist,
      options: []
    }
  ];

  /**
   * Custom Label Details
   */
  @track labels = {
    pmc_quoteHistory_quoteHistory,
    pmc_quoteHistory_searchQuotes,
    pmc_orderHistory_noResultsMsg,
    pmc_orderDetails_inactive,
    pmc_quoteDetailsFlow_statusActionPending
  };

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    let that = this;
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.intervalId = setInterval(() => {
      if (sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
        this.effAccId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
        clearInterval(that.intervalId);
        this.loadQuoteList();
      }
    }, 100);
  }

  /**
   * Fetches entire quote list
   * @function loadQuoteList
   */
  loadQuoteList() {
    this.isSpinner = true;
    fetchQuoteRecords({
      searchParams: {
        strSearchTerm: '',
        datFromDate: null,
        datToDate: null,
      },
      strEffectiveAccId: this.effAccId
    })
      .then((result) => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
          }
          if (result?.lstQuotes && result?.lstProductFilters) {
            this.quoteList = JSON.parse(JSON.stringify(result.lstQuotes));
            if (this.quoteList.length > 1000) {
              this.quoteList.length = 1000;
            }
            let productArr = JSON.parse(JSON.stringify(result.lstProductFilters))
            this.setProductFilters(productArr);
            this.updateQuoteDetails(JSON.parse(JSON.stringify(this.quoteList)));
          }
        }
        this.pageLoaded = true;
        this.isSpinner = false;
      })
      .catch(() => {
        toastMessageHandler();
        this.pageLoaded = true;
        this.isSpinner = false;
      })
  }

  /**
   * Updates quote records
   * @function updateQuoteDetails
   * @param {Array} quotes 
   * @param {boolean} fetchAll
   */
  updateQuoteDetails(quotes, fetchAll = true) {
    quotes.forEach((item) => {
      item.Id = item.quoteId
      item.expirationDateTime = item.expirationDateTime ? formatDateTime(item.expirationDateTime) : "N/A";
      if (item.status !== this.labels.pmc_quoteDetailsFlow_statusActionPending) {
        item.badgeStyleClass = SUCCESS_BADGE_CLASS;
      }
      if (item.status === this.labels.pmc_orderDetails_inactive) {
        item.badgeStyleClass = STATUS_BADGE_FINISHED;
      }
    });
    if (fetchAll) {
      this.quoteList = JSON.parse(JSON.stringify(quotes));
    }
    this.filteredData = sortData(JSON.parse(JSON.stringify(quotes)), expiresAtField, "datetime", SORT_DIRECTION.ASC);
    this.searchData = JSON.parse(JSON.stringify(this.filteredData));
    this.setColumnSortOrder();
    this.template.querySelector("c-pmc_dh_pagination")?.setDataOnSearch(this.filteredData);
  }

  /**
   * Returns Search Results based on user inputs
   * @function handleSearch
   * @param {Event} event 
   */
  handleSearch(event) {
    const targetEl = event.detail.targetId;
    let searchJSON = JSON.parse(JSON.stringify(event.detail.searchObj));
    this.isResultSetEmpty = false;
    if (searchJSON?.strSearchInput?.length > 2 || searchJSON?.fromDate || searchJSON?.toDate) {
      this.isSpinner = true;
      fetchQuoteRecords({
        searchParams: {
          strSearchTerm: searchJSON?.strSearchInput?.length > 2 ? searchJSON?.strSearchInput : null,
          datFromDate: targetEl === "strSearchInput" ? null : searchJSON?.fromDate,
          datToDate: targetEl === "strSearchInput" ? null : searchJSON?.toDate,
        },
        strEffectiveAccId: this.effAccId
      })
        .then((quotes) => {
          if (quotes && Object.keys(quotes).length) {
            if (JSON.parse(JSON.stringify(quotes)).statusCodeMessage?.strStatusMessage) {
              toastMessageHandler(JSON.parse(JSON.stringify(quotes)).statusCodeMessage.strStatusMessage)
            }
            if (quotes.lstQuotes.length > 1000) {
              quotes.lstQuotes.length = 1000;
            }
            if (quotes.lstQuotes.length === 0) {
              this.isResultSetEmpty = true;
            }
            this.updateQuoteDetails(JSON.parse(JSON.stringify(quotes.lstQuotes)), false);
            if (quotes.lstProductFilters) {
            this.setProductFilters(JSON.parse(JSON.stringify(quotes.lstProductFilters)));
          }
          }
          this.pageLoaded = true;
          this.isSpinner = false;
        })
        .catch(() => {
          toastMessageHandler();
          this.pageLoaded = true;
          this.isSpinner = false;
        });
    } else {
      this.loadQuoteList();
    }
  }

  /**
   * Set the product filters
   * @function setProductFilters
   * @param {Array} products 
   */
  setProductFilters(products) {
    let uniqueProducts = [...new Map(products.map(item =>
      [item.value, item])).values()];
    this.filters.forEach((el) => {
      if (el.name === productPicklist) {
        el.options = uniqueProducts;
      }
    });
    this.filters = JSON.parse(JSON.stringify(this.filters));
  }

  /**
   * Returns filter results based on product picklist selection
   * @function handleApplyFilter
   * @param {Event} event 
   */
  handleApplyFilter(event) {
    this.isResultSetEmpty = false;
    let searchJSON = JSON.parse(JSON.stringify(event.detail.searchObj));
    if (searchJSON?.product) {
      this.filteredData = this.searchData.filter((data) => {
        return data.setSKU.includes(searchJSON.product)
      });
    } else {
      this.filteredData = JSON.parse(JSON.stringify(this.searchData));
    }
    if (this.filteredData.length === 0) {
      this.isResultSetEmpty = true;
    }
    this.setDefaultMode();
  }

  /**
   * Navigate to Quote Info Details Page
   * @function navigateToQuoteDetails
   * @param {Event} event 
   */
  navigateToQuoteDetails(event) {
    let recId = event.detail.id;
    this.filteredData.forEach((el) => {
      if (el.quoteId === recId) {
        let url = el.quoteDetailLink;
        this[NavigationMixin.GenerateUrl]({
          type: "standard__webPage",
          attributes: {
            url: `${basePath}/${url}`
          }
        }).then((generatedUrl) => {
          urlRedirect(generatedUrl);
        });
      }
    })
  }

  /**
   * Setting column sort order once sorting is applied
   * @function setColumnSortOrder
   */
  setColumnSortOrder() {
    this.columns = this.columns.map((col) => {
      if (col.fieldName === expiresAtField) {
        col.isAscSort = false;
      }
      return col;
    });
  }

  /**
   * Set default state of quote list
   * @function setDefaultMode
   */
  setDefaultMode() {
    this.filteredData = sortData(this.filteredData, expiresAtField, "datetime", SORT_DIRECTION.ASC);
    this.setColumnSortOrder();
    this.template.querySelector("c-pmc_dh_pagination")?.setDataOnSearch(this.filteredData);
  }

  /**
   * Resets the filter results
   * @function clearFilters
   */
  clearFilters() {
    this.isResultSetEmpty = false;
    if (this.searchData.length === 0) {
      this.isResultSetEmpty = true;
    }
    this.filteredData = JSON.parse(JSON.stringify(this.searchData));
    this.setDefaultMode();
  }

  /**
   * Resets the search results
   * @function clearSearchInputs
   */
  clearSearchInputs() {
    this.isResultSetEmpty = false;
    this.loadQuoteList();
  }

  /**
   * Updating filtered data to display only current page details
   * @function updatePaginatedData
   * @param {Event} event 
   */
  updatePaginatedData(event) {
    this.filteredData = event.detail;
  }
}