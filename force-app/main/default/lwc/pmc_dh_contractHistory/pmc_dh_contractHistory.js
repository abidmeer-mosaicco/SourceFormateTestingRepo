import { LightningElement, track } from "lwc";
import { SORT_DIRECTION, toastMessageHandler } from "c/pmc_dh_utilityJs";
import { NavigationMixin } from "lightning/navigation";
import { getCurrencyAndPrice, urlRedirect } from "c/pmc_dh_utilityJs";
import basePath from "@salesforce/community/basePath";
import getContractRecords from "@salesforce/apex/PMC_DH_ContractListViewController.getContractRecords";

import pmc_contractDetails_poNumber from "@salesforce/label/c.pmc_contractDetails_poNumber";
import pmc_contractDetails_contractType from "@salesforce/label/c.pmc_contractDetails_contractType";
import pmc_quoteCheckoutFlow_incoterms from "@salesforce/label/c.pmc_quoteCheckoutFlow_incoterms";
import pmc_quoteCheckoutFlow_deliveryMode from "@salesforce/label/c.pmc_quoteCheckoutFlow_deliveryMode";
import pmc_quoteHistory_filterByProducts from "@salesforce/label/c.pmc_quoteHistory_filterByProducts";
import pmc_contractDetails_products from "@salesforce/label/c.pmc_contractDetails_products";
import pmc_quoteCheckoutFlow_shipTo from "@salesforce/label/c.pmc_quoteCheckoutFlow_shipTo";
import pmc_contractMgmt_contractNumber from "@salesforce/label/c.pmc_contractMgmt_contractNumber";
import pmc_quoteCheckoutFlow_shipFrom from "@salesforce/label/c.pmc_quoteCheckoutFlow_shipFrom";
import pmc_contractMgmt_filterContractType from "@salesforce/label/c.pmc_contractMgmt_filtercontractType";
import pmc_contractMgmt_searchContracts from "@salesforce/label/c.pmc_contractMgmt_searchContracts";
import pmc_addresses_status from "@salesforce/label/c.pmc_addresses_status";
import pmc_contractDetails_myContractsHistory from "@salesforce/label/c.pmc_contractDetails_myContractsHistory";
import pmc_breadcrumb_homepage from "@salesforce/label/c.pmc_breadcrumb_homepage";
import pmc_orderHistory_noResultsMsg from "@salesforce/label/c.pmc_orderHistory_noResultsMsg";
import pmc_contractDetails_availableQty from "@salesforce/label/c.pmc_contractDetails_availableQty";
//import pmc_contractDetails_price from "@salesforce/label/c.pmc_contractDetails_price";
import pmc_contractDetails_pricePerTon from "@salesforce/label/c.pmc_contractDetails_pricePerTon";
import pmc_orderDetails_active from "@salesforce/label/c.pmc_orderDetails_active";
import pmc_orderDetails_inactive from "@salesforce/label/c.pmc_orderDetails_inactive";
import pmc_requestToDeliverShippingInformation_multiple from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_multiple";

const columns = [
  {
    label: pmc_contractMgmt_contractNumber,
    fieldName: "strContractNumber",
    type: "dynamiclink",
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
    label: pmc_contractDetails_contractType,
    fieldName: "strContractType",
    type: "text",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_quoteCheckoutFlow_deliveryMode,
    fieldName: "strDeliveryMode",
    type: "text",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_quoteCheckoutFlow_incoterms,
    fieldName: "strIncoterm",
    type: "text",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_contractDetails_products,
    fieldName: "strProducts",
    type: "text",
    dataType: "alphanumeric",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_quoteCheckoutFlow_shipTo,
    fieldName: "strShipTo",
    type: "text",
    dataType: "alphanumeric",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_quoteCheckoutFlow_shipFrom,
    fieldName: "strShipFrom",
    type: "text",
    dataType: "alphanumeric",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_contractDetails_availableQty,
    fieldName: "decAvailableQuantity",
    type: "text",
    dataType: "number",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  /*{
    label: pmc_contractDetails_price,
    fieldName: "decTotalPrice",
    type: "text",
    dataType: "alphanumeric",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },*/

 { label: pmc_contractDetails_pricePerTon,
    fieldName: "decPricePerTon",
    type: "text",
    dataType: "alphanumeric",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
 },
 
  {
    label: pmc_addresses_status,
    fieldName: "strStatus",
    type: "badge",
    sortable: false,
    typeAttributes: {
      variant: "slds-badge_lightest"
    }
  }
];

const contractTypePicklist = "contractType";
const productPicklist = "product";
const STATUS_BADGE_SUCCESS = "success";
const STATUS_BADGE_FINISHED = "finished";

/**
 * A custom LWC to display contract history.
 * @alias Pmc_dh_contractHistory
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 *
 * @example
 * <c-pmc_dh_contract-history></c-pmc_dh_contract-history>
 */

export default class Pmc_dh_contractHistory extends NavigationMixin(
  LightningElement
) {
  @track columns = columns;
  @track filteredData = [];
  @track contractsData = [];
  @track searchData = [];
  @track labels = {
    pmc_contractMgmt_searchContracts,
    pmc_contractDetails_myContractsHistory,
    pmc_breadcrumb_homepage,
    pmc_orderHistory_noResultsMsg,
    pmc_orderDetails_active,
    pmc_orderDetails_inactive,
    pmc_requestToDeliverShippingInformation_multiple
  };
  @track filters = [
    {
      label: pmc_contractMgmt_filterContractType,
      name: contractTypePicklist,
      options: []
    },
    {
      label: pmc_quoteHistory_filterByProducts,
      name: productPicklist,
      options: []
    }
  ];

  crumbs = [
    { label: pmc_breadcrumb_homepage, url: `${basePath}/`, isActive: false },
    { label: pmc_contractDetails_myContractsHistory, url: "", isActive: true }
  ];
  pageLoaded = false;
  isSpinner = true;
  recordsPerPage = 10;
  defaultSortOrder = SORT_DIRECTION.ASC;
  effAccId;
  isResultSetEmpty = false;

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
        this.getContractList(true);
      }
    }, 100);
  }

  /**
   * Fetch all the contracts
   * @function getContractList
   * @param {boolean} fetchAll
   * @param {Object} contractWrapper
   */
  getContractList(fetchAll, contractWrapper) {
    this.isSpinner = true;
    if (!contractWrapper) {
      contractWrapper = {
        strSearchTerm: "",
        datFromDate: null,
        datToDate: null
      };
    }
    getContractRecords({
      searchParams: contractWrapper,
      effAccId: this.effAccId
    })
      .then((contracts) => {
        console.log("contracts",JSON.parse(JSON.stringify(contracts)))
        if (contracts && Object.keys(contracts).length) {
          if (JSON.parse(JSON.stringify(contracts)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(contracts)).statusCodeMessage.strStatusMessage)
          }
          this.updateContractDetails(
            JSON.parse(JSON.stringify(contracts)),
            fetchAll
          );
        }
        this.pageLoaded = true;
        this.isSpinner = false;
      })
      .catch(() => {
        toastMessageHandler();
        this.pageLoaded = true;
        this.isSpinner = false;
      });
  }

  /**
   * Update contract records
   * @function updateContractDetails
   * @param {Object} contracts
   * @param {boolean} fetchAll
   */
  updateContractDetails(contracts, fetchAll = true) {
    this.isResultSetEmpty = false;
    if (!fetchAll && contracts.lstContracts.length === 0) {
      this.isResultSetEmpty = true;
    }
    contracts.lstContracts.forEach((item) => {
      item.Id = item.strContractId;
      item.strShipTo = item.shipTo.boolIsMutiple ? this.labels.pmc_requestToDeliverShippingInformation_multiple : `${item.shipTo.strCity || ""}${item.shipTo.strCity && item.shipTo.strState ? "," : ""} ${item.shipTo.strState || ""}`;
      item.strShipFrom = item.shipFrom.boolIsMutiple ? this.labels.pmc_requestToDeliverShippingInformation_multiple : `${item.shipFrom.strCity || ""}${item.shipFrom.strCity && item.shipFrom.strState ? "," : ""} ${item.shipFrom.strState || ""}`;
      item.decAvailableQuantity = Math.floor(item.decAvailableQuantity);
      //item.decTotalPrice = parseFloat(item.decTotalPrice).toFixed(2);
     // item.decTotalPrice = getCurrencyAndPrice(item?.strCurrencyIsoCode,item.decTotalPrice);
      if (item.strStatus === this.labels.pmc_orderDetails_active) {
        item.badgeStyleClass = STATUS_BADGE_SUCCESS;
      } else if (item.strStatus === this.labels.pmc_orderDetails_inactive) {
        item.badgeStyleClass = STATUS_BADGE_FINISHED;
      }
    });
    if (contracts.lstContracts.length > 1000) {
      contracts.lstContracts.length = 1000;
    }
    this.filteredData = JSON.parse(JSON.stringify(contracts.lstContracts));
    if (fetchAll) {
      this.contractsData = JSON.parse(JSON.stringify(this.filteredData));
    }
    this.searchData = JSON.parse(JSON.stringify(this.filteredData));
    this.template
      .querySelector("c-pmc_dh_pagination")
      ?.setDataOnSearch(this.filteredData);
    this.setContractFilters(
      contracts.lstContractType,
      contracts.lstProductFilters
    );
  }

  /**
   * Setting the contract filters
   * @function setContractFilters
   * @param {Array} types
   * @param {Array} products
   */
  setContractFilters(types, productsList) {
    let uniqueTypes = [...new Map(types.map(item =>
      [item.value, item])).values()];
    let uniqueProducts = [...new Map(productsList.map(item =>
      [item.value, item])).values()];
    this.filters.forEach((fltr) => {
      if (fltr.name === contractTypePicklist) {
        fltr.options = uniqueTypes;
      }
      if (fltr.name === productPicklist) {
        fltr.options = uniqueProducts;
      }
    });
    this.filters = JSON.parse(JSON.stringify(this.filters));
  }

  /**
   * Set default state of contract list
   * @function setDefaultMode
   */
  setDefaultMode() {
    this.template
      .querySelector("c-pmc_dh_pagination")
      ?.setDataOnSearch(this.filteredData);
  }

  /**
   * Returns Search Results based on user inputs
   * @function handleSearch
   */
  handleSearch(event) {
    let targetEl = event.detail.targetId;
    let searchJSON = JSON.parse(JSON.stringify(event.detail.searchObj));
    if (
      searchJSON?.strSearchInput?.length > 2 ||
      searchJSON?.fromDate ||
      searchJSON?.toDate
    ) {
      let contractWrapper = {
        strSearchTerm:
          searchJSON?.strSearchInput?.length > 2
            ? searchJSON?.strSearchInput
            : null,
        datFromDate:
          targetEl === "strSearchInput" ? null : searchJSON?.fromDate,
        datToDate: targetEl === "strSearchInput" ? null : searchJSON?.toDate
      };
      this.getContractList(false, contractWrapper);
    } else {
      this.getContractList(true);
    }
  }

  /**
   * Returns filter Results based on picklist selection
   * @function
   * @param {Event} event
   */
  handleApplyFilter(event) {
    this.isResultSetEmpty = false;
    let searchJSON = JSON.parse(JSON.stringify(event.detail.searchObj));
    if (searchJSON?.contractType || searchJSON?.product) {
      this.filteredData = this.searchData.filter((data) => {
        if (searchJSON.contractType && searchJSON.product) {
          return (
            data.setContractTypes.includes(searchJSON.contractType) &&
            data.setSKU.includes(searchJSON.product)
          );
        } else if (searchJSON.contractType) {
          return data.setContractTypes.includes(searchJSON.contractType);
        }
        return data.setSKU.includes(searchJSON.product);
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
   * Reset all the filters
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
   * Reset the search results
   * @function clearFilters
   */
  clearSearchInputs() {
    this.getContractList(true);
  }

  /**
   * Navigate to Contract Details Page
   * @function clearFilters
   */
  navigateToContractDetails(event) {
    let contractId = event.detail.id;
    this.filteredData.forEach((el) => {
      if (el.strContractId === contractId) {
        let url = el.strContractDetailLink;
        this[NavigationMixin.GenerateUrl]({
          type: "standard__webPage",
          attributes: {
            url: `${basePath}${url}`
          }
        }).then((generatedUrl) => {
          urlRedirect(generatedUrl);
        });
      }
    })
  }

  /**
   * Updating filtered data to display only current page details
   * @function updatePaginatedData
   * @param {event} event 
   */
  updatePaginatedData(event) {
    this.filteredData = event.detail;
  }
}