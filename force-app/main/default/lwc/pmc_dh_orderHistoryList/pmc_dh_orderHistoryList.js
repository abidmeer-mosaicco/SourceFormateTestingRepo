import { LightningElement, track } from "lwc";
import basePath from "@salesforce/community/basePath";
import { NavigationMixin } from "lightning/navigation";
import {
  SORT_DIRECTION,
  sortData,
  formatDate,
  unFormatDate,
  formatDateTime,
  isBrazilRegion,
  fireEvent,
  urlRedirect,
  toastMessageHandler
} from "c/pmc_dh_utilityJs";

import getOrderRecords from "@salesforce/apex/PMC_DH_OrderListViewController.getOrderRecords";
import fetchOrderHistory from "@salesforce/apex/PMC_DH_OrderSubmitController.fetchOrderHistory";

import pmc_orderHistory_confirmed from "@salesforce/label/c.pmc_orderHistory_confirmed";
import pmc_orderHistory_requested from "@salesforce/label/c.pmc_orderHistory_requested";
import pmc_orderHistory_orderHistory from "@salesforce/label/c.pmc_orderHistory_orderHistory";
import pmc_orderHistory_orderNumber from "@salesforce/label/c.pmc_orderHistory_orderNumber";
import pmc_orderHistory_requestNumber from "@salesforce/label/c.pmc_orderHistory_requestNumber";
import pmc_requestToDeliver_contractNumber from "@salesforce/label/c.pmc_requestToDeliver_contractNumber";
import pmc_contractDetails_poNumber from "@salesforce/label/c.pmc_contractDetails_poNumber";
import pmc_quoteCheckoutFlow_products from "@salesforce/label/c.pmc_quoteCheckoutFlow_products";
import pmc_quoteCheckoutFlow_shipTo from "@salesforce/label/c.pmc_quoteCheckoutFlow_shipTo";
import pmc_requestToDeliver_qty from "@salesforce/label/c.pmc_requestToDeliver_qty";
import pmc_quoteHistory_totalPrice from "@salesforce/label/c.pmc_quoteHistory_totalPrice";
import pmc_orderHistory_dateCreated from "@salesforce/label/c.pmc_orderHistory_dateCreated";
// import pmc_orderHistory_viewOrder from "@salesforce/label/c.pmc_orderHistory_viewOrder";
import pmc_quoteHistory_filterByProducts from "@salesforce/label/c.pmc_quoteHistory_filterByProducts";
import pmc_orderHistory_noResultsMsg from "@salesforce/label/c.pmc_orderHistory_noResultsMsg";
import pmc_orderHistory_searchOrders from "@salesforce/label/c.pmc_orderHistory_searchOrders";
import pmc_requestToDeliver_expectedShipmentDate from "@salesforce/label/c.pmc_requestToDeliver_expectedShipmentDate";
import pmc_orderHistory_protocolId from "@salesforce/label/c.pmc_orderHistory_protocolId";
import pmc_requestToDeliverShippingInformation_multiple from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_multiple";

const ORDER_FIELD_NAME = "strOrderNumber";
const DATE_CREATED_FIELD_NAME = "orderDateCreated";
const FORMATTED_DATE_CREATED_FIELD_NAME = "formattedOrderCreationData";
const CONFIRMED = "Confirmed";
const REQUESTED = "Requested";
const PRODUCT = "product";
const MIN_SEARCH_LENGTH = 3;

const columns = [
  {
    label: pmc_orderHistory_orderNumber,
    fieldName: "strOrderNumber",
    type: "dynamiclink",
    dataType: "alphanumeric-substr",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_requestToDeliver_contractNumber,
    fieldName: "strContractNumber",
    type: "text",
    dataType: "alphanumeric",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_contractDetails_poNumber,
    fieldName: "strPONumber",
    type: "text",
    dataType: "alphanumeric",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_quoteCheckoutFlow_products,
    fieldName: "strProducts",
    type: "text",
    cellAttributes: {
      class: "fixedWidthCol"
    },
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
    label: pmc_requestToDeliver_qty,
    fieldName: "totalQuantity",
    type: "text",
    dataType: "number",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_requestToDeliver_expectedShipmentDate,
    fieldName: "orderShipmentDate",
    type: "text",
    dataType: "date"
  },
  {
    label: pmc_quoteHistory_totalPrice,
    fieldName: "totalPrice",
    type: "text",
    dataType: "alphanumeric",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_orderHistory_dateCreated,
    fieldName: "formattedOrderCreationData",
    type: "text",
    dataType: "datetime",
    dateTimeSortField: "orderDateCreated",
    sortable: true,
    defaultSortDirection: "desc",
    isAscSort: false
  },
  // {
  //   label: "",
  //   fieldName: "",
  //   type: "link",
  //   typeAttributes: {
  //     rowActionName: pmc_orderHistory_viewOrder
  //   }
  // }
];

/**
 * A custom LWC to display order history list.
 * @alias Pmc_dh_orderHistoryList
 * @extends LightningElement
 * @hideconstructor
 * @author Vanshika
 *
 * @example
 * <c-pmc_dh_order-history-list></c-pmc_dh_order-history-list>
 */

export default class Pmc_dh_orderHistoryList extends NavigationMixin(
  LightningElement
) {
  columns = columns;

  @track orderList = [];
  @track filteredData = [];
  @track searchData = [];
  @track productFilters = [];
  @track filters = [
    {
      label: pmc_quoteHistory_filterByProducts,
      name: PRODUCT,
      options: []
    }
  ];

  @track labels = {
    pmc_orderHistory_confirmed,
    pmc_orderHistory_requested,
    pmc_orderHistory_orderHistory,
    pmc_orderHistory_noResultsMsg,
    pmc_orderHistory_searchOrders,
    pmc_requestToDeliverShippingInformation_multiple
  };

  strStatus = CONFIRMED;
  defaultSortOrder = SORT_DIRECTION.ASC;
  effAccId;
  isConfirmedList = true;
  pageLoaded = false;
  isSpinner = false;
  isResultSetEmpty = false;
  error;
  recordsPerPage = 10;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    this.strLocale = sessionStorage.getItem("userRegion");
    if (sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
      this.effAccId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
    }
    this.queryParamsHandler();
  }

  /**
   * Reading query params
   * @function queryParamsHandler
   */
  queryParamsHandler() {
    let params = new URLSearchParams(window.location.search);
    if (params.get("menu") && params.get("menu") === REQUESTED) {
      this.strStatus = REQUESTED;
      this.isConfirmedList = false;
    }
    this.fetchOrderDetails(true);
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (this.isConfirmedList) {
      this.template.querySelector(".con").classList.add("dynamic-border");
      this.template.querySelector(".req").classList.remove("dynamic-border");
    } else {
      this.template.querySelector(".con").classList.remove("dynamic-border");
      this.template.querySelector(".req").classList.add("dynamic-border");
    }
  }

  /**
   * Fetches order list
   * @function fetchOrderDetails
   * @param {boolean} fetchAll 
   * @param {object} orderWrapper 
   */
  fetchOrderDetails(fetchAll, orderWrapper) {
    this.isSpinner = true;
    if (!orderWrapper) {
      orderWrapper = {
        strSearchTerm: "",
        datFromDate: null,
        datToDate: null,
        strStatus: this.strStatus
      };
    }
    // let orderedList = [];
    // this.updateOrderDetails(JSON.parse(JSON.stringify(orderedList)), fetchAll);
    if (isBrazilRegion() && this.strStatus === REQUESTED) {
      if (this.columns[4].fieldName !== "strProtocolNo") {
        this.columns.splice(4, 0, {
          label: pmc_orderHistory_protocolId,
          fieldName: "strProtocolNo",
          type: "text",
          dataType: "alphanumeric",
          cellAttributes: {
            class: "fixedWidthCol"
          },
          sortable: true,
          defaultSortDirection: "asc",
          isAscSort: true
        });
      }
      fetchOrderHistory({
        strEffectiveAccountId: this.effAccId
      }).then((order) => {
        if (order && Object.keys(order).length) {
          if (JSON.parse(JSON.stringify(order)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(order)).statusCodeMessage.strStatusMessage)
          }
          this.buildOrderWrapper(fetchAll, order);
        }
        this.isSpinner = false;
      }).catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.pageLoaded = true;
        this.isSpinner = false;
      })
    } else {
      this.columns = this.columns.filter(field => {
        return field.fieldName !== "strProtocolNo";
      })
      getOrderRecords({
        searchParams: orderWrapper,
        strEffectiveAccId: this.effAccId,
        strLocale: this.strLocale
      })
        .then((order) => {
          if (order && Object.keys(order).length) {
            if (JSON.parse(JSON.stringify(order)).statusCodeMessage?.strStatusMessage) {
              toastMessageHandler(JSON.parse(JSON.stringify(order)).statusCodeMessage.strStatusMessage)
            }
            this.buildOrderWrapper(fetchAll, order);
          }
          this.isSpinner = false;
        })
        .catch((error) => {
          toastMessageHandler();
          this.error = error;
          this.pageLoaded = true;
          this.isSpinner = false;
        });
    }
  }

  /**
   * Builds order wrapper after method call
   * @function buildOrderWrapper
   * @param {boolean} fetchAll 
   * @param {object} order 
   */
  buildOrderWrapper(fetchAll, order) {
    if (order?.lstOrders && order?.lstProductFilters) {
      let orderedList = JSON.parse(JSON.stringify(order.lstOrders.reverse()));
      this.updateOrderDetails(
        JSON.parse(JSON.stringify(orderedList)),
        fetchAll
      );
      if (this.strStatus === REQUESTED) {
        this.productFilters = JSON.parse(
          JSON.stringify(order.lstProductFilters)
        );
      }
      this.setProductFilters(
        JSON.parse(JSON.stringify(order.lstProductFilters))
      );
    } else {
      let orderedList = [];
      this.updateOrderDetails(JSON.parse(JSON.stringify(orderedList)), fetchAll);
    }
    this.pageLoaded = true;
  }

  /**
   * Updates order records
   * @function updateOrderDetails
   * @param {Array} orders 
   * @param {boolean} fetchAll
   */
  updateOrderDetails(orders, fetchAll = true) {
    this.isResultSetEmpty = false;
    if (!fetchAll && orders.length === 0) {
      this.isResultSetEmpty = true;
    }
    if (orders.length > 1000) {
      orders.length = 1000;
    }
    orders.forEach((item) => {
      item.strContractNumber = item.strContractNumber ? item.strContractNumber : 'TBD';
      item.strPONumber = item.strPONumber ? item.strPONumber : (item.strContractNumber && item.strContractNumber !== 'TBD' ? '' : 'TBD');
      if(item.strProtocolNo){
        item.strProtocolNo = String(item.strProtocolNo).replaceAll(';', ',');
        item.strProtocolNoNames = String(item.strProtocolNo).replaceAll(',', ';');
      }
      item.Id = item.strOrderNumber;
      item.totalPrice = parseFloat(item.totalPrice).toFixed(2);
      if (isBrazilRegion()) {
        item.totalPrice = `R$${item.totalPrice}`;
      } else {
        item.totalPrice = `$${item.totalPrice}`;
      }
      item.formattedOrderCreationData = item.orderDateCreated
        ? formatDate(item.orderDateCreated.split("T")[0])
        : "";
      item.orderDateCreated = item.orderDateCreated
        ? formatDateTime(item.orderDateCreated)
        : "";
      if (item.orderShipmentDate !== pmc_requestToDeliverShippingInformation_multiple) {
        item.orderShipmentDate = item.orderShipmentDate
          ? formatDate(item.orderShipmentDate.split("T")[0])
          : "";
      }
    });
    this.filteredData = sortData(
      JSON.parse(JSON.stringify(orders)),
      DATE_CREATED_FIELD_NAME,
      "datetime",
      SORT_DIRECTION.DESC
    );
    if (fetchAll) {
      this.orderList = JSON.parse(JSON.stringify(this.filteredData));
    }
    this.searchData = JSON.parse(JSON.stringify(this.filteredData));
    fireEvent(this.pageRef, "exportToCsvEvent", {
      exportData: [...this.filteredData],
      isConfirmedList: this.isConfirmedList
    });
    this.setColumnSortOrder();
    this.template
      .querySelector("c-pmc_dh_pagination")
      ?.setDataOnSearch(this.filteredData);
  }

  /**
   * Returns Search Results based on user inputs
   * @function handleSearch
   * @param {Event} event 
   */
  handleSearch(event) {
    let targetEl = event.detail.targetId;
    let searchJSON = JSON.parse(JSON.stringify(event.detail.searchObj));
    if (
      searchJSON?.strSearchInput?.length >= MIN_SEARCH_LENGTH ||
      searchJSON?.fromDate ||
      searchJSON?.toDate
    ) {
      let orderWrapper = {
        strSearchTerm:
          searchJSON?.strSearchInput?.length >= MIN_SEARCH_LENGTH
            ? searchJSON?.strSearchInput
            : null,
        datFromDate:
          targetEl === "strSearchInput" ? null : searchJSON?.fromDate,
        datToDate: targetEl === "strSearchInput" ? null : searchJSON?.toDate,
        strStatus: this.strStatus
      };
      if (this.strStatus === REQUESTED) {
        this.filterByDate(orderWrapper);
      } else {
        this.fetchOrderDetails(false, orderWrapper);
      }
    } else {
      this.fetchOrderDetails(true);
    }
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
        return data.setSKU.includes(searchJSON.product);
      });
    } else {
      this.filteredData = JSON.parse(JSON.stringify(this.searchData));
    }
    if (this.filteredData.length === 0) {
      this.isResultSetEmpty = true;
    }
    fireEvent(this.pageRef, "exportToCsvEvent", {
      exportData: [...this.filteredData],
      isConfirmedList: this.isConfirmedList
    });
    this.setDefaultMode();
  }

  /**
   * Filter records based on date and order
   * @function filterByDate
   * @param {object} searchObj 
   */
  filterByDate(searchObj) {
    this.isResultSetEmpty = false;
    this.filteredData = JSON.parse(JSON.stringify(this.orderList));
    if (searchObj?.datFromDate && searchObj?.datToDate) {
      this.filteredData = JSON.parse(
        JSON.stringify(
          this.filteredData.filter(
            (order) =>
              unFormatDate(order.formattedOrderCreationData) >= searchObj.datFromDate &&
              unFormatDate(order.formattedOrderCreationData) <= searchObj.datToDate
          )
        )
      );
    }
    if (searchObj?.strSearchTerm) {
      this.filteredData = JSON.parse(
        JSON.stringify(
          this.filteredData.filter((order) =>
            order.strSearchable
              .toLowerCase()
              .includes(searchObj.strSearchTerm.toLowerCase())
          )
        )
      );
    }
    this.searchData = JSON.parse(JSON.stringify(this.filteredData));
    let productList = this.getListOfProductsPresent(this.filteredData);
    this.setProductFilters(productList);
    this.template
      .querySelector("c-pmc_dh_pagination")
      ?.setDataOnSearch(this.filteredData);
    if (!this.filteredData.length) {
      this.isResultSetEmpty = true;
    }
    fireEvent(this.pageRef, "exportToCsvEvent", {
      exportData: [...this.filteredData],
      isConfirmedList: this.isConfirmedList
    });
  }

  /**
   * Get the list of products present
   * @function getListOfProductsPresent
   * @param {Array} orders 
   */
  getListOfProductsPresent(orders) {
    let list = JSON.parse(JSON.stringify(this.productFilters));
    let listOfProductsPresent = [];
    orders.forEach((order) => {
      order.setSKU.forEach((sku) => {
        if (!listOfProductsPresent?.includes(sku)) {
          listOfProductsPresent.push(sku);
        }
      });
    });
    list = list.filter((el) => listOfProductsPresent?.includes(el.value));
    return list;
  }

  /**
   * Set the product filters
   * @function setProductFilters
   * @param {Array} products 
   */
  setProductFilters(products) {
    this.filters.forEach((el) => {
      if (el.name === PRODUCT) {
        el.options = products;
      }
    });
    this.filters = JSON.parse(JSON.stringify(this.filters));
  }

  /**
   * Set default state of columns sort
   * @function setColumnSortOrder
   */
  setColumnSortOrder() {
    this.columns = this.columns.map((col) => {
      if (col.fieldName === FORMATTED_DATE_CREATED_FIELD_NAME) {
        col.isAscSort = true;
      }
      return col;
    });
  }

  /**
   * Set default state of quote list
   * @function setDefaultMode
   */
  setDefaultMode() {
    this.filteredData = sortData(
      this.filteredData,
      DATE_CREATED_FIELD_NAME,
      "datetime",
      SORT_DIRECTION.DESC
    );
    this.setColumnSortOrder();
    this.template
      .querySelector("c-pmc_dh_pagination")
      ?.setDataOnSearch(this.filteredData);
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
    fireEvent(this.pageRef, "exportToCsvEvent", {
      exportData: [...this.filteredData],
      isConfirmedList: this.isConfirmedList
    });
    this.setDefaultMode();
  }

  /**
   * Resets the search results
   * @function clearSearchInputs
   */
  clearSearchInputs() {
    this.fetchOrderDetails(true);
  }

  /**
   * Navigate to Order Details Page for Confirmed Orders
   * @function navigateToOrderDetails
   * @param {Event} event 
   */
  navigateToOrderDetails(event) {
    let url = '';
    let recId = event.detail.id;
    let LS = localStorage;
    this.filteredData.forEach((el) => {
      if (el.strOrderNumber === recId) {
        if (isBrazilRegion() && this.strStatus === REQUESTED) {
          url = 'orders/order-details';
          sessionStorage.setItem('ORDER_STATUS', REQUESTED);
          if (el.strOrderItems) {
            let strOrderItemsEncryption = el.strOrderItems;
            LS.setItem("BR_REQUESTED_ORDER", strOrderItemsEncryption);
            // console.log('strOrderItemsEncryption:', strOrderItemsEncryption);
          }
        } else {
          url = el.orderDetailLink;
          sessionStorage.setItem('ORDER_STATUS', CONFIRMED);
        }
        this[NavigationMixin.GenerateUrl]({
          type: "standard__webPage",
          attributes: {
            url: `${basePath}/${url}`
          }
        }).then((generatedUrl) => {
          urlRedirect(generatedUrl);
        });
      }
    });
  }

  /**
   * Handle selection of Confirmed or Requested tab
   * @function tabChangeHandler
   * @param {Event} event 
   */
  tabChangeHandler(event) {
    this.template.querySelector("c-pmc_dh_search-filters").resetInputs();
    this.isConfirmedList = event.target.dataset.id === CONFIRMED ? true : false;
    this.strStatus =
      event.target.dataset.id === CONFIRMED ? CONFIRMED : REQUESTED;
    let fieldLabel =
      event.target.dataset.id === CONFIRMED
        ? pmc_orderHistory_orderNumber
        : pmc_orderHistory_requestNumber;
    this.columns.find((col) => col.fieldName === ORDER_FIELD_NAME).label =
      fieldLabel;
    this.isResultSetEmpty = false;
    this.fetchOrderDetails(true);
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